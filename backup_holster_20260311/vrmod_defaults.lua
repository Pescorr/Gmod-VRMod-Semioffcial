-- VRMod Semi-Official Addon Plus - Centralized Default Values System
-- デフォルト値の中央管理システム
-- This file serves as the single source of truth for all default values

if SERVER then return end

VRMOD_DEFAULTS = {
	-- Character Settings / キャラクター設定
	character = {
		vrmod_scale = 38.7,
		vrmod_characterEyeHeight = 66.8,
		vrmod_characterHeadToHmdDist = 6.3,
		vrmod_crouchthreshold = 40,
		vrmod_znear = 1.0, -- FIXED: Was incorrectly 6.0 in some restore buttons
		vrmod_seatedoffset = 0, -- FIXED: Was incorrectly 66.8 in some restore buttons
		vrmod_seated = 0,
		vrmod_oldcharacteryaw = 0,
		vrmod_animation_Enable = 1,
		vrmod_LeftHand = 0,
		vrmod_lefthandleftfire = 1,
		vrmod_LeftHandmode = 0,
	},
	-- Gameplay Settings / ゲームプレイ設定
	gameplay = {
		vrmod_autojumpduck = 1,
		vrmod_allow_teleport_client = 1,
		vrmod_flashlight_attachment = 0,
		vrmod_pickup_weight = 100,
		vrmod_pickup_range = 1.1,
		vrmod_pickup_limit = 1,
		vrmod_manualpickups = 1,
	},
	-- UI Settings / UI設定
	ui = {
		vrmod_hud = 1,
		vrmod_hudcurve = 60,
		vrmod_huddistance = 60,
		vrmod_hudscale = 0.05,
		vrmod_hudtestalpha = 0,
		vrmod_hud_visible_quickmenukey = 0,
		vrmod_attach_quickmenu = 4,
		vrmod_attach_weaponmenu = 3,
		vrmod_attach_popup = 4,
		vre_ui_attachtohand = 1,
		vrmod_ui_outline = 1,
		vrmod_ui_realtime = 0,
		vrmod_cameraoverride = 1,
		vrmod_keyboard_uichatkey = 1,
	},
	-- Quick Menu Settings / クイックメニュー設定
	quickmenu = {
		vrmod_quickmenu_mapbrowser_enable = 1,
		vrmod_quickmenu_exit = 1,
		vrmod_quickmenu_vgui_reset_menu = 0,
		vrmod_quickmenu_vre_gbradial_menu = 1,
		vrmod_quickmenu_vre_heightadjust = 1,
		vrmod_quickmenu_weaponconfig = 1,
		vrmod_quickmenu_weaponmenu = 1,
		vrmod_quickmenu_vrmod_lvs_controlmenu = 1,
		vrmod_quickmenu_vrmod_vehicle_mirrormenu = 1,
		vrmod_quickmenu_vrmod_reload_bind = 1,
		vrmod_quickmenu_vrmod_vehicle_leftright = 1,
		vrmod_quickmenu_chat = 1,
		vrmod_quickmenu_spawnmenu = 1,
		vrmod_quickmenu_contextmenu = 1,
	},
	-- Network Settings / ネットワーク設定
	network = {
		vrmod_net_delay = 0.1,
		vrmod_net_delaymax = 0.2,
		vrmod_net_storedframes = 15,
		vrmod_net_tickrate = 67,
		vrmod_allow_teleport = 1,
	},
	-- Advanced Settings / 詳細設定
	advanced = {
		vrmod_rtWidth_Multiplier = 2.0,
		vrmod_rtHeight_Multiplier = 1.0,
		vrmod_error_check_method = 1,
		vrmod_locomotion_step = 1,
		vrmod_attach_viewmodel = 1,
		vrmod_directMovement = 1,
		vrmod_noTrigger = 1,
		vrmod_viewmodel_normal_enable = 1,
		vrmod_viewmodel_normal_offset_pos_x = 0,
		vrmod_viewmodel_normal_offset_pos_y = 0,
		vrmod_viewmodel_normal_offset_pos_z = 0,
		vrmod_viewmodel_normal_offset_ang_p = 0,
		vrmod_viewmodel_normal_offset_ang_y = 0,
		vrmod_viewmodel_normal_offset_ang_r = 0,
	},
	-- Melee Settings / 近接戦闘設定
	melee = {
		vrmelee_gunmelee = 1,
		vrmelee_fist = 1,
		vrmelee_kick = 1,
		vrmelee_damage_low = 10.0,
		vrmelee_damage_medium = 20.0,
		vrmelee_damage_high = 30.0,
		vrmelee_damage_velocity_low = 3.45,
		vrmelee_damage_velocity_medium = 4.11,
		vrmelee_damage_velocity_high = 4.35,
		vrmelee_impact = 5.0,
		vrmelee_delay = 0.0,
		vrmelee_range = 22,
		vrmelee_usegunmelee = 1,
		vrmelee_usefist = 1,
		vrmelee_usekick = 0,
		vrmelee_cooldown = 0.2,
		vrmelee_fist_collision = 0,
		vrmelee_fist_visible = 0,
		vrmelee_fist_collisionmodel = "models/hunter/plates/plate.mdl",
		vrmelee_hit_feedback = 1,
		vrmelee_hit_sound = 1,
		vrmelee_hitbox_width = 4,
		vrmelee_hitbox_length = 6,
		vrmelee_high_velocity_fire_bullets = 0,
		vrmelee_emulateblocking = 0,
		vrmelee_emulateblockbutton = "+attack2",
		vrmelee_emulateblockbutton_release = "-attack2",
		vrmelee_emulatebloack_Threshold_Low = 115,
		vrmelee_emulatebloack_Threshold_High = 180,
		vrmelee_lefthand_command = "",
		vrmelee_righthand_command = "",
		vrmelee_leftfoot_command = "",
		vrmelee_rightfoot_command = "",
		vrmelee_gunmelee_command = "",
	},
	-- Magazine Settings / マガジン設定
	magazine = {
		vrmod_mag_pos_x = 3.15,
		vrmod_mag_pos_y = 0.31,
		vrmod_mag_pos_z = 2.83,
		vrmod_mag_ang_p = -2.83,
		vrmod_mag_ang_y = 90,
		vrmod_mag_ang_r = 83,
		vrmod_mag_bones = "mag,ammo,clip,cylin,shell,magazine",
	},
	-- Foregrip Settings / フォアグリップ設定
	foregrip = {
		vrmod_Foregripmode_range = 30,
		vrmod_Foregripmode_enable = 1,
		vrmod_Foregripmode_key_leftprimary = 1,
		vrmod_Foregripmode_key_leftgrab = 1,
	},
	-- Physgun Settings / 物理ガン設定
	physgun = {
		-- Left hand
		vrmod_left_physgun_beam_enable = 1,
		vrmod_left_physgun_beam_range = 4096,
		vrmod_left_physgun_beam_damage_enable = 0,
		vrmod_left_physgun_beam_damage = 0.0001,
		vrmod_left_physgun_pull_enable = 1,
		vrmod_left_physgun_noclip_enable = 1,
		vrmod_left_physgun_beam_offset_x = 0,
		vrmod_left_physgun_beam_offset_y = 0,
		vrmod_left_physgun_beam_offset_z = 0,
		-- Right hand
		vrmod_right_physgun_beam_enable = 1,
		vrmod_right_physgun_beam_range = 4096,
		vrmod_right_physgun_beam_damage_enable = 0,
		vrmod_right_physgun_beam_damage = 0.0001,
		vrmod_right_physgun_pull_enable = 1,
		vrmod_right_physgun_noclip_enable = 1,
		vrmod_right_physgun_beam_offset_x = 0,
		vrmod_right_physgun_beam_offset_y = 0,
		vrmod_right_physgun_beam_offset_z = 0,
	},
	-- Beam Pickup Settings / ビームピックアップ設定
	beam_pickup = {
		vrmod_pickup_beam_enable = 1,
		vrmod_pickup_beamrange = 500,
		vrmod_pickup_beamrange02 = 50,
		vrmod_pickup_beam_damage_enable = 0,
		vrmod_pickup_beam_damage = 0,
	},
	-- Quick Menu Editor Settings / クイックメニューエディタ設定
	quickmenu_editor = {
		vrmod_quickmenu_use_custom = 0,
	},
	-- Auto Seat Reset Settings / 自動シートリセット設定
	auto_seat = {
		vrmod_auto_seat_reset = 1,
	},
	-- Key Guide HUD Settings / キーガイドHUD設定
	keyguide = {
		vrmod_keyguide_mode = 0,
		vrmod_keyguide_scale = 1.0,
		vrmod_keyguide_opacity = 200,
	},
	-- Holster Type1 Right Hand Settings / ホルスターType1右手設定
	holster_type1_right = {
		vrmod_weppouch_Pelvis = 1,
		vrmod_weppouch_Head = 1,
		vrmod_weppouch_Spine = 1,
		vrmod_weppouch_weapon_Pelvis = "",
		vrmod_weppouch_weapon_Head = "",
		vrmod_weppouch_weapon_Spine = "",
		vrmod_weppouch_weapon_lock_Pelvis = 0,
		vrmod_weppouch_weapon_lock_Head = 0,
		vrmod_weppouch_weapon_lock_Spine = 0,
		vrmod_weppouch_dist_Pelvis = 12.5,
		vrmod_weppouch_dist_head = 10.0,
		vrmod_weppouch_dist_spine = 0.0,
		vrmod_weppouch_customcvar_pelvis_enable = 0,
		vrmod_weppouch_customcvar_head_enable = 0,
		vrmod_weppouch_customcvar_spine_enable = 0,
		vrmod_weppouch_customcvar_pelvis_cmd = "vrmod_test_pickup_entteleport_right",
		vrmod_weppouch_customcvar_head_cmd = "vrmod_test_pickup_entteleport_right",
		vrmod_weppouch_customcvar_spine_cmd = "vrmod_test_pickup_entteleport_right",
		vrmod_weppouch_customcvar_pelvis_put_cmd = "+use,-use",
		vrmod_weppouch_customcvar_head_put_cmd = "+use,-use",
		vrmod_weppouch_customcvar_spine_put_cmd = "+use,-use",
		vrmod_weppouch_visiblerange = 0,
		vrmod_weppouch_visiblename = 1,
		vrmod_head_visible = 1,
	},
	-- Holster Type1 Left Hand Settings / ホルスターType1左手設定
	holster_type1_left = {
		vrmod_weppouch_left_Pelvis = 0,
		vrmod_weppouch_left_Head = 0,
		vrmod_weppouch_left_Spine = 0,
		vrmod_weppouch_weapon_left_Pelvis = "",
		vrmod_weppouch_weapon_left_Head = "",
		vrmod_weppouch_weapon_left_Spine = "",
		vrmod_weppouch_weapon_lock_left_Pelvis = 0,
		vrmod_weppouch_weapon_lock_left_Head = 0,
		vrmod_weppouch_weapon_lock_left_Spine = 0,
		vrmod_weppouch_dist_Pelvis_left = 12.5,
		vrmod_weppouch_dist_head_left = 10.0,
		vrmod_weppouch_dist_spine_left = 0.0,
		vrmod_weppouch_visiblerange_left = 0,
		vrmod_weppouch_visiblename_left = 1,
	},
	-- Holster Type2 Settings / ホルスターType2設定
	holster_type2 = {
		vrmod_pouch_enabled = 1,
		vrmod_pouch_visiblename = 1,
		vrmod_pouch_visiblename_hud = 1,
		vrmod_pouch_lefthandwep_enable = 1,
		vrmod_pouch_pickup_sound = "common/wpn_select.wav",
		vrmod_unoff_pouch_slot_enabled_1 = 1,
		vrmod_pouch_weapon_1 = "",
		vrmod_pouch_size_1 = 12,
		vrmod_unoff_pouch_slot_enabled_2 = 1,
		vrmod_pouch_weapon_2 = "",
		vrmod_pouch_size_2 = 12,
		vrmod_unoff_pouch_slot_enabled_3 = 1,
		vrmod_pouch_weapon_3 = "",
		vrmod_pouch_size_3 = 12,
		vrmod_unoff_pouch_slot_enabled_4 = 1,
		vrmod_pouch_weapon_4 = "",
		vrmod_pouch_size_4 = 12,
		vrmod_unoff_pouch_slot_enabled_5 = 1,
		vrmod_pouch_weapon_5 = "",
		vrmod_pouch_size_5 = 12,
		vrmod_unoff_pouch_slot_enabled_6 = 1,
		vrmod_pouch_weapon_6 = "",
		vrmod_pouch_size_6 = 12.5,
		vrmod_unoff_pouch_slot_enabled_7 = 1,
		vrmod_pouch_weapon_7 = "",
		vrmod_pouch_size_7 = 10.0,
		vrmod_unoff_pouch_slot_enabled_8 = 1,
		vrmod_pouch_weapon_8 = "",
		vrmod_pouch_size_8 = 0.0,
	},
	-- Character Advanced Settings / キャラクター詳細設定
	character_advanced = {
		vrmod_hide_head = 0,
		vrmod_hide_head_pos_x = 0,
		vrmod_hide_head_pos_y = 20,
		vrmod_hide_head_pos_z = 0,
		vrmod_idle_act = "ACT_HL2MP_IDLE",
		vrmod_walk_act = "ACT_HL2MP_WALK",
		vrmod_run_act = "ACT_HL2MP_RUN",
		vrmod_jump_act = "ACT_HL2MP_JUMP_PASSIVE",
	},
	-- Foregrip Advanced Settings / フォアグリップ詳細設定
	foregrip_advanced = {
		vrmod_Foregripmode_rotation_blend = 1.0,
		vrmod_Foregripmode_offset_x = 0,
		vrmod_Foregripmode_offset_y = 0,
		vrmod_Foregripmode_offset_z = 0,
		vrmod_Foregripmode_ang_pitch = 0,
		vrmod_Foregripmode_ang_yaw = 0,
		vrmod_Foregripmode_ang_roll = 0,
	},
	-- Misc Settings / その他設定
	misc = {
		vrmod_pmchange = 0,
		vrmod_lvs_input_mode = 1,
		vrmod_sight_bodypart = 1,
	},
	-- Developer Settings / 開発者設定
	developer = {
		vrmod_unoff_developer_mode = 0,
		vrmod_test_Righthandle = 0,
		vrmod_test_lefthandle = 0,
		vrmod_error_hard = 0,
		vrmod_emergencystop_key = KEY_F3,
		vrmod_emergencystop_time = 3.0,
	},
}

