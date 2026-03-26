-- VRMod Feature Guide - Chinese (Simplified) Language Strings
-- 简体中文字符串

AddCSLuaFile()
if SERVER then return end

VRMOD_FGUIDE_LANG = VRMOD_FGUIDE_LANG or {}
VRMOD_FGUIDE_LANG.zh = {

-- ============================================================
-- UI Chrome
-- ============================================================
window_title = "VR功能指南",
lang_label = "语言:",
topbar_subtitle = "组合功能，获得最佳VR体验",
btn_open_main_menu = "打开VRMod主菜单",
btn_open_settings = "打开设置 (Settings02)",
status_modes = "个模式",
status_lang_en = "英语",
status_lang_ja = "日语",
status_lang_ru = "俄语",
status_lang_zh = "中文",

-- ============================================================
-- Sidebar
-- ============================================================
sidebar_welcome = "概览",
sidebar_group_toggle = "一键切换",
sidebar_group_wizard = "设置向导",
sidebar_group_troubleshoot = "故障排除",

-- ============================================================
-- Welcome Page
-- ============================================================
welcome_title = "VR功能指南",
welcome_desc = "此插件拥有众多功能，组合使用效果更佳。\n本指南将展示如何通过几次点击来设置常见的游戏风格。\n\n从左侧边栏选择一个模式开始。",
welcome_section_toggle = "一键切换",
welcome_toggle_desc = "一键即可同时配置多项设置的模式。\n主播模式、坐姿游玩、左手模式。",
welcome_section_wizard = "设置向导",
welcome_wizard_desc = "分步设置指南。从上到下按顺序操作即可。\n身高校准、全身追踪设置、性能优化。",
welcome_section_troubleshoot = "故障排除",
welcome_troubleshoot_desc = "遇到问题？回答几个问题即可获得解决方案。\n涵盖移动、显示、崩溃、控制和性能问题。",
vr_status_title = "VR状态",
vr_status_active = "VR已激活",
vr_status_inactive = "VR未激活。请从VRMod主菜单启动VR（控制台：vrmod）",

-- ============================================================
-- Mode: Streamer
-- ============================================================
mode_streamer_title = "主播模式",
mode_streamer_desc = "用于直播和录制VR游戏。\n禁用Camera Override，让观众看到正常的第三人称视角，而不是扭曲的VR画面。",
mode_streamer_tip = "观众将看到正常的游戏画面，而你在VR中游玩。非常适合直播！",
mode_streamer_cvar_info = "ConVar: vrmod_cameraoverride",
mode_streamer_btn_on = "启用主播模式",
mode_streamer_btn_off = "禁用主播模式",
mode_streamer_status_on = "已启用 - 观众看到正常画面",
mode_streamer_status_off = "已关闭 - 观众看到VR画面",

-- ============================================================
-- Mode: Seated
-- ============================================================
mode_seated_title = "坐姿游玩",
mode_seated_desc = "坐着玩VR。\n添加高度偏移，即使你坐着，角色也能以正常高度站立。",
mode_seated_tip = "启用后，使用自动调整命令来校准坐姿高度。",
mode_seated_cvar_info = "ConVar: vrmod_seated",
mode_seated_btn_on = "启用坐姿模式",
mode_seated_btn_off = "禁用坐姿模式",
mode_seated_status_on = "已启用 - 坐姿高度偏移已应用",
mode_seated_status_off = "已关闭 - 站立游玩",
mode_seated_auto_adjust = "启用后将自动调整坐姿高度。",

-- ============================================================
-- Mode: Left-Handed
-- ============================================================
mode_lefthand_title = "左手模式",
mode_lefthand_desc = "将主手切换为左手。\n左控制器将成为射击和交互的主手。",
mode_lefthand_tip = "所有武器操作、扳机和交互都会切换到左手。",
mode_lefthand_cvar_info = "ConVar: vrmod_LeftHand",
mode_lefthand_btn_on = "启用左手模式",
mode_lefthand_btn_off = "禁用左手模式",
mode_lefthand_status_on = "已启用 - 左手为主手",
mode_lefthand_status_off = "已关闭 - 右手为主手",

-- ============================================================
-- Wizard: Height & Appearance
-- ============================================================
mode_height_title = "身高与外观",
mode_height_desc = "将VR身体校准为你的真实身高和比例。\n按从上到下的顺序操作。",
mode_height_step1_title = "自动调整",
mode_height_step1_desc = "自动校准角色身高以匹配你的真实身体。\n站直后按下按钮。",
mode_height_step1_btn = "自动调整",
mode_height_step2_title = "启用镜子",
mode_height_step2_desc = "启用VR镜子查看角色外观。\n用来验证自动调整的结果。",
mode_height_step2_btn = "启用镜子",
mode_height_step3_title = "微调眼睛高度",
mode_height_step3_desc = "如果自动调整不够完美，手动调整眼睛高度。\n控制台输入：vrmod_characterEyeHeight <值>（默认：66.8）\n值越大 = 角色越高，值越小 = 角色越矮。",
mode_height_step4_title = "隐藏头部模型",
mode_height_step4_desc = "如果角色的头发或头部遮挡了视野，可以切换隐藏。",
mode_height_step4_btn = "切换头部可见性",

-- ============================================================
-- Wizard: FBT Setup
-- ============================================================
mode_fbt_title = "全身追踪",
mode_fbt_desc = "使用Vive Tracker或类似设备设置全身追踪。\n按步骤配置追踪器。",
mode_fbt_step1_title = "检查追踪器状态",
mode_fbt_step1_desc = "将已连接的VR设备和追踪器信息输出到控制台。\n确保追踪器已开启且在SteamVR中可见。",
mode_fbt_step1_btn = "检查设备",
mode_fbt_step2_title = "配置追踪器角色",
mode_fbt_step2_desc = "在SteamVR设置 > 控制器 > 管理追踪器中：\n为每个追踪器分配角色（左脚、右脚、腰部）。\n此步骤在SteamVR中完成，不是在Garry's Mod中。",
mode_fbt_step3_title = "重启VRMod",
mode_fbt_step3_desc = "VRMod需要重启以检测追踪器配置。\nVR会短暂停止然后重新启动。",
mode_fbt_step3_btn = "重启VR",
mode_fbt_step4_title = "校准",
mode_fbt_step4_desc = "站成T字姿势（双臂伸展）并保持不动几秒钟。\n系统会将追踪器位置与角色身体匹配。",

-- ============================================================
-- Wizard: Performance
-- ============================================================
mode_performance_title = "性能优化",
mode_performance_desc = "优化Garry's Mod的VR性能。\n按步骤应用常见优化。",
mode_performance_step1_title = "启用多核渲染",
mode_performance_step1_desc = "启用多线程渲染以提高CPU利用率。\n这是VR最有效的优化之一。",
mode_performance_step1_btn = "应用",
mode_performance_step2_title = "降低渲染分辨率",
mode_performance_step2_desc = "将VR渲染目标分辨率降低到0.8倍。\n以较小的画质损失换取显著的GPU负载降低。",
mode_performance_step2_btn = "应用 (0.8x)",
mode_performance_step3_title = "额外优化",
mode_performance_step3_desc = "应用额外的Source引擎优化。\n增加地图范围限制以改善大型地图的渲染。",
mode_performance_step3_btn = "应用",
mode_performance_step4_title = "检查结果",
mode_performance_step4_desc = "在控制台输入 cl_showfps 1 查看FPS。\nVR需要大约2倍于头显刷新率的FPS才能舒适游玩。\n如果仍然卡顿，尝试减少插件数量或使用较小的地图。",

-- ============================================================
-- Mode: Troubleshoot
-- ============================================================
mode_troubleshoot_title = "故障排除",
mode_troubleshoot_desc = "回答问题以找到问题的解决方案。\n点击选项继续，或使用[返回]按钮回到上一步。",
ts_btn_back = "返回",
ts_btn_start_over = "重新开始",
ts_solution_title = "解决方案",

-- Troubleshoot: Root
ts_root_question = "你遇到了什么问题？",
ts_cant_move = "无法移动",
ts_display = "显示问题",
ts_crash = "崩溃/错误",
ts_controls = "控制不起作用",
ts_perf = "性能很差",

-- Troubleshoot: Can't Move
ts_cant_move_question = "控制台（~）或主菜单是否打开？",
ts_yes = "是",
ts_no = "否",
ts_cant_move_close = "用~键关闭控制台，或用ESC关闭主菜单。它们打开时无法移动。",
ts_cant_move_2_question = "你在特殊游戏模式中吗（Helix、DarkRP等）？",
ts_no_sandbox = "否/沙盒模式",
ts_cant_move_gamemode = "某些游戏模式（尤其是Helix）会限制VR移动。尝试穿墙飞行（V键）。如果可以，说明是游戏模式的限制。",
ts_cant_move_3_question = "手可以动但不能走路？",
ts_hands_ok = "是 - 手能动但不能走",
ts_nothing = "否 - 完全不能动",
ts_cant_move_stick = "检查SteamVR控制器绑定。SteamVR设置 > 控制器 > 管理绑定 > 选择VRMod。确保摇杆/触摸板已绑定到移动。",
ts_cant_move_frozen = "尝试：1) 在控制台输入 vrmod_stop 然后 vrmod_start。2) 如果仍然不动，禁用VRMod以外的所有插件重试。3) 在SteamVR Home中检查头显是否正常追踪。",

-- Troubleshoot: Display
ts_display_question = "你看到了什么？",
ts_gray_eye = "一只眼睛是灰色的",
ts_flicker = "屏幕闪烁",
ts_borders = "黑色边框",
ts_head = "看到头部/头发",
ts_wobble = "画面拉伸/抖动",
ts_display_gray = "插件冲突是最常见的原因。禁用所有插件，只测试VRMod。如果正常，逐个重新启用插件找出冲突源。ReShade是已知原因。",
ts_display_flicker_question = "SteamVR的桌面游戏剧院是否已禁用？",
ts_dont_know = "不知道/没有",
ts_yes_disabled = "是，已禁用",
ts_display_flicker_fix = "Steam库 > 右键Garry's Mod > 属性 > 常规 > 取消勾选"SteamVR激活时使用桌面游戏剧院"。同时在启动选项中添加 -window。",
ts_display_flicker_2 = "尝试在SteamVR设置中禁用运动平滑（视频 > 运动平滑 > 关闭）。同时禁用所有插件检查冲突。",
ts_display_borders = "视野周围的黑色边框是Quest 3因FOV差异导致的已知问题。尝试调整SteamVR渲染分辨率（设置 > 视频 > 渲染分辨率）。这是VRMod上游的限制。",
ts_display_head_question = "是否在设置中启用了"隐藏头部"？",
ts_yes_still_visible = "是，但仍然可见",
ts_display_head_fix = "VRMod菜单 > 角色 > 启用 vrmod_hide_head。这会将头部骨骼从VR视角偏移。",
ts_display_head_adjust = "调整 vrmod_hide_head_pos_y（前后偏移）。默认为20。尝试增加到30-40。使用镜子检查效果。",
ts_display_wobble = "在SteamVR中禁用运动平滑。在Steam安装文件夹 > config 中找到 steamvr.vrsettings，将运动平滑设为false。这是画面抖动最常见的原因。",

-- Troubleshoot: Crash
ts_crash_question = "崩溃在什么时候发生？",
ts_on_start = "启动VR时（vrmod_start）",
ts_gameplay = "游戏过程中",
ts_error_msg = "控制台中有错误消息",
ts_crash_start_question = "启动选项中是否有 -dxlevel 95？",
ts_crash_dxlevel = "在GMod启动选项中添加 -dxlevel 95（Steam > GMod > 属性 > 启动选项）。启动游戏一次后删除 -dxlevel 95（只需运行一次）。同时确保桌面游戏剧院已禁用。",
ts_crash_start_2 = "尝试：1) 在Steam中验证GMod文件完整性。2) 重新安装SteamVR。3) 禁用VRMod以外的所有插件。4) 启动选项 -window -novid。",
ts_crash_gameplay = "很可能是插件冲突。只启用VRMod测试。如果稳定，逐个添加插件。渲染/HUD/玩家模型类插件最容易冲突。",
ts_crash_error_question = "你看到什么错误？",
ts_module = "模块未安装",
ts_manifest = "SetActionManifestPath failed",
ts_version = "未知模块版本",
ts_other = "其他/无法读取",
ts_crash_module = "从 catse.net/vrmod 下载VRMod模块，将DLL放入 garrysmod/lua/bin/。如果杀毒软件阻止，请添加例外。Semiofficial插件支持"原版"和"semiofficial"两种模块。",
ts_crash_manifest = "这是SteamVR端的问题。完全退出SteamVR > 重启电脑 > 需要时重新安装SteamVR。",
ts_crash_version = "模块版本不匹配。从 catse.net/vrmod 重新下载最新模块。确保 garrysmod/lua/bin/ 中只有一个vrmod DLL。",
ts_crash_other = "查看控制台中的完整错误消息。常见修复：1) 验证GMod文件。2) 重新安装SteamVR。3) 删除ReShade。4) 不使用其他插件测试。如果错误持续，请附带完整错误文本报告。",

-- Troubleshoot: Controls
ts_controls_question = "具体什么不起作用？",
ts_grab = "无法抓取/拾取物体",
ts_use = "Use键不起作用",
ts_trigger = "扳机不射击",
ts_vehicle = "载具控制",
ts_controls_grab = "将手靠近物体。抓取范围由 vrmod_pickup_range 设置（默认：1.1）。可以在设置中增加。同时检查 vrmod_manualpickups 是否启用。",
ts_controls_use = "Oculus/Meta控制器：扳机需要完全按下（不是半按）。同时检查SteamVR绑定 - "Use"动作应绑定到扳机。",
ts_controls_trigger = "检查VRMod的SteamVR控制器绑定。设置 > 控制器 > 管理绑定 > VRMod。需要时重置为默认绑定。",
ts_controls_vehicle_question = "你能进入载具吗？",
ts_cant_enter = "无法进入载具",
ts_cant_drive = "进入了但无法驾驶",
ts_cant_shoot = "无法从载具射击",
ts_vehicle_enter = "靠近载具并按Use键（完全按下扳机）。某些载具插件（SimFPhys）可能需要看向车门区域。",
ts_vehicle_drive = "检查SteamVR绑定中的"In Vehicle"类别。方向盘和油门应已绑定。同时尝试 vrmod_lvs_input_mode 0（传统）或 1（网络）切换输入模式。",
ts_vehicle_shoot = "在SteamVR绑定中检查"In Vehicle" > "turret_primary_fire"是否绑定到扳机。LVS载具可能还需要绑定武器选择。",

-- Troubleshoot: Performance
ts_perf_question = "没有VR时的桌面FPS是多少？（用 cl_showfps 1 检查）",
ts_low = "低于200 FPS",
ts_med = "200-400 FPS",
ts_high = "高于400 FPS",
ts_perf_low = "基础FPS对VR来说太低。减少插件数量，使用小地图，降低GMod图形设置。VR大约会将FPS减半（渲染两次）。使用本指南的性能向导快速优化。",
ts_perf_med = "尝试以下优化：1) gmod_mcore_test 1（多核）。2) mat_queue_mode -1（自动）。3) vrmod_rtWidth_Multiplier 降到1.6。4) 禁用不必要的插件。使用本指南的性能向导一键应用。",
ts_perf_high = "基础FPS良好。如果VR仍然卡：1) 降低SteamVR渲染分辨率（设置 > 视频）。2) 禁用运动平滑。3) 检查特定插件冲突。4) 尝试小地图排查问题。",

}

print("[VRMod] Feature Guide ZH language loaded")
