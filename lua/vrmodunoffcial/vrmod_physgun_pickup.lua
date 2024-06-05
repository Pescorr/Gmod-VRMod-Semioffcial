-- if CLIENT then
--     local convars = vrmod.GetConvars()
--     hook.Add(
--         "VRMod_Input",
--         "vrmod_custom_physgun_pickup",
--         function(action, pressed)
--             if not LocalPlayer():Alive() or LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_physgun" then return end
--             if action == "boolean_rightpickup" then
--                 if pressed then
--                     LocalPlayer():ConCommand("vrmod_LeftHand 0")
--                     LocalPlayer():ConCommand("+attack")
--                 else
--                     LocalPlayer():ConCommand("-attack")
--                 end

--                 return 
--             elseif action == "boolean_leftpickup" then
--                 if pressed then
--                     LocalPlayer():ConCommand("vrmod_LeftHand 1")
--                     LocalPlayer():ConCommand("+attack")
--                 else
--                     LocalPlayer():ConCommand("-attack")
--                 end

--                 return 
--             end
--         end
--     )

--     hook.Add(
--         "VRMod_Pickup",
--         "vrmod_disable_default_pickup",
--         function(ply, ent)
--             if ply == LocalPlayer() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" then
--                 LocalPlayer():ConCommand("vr_pickup_disable_client 1")
--             end
--         end
--     )

--     -- physgunまたはgravitygunを装備している時だけ専用のviewmodelを使う
--     hook.Add(
--         "PreDrawViewModel",
--         "CustomPhysgunViewModel",
--         function(vm, ply, wep)
--             if wep:GetClass() == "weapon_physgun" or wep:GetClass() == "weapon_physcannon" then
--                 vm:SetModelScale(0.1, 0) -- サイズを0.1倍に
--             end
--         end
--     )


-- end