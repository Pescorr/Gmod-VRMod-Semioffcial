AddCSLuaFile()
if SERVER then return end
local _, convars, convarValues = vrmod.GetConvars()
local autoscrsetting = CreateClientConVar("vrmod_scr_alwaysautosetting", 1, true, FCVAR_ARCHIVE)
local autooptimize = CreateClientConVar("vrmod_gmod_optimization_auto", 1, true, FCVAR_ARCHIVE)
local vrautobenchgun = CreateClientConVar("vrmod_auto_arc_benchgun", 1, true, FCVAR_ARCHIVE)
local lvsautosetting = CreateClientConVar("vrmod_auto_lvs_keysetings", 1, true, FCVAR_ARCHIVE)
hook.Add(
    "VRMod_Start",
    "VRMod_changesettings",
    function(ply)
        if ply ~= LocalPlayer() then return end
        if vrautobenchgun:GetBool() then
            LocalPlayer():ConCommand("cl_tfa_fx_rtscopeblur_mode 0")
            LocalPlayer():ConCommand("cl_tfa_fx_rtscopeblur_passes 0")
            LocalPlayer():ConCommand("cl_tfa_fx_rtscopeblur_intensity 0")
            LocalPlayer():ConCommand("cl_tfa_fx_ads_dof 0")
            LocalPlayer():ConCommand("cl_tfa_fx_ads_dof_hd 0")
            LocalPlayer():ConCommand("cl_tfa_3dscope_overlay 0")
            LocalPlayer():ConCommand("sv_tfa_sprint_enabled 0")
            LocalPlayer():ConCommand("cl_tfa_ironsights_toggle 0")
            LocalPlayer():ConCommand("arc9_dev_benchgun 1")
            LocalPlayer():ConCommand("arc9_tpik 0")
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
            LocalPlayer():ConCommand("arc9_dtap_sights 1")
            LocalPlayer():ConCommand("arc9_fx_animblur 0")
            LocalPlayer():ConCommand("tacrp_quicknade 1")
            LocalPlayer():ConCommand("tacrp_freeaim 0")
            LocalPlayer():ConCommand("arccw_blur_toytown 0")
            LocalPlayer():ConCommand("arccw_blur 0")
            LocalPlayer():ConCommand("arccw_dev_benchgun 1")
            LocalPlayer():ConCommand("arccw_hud_size 0")
        end

        if lvsautosetting:GetBool() then
            LocalPlayer():ConCommand("vrmod_lfsmode")
            LocalPlayer():ConCommand("lvs_mouseaim 1")
            LocalPlayer():ConCommand("lvs_select_weapon1 112")
            LocalPlayer():ConCommand("lvs_select_weapon2 113")
            LocalPlayer():ConCommand("lvs_select_weapon3 110")
            LocalPlayer():ConCommand("lvs_select_weapon4 111")
            LocalPlayer():ConCommand("lvs_edit_hud 0")
        end

        if autoscrsetting:GetBool() then
            LocalPlayer():ConCommand("vrmod_Scr_Auto")
        end
    end
)

