--------[vrmod_holster_dupe.lua]Start--------
-- ホルスターDupe機能: 複合エンティティ（溶接グループ等）のホルスター保存/復元
-- Gmod duplicator ライブラリを活用
-- ファイル永続化: data/vrmod/holster/{steamid64}/slot_{n}.dat
AddCSLuaFile()

vrmod = vrmod or {}
vrmod.HolsterDupe = vrmod.HolsterDupe or {}

local MAX_DUPE_ENTITIES = 50
-- S20 Problem 1+2: 1-8右手, 9-11左手slot6-8（既存互換）, 12-16左手slot1-5
local MAX_SLOTS = 16
local RATE_LIMIT_INTERVAL = 2 -- 秒
local DUPE_DIR = "vrmod/holster"
-- S20: net bit幅（MAX_SLOTS=16対応: 5bit=0-31）
local NET_SLOT_BITS = 5

if SERVER then
    -- サーバー側dupeストレージ: [steamid][slot] = dupeData
    local dupeStorage = {}
    -- レートリミット: 保存と復元を分離
    local rateLimitsStore = {}
    local rateLimitsSpawn = {}

    util.AddNetworkString("vrmod_unoff_holster_dupe_store")
    util.AddNetworkString("vrmod_unoff_holster_dupe_spawn")
    util.AddNetworkString("vrmod_unoff_holster_dupe_sync")

    local function InitPlayerStorage(steamid)
        if not dupeStorage[steamid] then
            dupeStorage[steamid] = {}
        end
    end

    -- ファイルI/O: lambdaと同一方式（file.Open binary + compress）
    local function SaveDupeToFile(steamid64, slotIndex, data)
        file.CreateDir(DUPE_DIR .. "/" .. steamid64)
        local path = DUPE_DIR .. "/" .. steamid64 .. "/slot_" .. slotIndex .. ".dat"
        local json = util.TableToJSON(data)
        local compressed = util.Compress(json)
        local f = file.Open(path, "wb", "DATA")
        if not f then return false end
        f:Write(compressed)
        f:Close()
        return true
    end

    local function LoadDupeFromFile(steamid64, slotIndex)
        local path = DUPE_DIR .. "/" .. steamid64 .. "/slot_" .. slotIndex .. ".dat"
        local f = file.Open(path, "rb", "DATA")
        if not f then return nil end
        local compressed = f:Read(f:Size())
        f:Close()
        if not compressed then return nil end
        local json = util.Decompress(compressed)
        if not json then return nil end
        return util.JSONToTable(json)
    end

    local function DeleteDupeFile(steamid64, slotIndex)
        local path = DUPE_DIR .. "/" .. steamid64 .. "/slot_" .. slotIndex .. ".dat"
        file.Delete(path)
    end

    local function CheckRateLimitStore(steamid)
        local now = CurTime()
        if rateLimitsStore[steamid] and (now - rateLimitsStore[steamid]) < RATE_LIMIT_INTERVAL then
            return false
        end
        rateLimitsStore[steamid] = now
        return true
    end

    local function CheckRateLimitSpawn(steamid)
        local now = CurTime()
        if rateLimitsSpawn[steamid] and (now - rateLimitsSpawn[steamid]) < RATE_LIMIT_INTERVAL then
            return false
        end
        rateLimitsSpawn[steamid] = now
        return true
    end

    -- プレイヤー切断時のクリーンアップ（メモリのみ。ファイルは維持）
    hook.Add("PlayerDisconnected", "VRMod_HolsterDupe_Cleanup", function(ply)
        local steamid = ply:SteamID()
        dupeStorage[steamid] = nil
        rateLimitsStore[steamid] = nil
        rateLimitsSpawn[steamid] = nil
    end)

    -- プレイヤー参加時: ファイルからdupeデータを復元
    hook.Add("PlayerInitialSpawn", "VRMod_HolsterDupe_Load", function(ply)
        timer.Simple(2, function()
            if not IsValid(ply) then return end
            local steamid = ply:SteamID()
            local steamid64 = ply:SteamID64()
            InitPlayerStorage(steamid)

            for i = 1, MAX_SLOTS do
                local saved = LoadDupeFromFile(steamid64, i)
                if saved and saved.dupeData then
                    dupeStorage[steamid][i] = saved.dupeData
                    net.Start("vrmod_unoff_holster_dupe_sync")
                    net.WriteUInt(i, NET_SLOT_BITS)
                    net.WriteString(saved.displayName or "dupe: unknown")
                    net.Send(ply)
                end
            end
        end)
    end)

    -- 保存: クライアントからheldEntityのdupe保存リクエスト
    net.Receive("vrmod_unoff_holster_dupe_store", function(len, ply)
        if not IsValid(ply) then return end
        local steamid = ply:SteamID()

        if not CheckRateLimitStore(steamid) then
            ply:ChatPrint("[VRHolster] Too fast, wait a moment")
            return
        end

        local slotIndex = net.ReadUInt(NET_SLOT_BITS)
        local entIndex = net.ReadUInt(14)
        local isLeftHand = net.ReadBool()

        -- バリデーション
        if slotIndex < 1 or slotIndex > MAX_SLOTS then return end
        local ent = Entity(entIndex)
        if not IsValid(ent) then
            -- S20 Problem 7: サイレント失敗にフィードバック追加
            ply:ChatPrint("[VRHolster] Entity not found, cannot store dupe")
            return
        end

        -- 距離チェック（500ユニット以内）
        if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then
            -- S20 Problem 7: 距離オーバー時のフィードバック
            ply:ChatPrint("[VRHolster] Entity too far away to store")
            return
        end

        InitPlayerStorage(steamid)

        -- duplicator.Copy でエンティティ＋コンストレイント群を丸ごとキャプチャ
        local rootPos = ent:GetPos()
        local rootAng = ent:GetAngles()

        duplicator.SetLocalPos(rootPos)
        duplicator.SetLocalAng(Angle(0, rootAng.y, 0))
        local ok, dupeData = pcall(duplicator.Copy, ent)
        duplicator.SetLocalPos(Vector())
        duplicator.SetLocalAng(Angle())

        if not ok or not dupeData or not dupeData.Entities then
            ply:ChatPrint("[VRHolster] Dupe capture failed")
            return
        end

        -- エンティティ数チェック
        local entCount = 0
        for _ in pairs(dupeData.Entities) do
            entCount = entCount + 1
        end
        if entCount > MAX_DUPE_ENTITIES then
            ply:ChatPrint("[VRHolster] Too many entities (" .. entCount .. "/" .. MAX_DUPE_ENTITIES .. ")")
            return
        end

        -- dupeデータを保存
        dupeStorage[steamid][slotIndex] = dupeData

        -- 元のエンティティ群をすべて削除
        for k, _ in pairs(dupeData.Entities) do
            local e = Entity(k)
            if IsValid(e) then
                e:Remove()
            end
        end

        -- 表示名を構築（HUD/3Dテキスト/メニューでそのまま表示される）
        local displayName = "dupe: " .. entCount .. " ents"
        for _, v in pairs(dupeData.Entities) do
            if v.Class then
                if entCount == 1 then
                    displayName = "dupe: " .. v.Class
                else
                    displayName = "dupe: " .. v.Class .. " (" .. entCount .. ")"
                end
                break
            end
        end

        -- ファイルにも永続化（displayNameと共に保存）
        local saved = SaveDupeToFile(ply:SteamID64(), slotIndex, {
            dupeData = dupeData,
            displayName = displayName
        })
        -- S20 Problem 7: 保存成功フィードバック
        if saved then
            ply:ChatPrint("[VRHolster] Dupe stored: " .. displayName)
        else
            ply:ChatPrint("[VRHolster] Dupe captured but file save failed")
        end
        -- クライアントに同期
        net.Start("vrmod_unoff_holster_dupe_sync")
        net.WriteUInt(slotIndex, NET_SLOT_BITS)
        net.WriteString(displayName)
        net.Send(ply)
    end)

    -- 復元: クライアントからdupeスポーンリクエスト
    net.Receive("vrmod_unoff_holster_dupe_spawn", function(len, ply)
        if not IsValid(ply) then return end
        local steamid = ply:SteamID()

        if not CheckRateLimitSpawn(steamid) then
            ply:ChatPrint("[VRHolster] Spawn too fast, wait a moment")
            return
        end

        local slotIndex = net.ReadUInt(NET_SLOT_BITS)
        local handPos = net.ReadVector()
        local handAng = net.ReadAngle()
        local isLeftHand = net.ReadBool()

        if slotIndex < 1 or slotIndex > MAX_SLOTS then return end
        if not dupeStorage[steamid] or not dupeStorage[steamid][slotIndex] then
            ply:ChatPrint("[VRHolster] No dupe data in slot " .. slotIndex)
            -- クライアントのConVarをクリア（サーバーとの同期修復）
            net.Start("vrmod_unoff_holster_dupe_sync")
            net.WriteUInt(slotIndex, NET_SLOT_BITS)
            net.WriteString("")
            net.Send(ply)
            return
        end

        local dupeData = dupeStorage[steamid][slotIndex]

        -- duplicator.Paste で再構築
        duplicator.SetLocalPos(handPos)
        duplicator.SetLocalAng(Angle(0, handAng.y, 0))
        local ok, createdEnts, createdConstraints = pcall(
            duplicator.Paste, ply, dupeData.Entities, dupeData.Constraints
        )
        duplicator.SetLocalPos(Vector())
        duplicator.SetLocalAng(Angle())

        if not ok or not createdEnts then
            ply:ChatPrint("[VRHolster] Failed to spawn dupe")
            return
        end

        -- ルートエンティティを特定（最初の有効なエンティティ）
        local rootEnt = nil
        for _, e in pairs(createdEnts) do
            if IsValid(e) then
                rootEnt = e
                break
            end
        end

        -- VR手にピックアップ + 再利用設定に応じてスロット管理
        if IsValid(rootEnt) then
            local slotLocal = slotIndex
            timer.Simple(0.15, function()
                if not IsValid(ply) then return end
                if not IsValid(rootEnt) then
                    -- エンティティが消えた（他MODによる削除等）→ dupeデータ維持
                    ply:ChatPrint("[VRHolster] Entity lost, dupe kept in slot")
                    return
                end
                -- pickup実行
                pickup(ply, isLeftHand, rootEnt:GetPos(), rootEnt:GetAngles())
                -- 再利用設定チェック
                if ply:GetInfoNum("vrmod_unoff_dupe_reusable", 0) ~= 0 then
                    -- 再利用モード: データもファイルもそのまま維持
                    local saved = LoadDupeFromFile(ply:SteamID64(), slotLocal)
                    local dn = saved and saved.displayName or "dupe: unknown"
                    net.Start("vrmod_unoff_holster_dupe_sync")
                    net.WriteUInt(slotLocal, NET_SLOT_BITS)
                    net.WriteString(dn)
                    net.Send(ply)
                else
                    -- 通常モード: メモリ + ファイル削除
                    dupeStorage[steamid][slotLocal] = nil
                    DeleteDupeFile(ply:SteamID64(), slotLocal)
                    net.Start("vrmod_unoff_holster_dupe_sync")
                    net.WriteUInt(slotLocal, NET_SLOT_BITS)
                    net.WriteString("")
                    net.Send(ply)
                end
            end)
        else
            -- rootEntなし → データ維持
            ply:ChatPrint("[VRHolster] No valid entity spawned, dupe kept")
        end
    end)

    -- 外部API: スロットにdupeがあるか確認
    function vrmod.HolsterDupe.HasDupe(steamid, slotIndex)
        return dupeStorage[steamid] and dupeStorage[steamid][slotIndex] ~= nil
    end
