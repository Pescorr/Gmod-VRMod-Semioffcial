--[[
    Module 17: VR Ragdoll Puppeteer — Server (v2)
    VR tracking (HMD + both hands) drives a prop_ragdoll's physics bones.

    Key mechanism (learned from RagMorph):
    - Driven bones: EnableMotion(false) → kinematic, SetPos/SetAngles every frame
    - Free bones: EnableMotion(true) → physics-driven (ragdoll legs, etc.)
    - Per-bone rigging: each of 15 bones independently toggled driven/physics
    - Velocity matching: SetVelocity(ply:GetVelocity()) for smooth movement
    - 2-bone IK for arm chains

    Experimental / proof-of-concept.
]]

if CLIENT then return end

g_VR = g_VR or {}
vrmod = vrmod or {}

-- ============================================================================
-- ConVars
-- ============================================================================

local cv_enable = CreateConVar(
    "vrmod_unoff_puppeteer_enable", "1",
    FCVAR_REPLICATED + FCVAR_ARCHIVE,
    "Enable VR Ragdoll Puppeteer module", 0, 1
)

local cv_pelvis_offset = CreateConVar(
    "vrmod_unoff_puppeteer_pelvis_offset", "30",
    FCVAR_ARCHIVE,
    "Distance from HMD to pelvis (units)", 10, 60
)

local cv_shoulder_width = CreateConVar(
    "vrmod_unoff_puppeteer_shoulder_width", "8",
    FCVAR_ARCHIVE,
    "Half shoulder width from spine center (units)", 4, 16
)

local cv_hide_player = CreateConVar(
    "vrmod_unoff_puppeteer_hide_player", "1",
    FCVAR_REPLICATED + FCVAR_ARCHIVE,
    "Hide player model when puppet is active", 0, 1
)

local cv_phys_effects_ply = CreateConVar(
    "vrmod_unoff_puppeteer_phys_effects_ply", "0",
    FCVAR_ARCHIVE,
    "Ragdoll physics affects player movement (momentum transfer)", 0, 1
)

local cv_momentum_scale = CreateConVar(
    "vrmod_unoff_puppeteer_momentum_scale", "0.05",
    FCVAR_ARCHIVE,
    "Momentum transfer scale from ragdoll to player", 0, 0.5
)

local cv_leg_mode = CreateConVar(
    "vrmod_unoff_puppeteer_leg_mode", "0",
    FCVAR_REPLICATED + FCVAR_ARCHIVE,
    "Leg animation: 0=static, 1=auto (skeleton copy or FBT tracker IK)", 0, 1
)

-- ============================================================================
-- Network
-- ============================================================================

util.AddNetworkString("vrmod_puppeteer_state")      -- S->C: state change
util.AddNetworkString("vrmod_puppeteer_rig_apply")   -- C->S: client sends 15-bool rig

-- ============================================================================
-- Constants: 15 standard ValveBiped physics bones
-- ============================================================================

