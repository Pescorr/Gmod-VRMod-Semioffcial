--[[
    Module 13: RealMech - Automatic Realistic Gun Mechanics
    Animate: Per-frame bone animation (VRMod_PreRender hook)

    Slide blowback, trigger pull, bullet visibility,
    hammer tap, fire selector rotation.
]]

AddCSLuaFile()
if SERVER then return end

-- ============================================================================
-- Runtime State
-- ============================================================================

local state = {
    slidePos = 0,
    slidePrevPos = 0,
    triggerDelta = 0,
    hammerEndTime = 0,
    hammerReturnDelta = 0,
    selectorAngle = 0,
    targetSelectorAngle = 0,
    chambered = true,
    lastClip = -1,
    lastWeaponClass = "",
    slideGrabbed = false,
    slideGrabOffset = 0,
    slideLockedBack = false,
    firemodeIndex = 1,
    ejectorEndTime = 0,
    needsReset = false,
    hasDetectedBones = false,
}

-- Export state for interact.lua
vrmod.RealMech = vrmod.RealMech or {}
vrmod.RealMech.state = state

-- ============================================================================
-- Bone Reset
-- ============================================================================

local function ResetBone(vm, idx)
    if not idx then return end
    vm:ManipulateBonePosition(idx, Vector(0, 0, 0))
    vm:ManipulateBoneAngles(idx, Angle(0, 0, 0))
    vm:ManipulateBoneScale(idx, Vector(1, 1, 1))
end

local function ResetAllBones(vm, cache)
    if not IsValid(vm) or not cache then return end

    ResetBone(vm, cache.slideIdx)
    ResetBone(vm, cache.triggerIdx)
    ResetBone(vm, cache.hammerIdx)
    ResetBone(vm, cache.safetyIdx)
    ResetBone(vm, cache.slidelockIdx)
    ResetBone(vm, cache.ejectorIdx)

    if cache.bulletIdx then
        for _, idx in ipairs(cache.bulletIdx) do
            ResetBone(vm, idx)
        end
    end
end

local function ResetState()
    state.slidePos = 0
    state.slidePrevPos = 0
    state.triggerDelta = 0
    state.hammerEndTime = 0
    state.hammerReturnDelta = 0
    state.selectorAngle = 0
    state.targetSelectorAngle = 0
    state.lastClip = -1
    state.slideGrabbed = false
    state.slideGrabOffset = 0
    state.slideLockedBack = false
    state.firemodeIndex = 1
    state.ejectorEndTime = 0
    state.hasDetectedBones = false
end

-- ============================================================================
-- Individual Animation Functions
-- ============================================================================

local function AnimateSlide(vm, cache, wep, dt, currentClip)
    local cv = vrmod.RealMech.cv

    -- Shot detection: clip decreased while not zero-to-zero
    if currentClip < state.lastClip and state.lastClip > 0 then
        state.slidePos = cache.blowbackAmount
        state.hammerEndTime = CurTime() + 0.08
        state.chambered = currentClip > 0
        state.ejectorEndTime = CurTime() + 0.15

        -- Release slide lock if we just reloaded
        if state.slideLockedBack then
            state.slideLockedBack = false
        end
    end

    -- Slide lock on empty
    if currentClip <= 0 and state.lastClip > 0 then
        state.slideLockedBack = true
        state.slidePos = cache.blowbackAmount * 0.95
    end

    -- Release slide lock when ammo restored (reload happened externally)
    if currentClip > 0 and state.slideLockedBack then
        state.slideLockedBack = false
        state.slidePos = cache.blowbackAmount * 0.5
    end

    -- Slide return spring (unless grabbed or locked back)
    if not state.slideGrabbed and not state.slideLockedBack then
        local speed = cv.slide_speed:GetFloat()
        state.slidePos = math.Approach(state.slidePos, 0, speed * dt)
    end

    -- Apply slide bone position
    vm:ManipulateBonePosition(cache.slideIdx,
        state.slidePos * cache.slideDir)

    -- Slidelock bone visual
    if cache.hasSlidelock and cache.slidelockIdx then
        if state.slideLockedBack then
            vm:ManipulateBonePosition(cache.slidelockIdx, Vector(0, 0, -0.3))
        else
            vm:ManipulateBonePosition(cache.slidelockIdx, Vector(0, 0, 0))
        end
    end

    state.slidePrevPos = state.slidePos
end

local function AnimateTrigger(vm, cache, dt)
    -- Read analog trigger from VR controller
    local targetDelta = 0
    if g_VR.input and g_VR.input.vector1_primaryfire then
        targetDelta = g_VR.input.vector1_primaryfire
    end

    -- Smooth interpolation
    state.triggerDelta = Lerp(dt * 20, state.triggerDelta, targetDelta)

    -- Apply rotation
    local pullOffset = cache.triggerPullOffset
    vm:ManipulateBoneAngles(cache.triggerIdx,
        Angle(
            pullOffset.ang.p * state.triggerDelta,
            pullOffset.ang.y * state.triggerDelta,
            pullOffset.ang.r * state.triggerDelta
        ))
    vm:ManipulateBonePosition(cache.triggerIdx,
        pullOffset.pos * state.triggerDelta)
end

local function AnimateBullets(vm, cache, currentClip)
    -- Show/hide bullet bones based on ammo count
    for i, boneIdx in ipairs(cache.bulletIdx) do
        if currentClip >= i then
            vm:ManipulateBoneScale(boneIdx, Vector(1, 1, 1))
        else
            vm:ManipulateBoneScale(boneIdx, Vector(0, 0, 0))
        end
    end