end

if CLIENT then
    -- dupeの再利用設定（userinfo=trueでサーバーから読み取り可能）
    CreateClientConVar("vrmod_unoff_dupe_reusable", "1", true, true)

    -- dupeスポーン保留状態（VRMod_Pickupフック用）
    local dupePendingSpawn = nil

    -- サーバーからの同期を受信
    net.Receive("vrmod_unoff_holster_dupe_sync", function()
        local slotIndex = net.ReadUInt(NET_SLOT_BITS)
        local displayName = net.ReadString()

        -- ConVarを更新（ホルスターシステムが読み取る）
        -- S20 Problem 1+2: slot 12-16は左手用slot1-5、slot 9-11は左手用slot6-8
        local convarName
        if slotIndex >= 12 and slotIndex <= 16 then
            convarName = "vrmod_pouch_weapon_" .. (slotIndex - 11) .. "_left"
        elseif slotIndex >= 9 and slotIndex <= 11 then
            convarName = "vrmod_pouch_weapon_" .. (slotIndex - 3) .. "_left"
        else
            convarName = "vrmod_pouch_weapon_" .. slotIndex
        end
        RunConsoleCommand(convarName, displayName)
    end)

    -- dupeスロットかどうか判定
    function vrmod.HolsterDupe.IsDupeSlot(slotIndex)
        local convar = GetConVar("vrmod_pouch_weapon_" .. slotIndex)
        if not convar then return false end
        local val = convar:GetString()
        return string.StartWith(val, "dupe:")
    end

    -- dupe保存リクエスト送信
    function vrmod.HolsterDupe.StoreEntity(slotIndex, ent, isLeftHand)
        if not IsValid(ent) then return false end
        net.Start("vrmod_unoff_holster_dupe_store")
        net.WriteUInt(slotIndex, NET_SLOT_BITS)
        net.WriteUInt(ent:EntIndex(), 14)
        net.WriteBool(isLeftHand)
        net.SendToServer()
        return true
    end

    -- dupeスポーンリクエスト送信
    function vrmod.HolsterDupe.SpawnDupe(slotIndex, handPos, handAng, isLeftHand)
        -- VRMod_Pickupフック用に保留状態をセット
        dupePendingSpawn = {
            leftHand = isLeftHand,
            time = CurTime()
        }

        net.Start("vrmod_unoff_holster_dupe_spawn")
        net.WriteUInt(slotIndex, NET_SLOT_BITS)
        net.WriteVector(handPos)
        net.WriteAngle(handAng)
        net.WriteBool(isLeftHand)
        net.SendToServer()
    end

    -- dupeスポーン後のVRMod_Pickupフック
    -- サーバー側pickup()がVRMod_Pickupを発火させるので、
    -- クライアント側でvrmod.Pickup()を呼んでVR手にアタッチする
    hook.Add("VRMod_Pickup", "VRMod_HolsterDupe_Pickup", function(ply, ent)
        if ply ~= LocalPlayer() then return end
        if not dupePendingSpawn then return end

        -- 2秒以内のリクエストのみ処理
        if CurTime() - dupePendingSpawn.time > 2.0 then
            dupePendingSpawn = nil
            return
        end

        if vrmod and vrmod.Pickup then
            vrmod.Pickup(dupePendingSpawn.leftHand, false)
        end
        dupePendingSpawn = nil
    end)
end
--------[vrmod_holster_dupe.lua]End--------
