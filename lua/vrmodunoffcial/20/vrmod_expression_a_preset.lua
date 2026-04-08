--[[
    Module 20: Expression System — Preset Definitions (SH)
    VRChat-style gesture IDs and facial expression flex weight mappings.
    File prefix "a_" ensures this loads before gesture/apply/menu files.
]]

AddCSLuaFile()

vrmod.Expression = vrmod.Expression or {}

---------------------------------------------------------------------------
-- Gesture IDs (mirrors VRChat convention)
---------------------------------------------------------------------------
vrmod.Expression.GESTURE_NEUTRAL     = 0
vrmod.Expression.GESTURE_FIST        = 1
vrmod.Expression.GESTURE_HAND_OPEN   = 2
vrmod.Expression.GESTURE_FINGER_POINT = 3
vrmod.Expression.GESTURE_VICTORY     = 4
vrmod.Expression.GESTURE_ROCK_N_ROLL = 5
vrmod.Expression.GESTURE_HAND_GUN   = 6
vrmod.Expression.GESTURE_THUMBS_UP  = 7

vrmod.Expression.GESTURE_COUNT = 8

vrmod.Expression.GESTURE_NAMES = {
    [0] = "Neutral",
    [1] = "Fist",
    [2] = "HandOpen",
    [3] = "FingerPoint",
    [4] = "Victory",
    [5] = "RockNRoll",
    [6] = "HandGun",
    [7] = "ThumbsUp",
}

---------------------------------------------------------------------------
-- Expression presets: gesture ID → { display name, { flexName = weight, ... } }
-- Flex names are standard HL2 model flex controller names from facerules_xsi.qci.
---------------------------------------------------------------------------
vrmod.Expression.PRESETS = {
    [0] = { -- Neutral
        name = "Default",
        flexes = {},
    },
    [1] = { -- Fist → Angry
        name = "Angry",
        flexes = {
            left_lowerer = 0.8,
            right_lowerer = 0.8,
            left_corner_depressor = 0.6,
            right_corner_depressor = 0.6,
            jaw_clencher = 0.3,
            wrinkler = 0.4,
        },
    },
    [2] = { -- HandOpen → Happy
        name = "Happy",
        flexes = {
            left_corner_puller = 0.8,
            right_corner_puller = 0.8,
            left_cheek_raiser = 0.5,
            right_cheek_raiser = 0.5,
            blink = 0.15,
        },
    },
    [3] = { -- FingerPoint → Wink
        name = "Wink",
        flexes = {
            right_lid_closer = 0.9,
            left_corner_puller = 0.4,
        },
    },
    [4] = { -- Victory → Smile
        name = "Smile",
        flexes = {
            left_corner_puller = 1.0,
            right_corner_puller = 1.0,
            left_cheek_raiser = 0.7,
            right_cheek_raiser = 0.7,
        },
    },
    [5] = { -- RockNRoll → Crazy
        name = "Crazy",
        flexes = {
            left_outer_raiser = 0.8,
            right_outer_raiser = 0.8,
            jaw_drop = 0.4,
            left_corner_puller = 0.5,
            right_corner_puller = 0.5,
        },
    },
    [6] = { -- HandGun → Cool
        name = "Cool",
        flexes = {
            left_lid_droop = 0.4,
            right_lid_droop = 0.4,
            left_corner_puller = 0.3,
            right_corner_puller = 0.3,
        },
    },
    [7] = { -- ThumbsUp → Grin
        name = "Grin",
        flexes = {
            left_corner_puller = 0.6,
            right_corner_puller = 0.6,
            left_inner_raiser = 0.3,
            right_inner_raiser = 0.3,
        },
    },
}

---------------------------------------------------------------------------
-- Resolve flex name → flex ID for a given entity.
-- Returns a table of { flexID = targetWeight } for a preset, or nil if
-- the model has no matching flexes at all.
---------------------------------------------------------------------------
function vrmod.Expression.ResolvePreset(ent, gestureID)
    local preset = vrmod.Expression.PRESETS[gestureID]
    if not preset then return nil end

    local resolved = {}
    local found = false

    for flexName, weight in pairs(preset.flexes) do
        local id = ent:GetFlexIDByName(flexName)
        if id then
            resolved[id] = weight
            found = true
        end
    end

    if gestureID == 0 then
        -- Neutral always valid (resets all to 0)
        return resolved, true
    end

    return found and resolved or nil, found
end

---------------------------------------------------------------------------
-- Auto-detect expression bodygroup on a model.
-- Looks for bodygroups named "face"/"expression"/"expressions" first,
-- then falls back to the first bodygroup with >2 submodels.
-- Returns { id, name, max } or nil.
---------------------------------------------------------------------------
function vrmod.Expression.FindExpressionBodygroup(ent)
    if not IsValid(ent) then return nil end
    local groups = ent:GetBodyGroups()
    if not groups then return nil end

    local FACE_NAMES = { face = true, expression = true, expressions = true }

    -- Pass 1: name match + at least 2 submodels
    for _, bg in ipairs(groups) do
        if bg.num > 1 and FACE_NAMES[string.lower(bg.name)] then
            return { id = bg.id, name = bg.name, max = bg.num - 1 }
        end
    end
    -- Pass 2: any bodygroup with >2 submodels (likely expression group)
    for _, bg in ipairs(groups) do
        if bg.num > 2 then
            return { id = bg.id, name = bg.name, max = bg.num - 1 }
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Build a full flex ID map for all presets on a model (called once on init).
-- Returns { [gestureID] = { [flexID] = weight, ... }, ... }
-- Also returns a set of all flex IDs used by any preset (for reset).
---------------------------------------------------------------------------
function vrmod.Expression.BuildFlexMap(ent)
    local map = {}
    local allFlexIDs = {}
    local anyFound = false

    for gestureID = 0, vrmod.Expression.GESTURE_COUNT - 1 do
        local preset = vrmod.Expression.PRESETS[gestureID]
        if not preset then continue end

        local resolved = {}
        for flexName, weight in pairs(preset.flexes) do
            local id = ent:GetFlexIDByName(flexName)
            if id then
                resolved[id] = weight
                allFlexIDs[id] = true
                anyFound = true
            end
        end
        map[gestureID] = resolved
    end

    return anyFound and map or nil, allFlexIDs
