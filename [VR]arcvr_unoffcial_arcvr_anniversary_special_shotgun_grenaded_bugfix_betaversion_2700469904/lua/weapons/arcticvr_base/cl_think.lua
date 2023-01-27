local cl_magbugbullet = CreateClientConVar("arcticvr_magbug_bullet","1",FCVAR_ARCHIVE)

function SWEP:VRThink()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    self:PreThink()

    if self.MeleeAttack then
        self:DetectMeleeStrike()
    end

    local vec1 = Vector(1, 1, 1)
    local vec0 = vec1 * 0

    if g_VR.input.boolean_primaryfire then
        if !((self.Firemode == 1) or self. NeedAnotherTriggerPull) then
            if !self.TwoStageTrigger or g_VR.input.vector1_primaryfire >= 0.9 then
                self:VR_PrimaryAttack()
            end
        end
    else
        self.BurstLength = 0
    end

    for i = 0, vm:GetBoneCount() do
        vm:ManipulateBonePosition(i, Vector(0, 0, 0))
        vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
        vm:ManipulateBoneScale(i, vec1)
    end

    local extraoffset = Vector(0, 0, 0)
    local extraangle = Angle(0, 0, 0)

    if self.CHandleRaisePos > 0 then
        local delta = self.CHandleRaisePos / self.CHandleRaiseAmount

        local a = LerpVector(delta, Vector(0, 0, 0), self.CHandleRaisedOffset.pos)

        extraoffset = extraoffset + a

        extraangle = LerpAngle(delta, Angle(0, 0, 0), self.CHandleRaisedOffset.ang)
    end

    if self.CHandleBone then
        vm:ManipulateBonePosition(self.BoneIndices[self.CHandleBone], extraoffset)
        vm:ManipulateBoneAngles(self.BoneIndices[self.CHandleBone], extraangle)

        extraoffset = Vector(0, 0, 0)
        extraangle = Angle(0, 0, 0)
    end

    if self.NonReciprocatingChargingHandle then
        local bone = self.BoneIndices.chandle
        if !self.CHandleBone then
            vm:ManipulateBonePosition(bone, extraoffset + (self.CHandlePos * self.SlideDir))
            vm:ManipulateBoneAngles(bone, extraangle)
        end
        if self.BoneIndices.slide then
            vm:ManipulateBonePosition(self.BoneIndices.slide, self.SlidePos * self.SlideDir)
        end
    else
        if self.BoneIndices.slide then
            vm:ManipulateBonePosition(self.BoneIndices.slide, extraoffset + (self.SlidePos * self.SlideDir))
            vm:ManipulateBoneAngles(self.BoneIndices.slide, extraangle)
        end
    end

    if self.SlideGrabbed or (self.PumpAction and self.ForegripGrabbed) then
        local coffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos).x
        local pullback = self.SlideGrabOffset - coffset
        local slidebone = self.BoneIndices.slide
		local cv_slideplus = GetConVar("arcticvr_slide_magnification"):GetFloat()

        if !slidebone then
            slidebone = self.BoneIndices.chandle
        end

        if self.PumpAction and self.ForegripGrabbed and self.PumpSlideOffset then
            pullback = self.PumpSlideOffset - coffset
        end

        if self.PumpAction and
            self.ForegripGrabbed and
            self.SlidePos == 0 and
            (self.Chambered > 0 or
            self.LoadedRounds > 0 and
            (self.ShootStraightFromMag or self.OpenBolt))
        then
            pullback = 0

            self.PumpActionSlideUnlocked = false
        else
            self.PumpActionSlideUnlocked = true
        end

        if self.ReverseSlide then
            pullback = -pullback
        end

        if self.CHandleRaiseAtStart and self.CHandleRaisePos < self.CHandleRaiseAmount then
            pullback = 0
        end

        if self.ChargingHandlePullAmount then
            pullback = math.Clamp(pullback, 0, self.ChargingHandlePullAmount)
        else
            pullback = math.Clamp(pullback, 0, self.SlideBlowbackAmount)
        end

        if self.NonReciprocatingChargingHandle then
            self.CHandlePos = pullback
        end

        if self.ChargingHandlePullAmount then
            pullback = pullback * ((self.SlideBlowbackAmount + 0.1) / self.ChargingHandlePullAmount)
            pullback = math.Clamp(pullback, 0, self.SlideBlowbackAmount)
        end

        self.SlidePos = pullback

        if self.LastSlidePos != self.SlidePos and
            self.SlidePos == self.SlideBlowbackAmount and
            !self.SlideReleasing
        then
            if self.OpenBolt then
                self.SlideLockedBack = true
                self.SlideReleasing = true
                self:PlayNetworkedSound(nil, "SlideBackSound")
                self:EjectEmptyChambered()
            else
                self:PlayNetworkedSound(nil, "SlideBackSound")

                if self.CanDirectChamber then
                    if !self.SlideLockedBack then
                        self:Cycle(true)
                        net.Start("avr_rack")
                        net.SendToServer()
                    end
                elseif !self.ShootStraightFromMag then
                    self:Cycle(true)
                    net.Start("avr_rack")
                    net.SendToServer()
                end

                if self.SlideLockedBack and (self.LoadedRounds > 0 or !self.Magazine) then
                    self.SlideLockedBack = false
                end

                self.SlideReleasing = true
            end

            if self.MagEjectOnOpen and self.MagCanDropFree and self.LoadedRounds <= 0 then
                self:EjectMagazine()
            end
        end

        if (self.CHandleRaise and self.SlidePos >= self.SlideLockbackAmount) or (self.CHandleRaiseAtStart and self.SlidePos == 0) then
            local cvoffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos).z
            local pullup = -(self.SlideGrabVerticalOffset - cvoffset)

            self.CHandleRaisePos = pullup

            self.CHandleRaisePos = math.Clamp(self.CHandleRaisePos, 0, self.CHandleRaiseAmount)

            if self.CHandleRaiseAtStart and self.SlidePos > 0 then
                self.CHandleRaisePos = self.CHandleRaiseAmount
            end

            if self.CHandleRaisePos == self.CHandleRaiseAmount and self.LastCHandleRaisePos != self.CHandleRaisePos then
                self:PlayNetworkedSound(nil, "BoltUpSound")
            end
        end

        self.LastCHandleRaisePos = self.CHandleRaisePos

        if !(self.PumpAction and self.ForegripGrabbed) then
            if self.BoneIndices.chandle then
                slidebone = self.BoneIndices.chandle
            end
            if !self:LeftHandInMaxs(slidebone, self.SlideMins * cv_slideplus, self.SlideMaxs * cv_slideplus) then
                self.SlideGrabbed = false
            end
        end
    else
        if !self.SlideNoAutoReciprocate then
            local rpm = self.RPM * self:GetBuff("Buff_RPM")
            self.SlidePos = math.Approach(self.SlidePos, 0, FrameTime() * self.SlideBlowbackAmount * rpm / 60)

            if self.NonReciprocatingChargingHandle then
                self.CHandlePos = math.Approach(self.CHandlePos, 0, FrameTime() * self.SlideBlowbackAmount * 500 / 60)
            end
        end
    end

    if self.SlideLockedBack or
        (self.CHandleRaise and self.CHandleRaisePos > 0)
    then
        self.SlidePos = math.Clamp(self.SlidePos, self.SlideLockbackAmount, self.SlideBlowbackAmount)
        if self.NonReciprocatingChargingHandle and (self.CHandleRaise and self.CHandleRaisePos > 0) then
            self.CHandlePos = math.Clamp(self.CHandlePos, self.SlideLockbackAmount, self.SlideBlowbackAmount)
        end
    end

    if self.SafetyBlocksSlide and self.Firemode == 0 then
        self.SlidePos = math.Clamp(self.SlidePos, 0, self.SlideLockbackAmount)
    end

    if self.SlideLockedBack and self.SlidePos == self.SlideLockbackAmount and self.SlideReleasing then
        self.SlideReleasing = false
        self:PlayNetworkedSound(nil, "SlideClickLockSound")
    end

    local delta = self.SlidePos / self.SlideBlowbackAmount

    for i, k in pairs(self.FullBackOffset or {}) do
        if !self.BoneIndices[i] then continue end

        local cpos = LerpVector(delta, k.uppos or Vector(0, 0, 0), k.pos)
        local cang = LerpAngle(delta, k.upang or Angle(0, 0, 0), k.ang)

        vm:ManipulateBonePosition(self.BoneIndices[i], cpos)
        vm:ManipulateBoneAngles(self.BoneIndices[i], cang)
    end

    if self.LastSlidePos != self.SlidePos and self.SlidePos == 0 and self.SlideReleasing then
        self.SlideReleasing = false

        if self.OpenBolt  then
            self:VR_OpenBoltShoot()
        else
            self:PlayNetworkedSound(nil, "SlideForwardSound")
        end

        if self.NonAutoloading and self.Chambered <= 0 and !self.ShootStraightFromMag then
            self:Cycle(true)
            net.Start("avr_rack")
            net.SendToServer()
        end
    end

    if self.SlidePos == self.SlideBlowbackAmount then
        self.HammerDown = true
    end

    self.LastSlidePos = self.SlidePos

    if self.HKSlap and self.CHandleRaisePos > 0 and !self.SlideGrabbed then
        local slidebone = self.BoneIndices.slide
        if self.NonReciprocatingChargingHandle then
            slidebone = self.BoneIndices.chandle
        end

        if self:LeftHandInMaxs(slidebone, self.SlideMins, self.SlideMaxs) then
            local vel = g_VR.tracking.pose_lefthand.vel - g_VR.tracking.pose_righthand.vel

            if vel:Length() > 2.5 then
                self.CHandleRaisePos = 0
                self:PlayNetworkedSound(nil, "SlideReleaseSound")
                if self.Chambered <= 0 then
                    self:Cycle()
                end
            end
        end
    end

    self.RecoilBlowback = math.Approach(self.RecoilBlowback, 0, FrameTime() * 4 * self.RecoilBlowback)

    local ra_p = self.RecoilAngles[1]
    local ra_y = self.RecoilAngles[2]

    ra_p = math.ApproachAngle(ra_p, 0, FrameTime() * 2.5 * ra_p)
    ra_y = math.ApproachAngle(ra_y, 0, FrameTime() * 2.5 * ra_y)

    self.RecoilAngles = Angle(ra_p, ra_y, 0)

    -- lerp fire selector position

    if self.FireSelectPoses and self.FireSelectPoses[self.Firemode] then
        local fspose = self.FireSelectPoses[self.Firemode]

        for i, k in pairs(fspose) do
            self.TargetMiscLerps[self.BoneIndices[i]] = k
        end
    end

    for i, k in pairs(self.BoneTaps) do
        if !k then continue end
        if k <= CurTime() then
            self.TargetMiscLerps[i] = {
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0)
            }
            self.BoneTaps[i] = nil
        end
    end

    if self.BeltGrabbed then
        local attid_s = vm:LookupAttachment("beltstart")

        local ret_s = vm:GetAttachment(attid_s)
        local pos_s = ret_s.Pos

        local attid_t = vm:LookupAttachment("belttarget")

        local ret_t = vm:GetAttachment(attid_t)
        local pos_t = ret_t.Pos

        local tdist = (pos_s - pos_t):Length()

        local lhpos = g_VR.tracking.pose_lefthand.pos
        local hdist = (lhpos - pos_t):Length()

        local bdelta = math.Clamp(tdist / hdist, 0, 1)

        local beltin = math.Round(bdelta * self.BeltBullets)

        self.BeltAmountIn = math.Approach(self.BeltAmountIn, beltin, 1)
    end

    if self.BeltFed then
        for i = 1, self.BeltBullets do
            vm:ManipulateBoneScale(self.BoneIndices[self.BeltBones[i]], vec0)
            if i <= (self.BeltBullets - self.BeltAmountIn) then continue end
            if i > ((self.BeltBullets - self.BeltAmountIn) + self.LoadedRounds) then continue end
            vm:ManipulateBoneScale(self.BoneIndices[self.BeltBones[i]], vec1)
        end
    end

    if self.LoadedRounds == 0 then
        self.BeltAmountIn = 0
    end

    self.LastDustCoverPos = self.LastDustCoverPos or 0

    if self.DustCoverGrabbed then
        local dcpos = vm:GetBonePosition(self.BoneIndices.dustcover)
        local lhpos = g_VR.tracking.pose_lefthand.pos

        dcpos = vm:WorldToLocal(dcpos)
        lhpos = vm:WorldToLocal(lhpos)

        local ang = (dcpos - lhpos):GetNormalized():AngleEx(-vm:GetAngles():Forward())[1]

        if ang > 180 then
            ang = ang - 360
        end

        self.DustCoverPos = math.Clamp(ang, self.DustCoverLimitCCW, self.DustCoverLimitCW)

        if self.LastDustCoverPos != self.DustCoverPos then
            if self.DustCoverPos == 0 then
                self:PlayNetworkedSound(nil, "CloseChamberSound")
            elseif self.DustCoverPos == self.DustCoverLimitCCW or self.DustCoverPos == self.DustCoverLimitCW then
                self:PlayNetworkedSound(nil, "OpenChamberSound")
            end
        end
    end

    if self.DustCover then
        vm:ManipulateBoneAngles(self.BoneIndices.dustcover, Angle(0, 0, self.DustCoverPos))
    end

    self.LastDustCoverPos = self.DustCoverPos

    -- insert magazine

    self:InsertMagazineBehaviour()

    -- chambered round behavior

    for i, k in pairs(self.CaseBones) do
        if !self.BoneIndices[k] then continue end
        vm:ManipulateBoneScale(self.BoneIndices[k], vec0)
    end

    for i, k in pairs(self.BulletBones) do
        if !self.BoneIndices[k] then continue end
        vm:ManipulateBoneScale(self.BoneIndices[k], vec0)
    end

    for i, k in pairs(self.CaseBones) do
        if !self.BoneIndices[k] then continue end		
			if i == nil then i = cl_magbugbullet end --magazine bug fix test
			if self.VolleyFireChambers[i] == nil then self.VolleyFireChambers[i] = cl_magbugbullet end --magazine bug fix test
        if self.VolleyFire then
            if self.VolleyFireChambers[i] >= 1 then
                vm:ManipulateBoneScale(self.BoneIndices[k], vec1)
            end
        else
            if self.EmptyChambered >= i then
                vm:ManipulateBoneScale(self.BoneIndices[k], vec1)
            end
        end
    end

    for i, k in pairs(self.BulletBones) do
        if !self.BoneIndices[k] then continue end

        if self.VolleyFire then
            if self.VolleyFireChambers[i] == 2 then
                vm:ManipulateBoneScale(self.BoneIndices[k], vec1)
            end
        else
            if self.Chambered >= i then
                vm:ManipulateBoneScale(self.BoneIndices[k], vec1)
            end

            if self.OpenBolt then
                if self.LoadedRounds >= i then
                    vm:ManipulateBoneScale(self.BoneIndices[k], vec1)
                end
            end
        end
    end

    if self.BreakAction and self.BreakActionChamberOpen then
        if self:MinimumVel(self.BreakActionCloseVector) then
            self:CloseChambers()
        end
    end

        if self.Magazine and ArcticVR.CSMagazine and IsValid(ArcticVR.CSMagazine) then
        local bsb = ArcticVR.MagazineTable[self.Magazine].BodygroupsShowBullets

        for i, bgs in pairs(bsb or {}) do
            if i == "BaseClass" then continue end
			if self.LoadedRounds >= (i + self.BeltAmountIn) then
				ArcticVR.CSMagazine:SetBodygroup(bgs.ind, bgs.bg)
			else
				ArcticVR.CSMagazine:SetBodygroup(bgs.ind, 0)
			end
		end
    end

    -- for i, bgs in pairs(self.BodygroupsShowBullets or {}) do
        -- if i == "BaseClass" then continue end
        -- if self.Rounds >= i then
            -- self:SetBodygroup(bgs.ind, bgs.bg)
        -- else
            -- self:SetBodygroup(bgs.ind, 0)
        -- end
    -- end
