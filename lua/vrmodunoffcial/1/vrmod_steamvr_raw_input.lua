if SERVER then return end

--[[
	vrmod_steamvr_raw_input.lua
	Loads AFTER vrmod_steamvr_bindings.lua (alphabetical order: "raw" > "bindings")

	Purpose:
	- Injects raw physical input actions into the action manifest
	- Injects raw binding sections into each controller's binding JSON
	- Enables "Lua Keybinding Mode" where SteamVR passes raw buttons
	  and Lua handles all input mapping

	Added in: semiofficial module v101 (S28)
]]

g_VR = g_VR or {}

-------------------------------------------------------------------------------
-- 1. RAW ACTION DEFINITIONS
-------------------------------------------------------------------------------

-- 16 raw actions: 8 per hand (trigger, grip, stick, stick_click, a, b + 2 analog)
local RAW_ACTIONS_JSON = [[
		,

		{
			"name": "/actions/raw/in/raw_left_trigger_bool",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_left_trigger_pull",
			"type": "vector1"
		},
		{
			"name": "/actions/raw/in/raw_left_grip_bool",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_left_grip_pull",
			"type": "vector1"
		},
		{
			"name": "/actions/raw/in/raw_left_stick",
			"type": "vector2"
		},
		{
			"name": "/actions/raw/in/raw_left_stick_click",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_left_a",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_left_b",
			"type": "boolean"
		},

		{
			"name": "/actions/raw/in/raw_right_trigger_bool",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_right_trigger_pull",
			"type": "vector1"
		},
		{
			"name": "/actions/raw/in/raw_right_grip_bool",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_right_grip_pull",
			"type": "vector1"
		},
		{
			"name": "/actions/raw/in/raw_right_stick",
			"type": "vector2"
		},
		{
			"name": "/actions/raw/in/raw_right_stick_click",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_right_a",
			"type": "boolean"
		},
		{
			"name": "/actions/raw/in/raw_right_b",
			"type": "boolean"
		}]]

-- Additional action set for raw
local RAW_ACTIONSET_JSON = [[
		,
		{
			"name": "/actions/raw",
			"usage": "leftright"
		}]]

-- Localization entries for raw actions
local RAW_LOCALIZATION_JSON = [[
			,
			"/actions/raw" : "Raw Input",
			"/actions/raw/in/raw_left_trigger_bool" : "Left Trigger (Digital)",
			"/actions/raw/in/raw_left_trigger_pull" : "Left Trigger (Analog)",
			"/actions/raw/in/raw_left_grip_bool" : "Left Grip (Digital)",
			"/actions/raw/in/raw_left_grip_pull" : "Left Grip (Analog)",
			"/actions/raw/in/raw_left_stick" : "Left Stick/Pad",
			"/actions/raw/in/raw_left_stick_click" : "Left Stick/Pad Click",
			"/actions/raw/in/raw_left_a" : "Left A/X Button",
			"/actions/raw/in/raw_left_b" : "Left B/Y Button",
			"/actions/raw/in/raw_right_trigger_bool" : "Right Trigger (Digital)",
			"/actions/raw/in/raw_right_trigger_pull" : "Right Trigger (Analog)",
			"/actions/raw/in/raw_right_grip_bool" : "Right Grip (Digital)",
			"/actions/raw/in/raw_right_grip_pull" : "Right Grip (Analog)",
			"/actions/raw/in/raw_right_stick" : "Right Stick/Pad",
			"/actions/raw/in/raw_right_stick_click" : "Right Stick/Pad Click",
			"/actions/raw/in/raw_right_a" : "Right A/X Button",
			"/actions/raw/in/raw_right_b" : "Right B/Y Button"]]

-------------------------------------------------------------------------------
-- 2. RAW BINDING SECTIONS PER CONTROLLER
-------------------------------------------------------------------------------