end

---------------------------------------------------------------------------
-- Custom preset persistence (save/load user edits to DATA folder)
---------------------------------------------------------------------------
local CUSTOM_DIR = "vrmod_expression/"
local CUSTOM_FILE = CUSTOM_DIR .. "custom_presets.txt"

-- Deep-copy original defaults so they can be restored after user edits
vrmod.Expression.DEFAULT_FLEXES = vrmod.Expression.DEFAULT_FLEXES or {}
for i = 0, vrmod.Expression.GESTURE_COUNT - 1 do
    local preset = vrmod.Expression.PRESETS[i]
    if preset and not vrmod.Expression.DEFAULT_FLEXES[i] then
        vrmod.Expression.DEFAULT_FLEXES[i] = table.Copy(preset.flexes)
    end
end

--- Save only the gestures that differ from defaults.
function vrmod.Expression.SaveCustomPresets()
    file.CreateDir(CUSTOM_DIR)
    local data = {}
    for i = 1, vrmod.Expression.GESTURE_COUNT - 1 do
        local preset = vrmod.Expression.PRESETS[i]
        if not preset then continue end
        local def = vrmod.Expression.DEFAULT_FLEXES[i] or {}

        local isDifferent = false
        for k, v in pairs(preset.flexes) do
            if def[k] ~= v then isDifferent = true; break end
        end
        if not isDifferent then
            for k in pairs(def) do
                if preset.flexes[k] == nil then isDifferent = true; break end
            end
        end

        if isDifferent then
            data[tostring(i)] = preset.flexes
        end
    end
    file.Write(CUSTOM_FILE, util.TableToJSON(data, true))
end

--- Load custom presets from disk, overwrite PRESETS.flexes for changed gestures.
function vrmod.Expression.LoadCustomPresets()
    if not file.Exists(CUSTOM_FILE, "DATA") then return end
    local raw = file.Read(CUSTOM_FILE, "DATA")
    if not raw or raw == "" then return end
    local ok, data = pcall(util.JSONToTable, raw)
    if not ok or not data then return end

    for idStr, flexes in pairs(data) do
        local id = tonumber(idStr)
        if id and vrmod.Expression.PRESETS[id] and type(flexes) == "table" then
            vrmod.Expression.PRESETS[id].flexes = flexes
        end
    end
    print("[VRMod Expression] Custom presets loaded")
end

--- Set a single flex weight in a preset (debounced save).
function vrmod.Expression.SetPresetFlex(gestureID, flexName, weight)
    local preset = vrmod.Expression.PRESETS[gestureID]
    if not preset then return end

    if weight <= 0.001 then
        preset.flexes[flexName] = nil
    else
        preset.flexes[flexName] = weight
    end
    vrmod.Expression._lastModel = nil -- force flex map rebuild next frame

    -- Debounced disk write (1s after last change)
    if timer.Exists("vrmod_expr_save") then timer.Remove("vrmod_expr_save") end
    timer.Create("vrmod_expr_save", 1, 1, function()
        vrmod.Expression.SaveCustomPresets()
    end)
end

--- Reset a single gesture to its hardcoded default.
function vrmod.Expression.ResetPreset(gestureID)
    local def = vrmod.Expression.DEFAULT_FLEXES[gestureID]
    if def then
        vrmod.Expression.PRESETS[gestureID].flexes = table.Copy(def)
        vrmod.Expression.SaveCustomPresets()
        vrmod.Expression._lastModel = nil
    end
end

--- Reset all gestures to hardcoded defaults and delete the custom file.
function vrmod.Expression.ResetAllPresets()
    for i = 0, vrmod.Expression.GESTURE_COUNT - 1 do
        local def = vrmod.Expression.DEFAULT_FLEXES[i]
        if def then
            vrmod.Expression.PRESETS[i].flexes = table.Copy(def)
        end
    end
    if file.Exists(CUSTOM_FILE, "DATA") then
        file.Delete(CUSTOM_FILE)
    end
    vrmod.Expression._lastModel = nil
end

--- Get all flex names on the current local player's model (CL utility).
function vrmod.Expression.GetModelFlexNames()
    if SERVER then return {} end
    local ply = LocalPlayer()
    if not IsValid(ply) then return {} end

    local names = {}
    for i = 0, ply:GetFlexNum() - 1 do
        local name = ply:GetFlexName(i)
        if name and name ~= "" then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

-- Auto-load custom presets on file init
vrmod.Expression.LoadCustomPresets()
