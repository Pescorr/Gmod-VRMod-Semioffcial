
--------[vrmod_simfphysremix.lua]Start--------
if CLIENT then
    hook.Add("VRE_simphys_Overrides","vre_simfphysfix_override",function()
        if LocalPlayer():InVehicle() then
            hook.Remove("CreateMove","vre_simfphysfix")
            end
    end)
    hook.Add("VRMod_Input","vre_onlocomotion_action",function( action, pressed )
            if action == "boolean_right_pickup" then
                LocalPlayer():ConCommand(pressed and "vrmod_test_Righthandle 1" or "vrmod_test_Righthandle 0")
                return
            end
            if action == "boolean_left_pickup" then
                LocalPlayer():ConCommand(pressed and "vrmod_test_lefthandle 1" or "vrmod_test_lefthandle 0")
                return
            end
    end)

    local lastSimfphysSentTime = 0
    local simfphysSendInterval = 0.05 -- 50msごと

    hook.Add("Think", "vre_simfphysfix_remix_think", function()
        if not g_VR or not g_VR.active or not g_VR.input or not LocalPlayer():InVehicle() then return end
        -- scripted_ents.Get のチェックはサーバーサイドで行うべきか？クライアントでも必要なら残す
        -- if scripted_ents.Get("gmod_sent_vehicle_fphysics_base") == nil then return end
        if not g_VR.net[LocalPlayer():SteamID()] then return end

        local now = CurTime()
        if now - lastSimfphysSentTime > simfphysSendInterval then
            net.Start("vre_drivingfix_remix")
            net.WriteFloat(g_VR.input.vector1_forward or 0) -- nil チェック追加
            net.WriteFloat(g_VR.input.vector1_reverse or 0) -- nil チェック追加

            local cv_righthandle = GetConVar("vrmod_test_Righthandle")
            local cv_lefthandle = GetConVar("vrmod_test_lefthandle")
            local steering = 0.01 -- デフォルト値

            if cv_righthandle and cv_lefthandle then -- ConVarオブジェクトの存在チェック
                if cv_righthandle:GetBool() then
                    steering = g_VR.tracking.pose_righthand.ang.z * 0.01
                elseif cv_lefthandle:GetBool() then
                    steering = g_VR.tracking.pose_lefthand.ang.z * 0.01
                end
            end
            net.WriteFloat(steering)
            net.SendToServer()
            lastSimfphysSentTime = now
        end
    end)

    -- 元の CreateMove フックは削除
    -- hook.Add("CreateMove","vre_simfphysfix_remix",function() ... end)

elseif SERVER then
	util.AddNetworkString("vre_drivingfix_remix")
    net.Receive( "vre_drivingfix_remix", function( len, ply )
        if scripted_ents.Get("gmod_sent_vehicle_fphysics_base") == nil then return false
        else
            local curveh = ply:GetSimfphys()
            if IsValid(curveh) and ply:IsDrivingSimfphys() == true then -- IsValid チェックを追加
                local clforward  = net.ReadFloat()
                local clbackward = net.ReadFloat()
                local clsteering = net.ReadFloat()
                local fakeleft = 0
                local fakeright = 0
                if clsteering >= 0 then
                    fakeright = clsteering
                    fakeleft = 0
                else
                    fakeright = 0
                    fakeleft = math.abs(clsteering)
                end
                curveh.PressedKeys["joystick_throttle"] = clforward
                curveh.PressedKeys["joystick_brake"] = clbackward
                curveh.PressedKeys["joystick_steer_left"] = fakeleft
                curveh.PressedKeys["joystick_steer_right"] = fakeright
            end
        end
	end)
end
--------[vrmod_simfphysremix.lua]End--------