-- Helper: generates the /actions/raw binding JSON for a controller
-- stick_path: "thumbstick" for Index/Oculus/HP, "trackpad" for Vive
-- grip_mode: "trigger" for most, works for Index force sensor too
-- a_path/b_path: controller-specific button paths
local function MakeRawBindings(stick_path, a_left, b_left, a_right, b_right)
	return string.format([[
         "/actions/raw" : {
            "sources" : [
               {
                  "inputs" : {
                     "click" : { "output" : "/actions/raw/in/raw_left_trigger_bool" },
                     "pull" : { "output" : "/actions/raw/in/raw_left_trigger_pull" }
                  },
                  "mode" : "trigger",
                  "path" : "/user/hand/left/input/trigger"
               },
               {
                  "inputs" : {
                     "click" : { "output" : "/actions/raw/in/raw_left_grip_bool" },
                     "pull" : { "output" : "/actions/raw/in/raw_left_grip_pull" }
                  },
                  "mode" : "trigger",
                  "path" : "/user/hand/left/input/grip"
               },
               {
                  "inputs" : {
                     "position" : { "output" : "/actions/raw/in/raw_left_stick" },
                     "click" : { "output" : "/actions/raw/in/raw_left_stick_click" }
                  },
                  "mode" : "joystick",
                  "path" : "/user/hand/left/input/%s"
               },
               {
                  "inputs" : { "click" : { "output" : "/actions/raw/in/raw_left_a" } },
                  "mode" : "button",
                  "path" : "%s"
               },
               {
                  "inputs" : { "click" : { "output" : "/actions/raw/in/raw_left_b" } },
                  "mode" : "button",
                  "path" : "%s"
               },
               {
                  "inputs" : {
                     "click" : { "output" : "/actions/raw/in/raw_right_trigger_bool" },
                     "pull" : { "output" : "/actions/raw/in/raw_right_trigger_pull" }
                  },
                  "mode" : "trigger",
                  "path" : "/user/hand/right/input/trigger"
               },
               {
                  "inputs" : {
                     "click" : { "output" : "/actions/raw/in/raw_right_grip_bool" },
                     "pull" : { "output" : "/actions/raw/in/raw_right_grip_pull" }
                  },
                  "mode" : "trigger",
                  "path" : "/user/hand/right/input/grip"
               },
               {
                  "inputs" : {
                     "position" : { "output" : "/actions/raw/in/raw_right_stick" },
                     "click" : { "output" : "/actions/raw/in/raw_right_stick_click" }
                  },
                  "mode" : "joystick",
                  "path" : "/user/hand/right/input/%s"
               },
               {
                  "inputs" : { "click" : { "output" : "/actions/raw/in/raw_right_a" } },
                  "mode" : "button",
                  "path" : "%s"
               },
               {
                  "inputs" : { "click" : { "output" : "/actions/raw/in/raw_right_b" } },
                  "mode" : "button",
                  "path" : "%s"
               }
            ]
         }]],
		stick_path,  -- left stick
		a_left, b_left,
		stick_path,  -- right stick
		a_right, b_right
	)
end

-- Controller-specific raw bindings
local RAW_BINDINGS = {
	-- Valve Index (Knuckles)
	knuckles = MakeRawBindings(
		"thumbstick",
		"/user/hand/left/input/a", "/user/hand/left/input/b",
		"/user/hand/right/input/a", "/user/hand/right/input/b"
	),
	-- Oculus Touch
	touch = MakeRawBindings(
		"joystick",
		"/user/hand/left/input/x", "/user/hand/left/input/y",
		"/user/hand/right/input/a", "/user/hand/right/input/b"
	),
	-- HTC Vive
	vive = MakeRawBindings(
		"trackpad",
		"/user/hand/left/input/application_menu", "/user/hand/left/input/grip",
		"/user/hand/right/input/application_menu", "/user/hand/right/input/grip"
	),
	-- Vive Cosmos
	cosmos = MakeRawBindings(
		"joystick",
		"/user/hand/left/input/a", "/user/hand/left/input/b",
		"/user/hand/right/input/a", "/user/hand/right/input/b"
	),
	-- HP Reverb G2 / WMR
	hp = MakeRawBindings(
		"joystick",
		"/user/hand/left/input/x", "/user/hand/left/input/y",
		"/user/hand/right/input/a", "/user/hand/right/input/b"
	),
	-- WMR Holographic
	holographic = MakeRawBindings(
		"joystick",
		"/user/hand/left/input/menu", "/user/hand/left/input/grip",
		"/user/hand/right/input/menu", "/user/hand/right/input/grip"
	),
}

