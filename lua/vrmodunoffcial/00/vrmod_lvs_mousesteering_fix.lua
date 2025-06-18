-- if CLIENT then
--     if not g_VR or not LVS then return end
    
--     local cv_vrMouseSteeringEnable = CreateClientConVar("vrmod_lvs_mousesteering", "1", true, FCVAR_ARCHIVE, "Enable VR mouse steering emulation for LVS vehicles")
--     local cv_vrMouseSteeringSensitivity = CreateClientConVar("vrmod_lvs_mousesteering_sensitivity", "1.5", true, FCVAR_ARCHIVE, "VR mouse steering sensitivity")
--     local cv_vrMouseSteeringDeadzone = CreateClientConVar("vrmod_lvs_mousesteering_deadzone", "5", true, FCVAR_ARCHIVE, "VR mouse steering deadzone in degrees")
    
--     local lastHandAngle = 0
--     local virtualMouseX = 0
--     local virtualMouseY = 0
    
--     hook.Add("CreateMove", "vrmod_lvs_mousesteering", function(cmd)
--         if not g_VR.active or not cv_vrMouseSteeringEnable:GetBool() then return end
        
--         local ply = LocalPlayer()
--         if not ply:InVehicle() then return end
        
--         local vehicle = ply:lvsGetVehicle()
--         if not IsValid(vehicle) then return end
        
--         if not ply:lvsMouseAim() then
--             LocalPlayer():ConCommand("lvs_mouseaim 1")
--         end
        
--         if IsValid(g_VR.tracking.pose_righthand) then
--             local handAng = g_VR.tracking.pose_righthand.ang
--             local vehicleAng = vehicle:GetAngles()
--             local relativeRoll = math.NormalizeAngle(handAng.r - vehicleAng.y)
            
--             local deadzone = cv_vrMouseSteeringDeadzone:GetFloat()
--             if math.abs(relativeRoll) < deadzone then
--                 relativeRoll = 0
--             else
--                 relativeRoll = relativeRoll - deadzone * (relativeRoll > 0 and 1 or -1)
--             end
            
--             local sensitivity = cv_vrMouseSteeringSensitivity:GetFloat()
--             local targetMouseX = relativeRoll * sensitivity
            
--             virtualMouseX = Lerp(0.3, virtualMouseX, targetMouseX)
            
--             cmd:SetMouseX(virtualMouseX)
--             cmd:SetMouseY(0)
--         end
--     end)
    
--     hook.Add("VRMod_Input", "vrmod_lvs_mousesteering_toggle", function(action, pressed)
--         if action == "boolean_reload" and pressed then
--             LocalPlayer():ConCommand("vrmod_lvs_mousesteering " .. (cv_vrMouseSteeringEnable:GetBool() and "0" or "1"))
            
--             local status = cv_vrMouseSteeringEnable:GetBool() and "Enabled" or "Disabled"
--             notification.AddLegacy("VR LVS Mouse Steering: " .. status, NOTIFY_GENERIC, 3)
--             surface.PlaySound("buttons/button14.wav")
--         end
--     end)
    
--     local function resetMouseSteering()
--         virtualMouseX = 0
--         virtualMouseY = 0
--         if LocalPlayer():lvsMouseAim() then
--             LocalPlayer():ConCommand("lvs_mouseaim 0")
--         end
--     end
    
--     hook.Add("LVS.PlayerLeaveVehicle", "vrmod_lvs_mousesteering_reset", function(ply, veh)
--         if ply == LocalPlayer() then
--             resetMouseSteering()
--         end
--     end)
    
--     hook.Add("VRMod_Exit", "vrmod_lvs_mousesteering_cleanup", function()
--         resetMouseSteering()
--     end)
    
--     concommand.Add("vrmod_lvs_mousesteering_debug", function()
--         hook.Add("HUDPaint", "vrmod_lvs_mousesteering_debug", function()
--             if not g_VR.active or not LocalPlayer():InVehicle() then return end
            
--             local vehicle = LocalPlayer():lvsGetVehicle()
--             if not IsValid(vehicle) then return end
            
--             local x, y = ScrW() * 0.5, ScrH() * 0.7
            
--             draw.SimpleText("VR LVS Mouse Steering Debug", "DermaLarge", x, y - 60, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--             draw.SimpleText("Mouse Steering: " .. (LocalPlayer():lvsMouseAim() and "ON" or "OFF"), "DermaDefault", x, y - 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--             draw.SimpleText("Virtual Mouse X: " .. math.Round(virtualMouseX, 2), "DermaDefault", x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            
--             if IsValid(g_VR.tracking.pose_righthand) then
--                 local handAng = g_VR.tracking.pose_righthand.ang
--                 draw.SimpleText("Right Hand Roll: " .. math.Round(handAng.r, 1), "DermaDefault", x, y + 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--             end
--         end)
        
--         timer.Simple(10, function()
--             hook.Remove("HUDPaint", "vrmod_lvs_mousesteering_debug")
--         end)
--     end)
-- end