--[[
    Module 13: RealMech - Automatic Realistic Gun Mechanics
    Interact: VR interaction handlers (slide grab, fire mode switch)

    VRMod_Input for button events, VRMod_Tracking for position tracking.
]]

AddCSLuaFile()
if SERVER then return end

-- ============================================================================
-- Dependencies (available after core.lua and animate.lua load)
-- ============================================================================

-- vrmod.RealMech.state is set by animate.lua
-- vrmod.RealMech.cv is set by core.lua
-- vrmod.RealMech.ShouldSkipWeapon is set by core.lua
-- All are accessed at hook runtime, not load time.

-- ============================================================================
-- Slide Grab: Left Hand Grabs and Pulls the Slide
-- ============================================================================

local function TrySlideGrab(ply, wep, cache, vm)
    local state = vrmod.RealMech.state
    if not state then return false end

    if not cache.hasSlide then return false end
    if not g_VR.tracking or not g_VR.tracking.pose_lefthand then return false end

    local slideWorldPos = vm:GetBonePosition(cache.slideIdx)
    if not slideWorldPos then return false end

    local leftHandPos = g_VR.tracking.pose_lefthand.pos
    local grabRange = vrmod.RealMech.cv.slide_grab_range:GetFloat()

    if leftHandPos:Distance(slideWorldPos) < grabRange then
        state.slideGrabbed = true
        state.slideGrabOffset = state.slidePos

        -- Store initial grab hand position for delta tracking
        state._grabStartPos = leftHandPos
        state._grabSlideWorldPos = slideWorldPos

        return true
    end

    return false
end

local function ReleaseSlideGrab(ply, cache)
    local state = vrmod.RealMech.state
    if not state or not state.slideGrabbed then return end

    state.slideGrabbed = false

    -- If pulled back far enough, consider it a rack
    if state.slidePos >= cache.blowbackAmount * 0.7 then
        -- Racking action: chamber a round
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            -- Play racking sound
            ply:EmitSound("weapons/m4a1/m4a1_boltpull.wav", 60, 100, 0.5)

            -- Release slide lock
            if state.slideLockedBack then
                state.slideLockedBack = false
            end
        end
    end

    state._grabStartPos = nil
    state._grabSlideWorldPos = nil
end

-- ============================================================================
-- VRMod_Input Hook: Button Events
-- ============================================================================

hook.Add("VRMod_Input", "VRRealMech_Input", function(action, pressed)
    if not vrmod.RealMech.IsEnabled() then return end
    if not g_VR or not g_VR.active then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if vrmod.RealMech.ShouldSkipWeapon(wep) then return end

    local class = wep:GetClass()
    local cache = vrmod.RealMech.GetWeaponCache(class)
    if not cache or not cache.analyzed then return end

    local state = vrmod.RealMech.state
    local cv = vrmod.RealMech.cv

    -- ===== SLIDE GRAB =====
    if cv.slide_grab_enable:GetBool() and cache.hasSlide then
        if action == "boolean_left_pickup" then
            if pressed then
                local vm = ply:GetViewModel()
                if IsValid(vm) then
                    TrySlideGrab(ply, wep, cache, vm)
                end
            else
                if state.slideGrabbed then
                    ReleaseSlideGrab(ply, cache)
                end
            end
        end
    end

    -- ===== FIRE MODE SWITCH =====
    if cv.selector_enable:GetBool() and cache.hasSafety then
        if action == "boolean_secondaryfire" and pressed then
            -- Cycle firemode: 1 -> 2 -> 3 -> 1 (Safe/Semi/Auto)
            state.firemodeIndex = state.firemodeIndex + 1
            if state.firemodeIndex > 3 then
                state.firemodeIndex = 1
            end

            -- Set target angle for selector bone animation
            -- 0 = position 1, 45 = position 2, 90 = position 3
            state.targetSelectorAngle = (state.firemodeIndex - 1) * 45

            -- Play switch sound
            ply:EmitSound("weapons/smg1/switch_single.wav", 60, 100, 0.4)
        end
    end

    -- ===== SLIDE RELEASE (optional: use reload button) =====
    if cache.hasSlide then
        if action == "boolean_reload" and pressed then
            if state.slideLockedBack then
                state.slideLockedBack = false
                state.slidePos = cache.blowbackAmount * 0.3
                ply:EmitSound("weapons/m4a1/m4a1_boltpull.wav", 60, 120, 0.4)
            end
        end
    end
end)

-- ============================================================================
-- VRMod_Tracking Hook: Slide Position Tracking During Grab
-- ============================================================================

hook.Add("VRMod_Tracking", "VRRealMech_Tracking", function()
    local state = vrmod.RealMech.state
    if not state or not state.slideGrabbed then return end
    if not g_VR or not g_VR.active then return end
    if not g_VR.tracking or not g_VR.tracking.pose_lefthand then
        state.slideGrabbed = false
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then
        state.slideGrabbed = false
        return
    end

    local vm = ply:GetViewModel()
    if not IsValid(vm) then
        state.slideGrabbed = false
        return
    end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        state.slideGrabbed = false
        return
    end

    local cache = vrmod.RealMech.GetWeaponCache(wep:GetClass())
    if not cache or not cache.hasSlide then
        state.slideGrabbed = false
        return
    end

    -- Calculate hand movement along slide axis
    local leftHandPos = g_VR.tracking.pose_lefthand.pos

    if state._grabStartPos then
        -- Movement delta from grab start position
        local delta = leftHandPos - state._grabStartPos
        -- Project onto slide direction
        local projection = delta:Dot(cache.slideDir)

        -- Slide moves in the negative direction of slideDir
        -- (pulling back = moving along negative slideDir)
        state.slidePos = math.Clamp(
            state.slideGrabOffset + math.abs(projection),
            0,
            cache.blowbackAmount
        )
    end
end)

print("[RealMech] Interact loaded - VR interaction system")
