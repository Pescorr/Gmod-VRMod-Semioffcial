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
	end
end, "lkb_mode_trace")

-------------------------------------------------------------------------------
-- DEFAULT MAPPING TABLE
-- Maps raw physical actions → logical VRMod actions
-- Users can override this via saved config
-------------------------------------------------------------------------------

local DEFAULT_MAPPING = {
	-- Boolean mappings: raw_name → logical_name
	-- 10 physical buttons → the most essential actions
	-- Users can remap via vrmod_keybinding_set or Settings UI
	raw_right_trigger_bool = "boolean_primaryfire",
	raw_left_trigger_bool  = "boolean_left_primaryfire",
	raw_right_grip_bool    = "boolean_right_pickup",
	raw_left_grip_bool     = "boolean_left_pickup",
	raw_right_a            = "boolean_use",
	raw_right_b            = "boolean_spawnmenu",
	raw_left_a             = "boolean_jump",
	raw_left_b             = "boolean_changeweapon",
	raw_right_stick_click  = "boolean_sprint",
	raw_left_stick_click   = "boolean_crouch",

	-- Vector1 mappings: raw_name → logical_name
	raw_right_trigger_pull = "vector1_primaryfire",
	raw_left_trigger_pull  = "vector1_left_primaryfire",
	raw_right_grip_pull    = nil, -- available for custom mapping
	raw_left_grip_pull     = nil, -- available for custom mapping

	-- Vector2 mappings: raw_name → logical_name
	raw_left_stick         = "vector2_walkdirection",
	raw_right_stick        = "vector2_smoothturn",
}

-- Driving mode mapping (when in vehicle)
local DEFAULT_DRIVING_MAPPING = {
	raw_right_trigger_bool = "boolean_turret",
	raw_left_trigger_bool  = nil, -- vector1 handles this
	raw_right_grip_bool    = "boolean_right_pickup",
	raw_left_grip_bool     = "boolean_left_pickup",
	raw_right_a            = "boolean_handbrake",
	raw_right_b            = "boolean_turbo",
	raw_left_a             = "boolean_handbrake",
	raw_left_b             = "boolean_spawnmenu",
	raw_right_stick_click  = nil,
	raw_left_stick_click   = nil,

	raw_right_trigger_pull = "vector1_forward",
	raw_left_trigger_pull  = "vector1_reverse",

	raw_left_stick         = "vector2_steer",
	raw_right_stick        = "vector2_steer",
}

-------------------------------------------------------------------------------
-- ACTIVE MAPPING (loaded from config or defaults)
-------------------------------------------------------------------------------

LKB.mapping = LKB.mapping or {}
LKB.drivingMapping = LKB.drivingMapping or {}
LKB.prevRawBooleans = LKB.prevRawBooleans or {}

local function LoadMappingFromDisk()
	local json = file.Read("vrmod/vrmod_keybindings.txt", "DATA")
	if json then
		local data = util.JSONToTable(json)
		if data and data.mapping then
			LKB.mapping = data.mapping
			LKB.drivingMapping = data.drivingMapping or {}
			print("[VRMod Keybinding] Loaded custom keybindings from disk")
			return true
		end
	end
	return false
end

local function SaveMappingToDisk()
	local data = {
		mapping = LKB.mapping,
		drivingMapping = LKB.drivingMapping,
		version = 1,
	}
	if not file.Exists("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end
	file.Write("vrmod/vrmod_keybindings.txt", util.TableToJSON(data, true))
	print("[VRMod Keybinding] Saved keybindings to disk")
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

local function ProcessRawInput(input, changedInputs)
	if not input then return input, changedInputs end

	local inVehicle = g_VR and g_VR.active and LocalPlayer and LocalPlayer():InVehicle()
	local activeMapping = inVehicle and LKB.drivingMapping or LKB.mapping

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

	-- Build new input table: start with non-raw values cleared for mapped targets
	-- Then overwrite with mapped raw values
	local newChanged = {}

	-- Step 1: Map raw boolean actions → logical boolean actions
	for rawName, logicalName in pairs(activeMapping) do
		if not logicalName then continue end

		local rawType = g_VR.rawActionTypes and g_VR.rawActionTypes[rawName]
		if not rawType then continue end

		local rawValue = input[rawName]
		if rawValue == nil then continue end

		if rawType == "boolean" then
			-- Overwrite the logical action with raw value
			input[logicalName] = rawValue

			-- Track changes for VRMod_Input hook
			local prev = LKB.prevRawBooleans[rawName]
			if prev ~= rawValue then
				newChanged[logicalName] = rawValue
				LKB.prevRawBooleans[rawName] = rawValue
				-- Debug: log every state change (not throttled — these are events)
				DbgInfo("[LKB] MAPPED: %s (%s) -> %s = %s",
					rawName, rawType, logicalName, tostring(rawValue))
			end

		elseif rawType == "vector1" then
			input[logicalName] = rawValue

		elseif rawType == "vector2" then
			input[logicalName] = rawValue
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
	local origSetActive = VRMOD_SetActiveActionSets
	VRMOD_SetActiveActionSets = function(...)
		local mode = cv_inputmode:GetInt()
		if mode == 1 then
			local args = {...}
			-- Check if /actions/raw is already in the args
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
	print("[VRMod Keybinding] Reset to default mappings")
end)

