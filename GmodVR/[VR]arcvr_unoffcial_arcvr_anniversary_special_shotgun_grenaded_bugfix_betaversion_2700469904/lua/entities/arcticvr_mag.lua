AddCSLuaFile()

ENT.Type = "anim"
ENT.Spawnable = false
ENT.Base = "base_entity"
ENT.Category = "Arctic VR - Magazines"
ENT.DoNotDuplicate = false

ENT.ArcticVR = true
ENT.ArcticVRMagazine = true

ENT.Pose = {
    pos = Vector(),
    ang = Angle()
}
ENT.Model = "models/weapons/arcticvr/aniv/mag_m9.mdl"
ENT.MagType = ""
ENT.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1}
}
ENT.MaxRounds = 0
ENT.Rounds = 0
ENT.Hide = false
ENT.NeverDespawn = false

ENT.SoundEmpty = "weapon.ImpactHard"
ENT.SoundFull = "weapon.ImpactSoft"

if SERVER then

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    self:GetPhysicsObject():Wake()

    if !self.NeverDespawn then
        if self.Rounds < 1 then
            timer.Simple(5, function()
                SafeRemoveEntity(self)
            end)
        else
            timer.Simple(60, function()
                SafeRemoveEntity(self)
            end)
        end
    end

    timer.Simple(0.1, function()
		-- if(!self || !self.MagID) then
			-- return
		-- end
        net.Start("avr_updatemag")
        net.WriteString(self.MagID)
        net.WriteUInt(self.Rounds, 16)
        net.WriteEntity(self)
        net.Broadcast()
    end)
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if ( !tr.Hit ) then return end

    local SpawnPos = tr.HitPos + tr.HitNormal * 10
    local SpawnAng = ply:EyeAngles()
    SpawnAng.p = 0

    local ent = ents.Create( ClassName )
    ent.NeverDespawn = true
    ent:SetCreator( ply )
    ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )
    ent:Spawn()
    ent:Activate()

    ent:DropToFloor()

    return ent
end

function ENT:PhysicsCollide(colData, collider)
    if colData.DeltaTime < 0.1 then return end

    if self.Rounds == 0 then
        self:EmitSound(self.SoundEmpty)
    else
        self:EmitSound(self.SoundFull)
    end
end

else

function ENT:UpdateMag(rounds)
    self.Rounds = rounds

    for i, bgs in pairs(self.BodygroupsShowBullets or {}) do
        if i == "BaseClass" then continue end
        if self.Rounds >= i then
            self:SetBodygroup(bgs.ind, bgs.bg)
        else
            self:SetBodygroup(bgs.ind, 0)
        end
    end
end

function ENT:Draw()
    if self.Hide then return end
    self:DrawModel()
end

end