if SERVER then
print ("running vrmod manual item pickup") 	-- tells me that the script is running so i can sleep at night
											-- there are going to be comments everywhere
											-- this is a different take on the same addon, now with hopefully cleaner and more efficient code
local vrmod_manualpickup = CreateConVar( "vrmod_manualpickups", 1, { FCVAR_ARCHIVE,FCVAR_REPLICATED }, "vrmod manual pickup toggle" ) -- creates the convar so it can be turned on or off (default on)

hook.Add ("PlayerSpawn", "SpawnSetPickupState", function (ply)		-- sets the initial state of the addon, aswell as excluding non-VR players from being affected
	PickupDisabled = true
	PickupDisabledWeapons = true
end)

hook.Add ("VRMod_Start", "VRModPickupStartState", function (ply)	-- this gets called when a player enters VR, so this addon only affects VR players (important in multiplayer)
		IsVR = true
end)

hook.Add ("VRMod_Exit", "VRModPickupResetState", function (ply)		-- returns a player's status back to non-VR when exiting VRMod
		IsVR = false
end)

hook.Add ( "VRMod_Drop", "ManualItemPickupDropHook", function (ply, ent)
end)

hook.Add ( "VRMod_Pickup", "ManualWeaponPickupHook", function (ply, ent)
	if ent:IsWeapon() == true then
		ply:PickupWeapon(ent)
		ply:SelectWeapon(ent)
		return 
	end
end)

hook.Add ("PlayerCanPickupItem", "ItemTouchPickupDisablerVR", function( ply, item )
	if IsVR == true and PickupDisabled == true then
	return false
	end
end)

hook.Add ( "PlayerCanPickupWeapon", "WeaponTouchPickupDisablerVR", function( ply, wep)
	if IsVR == true and PickupDisabled == true and wep.VR_Pickup_Tag == false  then
	return false
	
end
end)
end