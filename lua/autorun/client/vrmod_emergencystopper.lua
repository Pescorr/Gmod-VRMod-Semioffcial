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
CreateClientConVar("vrmod_emergencystop_key", KEY_L, true, FCVAR_ARCHIVE, "Key for VR Emergency Stop")
CreateClientConVar("vrmod_emergencystop_time", 0.1, true, FCVAR_ARCHIVE, "Time to hold the key for VR Emergency Stop (in seconds)")

-- Emergency Stop functionality
local keyDownTime = nil
hook.Add("Think", "VRMod_EmergencyStop", function()
    if vrmod.IsPlayerInVR(LocalPlayer()) then
        if input.IsKeyDown(GetConVar("vrmod_emergencystop_key"):GetInt()) then
            if not keyDownTime then
                keyDownTime = CurTime()
            elseif CurTime() - keyDownTime >= GetConVar("vrmod_emergencystop_time"):GetFloat() then
                VRUtilClientExit()
                print("VR mode has been emergency stopped.")
                keyDownTime = nil
            end
        else
            keyDownTime = nil
        end
    end
end)