-- Ordered array (matches RagMorph's boneTable order)
local BONE_TABLE = {
    "ValveBiped.Bip01_Pelvis",       -- 1
    "ValveBiped.Bip01_Spine2",       -- 2
    "ValveBiped.Bip01_Head1",        -- 3
    "ValveBiped.Bip01_L_Hand",       -- 4
    "ValveBiped.Bip01_L_Forearm",    -- 5
    "ValveBiped.Bip01_L_UpperArm",   -- 6
    "ValveBiped.Bip01_L_Foot",       -- 7
    "ValveBiped.Bip01_L_Calf",       -- 8
    "ValveBiped.Bip01_L_Thigh",      -- 9
    "ValveBiped.Bip01_R_Hand",       -- 10
    "ValveBiped.Bip01_R_Forearm",    -- 11
    "ValveBiped.Bip01_R_UpperArm",   -- 12
    "ValveBiped.Bip01_R_Foot",       -- 13
    "ValveBiped.Bip01_R_Calf",       -- 14
    "ValveBiped.Bip01_R_Thigh",      -- 15
}

-- Reverse lookup: bone name -> index in BONE_TABLE
local BONE_INDEX = {}
for i, name in ipairs(BONE_TABLE) do
    BONE_INDEX[name] = i
end

-- Short names for convenience
local B = {
    pelvis    = BONE_TABLE[1],
    spine2    = BONE_TABLE[2],
    head      = BONE_TABLE[3],
    l_hand    = BONE_TABLE[4],
    l_forearm = BONE_TABLE[5],
    l_upper   = BONE_TABLE[6],
    l_foot    = BONE_TABLE[7],
    l_calf    = BONE_TABLE[8],
    l_thigh   = BONE_TABLE[9],
    r_hand    = BONE_TABLE[10],
    r_forearm = BONE_TABLE[11],
    r_upper   = BONE_TABLE[12],
    r_foot    = BONE_TABLE[13],
    r_calf    = BONE_TABLE[14],
    r_thigh   = BONE_TABLE[15],
}

-- Default rigging: Head + Hands only (3 VR tracking points driven, rest physics)
-- Index: 1=Pelvis, 2=Spine2, 3=Head, 4=L_Hand, 5=L_Forearm, 6=L_Upper,
--        7=L_Foot, 8=L_Calf, 9=L_Thigh, 10=R_Hand, 11=R_Forearm, 12=R_Upper,
--        13=R_Foot, 14=R_Calf, 15=R_Thigh
local DEFAULT_RIG = { false, false, true, true, false, false, false, false, false, true, false, false, false, false, false }

-- ============================================================================
-- State
-- ============================================================================

--[[
    activePuppets[steamid] = {
        ragdoll      = Entity,
        player       = Player,
        boneMap      = { boneName -> physIdx },
        boneRig      = { [1..15] = true/false },  -- per-bone driven state
        upperArmLen  = number,
        forearmLen   = number,
        oldMaterial  = string|nil,
        savedVel     = { [physIdx] = Vector },     -- for momentum preservation
        savedAngVel  = { [physIdx] = Vector },
    }
]]
local activePuppets = {}

-- ============================================================================
-- Utility: Build physics bone index map
-- ============================================================================

local function BuildBoneMap(ragdoll)
    local map = {}
    local physCount = ragdoll:GetPhysicsObjectCount()

    for i = 0, physCount - 1 do
        local modelBoneID = ragdoll:TranslatePhysBoneToBone(i)
        if modelBoneID and modelBoneID >= 0 then
            local boneName = ragdoll:GetBoneName(modelBoneID)
            if boneName then
                map[boneName] = i
            end
        end
    end

    return map
end

-- ============================================================================
-- Rigging: Apply EnableMotion state to ragdoll bones
-- ============================================================================

--- Apply rigging state: driven bones get EnableMotion(false), free bones get EnableMotion(true)
local function ApplyRigging(data)
    local rag = data.ragdoll
    local boneMap = data.boneMap
    local boneRig = data.boneRig

    if not IsValid(rag) then return end

    for i, boneName in ipairs(BONE_TABLE) do
        local physIdx = boneMap[boneName]
        if physIdx then
            local phys = rag:GetPhysicsObjectNum(physIdx)
            if IsValid(phys) then
                local isDriven = boneRig[i]
                if isDriven then
                    -- Save velocity before freezing (for later momentum restoration)
                    data.savedVel[physIdx] = phys:GetVelocity()
                    data.savedAngVel[physIdx] = phys:GetAngleVelocity()
                    phys:EnableMotion(false)  -- KINEMATIC: physics disabled
                else
                    phys:EnableMotion(true)   -- PHYSICS: free ragdoll
                    phys:Wake()
                    -- Restore saved velocity for smooth transition
                    if data.savedVel[physIdx] then
                        phys:SetVelocity(data.savedVel[physIdx])
                        data.savedVel[physIdx] = nil
                    end
                    if data.savedAngVel[physIdx] then
                        phys:AddAngleVelocity(data.savedAngVel[physIdx])
                        data.savedAngVel[physIdx] = nil
                    end
                end
            end
        end
    end
end

--- Toggle individual bone rigging
local function SetBoneRig(data, boneIdx, isDriven)
    if boneIdx < 1 or boneIdx > 15 then return end
    data.boneRig[boneIdx] = isDriven
    ApplyRigging(data)
end

-- ============================================================================
-- 2-Bone IK Solver
-- ============================================================================

local function SolveTwoBoneIK(shoulder, hand, lenUpper, lenLower, poleHint)
    local toHand = hand - shoulder
    local dist = toHand:Length()

    if dist < 0.01 then
        return shoulder + poleHint * lenUpper
    end

    local maxReach = lenUpper + lenLower - 0.1
    if dist >= maxReach then
        return shoulder + toHand:GetNormalized() * lenUpper
    end

    local cosA = (lenUpper * lenUpper + dist * dist - lenLower * lenLower)
                 / (2 * lenUpper * dist)
    cosA = math.Clamp(cosA, -1, 1)
    local angleA = math.acos(cosA)

    local fwd = toHand / dist
    local dot = poleHint:Dot(fwd)
    local projHint = poleHint - fwd * dot
    if projHint:LengthSqr() < 0.001 then
        projHint = Vector(0, 0, -1) - fwd * fwd.z
        if projHint:LengthSqr() < 0.001 then
            projHint = Vector(0, 1, 0)
        end
    end
    projHint:Normalize()

    local elbowDir = fwd * math.cos(angleA) + projHint * math.sin(angleA)
    return shoulder + elbowDir * lenUpper
end

-- ============================================================================
-- Angle from direction
-- ============================================================================

local function AngleBetween(fromPos, toPos)
    local dir = toPos - fromPos
    if dir:LengthSqr() < 0.01 then
        return Angle(0, 0, 0)
    end
    return dir:Angle()
end

-- ============================================================================
-- Create / Remove Puppet
-- ============================================================================

local function CreatePuppet(ply)
    local steamid = ply:SteamID()
    if activePuppets[steamid] then return false end

    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return false end

    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetSkin(ply:GetSkin() or 0)
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())

    for i = 0, (ply:GetNumBodyGroups() or 1) - 1 do
        ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
    end

    ragdoll:Spawn()
    ragdoll:Activate()
    ragdoll:SetOwner(ply)
    ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

    -- Initialize bone poses from player skeleton
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local boneId = ragdoll:TranslatePhysBoneToBone(i)
            if boneId and boneId >= 0 then
                local pos, ang = ply:GetBonePosition(boneId)
                if pos and pos ~= ply:GetPos() then
                    phys:SetPos(pos)
                    phys:SetAngles(ang)
                end
            end
            phys:Wake()
        end
    end

    local boneMap = BuildBoneMap(ragdoll)

    -- Measure arm lengths from initial bone positions
    local upperArmLen = 12
    local forearmLen  = 12

    local uIdx = boneMap[B.r_upper]
    local fIdx = boneMap[B.r_forearm]
    local hIdx = boneMap[B.r_hand]
    if uIdx and fIdx and hIdx then
        local pu = ragdoll:GetPhysicsObjectNum(uIdx)
        local pf = ragdoll:GetPhysicsObjectNum(fIdx)
        local ph = ragdoll:GetPhysicsObjectNum(hIdx)
        if IsValid(pu) and IsValid(pf) and IsValid(ph) then
            local mu = pu:GetPos():Distance(pf:GetPos())
            local ml = pf:GetPos():Distance(ph:GetPos())
            if mu > 1 then upperArmLen = mu end
            if ml > 1 then forearmLen  = ml end
        end
    end

    -- Measure leg lengths from initial bone positions (same pattern as arms)
    local upperLegLen = 15
    local lowerLegLen = 15

    local tIdx = boneMap[B.l_thigh]
    local cIdx = boneMap[B.l_calf]
    local fLIdx = boneMap[B.l_foot]
    if tIdx and cIdx and fLIdx then
        local pt = ragdoll:GetPhysicsObjectNum(tIdx)
        local pc = ragdoll:GetPhysicsObjectNum(cIdx)
        local pf = ragdoll:GetPhysicsObjectNum(fLIdx)
        if IsValid(pt) and IsValid(pc) and IsValid(pf) then
            local mt = pt:GetPos():Distance(pc:GetPos())
            local ml = pc:GetPos():Distance(pf:GetPos())
            if mt > 1 then upperLegLen = mt end
            if ml > 1 then lowerLegLen = ml end
        end
    end

    -- Cache player leg bone IDs for skeleton copy mode
    local plyLegBones = {
        l_thigh = ply:LookupBone("ValveBiped.Bip01_L_Thigh"),
        l_calf  = ply:LookupBone("ValveBiped.Bip01_L_Calf"),
        l_foot  = ply:LookupBone("ValveBiped.Bip01_L_Foot"),
        r_thigh = ply:LookupBone("ValveBiped.Bip01_R_Thigh"),
        r_calf  = ply:LookupBone("ValveBiped.Bip01_R_Calf"),
        r_foot  = ply:LookupBone("ValveBiped.Bip01_R_Foot"),
    }

    -- Hide player model
    local oldMaterial = nil
    if cv_hide_player:GetBool() then
        oldMaterial = ply:GetMaterial()
        ply:SetMaterial("models/effects/vol_light001")
        ply:DrawWorldModel(false)
        ply:SetNoDraw(true)
    end

    -- Build initial rigging (default: upper body driven, legs physics)
    -- Client will send saved rigging via net message after creation
    local boneRig = {}
    for i = 1, 15 do
        boneRig[i] = DEFAULT_RIG[i]
    end

    local data = {
        ragdoll     = ragdoll,
        player      = ply,
        boneMap     = boneMap,
        boneRig     = boneRig,
        upperArmLen = upperArmLen,
        forearmLen  = forearmLen,
        upperLegLen = upperLegLen,
        lowerLegLen = lowerLegLen,
        plyLegBones = plyLegBones,
        oldMaterial = oldMaterial,
        savedVel    = {},
        savedAngVel = {},
    }

    activePuppets[steamid] = data

    -- Apply rigging: freeze driven bones, free physics bones
    ApplyRigging(data)

    ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Puppet created (arms: " ..
        string.format("%.1f/%.1f", upperArmLen, forearmLen) ..
        ", legs: " .. string.format("%.1f/%.1f", upperLegLen, lowerLegLen) .. ")")

    return true
