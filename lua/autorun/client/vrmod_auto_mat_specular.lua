-- if CLIENT then
--     -- クライアント側のみで実行
--     -- クライアントコンバーの作成
--     CreateClientConVar("vrmod_auto_mat_specular_disable", "0", true, FCVAR_ARCHIVE, "VRモードで自動的にmat_specularを設定する（1=有効, 0=無効）", -1, 1)
--     -- マップ読み込み時に実行する関数
--     local function AutoSetMatSpecular()
--         local autoMatSpecular = GetConVar("vrmod_auto_mat_specular_disable"):GetBool()
--         if autoMatSpecular == 0 then
--             RunConsoleCommand("mat_specular", "-1")
--             print("VRMod: mat_specular automatically set to -1")
--         elseif autoMatSpecular == 1 then

--             -- local commands = {"mat_antialias", "0", "mat_aaquality", "0", "mat_filterlightmaps", "0", "mat_filtertextures", "0", "mat_disablehwmorph", "1", "r_staticprop_lod", "10", "mat_fastspecular", "0", "mat_trilinear", "0", "r_3dsky", "0", "r_dynamic", "0", "r_decals", "0", "r_drawmodeldecals", "0", "r_drawflecks", "0", "r_drawdetailprops", "0", "physgun_drawbeams", "0", "g_antlion_maxgibs", "0", "r_WaterDrawReflection", "0", "r_WaterDrawRefraction", "0", "mat_mipmaptextures", "1", "mat_reduceparticles", "1", "mat_reducefillrate", "1", "mat_disable_bloom", "1", "mat_disable_fancy_blending", "1", "mat_disable_lightwarp", "1", "mat_colorcorrection", "0", "mat_forceaniso", "1", "dsp_room", "0", "dsp_spatial", "0", "dsp_water", "0", "dsp_slow_cpu", "1", "snd_spatialize_roundrobin", "4", "r_shadows", "0", "r_shadow_allowdynamic", "0", "r_shadow_allowbelow", "0", "r_shadow_lightpos_lerptime", "0", "r_shadowfromworldlights", "0", "r_shadowrendertotexture", "0", "r_flashlightdepthres", "1", "r_flashlightdepthtexture", "0", "r_maxdlights", "0", "mp_show_voice_icons", "0", "r_fastzreject", "1", "r_fastzrejectdisp", "1", "sv_forcepreload", "1", "cl_forcepreload", "1", "mat_motion_blur_forward_enabled", "0", "ai_expression_optimization", "1", "sbox_bonemanip_misc", "0", "sbox_bonemanip_npc", "0", "hud_deathnotice_time", "0", {"mat_motion_blur_enabled", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}} -- "mat_picmip", "20", --"mat_bumpmap", "0", --"mat_specular", "0", --"mat_hdr_level", "0",

--             -- local function RunConsoleCommands()
-- 			-- 	for i = 1, #commands, 2 do
-- 			-- 		local cmd = commands[i]
-- 			-- 		local arg = commands[i + 1]
-- 			-- 		RunConsoleCommand(cmd, arg)
-- 			-- 	end
-- 			-- end

-- 			-- RunConsoleCommands()
--             RunConsoleCommand("mat_specular", "0")
--             print("VRMod: mat_specular automatically set to 0")
--         else
--             return
--         end
--     end

--     -- マップ読み込み開始時にフックを追加
--     hook.Add("InitPostEntity", "VRModAutoMatSpecular", AutoSetMatSpecular)
-- end