-- VRMod Semi-Official Addon Plus - Localization System
-- 多言語対応システム
-- Extensible multi-language support for UI text

if SERVER then return end

VRMOD_LANG = {}
VRMOD_LANG.current = "en" -- Default language / デフォルト言語

-- English strings / 英語文字列
VRMOD_LANG.en = {
	-- Menu titles
	menu_settings02 = "Settings02",
	menu_vr = "VR  ",
	menu_character = "Character",
	menu_ui = "UI Settings",
	menu_gameplay = "Gameplay",
	menu_quickmenu = "Quick Menu",
	menu_network = "Network",
	menu_advanced = "Advanced",
	menu_melee = "VR Melee",
	menu_magazine = "VR Magazine",
	menu_foregrip = "VR Grip",
	menu_physgun = "VR Physgun",
	menu_beam_pickup = "VR Pickup",
	-- Common buttons
	btn_restore_defaults = "Restore Default Settings",
	btn_apply = "Apply",
	btn_reset = "Reset",
	btn_close = "Close",
	btn_toggle_mirror = "Toggle Mirror",
	btn_enable_seated = "Enable\nSeated\nOffset",
	btn_disable_seated = "Disable\nSeated\nOffset",
	btn_reset_config = "Reset\nConfig",
	btn_auto_scale = "Auto\nScale",
	btn_auto_set = "Auto\nSet",
	btn_hide_head = "Hide\nHead",
	btn_reset_body = "Reset\nBody",
	btn_hide_near_hmd = "HideNear\nHMD",
	btn_toggle_laser = "Toggle Laser Pointer",
	btn_weapon_config = "Weapon Viewmodel Setting",
	-- Labels
	label_scale = "Character Scale",
	label_eye_height = "Character Eye Height",
	label_head_hmd_dist = "Character Head to HMD Distance",
	label_crouch_threshold = "Crouch Threshold",
	label_znear = "Z Near",
	label_seated_mode = "Enable seated offset",
	label_seated_offset = "Seated Offset",
	label_jump_duck = "[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP",
	label_teleport = "[Teleport Enable]",
	label_flashlight = "[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD",
	label_manual_pickup = "Manual Pickup (by Hugo)",
	label_pickup_weight = "Pickup Weight (Server)",
	label_pickup_range = "Pickup Range (Server)",
	label_pickup_limit = "Pickup Limit (Server)",
	-- Tooltips
	tooltip_znear = "Objects closer than this will become transparent. Increase if you see parts of your head.",
	tooltip_seated = "Adjust from height adjustment menu",
	tooltip_flashlight = "0 = Right Hand, 1 = Left Hand, 2 = HMD",
	-- Messages
	msg_character_reset = "Character settings reset to defaults",
	msg_melee_reset = "VR Melee settings have been reset to defaults.",
	msg_magazine_reset = "Magazine settings reset to defaults",
	msg_gameplay_reset = "Gameplay settings reset to defaults",
	msg_ui_reset = "UI settings reset to defaults",
	msg_quickmenu_reset = "Quick menu settings reset to defaults",
	msg_network_reset = "Network settings reset to defaults",
	msg_advanced_reset = "Advanced settings reset to defaults",
	msg_foregrip_reset = "Foregrip settings reset to defaults",
	msg_physgun_reset = "Physgun settings reset to defaults",
	msg_beam_pickup_reset = "Beam pickup settings reset to defaults",
	msg_language_set = "Language set to: ",
	msg_unknown_category = "Error: Unknown category",
}

