-- vrmod_presets.lua
if SERVER then return end
local PRESET_FOLDER = "vrmod_presets"
local PRESET_EXTENSION = ".txt"
-- プリセットフォルダが存在しない場合は作成
if not file.Exists(PRESET_FOLDER, "DATA") then
    file.CreateDir(PRESET_FOLDER)
end

-- VR関連のConVarリスト
local VR_CONVARS = {
    "arcticvr_2h_sens",
    "arcticvr_allgun_allow_attachment",
    "arcticvr_allgun_allow_reloadkey",
    "arcticvr_allgun_allow_reloadkey_client",
    "arcticvr_bumpreload_allgun",
    "arcticvr_bumpreload_allgun_client",
    "arcticvr_customswep_clipsize",
    "arcticvr_customswep_damage",
    "arcticvr_customswep_model",
    "arcticvr_customswep_primaryammo",
    "arcticvr_customswep_printName",
    "arcticvr_customswep_slotnum",
    "arcticvr_customswep_slotpos",
    "arcticvr_defaultammo_normalize",
    "arcticvr_defpouchdist",
    "arcticvr_disable_grabreload",
    "arcticvr_disable_reloadkey",
    "arcticvr_entthrower_001",
    "arcticvr_entthrower_002",
    "arcticvr_entthrower_003",
    "arcticvr_fist",
    "arcticvr_fist_client",
    "arcticvr_grip_alternative_mode",
    "arcticvr_grip_magnification",
    "arcticvr_grip_withreloadkey",
    "arcticvr_gunmelee",
    "arcticvr_gunmelee_client",
    "arcticvr_gunmelee_damage",
    "arcticvr_gunmelee_Delay",
    "arcticvr_gunmelee_velthreshold",
    "arcticvr_headpouch",
    "arcticvr_headpouchdist",
    "arcticvr_hybridpouch",
    "arcticvr_hybridpouchdist",
    "arcticvr_infpouch",
    "arcticvr_kick",
    "arcticvr_kick_client",
    "arcticvr_mag_bumpreload",
    "arcticvr_magbug_bullet",
    "arcticvr_net_magtimertime",
    "arcticvr_physical_bullets",
    "arcticvr_printgvr",
    "arcticvr_printmats",
    "arcticvr_printvmbones",
    "arcticvr_shootsys",
    "arcticvr_slide_magnification",
    "arcticvr_test_cl_misc_fix",
    "arcticvr_virtualstock",
    "cl_streamradi_vr_enable_cursor",
    "cl_streamradio_vr_enable_touch",
    "cl_streamradio_vr_enable_trigger",
    "cvrg_version",
    "genkidamaVRdebugButtons",
    "genkidamaVRforceButtonsActive",
    "pac_optimization_render_once_per_frame",
    "vr_dummy_menu_toggle",
    "vr_pickup_disable_client",
    "vre_addvrmenu",
    "vre_binds_concommands",
    "vre_callibrateheight",
    "vre_closedcaptions",
    "vre_gb-radial",
    "vre_hidehint",
    "vre_key_chat_held",
    "vre_menu",
    "vre_svmenu",
    "vre_ui_attachtohand",
    "vrgrab_gravitygloves",
    "vrgrab_gravitygloves_minrange",
    "vrgrab_maxmass",
    "vrgrab_range",
    "vrgrab_range_palm",
    "vrmelee_cooldown",
    "vrmelee_damage_high",
    "vrmelee_damage_low",
    "vrmelee_damage_medium",
    "vrmelee_damage_velocity_high",
    "vrmelee_damage_velocity_low",
    "vrmelee_damage_velocity_medium",
    "vrmelee_default",
    "vrmelee_delay",
    "vrmelee_emulatebloack_Threshold_High",
    "vrmelee_emulatebloack_Threshold_Low",
    "vrmelee_emulateblockbutton",
    "vrmelee_emulateblockbutton_release",
    "vrmelee_emulateblocking",
    "vrmelee_fist",
    "vrmelee_fist_collision",
    "vrmelee_fist_collisionmodel",
    "vrmelee_fist_visible",
    "vrmelee_gunmelee",
    "vrmelee_gunmelee_command",
    "vrmelee_impact",
    "vrmelee_kick",
    "vrmelee_leftfoot_command",
    "vrmelee_lefthand_command",
    "vrmelee_ragdoll_pickup",
    "vrmelee_ragdollpickup_left",
    "vrmelee_ragdollpickup_range",
    "vrmelee_ragdollpickup_right",
    "vrmelee_rightfoot_command",
    "vrmelee_righthand_command",
    "vrmelee_usefist",
    "vrmelee_usegunmelee",
    "vrmelee_usekick",
    "vrmod",
    "vrmod_actioneditor",
    "vrmod_allow_teleport",
    "vrmod_allow_teleport_client",
    "vrmod_althead",
    "vrmod_animation_Enable",
    "vrmod_apply_optimization",
    "vrmod_attach_heightmenu",
    "vrmod_attach_popup",
    "vrmod_attach_quickmenu",
    "vrmod_attach_weaponmenu",
    "vrmod_auto_arc_benchgun",
    "vrmod_auto_lvs_keysetings",
    "vrmod_autojumpduck",
    "vrmod_autosetting_reset",
    "vrmod_autostart",
    "vrmod_bindingversion",
    "vrmod_cameraoverride",
    "vrmod_character_auto",
    "vrmod_character_reset",
    "vrmod_character_start",
    "vrmod_character_stop",
    "vrmod_characterEyeHeight",
    "vrmod_characterHeadToHmdDist",
    "vrmod_chatmode",
    "vrmod_Clipboard",
    "vrmod_cmd_contextmenu_close",
    "vrmod_cmd_contextmenu_open",
    "vrmod_cmd_spawnmenu_close",
    "vrmod_cmd_spawnmenu_open",
    "vrmod_configversion",
    "vrmod_controlleroffset_pitch",
    "vrmod_controlleroffset_roll",
    "vrmod_controlleroffset_x",
    "vrmod_controlleroffset_y",
    "vrmod_controlleroffset_yaw",
    "vrmod_controlleroffset_z",
    "vrmod_controlleroriented",
    "vrmod_crouchthreshold",
    "vrmod_data_vmt_generate_test",
    "vrmod_debuglocomotion",
    "vrmod_desktopview",
    "vrmod_dev_pickup_limit_droptest",
    "vrmod_dev_climbtest",
    "vrmod_dev_lua_reinclude_original",
    "vrmod_dev_lua_reinclude_semioffcial",
    "vrmod_dev_original_excluded_files",
    "vrmod_dev_unoffcial_folder_excluded_files",
    "vrmod_dev_unoffcial_folder_file_operation",
    "vrmod_dev_vrmod_original_folder_file_operation",
    "vrmod_disable_mirrors",
    "vrmod_doordebug",
    "vrmod_doors",
    "vrmod_emergencystop_key",
    "vrmod_emergencystop_time",
    "vrmod_enable_contextmenu_button",
    "vrmod_error_check_method",
    "vrmod_error_hard",
    "vrmod_exit",
    "vrmod_flashlight_attachment",
    "vrmod_floatinghands",
    "vrmod_floatinghands_material",
    "vrmod_floatinghands_model",
    "vrmod_Foregripmode",
    "vrmod_Foregripmode_enable",
    "vrmod_Foregripmode_key_leftgrab",
    "vrmod_Foregripmode_key_leftprimary",
    "vrmod_Foregripmode_range",
    "vrmod_gbradial_cmd_close",
    "vrmod_gbradial_cmd_open",
    "vrmod_gmod_optimization",
    "vrmod_gmod_optimization_02",
    "vrmod_gmod_optimization_03",
    "vrmod_gmod_optimization_auto",
    "vrmod_gmod_optimization_reset",
    "vrmod_gmod_optimize_load",
    "vrmod_gmod_optimize_save",
    "vrmod_halo_enable",
    "vrmod_heightmenu",
    "vrmod_hmdoffset_pitch",
    "vrmod_hmdoffset_roll",
    "vrmod_hmdoffset_x",
    "vrmod_hmdoffset_y",
    "vrmod_hmdoffset_yaw",
    "vrmod_hmdoffset_z",
    "vrmod_hook_character",
    "vrmod_hook_dermapopup",
    "vrmod_hook_hud",
    "vrmod_hook_vrmod",
    "vrmod_hud",
    "vrmod_hud_visible_quickmenukey",
    "vrmod_hudblacklist",
    "vrmod_hudcurve",
    "vrmod_huddistance",
    "vrmod_hudscale",
    "vrmod_hudtestalpha",
    "vrmod_idle_act",
    "vrmod_info",
    "vrmod_jump_act",
    "vrmod_keyboard",
    "vrmod_keyboard_uichatkey",
    "vrmod_keymode_both",
    "vrmod_keymode_driving",
    "vrmod_keymode_main",
    "vrmod_keymode_restore",
    "vrmod_laserpointer",
    "vrmod_lefthand",
    "vrmod_lefthandleftfire",
    "vrmod_LeftHandmode",
    "vrmod_lfsmode",
    "vrmod_locomotion",
    "vrmod_lua_reset",
    "vrmod_lua_reset_character",
    "vrmod_lua_reset_character_hands",
    "vrmod_lua_reset_pickup",
    "vrmod_lua_reset_pickup_arcvr",
    "vrmod_lvs_pickup_handle",
    "vrmod_mag_ang_p",
    "vrmod_mag_ang_r",
    "vrmod_mag_ang_y",
    "vrmod_mag_ejectbone_enable",
    "vrmod_mag_pos_x",
    "vrmod_mag_pos_y",
    "vrmod_mag_pos_z",
    "vrmod_mag_system_enable",
    "vrmod_lua_reset_ui",
    "vrmod_mag_ejectbone_enable",
    "vrmod_magazine_reset",
    "vrmod_magent_model",
    "vrmod_magent_range",
    "vrmod_magent_sound",
    "vrmod_manualpickups",
    "vrmod_mapbrowser",
    "vrmod_menu_type",
    "vrmod_mirror_optimization",
    "vrmod_net_debug",
    "vrmod_net_delay",
    "vrmod_net_delaymax",
    "vrmod_net_storedframes",
    "vrmod_net_tickrate",
    "vrmod_oldcharacteryaw",
    "vrmod_pickup_beam_damage",
    "vrmod_pickup_beam_damage_enable",
    "vrmod_pickup_beam_enable",
    "vrmod_pickup_beam_left",
    "vrmod_pickup_beam_ragdoll_spine",
    "vrmod_pickup_beam_right",
    "vrmod_pickup_beamrange",
    "vrmod_pickup_beamrange02",
    "vrmod_pickup_centered",
    "vrmod_pickup_limit",
    "vrmod_pickup_range",
    "vrmod_pickup_weight",
    "vrmod_pickupoff_weaponholster",
    "vrmod_pmchange",
    "vrmod_postprocess",
    "vrmod_pouch_enabled",
    "vrmod_pouch_lefthandwep_enable",
    "vrmod_pouch_pickup_sound",
    "vrmod_pouch_size_1",
    "vrmod_pouch_size_2",
    "vrmod_pouch_size_3",
    "vrmod_pouch_size_4",
    "vrmod_pouch_size_5",
    "vrmod_pouch_visiblename",
    "vrmod_pouch_visiblename_hud",
    "vrmod_pouch_weapon_1",
    "vrmod_pouch_weapon_2",
    "vrmod_pouch_weapon_3",
    "vrmod_pouch_weapon_4",
    "vrmod_pouch_weapon_5",
    "vrmod_preset_list",
    "vrmod_preset_load",
    "vrmod_preset_save",
    "vrmod_print_devices",
    "vrmod_quickmenu_arccw",
    "vrmod_quickmenu_chat",
    "vrmod_quickmenu_context_menu",
    "vrmod_quickmenu_exit",
    "vrmod_quickmenu_mapbrowser_enable",
    "vrmod_quickmenu_noclip",
    "vrmod_quickmenu_seated_menu",
    "vrmod_quickmenu_spawn_menu",
    "vrmod_quickmenu_togglemirror",
    "vrmod_quickmenu_togglevehiclemode",
    "vrmod_quickmenu_vgui_reset_menu",
    "vrmod_quickmenu_vre_gbradial_menu",
    "vrmod_reflective_glass_toggle",
    "vrmod_reset",
    "vrmod_reset_render_targets",
    "vrmod_restart",
    "vrmod_rtHeight_Multiplier",
    "vrmod_rtWidth_Multiplier",
    "vrmod_run_act",
    "vrmod_scale",
    "vrmod_scale_apply",
    "vrmod_scale_auto",
    "vrmod_scr_alwaysautosetting",
    "vrmod_Scr_Auto",
    "vrmod_ScrH",
    "vrmod_ScrH_hud",
    "vrmod_ScrW",
    "vrmod_ScrW_hud",
    "vrmod_seated",
    "vrmod_seatedoffset",
    "vrmod_seatedoffset_auto",
    "vrmod_showmanualoptimizationtabs",
    "vrmod_showonstartup",
    "vrmod_sight_bodypart",
    "vrmod_simfmode",
    "vrmod_smoothturn",
    "vrmod_smoothturnrate",
    "vrmod_stabilize_hmdni",
    "vrmod_start",
    "vrmod_teleport_run_jump_walkkey",
    "vrmod_test_analogmoveonly",
    "vrmod_test_entteleport_range",
    "vrmod_test_lefthandle",
    "vrmod_test_pickup_entspawn_left",
    "vrmod_test_pickup_entspawn_right",
    "vrmod_test_pickup_entteleport_left",
    "vrmod_test_pickup_entteleport_right",
    "vrmod_test_Righthandle",
    "vrmod_test_ui_testver",
    "vrmod_togglelaserpointer",
    "vrmod_ui_outline",
    "vrmod_ui_realtime",
    "vrmod_update_render_targets",
    "vrmod_useworldmodels",
    "vrmod_vehicle_bothkeymode",
    "vrmod_vehicle_reticlemode",
    "vrmod_version",
    "vrmod_vgui_reset",
    "vrmod_walk_act",
    "vrmod_weaponconfig",
    "vrmod_weapondrop_enable",
    "vrmod_weapondrop_trashwep",
    "vrmod_weppouch_customcvar_head_cmd",
    "vrmod_weppouch_customcvar_head_enable",
    "vrmod_weppouch_customcvar_head_put_cmd",
    "vrmod_weppouch_customcvar_left_head_cmd",
    "vrmod_weppouch_customcvar_left_head_enable",
    "vrmod_weppouch_customcvar_left_head_put_cmd",
    "vrmod_weppouch_customcvar_left_pelvis_cmd",
    "vrmod_weppouch_customcvar_left_pelvis_enable",
    "vrmod_weppouch_customcvar_left_pelvis_put_cmd",
    "vrmod_weppouch_customcvar_left_spine_cmd",
    "vrmod_weppouch_customcvar_left_spine_enable",
    "vrmod_weppouch_customcvar_left_spine_put_cmd",
    "vrmod_weppouch_customcvar_pelvis_cmd",
    "vrmod_weppouch_customcvar_pelvis",
    "vrmod_weppouch_customcvar_pelvis_enable",
    "vrmod_weppouch_customcvar_pelvis_put_cmd",
    "vrmod_weppouch_customcvar_spine_cmd",
    "vrmod_weppouch_customcvar_spine_enable",
    "vrmod_weppouch_customcvar_spine_put_cmd",
    "vrmod_weppouch_dist_head",
    "vrmod_weppouch_dist_Pelvis",
    "vrmod_weppouch_dist_spine",
    "vrmod_weppouch_Head",
    "vrmod_weppouch_left_dist_head",
    "vrmod_weppouch_left_dist_Pelvis",
    "vrmod_weppouch_left_dist_spine",
    "vrmod_weppouch_left_Head",
    "vrmod_weppouch_left_Pelvis",
    "vrmod_weppouch_left_Spine",
    "vrmod_weppouch_Pelvis",
    "vrmod_weppouch_Spine",
    "vrmod_weppouch_visiblename",
    "vrmod_weppouch_visiblerange",
    "vrmod_weppouch_weapon_Head",
    "vrmod_weppouch_weapon_left_Head",
    "vrmod_weppouch_weapon_left_Pelvis",
    "vrmod_weppouch_weapon_left_Spine",
    "vrmod_weppouch_weapon_lock_Head",
    "vrmod_weppouch_weapon_lock_left_Head",
    "vrmod_weppouch_weapon_lock_left_Pelvis",
    "vrmod_weppouch_weapon_lock_left_Spine",
    "vrmod_weppouch_weapon_lock_Pelvis",
    "vrmod_weppouch_weapon_lock_Spine",
    "vrmod_weppouch_weapon_Pelvis",
    "vrmod_weppouch_weapon_Spine",
    "vrmelee_default",
    "vrmelee_gunmelee_command",
    "vrmelee_leftfoot_command",
    "vrmelee_lefthand_command",
    "vrmelee_ragdoll_pickup",
    "vrmelee_ragdollpickup_left",
    "vrmelee_ragdollpickup_right",
    "vrmelee_rightfoot_command",
    "vrmelee_righthand_command",
    "vrmag_ang_p",
    "vrmag_ang_r",
    "vrmag_ang_y",
    "vrmag_bones",
    "vrmag_ejectbone_enable",
    "vrmag_ejectbone_type",
    "vrmag_pos_x",
    "vrmag_pos_y",
    "vrmag_pos_z",
    "vrmag_system_enable",
    "vrgrab_gravitygloves",
    "vrgrab_gravitygloves_minrange",
    "vrgrab_maxmass",
    "vrgrab_range",
    "vrgrab_range_palm",
    "vre_addvrmenu",
    "vre_binds_concommands",
    "vre_callibrateheight",
    "vre_closedcaptions",
    "vre_gb-radial",
    "vre_hidehint",
    "vre_key_chat_held",
    "vre_menu",
    "vre_svmenu",
    "vre_ui_attachtohand",
    "vr_pickup_disable_client",
    "vr_pickup_disable_client",
    "vre_addvrmenu",
    "vre_binds_concommands",
    "vre_callibrateheight",
    "vre_closedcaptions",
    "vre_gb-radial",
    "vre_hidehint",
    "vre_key_chat_held",
    "vre_menu",
    "vre_svmenu",
    "vre_ui_attachtohand",
    "vrmod_znear"
    }

    
    -- VR関連のConVarを取得
