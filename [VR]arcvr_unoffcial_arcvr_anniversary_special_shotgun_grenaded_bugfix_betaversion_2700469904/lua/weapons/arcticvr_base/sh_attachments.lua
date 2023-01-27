if CLIENT then

function SWEP:AttRender()
    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl.Holosight then
            self:DrawHolosight(atttbl, k.CSModel, k.HSPiece, true)
        end

        if atttbl.LaserSight then
            self:DrawLaserSight(k.CSModel, atttbl)
        end

        if atttbl.AttThink then
            atttbl:AttThink(self, g_VR.viewModel, k.CSModel, k)
        end
    end
end

function SWEP:AttachmentBehaviour(pickup)
    local vm = g_VR.viewModel
    local leftent = g_VR.heldEntityLeft

    if CLIENT and self.NextAttachmentTime > CurTime() then return end

    if !leftent and !pickup then return end
    if leftent and !pickup then
        if !leftent.ArcticVRAttachment then
            return
        end
    end

    -- are we in any of our attachment hitboxes?

    for i, k in pairs(self.Attachments) do
        local vmatt = vm:LookupAttachment(k.Bone or "")

        local lhpos = g_VR.tracking.pose_lefthand.pos
        local pos = g_VR.tracking.pose_righthand.pos
        local mins = Vector(-6, -6, -6)
        local maxs = Vector(6, 6, 6)

        if vmatt > 0 then
            pos = vm:GetAttachment(vmatt).Pos
            mins = Vector(-2, -2, -2)
            maxs = Vector(2, 2, 2)
        elseif pickup then
            -- "core" upgrades cannot be removed
            continue
        end
        -- there is no attachment bone?
        -- just refer to right hand

        if pickup then
            -- we are trying to remove this attachment
            if !self:PositionInMaxs(lhpos, pos, mins, maxs) then continue end

            net.Start("avr_detach")
            net.WriteUInt(i, 8)
            net.SendToServer()

            self:Detach(i)
        else
            -- we are trying to install an attachment
            if !leftent then return end
            if !leftent.ArcticVRAttachment then return end

            local attname = leftent.AttID
            local atttbl = ArcticVR.AttachmentTable[attname]

            if atttbl.Bone then
                if k.Bone != atttbl.Bone then continue end
            end

            if k.Slot != atttbl.Slot then continue end

            if !self:CheckFlags(i, attname) then continue end

            if leftent.AlreadyAttached then continue end

            if k.Installed then
                net.Start("avr_detach")
                net.WriteUInt(i, 8)
                net.SendToServer()

                self:Detach(i)

                return
            end

            -- ok, let's do it
            net.Start("avr_attach")
            net.WriteEntity(leftent)
            net.SendToServer()

            self:Attach(attname)

            leftent.AlreadyAttached = true

            g_VR.heldEntityLeft.RenderOverride = function(a)
                return
            end

            g_VR.heldEntityLeft = nil
        end
    end
end

function SWEP:RebuildAttModels()
    self:CleanAttModels()

    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if !atttbl.Model then continue end
        if atttbl.HideModel then continue end

        local parent = vm

        if k.ParentToSlot then
            if self.Attachments[k.ParentToSlot].Installed and IsValid(self.Attachments[k.ParentToSlot].CSModel) then
                parent = self.Attachments[k.ParentToSlot].CSModel
            end
        end

        local attmdl = ClientsideModel(atttbl.Model)
        attmdl:SetParent(parent)
        attmdl:AddEffects(EF_BONEMERGE)

        k.CSModel = attmdl
        table.insert(ArcticVR.AttachmentModels, attmdl)

        if atttbl.HolosightPiece then
            local spmdl = ClientsideModel(atttbl.HolosightPiece)
            spmdl:SetParent(parent)
            spmdl:SetNoDraw(true)
            spmdl:AddEffects(EF_BONEMERGE)

            k.HSPiece = spmdl
            table.insert(ArcticVR.AttachmentModels, spmdl)
        end

        if atttbl.RTScope then
            k.RTScopeMat = GetRenderTarget("avr_rtmat", atttbl.RTScopeRes, atttbl.RTScopeRes, false)
            k.RTScopeSurface = Material("effects/avr_rt")
        end
    end
end

function SWEP:CleanAttModels()
    for i, k in pairs(ArcticVR.AttachmentModels) do
        SafeRemoveEntity(k)
    end

    ArcticVR.AttachmentModels = {}
