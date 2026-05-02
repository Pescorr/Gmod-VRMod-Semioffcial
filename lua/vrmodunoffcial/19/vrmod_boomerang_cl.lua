if SERVER then return end

util.AddNetworkString("vrmod_boomerang_pickup")

-- Server tells us to pickup a returning boomerang with left hand
net.Receive("vrmod_boomerang_pickup", function(len)
    local ply = net.ReadEntity()
    local ent = net.ReadEntity()

    if not IsValid(ent) then return end
    if not IsValid(ply) then return end

    -- Get current left hand transform from VR frame data
    local handPos = g_VR and g_VR.latestFrame and g_VR.latestFrame.lefthandPos
    local handAng = g_VR and g_VR.latestFrame and g_VR.latestFrame.lefthandAng

    if not handPos or not handAng then return end

    -- Check if left hand is free
    local steamid = ply:SteamID64()
    local heldItems = g_VR[steamid] and g_VR[steamid].heldItems
    if heldItems and heldItems[1] and IsValid(heldItems[1].ent) then
        return -- Left hand busy, skip pickup
    end

    -- Send standard VRMod pickup request (left hand)
    net.Start("vrmod_pickup")
        net.WriteBool(true)  -- left hand
        net.WriteBool(false) -- not drop
        net.WriteVector(handPos)
        net.WriteAngle(handAng)
    net.SendToServer()
end)

print("[Boomerang CL] Pickup handler loaded")
