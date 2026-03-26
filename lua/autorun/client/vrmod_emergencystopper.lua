-- hook.Add("VRMod_Menu", "AddEmergencyStopSettings", function(frame)
--     -- Add a tab for Emergency Stop Settings
--     local emergencyStopPanel = vgui.Create("DPanel", frame.DPropertySheet)
--     frame.DPropertySheet:AddSheet("VR STOP Key", emergencyStopPanel)
--     emergencyStopPanel.Paint = function(self, w, h)
--         draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
--     end

--     -- Emergency stop key selection using DBinder
--     local emergencyStopKeyBinder = vgui.Create("DBinder", emergencyStopPanel)
--     emergencyStopKeyBinder:SetPos(20, 30)
--     emergencyStopKeyBinder:SetSize(200, 30)
--     emergencyStopKeyBinder:SetConVar("vrmod_emergencystop_key")

--     -- Time to hold the key for Emergency Stop
--     local emergencyStopTime = vgui.Create("DNumSlider", emergencyStopPanel)
--     emergencyStopTime:SetPos(20, 70)
--     emergencyStopTime:SetSize(390, 40)
--     emergencyStopTime:SetText("Time to Hold Key (Seconds)")
--     emergencyStopTime:SetMin(1)
--     emergencyStopTime:SetMax(10)
--     emergencyStopTime:SetDecimals(1)
--     emergencyStopTime:SetConVar("vrmod_emergencystop_time")
-- end)

-- Create ConVars for emergency stop
CreateClientConVar("vrmod_emergencystop_key", KEY_F3, true, FCVAR_ARCHIVE, "Key for VR Emergency Stop")
CreateClientConVar("vrmod_emergencystop_time", 0.0, true, FCVAR_ARCHIVE, "Time to hold the key for VR Emergency Stop (in seconds)")

-- Low FPS emergency exit ConVars
CreateClientConVar("vrmod_unoff_emergency_fps_enabled", "1", true, FCVAR_ARCHIVE, "Enable low FPS emergency VR exit", 0, 1)
CreateClientConVar("vrmod_unoff_emergency_fps_threshold", "5", true, FCVAR_ARCHIVE, "FPS threshold for emergency exit", 1, 30)
CreateClientConVar("vrmod_unoff_emergency_fps_duration", "2", true, FCVAR_ARCHIVE, "Seconds below threshold before emergency exit", 0, 15)

-- ConVar cache (avoid GetConVar() every frame)
local cv_stopKey, cv_stopTime
local cv_fpsEnabled, cv_fpsThreshold, cv_fpsDuration

local function ensureConVars()
    if not cv_stopKey then
        cv_stopKey = GetConVar("vrmod_emergencystop_key")
        cv_stopTime = GetConVar("vrmod_emergencystop_time")
        cv_fpsEnabled = GetConVar("vrmod_unoff_emergency_fps_enabled")
        cv_fpsThreshold = GetConVar("vrmod_unoff_emergency_fps_threshold")
        cv_fpsDuration = GetConVar("vrmod_unoff_emergency_fps_duration")
    end
    return cv_stopKey ~= nil
end

-- Emergency Stop functionality
local keyDownTime = nil
local lowFpsSince = nil

hook.Add("Think", "VRMod_EmergencyStop", function()
    if not ensureConVars() then return end
    if not vrmod.IsPlayerInVR(LocalPlayer()) then
        keyDownTime = nil
        lowFpsSince = nil
        return
    end

    -- Key hold emergency stop (existing)
    if input.IsKeyDown(cv_stopKey:GetInt()) then
        if not keyDownTime then
            keyDownTime = CurTime()
        elseif CurTime() - keyDownTime >= cv_stopTime:GetFloat() then
            VRUtilClientExit()
            print("[VRMod] VR mode has been emergency stopped. (key)")
            keyDownTime = nil
            lowFpsSince = nil
            return
        end
    else
        keyDownTime = nil
    end

    -- Low FPS emergency exit
    if not cv_fpsEnabled:GetBool() then
        lowFpsSince = nil
        return
    end

    local ft = FrameTime()
    -- FrameTime can be 0 on first frame or during loading
    if ft <= 0 then
        lowFpsSince = nil
        return
    end

    local currentFPS = 1 / ft
    local threshold = cv_fpsThreshold:GetFloat()

    if currentFPS < threshold then
        if not lowFpsSince then
            lowFpsSince = SysTime()
        elseif SysTime() - lowFpsSince >= cv_fpsDuration:GetFloat() then
            VRUtilClientExit()
            print("[VRMod] VR mode emergency stopped! FPS was below " .. threshold .. " for " .. cv_fpsDuration:GetFloat() .. "s")
            lowFpsSince = nil
            keyDownTime = nil
        end
    else
        lowFpsSince = nil
    end
end)