end

end

function SWEP:CheckFlags(slotid, attname)
    local activeflags = {}

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        if k.GivesFlags then
            table.Add(activeflags, k.GivesFlags)
        end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl.GivesFlags then
            table.Add(activeflags, atttbl.GivesFlags)
        end
    end

    local slottbl = self.Attachments[slotid]

    if slottbl.BlacklistFlags then
        for i, k in pairs(slottbl.BlacklistFlags or {}) do
            if table.HasValue(activeflags, k) then return false end
        end
    end

    if slottbl.WhitelistFlags then
        for i, k in pairs(slottbl.WhitelistFlags or {}) do
            if !table.HasValue(activeflags, k) then return false end
        end
    end

    return true
end

function SWEP:GetAttOverride(stat)
    local maxprecedence = 0
    local seli = nil
    local selected = nil

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl[stat] then
            local precedence = 1

            if atttbl[stat .. "_Precedence"] then
                precedence = attbl[stat .. "_Precedence"]
            end

            if precedence < maxprecedence then continue end

            seli = i
            selected = atttbl[stat]
        end
    end

    return selected, seli
end

function SWEP:GetBuff(stat)
    local buff = 1

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl[stat] then
            buff = buff * atttbl[stat]
        end
    end

    if self.Magazine then
        local magtbl = ArcticVR.MagazineTable[self.Magazine]

        if magtbl[stat] then
            buff = buff * magtbl[stat]
        end
    end

    return buff
end

function SWEP:GetBuffAdditive(stat)
    local buff = 0

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl[stat] then
            buff = buff + atttbl[stat]
        end
    end

    if self.Magazine then
        local magtbl = ArcticVR.MagazineTable[self.Magazine]

        if magtbl[stat] then
            buff = buff + magtbl[stat]
        end
    end

    return buff
end

function SWEP:CalcLaserStuff()
    self.TotalLaserStrength = 0
    self.AverageLaserColor = Color(0, 0, 0)

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]

        if atttbl.LaserSight then
            self.TotalLaserStrength = self.TotalLaserStrength + atttbl.LaserStrength
            self.AverageLaserColor.r = self.AverageLaserColor.r + atttbl.LaserSightColor.r
            self.AverageLaserColor.g = self.AverageLaserColor.g + atttbl.LaserSightColor.g
            self.AverageLaserColor.b = self.AverageLaserColor.b + atttbl.LaserSightColor.b
        end
    end

    local toplasercolor = self.AverageLaserColor.r

    if self.AverageLaserColor.g > toplasercolor then
        toplasercolor = self.AverageLaserColor.g
    end

    if self.AverageLaserColor.b > toplasercolor then
        toplasercolor = self.AverageLaserColor.b
    end

    if toplasercolor < 255 then return end

    local laserdiv = 255 / toplasercolor

    self.AverageLaserColor.r = self.AverageLaserColor.r * laserdiv
    self.AverageLaserColor.g = self.AverageLaserColor.g * laserdiv
    self.AverageLaserColor.b = self.AverageLaserColor.b * laserdiv
end

function SWEP:Attach(attname)
    if CLIENT and self.NextAttachmentTime > CurTime() then return end

    local atttbl = ArcticVR.AttachmentTable[attname]

    for i, k in pairs(self.Attachments) do
        if atttbl.Bone then
            if k.Bone != atttbl.Bone then continue end
        end

        if k.Slot != atttbl.Slot then continue end

        if !self:CheckFlags(i, attname) then continue end

        if k.Installed then continue end

        if atttbl.AttachFunc then
            atttbl.AttachFunc(self)
        end

        k.Installed = attname

        if CLIENT then
            self:RebuildAttModels()

            surface.PlaySound("weapons/smg1/switch_burst.wav")

            self.NextAttachmentTime = CurTime() + 0.1
        end

        self:CalcLaserStuff()

        break
    end
end

function SWEP:Detach(slotid)
    if CLIENT and self.NextAttachmentTime > CurTime() then return end

    local k = self.Attachments[slotid]
    if !k.Installed then return end

    local atttbl = ArcticVR.AttachmentTable[k.Installed]

    if atttbl.DetachFunc then
        atttbl.DetachFunc(self)
    end

    local kin = k.Installed

    k.Installed = nil

    if CLIENT then
        self:RebuildAttModels()

        surface.PlaySound("weapons/smg1/switch_single.wav")
    end

    return kin
end