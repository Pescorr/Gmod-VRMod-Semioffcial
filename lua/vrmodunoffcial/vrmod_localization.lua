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
		CreateClientConVar("vrmod_language", lang_code, true, FCVAR_ARCHIVE, "VRMod UI Language (en/ja)", 0, 0)
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
			print("[VRMod] Available languages: en (English), ja (Japanese)")
			print("[VRMod] Current language: " .. VRMOD_LANG.current)

			return
		end

		VRModSetLanguage(args[1])
	end
)

print("[VRMod] Localization system loaded successfully (Current: " .. VRMOD_LANG.current .. ")")
