AddCSLuaFile()
CreateClientConVar("vrmod_pickup_beamrange02", 30, true, FCVAR_ARCHIVE, "Range to check for entities to grab")
CreateClientConVar("vrmod_pickup_weight", 100, true, FCVAR_ARCHIVE, "Max weight of entity to grab")
CreateClientConVar("vrmod_pickup_beam_enable", 1, true, FCVAR_ARCHIVE, "Enable/disable the pickup beam laser")
CreateClientConVar("vrmod_pickup_beam_damage", 0.0001, true, FCVAR_ARCHIVE, "Damage dealt by the beam laser", 0, 1.000)
CreateClientConVar("vrmod_pickup_beam_damage_enable", 1, true, FCVAR_ARCHIVE, "Enable/disable damage dealt by the beam laser")
CreateClientConVar("vrmod_pickup_beam_ragdoll_spine", 0, true, FCVAR_ARCHIVE, "Enable/disable damage to ragdoll spine")
if SERVER then
    if util ~= nil then
        util.AddNetworkString("vrmod_pickup_beam")
        util.AddNetworkString("vrmod_pickup_beam_damage")
        local function FindNearestEntity(ply, handPos, grabRange, maxWeight, excludeEnt)
            local nearestEnt = nil
            local nearestDist = grabRange
            for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
                if IsValid(ent) and not ent:IsPlayer() and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject():GetMass() <= maxWeight then
                    local dist = handPos:Distance(ent:GetPos())
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestEnt = ent
                    end
                end
            end

            return nearestEnt
        end

        local function TeleportEntityToHand(ply, handPos, ent, isLeftHand)
            if ent then
                ent:SetPos(handPos)
                ent:Activate(false)
                pickup(ply, isLeftHand, handPos, Angle())
                ent:Activate(true)
            end
        end

        net.Receive(
            "vrmod_pickup_beam",
            function(len, ply)
                if not IsValid(ply) or ply:InVehicle() then return end
                local isLeftHand = net.ReadBool()
                local grabRange = net.ReadFloat()
                local maxWeight = net.ReadFloat()
                local entClass = net.ReadString()
                local hitPos = net.ReadVector()
                local handPos = net.ReadVector()
                local foundEnt = nil
                local otherHandEnt = g_VR[ply:SteamID()].heldItems and g_VR[ply:SteamID()].heldItems[isLeftHand and 2 or 1] and g_VR[ply:SteamID()].heldItems[isLeftHand and 2 or 1].ent
                if entClass == "" then
                    foundEnt = FindNearestEntity(ply, hitPos, grabRange, maxWeight, otherHandEnt)
                else
                    for _, ent in ipairs(ents.FindInSphere(hitPos, grabRange)) do
                        if ent:GetClass() == entClass and ent ~= otherHandEnt then
                            foundEnt = ent
                            break
                        end
                    end
                end

                TeleportEntityToHand(ply, handPos, foundEnt, isLeftHand)
            end
        )

        net.Receive(
            "vrmod_pickup_beam_damage",
            function(len, ply)
                if not IsValid(ply) or ply:InVehicle() then return end
                if not GetConVar("vrmod_pickup_beam_damage_enable"):GetBool() then return end
                local hitPos = net.ReadVector()
                local damage = net.ReadFloat()
                local dmgInfo = DamageInfo()
                dmgInfo:SetAttacker(ply)
                dmgInfo:SetInflictor(ply)
                dmgInfo:SetDamage(damage)
                dmgInfo:SetDamageType(DMG_CRUSH)
                    dmgInfo:SetDamagePosition(hitPos)
                    util.BlastDamageInfo(dmgInfo, hitPos, 3.0)
            end
        )
    else
        print("util library is not available. Skipping network string registration.")
    end
end

if SERVER then return end
local beamrange = CreateClientConVar("vrmod_pickup_beamrange", 100, true, FCVAR_ARCHIVE, "Range to check for beam")
local function DoTrace(handPos, handAng)
    local traceRes = util.TraceLine(
        {
            start = handPos,
            endpos = handPos + handAng:Forward() * beamrange:GetFloat(),
            filter = LocalPlayer()
        }
    )

    local hitValid = false
    if traceRes.Entity and IsValid(traceRes.Entity) and traceRes.Entity:GetPhysicsObject() then
        local mass = 1
        if mass < GetConVar("vrmod_pickup_weight"):GetFloat() then
            hitValid = true
        end
    end

    local beamMaterial = Material("trails/smoke")
    local beamColor = Color(255, 0, 0, 90)
    local hitvisible = hitValid and 1 or 0
    render.SetMaterial(beamMaterial)
    render.StartBeam(2)
    render.AddBeam(handPos, hitvisible, 0, beamColor)
    render.AddBeam(traceRes.HitPos, hitvisible, traceRes.Fraction * beamrange:GetFloat(), beamColor)
    render.EndBeam()
    if hitValid then
        if traceRes.Entity:GetClass() == "prop_ragdoll" then
            local damage = GetConVar("vrmod_pickup_beam_damage"):GetFloat()
            net.Start("vrmod_pickup_beam_damage")
            net.WriteVector(traceRes.HitPos)
            net.WriteFloat(damage)
            net.SendToServer()
        end
    end

    return traceRes.HitPos
end

concommand.Add(
    "vrmod_pickup_beam_left",
    function(ply, cmd, args)
        if ply:InVehicle() then return end
        if not GetConVar("vrmod_pickup_beam_enable"):GetBool() then return end
        local grabRange = GetConVar("vrmod_pickup_beamrange02"):GetFloat()
        local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
        local entClass = args[1] or ""
        local leftHandPos, leftHandAng = vrmod.GetLeftHandPose(ply)
        local hitPos = DoTrace(leftHandPos, leftHandAng)
        net.Start("vrmod_pickup_beam")
        net.WriteBool(true)
        net.WriteFloat(grabRange)
        net.WriteFloat(maxWeight)
        net.WriteString(entClass)
        net.WriteVector(hitPos)
        net.WriteVector(leftHandPos)
        net.SendToServer()
    end
)

concommand.Add(
    "vrmod_pickup_beam_right",
    function(ply, cmd, args)
        if ply:InVehicle() then return end
        if not GetConVar("vrmod_pickup_beam_enable"):GetBool() then return end
        local grabRange = GetConVar("vrmod_pickup_beamrange02"):GetFloat()
        local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
        local entClass = args[1] or ""
        local rightHandPos, rightHandAng = vrmod.GetRightHandPose(ply)
        local hitPos = DoTrace(rightHandPos, rightHandAng)
        net.Start("vrmod_pickup_beam")
        net.WriteBool(false)
        net.WriteFloat(grabRange)
        net.WriteFloat(maxWeight)
        net.WriteString(entClass)
        net.WriteVector(hitPos)
        net.WriteVector(rightHandPos)
        net.SendToServer()
    end
)

hook.Add(
    "PostDrawTranslucentRenderables",
    "vrmod_pickup_beam_laser",
    function()
        if GetConVar("vrmod_pickup_beam_enable"):GetBool() then
            local leftHandPos, leftHandAng = vrmod.GetLeftHandPose(LocalPlayer())
            local rightHandPos, rightHandAng = vrmod.GetRightHandPose(LocalPlayer())
            DoTrace(leftHandPos, leftHandAng)
            DoTrace(rightHandPos, rightHandAng)
        end
    end
)