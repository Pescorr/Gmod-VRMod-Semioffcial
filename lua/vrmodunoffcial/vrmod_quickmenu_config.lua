-- VRMod Semi-Official Addon Plus - Quick Menu Configuration System
-- クイックメニュー設定の読み込み・保存処理
-- Version 1.0

if SERVER then return end

-- Configuration file path
local CONFIG_FILE_PATH = "vrmod/quickmenu_config.json"
local CONFIG_VERSION = 1

-- Local cache for loaded config
local loadedConfig = nil
local configApplied = false

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------

-- Ensure the vrmod data directory exists
local function EnsureDataDirectory()
    if not file.IsDir("vrmod", "DATA") then
        file.CreateDir("vrmod")
    end
end

-- Validate a single menu item structure
local function ValidateMenuItem(item)
    if not istable(item) then return false end
    if not isstring(item.name) or item.name == "" then return false end
    if not isnumber(item.slot) or item.slot < 0 or item.slot > 5 then return false end
    if not isnumber(item.slotPos) or item.slotPos < 0 or item.slotPos > 20 then return false end
    if not isstring(item.actionType) then return false end
    if item.actionType ~= "convar_toggle" and item.actionType ~= "command" and item.actionType ~= "key_press" then return false end
    if not isstring(item.actionValue) or item.actionValue == "" then return false end
    if item.actionType == "key_press" then
        local code = tonumber(item.actionValue)
        if not code or code < 1 then return false end
    end
    return true
end

-- Validate entire config structure
local function ValidateConfig(config)
    if not istable(config) then return false end
    if not isnumber(config.version) then return false end
    if not istable(config.items) then return false end
    return true
end

-----------------------------------------------------------
-- Core API Functions
-----------------------------------------------------------

