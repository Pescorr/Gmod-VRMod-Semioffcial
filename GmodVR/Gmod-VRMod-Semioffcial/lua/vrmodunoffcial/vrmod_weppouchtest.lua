g_VR = g_VR or {}
vrmod = vrmod or {}
local convars = vrmod.GetConvars()



		-- pes pouch test
		
hook.Add("VRMod_Input","vrutil_hook_weppouchtest",function( action, pressed )

	if convars.vrmod_floatinghands:GetBool() then return end
	
	
		-- pes pouch test
		local wep3pouchbone = "ValveBiped.Bip01_Spine2"
		local wep3pouchsize = GetConVar("arcticvr_hybridpouchdist"):GetFloat()
		local wep3pouchdist = g_VR.eyePosRight
		if (LocalPlayer():LookupBone(wep3pouchbone) && LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(wep3pouchbone))) then
			wep3pouchdist = LocalToWorld(Vector(3,3,0), Angle(0,0,0),
			LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(wep3pouchbone)):GetTranslation(),
			Angle(0,g_VR.characterYaw,0))
		
			if g_VR.tracking.pose_righthand.pos:DistToSqr(wep3pouchdist) < (wep3pouchsize * wep3pouchsize) then
				if action == "boolean_right_pickup" and pressed then
					LocalPlayer():ConCommand("slot3")
				end
			end
		end

		-- pes pouch end
		
		-- pes pouch test
		local wep2pouchbone = "ValveBiped.Bip01_Pelvis"
		local wep2pouchsize = GetConVar("arcticvr_defpouchdist"):GetFloat()
		local wep2pouchdist = g_VR.eyePosRight
		if (LocalPlayer():LookupBone(wep2pouchbone) && LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(wep2pouchbone))) then
			wep2pouchdist = LocalToWorld(Vector(3,3,0), Angle(0,0,0),
			LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(wep2pouchbone)):GetTranslation(),
			Angle(0,g_VR.characterYaw,0))
		
			if g_VR.tracking.pose_righthand.pos:DistToSqr(wep2pouchdist) < (wep2pouchsize * wep2pouchsize) then
				if action == "boolean_right_pickup" and pressed then
					LocalPlayer():ConCommand("slot2")
				end
			end
		end

		-- pes pouch end

		-- pes pouch test
		local wep4pouchbone = "ValveBiped.Bip01_Head1"
		local wep4pouchsize = GetConVar("arcticvr_headpouchdist"):GetFloat()
		local wep4pouchdist = g_VR.eyePosRight
		if (LocalPlayer():LookupBone(wep4pouchbone) && LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(wep4pouchbone))) then
			wep4pouchdist = LocalToWorld(Vector(3,3,0), Angle(0,0,0),
			LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(wep4pouchbone)):GetTranslation(),
			Angle(0,g_VR.characterYaw,0))
		
			if g_VR.tracking.pose_righthand.pos:DistToSqr(wep4pouchdist) < (wep4pouchsize * wep4pouchsize) then
				if action == "boolean_right_pickup" and pressed then
					LocalPlayer():ConCommand("slot4")
				end
			end
		end

		-- pes pouch end

		

end)

