-- VR Controller → input.IsKeyDown() Emulation Layer
--
-- Problem: VR controller inputs go through SteamVR → VRMod C++ → Lua hooks,
-- bypassing the engine's CInputSystem. Third-party addons that use
-- input.IsKeyDown(KEY_*) only check engine keyboard state, so VR controllers
-- cannot trigger those checks.
--
-- Solution: Override input.IsKeyDown/IsButtonDown/IsMouseDown at the Lua level
-- to additionally check a VR input state table. When VR controller buttons
-- are pressed, the corresponding KEY/MOUSE codes are set in this table.
--
-- The override is installed at load time (! prefix = first in autorun/client)
-- but has zero cost when VR is not active (empty table → fallthrough).
--
-- Limitations:
-- - Only affects Lua-level callers. Engine C++ internal checks are not affected.
-- - Addons that cached function references before this file loaded are not affected.
--   (No such caching was found in GMod base code or common addons.)

if SERVER then return end

local cv_enabled = CreateClientConVar("vrmod_unoff_input_emu", "0", true, false,
	"Enable VR controller input emulation for input.IsKeyDown() etc.")

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
-- VR Action → BUTTON_CODE mapping
-- ============================================================================

local actionMap = {}

-- Resolve which BUTTON_CODE is bound to a console command
local function FindKeyForBind(bind)
	local limit = BUTTON_CODE_LAST or 171
	for code = 1, limit do
		if input.LookupKeyBinding(code) == bind then
			return code
		end
	end
	return nil
end

-- Build mapping table using user's actual key bindings (with fallbacks)
local function BuildMapping()
	actionMap = {
		boolean_primaryfire       = FindKeyForBind("+attack") or MOUSE_LEFT,
		boolean_secondaryfire     = FindKeyForBind("+attack2") or MOUSE_RIGHT,
		boolean_reload            = FindKeyForBind("+reload") or KEY_R,
		boolean_use               = FindKeyForBind("+use") or KEY_E,
		boolean_flashlight        = FindKeyForBind("impulse 100") or KEY_F,
		boolean_sprint            = FindKeyForBind("+speed") or KEY_LSHIFT,
		boolean_jump              = FindKeyForBind("+jump") or KEY_SPACE,
		boolean_crouch            = FindKeyForBind("+duck") or KEY_LCONTROL,
		boolean_walkkey           = FindKeyForBind("+walk") or KEY_LALT,
		boolean_forword           = FindKeyForBind("+forward") or KEY_W,
		boolean_back              = FindKeyForBind("+back") or KEY_S,
		boolean_left              = FindKeyForBind("+moveleft") or KEY_A,
		boolean_right             = FindKeyForBind("+moveright") or KEY_D,
		boolean_undo              = FindKeyForBind("gmod_undo") or KEY_Z,
		boolean_chat              = FindKeyForBind("+zoom"),
		boolean_menucontext       = FindKeyForBind("+menu_context") or KEY_C,
		boolean_spawnmenu         = FindKeyForBind("+menu") or KEY_Q,
		boolean_slot1             = KEY_1,
		boolean_slot2             = KEY_2,
		boolean_slot3             = KEY_3,
		boolean_slot4             = KEY_4,
		boolean_slot5             = KEY_5,
		boolean_slot6             = KEY_6,
	}

	-- Left hand fire mirrors right hand
	actionMap.boolean_left_primaryfire = actionMap.boolean_primaryfire
	actionMap.boolean_left_secondaryfire = actionMap.boolean_secondaryfire
end

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
	print("[VR Input Emu] Activated. Mapped", table.Count(actionMap), "actions")
end)

-- Fallback: VR already active when this file loads (e.g. lua_openscript_cl reload)
timer.Simple(0, function()
	if cv_enabled:GetBool() and g_VR and g_VR.active and not vrActive then
		vrActive = true
		BuildMapping()
		print("[VR Input Emu] Late init: VR already active. Mapped", table.Count(actionMap), "actions")
	end
end)

hook.Add("VRMod_Input", "vrmod_unoff_input_emu", function(action, pressed)
	if not vrActive then return end
	local key = actionMap[action]
	if not key then return end
	vrKeys[key] = pressed or nil
end)

hook.Add("VRMod_Exit", "vrmod_unoff_input_emu", function()
	vrActive = false
	ClearVRKeys()
end)

cvars.AddChangeCallback("vrmod_unoff_input_emu", function(_, _, new)
	if new == "0" then
		vrActive = false
		ClearVRKeys()
	end
end, "vrmod_unoff_input_emu")

-- ============================================================================
-- 公開API: 外部からキー状態を注入（vrmod_keybridgeやテスト用）
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
	timer.Simple(0, function()
		vrKeys[buttonCode] = nil
	end)
end

-- ============================================================================
-- Debug command
-- ============================================================================

concommand.Add("vrmod_unoff_input_emu_status", function()
	print("[VR Input Emu] Enabled:", cv_enabled:GetBool())
	print("[VR Input Emu] VR Active:", vrActive)
	local count = 0
	for k, v in pairs(vrKeys) do
		if v then
			count = count + 1
			local name = input.GetKeyName(k)
			print("  Button code", k, "=", name or "unknown")
		end
	end
	print("[VR Input Emu] Keys currently down:", count)
	print("[VR Input Emu] Mapped actions:", table.Count(actionMap))
end)
