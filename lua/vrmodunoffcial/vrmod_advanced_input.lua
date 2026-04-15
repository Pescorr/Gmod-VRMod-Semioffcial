if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

--[[
	vrmod_advanced_input.lua
	Advanced VR Input Processor

	Provides:
	  - Raw VR button → Keyboard key direct mapping (bypassing logical actions)
	  - Gesture detection: short_press, long_press, double_click, combo
	  - Both "raw → key" and "raw → logical action" targets per gesture
	  - Coexists with existing Lua Keybinding system

	Load order: this file loads BEFORE vrmod_lua_keybinding.lua (alphabetical).
	Registers itself at g_VR.advancedInput for integration.

	Config stored at: data/vrmod/vrmod_advanced_input.txt (JSON)
]]

g_VR = g_VR or {}

local TAG = "[VRMod AdvInput] "

-------------------------------------------------------------------------------
-- DEBUG LOGGING
-------------------------------------------------------------------------------

local Log
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

-------------------------------------------------------------------------------
-- ConVars
-------------------------------------------------------------------------------

local cv_enabled = CreateClientConVar("vrmod_unoff_advanced_input", "0", true, false,
	"Enable advanced input processor (gesture detection + direct key mapping)", 0, 1)

local cv_disableSteamVR = CreateClientConVar("vrmod_unoff_disable_steamvr_input", "0", true, false,
	"When Lua mode active, disable SteamVR /actions/main and /actions/driving entirely", 0, 1)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local CONFIG_PATH = "vrmod/vrmod_advanced_input.txt"
local CONFIG_VERSION = 1

-- Gesture types
local GESTURE_SHORT    = "short_press"
local GESTURE_LONG     = "long_press"
local GESTURE_DOUBLE   = "double_click"
local GESTURE_COMBO    = "combo"

-- Default timing (ms)
local DEFAULT_LONG_MS   = 500
local DEFAULT_DOUBLE_MS = 300

-- State machine states
local ST_IDLE         = 0
local ST_PRESSED      = 1
local ST_HELD         = 2
local ST_WAIT_DOUBLE  = 3

-- Context
local CTX_ONFOOT  = "on_foot"
local CTX_DRIVING = "driving"
local CTX_BOTH    = "both"

-------------------------------------------------------------------------------
-- MODULE STATE
-------------------------------------------------------------------------------

local AI = {}  -- module table, registered as g_VR.advancedInput

AI.mappings = {}         -- flat list of mapping rules (loaded from disk)
AI.rawIndex = {}         -- rawIndex[rawName][gesture] = { mapping, ... }
AI.buttonState = {}      -- per-button state machine
AI.activeKeyTargets = {} -- currently held keyboard keys { [buttonCode] = count }

-------------------------------------------------------------------------------
-- CONFIG LOAD / SAVE
-------------------------------------------------------------------------------

