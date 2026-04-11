--[[
    TIME CRISIS System ON VRmod — Client
    Cover system: crouch to become invincible (but cannot attack),
    stand up to fight normally. Ground holsters appear while crouching.
    Compatible with both original and semiofficial VRMod.
]]

if not CLIENT then return end

local L = VRModL or function(_, fb) return fb or "" end

------------------------------------------------------------------------
-- ConVars (cached at load time, never call GetConVar() per frame)
------------------------------------------------------------------------
local cv_enabled         = CreateClientConVar("vrmod_unoff_timecrisis", "0", true, FCVAR_ARCHIVE, "Enable Time Crisis cover system", 0, 1)
local cv_block_movement  = CreateClientConVar("vrmod_unoff_tc_block_movement", "0", true, FCVAR_ARCHIVE, "Block movement while in cover", 0, 1)
local cv_holster_dist    = CreateClientConVar("vrmod_unoff_tc_holster_dist", "18", true, FCVAR_ARCHIVE, "Ground holster distance from player", 5, 40)
local cv_holster_radius  = CreateClientConVar("vrmod_unoff_tc_holster_radius", "8", true, FCVAR_ARCHIVE, "Ground holster detection radius", 3, 20)

-- Per-slot weapon class ConVars (4 slots)
local TC_SLOTS = 4
local cv_slots = {}
for i = 1, TC_SLOTS do
    cv_slots[i] = CreateClientConVar("vrmod_unoff_tc_slot_" .. i, "", true, FCVAR_ARCHIVE)
end

------------------------------------------------------------------------
-- Pre-allocated colors/vectors for render (avoid per-frame GC pressure)
------------------------------------------------------------------------
local COLOR_SLOT_FILLED  = Color(60, 180, 255, 150)
local COLOR_SLOT_EMPTY   = Color(100, 100, 100, 100)
local COLOR_RING         = Color(60, 180, 255, 60)
local COLOR_TEXT_WHITE    = Color(255, 255, 255, 200)
local COLOR_TEXT_WEAPON   = Color(60, 180, 255, 220)
local COLOR_TEXT_EMPTY    = Color(150, 150, 150, 150)
local COLOR_COVER_TEXT    = Color(0, 200, 255, 180)
local ANGLE_ZERO         = Angle(0, 0, 0)
local VEC_TEXT_OFFSET     = Vector(0, 0, 5)
local VEC_HMD_OFFSET      = Vector(0, 0, -10)

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------
local tcInitialized  = false  -- True while VR is active and module is running
local isCoverMode    = false  -- True while player is crouching (in cover)
local prevCrouching  = false  -- Previous frame's crouch state (for edge detection)

