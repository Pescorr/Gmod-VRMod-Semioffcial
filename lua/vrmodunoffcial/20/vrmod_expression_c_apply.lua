--[[
    Module 20: Expression System — Flex/Bodygroup Application + Network Sync (SH)
    Applies gesture-driven facial expressions to player models.
    Networks gesture state to other players.
    Supports both flex weights (analog, up to 500%) and bodygroup switching.
    Coexists with SRanipal (auto-disables when SRanipal is active).
]]

AddCSLuaFile()

vrmod.Expression = vrmod.Expression or {}

---------------------------------------------------------------------------
-- ConVars (cached locally)
---------------------------------------------------------------------------
local cv_enable = CreateClientConVar("vrmod_unoff_expression_enable", "1", true, false,
    "Enable VRChat-style gesture expressions", 0, 1)
local cv_gesture = CreateClientConVar("vrmod_unoff_expression_gesture", "1", true, false,
    "Enable automatic gesture detection from finger tracking", 0, 1)
local cv_sensitivity = CreateClientConVar("vrmod_unoff_expression_sensitivity", "1", true, false,
    "Gesture detection sensitivity (0=low, 1=medium, 2=high)", 0, 2)
local cv_intensity = CreateClientConVar("vrmod_unoff_expression_intensity", "100", true, false,
    "Expression intensity when gesture is fully matched (10-500%)", 10, 500)

---------------------------------------------------------------------------
-- Network strings
---------------------------------------------------------------------------
if SERVER then
    util.AddNetworkString("vrmod_expr_state")
    util.AddNetworkString("vrmod_expr_request")
end

---------------------------------------------------------------------------
-- SERVER: Relay gesture state between players + apply bodygroups
---------------------------------------------------------------------------
if SERVER then

    -- Receive gesture state from a VR client
    local function OnReceiveExprState(len, ply)
        if not IsValid(ply) then return end

        local gestureID = net.ReadUInt(4)
        local manualOverride = net.ReadBool()

        ply.vrmod_expr_gestureID = gestureID
        ply.vrmod_expr_manual = manualOverride

        -- Claim all flexes on server (prevents engine default animations from fighting,
        -- same pattern as SRanipal in vrmod_sranipal.lua line 527-531)
        if not ply.vrmod_expr_claimed then
            for i = 0, ply:GetFlexNum() - 1 do
                ply:SetFlexWeight(i, 0)
            end
            ply.vrmod_expr_claimed = true
        end

        -- Apply bodygroup (server-side → auto-replicates to all clients)
        if not ply.vrmod_expr_bgInfo or ply:GetModel() ~= ply.vrmod_expr_bgModel then
            ply.vrmod_expr_bgModel = ply:GetModel()
            ply.vrmod_expr_bgInfo = vrmod.Expression.FindExpressionBodygroup(ply)
        end
        if ply.vrmod_expr_bgInfo then
            local bgVal = gestureID > 0
                and math.min(gestureID, ply.vrmod_expr_bgInfo.max)
                or 0
            ply:SetBodygroup(ply.vrmod_expr_bgInfo.id, bgVal)
        end

        -- Relay to all other clients
        net.Start("vrmod_expr_state")
        net.WriteEntity(ply)
        net.WriteUInt(gestureID, 4)
        net.WriteBool(manualOverride)
        net.SendOmit(ply)
    end

    -- Use vrmod.NetReceiveLimited if available (rate limiting), else raw net.Receive
    if vrmod.NetReceiveLimited then
        vrmod.NetReceiveLimited("vrmod_expr_state", 30, 64, OnReceiveExprState)
    else
        net.Receive("vrmod_expr_state", OnReceiveExprState)
    end

    -- Handle late-joining players requesting current expression states
    local function OnRequestExprState(len, ply)
        if not IsValid(ply) then return end

        for _, other in ipairs(player.GetAll()) do
            if other ~= ply and other.vrmod_expr_gestureID then
                net.Start("vrmod_expr_state")
                net.WriteEntity(other)
                net.WriteUInt(other.vrmod_expr_gestureID, 4)
                net.WriteBool(other.vrmod_expr_manual or false)
                net.Send(ply)
            end
        end
    end

    if vrmod.NetReceiveLimited then
        vrmod.NetReceiveLimited("vrmod_expr_request", 5, 32, OnRequestExprState)
    else
        net.Receive("vrmod_expr_request", OnRequestExprState)
    end

    -- Clean up on disconnect
    hook.Add("PlayerDisconnected", "vrmod_expression_cleanup", function(ply)
        ply.vrmod_expr_gestureID = nil
        ply.vrmod_expr_manual = nil
        ply.vrmod_expr_claimed = nil
        ply.vrmod_expr_bgInfo = nil
        ply.vrmod_expr_bgModel = nil
    end)

    return -- SERVER-only code ends here