end

local function RemovePuppet(ply)
    local steamid = ply:SteamID()
    local data = activePuppets[steamid]
    if not data then return end

    if IsValid(data.ragdoll) then
        data.ragdoll:Remove()
    end

    if IsValid(ply) then
        if data.oldMaterial then
            ply:SetMaterial(data.oldMaterial)
        else
            ply:SetMaterial("")
        end
        ply:DrawWorldModel(true)
        ply:SetNoDraw(false)
    end

    activePuppets[steamid] = nil
end

-- ============================================================================
-- Toggle / Concommands
-- ============================================================================

local function TogglePuppet(ply)
    local steamid = ply:SteamID()

    if activePuppets[steamid] then
        RemovePuppet(ply)
        net.Start("vrmod_puppeteer_state")
        net.WriteBool(false)
        net.Send(ply)
        ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Puppet removed")
    else
        if CreatePuppet(ply) then
            net.Start("vrmod_puppeteer_state")
            net.WriteBool(true)
            net.Send(ply)
        end
    end
end

concommand.Add("vrmod_puppeteer_toggle", function(ply)
    if not IsValid(ply) then return end
    if not cv_enable:GetBool() then
        ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Module disabled")
        return
    end

    local ok, inVR = pcall(vrmod.IsPlayerInVR, ply)
    if not ok or not inVR then
        ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] VR not active")
        return
    end

    TogglePuppet(ply)
