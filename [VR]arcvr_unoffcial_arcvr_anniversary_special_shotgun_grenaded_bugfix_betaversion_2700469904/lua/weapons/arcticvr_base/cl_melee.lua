local cv_allowgunmelee = false or CreateConVar("arcticvr_gunmelee", "1", FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE) 
local cv_usegunmelee = CreateClientConVar("arcticvr_gunmelee_client","1",FCVAR_ARCHIVE)
local cv_allowfist = false or CreateConVar("arcticvr_fist", "1", FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE) 
local cv_usefist = CreateClientConVar("arcticvr_fist_client","1",FCVAR_ARCHIVE)

-- local cv_dmggunmelee = CreateConvar("arcticvr_gunmelee_damage","10",FCVAR_REPLICATED) or 0

function SWEP:DetectMeleeStrike(ply)
	if cv_usefist:GetBool() and cv_allowfist:GetBool() then

		local vm = g_VR.viewModel

		if !vm then return end
		if !IsValid(vm) then return end


		if self.NextMeleeAttack > CurTime() then return end
		-- if we are swinging fast enough
		local vel = g_VR.tracking.pose_lefthand.vel:Length()/40
		local vel2 = g_VR.tracking.pose_righthand.vel:Length()/40

		if vel < self.MeleeVelThreshold and vel2 < self.MeleeVelThreshold then return end

		-- detect hit targets


		local startbone = g_VR.tracking.pose_righthand.pos
		local endbone = g_VR.tracking.pose_lefthand.pos

		local tr = util.TraceLine({
			start = startbone,
			endpos = endbone,
			mask = MASK_ALL,
			filter = LocalPlayer()
		})
		-- submit attack
		if tr.Hit then
			self.NextMeleeAttack = CurTime() + self.MeleeDelay

			local src = tr.HitPos + (tr.HitNormal * -2)

			local tr2 = util.TraceLine({
				start = src,
				endpos = src + (g_VR.tracking.pose_lefthand.vel:GetNormalized() * 8),
				mask = MASK_ALL
			})

			if !tr2.Hit then return end

			local hs = "MeleeHitSound"

			if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
				hs = "MeleeStrikeSound"
			end

			self:PlayNetworkedSound(nil, hs)

			net.Start("avr_meleeattack")
			net.WriteFloat(src[1])
			net.WriteFloat(src[2])
			net.WriteFloat(src[3])
			net.WriteVector(g_VR.tracking.pose_lefthand.vel:GetNormalized())
			net.SendToServer()
		end
	end
	
	if g_VR.sixPoints == true then
		-- if !g_VR.tracking.pose_leftfoot or !g_VR.tracking.pose_leftfoot then return end
		
		-- if we are swinging fast enough
		local vel = g_VR.tracking.pose_lefthand.vel:Length()/40
		local vel2 = g_VR.tracking.pose_righthand.vel:Length()/40

		-- if vel < self.MeleeVelThreshold and vel2 < self.MeleeVelThreshold then return end

		-- detect hit targets


		local startbone = g_VR.tracking.pose_leftfoot.pos
		local endbone = g_VR.tracking.pose_rightfoot.pos

		local tr = util.TraceLine({
			start = startbone,
			endpos = endbone,
			mask = MASK_ALL,
			filter = LocalPlayer()
		})
		-- submit attack
		if tr.Hit then
			self.NextMeleeAttack = CurTime() + self.MeleeDelay

			local src = tr.HitPos + (tr.HitNormal * -2)

			local tr2 = util.TraceLine({
				start = src,
				endpos = src,
				mask = MASK_ALL
			})

			if !tr2.Hit then return end

			local hs = "MeleeHitSound"

			if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
				hs = "MeleeStrikeSound"
			end

			self:PlayNetworkedSound(nil, hs)

			net.Start("avr_meleeattack")
			net.WriteFloat(src[1])
			net.WriteFloat(src[2])
			net.WriteFloat(src[3])
			net.WriteVector(g_VR.tracking.hmd.vel)
			net.SendToServer()
		end	
	end

	
	--
	if cv_usegunmelee:GetBool() and cv_allowgunmelee:GetBool() then

		local vm = g_VR.viewModel

		if !vm then return end
		if !IsValid(vm) then return end
		if !vm:GetAttachment(1) then return end


		if self.NextMeleeAttack > CurTime() then return end
		-- if we are swinging fast enough
		local vel = g_VR.tracking.pose_righthand.vel:Length()/40

		if vel < self.MeleeVelThreshold then return end
		-- detect hit targets


		local startbone = vm:GetAttachment(1).Pos
		local endbone = vm:GetAttachment(2).Pos

		local tr = util.TraceLine({
			start = startbone,
			endpos = endbone,
			mask = MASK_ALL,
			filter = LocalPlayer()
		})
		-- submit attack
		if tr.Hit then
			self.NextMeleeAttack = CurTime() + self.MeleeDelay

			local src = tr.HitPos + (tr.HitNormal * -2)

			local tr2 = util.TraceLine({
				start = src,
				endpos = src + (g_VR.tracking.pose_righthand.vel:GetNormalized() * 8),
				mask = MASK_ALL
			})

			if !tr2.Hit then return end

			local hs = "MeleeHitSound"

			if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
				hs = "MeleeStrikeSound"
			end

			self:PlayNetworkedSound(nil, hs)

			net.Start("avr_meleeattack")
			net.WriteFloat(src[1])
			net.WriteFloat(src[2])
			net.WriteFloat(src[3])
			net.WriteVector(g_VR.tracking.pose_righthand.vel)
			net.SendToServer()
		end
	else
		local vm = g_VR.viewModel

		if !vm then return end
		if !IsValid(vm) then return end
		if !self.BoneIndices.bladestart then return end
		if !self.BoneIndices.bladeend then return end

		if self.NextMeleeAttack > CurTime() then return end
		-- if we are swinging fast enough
		local vel = g_VR.tracking.pose_righthand.vel:Length()/40

		if vel < self.MeleeVelThreshold then return end
		-- detect hit targets

		local startatt = vm:LookupAttachment("bladestart")
		local endatt = vm:LookupAttachment("bladeend")

		local startbone = vm:GetAttachment(startatt).Pos
		local endbone = vm:GetAttachment(endatt).Pos

		local tr = util.TraceLine({
			start = startbone,
			endpos = endbone,
			mask = MASK_ALL,
			filter = LocalPlayer()
		})
		-- submit attack
		if tr.Hit then
			self.NextMeleeAttack = CurTime() + self.MeleeDelay

			local src = tr.HitPos + (tr.HitNormal * -2)

			local tr2 = util.TraceLine({
				start = src,
				endpos = src + (g_VR.tracking.pose_righthand.vel:GetNormalized() * 8),
				mask = MASK_ALL
			})

			if !tr2.Hit then return end

			local hs = "MeleeHitSound"

			if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
				hs = "MeleeStrikeSound"
			end

			self:PlayNetworkedSound(nil, hs)

			net.Start("avr_meleeattack")
			net.WriteFloat(src[1])
			net.WriteFloat(src[2])
			net.WriteFloat(src[3])
			net.WriteVector(g_VR.tracking.pose_righthand.vel)
			net.SendToServer()
		end
	end
end