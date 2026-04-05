--[[
    TIME CRISIS System ON VRmod — Server
    EntityTakeDamage hook for invincibility during cover mode.
    Compatible with both original and semiofficial VRMod.
]]

if not SERVER then return end

AddCSLuaFile("vrmod_timecrisis_cl.lua")
AddCSLuaFile("vrmod_timecrisis_menu.lua")

-- Network string
util.AddNetworkString("VRMod_TC_Cover")

-- Server-side ConVar: allows server owner to disable godmode feature
local cv_sv_enabled = CreateConVar("vrmod_unoff_tc_sv_enabled", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow Time Crisis godmode on this server", 0, 1)

-- Per-player cover state
local timeCrisisCover = {}

-- Rate limiting: prevent abuse (min 0.2s between toggles per player)
local lastToggleTime = {}
local RATE_LIMIT = 0.2

-- Helper: Check if player is in VR (works with both original and semiofficial)
local function IsPlayerInVR(ply)
    -- semiofficial / original: vrmod.IsPlayerInVR exists in both
    if vrmod and vrmod.IsPlayerInVR then
        return vrmod.IsPlayerInVR(ply)
    end
    -- Fallback: check g_VR network table
    if g_VR and g_VR[ply:SteamID()] then
        return true
    end
    return false
end

net.Receive("VRMod_TC_Cover", function(len, ply)
    if not IsValid(ply) then return end
    if not cv_sv_enabled:GetBool() then return end

    -- Rate limit
    local now = CurTime()
    if lastToggleTime[ply] and (now - lastToggleTime[ply]) < RATE_LIMIT then
        return
    end
    lastToggleTime[ply] = now

    local inCover = net.ReadBool()

    -- Server-side validation: player must actually be in VR
    if not IsPlayerInVR(ply) then
        timeCrisisCover[ply] = nil
        return
    end

    -- Server-side validation: if claiming cover, verify player is actually crouching
    if inCover and not ply:Crouching() then
        return
    end

    timeCrisisCover[ply] = inCover
end)

-- Block damage when player is in cover
hook.Add("EntityTakeDamage", "VRMod_TimeCrisis_Godmode", function(target, dmginfo)
    if not cv_sv_enabled:GetBool() then return end
    if not target:IsPlayer() then return end
    if timeCrisisCover[target] then
        -- Extra safety: if player is no longer crouching, revoke cover
        if not target:Crouching() then
            timeCrisisCover[target] = nil
            return
        end
        return true -- Cancel all damage
    end
end)

-- Cleanup on disconnect
hook.Add("PlayerDisconnected", "VRMod_TimeCrisis_Disconnect", function(ply)
    timeCrisisCover[ply] = nil
    lastToggleTime[ply] = nil
end)