end)

concommand.Add("vrmod_puppeteer_on", function(ply)
    if not IsValid(ply) then return end
    if not cv_enable:GetBool() then return end
    if activePuppets[ply:SteamID()] then return end

    local ok, inVR = pcall(vrmod.IsPlayerInVR, ply)
    if not ok or not inVR then return end

    if CreatePuppet(ply) then
        net.Start("vrmod_puppeteer_state")
        net.WriteBool(true)
        net.Send(ply)
    end
end)

concommand.Add("vrmod_puppeteer_off", function(ply)
    if not IsValid(ply) then return end
    if not activePuppets[ply:SteamID()] then return end

    RemovePuppet(ply)
    net.Start("vrmod_puppeteer_state")
    net.WriteBool(false)
    net.Send(ply)
    ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Puppet removed")
end)

-- ============================================================================
-- Net Receive: Client sends full 15-bone rigging state
-- ============================================================================

local netReceive = (vrmod.NetReceiveLimited)
    or function(name, _, _, fn) net.Receive(name, fn) end

netReceive("vrmod_puppeteer_rig_apply", 5, 200, function(len, ply)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()
    local data = activePuppets[steamid]
    if not data then return end

    -- Read 15 bools
    local newRig = {}
    for i = 1, 15 do
        newRig[i] = net.ReadBool()
    end

    data.boneRig = newRig
    ApplyRigging(data)
end)

