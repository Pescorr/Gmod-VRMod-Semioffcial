if CLIENT then
    hook.Add(
        "VRMod_Input",
        "vrutil_novrweapon",
        function(action, pressed)
            if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end

            if action == "boolean_chat" and pressed then
                LocalPlayer():ConCommand("arccw_firemode")

                return
            end
            if action == "boolean_flashlight" and pressed then
                LocalPlayer():ConCommand("arccw_toggle_ubgl")

                return
            end

        end
    )

end