-- Japanese strings / 日本語文字列
VRMOD_LANG.ja = {
	-- Menu titles
	menu_settings02 = "設定02",
	menu_vr = "VR  ",
	menu_character = "キャラクター",
	menu_ui = "UI設定",
	menu_gameplay = "ゲームプレイ",
	menu_quickmenu = "クイックメニュー",
	menu_network = "ネットワーク",
	menu_advanced = "詳細設定",
	menu_melee = "VR近接戦闘",
	menu_magazine = "VRマガジン",
	menu_foregrip = "VRグリップ",
	menu_physgun = "VR物理ガン",
	menu_beam_pickup = "VRピックアップ",
	-- Common buttons
	btn_restore_defaults = "デフォルト設定に戻す",
	btn_apply = "適用",
	btn_reset = "リセット",
	btn_close = "閉じる",
	btn_toggle_mirror = "鏡を切り替え",
	btn_enable_seated = "座位\nオフセット\n有効",
	btn_disable_seated = "座位\nオフセット\n無効",
	btn_reset_config = "設定\nリセット",
	btn_auto_scale = "自動\nスケール",
	btn_auto_set = "自動\n設定",
	btn_hide_head = "頭を\n非表示",
	btn_reset_body = "体を\nリセット",
	btn_hide_near_hmd = "HMD近く\nを非表示",
	btn_toggle_laser = "レーザーポインター切替",
	btn_weapon_config = "武器ビューモデル設定",
	-- Labels
	label_scale = "キャラクタースケール",
	label_eye_height = "キャラクター目線の高さ",
	label_head_hmd_dist = "頭とHMDの距離",
	label_crouch_threshold = "しゃがみ閾値",
	label_znear = "Z近接値",
	label_seated_mode = "座位オフセットを有効にする",
	label_seated_offset = "座位オフセット",
	label_jump_duck = "[ジャンプキー自動しゃがみ]\nON => ジャンプキー = IN_DUCK + IN_JUMP\nOFF => ジャンプキー = IN_JUMP",
	label_teleport = "[テレポート有効化]",
	label_flashlight = "[懐中電灯の取り付け位置]\n0 = 右手 1 = 左手\n 2 = HMD",
	label_manual_pickup = "手動ピックアップ (by Hugo)",
	label_pickup_weight = "ピックアップ重量 (サーバー)",
	label_pickup_range = "ピックアップ範囲 (サーバー)",
	label_pickup_limit = "ピックアップ制限 (サーバー)",
	-- Tooltips
	tooltip_znear = "これより近い物体は透明になります。頭の一部が見える場合は増やしてください。",
	tooltip_seated = "高さ調整メニューから調整",
	tooltip_flashlight = "0 = 右手、1 = 左手、2 = HMD",
	-- Messages
	msg_character_reset = "キャラクター設定をデフォルトにリセットしました",
	msg_melee_reset = "VR近接戦闘設定をデフォルトにリセットしました。",
	msg_magazine_reset = "マガジン設定をデフォルトにリセットしました",
	msg_gameplay_reset = "ゲームプレイ設定をデフォルトにリセットしました",
	msg_ui_reset = "UI設定をデフォルトにリセットしました",
	msg_quickmenu_reset = "クイックメニュー設定をデフォルトにリセットしました",
	msg_network_reset = "ネットワーク設定をデフォルトにリセットしました",
	msg_advanced_reset = "詳細設定をデフォルトにリセットしました",
	msg_foregrip_reset = "フォアグリップ設定をデフォルトにリセットしました",
	msg_physgun_reset = "物理ガン設定をデフォルトにリセットしました",
	msg_beam_pickup_reset = "ビームピックアップ設定をデフォルトにリセットしました",
	msg_language_set = "言語を設定しました: ",
	msg_unknown_category = "エラー: 不明なカテゴリ",
}