-- Toggle individual bone: vrmod_puppeteer_rig_bone <1-15> <0|1>
concommand.Add("vrmod_puppeteer_rig_bone", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()
    local data = activePuppets[steamid]
    if not data then return end

    local boneIdx = tonumber(args[1])
    local driven = (args[2] == "1")
    if not boneIdx then return end

    SetBoneRig(data, boneIdx, driven)

    local boneName = BONE_TABLE[boneIdx] or "?"
    ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Bone " .. boneIdx ..
        " (" .. boneName .. ") = " .. (driven and "DRIVEN" or "PHYSICS"))
end)

-- Freeze all bones (saves velocities, disables motion)
concommand.Add("vrmod_puppeteer_freeze", function(ply)
    if not IsValid(ply) then return end
    local data = activePuppets[ply:SteamID()]
    if not data or not IsValid(data.ragdoll) then return end

    local rag = data.ragdoll
    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            data.savedVel[i] = phys:GetVelocity()
            data.savedAngVel[i] = phys:GetAngleVelocity()
            phys:EnableMotion(false)
        end
    end

    data.frozen = true
    ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] All bones frozen")
end)

-- Unfreeze: restore rigging state + saved velocities
concommand.Add("vrmod_puppeteer_unfreeze", function(ply)
    if not IsValid(ply) then return end
    local data = activePuppets[ply:SteamID()]
    if not data or not IsValid(data.ragdoll) then return end

    data.frozen = false
    ApplyRigging(data)
    ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Bones unfrozen (rigging restored)")
end)

-- ============================================================================
-- Main Think Loop: Drive puppet bones from VR tracking
-- ============================================================================
-- RagMorph pattern: for driven bones, every frame:
--   bone:Wake() → bone:SetVelocity(playerVel) → bone:SetPos(targetPos) → bone:SetAngles(targetAng)
-- Physics bones are untouched (they ragdoll freely).

