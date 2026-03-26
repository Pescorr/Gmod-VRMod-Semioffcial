-- VRMod Feature Guide - English Language Strings

AddCSLuaFile()
if SERVER then return end

VRMOD_FGUIDE_LANG = VRMOD_FGUIDE_LANG or {}
VRMOD_FGUIDE_LANG.en = {

-- ============================================================
-- UI Chrome
-- ============================================================
window_title = "VR Feature Guide",
lang_label = "Language:",
topbar_subtitle = "Combine features for the best VR experience",
btn_open_main_menu = "Open Main VRMod Menu",
btn_open_settings = "Open Settings (Settings02)",
status_modes = "modes",
status_lang_en = "English",
status_lang_ja = "Japanese",
status_lang_ru = "Russian",
status_lang_zh = "Chinese",

-- ============================================================
-- Sidebar
-- ============================================================
sidebar_welcome = "Overview",
sidebar_group_toggle = "Quick Toggle",
sidebar_group_wizard = "Setup Wizard",
sidebar_group_troubleshoot = "Troubleshoot",

-- ============================================================
-- Welcome Page
-- ============================================================
welcome_title = "VR Feature Guide",
welcome_desc = "This addon has many features that work even better when combined.\nThis guide shows you how to set up common play styles with just a few clicks.\n\nSelect a mode from the left sidebar to get started.",
welcome_section_toggle = "Quick Toggle",
welcome_toggle_desc = "One-click modes that instantly configure multiple settings.\nStreamer Mode, Seated Play, Left-Handed Mode.",
welcome_section_wizard = "Setup Wizard",
welcome_wizard_desc = "Step-by-step setup guides. Follow the steps from top to bottom.\nHeight calibration, Full Body Tracking setup, Performance optimization.",
welcome_section_troubleshoot = "Troubleshoot",
welcome_troubleshoot_desc = "Having a problem? Answer a few questions and get a solution.\nCovers movement, display, crashes, controls, and performance issues.",
vr_status_title = "VR Status",
vr_status_active = "VR is ACTIVE",
vr_status_inactive = "VR is NOT active. Start VR from the main VRMod menu (console: vrmod)",

-- ============================================================
-- Mode: Streamer
-- ============================================================
mode_streamer_title = "Streamer Mode",
mode_streamer_desc = "For streaming and recording VR gameplay.\nDisables Camera Override so your viewers see normal third-person view instead of the warped VR perspective.",
mode_streamer_tip = "Your viewers will see a normal game view while you play in VR. Perfect for streaming!",
mode_streamer_cvar_info = "ConVar: vrmod_cameraoverride",
mode_streamer_btn_on = "Enable Streamer Mode",
mode_streamer_btn_off = "Disable Streamer Mode",
mode_streamer_status_on = "ACTIVE - Viewers see normal view",
mode_streamer_status_off = "OFF - Viewers see VR view",

-- ============================================================
-- Mode: Seated
-- ============================================================
mode_seated_title = "Seated Play",
mode_seated_desc = "Play VR while sitting down.\nAdds height offset so your character stands at normal height even though you're seated.",
mode_seated_tip = "After enabling, use the auto-adjust command to calibrate your seated height.",
mode_seated_cvar_info = "ConVar: vrmod_seated",
mode_seated_btn_on = "Enable Seated Mode",
mode_seated_btn_off = "Disable Seated Mode",
mode_seated_status_on = "ACTIVE - Seated height offset applied",
mode_seated_status_off = "OFF - Standing play",
mode_seated_auto_adjust = "Auto-adjust seated height will run after enabling.",

-- ============================================================
-- Mode: Left-Handed
-- ============================================================
mode_lefthand_title = "Left-Handed Mode",
mode_lefthand_desc = "Swap the dominant hand to left.\nYour left controller becomes the primary hand for shooting and interacting.",
mode_lefthand_tip = "All weapon handling, triggers, and interactions swap to the left hand.",
mode_lefthand_cvar_info = "ConVar: vrmod_LeftHand",
mode_lefthand_btn_on = "Enable Left-Handed",
mode_lefthand_btn_off = "Disable Left-Handed",
mode_lefthand_status_on = "ACTIVE - Left hand is dominant",
mode_lefthand_status_off = "OFF - Right hand is dominant",

-- ============================================================
-- Wizard: Height & Appearance
-- ============================================================
mode_height_title = "Height & Appearance",
mode_height_desc = "Calibrate your VR body to match your real height and proportions.\nFollow the steps from top to bottom.",
mode_height_step1_title = "Auto Adjust",
mode_height_step1_desc = "Automatically calibrate character height to match your real body.\nStand straight and press the button.",
mode_height_step1_btn = "Auto Adjust",
mode_height_step2_title = "Enable Mirror",
mode_height_step2_desc = "Enable the VR mirror to check how your character looks.\nUse this to verify the auto-adjust result.",
mode_height_step2_btn = "Enable Mirror",
mode_height_step3_title = "Fine-Tune Eye Height",
mode_height_step3_desc = "If the auto-adjust isn't perfect, manually adjust the eye height.\nUse console: vrmod_characterEyeHeight <value> (default: 66.8)\nHigher = taller character, Lower = shorter.",
mode_height_step4_title = "Hide Head Model",
mode_height_step4_desc = "If you see your character's hair or head blocking your view, toggle this to hide it.",
mode_height_step4_btn = "Toggle Head Visibility",

-- ============================================================
-- Wizard: FBT Setup
-- ============================================================
mode_fbt_title = "Full Body Tracking",
mode_fbt_desc = "Set up full body tracking with Vive Trackers or similar devices.\nFollow the steps to configure trackers.",
mode_fbt_step1_title = "Check Tracker Status",
mode_fbt_step1_desc = "Print connected VR devices and tracker info to the console.\nMake sure your trackers are turned on and visible in SteamVR.",
mode_fbt_step1_btn = "Check Devices",
mode_fbt_step2_title = "Configure Tracker Roles",
mode_fbt_step2_desc = "In SteamVR Settings > Controllers > Manage Trackers:\nAssign roles to each tracker (left foot, right foot, waist).\nThis step is done in SteamVR, not in Garry's Mod.",
mode_fbt_step3_title = "Restart VRMod",
mode_fbt_step3_desc = "VRMod needs to restart to detect the tracker configuration.\nThis will briefly stop and restart VR.",
mode_fbt_step3_btn = "Restart VR",
mode_fbt_step4_title = "Calibrate",
mode_fbt_step4_desc = "Stand in a T-pose (arms straight out) and hold still for a few seconds.\nThe system will match tracker positions to your character's body.",

-- ============================================================
-- Wizard: Performance
-- ============================================================
mode_performance_title = "Performance",
mode_performance_desc = "Optimize Garry's Mod for better VR performance.\nFollow the steps to apply common optimizations.",
mode_performance_step1_title = "Enable Multicore Rendering",
mode_performance_step1_desc = "Enables multi-threaded rendering for better CPU utilization.\nThis is one of the most impactful optimizations for VR.",
mode_performance_step1_btn = "Apply",
mode_performance_step2_title = "Reduce Render Resolution",
mode_performance_step2_desc = "Lowers the VR render target resolution to 0.8x.\nReduces GPU load significantly with a small quality trade-off.",
mode_performance_step2_btn = "Apply (0.8x)",
mode_performance_step3_title = "Extra Optimizations",
mode_performance_step3_desc = "Applies additional Source Engine optimizations.\nIncreases map extents limit for better rendering of large maps.",
mode_performance_step3_btn = "Apply",
mode_performance_step4_title = "Check Result",
mode_performance_step4_desc = "Check your FPS with cl_showfps 1 in console.\nVR needs roughly 2x your headset's refresh rate for comfortable play.\nIf still slow, try reducing addon count or using smaller maps.",

-- ============================================================
-- Mode: Troubleshoot
-- ============================================================
mode_troubleshoot_title = "Troubleshoot",
mode_troubleshoot_desc = "Answer the questions to find a solution to your problem.\nClick an option to continue, or use the Back button to return.",
ts_btn_back = "Back",
ts_btn_start_over = "Start Over",
ts_solution_title = "Solution",

-- Troubleshoot: Root
ts_root_question = "What kind of problem are you having?",
ts_cant_move = "Can't move",
ts_display = "Display issues",
ts_crash = "Crash / Error",
ts_controls = "Controls not working",
ts_perf = "Performance is bad",

-- Troubleshoot: Can't Move
ts_cant_move_question = "Is the console (~) or main menu open?",
ts_yes = "Yes",
ts_no = "No",
ts_cant_move_close = "Close the console with ~ key, or close the main menu with ESC. You cannot move while these are open.",
ts_cant_move_2_question = "Are you in a special gamemode (Helix, DarkRP, etc.)?",
ts_no_sandbox = "No / Sandbox",
ts_cant_move_gamemode = "Some gamemodes (especially Helix) restrict VR movement. Try noclip (V key). If that works, it's a gamemode limitation.",
ts_cant_move_3_question = "Can you move your hands but not walk?",
ts_hands_ok = "Yes - hands work, can't walk",
ts_nothing = "No - nothing moves at all",
ts_cant_move_stick = "Check SteamVR controller bindings. Go to SteamVR Settings > Controllers > Manage Controller Bindings > select VRMod. Make sure the thumbstick/trackpad is bound to movement.",
ts_cant_move_frozen = "Try: 1) vrmod_stop then vrmod_start in console. 2) If still frozen, disable all other addons and retry. 3) Check if your headset is tracking properly in SteamVR Home.",

-- Troubleshoot: Display
ts_display_question = "What do you see?",
ts_gray_eye = "One eye is gray",
ts_flicker = "Screen flickering",
ts_borders = "Black borders",
ts_head = "Head/hair in view",
ts_wobble = "View stretches/wobbles",
ts_display_gray = "Addon conflict is the most common cause. Disable ALL other addons, test VRMod alone. If it works, re-enable addons one by one to find the culprit. ReShade is a known cause.",
ts_display_flicker_question = "Is SteamVR Desktop Game Theatre disabled?",
ts_dont_know = "I don't know / No",
ts_yes_disabled = "Yes, it's disabled",
ts_display_flicker_fix = "Steam Library > Right-click Garry's Mod > Properties > General > Uncheck 'Use Desktop Game Theatre while SteamVR is active'. Also add -window to launch options.",
ts_display_flicker_2 = "Try disabling Motion Smoothing in SteamVR settings (Video > Motion Smoothing > OFF). Also disable all other addons to check for conflicts.",
ts_display_borders = "Black borders around vision are a known issue with Quest 3 due to FOV differences. Try adjusting SteamVR render resolution (Settings > Video > Render Resolution). This is an upstream VRMod limitation.",
ts_display_head_question = "Have you enabled 'Hide Head' in settings?",
ts_yes_still_visible = "Yes, but still visible",
ts_display_head_fix = "Go to VRMod menu > Character > enable vrmod_hide_head. This offsets head bones from your VR view.",
ts_display_head_adjust = "Adjust vrmod_hide_head_pos_y (front/back offset). Default is 20. Try increasing to 30-40. Use the mirror to check results.",
ts_display_wobble = "Disable Motion Smoothing in SteamVR. Find steamvr.vrsettings in your Steam install folder > config, and set Motion Smoothing to false. This is the most common cause of view wobble/stretching.",

-- Troubleshoot: Crash
ts_crash_question = "When does the crash happen?",
ts_on_start = "On VR start (vrmod_start)",
ts_gameplay = "During gameplay",
ts_error_msg = "Error message in console",
ts_crash_start_question = "Do you have -dxlevel 95 in launch options?",
ts_crash_dxlevel = "Add -dxlevel 95 to GMod launch options (Steam > GMod > Properties > Launch Options). Start the game once, then REMOVE -dxlevel 95 (it only needs to run once). Also ensure Desktop Game Theatre is disabled.",
ts_crash_start_2 = "Try: 1) Verify GMod file integrity in Steam. 2) Reinstall SteamVR. 3) Disable all addons except VRMod. 4) Try -window -novid launch options.",
ts_crash_gameplay = "Most likely an addon conflict. Test with only VRMod enabled. If stable, add addons back one by one. Rendering/HUD/playermodel addons are most likely to conflict.",
ts_crash_error_question = "What error do you see?",
ts_module = "Module not installed",
ts_manifest = "SetActionManifestPath failed",
ts_version = "Unknown module version",
ts_other = "Other / can't read it",
ts_crash_module = "Download the VRMod module from catse.net/vrmod and place the DLL in garrysmod/lua/bin/. If antivirus blocks it, add an exception. The semiofficial addon works with both 'original' and 'semiofficial' modules.",
ts_crash_manifest = "This is a SteamVR-side issue. Fully quit SteamVR > Restart PC > Reinstall SteamVR if needed. Happens across all VRMod versions.",
ts_crash_version = "Module version mismatch. Re-download the latest module from catse.net/vrmod. Make sure you only have ONE vrmod DLL in garrysmod/lua/bin/.",
ts_crash_other = "Check console for the full error. Common fixes: 1) Verify GMod files. 2) Reinstall SteamVR. 3) Remove ReShade if installed. 4) Try with no other addons. If the error persists, report it with the full error text.",

-- Troubleshoot: Controls
ts_controls_question = "What specifically isn't working?",
ts_grab = "Can't grab / pick up objects",
ts_use = "Use key doesn't work",
ts_trigger = "Trigger doesn't fire",
ts_vehicle = "Vehicle controls",
ts_controls_grab = "Move your hand closer to the object. The grab range is set by vrmod_pickup_range (default 1.1). You can increase it in settings. Also check vrmod_manualpickups is enabled.",
ts_controls_use = "For Oculus/Meta controllers: the trigger must be FULLY pressed (not half-pressed). Also check SteamVR bindings - the 'Use' action should be bound to the trigger.",
ts_controls_trigger = "Check SteamVR controller bindings for VRMod. Go to SteamVR Settings > Controllers > Manage Bindings > VRMod. Reset to default bindings if needed.",
ts_controls_vehicle_question = "Can you get IN the vehicle?",
ts_cant_enter = "Can't enter vehicle",
ts_cant_drive = "In vehicle but can't drive",
ts_cant_shoot = "Can't shoot from vehicle",
ts_vehicle_enter = "Approach the vehicle and press the Use key (fully press trigger). For some vehicle addons (SimFPhys), you may need to look at the door area specifically.",
ts_vehicle_drive = "Check SteamVR bindings for 'In Vehicle' category. Steering and throttle should be bound. Also try vrmod_lvs_input_mode 0 (legacy) or 1 (networked) to switch input modes.",
ts_vehicle_shoot = "In SteamVR bindings, check 'In Vehicle' > 'turret_primary_fire' is bound to trigger. For LVS vehicles, weapon selection may also need binding.",

-- Troubleshoot: Performance
ts_perf_question = "What's your desktop FPS WITHOUT VR? (check with cl_showfps 1)",
ts_low = "Below 200 FPS",
ts_med = "200-400 FPS",
ts_high = "Above 400 FPS",
ts_perf_low = "Your base FPS is too low for comfortable VR. Reduce addon count, use smaller maps, lower GMod graphics settings. VR roughly halves your FPS (rendering twice). Use the Performance wizard button in this guide for quick optimizations.",
ts_perf_med = "Try these optimizations: 1) gmod_mcore_test 1 (multicore). 2) mat_queue_mode -1 (auto). 3) Reduce vrmod_rtWidth_Multiplier to 1.6. 4) Disable unnecessary addons. Use the Performance wizard in this guide for one-click apply.",
ts_perf_high = "Your base FPS is good. If VR is still slow: 1) Lower SteamVR render resolution (Settings > Video). 2) Disable Motion Smoothing. 3) Check for specific addon conflicts. 4) Try a small map to isolate the issue.",

}

print("[VRMod] Feature Guide EN language loaded")
