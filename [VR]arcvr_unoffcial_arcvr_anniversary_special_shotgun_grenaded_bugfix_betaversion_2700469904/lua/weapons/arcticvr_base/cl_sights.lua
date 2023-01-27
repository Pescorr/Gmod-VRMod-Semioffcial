function SWEP:InitRT()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if self.RTScope then
        self.RTScopeMat = GetRenderTarget("avr_rtmat", self.RTScopeRes, self.RTScopeRes, false)
    end
end

function SWEP:RTScopeExtra(size)
end

function SWEP:RTScopeFunc(left)
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if self.RTScope then
        if !self.RTScopeMat then
            self:InitRT()
        end

        self:DrawRTScope(self, vm, self.RTScopeMat, self.RTScopeSurface, left)
    end
end

local shadow = Material("scopes/shadow.png")

function SWEP:DrawRTScope(rts, rtsm, rtmat, rtsurf, left)
    local attid = rtsm:LookupAttachment("scope")

    if !attid then return end
	-- if !ret then return end

    local ret = rtsm:GetAttachment(attid)
    local pos = ret.Pos
    local ang = rtsm:LocalToWorldAngles( Angle(0, 0, 0) )

    pos = pos + ang:Right() * rts.RTScopeOffset[1]
    pos = pos + ang:Forward() * rts.RTScopeOffset[2]
    pos = pos + ang:Up() * rts.RTScopeOffset[1]

    local eyeang = g_VR.tracking.hmd.ang
    local lefteye = g_VR.eyePosLeft
    local righteye = g_VR.eyePosRight

    local lett = pos - lefteye
    local rett = pos - righteye

    local ldom = false

    if lett:Length() > rett:Length() then
        ldom = true
    end

    local eyepos = g_VR.eyePosRight
    local othereye = g_VR.eyePosLeft

    if left then
        eyepos = g_VR.eyePosLeft
        othereye = g_VR.eyePosRight
    end

    local eyedist = ((pos - eyepos):Length() + 1)

    local eyediff = ((pos - othereye):Length() + 1)

    local eyebruh = math.Clamp(eyediff - eyedist, 0, 2)

    if eyebruh > 1 then
        eyebruh = 2 - eyebruh
    end

    eyebruh = math.Clamp(eyebruh * 16, 0, 1)

    eyebruh = eyebruh - (eyedist / 96)

    local size = rts.RTScopeRes
    local ogscrw = ScrW()
    local ogscrh = ScrH()
    local fov = rts.RTScopeFOV
    local rt = {
        x = 0,
        y = 0,
        w = size,
        h = size,
        angles = ang,
        origin = pos,
        drawviewmodel = false,
        fov = fov / eyedist * 32,
    }
    local ogrt = render.GetRenderTarget()

    render.PushRenderTarget(rtmat, 0, 0, size, size)

    local black = false

    if ldom == left then
        black = true
        render.Clear(0, 0, 0, 255, true, true)
    else
        render.Clear(0, 0, 0, 255, true, true)
        render.RenderView(rt)
    end

    if !black then
        cam.Start3D(pos, ang, rt.fov, 0, 0, size, size)
            local scopesize = math.Round(size * eyebruh)

            local scopeposx = math.Round((size - scopesize) / 2)
            local scopeposy = math.Round((size - scopesize) / 2)
        cam.End3D()

        cam.Start2D()
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(rts.RTScopeReticle)
            surface.DrawTexturedRect(0, 0, size, size)

            self:RTScopeExtra(size)

            surface.SetDrawColor( 0, 0, 0 )

            if scopeposx > ScrW() or scopeposx < 0 - scopesize or scopeposy > ScrH() or scopeposy < 0 - scopesize then

                surface.SetDrawColor( 0, 0, 0 )

                surface.DrawRect( 0, 0, ScrW(), ScrH() )

            else
                surface.DrawRect( scopeposx - ScrW(), scopeposy - ScrH(), 4 * ScrW(), ScrH() )
                surface.DrawRect( scopeposx - ScrW(), scopeposy + scopesize , 4 * ScrW(), ScrH() )

                surface.DrawRect( scopeposx - ScrW(), scopeposy - ScrH(), ScrW(), 4 * ScrH() )
                surface.DrawRect( scopeposx + scopesize, scopeposy - ScrH() , ScrW(), 4 * ScrH() )
            end

            surface.SetMaterial( shadow )
            surface.DrawTexturedRect( scopeposx, scopeposy, scopesize, scopesize )

        cam.End2D()
    end

    render.PopRenderTarget()

    rtsurf:SetTexture("$basetexture", rtmat)

    rtsm:SetSubMaterial()

    rtsm:SetSubMaterial(rts.RTScopeSubmatIndex, "effects/avr_rt")

    render.SetRenderTarget(ogrt)
    render.SetViewPort(0,0,ogscrw,ogscrh)