hook.Add("Think", "VRMod_Puppeteer_Think", function()
    if not cv_enable:GetBool() then return end

    for steamid, data in pairs(activePuppets) do
        local ply = data.player
        local rag = data.ragdoll

        -- Validity check
        if not IsValid(ply) or not IsValid(rag) or not ply:Alive() then
            if IsValid(ply) then RemovePuppet(ply) end
            if IsValid(rag) then rag:Remove() end
            activePuppets[steamid] = nil
            continue
        end

        -- Skip if fully frozen (pose mode)
        if data.frozen then continue end

        -- Get VR tracking (pcall-protected)
        local ok1, hmdPos  = pcall(vrmod.GetHMDPos, ply)
        local ok2, hmdAng  = pcall(vrmod.GetHMDAng, ply)
        local ok3, lhPos   = pcall(vrmod.GetLeftHandPos, ply)
        local ok4, lhAng   = pcall(vrmod.GetLeftHandAng, ply)
        local ok5, rhPos   = pcall(vrmod.GetRightHandPos, ply)
        local ok6, rhAng   = pcall(vrmod.GetRightHandAng, ply)

        if not (ok1 and ok2 and ok3 and ok4 and ok5 and ok6) then continue end
        if not (hmdPos and hmdAng and lhPos and lhAng and rhPos and rhAng) then continue end

        local boneMap    = data.boneMap
        local boneRig    = data.boneRig
        local pelvisOff  = cv_pelvis_offset:GetFloat()
        local shoulderW  = cv_shoulder_width:GetFloat()
        local plyVel     = ply:GetVelocity()  -- Match player velocity (RagMorph pattern)

        -- =================================================================
        -- Calculate body positions from VR tracking
        -- =================================================================

        -- Head: directly from HMD (angle offset for ValveBiped bone orientation)
        local headPos = hmdPos
        local headAng = Angle(hmdAng.p - 90, hmdAng.y, hmdAng.r + 90)

        -- Pelvis: below HMD, yaw-only
        local pelvisPos = hmdPos - Vector(0, 0, pelvisOff)
        local pelvisAng = Angle(0, hmdAng.y, 0)

        -- Spine2 (chest): 40% from pelvis toward head
        local spinePos = LerpVector(0.4, pelvisPos, headPos)
        local spineAng = Angle(hmdAng.p * 0.3, hmdAng.y, 0)

        -- Shoulder positions
        local spineRight = spineAng:Right()
        local shoulderL = spinePos - spineRight * shoulderW
        local shoulderR = spinePos + spineRight * shoulderW

        -- =================================================================
        -- IK: solve arm chains
        -- =================================================================

        local bodyFwd = spineAng:Forward()
        local hintBack = (-bodyFwd + Vector(0, 0, -0.3)):GetNormalized()

        local elbowL = SolveTwoBoneIK(shoulderL, lhPos, data.upperArmLen, data.forearmLen, hintBack)
        local elbowR = SolveTwoBoneIK(shoulderR, rhPos, data.upperArmLen, data.forearmLen, hintBack)

        -- =================================================================
        -- Apply to physics bones (RagMorph sequence)
        -- =================================================================

        -- Accumulate ragdoll velocity for optional momentum transfer
        local ragVelSum = Vector(0, 0, 0)
        local ragVelCount = 0

        --- Set a driven bone's position (RagMorph pattern)
        local function SetDrivenBone(boneName, pos, ang)
            local boneIdx = BONE_INDEX[boneName]
            if not boneIdx then return end

            -- Only drive if this bone is rigged as "driven"
            if not boneRig[boneIdx] then return end

            local physIdx = boneMap[boneName]
            if not physIdx then return end
            local phys = rag:GetPhysicsObjectNum(physIdx)
            if not IsValid(phys) then return end

            -- RagMorph sequence: Wake → SetVelocity(playerVel) → SetPos → SetAngles
            phys:Wake()
            phys:SetVelocity(plyVel)
            phys:SetPos(pos)
            phys:SetAngles(ang)
        end

        -- Accumulate velocity from ALL physics bones (for momentum transfer)
        if cv_phys_effects_ply:GetBool() then
            for i = 0, rag:GetPhysicsObjectCount() - 1 do
                local phys = rag:GetPhysicsObjectNum(i)
                if IsValid(phys) then
                    ragVelSum = ragVelSum + phys:GetVelocity()
                    ragVelCount = ragVelCount + 1
                end
            end
        end

        -- === Core body ===
        SetDrivenBone(B.pelvis, pelvisPos, pelvisAng)
        SetDrivenBone(B.spine2, spinePos, spineAng)
        SetDrivenBone(B.head, headPos, headAng)

        -- === Left arm chain ===
        SetDrivenBone(B.l_upper, shoulderL, AngleBetween(shoulderL, elbowL))
        SetDrivenBone(B.l_forearm, elbowL, AngleBetween(elbowL, lhPos))
        SetDrivenBone(B.l_hand, lhPos, lhAng)

        -- === Right arm chain ===
        SetDrivenBone(B.r_upper, shoulderR, AngleBetween(shoulderR, elbowR))
        SetDrivenBone(B.r_forearm, elbowR, AngleBetween(elbowR, rhPos))
        SetDrivenBone(B.r_hand, rhPos, rhAng + Angle(0, 0, 180))

        -- === Legs ===
        local legMode = cv_leg_mode:GetInt()

        if legMode >= 1 then
            -- Auto mode: check for FBT tracker data
            local playerTable = g_VR[steamid]
            local lf = playerTable and playerTable.latestFrame
            local hasFBT = lf and lf.waistPos ~= nil

            if hasFBT then
                -- FBT IK mode: use tracker positions as IK targets
                local refPos = ply:GetPos()
                local refAng = ply:InVehicle() and ply:GetVehicle():GetAngles() or Angle()
                local waistWorld, waistAngW = LocalToWorld(lf.waistPos, lf.waistAng, refPos, refAng)
                local lfootWorld, lfootAngW = LocalToWorld(lf.leftfootPos, lf.leftfootAng, refPos, refAng)
                local rfootWorld, rfootAngW = LocalToWorld(lf.rightfootPos, lf.rightfootAng, refPos, refAng)

                -- Pelvis from waist tracker (more accurate than HMD-offset)
                pelvisPos = waistWorld
                pelvisAng = Angle(0, waistAngW.y, 0)
                SetDrivenBone(B.pelvis, pelvisPos, pelvisAng)

                -- Left leg IK
                if boneRig[9] then
                    local hipL = pelvisPos - pelvisAng:Right() * shoulderW - Vector(0, 0, 2)
                    local kneeL = SolveTwoBoneIK(hipL, lfootWorld, data.upperLegLen, data.lowerLegLen, -pelvisAng:Forward())
                    SetDrivenBone(B.l_thigh, hipL, AngleBetween(hipL, kneeL))
                    SetDrivenBone(B.l_calf, kneeL, AngleBetween(kneeL, lfootWorld))
                    SetDrivenBone(B.l_foot, lfootWorld, lfootAngW)
                end

                -- Right leg IK
                if boneRig[15] then
                    local hipR = pelvisPos + pelvisAng:Right() * shoulderW - Vector(0, 0, 2)
                    local kneeR = SolveTwoBoneIK(hipR, rfootWorld, data.upperLegLen, data.lowerLegLen, -pelvisAng:Forward())
                    SetDrivenBone(B.r_thigh, hipR, AngleBetween(hipR, kneeR))
                    SetDrivenBone(B.r_calf, kneeR, AngleBetween(kneeR, rfootWorld))
                    SetDrivenBone(B.r_foot, rfootWorld, rfootAngW)
                end
            else
                -- Skeleton Copy mode: copy player walking animation (rag_morph style)
                local plb = data.plyLegBones
                if boneRig[9] and plb.l_thigh then
                    local tPos, tAng = ply:GetBonePosition(plb.l_thigh)
                    local cPos, cAng = ply:GetBonePosition(plb.l_calf)
                    local fPos, fAng = ply:GetBonePosition(plb.l_foot)
                    if tPos then
                        SetDrivenBone(B.l_thigh, tPos, tAng)
                        SetDrivenBone(B.l_calf, cPos, cAng)
                        SetDrivenBone(B.l_foot, fPos, fAng)
                    end
                end
                if boneRig[15] and plb.r_thigh then
                    local tPos, tAng = ply:GetBonePosition(plb.r_thigh)
                    local cPos, cAng = ply:GetBonePosition(plb.r_calf)
                    local fPos, fAng = ply:GetBonePosition(plb.r_foot)
                    if tPos then
                        SetDrivenBone(B.r_thigh, tPos, tAng)
                        SetDrivenBone(B.r_calf, cPos, cAng)
                        SetDrivenBone(B.r_foot, fPos, fAng)
                    end
                end
            end
        else
            -- Static mode (legacy): fixed positions relative to pelvis
            if boneRig[9] then
                local pRight = pelvisAng:Right()
                local hipL = pelvisPos - pRight * 5 - Vector(0, 0, 2)
                local kneeL = hipL - Vector(0, 0, 15)
                local footL = kneeL - Vector(0, 0, 15)
                SetDrivenBone(B.l_thigh, hipL, AngleBetween(hipL, kneeL))
                SetDrivenBone(B.l_calf, kneeL, AngleBetween(kneeL, footL))
                SetDrivenBone(B.l_foot, footL, Angle(0, hmdAng.y, 0))
            end
            if boneRig[15] then
                local pRight = pelvisAng:Right()
                local hipR = pelvisPos + pRight * 5 - Vector(0, 0, 2)
                local kneeR = hipR - Vector(0, 0, 15)
                local footR = kneeR - Vector(0, 0, 15)
                SetDrivenBone(B.r_thigh, hipR, AngleBetween(hipR, kneeR))
                SetDrivenBone(B.r_calf, kneeR, AngleBetween(kneeR, footR))
                SetDrivenBone(B.r_foot, footR, Angle(0, hmdAng.y, 0))
            end
        end

        -- === Optional: momentum transfer from ragdoll to player ===
        if cv_phys_effects_ply:GetBool() and ragVelCount > 0 then
            local avgVel = ragVelSum / ragVelCount
            local scale = cv_momentum_scale:GetFloat()
            ply:SetVelocity(avgVel * scale)
        end
    end
end)

