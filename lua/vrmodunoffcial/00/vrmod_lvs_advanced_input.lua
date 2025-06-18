-- if CLIENT then
--     if not g_VR or not LVS then return end
    
--     local cv_handSteeringMode = CreateClientConVar("vrmod_lvs_handsteering_mode", "1", true, FCVAR_ARCHIVE, "Hand steering mode: 0=off, 1=right, 2=left, 3=both")
--     local cv_steeringMethod = CreateClientConVar("vrmod_lvs_steering_method", "1", true, FCVAR_ARCHIVE, "Steering method: 1=roll, 2=yaw, 3=position")
--     local cv_returnToCenter = CreateClientConVar("vrmod_lvs_return_center", "1", true, FCVAR_ARCHIVE, "Auto return steering to center")
--     local cv_returnSpeed = CreateClientConVar("vrmod_lvs_return_speed", "2", true, FCVAR_ARCHIVE, "Steering return to center speed")
    
--     local steeringInput = 0
--     local lastValidInput = 0
--     local gripStartAngle = nil
--     local gripStartSteering = 0
    
--     local function getHandSteeringInput()
--         local mode = cv_handSteeringMode:GetInt()
--         if mode == 0 then return 0 end
        
--         local method = cv_steeringMethod:GetInt()
--         local input = 0
        
--         if mode == 1 or mode == 3 then
--             if IsValid(g_VR.tracking.pose_righthand) then
--                 if method == 1 then
--                     local roll = g_VR.tracking.pose_righthand.ang.r
--                     input = math.Clamp(roll / 45, -1, 1)
--                 elseif method == 2 then
--                     local yaw = math.NormalizeAngle(g_VR.tracking.pose_righthand.ang.y)
--                     input = math.Clamp(yaw / 90, -1, 1)
--                 elseif method == 3 then
--                     local relPos = g_VR.tracking.pose_righthand.pos - g_VR.tracking.hmd.pos
--                     input = math.Clamp(relPos.y / 20, -1, 1)
--                 end
--             end
--         end
        
--         if mode == 2 or mode == 3 then
--             if IsValid(g_VR.tracking.pose_lefthand) then
--                 local leftInput = 0
--                 if method == 1 then
--                     local roll = g_VR.tracking.pose_lefthand.ang.r
--                     leftInput = math.Clamp(-roll / 45, -1, 1)
--                 elseif method == 2 then
--                     local yaw = math.NormalizeAngle(g_VR.tracking.pose_lefthand.ang.y)
--                     leftInput = math.Clamp(-yaw / 90, -1, 1)
--                 elseif method == 3 then
--                     local relPos = g_VR.tracking.pose_lefthand.pos - g_VR.tracking.hmd.pos
--                     leftInput = math.Clamp(-relPos.y / 20, -1, 1)
--                 end
                
--                 if mode == 3 then
--                     input = (input + leftInput) / 2
--                 else
--                     input = leftInput
--                 end
--             end
--         end
        
--         return input
--     end
    
--     local function updateVirtualSteering()
--         local targetInput = getHandSteeringInput()
        
--         if cv_returnToCenter:GetBool() and math.abs(targetInput) < 0.1 then
--             local returnSpeed = cv_returnSpeed:GetFloat()
--             steeringInput = Lerp(FrameTime() * returnSpeed, steeringInput, 0)
--         else
--             steeringInput = Lerp(0.3, steeringInput, targetInput)
--         end
        
--         return steeringInput
--     end
    
--     hook.Add("CreateMove", "vrmod_lvs_advanced_steering", function(cmd)
--         if not g_VR.active then return end
        
--         local ply = LocalPlayer()
--         if not ply:InVehicle() then 
--             steeringInput = 0
--             return 
--         end
        
--         local vehicle = ply:lvsGetVehicle()
--         if not IsValid(vehicle) then return end
        
--         local wheelDriveVehicle = string.find(vehicle:GetClass(), "wheeldrive")
--         if not wheelDriveVehicle then return end
        
--         local steering = updateVirtualSteering()
--         local virtualMouseX = steering * 50
        
--         if cv_handSteeringMode:GetInt() > 0 then
--             if not ply:lvsMouseAim() then
--                 LocalPlayer():ConCommand("lvs_mouseaim 1")
--             end
--             cmd:SetMouseX(virtualMouseX)
--         end
--     end)
    
--     hook.Add("VRMod_Input", "vrmod_lvs_grip_steering", function(action, pressed)
--         if not g_VR.active then return end
        
--         if action == "boolean_left_pickup" or action == "boolean_right_pickup" then
--             if pressed then
--                 gripStartSteering = steeringInput
--                 if action == "boolean_right_pickup" and IsValid(g_VR.tracking.pose_righthand) then
--                     gripStartAngle = g_VR.tracking.pose_righthand.ang.r
--                 elseif action == "boolean_left_pickup" and IsValid(g_VR.tracking.pose_lefthand) then
--                     gripStartAngle = g_VR.tracking.pose_lefthand.ang.r
--                 end
--             else
--                 gripStartAngle = nil
--             end
--         end
--     end)
    
