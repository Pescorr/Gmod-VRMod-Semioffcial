-- VRMod Semi-Official Addon Plus - Auto Seat Reset
-- 車両/椅子に座った時の自動シートモードリセット機能
-- Version 1.0

if SERVER then return end

-----------------------------------------------------------
-- ConVar Creation
-----------------------------------------------------------

CreateClientConVar("vrmod_auto_seat_reset", "1", true, false,
    "Automatically disable seat mode and reset vehicle view when entering a vehicle", 0, 1)

-----------------------------------------------------------
-- Local Variables
-----------------------------------------------------------

local lastVehicleState = false

-----------------------------------------------------------
-- Core Functionality
-----------------------------------------------------------

-- Check if player is in vehicle (works in both singleplayer and multiplayer)
local function IsPlayerInVehicle()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    return ply:InVehicle()
end

-- Execute seat reset actions
local function ExecuteSeatReset()
    -- Check if feature is enabled
    local cvar = GetConVar("vrmod_auto_seat_reset")
    if not cvar or not cvar:GetBool() then return end

    -- Disable seat mode
    local seatCvar = GetConVar("vrmod_seated")
    if seatCvar then
        RunConsoleCommand("vrmod_seated", "0")
    end

    -- Reset vehicle view via g_VR.menuItems (there is no ConCommand for this;
    -- the reset function is registered as an in-game menu item by the locomotion module)
    timer.Simple(0.1, function()
        if not g_VR or not g_VR.menuItems then return end
        for i = 1, #g_VR.menuItems do
            if g_VR.menuItems[i].name == "Reset Vehicle View" then
                g_VR.menuItems[i].func()
                return
            end
        end
    end)
end

-----------------------------------------------------------
-- Vehicle Detection Hook
-----------------------------------------------------------

-- Using Think hook for reliable cross-realm detection
-- This works in both singleplayer and multiplayer
hook.Add("Think", "VRMod_AutoSeatReset_VehicleCheck", function()
    -- Skip if VR is not active
    if not g_VR or not g_VR.active then
        lastVehicleState = false
        return
    end

    local currentState = IsPlayerInVehicle()

    -- Detect transition from not-in-vehicle to in-vehicle
    if currentState and not lastVehicleState then
        ExecuteSeatReset()
    end

    lastVehicleState = currentState
end)

-- Alternative: Hook into GMod's built-in vehicle enter event (if available client-side)
hook.Add("PlayerEnteredVehicle", "VRMod_AutoSeatReset", function(ply, vehicle)
    if ply ~= LocalPlayer() then return end
    if not g_VR or not g_VR.active then return end

    ExecuteSeatReset()
end)

print("[VRMod] Auto Seat Reset loaded")
