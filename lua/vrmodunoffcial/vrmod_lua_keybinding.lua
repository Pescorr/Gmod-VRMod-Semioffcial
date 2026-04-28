if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

--[[
	vrmod_lua_keybinding.lua
	Root file in vrmodunoffcial/ — loads AFTER vrmod.lua

	Lua Keybinding Mode:
	  When enabled, bypasses SteamVR's binding system for button inputs.
	  SteamVR only handles raw physical button → raw action (1:1 fixed).
	  All logical mapping (raw → game action) is done here in Lua.

	  This solves:
	  - SteamVR binding UI being unreliable
	  - SteamVR binding cache not updating
	  - Users unable to customize controls easily

	Modes:
	  0 = SteamVR mode (default, traditional behavior)
	  1 = Lua keybinding mode (raw input → Lua mapping)

	Added in: semiofficial module v101 (S28)
]]

g_VR = g_VR or {}
g_VR.luaKeybinding = g_VR.luaKeybinding or {}

local LKB = g_VR.luaKeybinding

-------------------------------------------------------------------------------
-- DEBUG LOGGING (integrates with vrmod_debug_core when debug enabled)
-------------------------------------------------------------------------------

local Log -- lazy-initialized to vrmod.debug.Log when available
local function DbgInfo(fmt, ...)
	if not Log then
		if vrmod and vrmod.debug and vrmod.debug.enabled then
			Log = vrmod.debug.Log
		else
			return
		end
	end
	Log.Info(string.format(fmt, ...))
end
local function DbgDebug(fmt, ...)
	if not Log then
		if vrmod and vrmod.debug and vrmod.debug.enabled then
			Log = vrmod.debug.Log
		else
			return
		end
	end
	Log.Debug(string.format(fmt, ...))
end
local function DbgWarn(fmt, ...)
	if not Log then
		if vrmod and vrmod.debug and vrmod.debug.enabled then
			Log = vrmod.debug.Log
		else
			return
		end
	end
	Log.Warn(string.format(fmt, ...))
end

-- Throttled debug: only log raw input every N frames to avoid spam
local dbgFrameCount = 0
local DBG_RAW_INTERVAL = 60 -- log raw values every 60 frames (~1 second)

-------------------------------------------------------------------------------
-- ConVar
-------------------------------------------------------------------------------

local cv_inputmode = CreateClientConVar("vrmod_unoff_inputmode", "0", true, false,
	"Input mode: 0=SteamVR bindings, 1=Lua keybinding", 0, 1)

