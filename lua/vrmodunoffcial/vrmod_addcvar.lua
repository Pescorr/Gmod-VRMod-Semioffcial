if CLIENT then
	local _, convars, convarValues = vrmod.GetConvars()
	local drivingmode = 0
	local bothmode = 0
	local ply = LocalPlayer()
	concommand.Add(
		"vrmod_vgui_reset",
		function()
			for _, v in pairs(vgui.GetWorldPanel():GetChildren()) do
				v:Remove()
			end

			RunConsoleCommand("spawnmenu_reload") -- It even removes spawnmenu, so we need to reload it
		end
	)

	-- 鏡の反射のパフォーマンスを向上させる関数
	local function optimizeMirrorReflections()
		-- 解像度を動的に調整する
		local function adjustReflectionResolution()
			local currentFPS = 1 / FrameTime()
			local targetFPS = 62 -- 目標のFPS
			local resolutionScale = math.sqrt(currentFPS / targetFPS)
			resolutionScale = math.Clamp(resolutionScale, 0.5, 1)
			-- 解像度を設定
			for _, ent in ipairs(ents.FindByClass("env_cubemap")) do
				ent:SetKeyValue("cubemapsize", tostring(math.floor(1024 * resolutionScale)))
			end
		end

		-- 描画距離を制限する
		local maxReflectionDistance = 100 -- 反射の最大描画距離
		-- 反射の描画距離を設定
		for _, ent in ipairs(ents.FindByClass("env_cubemap")) do
			ent:SetKeyValue("farz", tostring(maxReflectionDistance))
		end

		-- オブジェクトの詳細度を調整する
		local reflectionLODDistance = 100 -- 反射でのLOD切り替え距離
		-- 反射でのLOD切り替え距離を設定
		for _, ent in ipairs(ents.FindByClass("env_cubemap")) do
			ent:SetKeyValue("loddistance", tostring(reflectionLODDistance))
		end

		-- 解像度の動的調整を有効化
		hook.Add("PreRender", "OptimizeMirrorReflections_AdjustResolution", adjustReflectionResolution)
	end

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
			g_VR.StopCharacterSystem(ply:SteamID())
			LocalPlayer():ConCommand("vrmod_exit")
			AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
			include("vrmodunoffcial/vrmod_character.lua")
			AddCSLuaFile("vrmodunoffcial/vrmod_character_hands.lua")
			include("vrmodunoffcial/vrmod_character_hands.lua")
			LocalPlayer():ConCommand("vrmod_start")
			g_VR.MenuOpen()
			g_VR.MenuClose()
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
			g_VR.StopCharacterSystem(ply:SteamID())
			VRUtilClientExit()
			VRUtilClientStart()
			g_VR.StartCharacterSystem(ply)
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
			LocalPlayer():ConCommand("vrmod_seatedoffset  33.4")
			print("vrmod_crouchthreshold 33.4")
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
				local optimizeconvar = {{"mat_motion_blur_enabled", "0"}, {"mat_motion_blur_falling_intensity", "0"}, {"mat_motion_blur_falling_min", "0"}, {"mat_motion_blur_falling_max", "0"}, {"mat_motion_blur_rotation_intensity", "0"}, {"mat_motion_blur_strength", "0"}, {"mat_queue_mode", "1"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}}
				for _, optimizeconvar in ipairs(optimizeconvar) do
					local name, value = unpack(optimizeconvar)
					LocalPlayer():ConCommand(name .. " " .. value)
					if CLIENT then
						print(name .. " " .. value)
					end
				end
			end

			setConvars()
			timer.Simple(
				1,
				function()
					optimizeMirrorReflections()
				end
			)
		end
	)

	concommand.Add(
		"vrmod_gmod_optimization_02",
		function(ply, cmd, args)
			-- Gmodのluaコード
			-- LocalPlayer():ConCommand("remove_reflective_glass")
			local function setConvars()
				local optimizeconvar = {{"mat_motion_blur_enabled", "0"}, {"mat_motion_blur_falling_intensity", "0"}, {"mat_motion_blur_falling_min", "0"}, {"mat_motion_blur_falling_max", "0"}, {"mat_motion_blur_rotation_intensity", "0"}, {"mat_motion_blur_strength", "0"}, {"mat_queue_mode", "1"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"},{"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_projectedtexture_filter", "0"}, {"cl_detaildist", "500"}, {"cl_detailfade", "400"}, {"mat_use_compressed_hdr_textures", "1"},  {"r_ambientboost", "0"}, {"r_decals", "60.00"}, {"r_drawparticles", "1"}, {"g_ragdoll_maxcount", "0"}, {"gmod_physiterations", "1"}, {"r_drawflecks", "0"}, {"r_drawrain", "0"}, {"r_drawropes", "0"}, {"r_drawsprites", "1"}, {"mat_alphacoverage", "0"}, {"gmod_mcore_test", "1"}, {"r_maxdlights", "0.00"}, {"r_shadowmaxrendered", "0.00"},  {"mat_compressedtextures", "1"}, {"ai_strong_optimizations", "1"}, {"r_radiosity", "2"}, {"ai_strong_optimizations_no_checkstand", "1"}, {"ai_expression_optimization", "1"}, {"r_flashlightdepthres", "256"}, {"spawnicon_queue", "1"}}
				for _, optimizeconvar in ipairs(optimizeconvar) do
					local name, value = unpack(optimizeconvar)
					LocalPlayer():ConCommand(name .. " " .. value)
					if CLIENT then
						print(name .. " " .. value)
					end
				end
			end

			setConvars()
			timer.Simple(
				1,
				function()
					if g_VR.active == true then
						LocalPlayer():ConCommand("vrmod_character_restart")
					end
				end
			)
		end
	)

	concommand.Add(
		"vrmod_gmod_optimization_03",
		function(ply, cmd, args)
			-- Gmodのluaコード
			local function setConvars()
				local optimizeconvar = {{"r_drawparticles", "0"}, {"mat_bumpmap", "0"}, {"mat_specular", "0"}, {"cl_detailfade", "100"}, {"mat_motion_blur_enabled", "0"}, {"mat_motion_blur_falling_intensity", "0"}, {"mat_motion_blur_falling_min", "0"}, {"mat_motion_blur_falling_max", "0"}, {"mat_motion_blur_rotation_intensity", "0"}, {"mat_motion_blur_strength", "0"}, {"mat_queue_mode", "-1"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_flashlightscissor", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"engine_no_focus_sleep", "0"}, {"r_mapextents", "5000"}, {"r_projectedtexture_filter", "0"}, {"cl_detaildist", "500"}, {"cl_detailfade", "400"}, {"mat_colorcorrection", "0"}, {"mat_dynamic_tonemapping", "0"}, {"mat_filtertextures", "1"}, {"mat_mipmaptextures", "1"}, {"mat_parallaxmap", "0"}, {"mat_use_compressed_hdr_textures", "1"}, {"r_ambientboost", "0"}, {"r_decals", "60.00"}, {"r_drawdecals", "0"}, {"r_drawdetailprops", "1"}, {"r_drawparticles", "1"}, {"r_farz", "-1"}, {"r_radiosity", "1"}, {"g_ragdoll_maxcount", "0"}, {"gmod_physiterations", "1"}, {"r_drawflecks", "0"}, {"r_drawrain", "0"}, {"r_drawropes", "0"}, {"r_drawsprites", "1"}, {"r_DrawDisp", "1"}, {"mat_alphacoverage", "0"}, {"gmod_mcore_test", "1"}, {"r_maxdlights", "0.00"}, {"r_shadow_allowbelow", "0"}, {"r_shadow_allowdynamic", "0"}, {"r_shadowfromanyworldlight", "0"}, {"r_shadowmaxrendered", "0.00"}, {"r_shadowrendertotexture", "0"}, {"mat_antialias", "0"}, {"mat_compressedtextures", "1"}, {"ai_strong_optimizations", "1"}, {"ai_expression_optimization", "1"}, {"spawnicon_queue", "1"}}
				for _, optimizeconvar in ipairs(optimizeconvar) do
					local name, value = unpack(optimizeconvar)
					LocalPlayer():ConCommand(name .. " " .. value)
					if CLIENT then
						print(name .. " " .. value)
					end
				end
			end

			setConvars()
			timer.Simple(
				1,
				function()
					if g_VR.active == true then
						LocalPlayer():ConCommand("vrmod_character_restart")
					end
				end
			)
		end
	)

	if CLIENT then
		local _, convars, convarValues = vrmod.GetConvars()
		local drivingmode = 0
		local bothmode = 0
		local ply = LocalPlayer()
		-- 以前のコマンドで設定されたconvarのリスト
		local optimizeconvar = {"mat_motion_blur_enabled", "mat_motion_blur_falling_intensity", "mat_motion_blur_falling_min", "mat_motion_blur_falling_max", "mat_motion_blur_rotation_intensity", "mat_motion_blur_strength", "mat_queue_mode", "r_WaterDrawReflection", "r_WaterDrawRefraction", "r_waterforceexpensive", "r_waterforcereflectentities", "fov_desired", "r_waterforceexpensive", "r_waterforcereflectentities", "engine_no_focus_sleep", "r_projectedtexture_filter", "cl_detaildist", "cl_detailfade", "mat_use_compressed_hdr_textures", "r_3dsky", "r_ambientboost", "r_decals", "r_drawparticles", "g_ragdoll_maxcount", "gmod_physiterations", "r_drawflecks", "r_drawrain", "r_drawropes", "r_drawsprites", "mat_alphacoverage", "gmod_mcore_test", "r_maxdlights", "r_shadowmaxrendered", "mat_compressedtextures", "ai_strong_optimizations", "r_radiosity", "ai_strong_optimizations_no_checkstand", "ai_expression_optimization", "r_flashlightdepthres", "spawnicon_queue"}
		-- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
		concommand.Add(
			"vrmod_gmod_optimization_reset",
			function(ply, cmd, args)
				for _, name in ipairs(optimizeconvar) do
					local default = GetConVar(name):GetDefault()
					LocalPlayer():ConCommand(name .. " " .. default)
				end

				timer.Simple(
					1,
					function()
						if g_VR.active == true then
							LocalPlayer():ConCommand("vrmod_restart")
						end
					end
				)
			end
		)
	end

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