-- if autooptimize:GetBool() and g_VR.active then
--     LocalPlayer():ConCommand("vrmod_seatedoffset -100000")
--     LocalPlayer():ConCommand("vrmod_seated 1")
--     timer.Simple(
--         10.0,
--         function()
--             LocalPlayer():ConCommand("vrmod_seatedoffset 0")
--             LocalPlayer():ConCommand("vrmod_seated 0")
--         end
--     )
-- end
hook.Add(
    "VRMod_Menu",
    "VRMod_changesettings_menu",
    function(ply)
        if ply ~= LocalPlayer() then return end
        if lvsautosetting:GetBool() then
            -- 以前のコマンドで設定されたconvarのリスト
            local lvsconvar = {"lvs_mouseaim", "lvs_select_weapon1", "lvs_select_weapon2", "lvs_select_weapon3", "lvs_select_weapon4", "gred_cl_simfphys_key_togglezoom", "lvs_edit_hud"}
            -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
            if not LVS then return end
            for _, lvsname in ipairs(lvsconvar) do
                local lvsdefault = GetConVar(lvsname):GetDefault()
                LocalPlayer():ConCommand(lvsname .. " " .. lvsdefault)
            end
        end

        if vrautobenchgun:GetBool() then
            -- 以前のコマンドで設定されたconvarのリスト
            local arcconvar = {"arc9_dev_benchgun", "arc9_tpik", "arc9_dtap_sights", "arc9_cheapscopes", "arc9_controller", "arc9_autolean", "arc9_never_ready", "arc9_vm_cambob", "arc9_vm_cambobwalk", "arc9_breath_pp", "arc9_fx_rtblur", "arc9_fx_adsblur", "arc9_fx_reloadblur", "arc9_fx_animblur", "cl_tfa_fx_rtscopeblur_mode", "cl_tfa_fx_rtscopeblur_passes", "cl_tfa_fx_rtscopeblur_intensity", "cl_tfa_fx_ads_dof", "cl_tfa_fx_ads_dof_hd", "cl_tfa_3dscope_overlay", "sv_tfa_sprint_enabled", "cl_tfa_ironsights_toggle", "arccw_blur_toytown", "arccw_blur", "arccw_hud_size"}
            -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
            if not arc then return end
            for _, arcname in ipairs(arcconvar) do
                local arcdefault = GetConVar(arcname):GetDefault()
                LocalPlayer():ConCommand(arcname .. " " .. arcdefault)
            end
        end
    end
)

concommand.Add(
    "vrmod_autosetting_reset",
    function(ply, cmd, args)
        if ply ~= LocalPlayer() then return end
        if lvsautosetting:GetBool() then
            -- 以前のコマンドで設定されたconvarのリスト
            local lvsconvar = {"lvs_mouseaim", "lvs_select_weapon1", "lvs_select_weapon2", "lvs_select_weapon3", "lvs_select_weapon4", "gred_cl_simfphys_key_togglezoom", "lvs_edit_hud"}
            -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
            if not LVS then return end
            for _, lvsname in ipairs(lvsconvar) do
                local lvsdefault = GetConVar(lvsname):GetDefault()
                LocalPlayer():ConCommand(lvsname .. " " .. lvsdefault)
            end
        end

        if vrautobenchgun:GetBool() then
            -- 以前のコマンドで設定されたconvarのリスト
            local arcconvar = {"arc9_dev_benchgun", "arc9_tpik", "arc9_dtap_sights", "arc9_cheapscopes", "arc9_controller", "arc9_autolean", "arc9_never_ready", "arc9_vm_cambob", "arc9_vm_cambobwalk", "arc9_breath_pp", "arc9_fx_rtblur", "arc9_fx_adsblur", "arc9_fx_reloadblur", "arc9_fx_animblur", "cl_tfa_fx_rtscopeblur_mode", "cl_tfa_fx_rtscopeblur_passes", "cl_tfa_fx_rtscopeblur_intensity", "cl_tfa_fx_ads_dof", "cl_tfa_fx_ads_dof_hd", "cl_tfa_3dscope_overlay", "sv_tfa_sprint_enabled", "cl_tfa_ironsights_toggle", "arccw_blur_toytown", "arccw_blur", "arccw_hud_size"}
            -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
            if not arc then return end
            for _, arcname in ipairs(arcconvar) do
                local arcdefault = GetConVar(arcname):GetDefault()
                LocalPlayer():ConCommand(arcname .. " " .. arcdefault)
            end
        end
    end
)

