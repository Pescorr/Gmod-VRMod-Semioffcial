--[[
    Module 20: Expression System — Gesture Detection Engine (CL)
    Classifies VR controller finger curl data into VRChat-style gesture IDs.
    Reads g_VR.input.skeleton_lefthand.fingerCurls / skeleton_righthand.fingerCurls.
]]

AddCSLuaFile()
if SERVER then return end

vrmod.Expression = vrmod.Expression or {}

---------------------------------------------------------------------------
-- Sensitivity presets: { openThreshold, curledThreshold }
-- Hysteresis: finger is "open" below openThreshold, "curled" above curledThreshold.
-- Between thresholds, previous state is kept (prevents chattering).
---------------------------------------------------------------------------
local SENSITIVITY = {
    [0] = { 0.25, 0.75 }, -- Low sensitivity (wide dead zone)
    [1] = { 0.30, 0.70 }, -- Medium (default)
    [2] = { 0.35, 0.65 }, -- High sensitivity (narrow dead zone)
}

local FRAMES_TO_CONFIRM = 3 -- Gesture must be stable for N frames before confirming

---------------------------------------------------------------------------
-- Gesture pattern definitions.
-- Each entry: { thumb, index, middle, ring, pinky }
-- true = curled, false = open, nil = don't care
-- Checked in priority order (first match wins).
---------------------------------------------------------------------------
local PATTERNS = {
    { id = 1, name = "Fist",        pattern = { true,  true,  true,  true,  true  } },
    { id = 2, name = "HandOpen",    pattern = { false, false, false, false, false } },
    { id = 3, name = "FingerPoint", pattern = { true,  false, true,  true,  true  } },
    { id = 4, name = "Victory",     pattern = { true,  false, false, true,  true  } },
    { id = 5, name = "RockNRoll",   pattern = { true,  false, true,  true,  false } },
    { id = 6, name = "HandGun",     pattern = { false, false, true,  true,  true  } },
    { id = 7, name = "ThumbsUp",    pattern = { false, true,  true,  true,  true  } },
}

---------------------------------------------------------------------------
-- Per-hand state tracking
---------------------------------------------------------------------------
local handState = {
    left = {
        fingerStates = { nil, nil, nil, nil, nil }, -- true=curled, false=open
        candidateGesture = 0,
        candidateFrames = 0,
        confirmedGesture = 0,
    },
    right = {
        fingerStates = { nil, nil, nil, nil, nil },
        candidateGesture = 0,
        candidateFrames = 0,
        confirmedGesture = 0,
    },
}

---------------------------------------------------------------------------
-- Classify finger curls into discrete states using hysteresis.
-- curls: array of 5 floats (0.0 = open, 1.0 = fully curled)
-- prevStates: previous finger states (modified in place)
-- sensitivity: index into SENSITIVITY table
-- Returns: modified prevStates table
---------------------------------------------------------------------------
local function ClassifyFingers(curls, prevStates, sensitivity)
    local thresholds = SENSITIVITY[sensitivity] or SENSITIVITY[1]
    local openTh, curledTh = thresholds[1], thresholds[2]

    for i = 1, 5 do
        local curl = curls[i]
        if not curl then
            prevStates[i] = nil
            continue
        end

        if curl >= curledTh then
            prevStates[i] = true -- curled
        elseif curl <= openTh then
            prevStates[i] = false -- open
        end
        -- Between thresholds: keep previous state (hysteresis)
    end

    return prevStates
end

---------------------------------------------------------------------------
-- Match classified finger states against gesture patterns.
-- Returns gesture ID (0 = Neutral if no pattern matches).
---------------------------------------------------------------------------
local function MatchGesture(fingerStates)
    -- If any finger state is nil, we have incomplete data
    for i = 1, 5 do
        if fingerStates[i] == nil then return 0 end
    end

    for _, def in ipairs(PATTERNS) do
        local match = true
        for i = 1, 5 do
            if def.pattern[i] ~= nil and def.pattern[i] ~= fingerStates[i] then
                match = false
                break
            end
        end
        if match then return def.id end
    end

    return 0 -- Neutral (no pattern matched)
