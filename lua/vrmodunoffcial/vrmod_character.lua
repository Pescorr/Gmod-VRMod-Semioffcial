--------[vrmod_character.lua]Start--------
function vrmod_character_lua()
	g_VR = g_VR or {}
	g_VR.characterYaw = 0
	local convars, convarValues = vrmod.GetConvars()
	if not convars or not convarValues then
		print("VRMod_Character: Warning - convars or convarValues not initialized. This might lead to errors.")
		convars = {} -- Fallback
		convarValues = {} -- Fallback
	end

	local cv_animation_convar = CreateClientConVar("vrmod_animation_Enable", "1", true, FCVAR_ARCHIVE)
	-- cv_animationの代わりにcv_animation_convarを使用
	if CLIENT then
		CreateClientConVar("vrmod_idle_act", "ACT_HL2MP_IDLE", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_walk_act", "ACT_HL2MP_WALK", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_run_act", "ACT_HL2MP_RUN", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_jump_act", "ACT_HL2MP_JUMP_PASSIVE", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_hide_head", "0", true, FCVAR_ARCHIVE, "Hide player's head in VR (0=Scale, 1=Offset)", 0, 1)
		local hideHeadPosX = CreateClientConVar("vrmod_hide_head_pos_x", 0, true, FCVAR_ARCHIVE, "up down", -1000, 1000)
		local hideHeadPosY = CreateClientConVar("vrmod_hide_head_pos_y", 20, true, FCVAR_ARCHIVE, " front back ", -1000, 1000)
		local hideHeadPosZ = CreateClientConVar("vrmod_hide_head_pos_z", 0, true, FCVAR_ARCHIVE, " left right", -1000, 1000)
	end

	g_VR.defaultOpenHandAngles = {Angle(0, 0, 0), Angle(0, -40, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, -40, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0),}
	g_VR.defaultClosedHandAngles = {Angle(30, 0, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, -50, -10), Angle(0, -90, 0), Angle(0, -70, 0), Angle(0, -35. - 8, 0), Angle(0, -80, 0), Angle(0, -70, 0), Angle(0, -26.5, 4.8), Angle(0, -70, 0), Angle(0, -70, 0), Angle(0, -30, 12.7), Angle(0, -70, 0), Angle(0, -70, 0), Angle(-30, 0, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, -50, 10), Angle(0, -90, 0), Angle(0, -70, 0), Angle(0, -35.8, 0), Angle(0, -80, 0), Angle(0, -70, 0), Angle(0, -26.5, -4.8), Angle(0, -70, 0), Angle(0, -70, 0), Angle(0, -30, -12.7), Angle(0, -70, 0), Angle(0, -70, 0),}
	g_VR.zeroHandAngles = {Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0),}
	g_VR.openHandAngles = g_VR.defaultOpenHandAngles
	g_VR.closedHandAngles = g_VR.defaultClosedHandAngles
	local characterInfo = {}
	local activePlayers = {}
	local zeroVec, zeroAng = Vector(), Angle()
	local function RecursiveBoneTable2(ent, parentbone, infotab, ordertab, notfirst)
		if not IsValid(ent) then return end
		local bones = notfirst and ent:GetChildBones(parentbone) or {parentbone}
		for k, v in pairs(bones) do
			local n = ent:GetBoneName(v)
			local boneparent = ent:GetBoneParent(v)
			local parentmat = ent:GetBoneMatrix(boneparent)
			local childmat = ent:GetBoneMatrix(v)
			if not parentmat or not childmat then continue end -- 保護: マトリックスがnilの場合 -- print("VRMod_Character: Warning - Bone matrix is nil in RecursiveBoneTable2 for bone " .. (n or "unknown"))
			local parentpos, parentang = parentmat:GetTranslation(), parentmat:GetAngles()
			local childpos, childang = childmat:GetTranslation(), childmat:GetAngles()
			local relpos, relang = WorldToLocal(childpos, childang, parentpos, parentang)
			infotab[v] = {
				name = n,
				pos = Vector(0, 0, 0),
				ang = Angle(0, 0, 0),
				parent = boneparent,
				relativePos = relpos,
				relativeAng = relang,
				offsetAng = Angle(0, 0, 0)
			}

			ordertab[#ordertab + 1] = v
		end

		for k, v in pairs(bones) do
			RecursiveBoneTable2(ent, v, infotab, ordertab, true)
		end
	end

	local function UpdateIK(ply)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		if not g_VR.net or not g_VR.net[steamid] or not g_VR.net[steamid].lerpedFrame then return end
		local net = g_VR.net[steamid]
		if not characterInfo or not characterInfo[steamid] or not characterInfo[steamid].boneinfo then return end
		local charinfo = characterInfo[steamid]
		local boneinfo = charinfo.boneinfo
		local bones = charinfo.bones
		if not net or not net.lerpedFrame then return end
		local frame = net.lerpedFrame
		if not frame then return end
		local inVehicle = ply:InVehicle()
		local vehicle = inVehicle and ply:GetVehicle() or nil
		local plyAng = Angle(0, frame.characterYaw, 0)
		if inVehicle and IsValid(vehicle) then
			plyAng = vehicle:GetAngles()
			_, plyAng = LocalToWorld(zeroVec, Angle(0, 90, 0), zeroVec, plyAng)
		end

		if net.characterAltHead then
			local tmp1, tmp2 = WorldToLocal(zeroVec, frame.hmdAng, zeroVec, Angle(0, frame.characterYaw, 0))
			if bones and bones.b_head and ply:GetBoneMatrix(bones.b_head) then
				ply:ManipulateBoneAngles(bones.b_head, Angle(-tmp2.roll, -tmp2.pitch, tmp2.yaw))
			end
		end

		if not inVehicle then
			local headHeight = frame.hmdPos.z + (frame.hmdAng:Forward() * -3).z
			local cutAmount = math.Clamp(charinfo.preRenderPos.z + charinfo.characterEyeHeight - headHeight, 0, 40)
			local spineTargetLen = charinfo.spineLen - cutAmount * 0.5
			local a1 = math.acos(math.Clamp(spineTargetLen / charinfo.spineLen, -1, 1))
			charinfo.horizontalCrouchOffset = math.sin(a1) * charinfo.spineLen
			if bones and bones.b_spine and ply:GetBoneMatrix(bones.b_spine) then
				ply:ManipulateBoneAngles(bones.b_spine, Angle(0, math.deg(a1), 0))
			end

			charinfo.verticalCrouchOffset = cutAmount * 0.5
			local legTargetLen = charinfo.upperLegLen + charinfo.lowerLegLen - charinfo.verticalCrouchOffset * 0.8
			local a1_denom = 2 * charinfo.upperLegLen * legTargetLen
			local a23_denom = 2 * charinfo.lowerLegLen * legTargetLen
			local a1_val = (a1_denom ~= 0) and math.Clamp((charinfo.upperLegLen * charinfo.upperLegLen + legTargetLen * legTargetLen - charinfo.lowerLegLen * charinfo.lowerLegLen) / a1_denom, -1, 1) or 0
			local a23_val = (a23_denom ~= 0) and math.Clamp((charinfo.lowerLegLen * charinfo.lowerLegLen + legTargetLen * legTargetLen - charinfo.upperLegLen * charinfo.upperLegLen) / a23_denom, -1, 1) or 0
			local a1_leg = math.deg(math.acos(a1_val))
			local a23_leg = 180 - a1_leg - math.deg(math.acos(a23_val))
			if a1_leg ~= a1_leg or a23_leg ~= a23_leg then
				a1_leg = 0
				a23_leg = 180
			end

			if bones and bones.b_leftCalf and ply:GetBoneMatrix(bones.b_leftCalf) then
				ply:ManipulateBoneAngles(bones.b_leftCalf, Angle(0, -(a23_leg - 180), 0))
			end

			if bones and bones.b_leftThigh and ply:GetBoneMatrix(bones.b_leftThigh) then
				ply:ManipulateBoneAngles(bones.b_leftThigh, Angle(0, -a1_leg, 0))
			end

			if bones and bones.b_rightCalf and ply:GetBoneMatrix(bones.b_rightCalf) then
				ply:ManipulateBoneAngles(bones.b_rightCalf, Angle(0, -(a23_leg - 180), 0))
			end

			if bones and bones.b_rightThigh and ply:GetBoneMatrix(bones.b_rightThigh) then
				ply:ManipulateBoneAngles(bones.b_rightThigh, Angle(0, -a1_leg, 0))
			end

			if bones and bones.b_leftFoot and ply:GetBoneMatrix(bones.b_leftFoot) then
				ply:ManipulateBoneAngles(bones.b_leftFoot, Angle(0, -a1_leg, 0))
			end

			if bones and bones.b_rightFoot and ply:GetBoneMatrix(bones.b_rightFoot) then
				ply:ManipulateBoneAngles(bones.b_rightFoot, Angle(0, -a1_leg, 0))
			end
		else
			if bones and bones.b_spine and ply:GetBoneMatrix(bones.b_spine) then
				ply:ManipulateBoneAngles(bones.b_spine, Angle(0, 0, 0))
			end

			if bones and bones.b_leftCalf and ply:GetBoneMatrix(bones.b_leftCalf) then
				ply:ManipulateBoneAngles(bones.b_leftCalf, Angle(0, 0, 0))
			end

			if bones and bones.b_leftThigh and ply:GetBoneMatrix(bones.b_leftThigh) then
				ply:ManipulateBoneAngles(bones.b_leftThigh, Angle(0, 0, 0))
			end

			if bones and bones.b_rightCalf and ply:GetBoneMatrix(bones.b_rightCalf) then
				ply:ManipulateBoneAngles(bones.b_rightCalf, Angle(0, 0, 0))
			end

			if bones and bones.b_rightThigh and ply:GetBoneMatrix(bones.b_rightThigh) then
				ply:ManipulateBoneAngles(bones.b_rightThigh, Angle(0, 0, 0))
			end

			if bones and bones.b_leftFoot and ply:GetBoneMatrix(bones.b_leftFoot) then
				ply:ManipulateBoneAngles(bones.b_leftFoot, Angle(0, 0, 0))
			end

			if bones and bones.b_rightFoot and ply:GetBoneMatrix(bones.b_rightFoot) then
				ply:ManipulateBoneAngles(bones.b_rightFoot, Angle(0, 0, 0))
			end
		end

		local L_TargetPos = frame.lefthandPos
		local L_TargetAng = frame.lefthandAng
		local mtx_l_clavicle = bones and bones.b_leftClavicle and ply:GetBoneMatrix(bones.b_leftClavicle) or nil
		local L_ClaviclePos = mtx_l_clavicle and mtx_l_clavicle:GetTranslation() or Vector()
		charinfo.L_ClaviclePos = L_ClaviclePos
		local tmp1 = L_ClaviclePos + plyAng:Right() * -charinfo.clavicleLen
		local tmp2 = tmp1 + (L_TargetPos - tmp1) * 0.15
		local L_ClavicleTargetAng
		if not inVehicle then
			L_ClavicleTargetAng = (tmp2 - L_ClaviclePos):Angle()
		else
			_, L_ClavicleTargetAng = LocalToWorld(zeroVec, WorldToLocal(tmp2 - L_ClaviclePos, zeroAng, zeroVec, plyAng):Angle(), zeroVec, plyAng)
		end

		L_ClavicleTargetAng:RotateAroundAxis(L_ClavicleTargetAng:Forward(), 90)
		local L_UpperarmPos = L_ClaviclePos + L_ClavicleTargetAng:Forward() * charinfo.clavicleLen
		local L_TargetVec = L_TargetPos - L_UpperarmPos
		local L_TargetVecLen = L_TargetVec:Length()
		local L_TargetVecAng, L_TargetVecAngLocal
		if not inVehicle then
			L_TargetVecAng = L_TargetVec:Angle()
		else
			L_TargetVecAngLocal = WorldToLocal(L_TargetVec, zeroAng, zeroVec, plyAng):Angle()
			_, L_TargetVecAng = LocalToWorld(Vector(), L_TargetVecAngLocal, zeroVec, plyAng)
		end

		local L_UpperarmTargetAng = Angle(L_TargetVecAng.pitch, L_TargetVecAng.yaw, L_TargetVecAng.roll)
		local tmp
		if not inVehicle then
			tmp = Angle(L_TargetVecAng.pitch, frame.characterYaw, -90)
		else
			_, tmp = LocalToWorld(Vector(), Angle(L_TargetVecAngLocal.pitch, 0, -90), zeroVec, plyAng)
		end

		local tpos, tang = WorldToLocal(zeroVec, tmp, zeroVec, L_TargetVecAng)
		L_UpperarmTargetAng:RotateAroundAxis(L_UpperarmTargetAng:Forward(), tang.roll)
		local a1_left_denom = 2 * charinfo.upperArmLen * L_TargetVecLen
		local a23_left_denom = 2 * charinfo.lowerArmLen * L_TargetVecLen
		local a1_left_val = (a1_left_denom ~= 0) and math.Clamp((charinfo.upperArmLen * charinfo.upperArmLen + L_TargetVecLen * L_TargetVecLen - charinfo.lowerArmLen * charinfo.lowerArmLen) / a1_left_denom, -1, 1) or 0
		local a23_left_val = (a23_left_denom ~= 0) and math.Clamp((charinfo.lowerArmLen * charinfo.lowerArmLen + L_TargetVecLen * L_TargetVecLen - charinfo.upperArmLen * charinfo.upperArmLen) / a23_left_denom, -1, 1) or 0
		local a1_left = math.deg(math.acos(a1_left_val))
		if a1_left == a1_left then
			L_UpperarmTargetAng:RotateAroundAxis(L_UpperarmTargetAng:Up(), a1_left)
		end

		local test_left
		if not inVehicle then
			test_left = ((L_TargetPos.z - L_UpperarmPos.z) + 20) * 1.5
		else
			test_left = ((L_TargetPos - L_UpperarmPos):Dot(plyAng:Up()) + 20) * 1.5
		end

		if test_left < 0 then
			test_left = 0
		end

		L_UpperarmTargetAng:RotateAroundAxis(L_TargetVec:GetNormalized(), 30 + test_left)
		local L_ForearmTargetAng = Angle(L_UpperarmTargetAng.pitch, L_UpperarmTargetAng.yaw, L_UpperarmTargetAng.roll)
		local a23_left = 180 - a1_left - math.deg(math.acos(a23_left_val))
		if a23_left == a23_left then
			L_ForearmTargetAng:RotateAroundAxis(L_ForearmTargetAng:Up(), 180 + a23_left)
		end

		local tmp_left = Angle(L_TargetAng.pitch, L_TargetAng.yaw, L_TargetAng.roll - 90)
		local tpos_left, tang_left = WorldToLocal(zeroVec, tmp_left, zeroVec, L_ForearmTargetAng)
		local L_WristTargetAng = Angle(L_ForearmTargetAng.pitch, L_ForearmTargetAng.yaw, L_ForearmTargetAng.roll)
		L_WristTargetAng:RotateAroundAxis(L_WristTargetAng:Forward(), tang_left.roll)
		local L_UlnaTargetAng = LerpAngle(0.5, L_ForearmTargetAng, L_WristTargetAng)
		local R_TargetPos = frame.righthandPos
		local R_TargetAng = frame.righthandAng
		local mtx_r_clavicle = bones and bones.b_rightClavicle and ply:GetBoneMatrix(bones.b_rightClavicle) or nil
		local R_ClaviclePos = mtx_r_clavicle and mtx_r_clavicle:GetTranslation() or Vector()
		charinfo.R_ClaviclePos = R_ClaviclePos
		local tmp1_right = R_ClaviclePos + plyAng:Right() * charinfo.clavicleLen
		local tmp2_right = tmp1_right + (R_TargetPos - tmp1_right) * 0.15
		local R_ClavicleTargetAng
		if not inVehicle then
			R_ClavicleTargetAng = (tmp2_right - R_ClaviclePos):Angle()
		else
			_, R_ClavicleTargetAng = LocalToWorld(Vector(), WorldToLocal(tmp2_right - R_ClaviclePos, zeroAng, zeroVec, plyAng):Angle(), zeroVec, plyAng)
		end

		R_ClavicleTargetAng:RotateAroundAxis(R_ClavicleTargetAng:Forward(), 90)
		local R_UpperarmPos = R_ClaviclePos + R_ClavicleTargetAng:Forward() * charinfo.clavicleLen
		local R_TargetVec = R_TargetPos - R_UpperarmPos
		local R_TargetVecLen = R_TargetVec:Length()
		local R_TargetVecAng, R_TargetVecAngLocal
		if not inVehicle then
			R_TargetVecAng = R_TargetVec:Angle()
		else
			R_TargetVecAngLocal = WorldToLocal(R_TargetVec, zeroAng, zeroVec, plyAng):Angle()
			_, R_TargetVecAng = LocalToWorld(Vector(), R_TargetVecAngLocal, zeroVec, plyAng)
		end

		local R_UpperarmTargetAng = Angle(R_TargetVecAng.pitch, R_TargetVecAng.yaw, R_TargetVecAng.roll)
		R_UpperarmTargetAng:RotateAroundAxis(R_TargetVec, 180)
		local tmp_right
		if not inVehicle then
			tmp_right = Angle(R_TargetVecAng.pitch, frame.characterYaw, 90)
		else
			_, tmp_right = LocalToWorld(Vector(), Angle(R_TargetVecAngLocal.pitch, 0, 90), zeroVec, plyAng)
		end

		local tpos_right, tang_right = WorldToLocal(zeroVec, tmp_right, zeroVec, R_TargetVecAng)
		R_UpperarmTargetAng:RotateAroundAxis(R_UpperarmTargetAng:Forward(), tang_right.roll)
		local a1_right_denom = 2 * charinfo.upperArmLen * R_TargetVecLen
		local a23_right_denom = 2 * charinfo.lowerArmLen * R_TargetVecLen
		local a1_right_val = (a1_right_denom ~= 0) and math.Clamp((charinfo.upperArmLen * charinfo.upperArmLen + R_TargetVecLen * R_TargetVecLen - charinfo.lowerArmLen * charinfo.lowerArmLen) / a1_right_denom, -1, 1) or 0
		local a23_right_val = (a23_right_denom ~= 0) and math.Clamp((charinfo.lowerArmLen * charinfo.lowerArmLen + R_TargetVecLen * R_TargetVecLen - charinfo.upperArmLen * charinfo.upperArmLen) / a23_right_denom, -1, 1) or 0
		local a1_right = math.deg(math.acos(a1_right_val))
		if a1_right == a1_right then
			R_UpperarmTargetAng:RotateAroundAxis(R_UpperarmTargetAng:Up(), a1_right)
		end

		local test_right
		if not inVehicle then
			test_right = ((R_TargetPos.z - R_UpperarmPos.z) + 20) * 1.5
		else
			test_right = ((R_TargetPos - R_UpperarmPos):Dot(plyAng:Up()) + 20) * 1.5
		end

		if test_right < 0 then
			test_right = 0
		end

		R_UpperarmTargetAng:RotateAroundAxis(R_TargetVec:GetNormalized(), -(30 + test_right))
		local R_ForearmTargetAng = Angle(R_UpperarmTargetAng.pitch, R_UpperarmTargetAng.yaw, R_UpperarmTargetAng.roll)
		local a23_right = 180 - a1_right - math.deg(math.acos(a23_right_val))
		if a23_right == a23_right then
			R_ForearmTargetAng:RotateAroundAxis(R_ForearmTargetAng:Up(), 180 + a23_right)
		end

		local tmp_r = Angle(R_TargetAng.pitch, R_TargetAng.yaw, R_TargetAng.roll - 90)
		local tpos_r, tang_r = WorldToLocal(zeroVec, tmp_r, zeroVec, R_ForearmTargetAng)
		local R_WristTargetAng = Angle(R_ForearmTargetAng.pitch, R_ForearmTargetAng.yaw, R_ForearmTargetAng.roll)
		R_WristTargetAng:RotateAroundAxis(R_WristTargetAng:Forward(), tang_r.roll)
		local R_UlnaTargetAng = LerpAngle(0.5, R_ForearmTargetAng, R_WristTargetAng)
		if bones and bones.b_leftClavicle and boneinfo[bones.b_leftClavicle] then
			boneinfo[bones.b_leftClavicle].overrideAng = L_ClavicleTargetAng
		end

		if bones and bones.b_leftUpperarm and boneinfo[bones.b_leftUpperarm] then
			boneinfo[bones.b_leftUpperarm].overrideAng = L_UpperarmTargetAng
		end

		if bones and bones.b_leftHand and boneinfo[bones.b_leftHand] then
			boneinfo[bones.b_leftHand].overrideAng = L_TargetAng
		end

		if bones and bones.b_rightClavicle and boneinfo[bones.b_rightClavicle] then
			boneinfo[bones.b_rightClavicle].overrideAng = R_ClavicleTargetAng
		end

		if bones and bones.b_rightUpperarm and boneinfo[bones.b_rightUpperarm] then
			boneinfo[bones.b_rightUpperarm].overrideAng = R_UpperarmTargetAng
		end

		if bones and bones.b_rightHand and boneinfo[bones.b_rightHand] then
			boneinfo[bones.b_rightHand].overrideAng = R_TargetAng + Angle(0, 0, 180)
		end

		if bones and bones.b_leftWrist and boneinfo[bones.b_leftWrist] and bones.b_leftUlna and boneinfo[bones.b_leftUlna] then
			if boneinfo[bones.b_leftForearm] then
				boneinfo[bones.b_leftForearm].overrideAng = L_ForearmTargetAng
			end

			if boneinfo[bones.b_leftWrist] then
				boneinfo[bones.b_leftWrist].overrideAng = L_WristTargetAng
			end

			if boneinfo[bones.b_leftUlna] then
				boneinfo[bones.b_leftUlna].overrideAng = L_UlnaTargetAng
			end

			if boneinfo[bones.b_rightForearm] then
				boneinfo[bones.b_rightForearm].overrideAng = R_ForearmTargetAng
			end

			if boneinfo[bones.b_rightWrist] then
				boneinfo[bones.b_rightWrist].overrideAng = R_WristTargetAng
			end

			if boneinfo[bones.b_rightUlna] then
				boneinfo[bones.b_rightUlna].overrideAng = R_UlnaTargetAng
			end
		else
			if bones and bones.b_leftForearm and boneinfo[bones.b_leftForearm] then
				boneinfo[bones.b_leftForearm].overrideAng = L_UlnaTargetAng
			end

			if bones and bones.b_rightForearm and boneinfo[bones.b_rightForearm] then
				boneinfo[bones.b_rightForearm].overrideAng = R_UlnaTargetAng
			end
		end

		if bones and bones.fingers then
			for k, v_bone_id in pairs(bones.fingers) do
				if not boneinfo[v_bone_id] then continue end
				local finger_index_base = math.floor((k - 1) / 3 + 1)
				if frame["finger" .. finger_index_base] then
					boneinfo[v_bone_id].offsetAng = LerpAngle(frame["finger" .. finger_index_base], g_VR.openHandAngles[k] or Angle(), g_VR.closedHandAngles[k] or Angle())
				end
			end
		end

		if charinfo and charinfo.boneorder then
			for i = 1, #charinfo.boneorder do
				local bone_id_current = charinfo.boneorder[i]
				if not boneinfo[bone_id_current] then continue end
				local parent_id = boneinfo[bone_id_current].parent
				local wpos, wang
				if boneinfo[bone_id_current].name == "ValveBiped.Bip01_L_Clavicle" then
					wpos = L_ClaviclePos
				elseif boneinfo[bone_id_current].name == "ValveBiped.Bip01_R_Clavicle" then
					wpos = R_ClaviclePos
				else
					local parentInfo = boneinfo[parent_id]
					if parentInfo then
						local parentPos, parentAng = parentInfo.pos, parentInfo.ang
						wpos, wang = LocalToWorld(boneinfo[bone_id_current].relativePos, boneinfo[bone_id_current].relativeAng + boneinfo[bone_id_current].offsetAng, parentPos, parentAng)
					else
						wpos = boneinfo[bone_id_current].relativePos
						wang = boneinfo[bone_id_current].relativeAng + boneinfo[bone_id_current].offsetAng
					end
				end

				if boneinfo[bone_id_current].overrideAng ~= nil then
					wang = boneinfo[bone_id_current].overrideAng
				end

				local mat = Matrix()
				mat:Translate(wpos or vector_origin) -- 保護: wposがnilの場合
				mat:Rotate(wang or angle_zero) -- 保護: wangがnilの場合
				boneinfo[bone_id_current].targetMatrix = mat
				boneinfo[bone_id_current].pos = wpos or vector_origin
				boneinfo[bone_id_current].ang = wang or angle_zero
			end
		end
	end

	local function CharacterInit(ply)
		if not IsValid(ply) then return false end
		local steamid = ply:SteamID()
		local pmname = ply.vrmod_pm or ply:GetModel()
		-- フォールバックモデル
		if not pmname or pmname == "" then
			pmname = "models/player/kleiner.mdl"
		end

		if characterInfo[steamid] and characterInfo[steamid].modelName == pmname then return true end
		if ply == LocalPlayer() then
			timer.Create(
				"vrutil_timer_validatefingertracking",
				0.1,
				0,
				function()
					if not g_VR or not g_VR.tracking or not g_VR.tracking.pose_lefthand or not g_VR.tracking.pose_righthand then return end
					if g_VR.tracking.pose_lefthand.simulatedPos == nil and g_VR.tracking.pose_righthand.simulatedPos == nil then
						timer.Remove("vrutil_timer_validatefingertracking")
						if not g_VR.input or not g_VR.input.skeleton_lefthand or not g_VR.input.skeleton_righthand then return end
						for i = 1, 2 do
							local hand_skeleton = (i == 1) and g_VR.input.skeleton_lefthand or g_VR.input.skeleton_righthand
							if not hand_skeleton or not hand_skeleton.fingerCurls then continue end
							local curls = hand_skeleton.fingerCurls
							for k, v_curl in pairs(curls) do
								if v_curl < 0 or v_curl > 1 or (k == 3 and v_curl == 0.75) then
									g_VR.defaultOpenHandAngles = g_VR.zeroHandAngles
									g_VR.defaultClosedHandAngles = g_VR.zeroHandAngles
									g_VR.openHandAngles = g_VR.zeroHandAngles
									g_VR.closedHandAngles = g_VR.zeroHandAngles
									break
								end
							end
						end
					end
				end
			)
		end

		characterInfo[steamid] = {
			preRenderPos = Vector(0, 0, 0),
			renderPos = Vector(0, 0, 0),
			characterHeadToHmdDist = 0,
			characterEyeHeight = 0,
			bones = {},
			boneinfo = {},
			boneorder = {},
			player = ply,
			boneCallback = 0,
			verticalCrouchOffset = 0,
			horizontalCrouchOffset = 0,
			originalHeadPosScale = nil
		}

		ply:SetLOD(0)
		local cm = ClientsideModel(pmname)
		if not IsValid(cm) then
			print("VRMod_Character: Error - Failed to create clientside model: " .. pmname)
			characterInfo[steamid] = nil -- 初期化失敗

			return false
		end

		cm:SetPos(LocalPlayer():GetPos())
		cm:SetAngles(Angle(0, 0, 0))
		cm:SetupBones()
		RecursiveBoneTable2(cm, cm:LookupBone("ValveBiped.Bip01_L_Clavicle"), characterInfo[steamid].boneinfo, characterInfo[steamid].boneorder)
		RecursiveBoneTable2(cm, cm:LookupBone("ValveBiped.Bip01_R_Clavicle"), characterInfo[steamid].boneinfo, characterInfo[steamid].boneorder)
		local boneNames = {
			b_leftClavicle = "ValveBiped.Bip01_L_Clavicle",
			b_leftUpperarm = "ValveBiped.Bip01_L_UpperArm",
			b_leftForearm = "ValveBiped.Bip01_L_Forearm",
			b_leftHand = "ValveBiped.Bip01_L_Hand",
			b_leftWrist = "ValveBiped.Bip01_L_Wrist",
			b_leftUlna = "ValveBiped.Bip01_L_Ulna",
			b_leftCalf = "ValveBiped.Bip01_L_Calf",
			b_leftThigh = "ValveBiped.Bip01_L_Thigh",
			b_leftFoot = "ValveBiped.Bip01_L_Foot",
			b_rightClavicle = "ValveBiped.Bip01_R_Clavicle",
			b_rightUpperarm = "ValveBiped.Bip01_R_UpperArm",
			b_rightForearm = "ValveBiped.Bip01_R_Forearm",
			b_rightHand = "ValveBiped.Bip01_R_Hand",
			b_rightWrist = "ValveBiped.Bip01_R_Wrist",
			b_rightUlna = "ValveBiped.Bip01_R_Ulna",
			b_rightCalf = "ValveBiped.Bip01_R_Calf",
			b_rightThigh = "ValveBiped.Bip01_R_Thigh",
			b_rightFoot = "ValveBiped.Bip01_R_Foot",
			b_head = "ValveBiped.Bip01_Head1",
			b_spine = "ValveBiped.Bip01_Spine",
		}

		characterInfo[steamid].bones = {
			fingers = {cm:LookupBone("ValveBiped.Bip01_L_Finger0") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger01") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger02") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger1") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger11") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger12") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger2") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger21") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger22") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger3") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger31") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger32") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger4") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger41") or -1, cm:LookupBone("ValveBiped.Bip01_L_Finger42") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger0") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger01") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger02") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger1") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger11") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger12") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger2") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger21") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger22") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger3") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger31") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger32") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger4") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger41") or -1, cm:LookupBone("ValveBiped.Bip01_R_Finger42") or -1,}
		}

		if ply == LocalPlayer() then
			g_VR.errorText = ""
		end

		for k, v_bone_name in pairs(boneNames) do
			local bone = cm:LookupBone(v_bone_name) or -1
			characterInfo[steamid].bones[k] = bone
			if bone == -1 and not string.find(k, "Wrist") and not string.find(k, "Ulna") then
				if ply == LocalPlayer() then
					g_VR.errorText = "Incompatible player model. Missing bone " .. v_bone_name
				end

				cm:Remove()
				g_VR.StopCharacterSystem(steamid)
				print("VRMod: CharacterInit failed for " .. steamid .. " due to missing bone: " .. v_bone_name)

				return false
			end
		end

		characterInfo[steamid].modelName = pmname
		local claviclePos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftClavicle) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftClavicle):GetTranslation() or cm:GetPos()
		local upperPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftUpperarm) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftUpperarm):GetTranslation() or cm:GetPos()
		local lowerPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftForearm) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftForearm):GetTranslation() or cm:GetPos()
		local handPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftHand) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftHand):GetTranslation() or cm:GetPos()
		local thighPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftThigh) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftThigh):GetTranslation() or cm:GetPos()
		local calfPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftCalf) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftCalf):GetTranslation() or cm:GetPos()
		local footPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftFoot) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_leftFoot):GetTranslation() or cm:GetPos()
		local headPos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_head) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_head):GetTranslation() or cm:GetPos()
		local spinePos = cm:GetBoneMatrix(characterInfo[steamid].bones.b_spine) and cm:GetBoneMatrix(characterInfo[steamid].bones.b_spine):GetTranslation() or cm:GetPos()
		characterInfo[steamid].clavicleLen = claviclePos:Distance(upperPos)
		characterInfo[steamid].upperArmLen = upperPos:Distance(lowerPos)
		characterInfo[steamid].lowerArmLen = lowerPos:Distance(handPos)
		characterInfo[steamid].upperLegLen = thighPos:Distance(calfPos)
		characterInfo[steamid].lowerLegLen = calfPos:Distance(footPos)
		local eyes = cm:GetAttachment(cm:LookupAttachment("eyes"))
		-- 保護: eyes.Posが存在するか確認
		if eyes and eyes.Pos then
			eyes.Pos = eyes.Pos - cm:GetPos()
		end

		if ply == LocalPlayer() then
			if not convarValues or not convarValues.vrmod_characterEyeHeight or not convarValues.vrmod_characterHeadToHmdDist then
				print("VRMod_Character: Warning - convarValues not fully initialized for LocalPlayer.")
				characterInfo[steamid].characterEyeHeight = 65 -- フォールバック値
				characterInfo[steamid].characterHeadToHmdDist = 5 -- フォールバック値
			else
				characterInfo[steamid].characterEyeHeight = convarValues.vrmod_characterEyeHeight
				characterInfo[steamid].characterHeadToHmdDist = convarValues.vrmod_characterHeadToHmdDist
			end

			characterInfo[steamid].spineLen = (cm:GetPos().z + characterInfo[steamid].characterEyeHeight) - spinePos.z
			cm:Remove()
		else
			-- 保護: eyes.Pos.zが存在するか確認
			if eyes and eyes.Pos and eyes.Pos.z > 10 then
				characterInfo[steamid].characterEyeHeight = eyes.Pos.z
				characterInfo[steamid].characterHeadToHmdDist = eyes.Pos.z / 5 - 6.3
			else
				local validHeadPos = headPos - cm:GetPos()
				characterInfo[steamid].characterEyeHeight = validHeadPos.z
				characterInfo[steamid].characterHeadToHmdDist = validHeadPos.z / 5 - 6.3
			end

			characterInfo[steamid].spineLen = (cm:GetPos().z + characterInfo[steamid].characterEyeHeight) - spinePos.z
			cm:Remove()
		end

		return true
	end

	local function BoneCallbackFunc(ply, numbones)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		if not g_VR.net or not g_VR.net[steamid] or not g_VR.net[steamid].lerpedFrame then return end
		if activePlayers[steamid] == nil then return end
		if not characterInfo or not characterInfo[steamid] or not characterInfo[steamid].bones then return end
		local vehicle = ply:GetVehicle()
		if IsValid(vehicle) and vehicle:GetClass() ~= "prop_vehicle_prisoner_pod" then return end
		local bones = characterInfo[steamid].bones
		if not bones or not bones.b_rightHand then return end -- 保護: bonesとb_rightHandの存在を確認
		local righthand_mtx = ply:GetBoneMatrix(bones.b_rightHand)
		if righthand_mtx then
			ply:SetBonePosition(bones.b_rightHand, g_VR.net[steamid].lerpedFrame.righthandPos, g_VR.net[steamid].lerpedFrame.righthandAng + Angle(0, 0, 180))
		end

		if not g_VR.net[steamid].characterAltHead then
			local _, targetAng = LocalToWorld(zeroVec, Angle(-80, 0, 90), zeroVec, g_VR.net[steamid].lerpedFrame.hmdAng)
			if bones.b_head then
				local mtx = ply:GetBoneMatrix(bones.b_head)
				if mtx then
					mtx:SetAngles(targetAng)
					ply:SetBoneMatrix(bones.b_head, mtx)
				end
			end
		end
	end

	local handYaw = 0
	local up = Vector(0, 0, 1)
	local function PreRenderFunc()
		if not g_VR or not g_VR.tracking or not g_VR.tracking.hmd or not g_VR.input then return end
		if not convars or not convars.vrmod_oldcharacteryaw then
			print("VRMod_Character: Warning - convars.vrmod_oldcharacteryaw not available in PreRenderFunc.")

			return
		end

		if convars.vrmod_oldcharacteryaw:GetBool() then
			local unused, relativeAng = WorldToLocal(zeroVec, Angle(0, g_VR.tracking.hmd.ang.yaw, 0), zeroVec, Angle(0, g_VR.characterYaw, 0))
			if relativeAng.yaw > 45 then
				g_VR.characterYaw = g_VR.characterYaw + relativeAng.yaw - 45
			elseif relativeAng.yaw < -45 then
				g_VR.characterYaw = g_VR.characterYaw + relativeAng.yaw + 45
			end

			if g_VR.input.boolean_walk or g_VR.input.boolean_turnleft or g_VR.input.boolean_turnright then
				g_VR.characterYaw = g_VR.tracking.hmd.ang.yaw
			end
		else
			if not g_VR.tracking.pose_lefthand or not g_VR.tracking.pose_righthand then return end
			local leftPos, rightPos, hmdPos, hmdAng = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_righthand.pos, g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
			if WorldToLocal(leftPos, zeroAng, hmdPos, hmdAng).y > WorldToLocal(rightPos, zeroAng, hmdPos, hmdAng).y then
				handYaw = Vector(rightPos.x - leftPos.x, rightPos.y - leftPos.y, 0):Angle().yaw + 90
			end

			local forwardAng = up:Cross(g_VR.tracking.hmd.ang:Right()):Angle()
			local _, tmp = WorldToLocal(zeroVec, Angle(0, handYaw, 0), zeroVec, forwardAng)
			local targetYaw = forwardAng.yaw + math.Clamp(tmp.yaw, -45, 45)
			local _, tmp_yaw_diff = WorldToLocal(zeroVec, Angle(0, targetYaw, 0), zeroVec, Angle(0, g_VR.characterYaw, 0))
			local diff = tmp_yaw_diff.yaw
			g_VR.characterYaw = math.NormalizeAngle(g_VR.characterYaw + diff * 8 * RealFrameTime())
		end
	end

	local prevFrameNumber = 0
	local updatedPlayers = {}
	local function PrePlayerDrawFunc(ply)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		if not activePlayers[steamid] or not g_VR.net or not g_VR.net[steamid] or not g_VR.net[steamid].lerpedFrame then return end
		if not characterInfo or not characterInfo[steamid] or not characterInfo[steamid].bones then return end
		local isFirstPerson = false
		if ply == LocalPlayer() then
			if not g_VR.eyePosLeft or not g_VR.eyePosRight then return end -- 保護
			local ep = EyePos()
			isFirstPerson = (ep == g_VR.eyePosLeft or ep == g_VR.eyePosRight) and ply:GetViewEntity() == ply
		end

		local hide_head_convar = GetConVar("vrmod_hide_head")
		local hideHeadSetting = hide_head_convar and hide_head_convar:GetInt() or 0
		local hideHeadPosX_convar = GetConVar("vrmod_hide_head_pos_x")
		local hideHeadPosY_convar = GetConVar("vrmod_hide_head_pos_y")
		local hideHeadPosZ_convar = GetConVar("vrmod_hide_head_pos_z")
		local hide_head_pos_x_val = hideHeadPosX_convar and hideHeadPosX_convar:GetFloat() or 0
		local hide_head_pos_y_val = hideHeadPosY_convar and hideHeadPosY_convar:GetFloat() or 20
		local hide_head_pos_z_val = hideHeadPosZ_convar and hideHeadPosZ_convar:GetFloat() or 0
		local headBoneID = characterInfo[steamid].bones.b_head
		-- 保護: ボーンマトリックスの存在確認
		if headBoneID and ply:GetBoneMatrix(headBoneID) then
			if isFirstPerson then
				if hideHeadSetting == 1 then
					ply:ManipulateBoneScale(headBoneID, Vector(0.01, 0.01, 0.01))
					ply:ManipulateBonePosition(headBoneID, Vector(hide_head_pos_x_val, hide_head_pos_y_val, hide_head_pos_z_val))
				elseif hideHeadSetting == 0 then
					ply:ManipulateBoneScale(headBoneID, zeroVec)
					ply:ManipulateBonePosition(headBoneID, Vector(0, 0, 0))
				end
			else
				ply:ManipulateBoneScale(headBoneID, Vector(1, 1, 1))
				ply:ManipulateBonePosition(headBoneID, Vector(0, 0, 0))
			end
		end

		characterInfo[steamid].preRenderPos = ply:GetPos()
		local vehicle = ply:GetVehicle()
		if not IsValid(vehicle) then
			characterInfo[steamid].renderPos = g_VR.net[steamid].lerpedFrame.hmdPos + up:Cross(g_VR.net[steamid].lerpedFrame.hmdAng:Right()) * -characterInfo[steamid].characterHeadToHmdDist + Angle(0, g_VR.net[steamid].lerpedFrame.characterYaw, 0):Forward() * -characterInfo[steamid].horizontalCrouchOffset * 0.8
			characterInfo[steamid].renderPos.z = ply:GetPos().z - characterInfo[steamid].verticalCrouchOffset
			ply:SetPos(characterInfo[steamid].renderPos)
			ply:SetRenderAngles(Angle(0, g_VR.net[steamid].lerpedFrame.characterYaw, 0))
		end

		ply:SetupBones()
		if prevFrameNumber ~= FrameNumber() then
			prevFrameNumber = FrameNumber()
			updatedPlayers = {}
		end

		if not updatedPlayers[steamid] then
			UpdateIK(ply)
			updatedPlayers[steamid] = 1
		end

		if IsValid(vehicle) and vehicle:GetClass() ~= "prop_vehicle_prisoner_pod" then return end
		if characterInfo[steamid] and characterInfo[steamid].boneorder and characterInfo[steamid].boneinfo then
			for i = 1, #characterInfo[steamid].boneorder do
				local bone_id_current = characterInfo[steamid].boneorder[i]
				if ply:GetBoneMatrix(bone_id_current) and characterInfo[steamid].boneinfo[bone_id_current] and characterInfo[steamid].boneinfo[bone_id_current].targetMatrix then
					ply:SetBoneMatrix(bone_id_current, characterInfo[steamid].boneinfo[bone_id_current].targetMatrix)
				end
			end
		end
	end

	local function PostPlayerDrawFunc(ply)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		if activePlayers[steamid] == nil then return end
		if not g_VR.net or not g_VR.net[steamid] or not g_VR.net[steamid].lerpedFrame then return end
		if not characterInfo or not characterInfo[steamid] then return end
		local vehicle = ply:GetVehicle()
		if IsValid(vehicle) then return end
		ply:SetPos(characterInfo[steamid].preRenderPos)
	end

	local function CalcMainActivityFunc(ply, vel)
		if not IsValid(ply) or not activePlayers[ply:SteamID()] or ply:InVehicle() then return end
		local idle_act_convar = GetConVar("vrmod_idle_act")
		local jump_act_convar = GetConVar("vrmod_jump_act")
		local run_act_convar = GetConVar("vrmod_run_act")
		local walk_act_convar = GetConVar("vrmod_walk_act")
		local act = idle_act_convar and idle_act_convar:GetString() or "ACT_HL2MP_IDLE"
		if cv_animation_convar and cv_animation_convar:GetBool() then
			if ply.m_bJumping then
				act = jump_act_convar and jump_act_convar:GetString() or "ACT_HL2MP_JUMP_PASSIVE"
				if (CurTime() - (ply.m_flJumpStartTime or 0)) > 0.2 and ply:OnGround() then
					ply.m_bJumping = false
				end
			else
				local len2d = vel:Length2DSqr()
				if len2d > 22500 then
					act = run_act_convar and run_act_convar:GetString() or "ACT_HL2MP_RUN"
				elseif len2d > 0.25 then
					act = walk_act_convar and walk_act_convar:GetString() or "ACT_HL2MP_WALK"
				end
			end
		end
		-- ACT_INVALIDの代わりに-1を使用していたが、GModの定数を使用する方が明確

		return _G[act] or ACT_INVALID, -1
	end

	local function DoAnimationEventFunc(ply, evt, data)
		if not IsValid(ply) or not activePlayers[ply:SteamID()] or ply:InVehicle() then return end
		if evt ~= PLAYERANIMEVENT_JUMP then return ACT_INVALID end
	end

	local function SafeResetBoneManipulation(ply, bones_table)
		if not IsValid(ply) then return end
		if not bones_table or type(bones_table) ~= "table" then return end
		for boneName, boneID in pairs(bones_table) do
			if isnumber(boneID) and ply:GetBoneMatrix(boneID) then
				ply:ManipulateBoneScale(boneID, Vector(1, 1, 1))
				ply:ManipulateBonePosition(boneID, Vector(0, 0, 0))
				ply:ManipulateBoneAngles(boneID, Angle(0, 0, 0))
			end
		end

		if bones_table.b_head and ply:GetBoneMatrix(bones_table.b_head) then
			ply:ManipulateBoneScale(bones_table.b_head, Vector(1, 1, 1))
			ply:ManipulateBonePosition(bones_table.b_head, Vector(0, 0, 0))
		end
	end

	function g_VR.StartCharacterSystem(ply)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		if CharacterInit(ply) == false then return end
		if not g_VR.net or not g_VR.net[steamid] then
			print("[VRMod] Warning: Network data not ready for player " .. steamid)

			return
		end

		if characterInfo and characterInfo[steamid] then
			if characterInfo[steamid].boneCallback then
				ply:RemoveCallback("BuildBonePositions", characterInfo[steamid].boneCallback)
			end

			characterInfo[steamid].boneCallback = ply:AddCallback("BuildBonePositions", BoneCallbackFunc)
			if ply == LocalPlayer() then
				hook.Remove("VRMod_PreRender", "vrutil_hook_calcplyrenderpos")
				hook.Add("VRMod_PreRender", "vrutil_hook_calcplyrenderpos", PreRenderFunc)
			end

			hook.Remove("PrePlayerDraw", "vrutil_hook_preplayerdraw")
			hook.Add("PrePlayerDraw", "vrutil_hook_preplayerdraw", PrePlayerDrawFunc)
			hook.Remove("PostPlayerDraw", "vrutil_hook_postplayerdraw")
			hook.Add("PostPlayerDraw", "vrutil_hook_postplayerdraw", PostPlayerDrawFunc)
			hook.Remove("CalcMainActivity", "vrutil_hook_calcmainactivity")
			hook.Add("CalcMainActivity", "vrutil_hook_calcmainactivity", CalcMainActivityFunc)
			hook.Remove("DoAnimationEvent", "vrutil_hook_doanimationevent")
			hook.Add("DoAnimationEvent", "vrutil_hook_doanimationevent", DoAnimationEventFunc)
			activePlayers[steamid] = true
		end
	end

	function g_VR.StopCharacterSystem(steamid)
		if not steamid or activePlayers[steamid] == nil then return end
		local ply = player.GetBySteamID(steamid)
		if not IsValid(ply) then
			activePlayers[steamid] = nil

			return
		end

		if characterInfo and characterInfo[steamid] then
			SafeResetBoneManipulation(ply, characterInfo[steamid].bones)
			if characterInfo[steamid].boneCallback then
				ply:RemoveCallback("BuildBonePositions", characterInfo[steamid].boneCallback)
				characterInfo[steamid].boneCallback = nil
			end

			if ply == LocalPlayer() then
				hook.Remove("VRMod_PreRender", "vrutil_hook_calcplyrenderpos")
			end
		end

		activePlayers[steamid] = nil
		local otherPlayersActive = false
		for sid, isActive in pairs(activePlayers) do
			if isActive then
				otherPlayersActive = true
				break
			end
		end

		if not otherPlayersActive then
			hook.Remove("PrePlayerDraw", "vrutil_hook_preplayerdraw")
			hook.Remove("PostPlayerDraw", "vrutil_hook_postplayerdraw")
			hook.Remove("CalcMainActivity", "vrutil_hook_calcmainactivity")
			hook.Remove("DoAnimationEvent", "vrutil_hook_doanimationevent")
		end
	end

	hook.Add(
		"VRMod_Start",
		"vrmod_characterstart",
		function(ply)
			if not IsValid(ply) then return end
			g_VR.StartCharacterSystem(ply)
		end
	)

	hook.Add(
		"VRMod_Exit",
		"vrmod_characterstop",
		function(ply, steamid)
			-- ply can be nil here if player disconnected
			g_VR.StopCharacterSystem(steamid)
		end
	)
end

vrmod_character_lua()
concommand.Add(
	"vrmod_lua_reset_character",
	function(ply, cmd, args)
		AddCSLuaFile("vrmodunoffcial/vrmod_character.lua") -- パスは適宜修正
		include("vrmodunoffcial/vrmod_character.lua") -- パスは適宜修正
		vrmod_character_lua()
	end
)
--------[vrmod_character.lua]End--------