local function GetVRConVars()
    local vr_convars = {}
    for _, cvar_name in ipairs(VR_CONVARS) do
        local cvar = GetConVar(cvar_name)
        if cvar then
            vr_convars[cvar_name] = cvar:GetString()
        end
    end

    return vr_convars
end

-- プリセットを保存
local function SavePreset(name)
    local vr_convars = GetVRConVars()
    local json = util.TableToJSON(vr_convars, true)
    file.Write(PRESET_FOLDER .. "/" .. name .. PRESET_EXTENSION, json)
    print("VRMod preset saved: " .. name)
end

-- プリセットをロード
local function LoadPreset(name)
    local content = file.Read(PRESET_FOLDER .. "/" .. name .. PRESET_EXTENSION, "DATA")
    if content then
        local vr_convars = util.JSONToTable(content)
        for cvar_name, value in pairs(vr_convars) do
            RunConsoleCommand(cvar_name, value)
        end

        print("VRMod preset loaded: " .. name)
    else
        print("VRMod preset not found: " .. name)
    end
end

-- プリセットリストを取得
local function GetPresetList()
    local files, _ = file.Find(PRESET_FOLDER .. "/*" .. PRESET_EXTENSION, "DATA")
    local presets = {}
    for _, f in ipairs(files) do
        table.insert(presets, string.sub(f, 1, -#PRESET_EXTENSION - 1))
    end

    return presets
end

-- コンソールコマンドを追加
concommand.Add(
    "vrmod_preset_save",
    function(ply, cmd, args)
        if #args < 1 then
            print("Usage: vrmod_preset_save <preset_name>")

            return
        end

        SavePreset(args[1])
    end
)

concommand.Add(
    "vrmod_preset_load",
    function(ply, cmd, args)
        if #args < 1 then
            print("Usage: vrmod_preset_load <preset_name>")

            return
        end

        LoadPreset(args[1])
    end
)

concommand.Add(
    "vrmod_preset_list",
    function(ply, cmd, args)
        local presets = GetPresetList()
        print("VRMod Presets:")
        for _, preset in ipairs(presets) do
            print("- " .. preset)
        end
    end
)

-- GUIメニューにプリセット機能を追加
hook.Add(
    "VRMod_Menu",
    "vrmod_presets",
    function(frame)
        local presetPanel = vgui.Create("DPanel", frame)
        presetPanel:SetSize(300, 230) -- パネルの高さを増加
        presetPanel:Dock(TOP)
        local presetList = vgui.Create("DListView", presetPanel)
        presetList:Dock(FILL)
        presetList:AddColumn("Presets")
        local function RefreshPresetList()
            presetList:Clear()
            for _, preset in ipairs(GetPresetList()) do
                presetList:AddLine(preset)
            end
        end

        RefreshPresetList()
        local presetNameEntry = vgui.Create("DTextEntry", presetPanel)
        presetNameEntry:SetPlaceholderText("Enter preset name")
        presetNameEntry:Dock(BOTTOM)
        local saveButton = vgui.Create("DButton", presetPanel)
        saveButton:SetText("Save Preset")
        saveButton:Dock(BOTTOM)
        saveButton.DoClick = function()
            local presetName = presetNameEntry:GetValue()
            if presetName and presetName ~= "" then
                SavePreset(presetName)
                RefreshPresetList()
                presetNameEntry:SetValue("") -- テキスト欄をクリア
            else
                print("Please enter a preset name")
            end
        end

        local loadButton = vgui.Create("DButton", presetPanel)
        loadButton:SetText("Load Preset")
        loadButton:Dock(BOTTOM)
        loadButton.DoClick = function()
            local selected = presetList:GetSelectedLine()
            if selected then
                local preset = presetList:GetLine(selected):GetColumnText(1)
                LoadPreset(preset)
            end
        end

        local deleteButton = vgui.Create("DButton", presetPanel)
        deleteButton:SetText("Delete Preset")
        deleteButton:Dock(BOTTOM)
        deleteButton.DoClick = function()
            local selected = presetList:GetSelectedLine()
            if selected then
                local preset = presetList:GetLine(selected):GetColumnText(1)
                file.Delete(PRESET_FOLDER .. "/" .. preset .. PRESET_EXTENSION)
                RefreshPresetList()
            end
        end

        frame.SettingsForm:AddItem(presetPanel)
    end
)