end

---------------------------------------------------------------------------
-- Update one hand's gesture detection with frame stabilization.
-- Returns confirmed gesture ID.
---------------------------------------------------------------------------
local function UpdateHandGesture(state, curls, sensitivity)
    if not curls then
        state.confirmedGesture = 0
        state.candidateGesture = 0
        state.candidateFrames = 0
        return 0
    end

    ClassifyFingers(curls, state.fingerStates, sensitivity)
    local rawGesture = MatchGesture(state.fingerStates)

    if rawGesture == state.candidateGesture then
        state.candidateFrames = state.candidateFrames + 1
    else
        state.candidateGesture = rawGesture
        state.candidateFrames = 1
    end

    if state.candidateFrames >= FRAMES_TO_CONFIRM then
        state.confirmedGesture = state.candidateGesture
    end

    return state.confirmedGesture
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Detect gestures for both hands. Call once per frame.
--- Returns leftGesture, rightGesture (integer IDs 0-7)
function vrmod.Expression.DetectGestures(sensitivity)
    sensitivity = sensitivity or 1

    local leftCurls, rightCurls

    if g_VR and g_VR.input then
        local skelL = g_VR.input.skeleton_lefthand
        local skelR = g_VR.input.skeleton_righthand
        if skelL then leftCurls = skelL.fingerCurls end
        if skelR then rightCurls = skelR.fingerCurls end
    end

    local left = UpdateHandGesture(handState.left, leftCurls, sensitivity)
    local right = UpdateHandGesture(handState.right, rightCurls, sensitivity)

    return left, right
end

--- Check if finger tracking data is available (at least one hand has curl data).
function vrmod.Expression.HasFingerTracking()
    if not g_VR or not g_VR.input then return false end

    local skelL = g_VR.input.skeleton_lefthand
    local skelR = g_VR.input.skeleton_righthand

    if skelL and skelL.fingerCurls then
        for i = 1, 5 do
            if skelL.fingerCurls[i] and skelL.fingerCurls[i] > 0 then return true end
        end
    end

    if skelR and skelR.fingerCurls then
        for i = 1, 5 do
            if skelR.fingerCurls[i] and skelR.fingerCurls[i] > 0 then return true end
        end
    end

    return false
end

--- Reset gesture detection state (call on VRMod_Exit).
function vrmod.Expression.ResetGestures()
    for _, hand in pairs(handState) do
        hand.fingerStates = { nil, nil, nil, nil, nil }
        hand.candidateGesture = 0
        hand.candidateFrames = 0
        hand.confirmedGesture = 0
    end
end

--- Get current confirmed gestures without running detection.
function vrmod.Expression.GetCurrentGestures()
    return handState.left.confirmedGesture, handState.right.confirmedGesture
end

---------------------------------------------------------------------------
-- Compute analog blend factor for a confirmed gesture.
-- Returns 0.0-1.0 indicating how well the finger curls match the pattern.
-- Used to scale expression weights for smooth analog transitions (Index).
-- Returns 1.0 for neutral, missing data, or non-finger-tracking controllers.
---------------------------------------------------------------------------
function vrmod.Expression.ComputeBlendFactor(gestureID, curls)
    if gestureID == 0 or not curls then return 1.0 end

    -- Find the pattern definition for this gesture
    local pattern = nil
    for _, def in ipairs(PATTERNS) do
        if def.id == gestureID then pattern = def.pattern; break end
    end
    if not pattern then return 1.0 end

    local sum, count = 0, 0
    for i = 1, 5 do
        if pattern[i] ~= nil and curls[i] then
            if pattern[i] then -- expected curled: higher curl = better match
                sum = sum + curls[i]
            else -- expected open: lower curl = better match
                sum = sum + (1 - curls[i])
            end
            count = count + 1
        end
    end

    return count > 0 and (sum / count) or 1.0
end
