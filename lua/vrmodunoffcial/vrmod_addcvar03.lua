if CLIENT then return end
-- コンソールコマンド 'remove_reflective_glass' を追加して、func_reflective_glass エンティティを削除する
concommand.Add(
    "remove_reflective_glass",
    function(ply, cmd, args)
        -- 実行者が管理者か確認
        if not IsValid(ply) or ply:IsAdmin() then
            -- func_reflective_glass エンティティを検索して削除
            for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
                ent:Remove()
            end

            -- 実行者がいる場合は、操作が成功したことを通知
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTCONSOLE, "Removed all func_reflective_glass entities.")
            end
        else
            -- 実行者が管理者でない場合は、拒否メッセージを表示
            ply:PrintMessage(HUD_PRINTCONSOLE, "You must be an admin to use this command.")
        end
    end
)

-- local commands = {
--     "mat_antialias", "0",
--     "mat_aaquality", "0",
--     "mat_filterlightmaps", "0",
--     -- "mat_picmip", "20",
--     "mat_filtertextures", "0",
--     "mat_disablehwmorph", "1",
--     "r_lod", "10",
--     "r_staticprop_lod", "10",
--     --"mat_bumpmap", "0",
--     "mat_fastspecular", "0",
--     --"mat_specular", "0",
--     "mat_trilinear", "0",
--     "r_3dsky", "0",
--     "r_dynamic", "0",
--     "r_decals", "0",
--     "r_drawmodeldecals", "0",
--     "r_drawflecks", "0",
--     "r_drawdetailprops", "0",
--     "physgun_drawbeams", "0",
--     "g_antlion_maxgibs", "0",
--     "r_WaterDrawReflection", "0",
--     "r_WaterDrawRefraction", "0",
--     "mat_mipmaptextures", "1",
--     "mat_reduceparticles", "1",
--     "mat_reducefillrate", "1",
--     "mat_disable_bloom", "1",
--     "mat_disable_fancy_blending", "1",
--     "mat_disable_lightwarp", "1",
--     --"mat_hdr_level", "0",
--     "mat_colorcorrection", "0",
--     "mat_forceaniso", "1",
--     "dsp_room", "0",
--     "dsp_spatial", "0",
--     "dsp_water", "0",
--     "dsp_slow_cpu", "1",
--     "snd_spatialize_roundrobin", "4",
--     "r_shadows", "0",
--     "r_shadow_allowdynamic", "0",
--     "r_shadow_allowbelow", "0",
--     "r_shadow_lightpos_lerptime", "0",
--     "r_shadowfromworldlights", "0",
--     "r_shadowrendertotexture", "0",
--     "r_flashlightdepthres", "1",
--     "r_flashlightdepthtexture", "0",
--     "r_maxdlights", "0",
--     "mp_show_voice_icons", "0",
--     "r_fastzreject", "1",
--     "r_fastzrejectdisp", "1",
--     "sv_forcepreload", "1",
--     "cl_forcepreload", "1",
--     "mat_motion_blur_forward_enabled", "0",
--     "ai_expression_optimization", "1",
--     "sbox_bonemanip_misc", "0",
--     "sbox_bonemanip_npc", "0",
--     "hud_deathnotice_time", "0"
-- }
-- local function RunConsoleCommands()
--     for i = 1, #commands, 2 do
--         local cmd = commands[i]
--         local arg = commands[i + 1]
--         RunConsoleCommand(cmd, arg)
--     end
-- end

-- hook.Add(
--     "PlayerInitialSpawn",
--     "RunMyConsoleCommands",
--     function(ply)
--         -- if ply:IsAdmin() then
--         --     RunConsoleCommands()
--         -- end

--         concommand.Add(
--             "fps_performance_0",
--             function(ply, cmd, args)
--                 if ply:IsAdmin() then
--                     RunConsoleCommands()
--                 end
--             end
--         )
--     end
-- )