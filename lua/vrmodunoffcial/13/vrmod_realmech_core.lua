--[[
    Module 13: RealMech - Automatic Realistic Gun Mechanics
    Core: Bone detection dictionary, weapon analysis engine, caching, ConVars

    任意の非VR武器のViewmodelボーンを自動検出し、
    ArcVR風のリアル銃器メカニクスを付与する。
]]

AddCSLuaFile()
if SERVER then return end

-- Defensive init
g_VR = g_VR or {}
vrmod = vrmod or {}
vrmod.RealMech = vrmod.RealMech or {}
vrmod.RealMech._cache = vrmod.RealMech._cache or {}

-- ============================================================================
-- ConVar Definitions
-- ============================================================================

CreateClientConVar("vrmod_unoff_realmech_enable", "1", true, false, "Enable RealMech automatic gun mechanics")
CreateClientConVar("vrmod_unoff_realmech_slide_enable", "1", true, false, "Enable slide blowback animation")
CreateClientConVar("vrmod_unoff_realmech_trigger_enable", "1", true, false, "Enable trigger pull animation")
CreateClientConVar("vrmod_unoff_realmech_bullet_enable", "1", true, false, "Enable bullet bone visibility")
CreateClientConVar("vrmod_unoff_realmech_hammer_enable", "1", true, false, "Enable hammer animation")
CreateClientConVar("vrmod_unoff_realmech_selector_enable", "1", true, false, "Enable fire selector animation")
CreateClientConVar("vrmod_unoff_realmech_slide_speed", "15", true, false, "Slide return speed multiplier")
CreateClientConVar("vrmod_unoff_realmech_blowback", "2.5", true, false, "Default blowback distance")
CreateClientConVar("vrmod_unoff_realmech_trigger_angle", "15", true, false, "Trigger pull angle in degrees")
CreateClientConVar("vrmod_unoff_realmech_slide_grab_enable", "1", true, false, "Enable VR slide grab")
CreateClientConVar("vrmod_unoff_realmech_slide_grab_range", "10", true, false, "Slide grab detection range")
CreateClientConVar("vrmod_unoff_realmech_slide_dir", "auto", true, false, "Slide direction: auto, -x, +x, -y, +y, -z, +z")
CreateClientConVar("vrmod_unoff_realmech_reload_enable", "1", true, false, "Enable animation interact reload system")
CreateClientConVar("vrmod_unoff_realmech_reload_freeze_delay", "0.3", true, false, "Seconds of animation before freezing")
CreateClientConVar("vrmod_unoff_realmech_reload_freeze_rate", "0.01", true, false, "Playback rate when animation is frozen")
CreateClientConVar("vrmod_unoff_realmech_reload_idle_return", "1", true, false, "On vrmagent pickup: 1=return to idle (pistol), 0=keep frozen pose (revolver/break-action)")
CreateClientConVar("vrmod_unoff_realmech_debug", "0", true, false, "Debug: show detected bones in console")

-- ConVar cache (never call GetConVar in per-frame hooks)
local cv_enable = GetConVar("vrmod_unoff_realmech_enable")
local cv_slide_enable = GetConVar("vrmod_unoff_realmech_slide_enable")
local cv_trigger_enable = GetConVar("vrmod_unoff_realmech_trigger_enable")
local cv_bullet_enable = GetConVar("vrmod_unoff_realmech_bullet_enable")
local cv_hammer_enable = GetConVar("vrmod_unoff_realmech_hammer_enable")
local cv_selector_enable = GetConVar("vrmod_unoff_realmech_selector_enable")
local cv_slide_speed = GetConVar("vrmod_unoff_realmech_slide_speed")
local cv_blowback = GetConVar("vrmod_unoff_realmech_blowback")
local cv_trigger_angle = GetConVar("vrmod_unoff_realmech_trigger_angle")
local cv_slide_grab_enable = GetConVar("vrmod_unoff_realmech_slide_grab_enable")
local cv_slide_grab_range = GetConVar("vrmod_unoff_realmech_slide_grab_range")
local cv_slide_dir = GetConVar("vrmod_unoff_realmech_slide_dir")
local cv_reload_enable = GetConVar("vrmod_unoff_realmech_reload_enable")
local cv_reload_freeze_delay = GetConVar("vrmod_unoff_realmech_reload_freeze_delay")
local cv_reload_freeze_rate = GetConVar("vrmod_unoff_realmech_reload_freeze_rate")
local cv_reload_idle_return = GetConVar("vrmod_unoff_realmech_reload_idle_return")
local cv_debug = GetConVar("vrmod_unoff_realmech_debug")

