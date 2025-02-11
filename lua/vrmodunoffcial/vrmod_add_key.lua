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

            -- if action == "boolean_secondaryfire" and pressed then
            --     if g_VR.active then
            --         RunConsoleCommand("vrmod_ScrW_hud", g_VR.rt:Width() / 2)
            --         RunConsoleCommand("vrmod_ScrH_hud", g_VR.rt:Height())

            --         return
            --     end
            -- else
            --     if g_VR.active then
            --         RunConsoleCommand("vrmod_ScrW_hud", ScrW())
            --         RunConsoleCommand("vrmod_ScrH_hud", ScrH())
            --     end

            --     return
            -- end
        end
    )
end