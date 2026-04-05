--[[
    Module 14: VR Throw — Server Side
    エンティティ捕捉方式: 武器が生成したプロジェクタイルを捕捉し、
    VR手の速度・位置で上書きする。
]]

AddCSLuaFile()
if CLIENT then return end

-- ============================================================================
-- Constants
-- ============================================================================

local THROW_WINDOW = 1.5 -- リリースからエンティティ捕捉までの最大待機秒数
local MAX_VELOCITY = 10000 -- アンチチート: 速度上限
local PROXIMITY_RADIUS_SQR = 300 * 300 -- フォールバックマッチング距離（300ユニット）

-- ============================================================================
-- Network
-- ============================================================================

util.AddNetworkString("vrmod_throw_fire")

-- ============================================================================
-- State
-- ============================================================================

local pendingThrows = {} -- [steamid] = { time, handPos, handVel, handAngVel, ply }

-- ============================================================================
-- Net Receive (rate limited)
-- ============================================================================

vrmod.NetReceiveLimited("vrmod_throw_fire", 5, 200, function(len, ply)
    local steamid = ply:SteamID()
    if not g_VR[steamid] then return end -- VRプレイヤーでなければ無視

    local isLeftHand = net.ReadBool()
    local handVel = net.ReadVector()
    local handAngVel = net.ReadVector()

    -- アンチチート: 速度上限チェック
    if handVel:Length() > MAX_VELOCITY then return end

    -- サーバー側で手の位置を取得（pcall保護）
    local handPos
    local getHandPos = isLeftHand and vrmod.GetLeftHandPos or vrmod.GetRightHandPos
    local ok, pos = pcall(getHandPos, ply)
    if ok and pos then
        handPos = pos
    else
        handPos = ply:GetShootPos() -- フォールバック
    end

    pendingThrows[steamid] = {
        time = CurTime(),
        handPos = handPos,
        handVel = handVel,
        handAngVel = handAngVel,
        ply = ply,
    }
end)

-- ============================================================================
-- Entity Capture (OnEntityCreated)
-- ============================================================================

hook.Add("OnEntityCreated", "vrmod_throw_capture", function(ent)
    if not IsValid(ent) then return end
    if next(pendingThrows) == nil then return end -- pendingが空なら即return

    -- 1フレーム待機（エンティティ初期化完了待ち）
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if next(pendingThrows) == nil then return end

        -- フィルタ: プレイヤー、武器、worldspawnは除外
        if ent:IsPlayer() then return end
        if ent:IsWeapon() then return end
        local class = ent:GetClass()
        if class == "worldspawn" then return end

        local now = CurTime()
        local matchedSteamid = nil
        local throwData = nil

        -- Method 1: Owner でマッチング
        local owner = ent:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            local steamid = owner:SteamID()
            local pd = pendingThrows[steamid]
            if pd and (now - pd.time < THROW_WINDOW) then
                matchedSteamid = steamid
                throwData = pd
            end
        end

        -- Method 2: フォールバック — 近接距離 + タイミング
        if not matchedSteamid then
            for steamid, pd in pairs(pendingThrows) do
                if (now - pd.time < THROW_WINDOW) and IsValid(pd.ply) then
                    local distSqr = ent:GetPos():DistToSqr(pd.ply:GetPos())
                    if distSqr < PROXIMITY_RADIUS_SQR then
                        matchedSteamid = steamid
                        throwData = pd
                        break
                    end
                end
            end
        end

        if not matchedSteamid or not throwData then return end
        if not IsValid(throwData.ply) then
            pendingThrows[matchedSteamid] = nil
            return
        end

        -- 速度適用（vrmod_pickup.lua:111-112 パターン）
        ent:SetPos(throwData.handPos)

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetPos(throwData.handPos)
            phys:SetVelocity(throwData.ply:GetVelocity() + throwData.handVel)
            phys:AddAngleVelocity(
                -phys:GetAngleVelocity()
                + phys:WorldToLocalVector(throwData.handAngVel)
            )
            phys:Wake()
        else
            ent:SetVelocity(throwData.handVel)
        end

        -- 消費: 1投擲 = 1捕捉
        pendingThrows[matchedSteamid] = nil
    end)
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

-- 期限切れデータの定期削除
timer.Create("vrmod_throw_cleanup", 1, 0, function()
    local now = CurTime()
    for steamid, data in pairs(pendingThrows) do
        if now - data.time > THROW_WINDOW then
            pendingThrows[steamid] = nil
        end
    end
end)

-- VR終了時 / 切断時のクリーンアップ
hook.Add("VRMod_Exit", "vrmod_throw_sv_exit", function(ply)
    if IsValid(ply) then
        pendingThrows[ply:SteamID()] = nil
    end
end)

hook.Add("PlayerDisconnected", "vrmod_throw_sv_disconnect", function(ply)
    if IsValid(ply) then
        pendingThrows[ply:SteamID()] = nil
    end
end)