-- Equip cooldown: prevents store-on-release after equip-on-press (#1 fix)
local equipCooldownRight = 0
local equipCooldownLeft  = 0
local EQUIP_COOLDOWN     = 0.3  -- seconds

-- Ground holster positions (updated every VR frame while crouching)
local holsterPositions = {}   -- [1..4] = Vector
local holsterBaseYaw   = 0    -- HMD yaw at the moment player crouched (locked)

-- Fan angles for 4 holster slots (relative to HMD forward)
local HOLSTER_ANGLES = { -60, -20, 20, 60 }

------------------------------------------------------------------------
-- Utility: Attack action check
------------------------------------------------------------------------
local ATTACK_ACTIONS = {
    ["boolean_primaryfire"]  = true,
    ["boolean_secondaryfire"] = true,
    ["boolean_turret"]       = true,  -- Original VRMod turret action
}

local function IsAttackAction(action)
    return ATTACK_ACTIONS[action] == true
end

------------------------------------------------------------------------
-- Utility: Validate weapon class string (prevent command injection)
------------------------------------------------------------------------
local function IsValidWeaponClass(wepclass)
    if not wepclass or wepclass == "" then return false end
    -- Reject strings with semicolons, spaces, or quotes (command injection)
    if string.find(wepclass, "[;%s\"']") then return false end
    return true
end

------------------------------------------------------------------------
-- Utility: Find closest holster slot within radius
------------------------------------------------------------------------
local function FindClosestHolsterSlot(hand_pos)
    if not isCoverMode then return nil end

    local radiusSqr = cv_holster_radius:GetFloat() ^ 2
    local closest_slot = nil
    local closest_dist = math.huge

    for i = 1, TC_SLOTS do
        local pos = holsterPositions[i]
        if pos then
            local dist = hand_pos:DistToSqr(pos)
            if dist < radiusSqr and dist < closest_dist then
                closest_dist = dist
                closest_slot = i
            end
        end
    end

    return closest_slot
end

------------------------------------------------------------------------
-- Utility: Safe hand position access (null-safety for tracking data)
------------------------------------------------------------------------
local function GetHandPos(leftHand)
    if not g_VR or not g_VR.tracking then return nil end
    local pose = leftHand and g_VR.tracking.pose_lefthand or g_VR.tracking.pose_righthand
    if not pose then return nil end
    return pose.pos
end

------------------------------------------------------------------------
-- Utility: Update holster positions (fan pattern at ground level)
------------------------------------------------------------------------
local function UpdateHolsterPositions()
    if not g_VR or not g_VR.origin then return end

    local dist     = cv_holster_dist:GetFloat()
    local groundZ  = g_VR.origin.z
    local centerX  = g_VR.origin.x
    local centerY  = g_VR.origin.y

    for i = 1, TC_SLOTS do
        local ang = math.rad(holsterBaseYaw + HOLSTER_ANGLES[i])
        holsterPositions[i] = Vector(
            centerX + math.cos(ang) * dist,
            centerY + math.sin(ang) * dist,
            groundZ + 2  -- Slightly above ground to be reachable
        )
    end
end

------------------------------------------------------------------------
-- Network: Send cover state change to server
------------------------------------------------------------------------
local function SendCoverState(inCover)
    net.Start("VRMod_TC_Cover")
    net.WriteBool(inCover)
    net.SendToServer()
end

------------------------------------------------------------------------
-- Cover state transitions
------------------------------------------------------------------------
local function EnterCover()
    if isCoverMode then return end
    isCoverMode = true

    -- Lock holster yaw to current HMD forward direction
    if g_VR and g_VR.tracking and g_VR.tracking.hmd then
        holsterBaseYaw = g_VR.tracking.hmd.ang.yaw
    end

    UpdateHolsterPositions()
    SendCoverState(true)
end

local function ExitCover()
    if not isCoverMode then return end
    isCoverMode = false

    SendCoverState(false)
end

------------------------------------------------------------------------
-- Weapon equip from holster slot (returns true if equip started)
------------------------------------------------------------------------
local function EquipFromSlot(slotIndex, leftHand)
    local wepclass = cv_slots[slotIndex]:GetString()
    if not IsValidWeaponClass(wepclass) then return false end

    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    -- Check weapon still in inventory
    if not IsValid(ply:GetWeapon(wepclass)) then
        RunConsoleCommand("vrmod_unoff_tc_slot_" .. slotIndex, "")
        return false
    end

    ply:ConCommand("use " .. wepclass)

    -- Set hand if vrmod.Pickup is available
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == wepclass then
            if vrmod and vrmod.Pickup then
                vrmod.Pickup(leftHand, false)
            end
        end
    end)

    surface.PlaySound("items/ammocrate_open.wav")
    return true
end

------------------------------------------------------------------------
-- Weapon store into holster slot
------------------------------------------------------------------------
local function StoreToSlot(slotIndex)
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return false end

    local wepclass = wep:GetClass()
    if wepclass == "weapon_vrmod_empty" then return false end
    if not IsValidWeaponClass(wepclass) then return false end

    -- Check if slot already occupied (warn but allow overwrite)
    local existing = cv_slots[slotIndex]:GetString()
    if existing ~= "" and existing ~= wepclass then
        -- Slot already has a different weapon; overwrite
    end

    -- Store weapon class to slot ConVar
    RunConsoleCommand("vrmod_unoff_tc_slot_" .. slotIndex, wepclass)

    -- Switch to empty hands
    ply:ConCommand("use weapon_vrmod_empty")

    surface.PlaySound("items/ammocrate_close.wav")
    return true
