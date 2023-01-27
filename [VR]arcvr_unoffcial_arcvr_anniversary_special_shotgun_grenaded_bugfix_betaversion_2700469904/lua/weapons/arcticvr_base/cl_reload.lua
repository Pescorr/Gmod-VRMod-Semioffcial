local cv_bumpreload = CreateClientConVar("arcticvr_mag_bumpreload","1",FCVAR_ARCHIVE)
local cv_bumpreload_allgun = CreateConVar("arcticvr_bumpreload_allgun","0",FCVAR_ARCHIVE) or false
local cv_bumpreload_allgun_client = CreateClientConVar("arcticvr_bumpreload_allgun_client","0",FCVAR_ARCHIVE)


function SWEP:EjectMagazine(grab)
    if !self.Magazine then return end
    if self.InternalMagazine then return end
    if self.BeltAmountIn >= self.BeltBullets then return end

    local vm = g_VR.viewModel
    grab = grab or false

    local locpos, locang = LocalToWorld(self.MagazineOffset, self.MagazineAngleOffset, vm:GetPos(), vm:GetAngles())

    net.Start("avr_magout_r")
    net.WriteBool(grab)
    net.WriteVector(locpos)
    net.WriteAngle(locang)
    if grab then
        local pos, ang = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang

        net.WriteVector(pos)
        net.WriteAngle(ang)
        net.WriteBool(true)
    end
    net.SendToServer()

    if game.SinglePlayer() then
        self:PlayNetworkedSound(nil, "MagOutSound")
    end

    SafeRemoveEntity(ArcticVR.CSMagazine)
    self.Magazine = nil
    self.LoadedRounds = 0
end

function SWEP:VolleyFireEject(ej_full)
    ej_full = ej_full or false
    if !self.BreakActionChamberOpen then return end

    local vm = g_VR.viewModel

    local ejected = false

    for i = 1, self.InternalMagazineCapacity do
        if self.VolleyFireChambers[i] == 0 then
            continue
        end

        local att = vm:LookupAttachment((self.ChamberAtt or "chamber") .. tostring(i))
        local posang = vm:GetAttachment(att)

        local fx = EffectData()
        fx:SetAttachment(att)
        fx:SetMagnitude(150)
        fx:SetNormal(-posang.Ang:Up())
        fx:SetEntity(vm)

        if self.VolleyFireChambers[i] == 1 then
            if self.CaseEffect then
                util.Effect(self.CaseEffect, fx)
            end
            self.VolleyFireChambers[i] = 0
            ejected = true
        elseif ej_full then
            if self.BulletEffect then
                util.Effect(self.BulletEffect, fx)
            end
            self.VolleyFireChambers[i] = 0
            ejected = true
        end
    end

    if ejected then
        self:PlayNetworkedSound(nil, "MagOutSound")
    end
end

function SWEP:InsertMagazineBehaviourVolleyFire()
    if !self.BreakActionChamberOpen then return end

    local leftent = g_VR.heldEntityLeft

    lastinmaxsany = false

    for i = 1, self.InternalMagazineCapacity do
        local inmaxs = self:LeftHandInMaxs(self.BoneIndices["chamber" .. tostring(i)], self.MagazineInsertMins, self.MagazineInsertMaxs)
        -- if inmaxs then
        --     lastinmaxsany = true
        -- end
        -- if lastinmaxsany then continue end
        if self.VolleyFireChambers[i] != 0 then continue end

        if inmaxs then
            net.Start("avr_magin")
            net.WriteEntity(leftent)
            net.WriteBool(false)
            net.SendToServer()

            self:PlayNetworkedSound(nil, "MagInSound")

            g_VR.heldEntityLeft.RenderOverride = function(a)
                return
            end

            g_VR.heldEntityLeft = nil

            self.VolleyFireChambers[i] = 2
            break
        end
    end
end

local prevlhinmagmaxs = false