-- Chinese Simplified strings / 简体中文
VRMOD_LANG.zh = {
	-- Menu titles
	menu_settings02 = "Settings02",
	menu_vr = "VR  ",
	menu_character = "角色",
	menu_ui = "UI设置",
	menu_gameplay = "游戏性",
	menu_quickmenu = "��捷菜单",
	menu_network = "网络",
	menu_advanced = "高��设置",
	menu_melee = "VR近战",
	menu_magazine = "VR弹匣",
	menu_foregrip = "VR握把",
	menu_physgun = "VR物理枪",
	menu_beam_pickup = "VR拾取",
	-- Common buttons
	btn_restore_defaults = "恢复默认设置",
	btn_apply = "应用",
	btn_reset = "重置",
	btn_close = "关闭",
	btn_toggle_mirror = "切换镜像",
	btn_enable_seated = "启用\n坐姿\n偏移",
	btn_disable_seated = "禁用\n坐姿\n偏移",
	btn_reset_config = "重置\n配置",
	btn_auto_scale = "自动\n缩放",
	btn_auto_set = "自动\n设置",
	btn_hide_head = "隐藏\n头部",
	btn_reset_body = "重置\n身体",
	btn_hide_near_hmd = "隐藏HMD\n附近物体",
	btn_toggle_laser = "切换激光指示器",
	btn_weapon_config = "��器视角模型设置",
	-- Labels
	label_scale = "角色缩放",
	label_eye_height = "角色眼睛高度",
	label_head_hmd_dist = "���部到HMD距离",
	label_crouch_threshold = "蹲下阈值",
	label_znear = "Z近裁面",
	label_seated_mode = "启用坐姿偏移",
	label_seated_offset = "坐姿偏移量",
	label_jump_duck = "[跳跃键自动蹲下]\nON => 跳跃键 = IN_DUCK + IN_JUMP\nOFF => 跳跃键 = IN_JUMP",
	label_teleport = "[传送启用]",
	label_flashlight = "[手电筒安装位置]\n0 = 右手 1 = 左手\n 2 = HMD",
	label_manual_pickup = "手动拾取 (by Hugo)",
	label_pickup_weight = "拾取重量 (服务器)",
	label_pickup_range = "拾取范围 (服务器)",
	label_pickup_limit = "拾取限制 (服务器)",
	-- Tooltips
	tooltip_znear = "比此距离更近的物体将变为透明。如果看到头部的一部分，请增大此值。",
	tooltip_seated = "从高度调整菜单中调整",
	tooltip_flashlight = "0 = 右手、1 = 左手、2 = HMD",
	-- Messages
	msg_character_reset = "角色设置已恢复为默认值",
	msg_melee_reset = "VR近战设置已恢复为默认值。",
	msg_magazine_reset = "弹匣设置已恢复为默认值",
	msg_gameplay_reset = "游戏性设置已恢复为默认值",
	msg_ui_reset = "UI设置已恢复为默认值",
	msg_quickmenu_reset = "快捷菜单设置已恢复为默认值",
	msg_network_reset = "网络设置已恢复为默认值",
	msg_advanced_reset = "高级设置已恢复为默认值",
	msg_foregrip_reset = "握把设置已恢复为默认值",
	msg_physgun_reset = "物理枪设置已恢复为默认值",
	msg_beam_pickup_reset = "光束拾取设置已恢复为默认值",
	msg_language_set = "语言已设置为: ",
	msg_unknown_category = "错误: 未知类别",
}

-- Russian strings / Русский
VRMOD_LANG.ru = {
	-- Menu titles
	menu_settings02 = "Settings02",
	menu_vr = "VR  ",
	menu_character = "Персонаж",
	menu_ui = "Настройки UI",
	menu_gameplay = "Геймплей",
	menu_quickmenu = "Быстрое меню",
	menu_network = "Сеть",
	menu_advanced = "Дополнительно",
	menu_melee = "VR Ближний бой",
	menu_magazine = "VR Магазин",
	menu_foregrip = "VR Хват",
	menu_physgun = "VR Физпушка",
	menu_beam_pickup = "VR Подбор",
	-- Common buttons
	btn_restore_defaults = "Сбросить настройки",
	btn_apply = "Применить",
	btn_reset = "Сброс",
	btn_close = "Закрыть",
	btn_toggle_mirror = "Переключить зеркало",
	btn_enable_seated = "Включить\nсидячий\nрежим",
	btn_disable_seated = "Выключить\nсидячий\nрежим",
	btn_reset_config = "Сброс\nнастроек",
	btn_auto_scale = "Авто\nмасштаб",
	btn_auto_set = "Авто\nнастройка",
	btn_hide_head = "Скрыть\nголову",
	btn_reset_body = "Сброс\nтела",
	btn_hide_near_hmd = "Скрыть\nрядом с HMD",
	btn_toggle_laser = "Лазерный указатель",
	btn_weapon_config = "Настройка модели оружия",
	-- Labels
	label_scale = "Масштаб персонажа",
	label_eye_height = "Высота глаз персонажа",
	label_head_hmd_dist = "Расстояние головы до HMD",
	label_crouch_threshold = "Порог приседания",
	label_znear = "Z ближняя плоскость",
	label_seated_mode = "Включить сидячий режим",
	label_seated_offset = "Смещение сидячего режима",
	label_jump_duck = "[Авто-присед при прыжке]\nON => Прыжок = IN_DUCK + IN_JUMP\nOFF => Прыжок = IN_JUMP",
	label_teleport = "[Телепортация]",
	label_flashlight = "[Крепление фонарика]\n0 = Правая рука 1 = Левая рука\n 2 = HMD",
	label_manual_pickup = "Ручной подбор (by Hugo)",
	label_pickup_weight = "Вес подбора (Сервер)",
	label_pickup_range = "Дальность подбора (Сервер)",
	label_pickup_limit = "Лимит подбора (Сервер)",
	-- Tooltips
	tooltip_znear = "Объекты ближе этого расстояния станут прозрачными. Увеличьте, если видите части головы.",
	tooltip_seated = "Настройте в меню регулировки высоты",
	tooltip_flashlight = "0 = Правая рука, 1 = Левая рука, 2 = HMD",
	-- Messages
	msg_character_reset = "Настройки персонажа сброшены",
	msg_melee_reset = "Настройки ближнего боя сброшены.",
	msg_magazine_reset = "Настройки магазина сброшены",
	msg_gameplay_reset = "Настройки геймплея сброшены",
	msg_ui_reset = "Настройки UI сброшены",
	msg_quickmenu_reset = "Настройки быстрого меню сброшены",
	msg_network_reset = "Настройки сети сброшены",
	msg_advanced_reset = "Дополнительные настройки сброшены",
	msg_foregrip_reset = "Настройки хвата сброшены",
	msg_physgun_reset = "Настройки физпушки сброшены",
	msg_beam_pickup_reset = "Настройки подбора сброшены",
	msg_language_set = "Язык установлен: ",
	msg_unknown_category = "Ошибка: Неизвестная категория",
}