end

local function AnimateHammer(vm, cache, dt)
    -- BoneTap pattern: quick forward strike, then slow return
    if CurTime() < state.hammerEndTime then
        -- Hammer in "fired" position
        vm:ManipulateBoneAngles(cache.hammerIdx, Angle(20, 0, 0))
        state.hammerReturnDelta = 1.0
    else
        -- Return to rest
        state.hammerReturnDelta = math.Approach(state.hammerReturnDelta, 0, dt * 8)
        vm:ManipulateBoneAngles(cache.hammerIdx,
            Angle(20 * state.hammerReturnDelta, 0, 0))
    end
end

local function AnimateSelector(vm, cache, dt)
    -- Smooth approach to target angle (MiscLerps pattern)
    state.selectorAngle = math.ApproachAngle(
        state.selectorAngle,
        state.targetSelectorAngle,
        500 * dt
    )

    vm:ManipulateBoneAngles(cache.safetyIdx,
        Angle(0, state.selectorAngle, 0))
end

local function AnimateEjector(vm, cache)
    -- Brief visibility pulse when firing (shell ejection visual)
    if cache.hasEjector and cache.ejectorIdx then
        if CurTime() < state.ejectorEndTime then
            vm:ManipulateBoneScale(cache.ejectorIdx, Vector(1, 1, 1))
        else
            vm:ManipulateBoneScale(cache.ejectorIdx, Vector(0, 0, 0))
        end
    end
end

-- ============================================================================
-- Main Animation Hook (VRMod_PreRender)
-- ============================================================================

hook.Add("VRMod_PreRender", "VRRealMech_Animate", function()
    -- Guard checks
    if not g_VR or not g_VR.active then return end
    if not vrmod.RealMech.IsEnabled() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local wep = ply:GetActiveWeapon()
    local vm = ply:GetViewModel()

    if not IsValid(wep) or not IsValid(vm) then
        if state.hasDetectedBones then
            ResetAllBones(vm, vrmod.RealMech.GetWeaponCache(state.lastWeaponClass))
            ResetState()
        end
        return
    end

    -- Exclusion check
    if vrmod.RealMech.ShouldSkipWeapon(wep) then
        if state.hasDetectedBones then
            ResetAllBones(vm, vrmod.RealMech.GetWeaponCache(state.lastWeaponClass))
            ResetState()
        end
        return
    end

    local class = wep:GetClass()
    local cv = vrmod.RealMech.cv

    -- Weapon change detection
    if class ~= state.lastWeaponClass then
        -- Reset previous weapon's bones
        if state.lastWeaponClass ~= "" then
            local prevCache = vrmod.RealMech.GetWeaponCache(state.lastWeaponClass)
            ResetAllBones(vm, prevCache)
        end

        state.lastWeaponClass = class
        state.lastClip = wep:Clip1()
        state.slidePos = 0
        state.slidePrevPos = 0
        state.hammerEndTime = 0
        state.hammerReturnDelta = 0
        state.selectorAngle = 0
        state.targetSelectorAngle = 0
        state.firemodeIndex = 1
        state.slideGrabbed = false
        state.slideLockedBack = false
        state.ejectorEndTime = 0
        state.hasDetectedBones = false
    end

    -- Get or create weapon analysis cache
    local cache = vrmod.RealMech.GetWeaponCache(class)
    if not cache then
        cache = vrmod.RealMech.AnalyzeWeapon(wep)
    end
    if not cache or not cache.analyzed then return end

    state.hasDetectedBones = true

    local dt = FrameTime()
    local currentClip = wep:Clip1()

    -- === SLIDE BLOWBACK ===
    if cv.slide_enable:GetBool() and cache.hasSlide then
        AnimateSlide(vm, cache, wep, dt, currentClip)
    end

    -- === TRIGGER ===
    if cv.trigger_enable:GetBool() and cache.hasTrigger then
        AnimateTrigger(vm, cache, dt)
    end

    -- === BULLET VISIBILITY ===
    if cv.bullet_enable:GetBool() and cache.hasBullet then
        AnimateBullets(vm, cache, currentClip)
    end

    -- === HAMMER ===
    if cv.hammer_enable:GetBool() and cache.hasHammer then
        AnimateHammer(vm, cache, dt)
    end

    -- === FIRE SELECTOR ===
    if cv.selector_enable:GetBool() and cache.hasSafety then
        AnimateSelector(vm, cache, dt)
    end

    -- === EJECTOR ===
    if cache.hasEjector then
        AnimateEjector(vm, cache)
    end

    -- Update lastClip for next frame
    state.lastClip = currentClip
end)

-- ============================================================================
-- Cleanup Hooks
-- ============================================================================

local function CleanupAll()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local vm = ply:GetViewModel()
    if IsValid(vm) and state.lastWeaponClass ~= "" then
        local cache = vrmod.RealMech.GetWeaponCache(state.lastWeaponClass)
        ResetAllBones(vm, cache)
    end

    ResetState()
    state.lastWeaponClass = ""
end

hook.Add("VRMod_Exit", "VRRealMech_Cleanup", CleanupAll)
hook.Add("Shutdown", "VRRealMech_ShutdownCleanup", CleanupAll)

-- Also cleanup when RealMech is disabled via ConVar
cvars.AddChangeCallback("vrmod_unoff_realmech_enable", function(_, _, new)
    if new == "0" then
        CleanupAll()
    end
end, "VRRealMech_EnableToggle")

print("[RealMech] Animate loaded - bone animation system")
