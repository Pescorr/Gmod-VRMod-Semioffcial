-- vrmod_pickup_physgun.lua
g_VR = g_VR or {}
vrmod = vrmod or {}
function CreateVRPhysgunSystem(prefix)
	local physgunmaxrange = GetConVar("physgun_maxrange")
	scripted_ents.Register(
		{
			Type = "anim"
		}, "vrmod_physgun_controller_" .. prefix
	)

	if CLIENT then
		local beam_mat1 = Material("sprites/physbeam")
		local beam_mat2 = Material("sprites/physbeama")
		CreateClientConVar("vrmod_" .. prefix .. "_physgun_beam_enable", "1", true, FCVAR_ARCHIVE, "")
		CreateClientConVar("vrmod_" .. prefix .. "_physgun_beam_range", physgunmaxrange:GetFloat(), true, FCVAR_ARCHIVE, "")
		CreateClientConVar("vrmod_" .. prefix .. "_physgun_beam_color_a", "0", false, false, "")
		CreateClientConVar("vrmod_" .. prefix .. "_physgun_beam_damage", "0.0001", true, FCVAR_ARCHIVE, "", 0, 1.000)
		CreateClientConVar("vrmod_" .. prefix .. "_physgun_beam_damage_enable", "1", true, FCVAR_ARCHIVE, "")
		CreateClientConVar("vrmod_" .. prefix .. "_physgun_pull_enable", "1", true, FCVAR_ARCHIVE, "")
		g_VR["physgunHeldEntity_" .. prefix] = nil
		g_VR["physgunHandoffPending_" .. prefix] = false
		vrmod["PhysgunAction_" .. prefix] = function(bDrop)
			if GetConVar("vrmod_" .. prefix .. "_physgun_beam_enable"):GetInt() == 0 then return end
			net.Start("vrmod_physgun_action_" .. prefix)
			net.WriteBool(bDrop or false)
			local hand = prefix == "left" and "pose_lefthand" or "pose_righthand"
			local pose = g_VR.tracking[hand]
			net.WriteVector(pose.pos)
			net.WriteAngle(pose.ang)
			if bDrop then
				net.WriteVector(pose.vel)
				net.WriteVector(pose.angvel)
				g_VR["physgunHeldEntity_" .. prefix] = nil
				g_VR["physgunHandoffPending_" .. prefix] = false
			end

			net.SendToServer()
		end

		vrmod["PhysgunPull_" .. prefix] = function()
			if not GetConVar("vrmod_" .. prefix .. "_physgun_pull_enable"):GetBool() then return end
			local heldEntity = g_VR["physgunHeldEntity_" .. prefix]
			if not heldEntity or not IsValid(heldEntity) then return end
			net.Start("vrmod_physgun_pull_" .. prefix)
			net.SendToServer()
			if IsValid(heldEntity) then
				heldEntity:EmitSound("weapons/physcannon_pickup.wav")
			end
		end

		vrmod["PhysgunRequestHandoff_" .. prefix] = function()
			if not g_VR["physgunHeldEntity_" .. prefix] then return end
			net.Start("vrmod_physgun_request_handoff_" .. prefix)
			net.SendToServer()
			g_VR["physgunHandoffPending_" .. prefix] = true
		end

		local function GetPhysgunBeamColor()
			local r, g, b = 0, 255, 255
			local a = GetConVar("vrmod_" .. prefix .. "_physgun_beam_color_a"):GetInt()
			local r_cvar = GetConVar("physgun_color_r")
			local g_cvar = GetConVar("physgun_color_g")
			local b_cvar = GetConVar("physgun_color_b")
			if r_cvar then
				r = r_cvar:GetInt()
			end

			if g_cvar then
				g = g_cvar:GetInt()
			end

			if b_cvar then
				b = b_cvar:GetInt()
			end

			if r == 0 and g == 255 and b == 255 then
				local weaponColor = GetConVar("cl_weaponcolor")
				if weaponColor then
					local colorStr = weaponColor:GetString()
					local parts = string.Split(colorStr, " ")
					if #parts >= 3 then
						r = tonumber(parts[1]) * 255
						g = tonumber(parts[2]) * 255
						b = tonumber(parts[3]) * 255
					end
				end
			end

			return Color(r, g, b, a)
		end

		local function DrawPhysgunBeams()
			if not g_VR.active then return end
			if LocalPlayer():InVehicle() then return end
			if not GetConVar("vrmod_" .. prefix .. "_physgun_beam_enable"):GetBool() then return end
			local beamColor = GetPhysgunBeamColor()
			local hand = prefix == "left" and "pose_lefthand" or "pose_righthand"
			local heldEnt = g_VR["physgunHeldEntity_" .. prefix]
			local startPos = g_VR.tracking[hand].pos
			local forward = g_VR.tracking[hand].ang:Forward()
			local beamRange = GetConVar("vrmod_" .. prefix .. "_physgun_beam_range"):GetFloat()
			local tr = util.TraceLine(
				{
					start = startPos,
					endpos = startPos + forward * beamRange,
					filter = LocalPlayer()
				}
			)

			local endPos
			if heldEnt and IsValid(heldEnt) then
				endPos = heldEnt:GetPos()
			else
				endPos = tr.HitPos
			end

			local color = beamColor
			if heldEnt and IsValid(heldEnt) then
				color = Color(math.min(color.r + 50, 255), math.min(color.g + 50, 255), math.min(color.b + 50, 255), color.a)
			end

			render.SetMaterial(beam_mat1)
			render.DrawBeam(startPos, endPos, 1, 0, 1, color)
			render.SetMaterial(beam_mat2)
			render.DrawBeam(startPos, endPos, 1, 0, 1, Color(color.r, color.g, color.b, color.a * 0.5))
			local endSize = heldEnt and IsValid(heldEnt) and math.random(4, 6) or math.random(1, 1)
			render.DrawSprite(endPos, endSize, endSize, color)
			if GetConVar("vrmod_" .. prefix .. "_physgun_beam_damage_enable"):GetBool() and tr.Hit and IsValid(tr.Entity) and not heldEnt then
				if tr.Entity:GetClass() == "prop_ragdoll" then
					local damage = GetConVar("vrmod_" .. prefix .. "_physgun_beam_damage"):GetFloat()
					net.Start("vrmod_physgun_beam_damage_" .. prefix)
					net.WriteVector(tr.HitPos)
					net.WriteFloat(damage)
					net.SendToServer()
				end
			end
		end

		hook.Add(
			"PostDrawTranslucentRenderables",
			"vrmod_physgun_beams_" .. prefix,
			function(depth, sky)
				if depth or sky then return end
				DrawPhysgunBeams()
			end
		)

		local function SetRenderOverride(ent, ply, localPos, localAng)
			local steamid = IsValid(ply) and ply:SteamID()
			if g_VR.net[steamid] == nil then return end
			ent.RenderOverride = function()
				if g_VR.net[steamid] == nil then return end
				local wpos, wang
				local hand = prefix == "left" and "lefthand" or "righthand"
				-- Use the current localPos and localAng for rendering
				wpos, wang = LocalToWorld(ent.vrmod_currentLocalPos or localPos, ent.vrmod_currentLocalAng or localAng, g_VR.net[steamid].lerpedFrame[hand .. "Pos"], g_VR.net[steamid].lerpedFrame[hand .. "Ang"])
				ent:SetPos(wpos)
				ent:SetAngles(wang)
				ent:SetupBones()
				ent:DrawModel()
			end

			ent["VRPhysgunRenderOverride_" .. prefix] = ent.RenderOverride
			ent.vrmod_currentLocalPos = localPos -- Store current localPos for RenderOverride
			ent.vrmod_currentLocalAng = localAng -- Store current localAng for RenderOverride
		end

		net.Receive(
			"vrmod_physgun_action_" .. prefix,
			function(len)
				local ply = net.ReadEntity()
				local ent = net.ReadEntity()
				local bDrop = net.ReadBool()
				if bDrop then
					if IsValid(ent) and ent.RenderOverride == ent["VRPhysgunRenderOverride_" .. prefix] then
						ent.RenderOverride = nil
						ent.vrmod_currentLocalPos = nil
						ent.vrmod_currentLocalAng = nil
					end

					if ply == LocalPlayer() then
						if g_VR["physgunHeldEntity_" .. prefix] == ent then
							g_VR["physgunHeldEntity_" .. prefix] = nil
						end
					end

					if IsValid(ent) then
						ent:EmitSound("physics/metal/metal_box_impact_soft" .. math.random(1, 3) .. ".wav")
					end
				else
					local initialLocalPos = net.ReadVector()
					local initialLocalAng = net.ReadAngle()
					SetRenderOverride(ent, ply, initialLocalPos, initialLocalAng)
					if ply == LocalPlayer() then
						g_VR["physgunHeldEntity_" .. prefix] = ent
					end

					ent:EmitSound("weapons/physgun_on.wav")
				end
			end
		)

		net.Receive(
			"vrmod_physgun_update_localoffset_" .. prefix,
			function(len)
				local ply = net.ReadEntity()
				local ent = net.ReadEntity()
				local newLocalPos = net.ReadVector()
				local newLocalAng = net.ReadAngle()
				if IsValid(ent) and ent.RenderOverride == ent["VRPhysgunRenderOverride_" .. prefix] then
					-- Update the localPos and localAng used by RenderOverride
					ent.vrmod_currentLocalPos = newLocalPos
					ent.vrmod_currentLocalAng = newLocalAng
				end
			end
		)

		net.Receive(
			"vrmod_physgun_handoff_ready_" .. prefix,
			function()
				local isLeftHandForHandoff = net.ReadBool()
				local currentPrefix = isLeftHandForHandoff and "left" or "right"
				if g_VR["physgunHandoffPending_" .. currentPrefix] then
					vrmod.Pickup(isLeftHandForHandoff, false) -- Assuming vrmod.Pickup is the general pickup function
					g_VR["physgunHandoffPending_" .. currentPrefix] = false
				end
			end
		)
	elseif SERVER then
		util.AddNetworkString("vrmod_physgun_action_" .. prefix)
		util.AddNetworkString("vrmod_physgun_beam_damage_" .. prefix)
		util.AddNetworkString("vrmod_physgun_pull_" .. prefix)
		util.AddNetworkString("vrmod_physgun_request_handoff_" .. prefix)
		util.AddNetworkString("vrmod_physgun_handoff_ready_" .. prefix)
		util.AddNetworkString("vrmod_physgun_update_localoffset_" .. prefix) -- New network string for server
		local PhysgunController = {
			controller = nil,
			pickupList = {},
			pickupCount = 0
		}

		local ShadowParams = {
			secondstoarrive = 0.0001,
			maxangular = 5000,
			maxangulardamp = 5000,
			maxspeed = 5000,
			maxspeeddamp = 10000,
			dampfactor = 0.5,
			teleportdistance = 0,
			deltatime = 0
		}

		net.Receive(
			"vrmod_physgun_beam_damage_" .. prefix,
			function(len, ply)
				if not IsValid(ply) or ply:InVehicle() then return end
				if not ply:GetInfoNum("vrmod_" .. prefix .. "_physgun_beam_damage_enable", 1) == 1 then return end
				local hitPos = net.ReadVector()
				local damage = net.ReadFloat()
				local dmgInfo = DamageInfo()
				dmgInfo:SetAttacker(ply)
				dmgInfo:SetInflictor(ply)
				dmgInfo:SetDamage(damage)
				dmgInfo:SetDamageType(DMG_CRUSH)
				dmgInfo:SetDamagePosition(hitPos)
				util.BlastDamageInfo(dmgInfo, hitPos, 3.0)
			end
		)

		net.Receive(
			"vrmod_physgun_pull_" .. prefix,
			function(len, ply)
				if not IsValid(ply) or ply:InVehicle() then return end
				for i = 1, PhysgunController.pickupCount do
					local t = PhysgunController.pickupList[i]
					if t.steamid ~= ply:SteamID() then continue end
					local frame = g_VR[ply:SteamID()].latestFrame
					if not frame then continue end
					local handPos, handAng
					if prefix == "left" then
						handPos, handAng = LocalToWorld(frame.lefthandPos, frame.lefthandAng, ply:GetPos(), Angle())
					else
						handPos, handAng = LocalToWorld(frame.righthandPos, frame.righthandAng, ply:GetPos(), Angle())
					end

					t.localPos = Vector(0, 0, 0)
					-- Notify client about the updated localPos
					net.Start("vrmod_physgun_update_localoffset_" .. prefix)
					net.WriteEntity(ply)
					net.WriteEntity(t.ent)
					net.WriteVector(t.localPos)
					net.WriteAngle(t.localAng) -- localAng doesn't change on pull, but send for consistency
					net.Send(ply) -- Send only to the relevant client
					hook.Run("VRPhysgun_Pull_" .. prefix, ply, t.ent)
					ply:EmitSound("physics/metal/metal_box_strain" .. math.random(1, 3) .. ".wav")
					break
				end
			end
		)

		net.Receive(
			"vrmod_physgun_request_handoff_" .. prefix,
			function(len, ply)
				if not IsValid(ply) or ply:InVehicle() then return end
				local handoffIsLeft = prefix == "left"
				for i = 1, PhysgunController.pickupCount do
					local t = PhysgunController.pickupList[i]
					if t.steamid ~= ply:SteamID() then continue end
					local frame = g_VR[ply:SteamID()].latestFrame
					if not frame then continue end
					local handPos, handAng
					if handoffIsLeft then
						handPos, handAng = LocalToWorld(frame.lefthandPos, frame.lefthandAng, ply:GetPos(), Angle())
					else
						handPos, handAng = LocalToWorld(frame.righthandPos, frame.righthandAng, ply:GetPos(), Angle())
					end

					local targetPickupPoint = LocalToWorld(Vector(0.0, handoffIsLeft and -0.0 or 0.0, 0), Angle(), handPos, handAng)
					if IsValid(t.ent) and IsValid(t.phys) then
						t.phys:SetPos(targetPickupPoint)
						t.phys:SetAngles(handAng)
						t.phys:SetVelocity(Vector(0, 0, 0))
						t.phys:SetAngleVelocity(Vector(0, 0, 0))
						t.phys:Wake()
					end

					drop(t.steamid, nil, nil, Vector(0, 0, 0), Vector(0, 0, 0))
					net.Start("vrmod_physgun_handoff_ready_" .. prefix)
					net.WriteBool(handoffIsLeft)
					net.Send(ply)
					break
				end
			end
		)

		local function drop(steamid, handPos, handAng, handVel, handAngVel)
			for i = 1, PhysgunController.pickupCount do
				local t = PhysgunController.pickupList[i]
				if t.steamid ~= steamid then continue end
				local phys = t.phys
				if IsValid(phys) then
					t.ent:SetCollisionGroup(t.collisionGroup)
					PhysgunController.controller:RemoveFromMotionController(phys)
					if handPos then
						local wPos, wAng = LocalToWorld(t.localPos, t.localAng, handPos, handAng)
						phys:SetPos(wPos)
						phys:SetAngles(wAng)
						phys:SetVelocity(t.ply:GetVelocity() + handVel)
						phys:AddAngleVelocity(-phys:GetAngleVelocity() + phys:WorldToLocalVector(handAngVel))
						phys:Wake()
					end
				end

				net.Start("vrmod_physgun_action_" .. prefix)
				net.WriteEntity(t.ply)
				net.WriteEntity(t.ent)
				net.WriteBool(true)
				net.Broadcast()
				if g_VR[t.steamid] then
					g_VR[t.steamid]["physgunHeldItems_" .. prefix] = g_VR[t.steamid]["physgunHeldItems_" .. prefix] or {}
					g_VR[t.steamid]["physgunHeldItems_" .. prefix] = nil
				end

				PhysgunController.pickupList[i] = PhysgunController.pickupList[PhysgunController.pickupCount]
				PhysgunController.pickupList[PhysgunController.pickupCount] = nil
				PhysgunController.pickupCount = PhysgunController.pickupCount - 1
				if PhysgunController.pickupCount == 0 and IsValid(PhysgunController.controller) then
					PhysgunController.controller:StopMotionController()
					PhysgunController.controller:Remove()
					PhysgunController.controller = nil
				end

				hook.Run("VRPhysgun_Drop_" .. prefix, t.ply, t.ent)

				return
			end
		end

		local function pickup(ply, handPos, handAng)
			local steamid = ply:SteamID()
			local maxRange = ply:GetInfoNum("vrmod_" .. prefix .. "_physgun_beam_range", physgunmaxrange:GetFloat())
			local tr = util.TraceLine(
				{
					start = handPos,
					endpos = handPos + handAng:Forward() * maxRange,
					filter = ply
				}
			)

			if not tr.Hit or not IsValid(tr.Entity) then return end
			local entity = tr.Entity
			if entity:IsPlayer() or not IsValid(entity:GetPhysicsObject()) or ply:InVehicle() or entity:GetMoveType() ~= MOVETYPE_VPHYSICS or entity:GetPhysicsObject():GetMass() > 1000 or (entity.CPPICanPickup and not entity:CPPICanPickup(ply)) then return end
			if hook.Run("VRPhysgun_CanPickup_" .. prefix, ply, entity) == false then return end
			if not IsValid(PhysgunController.controller) then
				PhysgunController.controller = ents.Create("vrmod_physgun_controller_" .. prefix)
				PhysgunController.controller.ShadowParams = table.Copy(ShadowParams)
				function PhysgunController.controller:PhysicsSimulate(phys, deltatime)
					phys:Wake()
					local t = phys:GetEntity()["vrmod_physgun_info_" .. prefix]
					local frame = g_VR[t.steamid] and g_VR[t.steamid].latestFrame
					if not frame then return end
					local handPos, handAng
					if prefix == "left" then
						handPos, handAng = LocalToWorld(frame.lefthandPos, frame.lefthandAng, t.ply:GetPos(), Angle())
					else
						handPos, handAng = LocalToWorld(frame.righthandPos, frame.righthandAng, t.ply:GetPos(), Angle())
					end

					self.ShadowParams.pos, self.ShadowParams.angle = LocalToWorld(t.localPos, t.localAng, handPos, handAng)
					phys:ComputeShadowControl(self.ShadowParams)
				end

				PhysgunController.controller:StartMotionController()
				if not hook.GetTable()["Tick"]["vrmod_physgun_tick_" .. prefix] then
					hook.Add(
						"Tick",
						"vrmod_physgun_tick_" .. prefix,
						function()
							for i = 1, PhysgunController.pickupCount do
								local t = PhysgunController.pickupList[i]
								if not IsValid(t.phys) or not t.phys:IsMoveable() or not g_VR[t.steamid] or not t.ply:Alive() or t.ply:InVehicle() then
									drop(t.steamid)
								end
							end
						end
					)
				end
			end

			for k = 1, PhysgunController.pickupCount do
				if PhysgunController.pickupList[k].ent == entity then return end
			end

			if entity.RenderOverride then
				local otherPrefix = prefix == "left" and "right" or "left"
				if entity["VRPhysgunRenderOverride_" .. otherPrefix] then return end
			end

			local phys = entity:GetPhysicsObject()
			local localPos, localAng = WorldToLocal(entity:GetPos(), entity:GetAngles(), handPos, handAng)
			phys:Wake()
			PhysgunController.pickupCount = PhysgunController.pickupCount + 1
			local index = PhysgunController.pickupCount
			PhysgunController.controller:AddToMotionController(phys)
			PhysgunController.pickupList[index] = {
				ent = entity,
				phys = phys,
				localPos = localPos,
				localAng = localAng,
				collisionGroup = entity:GetCollisionGroup(),
				steamid = steamid,
				ply = ply
			}

			g_VR[steamid] = g_VR[steamid] or {}
			g_VR[steamid]["physgunHeldItems_" .. prefix] = PhysgunController.pickupList[index]
			entity["vrmod_physgun_info_" .. prefix] = PhysgunController.pickupList[index]
			net.Start("vrmod_physgun_action_" .. prefix)
			net.WriteEntity(ply)
			net.WriteEntity(entity)
			net.WriteBool(false)
			net.WriteVector(localPos)
			net.WriteAngle(localAng)
			net.Broadcast()
			hook.Run("VRPhysgun_Pickup_" .. prefix, ply, entity)
		end

		net.Receive(
			"vrmod_physgun_action_" .. prefix,
			function(len, ply)
				if not IsValid(ply) or not g_VR[ply:SteamID()] then return end
				if ply:GetInfoNum("vrmod_" .. prefix .. "_physgun_beam_enable", 1) == 0 then return end
				local bDrop = net.ReadBool()
				if not bDrop then
					pickup(ply, net.ReadVector(), net.ReadAngle())
				else
					drop(ply:SteamID(), net.ReadVector(), net.ReadAngle(), net.ReadVector(), net.ReadVector())
				end
			end
		)
	end

	hook.Add(
		"VRMod_Input",
		"vrmod_physgun_input_" .. prefix,
		function(action, pressed)
			if CLIENT and GetConVar("vrmod_" .. prefix .. "_physgun_beam_enable"):GetInt() == 0 then return end
			if not g_VR.active then return end
			if LocalPlayer():InVehicle() then return end
			local pickupAction = "boolean_" .. (prefix == "left" and "left_secondaryfire" or "secondaryfire")
			local activationAction = "boolean_" .. prefix .. "_pickup"
			local actflag = false
			if action == activationAction then
				vrmod["PhysgunAction_" .. prefix](not pressed)
				if pressed then
					LocalPlayer():ConCommand("vrmod_" .. prefix .. "_physgun_beam_color_a 100")
					actflag = true
				else
					LocalPlayer():ConCommand("vrmod_" .. prefix .. "_physgun_beam_color_a 0")
					actflag = false
					if g_VR["physgunHeldEntity_" .. prefix] then
						vrmod["PhysgunRequestHandoff_" .. prefix]()
					end
				end
			elseif action == pickupAction and pressed then
				if g_VR["physgunHeldEntity_" .. prefix] then
					vrmod["PhysgunPull_" .. prefix]()
				end

				if actflag == true then
					vrmod.Pickup(prefix == "left" and true or false, not pressed)
				end
			elseif action == pickupAction and not pressed then
				if g_VR["physgunHeldEntity_" .. prefix] then
					vrmod.Pickup(prefix == "left" and true or false)
				end

				if actflag == false then
					vrmod.Pickup(prefix == "left" and true or false)
				end
			end
		end
	)

	print("[VRMod] " .. string.upper(prefix) .. " hand Physgun controller module loaded")
end

CreateVRPhysgunSystem("left")
CreateVRPhysgunSystem("right")
print("[VRMod] Dual Physgun systems initialized")