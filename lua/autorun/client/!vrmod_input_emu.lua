-- VR Controller → input.IsKeyDown() Emulation Layer (Dual-Layer)
--
-- Problem: VR controller inputs go through SteamVR → VRMod C++ → Lua hooks,
-- bypassing the engine's CInputSystem. Third-party addons that use
-- input.IsKeyDown(KEY_*) only check engine keyboard state, so VR controllers
-- cannot trigger those checks.
--
-- Solution (Dual-Layer):
-- Layer 1 (Lua): Override input.IsKeyDown/IsButtonDown/IsMouseDown at the Lua level
--   to check a VR input state table. Covers all Lua-level callers.
-- Layer 2 (C++): PostMessage(WM_KEYDOWN/WM_KEYUP) to the engine's HWND via
--   VRMOD_SendKeyEvent. Covers engine C++ internal CInputSystem checks.
--   Requires module v102+. Confirmed working 2026-04-01.
--
-- The override is installed at load time (! prefix = first in autorun/client)
-- but has zero cost when VR is not active (empty table → fallthrough).

if SERVER then return end

local TAG = "[VR Input Emu] "

local cv_enabled = CreateClientConVar("vrmod_unoff_input_emu", "0", true, false,
	"Enable VR controller input emulation for input.IsKeyDown() etc.")

local cv_cpp_inject = CreateClientConVar("vrmod_unoff_cpp_keyinject", "1", true, false,
	"Enable C++ engine-level key injection via PostMessage (requires module v102+)")

-- ============================================================================
-- Detour installation (must happen at load time, before other addons)
-- ============================================================================

-- VR input state table (BUTTON_CODE → true/nil)
-- Shared by all three functions since KEY, MOUSE, JOYSTICK ranges don't overlap
local vrKeys = {}

-- Capture original C functions before any other addon can modify them
local orig_IsKeyDown = input.IsKeyDown
local orig_IsButtonDown = input.IsButtonDown
local orig_IsMouseDown = input.IsMouseDown

-- Minimal detours: check VR state → fallthrough to original
-- Error analysis:
--   vrKeys[nil]  → nil (falsy, Lua allows nil indexing for read)  → safe fallthrough
--   vrKeys[num]  → nil or true                                     → safe
--   orig_*(key)  → identical to original behavior                  → safe
function input.IsKeyDown(key)
	if vrKeys[key] then return true end
	return orig_IsKeyDown(key)
end

function input.IsButtonDown(button)
	if vrKeys[button] then return true end
	return orig_IsButtonDown(button)
end

function input.IsMouseDown(mouse)
	if vrKeys[mouse] then return true end
	return orig_IsMouseDown(mouse)
end

-- ============================================================================
-- Gmod BUTTON_CODE → Windows VK_* mapping (for C++ PostMessage layer)
-- ============================================================================

