AddCSLuaFile()

local modelname = CreateClientConVar("vrmod_magent_model", "models/props_c17/tv_monitor01_screen.mdl", true, FCVAR_ARCHIVE)

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "VRMod Magent"
ENT.Category = "VRMod"
ENT.Spawnable = true
ENT.AdminSpawnable = true

-- エンティティの属性
ENT.MagName = "default_mag"
ENT.PrintName = "Default Mag"
ENT.Capacity = 30
ENT.MagType = "rifle"
ENT.AmmoType = "5.56mm"
ENT.Model = modelname:GetString()
ENT.Pose = {Pos = Vector(0, 0, 0), Ang = Angle(0, 0, 0)}

-- スポーン制限用のテーブル
if SERVER then
    ENT.SpawnLimits = ENT.SpawnLimits or {}
end

function ENT:SetupDataTables()
    self:NetworkVar("Angle", 0, "SpawnAngle")
end

function ENT:Initialize()
    local modelname = CreateClientConVar("vrmod_magent_model", "models/props_c17/tv_monitor01_screen.mdl", true, FCVAR_ARCHIVE)
    self:SetModel(modelname:GetString())
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass(1)
    end

    self:SetPos(self:GetPos() + Vector(0, 0, 0))
    self:SetAngles(Angle(self:GetSpawnAngle().x, self:GetSpawnAngle().y, self:GetSpawnAngle().z))

    if SERVER then
        -- 15秒後に消滅
        timer.Simple(6, function()
            if IsValid(self) then
                self:Remove()
            end
        end)

    end
end


if SERVER then
    function ENT:SpawnFunction(ply, tr, ClassName)
        if not tr.Hit then return end

        
        local SpawnPos =  vrmod.GetLeftHandPos(ply)
        local SpawnAng = vrmod.GetLeftHandAng(ply)
        -- SpawnAng.p = 0
        -- SpawnAng.y = SpawnAng.y - 90

        local ent = ents.Create(ClassName)
        ent:SetPos(SpawnPos)
        ent:SetSpawnAngle(SpawnAng)
        ent:Spawn()
        ent:Activate()

        return ent
    end
end