-------------------------------------------------------------------------------
-- 3. INJECT INTO MANIFEST
-------------------------------------------------------------------------------

local function InjectRawIntoManifest()
	local manifest = g_VR.action_manifest
	if not manifest then return false end

	-- Already injected?
	if string.find(manifest, "raw_left_trigger_bool", 1, true) then
		return true -- already has raw actions
	end

	-- Find the last action entry (before the closing ] of "actions" array)
	-- Strategy: find the last "type" field before "action_sets"
	local actionSetsPos = string.find(manifest, '"action_sets"', 1, true)
	if not actionSetsPos then
		print("[VRMod Raw Input] ERROR: Could not find action_sets in manifest")
		return false
	end

	-- Find the ] that closes the actions array (before action_sets)
	local closeBracket = string.find(manifest, "%]", 1)
	-- We need the ] that's right before "action_sets"
	local searchStart = 1
	local lastBracket = nil
	while true do
		local pos = string.find(manifest, "%]", searchStart)
		if not pos or pos >= actionSetsPos then break end
		lastBracket = pos
		searchStart = pos + 1
	end

	if not lastBracket then
		print("[VRMod Raw Input] ERROR: Could not find actions array end")
		return false
	end

	-- Insert raw actions before the ]
	manifest = string.sub(manifest, 1, lastBracket - 1)
		.. RAW_ACTIONS_JSON .. "\n\t"
		.. string.sub(manifest, lastBracket)

	-- Find the ] that closes "action_sets" array
	local actionSetsStart = string.find(manifest, '"action_sets"', 1, true)
	local setsArrayStart = string.find(manifest, "%[", actionSetsStart)
	local setsArrayEnd = string.find(manifest, "%]", setsArrayStart)
	if setsArrayEnd then
		manifest = string.sub(manifest, 1, setsArrayEnd - 1)
			.. RAW_ACTIONSET_JSON .. "\n\t"
			.. string.sub(manifest, setsArrayEnd)
	end

	-- Find the closing } of the localization object (last entry before ]} )
	local locStart = string.find(manifest, '"localization"', 1, true)
	if locStart then
		-- Find the last key-value pair in the localization object
		-- The localization is an array with one object: [ { ... } ]
		-- We need to insert before the closing }
		local locObjStart = string.find(manifest, "%{", locStart)
		if locObjStart then
			-- Find the matching } - it's the last } before the ] of localization array
			local locArrayEnd = string.find(manifest, "%]", locObjStart)
			if locArrayEnd then
				local locObjEnd = string.find(manifest, "%}", locObjStart)
				-- Find the LAST } before locArrayEnd
				local searchPos = locObjStart
				local lastClose = nil
				while true do
					local pos = string.find(manifest, "%}", searchPos + 1)
					if not pos or pos >= locArrayEnd then break end
					lastClose = pos
					searchPos = pos
				end
				if lastClose then
					manifest = string.sub(manifest, 1, lastClose - 1)
						.. RAW_LOCALIZATION_JSON .. "\n\t\t"
						.. string.sub(manifest, lastClose)
				end
			end
		end
	end

	g_VR.action_manifest = manifest
	return true
end

-------------------------------------------------------------------------------
-- 4. INJECT RAW BINDINGS INTO CONTROLLER BINDING STRINGS
-------------------------------------------------------------------------------

