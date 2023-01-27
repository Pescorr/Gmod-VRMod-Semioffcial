
if SERVER then
CreateConVar("arcticvr_net_magtimertime", "0.08")
CreateConVar("arcticvr_defaultammo_normalize", "0", FCVAR_ARCHIVE, "")

hook.Add( "OnEntityCreated", "ArcticVR_NormalizeDefaultAmmo", function( ent )
    if !ent:IsWeapon() then return end
    if !(ent.ArcticVR or ent.ArcticVRNade) then return end
    if GetConVar("arcticvr_defaultammo_normalize"):GetInt() == 0 then return end

    local clips = GetConVar("arcticvr_defaultammo_normalize"):GetInt()

    ent.Primary.DefaultClip = ent.Primary.ClipSize * (clips + 1)

    if ent.Primary.ClipSize <= 0 then
        ent.Primary.DefaultClip = clips
    end
end )

local function EntityPose(ent, handpos, handang, right)
    local pos = handpos
    local ang = handang

    local rflip = 1

    if right then
        rflip = -1
    end

    if ent.Pose then

        pos = pos + handang:Forward() * ent.Pose.pos[1]
        pos = pos + handang:Right() * ent.Pose.pos[2] * rflip
        pos = pos + handang:Up() * ent.Pose.pos[3]

        _, ang = LocalToWorld(Vector(0, 0, 0), ent.Pose.ang, Vector(0, 0, 0), handang)

    end

    return pos, ang
end


CreateConVar("arcticvr_physical_bullets", "0", FCVAR_ARCHIVE, "")

local phys_bullets = GetConVar("arcticvr_physical_bullets")
function ArcticVR.IsPhysicalBullets()
	return phys_bullets:GetInt() != 0
end


util.AddNetworkString("avr_deploy")
util.AddNetworkString("avr_holster")
util.AddNetworkString("avr_shoot")
util.AddNetworkString("avr_meleeattack")
util.AddNetworkString("avr_secondaryattack")
util.AddNetworkString("avr_nadethrow")
util.AddNetworkString("avr_pose")
util.AddNetworkString("avr_magin")
util.AddNetworkString("avr_magout_r")
util.AddNetworkString("avr_rack")
util.AddNetworkString("avr_playsound")
util.AddNetworkString("avr_magin_forclient")
util.AddNetworkString("avr_updatemag")
util.AddNetworkString("avr_spawnmag_r")
util.AddNetworkString("avr_despawnmag")
util.AddNetworkString("avr_attach")
util.AddNetworkString("avr_detach")
util.AddNetworkString("avr_sendatts")

net.Receive("avr_playsound", function(len, ply)
    local sindex = net.ReadUInt(8)
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcticVR then return end

    wpn:PlayNetworkedSound(sindex)
end)

net.Receive("avr_despawnmag", function(len, ply)
    local mag = net.ReadEntity()

    if !mag then return end
    if !IsValid(mag) then return end
    if !mag.ArcticVR then return end

    local ammotype = mag.AmmoType
    local rounds = mag.Rounds

    ply:GiveAmmo(rounds, ammotype)
    mag:Remove()
end)

net.Receive("avr_rack", function(len, ply)
    local wpn = ply:GetActiveWeapon()

    if wpn.ArcticVR then
        wpn:Cycle()
    end
end)

net.Receive("avr_shoot", function(len, ply)
    local src = Vector(0, 0, 0)
    src[1] = net.ReadFloat()
    src[2] = net.ReadFloat()
    src[3] = net.ReadFloat()
    local ang = net.ReadAngle()

    local wpn = ply:GetActiveWeapon()

    if wpn.ArcticVR then
        wpn:VR_Shoot(src, ang)
    end
end)

net.Receive("avr_secondaryattack", function(len, ply)
    local src = Vector(0, 0, 0)
    src[1] = net.ReadFloat()
    src[2] = net.ReadFloat()
    src[3] = net.ReadFloat()
    local ang = net.ReadAngle()

    local wpn = ply:GetActiveWeapon()

    if wpn.ArcticVR then
        wpn:VR_SecondaryShoot(src, ang)
    end
end)

net.Receive("avr_meleeattack", function(len, ply)
    local src = Vector(0, 0, 0)
    src[1] = net.ReadFloat()
    src[2] = net.ReadFloat()
    src[3] = net.ReadFloat()
    local vel = net.ReadVector()

    local wpn = ply:GetActiveWeapon()

    if wpn.ArcticVR then
        wpn:VR_Melee(src, vel)
    end
end)

net.Receive("avr_nadethrow", function(len, ply)
    local src = Vector(0, 0, 0)
    src[1] = net.ReadFloat()
    src[2] = net.ReadFloat()
    src[3] = net.ReadFloat()
    local vel = net.ReadVector()
    local ang = net.ReadAngle()
    local angvel = net.ReadAngle()

    local wpn = ply:GetActiveWeapon()

    if wpn.ArcticVRNade then
        wpn:VR_Throw(src, ang, vel, angvel)
    end
end)

