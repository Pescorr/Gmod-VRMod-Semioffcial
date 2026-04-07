-- テレポートConVar対応オーバーライド
-- ロコモーションファイル（1/2/3/6）のテレポートhookを上書きし、
-- vrmod_unoff_teleport_hand ConVarを全モードで有効にする
-- ファイル名 vrmod_t... > vrmod_l... なので locomotion ファイル群の後にロードされる

local cv_allowtp = CreateClientConVar("vrmod_allow_teleport", 1, true, FCVAR_REPLICATED)
local cv_usetp = CreateClientConVar("vrmod_allow_teleport_client", 0, true, FCVAR_ARCHIVE)
local cv_tp_hand = CreateClientConVar("vrmod_unoff_teleport_hand", "0", true, FCVAR_ARCHIVE, "Teleport aim source: 0=Left Hand, 1=Right Hand, 2=Head", 0, 2)

if SERVER then return end

local tpBeamMatrices, tpBeamEnt, tpBeamHitPos = {}, nil, nil
for i = 1, 17 do tpBeamMatrices[i] = Matrix() end

hook.Add("VRMod_Input", "teleport", function(action, pressed)
	if action == "boolean_teleport" and not LocalPlayer():InVehicle() and cv_allowtp:GetBool() and cv_usetp:GetBool() then
		if pressed then
			tpBeamEnt = ClientsideModel("models/vrmod/tpbeam.mdl")
			tpBeamEnt:SetRenderMode(RENDERMODE_TRANSCOLOR)
			tpBeamEnt.RenderOverride = function(self)
				render.SuppressEngineLighting(true)
				self:SetupBones()
				for i = 1, 17 do
					self:SetBoneMatrix(i - 1, tpBeamMatrices[i])
				end
				self:DrawModel()
				render.SetColorModulation(1, 1, 1)
				render.SuppressEngineLighting(false)
			end
			hook.Add("VRMod_PreRender", "teleport", function()
				local tpHand = cv_tp_hand:GetInt()
				local controllerPos, controllerDir
				if tpHand == 2 then
					controllerPos, controllerDir = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang:Forward()
				elseif tpHand == 1 then
					controllerPos, controllerDir = g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang:Forward()
				else
					controllerPos, controllerDir = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang:Forward()
				end
				prevPos = controllerPos
				local hit = false
				for i = 2, 17 do
					local d = i - 1
					local nextPos = controllerPos + controllerDir * 50 * d + Vector(0, 0, -d * d * 3)
					local v = nextPos - prevPos
					if not hit then
						local tr = util.TraceLine({start = prevPos, endpos = prevPos + v, filter = LocalPlayer(), mask = MASK_PLAYERSOLID})
						hit = tr.Hit
						if hit then
							tpBeamMatrices[1] = Matrix()
							tpBeamMatrices[1]:Translate(tr.HitPos + tr.HitNormal)
							tpBeamMatrices[1]:Rotate(tr.HitNormal:Angle() + Angle(90, 0, 90))
							if tr.HitNormal.z < 0.7 then
								tpBeamMatrices[1]:Scale(Vector(0.5, 0.5, 0.5))
								tpBeamEnt:SetColor(Color(255, 100, 100, 150))
								tpBeamHitPos = nil
							else
								tpBeamEnt:SetColor(Color(100, 255, 100, 150))
								tpBeamHitPos = tr.HitPos
							end
							tpBeamEnt:SetPos(tr.HitPos)
						end
					end
					tpBeamMatrices[i] = Matrix()
					tpBeamMatrices[i]:Translate(prevPos + v * 0.5)
					tpBeamMatrices[i]:Rotate(v:Angle() + Angle(-90, 0, 0))
					tpBeamMatrices[i]:Scale(Vector(0.5, 0.5, v:Length()))
					prevPos = nextPos
				end
				if not hit then
					tpBeamEnt:SetColor(Color(0, 0, 0, 0))
					tpBeamHitPos = nil
				end
			end)
		else
			tpBeamEnt:Remove()
			hook.Remove("VRMod_PreRender", "teleport")
			if tpBeamHitPos then
				net.Start("vrmod_teleport") net.WriteVector(tpBeamHitPos) net.SendToServer()
			end
		end
	end
end)