-- end


    if self.VolleyFire and !self.VolleyFireAutoEject then
        if self:MinimumVel(self.VolleyFireRemoveDir) then
            self:VolleyFireEject(true)
	    self:EjectMagazine(false /*grab*/)
        end
    end

    -- if self.BoneIndices.bullet then
    --     if self.Chambered > 0 then
    --         vm:ManipulateBoneScale(self.BoneIndices.bullet, vec1)
    --     else
    --         vm:ManipulateBoneScale(self.BoneIndices.bullet, vec0)
    --     end
    -- end

    if g_VR.heldEntityLeft then
        ArcticVR.lasthelditem = g_VR.heldEntityLeft
    end

    if self.BoneIndices.slidelock then
        if self.SlideLockedBack then
            self.TargetMiscLerps[self.BoneIndices.slidelock] = self.SlidelockActivePose
        else
            self.TargetMiscLerps[self.BoneIndices.slidelock] = {
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0)
            }
        end
    end

    if self.BreakAction and self.BoneIndices.pivot then
        if self.BreakActionChamberOpen then
            self.TargetMiscLerps[self.BoneIndices.pivot] = {
                pos = Vector(0, 0, 0),
                ang = self.BreakActionOpenAng
            }
        else
            self.TargetMiscLerps[self.BoneIndices.pivot] = {
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0)
            }
        end
    end

    if self.BoneIndices.cylinder then
        local a = (360 / self.InternalMagazineCapacity) * self.VolleyFireIndex

        a = self.RevolverBoneRotAxis * a

        self.TargetMiscLerps[self.BoneIndices.cylinder] = {
            pos = Vector(0, 0, 0),
            ang = a,
            rotspeed = self.RPM * self.InternalMagazineCapacity * self:GetBuff("Buff_RPM")
        }
    end

    if self.BoneIndices.trigger then
        local delta2 = g_VR.input.vector1_primaryfire

        local posoff = LerpVector(delta2, Vector(0, 0, 0), self.TriggerPulledOffset.pos)
        local angoff = LerpAngle(delta2, Angle(0, 0, 0), self.TriggerPulledOffset.ang)

        vm:ManipulateBonePosition(self.BoneIndices.trigger, posoff)
        vm:ManipulateBoneAngles(self.BoneIndices.trigger, angoff)
    end

    -- if self.BoneIndices.hammer and self.RevolverHammer then
    --     local delta = g_VR.input.vector1_primaryfire * 4

    --     if g_VR.input.boolean_primaryfire and g_VR.previousInput.boolean_primaryfire then
    --         delta = 0
    --     end

    --     local posoff = LerpVector(delta, Vector(0, 0, 0), self.HammerDownOffset.pos)
    --     local angoff = LerpAngle(delta, Angle(0, 0, 0), self.HammerDownOffset.ang)

    --     self.TargetMiscLerps[self.BoneIndices.hammer] = {pos = posoff, ang = angoff, rotspeed = 720}
    -- end

    for i, k in pairs(self.TargetMiscLerps) do
        if i == "BaseClass" then continue end
        if !self.MiscLerps[i] then continue end

        local rotspeed = 360

        if k.rotspeed then
            rotspeed = k.rotspeed
        end

        self.MiscLerps[i].pos[1] = math.Approach(self.MiscLerps[i].pos[1], k.pos[1], FrameTime() * 5)
        self.MiscLerps[i].pos[2] = math.Approach(self.MiscLerps[i].pos[2], k.pos[2], FrameTime() * 5)
        self.MiscLerps[i].pos[3] = math.Approach(self.MiscLerps[i].pos[3], k.pos[3], FrameTime() * 5)

        self.MiscLerps[i].ang[1] = math.ApproachAngle(self.MiscLerps[i].ang[1], k.ang[1], FrameTime() * rotspeed)
        self.MiscLerps[i].ang[2] = math.ApproachAngle(self.MiscLerps[i].ang[2], k.ang[2], FrameTime() * rotspeed)
        self.MiscLerps[i].ang[3] = math.ApproachAngle(self.MiscLerps[i].ang[3], k.ang[3], FrameTime() * rotspeed)

        vm:ManipulateBonePosition(i, self.MiscLerps[i].pos)
        vm:ManipulateBoneAngles(i, self.MiscLerps[i].ang)

        if i == self.BoneIndices.pivot and self.VolleyFireAutoEject and
            self.MiscLerps[i].ang == k.ang and
            self.MiscLerps[i].pos == k.pos then
            self:VolleyFireEject(self.VolleyFireAutoEjectUnspent)
        end
    end

    self:AttachmentBehaviour(false)

    vm:SetBodyGroups(self.DefaultBodygroups)

    for i, k in pairs(self.Attachments) do
        if !k.InstalledBG then continue end
        if k.Installed then
            vm:SetBodygroup(k.InstalledBG.ind, k.InstalledBG.bg)
        else
            vm:SetBodygroup(k.InstalledBG.ind, 0)
        end
    end

    self:OnThink()

end

function SWEP:PreThink()
end

function SWEP:OnThink()
end