function SWEP:InsertMagazineBehaviour()
    local vm = g_VR.viewModel
    local leftent = g_VR.heldEntityLeft
    -- is a magazine in the right position?
    if !leftent then return end
    if !leftent.ArcticVR then return end
    if !leftent.MagType then return end

    local magtbl = ArcticVR.MagazineTable[leftent.MagID]

    if magtbl.IsBeltBox then
        if leftent.MagType != self.BeltBoxType then return end
    else
        if leftent.MagType != self.MagType then return end
    end

    if self.VolleyFire then
        self:InsertMagazineBehaviourVolleyFire()
        return
    end

    if self.MustBeOpenToLoad and self.SlidePos < self.SlideBlowbackAmount then return end
    if self.InternalMagazine and self.LoadedRounds >= self.InternalMagazineCapacity then return end

    if self.InternalMagazine and self.CanDirectChamber and self.Chambered <= 0 and self.SlidePos >= self.SlideLockbackAmount then
        local dcinmaxs = self:LeftHandInMaxs(self.BoneIndices.chamber, self.MagazineInsertMins, self.MagazineInsertMaxs)

        if dcinmaxs then
            net.Start("avr_magin")
            net.WriteEntity(leftent)
            net.WriteBool(true)
            net.SendToServer()

            if self.DirectChamberSound then
                self:PlayNetworkedSound(nil, "DirectChamberSound")
            else
                self:PlayNetworkedSound(nil, "MagInSound")
            end

            self.Chambered = self.Chambered + 1

            g_VR.heldEntityLeft.RenderOverride = function(a)
                return
            end

            g_VR.heldEntityLeft = nil

            return
        end
    end

    local magbone = self.BoneIndices.mag or self.BoneIndices.magazine

    if magtbl and magtbl.IsBeltBox then
        magbone = self.BoneIndices.box
    end

    if !self:LeftHandInMaxs(magbone, self.MagazineInsertMins * 1.75, self.MagazineInsertMaxs * 1.75) then return end

    if self.Magazine and cv_bumpreload:GetBool() then
		if self.MagCanDropFree or cv_bumpreload_allgun:GetBool() and cv_bumpreload_allgun_client:GetBool() then
			self:EjectMagazine()
			return
		end
    end

    local inmaxs = self:LeftHandInMaxs(magbone, self.MagazineInsertMins, self.MagazineInsertMaxs)

    if prevlhinmagmaxs then prevlhinmagmaxs = inmaxs return end

    prevlhinmagmaxs = inmaxs

    if !inmaxs then return end
    if self.Magazine then return end

    -- send a message to insert the new magazine.

    net.Start("avr_magin")
    net.WriteEntity(leftent)
    net.WriteBool(false)
    net.SendToServer()

    self:PlayNetworkedSound(nil, "MagInSound")

    if self.InternalMagazine then
        self.LoadedRounds = self.LoadedRounds + leftent.Rounds
    else

        self.LoadedRounds = leftent.Rounds
        self.Magazine = leftent.Name
        -- on our side, hide the magazine, and create a visual magazine to swoop into position.

        SafeRemoveEntity(ArcticVR.CSMagazine)

        ArcticVR.CSMagazine = ClientsideModel(leftent:GetModel())
        ArcticVR.CSMagazine:SetParent(vm)
        ArcticVR.CSMagazine:SetNoDraw(true)
        ArcticVR.CSMagazine:AddEffects(EF_BONEMERGE)

    end

    g_VR.heldEntityLeft.RenderOverride = function(a)
        return
    end

    g_VR.heldEntityLeft = nil
end

function SWEP:PostDrawViewModel()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if ArcticVR.CSMagazine and IsValid(ArcticVR.CSMagazine) then
    --     self.CSMagazineInsertionTime = math.Approach(self.CSMagazineInsertionTime, 1, FrameTime() * 0.25)

    --     local locpos, locang = LocalToWorld(self.MagazineOffset + g_VR.viewModelInfo.arcticvr_m9.offsetPos,
    --         self.MagazineAngleOffset + g_VR.viewModelInfo.arcticvr_m9.offsetAng,
    --         g_VR.tracking.pose_righthand.pos,
    --         g_VR.tracking.pose_righthand.ang)

    --     self.CSMagazine:SetPos(locpos)
    --     self.CSMagazine:SetAngles(locang)
    --     self.CSMagazine:SetRenderOrigin(locpos)
    --     self.CSMagazine:SetRenderAngles(locang)
        ArcticVR.CSMagazine:DrawModel()
    end

    if ArcticVR.Overdraw then return end

    self:HolosightFunc()
    self:LaserSightFunc()
    self:AttRender()
end

function SWEP:OpenChambers()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if !self.BreakActionChamberOpen then
        self:PlayNetworkedSound(nil, "OpenChamberSound")
        self.BreakActionChamberOpen = true
        if self.ForegripOnPivot then
            self.ForegripGrabbed = false
        end
    else
        self:CloseChambers()
    end
end

function SWEP:CloseChambers()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if !self.BreakActionChamberOpen then return end

    self:PlayNetworkedSound(nil, "CloseChamberSound")
    self.BreakActionChamberOpen = false
end