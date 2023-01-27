function SWEP:VR_PrimaryAttack()

    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if g_VR.menuFocus then return end

    if self.NotAGun then return end

    if self.SlideGrabbed then return end
    if self.CHandleRaisePos > 0 then return end

    if self.NextPrimaryFire > CurTime() then return end

    if self.Firemode == 0 then return end

    if self.Firemode < 0 and self.BurstLength >= -self.Firemode then return end

    if self.BreakAction and self.BreakActionChamberOpen then return end

    if self.DustCoverPos != 0 then return end

    self.HammerDown = false

    if self.AlwaysShoot then
        self:VR_OpenBoltShoot()
        return
    end

    if self.OpenBolt then
        if self.Firemode == 0 then return end
        if !self.SlideLockedBack then return end

        self.SlideLockedBack = false
        self.SlideReleasing = true
        if self.LoadedRounds <= 0 then
            self:PlayNetworkedSound(nil, "SlideReleaseSound")
        end
        return
    end

    if self.SlideLockedBack and self.BoltCanAutoRelease and self.LoadedRounds > 0 then
        self.SlideLockedBack = false
        self.SlideReleasing = true
        self.NeedAnotherTriggerPull = true
        self:Cycle()
        net.Start("avr_rack")
        net.SendToServer()
        self:PlayNetworkedSound(nil, "SlideReleaseSound")
        return
    end

    if self.SlidePos > 0 then return end

    if self.VolleyFire then
        self:VolleyFireShoot()
    end

    if self.ShootStraightFromMag then
        if self.LoadedRounds <= 0 then self:DryFire() return end
    else
        if self.Chambered <= 0 then self:DryFire() return end
    end

    if self.BeltFed then
        local magtbl =  ArcticVR.MagazineTable[self.Magazine]

        if magtbl.IsBeltBox then
            if self.BeltAmountIn < self.BeltBullets then self:DryFire() return end
        end
    end

    self:VR_Shoot()
end

function SWEP:IsStabilizing()
    local lhpos = g_VR.tracking.pose_lefthand.pos
    local rhpos = g_VR.tracking.pose_righthand.pos
    local dostab = false

    if self.ForegripGrabbed then
        dostab = true
    elseif (!self.TwoHanded or self.PistolStabilize) and (lhpos - rhpos):Length() <= 6 then
        dostab = true
    end

    return dostab
end

function SWEP:GetCurrentBarrel()
    if self:GetAttOverride("OverrideMuzzle") then
        local _, i = self:GetAttOverride("OverrideMuzzle")

        return self.Attachments[i].CSModel:LookupAttachment("supp_muzzle")
    end

    if !self.VolleyFire then return 1 end
    if self.VolleyFireFromOneBarrel then return 1 end

    local vm = g_VR.viewModel
    local a = self.VolleyFireIndex
    if !self.VolleyFireBarrelToChamber then
        a = self.VolleyFireBarrelIndex
    end
    local attname = "muzzle" .. tostring(a)

    local att = vm:LookupAttachment(attname)

    return att
end

function SWEP:GetCurrentAttEnt()
    if self:GetAttOverride("OverrideMuzzle") then
        local _, i = self:GetAttOverride("OverrideMuzzle")

        return self.Attachments[i].CSModel
    end

    return g_VR.viewModel
end

function SWEP:DoEffects()
    local vm = g_VR.viewModel

    if !self.DisableMuzzleEffect then
        local posang = self:GetCurrentAttEnt():GetAttachment(self:GetCurrentBarrel())
        local pos = posang.Pos
        local ang = posang.Ang

        local angoff = self:GetAttOverride("MuzzleEffectAngle") or Angle(0, 0, 0)

        ang:RotateAroundAxis(ang:Up(), angoff.y)
        ang:RotateAroundAxis(ang:Right(), angoff.p)
        ang:RotateAroundAxis(ang:Forward(), angoff.r)

        local fx = EffectData()
        fx:SetOrigin(pos)
        fx:SetAngles(ang)
        fx:SetAttachment(self:GetCurrentBarrel())
        fx:SetScale(self.MuzzleEffectScale)
        fx:SetEntity(self:GetCurrentAttEnt())

        local muzzleeffect = self.MuzzleEffect

        if muzzleeffect == "" then
            muzzleeffect = "CS_MuzzleFlash"
        end

        muzzleeffect = self:GetAttOverride("MuzzleEffectOverride") or muzzleeffect

        util.Effect(muzzleeffect, fx)
    end

    if !self.NonAutoloading and self.CaseEffect then
        local fx2 = EffectData()
        fx2:SetAttachment(2)
        fx2:SetNormal(Vector(0, 0, 0))
        fx2:SetMagnitude(150)
        fx2:SetEntity(vm)
        util.Effect(self.CaseEffect, fx2)
    else
        self.EmptyChambered = self.EmptyChambered + 1
    end
end