--     concommand.Add("vrmod_lvs_steering_menu", function()
--         local frame = vgui.Create("DFrame")
--         frame:SetTitle("VR LVS Steering Settings")
--         frame:SetSize(400, 300)
--         frame:Center()
--         frame:MakePopup()
        
--         local y = 30
        
--         local modeLabel = vgui.Create("DLabel", frame)
--         modeLabel:SetPos(10, y)
--         modeLabel:SetText("Hand Steering Mode:")
--         modeLabel:SizeToContents()
        
--         local modeCombo = vgui.Create("DComboBox", frame)
--         modeCombo:SetPos(150, y)
--         modeCombo:SetSize(200, 20)
--         modeCombo:SetValue(cv_handSteeringMode:GetInt() == 0 and "Disabled" or 
--                           cv_handSteeringMode:GetInt() == 1 and "Right Hand" or
--                           cv_handSteeringMode:GetInt() == 2 and "Left Hand" or "Both Hands")
--         modeCombo:AddChoice("Disabled", 0)
--         modeCombo:AddChoice("Right Hand", 1)
--         modeCombo:AddChoice("Left Hand", 2)
--         modeCombo:AddChoice("Both Hands", 3)
--         modeCombo.OnSelect = function(self, index, value, data)
--             cv_handSteeringMode:SetInt(data)
--         end
        
--         y = y + 30
        
--         local methodLabel = vgui.Create("DLabel", frame)
--         methodLabel:SetPos(10, y)
--         methodLabel:SetText("Steering Method:")
--         methodLabel:SizeToContents()
        
--         local methodCombo = vgui.Create("DComboBox", frame)
--         methodCombo:SetPos(150, y)
--         methodCombo:SetSize(200, 20)
--         methodCombo:SetValue(cv_steeringMethod:GetInt() == 1 and "Roll (Twist)" or
--                             cv_steeringMethod:GetInt() == 2 and "Yaw (Turn)" or "Position")
--         methodCombo:AddChoice("Roll (Twist)", 1)
--         methodCombo:AddChoice("Yaw (Turn)", 2)
--         methodCombo:AddChoice("Position", 3)
--         methodCombo.OnSelect = function(self, index, value, data)
--             cv_steeringMethod:SetInt(data)
--         end
        
--         y = y + 30
        
--         local returnCheck = vgui.Create("DCheckBoxLabel", frame)
--         returnCheck:SetPos(10, y)
--         returnCheck:SetText("Auto Return to Center")
--         returnCheck:SetValue(cv_returnToCenter:GetBool())
--         returnCheck:SizeToContents()
--         returnCheck.OnChange = function(self, val)
--             cv_returnToCenter:SetBool(val)
--         end
        
--         y = y + 30
        
--         local returnSpeedLabel = vgui.Create("DLabel", frame)
--         returnSpeedLabel:SetPos(10, y)
--         returnSpeedLabel:SetText("Return Speed:")
--         returnSpeedLabel:SizeToContents()
        
--         local returnSpeedSlider = vgui.Create("DSlider", frame)
--         returnSpeedSlider:SetPos(150, y)
--         returnSpeedSlider:SetSize(200, 20)
--         returnSpeedSlider:SetMin(0.5)
--         returnSpeedSlider:SetMax(5)
--         returnSpeedSlider:SetValue(cv_returnSpeed:GetFloat())
--         returnSpeedSlider.OnValueChanged = function(self, val)
--             cv_returnSpeed:SetFloat(val)
--         end
--     end)
    
--     local function drawSteeringHUD()
--         if not g_VR.active or not LocalPlayer():InVehicle() then return end
        
--         local vehicle = LocalPlayer():lvsGetVehicle()
--         if not IsValid(vehicle) then return end
        
--         local x, y = ScrW() * 0.5, ScrH() * 0.8
--         local width = 200
--         local height = 20
        
--         surface.SetDrawColor(0, 0, 0, 128)
--         surface.DrawRect(x - width/2, y - height/2, width, height)
        
--         surface.SetDrawColor(255, 255, 255, 255)
--         surface.DrawOutlinedRect(x - width/2, y - height/2, width, height)
        
--         local steerPos = x + (steeringInput * (width/2 - 10))
--         surface.SetDrawColor(255, 100, 100, 255)
--         surface.DrawRect(steerPos - 5, y - height/2 + 2, 10, height - 4)
        
--         draw.SimpleText("Steering", "DermaDefault", x, y - height, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
--     end
    
--     concommand.Add("vrmod_lvs_steering_hud", function()
--         if hook.GetTable()["HUDPaint"] and hook.GetTable()["HUDPaint"]["vrmod_lvs_steering_hud"] then
--             hook.Remove("HUDPaint", "vrmod_lvs_steering_hud")
--             notification.AddLegacy("Steering HUD: OFF", NOTIFY_GENERIC, 2)
--         else
--             hook.Add("HUDPaint", "vrmod_lvs_steering_hud", drawSteeringHUD)
--             notification.AddLegacy("Steering HUD: ON", NOTIFY_GENERIC, 2)
--         end
--     end)
-- end