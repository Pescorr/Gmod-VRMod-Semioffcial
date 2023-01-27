
ArcticVR.lasthelditem = nil
	local cv_allgunreloadkey = CreateConVar("arcticvr_allgun_allow_reloadkey","0",FCVAR_ARCHIVE) or false
	local cv_allgunreloadkeyclient = CreateClientConVar("arcticvr_allgun_allow_reloadkey_client","0",FCVAR_ARCHIVE)
	local cv_gripwithreloadkey = CreateClientConVar("arcticvr_grip_withreloadkey","0",FCVAR_ARCHIVE)
	local cv_disablereloadkey = CreateClientConVar("arcticvr_disable_reloadkey","0",FCVAR_ARCHIVE)
	local cv_disablegrabreload = CreateClientConVar("arcticvr_disable_grabreload","1",FCVAR_ARCHIVE)
	local cv_gripplus = CreateClientConVar("arcticvr_grip_magnification","1.0",FCVAR_ARCHIVE)

function SWEP:VRInput(action, state)
    local vm = g_VR.viewModel


    if !vm then return end
    if !IsValid(vm) then return end

    local foregripbone = 0
	local gripkey = "boolean_left_secondaryfire"

    if self.BoneIndices.foregrip then
        foregripbone = self.BoneIndices.foregrip
    end

    if (self.Firemode == 1) or self.TwoStageTrigger or self.NeedAnotherTriggerPull then
        if action == "boolean_primaryfire" and state then
            if self.NextPrimaryFire < CurTime() then
                self:VR_PrimaryAttack()
            end
        end
    end



    if action == "boolean_secondaryfire" and state then
        if self.BreakAction then
            self:OpenChambers()
        else
            self:FiremodeSwitch()
        end
    end

    if action == "boolean_left_pickup" and state then
        local slidebone = self.BoneIndices.slide
        local off = self.SlidePos
		local cv_slideplus = GetConVar("arcticvr_slide_magnification"):GetFloat()
        if self.NonReciprocatingChargingHandle then
            slidebone = self.BoneIndices.chandle
            off = self.CHandlePos
        end
        if self.NotAGun then slidebone = nil end
        if slidebone then
            if self:LeftHandInMaxs(slidebone, self.SlideMins*cv_slideplus, self.SlideMaxs*cv_slideplus) then
                self.SlideGrabOffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos).x + off
                if self.CHandleRaise or self.CHandleRaiseAtStart then
                    self.SlideGrabVerticalOffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos).z + self.CHandleRaisePos
                end
                self.SlideGrabbed = true
                self:PlayNetworkedSound(nil, "SlidePulledSound")
                return
            end
        end
    elseif !state then
        self.SlideGrabbed = false
    end

    if action == "boolean_left_pickup" and state then
        if self.BeltFed and !self.BeltGrabbed and self.LoadedRounds > 0 and math.abs(self.DustCoverPos) >= self.DustCoverMinimums then
            if self.Magazine then
                local magtbl =  ArcticVR.MagazineTable[self.Magazine]

                if magtbl.IsBeltBox then
                    local bsbone = self.BoneIndices.beltstart

                    if self.BeltAmountIn == self.BeltBullets then
                        bsbone = self.BoneIndices.belttarget
                    end

                    if self:LeftHandInMaxs(bsbone, self.BeltMins, self.BeltMaxs) then
                        self.BeltGrabbed = true
                        self:PlayNetworkedSound(nil, "BeltPullSound")
                        return
                    end
                end
            end
        end
    elseif !state then
        if self.BeltGrabbed then
            if self.BeltAmountIn < self.BeltBullets then
                self.BeltAmountIn = 0
                self:PlayNetworkedSound(nil, "BeltOutSound")
            else
                self:PlayNetworkedSound(nil, "BeltInSound")
            end
            self.BeltGrabbed = false
            return
        end
    end

    if action == "boolean_left_pickup" and state then
        if self.DustCover and !self.DustCoverGrabbed then
            if self:LeftHandInMaxs(self.BoneIndices.dustcover_grip, self.DustCoverMins, self.DustCoverMaxs) then
                self.DustCoverGrabbed = true
                return
            end
        end
    elseif !state then
        if self.DustCover and self.DustCoverGrabbed then
            self.DustCoverGrabbed = false
            return
        end
    end

    if action == "boolean_left_pickup" and state then
        local magbone = self.BoneIndices.mag or self.BoneIndices.magazine

        local magtbl = nil
		

        if self.Magazine then
            magtbl = ArcticVR.MagazineTable[self.Magazine]
        end

        if magtbl and magtbl.IsBeltBox then
            magbone = self.BoneIndices.box
        end

        if magbone then
            if self:LeftHandInMaxs(magbone, self.MagazineInsertMins, self.MagazineInsertMaxs) then
                if !self.MagEjectOnOpen or (self.SlidePos > self.SlideLockbackAmount) then
					if not cv_disablegrabreload:GetBool() then
						self:EjectMagazine(true)
						return
					end
				end
            end
        end
    end

    if action == "boolean_left_pickup" and state then
        if self.BoneIndices.ejector then
            if self:LeftHandInMaxs(self.BoneIndices.ejector, Vector(-1.5, -1.5, -1.5), Vector(1.5, 1.5,-1.5)) then
                self:VolleyFireEject(true)
                self:BoneTap(self.BoneIndices.ejector, {pos = self.EjectorTapOffset, ang = Angle(0, 0, 0)}, 0.5)
                return
            end
        end
    end

    if self.TwoHanded then
	
		if cv_gripwithreloadkey:GetBool() then
			 gripkey = "boolean_reload"
		else
			 gripkey = "boolean_left_primaryfire"
		end


		if GetConVar("arcticvr_grip_alternative_mode"):GetBool() then
			if self.ForegripGrabbed then
				if action == gripkey and !state then
					self:UngripForegrip()
					return
				end
			elseif self:LeftHandInMaxs(foregripbone, self.ForegripMins*cv_gripplus:GetFloat(), self.ForegripMaxs*cv_gripplus:GetFloat()) then
			if action == gripkey and state then				
					self:GripForegrip()
					return
				end
			end
		else

			if action == gripkey and state then
				if self.ForegripGrabbed then
					self:UngripForegrip()
					return				
				elseif self:LeftHandInMaxs(foregripbone, self.ForegripMins*cv_gripplus:GetFloat(), self.ForegripMaxs*cv_gripplus:GetFloat()) then
					self:GripForegrip()
					return
				end
			else			
				if self.ForegripGrabbed then
					if action == "boolean_left_pickup" and !state then
						self:UngripForegrip()
						return
					end
				elseif self:LeftHandInMaxs(foregripbone, self.ForegripMins*cv_gripplus:GetFloat(), self.ForegripMaxs*cv_gripplus:GetFloat()) then
					if action == "boolean_left_pickup" and state then
						self:GripForegrip()
						return
					end
				end
            end
        end
    end
	
	