function SWEP:DoRecoil()
    local m = 1

    if self:IsStabilizing() then
        m = 0.75 * self:GetBuff("Buff_Recoil_TwoHand_Pistol")

        if self.ForegripGrabbed then
            m = 0.75 * self:GetBuff("Buff_Recoil_TwoHand")
        end
    end

    m = m * self:GetBuff("Buff_Recoil")

    m = m * Lerp(ArcticVR:GetStockDelta(), 1, self.RecoilStockMult * self:GetBuff("Buff_Recoil_Stock"))

    self.RecoilBlowback = self.RecoilBlowback + (self.Recoil * m)
    self.RecoilBlowback = math.Clamp(self.RecoilBlowback, 0, 10)
    self.RecoilAngles = self.RecoilAngles + Angle(-self.RecoilVertical * self:GetBuff("Buff_Recoil_Vertical"), 0, 0) * (self.Recoil * m)
    self.RecoilAngles = self.RecoilAngles + Angle(0, 1, 0) * self.RecoilSide * m * self:GetBuff("Buff_Recoil_Side") * math.Rand(-1, 1) * (self.Recoil * m)

    self.RecoilAngles[1] = math.Clamp(self.RecoilAngles[1], -90, 90)
end

function SWEP:VolleyFireAdvance()
    self.VolleyFireIndex = self.VolleyFireIndex + 0.5

    -- so... for some reason, this function gets called twice per shot and I have no goddamn clue why.
    -- this is the workaround for now.

    if self.VolleyFireIndex > self.InternalMagazineCapacity + 0.5 then
        self.VolleyFireIndex = 1
    end

    if !self.VolleyFireBarrelToChamber then
        self.VolleyFireBarrelIndex = self.VolleyFireBarrelIndex + 1

        if self.VolleyFireBarrelIndex > self.VolleyFireBarrels then
            self.VolleyFireBarrelIndex = 1
        end
    end
end

function SWEP:DryFire()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    self:PlayNetworkedSound(nil, "DryFireSound")

    self.NeedAnotherTriggerPull = true

    if self.VolleyFire and self.VolleyFireAlwaysAdvance then
        self:VolleyFireAdvance()
    end

    local rpm = self.RPM * self:GetBuff("Buff_RPM")

    self.NextPrimaryFire = CurTime() + (60 / rpm)
end

function SWEP:VolleyFireShoot()
    local a = self.VolleyFireIndex

    if self.VolleyFireAlwaysFromChamberOne then
        for i = 1, self.InternalMagazineCapacity do
            if self.VolleyFireChambers[i] == 2 then
                self.VolleyFireIndex = i
                a = i
                break
            end
        end
    end

    if self.VolleyFireChambers[a] != 2 then self:DryFire() return end

    self.VolleyFireChambers[a] = 1
    self:VR_Shoot()

    self:VolleyFireAdvance()
end

function SWEP:VR_OpenBoltShoot()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end
    if self.LoadedRounds <= 0 then return end

    if self.BeltFed then
        local magtbl =  ArcticVR.MagazineTable[self.Magazine]

        if magtbl.IsBeltBox then
            if self.BeltAmountIn < self.BeltBullets then return end
        end
    end

    local msbf = self.MeanShotsBetweenJams
    if msbf != 0 and 1 / msbf > math.Rand(0, 1) then
        -- JAM!
        return
    end

    self:VR_Shoot()
end

function SWEP:VR_Shoot()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    -- VRMOD_TriggerHaptic( string actionName, number delay, number duration, number frequency, number amplitude )
    VRMOD_TriggerHaptic("vibration_right", 0, 0.3, 15, 20)

    if self.ForegripGrabbed then
       VRMOD_TriggerHaptic("vibration_left", 0, 0.3, 15, 20)
    end

    local att = self:GetCurrentAttEnt():GetAttachment(self:GetCurrentBarrel())

    local src = att.Pos

    local mainmuzz = vm:GetAttachment(1)

    local dir = mainmuzz.Ang

    if self:GetAttOverride("Silencer") then
        self:PlayNetworkedSound(nil, "FireSoundSil")
    else
        self:PlayNetworkedSound(nil, "FireSound")
    end

    net.Start("avr_shoot")
    net.WriteFloat(src[1])
    net.WriteFloat(src[2])
    net.WriteFloat(src[3])
    net.WriteAngle(dir)
    net.SendToServer()

    self.NeedAnotherTriggerPull = false

    self.Chambered = 0

    if !self.NonAutoloading then
        self.SlidePos = self.SlideBlowbackAmount
        self:Cycle()

        if self.CanLockBack and self.Chambered == 0 and (self.Magazine or self.InternalMagazine) then
            self.SlideLockedBack = true
        end
    elseif self.AlwaysCycle then
        self:Cycle()
    end

    self:DoRecoil()

    self:DoEffects()

    self.BurstLength = self.BurstLength + 1
end