end

function SWEP:HolosightFunc()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end
    if !self.Holosight then return end

    if !ArcticVR.SightPiece or !IsValid(ArcticVR.SightPiece) then
        ArcticVR.SightPiece = ClientsideModel(self.HolosightPiece)
        ArcticVR.SightPiece:SetParent(vm)
        ArcticVR.SightPiece:SetNoDraw(true)
        ArcticVR.SightPiece:AddEffects(EF_BONEMERGE)
    end

    self:DrawHolosight(self, vm, ArcticVR.SightPiece, true)
end

function SWEP:DrawHolosight(hs, hsm, hsp, cullhsm)
    cullhsm = cullhsm or false
    local attid = hsm:LookupAttachment("holosight")

    if attid == 0 then
        attid = hsm:LookupAttachment("scope")
    end

    if attid == 0 then return end

    local ret = hsm:GetAttachment(attid)
    local pos = ret.Pos
    local ang = ret.Ang
    local size = hs.HolosightSize

    render.UpdateScreenEffectTexture()
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_REPLACE)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(55)

    render.SetBlend(1)
    hsp:DrawModel()
    render.SetStencilReferenceValue(0)

    for i, k in pairs(self.Attachments) do
        if k.CSModel then
            k.CSModel:DrawModel()
        end
    end

    if cullhsm then

        ArcticVR.Overdraw = true
        hsm:DrawModel()

    end

    render.SetStencilReferenceValue(55)

    ArcticVR.Overdraw = false

    render.SetBlend(0)

    render.SetStencilCompareFunction(STENCIL_EQUAL)

    local dir = ang:Up()
    pos = pos + (dir * hs.HolosightDist)

    local corner1, corner2, corner3, corner4

    corner1 = pos + (ang:Right() * (-0.5 * size)) + (ang:Forward() * (0.5 * size))
    corner2 = pos + (ang:Right() * (-0.5 * size)) + (ang:Forward() * (-0.5 * size))
    corner3 = pos + (ang:Right() * (0.5 * size)) + (ang:Forward() * (-0.5 * size))
    corner4 = pos + (ang:Right() * (0.5 * size)) + (ang:Forward() * (0.5 * size))

    render.SetMaterial(hs.HolosightReticle)
    render.DrawQuad( corner1, corner2, corner3, corner4, Color(255, 255, 255) )

    render.SetStencilEnable( false )
end

local lasermat = Material("effects/laser1")
local laserflare = Material("effects/whiteflare")

function SWEP:LaserSightFunc()
    if !self.LaserSight then return end

    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    self:DrawLaserSight(vm, self)
end

function SWEP:DrawLaserSight(lsm, ls)
    local attid = lsm:LookupAttachment("laser")

    if attid == 0 then
        attid = lsm:LookupAttachment("muzzle")
    end

    if attid == 0 then return end

    local ret = lsm:GetAttachment(attid)
    local pos = ret.Pos
    local ang = ret.Ang

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + (ang:Up() * 40000),
        filter = self.Owner
    })
    local hit = tr.HitPos
    local didhit = tr.Hit
    local m = ls.LaserStrength or 1
    local col = ls.LaserSightColor

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