-- Helper function to get default value for a specific ConVar
-- 特定のConVarのデフォルト値を取得するヘルパー関数
function VRModGetDefault(cvar_name)
	for category, cvars in pairs(VRMOD_DEFAULTS) do
		if cvars[cvar_name] ~= nil then
			return cvars[cvar_name]
		end
	end

	return nil
end

-- Helper function to reset all ConVars in a category to defaults
-- カテゴリ内の全ConVarをデフォルトにリセットするヘルパー関数
function VRModResetCategory(category)
	if not VRMOD_DEFAULTS[category] then
		print("[VRMod] Error: Unknown category '" .. category .. "'")

		return
	end

	local count = 0
	for cvar_name, value in pairs(VRMOD_DEFAULTS[category]) do
		if type(value) == "string" then
			LocalPlayer():ConCommand(cvar_name .. " \"" .. value .. "\"")
		else
			LocalPlayer():ConCommand(cvar_name .. " " .. tostring(value))
		end

		count = count + 1
	end

	print("[VRMod] Reset " .. count .. " settings in category '" .. category .. "' to defaults")
end

-- Helper function to reset all ConVars to defaults
-- 全ConVarをデフォルトにリセットするヘルパー関数
function VRModResetAll()
	local total = 0
	for category, _ in pairs(VRMOD_DEFAULTS) do
		local count = 0
		for _ in pairs(VRMOD_DEFAULTS[category]) do
			count = count + 1
		end

		VRModResetCategory(category)
		total = total + count
	end

	print("[VRMod] Reset all " .. total .. " settings to defaults")
end

print("[VRMod] Default values system loaded successfully")
