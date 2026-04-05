--[vrmod_pickup_rotation.lua]start--
-- Held entity rotation control via secondary fire + hand movement
-- Press secondary fire while holding a vrmod_pickup entity:
--   speed=0 (default): Stabilize mode. Entity maintains world orientation.
--     Move your hand while holding the button, release to "re-grip".
--   speed=1: Normal hand-follow behavior (pressing button has no effect).
--   speed>1: Amplified rotation.
-- ConVar vrmod_unoff_rotate_held_enable: 0=off (original), 1=on
AddCSLuaFile()

-- ConVars (shared: client creates, server reads via GetInfoNum)
CreateClientConVar("vrmod_unoff_rotate_held_enable", 1, true, FCVAR_ARCHIVE, "Enable held entity rotation (secondary fire + hand movement)", 0, 1)
CreateClientConVar("vrmod_unoff_rotate_held_speed", 0, true, FCVAR_ARCHIVE, "Rotation speed (0=stabilize/re-grip, 1=normal follow)", 0, 3.0)

-----------------------------------------------------------------------
-- SERVER
-----------------------------------------------------------------------
if SERVER then
	if util == nil then return end

	util.AddNetworkString("vrmod_pickup_rotate")
	util.AddNetworkString("vrmod_pickup_rotate_update")

	-- Active rotation sessions: key = "STEAM_X:Y:Z_L" or "_R"
	local activeRotations = {}

	-- Get hand world angle from VR tracking data
	local function GetHandWorldAng(steamid, ply, isLeft)
		local frame = g_VR[steamid] and g_VR[steamid].latestFrame
		if not frame then return nil end
		local handLocalPos = isLeft and frame.lefthandPos or frame.righthandPos
		local handLocalAng = isLeft and frame.lefthandAng or frame.righthandAng
		local _, handAng = LocalToWorld(handLocalPos, handLocalAng, ply:GetPos(), Angle())
		return handAng
	end

	net.Receive("vrmod_pickup_rotate", function(len, ply)
		if not IsValid(ply) or ply:InVehicle() then return end
		local steamid = ply:SteamID()
		if not g_VR[steamid] then return end

		local isLeft = net.ReadBool()
		local startRotation = net.ReadBool()
		local key = steamid .. (isLeft and "_L" or "_R")

		if startRotation then
			local speed = math.Clamp(net.ReadFloat(), 0, 3)
			local slot = isLeft and 1 or 2
			if not g_VR[steamid].heldItems then return end
			local item = g_VR[steamid].heldItems[slot]
			if not item or not IsValid(item.ent) then return end

			local handAng = GetHandWorldAng(steamid, ply, isLeft)
			if not handAng then return end

			-- Record the entity's current world orientation as the stabilization target
			local _, baseWorldAng = LocalToWorld(Vector(), item.localAng, Vector(), handAng)

			activeRotations[key] = {
				ply = ply,
				steamid = steamid,
				isLeft = isLeft,
				item = item,
				baseWorldAng = baseWorldAng,
				baseLocalAng = Angle(item.localAng.p, item.localAng.y, item.localAng.r),
				speed = speed,
				lastBroadcast = 0,
			}
		else
			activeRotations[key] = nil
		end
	end)

	-- Tick: continuously compute stabilized localAng for active rotations
	hook.Add("Tick", "vrmod_unoff_rotate_tick", function()
		for key, rot in pairs(activeRotations) do
			-- Validate session is still valid
			if not IsValid(rot.ply) or not g_VR[rot.steamid] then
				activeRotations[key] = nil
				continue
			end
			local slot = rot.isLeft and 1 or 2
			local items = g_VR[rot.steamid].heldItems
			if not items or items[slot] ~= rot.item or not IsValid(rot.item.ent) then
				activeRotations[key] = nil
				continue
			end

			local currentHandAng = GetHandWorldAng(rot.steamid, rot.ply, rot.isLeft)
			if not currentHandAng then continue end

			-- Stabilized localAng: keeps entity at its original world orientation
			local _, stabilizedLocalAng = WorldToLocal(Vector(), rot.baseWorldAng, Vector(), currentHandAng)

			-- Blend: speed=0 → stabilized (re-grip), speed=1 → baseLocalAng (normal follow)
			local newLocalAng = LerpAngle(rot.speed, stabilizedLocalAng, rot.baseLocalAng)

			rot.item.localAng.p = newLocalAng.p
			rot.item.localAng.y = newLocalAng.y
			rot.item.localAng.r = newLocalAng.r

			-- Rate-limited broadcast to clients for RenderOverride
			local now = CurTime()
			if now - rot.lastBroadcast >= 0.05 then
				rot.lastBroadcast = now
				net.Start("vrmod_pickup_rotate_update")
				net.WriteEntity(rot.ply)
				net.WriteEntity(rot.item.ent)
				net.WriteBool(rot.isLeft)
				net.WriteVector(rot.item.localPos)
				net.WriteAngle(rot.item.localAng)
				net.Broadcast()
			end
		end
	end)

	-- Cleanup on drop
	hook.Add("VRMod_Drop", "vrmod_unoff_rotate_drop_cleanup", function(ply, ent)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		for _, suffix in ipairs({"_L", "_R"}) do
			local key = steamid .. suffix
			if activeRotations[key] and activeRotations[key].item and activeRotations[key].item.ent == ent then
				activeRotations[key] = nil
			end
		end
	end)

	-- Cleanup on VR exit
	hook.Add("VRMod_Exit", "vrmod_unoff_rotate_exit_cleanup", function(ply)
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		activeRotations[steamid .. "_L"] = nil
		activeRotations[steamid .. "_R"] = nil
	end)

	return
