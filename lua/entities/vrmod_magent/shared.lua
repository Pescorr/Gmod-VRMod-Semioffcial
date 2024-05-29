


AddCSLuaFile()
local modelname = CreateClientConVar("vrmod_magent_model","models/Items/combine_rifle_ammo01.mdl",true,FCVAR_ARCHIVE)

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

function ENT:SetupDataTables()
    self:NetworkVar("Angle", 0, "SpawnAngle")
end

function ENT:Initialize()
    local modelname = CreateClientConVar("vrmod_magent_model","models/Items/combine_rifle_ammo01.mdl",true,FCVAR_ARCHIVE)

    self:SetModel(modelname:GetString())
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass(5) -- 質量の調整
    end

    -- pickup成功率を向上させるための位置と角度の調整
    self:SetPos(self:GetPos() + Vector(0, 0, 0)) -- スポーン位置を少し上に調整
    self:SetAngles(Angle(0, self:GetSpawnAngle().y, 0)) -- 事前に設定されたプレイヤーの向きに合わせて角度を調整
end