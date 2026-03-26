--[vrmod_test_pickup_beam.lua]start--
-- Cone-based pickup assist system for vrmod_pickup
-- Detects entities in a forward cone from the hand, teleports them to hand,
-- and retries until vrmod_pickup grabs them or grip is released.
AddCSLuaFile()

-- Shared ConVars
CreateClientConVar("vrmod_pickup_beam_enable", 1, true, FCVAR_ARCHIVE, "Enable/disable the cone pickup assist")
CreateClientConVar("vrmod_pickup_beam_cone_angle", 25, true, FCVAR_ARCHIVE, "Half-angle of detection cone (degrees)", 1, 60)
CreateClientConVar("vrmod_pickup_beam_cone_range", 25, true, FCVAR_ARCHIVE, "Max range of cone detection (units)", 1, 1000)
CreateClientConVar("vrmod_pickup_beam_retry_max", 10, true, FCVAR_ARCHIVE, "Max retry ticks for pickup assist", 1, 30)
CreateClientConVar("vrmod_pickup_weight", 100, true, FCVAR_ARCHIVE, "Max weight of entity to grab")
CreateClientConVar("vrmod_pickup_beam_damage", 0.0001, true, FCVAR_ARCHIVE, "Damage dealt by the beam laser", 0, 1.000)
CreateClientConVar("vrmod_pickup_beam_damage_enable", 1, true, FCVAR_ARCHIVE, "Enable/disable damage dealt by the beam laser")
CreateClientConVar("vrmod_pickup_beam_ragdoll_spine", 0, true, FCVAR_ARCHIVE, "Enable/disable damage to ragdoll spine")
-- Keep visual beam range for rendering
CreateClientConVar("vrmod_pickup_beamrange", 25, true, FCVAR_ARCHIVE, "Visual beam length (units)")

