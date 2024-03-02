



local modelname = CreateClientConVar("vrmod_magent_modelname","models/Items/AR2_Grenade.mdl",true,FCVAR_ARCHIVE)

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "VR_MagEntity"
ENT.Author = ""
ENT.Information = ""
ENT.Spawnable = true
ENT.AdminSpawnable = false

ENT.Model = modelname:GetString()
ENT.FuseTime = 5
ENT.ArmTime = 0
ENT.ImpactFuse = false

AddCSLuaFile()



function ENT:Initialize()
    if SERVER then
        self:SetModel( self.Model )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:DrawShadow( true )

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:SetBuoyancyRatio(0)
        end

        self.kt = CurTime() + self.FuseTime
        self.at = CurTime() + self.ArmTime

        self:SetBodygroup(1, 1)
        self:SetBodygroup(2, 1)
    end
end

function ENT:PhysicsCollide(data, physobj)
    if SERVER then
            -- self:EmitSound("weapons/elite/elite-1.wav", 50, 10, 1, CHAN_AUTO)

        if self.at <= CurTime() and self.ImpactFuse then
            self:Detonate()
        end
    end
end

function ENT:Think()
    if SERVER and CurTime() >= self.kt then
        self:Detonate()
		end
end

function ENT:Detonate()
    if SERVER then
        if not self:IsValid() then return end

        -- -- Define the radius within which to affect LVS entities
        -- local radius = 500 -- Change this value as needed

        -- -- Find entities within the specified radius
        -- local entities = ents.FindInSphere(self:GetPos(), radius)

        -- -- Iterate through the found entities
        -- for _, ent in pairs(entities) do
        --     if ent:GetClass():lower():find("lvs_") then -- Assuming LVS entities have 'lvs_' in their class names
        --         -- Modify properties here, example:
        --         ent:SetAI(true)
        --         -- Set health if the vehicle has a SetHP function

        --         -- Set AI team if the vehicle has a SetAITEAM function
        --         if isfunction(ent.SetAITEAM) then
        --             ent:SetAITEAM(1)
        --         end

        --         -- Add more modifications as needed
        --     end
        -- end

        self:Remove() -- Remove the ball entity after modifying LVS entities
    end
end


function ENT:Draw()
    if CLIENT then
        self:DrawModel()
    end
end