
--------[vrmod_glideinput.lua]Start--------
if not Glide then return end
if not g_VR then return end
if CLIENT then
    local function isGroundVehicle(vehicle)
        if not IsValid(vehicle) then return false end
        local vType = vehicle.VehicleType
        return vType == Glide.VEHICLE_TYPE.CAR or
               vType == Glide.VEHICLE_TYPE.MOTORCYCLE or
               vType == Glide.VEHICLE_TYPE.TANK
    end
    local cv_rightHandle = CreateClientConVar("glide_vr_righthandle", "0", true, nil)
    local cv_leftHandle = CreateClientConVar("glide_vr_lefthandle", "0", true, nil)
    local cv_handbrake = CreateClientConVar("glide_vr_handbrake", "0", true, nil)
    local cv_headlights = CreateClientConVar("glide_vr_headlights", "0", true, nil)
    local cv_horn = CreateClientConVar("glide_vr_horn", "0", true, nil)
    local cv_reducedThrottle = CreateClientConVar("glide_vr_reduced_throttle", "0", true, nil)
    local VR_CONTROLS = {
        ["boolean_forword"] = "shift_up",
        ["boolean_back"] = "shift_down",
        ["boolean_right_pickup"] = "righthandle",
        ["boolean_left_pickup"] = "lefthandle",
        ["boolean_left"] = "shift_neutral",
        ["boolean_handbrake"] = "handbrake",
        ["boolean_flashlight"] = "headlights",
        ["boolean_turbo"] = "horn",
        ["boolean_reload"] = "reduce_throttle",
        ["boolean_spawnmenu"] = "switch_weapon"
    }
    hook.Add("VRMod_Input", "glide_vr_input", function(action, pressed)
        if not g_VR.active then return end
        local vehicle = LocalPlayer():GetNWEntity("GlideVehicle")
        if not isGroundVehicle(vehicle) then return end
        local control = VR_CONTROLS[action]
        if control then
            LocalPlayer():ConCommand(pressed and "glide_vr_" .. control .. " 1" or "glide_vr_" .. control .. " 0")
        end
    end)

    local lastGlideSentTime = 0
    local glideSendInterval = 0.05 -- 50msごと

    hook.Add("Think", "glide_vr_update", function()
        if not g_VR or not g_VR.active or not g_VR.input then return end -- g_VR.input のチェックを追加
        local vehicle = LocalPlayer():GetNWEntity("GlideVehicle")
        -- isGroundVehicle のチェックは適切か確認 (元のコードでは Think フックの先頭にあった)
        if not isGroundVehicle(vehicle) or not g_VR.net[LocalPlayer():SteamID()] then return end

        local now = CurTime()
        if now - lastGlideSentTime > glideSendInterval then
            local steeringInput = 0
            local cv_rightHandle = GetConVar("glide_vr_righthandle")
            local cv_leftHandle = GetConVar("glide_vr_lefthandle")
            if cv_rightHandle and cv_leftHandle then -- ConVarオブジェクトの存在チェック
                if cv_rightHandle:GetBool() then
                    steeringInput = g_VR.tracking.pose_righthand.ang.z * 0.01
                elseif cv_leftHandle:GetBool() then
                    steeringInput = g_VR.tracking.pose_lefthand.ang.z * 0.01
                end
            end

            -- g_VR.input の nil チェックを追加
            local forward = g_VR.input.vector1_forward or 0
            local reverse = g_VR.input.vector1_reverse or 0
            local boolean_forward = g_VR.input.boolean_forword or false
            local boolean_back = g_VR.input.boolean_back or false
            local boolean_left = g_VR.input.boolean_left or false
            local boolean_spawnmenu = g_VR.input.boolean_spawnmenu or false

            -- cv_ ConVar の nil チェックを追加 (より安全に)
            local cv_handbrake_val = GetConVar("glide_vr_handbrake") and GetConVar("glide_vr_handbrake"):GetBool() or false
            local cv_headlights_val = GetConVar("glide_vr_headlights") and GetConVar("glide_vr_headlights"):GetBool() or false
            local cv_horn_val = GetConVar("glide_vr_horn") and GetConVar("glide_vr_horn"):GetBool() or false
            local cv_reducedThrottle_val = GetConVar("glide_vr_reduced_throttle") and GetConVar("glide_vr_reduced_throttle"):GetBool() or false

            net.Start("glide_vr_input")
                net.WriteFloat(forward)
                net.WriteFloat(reverse)
                net.WriteFloat(steeringInput)
                net.WriteBool(cv_handbrake_val)
                net.WriteBool(cv_headlights_val)
                net.WriteBool(cv_horn_val)
                net.WriteBool(cv_reducedThrottle_val)
                net.WriteBool(boolean_forward)
                net.WriteBool(boolean_back)
                net.WriteBool(boolean_left)
                net.WriteBool(boolean_spawnmenu)
            net.SendToServer()
            lastGlideSentTime = now
        end
    end)
elseif SERVER then
    util.AddNetworkString("glide_vr_input")
    net.Receive("glide_vr_input", function(len, ply)
        local vehicle = ply:GetNWEntity("GlideVehicle")
        if not IsValid(vehicle) then return end
        local vType = vehicle.VehicleType
        if vType ~= Glide.VEHICLE_TYPE.CAR and
           vType ~= Glide.VEHICLE_TYPE.MOTORCYCLE and
           vType ~= Glide.VEHICLE_TYPE.TANK then
            return
        end
        local throttle = net.ReadFloat()
        local brake = net.ReadFloat()
        local steering = net.ReadFloat()
        local handbrake = net.ReadBool()
        local headlights = net.ReadBool()
        local horn = net.ReadBool()
        local reducedThrottle = net.ReadBool()
        local shiftUp = net.ReadBool()
        local shiftDown = net.ReadBool()
        local shiftNeutral = net.ReadBool()
        local switchWeapon = net.ReadBool()
        vehicle:SetInputFloat(1, "accelerate", throttle)
        vehicle:SetInputFloat(1, "brake", brake)
        vehicle:SetInputFloat(1, "steer", steering)
        vehicle:SetInputBool(1, "handbrake", handbrake)
        vehicle:SetInputBool(1, "horn", horn)
        vehicle:SetInputBool(1, "reduce_throttle", reducedThrottle)
        if shiftUp then
            vehicle:SetInputBool(1, "shift_up", true)
        elseif shiftDown then
            vehicle:SetInputBool(1, "shift_down", true)
        elseif shiftNeutral then
            vehicle:SetInputBool(1, "shift_neutral", true)
        end
        if switchWeapon then
            vehicle:SetInputBool(1, "switch_weapon", true)
        end
        if headlights ~= (vehicle:GetHeadlightState() > 0) then
            vehicle:ChangeHeadlightState(headlights and 2 or 0)
        end
    end)
end
--------[vrmod_glideinput.lua]End--------