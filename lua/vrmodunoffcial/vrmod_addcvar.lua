if CLIENT then
	local _, convars, convarValues = vrmod.GetConvars()
	local drivingmode = 0
	local bothmode = 0
	local ply = LocalPlayer()
	local restartflag = false
	concommand.Add(
		"vrmod_vgui_reset",
		function()
			for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
				v:Remove()
			end

			RunConsoleCommand("spawnmenu_reload") -- It even removes spawnmenu, so we need to reload it
		end
	)

	-- LVS 入力モード切り替え用 ConVar を追加
	CreateClientConVar("vrmod_lvs_input_mode", "1", true, FCVAR_ARCHIVE, "LVS input mode (0 = legacy/singleplayer, 1 = networked/multiplayer client)", 0, 1)
	-- VRMod 開始時に LVS 入力モードを自動設定
	hook.Add(
		"VRMod_Start",
		"vrmod_lvs_set_input_mode",
		function(ply)
			if ply ~= LocalPlayer() then return end
			local inputMode = 1 -- デフォルトはネットワークモード
			if game.SinglePlayer() or game.IsListenServer() then
				inputMode = 0 -- シングルプレイまたはホストならレガシーモード
			end

			RunConsoleCommand("vrmod_lvs_input_mode", tostring(inputMode))
			print("[VRMod] LVS Input Mode set to: " .. (inputMode == 0 and "Legacy (Singleplayer/Host)" or "Networked (Multiplayer Client)"))
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

	concommand.Add(
		"vrmod_scale_apply",
		function(ply, cmd, args)
			g_VR.scale = convarValues.vrmod_scale
			convars.vrmod_scale:SetFloat(g_VR.scale)
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

	--"pescorr_cvar_cl_default"
	local CVars = {{"vrmod_characterEyeHeight", "vrmod_characterHeadToHmdDist", "vrmod_scale", "vrmod_seatedoffset", "vrmod_seated"}}
	concommand.Add(
		"vrmod_character_reset",
		function(ply, cmd, args)
			for _, cvar in ipairs(CVars) do
				if cvar ~= nil then
					local name, value = unpack(cvar)
					if GetConVar(name) ~= nil then
						local value = GetConVar(name):GetDefault()
						LocalPlayer():ConCommand(name .. " " .. value)
						LocalPlayer():ConCommand("vrmod_scale 38.7")
						LocalPlayer():ConCommand("vrmod_characterHeadToHmdDist 6.3")
						LocalPlayer():ConCommand("vrmod_characterEyeHeight 66.8")
						LocalPlayer():ConCommand("vrmod_seatedoffset 66.8")
						LocalPlayer():ConCommand("vrmod_crouchthreshold  40")
						LocalPlayer():ConCommand("vrmod_znear 6.0")
						if CLIENT then
							print(name .. " default: " .. value)
						end
					end
				end
			end
		end
	)

	concommand.Add(
		"vrmod_lfsmode",
		function(ply, cmd, args)
			LocalPlayer():ConCommand("vrmod_vehicle_reticlemode 1")
		end
	)

	concommand.Add(
		"vrmod_simfmode",
		function(ply, cmd, args)
			LocalPlayer():ConCommand("vrmod_vehicle_reticlemode 0")
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
		"vrmod_restart",
		function(ply, cmd, args)
			restartflag = true
			if not g_VR.active then return end
			if not IsValid(ply) then return end
			g_VR.StopCharacterSystem(ply:SteamID())
			LocalPlayer():ConCommand("vrmod_exit")
			LocalPlayer():ConCommand("vrmod_lua_reset")
			AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
			include("vrmodunoffcial/vrmod_character.lua")
			AddCSLuaFile("vrmodunoffcial/vrmod_pickup.lua")
			include("vrmodunoffcial/vrmod_pickup.lua")
			AddCSLuaFile("vrmodunoffcial/vrmod_pickup_arcvr.lua")
			include("vrmodunoffcial/vrmod_pickup_arcvr.lua")
			-- AddCSLuaFile("vrmodunoffcial/vrmod_character_hands.lua")
			-- include("vrmodunoffcial/vrmod_character_hands.lua")
			-- LocalPlayer():ConCommand("vrmod_lua_reset_pickup")
			-- LocalPlayer():ConCommand("vrmod_lua_reset_pickup_arcvr")
			-- LocalPlayer():ConCommand("vrmod_lua_reset_character")
			-- LocalPlayer():ConCommand("vrmod_lua_reset_character_hands")
			LocalPlayer():ConCommand("vrmod_start")
			timer.Simple(
				1,
				function()
					restartflag = false
					g_VR.MenuOpen()
					g_VR.MenuClose()
				end
			)
		end
	)

	concommand.Add(
		"vrmod_character_auto",
		function(ply, cmd, args)
			local steamid = ply:SteamID()
			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
			local feet = ply:GetPos()
			if eyes then
				local eyeHeight = eyes.Pos.z - feet.z
				local crouchHeight = eyeHeight / 2
				-- eyeHeightがnanかどうかをチェック
				-- Luaでnanをチェックする方法
				if eyeHeight ~= eyeHeight then
					print("Eye height is NaN, resetting character settings...")
					RunConsoleCommand("vrmod_character_reset")

					return
				end

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

	-- concommand.Add(
	-- 	"vrmod_gmod_optimization",
	-- 	function(ply, cmd, args)
	-- 		-- Gmodのluaコード
	-- 		local function setConvars()
	-- 			local optimizeconvar = {{"gmod_mcore_test", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}}
	-- 			for _, optimizeconvar in ipairs(optimizeconvar) do
	-- 				local name, value = unpack(optimizeconvar)
	-- 				LocalPlayer():ConCommand(name .. " " .. value)
	-- 				if CLIENT then
	-- 					print(name .. " " .. value)
	-- 				end
	-- 			end
	-- 		end
	-- 		timer.Simple(
	-- 			1,
	-- 			function()
	-- 				if g_VR.active == true then
	-- 					setConvars()
	-- 				end
	-- 			end
	-- 		)
	-- 	end
	-- )
	concommand.Add(
		"vrmod_gmod_optimization_02",
		function(ply, cmd, args)
			-- Gmodのluaコード
			-- LocalPlayer():ConCommand("remove_reflective_glass")
			local function setConvars02()
				--local optimizeconvar = {{"mat_motion_blur_enabled", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_projectedtexture_filter", "0"}, {"cl_detaildist", "500"}, {"cl_detailfade", "400"}, {"mat_use_compressed_hdr_textures", "1"}, {"r_ambientboost", "0"}, {"r_decals", "60.00"}, {"r_drawparticles", "1"}, {"g_ragdoll_maxcount", "0"}, {"gmod_physiterations", "1"}, {"r_drawflecks", "0"}, {"r_drawrain", "0"}, {"r_drawropes", "0"}, {"r_drawsprites", "1"}, {"mat_alphacoverage", "0"}, {"gmod_mcore_test", "1"}, {"r_maxdlights", "0.00"}, {"r_shadowmaxrendered", "0.00"}, {"mat_compressedtextures", "1"}, {"ai_strong_optimizations", "1"}, {"r_radiosity", "2"}, {"ai_strong_optimizations_no_checkstand", "1"}, {"ai_expression_optimization", "1"}, {"r_flashlightdepthres", "256"}, {"spawnicon_queue", "1"}}
				local optimizeconvar = {{"gmod_mcore_test", "0"}, {"mat_motion_blur_enabled", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}}
				for _, optimizeconvar in ipairs(optimizeconvar) do
					local name, value = unpack(optimizeconvar)
					LocalPlayer():ConCommand(name .. " " .. value)
					if CLIENT then
						print(name .. " " .. value)
					end
				end
			end

			timer.Simple(
				1,
				function()
					if g_VR.active == true then
						restartflag = true
						-- LocalPlayer():ConCommand("vrmod_restart")
						setConvars02()
						optimizeMirrorReflections()
						LocalPlayer():ConCommand("vrmod_restart")
					end
				end
			)
		end
	)

	concommand.Add(
		"vrmod_gmod_optimization_03",
		function(ply, cmd, args)
			-- Gmodのluaコード
			-- local function setConvars()
			-- 	local optimizeconvar = {{"r_drawparticles", "0"}, {"mat_bumpmap", "0"}, {"mat_specular", "0"}, {"cl_detailfade", "100"}, {"mat_motion_blur_enabled", "0"}, {"mat_motion_blur_falling_intensity", "0"}, {"mat_motion_blur_falling_min", "0"}, {"mat_motion_blur_falling_max", "0"}, {"mat_motion_blur_rotation_intensity", "0"}, {"mat_motion_blur_strength", "0"}, {"mat_queue_mode", "-1"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_flashlightscissor", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_mapextents", "5000"}, {"r_projectedtexture_filter", "0"}, {"cl_detaildist", "500"}, {"cl_detailfade", "400"}, {"mat_colorcorrection", "0"}, {"mat_dynamic_tonemapping", "0"}, {"mat_filtertextures", "1"}, {"mat_mipmaptextures", "1"}, {"mat_parallaxmap", "0"}, {"mat_use_compressed_hdr_textures", "1"}, {"r_ambientboost", "0"}, {"r_decals", "60.00"}, {"r_drawdecals", "0"}, {"r_drawdetailprops", "1"}, {"r_drawparticles", "1"}, {"r_farz", "-1"}, {"r_radiosity", "1"}, {"g_ragdoll_maxcount", "0"}, {"gmod_physiterations", "1"}, {"r_drawflecks", "0"}, {"r_drawrain", "0"}, {"r_drawropes", "0"}, {"r_drawsprites", "1"}, {"r_DrawDisp", "1"}, {"mat_alphacoverage", "0"}, {"gmod_mcore_test", "1"}, {"r_maxdlights", "0.00"}, {"r_shadow_allowbelow", "0"}, {"r_shadow_allowdynamic", "0"}, {"r_shadowfromanyworldlight", "0"}, {"r_shadowmaxrendered", "0.00"}, {"r_shadowrendertotexture", "0"}, {"mat_antialias", "0"}, {"mat_compressedtextures", "1"}, {"ai_strong_optimizations", "1"}, {"ai_expression_optimization", "1"}, {"spawnicon_queue", "1"}}
			-- 	for _, optimizeconvar in ipairs(optimizeconvar) do
			-- 		local name, value = unpack(optimizeconvar)
			-- 		LocalPlayer():ConCommand(name .. " " .. value)
			-- 		if CLIENT then
			-- 			print(name .. " " .. value)
			-- 		end
			-- 	end
			-- end
			local commands = {"mat_antialias", "0", "mat_aaquality", "0", "mat_filterlightmaps", "0", "mat_filtertextures", "0", "mat_disablehwmorph", "1", "r_staticprop_lod", "10", "mat_fastspecular", "0", "mat_trilinear", "0", "r_3dsky", "0", "r_dynamic", "0", "r_decals", "0", "r_drawmodeldecals", "0", "r_drawflecks", "0", "r_drawdetailprops", "0", "physgun_drawbeams", "0", "g_antlion_maxgibs", "0", "r_WaterDrawReflection", "0", "r_WaterDrawRefraction", "0", "mat_mipmaptextures", "1", "mat_reduceparticles", "1", "mat_reducefillrate", "1", "mat_disable_bloom", "1", "mat_disable_fancy_blending", "1", "mat_disable_lightwarp", "1", "mat_colorcorrection", "0", "mat_forceaniso", "1", "dsp_room", "0", "dsp_spatial", "0", "dsp_water", "0", "dsp_slow_cpu", "1", "snd_spatialize_roundrobin", "4", "r_shadows", "0", "r_shadow_allowdynamic", "0", "r_shadow_allowbelow", "0", "r_shadow_lightpos_lerptime", "0", "r_shadowfromworldlights", "0", "r_shadowrendertotexture", "0", "r_flashlightdepthres", "1", "r_flashlightdepthtexture", "0", "r_maxdlights", "0", "mp_show_voice_icons", "0", "r_fastzreject", "1", "r_fastzrejectdisp", "1", "sv_forcepreload", "1", "cl_forcepreload", "1", "mat_motion_blur_forward_enabled", "0", "ai_expression_optimization", "1", "sbox_bonemanip_misc", "0", "sbox_bonemanip_npc", "0", "hud_deathnotice_time", "0"} -- "mat_picmip", "20", --"mat_bumpmap", "0", --"mat_specular", "0", --"mat_hdr_level", "0",
			local function RunConsoleCommands()
				for i = 1, #commands, 2 do
					local cmd = commands[i]
					local arg = commands[i + 1]
					RunConsoleCommand(cmd, arg)
				end
			end

			RunConsoleCommands()
			-- setConvars()
			timer.Simple(
				1,
				function()
					if g_VR.active == true then
						restartflag = true
						LocalPlayer():ConCommand("vrmod_restart")
					end
				end
			)
		end
	)

	-- local commands = {"mat_antialias", "0", "mat_aaquality", "0", "mat_filterlightmaps", "0", "mat_filtertextures", "0", "mat_disablehwmorph", "1", "r_lod", "10", "r_staticprop_lod", "10", "mat_fastspecular", "0", "mat_trilinear", "0", "r_3dsky", "0", "r_dynamic", "0", "r_decals", "0", "r_drawmodeldecals", "0", "r_drawflecks", "0", "r_drawdetailprops", "0", "physgun_drawbeams", "0", "g_antlion_maxgibs", "0", "r_WaterDrawReflection", "0", "r_WaterDrawRefraction", "0", "mat_mipmaptextures", "1", "mat_reduceparticles", "1", "mat_reducefillrate", "1", "mat_disable_bloom", "1", "mat_disable_fancy_blending", "1", "mat_disable_lightwarp", "1", "mat_colorcorrection", "0", "mat_forceaniso", "1", "dsp_room", "0", "dsp_spatial", "0", "dsp_water", "0", "dsp_slow_cpu", "1", "snd_spatialize_roundrobin", "4", "r_shadows", "0", "r_shadow_allowdynamic", "0", "r_shadow_allowbelow", "0", "r_shadow_lightpos_lerptime", "0", "r_shadowfromworldlights", "0", "r_shadowrendertotexture", "0", "r_flashlightdepthres", "1", "r_flashlightdepthtexture", "0", "r_maxdlights", "0", "mp_show_voice_icons", "0", "r_fastzreject", "1", "r_fastzrejectdisp", "1", "sv_forcepreload", "1", "cl_forcepreload", "1", "mat_motion_blur_forward_enabled", "0", "ai_expression_optimization", "1", "sbox_bonemanip_misc", "0", "sbox_bonemanip_npc", "0", "hud_deathnotice_time", "0"} -- "mat_picmip", "20", --"mat_bumpmap", "0", --"mat_specular", "0", --"mat_hdr_level", "0",
	-- local function RunConsoleCommands()
	-- 	for i = 1, #commands, 2 do
	-- 		local cmd = commands[i]
	-- 		local arg = commands[i + 1]
	-- 		RunConsoleCommand(cmd, arg)
	-- 	end
	-- end
	-- hook.Add(
	-- 	"PlayerInitialSpawn",
	-- 	"RunConsoleCommands",
	-- 	function(ply)
	-- 		concommand.Add(
	-- 			"vrmod_gmod_optimization_04",
	-- 			function(ply, cmd, args)
	-- 				if ply:IsAdmin() then
	-- 					RunConsoleCommands()
	-- 				end
	-- 			end
	-- 		)
	-- 	end
	-- )
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