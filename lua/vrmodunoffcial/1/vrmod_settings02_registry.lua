-- vrmod_settings02_registry.lua
-- Settings02 panel definitions as pure data.
-- Used by vrmod_spawnmenu_tab.lua to build spawn menu categories.
-- When Settings02 panels in vrmod_unoff_addmenu.lua change, update this file too.
-- SYNC: This file must mirror vrmod_unoff_addmenu.lua Settings02 panels exactly.

if SERVER then return end

VRMOD_SETTINGS02_REGISTRY = {
	-- ==============================
	-- VR
	-- ==============================
	{
		key = "vr", label = "VR", icon = "icon16/basket.png",
		items = {
			{ type = "checkbox", label = "Jumpkey Auto Duck", cvar = "vrmod_autojumpduck" },
			{ type = "checkbox", label = "Teleport Enable", cvar = "vrmod_allow_teleport_client" },
			{ type = "slider", label = "Teleport Hand (0=Left 1=Right 2=Head)", cvar = "vrmod_unoff_teleport_hand", min = 0, max = 2, decimals = 0 },
			{ type = "slider", label = "Flashlight Attachment (0=R 1=L 2=HMD)", cvar = "vrmod_flashlight_attachment", min = 0, max = 2, decimals = 0 },
			{ type = "button", label = "Toggle Laser Pointer", command = "vrmod_togglelaserpointer" },
			{ type = "button", label = "Weapon Viewmodel Setting", command = "vrmod_weaponconfig" },
			{ type = "button", label = "Weapon Bone Config", command = "vrmod_weapon_bone_config" },
			{ type = "slider", label = "Pickup Weight (Server)", cvar = "vrmod_pickup_weight", min = 0, max = 1000, decimals = 0 },
			{ type = "slider", label = "Pickup Range (Server)", cvar = "vrmod_pickup_range", min = 0, max = 5, decimals = 2 },
			{ type = "slider", label = "Pickup Limit (Server)", cvar = "vrmod_pickup_limit", min = 0, max = 3, decimals = 0 },
			{ type = "checkbox", label = "Manual Pickup", cvar = "vrmod_pickup_allow_default" },
			{ type = "button", label = "Restore Default Settings", command = "vrmod_reset_gameplay" },
		},
	},

	-- ==============================
	-- Character
	-- ==============================
	{
		key = "character", label = "Character", icon = "icon16/user.png",
		items = {
			{ type = "section", text = "Character Scale" },
			{ type = "slider", label = "Character Scale", cvar = "vrmod_scale", min = 0, max = 200, decimals = 1 },
			{ type = "slider", label = "Character Eye Height", cvar = "vrmod_characterEyeHeight", min = 0, max = 100, decimals = 2 },
			{ type = "slider", label = "Crouch Threshold", cvar = "vrmod_crouchthreshold", min = 0, max = 100, decimals = 2 },
			{ type = "slider", label = "Head to HMD Distance", cvar = "vrmod_characterHeadToHmdDist", min = -20, max = 20, decimals = 2 },
			{ type = "slider", label = "Z Near", cvar = "vrmod_znear", min = 0, max = 20, decimals = 2 },
			{ type = "checkbox", label = "Seated Mode", cvar = "vrmod_seated" },
			{ type = "slider", label = "Seated Offset", cvar = "vrmod_seatedoffset", min = -100, max = 100, decimals = 2 },
			{ type = "checkbox", label = "Alternative Character Yaw", cvar = "vrmod_oldcharacteryaw" },
			{ type = "checkbox", label = "Character Animation Enable", cvar = "vrmod_animation_Enable" },
			{ type = "section", text = "Head Hide Settings" },
			{ type = "checkbox", label = "Hide Head", cvar = "vrmod_hide_head" },
			{ type = "slider", label = "Head Hide Pos X", cvar = "vrmod_hide_head_pos_x", min = -1000, max = 1000, decimals = 1 },
			{ type = "slider", label = "Head Hide Pos Y", cvar = "vrmod_hide_head_pos_y", min = -1000, max = 1000, decimals = 1 },
			{ type = "slider", label = "Head Hide Pos Z", cvar = "vrmod_hide_head_pos_z", min = -1000, max = 1000, decimals = 1 },
			{ type = "section", text = "Animations" },
			{ type = "text", label = "Idle Animation", cvar = "vrmod_idle_act" },
			{ type = "text", label = "Walk Animation", cvar = "vrmod_walk_act" },
			{ type = "text", label = "Run Animation", cvar = "vrmod_run_act" },
			{ type = "text", label = "Jump Animation", cvar = "vrmod_jump_act" },
			{ type = "section", text = "Left Hand (WIP)" },
			{ type = "checkbox", label = "Left Hand", cvar = "vrmod_LeftHand" },
			{ type = "checkbox", label = "Left Hand Fire", cvar = "vrmod_lefthandleftfire" },
			{ type = "checkbox", label = "Left Hand Hold Mode", cvar = "vrmod_LeftHandmode" },
			{ type = "button", label = "Apply VR Settings (Requires VRMod Restart)", command = "vrmod_restart" },
			{ type = "button", label = "Auto Adjust VR Settings", command = "vrmod_character_auto" },
			{ type = "button", label = "Restore Default Settings", command = "vrmod_reset_character" },
		},
	},

	-- ==============================
	-- UI
	-- ==============================
	{
		key = "ui", label = "UI", icon = "icon16/photos.png",
		items = {
			{ type = "checkbox", label = "HUD Enable", cvar = "vrmod_hud" },
			{ type = "slider", label = "HUD Curve", cvar = "vrmod_hudcurve", min = 1, max = 100, decimals = 0 },
			{ type = "slider", label = "HUD Distance", cvar = "vrmod_huddistance", min = 1, max = 200, decimals = 0 },
			{ type = "slider", label = "HUD Scale", cvar = "vrmod_hudscale", min = 0.01, max = 0.20, decimals = 2 },
			{ type = "slider", label = "HUD Alpha", cvar = "vrmod_hudtestalpha", min = 0, max = 255, decimals = 0 },
			{ type = "checkbox", label = "HUD Only While Pressing Menu Key", cvar = "vrmod_hud_visible_quickmenukey" },
			{ type = "combo", label = "Quickmenu Attach Position", cvar = "vrmod_attach_quickmenu",
				options = { { label = "Left Hand", value = "1" }, { label = "Right Hand", value = "4" }, { label = "HMD", value = "3" } } },
			{ type = "combo", label = "Weapon Menu Attach Position", cvar = "vrmod_attach_weaponmenu",
				options = { { label = "Left Hand", value = "1" }, { label = "Right Hand", value = "4" }, { label = "HMD", value = "3" } } },
			{ type = "combo", label = "Popup Window Attach Position", cvar = "vrmod_attach_popup",
				options = { { label = "Left Hand", value = "1" }, { label = "Right Hand", value = "4" }, { label = "HMD", value = "3" } } },
			{ type = "checkbox", label = "Menu & UI Red Outline", cvar = "vrmod_ui_outline" },
			{ type = "checkbox", label = "UI Render Alternative", cvar = "vrmod_ui_realtime" },
			{ type = "checkbox", label = "Desktop 3rd Person Camera", cvar = "vrmod_cameraoverride" },
			{ type = "checkbox", label = "Keyboard UI Chat Key", cvar = "vrmod_keyboard_uichatkey" },
			{ type = "checkbox", label = "VRE Attach Left Hands", cvar = "vre_ui_attachtohand" },
			{ type = "checkbox", label = "Show VR UI on Desktop Window", cvar = "vrmod_unoff_desktop_ui_mirror" },
			{ type = "button", label = "Toggle VR Keyboard", command = "vrmod_keyboard" },
			{ type = "button", label = "Open Action Editor", command = "vrmod_actioneditor" },
			{ type = "section", text = "Screen Resolution" },
			{ type = "slider", label = "VR UI Height", cvar = "vrmod_ScrH", min = 480, max = 4320, decimals = 0 },
			{ type = "slider", label = "VR UI Width", cvar = "vrmod_ScrW", min = 640, max = 7680, decimals = 0 },
			{ type = "slider", label = "VR HUD Height", cvar = "vrmod_ScrH_hud", min = 480, max = 4320, decimals = 0 },
			{ type = "slider", label = "VR HUD Width", cvar = "vrmod_ScrW_hud", min = 640, max = 7680, decimals = 0 },
			{ type = "checkbox", label = "Always Auto-Detect Resolution on VR Start", cvar = "vrmod_scr_alwaysautosetting" },
			{ type = "button", label = "Restore Default Settings", command = "vrmod_reset_ui" },
		},
	},

	-- ==============================
	-- Optimize
	-- ==============================
	{
		key = "optimize", label = "Optimize", icon = "icon16/picture.png",
		items = {
			{ type = "checkbox", label = "Skybox Enable (Client)", cvar = "r_3dsky" },
			{ type = "checkbox", label = "Shadows & Flashlights Effect Enable (Client)", cvar = "r_shadows" },
			{ type = "slider", label = "Visible Range of Map", cvar = "r_farz", min = 0, max = 16384, decimals = 0 },
			{ type = "slider", label = "VRMod Optimization Level (0-4)", cvar = "vrmod_gmod_optimization", min = 0, max = 4, decimals = 0 },
			{ type = "help", text = "0:None 1:No changes 2:Reset 3:VR safe 4:Max(flash warn)" },
			{ type = "button", label = "Apply Optimization Now", command = "vrmod_apply_optimization" },
			{ type = "section", text = "Mirror & Reflection" },
			{ type = "button", label = "Remove All Reflective Glass", command = "remove_reflective_glass" },
			{ type = "section", text = "Render Target" },
			{ type = "slider", label = "RT Width Multiplier", cvar = "vrmod_rtWidth_Multiplier", min = 0.1, max = 5.0, decimals = 1 },
			{ type = "slider", label = "RT Height Multiplier", cvar = "vrmod_rtHeight_Multiplier", min = 0.1, max = 5.0, decimals = 1 },
			{ type = "button", label = "Reset Render Targets", command = "vrmod_reset_render_targets" },
			{ type = "button", label = "Update Render Targets", command = "vrmod_update_render_targets" },
			{ type = "button", label = "Apply Quest 2 + Virtual Desktop Preset", command = "vrmod_quest2_preset" },
			{ type = "button", label = "Reset RT Multipliers to Default", command = "vrmod_reset_rt_multipliers" },
		},
	},

	-- ==============================
	-- Opt.VR
	-- ==============================
	{
		key = "optvr", label = "Opt.VR", icon = "icon16/cog_add.png",
		items = {
			{ type = "help", text = "Changes apply immediately in spawn menu." },
			{ type = "slider", label = "Water Reflections", cvar = "r_WaterDrawReflection", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Water Refractions", cvar = "r_WaterDrawRefraction", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Force Expensive Water", cvar = "r_waterforceexpensive", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Force Water Reflect Entities", cvar = "r_waterforcereflectentities", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "VR Mirror Optimization", cvar = "vrmod_mirror_optimization", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Reflective Glass Toggle", cvar = "vrmod_reflective_glass_toggle", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Disable Mirrors", cvar = "vrmod_disable_mirrors", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Multi-core Rendering", cvar = "gmod_mcore_test", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Multicore Rendering Mode", cvar = "mat_queue_mode", min = -1, max = 2, decimals = 0 },
		},
	},

	-- ==============================
	-- Opt.Gmod
	-- ==============================
	{
		key = "optgmod", label = "Opt.Gmod", icon = "icon16/cog_add.png",
		items = {
			{ type = "help", text = "Changes apply immediately in spawn menu." },
			{ type = "slider", label = "Max Shadows Rendered", cvar = "r_shadowmaxrendered", min = 1, max = 32, decimals = 0 },
			{ type = "slider", label = "Flashlight Shadow Resolution", cvar = "r_flashlightdepthres", min = 1, max = 1024, decimals = 0 },
			{ type = "slider", label = "Texture Quality (lower=better)", cvar = "mat_picmip", min = -10, max = 20, decimals = 0 },
			{ type = "slider", label = "Level of Detail", cvar = "r_lod", min = -1, max = 10, decimals = 0 },
			{ type = "slider", label = "Root Level of Detail", cvar = "r_rootlod", min = -1, max = 10, decimals = 0 },
			{ type = "slider", label = "AI Expression Frequency", cvar = "ai_expression_frametime", min = 0.1, max = 2, decimals = 1 },
			{ type = "slider", label = "Detail Distance", cvar = "cl_detaildist", min = 1, max = 8000, decimals = 0 },
			{ type = "slider", label = "Fast Specular", cvar = "mat_fastspecular", min = 0, max = 1, decimals = 0 },
			{ type = "slider", label = "Water Overlay Size", cvar = "mat_wateroverlaysize", min = 2, max = 1200, decimals = 0 },
			{ type = "slider", label = "Draw Detail Props", cvar = "r_drawdetailprops", min = 0, max = 2, decimals = 0 },
			{ type = "slider", label = "Specular Reflections", cvar = "mat_specular", min = 0, max = 1, decimals = 0 },
		},
	},

	-- ==============================
	-- Quick Menu
	-- ==============================
	{
		key = "quickmenu", label = "Quick Menu", icon = "icon16/application_view_tile.png",
		items = {
			{ type = "checkbox", label = "Map Browser", cvar = "vrmod_quickmenu_mapbrowser_enable" },
			{ type = "checkbox", label = "VR Exit", cvar = "vrmod_quickmenu_exit" },
			{ type = "checkbox", label = "UI Reset", cvar = "vrmod_quickmenu_vgui_reset_menu" },
			{ type = "checkbox", label = "VRE GBRadial & Add Menu", cvar = "vrmod_quickmenu_vre_gbradial_menu" },
			{ type = "checkbox", label = "Chat", cvar = "vrmod_quickmenu_chat" },
			{ type = "checkbox", label = "Keyboard", cvar = "vrmod_quickmenu_keyboard" },
			{ type = "checkbox", label = "Seated Mode", cvar = "vrmod_quickmenu_seated_menu" },
			{ type = "checkbox", label = "Toggle Mirror", cvar = "vrmod_quickmenu_togglemirror" },
			{ type = "checkbox", label = "Spawn Menu", cvar = "vrmod_quickmenu_spawn_menu" },
			{ type = "checkbox", label = "No Clip", cvar = "vrmod_quickmenu_noclip" },
			{ type = "checkbox", label = "Context Menu", cvar = "vrmod_quickmenu_context_menu" },
			{ type = "checkbox", label = "ArcCW Customize", cvar = "vrmod_quickmenu_arccw" },
			{ type = "checkbox", label = "Toggle Vehicle Mode", cvar = "vrmod_quickmenu_togglevehiclemode" },
			{ type = "button", label = "Restore Default Settings", command = "vrmod_reset_quickmenu" },
		},
	},

	-- ==============================
	-- VRStop Key
	-- ==============================
	{
		key = "vrstop", label = "VRStop Key", icon = "icon16/stop.png",
		items = {
			{ type = "help", text = "Emergency Stop key must be set in VRMod Menu (key binder)." },
			{ type = "slider", label = "Hold Time (Seconds)", cvar = "vrmod_emergencystop_time", min = 0, max = 10, decimals = 2 },
			{ type = "section", text = "FPS Guard" },
			{ type = "checkbox", label = "FPS Guard Enable", cvar = "vrmod_unoff_fps_guard" },
			{ type = "slider", label = "FPS Drop Threshold (ms)", cvar = "vrmod_unoff_fps_guard_threshold_ms", min = 10, max = 200, decimals = 0 },
			{ type = "slider", label = "Retry Count", cvar = "vrmod_unoff_fps_guard_retry", min = 0, max = 10, decimals = 0 },
			{ type = "help", text = "Automatically stops VR when frame time exceeds threshold." },
			{ type = "section", text = "Emergency FPS Stop" },
			{ type = "checkbox", label = "Emergency FPS Enable", cvar = "vrmod_unoff_emergency_fps_enabled" },
			{ type = "slider", label = "FPS Threshold", cvar = "vrmod_unoff_emergency_fps_threshold", min = 1, max = 30, decimals = 0 },
			{ type = "slider", label = "Duration (Seconds)", cvar = "vrmod_unoff_emergency_fps_duration", min = 0, max = 15, decimals = 1 },
			{ type = "help", text = "Stops VR if FPS stays below threshold for the specified duration." },
		},
	},

	-- ==============================
	-- Misc
	-- ==============================
	{
		key = "misc", label = "Misc", icon = "icon16/cog.png",
		items = {
			{ type = "checkbox", label = "VRMod Menu Show on Startup", cvar = "vrmod_showonstartup" },
			{ type = "checkbox", label = "Error Check Method", cvar = "vrmod_error_check_method" },
			{ type = "checkbox", label = "ModuleError VRMod Menu Lock", cvar = "vrmod_error_hard" },
			{ type = "checkbox", label = "Player Model Change (forPAC3)", cvar = "vrmod_pmchange" },
			{ type = "checkbox", label = "VR Disable Pickup (Client)", cvar = "vr_pickup_disable_client" },
			{ type = "checkbox", label = "Enable LVS Pickup Handle", cvar = "vrmod_lvs_input_mode" },
			{ type = "checkbox", label = "VRMod Menu Type", cvar = "vrmod_menu_type" },
			{ type = "checkbox", label = "Use Custom QuickMenu", cvar = "vrmod_quickmenu_use_custom" },
			{ type = "checkbox", label = "Auto Seat Reset", cvar = "vrmod_auto_seat_reset" },
			{ type = "checkbox", label = "Sight Bodypart", cvar = "vrmod_sight_bodypart" },
			{ type = "checkbox", label = "Developer Mode (requires restart)", cvar = "vrmod_unoff_developer_mode" },
			{ type = "button", label = "Restore Misc Defaults", command = "vrmod_reset_misc" },
		},
	},

	-- ==============================
	-- Animation
	-- ==============================
	{
		key = "animation", label = "Animation", icon = "icon16/user_edit.png",
		items = {
			{ type = "text", label = "Idle Animation", cvar = "vrmod_idle_act" },
			{ type = "text", label = "Walk Animation", cvar = "vrmod_walk_act" },
			{ type = "text", label = "Run Animation", cvar = "vrmod_run_act" },
			{ type = "text", label = "Jump Animation", cvar = "vrmod_jump_act" },
			{ type = "help", text = "Enter animation names (e.g., ACT_HL2MP_IDLE)" },
			{ type = "button", label = "Reset to Default", command = "vrmod_reset_animation" },
		},
	},

	-- ==============================
	-- Graphics02
	-- ==============================
	{
		key = "graphics02", label = "Graphics02", icon = "icon16/wrench.png",
		items = {
			{ type = "checkbox", label = "Automatic Resolution Set", cvar = "vrmod_scr_alwaysautosetting" },
			{ type = "slider", label = "RT Width Multiplier", cvar = "vrmod_rtWidth_Multiplier", min = 0.1, max = 10, decimals = 1 },
			{ type = "slider", label = "RT Height Multiplier", cvar = "vrmod_rtHeight_Multiplier", min = 0.1, max = 10, decimals = 1 },
			{ type = "slider", label = "VR UI Width", cvar = "vrmod_ScrW", min = 640, max = 7680, decimals = 0 },
			{ type = "slider", label = "VR UI Height", cvar = "vrmod_ScrH", min = 480, max = 4320, decimals = 0 },
			{ type = "slider", label = "VR HUD Width", cvar = "vrmod_ScrW_hud", min = 640, max = 7680, decimals = 0 },
			{ type = "slider", label = "VR HUD Height", cvar = "vrmod_ScrH_hud", min = 480, max = 4320, decimals = 0 },
			{ type = "button", label = "Quest 2 / Virtual Desktop Preset", command = "vrmod_quest2_preset" },
			{ type = "button", label = "Restore Default Settings", command = "vrmod_reset_advanced" },
		},
	},

	-- ==============================
	-- Network(Server)
	-- ==============================
	{
		key = "network", label = "Network(Server)", icon = "icon16/connect.png",
		items = {
			{ type = "slider", label = "Net Delay", cvar = "vrmod_net_delay", min = 0, max = 1, decimals = 3 },
			{ type = "slider", label = "Net Delay Max", cvar = "vrmod_net_delaymax", min = 0, max = 100, decimals = 3 },
			{ type = "slider", label = "Net Stored Frames", cvar = "vrmod_net_storedframes", min = 1, max = 25, decimals = 3 },
			{ type = "slider", label = "Net Tickrate", cvar = "vrmod_net_tickrate", min = 1, max = 100, decimals = 3 },
			{ type = "checkbox", label = "Allow VR Teleport (Server)", cvar = "vrmod_allow_teleport" },
			{ type = "button", label = "Restore Default Settings", command = "vrmod_reset_network" },
		},
	},

	-- ==============================
	-- Commands
	-- ==============================
	{
		key = "commands", label = "Commands", icon = "icon16/application_xp_terminal.png",
		items = {
			{ type = "section", text = "Debug Visualization" },
			{ type = "button", label = "Toggle Door Collision Debug", command = "vrmod_doordebug" },
			{ type = "button", label = "Toggle Playspace Debug", command = "vrmod_debuglocomotion" },
			{ type = "button", label = "Toggle Network Debug", command = "vrmod_net_debug" },
			{ type = "section", text = "Device Information" },
			{ type = "button", label = "Print VR Devices Info", command = "vrmod_print_devices" },
			{ type = "section", text = "Cardboard VR" },
			{ type = "button", label = "Start Cardboard VR", command = "cardboardmod_start" },
			{ type = "button", label = "Exit Cardboard VR", command = "cardboardmod_exit" },
			{ type = "section", text = "VRE Integration" },
			{ type = "button", label = "Toggle Radial Menu", command = "vre_gb-radial" },
			{ type = "button", label = "Toggle Server Menu", command = "vre_svmenu" },
		},
	},

	-- ==============================
	-- Vehicle
	-- ==============================
	{
		key = "vehicle", label = "Vehicle", icon = "icon16/car.png",
		items = {
			{ type = "button", label = "Main Mode (On-Foot)", command = "vrmod_keymode_main" },
			{ type = "button", label = "Driving Mode (Vehicle)", command = "vrmod_keymode_driving" },
			{ type = "button", label = "Both Modes (Main+Driving)", command = "vrmod_keymode_both" },
			{ type = "button", label = "Auto Mode (Restore)", command = "vrmod_keymode_restore" },
			{ type = "checkbox", label = "Auto-detect Vehicle Type", cvar = "vrmod_auto_vehicle_scheme" },
			{ type = "checkbox", label = "LVS Networked Mode", cvar = "vrmod_lvs_input_mode" },
			{ type = "button", label = "LFS Mode", command = "vrmod_lfsmode" },
			{ type = "button", label = "SimfPhys Mode", command = "vrmod_simfmode" },
			{ type = "checkbox", label = "Auto Seat Reset", cvar = "vrmod_auto_seat_reset" },
			{ type = "button", label = "Reset Vehicle Settings", command = "vrmod_reset_vehicle" },
		},
	},

	-- ==============================
	-- Magazine
	-- ==============================
	{
		key = "magazine", label = "Magazine", icon = "icon16/basket.png",
		items = {
			{ type = "checkbox", label = "Enable VR Magazine System", cvar = "vrmod_mag_system_enable" },
			{ type = "checkbox", label = "Enable Magazine Pouch", cvar = "vrmod_unoff_mag_pouch_enable" },
			{ type = "help", text = "Magazine Pouch: reach left hand to body pouch + Pickup to spawn vrmagent." },
			{ type = "checkbox", label = "VR Magazine bone or bonegroup", cvar = "vrmod_mag_ejectbone_type" },
			{ type = "text", label = "Magazine Enter Sound", cvar = "vrmod_magent_sound" },
			{ type = "slider", label = "Magazine Enter Range", cvar = "vrmod_magent_range", min = 1, max = 100, decimals = 0 },
			{ type = "text", label = "Magazine Enter Model", cvar = "vrmod_magent_model" },
			{ type = "checkbox", label = "[WIP] WeaponModel Mag Grab/Eject", cvar = "vrmod_mag_ejectbone_enable" },
			{ type = "section", text = "Magazine Position" },
			{ type = "slider", label = "Position X", cvar = "vrmod_mag_pos_x", min = -20, max = 20, decimals = 2 },
			{ type = "slider", label = "Position Y", cvar = "vrmod_mag_pos_y", min = -20, max = 20, decimals = 2 },
			{ type = "slider", label = "Position Z", cvar = "vrmod_mag_pos_z", min = -20, max = 20, decimals = 2 },
			{ type = "slider", label = "Angle Pitch", cvar = "vrmod_mag_ang_p", min = -180, max = 180, decimals = 2 },
			{ type = "slider", label = "Angle Yaw", cvar = "vrmod_mag_ang_y", min = -180, max = 180, decimals = 2 },
			{ type = "slider", label = "Angle Roll", cvar = "vrmod_mag_ang_r", min = -180, max = 180, decimals = 2 },
			{ type = "text", label = "Magazine Bone Names", cvar = "vrmod_mag_bones" },
			{ type = "section", text = "Pouch Position (shared with ArcVR)" },
			{ type = "combo", label = "Pouch Location", cvar = "vrmod_unoff_pouch_location",
				options = { { label = "Pelvis (Hip)", value = "pelvis" }, { label = "Head", value = "head" }, { label = "Spine (Chest)", value = "spine" } } },
			{ type = "slider", label = "Pouch Distance", cvar = "vrmod_unoff_pouch_dist", min = 1, max = 50, decimals = 1 },
			{ type = "checkbox", label = "Infinite Pouch (any distance)", cvar = "vrmod_unoff_pouch_infinite" },
			{ type = "checkbox", label = "Sync to ArcVR ConVars", cvar = "vrmod_unoff_pouch_sync_arcvr" },
			{ type = "section", text = "ARC9 Weapon Settings" },
			{ type = "checkbox", label = "Enable ARC9 VR Integration", cvar = "vrmod_arc9_enable" },
			{ type = "checkbox", label = "Enable ARC9 Magazine Bone Fix", cvar = "vrmod_arc9_magbone_fix_enable" },
			{ type = "checkbox", label = "ARC9 Mag Bone: Follow Left Hand / Hide Only", cvar = "vrmod_arc9_magbone_track" },
		},
	},

	-- ==============================
	-- Utility
	-- ==============================
	{
		key = "utility", label = "Utility", icon = "icon16/wrench.png",
		items = {
			{ type = "section", text = "Screen & VGUI" },
			{ type = "button", label = "Auto-Detect Screen Resolution", command = "vrmod_Scr_Auto" },
			{ type = "button", label = "Reset VGUI Panels", command = "vrmod_vgui_reset" },
			{ type = "section", text = "VR Config Data Generation" },
			{ type = "button", label = "Generate VR Config Data", command = "vrmod_data_vmt_generate_test" },
			{ type = "checkbox", label = "Auto-generate on VR startup", cvar = "vrmod_unoff_auto_generate_config" },
			{ type = "section", text = "Core VR Control" },
			{ type = "button", label = "Start VR", command = "vrmod_start" },
			{ type = "button", label = "Exit VR", command = "vrmod_exit" },
			{ type = "button", label = "Reset All Settings", command = "vrmod_reset" },
			{ type = "button", label = "Print VR Info", command = "vrmod_info" },
			{ type = "button", label = "Reset Lua Modules", command = "vrmod_lua_reset" },
		},
	},

	-- ==============================
	-- Cardboard
	-- ==============================
	{
		key = "cardboard", label = "Cardboard", icon = "icon16/phone.png",
		items = {
			{ type = "slider", label = "Cardboard Scale", cvar = "cardboardmod_scale", min = 1, max = 100, decimals = 2 },
			{ type = "slider", label = "Cardboard Sensitivity", cvar = "cardboardmod_sensitivity", min = 0.001, max = 0.1, decimals = 3 },
		},
	},

	-- ==============================
	-- C++ Module
	-- ==============================
	{
		key = "cppmodule", label = "C++ Module", icon = "icon16/brick.png",
		items = {
			{ type = "section", text = "Settings" },
			{ type = "combo", label = "Input Mode", cvar = "vrmod_unoff_inputmode",
				options = { { label = "SteamVR Bindings (Default)", value = "0" }, { label = "Lua Keybinding", value = "1" } } },
			{ type = "checkbox", label = "Module Error: Lock VRMod Menu", cvar = "vrmod_error_hard" },
			{ type = "section", text = "Actions" },
			{ type = "button", label = "Re-extract Module Files", command = "vrmod_module_extract" },
			{ type = "button", label = "Open Keybinding Editor", command = "vrmod_keybinding_menu" },
			{ type = "button", label = "Keybinding Wizard (VR)", command = "vrmod_keybinding_wizard" },
			{ type = "button", label = "Open Module Folder Guide", command = "vrmod_open_module_folder" },
			{ type = "button", label = "Print Module Diagnostics", command = "vrmod_module_diagnostics" },
			{ type = "section", text = "Troubleshooting" },
			{ type = "help", text = "If module is not working: 1) Go to garrysmod/data/vrmod_module/ 2) Rename install.txt -> install.bat 3) Run install.bat, restart Gmod 4) Add GarrysMod folder to AV exclusions if blocked" },
		},
	},

	-- ==============================
	-- Key Mapping
	-- ==============================
	{
		key = "keymapping", label = "Key Mapping", icon = "icon16/keyboard.png",
		items = {
			{ type = "checkbox", label = "Enable Input Emulation", cvar = "vrmod_unoff_input_emu" },
			{ type = "checkbox", label = "Enable C++ Engine Injection", cvar = "vrmod_unoff_cpp_keyinject" },
			{ type = "section", text = "Key Assignment" },
			{ type = "help", text = "Click a keyboard key, then press a VR controller button to assign." },
			{ type = "button", label = "Open Visual Keyboard Editor", command = "vrmod_input_emu_editor" },
			{ type = "section", text = "Debug" },
			{ type = "button", label = "Print Current Mapping", command = "vrmod_unoff_input_emu_status" },
		},
	},

	-- ==============================
	-- Modules
	-- ==============================
	{
		key = "modules", label = "Modules", icon = "icon16/bricks.png",
		items = {
			{ type = "help", text = "Changes require Gmod restart to take effect." },
			{ type = "section", text = "Addon-Only Mode" },
			{ type = "checkbox", label = "Addon-Only Mode (skip root files)", cvar = "vrmod_unoff_addon_only_mode" },
			{ type = "section", text = "Legacy Mode" },
			{ type = "checkbox", label = "Legacy Mode (load only core features)", cvar = "vrmod_unoff_legacy_mode" },
			{ type = "section", text = "Feature Modules" },
			{ type = "checkbox", label = "[2] Holster Type2", cvar = "vrmod_unoff_load_2" },
			{ type = "checkbox", label = "[3] Foregrip", cvar = "vrmod_unoff_load_3" },
			{ type = "checkbox", label = "[4] Magbone/ARC9", cvar = "vrmod_unoff_load_4" },
			{ type = "checkbox", label = "[5] Melee", cvar = "vrmod_unoff_load_5" },
			{ type = "checkbox", label = "[6] Holster Type1", cvar = "vrmod_unoff_load_6" },
			{ type = "checkbox", label = "[7] VR Hand HUD", cvar = "vrmod_unoff_load_7" },
			{ type = "checkbox", label = "[8] Physgun", cvar = "vrmod_unoff_load_8" },
			{ type = "checkbox", label = "[9] VR Pickup", cvar = "vrmod_unoff_load_9" },
			{ type = "checkbox", label = "[10] Debug", cvar = "vrmod_unoff_load_10" },
			{ type = "checkbox", label = "[11] (Reserved)", cvar = "vrmod_unoff_load_11" },
			{ type = "checkbox", label = "[12] Guide", cvar = "vrmod_unoff_load_12" },
			{ type = "checkbox", label = "[13] RealMech", cvar = "vrmod_unoff_load_13" },
			{ type = "checkbox", label = "[14] Throw", cvar = "vrmod_unoff_load_14" },
		},
	},
}

print("[VRMod] Settings02 registry loaded (" .. #VRMOD_SETTINGS02_REGISTRY .. " categories)")