net.Receive("avr_magin", function(len, ply)
    local mag = net.ReadEntity()
    local dc = net.ReadBool()

    local wpn = ply:GetActiveWeapon()

    if !IsValid(mag) then return end
    if !mag.ArcticVR then return end
    if !mag.MagType then return end
    if !wpn.ArcticVR then return end

    local magtbl = ArcticVR.MagazineTable[mag.MagID]

    if magtbl.IsBeltBox then
        if mag.MagType != wpn.BeltBoxType then return end
    else
        if mag.MagType != wpn.MagType then return end
    end

    if !dc then
        if wpn.InternalMagazine then
            wpn.LoadedRounds = wpn.LoadedRounds + mag.Rounds

            if wpn.LoadedRounds > wpn.InternalMagazineCapacity then
                wpn.LoadedRounds = wpn.InternalMagazineCapacity
            end
        else
            wpn.Magazine = mag.Name
            wpn.LoadedRounds = mag.Rounds
        end
    end

    mag:Remove()

    net.Start("avr_magin_forclient")
    net.WriteUInt(wpn.LoadedRounds, 16)
    net.Send(ply)
end)

local function GrabAndPose(ent, pos, ang, lefthand, ply)
    if !IsValid(ent) then return end
    if !ent.ArcticVR then return end

    local ppos, pang = EntityPose(ent, pos, ang, !lefthand)

    ent:SetPos(ppos)
    ent:SetAngles(pang)

    local locpos, locang = WorldToLocal(ent:GetPos(), ent:GetAngles(), pos, ang)

    if hook.Call("VRMod_Pickup", nil, ply, ent) == false then
        return
    end

    local found = false
    for k2,v2 in pairs(g_VR[ply:SteamID()].heldItems) do
        if v2.ent == ent then table.remove(g_VR[ply:SteamID()].heldItems, k2) found = true end
    end
    if !found then
        ply:PickupObject(ent)
        timer.Simple(0, function() ply:DropObject() end)
    end
    ent.originalCollisionGroup = ent:GetCollisionGroup()
    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ent:MakePhysicsObjectAShadow(true,true)
    g_VR[ply:SteamID()].heldItems[#g_VR[ply:SteamID()].heldItems + 1] = {ent = ent, left = lefthand, localPos = locpos, localAng = locang, targetPos = Vector(0,0,0), targetReached = SysTime()}

    net.Start("vrutil_net_pickup")
    net.WriteEntity(ply)
    net.WriteEntity(ent)
    net.WriteBool(lefthand)
    net.WriteVector(locpos)
    net.WriteAngle(locang)
    net.Broadcast()
end

function ArcticVR.CreateMag(magid, rounds)
    local magtbl = ArcticVR.MagazineTable[magid]

    if !magtbl then return end
    local mag = ents.Create("avrmag_" .. magid)
    -- local mag = ents.Create("")


    if !mag or !IsValid(mag) then print("!! Failed to create magazine") return end

    for i, k in pairs(magtbl) do
        mag[i] = k
    end

    mag.MagID = magtbl.Name
    mag.Rounds = rounds
    mag:Spawn()
    mag:Activate()

    -- net.Start("avr_updatemag")
    --     net.WriteString(mag.Name)
    --     net.WriteUInt(mag.Rounds, 16)
    --     net.WriteEntity(mag)
    -- net.Broadcast()

    return mag
end

net.Receive("avr_magout_r", function(len, ply)
    local grab = net.ReadBool()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local wpn = ply:GetActiveWeapon()
    local hpos, hang, lefthand
	

	

    if grab then
        hpos = net.ReadVector()
        hang = net.ReadAngle()
        lefthand = net.ReadBool()
    end

    if !wpn.ArcticVR then return end

    if !wpn.Magazine then return end

    local loaded = wpn.LoadedRounds or 0

    local mag = ArcticVR.CreateMag(wpn.Magazine, loaded)

    mag:SetAngles(ang)
    mag:SetPos(pos)

    wpn.Magazine = nil
    wpn.LoadedRounds = 0

    if grab then
        local timertime = 0

        -- if !game.SinglePlayer() then
        timertime = GetConVar("arcticvr_net_magtimertime"):GetFloat()
        -- end

        timer.Simple(timertime, function()
            GrabAndPose(mag, hpos, hang, lefthand, ply)
        end)
    end
end)

net.Receive("avr_pose", function(len, ply)
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local lefthand = net.ReadBool()
    local ent = net.ReadEntity()

    GrabAndPose(ent, pos, ang, lefthand, ply)
end)

net.Receive("avr_spawnmag_r", function(len, ply)
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local timertime = 0
    local wpn = ply:GetActiveWeapon()
	


    if !wpn.ArcticVR then return end

    for k, v in pairs(g_VR[ply:SteamID()].heldItems) do
        if v.left then return end
    end

    local magid = wpn.DefaultMagazine

    if wpn:GetAttOverride("MagExtender") then
        if wpn.ExtendedMagazine then
            magid = wpn.ExtendedMagazine
        end
    end

    if wpn:GetAttOverride("MagReducer") then
        if wpn.ReducedMagazine then
            magid = wpn.ReducedMagazine
        end

        if wpn:GetAttOverride("MagExtender") then
            magid = wpn.DefaultMagazine
        end
    end

    local magtbl = ArcticVR.MagazineTable[magid]

    local cap = magtbl.Capacity
    local ammotype = wpn.Primary.Ammo
    local reserve = ply:GetAmmoCount(ammotype)
    local toload = math.Clamp(reserve, 0, cap)

    local mag = ArcticVR.CreateMag(magid, toload)

    if !mag then return end

    ply:SetAmmo(reserve - toload, ammotype)

    mag:SetAngles(ang)
    mag:SetPos(pos)

    -- local timertime = 0

    -- if !game.SinglePlayer() then
        timertime = GetConVar("arcticvr_net_magtimertime"):GetFloat()
    -- end

    timer.Simple(timertime, function()
        GrabAndPose(mag, pos, ang, true, ply)
    end)
end)

end