--Anniversaryzone
	if action == "boolean_reload" && state then
		if cv_disablereloadkey:GetBool() then return end
		if self.MagCanDropFree or cv_allgunreloadkey:GetBool() and cv_allgunreloadkeyclient:GetBool() then
			self:EjectMagazine(false /*grab*/)
			return
		end
	end

--Anniversaryzone
    -- dump pouch

    local pouchbone = "ValveBiped.Bip01_Pelvis"
    local dist = GetConVar("arcticvr_defpouchdist"):GetFloat()

    if GetConVar("arcticvr_headpouch"):GetBool() then
        pouchbone = "ValveBiped.Bip01_Head1"
        dist = GetConVar("arcticvr_headpouchdist"):GetFloat()
    end

--Anniversaryzone
    if GetConVar("arcticvr_hybridpouch"):GetBool() then
        pouchbone = "ValveBiped.Bip01_Spine4"
        dist = GetConVar("arcticvr_hybridpouchdist"):GetFloat()
    end
	
	if GetConVar("vrmod_floatinghands"):GetBool() or GetConVar("arcticvr_infpouch"):GetBool() then
		pouchbone = "ValveBiped.Bip01_Pelvis"
		dist = 99999
	end
	
	local pouch = g_VR.eyePosLeft
	if (LocalPlayer():LookupBone(pouchbone) && LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(pouchbone))) then
		pouch = LocalToWorld(Vector(3,3,0), Angle(0,0,0),
			LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(pouchbone)):GetTranslation(),
			Angle(0,g_VR.characterYaw,0))
--Anniversaryzone
	else
		dist = 32 -- compensate for shit bones
	end
	
--Anniversaryzone
--floatingpouchdiststart
	-- pouchsize = GetConVar("arcticvr_pouchsize"):GetFloat()
	
	-- if GetConVar("vrmod_floatinghands"):GetBool() or GetConVar("arcticvr_infpouch"):GetBool() then
	-- pouchsize = 99999
	-- end


--floatingpouchdistend
    if g_VR.tracking.pose_lefthand.pos:DistToSqr(pouch) < (dist * dist) and not self.ForegripGrabbed then
        if action == "boolean_left_pickup" and state then

            if self.NextCanSpawnMagTime > CurTime() then return end

            if LocalPlayer():GetAmmoCount(self.Primary.Ammo) > 0 then
                net.Start("avr_spawnmag_r")
                    local pos, ang = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang
                    net.WriteVector(pos)
                    net.WriteAngle(ang)
                net.SendToServer()
                surface.PlaySound(self.SpawnMagSound)
            else
				if not self.NotAGun then
					surface.PlaySound("items/medshotno1.wav")
				end
            end

            self.NextCanSpawnMagTime = CurTime() + 0.1

            return

        elseif action == "boolean_left_pickup" and !state and IsValid(ArcticVR.lasthelditem) then

            if ArcticVR.lasthelditem:GetPos():DistToSqr(pouch) < (dist*3 * dist*3) then

                net.Start("avr_despawnmag")
                net.WriteEntity(ArcticVR.lasthelditem)
                net.SendToServer()

                return

            end
        end
		
	end
		--pes pouch test
		
		
		--Anniversaryzone
    if GetConVar("arcticvr_weppouch"):GetBool() then
        local weppouchbone = "ValveBiped.Bip01_Spine4"
		local weppouchsize = GetConVar("arcticvr_hybridpouchdist"):GetFloat()
		local weppouchdist = g_VR.eyePosRight
		if (LocalPlayer():LookupBone(weppouchbone) && LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone))) then
			weppouchdist = LocalToWorld(Vector(3,3,0), Angle(0,0,0),
			LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone)):GetTranslation(),
			Angle(0,g_VR.characterYaw,0))
	
		
				if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouchdist) < (weppouchsize * weppouchsize) then
					if action == "boolean_right_pickup" and state then
						LocalPlayer():ConCommand("slot3")
						
					elseif action == "boolean_right_pickup" and  !state then

						if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouchdist) < (weppouchsize * weppouchsize) then

							LocalPlayer():ConCommand("slot1")

							return

						end
					end
				end
		end
	end

		--pes pouch end




    -- if action == "boolean_left_pickup" and state then
        -- -- self:AttachmentBehaviour(true)
    -- end
end