concommand.Add("vrmod_keybinding_save", function()
	SaveMappingToDisk()
end)

concommand.Add("vrmod_keybinding_list", function()
	local mode = cv_inputmode:GetInt()
	print("=== VRMod Keybinding Config ===")
	print("Mode: " .. (mode == 1 and "Lua Keybinding" or "SteamVR"))
	print("")
	print("-- On Foot Mapping --")
	for raw, logical in SortedPairs(LKB.mapping) do
		print("  " .. raw .. " -> " .. tostring(logical))
	end
	print("")
	print("-- Driving Mapping --")
	for raw, logical in SortedPairs(LKB.drivingMapping) do
		print("  " .. raw .. " -> " .. tostring(logical))
	end
end)

concommand.Add("vrmod_keybinding_set", function(ply, cmd, args)
	if #args < 2 then
		print("Usage: vrmod_keybinding_set <raw_action> <logical_action>")
		print("  Example: vrmod_keybinding_set raw_right_a boolean_reload")
		print("  Use 'none' to unbind")
		return
	end
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
		LKB.mapping[rawName] = logicalName
		print("Mapped " .. rawName .. " -> " .. logicalName)
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
					local mapped = LKB.mapping[rawName] or "(unmapped)"
					if type(val) == "table" then
						lines[#lines + 1] = string.format("  %s: x=%.2f y=%.2f -> %s",
							rawName, val.x or 0, val.y or 0, mapped)
					elseif type(val) == "boolean" then
						lines[#lines + 1] = string.format("  %s: %s -> %s",
							rawName, val and "ON" or "off", mapped)
					else
						lines[#lines + 1] = string.format("  %s: %.3f -> %s",
							rawName, val, mapped)
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

concommand.Add("vrmod_keybinding_menu", function()
	if IsValid(LKB.menuFrame) then LKB.menuFrame:Remove() end

	local frame = vgui.Create("DFrame")
	frame:SetSize(640, 520)
	frame:Center()
	frame:SetTitle("VRMod Lua Keybinding Configuration")
	frame:MakePopup()
	frame:SetDeleteOnClose(true)
	LKB.menuFrame = frame

	-- Top bar: mode toggle
	local topBar = vgui.Create("DPanel", frame)
	topBar:Dock(TOP)
	topBar:SetTall(36)
	topBar:DockMargin(0, 0, 0, 4)
	topBar:SetPaintBackground(false)

	local modeLabel = vgui.Create("DLabel", topBar)
	modeLabel:SetPos(8, 8)
	modeLabel:SetText(L("Input Mode:", "Input Mode:"))
	modeLabel:SizeToContents()

	local modeCombo = vgui.Create("DComboBox", topBar)
	modeCombo:SetPos(100, 6)
	modeCombo:SetSize(200, 24)
	modeCombo:AddChoice("SteamVR Bindings (Default)", 0)
	modeCombo:AddChoice("Lua Keybinding (Recommended)", 1)
	modeCombo:SetValue(cv_inputmode:GetInt() == 1 and "Lua Keybinding (Recommended)" or "SteamVR Bindings (Default)")
	modeCombo.OnSelect = function(self, index, value, data)
		RunConsoleCommand("vrmod_unoff_inputmode", tostring(data))
	end

	local resetBtn = vgui.Create("DButton", topBar)
	resetBtn:SetPos(520, 6)
	resetBtn:SetSize(100, 24)
	resetBtn:SetText(L("Reset Defaults", "Reset Defaults"))
	resetBtn.DoClick = function()
		Derma_Query("Reset all keybindings to defaults?", "Confirm",
			"Yes", function()
				ResetToDefaults()
				-- Refresh the panel
				RunConsoleCommand("vrmod_keybinding_menu")
			end,
			"No", function() end
		)
	end

	-- Tab control for On Foot / Driving
	local tabs = vgui.Create("DPropertySheet", frame)
	tabs:Dock(FILL)

	-- Creates a mapping panel for a given mapping table
	local function CreateMappingPanel(parent, mappingTable, isDriving)
		local scroll = vgui.Create("DScrollPanel", parent)
		scroll:Dock(FILL)

		-- Header
		local header = vgui.Create("DPanel", scroll)
		header:Dock(TOP)
		header:SetTall(24)
		header:SetPaintBackground(false)

		local h1 = vgui.Create("DLabel", header)
		h1:SetPos(8, 4)
		h1:SetText(L("Physical Input", "Physical Input"))
		h1:SetFont("DermaDefaultBold")
		h1:SizeToContents()

		local h2 = vgui.Create("DLabel", header)
		h2:SetPos(260, 4)
		h2:SetText(L("Mapped To (Game Action)", "Mapped To (Game Action)"))
		h2:SetFont("DermaDefaultBold")
		h2:SizeToContents()

		-- Rows: one per raw action
		local rawNames = g_VR.rawActionNames or {}
		for _, rawName in ipairs(rawNames) do
			local rawType = g_VR.rawActionTypes and g_VR.rawActionTypes[rawName] or "boolean"

			local row = vgui.Create("DPanel", scroll)
			row:Dock(TOP)
			row:SetTall(28)
			row:DockMargin(0, 0, 0, 1)

			-- Display name
			local nameLabel = vgui.Create("DLabel", row)
			nameLabel:SetPos(8, 5)
			local displayName = rawName:gsub("^raw_", ""):gsub("_", " ")
			nameLabel:SetText(displayName .. "  [" .. rawType .. "]")
			nameLabel:SizeToContents()
			nameLabel:SetWide(240)

			-- Combo box for mapped action
			local combo = vgui.Create("DComboBox", row)
			combo:SetPos(260, 3)
			combo:SetSize(340, 22)

			-- Filter available actions by type compatibility
			for _, logicalName in ipairs(AVAILABLE_LOGICAL_ACTIONS) do
				if logicalName == "(none)" then
					combo:AddChoice("(none)", "")
				else
					-- Type compatibility check
					local logicalType = "boolean"
					if string.sub(logicalName, 1, 7) == "vector1" then logicalType = "vector1"
					elseif string.sub(logicalName, 1, 7) == "vector2" then logicalType = "vector2" end

					if logicalType == rawType then
						combo:AddChoice(logicalName, logicalName)
					end
				end
			end

			-- Set current value
			local currentMapping = mappingTable[rawName]
			if currentMapping then
				combo:SetValue(currentMapping)
			else
				combo:SetValue("(none)")
			end

			-- On change
			combo.OnSelect = function(self, index, value, data)
				if data == "" then
					mappingTable[rawName] = nil
				else
					mappingTable[rawName] = data
				end
				SaveMappingToDisk()
			end
		end

		return scroll
	end

	-- On Foot tab
	local footPanel = vgui.Create("DPanel")
	footPanel:SetPaintBackground(false)
	CreateMappingPanel(footPanel, LKB.mapping, false)
	tabs:AddSheet("On Foot", footPanel, "icon16/user.png")

	-- Driving tab
	local drivePanel = vgui.Create("DPanel")
	drivePanel:SetPaintBackground(false)
	CreateMappingPanel(drivePanel, LKB.drivingMapping, true)
	tabs:AddSheet("In Vehicle", drivePanel, "icon16/car.png")
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

	-- Current mapping
	local mapCount = table.Count(LKB.mapping or {})
	local driveMapCount = table.Count(LKB.drivingMapping or {})
	print("On-foot mapping entries: " .. mapCount)
	print("Driving mapping entries: " .. driveMapCount)
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

print("[VRMod Keybinding] Lua keybinding system loaded (vrmod_unoff_inputmode 0=SteamVR 1=Lua)")