local function LoadConfig()
	if not file.Exists(CONFIG_PATH, "DATA") then
		AI.mappings = {}
		return
	end

	local raw = file.Read(CONFIG_PATH, "DATA")
	if not raw or raw == "" then
		AI.mappings = {}
		return
	end

	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not data then
		DbgWarn("Failed to parse config: %s", CONFIG_PATH)
		AI.mappings = {}
		return
	end

	AI.mappings = data.mappings or {}
	-- Restore ConVar state from config
	if data.disableSteamVRNonRaw ~= nil then
		cv_disableSteamVR:SetBool(data.disableSteamVRNonRaw)
	end

	print(TAG .. "Loaded " .. #AI.mappings .. " mapping rules")
end

local function SaveConfig()
	local data = {
		version = CONFIG_VERSION,
		enabled = cv_enabled:GetBool(),
		disableSteamVRNonRaw = cv_disableSteamVR:GetBool(),
		mappings = AI.mappings,
	}

	file.CreateDir("vrmod")
	file.Write(CONFIG_PATH, util.TableToJSON(data, true))
	print(TAG .. "Saved " .. #AI.mappings .. " mapping rules")
end

-------------------------------------------------------------------------------
-- INDEX BUILDER
-- Builds rawIndex from flat mappings list for O(1) lookup per frame
-------------------------------------------------------------------------------

local function BuildIndex()
	AI.rawIndex = {}
	AI.buttonState = {}

	for _, m in ipairs(AI.mappings) do
		local rawName = m.raw
		if not rawName then continue end

		if not AI.rawIndex[rawName] then
			AI.rawIndex[rawName] = {}
		end

		local gesture = m.gesture or GESTURE_SHORT
		if not AI.rawIndex[rawName][gesture] then
			AI.rawIndex[rawName][gesture] = {}
		end

		table.insert(AI.rawIndex[rawName][gesture], m)

		-- Initialize button state
		if not AI.buttonState[rawName] then
			AI.buttonState[rawName] = {
				physical = false,
				pressTime = 0,
				releaseTime = 0,
				pressCount = 0,
				longFired = false,
				state = ST_IDLE,
			}
		end
	end

	DbgInfo("Built index: %d raw buttons with advanced mappings", table.Count(AI.rawIndex))
end

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

local function IsInContext(mapping)
	local ctx = mapping.context or CTX_BOTH
	if ctx == CTX_BOTH then return true end

	local inVehicle = g_VR and g_VR.active and LocalPlayer and IsValid(LocalPlayer()) and LocalPlayer():InVehicle()
	if ctx == CTX_DRIVING then return inVehicle end
	if ctx == CTX_ONFOOT then return not inVehicle end
	return true
end

local function GetLongMs(mapping)
	return (mapping.long_press_ms or DEFAULT_LONG_MS) / 1000
end

local function GetDoubleMs(mapping)
	return (mapping.double_click_ms or DEFAULT_DOUBLE_MS) / 1000
end

-- Check if a raw button has any mappings of a given gesture type (in current context)
local function HasGesture(rawName, gesture)
	local idx = AI.rawIndex[rawName]
	if not idx or not idx[gesture] then return false end
	for _, m in ipairs(idx[gesture]) do
		if IsInContext(m) then return true end
	end
	return false
end

-- Get the shortest long_press threshold for a raw button
local function GetMinLongThreshold(rawName)
	local idx = AI.rawIndex[rawName]
	if not idx or not idx[GESTURE_LONG] then return DEFAULT_LONG_MS / 1000 end
	local minT = 999
	for _, m in ipairs(idx[GESTURE_LONG]) do
		if IsInContext(m) then
			local t = GetLongMs(m)
			if t < minT then minT = t end
		end
	end
	return minT
end

-- Get the longest double_click window for a raw button
local function GetMaxDoubleWindow(rawName)
	local idx = AI.rawIndex[rawName]
	if not idx or not idx[GESTURE_DOUBLE] then return DEFAULT_DOUBLE_MS / 1000 end
	local maxT = 0
	for _, m in ipairs(idx[GESTURE_DOUBLE]) do
		if IsInContext(m) then
			local t = GetDoubleMs(m)
			if t > maxT then maxT = t end
		end
	end
	return maxT
end

-------------------------------------------------------------------------------
-- TARGET FIRING
-------------------------------------------------------------------------------

-- Fire a keyboard key target (press or release)
local function FireKeyTarget(buttonCode, pressed)
	if not vrmod or not vrmod.InputEmu_SetKeyDual then return end

	if pressed then
		AI.activeKeyTargets[buttonCode] = (AI.activeKeyTargets[buttonCode] or 0) + 1
		vrmod.InputEmu_SetKeyDual(buttonCode, true)
	else
		local count = AI.activeKeyTargets[buttonCode] or 0
		count = count - 1
		if count <= 0 then
			AI.activeKeyTargets[buttonCode] = nil
			vrmod.InputEmu_SetKeyDual(buttonCode, nil)
		else
			AI.activeKeyTargets[buttonCode] = count
		end
	end
end

-- Fire a logical action target by injecting into input/changedInputs tables
local function FireLogicalTarget(actionName, pressed, input, changedInputs)
	input[actionName] = pressed
	changedInputs[actionName] = pressed
end

-- Fire all mappings for a given raw button + gesture
local function FireGesture(rawName, gesture, pressed, input, changedInputs)
	local idx = AI.rawIndex[rawName]
	if not idx or not idx[gesture] then return end

	for _, m in ipairs(idx[gesture]) do
		if not IsInContext(m) then continue end

		if m.target_type == "key" then
			local code = tonumber(m.target)
			if code and code > 0 then
				FireKeyTarget(code, pressed)
			end
		elseif m.target_type == "logical" then
			FireLogicalTarget(m.target, pressed, input, changedInputs)
		end
	end
end

-- Tap (momentary press+release) for double_click gesture
local function TapGesture(rawName, gesture, input, changedInputs)
	local idx = AI.rawIndex[rawName]
	if not idx or not idx[gesture] then return end

	for _, m in ipairs(idx[gesture]) do
		if not IsInContext(m) then continue end

		if m.target_type == "key" then
			local code = tonumber(m.target)
			if code and code > 0 and vrmod and vrmod.InputEmu_TapKey then
				vrmod.InputEmu_TapKey(code)
			end
		elseif m.target_type == "logical" then
			-- Inject as pressed, then schedule release next frame
			input[m.target] = true
			changedInputs[m.target] = true
			timer.Simple(0, function()
				-- Will be cleaned up by next ProcessRawInput cycle
			end)
		end
	end
end

-------------------------------------------------------------------------------
-- GESTURE STATE MACHINE
-- Called per-frame for each raw boolean button that has advanced mappings
-------------------------------------------------------------------------------

local function ProcessButton(rawName, rawValue, now, input, changedInputs)
	local bs = AI.buttonState[rawName]
	if not bs then return end

	local prevPhysical = bs.physical
	bs.physical = rawValue

	local hasShort  = HasGesture(rawName, GESTURE_SHORT)
	local hasLong   = HasGesture(rawName, GESTURE_LONG)
	local hasDouble = HasGesture(rawName, GESTURE_DOUBLE)
	local hasCombo  = HasGesture(rawName, GESTURE_COMBO)

	-- Shortcut: if only short_press and no other gestures, use direct pass-through
	if hasShort and not hasLong and not hasDouble and not hasCombo then
		if rawValue ~= prevPhysical then
			FireGesture(rawName, GESTURE_SHORT, rawValue, input, changedInputs)
		end
		return
	end

	-- === COMBO CHECK ===
	-- On press, check if this button has combo mappings with a partner that's held
	if rawValue and not prevPhysical and hasCombo then
		local idx = AI.rawIndex[rawName]
		if idx and idx[GESTURE_COMBO] then
			for _, m in ipairs(idx[GESTURE_COMBO]) do
				if not IsInContext(m) then continue end
				local partner = m.combo_partner
				if partner and AI.buttonState[partner] and AI.buttonState[partner].physical then
					-- Combo triggered: fire it and skip normal gesture processing
					FireGesture(rawName, GESTURE_COMBO, true, input, changedInputs)
					bs.state = ST_HELD
					bs.longFired = false
					bs._comboFired = true
					return
				end
			end
		end
	end

	-- On release after combo, clean up
	if not rawValue and prevPhysical and bs._comboFired then
		FireGesture(rawName, GESTURE_COMBO, false, input, changedInputs)
		bs._comboFired = false
		bs.state = ST_IDLE
		return
	end

	-- === STATE MACHINE ===
	if bs.state == ST_IDLE then
		if rawValue and not prevPhysical then
			-- Button just pressed
			bs.pressTime = now
			bs.longFired = false

			if hasLong or hasDouble then
				-- Need to wait to determine gesture type
				bs.state = ST_PRESSED
			else
				-- Only short_press (already handled above, but safety fallback)
				FireGesture(rawName, GESTURE_SHORT, true, input, changedInputs)
				bs.state = ST_HELD
			end
		end

	elseif bs.state == ST_PRESSED then
		if not rawValue and prevPhysical then
			-- Released before long_press threshold
			if hasDouble then
				-- Go to WAIT_DOUBLE to see if second press comes
				bs.releaseTime = now
				bs.pressCount = (bs.pressCount or 0) + 1
				bs.state = ST_WAIT_DOUBLE
			else
				-- No double_click possible; this was a short press
				-- Fire as momentary (press+release in same logical frame)
				if hasShort then
					FireGesture(rawName, GESTURE_SHORT, true, input, changedInputs)
					-- Schedule release next frame
					local rn = rawName
					timer.Simple(0, function()
						if AI.rawIndex[rn] then
							-- Use empty tables for deferred release - no input injection needed
							-- The VRMod_Input hook already got the press event
							FireGesture(rn, GESTURE_SHORT, false, {}, {})
						end
					end)
				end
				bs.state = ST_IDLE
			end

		elseif rawValue then
			-- Still held, check for long_press threshold
			if hasLong and not bs.longFired then
				local threshold = GetMinLongThreshold(rawName)
				if (now - bs.pressTime) >= threshold then
					FireGesture(rawName, GESTURE_LONG, true, input, changedInputs)
					bs.longFired = true
					bs.state = ST_HELD

					-- If short_press + long_press coexist and short hasn't fired yet,
					-- the user held long enough → don't fire short at all
				end
			end
		end

	elseif bs.state == ST_HELD then
		if not rawValue and prevPhysical then
			-- Released after being held
			if bs.longFired then
				FireGesture(rawName, GESTURE_LONG, false, input, changedInputs)
			end
			bs.longFired = false
			bs.state = ST_IDLE
		end

	elseif bs.state == ST_WAIT_DOUBLE then
		if rawValue and not prevPhysical then
			-- Second press within window → double_click!
			local window = GetMaxDoubleWindow(rawName)
			if (now - bs.releaseTime) <= window then
				TapGesture(rawName, GESTURE_DOUBLE, input, changedInputs)
				bs.pressCount = 0
				bs.state = ST_IDLE
			else
				-- Too slow, treat as new short_press
				bs.pressCount = 0
				bs.pressTime = now
				if hasLong then
					bs.state = ST_PRESSED
				else
					if hasShort then
						FireGesture(rawName, GESTURE_SHORT, true, input, changedInputs)
					end
					bs.state = ST_HELD
				end
			end

		elseif not rawValue then
			-- Still released, check timeout
			local window = GetMaxDoubleWindow(rawName)
			if (now - bs.releaseTime) > window then
				-- Timeout: fire delayed short_press
				if hasShort then
					FireGesture(rawName, GESTURE_SHORT, true, input, changedInputs)
					local rn = rawName
					timer.Simple(0, function()
						if AI.rawIndex[rn] then
							FireGesture(rn, GESTURE_SHORT, false, {}, {})
						end
					end)
				end
				bs.pressCount = 0
				bs.state = ST_IDLE
			end
		end
	end
end

-------------------------------------------------------------------------------
-- MAIN PROCESS FUNCTION
-- Called from ProcessRawInput() in vrmod_lua_keybinding.lua
-- Returns: input, changedInputs (with consumed raw buttons removed)
-- Also returns set of consumed raw names
-------------------------------------------------------------------------------

function AI.Process(input, changedInputs)
	if not input then return input, changedInputs, {} end
	if not cv_enabled:GetBool() then return input, changedInputs, {} end

	local now = CurTime()
	local consumed = {}

	-- Process each raw button that has advanced mappings
	for rawName, _ in pairs(AI.rawIndex) do
		local rawType = g_VR.rawActionTypes and g_VR.rawActionTypes[rawName]
		if rawType ~= "boolean" then continue end  -- only boolean for gesture detection

		local rawValue = input[rawName]
		if rawValue == nil then
			-- Button might not be in input this frame, use last known state
			rawValue = AI.buttonState[rawName] and AI.buttonState[rawName].physical or false
		end

		ProcessButton(rawName, rawValue, now, input, changedInputs)
		consumed[rawName] = true
	end

	-- Also handle WAIT_DOUBLE timeouts for buttons that have no new input this frame
	for rawName, bs in pairs(AI.buttonState) do
		if not consumed[rawName] and bs.state == ST_WAIT_DOUBLE then
			ProcessButton(rawName, false, now, input, changedInputs)
		end
	end

	return input, changedInputs, consumed
end

-------------------------------------------------------------------------------
-- STEAMVR DISABLE CHECK (called from keybinding's SetActiveActionSets patch)
-------------------------------------------------------------------------------

function AI.ShouldDisableSteamVRActions()
	return cv_enabled:GetBool() and cv_disableSteamVR:GetBool()
end

-------------------------------------------------------------------------------
-- PUBLIC API (for UI and console commands)
-------------------------------------------------------------------------------

function AI.AddMapping(raw, gesture, targetType, target, opts)
	opts = opts or {}
	local m = {
		raw = raw,
		gesture = gesture or GESTURE_SHORT,
		target_type = targetType,
		target = target,
		long_press_ms = opts.long_press_ms or DEFAULT_LONG_MS,
		double_click_ms = opts.double_click_ms or DEFAULT_DOUBLE_MS,
		combo_partner = opts.combo_partner,
		context = opts.context or CTX_BOTH,
	}
	table.insert(AI.mappings, m)
	BuildIndex()
	return m
end

function AI.RemoveMapping(index)
	if AI.mappings[index] then
		table.remove(AI.mappings, index)
		BuildIndex()
		return true
	end
	return false
end

function AI.ClearMappings()
	AI.mappings = {}
	BuildIndex()
end

function AI.GetMappings()
	return AI.mappings
end

function AI.Save()
	SaveConfig()
end

function AI.Load()
	LoadConfig()
	BuildIndex()
end

function AI.IsEnabled()
	return cv_enabled:GetBool()
end

-- Import from existing Lua Keybinding (creates short_press rules for each mapping)
function AI.ImportFromLuaKeybinding()
	local LKB = g_VR.luaKeybinding
	if not LKB then
		print(TAG .. "Lua Keybinding not loaded")
		return 0
	end

	local count = 0

	-- Import on_foot mappings
	if LKB.mapping then
		for rawName, logicalName in pairs(LKB.mapping) do
			if logicalName and logicalName ~= "" then
				AI.AddMapping(rawName, GESTURE_SHORT, "logical", logicalName, { context = CTX_ONFOOT })
				count = count + 1
			end
		end
	end

	-- Import driving mappings
	if LKB.drivingMapping then
		for rawName, logicalName in pairs(LKB.drivingMapping) do
			if logicalName and logicalName ~= "" then
				AI.AddMapping(rawName, GESTURE_SHORT, "logical", logicalName, { context = CTX_DRIVING })
				count = count + 1
			end
		end
	end

	BuildIndex()
	print(TAG .. "Imported " .. count .. " rules from Lua Keybinding")
	return count
end

-- Get human-readable name for a raw action
function AI.GetRawDisplayName(rawName)
	local names = {
		raw_left_trigger_bool  = "L Trigger",
		raw_left_grip_bool     = "L Grip",
		raw_left_stick_click   = "L Stick Click",
		raw_left_a             = "L A Button",
		raw_left_b             = "L B Button",
		raw_right_trigger_bool = "R Trigger",
		raw_right_grip_bool    = "R Grip",
		raw_right_stick_click  = "R Stick Click",
		raw_right_a            = "R A Button",
		raw_right_b            = "R B Button",
	}
	return names[rawName] or rawName
end

function AI.GetGestureDisplayName(gesture)
	local names = {
		[GESTURE_SHORT]  = L("Short Press", "Short Press"),
		[GESTURE_LONG]   = L("Long Press", "Long Press"),
		[GESTURE_DOUBLE] = L("Double Click", "Double Click"),
		[GESTURE_COMBO]  = L("Combo", "Combo"),
	}
	return names[gesture] or gesture
end

-- Get list of available boolean raw actions
function AI.GetAvailableRawBooleans()
	local result = {}
	if g_VR.rawActionTypes then
		for name, typ in pairs(g_VR.rawActionTypes) do
			if typ == "boolean" then
				table.insert(result, name)
			end
		end
	end
	table.sort(result)
	return result
end

-- Get list of known logical actions (from VRMod_Input hook targets)
function AI.GetAvailableLogicalActions()
	return {
		"boolean_primaryfire", "boolean_secondaryfire",
		"boolean_left_primaryfire", "boolean_left_secondaryfire",
		"boolean_reload", "boolean_use",
		"boolean_flashlight", "boolean_sprint",
		"boolean_jump", "boolean_crouch",
		"boolean_walkkey", "boolean_forword", "boolean_back",
		"boolean_left", "boolean_right",
		"boolean_undo", "boolean_chat",
		"boolean_menucontext", "boolean_spawnmenu",
		"boolean_changeweapon",
		"boolean_left_pickup", "boolean_right_pickup",
		"boolean_teleport",
		"boolean_slot1", "boolean_slot2", "boolean_slot3",
		"boolean_slot4", "boolean_slot5", "boolean_slot6",
		"boolean_invnext", "boolean_invprev",
		"boolean_turret", "boolean_handbrake", "boolean_turbo",
		"boolean_lefthandmode", "boolean_righthandmode",
	}
end

-------------------------------------------------------------------------------
-- KEYBOARD UI SUPPORT
-- Reverse map and short display names for keyboard assignment UI
-------------------------------------------------------------------------------

-- Returns { [BUTTON_CODE] = { {raw=rawName, gesture=gesture, index=i}, ... } }
function AI.GetKeyReverseMap()
	local reverse = {}
	for i, m in ipairs(AI.mappings) do
		if m.target_type == "key" then
			local code = tonumber(m.target)
			if code and code > 0 then
				if not reverse[code] then reverse[code] = {} end
				table.insert(reverse[code], {
					raw = m.raw,
					gesture = m.gesture or GESTURE_SHORT,
					index = i,
				})
			end
		end
	end
	return reverse
end

-- Short raw button name for key face display (3-5 chars)
function AI.GetShortRawName(rawName)
	local short = {
		raw_left_trigger_bool  = "LTrig",
		raw_left_grip_bool     = "LGrip",
		raw_left_stick_click   = "LStk",
		raw_left_a             = "LA",
		raw_left_b             = "LB",
		raw_right_trigger_bool = "RTrig",
		raw_right_grip_bool    = "RGrip",
		raw_right_stick_click  = "RStk",
		raw_right_a            = "RA",
		raw_right_b            = "RB",
	}
	return short[rawName] or rawName
end

-- Single character for gesture type
function AI.GetShortGestureChar(gesture)
	local chars = {
		[GESTURE_SHORT]  = "S",
		[GESTURE_LONG]   = "L",
		[GESTURE_DOUBLE] = "D",
		[GESTURE_COMBO]  = "C",
	}
	return chars[gesture] or "?"
end

-------------------------------------------------------------------------------
-- CLEANUP on VR exit
-------------------------------------------------------------------------------

hook.Add("VRMod_Exit", "vrmod_advanced_input_cleanup", function()
	-- Release all held keyboard keys
	for code, _ in pairs(AI.activeKeyTargets) do
		if vrmod and vrmod.InputEmu_SetKeyDual then
			vrmod.InputEmu_SetKeyDual(code, nil)
		end
	end
	AI.activeKeyTargets = {}

	-- Reset all button states
	for _, bs in pairs(AI.buttonState) do
		bs.physical = false
		bs.state = ST_IDLE
		bs.longFired = false
		bs.pressCount = 0
		bs._comboFired = false
	end
end)

-------------------------------------------------------------------------------
-- CONSOLE COMMANDS
-------------------------------------------------------------------------------

concommand.Add("vrmod_advanced_add", function(_, _, args)
	if #args < 4 then
		print("Usage: vrmod_advanced_add <raw_action> <gesture> <target_type> <target> [long_ms] [double_ms] [combo_partner] [context]")
		print("  gesture: short_press, long_press, double_click, combo")
		print("  target_type: key, logical")
		print("  target: BUTTON_CODE number (for key) or action name (for logical)")
		print("  context: on_foot, driving, both (default: both)")
		return
	end

	local raw = args[1]
	local gesture = args[2]
	local targetType = args[3]
	local target = targetType == "key" and tonumber(args[4]) or args[4]
	local opts = {
		long_press_ms = tonumber(args[5]) or DEFAULT_LONG_MS,
		double_click_ms = tonumber(args[6]) or DEFAULT_DOUBLE_MS,
		combo_partner = args[7] ~= "" and args[7] or nil,
		context = args[8] or CTX_BOTH,
	}

	local m = AI.AddMapping(raw, gesture, targetType, target, opts)
	print(TAG .. string.format("Added: %s [%s] -> %s:%s", raw, gesture, targetType, tostring(target)))
end)

concommand.Add("vrmod_advanced_remove", function(_, _, args)
	local idx = tonumber(args[1])
	if not idx then
		print("Usage: vrmod_advanced_remove <index>")
		return
	end
	if AI.RemoveMapping(idx) then
		print(TAG .. "Removed mapping #" .. idx)
	else
		print(TAG .. "Invalid index: " .. idx)
	end
end)

concommand.Add("vrmod_advanced_list", function()
	print(TAG .. "=== Advanced Input Mappings ===")
	print(TAG .. "Enabled: " .. tostring(cv_enabled:GetBool()))
	print(TAG .. "SteamVR disable: " .. tostring(cv_disableSteamVR:GetBool()))
	if #AI.mappings == 0 then
		print(TAG .. "(no mappings)")
		return
	end
	for i, m in ipairs(AI.mappings) do
		local targetStr = m.target_type == "key"
			and ("KEY " .. tostring(m.target))
			or m.target
		local extra = ""
		if m.gesture == GESTURE_LONG then
			extra = string.format(" (%dms)", m.long_press_ms or DEFAULT_LONG_MS)
		elseif m.gesture == GESTURE_DOUBLE then
			extra = string.format(" (%dms)", m.double_click_ms or DEFAULT_DOUBLE_MS)
		elseif m.gesture == GESTURE_COMBO and m.combo_partner then
			extra = " + " .. m.combo_partner
		end
		print(string.format("  #%d: %s [%s%s] -> %s:%s (%s)",
			i, m.raw, m.gesture, extra, m.target_type, targetStr, m.context or CTX_BOTH))
	end
end)

concommand.Add("vrmod_advanced_clear", function()
	AI.ClearMappings()
	print(TAG .. "All mappings cleared")
end)

concommand.Add("vrmod_advanced_save", function()
	AI.Save()
end)

concommand.Add("vrmod_advanced_load", function()
	AI.Load()
end)

concommand.Add("vrmod_advanced_import_lkb", function()
	AI.ImportFromLuaKeybinding()
end)

concommand.Add("vrmod_advanced_diag", function()
	print(TAG .. "=== Diagnostics ===")
	print(TAG .. "Enabled: " .. tostring(cv_enabled:GetBool()))
	print(TAG .. "SteamVR disable: " .. tostring(cv_disableSteamVR:GetBool()))
	print(TAG .. "Total mappings: " .. #AI.mappings)
	print(TAG .. "Indexed raw buttons: " .. table.Count(AI.rawIndex))
	print(TAG .. "Active key targets: " .. table.Count(AI.activeKeyTargets))
	print(TAG .. "Button states:")
	for name, bs in pairs(AI.buttonState) do
		local stateNames = { [ST_IDLE] = "IDLE", [ST_PRESSED] = "PRESSED", [ST_HELD] = "HELD", [ST_WAIT_DOUBLE] = "WAIT_DBL" }
		print(string.format("  %s: state=%s physical=%s longFired=%s",
			name, stateNames[bs.state] or "?", tostring(bs.physical), tostring(bs.longFired)))
	end
	print(TAG .. "InputEmu available: " .. tostring(vrmod and vrmod.InputEmu_SetKeyDual ~= nil))
	print(TAG .. "InputEmu C++ available: " .. tostring(vrmod and vrmod.InputEmu_IsCppAvailable and pcall(vrmod.InputEmu_IsCppAvailable) and vrmod.InputEmu_IsCppAvailable()))
end)

-------------------------------------------------------------------------------
-- REGISTER & INITIALIZE
-------------------------------------------------------------------------------

g_VR.advancedInput = AI

-- Load config on startup
LoadConfig()
BuildIndex()

print(TAG .. "Module loaded (" .. #AI.mappings .. " rules)")