-----------------------------------------------------------------------
-- SERVER
-----------------------------------------------------------------------
if SERVER then
	if util ~= nil then
		util.AddNetworkString("vrmod_pickup_beam")
		util.AddNetworkString("vrmod_pickup_beam_damage")

		-- Per-player/hand retry state
		local retryState = {} -- key: "STEAM_X:Y:Z_L" or "_R"

		-- Check if an entity is valid for cone pickup
		-- Mirrors vrmod_pickup.lua validation (pickup_limit == 1 mode)
		local function ValidateEntity(ply, ent, maxWeight)
			if not IsValid(ent) then return false end
			if not IsValid(ent:GetPhysicsObject()) then return false end
			if ent:IsPlayer() then return false end
			if ply:InVehicle() then return false end
			if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
			-- Skip frozen/constrained entities (e.g. harpoons, anchored props)
			if not ent:GetPhysicsObject():IsMoveable() then return false end
			if ent:GetPhysicsObject():GetMass() > maxWeight then return false end
			-- Use global shouldPickUp from vrmod_pickup.lua if available
			if shouldPickUp and not shouldPickUp(ent) then return false end
			-- CPPI ownership check
			if ent.CPPICanPickup and not ent:CPPICanPickup(ply) then return false end
			-- Client pickup limit check
			local clientLimit = ply:GetInfoNum("vrmod_unoff_pickup_limit_client", 0)
			if clientLimit >= 3 then return false end
			if clientLimit >= 2 and ent:GetPhysicsObject():HasGameFlag(FVPHYSICS_MULTIOBJECT_ENTITY) then return false end
			return true
		end

		-- Find the best entity within a sphere around hand (closest wins)
		local function FindBestEntityInSphere(ply, handPos, sphereRange, maxWeight, excludeEnt)
			local bestEnt = nil
			local bestDist = sphereRange + 1

			for _, ent in ipairs(ents.FindInSphere(handPos, sphereRange)) do
				if ent == excludeEnt then continue end
				if not ValidateEntity(ply, ent, maxWeight) then continue end

				local dist = handPos:Distance(ent:GetPos())
				if dist < bestDist then
					bestDist = dist
					bestEnt = ent
				end
			end

			return bestEnt
		end

		-- Teleport entity to hand and attempt pickup via global pickup()
		local function TeleportAndPickup(ply, handPos, ent, isLeftHand)
			if not IsValid(ent) or not IsValid(ply) then return end
			ent:SetPos(handPos)
			-- Zero velocity so moving/thrown objects stay at hand position for pickup
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(Vector(0, 0, 0))
				phys:SetAngleVelocity(Vector(0, 0, 0))
				phys:Wake()
			end
			-- Call global pickup() from vrmod_pickup.lua
			if pickup then
				pickup(ply, isLeftHand, handPos, Angle())
			end
		end

		-- Check if vrmod_pickup has successfully grabbed something in this hand
		local function IsHandHolding(ply, isLeftHand)
			local steamid = ply:SteamID()
			if not g_VR[steamid] then return false end
			if not g_VR[steamid].heldItems then return false end
			local slot = isLeftHand and 1 or 2
			local item = g_VR[steamid].heldItems[slot]
			return item and IsValid(item.ent)
		end

		-- Stop retry for a specific key
		local function StopRetry(key)
			retryState[key] = nil
			-- Remove Tick hook if no retries remain
			if next(retryState) == nil then
				hook.Remove("Tick", "vrmod_pickup_beam_retry")
			end
		end

		-- Retry tick: keep teleporting + attempting pickup
		local function RetryTick()
			for key, state in pairs(retryState) do
				-- Validate state
				if not IsValid(state.ply) or not IsValid(state.ent) then
					StopRetry(key)
				elseif not state.ply:Alive() or state.ply:InVehicle() then
					StopRetry(key)
				elseif IsHandHolding(state.ply, state.isLeftHand) then
					-- SUCCESS: vrmod_pickup grabbed it
					StopRetry(key)
				else
					state.remaining = state.remaining - 1
					if state.remaining <= 0 then
						StopRetry(key)
					else
						-- Get current hand position from tracking data
						local steamid = state.ply:SteamID()
						local frame = g_VR[steamid] and g_VR[steamid].latestFrame
						if not frame then
							StopRetry(key)
						else
							local handPos, handAng
							if state.isLeftHand then
								handPos, handAng = LocalToWorld(frame.lefthandPos, frame.lefthandAng, state.ply:GetPos(), Angle())
							else
								handPos, handAng = LocalToWorld(frame.righthandPos, frame.righthandAng, state.ply:GetPos(), Angle())
							end
							TeleportAndPickup(state.ply, handPos, state.ent, state.isLeftHand)
						end
					end
				end
			end
		end

		-- Start retry mechanism
		local function StartRetry(ply, ent, isLeftHand, maxRetries)
			local key = ply:SteamID() .. (isLeftHand and "_L" or "_R")
			retryState[key] = {
				ply = ply,
				ent = ent,
				isLeftHand = isLeftHand,
				remaining = maxRetries
			}
			-- Add Tick hook if not already present
			if not hook.GetTable()["Tick"] or not hook.GetTable()["Tick"]["vrmod_pickup_beam_retry"] then
				hook.Add("Tick", "vrmod_pickup_beam_retry", RetryTick)
			end
		end

		-- Receive cone assist request from client
		net.Receive(
			"vrmod_pickup_beam",
			function(len, ply)
				if not IsValid(ply) or ply:InVehicle() then return end
				local steamid = ply:SteamID()
				if not g_VR[steamid] then return end

				local isLeftHand = net.ReadBool()
				local sphereRange = net.ReadFloat()
				local clientMaxWeight = net.ReadFloat()
				local handPos = net.ReadVector()
				local gripReleased = net.ReadBool()

				-- Server-side weight double-check: enforce min(server, client)
				local serverWeight = GetConVar("vrmod_pickup_weight") and GetConVar("vrmod_pickup_weight"):GetFloat() or 100
				local clientWeightLimit = ply:GetInfoNum("vrmod_unoff_pickup_weight_client", 0)
				local maxWeight = clientWeightLimit > 0 and math.min(serverWeight, clientWeightLimit) or serverWeight
				maxWeight = math.min(maxWeight, clientMaxWeight)

				local key = steamid .. (isLeftHand and "_L" or "_R")

				-- Grip released: stop any active retry
				if gripReleased then
					if retryState[key] then
						StopRetry(key)
					end
					return
				end

				-- Already holding something in this hand, skip
				if IsHandHolding(ply, isLeftHand) then return end

				-- Find the other hand's held entity to exclude from search
				local otherSlot = isLeftHand and 2 or 1
				local excludeEnt = nil
				if g_VR[steamid].heldItems and g_VR[steamid].heldItems[otherSlot] then
					excludeEnt = g_VR[steamid].heldItems[otherSlot].ent
				end

				-- Sphere search
				local ent = FindBestEntityInSphere(ply, handPos, sphereRange, maxWeight, excludeEnt)

				if ent then
					-- Teleport and attempt pickup
					TeleportAndPickup(ply, handPos, ent, isLeftHand)

					-- Start retry in case first attempt failed
					local maxRetries = ply:GetInfoNum("vrmod_pickup_beam_retry_max", 10)
					StartRetry(ply, ent, isLeftHand, maxRetries)
				end

				-- Delayed re-scan: catches entities released by holster/other delayed systems
				-- Holster uses timer.Simple(0.08~0.1) to spawn+pickup, so we re-scan after that
				-- Track that this grip press is active (cleared by StopRetry or grip release)
				retryState[key] = retryState[key] or { ply = ply, ent = nil, isLeftHand = isLeftHand, remaining = 0 }

				local function DelayedRescan()
					if not IsValid(ply) or ply:InVehicle() then return end
					if IsHandHolding(ply, isLeftHand) then return end -- already grabbed something
					-- If grip was released (retryState cleared), skip rescan
					if not retryState[key] then return end
					-- Get fresh hand position from tracking data
					local frame = g_VR[steamid] and g_VR[steamid].latestFrame
					if not frame then return end
					local freshHandPos
					if isLeftHand then
						freshHandPos = LocalToWorld(frame.lefthandPos, frame.lefthandAng, ply:GetPos(), Angle())
					else
						freshHandPos = LocalToWorld(frame.righthandPos, frame.righthandAng, ply:GetPos(), Angle())
					end
					-- Fresh cone scan with current hand position
					local freshExclude = nil
					if g_VR[steamid].heldItems and g_VR[steamid].heldItems[isLeftHand and 2 or 1] then
						freshExclude = g_VR[steamid].heldItems[isLeftHand and 2 or 1].ent
					end
					local freshEnt = FindBestEntityInSphere(ply, freshHandPos, sphereRange, maxWeight, freshExclude)
					if freshEnt then
						TeleportAndPickup(ply, freshHandPos, freshEnt, isLeftHand)
						-- Start tick retry for this new entity
						local maxRetries = ply:GetInfoNum("vrmod_pickup_beam_retry_max", 10)
						StartRetry(ply, freshEnt, isLeftHand, maxRetries)
					end
				end

				timer.Simple(0.12, DelayedRescan)
				timer.Simple(0.25, DelayedRescan)
			end
		)

		-- Beam damage (kept from original)
		net.Receive(
			"vrmod_pickup_beam_damage",
			function(len, ply)
				if not IsValid(ply) or ply:InVehicle() then return end
				if not GetConVar("vrmod_pickup_beam_damage_enable"):GetBool() then return end
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

		-- Cleanup retries when player exits VR or disconnects
		hook.Add("VRMod_Exit", "vrmod_pickup_beam_cleanup", function(ply)
			if not IsValid(ply) then return end
			local steamid = ply:SteamID()
			local keyL = steamid .. "_L"
			local keyR = steamid .. "_R"
			if retryState[keyL] then StopRetry(keyL) end
			if retryState[keyR] then StopRetry(keyR) end
		end)

		hook.Add("PlayerDisconnected", "vrmod_pickup_beam_disconnect", function(ply)
			if not IsValid(ply) then return end
			local steamid = ply:SteamID()
			local keyL = steamid .. "_L"
			local keyR = steamid .. "_R"
			if retryState[keyL] then StopRetry(keyL) end
			if retryState[keyR] then StopRetry(keyR) end
		end)
	else
		print("util library is not available. Skipping network string registration.")
	end
end

if SERVER then return end

-----------------------------------------------------------------------
-- CLIENT
-----------------------------------------------------------------------

-- ConVar cache (lazy init)
local cv_enable, cv_sphere_range, cv_weight, cv_beamrange, cv_damage, cv_damage_enable, cv_weight_client

local function EnsureConVars()
	if cv_enable then return end
	cv_enable = GetConVar("vrmod_pickup_beam_enable")
	cv_sphere_range = GetConVar("vrmod_pickup_beam_cone_range")
	cv_weight = GetConVar("vrmod_pickup_weight")
	cv_beamrange = GetConVar("vrmod_pickup_beamrange")
	cv_damage = GetConVar("vrmod_pickup_beam_damage")
	cv_damage_enable = GetConVar("vrmod_pickup_beam_damage_enable")
	cv_weight_client = GetConVar("vrmod_unoff_pickup_weight_client")
end

-- Ragdoll damage via forward trace (no visual beam)
local function DamageTraceForHand(handPos, handAng)
	EnsureConVars()
	if not cv_damage_enable or not cv_damage_enable:GetBool() then return end

	local beamLen = cv_beamrange and cv_beamrange:GetFloat() or 1000
	local traceRes = util.TraceLine({
		start = handPos,
		endpos = handPos + handAng:Forward() * beamLen,
		filter = LocalPlayer()
	})

	if traceRes.Hit and IsValid(traceRes.Entity) and traceRes.Entity:GetClass() == "prop_ragdoll" then
		local damage = cv_damage and cv_damage:GetFloat() or 0.0001
		net.Start("vrmod_pickup_beam_damage")
		net.WriteVector(traceRes.HitPos)
		net.WriteFloat(damage)
		net.SendToServer()
	end
end

hook.Add(
	"PostDrawTranslucentRenderables",
	"vrmod_pickup_beam_laser",
	function(depth, sky)
		if depth or sky then return end
		EnsureConVars()
		if not cv_enable or not cv_enable:GetBool() then return end
		if not g_VR or not g_VR.active then return end

		local ply = LocalPlayer()
		if not IsValid(ply) or ply:InVehicle() then return end

		local leftHandPos, leftHandAng = vrmod.GetLeftHandPose(ply)
		local rightHandPos, rightHandAng = vrmod.GetRightHandPose(ply)
		DamageTraceForHand(leftHandPos, leftHandAng)
		DamageTraceForHand(rightHandPos, rightHandAng)
	end
)

-- Input hook: send cone assist request on grip press/release
hook.Add(
	"VRMod_Input",
	"vrmod_pickup_beam",
	function(action, pressed)
		EnsureConVars()
		if not cv_enable or not cv_enable:GetBool() then return end
		if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end

		local isLeft
		if action == "boolean_left_pickup" then
			isLeft = true
		elseif action == "boolean_right_pickup" then
			isLeft = false
		else
			return -- not a pickup action, ignore
		end

		local ply = LocalPlayer()
		if not IsValid(ply) or ply:InVehicle() then return end

		-- Skip if climbing mod is active and this hand is holding a surface
		if vrmod.climbing then
			if isLeft and vrmod.climbing.IsHoldingLeft and vrmod.climbing.IsHoldingLeft() then return end
			if not isLeft and vrmod.climbing.IsHoldingRight and vrmod.climbing.IsHoldingRight() then return end
			-- Also skip during wall running
			local climbState = vrmod.climbing.GetState and vrmod.climbing.GetState()
			if climbState and climbState.wallrunning then return end
		end

		local handPos
		if isLeft then
			handPos = vrmod.GetLeftHandPose(ply)
		else
			handPos = vrmod.GetRightHandPose(ply)
		end

		local sphereRange = cv_sphere_range and cv_sphere_range:GetFloat() or 200
		local serverWeight = cv_weight and cv_weight:GetFloat() or 100
		local clientWeight = cv_weight_client and cv_weight_client:GetFloat() or 0
		local maxWeight = clientWeight > 0 and math.min(serverWeight, clientWeight) or serverWeight

		net.Start("vrmod_pickup_beam")
		net.WriteBool(isLeft)
		net.WriteFloat(sphereRange)
		net.WriteFloat(maxWeight)
		net.WriteVector(handPos)
		net.WriteBool(not pressed) -- gripReleased: pressed=true means grip down, so NOT pressed = released
		net.SendToServer()

		-- Do NOT return here: let subsequent hooks (vrmod.Pickup etc.) also fire
	end
)

print("[VRMod] Cone pickup assist system loaded")
--[vrmod_test_pickup_beam.lua]end--
