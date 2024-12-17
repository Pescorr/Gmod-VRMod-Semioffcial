AddCSLuaFile()

if CLIENT then
	local cl_pickupdisable = CreateClientConVar("vrmod_pickup_beam_enable", 1, true, FCVAR_ARCHIVE)
	hook.Add(
		"VRMod_Input",
		"vrmod_pickup_beam",
		function(action, pressed)
			if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
			if action == "boolean_left_pickup" and pressed then
				if !cl_pickupdisable:GetBool() then return end
				LocalPlayer():ConCommand("vrmod_pickup_beam_left")

				return
			end

			if action == "boolean_right_pickup" and pressed then
				if !cl_pickupdisable:GetBool() then return end
				LocalPlayer():ConCommand("vrmod_pickup_beam_right")

				return
			end
		end
	)
end

