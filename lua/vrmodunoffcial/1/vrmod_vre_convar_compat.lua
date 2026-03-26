AddCSLuaFile()
if SERVER then return end

--[[
    VRE ConVar Compatibility Bridge

    VRE Dynamic Menu (vre_dynamic_menu_darkrp_sandbox) uses vrutil_* ConVar names
    from the original VRMod. Semiofficial renamed these to vrmod_*.
    This module creates vrutil_* aliases with callback-based bidirectional sync.

    Design: zero polling, zero per-frame cost.
    - Phase 1 (immediate): Create vrutil_* ConVars so GetConVar() never returns nil
    - Phase 2 (deferred):  Set up bidirectional sync after vrmod_* ConVars exist
]]

-- vrutil_name -> vrmod_name mapping
local CONVAR_BRIDGE = {
    { vrutil = "vrutil_althead",            vrmod = "vrmod_althead",            default = "1" },
    { vrutil = "vrutil_autostart",          vrmod = "vrmod_autostart",          default = "0" },
    { vrutil = "vrutil_desktopview",        vrmod = "vrmod_desktopview",        default = "3" },
    { vrutil = "vrutil_useworldmodels",     vrmod = "vrmod_useworldmodels",     default = "0" },
    { vrutil = "vrutil_laserpointer",       vrmod = "vrmod_laserpointer",       default = "0" },
    { vrutil = "vrutil_controlleroriented", vrmod = "vrmod_controlleroriented", default = "0" },
    { vrutil = "vrutil_smoothturn",         vrmod = "vrmod_smoothturn",         default = "0" },
    { vrutil = "vrutil_znear",              vrmod = "vrmod_znear",              default = "6" },
}

-- Stub ConVars: no equivalent in semiofficial, but must exist to prevent nil errors
local CONVAR_STUBS = {
    { name = "vrutil_hidecharacter", default = "0" },
    { name = "vrutil_userheight",    default = "66.8" },
}

-- Phase 1: Create vrutil_* ConVars immediately (prevents GetConVar() nil crash)
local bridgeCreated = 0
for _, entry in ipairs(CONVAR_BRIDGE) do
    if not GetConVar(entry.vrutil) then
        CreateConVar(entry.vrutil, entry.default, FCVAR_ARCHIVE, "VRE compat: alias for " .. entry.vrmod)
        bridgeCreated = bridgeCreated + 1
    end
end

for _, entry in ipairs(CONVAR_STUBS) do
    if not GetConVar(entry.name) then
        CreateConVar(entry.name, entry.default, FCVAR_ARCHIVE, "VRE compat: stub (no-op in semiofficial)")
    end
end

-- Phase 2: Deferred sync setup (vrmod_* ConVars are created in root files, which load after folder 1)
timer.Simple(0, function()
    local syncing = false
    local syncCount = 0

    for _, entry in ipairs(CONVAR_BRIDGE) do
        local vrmod_cv = GetConVar(entry.vrmod)
        local vrutil_cv = GetConVar(entry.vrutil)

        if vrmod_cv and vrutil_cv then
            -- Initial value sync: vrmod -> vrutil
            RunConsoleCommand(entry.vrutil, vrmod_cv:GetString())

            -- Callback: vrutil -> vrmod (when VRE changes a setting)
            cvars.AddChangeCallback(entry.vrutil, function(_, _, new)
                if syncing then return end
                syncing = true
                RunConsoleCommand(entry.vrmod, new)
                syncing = false
            end, "vre_compat")

            -- Callback: vrmod -> vrutil (when semiofficial changes a setting)
            cvars.AddChangeCallback(entry.vrmod, function(_, _, new)
                if syncing then return end
                syncing = true
                RunConsoleCommand(entry.vrutil, new)
                syncing = false
            end, "vre_compat")

            syncCount = syncCount + 1
        end
    end

    if syncCount > 0 then
        print("[VRMod SemiOffcial] VRE compat bridge: " .. syncCount .. " ConVar aliases synced")
    end
end)
