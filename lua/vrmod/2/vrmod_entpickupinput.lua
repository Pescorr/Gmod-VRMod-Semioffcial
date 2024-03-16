if SERVER then return end
local cl_pickupdisable = CreateClientConVar("vrmod_test_entteleport_enable", 0, true, FCVAR_ARCHIVE)
hook.Add(
	"VRMod_Input",
	"vrutil_nearentpick",
	function(action, pressed)
		if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
		if action == "boolean_left_pickup" then
			if not cl_pickupdisable:GetBool() then return end
			LocalPlayer():ConCommand(pressed and "vrmod_test_pickup_entteleport_left" or "-use")

			return
		end

		if action == "boolean_right_pickup" then
			if not cl_pickupdisable:GetBool() then return end
			LocalPlayer():ConCommand(pressed and "vrmod_test_pickup_entteleport_right" or "-use")

			return
		end
	end
)