end

---------------------------------------------------------------------------
-- CLIENT: Local expression application + remote player rendering
---------------------------------------------------------------------------

local localActive = false          -- Is expression system active for local player?
local localFlexMap = nil           -- { [gestureID] = { [flexID] = weight } }
local localAllFlexIDs = nil        -- Set of all flex IDs used by any preset
local localCurrentWeights = {}     -- { [flexID] = currentLerpedWeight }
local localGestureID = 0           -- Current active gesture
local localManualOverride = false  -- Manual expression selected via menu
local lastSentGesture = -1         -- Last gesture ID sent to server
local localBGInfo = nil            -- { id, name, max } auto-detected bodygroup
local localBlendFactor = 1.0       -- Analog blend factor 0.0-1.0

-- Remote player state: { [SteamID] = { ply, gestureID, flexMap, allFlexIDs, currentWeights, lastModel } }
local remoteStates = {}

---------------------------------------------------------------------------
-- Check if SRanipal is active (coexistence rule: SRanipal takes priority)
---------------------------------------------------------------------------
local function IsSRanipalActive()
    local cv = GetConVar("vrmod_use_sranipal")
    if cv and cv:GetBool() then
        return VRMOD_SRanipalInit ~= nil
    end
    return false
end

---------------------------------------------------------------------------
-- Apply flex weights with smooth lerp transition (called every frame)
-- intensity: percentage (100 = normal, 500 = 5x exaggerated)
-- blendFactor: 0.0-1.0 analog match quality (1.0 for manual/binary)
---------------------------------------------------------------------------
local function ApplyFlexWeights(ent, flexMap, allFlexIDs, currentWeights, gestureID, dt, intensity, blendFactor)
    if not IsValid(ent) then return end

    local targetWeights = flexMap[gestureID] or {}
    local scale = (intensity / 100) * blendFactor
    local lerpSpeed = dt * 8

    for flexID in pairs(allFlexIDs) do
        local target = (targetWeights[flexID] or 0) * scale
        local current = currentWeights[flexID] or 0
        local newWeight = Lerp(lerpSpeed, current, target)

        if math.abs(newWeight) < 0.001 then newWeight = 0 end

        currentWeights[flexID] = newWeight
        ent:SetFlexWeight(flexID, newWeight)
    end
end

---------------------------------------------------------------------------
-- Reset all tracked flex weights to 0
---------------------------------------------------------------------------
local function ResetFlexWeights(ent, allFlexIDs, currentWeights)
    if not IsValid(ent) then return end

    for flexID in pairs(allFlexIDs) do
        currentWeights[flexID] = 0
        ent:SetFlexWeight(flexID, 0)
    end
end

---------------------------------------------------------------------------
-- Send gesture state to server (only when changed)
---------------------------------------------------------------------------
local function SendGestureState(gestureID, manualOverride)
    if gestureID == lastSentGesture then return end
    lastSentGesture = gestureID

    net.Start("vrmod_expr_state")
    net.WriteUInt(gestureID, 4)
    net.WriteBool(manualOverride or false)
    net.SendToServer()
