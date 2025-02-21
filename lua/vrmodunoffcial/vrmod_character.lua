function vrmod_character_lua()
	-- if CLIENT then
	g_VR = g_VR or {}
	g_VR.characterYaw = 0
	local convars, convarValues = vrmod.GetConvars()
	local cv_animation = CreateClientConVar("vrmod_animation_Enable", "1", true, FCVAR_ARCHIVE)
	if CLIENT then
		-- local charactereyelogic = CreateClientConVar("vrmod_characterlogic_alt", "0", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_idle_act", "ACT_HL2MP_IDLE", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_walk_act", "ACT_HL2MP_WALK", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_run_act", "ACT_HL2MP_WALK", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_jump_act", "ACT_HL2MP_WALK", true, FCVAR_ARCHIVE)
		CreateClientConVar("vrmod_hide_head", "0", true, FCVAR_ARCHIVE, "Hide player's head in VR")
		-- CreateClientConVar("vrmod_hide_body", "0", true, FCVAR_ARCHIVE, "Hide player's body in VR")
		-- CreateClientConVar("vrmod_hide_arms", "0", true, FCVAR_ARCHIVE, "Hide player's arms in VR")
		-- CreateClientConVar("vrmod_hide_legs", "0", true, FCVAR_ARCHIVE, "Hide player's legs in VR")
	end

	g_VR.defaultOpenHandAngles = {Angle(0, 0, 0), Angle(0, -40, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, -40, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, 10, 0), Angle(0, 0, 0),} --left hand --finger 0 --finger 1 --finger 2 --finger 3 --finger 4 --right hand
	g_VR.defaultClosedHandAngles = {Angle(30, 0, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, -50, -10), Angle(0, -90, 0), Angle(0, -70, 0), Angle(0, -35. - 8, 0), Angle(0, -80, 0), Angle(0, -70, 0), Angle(0, -26.5, 4.8), Angle(0, -70, 0), Angle(0, -70, 0), Angle(0, -30, 12.7), Angle(0, -70, 0), Angle(0, -70, 0), Angle(-30, 0, 0), Angle(0, 0, 0), Angle(0, 30, 0), Angle(0, -50, 10), Angle(0, -90, 0), Angle(0, -70, 0), Angle(0, -35.8, 0), Angle(0, -80, 0), Angle(0, -70, 0), Angle(0, -26.5, -4.8), Angle(0, -70, 0), Angle(0, -70, 0), Angle(0, -30, -12.7), Angle(0, -70, 0), Angle(0, -70, 0),} --
	g_VR.zeroHandAngles = {Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0),}
	g_VR.openHandAngles = g_VR.defaultOpenHandAngles
	g_VR.closedHandAngles = g_VR.defaultClosedHandAngles
	----------------------------------------------------------------------------------------------------------------------------------------------------
	local characterInfo = {}
	local activePlayers = {}
	local zeroVec, zeroAng = Vector(), Angle()
	local function RecursiveBoneTable2(ent, parentbone, infotab, ordertab, notfirst)
		local bones = notfirst and ent:GetChildBones(parentbone) or {parentbone}
		for k, v in pairs(bones) do
			local n = ent:GetBoneName(v)
			local boneparent = ent:GetBoneParent(v)
			local parentmat = ent:GetBoneMatrix(boneparent) --getboneposition doesnt work for all bones! but matrix seems to
			local childmat = ent:GetBoneMatrix(v)
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
		local steamid = ply:SteamID()
		local net = g_VR.net[steamid]
		local charinfo = characterInfo[steamid]
		local boneinfo = charinfo.boneinfo
		local bones = charinfo.bones
		local frame = net.lerpedFrame
		local inVehicle = ply:InVehicle()
		local plyAng = inVehicle and ply:GetVehicle():GetAngles() or Angle(0, frame.characterYaw, 0)
		if inVehicle then
			_, plyAng = LocalToWorld(zeroVec, Angle(0, 90, 0), zeroVec, plyAng)
		end

		--alt head
		if net.characterAltHead then
			local tmp1, tmp2 = WorldToLocal(zeroVec, frame.hmdAng, zeroVec, Angle(0, frame.characterYaw, 0))
			ply:ManipulateBoneAngles(bones.b_head, Angle(-tmp2.roll, -tmp2.pitch, tmp2.yaw))
		end

		--****************** CROUCHING ******************
		if not inVehicle then
			local headHeight = frame.hmdPos.z + (frame.hmdAng:Forward() * -3).z
			local cutAmount = math.Clamp(charinfo.preRenderPos.z + charinfo.characterEyeHeight - headHeight, 0, 40)
			--spine
			local spineTargetLen = charinfo.spineLen - cutAmount * 0.5
			local a1 = math.acos(spineTargetLen / charinfo.spineLen)
			charinfo.horizontalCrouchOffset = math.sin(a1) * charinfo.spineLen
			ply:ManipulateBoneAngles(bones.b_spine, Angle(0, math.deg(a1), 0))
			--legs
			charinfo.verticalCrouchOffset = cutAmount * 0.5
			local legTargetLen = charinfo.upperLegLen + charinfo.lowerLegLen - charinfo.verticalCrouchOffset * 0.8 --actually cut slightly less or it looks like the legs float with the player anim
			local a1 = math.deg(math.acos((charinfo.upperLegLen * charinfo.upperLegLen + legTargetLen * legTargetLen - charinfo.lowerLegLen * charinfo.lowerLegLen) / (2 * charinfo.upperLegLen * legTargetLen)))
			local a23 = 180 - a1 - math.deg(math.acos((charinfo.lowerLegLen * charinfo.lowerLegLen + legTargetLen * legTargetLen - charinfo.upperLegLen * charinfo.upperLegLen) / (2 * charinfo.lowerLegLen * legTargetLen)))
			if a1 ~= a1 or a23 ~= a23 then
				a1 = 0
				a23 = 180
			end

			ply:ManipulateBoneAngles(bones.b_leftCalf, Angle(0, -(a23 - 180), 0))
			ply:ManipulateBoneAngles(bones.b_leftThigh, Angle(0, -a1, 0))
			ply:ManipulateBoneAngles(bones.b_rightCalf, Angle(0, -(a23 - 180), 0))
			ply:ManipulateBoneAngles(bones.b_rightThigh, Angle(0, -a1, 0))
			ply:ManipulateBoneAngles(bones.b_leftFoot, Angle(0, -a1, 0))
			ply:ManipulateBoneAngles(bones.b_rightFoot, Angle(0, -a1, 0))
		else
			ply:ManipulateBoneAngles(bones.b_spine, Angle(0, 0, 0))
			ply:ManipulateBoneAngles(bones.b_leftCalf, Angle(0, 0, 0))
			ply:ManipulateBoneAngles(bones.b_leftThigh, Angle(0, 0, 0))
			ply:ManipulateBoneAngles(bones.b_rightCalf, Angle(0, 0, 0))
			ply:ManipulateBoneAngles(bones.b_rightThigh, Angle(0, 0, 0))
			ply:ManipulateBoneAngles(bones.b_leftFoot, Angle(0, 0, 0))
			ply:ManipulateBoneAngles(bones.b_rightFoot, Angle(0, 0, 0))
		end

		--****************** LEFT ARM ******************
		local L_TargetPos = frame.lefthandPos
		local L_TargetAng = frame.lefthandAng
		local mtx = ply:GetBoneMatrix(bones.b_leftClavicle)
		local L_ClaviclePos = mtx and mtx:GetTranslation() or Vector()
		charinfo.L_ClaviclePos = L_ClaviclePos
		--Calculate LEFT clavicle target angle
		local tmp1 = L_ClaviclePos + plyAng:Right() * -charinfo.clavicleLen --neutral shoulder position
		local tmp2 = tmp1 + (L_TargetPos - tmp1) * 0.15 --desired shoulder position
		local L_ClavicleTargetAng
		if not inVehicle then
			L_ClavicleTargetAng = (tmp2 - L_ClaviclePos):Angle()
		else
			_, L_ClavicleTargetAng = LocalToWorld(zeroVec, WorldToLocal(tmp2 - L_ClaviclePos, zeroAng, zeroVec, plyAng):Angle(), zeroVec, plyAng)
		end

		L_ClavicleTargetAng:RotateAroundAxis(L_ClavicleTargetAng:Forward(), 90)
		--
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

		--Calculate LEFT upperarm target angle
		local L_UpperarmTargetAng = Angle(L_TargetVecAng.pitch, L_TargetVecAng.yaw, L_TargetVecAng.roll) --copy to avoid weirdness
		local tmp
		if not inVehicle then
			tmp = Angle(L_TargetVecAng.pitch, frame.characterYaw, -90)
		else
			_, tmp = LocalToWorld(Vector(), Angle(L_TargetVecAngLocal.pitch, 0, -90), zeroVec, plyAng)
		end

		local tpos, tang = WorldToLocal(zeroVec, tmp, zeroVec, L_TargetVecAng)
		L_UpperarmTargetAng:RotateAroundAxis(L_UpperarmTargetAng:Forward(), tang.roll)
		local a1 = math.deg(math.acos((charinfo.upperArmLen * charinfo.upperArmLen + L_TargetVecLen * L_TargetVecLen - charinfo.lowerArmLen * charinfo.lowerArmLen) / (2 * charinfo.upperArmLen * L_TargetVecLen)))
		if a1 == a1 then
			L_UpperarmTargetAng:RotateAroundAxis(L_UpperarmTargetAng:Up(), a1)
		end

		local test
		if not inVehicle then
			test = ((L_TargetPos.z - L_UpperarmPos.z) + 20) * 1.5
		else
			test = ((L_TargetPos - L_UpperarmPos):Dot(plyAng:Up()) + 20) * 1.5
		end

		if test < 0 then
			test = 0
		end

		L_UpperarmTargetAng:RotateAroundAxis(L_TargetVec:GetNormalized(), 30 + test)
		--Calculate LEFT forearm target angle
		local L_ForearmTargetAng = Angle(L_UpperarmTargetAng.pitch, L_UpperarmTargetAng.yaw, L_UpperarmTargetAng.roll)
		local a23 = 180 - a1 - math.deg(math.acos((charinfo.lowerArmLen * charinfo.lowerArmLen + L_TargetVecLen * L_TargetVecLen - charinfo.upperArmLen * charinfo.upperArmLen) / (2 * charinfo.lowerArmLen * L_TargetVecLen)))
		if a23 == a23 then
			L_ForearmTargetAng:RotateAroundAxis(L_ForearmTargetAng:Up(), 180 + a23)
		end

		--Calculate LEFT wrist and ulna angle
		local tmp = Angle(L_TargetAng.pitch, L_TargetAng.yaw, L_TargetAng.roll - 90)
		local tpos, tang = WorldToLocal(zeroVec, tmp, zeroVec, L_ForearmTargetAng)
		local L_WristTargetAng = Angle(L_ForearmTargetAng.pitch, L_ForearmTargetAng.yaw, L_ForearmTargetAng.roll)
		L_WristTargetAng:RotateAroundAxis(L_WristTargetAng:Forward(), tang.roll)
		local L_UlnaTargetAng = LerpAngle(0.5, L_ForearmTargetAng, L_WristTargetAng)
		--****************** RIGHT ARM ******************
		local R_TargetPos = frame.righthandPos
		local R_TargetAng = frame.righthandAng
		local mtx = ply:GetBoneMatrix(bones.b_rightClavicle)
		local R_ClaviclePos = mtx and mtx:GetTranslation() or Vector()
		charinfo.R_ClaviclePos = R_ClaviclePos
		--Calculate RIGHT clavicle target angle
		local tmp1 = R_ClaviclePos + plyAng:Right() * charinfo.clavicleLen
		local tmp2 = tmp1 + (R_TargetPos - tmp1) * 0.15
		local R_ClavicleTargetAng
		if not inVehicle then
			R_ClavicleTargetAng = (tmp2 - R_ClaviclePos):Angle()
		else
			_, R_ClavicleTargetAng = LocalToWorld(Vector(), WorldToLocal(tmp2 - R_ClaviclePos, zeroAng, zeroVec, plyAng):Angle(), zeroVec, plyAng)
		end

		R_ClavicleTargetAng:RotateAroundAxis(R_ClavicleTargetAng:Forward(), 90)
		--
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

		--Calculate RIGHT upperarm target angle
		local R_UpperarmTargetAng = Angle(R_TargetVecAng.pitch, R_TargetVecAng.yaw, R_TargetVecAng.roll)
		R_UpperarmTargetAng:RotateAroundAxis(R_TargetVec, 180)
		local tmp
		if not inVehicle then
			tmp = Angle(R_TargetVecAng.pitch, frame.characterYaw, 90)
		else
			_, tmp = LocalToWorld(Vector(), Angle(R_TargetVecAngLocal.pitch, 0, 90), zeroVec, plyAng)
		end

		local tpos, tang = WorldToLocal(zeroVec, tmp, zeroVec, R_TargetVecAng)
		R_UpperarmTargetAng:RotateAroundAxis(R_UpperarmTargetAng:Forward(), tang.roll)
		local a1 = math.deg(math.acos((charinfo.upperArmLen * charinfo.upperArmLen + R_TargetVecLen * R_TargetVecLen - charinfo.lowerArmLen * charinfo.lowerArmLen) / (2 * charinfo.upperArmLen * R_TargetVecLen)))
		if a1 == a1 then
			R_UpperarmTargetAng:RotateAroundAxis(R_UpperarmTargetAng:Up(), a1)
		end

		local test
		if not inVehicle then
			test = ((R_TargetPos.z - R_UpperarmPos.z) + 20) * 1.5
		else
			test = ((R_TargetPos - R_UpperarmPos):Dot(plyAng:Up()) + 20) * 1.5
		end

		if test < 0 then
			test = 0
		end

		R_UpperarmTargetAng:RotateAroundAxis(R_TargetVec:GetNormalized(), -(30 + test))
		--Calculate RIGHT forearm target angle
		local R_ForearmTargetAng = Angle(R_UpperarmTargetAng.pitch, R_UpperarmTargetAng.yaw, R_UpperarmTargetAng.roll)
		local a23 = 180 - a1 - math.deg(math.acos((charinfo.lowerArmLen * charinfo.lowerArmLen + R_TargetVecLen * R_TargetVecLen - charinfo.upperArmLen * charinfo.upperArmLen) / (2 * charinfo.lowerArmLen * R_TargetVecLen)))
		if a23 == a23 then
			R_ForearmTargetAng:RotateAroundAxis(R_ForearmTargetAng:Up(), 180 + a23)
		end

		--Calculate RIGHT wrist and ulna angle
		local tmp = Angle(R_TargetAng.pitch, R_TargetAng.yaw, R_TargetAng.roll - 90)
		local tpos, tang = WorldToLocal(zeroVec, tmp, zeroVec, R_ForearmTargetAng)
		local R_WristTargetAng = Angle(R_ForearmTargetAng.pitch, R_ForearmTargetAng.yaw, R_ForearmTargetAng.roll)
		R_WristTargetAng:RotateAroundAxis(R_WristTargetAng:Forward(), tang.roll)
		local R_UlnaTargetAng = LerpAngle(0.5, R_ForearmTargetAng, R_WristTargetAng)
		--set absolute override angles for the relevant bones
		boneinfo[bones.b_leftClavicle].overrideAng = L_ClavicleTargetAng
		boneinfo[bones.b_leftUpperarm].overrideAng = L_UpperarmTargetAng
		boneinfo[bones.b_leftHand].overrideAng = L_TargetAng
		boneinfo[bones.b_rightClavicle].overrideAng = R_ClavicleTargetAng
		boneinfo[bones.b_rightUpperarm].overrideAng = R_UpperarmTargetAng
		boneinfo[bones.b_rightHand].overrideAng = R_TargetAng + Angle(0, 0, 180)
		if bones.b_leftWrist and boneinfo[bones.b_leftWrist] and bones.b_leftUlna and boneinfo[bones.b_leftUlna] then
			boneinfo[bones.b_leftForearm].overrideAng = L_ForearmTargetAng
			boneinfo[bones.b_leftWrist].overrideAng = L_WristTargetAng
			boneinfo[bones.b_leftUlna].overrideAng = L_UlnaTargetAng
			boneinfo[bones.b_rightForearm].overrideAng = R_ForearmTargetAng
			boneinfo[bones.b_rightWrist].overrideAng = R_WristTargetAng
			boneinfo[bones.b_rightUlna].overrideAng = R_UlnaTargetAng
		else
			boneinfo[bones.b_leftForearm].overrideAng = L_UlnaTargetAng
			boneinfo[bones.b_rightForearm].overrideAng = R_UlnaTargetAng
		end

		--set finger offset angles
		for k, v in pairs(bones.fingers) do
			if not boneinfo[v] then continue end
			boneinfo[v].offsetAng = LerpAngle(frame["finger" .. math.floor((k - 1) / 3 + 1)], g_VR.openHandAngles[k], g_VR.closedHandAngles[k])
		end

		--calculate target matrices
		for i = 1, #characterInfo[steamid].boneorder do
			local bone = characterInfo[steamid].boneorder[i]
			local parent = characterInfo[steamid].boneinfo[bone].parent
			local wpos, wang
			if characterInfo[steamid].boneinfo[bone].name == "ValveBiped.Bip01_L_Clavicle" then
				wpos = L_ClaviclePos
			elseif characterInfo[steamid].boneinfo[bone].name == "ValveBiped.Bip01_R_Clavicle" then
				wpos = R_ClaviclePos
			else
				local parentPos, parentAng = characterInfo[steamid].boneinfo[parent].pos, characterInfo[steamid].boneinfo[parent].ang
				wpos, wang = LocalToWorld(characterInfo[steamid].boneinfo[bone].relativePos, characterInfo[steamid].boneinfo[bone].relativeAng + characterInfo[steamid].boneinfo[bone].offsetAng, parentPos, parentAng)
			end

			if characterInfo[steamid].boneinfo[bone].overrideAng ~= nil then
				wang = characterInfo[steamid].boneinfo[bone].overrideAng
			end

			local mat = Matrix()
			mat:Translate(wpos)
			mat:Rotate(wang)
			characterInfo[steamid].boneinfo[bone].targetMatrix = mat
			characterInfo[steamid].boneinfo[bone].pos = wpos
			characterInfo[steamid].boneinfo[bone].ang = wang
		end
	end

	local function CharacterInit(ply)
		local steamid = ply:SteamID()
		local pmname = ply.vrmod_pm or ply:GetModel()
		if characterInfo[steamid] and characterInfo[steamid].modelName == pmname then return end
		if ply == LocalPlayer() then
			timer.Create(
				"vrutil_timer_validatefingertracking",
				0.1,
				0,
				function()
					if g_VR.tracking.pose_lefthand and g_VR.tracking.pose_righthand and g_VR.tracking.pose_lefthand.simulatedPos == nil and g_VR.tracking.pose_righthand.simulatedPos == nil then
						timer.Remove("vrutil_timer_validatefingertracking")
						for i = 1, 2 do
							for k, v in pairs(i == 1 and g_VR.input.skeleton_lefthand.fingerCurls or g_VR.input.skeleton_righthand.fingerCurls) do
								if v < 0 or v > 1 or (k == 3 and v == 0.75) then
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
		}

		ply:SetLOD(0)
		local cm = ClientsideModel(pmname)
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

		for k, v in pairs(boneNames) do
			local bone = cm:LookupBone(v) or -1
			characterInfo[steamid].bones[k] = bone
			if bone == -1 and not string.find(k, "Wrist") and not string.find(k, "Ulna") then
				if ply == LocalPlayer() then
					g_VR.errorText = "Incompatible player model. Missing bone " .. v
				end

				cm:Remove()
				g_VR.StopCharacterSystem(steamid)
				print("VRMod: CharacterInit failed for " .. steamid)

				return false
			end
		end

		characterInfo[steamid].modelName = pmname
		local claviclePos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftClavicle)
		local upperPos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftUpperarm)
		local lowerPos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftForearm)
		local handPos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftHand)
		local thighPos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftThigh)
		local calfPos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftCalf)
		local footPos = cm:GetBonePosition(characterInfo[steamid].bones.b_leftFoot)
		local headPos = cm:GetBonePosition(characterInfo[steamid].bones.b_head)
		local spinePos = cm:GetBonePosition(characterInfo[steamid].bones.b_spine)
		-- local neckpos = cm:GetBonePosition(characterInfo[steamid].bones.b_neck)
		characterInfo[steamid].clavicleLen = claviclePos:Distance(upperPos)
		characterInfo[steamid].upperArmLen = upperPos:Distance(lowerPos)
		characterInfo[steamid].lowerArmLen = lowerPos:Distance(handPos)
		characterInfo[steamid].upperLegLen = thighPos:Distance(calfPos)
		characterInfo[steamid].lowerLegLen = calfPos:Distance(footPos)
		--spineLen is set after eye height
		--
		local eyes = cm:GetAttachment(cm:LookupAttachment("eyes"))
		if eyes then
			eyes.Pos = eyes.Pos - cm:GetPos()
		end

		--"VRmodを使用する自分自身に適用するように変更"
		if ply == LocalPlayer() then
			characterInfo[steamid].characterEyeHeight = convarValues.vrmod_characterEyeHeight
			characterInfo[steamid].characterHeadToHmdDist = convarValues.vrmod_characterHeadToHmdDist
			characterInfo[steamid].spineLen = (cm:GetPos().z + characterInfo[steamid].characterEyeHeight) - spinePos.z
			cm:Remove()
		else
			--"自分以外のVRModユーザー行うように変更"
			if eyes and eyes.Pos.z > 10 then
				characterInfo[steamid].characterEyeHeight = eyes.Pos.z
				characterInfo[steamid].characterHeadToHmdDist = eyes.Pos.z / 5 - 6.3
			else
				headPos = headPos - cm:GetPos()
				characterInfo[steamid].characterEyeHeight = headPos.z
				characterInfo[steamid].characterHeadToHmdDist = headPos.z / 5 - 6.3
			end

			characterInfo[steamid].spineLen = (cm:GetPos().z + characterInfo[steamid].characterEyeHeight) - spinePos.z
			cm:Remove()
		end
		-- local seatset = convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z)
	end

	------------------------------------------------------------------------
	local function BoneCallbackFunc(ply, numbones)
		local steamid = ply:SteamID()
		if not g_VR.net[steamid] or not g_VR.net[steamid].lerpedFrame then return end
		if activePlayers[steamid] == nil then return end
		if g_VR.net[steamid].lerpedFrame == nil then return end
		if ply:InVehicle() and ply:GetVehicle():GetClass() ~= "prop_vehicle_prisoner_pod" then return end
		if ply:GetBoneMatrix(characterInfo[steamid].bones.b_rightHand) then
			ply:SetBonePosition(characterInfo[steamid].bones.b_rightHand, g_VR.net[steamid].lerpedFrame.righthandPos, g_VR.net[steamid].lerpedFrame.righthandAng + Angle(0, 0, 180))
		end

		if not g_VR.net[steamid].characterAltHead then
			local _, targetAng = LocalToWorld(zeroVec, Angle(-80, 0, 90), zeroVec, g_VR.net[steamid].lerpedFrame.hmdAng)
			local mtx = ply:GetBoneMatrix(characterInfo[steamid].bones.b_head)
			if mtx then
				mtx:SetAngles(targetAng)
				ply:SetBoneMatrix(characterInfo[steamid].bones.b_head, mtx)
			end
		end
	end

	-------------------------------------------------------------
	local handYaw = 0
	local up = Vector(0, 0, 1)
	local function PreRenderFunc()
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
			local leftPos, rightPos, hmdPos, hmdAng = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_righthand.pos, g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
			--update handYaw if hands are not crossed
			if WorldToLocal(leftPos, zeroAng, hmdPos, hmdAng).y > WorldToLocal(rightPos, zeroAng, hmdPos, hmdAng).y then
				handYaw = Vector(rightPos.x - leftPos.x, rightPos.y - leftPos.y, 0):Angle().yaw + 90
			end

			local forwardAng = up:Cross(g_VR.tracking.hmd.ang:Right()):Angle()
			local _, tmp = WorldToLocal(zeroVec, Angle(0, handYaw, 0), zeroVec, forwardAng)
			local targetYaw = forwardAng.yaw + math.Clamp(tmp.yaw, -45, 45)
			local _, tmp = WorldToLocal(zeroVec, Angle(0, targetYaw, 0), zeroVec, Angle(0, g_VR.characterYaw, 0))
			local diff = tmp.yaw
			g_VR.characterYaw = math.NormalizeAngle(g_VR.characterYaw + diff * 8 * RealFrameTime())
		end
	end

	-------------------------------------------------------------
	local prevFrameNumber = 0
	local updatedPlayers = {}
	-- 再帰的にボーンとその子ボーンを非表示にする関数
	local function HideBoneAndChildren(ply, boneID, hide)
		local zeroVec = Vector(0, 0, 0)
		local normalVec = Vector(1, 1, 1)
		-- 現在のボーンを非表示にする
		ply:ManipulateBoneScale(boneID, hide and zeroVec or normalVec, false)
		-- 子ボーンを探索
		local childrenBones = ply:GetChildBones(boneID)
		for _, childBoneID in ipairs(childrenBones) do
			HideBoneAndChildren(ply, childBoneID, hide)
		end
	end

	local function PrePlayerDrawFunc(ply)
		local steamid = ply:SteamID()
		if activePlayers[steamid] == nil then return end
		if not g_VR.net[steamid].lerpedFrame or g_VR.net[steamid].lerpedFrame == nil then return end
		--hide head in first person
		if ply == LocalPlayer() then
			local ep = EyePos()
			local hide = (ep == g_VR.eyePosLeft or ep == g_VR.eyePosRight) and ply:GetViewEntity() == ply
			if characterInfo[steamid] and characterInfo[steamid].bones and characterInfo[steamid].bones.b_head then
				local headBoneID = characterInfo[steamid].bones.b_head
				HideBoneAndChildren(ply, headBoneID, hide)
			end

			local isFirstPerson = (ep == g_VR.eyePosLeft or ep == g_VR.eyePosRight) and ply:GetViewEntity() == ply
			if characterInfo[steamid] and characterInfo[steamid].bones then
				local bones = characterInfo[steamid].bones
				local function SetBoneVisibility(boneID, hide)
					if boneID then
						ply:ManipulateBonePosition(boneID, hide and Vector(-150, 0, 0) or Vector(1, 1, 1), false)
					end
				end

				if g_VR.active and GetConVar("vrmod_hide_head"):GetBool() and isFirstPerson then
					HideBoneAndChildren(ply, characterInfo[steamid].bones.b_head, true)
					SetBoneVisibility(bones.b_head, true)
				else
					HideBoneAndChildren(ply, characterInfo[steamid].bones.b_head, false)
					SetBoneVisibility(bones.b_head, false)
				end
				-- if GetConVar("vrmod_hide_body"):GetBool() and isFirstPerson then
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightWrist, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftWrist, true)
				-- else
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightWrist, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftWrist, false)
				-- end
				-- if GetConVar("vrmod_hide_arms"):GetBool() and isFirstPerson then
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftUpperarm, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightUpperarm, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftForearm, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightForearm, true)
				-- else
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftUpperarm, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightUpperarm, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftForearm, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightForearm, false)
				-- end
				-- if GetConVar("vrmod_hide_legs"):GetBool() and isFirstPerson then
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftThigh, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightThigh, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftCalf, true)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightCalf, true)
				-- else
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftThigh, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightThigh, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_leftCalf, false)
				-- 	HideBoneAndChildren(ply, characterInfo[steamid].bones.b_rightCalf, false)
				-- end
			end
		end

		characterInfo[steamid].preRenderPos = ply:GetPos()
		if not ply:InVehicle() then
			characterInfo[steamid].renderPos = g_VR.net[steamid].lerpedFrame.hmdPos + up:Cross(g_VR.net[steamid].lerpedFrame.hmdAng:Right()) * -characterInfo[steamid].characterHeadToHmdDist + Angle(0, g_VR.net[steamid].lerpedFrame.characterYaw, 0):Forward() * -characterInfo[steamid].horizontalCrouchOffset * 0.8
			characterInfo[steamid].renderPos.z = ply:GetPos().z - characterInfo[steamid].verticalCrouchOffset
			ply:SetPos(characterInfo[steamid].renderPos)
			ply:SetRenderAngles(Angle(0, g_VR.net[steamid].lerpedFrame.characterYaw, 0))
		end

		ply:SetupBones()
		--update ik once per frame per player
		if prevFrameNumber ~= FrameNumber() then
			prevFrameNumber = FrameNumber()
			updatedPlayers = {}
		end

		if not updatedPlayers[steamid] then
			UpdateIK(ply)
			-- ここに新しいコードを追加
			if net.characterAltHead then
				-- より安定した頭部の角度計算
				local headOffset = WorldToLocal(zeroVec, frame.hmdAng, zeroVec, Angle(0, frame.characterYaw, 0))
				local clampedAngle = Angle(math.Clamp(headOffset.pitch, -80, 80), math.Clamp(headOffset.yaw, -120, 120), math.Clamp(headOffset.roll, -45, 45)) -- 頭部の上下の動きを制限 -- 左右の回転を制限 -- 首の傾きを制限
				ply:ManipulateBoneAngles(bones.b_head, clampedAngle)
			end

			updatedPlayers[steamid] = 1
		end

		--
		if ply:InVehicle() and ply:GetVehicle():GetClass() ~= "prop_vehicle_prisoner_pod" then return end
		--manipulate arms
		for i = 1, #characterInfo[steamid].boneorder do
			local bone = characterInfo[steamid].boneorder[i]
			--prevent unwritable bone errors (usually happens when someone opens pac editor while in vr and pac stuff in general)
			if ply:GetBoneMatrix(bone) then
				ply:SetBoneMatrix(bone, characterInfo[steamid].boneinfo[bone].targetMatrix)
			end
		end
	end

	-------------------------------------------------------------
	local function PostPlayerDrawFunc(ply)
		local steamid = ply:SteamID()
		if activePlayers[steamid] == nil then return end
		if g_VR.net[steamid] == nil then return end
		if g_VR.net[steamid].lerpedFrame == nil then return end
		if ply:InVehicle() then return end
		ply:SetPos(characterInfo[steamid].preRenderPos)
	end

	-------------------------------------------------------------
	-- CalcMainActivityFuncを修正
	local function CalcMainActivityFunc(ply, vel)
		if not activePlayers[ply:SteamID()] or ply:InVehicle() then return end
		local act = GetConVar("vrmod_idle_act"):GetString()
		if cv_animation:GetBool() then
			if ply.m_bJumping then
				act = GetConVar("vrmod_jump_act"):GetString()
				if (CurTime() - ply.m_flJumpStartTime) > 0.2 and ply:OnGround() then
					ply.m_bJumping = false
				end
			else
				local len2d = vel:Length2DSqr()
				if len2d > 22500 then
					act = GetConVar("vrmod_run_act"):GetString()
				elseif len2d > 0.25 then
					act = GetConVar("vrmod_walk_act"):GetString()
				end
			end
		end

		return _G[act] or -1, -1
	end

	-------------------------------------------------------------
	local function DoAnimationEventFunc(ply, evt, data)
		if not activePlayers[ply:SteamID()] or ply:InVehicle() then return end
		if evt ~= PLAYERANIMEVENT_JUMP then return ACT_INVALID end
	end

	-------------------------------------------------------------
	function g_VR.StartCharacterSystem(ply)
		local steamid = ply:SteamID()
		-- 既存のボーン状態を保存
		if characterInfo[steamid] and characterInfo[steamid].bones then
			for _, boneID in pairs(characterInfo[steamid].bones) do
				if isnumber(boneID) then
					SaveBoneState(ply, boneID)
				end
			end
		end

		return StartCharacterSystem(ply)
	end

	-- VR終了時の処理を追加
	hook.Add(
		"VRMod_Exit",
		"vrmod_cleanup_bones",
		function(ply)
			if not IsValid(ply) then return end
			local steamid = ply:SteamID()
			-- ボーン状態を復元
			if characterInfo[steamid] and characterInfo[steamid].bones then
				for _, boneID in pairs(characterInfo[steamid].bones) do
					if isnumber(boneID) then
						RestoreBoneState(ply, boneID)
					end
				end
			end

			-- システムのクリーンアップ
			g_VR.StopCharacterSystem(steamid)
			characterInfo[steamid] = nil
			boneStates[steamid] = nil
		end
	)

	-- ボーンコールバック関数を改善 
	local function BoneCallendFunc(ply, numbones)
		local steamid = ply:SteamID()
		if not g_VR.net[steamid] or not g_VR.net[steamid].lerpedFrame then return end
		-- ボーン操作前の状態チェック
		if not characterInfo[steamid] or not characterInfo[steamid].bones then return end
		-- 頭部ボーンの位置を正しく調整
		if characterInfo[steamid].bones.b_head then
			local headBone = characterInfo[steamid].bones.b_head
			if g_VR.net[steamid].characterAltHead then
				-- VRモード時の頭部位置
				local tmp1, tmp2 = WorldToLocal(zeroVec, g_VR.net[steamid].lerpedFrame.hmdAng, zeroVec, Angle(0, g_VR.net[steamid].lerpedFrame.characterYaw, 0))
				ply:ManipulateBoneAngles(headBone, Angle(-tmp2.roll, -tmp2.pitch, tmp2.yaw))
			else
				-- 通常位置に復元
				RestoreBoneState(ply, headBone)
			end
		end
	end

	function g_VR.StartCharacterSystem(ply)
		-- g_VR.netの存在確認を追加
		local steamid = ply:SteamID()
		if not g_VR.net then
			g_VR.net = {}
		end

		-- ネットワークデータの存在確認を追加
		if not g_VR.net[steamid] then
			print("[VRMod] Warning: Network data not ready for player " .. steamid)

			return
		end

		-- CharacterInitが失敗した場合のチェックを追加
		if CharacterInit(ply) == false then return end
		-- 既存のコードを安全に実行
		if characterInfo[steamid] then
			characterInfo[steamid].boneCallback = ply:AddCallback("BuildBonePositions", BoneCallendFunc)
			if ply == LocalPlayer() then
				hook.Add("VRMod_PreRender", "vrutil_hook_calcplyrenderpos", PreRenderFunc)
			end

			hook.Add("PrePlayerDraw", "vrutil_hook_preplayerdraw", PrePlayerDrawFunc)
			hook.Add("PostPlayerDraw", "vrutil_hook_postplayerdraw", PostPlayerDrawFunc)
			hook.Add("CalcMainActivity", "vrutil_hook_calcmainactivity", CalcMainActivityFunc)
			hook.Add("DoAnimationEvent", "vrutil_hook_doanimationevent", DoAnimationEventFunc)
			activePlayers[steamid] = true
		end
	end

	-- UpdateHeadVisibility 関数を追加
	local function UpdateHeadVisibility(ply, hide)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		local info = characterInfo[steamid]
		if not info or not info.bones then return end
		local headBone = info.bones.b_head
		if not headBone then return end
		-- 現在の状態を保存
		info.previousHeadState = info.previousHeadState or {
			pos = Vector(0, 0, 0),
			scale = Vector(1, 1, 1)
		}

		if hide then
			ply:ManipulateBonePosition(headBone, Vector(-150, 0, 0))
		else
			ply:ManipulateBonePosition(headBone, info.previousHeadState.pos)
			ply:ManipulateBoneScale(headBone, info.previousHeadState.scale)
		end
	end

	-- g_VR.StopCharacterSystem 関数を置き換え
	function g_VR.StopCharacterSystem(steamid)
		if not activePlayers[steamid] then return end
		local ply = player.GetBySteamID(steamid)
		if not IsValid(ply) then return end
		if characterInfo[steamid] then
			-- ボーンマニピュレーションのクリーンアップ
			for k, v in pairs(characterInfo[steamid].bones) do
				if not isnumber(v) then continue end
				ply:ManipulateBoneAngles(v, Angle(0, 0, 0))
			end

			-- コールバックの削除
			if characterInfo[steamid].boneCallback then
				ply:RemoveCallback("BuildBonePositions", characterInfo[steamid].boneCallback)
			end

			-- ローカルプレイヤー固有の処理
			if ply == LocalPlayer() then
				hook.Remove("VRMod_PreRender", "vrutil_hook_calcplyrenderpos")
				SafeResetBoneManipulation(ply, characterInfo[steamid].bones)
			end
		end

		-- グローバルフックの削除
		if table.Count(activePlayers) <= 1 then
			hook.Remove("PrePlayerDraw", "vrutil_hook_preplayerdraw")
			hook.Remove("PostPlayerDraw", "vrutil_hook_postplayerdraw")
			hook.Remove("CalcMainActivity", "vrutil_hook_calcmainactivity")
			hook.Remove("DoAnimationEvent", "vrutil_hook_doanimationevent")
		end

		activePlayers[steamid] = nil
	end

	-- ボーンマニピュレーションの安全なリセット
	function SafeResetBoneManipulation(ply, bones)
		if not IsValid(ply) then return end
		for boneName, boneID in pairs(bones) do
			if isnumber(boneID) then
				ply:ManipulateBoneScale(boneID, Vector(1, 1, 1))
				ply:ManipulateBonePosition(boneID, Vector(0, 0, 0))
				ply:ManipulateBoneAngles(boneID, Angle(0, 0, 0))
			end
		end
	end

	hook.Add(
		"VRMod_Start",
		"vrmod_characterstart",
		function(ply)
			g_VR.StartCharacterSystem(ply)
			timer.Simple(
				2,
				function()
					RunConsoleCommand("vrmod_character_stop")
				end
			)

			timer.Simple(
				2,
				function()
					RunConsoleCommand("vrmod_character_start")
				end
			)
		end
	)

	-- VRMod_Exit フックを更新
	hook.Add(
		"VRMod_Exit",
		"vrmod_cleanup_bones",
		function(ply)
			-- 全ボーンの位置をリセット
			for i = 0, ply:GetBoneCount() - 1 do
				ply:ManipulateBonePosition(i, Vector(0, 0, 0))
				ply:ManipulateBoneScale(i, Vector(1, 1, 1))
				ply:ManipulateBoneAngles(i, Angle(0, 0, 0))
			end

			-- 既存のVRMod_Exit処理も実行
			g_VR.StopCharacterSystem(ply)
			g_VR.StopCharacterSystem(ply:SteamID())
		end
	)
end

vrmod_character_lua()
concommand.Add(
	"vrmod_lua_reset_character",
	function(ply, cmd, args)
		AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
		include("vrmodunoffcial/vrmod_character.lua")
		vrmod_character_lua()
	end
)