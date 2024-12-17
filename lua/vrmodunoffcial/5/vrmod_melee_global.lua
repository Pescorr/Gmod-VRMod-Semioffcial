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

local cv_allowgunmelee = CreateConVar("vrmelee_gunmelee", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow melee attacks with gun?")
local cv_allowfist = CreateConVar("vrmelee_fist", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow fist attacks?")
local cv_allowkick = CreateConVar("vrmelee_kick", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Allow kick attacks? (Requires full body tracking)")
local cv_meleeDamageLow = CreateConVar("vrmelee_damage_low", "1.000", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Low velocity attack damage")
local cv_meleeDamageMedium = CreateConVar("vrmelee_damage_medium", "5.000", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Medium velocity attack damage")
local cv_meleeDamageHigh = CreateConVar("vrmelee_damage_high", "10.000", FCVAR_REPLICATED + FCVAR_ARCHIVE, "High velocity attack damage")
local cv_meleeVelocityLow = CreateConVar("vrmelee_damage_velocity_low", "1.1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Low velocity attack range")
local cv_meleeVelocityMedium = CreateConVar("vrmelee_damage_velocity_medium", "2.3", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Medium velocity attack range")
local cv_meleeVelocityHigh = CreateConVar("vrmelee_damage_velocity_high", "3.3", FCVAR_REPLICATED + FCVAR_ARCHIVE, "High velocity attack range")
local cv_meleeimpact = CreateConVar("vrmelee_impact", "0.0001", FCVAR_REPLICATED + FCVAR_ARCHIVE)
local cv_meleeDelay = CreateConVar("vrmelee_delay", "0.0001", FCVAR_REPLICATED + FCVAR_ARCHIVE)
local cl_usegunmelee = CreateClientConVar("vrmelee_usegunmelee", "1", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use melee attacks with gun?")
local cl_usefist = CreateClientConVar("vrmelee_usefist", "1", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use fist attacks?")
local cl_usekick = CreateClientConVar("vrmelee_usekick", "0", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use kick attacks? (Requires full body tracking)")
local cl_fisteffect = CreateClientConVar("vrmelee_fist_collision", "0", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Use Fist attack Collision?")
local cl_fistvisible = CreateClientConVar("vrmelee_fist_visible", "0", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Visible Fist Attack Collision Model?")
local cl_effectmodel = CreateClientConVar("vrmelee_fist_collisionmodel", "models/hunter/plates/plate.mdl", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Fist Attack Collision Model Config")
local cv_meleeCooldown = CreateClientConVar("vrmelee_cooldown", "0.0001", true, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Cooldown time for VR melee attacks")
local cv_lefthandcommand = CreateClientConVar("vrmelee_lefthand_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when left hand melee attack hits")
local cv_righthandcommand = CreateClientConVar("vrmelee_righthand_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when right hand melee attack hits")
local cv_leftfootcommand = CreateClientConVar("vrmelee_leftfoot_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when left foot melee attack hits")
local cv_rightfootcommand = CreateClientConVar("vrmelee_rightfoot_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when right foot melee attack hits")
local cv_gunmeleecommand = CreateClientConVar("vrmelee_gunmelee_command", "", true, FCVAR_CLIENTCMD_CAN_EXECUTE + FCVAR_ARCHIVE, "Command to execute when gun melee attack hits")
local NextMeleeTime = 0
local cv_emulateblocking = CreateClientConVar("vrmelee_emulateblocking", "0", true, FCVAR_ARCHIVE, "Emulate blocking when hand is rotated 70-100 degrees")
local cv_emulateblockbutton = CreateClientConVar("vrmelee_emulateblockbutton", "+attack2", true, FCVAR_ARCHIVE, "Button to emulate when blocking")
local cv_emulateblockrelease = CreateClientConVar("vrmelee_emulateblockbutton_release", "-attack2", true, FCVAR_ARCHIVE, "Button to emulate when blocking")
local blockingThresholdLow = CreateClientConVar("vrmelee_emulatebloack_Threshold_Low", "115", true, FCVAR_ARCHIVE, "")
local blockingThresholdHigh = CreateClientConVar("vrmelee_emulatebloack_Threshold_High", "180", true, FCVAR_ARCHIVE, "")

local dummylefthand = CreateClientConVar("vrmod_lefthand", 0, false)
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
    hook.Add(
        "VRMod_Tracking",
        "VRMeleeAttacks",
        function(action, pressed)
            if not IsValid(LocalPlayer()) then return end
            local ply = LocalPlayer()
            if not ply:Alive() or ply:InVehicle() or not IsPlayerInVR(ply) then return end
            if NextMeleeTime > CurTime() then return end
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

            if cv_allowgunmelee:GetBool() and cl_usegunmelee:GetBool() then
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) then
                    local vm = ply:GetViewModel()
                    if IsValid(vm) then
                        local vel = vrmod.GetRightHandVelocity():Length() / 40
                        local meleeDamage = 0
                        if vel >= cv_meleeVelocityHigh:GetFloat() then
                            meleeDamage = cv_meleeDamageHigh:GetFloat()
                        elseif vel >= cv_meleeVelocityMedium:GetFloat() then
                            meleeDamage = cv_meleeDamageMedium:GetFloat()
                        elseif vel >= cv_meleeVelocityLow:GetFloat() then
                            meleeDamage = cv_meleeDamageLow:GetFloat()
                        end

                        if meleeDamage > 0 then
                            local tr = util.TraceHull(
                                {
                                    start = vm:GetPos(),
                                    endpos = vm:GetPos(),
                                    filter = ply,
                                    mins = vm:OBBMins(),
                                    maxs = vm:OBBMaxs()
                                }
                            )

                            if cv_gunmeleecommand:GetString() ~= "" then
                                LocalPlayer():ConCommand(cv_gunmeleecommand:GetString())
                            end

                            if tr.Hit then
                                NextMeleeTime = CurTime() + cv_meleeDelay:GetFloat()
                                local src = tr.HitPos + (tr.HitNormal * -2)
                                local tr2 = util.TraceLine(
                                    {
                                        start = src,
                                        endpos = src + (vrmod.GetRightHandVelocity():GetNormalized() * 50),
                                        filter = ply
                                    }
                                )

                                if tr2.Hit then
                                    NextMeleeTime = CurTime() + cv_meleeCooldown:GetFloat()
                                    net.Start("VRMod_MeleeAttack")
                                    net.WriteFloat(src[1])
                                    net.WriteFloat(src[2])
                                    net.WriteFloat(src[3])
                                    net.WriteVector(vrmod.GetRightHandVelocity():GetNormalized())
                                    net.WriteFloat(meleeDamage)
                                    net.WriteBool(true)
                                    net.SendToServer()
                                end
                            end
                        end
                    end
                end
            end

            local activeWeapon = LocalPlayer():GetActiveWeapon()
            if (cv_allowfist:GetBool() and cl_usefist:GetBool()) or (cv_allowgunmelee:GetBool() and cl_usegunmelee:GetBool() and (IsValid(activeWeapon) and activeWeapon:GetClass() ~= "weapon_vrmod_empty")) then
                local lhvel = vrmod.GetLeftHandVelocity():Length() / 40
                local meleeDamage = 0
                if lhvel >= cv_meleeVelocityHigh:GetFloat() then
                    meleeDamage = cv_meleeDamageHigh:GetFloat()
                elseif lhvel >= cv_meleeVelocityMedium:GetFloat() then
                    meleeDamage = cv_meleeDamageMedium:GetFloat()
                elseif lhvel >= cv_meleeVelocityLow:GetFloat() then
                    meleeDamage = cv_meleeDamageLow:GetFloat()
                end

                if meleeDamage > 0 then
                    local src = vrmod.GetLeftHandPos(ply)
                    local tr = util.TraceLine(
                        {
                            start = src,
                            endpos = src,
                            filter = ply
                        }
                    )

                    NextMeleeTime = CurTime() + cv_meleeDelay:GetFloat()
                    local src = tr.HitPos + (tr.HitNormal * -2)
                    local tr2 = util.TraceLine(
                        {
                            start = src,
                            endpos = src + (vrmod.GetLeftHandVelocity():GetNormalized() * 8),
                            filter = ply
                        }
                    )

                    if cl_fisteffect:GetBool() then
                        net.Start("VRMod_SpawnMeleeBox")
                        net.WriteVector(src)
                        net.WriteVector(tr2.HitNormal)
                        net.SendToServer()
                        if cv_lefthandcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_lefthandcommand:GetString())
                        end
                    end

                    if tr2.Hit then
                        NextMeleeTime = CurTime() + cv_meleeCooldown:GetFloat()
                        net.Start("VRMod_MeleeAttack")
                        net.WriteFloat(src[1])
                        net.WriteFloat(src[2])
                        net.WriteFloat(src[3])
                        net.WriteVector(vrmod.GetLeftHandVelocity():GetNormalized())
                        net.WriteFloat(meleeDamage)
                        net.WriteBool(false)
                        net.SendToServer()
                    end
                end
            end

            local activeWeapon = LocalPlayer():GetActiveWeapon()
            if (cv_allowfist:GetBool() and cl_usefist:GetBool()) or (cv_allowgunmelee:GetBool() and cl_usegunmelee:GetBool() and (IsValid(activeWeapon) and activeWeapon:GetClass() ~= "weapon_vrmod_empty")) then
                local rhvel = vrmod.GetRightHandVelocity():Length() / 40
                local meleeDamage = 0
                if rhvel >= cv_meleeVelocityHigh:GetFloat() then
                    meleeDamage = cv_meleeDamageHigh:GetFloat()
                elseif rhvel >= cv_meleeVelocityMedium:GetFloat() then
                    meleeDamage = cv_meleeDamageMedium:GetFloat()
                elseif rhvel >= cv_meleeVelocityLow:GetFloat() then
                    meleeDamage = cv_meleeDamageLow:GetFloat()
                end

                if meleeDamage > 0 then
                    local src = vrmod.GetRightHandPos(ply)
                    local tr = util.TraceLine(
                        {
                            start = src,
                            endpos = src,
                            filter = ply
                        }
                    )

                    NextMeleeTime = CurTime() + cv_meleeDelay:GetFloat()
                    local src = tr.HitPos + (tr.HitNormal * -2)
                    local tr2 = util.TraceLine(
                        {
                            start = src,
                            endpos = src + (vrmod.GetRightHandVelocity():GetNormalized() * 8),
                            filter = ply
                        }
                    )

                    if cl_fisteffect:GetBool() then
                        net.Start("VRMod_SpawnMeleeBox")
                        net.WriteVector(src)
                        net.WriteVector(tr2.HitNormal)
                        net.SendToServer()
                        if cv_righthandcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_righthandcommand:GetString())
                        end
                    end

                    if tr2.Hit then
                        NextMeleeTime = CurTime() + cv_meleeCooldown:GetFloat()
                        net.Start("VRMod_MeleeAttack")
                        net.WriteFloat(src[1])
                        net.WriteFloat(src[2])
                        net.WriteFloat(src[3])
                        net.WriteVector(vrmod.GetRightHandVelocity():GetNormalized())
                        net.WriteFloat(meleeDamage)
                        net.WriteBool(false)
                        net.SendToServer()
                    end
                end
            end

            if cv_allowkick:GetBool() and cl_usekick:GetBool() then
                if not g_VR.net[ply:SteamID()] or not g_VR.net[ply:SteamID()].lerpedFrame then return end
                local lfvel = g_VR.net[ply:SteamID()].lerpedFrame.leftfootPos:Length() / 40
                local meleeDamage = 0
                if lfvel >= cv_meleeVelocityHigh:GetFloat() then
                    meleeDamage = cv_meleeDamageHigh:GetFloat()
                elseif lfvel >= cv_meleeVelocityMedium:GetFloat() then
                    meleeDamage = cv_meleeDamageMedium:GetFloat()
                elseif lfvel >= cv_meleeVelocityLow:GetFloat() then
                    meleeDamage = cv_meleeDamageLow:GetFloat()
                end

                if meleeDamage > 0 then
                    local src = g_VR.net[ply:SteamID()].lerpedFrame.leftfootPos
                    local tr = util.TraceLine(
                        {
                            start = src,
                            endpos = src,
                            filter = ply
                        }
                    )

                    if cl_fisteffect:GetBool() then
                        net.Start("VRMod_SpawnMeleeBox")
                        net.WriteVector(src)
                        net.WriteVector(tr.HitNormal)
                        net.SendToServer()
                        if cv_leftfootcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_leftfootcommand:GetString())
                        end
                    end

                    if tr.Hit then
                        NextMeleeTime = CurTime() + cv_meleeDelay:GetFloat()
                        local src = tr.HitPos + (tr.HitNormal * -2)
                        local tr2 = util.TraceLine(
                            {
                                start = src,
                                endpos = src + (g_VR.net[ply:SteamID()].lerpedFrame.leftfootPos:GetNormalized() * 8),
                                filter = ply
                            }
                        )

                        if tr2.Hit then
                            NextMeleeTime = CurTime() + cv_meleeCooldown:GetFloat()
                            net.Start("VRMod_MeleeAttack")
                            net.WriteFloat(src[1])
                            net.WriteFloat(src[2])
                            net.WriteFloat(src[3])
                            net.WriteVector(g_VR.net[ply:SteamID()].lerpedFrame.leftfootPos:GetNormalized())
                            net.WriteFloat(meleeDamage)
                            net.WriteBool(false)
                            net.SendToServer()
                        end
                    end
                end
            end

            if cv_allowkick:GetBool() and cl_usekick:GetBool() then
                if not g_VR.net[ply:SteamID()] or not g_VR.net[ply:SteamID()].lerpedFrame then return end
                local rfvel = g_VR.net[ply:SteamID()].lerpedFrame.rightfootPos:Length() / 40
                local meleeDamage = 0
                if rfvel >= cv_meleeVelocityHigh:GetFloat() then
                    meleeDamage = cv_meleeDamageHigh:GetFloat()
                elseif rfvel >= cv_meleeVelocityMedium:GetFloat() then
                    meleeDamage = cv_meleeDamageMedium:GetFloat()
                elseif rfvel >= cv_meleeVelocityLow:GetFloat() then
                    meleeDamage = cv_meleeDamageLow:GetFloat()
                end

                if meleeDamage > 0 then
                    local src = g_VR.net[ply:SteamID()].lerpedFrame.rightfootPos
                    local tr = util.TraceLine(
                        {
                            start = src,
                            endpos = src,
                            filter = ply
                        }
                    )

                    if cl_fisteffect:GetBool() then
                        net.Start("VRMod_SpawnMeleeBox")
                        net.WriteVector(src)
                        net.WriteVector(tr.HitNormal)
                        net.SendToServer()
                        if cv_rightfootcommand:GetString() ~= "" then
                            LocalPlayer():ConCommand(cv_rightfootcommand:GetString())
                        end
                    end

                    if tr.Hit then
                        NextMeleeTime = CurTime() + cv_meleeDelay:GetFloat()
                        local src = tr.HitPos + (tr.HitNormal * -2)
                        local tr2 = util.TraceLine(
                            {
                                start = src,
                                endpos = src + (g_VR.net[ply:SteamID()].lerpedFrame.rightfootPos:GetNormalized() * 8),
                                filter = ply
                            }
                        )

                        if tr2.Hit then
                            NextMeleeTime = CurTime() + cv_meleeCooldown:GetFloat()
                            net.Start("VRMod_MeleeAttack")
                            net.WriteFloat(src[1])
                            net.WriteFloat(src[2])
                            net.WriteFloat(src[3])
                            net.WriteVector(g_VR.net[ply:SteamID()].lerpedFrame.rightfootPos:GetNormalized())
                            net.WriteFloat(meleeDamage)
                            net.WriteBool(false)
                            net.SendToServer()
                        end
                    end
                end
            end
        end
    )
end

if SERVER then
    util.AddNetworkString("VRMod_MeleeAttack")
    util.AddNetworkString("VRMod_SpawnMeleeBox")
    local meleeBoxLifetime = 0.1 -- サーバー側でmeleeBoxLifetimeを定義
    net.Receive(
        "VRMod_MeleeAttack",
        function(len, ply)
            if not IsValid(ply) or not ply:Alive() then return end
            local src = Vector()
            src[1] = net.ReadFloat()
            src[2] = net.ReadFloat()
            src[3] = net.ReadFloat()
            local vel = net.ReadVector()
            local meleeDamage = net.ReadFloat()
            local isGunMelee = net.ReadBool()
            ply:LagCompensation(true)
            ply:FireBullets(
                {
                    Attacker = ply,
                    Damage = meleeDamage,
                    Force = cv_meleeimpact:GetFloat(),
                    Num = 1,
                    Tracer = 0,
                    Dir = vel,
                    DamageType = DMG_CLUB,
                    Src = src
                }
            )

            ply:LagCompensation(false)
        end
    )

    net.Receive(
        "VRMod_SpawnMeleeBox",
        function(len, ply)
            if not IsValid(ply) or not ply:Alive() then return end
            local pos = net.ReadVector()
            local ang = net.ReadVector():Angle()
            local ent = ents.Create("prop_physics")
            ent:SetModel(cl_effectmodel:GetString())
            ent:SetPos(pos)
            ent:SetAngles(ang)
            ent:Spawn()
            ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
            if cl_fistvisible:GetBool() then
                ent:SetRenderMode(RENDERMODE_NORMAL)
            else
                ent:SetRenderMode(RENDERMODE_TRANSALPHA)
                ent:SetColor(Color(255, 255, 255, 0))
            end

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetMass(100)
                phys:EnableGravity(false)
                phys:EnableCollisions(true)
                phys:EnableMotion(false)
            end

            SafeRemoveEntityDelayed(ent, meleeBoxLifetime) -- 直接値を指定
        end
    )
end