end

---------------------------------------------------------------------------
-- Initialize expression system for a player entity
---------------------------------------------------------------------------
local function InitForEntity(ent)
    local flexMap, allFlexIDs = vrmod.Expression.BuildFlexMap(ent)
    local bgInfo = vrmod.Expression.FindExpressionBodygroup(ent)
    return flexMap, allFlexIDs, bgInfo
end

---------------------------------------------------------------------------
-- Main think loop for local player (hooked to Think)
---------------------------------------------------------------------------
local function ExpressionThink()
    if not localActive then return end
    if not cv_enable:GetBool() then return end
    if IsSRanipalActive() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Rebuild flex/bodygroup map if model changed
    local mdl = ply:GetModel()
    if mdl ~= vrmod.Expression._lastModel then
        vrmod.Expression._lastModel = mdl
        localFlexMap, localAllFlexIDs, localBGInfo = InitForEntity(ply)
        localCurrentWeights = {}
        if not localFlexMap and not localBGInfo then
            return
        end
    end

    if not localFlexMap and not localBGInfo then return end

    -- Gesture detection (automatic mode) + analog blend factor
    if not localManualOverride and cv_gesture:GetBool() then
        local leftG, rightG = vrmod.Expression.DetectGestures(cv_sensitivity:GetInt())

        if rightG ~= 0 then
            localGestureID = rightG
        elseif leftG ~= 0 then
            localGestureID = leftG
        else
            localGestureID = 0
        end

        -- Compute analog blend factor from active hand's finger curls
        local activeCurls = nil
        if g_VR and g_VR.input then
            if rightG ~= 0 then
                local skelR = g_VR.input.skeleton_righthand
                activeCurls = skelR and skelR.fingerCurls
            elseif leftG ~= 0 then
                local skelL = g_VR.input.skeleton_lefthand
                activeCurls = skelL and skelL.fingerCurls
            end
        end
        localBlendFactor = vrmod.Expression.ComputeBlendFactor(localGestureID, activeCurls)
    else
        localBlendFactor = 1.0
    end

    -- Send to server if changed
    SendGestureState(localGestureID, localManualOverride)

    -- Apply flex weights with intensity and blend factor
    local intensity = cv_intensity:GetInt()
    local dt = FrameTime()
    if localFlexMap then
        ApplyFlexWeights(ply, localFlexMap, localAllFlexIDs, localCurrentWeights,
            localGestureID, dt, intensity, localBlendFactor)
    end

    -- Apply bodygroup (client-side for instant preview; server also sets for replication)
    if localBGInfo then
        if localGestureID > 0 and localBlendFactor > 0.3 then
            local bgVal = math.min(localGestureID, localBGInfo.max)
            ply:SetBodygroup(localBGInfo.id, bgVal)
        else
            ply:SetBodygroup(localBGInfo.id, 0)
        end
    end
end

---------------------------------------------------------------------------
-- Remote player flex update (hooked to UpdateAnimation)
---------------------------------------------------------------------------
local function ExpressionUpdateAnimation(ply)
    if not cv_enable:GetBool() then return end

    local steamid = ply:SteamID()
    local state = remoteStates[steamid]
    if not state then return end
    if not IsValid(state.ply) then
        remoteStates[steamid] = nil
        return
    end

    -- Rebuild flex map if model changed
    local mdl = ply:GetModel()
    if mdl ~= state.lastModel then
        state.lastModel = mdl
        state.flexMap, state.allFlexIDs = vrmod.Expression.BuildFlexMap(ply)
        state.currentWeights = {}
    end

    if not state.flexMap then return end

    local dt = FrameTime()
    ApplyFlexWeights(ply, state.flexMap, state.allFlexIDs, state.currentWeights,
        state.gestureID, dt, cv_intensity:GetInt(), 1.0)
end

