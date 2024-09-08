ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "VR Pickup Helper"
ENT.Author = "Your Name"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "PickupOwner")
    self:NetworkVar("Entity", 1, "PickupObject")
end