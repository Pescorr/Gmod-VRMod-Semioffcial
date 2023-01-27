net.Receive("avr_attach", function(len, ply)
    local attent = net.ReadEntity()
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcticVR then return end
    if !attent.ArcticVRAttachment then return end
    if attent.AlreadyAttached then return end

    wpn:Attach(attent.AttID)
    attent.AlreadyAttached = true
    attent:Remove()
end)

net.Receive("avr_detach", function(len, ply)
    local attindex = net.ReadUInt(8)
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcticVR then return end

    local ret = wpn:Detach(attindex)

    if ret then
        local atttbl = ArcticVR.AttachmentTable[ret]

        local att = ents.Create("avratt_" .. atttbl.Name)

        if !att or !IsValid(att) then print("!! Failed to create att") return end

        att.Model = atttbl.WorldModel or atttbl.Model
        att.ArcticVRAttachment = true
        att.AttID = atttbl.Name

        for i, k in pairs(atttbl) do
            att[i] = k
        end

        att:SetPos(ply:EyePos())
        att:SetAngles(ply:EyeAngles())
        att:Spawn()
        att:Activate()
    end
end)