---------------------------------------------------------------------------
-- Receive remote player gesture state from server
---------------------------------------------------------------------------
net.Receive("vrmod_expr_state", function()
    local ply = net.ReadEntity()
    local gestureID = net.ReadUInt(4)
    local manualOverride = net.ReadBool()

    if not IsValid(ply) then return end
    if ply == LocalPlayer() then return end

    local steamid = ply:SteamID()
    if not remoteStates[steamid] then
        remoteStates[steamid] = {
            ply = ply,
            gestureID = 0,
            flexMap = nil,
            allFlexIDs = nil,
            currentWeights = {},
            lastModel = nil,
        }
    end

    remoteStates[steamid].gestureID = gestureID
    remoteStates[steamid].ply = ply
end)

---------------------------------------------------------------------------
-- VRMod lifecycle hooks
---------------------------------------------------------------------------

hook.Add("VRMod_Start", "vrmod_expression_start", function(ply)
    if ply ~= LocalPlayer() then
        net.Start("vrmod_expr_request")
        net.SendToServer()
        return
    end

    if not cv_enable:GetBool() then return end

    localFlexMap, localAllFlexIDs, localBGInfo = InitForEntity(ply)
    localCurrentWeights = {}
    localGestureID = 0
    localManualOverride = false
    lastSentGesture = -1
    localBlendFactor = 1.0
    localActive = true
    vrmod.Expression._lastModel = ply:GetModel()

    hook.Add("Think", "vrmod_expression_think", ExpressionThink)
    hook.Add("UpdateAnimation", "vrmod_expression_remote", ExpressionUpdateAnimation)

    local status = ""
    if localFlexMap then status = status .. " flex:OK" end
    if localBGInfo then status = status .. " bodygroup:" .. localBGInfo.name end
    if not localFlexMap and not localBGInfo then status = " (no compatible flexes or bodygroups)" end
    print("[VRMod Expression] Started" .. status)
end)

hook.Add("VRMod_Exit", "vrmod_expression_exit", function(ply, steamid)
    if ply == LocalPlayer() then
        localActive = false
        hook.Remove("Think", "vrmod_expression_think")
        hook.Remove("UpdateAnimation", "vrmod_expression_remote")

        -- Reset flex weights
        if IsValid(ply) and localAllFlexIDs then
            ResetFlexWeights(ply, localAllFlexIDs, localCurrentWeights)
        end

        -- Reset bodygroup
        if IsValid(ply) and localBGInfo then
            ply:SetBodygroup(localBGInfo.id, 0)
        end

        localFlexMap = nil
        localAllFlexIDs = nil
        localCurrentWeights = {}
        localGestureID = 0
        lastSentGesture = -1
        localBGInfo = nil
        localBlendFactor = 1.0

        vrmod.Expression.ResetGestures()

        print("[VRMod Expression] Stopped")
    else
        if steamid then
            local state = remoteStates[steamid]
            if state and IsValid(state.ply) and state.allFlexIDs then
                ResetFlexWeights(state.ply, state.allFlexIDs, state.currentWeights)
            end
            remoteStates[steamid] = nil
        end
    end
end)

---------------------------------------------------------------------------
-- Public API for manual expression control (used by menu)
---------------------------------------------------------------------------

function vrmod.Expression.SetManualExpression(gestureID)
    localGestureID = gestureID
    localManualOverride = true
    SendGestureState(gestureID, true)
end

function vrmod.Expression.SetAutoMode()
    localManualOverride = false
end

function vrmod.Expression.GetState()
    return {
        active = localActive,
        gestureID = localGestureID,
        manualOverride = localManualOverride,
        hasFlexes = localFlexMap ~= nil,
        hasBodygroups = localBGInfo ~= nil,
        bodygroupName = localBGInfo and localBGInfo.name or nil,
        blendFactor = localBlendFactor,
        hasFingerTracking = vrmod.Expression.HasFingerTracking and vrmod.Expression.HasFingerTracking() or false,
    }
end
