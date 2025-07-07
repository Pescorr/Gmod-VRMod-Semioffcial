AddCSLuaFile()

g_VR = g_VR or {}
vrmod = vrmod or {}

-- ConVars
local cv_enable = CreateClientConVar("vrmod_realistic_weapon_enable", "1", true, FCVAR_ARCHIVE)
local cv_slide_range = CreateClientConVar("vrmod_realistic_slide_range", "10", true, FCVAR_ARCHIVE)
local cv_mag_release_range = CreateClientConVar("vrmod_realistic_mag_release_range", "8", true, FCVAR_ARCHIVE)
local cv_haptic_strength = CreateClientConVar("vrmod_realistic_haptic_strength", "0.5", true, FCVAR_ARCHIVE)

-- Weapon state tracking
local weaponStates = {}
local slidePositions = {}
local magReleased = {}
local chamberEmpty = {}

-- Sound definitions
local sounds = {
    slide_pull = "weapons/pistol/pistol_sliderelease1.wav",
    slide_release = "weapons/pistol/pistol_reload1.wav",
    bolt_pull = "weapons/ar2/ar2_reload_rotate.wav",
    bolt_release = "weapons/ar2/ar2_reload_push.wav",
    mag_release = "weapons/smg1/smg1_reload.wav",
    mag_insert = "weapons/ar2/ar2_reload.wav",
    empty_fire = "weapons/pistol/pistol_empty.wav"
}

-- Weapon configuration
local weaponConfigs = {
    weapon_pistol = {
        type = "pistol",
        slideOffset = Vector(-4, 0, 2),
        slideTravel = 3,
        magOffset = Vector(0, 0, -3),
        hasSlideStop = true
    },
    weapon_357 = {
        type = "revolver",
        cylinderOffset = Vector(-2, -1, 0),
        hasCylinder = true
    },
    weapon_smg1 = {
        type = "rifle",
        boltOffset = Vector(-8, 1, 3),
        boltTravel = 4,
        magOffset = Vector(0, 0, -5),
        chargingHandleOffset = Vector(-10, 1, 4)
    },
    weapon_ar2 = {
        type = "rifle",
        boltOffset = Vector(-10, 0, 4),
        boltTravel = 5,
        magOffset = Vector(0, 0, -6),
        chargingHandleOffset = Vector(-12, 0, 5)
    },
    weapon_shotgun = {
        type = "shotgun",
        pumpOffset = Vector(8, 0, -2),
        pumpTravel = 6,
        singleLoad = true
    },
    weapon_crossbow = {
        type = "special",
        reloadOffset = Vector(0, 0, 0)
    }
}

