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
		vrmod_pickup_range = 1.01,
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
		vrmod_cameraoverride = 0,
		vrmod_keyboard_uichatkey = 1,
		vrmod_unoff_desktop_ui_mirror = 0,
	},
	-- Quick Menu Settings / クイックメニュー設定
	quickmenu = {
		vrmod_quickmenu_mapbrowser_enable = 0,
		vrmod_quickmenu_exit = 1,
		vrmod_quickmenu_vgui_reset_menu = 0,
		vrmod_quickmenu_vre_gbradial_menu = 1,
		vrmod_quickmenu_chat = 1,
		vrmod_quickmenu_keyboard = 1,
		vrmod_quickmenu_seated_menu = 1,
		vrmod_quickmenu_togglemirror = 1,
		vrmod_quickmenu_spawn_menu = 1,
		vrmod_quickmenu_noclip = 1,
		vrmod_quickmenu_context_menu = 1,
		vrmod_quickmenu_arccw = 0,
		vrmod_quickmenu_togglevehiclemode = 1,
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
	-- Module-specific defaults removed (S32: modules are now individual addons with own defaults)
	-- Quick Menu Editor Settings / クイックメニューエディタ設定
	quickmenu_editor = {
		vrmod_quickmenu_use_custom = 1,
	},
	-- Auto Seat Reset Settings / 自動シートリセット設定
	auto_seat = {
		vrmod_auto_seat_reset = 1,
	},
	-- Holster/keyguide defaults removed (S32: modules are now individual addons)
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
	-- Foregrip advanced defaults removed (S32)
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
	-- Climbing Client Settings / クライミングクライアント設定 (vrmod_climbing addon)
	climbing = {
		vrmod_brushclimb_enable = 1,
		vrmod_brushclimb_bind_mode = 0,
		vrmod_brushclimb_grab_distance = 22,
		vrmod_brushclimb_launch_mult = 1.35,
		vrmod_brushclimb_launch_min = 120,
		vrmod_brushclimb_launch_max = 650,
		vrmod_brushclimb_sounds = 1,
		vrmod_brushclimb_sound_volume = 0.8,
		vrmod_brushclimb_debug = 0,
		vrmod_brushclimb_debug_text = 1,
		vrmod_brushclimb_hand_inset = 1.1,
		vrmod_brushclimb_wall_push_dist = 2.0,
		vrmod_brushclimb_camera_collision = 1,
		vrmod_brushclimb_palm_offset_forward = 3.30,
		vrmod_brushclimb_palm_offset_right = -2.32,
		vrmod_brushclimb_palm_offset_up = -0.05,
		vrmod_brushclimb_palm_offset_forward_right = 3.30,
		vrmod_brushclimb_palm_offset_right_right = 2.32,
		vrmod_brushclimb_palm_offset_up_right = 0.05,
		vrmod_brushclimb_allow_walls = 1,
		vrmod_brushclimb_allow_ceilings = 1,
		vrmod_brushclimb_allow_ledges = 1,
		vrmod_brushclimb_allow_floors = 1,
		vrmod_brushclimb_allow_doors = 0,
		vrmod_brushclimb_allow_pushable = 0,
		vrmod_brushclimb_allow_toggleable = 0,
		vrmod_brushclimb_allow_ladders = 1,
		vrmod_wallrun_hand_range = 20,
		vrmod_wallrun_bind_mode = 1,
		vrmod_wallrun_cooldown = 0.5,
		vrmod_wallrun_air_regen = 2.0,
		vrmod_wallrun_look_max_dot = 0.45,
		vrmod_wallrun_sounds = 1,
		vrmod_wallrun_sound_volume = 0.75,
		vrmod_wallrun_sound_interval = 0.18,
		vrmod_slide_enable = 1,
		vrmod_slide_head_height = 40,
		vrmod_slide_sounds = 1,
		vrmod_slide_sound_volume = 0.75,
	},
	-- RealMech/Throw/HandSync defaults removed (S32: modules are now individual addons)
	-- Cardboard VR Settings / カードボードVR設定
	cardboard = {
		cardboardmod_scale = 39.37008,
		cardboardmod_sensitivity = 0.01,
	},
	-- Vehicle Settings / 車両設定
	vehicle = {
		vrmod_lvs_input_mode = 1,
		vrmod_vehicle_reticlemode = 1,
		vrmod_auto_seat_reset = 1,
	},
	-- Puppeteer defaults removed (S32: module is now individual addon)
	-- Climbing Server Settings / クライミングサーバー設定 (vrmod_climbing addon, host/singleplayer only)
	climbing_server = {
		sv_vrmod_brushclimb_ledge_normal_min = 0.55,
		sv_vrmod_brushclimb_floor_normal_min = 0.85,
		sv_vrmod_brushclimb_ceil_normal_max = -0.55,
		sv_vrmod_brushclimb_reduce_collider = 1,
		sv_vrmod_brushclimb_allow_walls = 1,
		sv_vrmod_brushclimb_allow_ceilings = 1,
		sv_vrmod_brushclimb_allow_ledges = 1,
		sv_vrmod_brushclimb_allow_floors = 1,
		sv_vrmod_brushclimb_allow_doors = 0,
		sv_vrmod_brushclimb_allow_pushable = 0,
		sv_vrmod_brushclimb_allow_toggleable = 0,
		sv_vrmod_wallrun_jump_force = 350,
		sv_vrmod_wallrun_wall_force = 120,
		sv_vrmod_wallrun_free_time = 0.6,
		sv_vrmod_wallrun_fall_rate = 90,
		sv_vrmod_wallrun_max_fall_speed = 260,
		sv_vrmod_wallrun_speed_grace = 0.15,
		sv_vrmod_wallrun_min_jump_time = 0.1,
		sv_vrmod_slide_enable = 1,
		sv_vrmod_slide_min_speed = 150,
		sv_vrmod_slide_friction = 40,
		sv_vrmod_slide_air_boost = 80,
		sv_vrmod_slide_stop_speed = 60,
		sv_vrmod_slide_entry_boost = 60,
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
		-- JSON管理対象の場合はJsonConfig経由でリセット、そうでなければConCommand
		RunConsoleCommand(cvar_name, tostring(value))
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
