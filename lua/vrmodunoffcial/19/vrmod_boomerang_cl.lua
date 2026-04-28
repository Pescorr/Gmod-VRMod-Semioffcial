if SERVER then return end

print("[Boomerang] Client module initialized")

net.Receive("vrmod_boomerang_pickup", function(len)
    local ent = net.ReadEntity()
    
    if not IsValid(ent) then return end
    if not g_VR or not g_VR.latestFrame then return end
    
    local handPos = g_VR.latestFrame.lefthandPos
    local handAng = g_VR.latestFrame.lefthandAng
    
    if not handPos or not handAng then return end
    
    net.Start("vrmod_pickup")
        net.WriteBool(true)
        net.WriteBool(false)
        net.WriteVector(handPos)
        net.WriteAngle(handAng)
    net.SendToServer()
end)
