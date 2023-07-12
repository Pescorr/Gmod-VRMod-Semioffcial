

if CLIENT then

	local _,convars,convarValues = vrmod.GetConvars()

	local drivingmode = 0
	local bothmode = 0
	local ply = LocalPlayer()
	
	-- local hands = {
		-- {
			-- poseName = "pose_lefthand",
			-- overrideFunc = vrmod.SetLeftHandPose,
			-- getFunc = vrmod.GetLeftHandPose
		-- },
		-- {
			-- poseName = "pose_righthand",
			-- overrideFunc = vrmod.SetRightHandPose,
			-- getFunc = vrmod.GetRightHandPose,
		-- },
	-- }


	-- concommand.Add("vrmod_print_righthand_pos", function(ply)
	-- print(g_VR.tracking.pose_righthand.pos)
	-- end)

	-- concommand.Add("vrmod_print_righthand_pos_x", function(ply)
	-- print(g_VR.tracking.pose_righthand.pos.x)
	-- end)


	-- concommand.Add("vrmod_print_righthand_pos_y", function(ply)
	-- print(g_VR.tracking.pose_righthand.pos.y)
	-- end)

	-- concommand.Add("vrmod_print_righthand_pos_z", function(ply)
	-- print(g_VR.tracking.pose_righthand.pos.z)
	-- end)

	-- concommand.Add("vrmod_print_righthand_ang", function(ply)
	-- print(g_VR.tracking.pose_righthand.ang)
	-- end)

	-- concommand.Add("vrmod_print_righthand_ang_x", function(ply)
	-- print(g_VR.tracking.pose_righthand.ang.x)
	-- end)

	-- concommand.Add("vrmod_print_righthand_ang_y", function(ply)
	-- print(g_VR.tracking.pose_righthand.ang.y)
	-- end)

	-- concommand.Add("vrmod_print_righthand_ang_z", function(ply)
	-- print(g_VR.tracking.pose_righthand.ang.z)
	-- end)


	concommand.Add( "vrmod_keymode_restore", function( ply, cmd, args )
		bothmode = 0
		if ply:InVehicle() then
			drivingmode = 1
			VRMOD_SetActiveActionSets( "/actions/base","/actions/driving" )	
			LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")

			-- print("VRMOD_SetActiveActionSets:","driving") 
			else
			drivingmode = 0
			VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
			LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
			-- print("VRMOD_SetActiveActionSets:","main")
		end
	end)

	concommand.Add( "vrmod_keymode_main", function( ply, cmd, args )
		bothmode = 0
		drivingmode = 0
		VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
		LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
		-- print("VRMOD_SetActiveActionSets:","main")
	end)
	
	concommand.Add( "vrmod_keymode_driving", function( ply, cmd, args )
		bothmode = 0
		drivingmode = 1
		VRMOD_SetActiveActionSets( "/actions/base","/actions/driving" )	
		LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
		-- print("VRMOD_SetActiveActionSets:","driving") 
	end)

	
	concommand.Add( "vrmod_keymode_both", function( ply, cmd, args )
		bothmode = 1
		VRMOD_SetActiveActionSets( "/actions/base", "/actions/main", "/actions/driving" )
		LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 1")

	end)

	
	-- concommand.Add( "vrmod_character_apply", function(ply)
			-- -- g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z-g_VR.origin.z)/g_VR.scale)
			-- convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z-convarValues.vrmod_seatedoffset-g_VR.origin.z)) 
	-- end)
	
	concommand.Add( "vrmod_scale_apply" , function( ply, cmd, args )
			g_VR.scale = convarValues.vrmod_scale
			convars.vrmod_scale:SetFloat(g_VR.scale)
	end)
			
	concommand.Add( "vrmod_character_restart", function( ply, cmd, args )
		if not g_VR.active then return end
		LocalPlayer():ConCommand("vrmod_exit")
		AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
		include("vrmodunoffcial/vrmod_character.lua")
		LocalPlayer():ConCommand("vrmod_start")	
	end)

	concommand.Add( "vrmod_character_stop" , function( ply, cmd, args )
	if not IsValid(ply) then return end
		g_VR.StopCharacterSystem( ply:SteamID() )

	end)

	concommand.Add( "vrmod_character_start" , function( ply, cmd, args )
	if not IsValid(ply) then return end
		g_VR.StartCharacterSystem( ply )

	end)

	concommand.Add( "vrmod_restart", function( ply, cmd, args )
			VRUtilClientExit()
			VRUtilClientStart()
	end)

	concommand.Add( "vrmod_character_reset", function( ply, cmd, args )
		LocalPlayer():ConCommand("vrmod_characterEyeHeight 66.8")
			print("vrmod_characterEyeHeight 66.8")
		LocalPlayer():ConCommand("vrmod_characterHeadToHmdDist 6.3")
			print("vrmod_characterHeadToHmdDist 6.3")
		LocalPlayer():ConCommand("vrmod_scale 38.7")
			print("vrmod_scale 38.7")
		LocalPlayer():ConCommand("vrmod_crouchthreshold 40.0")
			print("vrmod_crouchthreshold 40.0")

	end)
	
	
	-- concommand.Add( "vrmod_character_reset", function( ply, cmd, args )
	-- 	LocalPlayer():ConCommand("vrmod_characterEyeHeight 66.8")
	-- 		print("vrmod_characterEyeHeight 66.8")
	-- 	LocalPlayer():ConCommand("vrmod_characterHeadToHmdDist 6.3")
	-- 		print("vrmod_characterHeadToHmdDist 6.3")
	-- 	LocalPlayer():ConCommand("vrmod_scale 38.7")
	-- 		print("vrmod_scale 38.7")
	-- 	LocalPlayer():ConCommand("vrmod_crouchthreshold 40.0")
	-- 		print("vrmod_crouchthreshold 40.0")

	-- end)


	-- concommand.Add( "vrmod_character_heightadjestmode", function( ply, cmd, args )
		-- LocalPlayer():ConCommand("vrmod_characterEyeHeight 25.0")
			-- print("vrmod_characterEyeHeight 25.0")
		-- LocalPlayer():ConCommand("vrmod_scale 38.7")
			-- print("vrmod_scale 38.7")
		-- LocalPlayer():ConCommand("vrmod_seatedoffset 1.00")
			-- print("vrmod_seatedoffset 1.00")
		-- LocalPlayer():ConCommand("vrmod_seated 1")
			-- print("vrmod_seated 1")
	-- end)

	
	concommand.Add( "vrmod_lfsmode", function( ply, cmd, args )
				LocalPlayer():ConCommand("vrmod_vehicle_reticlemode 1")
				LocalPlayer():ConCommand("lfs_hipster 0")
				LocalPlayer():ConCommand("weaponseats_enablecrosshair 0")


	end)

	concommand.Add( "vrmod_simfmode", function( ply, cmd, args )
				LocalPlayer():ConCommand("vrmod_vehicle_reticlemode 0")
				LocalPlayer():ConCommand("weaponseats_enablecrosshair 0")

	end)


	concommand.Add( "vrmod_scale_auto", function( ply, cmd, args )

		g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z-g_VR.origin.z)/g_VR.scale)
		convars.vrmod_scale:SetFloat(g_VR.scale)
	end)

	concommand.Add( "vrmod_seatedoffset_auto", function( ply, cmd, args )
		convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z-convarValues.vrmod_seatedoffset-g_VR.origin.z)) 
	end)


	
	concommand.Add( "vrmod_gmod_optimization", function( ply, cmd, args )
		-- LocalPlayer():ConCommand("mat_antialias 0")
		-- 	print("mat_antialias 0")
		-- LocalPlayer():ConCommand("mat_alphacoverage 0")
		-- 	print("mat_alphacoverage 0")
		-- LocalPlayer():ConCommand("mat_motion_blur_enabled 0")
		-- 	print("mat_motion_blur_enabled 0")
		-- LocalPlayer():ConCommand("r_WaterDrawReflection 0")
		-- 	print("r_WaterDrawReflection 0")
		-- LocalPlayer():ConCommand("r_WaterDrawRefraction 0")
		-- 	print("r_WaterDrawRefraction 0")
		-- LocalPlayer():ConCommand("r_waterforceexpensive 0")
		-- 	print("r_waterforceexpensive 0")
		-- LocalPlayer():ConCommand("r_waterforcereflectentities 0")
		-- 	print("r_waterforcereflectentities 0")
		-- LocalPlayer():ConCommand("engine_no_focus_sleep 0")
		-- 	print("engine_no_focus_sleep 0")
		-- LocalPlayer():ConCommand("fov_desired 90")
		-- 	print("fov_desired 90")
		-- LocalPlayer():ConCommand("r_mapextents 5000")
		-- 	print("r_mapextents 5000")
		-- LocalPlayer():ConCommand("mat_specular 0")
		-- 	print("mat_specular 0")
		-- LocalPlayer():ConCommand("fps_max 60")
		-- 	print("fps_max 60")
		-- LocalPlayer():ConCommand("mat_queue_mode 1")
		-- 		print("mat_queumate_mode 1")
		-- LocalPlayer():ConCommand("cl_threaded_bone_setup 1")
		-- 		print("cl_threaded_bone_setup 1")
		-- LocalPlayer():ConCommand("cl_threaded_client_leaf_system 1")
		-- 		print("cl_threaded_client_leaf_system 1")
		-- LocalPlayer():ConCommand("r_threaded_client_shadow_manager 1")
		-- 		print("r_threaded_client_shadow_manager 1")
		-- LocalPlayer():ConCommand("r_threaded_particles 1")
		-- 		print("r_threaded_particles 1")
		-- LocalPlayer():ConCommand("r_threaded_renderables 1")
		-- 		print("r_threaded_renderables 1")
		-- LocalPlayer():ConCommand("r_queued_ropes 1")
		-- 		print("r_queued_ropes 1")
		-- LocalPlayer():ConCommand("studio_queue_mode 1")
		-- 		print("studio_queue_mode 1")
		-- LocalPlayer():ConCommand("cl_forcepreload 1")
		-- 	print("cl_forcepreload 1")
		-- LocalPlayer():ConCommand("sv_forcepreload 1")
		-- print("sv_forcepreload 1")
		-- LocalPlayer():ConCommand("mat_alphacoverage 0")
		-- 	print("mat_alphacoverage 0")
		-- LocalPlayer():ConCommand("r_projectedtexture_filter 0")
		-- 	print("r_projectedtexture_filter 0")
		-- LocalPlayer():ConCommand("mat_vsync 1")
		-- 	print("mat_vsync 1")
		-- LocalPlayer():ConCommand("fov_desired 90")
		-- 	print("fov_desired 90")


			RunConsoleCommand("cl_detaildist", "500")
			RunConsoleCommand("cl_detailfade", "400.000000")
			RunConsoleCommand("cl_drawownshadow", "0")
			RunConsoleCommand("mat_bumpmap", "1")
			RunConsoleCommand("mat_colorcorrection", "0")
			RunConsoleCommand("mat_compressedtextures", "1")
			RunConsoleCommand("mat_dynamic_tonemapping", "0")
			RunConsoleCommand("mat_filterlightmaps", "0")
			RunConsoleCommand("mat_filtertextures", "1")
			RunConsoleCommand("mat_mipmaptextures", "1")
			RunConsoleCommand("mat_parallaxmap", "0")
			RunConsoleCommand("mat_showlowresimage", "0")
			RunConsoleCommand("mat_use_compressed_hdr_textures", "1")
			RunConsoleCommand("r_3dsky", "1")
			RunConsoleCommand("r_ambientboost", "0")
			RunConsoleCommand("r_decals", "60.00")
			RunConsoleCommand("r_drawdecals", "0")
			RunConsoleCommand("r_drawdetailprops", "1")
			RunConsoleCommand("r_drawparticles", "1")
			RunConsoleCommand("r_farz", "20000")
			RunConsoleCommand("r_maxdlights", "0.00")
			RunConsoleCommand("r_radiosity", "2")
			RunConsoleCommand("r_shadow_allowbelow", "0")
			RunConsoleCommand("r_shadow_allowdynamic", "0")
			RunConsoleCommand("r_shadow_lightpos_lerptime", "60.00")
			RunConsoleCommand("r_shadowfromanyworldlight", "0")
			RunConsoleCommand("r_shadowmaxrendered", "0.00")
			RunConsoleCommand("r_shadowrendertotexture", "0")
			RunConsoleCommand("viewmodel_fov", "90.00")

		if g_VR.active == true then
			LocalPlayer():ConCommand("vrmod_restart")
		end	
	end)

	concommand.Add("vrmod_character_auto", function( ply, cmd, args)
		local steamid = ply:SteamID()
		local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
		local feet = ply:GetPos()
			if eyes then
				local eyeHeight = eyes.Pos.z - feet.z
				local crouchHeight = eyeHeight /2
				print("Eye height for " .. steamid .. " is: " .. eyeHeight)
				
				-- Store the eye height for later use
				characterInfo = characterInfo or {}
				characterInfo[steamid] = characterInfo[steamid] or {}
				local eyeconvar = GetConVar("vrmod_characterEyeHeight")
				eyeconvar:SetFloat(eyeHeight + 3)
				local crouchconvar = GetConVar("vrmod_crouchthreshold")
				crouchconvar:SetFloat(crouchHeight + 3)
				local HeadToHmdDist = GetConVar("vrmod_characterHeadToHmdDist")
				HeadToHmdDist:SetFloat(eyeHeight / 5 - 6.3)

				-- convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z-convarValues.vrmod_seatedoffset-g_VR.origin.z)) 

			end
	end)


	concommand.Add( "vrmod_togglelaserpointer", function( ply, cmd, args )
		if not GetConVar("vrmod_laserpointer"):GetBool() then
		-- add laser pointer
			local mat = Material("cable/redlaser")
			hook.Add("PostDrawTranslucentRenderables","vr_laserpointer",function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox then return end
				if g_VR.viewModelMuzzle and not g_VR.menuFocus then
					render.SetMaterial(mat)
					render.DrawBeam(g_VR.viewModelMuzzle.Pos, g_VR.viewModelMuzzle.Pos + g_VR.viewModelMuzzle.Ang:Forward()*10000, 1, 0, 1, Color(255,255,255,255))
				end
			end)
			LocalPlayer():ConCommand("vrmod_laserpointer 1")
		else
			hook.Remove("PostDrawTranslucentRenderables","vr_laserpointer")
			LocalPlayer():ConCommand("vrmod_laserpointer 0")
		end
	end)

--
end