end

-----------------------------------------------------------------------
-- CLIENT
-----------------------------------------------------------------------

-- ConVar cache
local cv_enable, cv_speed

local function EnsureConVars()
	if cv_enable then return end
	cv_enable = GetConVar("vrmod_unoff_rotate_held_enable")
	cv_speed = GetConVar("vrmod_unoff_rotate_held_speed")
end

-- Track which hands are in rotation mode (for cleanup)
local rotatingHands = { left = false, right = false }

-- Check if vrmod_pickup is holding something in this hand (not physgun)
local function IsVRPickupHolding(isLeft)
	if not g_VR then return false end
	local key = isLeft and "heldEntityLeft" or "heldEntityRight"
	return IsValid(g_VR[key])
end

local function IsPhysgunHolding(isLeft)
	if not g_VR then return false end
	local key = isLeft and "physgunHeldEntity_left" or "physgunHeldEntity_right"
	return IsValid(g_VR[key])
end

-- VRMod_Input: detect secondary fire → send start/stop to server
hook.Add("VRMod_Input", "vrmod_unoff_rotate_input", function(action, pressed)
	EnsureConVars()
	if not cv_enable or not cv_enable:GetBool() then return end
	if not g_VR or not g_VR.active then return end

	local isLeft
	if action == "boolean_left_secondaryfire" then
		isLeft = true
	elseif action == "boolean_secondaryfire" then
		isLeft = false
	else
		return
	end

	local side = isLeft and "left" or "right"
	local ply = LocalPlayer()
	if not IsValid(ply) or ply:InVehicle() then return end

	if pressed then
		if IsVRPickupHolding(isLeft) and not IsPhysgunHolding(isLeft) then
			local speed = cv_speed and cv_speed:GetFloat() or 0
			net.Start("vrmod_pickup_rotate")
			net.WriteBool(isLeft)
			net.WriteBool(true) -- start
			net.WriteFloat(speed)
			net.SendToServer()
			rotatingHands[side] = true
		end
	else
		if rotatingHands[side] then
			net.Start("vrmod_pickup_rotate")
			net.WriteBool(isLeft)
			net.WriteBool(false) -- stop
			net.SendToServer()
			rotatingHands[side] = false
		end
	end

	-- Do NOT return: let other hooks handle secondary fire too
end)

-- Receive rotation updates from server: update RenderOverride
net.Receive("vrmod_pickup_rotate_update", function()
	local ply = net.ReadEntity()
	local ent = net.ReadEntity()
	local bLeftHand = net.ReadBool()
	local newLocalPos = net.ReadVector()
	local newLocalAng = net.ReadAngle()

	if not IsValid(ent) or not IsValid(ply) then return end

	-- Store updated values on entity
	ent.vrmod_rot_steamid = ply:SteamID()
	ent.vrmod_rot_lefthand = bLeftHand
	ent.vrmod_rot_localPos = newLocalPos
	ent.vrmod_rot_localAng = newLocalAng

	-- Create render function once per entity, store it for reuse
	if not ent.vrmod_rot_renderFunc then
		ent.vrmod_rot_renderFunc = function()
			local sid = ent.vrmod_rot_steamid
			if not sid or not g_VR or not g_VR.net or not g_VR.net[sid] then return end
			local frame = g_VR.net[sid].lerpedFrame
			if not frame then return end
			local wpos, wang
			if ent.vrmod_rot_lefthand then
				wpos, wang = LocalToWorld(ent.vrmod_rot_localPos, ent.vrmod_rot_localAng, frame.lefthandPos, frame.lefthandAng)
			else
				wpos, wang = LocalToWorld(ent.vrmod_rot_localPos, ent.vrmod_rot_localAng, frame.righthandPos, frame.righthandAng)
			end
			ent:SetPos(wpos)
			ent:SetAngles(wang)
			ent:SetupBones()
			ent:DrawModel()
		end
	end
	-- ALWAYS reassign: vrmod.Pickup re-pick may have overwritten with a new closure
	ent.RenderOverride = ent.vrmod_rot_renderFunc
	ent.VRPickupRenderOverride = ent.vrmod_rot_renderFunc
end)

-- Cleanup rotation state on drop
hook.Add("VRMod_Drop", "vrmod_unoff_rotate_cleanup", function(ply, ent)
	if IsValid(ent) then
		ent.vrmod_rot_steamid = nil
		ent.vrmod_rot_lefthand = nil
		ent.vrmod_rot_localPos = nil
		ent.vrmod_rot_localAng = nil
		ent.vrmod_rot_renderFunc = nil
	end
	if ply == LocalPlayer() then
		rotatingHands.left = false
		rotatingHands.right = false
	end
end)

-- Cleanup on VR exit
hook.Add("VRMod_Exit", "vrmod_unoff_rotate_exit", function()
	rotatingHands.left = false
	rotatingHands.right = false
end)

print("[VRMod] Held entity rotation control loaded")
--[vrmod_pickup_rotation.lua]end--
