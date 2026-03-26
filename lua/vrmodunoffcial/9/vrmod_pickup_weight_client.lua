--[vrmod_pickup_weight_client.lua]start--
-- Client-side weight and limit controls for VR pickup
-- Weight: effective = min(server, client) — lower value wins (more restrictive)
-- Limit:  effective = max(server, client) — higher value wins (more restrictive)
-- When client value is 0 (default), only server setting applies
AddCSLuaFile()

-- Client ConVars (0 = disabled, use server setting only)
CreateClientConVar("vrmod_unoff_pickup_weight_client", 0, true, FCVAR_ARCHIVE, "Client-side max pickup weight (0=disabled)", 0, 99999)
CreateClientConVar("vrmod_unoff_pickup_limit_client", 0, true, FCVAR_ARCHIVE, "Client-side pickup limit level (0=disabled, 1=standard, 2=strict, 3=off)", 0, 3)

-----------------------------------------------------------------------
-- SERVER: VRMod_Pickup hook to enforce client weight + limit
-----------------------------------------------------------------------
if SERVER then
	hook.Add("VRMod_Pickup", "vrmod_unoff_pickup_client_restrictions", function(ply, ent)
		if not IsValid(ply) or not IsValid(ent) then return end

		-- Client weight limit
		local clientWeight = ply:GetInfoNum("vrmod_unoff_pickup_weight_client", 0)
		if clientWeight > 0 then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) and phys:GetMass() > clientWeight then
				return false
			end
		end

		-- Client pickup limit (higher = stricter)
		local clientLimit = ply:GetInfoNum("vrmod_unoff_pickup_limit_client", 0)
		if clientLimit <= 0 then return end

		-- Level 3: disable all pickup
		if clientLimit >= 3 then return false end

		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) then return false end

		-- Level 1+: require MOVETYPE_VPHYSICS
		if clientLimit >= 1 then
			if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
		end

		-- Level 2+: require moveable, no multiobject, CPPI check
		if clientLimit >= 2 then
			if not phys:IsMoveable() then return false end
			if phys:HasGameFlag(FVPHYSICS_MULTIOBJECT_ENTITY) then return false end
			if ent.CPPICanPickup and not ent:CPPICanPickup(ply) then return false end
		end
	end)
end
--[vrmod_pickup_weight_client.lua]end--
