AddCSLuaFile()

if CLIENT then
	local cl_pickupdisable = CreateClientConVar("vrmod_test_entteleport_enable", 0, true, FCVAR_ARCHIVE)
	hook.Add(
		"VRMod_Input",
		"vrmod_nearentpick",
		function(action, pressed)
			if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
			if action == "boolean_left_pickup" and pressed then
				if !cl_pickupdisable:GetBool() then return end
				LocalPlayer():ConCommand("vrmod_test_pickup_entteleport_left")

				return
			end

			if action == "boolean_right_pickup" and pressed then
				if !cl_pickupdisable:GetBool() then return end
				LocalPlayer():ConCommand("vrmod_test_pickup_entteleport_right")

				return
			end
		end
	)
end