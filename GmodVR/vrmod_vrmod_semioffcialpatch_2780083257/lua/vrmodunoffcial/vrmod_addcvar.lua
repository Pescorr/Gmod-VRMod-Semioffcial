if CLIENT then
	local _, convars, convarValues = vrmod.GetConvars()
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
	concommand.Add(
		"vrmod_vgui_reset",
		function()
			for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
				v:Remove()
			end

			RunConsoleCommand("spawnmenu_reload") -- It even removes spawnmenu, so we need to reload it
		end
	)

	concommand.Add(
		"vrmod_keymode_restore",
		function(ply, cmd, args)
			bothmode = 0
			if ply:InVehicle() then
				drivingmode = 1
				VRMOD_SetActiveActionSets("/actions/base", "/actions/driving")
				LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
				-- print("VRMOD_SetActiveActionSets:","driving") 
			else
				drivingmode = 0
				VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
				LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
				-- print("VRMOD_SetActiveActionSets:","main")
			end
		end
	)

	concommand.Add(
		"vrmod_keymode_main",
		function(ply, cmd, args)
			bothmode = 0
			drivingmode = 0
			VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
			LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
		end
	)

	-- print("VRMOD_SetActiveActionSets:","main")
	concommand.Add(
		"vrmod_keymode_driving",
		function(ply, cmd, args)
			bothmode = 0
			drivingmode = 1
			VRMOD_SetActiveActionSets("/actions/base", "/actions/driving")
			LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 0")
		end
	)

	-- print("VRMOD_SetActiveActionSets:","driving") 
	concommand.Add(
		"vrmod_keymode_both",
		function(ply, cmd, args)
			bothmode = 1
			VRMOD_SetActiveActionSets("/actions/base", "/actions/main", "/actions/driving")
			LocalPlayer():ConCommand("vrmod_vehicle_bothkeymode 1")
		end
	)

	-- concommand.Add( "vrmod_character_apply", function(ply)
	-- -- g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z-g_VR.origin.z)/g_VR.scale)
	-- convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z-convarValues.vrmod_seatedoffset-g_VR.origin.z)) 
	-- end)
	concommand.Add(
		"vrmod_scale_apply",
		function(ply, cmd, args)
			g_VR.scale = convarValues.vrmod_scale
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
	)

	concommand.Add(
		"vrmod_character_restart",
		function(ply, cmd, args)
			if not g_VR.active then return end
			LocalPlayer():ConCommand("vrmod_exit")
			AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
			include("vrmodunoffcial/vrmod_character.lua")
			LocalPlayer():ConCommand("vrmod_start")
		end
	)

	concommand.Add(
		"vrmod_character_stop",
		function(ply, cmd, args)
			if not IsValid(ply) then return end
			g_VR.StopCharacterSystem(ply:SteamID())
		end
	)

	concommand.Add(
		"vrmod_character_start",
		function(ply, cmd, args)
			if not IsValid(ply) then return end
			g_VR.StartCharacterSystem(ply)
		end
	)

	concommand.Add(
		"vrmod_restart",
		function(ply, cmd, args)
			VRUtilClientExit()
			VRUtilClientStart()
		end
	)

	concommand.Add(
		"vrmod_character_reset",
		function(ply, cmd, args)
			LocalPlayer():ConCommand("vrmod_characterEyeHeight 66.8")
			print("vrmod_characterEyeHeight 66.8")
			LocalPlayer():ConCommand("vrmod_characterHeadToHmdDist 6.3")
			print("vrmod_characterHeadToHmdDist 6.3")
			LocalPlayer():ConCommand("vrmod_scale 38.7")
			print("vrmod_scale 38.7")
			LocalPlayer():ConCommand("vrmod_crouchthreshold 40.0")
			print("vrmod_crouchthreshold 40.0")
		end
	)

	concommand.Add(
		"vrmod_lfsmode",
		function(ply, cmd, args)
			LocalPlayer():ConCommand("vrmod_vehicle_reticlemode 1")
			LocalPlayer():ConCommand("lfs_hipster 0")
			LocalPlayer():ConCommand("weaponseats_enablecrosshair 0")
		end
	)

	concommand.Add(
		"vrmod_simfmode",
		function(ply, cmd, args)
			LocalPlayer():ConCommand("vrmod_vehicle_reticlemode 0")
			LocalPlayer():ConCommand("weaponseats_enablecrosshair 0")
		end
	)

	concommand.Add(
		"vrmod_normalgunsetting",
		function(ply, cmd, args)
			LocalPlayer():ConCommand("cl_tfa_fx_rtscopeblur_mode 0")
			LocalPlayer():ConCommand("cl_tfa_fx_rtscopeblur_passes 0")
			LocalPlayer():ConCommand("cl_tfa_fx_rtscopeblur_intensity 0")
			LocalPlayer():ConCommand("cl_tfa_fx_ads_dof 0")
			LocalPlayer():ConCommand("cl_tfa_fx_ads_dof_hd 0")
			LocalPlayer():ConCommand("cl_tfa_3dscope_overlay 0")
			LocalPlayer():ConCommand("sv_tfa_sprint_enabled 0")
			LocalPlayer():ConCommand("cl_tfa_ironsights_toggle 0")
			LocalPlayer():ConCommand("arccw_blur_toytown 0")
			LocalPlayer():ConCommand("arccw_blur 0")
			LocalPlayer():ConCommand("arc9_cheapscopes 0")
			LocalPlayer():ConCommand("arc9_controller 1")
			LocalPlayer():ConCommand("arc9_autolean 0")
			LocalPlayer():ConCommand("arc9_never_ready 1")
			LocalPlayer():ConCommand("arc9_vm_cambob 0")
			LocalPlayer():ConCommand("arc9_vm_cambobwalk 0")
			LocalPlayer():ConCommand("arc9_breath_pp 0")
			LocalPlayer():ConCommand("arc9_fx_rtblur 0")
			LocalPlayer():ConCommand("arc9_fx_adsblur 0")
			LocalPlayer():ConCommand("arc9_fx_reloadblur 0")
			LocalPlayer():ConCommand("arc9_fx_animblur 0")
		end
	)

	concommand.Add(
		"vrmod_scale_auto",
		function(ply, cmd, args)
			g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
	)

	concommand.Add(
		"vrmod_seatedoffset_auto",
		function(ply, cmd, args)
			convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z))
		end
	)


	concommand.Add(
		"vrmod_Scr_Auto",
		function(ply, cmd, args)
			local function ScrAuto()
				local Scrset = {{"vrmod_ScrH", ScrH()}, {"vrmod_ScrW", ScrW()}, {"vrmod_ScrH_hud", ScrH()}, {"vrmod_ScrW_hud", ScrW()}}
				for _, Scrset in ipairs(Scrset) do
					local name, value = unpack(Scrset)
					LocalPlayer():ConCommand(name .. " " .. value)
				end
			end

			ScrAuto()
		end
	)

	concommand.Add(
		"vrmod_gmod_optimization",
		function(ply, cmd, args)
			-- Gmodのluaコード
			local function setConvars()
				local optimizeconvar = {{"mat_motion_blur_enabled", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"fps_max", "60"}, {"SyntHud_max_ap", "0"}} --, {"cl_threaded_bone_setup", "1"}, {"cl_threaded_client_leaf_system", "1"}, {"r_threaded_client_shadow_manager", "1"}, {"r_threaded_particles", "1"}, {"r_threaded_renderables", "1"}, {"r_queued_ropes", "1"}, {"studio_queue_mode", "1"}, {"cl_forcepreload", "1"}, {"sv_forcepreload", "1"}, {"r_projectedtexture_filter", "0"}, {"cl_detaildist", "500"}, {"cl_detailfade", "400"}, {"cl_drawownshadow", "0"}, {"mat_bumpmap", "1"}, {"mat_colorcorrection", "0"}, {"mat_compressedtextures", "1"}, {"mat_dynamic_tonemapping", "0"}, {"mat_filtertextures", "1"}, {"mat_mipmaptextures", "1"}, {"mat_parallaxmap", "0"}, {"mat_showlowresimage", "0"}, {"mat_use_compressed_hdr_textures", "1"}, {"r_3dsky", "1"}, {"r_ambientboost", "0"}, {"r_decals", "60.00"}, {"r_drawdecals", "0"}, {"r_drawdetailprops", "1"}, {"r_drawparticles", "1"}, {"r_farz", "12000"}, {"r_radiosity", "2"}, {"cl_ejectbrass", "0"}, {"g_ragdoll_maxcount", "0"}, {"gmod_physiterations", "1"}, {"mat_aaquality", "0"}, {"r_drawflecks", "0"}, {"r_drawrain", "0"}, {"r_drawropes", "0"}, {"r_drawskybox", "1"}, {"r_drawsprites", "1"}, {"r_DrawDisp", "1"}, {"r_drawstaticprops", "1"}, {"mat_alphacoverage", "0"}, {"mat_specular", "0"}, {"r_maxdlights", "0.00"}, {"r_shadow_allowbelow", "0"}, {"r_shadow_allowdynamic", "0"}, {"r_shadowfromanyworldlight", "0"}, {"r_shadowmaxrendered", "0.00"}, {"r_shadowrendertotexture", "0"}, {"SyntHud_max_ap", "0"}} -- {"mat_filterlightmaps", "0"}, -- {"r_shadow_lightpos_lerptime", "60.00"}, --{"mat_antialias", "0"},
				for _, optimizeconvar in ipairs(optimizeconvar) do
					local name, value = unpack(optimizeconvar)
					LocalPlayer():ConCommand(name .. " " .. value)
					if CLIENT then
						print(name .. " " .. value)
					end
				end
			end

			setConvars()
		end
	)

	concommand.Add(
		"vrmod_gmod_optimization_02",
		function(ply, cmd, args)
			-- Gmodのluaコード
			local function setConvars()
				local optimizeconvar = {{"mat_motion_blur_enabled", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_mapextents", "5000"}, {"fps_max", "60"}, {"mat_queue_mode", "1"}, {"cl_threaded_bone_setup", "1"}, {"cl_threaded_client_leaf_system", "1"}, {"r_threaded_client_shadow_manager", "1"}, {"r_threaded_particles", "1"}, {"r_threaded_renderables", "1"}, {"r_queued_ropes", "1"}, {"studio_queue_mode", "1"}, {"cl_forcepreload", "1"}, {"sv_forcepreload", "1"}, {"r_projectedtexture_filter", "0"}, {"cl_detaildist", "500"}, {"cl_detailfade", "400"}, {"cl_drawownshadow", "0"}, {"mat_bumpmap", "1"}, {"mat_colorcorrection", "0"}, {"mat_compressedtextures", "1"}, {"mat_dynamic_tonemapping", "0"}, {"mat_filtertextures", "1"}, {"mat_mipmaptextures", "1"}, {"mat_parallaxmap", "0"}, {"mat_showlowresimage", "0"}, {"mat_use_compressed_hdr_textures", "1"}, {"r_3dsky", "1"}, {"r_ambientboost", "0"}, {"r_decals", "60.00"}, {"r_drawdecals", "0"}, {"r_drawdetailprops", "1"}, {"r_drawparticles", "1"}, {"r_farz", "12000"}, {"r_radiosity", "2"}, {"cl_ejectbrass", "0"}, {"g_ragdoll_maxcount", "0"}, {"gmod_physiterations", "1"}, {"mat_aaquality", "0"}, {"r_drawflecks", "0"}, {"r_drawrain", "0"}, {"r_drawropes", "0"}, {"r_drawskybox", "1"}, {"r_drawsprites", "1"}, {"r_DrawDisp", "1"}, {"r_drawstaticprops", "1"}, {"mat_alphacoverage", "0"}, {"mat_specular", "0"}, {"r_maxdlights", "0.00"}, {"r_shadow_allowbelow", "0"}, {"r_shadow_allowdynamic", "0"}, {"r_shadowfromanyworldlight", "0"}, {"r_shadowmaxrendered", "0.00"}, {"r_shadowrendertotexture", "0"}, {"SyntHud_max_ap", "0"}} -- {"mat_filterlightmaps", "0"}, -- {"r_shadow_lightpos_lerptime", "60.00"}, --{"mat_antialias", "0"},
				for _, optimizeconvar in ipairs(optimizeconvar) do
					local name, value = unpack(optimizeconvar)
					LocalPlayer():ConCommand(name .. " " .. value)
					if CLIENT then
						print(name .. " " .. value)
					end
				end
			end

			setConvars()
		end
	)

	-- if g_VR.active == true then
	-- 	LocalPlayer():ConCommand("vrmod_restart")
	-- end	
	concommand.Add(
		"vrmod_character_auto",
		function(ply, cmd, args)
			local steamid = ply:SteamID()
			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
			local feet = ply:GetPos()
			if eyes then
				local eyeHeight = eyes.Pos.z - feet.z
				local crouchHeight = eyeHeight / 2
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
		end
	)

	concommand.Add(
		"vrmod_togglelaserpointer",
		function(ply, cmd, args)
			if not GetConVar("vrmod_laserpointer"):GetBool() then
				-- add laser pointer
				local mat = Material("cable/redlaser")
				hook.Add(
					"PostDrawTranslucentRenderables",
					"vr_laserpointer",
					function(bDrawingDepth, bDrawingSkybox)
						if bDrawingSkybox then return end
						if g_VR.viewModelMuzzle and not g_VR.menuFocus then
							render.SetMaterial(mat)
							render.DrawBeam(g_VR.viewModelMuzzle.Pos, g_VR.viewModelMuzzle.Pos + g_VR.viewModelMuzzle.Ang:Forward() * 10000, 1, 0, 1, Color(255, 255, 255, 255))
						end
					end
				)

				LocalPlayer():ConCommand("vrmod_laserpointer 1")
			else
				hook.Remove("PostDrawTranslucentRenderables", "vr_laserpointer")
				LocalPlayer():ConCommand("vrmod_laserpointer 0")
			end
		end
	)

	hook.Add(
		"CreateMove",
		"vrmod_startup_loadcustomactions",
		function()
			hook.Remove("CreateMove", "vrmod_startup_loadcustomactions")
			timer.Simple(
				1,
				function()
					VRUtilLoadCustomActions()
					print("VRUtilLoadCustomActions")
				end
			)
		end
	)
	--
end