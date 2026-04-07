if SERVER then return end

-- ============================================
-- Player Model Preset System
-- Saves/loads character settings per player model to JSON
-- Pattern: same as viewmodelinfo.json
-- ============================================

local PRESET_FILE = "vrmod/playermodel_presets.json"
local PRESET_BACKUP_FILE = "vrmod/playermodel_presets_backup.json"

-- Character ConVars to save per model
-- These are the settings that change depending on the player model's body proportions
local PRESET_CONVARS = {
	-- Body proportions
	"vrmod_scale",
	"vrmod_characterEyeHeight",
	"vrmod_characterHeadToHmdDist",
	"vrmod_crouchthreshold",
	"vrmod_znear",
	"vrmod_seatedoffset",
	-- Head hiding (bone position varies per model)
	"vrmod_hide_head",
	"vrmod_hide_head_pos_x",
	"vrmod_hide_head_pos_y",
	"vrmod_hide_head_pos_z",
	-- Animation (some models clip HMD on run/fly; set all to WALK as workaround)
	"vrmod_idle_act",
	"vrmod_walk_act",
	"vrmod_run_act",
	"vrmod_jump_act",
	-- Character yaw/head method (model skeleton dependent)
	"vrmod_oldcharacteryaw",
	"vrmod_althead",
}

-- ========================================
-- Validation Rules
-- Protects against corrupted/invalid data being applied
-- ========================================

local PRESET_VALIDATORS = {
	vrmod_scale                 = { type = "number", min = 1,     max = 200  },
	vrmod_characterEyeHeight    = { type = "number", min = 0,     max = 100  },
	vrmod_characterHeadToHmdDist = { type = "number", min = -20,  max = 20   },
	vrmod_crouchthreshold       = { type = "number", min = 0,     max = 100  },
	vrmod_znear                 = { type = "number", min = 0,     max = 20   },
	vrmod_seatedoffset          = { type = "number", min = -100,  max = 100  },
	vrmod_hide_head             = { type = "bool" },
	vrmod_hide_head_pos_x       = { type = "number", min = -1000, max = 1000 },
	vrmod_hide_head_pos_y       = { type = "number", min = -1000, max = 1000 },
	vrmod_hide_head_pos_z       = { type = "number", min = -1000, max = 1000 },
	vrmod_idle_act              = { type = "act" },
	vrmod_walk_act              = { type = "act" },
	vrmod_run_act               = { type = "act" },
	vrmod_jump_act              = { type = "act" },
	vrmod_oldcharacteryaw       = { type = "bool" },
	vrmod_althead               = { type = "bool" },
}

-- Validate a single ConVar value against its rule
-- Returns: isValid, reason
local function ValidateValue(cvarName, value)
	local rule = PRESET_VALIDATORS[cvarName]
	if not rule then return true end

	local str = tostring(value)

	if rule.type == "number" then
		local num = tonumber(str)
		if not num then return false, "not a number (got '" .. str .. "')" end
		if rule.min and num < rule.min then return false, "below min " .. rule.min .. " (got " .. num .. ")" end
		if rule.max and num > rule.max then return false, "above max " .. rule.max .. " (got " .. num .. ")" end
	elseif rule.type == "bool" then
		local num = tonumber(str)
		if num == nil or (num ~= 0 and num ~= 1) then return false, "must be 0 or 1 (got '" .. str .. "')" end
	elseif rule.type == "act" then
		-- Empty = use default, otherwise must match ACT_UPPERCASE_NAME pattern
		if str ~= "" and not string.match(str, "^ACT_[%u%d_]+$") then
			return false, "must be empty or ACT_NAME format (got '" .. str .. "')"
		end
	end

	return true
end

local autoloadCV = CreateClientConVar("vrmod_unoff_preset_autoload", "1", true, FCVAR_ARCHIVE,
	"Auto-load character preset when player model changes during VR", 0, 1)

vrmod.PlayerModelPresets = vrmod.PlayerModelPresets or {}
local presetData = {}

-- ========================================
-- Core Functions
-- ========================================

local function LoadPresetsFromFile()
	if file.Exists(PRESET_FILE, "DATA") then
		local json = file.Read(PRESET_FILE, "DATA")
		if json then
			local ok, tbl = pcall(util.JSONToTable, json)
			if ok and tbl then
				presetData = tbl
				return true
			else
				print("[VRMod Presets] Warning: JSON parse failed, starting with empty presets")
			end
		end
	end
	presetData = {}
	return false
end

local function SavePresetsToFile()
	-- Backup current file before overwriting
	if file.Exists(PRESET_FILE, "DATA") then
		local currentJson = file.Read(PRESET_FILE, "DATA")
		if currentJson and #currentJson > 2 then
			file.Write(PRESET_BACKUP_FILE, currentJson)
		end
	end

	local json = util.TableToJSON(presetData, true)
	if json then
		file.Write(PRESET_FILE, json)
		return true
	end
	return false
