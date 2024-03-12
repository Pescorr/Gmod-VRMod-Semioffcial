if CLIENT then
	local _, convars, convarValues = vrmod.GetConvars()
	local drivingmode = 0
	local bothmode = 0
	local ply = LocalPlayer()
	-- 以前のコマンドで設定されたconvarのリスト
	local optimizeconvar = {"mat_motion_blur_enabled", "mat_motion_blur_falling_intensity", "mat_motion_blur_falling_min", "mat_motion_blur_falling_max", "mat_motion_blur_rotation_intensity", "mat_motion_blur_strength", "mat_queue_mode", "r_WaterDrawReflection", "r_WaterDrawRefraction", "r_waterforceexpensive", "r_waterforcereflectentities", "engine_no_focus_sleep", "fov_desired", "fps_max", "SyntHud_max_ap", "cl_threaded_bone_setup", "cl_threaded_client_leaf_system", "r_threaded_client_shadow_manager", "r_threaded_particles", "r_threaded_renderables", "r_queued_ropes", "studio_queue_mode", "cl_forcepreload", "sv_forcepreload", "r_projectedtexture_filter", "cl_detaildist", "cl_detailfade", "cl_drawownshadow", "mat_bumpmap", "mat_colorcorrection", "mat_compressedtextures", "mat_dynamic_tonemapping", "mat_filtertextures", "mat_mipmaptextures", "mat_parallaxmap", "mat_showlowresimage", "mat_use_compressed_hdr_textures", "r_3dsky", "r_ambientboost", "r_decals", "r_drawdecals", "r_drawdetailprops", "r_drawparticles", "r_farz", "r_radiosity", "cl_ejectbrass", "g_ragdoll_maxcount", "gmod_physiterations", "mat_aaquality", "r_drawflecks", "r_drawrain", "r_drawropes", "r_drawskybox", "r_drawsprites", "r_DrawDisp", "r_drawstaticprops", "mat_alphacoverage", "mat_specular", "r_maxdlights", "r_shadow_allowbelow", "r_shadow_allowdynamic", "r_shadowfromanyworldlight", "r_shadowmaxrendered", "r_shadowrendertotexture", "r_shadow_lightpos_lerptime", "mat_antialias", "gmod_mcore_test", "ai_expression_optimization", "r_flashlightscissor", "spawnicon_queue", "r_mapextents"}
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

if CLIENT then
	hook.Add(
		"VRMod_Input",
		"vrutil_novrweapon",
		function(action, pressed)
			if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
			if action == "boolean_secondaryfire" then
				LocalPlayer():ConCommand(pressed and "arccw_dev_benchgun 1" or "arccw_dev_benchgun 0")

				return
			end

			if action == "boolean_use" then
				if pressed then
					if action == "boolean_secondaryfire" then
						if pressed then
							LocalPlayer():ConCommand("arccw_firemode")
							LocalPlayer():ConCommand("arccw_toggle_ubgl")
						end
					end

					return
				end
			end
		end
	)
end