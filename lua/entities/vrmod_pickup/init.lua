AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/watermelon01.mdl")
    self:SetNoDraw(true)
    self:DrawShadow(false)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    self.ShadowParams = {
        secondstoarrive = 0.00005,
        maxangular = 5000,
        maxangulardamp = 5000,
        maxspeed = 2000000,
        maxspeeddamp = 20000,
        dampfactor = 0.3,
        teleportdistance = 2000,
        deltatime = 0,
    }
end

function ENT:PhysicsSimulate(phys, deltatime)
    phys:Wake()
    local pickupInfo = phys:GetEntity().vrmod_pickup_info
    local frame = g_VR[pickupInfo.steamid] and g_VR[pickupInfo.steamid].latestFrame
    if not frame then return end
    local handPos, handAng = LocalToWorld(pickupInfo.left and frame.lefthandPos or frame.righthandPos, pickupInfo.left and frame.lefthandAng or frame.righthandAng, pickupInfo.ply:GetPos(), Angle())
    self.ShadowParams.pos, self.ShadowParams.angle = LocalToWorld(pickupInfo.localPos, pickupInfo.localAng, handPos, handAng)
    phys:ComputeShadowControl(self.ShadowParams)
end

function ENT:StartMotionController()
    self:PhysicsInitShadow(true, true)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:StopMotionController()
    self:PhysicsInit(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
end

function ENT:AddToMotionController(phys)
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(true)
        self:AddToShadowController(phys)
    end
end

function ENT:RemoveFromMotionController(phys)
    if IsValid(phys) then
        self:RemoveFromShadowController(phys)
    end
end