-- Log mode changes
cvars.AddChangeCallback("vrmod_unoff_inputmode", function(_, old, new)
	DbgInfo("[LKB] Input mode changed: %s -> %s (%s)",
		old, new, new == "1" and "LUA KEYBINDING" or "STEAMVR")
	if new == "1" then
		DbgInfo("[LKB] Raw action names registered: %d", #(g_VR.rawActionNames or {}))
		DbgInfo("[LKB] Mapping entries (on_foot): %d", table.Count(LKB.mapping or {}))
		DbgInfo("[LKB] Mapping entries (driving): %d", table.Count(LKB.drivingMapping or {}))

		-- Safety net: when switching to Lua mode with no mappings defined,
		-- warn the user and auto-open the wizard so they can actually play.
		if table.Count(LKB.mapping or {}) == 0 then
			print("[VRMod Keybinding] WARNING: Lua mode active but no mappings defined.")
			print("[VRMod Keybinding] Fallback: right trigger = primary fire (UI click).")
			if chat and chat.AddText then
				chat.AddText(Color(255, 180, 60),
					"[VRMod] Lua keybinding mode ON but no bindings set. ",
					Color(180, 230, 255),
					"Opening wizard...")
			end
			-- Defer a tick so cvar callback completes before UI opens
			timer.Simple(0.1, function()
				-- Re-check: user may have filled mappings by now via other paths
				if cv_inputmode:GetInt() == 1 and table.Count(LKB.mapping or {}) == 0 then
					RunConsoleCommand("vrmod_keybinding_wizard")
				end
			end)
		end
	end
	-- Reactivate action sets so monkey-patch injects/removes /actions/raw
	if g_VR and g_VR.active and VRMOD_SetActiveActionSets then
		VRMOD_SetActiveActionSets("/actions/base",
			LocalPlayer():InVehicle() and "/actions/driving" or "/actions/main")
	end
end, "lkb_mode_trace")

-------------------------------------------------------------------------------
-- DEFAULT MAPPING TABLE
-- Ships EMPTY to match Advanced Input / C++ InputEmu behavior.
-- Users must explicitly assign via wizard or Settings UI.
-- This avoids the confusion of "am I seeing a default or my own mapping?".
-------------------------------------------------------------------------------

local DEFAULT_MAPPING = {}
local DEFAULT_DRIVING_MAPPING = {}

-- Emergency fallback — used ONLY in-memory when the active mapping is empty.
-- Never saved to disk. Ensures the user can at least click UI / open the wizard
-- instead of ending up in a totally unresponsive state.
local FALLBACK_MAPPING = {
	raw_right_trigger_bool = "boolean_primaryfire", -- right trigger = left-click equivalent
}

-------------------------------------------------------------------------------
-- ACTIVE MAPPING (loaded from config or defaults)
-------------------------------------------------------------------------------

LKB.mapping = LKB.mapping or {}
LKB.drivingMapping = LKB.drivingMapping or {}
LKB.prevRawBooleans = LKB.prevRawBooleans or {}
-- Hysteresis state for stick 4-direction derivation
LKB.stickDirState = LKB.stickDirState or {}

-- Gesture state machine (per rawName).
--   state: ST_IDLE | ST_PRESSED | ST_HELD | ST_WAIT_DOUBLE
--   down: current down state, pressedAt: press time, lastReleaseAt: release time
LKB.rawGestureState = LKB.rawGestureState or {}
-- Active key pulses: keycode -> timer id (so we can release reliably)
LKB.activeKeyPulses = LKB.activeKeyPulses or {}
-- Held keys (long_press / passthrough to keycode): keycode -> true
LKB.activeHeldKeys = LKB.activeHeldKeys or {}
-- Combo pending state: each raw tracks whether it currently believes combo partner is down
LKB.comboActive = LKB.comboActive or {}

-- Settings (part of v2 schema, saved alongside mappings)
LKB.settings = LKB.settings or {
	builtin_movement_passthrough = true,  -- raw_*_stick -> walkdir/smoothturn when not user-overridden
	disable_steamvr_main = false,          -- drop /actions/main /actions/driving while in Lua mode
	long_press_ms   = 500,                 -- time (ms) before press becomes long_press
	double_click_ms = 300,                 -- max interval (ms) between clicks for double_click
}

-- Synthetic raw names (stick 4-direction) — derived from raw_*_stick vector2 each frame.
-- Not registered with SteamVR manifest; Lua-side only.
LKB.SYNTHETIC_STICK_DIRS = {
	"raw_left_stick_up", "raw_left_stick_down", "raw_left_stick_left", "raw_left_stick_right",
	"raw_right_stick_up", "raw_right_stick_down", "raw_right_stick_left", "raw_right_stick_right",
}

-- Register synthetic raw names into g_VR.rawActionTypes / rawActionNames if available.
-- Called lazily because raw_input.lua may load after us.
local function RegisterSyntheticStickDirs()
	if LKB._syntheticRegistered then return end
	if not g_VR.rawActionTypes or not g_VR.rawActionNames then return end
	for _, n in ipairs(LKB.SYNTHETIC_STICK_DIRS) do
		g_VR.rawActionTypes[n] = "boolean"
		local already = false
		for _, existing in ipairs(g_VR.rawActionNames) do
			if existing == n then already = true break end
		end
		if not already then table.insert(g_VR.rawActionNames, n) end
	end
	LKB._syntheticRegistered = true
end

-- Stick hysteresis thresholds (ON at 0.5, OFF at 0.3 to prevent chatter)
local STICK_ON_THRESHOLD  = 0.5
local STICK_OFF_THRESHOLD = 0.3

-- Built-in vector2 passthrough: raw stick -> movement/turn when not user-overridden
local BUILTIN_VECTOR2_PASSTHROUGH = {
	raw_left_stick  = "vector2_walkdirection",
	raw_right_stick = "vector2_smoothturn",
}

-------------------------------------------------------------------------------
-- v2 SCHEMA: rule-object list per raw name
-- mapping[rawName] = { {target="logical_foo", trigger="passthrough"}, ... }
-- Also supports future gestures via additional trigger types (not implemented yet).
-------------------------------------------------------------------------------

-- Convert legacy string value into a rule-list.
local function NormalizeRuleList(v)
	if v == nil then return nil end
	if type(v) == "string" then
		if v == "" then return nil end
		return { { target = v, trigger = "passthrough", kind = "logical" } }
	end
	if type(v) == "table" then
		-- Already rule-list? Check first element.
		if v[1] and type(v[1]) == "table" and v[1].target ~= nil then
			for _, rule in ipairs(v) do
				rule.trigger = rule.trigger or "passthrough"
				-- Infer kind from target type when not set explicitly.
				if rule.kind == nil then
					rule.kind = (type(rule.target) == "number") and "key" or "logical"
				end
			end
			return v
		end
		-- Empty table: nothing to do
		if next(v) == nil then return nil end
	end
	return nil
end

-- Migrate a full mapping table (rawName -> string OR rule-list) into rule-list form.
local function MigrateMappingV1toV2(mapping)
	if not mapping then return {} end
	local out = {}
	for rawName, val in pairs(mapping) do
		local list = NormalizeRuleList(val)
		if list then out[rawName] = list end
	end
	return out
end

-- Try importing Advanced Input rules (short_press + logical only) on first load.
local ADVANCED_INPUT_CONFIG_PATH = "vrmod/vrmod_advanced_input.txt"
local ADVANCED_INPUT_BACKUP_PATH = "vrmod/vrmod_advanced_input.txt.backup"
local function ImportAdvancedInputIfPresent(mapping, drivingMapping)
	if not file.Exists(ADVANCED_INPUT_CONFIG_PATH, "DATA") then return 0, 0 end
	local json = file.Read(ADVANCED_INPUT_CONFIG_PATH, "DATA")
	if not json then return 0, 0 end
	local data = util.JSONToTable(json)
	if not data or type(data.mappings) ~= "table" then
		print("[VRMod Keybinding] Advanced Input config found but malformed — skipping import.")
		return 0, 0
	end

	local VALID_GESTURES = {
		short_press = true, long_press = true, double_click = true, combo = true,
	}
	local imported, skipped = 0, 0
	for _, m in ipairs(data.mappings) do
		local gesture = m.gesture or "short_press"
		local kind = m.target_type or "logical"
		local trigger = (gesture == "short_press") and "short_press" or gesture
		local okGesture = (gesture == "short_press") or VALID_GESTURES[gesture]
		local okKind = (kind == "logical") or (kind == "key")
		if okGesture and okKind and m.raw and m.target ~= nil then
			local rule = {
				target = m.target,
				trigger = trigger,
				kind = kind,
			}
			if gesture == "combo" and m.combo_partner then
				rule.combo_partner = m.combo_partner
			end
			local targetCtx = m.context or "both"
			if targetCtx == "on_foot" or targetCtx == "both" then
				mapping[m.raw] = mapping[m.raw] or {}
				table.insert(mapping[m.raw], rule)
				imported = imported + 1
			end
			if targetCtx == "driving" or targetCtx == "both" then
				drivingMapping[m.raw] = drivingMapping[m.raw] or {}
				table.insert(drivingMapping[m.raw], table.Copy(rule))
				imported = imported + 1
			end
		else
			skipped = skipped + 1
			print(string.format(
				"[VRMod Keybinding] Advanced Input rule dropped (unsupported): raw=%s gesture=%s target_type=%s",
				tostring(m.raw), tostring(m.gesture), tostring(m.target_type)))
		end
	end

	-- Rename config to backup so we don't re-import next launch
	local renamed = false
	pcall(function()
		if file.Exists(ADVANCED_INPUT_BACKUP_PATH, "DATA") then
			file.Delete(ADVANCED_INPUT_BACKUP_PATH)
		end
		file.Write(ADVANCED_INPUT_BACKUP_PATH, json)
		file.Delete(ADVANCED_INPUT_CONFIG_PATH)
		renamed = true
	end)
	print(string.format(
		"[VRMod Keybinding] Advanced Input imported: %d rules (%d skipped). Original %s",
		imported, skipped, renamed and "moved to .backup" or "left in place (rename failed)"))
	return imported, skipped
end

local function LoadMappingFromDisk()
	local json = file.Read("vrmod/vrmod_keybindings.txt", "DATA")
	if json then
		local data = util.JSONToTable(json)
		if data and data.mapping then
			local version = tonumber(data.version) or 1
			if version < 2 then
				LKB.mapping = MigrateMappingV1toV2(data.mapping)
				LKB.drivingMapping = MigrateMappingV1toV2(data.drivingMapping or {})
				print("[VRMod Keybinding] Migrated keybindings from v" .. version .. " to v2")
			else
				-- v2+: normalize anyway to catch manually-edited files
				LKB.mapping = MigrateMappingV1toV2(data.mapping)
				LKB.drivingMapping = MigrateMappingV1toV2(data.drivingMapping or {})
			end
			if type(data.settings) == "table" then
				if data.settings.builtin_movement_passthrough ~= nil then
					LKB.settings.builtin_movement_passthrough = data.settings.builtin_movement_passthrough
				end
				if data.settings.disable_steamvr_main ~= nil then
					LKB.settings.disable_steamvr_main = data.settings.disable_steamvr_main
				end
				local lp = tonumber(data.settings.long_press_ms)
				if lp and lp > 0 then LKB.settings.long_press_ms = lp end
				local dc = tonumber(data.settings.double_click_ms)
				if dc and dc > 0 then LKB.settings.double_click_ms = dc end
			end
			print("[VRMod Keybinding] Loaded custom keybindings from disk")
			return true
		end
	end
	return false
end

local function SaveMappingToDisk()
	local data = {
		version = 2,
		mapping = LKB.mapping,
		drivingMapping = LKB.drivingMapping,
		settings = LKB.settings,
	}
	if not file.Exists("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end
	file.Write("vrmod/vrmod_keybindings.txt", util.TableToJSON(data, true))
	print("[VRMod Keybinding] Saved keybindings to disk")

	-- Edge-detection cache must be flushed so the next ProcessRawInput call
	-- uses the NEW mapping instead of silently ignoring a "no change" frame
	-- on a previously-held button. This is what caused the "I changed the
	-- mapping but nothing happened until I let go and pressed again" issue.
	LKB.prevRawBooleans = {}
	LKB.stickDirState = {}

	-- If the user is live in Lua mode, re-assert the active action sets so
	-- /actions/raw membership stays consistent with the new mapping.
	if cv_inputmode:GetInt() == 1 and g_VR and g_VR.active and VRMOD_SetActiveActionSets then
		VRMOD_SetActiveActionSets("/actions/base",
			LocalPlayer():InVehicle() and "/actions/driving" or "/actions/main")
	end
end

local function ResetToDefaults()
	LKB.mapping = table.Copy(DEFAULT_MAPPING)
	LKB.drivingMapping = table.Copy(DEFAULT_DRIVING_MAPPING)
	SaveMappingToDisk()
end

-- Load on start
if not LoadMappingFromDisk() then
	LKB.mapping = table.Copy(DEFAULT_MAPPING)
	LKB.drivingMapping = table.Copy(DEFAULT_DRIVING_MAPPING)
end

-- One-shot Advanced Input import (destroys source config via rename after success).
do
	local imported, skipped = ImportAdvancedInputIfPresent(LKB.mapping, LKB.drivingMapping)
	if imported > 0 then
		-- Persist the newly imported rules so they survive restart
		SaveMappingToDisk()
	end
end

-- Expose for menu/console
LKB.SaveMapping = SaveMappingToDisk
LKB.ResetToDefaults = ResetToDefaults
LKB.DEFAULT_MAPPING = DEFAULT_MAPPING
LKB.DEFAULT_DRIVING_MAPPING = DEFAULT_DRIVING_MAPPING

-------------------------------------------------------------------------------
-- RAW INPUT PROCESSING
-------------------------------------------------------------------------------

local function IsRawAction(name)
	return string.sub(name, 1, 4) == "raw_"
end

-------------------------------------------------------------------------------
-- GESTURE STATE MACHINE
-------------------------------------------------------------------------------

local ST_IDLE        = 0
local ST_PRESSED     = 1
local ST_HELD        = 2
local ST_WAIT_DOUBLE = 3

local KEY_PULSE_SEC = 0.05
local GESTURE_TRIGGERS = {
	short_press = true, long_press = true, double_click = true, combo = true,
}

-- Apply a gesture-fired rule's ON/OFF state to the target.
-- target kind: "logical" writes to input table, "key" emits VRMOD_SendKeyEvent or InputEmu.
local function ApplyRuleTarget(rule, on, input, changedInputs)
	if not rule or rule.target == nil then return end
	if rule.kind == "key" then
		local code = tonumber(rule.target)
		if not code or code <= 0 then return end
		-- Prefer vrmod.InputEmu_SetKeyDual (Lua + C++ layers). Fallback to VRMOD_SendKeyEvent.
		if vrmod and vrmod.InputEmu_SetKeyDual then
			pcall(vrmod.InputEmu_SetKeyDual, code, on and true or nil)
		elseif VRMOD_SendKeyEvent then
			pcall(VRMOD_SendKeyEvent, code, on and true or false)
		end
		if on then
			LKB.activeHeldKeys[code] = true
		else
			LKB.activeHeldKeys[code] = nil
		end
	else
		-- logical
		local logicalName = tostring(rule.target)
		if logicalName == "" then return end
		input[logicalName] = on or nil
		changedInputs[logicalName] = on and true or false
	end
end

-- Emit a pulse: ON now, OFF after KEY_PULSE_SEC.
local function PulseRuleTarget(rule, input, changedInputs)
	ApplyRuleTarget(rule, true, input, changedInputs)
	if rule.kind == "key" then
		local code = tonumber(rule.target)
		if code then
			-- Clear any previous pulse timer for this code
			local prev = LKB.activeKeyPulses[code]
			if prev then timer.Remove(prev) end
			local tid = "lkb_key_pulse_" .. tostring(code) .. "_" .. tostring(SysTime())
			LKB.activeKeyPulses[code] = tid
			timer.Create(tid, KEY_PULSE_SEC, 1, function()
				ApplyRuleTarget(rule, false, input, changedInputs)
				LKB.activeKeyPulses[code] = nil
			end)
		end
	else
		-- Logical: ON this frame, rely on edge-detection to clear next frame.
		-- We stash a marker so CleanupPulseMarkers() below can OFF it next frame.
		LKB._pendingLogicalOff = LKB._pendingLogicalOff or {}
		LKB._pendingLogicalOff[rule] = true
	end
end

-- Filter rules by trigger type; returns a boolean "has at least one"
local function HasTrigger(rules, trigger)
	if not rules then return false end
	for _, r in ipairs(rules) do
		if (r.trigger or "passthrough") == trigger then return true end
	end
	return false
end

local function FireRulesByTrigger(rules, trigger, on, input, changedInputs, pulse)
	if not rules then return end
	for _, rule in ipairs(rules) do
		if (rule.trigger or "passthrough") == trigger then
			if pulse then
				PulseRuleTarget(rule, input, changedInputs)
			else
				ApplyRuleTarget(rule, on, input, changedInputs)
			end
		end
	end
end

-- Update gesture state for a single raw boolean. Triggers rule firing as needed.
local function UpdateGestureState(rawName, rawValue, now, rules, input, changedInputs, activeMapping)
	local gs = LKB.rawGestureState[rawName]
	if not gs then
		gs = { state = ST_IDLE, down = false, pressedAt = 0, lastReleaseAt = 0 }
		LKB.rawGestureState[rawName] = gs
	end

	local prevDown = gs.down
	local newDown = rawValue and true or false
	gs.down = newDown

	local longMs   = (LKB.settings.long_press_ms   or 500) / 1000
	local doubleMs = (LKB.settings.double_click_ms or 300) / 1000

	-- Combo handling: distinct from state machine because combo requires checking a partner.
	-- For each combo rule on this raw: evaluate (self.down AND partner.down).
	for _, rule in ipairs(rules) do
		if rule.trigger == "combo" and rule.combo_partner then
			local partnerDown = false
			local partnerState = LKB.rawGestureState[rule.combo_partner]
			if partnerState and partnerState.down then
				partnerDown = true
			end
			local bothDown = newDown and partnerDown
			local key = rawName .. "@combo@" .. tostring(rule.combo_partner) .. "@" .. tostring(rule.target)
			local prevCombo = LKB.comboActive[key]
			if bothDown ~= (prevCombo or false) then
				ApplyRuleTarget(rule, bothDown, input, changedInputs)
				LKB.comboActive[key] = bothDown or nil
			end
		end
	end

	if newDown and not prevDown then
		-- Press edge
		if gs.state == ST_WAIT_DOUBLE and (now - gs.lastReleaseAt) <= doubleMs then
			FireRulesByTrigger(rules, "double_click", true, input, changedInputs, true)
			gs.state = ST_IDLE
		else
			gs.state = ST_PRESSED
			gs.pressedAt = now
		end
	elseif not newDown and prevDown then
		-- Release edge
		if gs.state == ST_HELD then
			-- Long-press release (turn off held rules)
			FireRulesByTrigger(rules, "long_press", false, input, changedInputs, false)
			gs.state = ST_IDLE
		elseif gs.state == ST_PRESSED then
			gs.lastReleaseAt = now
			if HasTrigger(rules, "double_click") then
				gs.state = ST_WAIT_DOUBLE
			else
				if HasTrigger(rules, "short_press") then
					FireRulesByTrigger(rules, "short_press", true, input, changedInputs, true)
				end
				gs.state = ST_IDLE
			end
		end
	else
		-- Continue
		if gs.state == ST_PRESSED and (now - gs.pressedAt) >= longMs then
			FireRulesByTrigger(rules, "long_press", true, input, changedInputs, false)
			gs.state = ST_HELD
		elseif gs.state == ST_WAIT_DOUBLE and (now - gs.lastReleaseAt) > doubleMs then
			-- Double-click window expired, fire short_press instead
			if HasTrigger(rules, "short_press") then
				FireRulesByTrigger(rules, "short_press", true, input, changedInputs, true)
			end
			gs.state = ST_IDLE
		end
	end
end

-- Clear logical pulses that were emitted last frame (they should only be ON for 1 tick).
local function ClearPulseMarkers(input, changedInputs)
	if not LKB._pendingLogicalOff then return end
	for rule in pairs(LKB._pendingLogicalOff) do
		if rule and rule.target and rule.kind ~= "key" then
			local name = tostring(rule.target)
			input[name] = nil
			changedInputs[name] = false
		end
	end
	LKB._pendingLogicalOff = {}
end

-- Derive stick 4-direction booleans from raw_*_stick vector2 (with hysteresis).
-- Writes input[raw_{hand}_stick_{up|down|left|right}] as boolean.
local function DeriveStickDirections(input)
	for _, hand in ipairs({"left", "right"}) do
		local stickName = "raw_" .. hand .. "_stick"
		local v = input[stickName]
		local up    = "raw_" .. hand .. "_stick_up"
		local down  = "raw_" .. hand .. "_stick_down"
		local left  = "raw_" .. hand .. "_stick_left"
		local right = "raw_" .. hand .. "_stick_right"
		if v and type(v) == "table" then
			local x, y = v.x or 0, v.y or 0
			local function hyst(name, value)
				local cur = LKB.stickDirState[name]
				if cur then
					if value < STICK_OFF_THRESHOLD then cur = false end
				else
					if value > STICK_ON_THRESHOLD then cur = true end
				end
				LKB.stickDirState[name] = cur or false
				input[name] = LKB.stickDirState[name]
			end
			hyst(up,     y)
			hyst(down,  -y)
			hyst(right,  x)
			hyst(left,  -x)
		else
			-- No stick data this frame; preserve last derived state (could also clear)
			input[up]    = LKB.stickDirState[up]    or false
			input[down]  = LKB.stickDirState[down]  or false
			input[left]  = LKB.stickDirState[left]  or false
			input[right] = LKB.stickDirState[right] or false
		end
	end
end

local function ProcessRawInput(input, changedInputs)
	if not input then return input, changedInputs end

	-- Make sure synthetic names are in the VRMod bookkeeping tables.
	RegisterSyntheticStickDirs()

	-- Step 0: derive stick 4-direction booleans before any mapping runs.
	DeriveStickDirections(input)

	local inVehicle = g_VR and g_VR.active and LocalPlayer and LocalPlayer():InVehicle()
	local activeMapping = inVehicle and LKB.drivingMapping or LKB.mapping

	-- Safety net: if the user ended up with a completely empty mapping while
	-- Lua mode is active, apply an emergency fallback (in-memory only) so that
	-- at least the primary-fire click works. Lets them open the wizard / UI.
	LKB.fallbackActive = false
	if not activeMapping or table.Count(activeMapping) == 0 then
		-- FALLBACK_MAPPING is v1 (string) — normalize on the fly
		activeMapping = MigrateMappingV1toV2(FALLBACK_MAPPING)
		LKB.fallbackActive = true
	end

	-- Debug: periodic raw input dump
	dbgFrameCount = dbgFrameCount + 1
	local doPeriodicLog = (dbgFrameCount % DBG_RAW_INTERVAL == 0)

	if doPeriodicLog then
		local rawCount = 0
		for _, rawName in ipairs(g_VR.rawActionNames or {}) do
			if input[rawName] ~= nil then rawCount = rawCount + 1 end
		end
		DbgDebug("[LKB] ProcessRawInput: mode=%s, raw_actions_received=%d/%d",
			inVehicle and "driving" or "on_foot",
			rawCount, #(g_VR.rawActionNames or {}))
	end

	-- Step 1a: clear any 1-tick logical pulses emitted last frame.
	local newChanged = {}
	ClearPulseMarkers(input, newChanged)

	-- Step 1b: apply rule-list mappings (1:N supported).
	-- Passthrough rules: direct raw -> target copy (edge-detected for booleans).
	-- Gesture rules (short_press/long_press/double_click/combo): run through state machine.
	local now = SysTime()
	for rawName, ruleList in pairs(activeMapping) do
		if type(ruleList) ~= "table" then continue end
		local rawType = g_VR.rawActionTypes and g_VR.rawActionTypes[rawName]
		if not rawType then continue end
		local rawValue = input[rawName]
		if rawValue == nil then continue end

		-- Gesture processing (only for boolean raws)
		if rawType == "boolean" then
			local hasGesture = false
			for _, rule in ipairs(ruleList) do
				local trig = rule.trigger or "passthrough"
				if GESTURE_TRIGGERS[trig] then hasGesture = true break end
			end
			if hasGesture then
				UpdateGestureState(rawName, rawValue, now, ruleList, input, newChanged, activeMapping)
			end
		end

		-- Passthrough processing (all types)
		for _, rule in ipairs(ruleList) do
			if (rule.trigger or "passthrough") ~= "passthrough" then continue end
			if rule.target == nil or rule.target == "" then continue end

			if rawType == "boolean" then
				if rule.kind == "key" then
					-- Key passthrough: hold while raw is down
					local code = tonumber(rule.target)
					if code then
						local key = rawName .. "=>key=>" .. tostring(code)
						local prev = LKB.prevRawBooleans[key]
						if prev ~= rawValue then
							if vrmod and vrmod.InputEmu_SetKeyDual then
								pcall(vrmod.InputEmu_SetKeyDual, code, rawValue and true or nil)
							elseif VRMOD_SendKeyEvent then
								pcall(VRMOD_SendKeyEvent, code, rawValue and true or false)
							end
							LKB.prevRawBooleans[key] = rawValue
							LKB.activeHeldKeys[code] = rawValue and true or nil
						end
					end
				else
					local logicalName = tostring(rule.target)
					input[logicalName] = rawValue
					local key = rawName .. "->" .. logicalName
					local prev = LKB.prevRawBooleans[key]
					if prev ~= rawValue then
						newChanged[logicalName] = rawValue
						LKB.prevRawBooleans[key] = rawValue
						DbgInfo("[LKB] MAPPED: %s (%s) -> %s = %s",
							rawName, rawType, logicalName, tostring(rawValue))
					end
				end
			elseif rawType == "vector1" or rawType == "vector2" then
				-- Analog passthrough only to logical targets (key codes are digital)
				if rule.kind ~= "key" then
					input[tostring(rule.target)] = rawValue
				end
			end
		end
	end

	-- Step 1b: built-in vector2 passthrough (walk direction / smooth turn).
	-- Only applied when the user hasn't explicitly mapped to the same logical
	-- action and the feature is enabled via LKB.settings.
	if LKB.settings.builtin_movement_passthrough then
		for rawName, logicalName in pairs(BUILTIN_VECTOR2_PASSTHROUGH) do
			local v = input[rawName]
			if v and input[logicalName] == nil then
				input[logicalName] = v
			end
		end
	end

	-- Step 2: Remove raw action names from input table (clean up)
	-- Other code shouldn't see raw_* keys
	LKB.rawValues = LKB.rawValues or {}
	for _, rawName in ipairs(g_VR.rawActionNames or {}) do
		-- Keep raw values in a separate table for debug/UI
		if input[rawName] ~= nil then
			LKB.rawValues[rawName] = input[rawName]
			input[rawName] = nil -- Remove raw_* from input so other code doesn't see them
		end
	end

	-- Step 3: Replace changedInputs with our mapped changes
	-- The original changedInputs may contain raw_* changes that other code doesn't understand
	-- Filter out raw entries and add our mapped entries
	local filteredChanged = {}
	for k, v in pairs(changedInputs) do
		if not IsRawAction(k) then
			filteredChanged[k] = v
		end
	end
	for k, v in pairs(newChanged) do
		filteredChanged[k] = v
	end

	return input, filteredChanged
end

-------------------------------------------------------------------------------
-- MONKEY-PATCH INSTALLATION
-------------------------------------------------------------------------------

local function InstallPatches()
	if g_VR._rawInputHooked then return true end
	if not VRMOD_GetActions then return false end
	if not VRMOD_SetActiveActionSets then return false end

	-- Patch GetActions
	local origGetActions = VRMOD_GetActions
	VRMOD_GetActions = function()
		local input, changed = origGetActions()
		local mode = cv_inputmode:GetInt()
		if mode == 1 then
			input, changed = ProcessRawInput(input, changed)
		end
		-- Debug: periodic summary of what GetActions returned
		if dbgFrameCount % DBG_RAW_INTERVAL == 0 then
			local inputCount = 0
			if input then for _ in pairs(input) do inputCount = inputCount + 1 end end
			local changedCount = 0
			if changed then for _ in pairs(changed) do changedCount = changedCount + 1 end end
			DbgDebug("[LKB] GetActions: mode=%s, input_keys=%d, changed_keys=%d",
				mode == 1 and "LUA" or "STEAMVR", inputCount, changedCount)
		end
		return input, changed
	end

	-- Patch SetActiveActionSets to always include /actions/raw when in Lua mode
	-- Also supports the "disable SteamVR main" setting from the keybinding menu.
	local origSetActive = VRMOD_SetActiveActionSets
	VRMOD_SetActiveActionSets = function(...)
		local mode = cv_inputmode:GetInt()
		if mode == 1 then
			local args = {...}

			-- If "Disable SteamVR /actions/main" is enabled via Keybinding settings,
			-- remove /actions/main and /actions/driving to prevent SteamVR's
			-- native bindings from firing alongside Lua mappings.
			if LKB.settings and LKB.settings.disable_steamvr_main then
				local filtered = {}
				for _, v in ipairs(args) do
					if v == "/actions/base" or v == "/actions/raw" then
						filtered[#filtered + 1] = v
					end
					-- /actions/main and /actions/driving are intentionally dropped
				end
				-- Ensure /actions/raw is present
				local hasRaw = false
				for _, v in ipairs(filtered) do
					if v == "/actions/raw" then hasRaw = true break end
				end
				if not hasRaw then filtered[#filtered + 1] = "/actions/raw" end
				DbgInfo("[LKB] SetActiveActionSets: SteamVR disabled, using only base+raw (%d sets)", #filtered)
				return origSetActive(unpack(filtered))
			end

			-- Standard Lua mode: inject /actions/raw alongside existing sets
			local hasRaw = false
			for _, v in ipairs(args) do
				if v == "/actions/raw" then hasRaw = true break end
			end
			if not hasRaw then
				args[#args + 1] = "/actions/raw"
				DbgInfo("[LKB] SetActiveActionSets: injected /actions/raw (total sets: %d)", #args)
			end
			return origSetActive(unpack(args))
		end
		return origSetActive(...)
	end

	g_VR._rawInputHooked = true
	print("[VRMod Keybinding] Input patches installed (Lua keybinding mode available)")
	return true
end

-- Try to install immediately (if VR module already loaded)
if not InstallPatches() then
	-- Module not loaded yet, wait for it
	hook.Add("Think", "VRMod_RawInput_PatchInit", function()
		if InstallPatches() then
			hook.Remove("Think", "VRMod_RawInput_PatchInit")
		end
	end)
end

-------------------------------------------------------------------------------
-- CONSOLE COMMANDS
-------------------------------------------------------------------------------

concommand.Add("vrmod_keybinding_reset", function()
	ResetToDefaults()
	print("[VRMod Keybinding] All mappings cleared (default is empty)")
end)

concommand.Add("vrmod_keybinding_save", function()
	SaveMappingToDisk()
end)

local function PrintMappingTable(mapTable)
	if table.Count(mapTable) == 0 then
		print("  (empty)")
		return
	end
	for raw, ruleList in SortedPairs(mapTable) do
		if type(ruleList) == "table" and ruleList[1] then
			if #ruleList == 1 then
				print("  " .. raw .. " -> " .. tostring(ruleList[1].target))
			else
				print("  " .. raw .. " -> (" .. #ruleList .. " rules)")
				for i, rule in ipairs(ruleList) do
					print("    [" .. i .. "] " .. tostring(rule.target)
						.. " (" .. tostring(rule.trigger or "passthrough") .. ")")
				end
			end
		else
			print("  " .. raw .. " -> " .. tostring(ruleList))
		end
	end
end

concommand.Add("vrmod_keybinding_list", function()
	local mode = cv_inputmode:GetInt()
	print("=== VRMod Keybinding Config (v2) ===")
	print("Mode: " .. (mode == 1 and "Lua Keybinding" or "SteamVR"))
	print("Settings: movement_passthrough="
		.. tostring(LKB.settings.builtin_movement_passthrough)
		.. "  disable_steamvr_main="
		.. tostring(LKB.settings.disable_steamvr_main))
	if LKB.fallbackActive then
		print("!! FALLBACK ACTIVE — no mappings defined, using emergency mapping only.")
		print("!! Run vrmod_keybinding_wizard or vrmod_keybinding_menu to configure.")
	end
	print("")
	print("-- On Foot Mapping --")
	PrintMappingTable(LKB.mapping)
	print("")
	print("-- Driving Mapping --")
	PrintMappingTable(LKB.drivingMapping)
end)

concommand.Add("vrmod_keybinding_set", function(ply, cmd, args)
	if #args < 2 then
		print("Usage: vrmod_keybinding_set <raw_action> <logical_action|none>")
		print("  Replaces all rules on <raw_action> with one passthrough rule.")
		print("  Example: vrmod_keybinding_set raw_right_a boolean_reload")
		print("  Use 'none' to unbind all rules for that raw.")
		return
	end
	RegisterSyntheticStickDirs()
	local rawName = args[1]
	local logicalName = args[2]

	if not g_VR.rawActionTypes or not g_VR.rawActionTypes[rawName] then
		print("ERROR: Unknown raw action: " .. rawName)
		return
	end

	if logicalName == "none" or logicalName == "nil" then
		LKB.mapping[rawName] = nil
		print("Unbound " .. rawName)
	else
		LKB.mapping[rawName] = { { target = logicalName, trigger = "passthrough" } }
		print("Mapped " .. rawName .. " -> " .. logicalName)
	end
	SaveMappingToDisk()
end)

-- Add a rule alongside existing rules (1:N)
concommand.Add("vrmod_keybinding_add", function(ply, cmd, args)
	if #args < 2 then
		print("Usage: vrmod_keybinding_add <raw_action> <logical_action>")
		print("  Appends a passthrough rule; existing rules on same raw are kept.")
		return
	end
	RegisterSyntheticStickDirs()
	local rawName, logicalName = args[1], args[2]
	if not g_VR.rawActionTypes or not g_VR.rawActionTypes[rawName] then
		print("ERROR: Unknown raw action: " .. rawName)
		return
	end
	LKB.mapping[rawName] = LKB.mapping[rawName] or {}
	table.insert(LKB.mapping[rawName], { target = logicalName, trigger = "passthrough" })
	print("Added rule: " .. rawName .. " -> " .. logicalName
		.. " (" .. #LKB.mapping[rawName] .. " rule(s) on this raw)")
	SaveMappingToDisk()
end)

-- Clear all rules on a single raw (or all raws if none)
concommand.Add("vrmod_keybinding_clear", function(ply, cmd, args)
	if #args == 0 then
		LKB.mapping = {}
		print("Cleared ALL on-foot mappings")
	else
		LKB.mapping[args[1]] = nil
		print("Cleared mapping for " .. args[1])
	end
	SaveMappingToDisk()
end)

-- Debug: show raw input values in real-time
concommand.Add("vrmod_keybinding_debug", function()
	if LKB.debugPanel and IsValid(LKB.debugPanel) then
		LKB.debugPanel:Remove()
		LKB.debugPanel = nil
		return
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(400, 500)
	frame:SetPos(ScrW() - 420, 20)
	frame:SetTitle("VRMod Raw Input Debug")
	frame:SetDraggable(true)
	frame:MakePopup()
	frame:SetDeleteOnClose(true)

	local label = vgui.Create("DLabel", frame)
	label:Dock(FILL)
	label:SetWrap(true)
	label:SetContentAlignment(7)

	frame.Think = function()
		if not g_VR or not g_VR.active then
			label:SetText(L("VR not active", "VR not active"))
			return
		end

		local lines = {}
		lines[#lines + 1] = "Mode: " .. (cv_inputmode:GetInt() == 1 and "LUA" or "STEAMVR")
		lines[#lines + 1] = ""

		if LKB.rawValues then
			lines[#lines + 1] = "-- Raw Values --"
			for _, rawName in ipairs(g_VR.rawActionNames or {}) do
				local val = LKB.rawValues[rawName]
				if val ~= nil then
					local ruleList = LKB.mapping[rawName]
					local mappedStr = "(unmapped)"
					if type(ruleList) == "table" and ruleList[1] then
						if #ruleList == 1 then
							mappedStr = tostring(ruleList[1].target)
						else
							mappedStr = string.format("%s +%d",
								tostring(ruleList[1].target), #ruleList - 1)
						end
					end
					if type(val) == "table" then
						lines[#lines + 1] = string.format("  %s: x=%.2f y=%.2f -> %s",
							rawName, val.x or 0, val.y or 0, mappedStr)
					elseif type(val) == "boolean" then
						lines[#lines + 1] = string.format("  %s: %s -> %s",
							rawName, val and "ON" or "off", mappedStr)
					else
						lines[#lines + 1] = string.format("  %s: %.3f -> %s",
							rawName, val, mappedStr)
					end
				end
			end
		else
			lines[#lines + 1] = "(No raw data yet — is /actions/raw active?)"
		end

		label:SetText(table.concat(lines, "\n"))
	end

	LKB.debugPanel = frame
end)

-------------------------------------------------------------------------------
-- SETTINGS UI (concommand: vrmod_keybinding_menu)
-------------------------------------------------------------------------------

-- All logical actions that can be mapped to
local AVAILABLE_LOGICAL_ACTIONS = {
	"(none)",
	-- Core combat
	"boolean_primaryfire", "boolean_secondaryfire",
	"boolean_left_primaryfire", "boolean_left_secondaryfire",
	-- Interaction
	"boolean_use", "boolean_reload",
	"boolean_right_pickup", "boolean_left_pickup",
	-- Movement
	"boolean_jump", "boolean_crouch", "boolean_sprint", "boolean_walk",
	-- Menu/UI
	"boolean_spawnmenu", "boolean_changeweapon", "boolean_menucontext",
	"boolean_flashlight", "boolean_chat",
	-- Slots
	"boolean_slot1", "boolean_slot2", "boolean_slot3",
	"boolean_slot4", "boolean_slot5", "boolean_slot6",
	-- Direction (usually from stick, but can map to buttons)
	"boolean_turnleft", "boolean_turnright", "boolean_teleport",
	"boolean_undo",
	-- Mode
	"boolean_lefthandmode", "boolean_righthandmode",
	-- Analog
	"vector1_primaryfire", "vector1_left_primaryfire",
	-- 2D Axis
	"vector2_walkdirection", "vector2_smoothturn",
	-- Vehicle
	"vector1_forward", "vector1_reverse", "vector2_steer",
	"boolean_turbo", "boolean_handbrake", "boolean_turret",
}

-- Categorization helper for raw action names
local function CategorizeRawName(rawName)
	if rawName:find("_trigger") then return "Triggers"
	elseif rawName:find("_grip") then return "Grips"
	elseif rawName:find("_stick") then return "Sticks"
	else return "Buttons" end
end

local CATEGORY_ORDER = { "Triggers", "Grips", "Sticks", "Buttons" }

local function PrettyRawName(rawName)
	local s = rawName:gsub("^raw_", ""):gsub("_", " ")
	-- Stick direction icons for readability
	s = s:gsub(" stick up",    " Stick ↑")
	s = s:gsub(" stick down",  " Stick ↓")
	s = s:gsub(" stick left",  " Stick ←")
	s = s:gsub(" stick right", " Stick →")
	return s
end

concommand.Add("vrmod_keybinding_menu", function()
	if IsValid(LKB.menuFrame) then LKB.menuFrame:Remove() end
	RegisterSyntheticStickDirs()

	local frame = vgui.Create("DFrame")
	frame:SetSize(700, 620)
	frame:Center()
	frame:SetTitle("VRMod Lua Keybinding Configuration")
	frame:MakePopup()
	frame:SetDeleteOnClose(true)
	LKB.menuFrame = frame

	-- Top bar: mode toggle + mode banner + wizard/clear buttons
	local topBar = vgui.Create("DPanel", frame)
	topBar:Dock(TOP)
	topBar:SetTall(72)
	topBar:DockMargin(0, 0, 0, 4)
	topBar:SetPaintBackground(false)

	-- Row 1: mode banner
	local bannerLabel = vgui.Create("DLabel", topBar)
	bannerLabel:SetPos(8, 6)
	bannerLabel:SetSize(680, 18)
	bannerLabel:SetContentAlignment(4)
	local function RefreshBanner()
		if cv_inputmode:GetInt() == 1 then
			bannerLabel:SetText(L("[Lua Keybinding] These assignments are ACTIVE.",
				"[Lua Keybinding] These assignments are ACTIVE."))
			bannerLabel:SetTextColor(Color(100, 240, 140))
		else
			bannerLabel:SetText(L("[SteamVR mode] Assignments below are NOT used. Switch to Lua to enable them.",
				"[SteamVR mode] Assignments below are NOT used. Switch to Lua to enable them."))
			bannerLabel:SetTextColor(Color(255, 180, 60))
		end
	end
	RefreshBanner()

	-- Row 2: controls
	local modeLabel = vgui.Create("DLabel", topBar)
	modeLabel:SetPos(8, 34)
	modeLabel:SetText(L("Input Mode:", "Input Mode:"))
	modeLabel:SetTextColor(color_white)
	modeLabel:SizeToContents()

	local modeCombo = vgui.Create("DComboBox", topBar)
	modeCombo:SetPos(100, 32)
	modeCombo:SetSize(220, 24)
	modeCombo:AddChoice(L("SteamVR Bindings (Default)", "SteamVR Bindings (Default)"), 0)
	modeCombo:AddChoice(L("Lua Keybinding (Recommended)", "Lua Keybinding (Recommended)"), 1)
	modeCombo:SetValue(cv_inputmode:GetInt() == 1
		and L("Lua Keybinding (Recommended)", "Lua Keybinding (Recommended)")
		or L("SteamVR Bindings (Default)", "SteamVR Bindings (Default)"))
	modeCombo.OnSelect = function(_, _, _, data)
		RunConsoleCommand("vrmod_unoff_inputmode", tostring(data))
		timer.Simple(0.2, RefreshBanner)
	end

	local wizardBtn = vgui.Create("DButton", topBar)
	wizardBtn:SetPos(330, 32)
	wizardBtn:SetSize(110, 24)
	wizardBtn:SetText(L("VR Wizard", "VR Wizard"))
	wizardBtn.DoClick = function() RunConsoleCommand("vrmod_keybinding_wizard") end

	local resetBtn = vgui.Create("DButton", topBar)
	resetBtn:SetPos(450, 32)
	resetBtn:SetSize(110, 24)
	resetBtn:SetText(L("Clear All", "Clear All"))
	resetBtn.DoClick = function()
		Derma_Query(
			L("Clear all keybindings? (default is empty)", "Clear all keybindings? (default is empty)"),
			"Confirm",
			"Yes", function()
				ResetToDefaults()
				RunConsoleCommand("vrmod_keybinding_menu")
			end,
			"No", function() end
		)
	end

	-- Settings row (checkboxes + timing sliders)
	local settingsBar = vgui.Create("DPanel", frame)
	settingsBar:Dock(TOP)
	settingsBar:SetTall(96)
	settingsBar:DockMargin(0, 0, 0, 4)
	settingsBar:SetPaintBackground(false)

	local chkMovement = vgui.Create("DCheckBoxLabel", settingsBar)
	chkMovement:SetPos(8, 4)
	chkMovement:SetText(L(
		"Built-in movement passthrough (left stick -> walk, right stick -> turn)",
		"Built-in movement passthrough (left stick -> walk, right stick -> turn)"))
	chkMovement:SizeToContents()
	chkMovement:SetValue(LKB.settings.builtin_movement_passthrough)
	chkMovement.OnChange = function(_, val)
		LKB.settings.builtin_movement_passthrough = val and true or false
		SaveMappingToDisk()
	end

	local chkDisableSVR = vgui.Create("DCheckBoxLabel", settingsBar)
	chkDisableSVR:SetPos(8, 26)
	chkDisableSVR:SetText(L(
		"Disable SteamVR /actions/main (prevents native bindings firing in Lua mode)",
		"Disable SteamVR /actions/main (prevents native bindings firing in Lua mode)"))
	chkDisableSVR:SizeToContents()
	chkDisableSVR:SetValue(LKB.settings.disable_steamvr_main)
	chkDisableSVR.OnChange = function(_, val)
		LKB.settings.disable_steamvr_main = val and true or false
		SaveMappingToDisk()
	end

	-- Long press duration slider
	local longSlider = vgui.Create("DNumSlider", settingsBar)
	longSlider:SetPos(8, 48)
	longSlider:SetSize(330, 20)
	longSlider:SetText(L("Long press (ms)", "Long press (ms)"))
	longSlider:SetMin(200)
	longSlider:SetMax(1000)
	longSlider:SetDecimals(0)
	longSlider:SetValue(LKB.settings.long_press_ms or 500)
	longSlider.OnValueChanged = function(_, val)
		LKB.settings.long_press_ms = math.Round(val)
	end
	longSlider.PerformLayout = nil  -- avoid re-layout quirks
	local longSaveBtn = vgui.Create("DButton", settingsBar)
	longSaveBtn:SetPos(344, 48)
	longSaveBtn:SetSize(40, 20)
	longSaveBtn:SetText("Save")
	longSaveBtn.DoClick = function() SaveMappingToDisk() end

	-- Double click interval slider
	local dblSlider = vgui.Create("DNumSlider", settingsBar)
	dblSlider:SetPos(8, 72)
	dblSlider:SetSize(330, 20)
	dblSlider:SetText(L("Double click (ms)", "Double click (ms)"))
	dblSlider:SetMin(100)
	dblSlider:SetMax(800)
	dblSlider:SetDecimals(0)
	dblSlider:SetValue(LKB.settings.double_click_ms or 300)
	dblSlider.OnValueChanged = function(_, val)
		LKB.settings.double_click_ms = math.Round(val)
	end
	local dblSaveBtn = vgui.Create("DButton", settingsBar)
	dblSaveBtn:SetPos(344, 72)
	dblSaveBtn:SetSize(40, 20)
	dblSaveBtn:SetText("Save")
	dblSaveBtn.DoClick = function() SaveMappingToDisk() end

	-- Tab control for On Foot / Driving
	local tabs = vgui.Create("DPropertySheet", frame)
	tabs:Dock(FILL)

	-- Build a row for a single raw action with rule-list support (1:N)
	local function BuildRawRow(scroll, mappingTable, rawName)
		local rawType = (g_VR.rawActionTypes and g_VR.rawActionTypes[rawName]) or "boolean"

		local row = vgui.Create("DPanel", scroll)
		row:Dock(TOP)
		row:SetTall(28)
		row:DockMargin(0, 0, 0, 1)

		local nameLabel = vgui.Create("DLabel", row)
		nameLabel:SetPos(8, 6)
		nameLabel:SetSize(220, 18)
		nameLabel:SetText(PrettyRawName(rawName) .. "  [" .. rawType .. "]")

		local rulesText = vgui.Create("DLabel", row)
		rulesText:SetPos(232, 6)
		rulesText:SetSize(340, 18)

		local function RefreshRulesText()
			local list = mappingTable[rawName]
			if not list or #list == 0 then
				rulesText:SetText(L("(unbound)", "(unbound)"))
				rulesText:SetTextColor(Color(160, 160, 160))
			else
				local parts = {}
				for _, r in ipairs(list) do
					local trig = r.trigger or "passthrough"
					local prefix = (trig == "passthrough") and "" or ("[" .. (GESTURE_SHORT_CHAR[trig] or "?") .. "] ")
					parts[#parts + 1] = prefix .. tostring(r.target)
				end
				rulesText:SetText(table.concat(parts, " + "))
				rulesText:SetTextColor(Color(200, 230, 255))
			end
		end
		RefreshRulesText()

		-- Helper: insert rule with given trigger
		local function addRuleWithTrigger(trigger)
			-- For gesture triggers, only boolean targets make sense.
			-- Build the submenu of compatible logical actions.
			local menu = DermaMenu()
			for _, logicalName in ipairs(AVAILABLE_LOGICAL_ACTIONS) do
				if logicalName ~= "(none)" then
					local logicalType = "boolean"
					if string.sub(logicalName, 1, 7) == "vector1" then logicalType = "vector1"
					elseif string.sub(logicalName, 1, 7) == "vector2" then logicalType = "vector2" end
					-- Gesture triggers force boolean target, passthrough uses rawType
					local needType = (trigger == "passthrough") and rawType or "boolean"
					if logicalType == needType then
						menu:AddOption(logicalName, function()
							mappingTable[rawName] = mappingTable[rawName] or {}
							table.insert(mappingTable[rawName],
								{ target = logicalName, trigger = trigger, kind = "logical" })
							SaveMappingToDisk()
							RefreshRulesText()
						end)
					end
				end
			end
			menu:Open()
		end

		-- "+ Add" button opens gesture-selection submenu, then target picker.
		-- For non-boolean raws (vector1/vector2) only passthrough is offered.
		local addBtn = vgui.Create("DButton", row)
		addBtn:SetPos(580, 3)
		addBtn:SetSize(50, 22)
		addBtn:SetText("+")
		addBtn.DoClick = function()
			if rawType ~= "boolean" then
				-- Only passthrough supported for vector types
				addRuleWithTrigger("passthrough")
				return
			end
			local menu = DermaMenu()
			menu:AddOption(L("Hold (passthrough)", "Hold (passthrough)"), function()
				addRuleWithTrigger("passthrough")
			end)
			menu:AddOption(L("Short press", "Short press"), function()
				addRuleWithTrigger("short_press")
			end)
			menu:AddOption(L("Long press", "Long press"), function()
				addRuleWithTrigger("long_press")
			end)
			menu:AddOption(L("Double click", "Double click"), function()
				addRuleWithTrigger("double_click")
			end)
			menu:AddOption(L("Combo (pick partner later in right-click)", "Combo (pick partner later in right-click)"), function()
				addRuleWithTrigger("combo")
			end)
			menu:Open()
		end

		-- "Clear" button removes all rules on this raw
		local clearBtn = vgui.Create("DButton", row)
		clearBtn:SetPos(634, 3)
		clearBtn:SetSize(50, 22)
		clearBtn:SetText(L("Clear", "Clear"))
		clearBtn.DoClick = function()
			mappingTable[rawName] = nil
			SaveMappingToDisk()
			RefreshRulesText()
		end

		-- Right-click on rulesText removes the last rule (quick detail)
		rulesText:SetMouseInputEnabled(true)
		rulesText.OnMousePressed = function(_, code)
			if code == MOUSE_RIGHT then
				local list = mappingTable[rawName]
				if list and #list > 0 then
					local menu = DermaMenu()
					for i, r in ipairs(list) do
						menu:AddOption(string.format("[%d] Remove %s", i, tostring(r.target)), function()
							table.remove(mappingTable[rawName], i)
							if #mappingTable[rawName] == 0 then mappingTable[rawName] = nil end
							SaveMappingToDisk()
							RefreshRulesText()
						end)
					end
					menu:Open()
				end
			end
		end
	end

	-- Build a categorized mapping panel
	local function CreateMappingPanel(parent, mappingTable)
		local scroll = vgui.Create("DScrollPanel", parent)
		scroll:Dock(FILL)

		-- Bucket raw names by category
		local rawNames = g_VR.rawActionNames or {}
		local byCategory = {}
		for _, name in ipairs(CATEGORY_ORDER) do byCategory[name] = {} end
		for _, rawName in ipairs(rawNames) do
			local cat = CategorizeRawName(rawName)
			byCategory[cat] = byCategory[cat] or {}
			table.insert(byCategory[cat], rawName)
		end

		for _, cat in ipairs(CATEGORY_ORDER) do
			if byCategory[cat] and #byCategory[cat] > 0 then
				local hdr = vgui.Create("DPanel", scroll)
				hdr:Dock(TOP)
				hdr:SetTall(22)
				hdr:DockMargin(0, 6, 0, 2)
				local lbl = vgui.Create("DLabel", hdr)
				lbl:Dock(FILL)
				lbl:SetText("  " .. L(cat, cat))
				lbl:SetFont("DermaDefaultBold")
				lbl:SetTextColor(Color(180, 220, 255))
				table.sort(byCategory[cat])
				for _, rawName in ipairs(byCategory[cat]) do
					BuildRawRow(scroll, mappingTable, rawName)
				end
			end
		end

		return scroll
	end

	local footPanel = vgui.Create("DPanel")
	footPanel:SetPaintBackground(false)
	CreateMappingPanel(footPanel, LKB.mapping)
	tabs:AddSheet(L("On Foot", "On Foot"), footPanel, "icon16/user.png")

	local drivePanel = vgui.Create("DPanel")
	drivePanel:SetPaintBackground(false)
	CreateMappingPanel(drivePanel, LKB.drivingMapping)
	tabs:AddSheet(L("In Vehicle", "In Vehicle"), drivePanel, "icon16/car.png")
end)

-------------------------------------------------------------------------------
-- DIAGNOSTIC COMMAND (works even without debug mode)
-------------------------------------------------------------------------------

concommand.Add("vrmod_keybinding_diag", function()
	print("========================================")
	print("  VRMod Lua Keybinding Diagnostic")
	print("========================================")
	print("")

	-- Mode
	local mode = cv_inputmode:GetInt()
	print("Input Mode: " .. (mode == 1 and "LUA KEYBINDING (active)" or "STEAMVR (default)"))
	print("")

	-- Patches
	print("Monkey-patches installed: " .. (g_VR._rawInputHooked and "YES" or "NO"))
	print("")

	-- Raw actions
	local rawNames = g_VR.rawActionNames or {}
	print("Raw action definitions: " .. #rawNames)
	if #rawNames == 0 then
		print("  WARNING: No raw actions registered!")
		print("  Check vrmod_steamvr_raw_input.lua loaded correctly")
	end
	print("")

	-- Raw action types
	local typeCount = 0
	if g_VR.rawActionTypes then
		for _ in pairs(g_VR.rawActionTypes) do typeCount = typeCount + 1 end
	end
	print("Raw action type mappings: " .. typeCount)
	print("")

	-- Current mapping (count raws, and count total rules)
	local function CountRules(t)
		local raws, rules = 0, 0
		for _, list in pairs(t or {}) do
			raws = raws + 1
			if type(list) == "table" then rules = rules + #list end
		end
		return raws, rules
	end
	local mapRaws, mapRules = CountRules(LKB.mapping)
	local driveRaws, driveRules = CountRules(LKB.drivingMapping)
	print(string.format("On-foot mapping: %d raws, %d rules", mapRaws, mapRules))
	print(string.format("Driving mapping: %d raws, %d rules", driveRaws, driveRules))
	print(string.format("Settings: movement_passthrough=%s  disable_steamvr_main=%s",
		tostring(LKB.settings.builtin_movement_passthrough),
		tostring(LKB.settings.disable_steamvr_main)))
	if LKB.fallbackActive then
		print("Fallback mapping: ACTIVE (no user mappings — right trigger = primaryfire only)")
	end
	print("")

	-- Raw values (are we receiving input?)
	if LKB.rawValues then
		local hasAny = false
		print("Last received raw values:")
		for _, rawName in ipairs(rawNames) do
			local val = LKB.rawValues[rawName]
			if val ~= nil then
				hasAny = true
				if type(val) == "table" then
					print(string.format("  %s = {x=%.3f, y=%.3f}", rawName, val.x or 0, val.y or 0))
				elseif type(val) == "boolean" then
					print(string.format("  %s = %s", rawName, val and "TRUE" or "false"))
				else
					print(string.format("  %s = %.3f", rawName, val))
				end
			end
		end
		if not hasAny then
			print("  (no raw values received yet)")
			if mode == 0 then
				print("  NOTE: Mode is STEAMVR. Set vrmod_unoff_inputmode 1 to receive raw input.")
			else
				print("  WARNING: Mode is LUA but no raw input received!")
				print("  Possible causes:")
				print("    - /actions/raw not in active action sets")
				print("    - SteamVR binding cache not updated (try VRMod Reset)")
				print("    - Raw actions not in manifest (check vrmod_steamvr_raw_input.lua)")
			end
		end
	else
		print("Raw values: (none collected yet)")
	end
	print("")

	-- Manifest check
	local manifest = g_VR.action_manifest or ""
	local hasRawInManifest = string.find(manifest, "raw_left_trigger_bool", 1, true) ~= nil
	print("Manifest contains raw actions: " .. (hasRawInManifest and "YES" or "NO"))
	if not hasRawInManifest then
		print("  WARNING: Raw actions not found in manifest!")
	end
	print("")

	-- Binding file check
	local bindingFile = file.Read("vrmod/vrmod_action_manifest.txt", "DATA")
	if bindingFile then
		local hasRawInFile = string.find(bindingFile, "raw_left_trigger_bool", 1, true) ~= nil
		print("Manifest file on disk has raw actions: " .. (hasRawInFile and "YES" or "NO"))
		if not hasRawInFile then
			print("  WARNING: Disk manifest is stale! Raw actions not written.")
			print("  Try: vrmod_bindingversion 0 then restart")
		end
	else
		print("Manifest file on disk: NOT FOUND")
	end

	local bindingVersion = GetConVar("vrmod_bindingversion")
	if bindingVersion then
		print("Binding version: " .. bindingVersion:GetInt())
	end
	print("")

	-- Debug system
	local debugEnabled = vrmod and vrmod.debug and vrmod.debug.enabled
	print("Debug system (vrmod_unoff_debug): " .. (debugEnabled and "ENABLED" or "disabled"))
	print("")
	print("========================================")
end)

-------------------------------------------------------------------------------
-- PUBLIC API (replaces old g_VR.advancedInput API for VR keyboard UIs)
-------------------------------------------------------------------------------

-- Gesture display / compaction helpers
local GESTURE_DISPLAY_NAME = {
	short_press  = "Short Press",
	long_press   = "Long Press",
	double_click = "Double Click",
	combo        = "Combo",
	passthrough  = "Hold",
}
local GESTURE_SHORT_CHAR = {
	short_press  = "S",
	long_press   = "L",
	double_click = "D",
	combo        = "C",
	passthrough  = "H",
}

function LKB.GetGestureDisplayName(g)
	return GESTURE_DISPLAY_NAME[g] or (g or "?")
end
function LKB.GetShortGestureChar(g)
	return GESTURE_SHORT_CHAR[g] or "?"
end

function LKB.GetShortRawName(raw)
	if not raw then return "?" end
	local s = tostring(raw)
	s = s:gsub("^raw_", "")
	s = s:gsub("^left_", "L-")
	s = s:gsub("^right_", "R-")
	s = s:gsub("_bool$", "")
	s = s:gsub("_stick_up",    "Stk↑")
	s = s:gsub("_stick_down",  "Stk↓")
	s = s:gsub("_stick_left",  "Stk←")
	s = s:gsub("_stick_right", "Stk→")
	s = s:gsub("_trigger",   "Trg")
	s = s:gsub("_grip",      "Grp")
	s = s:gsub("_", "")
	return s
end

function LKB.GetRawDisplayName(raw)
	if not raw then return "?" end
	return PrettyRawName(raw)
end

-- Enumerate all raw action names of type boolean.
function LKB.GetAvailableRawBooleans()
	RegisterSyntheticStickDirs()
	local out = {}
	local names = g_VR.rawActionNames or {}
	local types = g_VR.rawActionTypes or {}
	for _, name in ipairs(names) do
		if types[name] == "boolean" then out[#out + 1] = name end
	end
	table.sort(out)
	return out
end

-- Add a rule to a raw.
--   rawName: "raw_right_b"
--   gesture: "passthrough"|"short_press"|"long_press"|"double_click"|"combo"
--   kind:    "logical" | "key"
--   target:  logical name (string) or keycode (number)
--   opts:    table, e.g. { combo_partner = "raw_left_a", context = "on_foot"|"driving"|"both" }
function LKB.AddMapping(rawName, gesture, kind, target, opts)
	if not rawName or not target then return false end
	gesture = gesture or "passthrough"
	kind = kind or "logical"
	opts = opts or {}

	RegisterSyntheticStickDirs()
	if not g_VR.rawActionTypes or not g_VR.rawActionTypes[rawName] then
		print("[VRMod Keybinding] AddMapping: unknown raw: " .. tostring(rawName))
		return false
	end

	local rule = { target = target, trigger = gesture, kind = kind }
	if gesture == "combo" and opts.combo_partner then
		rule.combo_partner = opts.combo_partner
	end

	local ctx = opts.context or "on_foot"
	local function insertInto(mapTable)
		mapTable[rawName] = mapTable[rawName] or {}
		table.insert(mapTable[rawName], rule)
	end
	if ctx == "on_foot" or ctx == "both" then insertInto(LKB.mapping) end
	if ctx == "driving" or ctx == "both" then insertInto(LKB.drivingMapping) end
	SaveMappingToDisk()
	return true
end

-- Remove a rule by reverse-map entry. Accepts either:
--   rm table { raw, gesture, kind, target, context } — removes first match
--   integer index (legacy) — no-op, logs warning
function LKB.RemoveMapping(rm)
	if type(rm) == "number" then
		print("[VRMod Keybinding] RemoveMapping(index) is no longer supported; pass the rm table instead.")
		return false
	end
	if type(rm) ~= "table" or not rm.raw then return false end
	local ctx = rm.context or "on_foot"
	local function removeFrom(mapTable)
		local list = mapTable[rm.raw]
		if not list then return false end
		for i, rule in ipairs(list) do
			local ruleGesture = rule.trigger or "passthrough"
			local ruleKind = rule.kind or "logical"
			if rule.target == rm.target
				and ruleGesture == (rm.gesture or ruleGesture)
				and ruleKind == (rm.kind or ruleKind) then
				table.remove(list, i)
				if #list == 0 then mapTable[rm.raw] = nil end
				return true
			end
		end
		return false
	end
	local removed = false
	if ctx == "on_foot" or ctx == "both" then removed = removeFrom(LKB.mapping) or removed end
	if ctx == "driving" or ctx == "both" then removed = removeFrom(LKB.drivingMapping) or removed end
	if removed then SaveMappingToDisk() end
	return removed
end

function LKB.Save()
	SaveMappingToDisk()
end

-- Build reverse map: keycode -> list of {raw, gesture, kind, target, context}
-- Scans both on_foot and driving mappings; any rule with kind="key" is included.
function LKB.GetKeyReverseMap()
	local reverse = {}
	local function walk(mapTable, ctxName)
		for rawName, rules in pairs(mapTable or {}) do
			if type(rules) == "table" then
				for _, rule in ipairs(rules) do
					if (rule.kind or "logical") == "key" then
						local code = tonumber(rule.target)
						if code then
							reverse[code] = reverse[code] or {}
							table.insert(reverse[code], {
								raw = rawName,
								gesture = rule.trigger or "passthrough",
								kind = "key",
								target = code,
								context = ctxName,
								combo_partner = rule.combo_partner,
							})
						end
					end
				end
			end
		end
	end
	walk(LKB.mapping, "on_foot")
	walk(LKB.drivingMapping, "driving")
	return reverse
end

-------------------------------------------------------------------------------
-- STUB COMMANDS for deleted Advanced Input system.
-- Users who had `bind` lines in cfg files or scripts referencing these commands
-- get a clear message instead of a silent "Unknown command" error.
-------------------------------------------------------------------------------

local function AdvancedStub()
	print("[VRMod] Advanced Input has been merged into Lua Keybinding.")
	print("[VRMod] Use vrmod_keybinding_menu — gesture triggers (short/long/double/combo) are now available under the '+' button per raw.")
end

for _, cmd in ipairs({
	"vrmod_advanced_add", "vrmod_advanced_remove", "vrmod_advanced_list",
	"vrmod_advanced_clear", "vrmod_advanced_save", "vrmod_advanced_load",
	"vrmod_advanced_import_lkb", "vrmod_advanced_diag", "vrmod_advanced_input_menu",
}) do
	concommand.Add(cmd, AdvancedStub)
end

print("[VRMod Keybinding] Lua keybinding system loaded (vrmod_unoff_inputmode 0=SteamVR 1=Lua)")