end

-- Get current player model path
function vrmod.PlayerModelPresets.GetCurrentModel()
	local ply = LocalPlayer()
	if not IsValid(ply) then return nil end
	return ply.vrmod_pm or ply:GetModel()
end

-- Get short display name from model path
local function GetShortModelName(mdl)
	if not mdl then return "unknown" end
	local name = string.GetFileFromFilename(mdl)
	if name then
		-- Remove .mdl extension for cleaner display
		name = string.gsub(name, "%.mdl$", "")
	end
	return name or mdl
end

-- Save current ConVar values for current model
function vrmod.PlayerModelPresets.SaveCurrentModel()
	local mdl = vrmod.PlayerModelPresets.GetCurrentModel()
	if not mdl then
		chat.AddText(Color(255, 100, 100), "[VRMod] ", Color(255, 255, 255), "Cannot detect player model")
		return false
	end

	local settings = {}
	local warnings = {}
	for _, cvarName in ipairs(PRESET_CONVARS) do
		local cv = GetConVar(cvarName)
		if cv then
			local val = cv:GetString()
			local valid, reason = ValidateValue(cvarName, val)
			if not valid then
				warnings[#warnings + 1] = cvarName .. ": " .. reason
			end
			settings[cvarName] = val
		end
	end

	-- Warn about suspicious values but still save (user might intentionally override)
	if #warnings > 0 then
		chat.AddText(Color(255, 200, 100), "[VRMod] ", Color(255, 255, 255), "Warning: " .. #warnings .. " value(s) outside normal range")
		for _, w in ipairs(warnings) do
			print("[VRMod Presets] Warning on save: " .. w)
		end
	end

	presetData[mdl] = settings
	SavePresetsToFile()

	local shortName = GetShortModelName(mdl)
	chat.AddText(Color(100, 200, 100), "[VRMod] ", Color(255, 255, 255), "Saved preset for: " .. shortName)
	return true
end

-- Load saved ConVar values for a model
-- restartCharacter: if true, stops and restarts the character system to apply changes
function vrmod.PlayerModelPresets.LoadForModel(mdl, restartCharacter)
	if not mdl or not presetData[mdl] then
		local shortName = GetShortModelName(mdl)
		chat.AddText(Color(255, 200, 100), "[VRMod] ", Color(255, 255, 255), "No preset found for: " .. shortName)
		return false
	end

	local settings = presetData[mdl]

	-- Stop character system before applying changes
	if restartCharacter then
		RunConsoleCommand("vrmod_character_stop")
	end

	-- Apply saved ConVar values with validation
	local skipped = {}
	for cvarName, value in pairs(settings) do
		local valid, reason = ValidateValue(cvarName, value)
		if valid then
			RunConsoleCommand(cvarName, tostring(value))
		else
			skipped[#skipped + 1] = cvarName .. " (" .. reason .. ")"
		end
	end

	-- Report skipped invalid values
	if #skipped > 0 then
		chat.AddText(Color(255, 100, 100), "[VRMod] ", Color(255, 255, 255), "Blocked " .. #skipped .. " invalid value(s):")
		for _, s in ipairs(skipped) do
			print("[VRMod Presets] Blocked: " .. s)
		end
	end

	-- Update cached g_VR.scale immediately
	if settings.vrmod_scale and g_VR then
		g_VR.scale = tonumber(settings.vrmod_scale) or g_VR.scale
	end

	-- Restart character system after a delay to let ConVars propagate
	if restartCharacter then
		timer.Simple(0.5, function()
			RunConsoleCommand("vrmod_character_start")
		end)
	end

	local shortName = GetShortModelName(mdl)
	chat.AddText(Color(100, 200, 100), "[VRMod] ", Color(255, 255, 255), "Loaded preset for: " .. shortName)
	return true
end

-- Load preset for current model
function vrmod.PlayerModelPresets.LoadCurrentModel()
	local mdl = vrmod.PlayerModelPresets.GetCurrentModel()
	return vrmod.PlayerModelPresets.LoadForModel(mdl, true)
end

-- Check if preset exists for a model
function vrmod.PlayerModelPresets.HasPreset(mdl)
	return presetData[mdl] ~= nil
end

-- Delete preset for a model
function vrmod.PlayerModelPresets.DeletePreset(mdl)
	if presetData[mdl] then
		presetData[mdl] = nil
		SavePresetsToFile()
		return true
	end
	return false
end

-- Get all saved presets (read-only reference)
function vrmod.PlayerModelPresets.GetAll()
	return presetData
end

-- Reload presets from disk
function vrmod.PlayerModelPresets.Reload()
	LoadPresetsFromFile()
end

-- ========================================
-- Initialize on file load
-- ========================================

LoadPresetsFromFile()

-- ========================================
-- ConCommands
-- ========================================

concommand.Add("vrmod_preset_save", function()
	vrmod.PlayerModelPresets.SaveCurrentModel()
end, nil, "Save current character settings for the current player model")

concommand.Add("vrmod_preset_load", function()
	vrmod.PlayerModelPresets.LoadCurrentModel()
end, nil, "Load saved character settings for the current player model")

concommand.Add("vrmod_preset_delete", function()
	local mdl = vrmod.PlayerModelPresets.GetCurrentModel()
	if mdl and vrmod.PlayerModelPresets.DeletePreset(mdl) then
		local shortName = GetShortModelName(mdl)
		chat.AddText(Color(100, 200, 100), "[VRMod] ", Color(255, 255, 255), "Deleted preset for: " .. shortName)
	else
		chat.AddText(Color(255, 200, 100), "[VRMod] ", Color(255, 255, 255), "No preset to delete")
	end
end, nil, "Delete saved character preset for the current player model")

concommand.Add("vrmod_preset_list", function()
	LoadPresetsFromFile()
	local count = 0
	print("========================================")
	print("[VRMod] Saved Player Model Presets:")
	print("----------------------------------------")
	for mdl, settings in pairs(presetData) do
		count = count + 1
		local scale = settings.vrmod_scale or "?"
		local eyeH = settings.vrmod_characterEyeHeight or "?"
		print(string.format("  %s", mdl))
		print(string.format("    scale=%s  eyeHeight=%s", scale, eyeH))
	end
	if count == 0 then
		print("  (no presets saved)")
	end
	print("========================================")
	print("[VRMod] Total: " .. count .. " preset(s)")
end, nil, "List all saved player model presets")

concommand.Add("vrmod_preset_restore_backup", function()
	if file.Exists(PRESET_BACKUP_FILE, "DATA") then
		local json = file.Read(PRESET_BACKUP_FILE, "DATA")
		if json then
			file.Write(PRESET_FILE, json)
			LoadPresetsFromFile()
			chat.AddText(Color(100, 200, 100), "[VRMod] ", Color(255, 255, 255), "Restored presets from backup")
		else
			chat.AddText(Color(255, 100, 100), "[VRMod] ", Color(255, 255, 255), "Backup file is empty")
		end
	else
		chat.AddText(Color(255, 200, 100), "[VRMod] ", Color(255, 255, 255), "No backup file found")
	end
end, nil, "Restore presets from backup (undo last save)")

-- ========================================
-- Auto-load on VR Start + Model Change Detection
-- ========================================

local lastKnownModel = nil

hook.Add("VRMod_Start", "vrmod_playermodel_presets", function(ply)
	if ply ~= LocalPlayer() then return end

	-- Reload presets from disk in case they were edited externally
	LoadPresetsFromFile()
	lastKnownModel = vrmod.PlayerModelPresets.GetCurrentModel()

	-- Auto-load preset on VR start (delayed to avoid conflict with character init)
	if autoloadCV:GetBool() and lastKnownModel and vrmod.PlayerModelPresets.HasPreset(lastKnownModel) then
		timer.Simple(2, function()
			if IsValid(LocalPlayer()) then
				vrmod.PlayerModelPresets.LoadForModel(lastKnownModel, true)
			end
		end)
	end

	-- Start model change polling (every 2 seconds, lightweight)
	timer.Create("vrmod_preset_modelwatch", 2, 0, function()
		if not IsValid(LocalPlayer()) then return end
		local currentModel = vrmod.PlayerModelPresets.GetCurrentModel()
		if currentModel and currentModel ~= lastKnownModel then
			local oldModel = lastKnownModel
			lastKnownModel = currentModel
			local shortName = GetShortModelName(currentModel)

			if autoloadCV:GetBool() and vrmod.PlayerModelPresets.HasPreset(currentModel) then
				-- Auto-load saved preset for the new model
				vrmod.PlayerModelPresets.LoadForModel(currentModel, true)
			else
				-- Notify user of model change
				chat.AddText(Color(255, 200, 100), "[VRMod] ", Color(255, 255, 255), "Model changed: " .. shortName)
				if not vrmod.PlayerModelPresets.HasPreset(currentModel) then
					chat.AddText(Color(255, 200, 100), "[VRMod] ", Color(255, 255, 255), "No preset saved. Use mirror 'Save Preset' or 'vrmod_preset_save'")
				end
			end
		end
	end)
end)

hook.Add("VRMod_Exit", "vrmod_playermodel_presets", function()
	timer.Remove("vrmod_preset_modelwatch")
end)
