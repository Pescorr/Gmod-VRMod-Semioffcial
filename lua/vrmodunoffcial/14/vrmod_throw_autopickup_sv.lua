--[[
    Module 15: VR Throw Auto-Pickup — Server Side
    グリップボタンを押しながらグレネードを投げると、
    生成されたプロジェクタイルをVR Pickupで自動的に掴む。

    核心の仕組み:
    - pickup() / drop() はvrmod_pickup.luaでlocalなしで定義されたグローバル関数
    - vrmod.ServerPickup() でラップし、外部モジュールから安全に呼び出せるAPIを提供
    - OnEntityCreatedでプロジェクタイルを捕捉 → 手にテレポート → pickup()で直接ピックアップ
    - VR Pickupの既存ドロップ機構が手の速度を適用するため、投擲物理の実装は不要
]]

AddCSLuaFile()
if CLIENT then return end

-- ============================================================================
-- Constants
-- ============================================================================

local CAPTURE_WINDOW = 1.5 -- リリースからエンティティ捕捉までの最大待機秒数
local PROXIMITY_RADIUS_SQR = 300 * 300 -- フォールバックマッチング距離

-- ============================================================================
-- vrmod.ServerPickup / ServerDrop API
-- グローバルなpickup()/drop()の安全なラッパー。他モジュールからも利用可能。
-- ============================================================================

vrmod = vrmod or {}

--- サーバー側からVR Pickupを実行する
-- @param ply Player VRプレイヤー
-- @param bLeftHand boolean 左手でピックアップするか
-- @param handPos Vector 手のワールド座標
-- @param handAng Angle 手のワールド角度
-- @return boolean 成功/失敗（pickup()はreturnなしだが呼び出し可否を返す）
function vrmod.ServerPickup(ply, bLeftHand, handPos, handAng)
    -- pickup() はvrmod_pickup.luaのグローバル関数（localなし定義）
    if not pickup then return false end
    if not IsValid(ply) then return false end
    local steamid = ply:SteamID()
    if not g_VR or not g_VR[steamid] then return false end
    pickup(ply, bLeftHand, handPos, handAng)
    return true
end

--- サーバー側からVR Dropを実行する
-- @param ply Player VRプレイヤー
-- @param bLeftHand boolean 左手からドロップするか
-- @param handPos Vector 手のワールド座標
-- @param handAng Angle 手のワールド角度
-- @param handVel Vector 手のワールド速度
-- @param handAngVel Vector 手のワールド角速度
-- @return boolean 成功/失敗
function vrmod.ServerDrop(ply, bLeftHand, handPos, handAng, handVel, handAngVel)
    -- drop() はvrmod_pickup.luaのグローバル関数（localなし定義）
    if not drop then return false end
    if not IsValid(ply) then return false end
    local steamid = ply:SteamID()
    if not g_VR or not g_VR[steamid] then return false end
    drop(steamid, bLeftHand, handPos, handAng, handVel, handAngVel)
    return true
end

-- ============================================================================
-- Network
-- ============================================================================

util.AddNetworkString("vrmod_throw_autopickup_req")

-- ============================================================================
-- State
-- ============================================================================

local pendingAutoPickups = {} -- [steamid] = { time, isLeftHand, ply }

-- ============================================================================
-- Net Receive (rate limited)
-- ============================================================================

vrmod.NetReceiveLimited("vrmod_throw_autopickup_req", 5, 200, function(len, ply)
    local steamid = ply:SteamID()
    if not g_VR[steamid] then return end -- VRプレイヤーでなければ無視

    local isLeftHand = net.ReadBool()

    pendingAutoPickups[steamid] = {
        time = CurTime(),
        isLeftHand = isLeftHand,
        ply = ply,
    }
end)

-- ============================================================================
-- Entity Capture + Auto-Pickup (OnEntityCreated)
-- ============================================================================

