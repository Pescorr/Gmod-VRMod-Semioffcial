--------[vrmod_holster_dupe.lua]Start--------
-- ホルスターDupe機能: 複合エンティティ（溶接グループ等）のホルスター保存/復元
-- Gmod duplicator ライブラリを活用
AddCSLuaFile()

vrmod = vrmod or {}
vrmod.HolsterDupe = vrmod.HolsterDupe or {}

local MAX_DUPE_ENTITIES = 50
local MAX_SLOTS = 8
local RATE_LIMIT_INTERVAL = 2 -- 秒

if SERVER then
    -- サーバー側dupeストレージ: [steamid][slot] = dupeData
    local dupeStorage = {}
    -- レートリミット: [steamid] = lastActionTime
    local rateLimits = {}

    util.AddNetworkString("vrmod_unoff_holster_dupe_store")
    util.AddNetworkString("vrmod_unoff_holster_dupe_spawn")
    util.AddNetworkString("vrmod_unoff_holster_dupe_sync")

    local function InitPlayerStorage(steamid)
        if not dupeStorage[steamid] then
            dupeStorage[steamid] = {}
        end
    end

    local function CheckRateLimit(steamid)
        local now = CurTime()
        if rateLimits[steamid] and (now - rateLimits[steamid]) < RATE_LIMIT_INTERVAL then
            return false
        end
        rateLimits[steamid] = now
        return true
    end

    -- プレイヤー切断時のクリーンアップ
    hook.Add("PlayerDisconnected", "VRMod_HolsterDupe_Cleanup", function(ply)
        local steamid = ply:SteamID()
        dupeStorage[steamid] = nil
        rateLimits[steamid] = nil
    end)

    -- 保存: クライアントからheldEntityのdupe保存リクエスト
    net.Receive("vrmod_unoff_holster_dupe_store", function(len, ply)
        if not IsValid(ply) then return end
        local steamid = ply:SteamID()

        if not CheckRateLimit(steamid) then return end

        local slotIndex = net.ReadUInt(4)
        local entIndex = net.ReadUInt(14)
        local isLeftHand = net.ReadBool()

        -- バリデーション
        if slotIndex < 1 or slotIndex > MAX_SLOTS then return end
        local ent = Entity(entIndex)
        if not IsValid(ent) then return end

        -- 距離チェック（500ユニット以内）
        if ent:GetPos():DistToSqr(ply:GetPos()) > 250000 then return end

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

        -- クライアントに同期
        net.Start("vrmod_unoff_holster_dupe_sync")
        net.WriteUInt(slotIndex, 4)
        net.WriteString(displayName)
        net.Send(ply)
    end)

    -- 復元: クライアントからdupeスポーンリクエスト
    net.Receive("vrmod_unoff_holster_dupe_spawn", function(len, ply)
        if not IsValid(ply) then return end
        local steamid = ply:SteamID()

        if not CheckRateLimit(steamid) then return end

        local slotIndex = net.ReadUInt(4)
        local handPos = net.ReadVector()
        local handAng = net.ReadAngle()
        local isLeftHand = net.ReadBool()

        if slotIndex < 1 or slotIndex > MAX_SLOTS then return end
        if not dupeStorage[steamid] or not dupeStorage[steamid][slotIndex] then return end

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

        -- VR手にピックアップ
        if IsValid(rootEnt) then
            timer.Simple(0.08, function()
                if IsValid(ply) and IsValid(rootEnt) then
                    pickup(ply, isLeftHand, rootEnt:GetPos(), rootEnt:GetAngles())
                end
            end)
        end

        -- スロットをクリア
        dupeStorage[steamid][slotIndex] = nil

        -- クライアントに同期（スロット空）
        net.Start("vrmod_unoff_holster_dupe_sync")
        net.WriteUInt(slotIndex, 4)
        net.WriteString("")
        net.Send(ply)
    end)

    -- 外部API: スロットにdupeがあるか確認
    function vrmod.HolsterDupe.HasDupe(steamid, slotIndex)
        return dupeStorage[steamid] and dupeStorage[steamid][slotIndex] ~= nil
    end
end

if CLIENT then
    -- dupeスポーン保留状態（VRMod_Pickupフック用）
    local dupePendingSpawn = nil

    -- サーバーからの同期を受信
    net.Receive("vrmod_unoff_holster_dupe_sync", function()
        local slotIndex = net.ReadUInt(4)
        local displayName = net.ReadString()

        -- ConVarを更新（ホルスターシステムが読み取る）
        LocalPlayer():ConCommand("vrmod_pouch_weapon_" .. slotIndex .. " " .. displayName)
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
        net.WriteUInt(slotIndex, 4)
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
        net.WriteUInt(slotIndex, 4)
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
