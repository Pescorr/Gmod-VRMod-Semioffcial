net.Receive("avr_sendatts", function(len, ply)
    local ent = net.ReadEntity()
    local amt = net.ReadUInt(10)

    local atts = {}

    for i = 1, amt do
        atts[i] = net.ReadUInt(24)
    end

    if net.ReadBool() then
        local mag = net.ReadString()
        local loadedrounds = net.ReadUInt(16)
        local chambered = net.ReadUInt(8)

        if mag != "" then
            ent.Magazine = mag
        else
            ent.Magazine = nil
        end

        ent.LoadedRounds = loadedrounds
        ent.Chambered = chambered
    end

    if !IsValid(ent) then return end
    if !ent.ArcticVR then return end
    if !ent.Attachments then return end

    for i, k in pairs(ent.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl.DetachFunc then
            atttbl.DetachFunc(ent)
        end

        k.Installed = nil
    end

    for i, k in pairs(atts) do
        if k == 0 then continue end
        local attname = ArcticVR.AttachmentIDTable[k]

        if !attname then continue end

        local atttbl = ArcticVR.AttachmentTable[attname]

        if !ent.Attachments[i] then continue end

        if atttbl.AttachFunc then
            atttbl.AttachFunc(ent)
        end

        ent.Attachments[i].Installed = attname
    end

    if ent == LocalPlayer():GetActiveWeapon() then
        ent:RebuildAttModels()
    end
end)

local lasermat = Material("effects/laser1")
local laserflare = Material("effects/whiteflare")

hook.Add("PostDrawTranslucentRenderables", "avr_drawplayerlasers", function(depth, sky)
    if sky then return end

    for i, k in pairs(player.GetAll()) do
        if k == LocalPlayer() then return end
        local wpn = k:GetActiveWeapon()

        if !wpn then continue end
        if !IsValid(wpn) then continue end
        if !wpn.ArcticVR then continue end

        if wpn.TotalLaserStrength == 0 then continue end
        if !wpn.AverageLaserColor then continue end

        local pos = k:EyePos()
        local ang = k:EyeAngles()

        local tr = util.TraceLine({
            start = pos,
            endpos = pos + (ang:Up() * 40000),
            filter = k
        })
        local hit = tr.HitPos
        local didhit = tr.Hit
        local m = wpn.TotalLaserStrength or 1
        local col = wpn.AverageLaserColor

        if tr.StartSolid then return end

        local width = math.Rand(0.5, 2) * m

        cam.Start3D()

        render.SetMaterial(lasermat)
        render.DrawBeam(pos, hit, width, 0, 1, col)

        if didhit then
            local sd = (tr.HitPos - EyePos()):Length()
            local mult = math.log10(sd) * m

            render.SetMaterial(laserflare)
            local r1 = math.Rand(10, 14) * mult
            local r2 = math.Rand(10, 14) * mult
            render.DrawSprite(hit, r1, r2, col)
            render.DrawSprite(hit, r1 * 0.25, r2 * 0.25, Color(255, 255, 255))
        end

        cam.End3D()
    end
end)