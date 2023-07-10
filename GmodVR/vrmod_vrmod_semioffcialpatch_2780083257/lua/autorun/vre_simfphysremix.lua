if CLIENT then
	hook.Add("VRE_simphys_Overrides","vre_simfphysfix_override",function()
		if LocalPlayer():InVehicle() then
			hook.Remove("CreateMove","vre_simfphysfix")
			end
	end)

	-- --Pickup Convar Start
	-- hook.Add("VRMod_Input","vre_onlocomotion_action",function( action, pressed )
			-- if action == "boolean_right_pickup" then
				-- LocalPlayer():ConCommand(pressed and "vrmod_test_Righthandle 1" or "vrmod_test_Righthandle 0")
				-- return
			-- end
			-- if action == "boolean_left_pickup" then
				-- LocalPlayer():ConCommand(pressed and "vrmod_test_lefthandle 1" or "vrmod_test_lefthandle 0")
				-- return
			-- end
			
			-- if action == "boolean_handbrake" then
				-- LocalPlayer():ConCommand(pressed and "vrmod_test_handbrake 1" or "vrmod_test_handbrake 0")
				-- return
			-- end
	-- end)
	-- --Pickup Convar End


    hook.Add("CreateMove","vre_simfphysfix_remix",function()
		local cv_righthandle = CreateClientConVar("vrmod_test_Righthandle","0",FCVAR_ARCHIVE)
		local cv_lefthandle = CreateClientConVar("vrmod_test_lefthandle","0",FCVAR_ARCHIVE)

	
        if not LocalPlayer():InVehicle() or scripted_ents.Get("gmod_sent_vehicle_fphysics_base") == nil or !g_VR.net[LocalPlayer():SteamID()] then return end
        net.Start("vre_drivingfix_remix")
            net.WriteFloat(g_VR.input.vector1_forward)
            net.WriteFloat(g_VR.input.vector1_reverse)
			if cv_righthandle:GetBool() or cv_lefthandle:GetBool() then
					if cv_righthandle:GetBool() then
						net.WriteFloat(g_VR.tracking.pose_righthand.ang.z*0.01)
					end
					if cv_lefthandle:GetBool() then
						net.WriteFloat(g_VR.tracking.pose_lefthand.ang.z*0.01)
					end
			else
				net.WriteFloat(g_VR.input.vector2_steer.x)
			end
		net.SendToServer()

		-- net.Start("vre_drivingaddbutton")
				-- net.WriteBool(g_VR.input.boolean_handbrake)
				-- net.WriteBool(g_VR.input.boolean_turbo)
		-- net.SendToServer()
    end)

elseif SERVER then 

	util.AddNetworkString("vre_drivingfix_remix")
    net.Receive( "vre_drivingfix_remix", function( len, ply )
        if scripted_ents.Get("gmod_sent_vehicle_fphysics_base") == nil then return false 
        else
            local curveh = ply:GetSimfphys()
            if ply:IsDrivingSimfphys() == true then
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
	
	-- util.AddNetworkString("vre_drivingaddbutton")
    -- net.Receive( "vre_drivingaddbutton", function( len, ply )
        -- if scripted_ents.Get("gmod_sent_vehicle_fphysics_base") == nil then return false 
        -- else
            -- local curveh = ply:GetSimfphys()
            -- if ply:IsDrivingSimfphys() == true then
                -- local clsidebrake = net.ReadFloat()
                -- local clturbo = net.ReadFloat()


                -- curveh.PressedKeys["joystick_handbrake"] = clsidebrake
                -- curveh.PressedKeys["joystick_clutch"] = clturbo
            -- end
        -- end
	-- end)

	
end