-- Get localized string with fallback chain
-- フォールバックチェーンを使用してローカライズされた文字列を取得
function VRModL(key, fallback)
	-- Try current language
	local lang_table = VRMOD_LANG[VRMOD_LANG.current]
	if lang_table and lang_table[key] then
		return lang_table[key]
	end

	-- Fallback to English
	if VRMOD_LANG.current ~= "en" and VRMOD_LANG.en[key] then
		return VRMOD_LANG.en[key]
	end

	-- Final fallback
	return fallback or key
end

-- Set current language
-- 現在の言語を設定
function VRModSetLanguage(lang_code)
	if VRMOD_LANG[lang_code] then
		VRMOD_LANG.current = lang_code
		CreateClientConVar("vrmod_language", lang_code, true, FCVAR_ARCHIVE, "VRMod UI Language (en/ja/zh/ru)", 0, 0)
		RunConsoleCommand("vrmod_language", lang_code)
		print("[VRMod] " .. VRModL("msg_language_set") .. lang_code)

		return true
	end

	print("[VRMod] Error: Unknown language code '" .. lang_code .. "'")

	return false
end

-- Detect system language
-- システム言語を検出
local function VRModDetectLanguage()
	local gmod_lang = GetConVarString("gmod_language")
	if gmod_lang == "ja" or gmod_lang == "japanese" then
		return "ja"
	elseif gmod_lang == "zh-cn" or gmod_lang == "zh-tw" or gmod_lang == "schinese" or gmod_lang == "tchinese" then
		return "zh"
	elseif gmod_lang == "ru" or gmod_lang == "russian" then
		return "ru"
	end

	return "en" -- Default to English
end

-- Initialize language on load
-- 読み込み時に言語を初期化
hook.Add(
	"Initialize",
	"VRModInitLanguage",
	function()
		-- Check for saved language preference
		local cvar = GetConVar("vrmod_language")
		if cvar then
			local saved_lang = cvar:GetString()
			if saved_lang and saved_lang ~= "" and VRMOD_LANG[saved_lang] then
				VRMOD_LANG.current = saved_lang
				print("[VRMod] Language loaded from settings: " .. saved_lang)

				return
			end
		end

		-- Auto-detect language
		VRMOD_LANG.current = VRModDetectLanguage()
		print("[VRMod] Language auto-detected: " .. VRMOD_LANG.current)
	end
)

-- Console command to change language
-- 言語を変更するコンソールコマンド
concommand.Add(
	"vrmod_setlang",
	function(ply, cmd, args)
		if not args[1] then
			print("[VRMod] Usage: vrmod_setlang <language_code>")
			print("[VRMod] Available languages: en (English), ja (Japanese), zh (Chinese), ru (Russian)")
			print("[VRMod] Current language: " .. VRMOD_LANG.current)

			return
		end

		VRModSetLanguage(args[1])
	end
)

print("[VRMod] Localization system loaded successfully (Current: " .. VRMOD_LANG.current .. ")")