local KEY_TO_VK = {
	[KEY_0] = 0x30, [KEY_1] = 0x31, [KEY_2] = 0x32, [KEY_3] = 0x33,
	[KEY_4] = 0x34, [KEY_5] = 0x35, [KEY_6] = 0x36, [KEY_7] = 0x37,
	[KEY_8] = 0x38, [KEY_9] = 0x39,
	[KEY_A] = 0x41, [KEY_B] = 0x42, [KEY_C] = 0x43, [KEY_D] = 0x44,
	[KEY_E] = 0x45, [KEY_F] = 0x46, [KEY_G] = 0x47, [KEY_H] = 0x48,
	[KEY_I] = 0x49, [KEY_J] = 0x4A, [KEY_K] = 0x4B, [KEY_L] = 0x4C,
	[KEY_M] = 0x4D, [KEY_N] = 0x4E, [KEY_O] = 0x4F, [KEY_P] = 0x50,
	[KEY_Q] = 0x51, [KEY_R] = 0x52, [KEY_S] = 0x53, [KEY_T] = 0x54,
	[KEY_U] = 0x55, [KEY_V] = 0x56, [KEY_W] = 0x57, [KEY_X] = 0x58,
	[KEY_Y] = 0x59, [KEY_Z] = 0x5A,
	[KEY_SPACE] = 0x20,
	[KEY_ENTER] = 0x0D,
	[KEY_ESCAPE] = 0x1B,
	[KEY_TAB] = 0x09,
	[KEY_BACKSPACE] = 0x08,
	[KEY_LSHIFT] = 0xA0, [KEY_RSHIFT] = 0xA1,
	[KEY_LCONTROL] = 0xA2, [KEY_RCONTROL] = 0xA3,
	[KEY_LALT] = 0xA4, [KEY_RALT] = 0xA5,
	[KEY_UP] = 0x26, [KEY_DOWN] = 0x28, [KEY_LEFT] = 0x25, [KEY_RIGHT] = 0x27,
	[KEY_INSERT] = 0x2D, [KEY_DELETE] = 0x2E,
	[KEY_HOME] = 0x24, [KEY_END] = 0x23,
	[KEY_PAGEUP] = 0x21, [KEY_PAGEDOWN] = 0x22,
	[KEY_F1] = 0x70, [KEY_F2] = 0x71, [KEY_F3] = 0x72, [KEY_F4] = 0x73,
	[KEY_F5] = 0x74, [KEY_F6] = 0x75, [KEY_F7] = 0x76, [KEY_F8] = 0x77,
	[KEY_F9] = 0x78, [KEY_F10] = 0x79, [KEY_F11] = 0x7A, [KEY_F12] = 0x7B,
	[MOUSE_LEFT] = 0x01, [MOUSE_RIGHT] = 0x02, [MOUSE_MIDDLE] = 0x04,
	[MOUSE_4] = 0x05, [MOUSE_5] = 0x06,
	-- Numpad
	[KEY_PAD_0] = 0x60, [KEY_PAD_1] = 0x61, [KEY_PAD_2] = 0x62, [KEY_PAD_3] = 0x63,
	[KEY_PAD_4] = 0x64, [KEY_PAD_5] = 0x65, [KEY_PAD_6] = 0x66, [KEY_PAD_7] = 0x67,
	[KEY_PAD_8] = 0x68, [KEY_PAD_9] = 0x69,
	[KEY_PAD_DIVIDE] = 0x6F, [KEY_PAD_MULTIPLY] = 0x6A,
	[KEY_PAD_MINUS] = 0x6D, [KEY_PAD_PLUS] = 0x6B,
	[KEY_PAD_ENTER] = 0x0D, [KEY_PAD_DECIMAL] = 0x6E,
	[KEY_NUMLOCK] = 0x90,
	-- OEM/Symbol keys (US keyboard layout)
	[KEY_SEMICOLON]  = 0xBA,  -- VK_OEM_1      ;:
	[KEY_APOSTROPHE] = 0xDE,  -- VK_OEM_7      '"
	[KEY_BACKQUOTE]  = 0xC0,  -- VK_OEM_3      `~
	[KEY_MINUS]      = 0xBD,  -- VK_OEM_MINUS  -_
	[KEY_EQUAL]      = 0xBB,  -- VK_OEM_PLUS   =+
	[KEY_LBRACKET]   = 0xDB,  -- VK_OEM_4      [{
	[KEY_RBRACKET]   = 0xDD,  -- VK_OEM_6      ]}
	[KEY_BACKSLASH]  = 0xDC,  -- VK_OEM_5      \|
	[KEY_SLASH]      = 0xBF,  -- VK_OEM_2      /?
	[KEY_COMMA]      = 0xBC,  -- VK_OEM_COMMA  ,<
	[KEY_PERIOD]     = 0xBE,  -- VK_OEM_PERIOD .>
}

-- Track which VK codes are currently injected (for cleanup on VR exit)
local injectedVKs = {}

-- ============================================================================
-- C++ injection helper
-- ============================================================================

local cppAvailable = false

-- Capture mode: next VRMod_Input press calls this callback (for UI key assignment)
local captureCallback = nil

-- Raw capture mode: polls LKB.rawValues for raw button press (for advanced input assignment)
local rawCaptureCallback = nil
local rawCapturePrev = {}

local function CppInject(key, pressed)
	if not cppAvailable then return end
	local vk = KEY_TO_VK[key]
	if not vk then return end
	if pressed then
		injectedVKs[vk] = true
	else
		injectedVKs[vk] = nil
	end
	pcall(VRMOD_SendKeyEvent, vk, pressed)
end

local function CppReleaseAll()
	if not cppAvailable then return end
	for vk in pairs(injectedVKs) do
		pcall(VRMOD_SendKeyEvent, vk, false)
	end
	injectedVKs = {}
end

-- ============================================================================
-- Selectable key list (for UI dropdown)
-- All BUTTON_CODE values that the dual-layer system can inject
-- ============================================================================

local ASSIGNABLE_KEYS = {
	-- Format: { buttonCode, displayName }
	-- Sorted by category for UI readability
	{ 0,          "(none)" },
	-- Letters
	{ KEY_A, "A" }, { KEY_B, "B" }, { KEY_C, "C" }, { KEY_D, "D" },
	{ KEY_E, "E" }, { KEY_F, "F" }, { KEY_G, "G" }, { KEY_H, "H" },
	{ KEY_I, "I" }, { KEY_J, "J" }, { KEY_K, "K" }, { KEY_L, "L" },
	{ KEY_M, "M" }, { KEY_N, "N" }, { KEY_O, "O" }, { KEY_P, "P" },
	{ KEY_Q, "Q" }, { KEY_R, "R" }, { KEY_S, "S" }, { KEY_T, "T" },
	{ KEY_U, "U" }, { KEY_V, "V" }, { KEY_W, "W" }, { KEY_X, "X" },
	{ KEY_Y, "Y" }, { KEY_Z, "Z" },
	-- Numbers
	{ KEY_0, "0" }, { KEY_1, "1" }, { KEY_2, "2" }, { KEY_3, "3" },
	{ KEY_4, "4" }, { KEY_5, "5" }, { KEY_6, "6" }, { KEY_7, "7" },
	{ KEY_8, "8" }, { KEY_9, "9" },
	-- Modifiers
	{ KEY_LSHIFT, "Left Shift" }, { KEY_RSHIFT, "Right Shift" },
	{ KEY_LCONTROL, "Left Ctrl" }, { KEY_RCONTROL, "Right Ctrl" },
	{ KEY_LALT, "Left Alt" }, { KEY_RALT, "Right Alt" },
	-- Common
	{ KEY_SPACE, "Space" }, { KEY_ENTER, "Enter" }, { KEY_TAB, "Tab" },
	{ KEY_ESCAPE, "Escape" }, { KEY_BACKSPACE, "Backspace" },
	-- Arrows
	{ KEY_UP, "Up Arrow" }, { KEY_DOWN, "Down Arrow" },
	{ KEY_LEFT, "Left Arrow" }, { KEY_RIGHT, "Right Arrow" },
	-- Navigation
	{ KEY_INSERT, "Insert" }, { KEY_DELETE, "Delete" },
	{ KEY_HOME, "Home" }, { KEY_END, "End" },
	{ KEY_PAGEUP, "Page Up" }, { KEY_PAGEDOWN, "Page Down" },
	-- Function keys
	{ KEY_F1, "F1" }, { KEY_F2, "F2" }, { KEY_F3, "F3" }, { KEY_F4, "F4" },
	{ KEY_F5, "F5" }, { KEY_F6, "F6" }, { KEY_F7, "F7" }, { KEY_F8, "F8" },
	{ KEY_F9, "F9" }, { KEY_F10, "F10" }, { KEY_F11, "F11" }, { KEY_F12, "F12" },
	-- Mouse
	{ MOUSE_LEFT, "Mouse Left" }, { MOUSE_RIGHT, "Mouse Right" }, { MOUSE_MIDDLE, "Mouse Middle" },
	{ MOUSE_4, "Mouse 4" }, { MOUSE_5, "Mouse 5" },
	{ MOUSE_WHEEL_UP, "Wheel Up" }, { MOUSE_WHEEL_DOWN, "Wheel Down" },
	-- Numpad
	{ KEY_PAD_0, "Num 0" }, { KEY_PAD_1, "Num 1" }, { KEY_PAD_2, "Num 2" },
	{ KEY_PAD_3, "Num 3" }, { KEY_PAD_4, "Num 4" }, { KEY_PAD_5, "Num 5" },
	{ KEY_PAD_6, "Num 6" }, { KEY_PAD_7, "Num 7" }, { KEY_PAD_8, "Num 8" },
	{ KEY_PAD_9, "Num 9" },
	{ KEY_NUMLOCK, "NumLock" },
	{ KEY_PAD_DIVIDE, "Num /" }, { KEY_PAD_MULTIPLY, "Num *" },
	{ KEY_PAD_MINUS, "Num -" }, { KEY_PAD_PLUS, "Num +" },
	{ KEY_PAD_ENTER, "Num Enter" }, { KEY_PAD_DECIMAL, "Num ." },
}

-- Build reverse lookup: BUTTON_CODE → display name (for UI)
local KEY_DISPLAY_NAMES = {}
for _, entry in ipairs(ASSIGNABLE_KEYS) do
	KEY_DISPLAY_NAMES[entry[1]] = entry[2]
end

-- ============================================================================
-- VR Action → BUTTON_CODE mapping (configurable, saved to JSON)
-- ============================================================================

local actionMap = {}
local customKeyMap = {} -- user overrides: action → BUTTON_CODE (0 = disabled)

-- All configurable actions with display names and default bind lookups
-- Order here determines UI display order
local ACTION_DEFS = {
	{ action = "boolean_primaryfire",       label = "Primary Fire (R)",         bind = "+attack",       fallback = MOUSE_LEFT },
	{ action = "boolean_secondaryfire",     label = "Secondary Fire (R)",       bind = "+attack2",      fallback = MOUSE_RIGHT },
	{ action = "boolean_left_primaryfire",  label = "Primary Fire (L)",         bind = "+attack",       fallback = MOUSE_LEFT,  mirror = "boolean_primaryfire" },
	{ action = "boolean_left_secondaryfire",label = "Secondary Fire (L)",       bind = "+attack2",      fallback = MOUSE_RIGHT, mirror = "boolean_secondaryfire" },
	{ action = "boolean_reload",            label = "Reload",                   bind = "+reload",       fallback = KEY_R },
	{ action = "boolean_use",              label = "Use / Interact",           bind = "+use",          fallback = KEY_E },
	{ action = "boolean_flashlight",        label = "Flashlight",               bind = "impulse 100",   fallback = KEY_F },
	{ action = "boolean_sprint",            label = "Sprint",                   bind = "+speed",        fallback = KEY_LSHIFT },
	{ action = "boolean_jump",              label = "Jump",                     bind = "+jump",         fallback = KEY_SPACE },
	{ action = "boolean_crouch",            label = "Crouch",                   bind = "+duck",         fallback = KEY_LCONTROL },
	{ action = "boolean_walkkey",           label = "Walk",                     bind = "+walk",         fallback = KEY_LALT },
	{ action = "boolean_forword",           label = "Forward",                  bind = "+forward",      fallback = KEY_W },
	{ action = "boolean_back",              label = "Back",                     bind = "+back",         fallback = KEY_S },
	{ action = "boolean_left",              label = "Move Left",                bind = "+moveleft",     fallback = KEY_A },
	{ action = "boolean_right",             label = "Move Right",               bind = "+moveright",    fallback = KEY_D },
	{ action = "boolean_undo",              label = "Undo",                     bind = "gmod_undo",     fallback = KEY_Z },
	{ action = "boolean_chat",              label = "Chat / Zoom",              bind = "+zoom",         fallback = nil },
	{ action = "boolean_menucontext",       label = "Context Menu",             bind = "+menu_context",  fallback = KEY_C },
	{ action = "boolean_spawnmenu",         label = "Spawn Menu",               bind = "+menu",         fallback = KEY_Q },
	{ action = "boolean_slot1",             label = "Weapon Slot 1",            bind = nil,             fallback = KEY_1 },
	{ action = "boolean_slot2",             label = "Weapon Slot 2",            bind = nil,             fallback = KEY_2 },
	{ action = "boolean_slot3",             label = "Weapon Slot 3",            bind = nil,             fallback = KEY_3 },
	{ action = "boolean_slot4",             label = "Weapon Slot 4",            bind = nil,             fallback = KEY_4 },
	{ action = "boolean_slot5",             label = "Weapon Slot 5",            bind = nil,             fallback = KEY_5 },
	{ action = "boolean_slot6",             label = "Weapon Slot 6",            bind = nil,             fallback = KEY_6 },
}

local SAVE_FILE = "vrmod/vrmod_input_emu_keymap.txt"

-- Resolve which BUTTON_CODE is bound to a console command
local function FindKeyForBind(bind)
	if not bind then return nil end
	local limit = BUTTON_CODE_LAST or 171
	for code = 1, limit do
		if input.LookupKeyBinding(code) == bind then
			return code
		end
	end
	return nil
end

-- Get the default key for an action (auto-detect from binds, then fallback)
local function GetDefaultKey(def)
	if def.mirror then
		-- Mirror actions inherit from their source
		return actionMap[def.mirror]
	end
	return FindKeyForBind(def.bind) or def.fallback
end

-- ============================================================================
-- Save / Load custom key mapping (JSON)
-- ============================================================================

local function SaveCustomKeyMap()
	-- Only save non-default entries to keep file small
	local saveData = { version = 1, keys = {} }
	for action, code in pairs(customKeyMap) do
		-- Store action name → button code number
		saveData.keys[action] = code
	end
	if not file.Exists("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end
	file.Write(SAVE_FILE, util.TableToJSON(saveData, true))
end

local function LoadCustomKeyMap()
	local json = file.Read(SAVE_FILE, "DATA")
	if not json then return false end

	local ok, data = pcall(util.JSONToTable, json)
	if not ok or not data then
		print(TAG .. "WARNING: Saved key mapping is corrupted, using defaults")
		return false
	end

	if not data.keys then
		print(TAG .. "WARNING: Saved key mapping has no 'keys' field, using defaults")
		return false
	end

	-- Validate each entry: action must be a known string, code must be a number
	customKeyMap = {}
	for action, code in pairs(data.keys) do
		if type(action) == "string" and type(code) == "number" then
			customKeyMap[action] = code
		end
	end

	return true
end

local function ResetCustomKeyMap()
	customKeyMap = {}
	SaveCustomKeyMap()
end

-- ============================================================================
-- Build mapping table
-- Uses ONLY customKeyMap entries. No auto-detection by default.
-- Call vrmod.InputEmu_AutoAssign() to populate from current keybinds.
-- ============================================================================

local function BuildMapping()
	actionMap = {}

	-- Only apply custom overrides (0 = explicitly disabled → skip)
	for action, code in pairs(customKeyMap) do
		if code ~= 0 then
			actionMap[action] = code
		end
	end
end

-- Auto-detect keys from current keybinds and save as custom overrides
local function AutoAssignFromBinds()
	local detected = {}

	-- Pass 1: Non-mirror actions — detect from engine keybinds or use fallback
	for _, def in ipairs(ACTION_DEFS) do
		if not def.mirror then
			local key = FindKeyForBind(def.bind) or def.fallback
			if key then
				detected[def.action] = key
			end
		end
	end

	-- Pass 2: Mirror actions — inherit from their source
	for _, def in ipairs(ACTION_DEFS) do
		if def.mirror and detected[def.mirror] then
			detected[def.action] = detected[def.mirror]
		end
	end

	-- Apply detected bindings into customKeyMap
	for action, key in pairs(detected) do
		customKeyMap[action] = key
	end

	BuildMapping()
	SaveCustomKeyMap()

	return table.Count(detected)
end

-- Load saved config at startup
LoadCustomKeyMap()

-- ============================================================================
-- VRMod hooks
-- ============================================================================

local vrActive = false

local function ClearVRKeys()
	for k in pairs(vrKeys) do
		vrKeys[k] = nil
	end
end

hook.Add("VRMod_Start", "vrmod_unoff_input_emu", function()
	if not cv_enabled:GetBool() then return end
	vrActive = true
	BuildMapping()
	-- Check C++ injection availability
	cppAvailable = cv_cpp_inject:GetBool() and (VRMOD_SendKeyEvent ~= nil)
	local displayModVer = (g_VR.moduleSemiVersion and g_VR.moduleSemiVersion > 0) and g_VR.moduleSemiVersion or g_VR.moduleVersion
	local cppStatus = cppAvailable and "ON (module v" .. tostring(displayModVer or "?") .. ")" or "OFF"
	local customCount = table.Count(customKeyMap)
	print(TAG .. "Activated. Mapped", table.Count(actionMap), "actions. Custom:", customCount, ". C++ inject:", cppStatus)
end)

-- Fallback: VR already active when this file loads (e.g. lua_openscript_cl reload)
timer.Simple(0, function()
	if cv_enabled:GetBool() and g_VR and g_VR.active and not vrActive then
		vrActive = true
		BuildMapping()
		cppAvailable = cv_cpp_inject:GetBool() and (VRMOD_SendKeyEvent ~= nil)
		print(TAG .. "Late init: VR already active. Mapped", table.Count(actionMap), "actions")
	end
end)

hook.Add("VRMod_Input", "vrmod_unoff_input_emu", function(action, pressed)
	-- Capture mode: intercept press events for UI key assignment
	if captureCallback and pressed then
		if string.StartWith(action, "boolean_") then
			local cb = captureCallback
			captureCallback = nil
			cb(action)
			return -- Don't process as key injection during capture
		end
	end

	if not vrActive then return end
	local key = actionMap[action]
	if not key then return end
	-- Layer 1: Lua detour
	vrKeys[key] = pressed or nil
	-- Layer 2: C++ engine injection
	CppInject(key, pressed)
end)

hook.Add("VRMod_Exit", "vrmod_unoff_input_emu", function()
	vrActive = false
	captureCallback = nil -- Cancel any pending capture
	rawCaptureCallback = nil -- Cancel any pending raw capture
	rawCapturePrev = {}
	hook.Remove("Think", "vrmod_unoff_raw_capture")
	CppReleaseAll()
	ClearVRKeys()
end)

cvars.AddChangeCallback("vrmod_unoff_input_emu", function(_, _, new)
	if new == "0" then
		vrActive = false
		CppReleaseAll()
		ClearVRKeys()
	end
end, "vrmod_unoff_input_emu")

cvars.AddChangeCallback("vrmod_unoff_cpp_keyinject", function(_, _, new)
	if new == "0" then
		CppReleaseAll()
		cppAvailable = false
	else
		cppAvailable = (VRMOD_SendKeyEvent ~= nil)
	end
end, "vrmod_unoff_cpp_keyinject")

-- ============================================================================
-- 公開API
-- ============================================================================

vrmod = vrmod or {}

--- キー状態を直接注入する。input.IsKeyDown等のデトアに反映される。
--- @param buttonCode number BUTTON_CODE (KEY_*, MOUSE_*)
--- @param state boolean|nil trueで押下、nil/falseで解放
function vrmod.InputEmu_SetKey(buttonCode, state)
	vrKeys[buttonCode] = state or nil
end

--- 指定キーを1フレームだけ押して自動で離す。
--- Think hookでポーリングしているアドオン（ZoneNPC等）に対して有効。
--- @param buttonCode number BUTTON_CODE
function vrmod.InputEmu_TapKey(buttonCode)
	vrKeys[buttonCode] = true
	CppInject(buttonCode, true)
	timer.Simple(0.1, function()
		vrKeys[buttonCode] = nil
		CppInject(buttonCode, false)
	end)
end

--- 指定キーを両レイヤーで注入する。
--- @param buttonCode number BUTTON_CODE (KEY_*, MOUSE_*)
--- @param state boolean|nil trueで押下、nil/falseで解放
function vrmod.InputEmu_SetKeyDual(buttonCode, state)
	vrKeys[buttonCode] = state or nil
	CppInject(buttonCode, state)
end

--- カスタムマッピングを1件設定する（即時反映、自動保存なし）
--- @param action string VRMod action name (e.g. "boolean_primaryfire")
--- @param buttonCode number BUTTON_CODE (0で無効化)
function vrmod.InputEmu_SetMapping(action, buttonCode)
	if type(action) ~= "string" then return end
	if type(buttonCode) ~= "number" then return end
	customKeyMap[action] = buttonCode
	BuildMapping()
end

--- 現在のactionMapのコピーを返す
function vrmod.InputEmu_GetMapping()
	return table.Copy(actionMap)
end

--- カスタムマッピングのコピーを返す
function vrmod.InputEmu_GetCustomKeyMap()
	return table.Copy(customKeyMap)
end

--- カスタムマッピングをディスクに保存する
function vrmod.InputEmu_SaveMapping()
	SaveCustomKeyMap()
	print(TAG .. "Custom key mapping saved")
end

--- カスタムマッピングをデフォルトにリセットする（保存込み）
function vrmod.InputEmu_ResetMapping()
	ResetCustomKeyMap()
	BuildMapping()
	print(TAG .. "Key mapping reset to defaults")
end

--- マッピングを再ビルドする（キーバインド変更後等に呼ぶ）
function vrmod.InputEmu_RebuildMapping()
	BuildMapping()
end

--- 現在のキーバインドから自動検出してマッピングを構築する（保存込み）
--- @return number 検出されたアクション数
function vrmod.InputEmu_AutoAssign()
	local count = AutoAssignFromBinds()
	print(TAG .. "Auto-assigned", count, "actions from current keybinds")
	return count
end

--- アクション定義一覧を返す（UI構築用）
function vrmod.InputEmu_GetActionDefs()
	return ACTION_DEFS
end

--- 割当可能なキー一覧を返す（UI構築用）
function vrmod.InputEmu_GetAssignableKeys()
	return ASSIGNABLE_KEYS
end

--- キーの表示名を返す
function vrmod.InputEmu_GetKeyDisplayName(buttonCode)
	return KEY_DISPLAY_NAMES[buttonCode] or input.GetKeyName(buttonCode) or "?"
end

--- KEY_TO_VKテーブルを返す（VRキーボードからのC++注入用）
function vrmod.InputEmu_GetKeyToVK()
	return KEY_TO_VK
end

--- C++注入が利用可能かどうか
function vrmod.InputEmu_IsCppAvailable()
	return cppAvailable
end

-- ============================================================================
-- Capture / Assignment API (for Visual Keyboard UI)
-- ============================================================================

--- キー→アクション逆引きマップを返す
--- @return table {[buttonCode] = {action1, action2, ...}, ...}
function vrmod.InputEmu_GetReverseMap()
	local reverse = {}
	for action, key in pairs(actionMap) do
		if not reverse[key] then reverse[key] = {} end
		table.insert(reverse[key], action)
	end
	return reverse
end

--- 次のVRMod_Input押下イベントをキャプチャする（UI用）
--- boolean_* アクションのみキャプチャ対象。キャプチャ中はそのアクションのキー注入をスキップ。
--- @param callback function callback(action) — VRアクション名を渡す
--- @return boolean キャプチャ開始成功
function vrmod.InputEmu_StartCapture(callback)
	if type(callback) ~= "function" then return false end
	captureCallback = callback
	return true
end

--- キャプチャモードを中止する
function vrmod.InputEmu_CancelCapture()
	captureCallback = nil
end

--- キャプチャ中かどうか
function vrmod.InputEmu_IsCapturing()
	return captureCallback ~= nil
end

--- rawボタンキャプチャ開始（LKB.rawValuesをポーリングしてbooleanのrising edgeを検出）
--- @param callback function callback(rawName) — rawアクション名を渡す
--- @param skipMenuUID string|nil メニューUID（カーソルがこの上ならprimaryfire対応rawをスキップ）
--- @return boolean キャプチャ開始成功
function vrmod.InputEmu_StartRawCapture(callback, skipMenuUID)
	if type(callback) ~= "function" then return false end

	rawCaptureCallback = callback

	-- Seed prev values from current raw state
	rawCapturePrev = {}
	local LKB = g_VR and g_VR.luaKeybinding
	local rawValues = LKB and LKB.rawValues
	if rawValues then
		for _, rawName in ipairs(g_VR.rawActionNames or {}) do
			rawCapturePrev[rawName] = rawValues[rawName]
		end
	end

	hook.Add("Think", "vrmod_unoff_raw_capture", function()
		if not rawCaptureCallback then
			hook.Remove("Think", "vrmod_unoff_raw_capture")
			return
		end

		if not g_VR or not g_VR.active then return end

		local lkb = g_VR.luaKeybinding
		local rv = lkb and lkb.rawValues
		if not rv then return end

		-- Build skip list: when cursor is on keyboard panel, skip primaryfire trigger
		local skipRaws = {}
		if skipMenuUID and g_VR.menuFocus == skipMenuUID then
			local mapping = lkb and lkb.mapping
			if mapping then
				for raw, logical in pairs(mapping) do
					if logical == "boolean_primaryfire" then
						skipRaws[raw] = true
						local pullName = string.gsub(raw, "_bool$", "_pull")
						if pullName ~= raw then skipRaws[pullName] = true end
						break
					end
				end
			end
		end

		for _, rawName in ipairs(g_VR.rawActionNames or {}) do
			local rawType = g_VR.rawActionTypes and g_VR.rawActionTypes[rawName]
			if rawType ~= "boolean" then continue end
			if skipRaws[rawName] then
				rawCapturePrev[rawName] = rv[rawName]
				continue
			end

			local val = rv[rawName]
			local prev = rawCapturePrev[rawName]

			if val == true and prev ~= true then
				-- Rising edge detected
				local cb = rawCaptureCallback
				rawCaptureCallback = nil
				rawCapturePrev = {}
				hook.Remove("Think", "vrmod_unoff_raw_capture")
				cb(rawName)
				return
			end

			rawCapturePrev[rawName] = val
		end
	end)

	return true
end

--- rawキャプチャ中止
function vrmod.InputEmu_CancelRawCapture()
	rawCaptureCallback = nil
	rawCapturePrev = {}
	hook.Remove("Think", "vrmod_unoff_raw_capture")
end

--- rawキャプチャ中かどうか
function vrmod.InputEmu_IsRawCapturing()
	return rawCaptureCallback ~= nil
end

--- キーをアクションに割当 + 保存 + リビルド（一括）
--- @param action string VRMod action name (e.g. "boolean_primaryfire")
--- @param buttonCode number BUTTON_CODE (KEY_*, MOUSE_*)
--- @return boolean 成功
function vrmod.InputEmu_AssignKeyToAction(action, buttonCode)
	if type(action) ~= "string" or type(buttonCode) ~= "number" then return false end
	customKeyMap[action] = buttonCode
	BuildMapping()
	SaveCustomKeyMap()
	return true
end

--- アクションのマッピングを削除（明示的に無効化） + 保存
--- @param action string VRMod action name
--- @return boolean 成功
function vrmod.InputEmu_RemoveAction(action)
	if type(action) ~= "string" then return false end
	customKeyMap[action] = 0 -- 0 = explicitly disabled
	BuildMapping()
	SaveCustomKeyMap()
	return true
end

--- 全カスタムマッピングを明示的に無効化 + 保存
function vrmod.InputEmu_ClearAll()
	for _, def in ipairs(ACTION_DEFS) do
		customKeyMap[def.action] = 0
	end
	BuildMapping()
	SaveCustomKeyMap()
end

-- ============================================================================
-- Debug command
-- ============================================================================

concommand.Add("vrmod_unoff_input_emu_status", function()
	print(TAG .. "Enabled:", cv_enabled:GetBool())
	print(TAG .. "VR Active:", vrActive)
	print(TAG .. "C++ inject available:", cppAvailable)
	print(TAG .. "C++ inject ConVar:", cv_cpp_inject:GetBool())
	print(TAG .. "Custom overrides:", table.Count(customKeyMap))
	local count = 0
	for k, v in pairs(vrKeys) do
		if v then
			count = count + 1
			local name = input.GetKeyName(k)
			print("  Lua vrKeys:", k, "=", name or "unknown")
		end
	end
	print(TAG .. "Lua keys down:", count)
	local cppCount = 0
	for vk in pairs(injectedVKs) do
		cppCount = cppCount + 1
		print("  C++ injected VK: 0x" .. string.format("%02X", vk))
	end
	print(TAG .. "C++ keys down:", cppCount)
	print(TAG .. "Mapped actions:", table.Count(actionMap))
	for action, key in pairs(actionMap) do
		local isCustom = customKeyMap[action] ~= nil
		local keyName = KEY_DISPLAY_NAMES[key] or input.GetKeyName(key) or "?"
		print("  " .. action .. " → " .. keyName .. " (" .. key .. ")" .. (isCustom and " [CUSTOM]" or ""))
	end
end)

-- ============================================================================
-- Shared Unified Keyboard Layout
-- ============================================================================
-- Used by both the VR keyboard (vrmod_add_keyboard.lua) and the desktop
-- key assignment editor (vrmod_input_emu_keyboard_ui.lua).
--
-- Each key: {code, label, widthMult, shiftLabel}
--   code       : BUTTON_CODE constant (KEY_*, MOUSE_*)
--                -1 = invisible gap spacer
--                -2 = numpad anchor (jump x to fixed numpad column)
--   label      : Display text for Page 1 / normal mode
--   widthMult  : Key width as multiple of base key width (1.0 = standard)
--   shiftLabel : Display text for Page 2 / shift mode (nil = no change)
--
-- Consumers provide their own sizing constants (KW, KH, KG, RG, PAD).

vrmod.UNIFIED_KEYBOARD_LAYOUT = {
	-- Row 0: Mouse buttons + scroll
	{
		{MOUSE_LEFT, "Mouse(L)", 1.8}, {MOUSE_MIDDLE, "Mouse(M)", 1.8}, {MOUSE_RIGHT, "Mouse(R)", 1.8},
		{-1, "", 0.3},
		{MOUSE_4, "Mouse4", 1.5}, {MOUSE_5, "Mouse5", 1.5},
		{-1, "", 0.3},
		{MOUSE_WHEEL_UP, "WheelUp", 1.8}, {MOUSE_WHEEL_DOWN, "WheelDn", 1.8},
	},
	-- Row 1: Escape + Function keys + Numpad top
	{
		{KEY_ESCAPE, "Esc", 1.0},
		{-1, "", 0.5},
		{KEY_F1, "F1", 1.0}, {KEY_F2, "F2", 1.0}, {KEY_F3, "F3", 1.0}, {KEY_F4, "F4", 1.0},
		{-1, "", 0.3},
		{KEY_F5, "F5", 1.0}, {KEY_F6, "F6", 1.0}, {KEY_F7, "F7", 1.0}, {KEY_F8, "F8", 1.0},
		{-1, "", 0.3},
		{KEY_F9, "F9", 1.0}, {KEY_F10, "F10", 1.0}, {KEY_F11, "F11", 1.0}, {KEY_F12, "F12", 1.0},
		{-1, "", 0.5},
		{KEY_NUMLOCK, "Num", 1.0}, {KEY_PAD_DIVIDE, "/", 1.0}, {KEY_PAD_MULTIPLY, "*", 1.0}, {KEY_PAD_MINUS, "-", 1.0},
	},
	-- Row 2: Backtick + Numbers + Minus + Equal + Backspace + Numpad 7-9, +
	{
		{KEY_BACKQUOTE, "`", 1.0, "~"},
		{KEY_1, "1", 1.0, "!"}, {KEY_2, "2", 1.0, "@"}, {KEY_3, "3", 1.0, "#"},
		{KEY_4, "4", 1.0, "$"}, {KEY_5, "5", 1.0, "%"}, {KEY_6, "6", 1.0, "^"},
		{KEY_7, "7", 1.0, "&"}, {KEY_8, "8", 1.0, "*"}, {KEY_9, "9", 1.0, "("},
		{KEY_0, "0", 1.0, ")"},
		{KEY_MINUS, "-", 1.0, "_"}, {KEY_EQUAL, "=", 1.0, "+"},
		{-1, "", 0.2},
		{KEY_BACKSPACE, "Back", 1.5},
		{-2, "", 0},
		{KEY_PAD_7, "N7", 1.0}, {KEY_PAD_8, "N8", 1.0}, {KEY_PAD_9, "N9", 1.0}, {KEY_PAD_PLUS, "+", 1.0},
	},
	-- Row 3: Tab + QWERTY + Brackets + Backslash + Numpad 4-6
	{
		{KEY_TAB, "Tab", 1.5},
		{KEY_Q, "Q", 1.0}, {KEY_W, "W", 1.0}, {KEY_E, "E", 1.0}, {KEY_R, "R", 1.0},
		{KEY_T, "T", 1.0}, {KEY_Y, "Y", 1.0}, {KEY_U, "U", 1.0}, {KEY_I, "I", 1.0},
		{KEY_O, "O", 1.0}, {KEY_P, "P", 1.0},
		{KEY_LBRACKET, "[", 1.0, "{"}, {KEY_RBRACKET, "]", 1.0, "}"}, {KEY_BACKSLASH, "\\", 1.0, "|"},
		{-2, "", 0},
		{KEY_PAD_4, "N4", 1.0}, {KEY_PAD_5, "N5", 1.0}, {KEY_PAD_6, "N6", 1.0},
	},
	-- Row 4: Home row (ASDF) + Semicolon + Apostrophe + Enter + Numpad 1-3, NE
	{
		{KEY_A, "A", 1.0}, {KEY_S, "S", 1.0}, {KEY_D, "D", 1.0}, {KEY_F, "F", 1.0},
		{KEY_G, "G", 1.0}, {KEY_H, "H", 1.0}, {KEY_J, "J", 1.0}, {KEY_K, "K", 1.0},
		{KEY_L, "L", 1.0},
		{KEY_SEMICOLON, ";", 1.0, ":"}, {KEY_APOSTROPHE, "'", 1.0, "\""},
		{-1, "", 0.2},
		{KEY_ENTER, "Enter", 2.0},
		{-2, "", 0},
		{KEY_PAD_1, "N1", 1.0}, {KEY_PAD_2, "N2", 1.0}, {KEY_PAD_3, "N3", 1.0}, {KEY_PAD_ENTER, "NEnter", 1.0},
	},
	-- Row 5: Shift + ZXCV + Comma + Period + Slash + Shift + Numpad 0, .
	{
		{KEY_LSHIFT, "LShift", 1.8},
		{KEY_Z, "Z", 1.0}, {KEY_X, "X", 1.0}, {KEY_C, "C", 1.0}, {KEY_V, "V", 1.0},
		{KEY_B, "B", 1.0}, {KEY_N, "N", 1.0}, {KEY_M, "M", 1.0},
		{KEY_COMMA, ",", 1.0, "<"}, {KEY_PERIOD, ".", 1.0, ">"}, {KEY_SLASH, "/", 1.0, "?"},
		{-1, "", 0.2},
		{KEY_RSHIFT, "RShift", 1.8},
		{-2, "", 0},
		{KEY_PAD_0, "N0", 2.07}, {KEY_PAD_DECIMAL, "N.", 1.0},
	},
	-- Row 6: Modifiers + Space
	{
		{KEY_LCONTROL, "LCtrl", 1.5},
		{KEY_LALT, "LAlt", 1.3},
		{KEY_SPACE, "Space", 5.5},
		{KEY_RALT, "RAlt", 1.3},
		{KEY_RCONTROL, "RCtrl", 1.5},
	},
	-- Row 7: Navigation + Arrow keys
	{
		{KEY_INSERT, "Ins", 1.0}, {KEY_DELETE, "Del", 1.0},
		{KEY_HOME, "Home", 1.2}, {KEY_END, "End", 1.0},
		{KEY_PAGEUP, "PgUp", 1.2}, {KEY_PAGEDOWN, "PgDn", 1.2},
		{-1, "", 0.7},
		{KEY_LEFT, "\xE2\x86\x90", 1.0}, {KEY_UP, "\xE2\x86\x91", 1.0},
		{KEY_DOWN, "\xE2\x86\x93", 1.0}, {KEY_RIGHT, "\xE2\x86\x92", 1.0},
	},
}

--- Calculate layout dimensions for given sizing constants.
--- @param kw number base key width
--- @param kh number key height
--- @param kg number gap between keys
--- @param rg number gap between rows
--- @param pad number panel edge padding
--- @return number panelW, number panelH, number numpadX
function vrmod.CalcKeyboardDimensions(kw, kh, kg, rg, pad)
	local layout = vrmod.UNIFIED_KEYBOARD_LAYOUT
	-- Find numpad X from Row 1 (F-key row, the reference alignment row)
	local numpadX = pad
	for _, kd in ipairs(layout[2]) do
		if kd[1] == KEY_NUMLOCK then break end
		numpadX = numpadX + math.floor(kd[3] * kw) + kg
	end
	-- Panel width from Row 1 (widest row due to F-keys + numpad)
	local maxW = 0
	for _, row in ipairs(layout) do
		local rowW = 0
		for _, k in ipairs(row) do
			if k[1] == -2 then
				rowW = numpadX - pad
			else
				rowW = rowW + math.floor(k[3] * kw) + kg
			end
		end
		maxW = math.max(maxW, rowW)
	end
	local panelW = maxW + pad * 2
	local panelH = #layout * (kh + rg) + pad * 2
	return panelW, panelH, numpadX
end