end

------------------------------------------------------------------------
-- VR Start (called on first VRMod_Tracking after initialization)
------------------------------------------------------------------------
local function TimeCrisis_OnVRStart()
    isCoverMode      = false
    prevCrouching    = false
    holsterPositions = {}
    equipCooldownRight = 0
    equipCooldownLeft  = 0

    -- VRMod_AllowDefaultAction: block attacks while in cover
    -- This hook exists in BOTH original VRMod (vrmod_input.lua:14) and semiofficial
    hook.Add("VRMod_AllowDefaultAction", "VRMod_TimeCrisis_BlockAttack", function(action)
        if not cv_enabled:GetBool() then return end
        if isCoverMode and IsAttackAction(action) then
            return false
        end
    end)

    -- CreateMove: belt-and-suspenders attack block + optional movement restriction
    hook.Add("CreateMove", "VRMod_TimeCrisis_CreateMove", function(cmd)
        if not cv_enabled:GetBool() then return end
        if not isCoverMode then return end

        local buttons = cmd:GetButtons()

        -- Double-block attacks via CreateMove (safety net)
        buttons = bit.band(buttons, bit.bnot(IN_ATTACK + IN_ATTACK2))

        -- Optional: block movement
        if cv_block_movement:GetBool() then
            buttons = bit.band(buttons, bit.bnot(IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT + IN_SPEED))
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
        end

        cmd:SetButtons(buttons)
    end)

    -- VRMod_Input: holster interaction while crouching
    hook.Add("VRMod_Input", "VRMod_TimeCrisis_Input", function(action, pressed)
        if not cv_enabled:GetBool() then return end
        if not isCoverMode then return end
        if not g_VR or not g_VR.active then return end

        local now = CurTime()

        -- Right hand pickup
        if action == "boolean_right_pickup" then
            local hand_pos = GetHandPos(false)
            if not hand_pos then return end
            local slot = FindClosestHolsterSlot(hand_pos)
            if slot then
                if pressed then
                    -- Try to equip weapon from slot
                    if EquipFromSlot(slot, false) then
                        equipCooldownRight = now + EQUIP_COOLDOWN
                    end
                else
                    -- Store only if we didn't just equip (prevents fight)
                    if now > equipCooldownRight then
                        StoreToSlot(slot)
                    end
                end
            end
        end

        -- Left hand pickup
        if action == "boolean_left_pickup" then
            local hand_pos = GetHandPos(true)
            if not hand_pos then return end
            local slot = FindClosestHolsterSlot(hand_pos)
            if slot then
                if pressed then
                    if EquipFromSlot(slot, true) then
                        equipCooldownLeft = now + EQUIP_COOLDOWN
                    end
                else
                    if now > equipCooldownLeft then
                        StoreToSlot(slot)
                    end
                end
            end
        end
    end)

    -- Render: draw holster markers while crouching
    hook.Add("PostDrawTranslucentRenderables", "VRMod_TimeCrisis_Render", function(_, bSkybox)
        if bSkybox then return end
        if not cv_enabled:GetBool() then return end
        if not isCoverMode then return end
        if not g_VR or not g_VR.active then return end

        render.SetColorMaterial()

        local radius = cv_holster_radius:GetFloat()
        local ringMin = Vector(-radius, -radius, -1)
        local ringMax = Vector(radius, radius, 1)

        for i = 1, TC_SLOTS do
            local pos = holsterPositions[i]
            if pos then
                local wepclass = cv_slots[i]:GetString()
                local hasWeapon = (wepclass ~= "")

                -- Draw holster sphere
                render.DrawSphere(pos, 3, 12, 12, hasWeapon and COLOR_SLOT_FILLED or COLOR_SLOT_EMPTY)

                -- Draw outer ring (detection area visualization)
                render.DrawWireframeBox(pos, ANGLE_ZERO, ringMin, ringMax, COLOR_RING, false)

                -- Draw slot number and weapon name via cam.Start3D2D
                local textPos = pos + VEC_TEXT_OFFSET
                local textAng = Angle(0, holsterBaseYaw - 90, 90)
                cam.Start3D2D(textPos, textAng, 0.1)
                    -- Slot number
                    draw.SimpleText(tostring(i), "DermaLarge", 0, 0, COLOR_TEXT_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    -- Weapon name
                    if hasWeapon then
                        local displayName = wepclass
                        local wepInfo = weapons.Get(wepclass)
                        if wepInfo and wepInfo.PrintName then
                            displayName = wepInfo.PrintName
                        end
                        draw.SimpleText(displayName, "DermaDefault", 0, 25, COLOR_TEXT_WEAPON, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText(L("[ Empty ]", "[ Empty ]"), "DermaDefault", 0, 25, COLOR_TEXT_EMPTY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                cam.End3D2D()
            end
        end

        -- Cover mode indicator near HMD
        if g_VR.tracking and g_VR.tracking.hmd then
            local indicatorPos = g_VR.tracking.hmd.pos + VEC_HMD_OFFSET
            local indicatorAng = Angle(0, g_VR.tracking.hmd.ang.yaw - 90, 90)
            cam.Start3D2D(indicatorPos, indicatorAng, 0.08)
                draw.SimpleText(L("COVER", "COVER"), "DermaLarge", 0, 0, COLOR_COVER_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end)
end

------------------------------------------------------------------------
-- VR Exit (cleanup all dynamic hooks)
------------------------------------------------------------------------
local function TimeCrisis_OnVRExit()
    -- Ensure server knows we're not in cover
    if isCoverMode then
        SendCoverState(false)
    end

    isCoverMode        = false
    prevCrouching      = false
    holsterPositions   = {}
    tcInitialized      = false
    equipCooldownRight = 0
    equipCooldownLeft  = 0

    -- Remove all dynamic hooks
    hook.Remove("VRMod_AllowDefaultAction", "VRMod_TimeCrisis_BlockAttack")
    hook.Remove("CreateMove", "VRMod_TimeCrisis_CreateMove")
    hook.Remove("VRMod_Input", "VRMod_TimeCrisis_Input")
    hook.Remove("PostDrawTranslucentRenderables", "VRMod_TimeCrisis_Render")
end

------------------------------------------------------------------------
-- Main tracking hook: VR start detection + crouch state monitoring
-- VRMod_Tracking exists in BOTH original and semiofficial VRMod
------------------------------------------------------------------------
hook.Add("VRMod_Tracking", "VRMod_TimeCrisis_Tracking", function()
    if not cv_enabled:GetBool() then
        -- If disabled while running, clean up
        if tcInitialized then
            TimeCrisis_OnVRExit()
        end
        return
    end

    -- VR start detection (uses VRMod_Tracking for original VRMod compatibility)
    if not tcInitialized then
        tcInitialized = true
        TimeCrisis_OnVRStart()
    end

    -- Crouch state monitoring
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local isCrouching = ply:Crouching()

    -- Edge detection: only act on state changes
    if isCrouching and not prevCrouching then
        EnterCover()
    elseif not isCrouching and prevCrouching then
        ExitCover()
    end

    prevCrouching = isCrouching

    -- Update holster positions while in cover (track player movement)
    if isCoverMode then
        UpdateHolsterPositions()
    end
end)

------------------------------------------------------------------------
-- VR exit detection via Think (g_VR.active polling)
-- Necessary because original VRMod has no VRMod_Exit hook
------------------------------------------------------------------------
hook.Add("Think", "VRMod_TimeCrisis_WatchExit", function()
    if not tcInitialized then return end
    if not g_VR or not g_VR.active then
        TimeCrisis_OnVRExit()
    end
end)

------------------------------------------------------------------------
-- ConVar change callback: clean up if disabled mid-session
------------------------------------------------------------------------
cvars.AddChangeCallback("vrmod_unoff_timecrisis", function(name, old, new)
    if tonumber(new) == 0 and tcInitialized then
        TimeCrisis_OnVRExit()
    end
end, "VRMod_TimeCrisis_ConVarCleanup")
