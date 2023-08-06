if SERVER then return end
local hands
CreateClientConVar("vrmod_floatinghands_material", "models/dog/eyeglass", FCVAR_ARCHIVE)
CreateClientConVar("vrmod_floatinghands_model", "models/player/vr_hands.mdl", FCVAR_ARCHIVE)
local convars = vrmod.GetConvars()
hook.Add(
	"VRMod_Start",
	"vrmod_starthandsonly",
	function(ply)
		if not (ply == LocalPlayer() and convars.vrmod_floatinghands:GetBool()) then return end
		timer.Simple(
			0,
			function()
				LocalPlayer().RenderOverride = function() end
			end
		)

		local zeroVec, zeroAng = Vector(), Angle()
		local steamid = LocalPlayer():SteamID()
		hands = ClientsideModel(GetConVar("vrmod_floatinghands_model"):GetString())
		hands:SetupBones()
		g_VR.hands = hands
		hands:SetMaterial(GetConVar("vrmod_floatinghands_material"):GetString())
		local leftHand = hands:LookupBone("ValveBiped.Bip01_L_Hand")
		local rightHand = hands:LookupBone("ValveBiped.Bip01_R_Hand")
		local fingerboneids = {}
		local tmp = {"0", "01", "02", "1", "11", "12", "2", "21", "22", "3", "31", "32", "4", "41", "42"}
		for i = 1, 30 do
			fingerboneids[#fingerboneids + 1] = hands:LookupBone("ValveBiped.Bip01_" .. ((i < 16) and "L" or "R") .. "_Finger" .. tmp[i - (i < 16 and 0 or 15)]) or -1
		end

		local boneinfo = {}
		local boneCount = hands:GetBoneCount()
		for i = 0, boneCount - 1 do
			local parent = hands:GetBoneParent(i)
			local mtx = hands:GetBoneMatrix(i) or Matrix()
			local mtxParent = hands:GetBoneMatrix(parent) or mtx
			local relativePos, relativeAng = WorldToLocal(mtx:GetTranslation(), mtx:GetAngles(), mtxParent:GetTranslation(), mtxParent:GetAngles())
			boneinfo[i] = {
				name = hands:GetBoneName(i),
				parent = parent,
				relativePos = relativePos,
				relativeAng = relativeAng,
				offsetAng = zeroAng,
				pos = zeroVec,
				ang = zeroAng,
				targetMatrix = mtx
			}
		end

		hands:SetPos(LocalPlayer():GetPos())
		hands:SetRenderBounds(zeroVec, zeroVec, Vector(1, 1, 1) * 65000)
		local frame = 0
		hands:AddCallback(
			"BuildBonePositions",
			function(ent, numbones)
				if frame ~= FrameNumber() then
					frame = FrameNumber()
					if LocalPlayer():InVehicle() and LocalPlayer():GetVehicle():GetClass() ~= "prop_vehicle_prisoner_pod" then
						hands:AddEffects(EF_NODRAW) --note: this will block BuildBonePositions from running
						hook.Add(
							"VRMod_ExitVehicle",
							"vrmod_floatinghands",
							function()
								hook.Remove("VRMod_ExitVehicle", "vrmod_floatinghands")
								hands:RemoveEffects(EF_NODRAW)
							end
						)

						return
					end

					local netFrame = g_VR.net[steamid] and g_VR.net[steamid].lerpedFrame
					if netFrame then
						boneinfo[leftHand].overridePos, boneinfo[leftHand].overrideAng = netFrame.lefthandPos, netFrame.lefthandAng
						boneinfo[rightHand].overridePos, boneinfo[rightHand].overrideAng = netFrame.righthandPos, netFrame.righthandAng + Angle(0, 0, 180)
						for k, v in pairs(fingerboneids) do
							if not boneinfo[v] then continue end
							boneinfo[v].offsetAng = LerpAngle(netFrame["finger" .. math.floor((k - 1) / 3 + 1)], g_VR.openHandAngles[k], g_VR.closedHandAngles[k])
						end

						hands:SetPos(LocalPlayer():GetPos()) --for lighting
					end

					for i = 0, boneCount - 1 do
						local info = boneinfo[i]
						local parentInfo = boneinfo[info.parent] or info
						local wpos, wang = LocalToWorld(info.relativePos, info.relativeAng + info.offsetAng, parentInfo.pos, parentInfo.ang)
						wpos = info.overridePos or wpos
						wang = info.overrideAng or wang
						local mat = Matrix()
						mat:Translate(wpos)
						mat:Rotate(wang)
						info.targetMatrix = mat
						info.pos = wpos
						info.ang = wang
					end
				end

				for i = 0, boneCount - 1 do
					if hands:GetBoneMatrix(i) then
						hands:SetBoneMatrix(i, boneinfo[i].targetMatrix)
					end
				end
			end
		)
	end
)

hook.Add(
	"VRMod_Exit",
	"vrmod_stophandsonly",
	function(ply, steamid)
		if IsValid(hands) then
			hands:Remove()
			LocalPlayer().RenderOverride = nil
		end
	end
)