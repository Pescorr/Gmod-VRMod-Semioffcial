--------[vrmod_melee_global.lua]Start--------
AddCSLuaFile()
local convars, convarValues = vrmod.GetConvars()
local function IsPlayerInVR(ply)
    return vrmod.IsPlayerInVR(ply)
end

local function GetHMDPos(ply)
    return vrmod.GetHMDPos(ply)
end

local function GetHMDAng(ply)
    return vrmod.GetHMDAng(ply)
end

local function GetLeftHandPos(ply)
    return vrmod.GetLeftHandPos(ply)
end

local function GetLeftHandAng(ply)
    return vrmod.GetLeftHandAng(ply)
end

local function GetRightHandPos(ply)
    return vrmod.GetRightHandPos(ply)
end

local function GetRightHandAng(ply)
    return vrmod.GetRightHandAng(ply)
end

-- ConVars --
local cv_allowgunmelee = CreateConVar("vrmelee_gunmelee", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow melee attacks with gun?")
local cv_allowfist = CreateConVar("vrmelee_fist", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow fist attacks?")
local cv_allowkick = CreateConVar("vrmelee_kick", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow kick attacks? (Requires full body tracking)")
-- Damage configurations
local cv_meleeDamageLow = CreateConVar("vrmelee_damage_low", "10.000", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Low velocity attack damage")
local cv_meleeDamageMedium = CreateConVar("vrmelee_damage_medium", "20.000", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Medium velocity attack damage")
local cv_meleeDamageHigh = CreateConVar("vrmelee_damage_high", "30.000", FCVAR_REPLICATED + FCVAR_ARCHIVE, "High velocity attack damage")
-- Velocity thresholds
local cv_meleeVelocityLow = CreateConVar("vrmelee_damage_velocity_low", "3.45", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Low velocity attack range")
local cv_meleeVelocityMedium = CreateConVar("vrmelee_damage_velocity_medium", "4.11", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Medium velocity attack range")
local cv_meleeVelocityHigh = CreateConVar("vrmelee_damage_velocity_high", "4.35", FCVAR_REPLICATED + FCVAR_ARCHIVE, "High velocity attack range")
-- Impact and delay
local cv_meleeimpact = CreateConVar("vrmelee_impact", "5.0", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Impact force for melee attacks")
local cv_meleeDelay = CreateConVar("vrmelee_delay", "0.00", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Delay between melee attacks")
local cv_meleeRange = CreateConVar("vrmelee_range", "22", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Range of melee attacks")
-- Client ConVars
local cl_usegunmelee = CreateClientConVar("vrmelee_usegunmelee", "1", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use melee attacks with gun?")
local cl_usefist = CreateClientConVar("vrmelee_usefist", "1", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use fist attacks?")
local cl_usekick = CreateClientConVar("vrmelee_usekick", "0", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use kick attacks? (Requires full body tracking)")
local cl_fisteffect = CreateClientConVar("vrmelee_fist_collision", "0", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use Fist attack Collision?")
local cl_fistvisible = CreateClientConVar("vrmelee_fist_visible", "0", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Visible Fist Attack Collision Model?")
local cl_effectmodel = CreateClientConVar("vrmelee_fist_collisionmodel", "models/hunter/plates/plate.mdl", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Fist Attack Collision Model Config")
local cv_meleeCooldown = CreateClientConVar("vrmelee_cooldown", "0.2", true, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Cooldown time for VR melee attacks")
-- Collision helpers
local cv_meleeHitboxWidth = CreateClientConVar("vrmelee_hitbox_width", "4", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Width of melee attack hitbox")
local cv_meleeHitboxLength = CreateClientConVar("vrmelee_hitbox_length", "6", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Length of melee attack hitbox")
-- Commands for when attacks hit
local cv_lefthandcommand = CreateClientConVar("vrmelee_lefthand_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when left hand melee attack hits")
local cv_righthandcommand = CreateClientConVar("vrmelee_righthand_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when right hand melee attack hits")
local cv_leftfootcommand = CreateClientConVar("vrmelee_leftfoot_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when left foot melee attack hits")
local cv_rightfootcommand = CreateClientConVar("vrmelee_rightfoot_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when right foot melee attack hits")
local cv_gunmeleecommand = CreateClientConVar("vrmelee_gunmelee_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when gun melee attack hits")
-- For hit feedback
local cv_meleefeedback = CreateClientConVar("vrmelee_hit_feedback", "1", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Enable hit feedback for melee attacks")
local cv_meleesound = CreateClientConVar("vrmelee_hit_sound", "1", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Play sound on melee hit")
-- Blocking configuration
local cv_emulateblocking = CreateClientConVar("vrmelee_emulateblocking", "0", true, FCVAR_ARCHIVE, "Emulate blocking when hand is rotated 70-100 degrees")
local cv_emulateblockbutton = CreateClientConVar("vrmelee_emulateblockbutton", "+attack2", true, FCVAR_ARCHIVE, "Button to emulate when blocking")
local cv_emulateblockrelease = CreateClientConVar("vrmelee_emulateblockbutton_release", "-attack2", true, FCVAR_ARCHIVE, "Button to emulate when blocking")
local blockingThresholdLow = CreateClientConVar("vrmelee_emulatebloack_Threshold_Low", "115", true, FCVAR_ARCHIVE, "")
local blockingThresholdHigh = CreateClientConVar("vrmelee_emulatebloack_Threshold_High", "180", true, FCVAR_ARCHIVE, "")
local dummylefthand = CreateClientConVar("vrmod_lefthand", 0, false)
-- Melee attack timing
local NextMeleeTime = 0
local LastHitTime = 0
local LastHitEntity = nil
-- Sound effects for melee attacks
local MELEE_SOUNDS = {
    MISS = {"weapons/iceaxe/iceaxe_swing1.wav"},
    FLESH = {"physics/flesh/flesh_impact_bullet1.wav", "physics/flesh/flesh_impact_bullet2.wav", "physics/flesh/flesh_impact_bullet3.wav", "physics/flesh/flesh_impact_bullet4.wav", "physics/flesh/flesh_impact_bullet5.wav"},
    METAL = {"physics/metal/metal_solid_impact_bullet1.wav", "physics/metal/metal_solid_impact_bullet2.wav", "physics/metal/metal_solid_impact_bullet3.wav", "physics/metal/metal_solid_impact_bullet4.wav"},
    WOOD = {"physics/wood/wood_solid_impact_bullet1.wav", "physics/wood/wood_solid_impact_bullet2.wav", "physics/wood/wood_solid_impact_bullet3.wav", "physics/wood/wood_solid_impact_bullet4.wav", "physics/wood/wood_solid_impact_bullet5.wav"},
    GLASS = {"physics/glass/glass_impact_bullet1.wav", "physics/glass/glass_impact_bullet2.wav", "physics/glass/glass_impact_bullet3.wav", "physics/glass/glass_impact_bullet4.wav"},
    CONCRETE = {"physics/concrete/concrete_impact_bullet1.wav", "physics/concrete/concrete_impact_bullet2.wav", "physics/concrete/concrete_impact_bullet3.wav", "physics/concrete/concrete_impact_bullet4.wav"}
}

-- 新しいConVarを追加 - ハイダメージモードでFireBulletsも使うかどうか
local cv_highVelocityFireBullets = CreateConVar("vrmelee_high_velocity_fire_bullets", "0", FCVAR_REPLICATED + FCVAR_ARCHIVE, "When enabled, high velocity attacks will also fire bullets for compatibility with old systems")
-- Function to determine damage type based on material
local function GetDamageTypeFromSurface(surfaceProps)
    local surfaceName = util.GetSurfacePropName(surfaceProps)
    if string.find(surfaceName, "metal") or string.find(surfaceName, "grate") then
        return DMG_CLUB, "METAL"
    elseif string.find(surfaceName, "wood") then
        return DMG_CLUB, "WOOD"
    elseif string.find(surfaceName, "flesh") or string.find(surfaceName, "zombie") or string.find(surfaceName, "player") then
        return DMG_CLUB, "FLESH"
    elseif string.find(surfaceName, "glass") then
        return bit.bor(DMG_CLUB, DMG_SLASH), "GLASS"
    elseif string.find(surfaceName, "concrete") or string.find(surfaceName, "tile") or string.find(surfaceName, "brick") then
        return DMG_CLUB, "CONCRETE"
    end
    -- Default

    return DMG_CLUB, "CONCRETE"
end

-- Handle blocking mechanics
hook.Add(
    "VRMod_Tracking",
    "vrmod_melee_blocking",
    function()
        if not cv_emulateblocking:GetBool() then return end
        local leftHandAng = g_VR.tracking.pose_lefthand.ang
        local rightHandAng = g_VR.tracking.pose_righthand.ang
        local leftBlocking = leftHandAng.z >= blockingThresholdLow:GetFloat() and leftHandAng.z <= blockingThresholdHigh:GetFloat()
        local rightBlocking = rightHandAng.z >= blockingThresholdLow:GetFloat() and rightHandAng.z <= blockingThresholdHigh:GetFloat()
        if (dummylefthand:GetBool() and leftBlocking) or (not dummylefthand:GetBool() and rightBlocking) then
            LocalPlayer():ConCommand(cv_emulateblockbutton:GetString())
        else
            LocalPlayer():ConCommand(cv_emulateblockrelease:GetString())
        end
    end
)

if CLIENT then
    local meleeBoxes = {}
    local meleeBoxLifetime = 0.1
    local isAttacking = false
    local attackBox = nil
    -- Play hit sound based on hit material
    local function PlayHitSound(surfaceProps, hitPos)
        if not cv_meleesound:GetBool() then return end
        local _, soundType = GetDamageTypeFromSurface(surfaceProps)
        local sounds = MELEE_SOUNDS[soundType] or MELEE_SOUNDS.CONCRETE
        local sound = sounds[math.random(1, #sounds)]
        sound = sound or MELEE_SOUNDS.MISS[1] -- Fallback sound
        EmitSound(sound, hitPos, LocalPlayer():EntIndex(), CHAN_WEAPON, 1, 75, 0, math.random(90, 110))
    end

    -- Play a miss sound
    local function PlayMissSound(pos)
        if not cv_meleesound:GetBool() then return end
        -- local sound = MELEE_SOUNDS.MISS[1]
        -- EmitSound(sound, pos, LocalPlayer():EntIndex(), CHAN_WEAPON, 0.5, 75, 0, math.random(90, 110))
    end

    -- Helper function to check if we should perform melee attack based on velocity
    local function ShouldPerformMeleeAttack(velocity)
        local vel = velocity:Length() / 40
        if vel >= cv_meleeVelocityLow:GetFloat() then
            local damage = 0
            local isHighVelocity = false
            if vel >= cv_meleeVelocityHigh:GetFloat() then
                damage = cv_meleeDamageHigh:GetFloat()
                isHighVelocity = true
            elseif vel >= cv_meleeVelocityMedium:GetFloat() then
                damage = cv_meleeDamageMedium:GetFloat()
            elseif vel >= cv_meleeVelocityLow:GetFloat() then
                damage = cv_meleeDamageLow:GetFloat()
            end

            return true, damage, vel, isHighVelocity
        end

        return false, 0, vel, false
    end

    -- Improved melee attack function that works like crowbar
    local function PerformMeleeAttack(src, dir, damage, isGunMelee, surfaceCheck, isHighVelocity)
        local ply = LocalPlayer()
        -- Default surface props
        local surfaceProps = surfaceCheck or 0
        -- Calculate damage type based on the surface properties
        local damageType, soundType = GetDamageTypeFromSurface(surfaceProps)
        -- Trace for actual hit detection with better accuracy
        local range = cv_meleeRange:GetFloat()
        local tr = util.TraceLine(
            {
                start = src,
                endpos = src + dir * range,
                filter = ply,
                mask = MASK_SHOT_HULL
            }
        )

        -- If didn't hit anything with line trace, try a hull trace for better hit chances
        if not tr.Hit then
            local hitboxWidth = cv_meleeHitboxWidth:GetFloat()
            local hitboxLength = cv_meleeHitboxLength:GetFloat()
            tr = util.TraceHull(
                {
                    start = src,
                    endpos = src + dir * range,
                    filter = ply,
                    mins = Vector(-hitboxWidth, -hitboxWidth, -hitboxWidth),
                    maxs = Vector(hitboxWidth, hitboxWidth, hitboxWidth),
                    mask = MASK_SHOT_HULL
                }
            )
        end

        -- Check for hit and send to server if we hit something
        if tr.Hit then
            -- Avoid hitting the same entity too quickly (crowbar behavior)
            if LastHitEntity == tr.Entity and CurTime() - LastHitTime < 0.1 then return false end
            LastHitEntity = tr.Entity
            LastHitTime = CurTime()
            -- Apply cooldown
            NextMeleeTime = CurTime() + cv_meleeCooldown:GetFloat()
            -- Play appropriate hit sound
            PlayHitSound(tr.SurfaceProps, tr.HitPos)
            -- Send hit info to server
            net.Start("VRMod_MeleeAttack")
            net.WriteVector(tr.HitPos)
            net.WriteVector(dir)
            net.WriteFloat(damage)
            net.WriteBool(isGunMelee)
            net.WriteUInt(damageType, 32)
            net.WriteUInt(tr.SurfaceProps, 32)
            net.WriteEntity(tr.Entity)
            net.WriteBool(isHighVelocity and cv_highVelocityFireBullets:GetBool()) -- 高速攻撃でFireBulletsモードが有効かをサーバーに送信
            net.SendToServer()

            return true
        else
            -- Play miss sound if we didn't hit anything
            PlayMissSound(src)

            return false
        end
    end

    -- Main function for processing melee attacks
    hook.Add(
        "VRMod_Tracking",
        "VRMeleeAttacks",
        function(action, pressed)
            if not IsValid(LocalPlayer()) then return end
            local ply = LocalPlayer()
            if not ply:Alive() or ply:InVehicle() or not IsPlayerInVR(ply) then return end
            if NextMeleeTime > CurTime() then return end
            -- Helper function to find the viewmodel tip position
            local function GetViewModelTipPosition(vm)
                local bestDist = 0
                local bestPos = nil
                for i = 0, vm:GetBoneCount() - 1 do
                    local bonePos, _ = vm:GetBonePosition(i)
                    local dist = bonePos:Distance(vrmod.GetRightHandPos(ply))
                    if dist > bestDist then
                        bestDist = dist
                        bestPos = bonePos
                    end
                end

                return bestPos
            end

            -- Process gun melee attacks
            if cv_allowgunmelee:GetBool() and cl_usegunmelee:GetBool() then
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) and wep:GetClass() ~= "weapon_vrmod_empty" then
                    local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(vrmod.GetRightHandVelocity())
                    if shouldAttack then
                        local vm = ply:GetViewModel()
                        if IsValid(vm) then
                            local muzzleAttach = vm:GetAttachment(1)
                            local src = muzzleAttach and muzzleAttach.Pos or vrmod.GetRightHandPos(ply)
                            local dir = vrmod.GetRightHandVelocity():GetNormalized()
                            -- If a gun command is set, execute it
                            if cv_gunmeleecommand:GetString() ~= "" and damage > 0 then
                                LocalPlayer():ConCommand(cv_gunmeleecommand:GetString())
                            end

                            -- Perform the attack
                            local hit = PerformMeleeAttack(src, dir, damage, true, nil, isHighVelocity)
                        end
                    end
                end
            end

            -- Process gun melee left hand attacks (fist or open hand)
            if cv_allowgunmelee:GetBool() and cl_usegunmelee:GetBool() then
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) and wep:GetClass() ~= "weapon_vrmod_empty" then
                    local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(vrmod.GetLeftHandVelocity())
                    if shouldAttack then
                        local src = vrmod.GetLeftHandPos(ply)
                        local dir = vrmod.GetLeftHandVelocity():GetNormalized()
                        -- If a command is set, execute it
                        if cv_lefthandcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_lefthandcommand:GetString())
                        end

                        -- Create visual effect if enabled
                        if cl_fisteffect:GetBool() then
                            net.Start("VRMod_SpawnMeleeBox")
                            net.WriteVector(src)
                            net.WriteVector(dir)
                            net.SendToServer()
                        end

                        -- Perform the attack
                        local hit = PerformMeleeAttack(src, dir, damage, false, nil, isHighVelocity)
                    end
                end
            end

            -- Process gun melee right hand attacks (fist or open hand)
            if cv_allowgunmelee:GetBool() and cl_usegunmelee:GetBool() then
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) and wep:GetClass() ~= "weapon_vrmod_empty" then
                    local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(vrmod.GetRightHandVelocity())
                    if shouldAttack then
                        local src = vrmod.GetRightHandPos(ply)
                        local dir = vrmod.GetRightHandVelocity():GetNormalized()
                        -- If a command is set, execute it
                        if cv_righthandcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_righthandcommand:GetString())
                        end

                        -- Create visual effect if enabled
                        if cl_fisteffect:GetBool() then
                            net.Start("VRMod_SpawnMeleeBox")
                            net.WriteVector(src)
                            net.WriteVector(dir)
                            net.SendToServer()
                        end

                        -- Perform the attack
                        local hit = PerformMeleeAttack(src, dir, damage, false, nil, isHighVelocity)
                    end
                end
            end

            -- Process left hand attacks (fist or open hand)
            if cv_allowfist:GetBool() and cl_usefist:GetBool() then
                local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(vrmod.GetLeftHandVelocity())
                if shouldAttack then
                    local src = vrmod.GetLeftHandPos(ply)
                    local dir = vrmod.GetLeftHandVelocity():GetNormalized()
                    -- If a command is set, execute it
                    if cv_lefthandcommand:GetString() ~= "" then
                        LocalPlayer():ConCommand(cv_lefthandcommand:GetString())
                    end

                    -- Create visual effect if enabled
                    if cl_fisteffect:GetBool() then
                        net.Start("VRMod_SpawnMeleeBox")
                        net.WriteVector(src)
                        net.WriteVector(dir)
                        net.SendToServer()
                    end

                    -- Perform the attack
                    local hit = PerformMeleeAttack(src, dir, damage, false, nil, isHighVelocity)
                end
            end

            -- Process right hand attacks (fist or open hand)
            if cv_allowfist:GetBool() and cl_usefist:GetBool() then
                local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(vrmod.GetRightHandVelocity())
                if shouldAttack then
                    local src = vrmod.GetRightHandPos(ply)
                    local dir = vrmod.GetRightHandVelocity():GetNormalized()
                    -- If a command is set, execute it
                    if cv_righthandcommand:GetString() ~= "" then
                        LocalPlayer():ConCommand(cv_righthandcommand:GetString())
                    end

                    -- Create visual effect if enabled
                    if cl_fisteffect:GetBool() then
                        net.Start("VRMod_SpawnMeleeBox")
                        net.WriteVector(src)
                        net.WriteVector(dir)
                        net.SendToServer()
                    end

                    -- Perform the attack
                    local hit = PerformMeleeAttack(src, dir, damage, false, nil, isHighVelocity)
                end
            end

            -- Process left foot attacks (requires full body tracking)
            if cv_allowkick:GetBool() and cl_usekick:GetBool() then
                if g_VR.net[ply:SteamID()] and g_VR.net[ply:SteamID()].lerpedFrame and g_VR.net[ply:SteamID()].lerpedFrame.leftfootPos then
                    -- Get the velocity from the foot position (calculated between frames)
                    local footPos = g_VR.net[ply:SteamID()].lerpedFrame.leftfootPos
                    local footVel = Vector(0, 0, 0) -- This should actually be calculated from position change
                    local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(footVel)
                    if shouldAttack then
                        local src = footPos
                        local dir = footVel:GetNormalized()
                        -- If a command is set, execute it
                        if cv_leftfootcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_leftfootcommand:GetString())
                        end

                        -- Create visual effect if enabled
                        if cl_fisteffect:GetBool() then
                            net.Start("VRMod_SpawnMeleeBox")
                            net.WriteVector(src)
                            net.WriteVector(dir)
                            net.SendToServer()
                        end

                        -- Perform the attack
                        local hit = PerformMeleeAttack(src, dir, damage, false, nil, isHighVelocity)
                    end
                end
            end

            -- Process right foot attacks (requires full body tracking)
            if cv_allowkick:GetBool() and cl_usekick:GetBool() then
                if g_VR.net[ply:SteamID()] and g_VR.net[ply:SteamID()].lerpedFrame and g_VR.net[ply:SteamID()].lerpedFrame.rightfootPos then
                    -- Get the velocity from the foot position (calculated between frames)
                    local footPos = g_VR.net[ply:SteamID()].lerpedFrame.rightfootPos
                    local footVel = Vector(0, 0, 0) -- This should actually be calculated from position change
                    local shouldAttack, damage, vel, isHighVelocity = ShouldPerformMeleeAttack(footVel)
                    if shouldAttack then
                        local src = footPos
                        local dir = footVel:GetNormalized()
                        -- If a command is set, execute it
                        if cv_rightfootcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_rightfootcommand:GetString())
                        end

                        -- Create visual effect if enabled
                        if cl_fisteffect:GetBool() then
                            net.Start("VRMod_SpawnMeleeBox")
                            net.WriteVector(src)
                            net.WriteVector(dir)
                            net.SendToServer()
                        end

                        -- Perform the attack
                        local hit = PerformMeleeAttack(src, dir, damage, false, nil, isHighVelocity)
                    end
                end
            end
        end
    )

    -- Add impact effects for melee hits
    hook.Add("PostDrawEffects", "VRMeleeImpactEffects", function() end) -- Add impact effects here if needed
end

if SERVER then
    util.AddNetworkString("VRMod_MeleeAttack")
    util.AddNetworkString("VRMod_SpawnMeleeBox")
    local meleeBoxLifetime = 0.1
    -- Handle melee attacks sent from clients
    net.Receive(
        "VRMod_MeleeAttack",
        function(len, ply)
            if not IsValid(ply) or not ply:Alive() then return end
            -- Read data
            local hitPos = net.ReadVector()
            local dir = net.ReadVector()
            local damage = net.ReadFloat()
            local isGunMelee = net.ReadBool()
            local damageType = net.ReadUInt(32)
            local surfaceProps = net.ReadUInt(32)
            local hitEntity = net.ReadEntity()
            local useFireBullets = net.ReadBool() -- 新しく追加されたFireBulletsフラグ
            -- Lag compensation
            ply:LagCompensation(true)
            -- Create impact effects at hit position
            util.Decal("ManhackCut", hitPos + dir * 5, hitPos - dir * 5, ply)
            -- Deal damage
            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage(damage)
            dmgInfo:SetDamageType(damageType)
            dmgInfo:SetDamageForce(dir * cv_meleeimpact:GetFloat() * 300)
            dmgInfo:SetDamagePosition(hitPos)
            dmgInfo:SetAttacker(ply)
            dmgInfo:SetInflictor(ply)
            -- If we have a valid hit entity, apply damage to it
            if IsValid(hitEntity) then
                hitEntity:TakeDamageInfo(dmgInfo)
            end

            -- 高速攻撃時かつFireBulletsモードが有効な場合、FireBulletsも実行する
            if useFireBullets then
                ply:FireBullets(
                    {
                        Attacker = ply,
                        Damage = damage,
                        Force = cv_meleeimpact:GetFloat() * 300,
                        Num = 1,
                        Tracer = 0,
                        Dir = dir,
                        Spread = Vector(0, 0, 0),
                        Src = hitPos - (dir * 5),
                        IgnoreEntity = ply,
                        Callback = function(attacker, trace, dmgInfo)
                            -- This callback is mainly for applying specific damage effects
                            -- or handling special interactions
                            dmgInfo:SetDamageType(damageType)
                        end
                    }
                )
            end

            ply:LagCompensation(false)
        end
    )

    -- Handle the creation of visual effects for melee attacks
    net.Receive(
        "VRMod_SpawnMeleeBox",
        function(len, ply)
            if not IsValid(ply) or not ply:Alive() then return end
            local pos = net.ReadVector()
            local dir = net.ReadVector()
            local ang = dir:Angle()
            -- Create the visual effect entity
            local ent = ents.Create("prop_physics")
            ent:SetModel(cl_effectmodel:GetString())
            ent:SetPos(pos)
            ent:SetAngles(ang)
            ent:Spawn()
            ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
            -- Set visibility
            if cl_fistvisible:GetBool() then
                ent:SetRenderMode(RENDERMODE_NORMAL)
            else
                ent:SetRenderMode(RENDERMODE_TRANSALPHA)
                ent:SetColor(Color(255, 255, 255, 0))
            end

            -- Configure physics
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetMass(100)
                phys:EnableGravity(false)
                phys:EnableCollisions(true)
                phys:EnableMotion(false)
            end

            -- Remove after lifetime
            SafeRemoveEntityDelayed(ent, meleeBoxLifetime)
        end
    )

    -- Add hook to display damage when debugging
    hook.Add(
        "ScalePlayerDamage",
        "VRMelee_DebugDamage",
        function(ply, hitgroup, dmginfo)
            if dmginfo:GetAttacker():IsPlayer() and vrmod.IsPlayerInVR(dmginfo:GetAttacker()) then end -- Could add debug visualization here
        end
    )
end
--------[vrmod_melee_global.lua]End--------