-- ============================================================================
-- Cleanup Hooks
-- ============================================================================

hook.Add("VRMod_Exit", "VRMod_Puppeteer_Exit", function(ply)
    if not IsValid(ply) then return end
    if activePuppets[ply:SteamID()] then
        RemovePuppet(ply)
    end
end)

hook.Add("PlayerDisconnected", "VRMod_Puppeteer_Disconnect", function(ply)
    if not IsValid(ply) then return end
    if activePuppets[ply:SteamID()] then
        RemovePuppet(ply)
    end
end)

hook.Add("PlayerDeath", "VRMod_Puppeteer_Death", function(ply)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()
    if activePuppets[steamid] then
        RemovePuppet(ply)
        net.Start("vrmod_puppeteer_state")
        net.WriteBool(false)
        net.Send(ply)
    end
end)

hook.Add("CanPlayerEnterVehicle", "VRMod_Puppeteer_Vehicle", function(ply, veh, role)
    if not IsValid(ply) then return end
    if activePuppets[ply:SteamID()] then
        RemovePuppet(ply)
        net.Start("vrmod_puppeteer_state")
        net.WriteBool(false)
        net.Send(ply)
        ply:PrintMessage(HUD_PRINTTALK, "[Puppeteer] Puppet removed (entering vehicle)")
    end
end)

-- ============================================================================
-- Public API
-- ============================================================================

vrmod.Puppeteer = vrmod.Puppeteer or {}

function vrmod.Puppeteer.IsActive(ply)
    if not IsValid(ply) then return false end
    return activePuppets[ply:SteamID()] ~= nil
end

function vrmod.Puppeteer.GetRagdoll(ply)
    if not IsValid(ply) then return nil end
    local data = activePuppets[ply:SteamID()]
    return data and data.ragdoll or nil
end

function vrmod.Puppeteer.GetBoneRig(ply)
    if not IsValid(ply) then return nil end
    local data = activePuppets[ply:SteamID()]
    return data and data.boneRig or nil
end

function vrmod.Puppeteer.GetAllActive()
    local result = {}
    for sid, data in pairs(activePuppets) do
        if IsValid(data.player) and IsValid(data.ragdoll) then
            result[sid] = data
        end
    end
    return result
end

-- ============================================================================

print("[VRMod] Module 17: VR Ragdoll Puppeteer v2 loaded (SV)")