if CLIENT then
    local function GetWeaponConfig(weapon)
        if not IsValid(weapon) then return nil end
        local class = weapon:GetClass()
        return weaponConfigs[class] or {type = "generic", slideOffset = Vector(-4, 0, 2), slideTravel = 3}
    end
    
    local function SendHapticPulse(hand, strength, duration)
        if not g_VR or not g_VR.active then return end
        strength = strength * cv_haptic_strength:GetFloat()
        
        if hand == "left" then
            vrmod.SetHaptic("vibration_left", strength, duration, 1/duration)
        else
            vrmod.SetHaptic("vibration_right", strength, duration, 1/duration)
        end
    end
    
    local function IsHandNearComponent(handPos, weaponPos, componentOffset, range)
        local componentWorldPos = weaponPos + componentOffset
        return handPos:Distance(componentWorldPos) < range
    end
    
    local function GetSlideProgress(weapon)
        local id = weapon:EntIndex()
        return slidePositions[id] or 0
    end
    
    local function SetSlideProgress(weapon, progress)
        local id = weapon:EntIndex()
        slidePositions[id] = math.Clamp(progress, 0, 1)
    end
    
    -- Initialize weapon state
    local function InitializeWeaponState(weapon)
        if not IsValid(weapon) then return end
        
        local id = weapon:EntIndex()
        weaponStates[id] = weaponStates[id] or {
            lastFired = 0,
            roundChambered = true,
            slideHeld = false,
            magInserted = true
        }
    end
    
    -- Check if weapon needs cycling
    local function NeedsCycling(weapon)
        local id = weapon:EntIndex()
        local state = weaponStates[id]
        
        if not state then return false end
        
        -- Check if slide/bolt is not fully forward
        local slideProgress = GetSlideProgress(weapon)
        if slideProgress > 0.1 then return true end
        
        -- Check if chamber is empty
        if chamberEmpty[id] then return true end
        
        return false
    end
    
    -- Handle slide/bolt manipulation
    local function HandleSlideManipulation(ply, weapon, leftHandPos, rightHandPos)
        local config = GetWeaponConfig(weapon)
        if not config or not config.slideOffset then return end
        
        local weaponPos = weapon:GetPos()
        local id = weapon:EntIndex()
        local state = weaponStates[id]
        
        -- Check if left hand is near slide/bolt
        if IsHandNearComponent(leftHandPos, weaponPos, config.slideOffset, cv_slide_range:GetFloat()) then
            
            if vrmod.IsPlayerGrabbing(ply, true) then -- Left hand grabbing
                if not state.slideHeld then
                    state.slideHeld = true
                    local sound = config.type == "pistol" and sounds.slide_pull or sounds.bolt_pull
                    ply:EmitSound(sound)
                    SendHapticPulse("left", 0.3, 0.1)
                end
                
                -- Calculate slide position based on hand movement
                local handDelta = leftHandPos - state.slideGrabPos
                local slideProgress = math.Clamp(handDelta:Dot(weapon:GetForward()) / config.slideTravel, 0, 1)
                SetSlideProgress(weapon, slideProgress)
                
                -- Eject shell at full pull
                if slideProgress > 0.9 and weapon:Clip1() > 0 then
                    if not state.shellEjected then
                        -- Eject shell effect
                        local effectdata = EffectData()
                        effectdata:SetOrigin(weaponPos + config.slideOffset)
                        effectdata:SetAngles(weapon:GetAngles())
                        util.Effect("ShellEject", effectdata)
                        state.shellEjected = true
                        chamberEmpty[id] = true
                    end
                end
            else
                if state.slideHeld then
                    state.slideHeld = false
                    state.slideGrabPos = nil
                    
                    -- Release slide
                    local slideProgress = GetSlideProgress(weapon)
                    if slideProgress > 0.5 then
                        -- Slide goes forward, chamber new round
                        SetSlideProgress(weapon, 0)
                        local sound = config.type == "pistol" and sounds.slide_release or sounds.bolt_release
                        ply:EmitSound(sound)
                        SendHapticPulse("right", 0.5, 0.15)
                        
                        state.shellEjected = false
                        chamberEmpty[id] = false
                        state.roundChambered = true
                    end
                end
            end
        else
            state.slideGrabPos = leftHandPos
        end
    end
    
    -- Handle magazine release
    local function HandleMagazineRelease(ply, weapon, leftHandPos)
        local config = GetWeaponConfig(weapon)
        if not config or not config.magOffset then return end
        
        local weaponPos = weapon:GetPos()
        local id = weapon:EntIndex()
        
        -- Check for reload button or hand near magazine
        local nearMag = IsHandNearComponent(leftHandPos, weaponPos, config.magOffset, cv_mag_release_range:GetFloat())
        
        if vrmod.IsActionPressed(ply, "boolean_reload") or (nearMag and vrmod.IsActionPressed(ply, "boolean_left_pickup")) then
            if not magReleased[id] then
                magReleased[id] = true
                
                -- Drop magazine
                local magEnt = ents.Create("prop_physics")
                if IsValid(magEnt) then
                    magEnt:SetModel("models/items/boxsrounds.mdl")
                    magEnt:SetPos(weaponPos + config.magOffset)
                    magEnt:SetAngles(weapon:GetAngles())
                    magEnt:Spawn()
                    
                    local phys = magEnt:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:SetVelocity(Vector(0, 0, -100))
                    end
                    
                    -- Remove after 5 seconds
                    timer.Simple(5, function()
                        if IsValid(magEnt) then magEnt:Remove() end
                    end)
                end
                
                ply:EmitSound(sounds.mag_release)
                SendHapticPulse("left", 0.4, 0.1)
                
                -- Empty weapon
                weaponStates[id].magInserted = false
            end
        end
    end
    
    -- Override weapon firing
    hook.Add("VRMod_AllowDefaultAction", "RealisticWeaponControls", function(action)
        if not cv_enable:GetBool() then return end
        
        local ply = LocalPlayer()
        if not g_VR.active then return end
        
        if action == "boolean_primaryfire" then
            local weapon = ply:GetActiveWeapon()
            if not IsValid(weapon) then return end
            
            InitializeWeaponState(weapon)
            
            -- Check if weapon can fire
            if NeedsCycling(weapon) then
                -- Play empty sound
                ply:EmitSound(sounds.empty_fire)
                SendHapticPulse("right", 0.2, 0.05)
                return false -- Prevent firing
            end
            
            -- Check if magazine is inserted
            local id = weapon:EntIndex()
            if weaponStates[id] and not weaponStates[id].magInserted then
                ply:EmitSound(sounds.empty_fire)
                SendHapticPulse("right", 0.2, 0.05)
                return false
            end
        end
    end)
    
    -- Main update loop
    hook.Add("Think", "RealisticWeaponControls", function()
        if not cv_enable:GetBool() or not g_VR or not g_VR.active then return end
        
        local ply = LocalPlayer()
        local weapon = ply:GetActiveWeapon()
        
        if not IsValid(weapon) or weapon:GetClass() == "weapon_vrmod_empty" then return end
        
        InitializeWeaponState(weapon)
        
        -- Get hand positions
        local leftHandPos = vrmod.GetLeftHandPos(ply)
        local rightHandPos = vrmod.GetRightHandPos(ply)
        
        if not leftHandPos or not rightHandPos then return end
        
        -- Handle slide/bolt manipulation
        HandleSlideManipulation(ply, weapon, leftHandPos, rightHandPos)
        
        -- Handle magazine release
        HandleMagazineRelease(ply, weapon, leftHandPos)
        
        -- Handle slide stop release with attack2
        if vrmod.IsActionPressed(ply, "boolean_secondaryfire") then
            local id = weapon:EntIndex()
            local slideProgress = GetSlideProgress(weapon)
            
            if slideProgress > 0.8 and weaponStates[id].magInserted then
                SetSlideProgress(weapon, 0)
                ply:EmitSound(sounds.slide_release)
                SendHapticPulse("right", 0.5, 0.15)
                chamberEmpty[id] = false
                weaponStates[id].roundChambered = true
            end
        end
    end)
    
    -- Visual feedback for slide position
    hook.Add("PostDrawOpaqueRenderables", "RealisticWeaponVisuals", function()
        if not cv_enable:GetBool() or not g_VR or not g_VR.active then return end
        
        local ply = LocalPlayer()
        local weapon = ply:GetActiveWeapon()
        
        if not IsValid(weapon) then return end
        
        local config = GetWeaponConfig(weapon)
        if not config or not config.slideOffset then return end
        
        local slideProgress = GetSlideProgress(weapon)
        if slideProgress > 0 then
            -- Visual indicator for slide position
            local weaponPos = weapon:GetPos()
            local slidePos = weaponPos + config.slideOffset - weapon:GetForward() * (slideProgress * config.slideTravel)
            
            cam.Start3D()
            render.SetColorMaterial()
            render.DrawSphere(slidePos, 1, 8, 8, Color(255, 100, 100, 100))
            cam.End3D()
        end
    end)
    
    -- Cleanup on weapon switch
    hook.Add("VRMod_Pickup", "RealisticWeaponCleanup", function(ply, ent)
        if ent:IsWeapon() then
            local id = ent:EntIndex()
            weaponStates[id] = nil
            slidePositions[id] = nil
            magReleased[id] = nil
            chamberEmpty[id] = nil
        end
    end)
end

-- Server-side networking
if SERVER then
    util.AddNetworkString("vrmod_realistic_weapon_state")
    
    -- Sync weapon states between players
    hook.Add("Think", "RealisticWeaponSync", function()
        for _, ply in ipairs(player.GetAll()) do
            if g_VR[ply:SteamID()] and g_VR[ply:SteamID()].active then
                local weapon = ply:GetActiveWeapon()
                if IsValid(weapon) then
                    -- Sync relevant data if needed
                end
            end
        end
    end)
end