-- Load configuration from JSON file
-- Returns: table or nil (if file doesn't exist or is invalid)
function vrmod.LoadQuickMenuConfig()
    EnsureDataDirectory()

    if not file.Exists(CONFIG_FILE_PATH, "DATA") then
        loadedConfig = nil
        return nil
    end

    local jsonData = file.Read(CONFIG_FILE_PATH, "DATA")
    if not jsonData or jsonData == "" then
        loadedConfig = nil
        return nil
    end

    local success, config = pcall(util.JSONToTable, jsonData)
    if not success or not ValidateConfig(config) then
        ErrorNoHalt("[VRMod QuickMenu] Failed to parse config file, using defaults\n")
        loadedConfig = nil
        return nil
    end

    -- Validate each item and filter out invalid ones
    local validItems = {}
    for i, item in ipairs(config.items) do
        if ValidateMenuItem(item) then
            table.insert(validItems, item)
        else
            ErrorNoHalt("[VRMod QuickMenu] Skipping invalid item at index " .. i .. "\n")
        end
    end

    config.items = validItems
    loadedConfig = config
    return config
end

-- Save configuration to JSON file
-- items: table of menu item definitions
-- Returns: boolean (success)
function vrmod.SaveQuickMenuConfig(items)
    if not istable(items) then
        ErrorNoHalt("[VRMod QuickMenu] SaveQuickMenuConfig: items must be a table\n")
        return false
    end

    EnsureDataDirectory()

    -- Validate and filter items before saving
    local validItems = {}
    for i, item in ipairs(items) do
        if ValidateMenuItem(item) then
            table.insert(validItems, {
                name = item.name,
                slot = item.slot,
                slotPos = item.slotPos,
                actionType = item.actionType,
                actionValue = item.actionValue
            })
        end
    end

    local config = {
        version = CONFIG_VERSION,
        items = validItems
    }

    local jsonData = util.TableToJSON(config, true)
    if not jsonData then
        ErrorNoHalt("[VRMod QuickMenu] Failed to serialize config to JSON\n")
        return false
    end

    local success = file.Write(CONFIG_FILE_PATH, jsonData)
    if success == false then
        ErrorNoHalt("[VRMod QuickMenu] Failed to write config file\n")
        return false
    end

    loadedConfig = config
    return true
end

-- Get currently loaded config (cached)
function vrmod.GetQuickMenuConfig()
    return loadedConfig
end

-- Check if custom config should be used
function vrmod.ShouldUseCustomQuickMenu()
    local cvar = GetConVar("vrmod_quickmenu_use_custom")
    return cvar and cvar:GetBool() and loadedConfig and #loadedConfig.items > 0
end

-- Create action function from item definition
local function CreateActionFunction(item)
    if item.actionType == "convar_toggle" then
        return function()
            local cvar = GetConVar(item.actionValue)
            if cvar then
                local current = cvar:GetBool()
                RunConsoleCommand(item.actionValue, current and "0" or "1")
            end
        end
    elseif item.actionType == "command" then
        return function()
            LocalPlayer():ConCommand(item.actionValue)
        end
    elseif item.actionType == "key_press" then
        return function()
            local code = tonumber(item.actionValue)
            if code and code > 0 and vrmod and vrmod.InputEmu_TapKey then
                vrmod.InputEmu_TapKey(code)
            end
        end
    end
    return function() end
end

-- Apply custom configuration to g_VR.menuItems
-- This replaces existing items with custom config
function vrmod.ApplyQuickMenuConfig()
    if not vrmod.ShouldUseCustomQuickMenu() then
        return false
    end

    if not g_VR or not g_VR.menuItems then
        return false
    end

    -- Clear existing custom items (marked with _customConfig flag)
    for i = #g_VR.menuItems, 1, -1 do
        if g_VR.menuItems[i]._customConfig then
            table.remove(g_VR.menuItems, i)
        end
    end

    -- Add items from custom config
    for _, item in ipairs(loadedConfig.items) do
        local menuItem = {
            name = item.name,
            slot = item.slot,
            slotPos = item.slotPos,
            func = CreateActionFunction(item),
            _customConfig = true
        }
        table.insert(g_VR.menuItems, menuItem)
    end

    configApplied = true
    return true
end

-- Reset to default menu items (remove custom items)
function vrmod.ResetQuickMenuToDefault()
    if not g_VR or not g_VR.menuItems then
        return false
    end

    for i = #g_VR.menuItems, 1, -1 do
        if g_VR.menuItems[i]._customConfig then
            table.remove(g_VR.menuItems, i)
        end
    end

    configApplied = false
    return true
end

-- Get list of current menu items for editor display
function vrmod.GetCurrentMenuItems()
    if loadedConfig and loadedConfig.items then
        return loadedConfig.items
    end
    return {}
end

-- Export current g_VR.menuItems to config format (for initial setup)
function vrmod.ExportCurrentMenuToConfig()
    if not g_VR or not g_VR.menuItems then
        return {}
    end

    local items = {}
    for _, item in ipairs(g_VR.menuItems) do
        if not item._customConfig then
            table.insert(items, {
                name = item.name or "Unknown",
                slot = item.slot or 0,
                slotPos = item.slotPos or 0,
                actionType = "command",
                actionValue = "echo " .. (item.name or "Unknown")
            })
        end
    end
    return items
end

-----------------------------------------------------------
-- ConVar Creation
-----------------------------------------------------------

CreateClientConVar("vrmod_quickmenu_use_custom", "1", true, false,
    "Use custom quick menu configuration", 0, 1)

-----------------------------------------------------------
-- Initialization
-----------------------------------------------------------

-- Load config on startup (deferred to ensure g_VR exists)
hook.Add("VRMod_Start", "VRMod_QuickMenuConfig_Init", function()
    vrmod.LoadQuickMenuConfig()

    -- Apply custom config if enabled
    timer.Simple(0.5, function()
        if vrmod.ShouldUseCustomQuickMenu() then
            vrmod.ApplyQuickMenuConfig()
        end
    end)
end)

-- Re-apply when convar changes
cvars.AddChangeCallback("vrmod_quickmenu_use_custom", function(name, old, new)
    if tobool(new) then
        vrmod.ApplyQuickMenuConfig()
    else
        vrmod.ResetQuickMenuToDefault()
    end
end, "VRMod_QuickMenuConfig")

print("[VRMod] Quick Menu Config System loaded")
