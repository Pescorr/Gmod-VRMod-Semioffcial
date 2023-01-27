if CLIENT then

ArcticVR = ArcticVR or {}
ArcticVR.StabilityFrameIndex = 1
ArcticVR.StabilityFrames = {}
ArcticVR.AttachmentModels = {}
ArcticVR.SightPiece = nil
ArcticVR.LastGun = nil

net.Receive("avr_updatemag", function(len, ply)
    local id = net.ReadString()
    local count = net.ReadUInt(16)
    local mag = net.ReadEntity()

    if !IsValid(mag) then return end

    local magid = id
    local magtab = ArcticVR.MagazineTable[magid]

    mag.MagID = magid
    mag.BodygroupsShowBullets = magtab.BodygroupsShowBullets

    mag:UpdateMag(count)
end)

net.Receive("avr_magin_forclient", function(len, ply)
    local loaded = net.ReadUInt(16)

    local wpn = LocalPlayer():GetActiveWeapon()
    if wpn.ArcticVR then
        wpn.LoadedRounds = loaded
    end
end)

local lastheldentleft = nil
local lastheldentright = nil

hook.Add("VRMod_Input","avr_input", function(action, state)
    local wpn = LocalPlayer():GetActiveWeapon()
    if wpn.ArcticVR or wpn.ArcticVRNade then
        wpn:VRInput(action, state)
    end
end)

hook.Add( "VRMod_PreRender", "avr_gunthink", function()
    local wpn = LocalPlayer():GetActiveWeapon()
    if ArcticVR.LastGun and ArcticVR.LastGun != wpn and ArcticVR.LastGun.ArcticVR then
        if IsValid(ArcticVR.LastGun) then
            ArcticVR.LastGun:VRHolster()
        end
    end
    if wpn.ArcticVR or wpn.ArcticVRNade then
        if ArcticVR.LastGun != wpn then
            wpn:VRDeploy()
        end

        if wpn.RTScope then
            wpn:RTScopeFunc(true)
        end

        for i, k in pairs(wpn.Attachments or {}) do
            if !k.Installed then continue end

            local atttbl = ArcticVR.AttachmentTable[k.Installed]

            if atttbl.RTScope then
                wpn:DrawRTScope(atttbl, k.CSModel, k.RTScopeMat, k.RTScopeSurface, true)
            end
        end

        wpn:VRThink()
    end

    ArcticVR.LastGun = wpn
end)

hook.Add("VRMod_PreRenderRight", "avr_rightrender", function()
    local wpn = LocalPlayer():GetActiveWeapon()
    if wpn.ArcticVR or wpn.ArcticVRNade then

        if wpn.RTScope then
            wpn:RTScopeFunc(false)
        end

        for i, k in pairs(wpn.Attachments or {}) do
            if !k.Installed then continue end

            local atttbl = ArcticVR.AttachmentTable[k.Installed]

            if atttbl.RTScope then
                wpn:DrawRTScope(atttbl, k.CSModel, k.RTScopeMat, k.RTScopeSurface, false)
            end
        end
    end
end)

-- hook.Add("PreDrawOpaqueRenderables", "avr_rtscope", function( depth, sky )
--     if sky then return end

--     local wpn = LocalPlayer():GetActiveWeapon()

--     local left = false

--     if g_VR.view.origin == g_VR.eyePosLeft then
--         left = true
--     end
-- end)

-- tracking:
-- 		hmd:
-- 				ang	=	0.044 17.125 0.909
-- 				angvel	=	0.239 0.293 0.023
-- 				pos	=	-39.197601 -2076.995850 31.977652
-- 				vel	=	-0.000745 -0.000299 0.001139
-- 		pose_lefthand:
-- 				ang	=	36.343 -6.817 7.154
-- 				angvel	=	1.403 -0.268 -0.126
-- 				pos	=	-38.255795 -2056.585693 33.242390
-- 				vel	=	-0.001984 -0.002926 0.000619
-- 		pose_righthand:
-- 				ang	=	37.672 3.286 3.465
-- 				angvel	=	0.906 0.030 -0.060
-- 				pos	=	-39.915737 -2066.740967 33.302757
-- 				vel	=	-0.001716 -0.001425 0.000653

