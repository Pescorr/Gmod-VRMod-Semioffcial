AddCSLuaFile()

ENT.Type = "anim"
ENT.Spawnable = false
ENT.Base = "base_entity"
ENT.Category = "Arctic VR - Attachments"
ENT.DoNotDuplicate = false

ENT.ArcticVR = true
ENT.ArcticVRAttachment = true

ENT.Pose = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0)
}
ENT.Model = "models/weapons/arcticvr/aniv/mag_m9.mdl"
ENT.AttID = ""

ENT.SoundHard = "weapon.ImpactHard"

if SERVER then

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    self:GetPhysicsObject():Wake()
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if ( !tr.Hit ) then return end

    local SpawnPos = tr.HitPos + tr.HitNormal * 10
    local SpawnAng = ply:EyeAngles()
    SpawnAng.p = 0

    local ent = ents.Create( ClassName )
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

    self:EmitSound(self.SoundHard)
end

else

function ENT:Draw()
    self:DrawModel()
end

end