-- Export cached ConVars for other files
vrmod.RealMech.cv = {
    enable = cv_enable,
    slide_enable = cv_slide_enable,
    trigger_enable = cv_trigger_enable,
    bullet_enable = cv_bullet_enable,
    hammer_enable = cv_hammer_enable,
    selector_enable = cv_selector_enable,
    slide_speed = cv_slide_speed,
    blowback = cv_blowback,
    trigger_angle = cv_trigger_angle,
    slide_grab_enable = cv_slide_grab_enable,
    slide_grab_range = cv_slide_grab_range,
    slide_dir = cv_slide_dir,
    reload_enable = cv_reload_enable,
    reload_freeze_delay = cv_reload_freeze_delay,
    reload_freeze_rate = cv_reload_freeze_rate,
    reload_idle_return = cv_reload_idle_return,
    debug = cv_debug,
}

-- ============================================================================
-- Self-register defaults (since we can't edit vrmod_defaults.lua)
-- ============================================================================

timer.Simple(0, function()
    if VRMOD_DEFAULTS then
        VRMOD_DEFAULTS["realmech"] = {
            vrmod_unoff_realmech_enable = 1,
            vrmod_unoff_realmech_slide_enable = 1,
            vrmod_unoff_realmech_trigger_enable = 1,
            vrmod_unoff_realmech_bullet_enable = 1,
            vrmod_unoff_realmech_hammer_enable = 1,
            vrmod_unoff_realmech_selector_enable = 1,
            vrmod_unoff_realmech_slide_speed = 15,
            vrmod_unoff_realmech_blowback = 2.5,
            vrmod_unoff_realmech_trigger_angle = 15,
            vrmod_unoff_realmech_slide_grab_enable = 1,
            vrmod_unoff_realmech_slide_grab_range = 10,
            vrmod_unoff_realmech_slide_dir = "auto",
            vrmod_unoff_realmech_reload_enable = 1,
            vrmod_unoff_realmech_reload_freeze_delay = 0.3,
            vrmod_unoff_realmech_reload_freeze_rate = 0.01,
            vrmod_unoff_realmech_reload_idle_return = 1,
            vrmod_unoff_realmech_debug = 0,
        }
    end
end)

-- ============================================================================
-- Bone Category Dictionary
-- ============================================================================

local BONE_CATEGORIES = {
    slide = {
        keywords = {
            "slide", "bolt", "charging", "chandle", "cocking",
            "bolt_carrier", "pump", "handle_charge", "action",
        },
    },
    trigger = {
        keywords = {
            "trigger", "trig",
        },
    },
    magazine = {
        -- Reference only: Module 4 handles magazine hide/show
        keywords = {
            "mag", "clip", "magazine",
        },
    },
    bullet = {
        keywords = {
            "bullet", "round", "cartridge", "chambered",
            "shell_loaded", "bullet_in",
        },
    },
    hammer = {
        keywords = {
            "hammer", "firing_pin", "striker", "cock",
        },
    },
    safety = {
        keywords = {
            "safety", "selector", "fire_select", "firesel",
            "firemode", "switch_fire", "semi_auto",
        },
    },
    muzzle = {
        -- Reference only: used for effect origin
        keywords = {
            "muzzle", "flash_point", "barrel_end",
        },
    },
    ejector = {
        keywords = {
            "eject", "ejection", "case_eject", "shell_eject",
        },
    },
    slidelock = {
        keywords = {
            "slidelock", "slide_lock", "slide_stop", "slidestop",
            "bolt_catch", "bolt_lock",
        },
    },
}

-- Export for other files
vrmod.RealMech.BONE_CATEGORIES = BONE_CATEGORIES

-- ============================================================================
-- Bone Name Matching (same pattern as Module 4 IsMagazineBone)
-- ============================================================================

local function MatchesBoneCategory(boneName, category)
    local lowerBone = string.lower(boneName)
    local cat = BONE_CATEGORIES[category]
    if not cat then return false end

    for _, keyword in ipairs(cat.keywords) do
        if string.find(lowerBone, keyword, 1, true) then
            return true
        end
    end
    return false
end

-- Check if bone matches ANY category, return category name
local function ClassifyBone(boneName)
    local lowerBone = string.lower(boneName)

    -- Check in priority order (slide before trigger to avoid
    -- bones like "slide_trigger" being classified as trigger)
    local priority = {
        "slidelock", "slide", "trigger", "hammer", "safety",
        "bullet", "magazine", "ejector", "muzzle",
    }

    for _, category in ipairs(priority) do
        local cat = BONE_CATEGORIES[category]
        for _, keyword in ipairs(cat.keywords) do
            if string.find(lowerBone, keyword, 1, true) then
                return category
            end
        end
    end
    return nil
end

-- ============================================================================
-- Weapon Exclusion Check
-- ============================================================================

function vrmod.RealMech.ShouldSkipWeapon(wep)
    if not IsValid(wep) then return true end

    -- Skip ArcVR weapons
    if wep.ArcticVR then return true end
    if wep.ArcticVRNade then return true end

    -- Skip VR-class and tool weapons
    local class = string.lower(wep:GetClass())
    if string.find(class, "vr", 1, true) then return true end
    if string.find(class, "gmod_tool", 1, true) then return true end
    if string.find(class, "physgun", 1, true) then return true end
    if string.find(class, "camera", 1, true) then return true end

    return false
end

-- ============================================================================
-- Slide Direction Detection (manual override + auto-detection)
-- ============================================================================

-- Manual direction presets for ConVar vrmod_unoff_realmech_slide_dir
local SLIDE_DIR_PRESETS = {
    ["-x"] = Vector(-1, 0, 0),
    ["+x"] = Vector(1, 0, 0),
    ["-y"] = Vector(0, -1, 0),
    ["+y"] = Vector(0, 1, 0),
    ["-z"] = Vector(0, 0, -1),
    ["+z"] = Vector(0, 0, 1),
}

local function DetectSlideDirection(vm, slideIdx)
    -- Check for manual override first
    local dirStr = cv_slide_dir:GetString()
    if dirStr ~= "auto" and SLIDE_DIR_PRESETS[dirStr] then
        return SLIDE_DIR_PRESETS[dirStr]
    end

    if not IsValid(vm) then return Vector(-1, 0, 0) end

    -- Method 1: Use bone matrix local axes
    -- ManipulateBonePosition works in bone-local space
    -- For most viewmodel slide bones, the slide moves along
    -- the bone's local X axis (backward = negative X)
    local boneMatrix = vm:GetBoneMatrix(slideIdx)
    if boneMatrix then
        -- The bone's local forward direction
        -- Slides typically move backward along the bone's forward axis
        local forward = boneMatrix:GetForward()
        if forward and forward:LengthSqr() > 0.001 then
            -- ManipulateBonePosition is in bone-LOCAL space
            -- So we return a local-space direction vector
            -- Most slide bones: -X is backward (rearward motion)
            return Vector(-1, 0, 0)
        end
    end

    -- Method 2: Parent-child position delta (legacy fallback)
    local parentIdx = vm:GetBoneParent(slideIdx)
    if parentIdx and parentIdx >= 0 then
        local slidePos = vm:GetBonePosition(slideIdx)
        local parentPos = vm:GetBonePosition(parentIdx)

        if slidePos and parentPos then
            local dir = (slidePos - parentPos)
            if dir:LengthSqr() > 0.001 then
                dir:Normalize()
                -- Convert world-space direction to bone-local direction
                -- (approximation: just use the dominant axis)
                local ax = math.abs(dir.x)
                local ay = math.abs(dir.y)
                local az = math.abs(dir.z)
                if ax >= ay and ax >= az then
                    return Vector(dir.x > 0 and 1 or -1, 0, 0)
                elseif ay >= ax and ay >= az then
                    return Vector(0, dir.y > 0 and 1 or -1, 0)
                else
                    return Vector(0, 0, dir.z > 0 and 1 or -1)
                end
            end
        end
    end

    -- Fallback: ManipulateBonePosition local space
    -- Most Source Engine viewmodel slide bones move along -X
    return Vector(-1, 0, 0)
end

-- ============================================================================
-- Trigger Pull Offset Estimation
-- ============================================================================

local function EstimateTriggerPull()
    local angle = cv_trigger_angle:GetFloat()
    return {
        pos = Vector(0, 0, 0),
        ang = Angle(angle, 0, 0),
    }
end

-- ============================================================================
-- Weapon Analysis Engine
-- ============================================================================

function vrmod.RealMech.AnalyzeWeapon(wep)
    if not IsValid(wep) then return nil end

    local class = wep:GetClass()

    -- Check cache first
    if vrmod.RealMech._cache[class] then
        return vrmod.RealMech._cache[class]
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return nil end

    local boneCount = vm:GetBoneCount()
    if not boneCount or boneCount <= 0 then return nil end

    -- Build analysis result
    local result = {
        slideIdx = nil,
        triggerIdx = nil,
        bulletIdx = {},
        hammerIdx = nil,
        safetyIdx = nil,
        ejectorIdx = nil,
        muzzleIdx = nil,
        slidelockIdx = nil,
        magazineIdx = {},
        slideDir = Vector(0, 0, -1),
        blowbackAmount = cv_blowback:GetFloat(),
        triggerPullOffset = EstimateTriggerPull(),
        hasSlide = false,
        hasTrigger = false,
        hasBullet = false,
        hasHammer = false,
        hasSafety = false,
        hasEjector = false,
        hasMuzzle = false,
        hasSlidelock = false,
        hasMagazine = false,
        boneMap = {},  -- category -> {idx, name}[]
        analyzed = true,
    }

    -- Scan all bones
    for i = 0, boneCount - 1 do
        local boneName = vm:GetBoneName(i)
        if boneName and boneName ~= "" then
            local category = ClassifyBone(boneName)

            if category then
                -- Store in bone map for debug
                if not result.boneMap[category] then
                    result.boneMap[category] = {}
                end
                table.insert(result.boneMap[category], {idx = i, name = boneName})

                -- Assign to specific slots
                if category == "slide" and not result.slideIdx then
                    result.slideIdx = i
                    result.hasSlide = true
                elseif category == "trigger" and not result.triggerIdx then
                    result.triggerIdx = i
                    result.hasTrigger = true
                elseif category == "bullet" then
                    table.insert(result.bulletIdx, i)
                    result.hasBullet = true
                elseif category == "hammer" and not result.hammerIdx then
                    result.hammerIdx = i
                    result.hasHammer = true
                elseif category == "safety" and not result.safetyIdx then
                    result.safetyIdx = i
                    result.hasSafety = true
                elseif category == "ejector" and not result.ejectorIdx then
                    result.ejectorIdx = i
                    result.hasEjector = true
                elseif category == "muzzle" and not result.muzzleIdx then
                    result.muzzleIdx = i
                    result.hasMuzzle = true
                elseif category == "slidelock" and not result.slidelockIdx then
                    result.slidelockIdx = i
                    result.hasSlidelock = true
                elseif category == "magazine" then
                    table.insert(result.magazineIdx, i)
                    result.hasMagazine = true
                end
            end
        end
    end

    -- Auto-detect slide direction
    if result.hasSlide then
        result.slideDir = DetectSlideDirection(vm, result.slideIdx)
    end

    -- Cache the result
    vrmod.RealMech._cache[class] = result

    -- Debug output
    if cv_debug:GetBool() then
        vrmod.RealMech.PrintAnalysis(class, result)
    end

    return result
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

function vrmod.RealMech.IsEnabled()
    return cv_enable:GetBool()
end

function vrmod.RealMech.GetWeaponCache(weaponClass)
    return vrmod.RealMech._cache[weaponClass]
end

function vrmod.RealMech.InvalidateCache(weaponClass)
    if weaponClass then
        vrmod.RealMech._cache[weaponClass] = nil
    else
        vrmod.RealMech._cache = {}
    end
end

function vrmod.RealMech.PrintAnalysis(class, result)
    print("=== [RealMech] Bone Analysis: " .. class .. " ===")

    local categories = {
        "slide", "trigger", "bullet", "hammer", "safety",
        "ejector", "muzzle", "slidelock", "magazine",
    }

    for _, cat in ipairs(categories) do
        local bones = result.boneMap[cat]
        if bones and #bones > 0 then
            for _, b in ipairs(bones) do
                print(string.format("  [%s] bone %d: %s", cat, b.idx, b.name))
            end
        end
    end

    if result.hasSlide then
        local d = result.slideDir
        print(string.format("  SlideDir: (%.2f, %.2f, %.2f)", d.x, d.y, d.z))
        print(string.format("  BlowbackAmount: %.2f", result.blowbackAmount))
    end

    local found = 0
    for _, cat in ipairs(categories) do
        if result.boneMap[cat] and #result.boneMap[cat] > 0 then
            found = found + 1
        end
    end
    print(string.format("  Total categories detected: %d / %d", found, #categories))
    print("=== [RealMech] End ===")
end

-- ============================================================================
-- Debug Console Command
-- ============================================================================

concommand.Add("vrmod_realmech_bones", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        print("[RealMech] No active weapon")
        return
    end

    local class = wep:GetClass()
    print("[RealMech] Active weapon: " .. class)

    -- Force re-analysis
    vrmod.RealMech._cache[class] = nil
    local result = vrmod.RealMech.AnalyzeWeapon(wep)

    if not result then
        print("[RealMech] Analysis failed (no viewmodel?)")
        return
    end

    vrmod.RealMech.PrintAnalysis(class, result)

    -- Also print ALL bones for reference
    local vm = ply:GetViewModel()
    if IsValid(vm) then
        print("")
        print("=== ALL VIEWMODEL BONES ===")
        local count = vm:GetBoneCount()
        for i = 0, count - 1 do
            local name = vm:GetBoneName(i)
            local parent = vm:GetBoneParent(i)
            local parentName = parent >= 0 and vm:GetBoneName(parent) or "(root)"
            print(string.format("  [%d] %s (parent: %s)", i, name, parentName))
        end
        print(string.format("  Total: %d bones", count))
    end
end)

-- Alias for convenience
concommand.Add("vrmod_realmech_refresh", function()
    vrmod.RealMech.InvalidateCache()
    print("[RealMech] Cache cleared. Bones will be re-analyzed on next frame.")
end)

print("[RealMech] Core loaded - Module 13 Realistic Gun Mechanics")