local function divvec(vec, div)
    vec[1] = vec[1] / div
    vec[2] = vec[2] / div
    vec[3] = vec[3] / div

    return vec
end

local prevstab = false

function ArcticVR:GetStockDelta()
    local headpos = g_VR.tracking.hmd.pos
    local rhpos = g_VR.tracking.pose_righthand.pos

    local amt = 0

    local ddt = (headpos - rhpos):Length()

    local md = 10
    local dd = 0
    local mu = 4

    if ddt < md then
        amt = math.Clamp(ddt - dd, 0, md) / md

        amt = 1 - amt
    end

    amt = amt * mu

    amt = math.Clamp(amt, 0, 1)

    return amt
end

local lastpos = nil

hook.Add( "VRMod_Tracking", "avr_guntracking", function()
    local wpn = LocalPlayer():GetActiveWeapon()
    local lpp = g_VR.origin

    if !wpn.ArcticVR then return end

    if !g_VR.tracking.pose_lefthand then return end

    local recoil = (wpn.RecoilBalance - wpn.RecoilAngles:Up()) * wpn.RecoilBlowback

    local dostab = wpn:IsStabilizing()
    local twohand = dostab

    -- left hand controls direction.
    -- right hand control position and roll.

    local wclass = wpn:GetClass()

    local offset = Vector()
    offset:Set(g_VR.viewModelInfo[wclass].offsetPos)
    local fg_offset = Vector()
    fg_offset:Set(wpn.ForegripOffset)
    local ang_offset = Angle()
    ang_offset:Set(g_VR.viewModelInfo[wclass].offsetAng)

    if wpn.CenterForegrip then
        fg_offset[2] = 0
    end

    lastpos = lastpos or lpp

    local diff = lpp - lastpos

    lastpos = lpp

    local lhpos = g_VR.tracking.pose_lefthand.pos - lpp
    local lhang = g_VR.tracking.pose_lefthand.ang
    local rhpos = g_VR.tracking.pose_righthand.pos - lpp
    local rhang = g_VR.tracking.pose_righthand.ang

    local origroll = rhang[3]

    -- record actual current position in stability frames.

    local sf = wpn.StabilityFrames
    local wp = wpn.WeightPenaltyFrames + wpn:GetBuffAdditive("Buff_WeightPenaltyFrames")

    sf = sf + wpn:GetBuffAdditive("Buff_StabilityFrames")

    sf = sf + math.floor(ArcticVR:GetStockDelta() * 3)

    sf = math.max(sf, wp)

    if !dostab then
        sf = wpn.PassiveStabilityFrames + wpn:GetBuffAdditive("Buff_PassiveStabilityFrames")

        if sf > 1 then
            dostab = true
        end
    end

    if sf > 1 and dostab then
        if !prevstab then
            ArcticVR.StabilityFrames = {}
        end

        ArcticVR.StabilityFrames[ArcticVR.StabilityFrameIndex] = {
            lhpos = lhpos,
            rhpos = rhpos,
            rhang = rhang:Forward()
        }

        ArcticVR.StabilityFrameIndex = ArcticVR.StabilityFrameIndex + 1

        if ArcticVR.StabilityFrameIndex > sf then
            ArcticVR.StabilityFrameIndex = 1
        end

        local mean_lhpos = lhpos
        local mean_rhpos = rhpos
        local mean_rhang = rhang:Forward()

        local nf = 1
        for i = 1, #ArcticVR.StabilityFrames do
            local sframe = ArcticVR.StabilityFrames[i]

            if !sframe then continue end
            if i > sf then
                ArcticVR.StabilityFrames[i] = nil
                continue
            end

            if twohand then
                mean_lhpos = mean_lhpos + sframe.lhpos
            end

            mean_rhpos = mean_rhpos + sframe.rhpos

            if nf > (sf - wp) then
                mean_rhang = mean_rhang + sframe.rhang
            else
                mean_rhang = mean_rhang + rhang:Forward()
            end

            nf = nf + 1
        end

        divvec(mean_lhpos, nf)
        divvec(mean_rhpos, nf)
        divvec(mean_rhang, nf)

        lhpos = mean_lhpos
        rhpos = mean_rhpos
        rhang = mean_rhang:Angle()

        rhang[3] = origroll

        prevstab = true
    else
        prevstab = false
    end

    if !wpn.ForegripGrabbed then
        if twohand then
            lhpos = lhpos + rhang:Forward() * recoil[1]
            lhpos = lhpos + rhang:Right() * recoil[2]
            lhpos = lhpos + rhang:Up() * recoil[3]
            lhang:RotateAroundAxis(rhang:Right(), -wpn.RecoilAngles[1])
            lhang:RotateAroundAxis(rhang:Up(), -wpn.RecoilAngles[2])
            lhang:RotateAroundAxis(rhang:Forward(), -wpn.RecoilAngles[3])
        end

        rhpos = rhpos + rhang:Forward() * recoil[1]
        rhpos = rhpos + rhang:Right() * recoil[2]
        rhpos = rhpos + rhang:Up() * recoil[3]
        rhang:RotateAroundAxis(rhang:Right(), -wpn.RecoilAngles[1])
        rhang:RotateAroundAxis(rhang:Up(), -wpn.RecoilAngles[2])
        rhang:RotateAroundAxis(rhang:Forward(), -wpn.RecoilAngles[3])

        if (wpn.HasStock or wpn:GetAttOverride("GivesStock")) and GetConVar("arcticvr_virtualstock"):GetBool() then
            local headpos = g_VR.tracking.hmd.pos - lpp

            local headang = (rhpos - headpos):Angle()

            local amt = ArcticVR:GetStockDelta() * 0.1

            rhang = LerpAngle(amt, rhang, headang)
        end

        if twohand then
            g_VR.tracking.pose_lefthand.pos = lhpos + lpp
            g_VR.tracking.pose_lefthand.ang = lhang
        end
        g_VR.tracking.pose_righthand.pos = rhpos + lpp
        g_VR.tracking.pose_righthand.ang = rhang
        return
    end

    local oldrhpos = Vector()
    oldrhpos:Set(rhpos)

    rhpos = rhpos + rhang:Forward() * offset[1]
    rhpos = rhpos + rhang:Right() * offset[2]
    rhpos = rhpos + rhang:Up() * offset[3]

    local oldlhpos = Vector()
    oldlhpos:Set(lhpos)

    lhpos = lhpos + rhang:Forward() * fg_offset[1]
    lhpos = lhpos + rhang:Right() * fg_offset[2]
    lhpos = lhpos + rhang:Up() * fg_offset[3]

    local newang = (lhpos - rhpos)

    if wpn.ReverseForegrip then
        newang = -newang
    end

    newang = newang:Angle()

    newang[3] = origroll

    local sens = GetConVar("arcticvr_2h_sens"):GetFloat()
    newang = LerpAngle(sens, rhang, newang)

    if (wpn.HasStock or wpn:GetAttOverride("GivesStock")) and GetConVar("arcticvr_virtualstock"):GetBool() then
        local headpos = g_VR.tracking.hmd.pos - lpp

        local headang = (rhpos - headpos):Angle()

        local amt = ArcticVR:GetStockDelta() * 0.1

        newang = LerpAngle(amt, newang, headang)
    end

    newang:RotateAroundAxis(newang:Right(), -wpn.RecoilAngles[1])
    newang:RotateAroundAxis(newang:Up(), -wpn.RecoilAngles[2])
    newang:RotateAroundAxis(newang:Forward(), -wpn.RecoilAngles[3])

    lhang:Set(newang)
    lhang:RotateAroundAxis(lhang:Up(), wpn.ForegripAngle[1])
    lhang:RotateAroundAxis(lhang:Right(), wpn.ForegripAngle[2])
    lhang:RotateAroundAxis(lhang:Forward(), wpn.ForegripAngle[3])

    rhpos:Set(oldrhpos)

    rhpos = rhpos + newang:Forward() * recoil[1]
    rhpos = rhpos + newang:Right() * recoil[2]
    rhpos = rhpos + newang:Up() * recoil[3]

    fg_offset = wpn.ForegripOffset

    newang:RotateAroundAxis(newang:Right(), ang_offset[1])
    newang:RotateAroundAxis(newang:Up(), ang_offset[2])
    newang:RotateAroundAxis(newang:Forward(), ang_offset[3])

    local pang = Angle()
    pang:Set(newang)

    lhang = g_VR.viewModel:LocalToWorldAngles(wpn.ForegripAngle)

    if wpn:GetAttOverride("OverrideForegrip") then
        local _, i = wpn:GetAttOverride("OverrideForegrip")
        local psm = wpn.Attachments[i].CSModel
        local fg_att = psm:LookupAttachment("foregrip")
        local fg_posang = psm:GetAttachment(fg_att)

        lhpos = fg_posang.Pos - lpp + diff

        fg_offset = wpn:GetAttOverride("ForegripOffset")
        lhang = g_VR.viewModel:LocalToWorldAngles(wpn:GetAttOverride("ForegripAngle"))
    elseif wpn.BoneBasedForegrip then
        local psm = g_VR.viewModel
        local fg_att = psm:LookupAttachment("foregrip")
        local fg_posang = psm:GetAttachment(fg_att)

        lhpos = fg_posang.Pos - lpp + diff

        fg_offset = wpn.ForegripOffset
        pang = g_VR.viewModel:GetAngles()
        lhang = g_VR.viewModel:LocalToWorldAngles(wpn.ForegripAngle)
    else
        lhpos:Set(rhpos)
    end

    lhpos = lhpos + pang:Forward() * fg_offset[1]
    lhpos = lhpos + pang:Right() * fg_offset[2]
    lhpos = lhpos + pang:Up() * fg_offset[3]

    if wpn.PumpAction then

        local spos = WorldToLocal(lhpos, ang_offset, rhpos, newang)
        local locpos = WorldToLocal(g_VR.tracking.pose_lefthand.pos - lpp, ang_offset, rhpos, newang)

        if wpn.SlideDir[1] == 0 then
            locpos[3] = 0
        else
            spos[3] = spos[3] - fg_offset[3]
        end

        if wpn.SlideDir[2] == 0 then
            locpos[2] = 0
        else
            spos[2] = spos[2] - fg_offset[2]
        end

        if wpn.SlideDir[3] == 0 then
            locpos[1] = 0
        else
            spos[1] = spos[1] - fg_offset[1]
        end

        if wpn.SlideDir[3] > 0 then
            spos[1] = math.Clamp(spos[1], 0, wpn.SlideBlowbackAmount)
        elseif wpn.SlideDir[3] < 0 then
            spos[1] = math.Clamp(spos[1], -wpn.SlideBlowbackAmount, 0)
        end

        if wpn.SlideDir[2] > 0 then
            spos[2] = math.Clamp(spos[2], 0, wpn.SlideBlowbackAmount)
        elseif wpn.SlideDir[2] < 0 then
            spos[2] = math.Clamp(spos[2], -wpn.SlideBlowbackAmount, 0)
        end

        if wpn.SlideDir[1] > 0 then
            spos[3] = math.Clamp(spos[3], 0, wpn.SlideBlowbackAmount)
        elseif wpn.SlideDir[1] < 0 then
            spos[3] = math.Clamp(spos[3], -wpn.SlideBlowbackAmount, 0)
        end

        spos = spos + locpos

        lhpos = LocalToWorld(spos, ang_offset, rhpos, newang)

    end
--start
	-- local function StartLerpingToGrabPoint(targetGrabPoint)
				-- local vm = g_VR.viewModel

				-- local tmpModel = g_VR.viewModel
				-- tmpModel:SetupBones()
				
				-- -- cvrg.boltBone = tmpModel:LookupBone("bolt")
				-- -- cvrg.boltHandleBone = tmpModel:LookupBone("bolthandle")
				-- -- cvrg.triggerBone = tmpModel:LookupBone("trigger")
				-- -- cvrg.magBone = tmpModel:LookupBone("mag")
				-- -- cvrg.bulletBone = tmpModel:LookupBone("bullet")
				-- -- cvrg.muzzleBone = tmpModel:LookupBone("muzzle")
				-- -- cvrg.entranceBone = tmpModel:LookupBone("mag_entrance")
				-- -- cvrg.sightBone = tmpModel:LookupBone("holosight")
				-- -- cvrg.leftHandBone = tmpModel:LookupBone("ValveBiped.Bip01_L_Hand")
				-- -- cvrg.rightHandBone = tmpModel:LookupBone("ValveBiped.Bip01_R_Hand")
				
				
				-- local grabPoints = {}
		-- -- holdingGrip = (targetGrabPoint and targetGrabPoint.type == GRIP or false)
		-- -- releasingGrip = (targetGrabPoint==nil and grabPoint.type == GRIP or false)
		-- -- local releasingBolt = (targetGrabPoint == nil and boltGrabOffset and true or false)
		-- --
		
		-- handLerpTime = SysTime()
		
		-- fingerPoseOpenStart = vrmod.GetLeftHandOpenFingerAngles()
		-- fingerPoseClosedStart = vrmod.GetLeftHandClosedFingerAngles()
		-- fingerPoseOpenEnd = targetGrabPoint and targetGrabPoint.fingerPose or g_VR.defaultOpenHandAngles
		-- fingerPoseClosedEnd = targetGrabPoint and targetGrabPoint.fingerPose or g_VR.defaultClosedHandAngles
		
		-- entityStart = entityEnd
		-- entityEnd = targetGrabPoint and tmpModel
		
		-- if entityStart then
			
			-- if true then
				-- boneStart = tmpModel
				-- local mtxRH = tmpModel:GetBoneMatrix(boneStart)
				-- local mtxSlide = tmpModel:GetBoneMatrix(boneEnd)
				-- local handWPos, handWAng = LocalToWorld(grabPoint.pos, grabPoint.ang, mtxSlide:GetTranslation(), mtxSlide:GetAngles())
				-- posStart, angStart = WorldToLocal( handWPos, handWAng, mtxRH:GetTranslation(), mtxRH:GetAngles())
			-- else
				-- boneStart = boneEnd
				-- posStart, angStart = posEnd, angEnd
			-- end
			
		-- end
		-- if entityStart then
			-- boneEnd = targetGrabPoint.bone
			-- posEnd, angEnd = targetGrabPoint.pos, targetGrabPoint.ang
		-- end
		
		-- grabPoints = targetGrabPoint
	 -- end
	

-- --end
				-- local vm = g_VR.viewModel
				


    g_VR.tracking.pose_righthand.pos = rhpos + lpp
    g_VR.tracking.pose_righthand.ang = newang
    g_VR.tracking.pose_lefthand.pos = lhpos + lpp
    g_VR.tracking.pose_lefthand.ang = lhang

	
end)

			-- local tickrate = GetConVar("vrmod_net_tickrate"):GetInt()
		
			-- hook.Add("Tick","yrsysss",function()
				-- local updates = false
				-- for handWPos,handWAng in pairs(g_VR) do
					-- StartLerpingToGrabPoint( vm:LookupBone("ValveBiped.Bip01_L_Hand").bone)
					-- updates = true
				-- end
				-- if not updates then
					-- hook.Remove("Tick","yrsysss")
					-- --print("position update hook removed")
				-- end
			-- end)


hook.Add( "VRMod_Pickup", "avr_pickup", function(ply, ent)
    local leftent = g_VR.heldEntityLeft
    local rightent = g_VR.heldEntityRight

    if leftent and leftent != lastheldentleft then
        local pos, ang = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang

        net.Start("avr_pose")
            net.WriteVector(pos)
            net.WriteAngle(ang)
            net.WriteBool(true)
            net.WriteEntity(leftent)
        net.SendToServer()
    end

    if rightent and rightent != lastheldentright then
        local pos, ang = g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang

        net.Start("avr_pose")
            net.WriteVector(pos)
            net.WriteAngle(ang)
            net.WriteBool(false)
            net.WriteEntity(rightent)
        net.SendToServer()
    end

    -- if rightent and rightent.ArcticVRMagazine then
    --     if !g_VR.input.boolean_left_reload then
    --         VRMod_Drop(LocalPlayer(), rightent)
    --     end
    -- end

    lastheldentright = rightent
    lastheldentleft = leftent
end)

end