hook.Add("OnEntityCreated", "vrmod_throw_autopickup_capture", function(ent)
    if not IsValid(ent) then return end
    if next(pendingAutoPickups) == nil then return end -- pendingが空なら即return

    -- 1フレーム待機（Spawn/Activate完了後）
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if next(pendingAutoPickups) == nil then return end

        -- フィルタ: プレイヤー、武器、worldspawnは除外
        if ent:IsPlayer() then return end
        if ent:IsWeapon() then return end
        local class = ent:GetClass()
        if class == "worldspawn" then return end

        local now = CurTime()
        local matchedSteamid = nil
        local pending = nil

        -- Method 1: Owner でマッチング（ARC-9/ArcCW等はOwner=player）
        local owner = ent:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            local steamid = owner:SteamID()
            local pd = pendingAutoPickups[steamid]
            if pd and (now - pd.time < CAPTURE_WINDOW) then
                matchedSteamid = steamid
                pending = pd
            end
        end

        -- Method 2: フォールバック — 近接距離 + タイミング
        if not matchedSteamid then
            for steamid, pd in pairs(pendingAutoPickups) do
                if (now - pd.time < CAPTURE_WINDOW) and IsValid(pd.ply) then
                    local distSqr = ent:GetPos():DistToSqr(pd.ply:GetPos())
                    if distSqr < PROXIMITY_RADIUS_SQR then
                        matchedSteamid = steamid
                        pending = pd
                        break
                    end
                end
            end
        end

        if not matchedSteamid or not pending then return end
        if not IsValid(pending.ply) then
            pendingAutoPickups[matchedSteamid] = nil
            return
        end

        -- 物理オブジェクト確認
        local phys = ent:GetPhysicsObject()
        if not IsValid(phys) then
            pendingAutoPickups[matchedSteamid] = nil
            return
        end

        -- VR手の位置・角度を取得（pcall保護）
        local isLeft = pending.isLeftHand
        local handPos, handAng
        local getPos = isLeft and vrmod.GetLeftHandPos or vrmod.GetRightHandPos
        local getAng = isLeft and vrmod.GetLeftHandAng or vrmod.GetRightHandAng

        local ok, pos = pcall(getPos, pending.ply)
        if ok and pos then
            handPos = pos
        else
            handPos = pending.ply:GetShootPos() -- フォールバック
        end

        local ok2, ang = pcall(getAng, pending.ply)
        if ok2 and ang then
            handAng = ang
        else
            handAng = pending.ply:EyeAngles() -- フォールバック
        end

        -- ============================================================
        -- ピックアップ準備
        -- ============================================================

        -- 1. 物理フリーズ（Module 14の速度適用を無効化）
        phys:EnableMotion(false)

        -- 2. 手にテレポート
        ent:SetPos(handPos)
        phys:SetPos(handPos)

        -- Note: コリジョングループは変更しない
        -- pickup()はshouldPickUp()/pickup_limitでコリジョングループをチェックしないため不要。
        -- 変更するとdrop()時の復元値が元のCOLLISION_GROUP_PROJECTILEではなく
        -- 変更後の値になってしまうバグが発生する。

        -- 消費: 1投擲 = 1捕捉
        pendingAutoPickups[matchedSteamid] = nil

        -- 4. 次フレームで物理再有効化 + pickup()呼出
        --    pickup()はMOVETYPE_VPHYSICSかつIsMoveable()をチェックするため、
        --    EnableMotion(true)してから呼ぶ必要がある
        local capturedPly = pending.ply
        local capturedIsLeft = isLeft
        timer.Simple(0, function()
            if not IsValid(ent) or not IsValid(capturedPly) then return end
            local p = ent:GetPhysicsObject()
            if not IsValid(p) then return end

            -- 物理再有効化 + 速度ゼロ
            p:EnableMotion(true)
            p:SetVelocity(Vector(0, 0, 0))
            p:SetAngles(handAng)
            p:Wake()

            -- MOVETYPE_VPHYSICS を保証（pickup_limit=1ではMoveTypeチェックあり）
            -- 一部の武器フレームワークでSpawn後にMoveTypeが変わる場合への安全策
            if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
                ent:SetMoveType(MOVETYPE_VPHYSICS)
            end

            -- 手の現在位置を再取得（1フレーム経過しているため）
            local currentHandPos, currentHandAng
            local ok3, pos3 = pcall(getPos, capturedPly)
            if ok3 and pos3 then
                currentHandPos = pos3
            else
                currentHandPos = handPos
            end
            local ok4, ang4 = pcall(getAng, capturedPly)
            if ok4 and ang4 then
                currentHandAng = ang4
            else
                currentHandAng = handAng
            end

            -- エンティティを最新の手の位置に再配置
            ent:SetPos(currentHandPos)
            p:SetPos(currentHandPos)

            -- ピックアップ実行
            vrmod.ServerPickup(capturedPly, capturedIsLeft, currentHandPos, currentHandAng)
        end)
    end)
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

-- 期限切れデータの定期削除
timer.Create("vrmod_throw_autopickup_cleanup", 1, 0, function()
    local now = CurTime()
    for steamid, data in pairs(pendingAutoPickups) do
        if now - data.time > CAPTURE_WINDOW then
            pendingAutoPickups[steamid] = nil
        end
    end
end)

-- VR終了時のクリーンアップ
hook.Add("VRMod_Exit", "vrmod_throw_autopickup_exit", function(ply)
    if IsValid(ply) then
        pendingAutoPickups[ply:SteamID()] = nil
    end
end)

-- 切断時のクリーンアップ
hook.Add("PlayerDisconnected", "vrmod_throw_autopickup_disconnect", function(ply)
    if IsValid(ply) then
        pendingAutoPickups[ply:SteamID()] = nil
    end
end)