local function InjectRawIntoBinding(bindingStr, controllerKey)
	if not bindingStr or bindingStr == "" then return bindingStr end

	local rawSection = RAW_BINDINGS[controllerKey]
	if not rawSection then return bindingStr end

	-- Already injected?
	if string.find(bindingStr, "/actions/raw", 1, true) then
		return bindingStr
	end

	-- Find the "bindings" object and insert the raw section
	-- Strategy: find the last action set section (e.g. /actions/driving or /actions/main)
	-- and add raw after it

	-- Find the closing of the "bindings" object
	-- The bindings object structure is:
	-- "bindings" : { "/actions/base": {...}, "/actions/main": {...}, "/actions/driving": {...} }
	-- We need to add: , "/actions/raw": {...}

	-- Find "category" which comes after "bindings" closes
	local categoryPos = string.find(bindingStr, '"category"', 1, true)
	if not categoryPos then
		-- Some binding files might not have category, try "controller_type"
		categoryPos = string.find(bindingStr, '"controller_type"', 1, true)
	end

	if not categoryPos then
		print("[VRMod Raw Input] WARNING: Could not find insertion point for " .. controllerKey)
		return bindingStr
	end

	-- Find the } that closes "bindings" - it's right before "category"
	local searchPos = categoryPos
	local bindingsClose = nil
	while searchPos > 1 do
		searchPos = searchPos - 1
		local char = string.sub(bindingStr, searchPos, searchPos)
		if char == "}" then
			bindingsClose = searchPos
			break
		end
	end

	if not bindingsClose then
		print("[VRMod Raw Input] WARNING: Could not find bindings close for " .. controllerKey)
		return bindingStr
	end

	-- Insert raw binding section before the closing }
	bindingStr = string.sub(bindingStr, 1, bindingsClose - 1)
		.. ",\n" .. rawSection .. "\n      "
		.. string.sub(bindingStr, bindingsClose)

	return bindingStr
end

-------------------------------------------------------------------------------
-- 5. EXECUTE INJECTION
-------------------------------------------------------------------------------

local success = InjectRawIntoManifest()
if success then
	-- Inject into each controller binding
	g_VR.bindings_knuckles = InjectRawIntoBinding(g_VR.bindings_knuckles, "knuckles")
	g_VR.bindings_touch = InjectRawIntoBinding(g_VR.bindings_touch, "touch")
	g_VR.bindings_vive = InjectRawIntoBinding(g_VR.bindings_vive, "vive")
	g_VR.bindings_cosmos = InjectRawIntoBinding(g_VR.bindings_cosmos, "cosmos")
	g_VR.bindings_hp = InjectRawIntoBinding(g_VR.bindings_hp, "hp")
	g_VR.bindings_holographic = InjectRawIntoBinding(g_VR.bindings_holographic, "holographic")

	print("[VRMod Raw Input] Raw input actions injected successfully (16 raw actions)")
else
	print("[VRMod Raw Input] ERROR: Failed to inject raw actions into manifest")
end