if CLIENT then
    hook.Add(
        "CreateMove",
        "vrmod_startup_setting_default",
        function()
            hook.Remove("CreateMove", "vrmod_startup_setting_default")
            timer.Simple(
                1,
                function()
                    if ply ~= LocalPlayer() then return end
                    if lvsautosetting:GetBool() then
                        -- 以前のコマンドで設定されたconvarのリスト
                        local lvsconvar = {"lvs_mouseaim", "lvs_select_weapon1", "lvs_select_weapon2", "lvs_select_weapon3", "lvs_select_weapon4", "gred_cl_simfphys_key_togglezoom", "lvs_edit_hud"}
                        -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
                        if not LVS then return end
                        for _, lvsname in ipairs(lvsconvar) do
                            local lvsdefault = GetConVar(lvsname):GetDefault()
                            LocalPlayer():ConCommand(lvsname .. " " .. lvsdefault)
                        end
                    end

                    if vrautobenchgun:GetBool() then
                        -- 以前のコマンドで設定されたconvarのリスト
                        local arcconvar = {"arc9_dev_benchgun", "arc9_tpik", "arc9_dtap_sights", "arc9_cheapscopes", "arc9_controller", "arc9_autolean", "arc9_never_ready", "arc9_vm_cambob", "arc9_vm_cambobwalk", "arc9_breath_pp", "arc9_fx_rtblur", "arc9_fx_adsblur", "arc9_fx_reloadblur", "arc9_fx_animblur", "cl_tfa_fx_rtscopeblur_mode", "cl_tfa_fx_rtscopeblur_passes", "cl_tfa_fx_rtscopeblur_intensity", "cl_tfa_fx_ads_dof", "cl_tfa_fx_ads_dof_hd", "cl_tfa_3dscope_overlay", "sv_tfa_sprint_enabled", "cl_tfa_ironsights_toggle", "arccw_blur_toytown", "arccw_blur", "arccw_hud_size"}
                        -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
                        if not arc then return end
                        for _, arcname in ipairs(arcconvar) do
                            local arcdefault = GetConVar(arcname):GetDefault()
                            LocalPlayer():ConCommand(arcname .. " " .. arcdefault)
                        end
                    end

                    LocalPlayer():ConCommand("vrmod_autosetting_reset")
                    print("asoighbqio")
                end
            )
        end
    )
end

hook.Add(
    "VRMod_Exit",
    "VRMod_changesettings",
    function(ply)
        if ply ~= LocalPlayer() then return end
        if lvsautosetting:GetBool() then
            -- 以前のコマンドで設定されたconvarのリスト
            local lvsconvar = {"lvs_mouseaim", "lvs_select_weapon1", "lvs_select_weapon2", "lvs_select_weapon3", "lvs_select_weapon4", "lvs_edit_hud"}
            if not LVS then return end
            for _, lvsname in ipairs(lvsconvar) do
                local lvsdefault = GetConVar(lvsname):GetDefault()
                LocalPlayer():ConCommand(lvsname .. " " .. lvsdefault)
            end
        end

        if vrautobenchgun:GetBool() then
            -- 以前のコマンドで設定されたconvarのリスト
            local arcconvar = {"arc9_dev_benchgun", "arc9_tpik", "arc9_dtap_sights", "arc9_cheapscopes", "arc9_controller", "arc9_autolean", "arc9_never_ready", "arc9_vm_cambob", "arc9_vm_cambobwalk", "arc9_breath_pp", "arc9_fx_rtblur", "arc9_fx_adsblur", "arc9_fx_reloadblur", "arc9_fx_animblur", "cl_tfa_fx_rtscopeblur_mode", "cl_tfa_fx_rtscopeblur_passes", "cl_tfa_fx_rtscopeblur_intensity", "cl_tfa_fx_ads_dof", "cl_tfa_fx_ads_dof_hd", "cl_tfa_3dscope_overlay", "sv_tfa_sprint_enabled", "cl_tfa_ironsights_toggle", "arccw_blur_toytown", "arccw_hud_size", "arccw_blur", "tacrp_quicknade"}
            -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
            if not arc then return end
            for _, arcname in ipairs(arcconvar) do
                local arcdefault = GetConVar(arcname):GetDefault()
                LocalPlayer():ConCommand(arcname .. " " .. arcdefault)
            end
        end

        LocalPlayer():ConCommand("vrmod_character_stop")
    end
)