-- Always verify disk files have raw actions, rewrite if stale
-- This fixes the case where bindingversion was bumped but files are stale
local function WriteAllBindingFiles()
	if not file.Exists("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end
	file.Write("vrmod/vrmod_action_manifest.txt", g_VR.action_manifest)
	file.Write("vrmod/vrmod_bindings_knuckles.txt", g_VR.bindings_knuckles)
	file.Write("vrmod/vrmod_bindings_oculus_touch.txt", g_VR.bindings_touch)
	file.Write("vrmod/vrmod_bindings_vive_controller.txt", g_VR.bindings_vive)
	file.Write("vrmod/vrmod_bindings_vive_cosmos_controller.txt", g_VR.bindings_cosmos)
	file.Write("vrmod/vrmod_bindings_hpmotioncontroller.txt", g_VR.bindings_hp)
	file.Write("vrmod/vrmod_bindings_holographic_controller.txt", g_VR.bindings_holographic)
	file.Write("vrmod/vrmod_bindings_vive_tracker_left_foot.txt", g_VR.bindings_vive_tracker_left_foot)
	file.Write("vrmod/vrmod_bindings_vive_tracker_right_foot.txt", g_VR.bindings_vive_tracker_right_foot)
	file.Write("vrmod/vrmod_bindings_vive_tracker_waist.txt", g_VR.bindings_vive_tracker_waist)
end

if success then
	-- Check if disk manifest actually has raw actions
	local diskManifest = file.Read("vrmod/vrmod_action_manifest.txt", "DATA")
	local diskHasRaw = diskManifest and string.find(diskManifest, "raw_left_trigger_bool", 1, true)
	if not diskHasRaw then
		-- Disk is stale — rewrite all files with injected raw actions
		WriteAllBindingFiles()
		print("[VRMod Raw Input] Disk files were stale — rewritten with raw actions")
	end

	-- Also handle binding version for base file compatibility
	local cv_bindingVersion = GetConVar("vrmod_bindingversion")
	if cv_bindingVersion and cv_bindingVersion:GetInt() < 18 then
		cv_bindingVersion:SetInt(18)
		WriteAllBindingFiles()
		print("[VRMod Raw Input] Binding files updated to version 18 (raw input support)")
	end
end

-- Force rewrite command (for troubleshooting)
concommand.Add("vrmod_keybinding_force_rewrite", function()
	if not g_VR.action_manifest then
		print("ERROR: action_manifest not loaded")
		return
	end
	WriteAllBindingFiles()
	print("[VRMod Raw Input] All binding files force-rewritten to disk")
	print("IMPORTANT: You must restart VR (vrmod_exit then vrmod_start) for changes to take effect.")
	print("If raw input still doesn't work, SteamVR may have cached old bindings.")
	print("In that case, open SteamVR Settings > Controller Bindings > Garry's Mod > Revert to Default")
end)

-- Re-inject raw actions after VRMod_Reset (which CopyVMTsToTXT overwrites with raw-free VMTs)
hook.Add("VRMod_Reset", "vrmod_raw_input_reinject", function()
	-- CopyVMTsToTXT has already run and written raw-free files from VMTs.
	-- vrmod_steamvr_bindings.lua's VRMod_Reset hook has rewritten base bindings.
	-- We need to re-inject raw actions into the in-memory strings and rewrite disk files.
	-- Use timer.Simple(0) to ensure we run AFTER bindings.lua's reset hook.
	timer.Simple(0, function()
		local ok = InjectRawIntoManifest()
		if ok then
			g_VR.bindings_knuckles = InjectRawIntoBinding(g_VR.bindings_knuckles, "knuckles")
			g_VR.bindings_touch = InjectRawIntoBinding(g_VR.bindings_touch, "touch")
			g_VR.bindings_vive = InjectRawIntoBinding(g_VR.bindings_vive, "vive")
			g_VR.bindings_cosmos = InjectRawIntoBinding(g_VR.bindings_cosmos, "cosmos")
			g_VR.bindings_hp = InjectRawIntoBinding(g_VR.bindings_hp, "hp")
			g_VR.bindings_holographic = InjectRawIntoBinding(g_VR.bindings_holographic, "holographic")
			WriteAllBindingFiles()
			print("[VRMod Raw Input] Re-injected raw actions after VRMod_Reset")
		end
	end)
end)

-- Store raw action list for use by keybinding layer
g_VR.rawActionNames = {
	"raw_left_trigger_bool", "raw_left_trigger_pull",
	"raw_left_grip_bool", "raw_left_grip_pull",
	"raw_left_stick", "raw_left_stick_click",
	"raw_left_a", "raw_left_b",
	"raw_right_trigger_bool", "raw_right_trigger_pull",
	"raw_right_grip_bool", "raw_right_grip_pull",
	"raw_right_stick", "raw_right_stick_click",
	"raw_right_a", "raw_right_b",
}

-- Categorize by type for the keybinding layer
g_VR.rawActionTypes = {
	raw_left_trigger_bool = "boolean",  raw_left_trigger_pull = "vector1",
	raw_left_grip_bool    = "boolean",  raw_left_grip_pull    = "vector1",
	raw_left_stick        = "vector2",  raw_left_stick_click  = "boolean",
	raw_left_a            = "boolean",  raw_left_b            = "boolean",
	raw_right_trigger_bool = "boolean", raw_right_trigger_pull = "vector1",
	raw_right_grip_bool    = "boolean", raw_right_grip_pull    = "vector1",
	raw_right_stick        = "vector2", raw_right_stick_click  = "boolean",
	raw_right_a            = "boolean", raw_right_b            = "boolean",
}
