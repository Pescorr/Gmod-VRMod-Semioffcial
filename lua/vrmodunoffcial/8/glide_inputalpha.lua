-- if CLIENT then
--     -- Glide vehicle input handler for VR
--     util.AddNetworkString("glide_vrsetinput")

--     local actionStates = {
--         -- Land vehicle controls
--         ["accelerate"] = false,
--         ["brake"] = false,
--         ["steer_left"] = false, 
--         ["steer_right"] = false,
--         ["handbrake"] = false,
--         ["horn"] = false,
--         ["headlights"] = false,
--         ["reduce_throttle"] = false,
--         ["shift_up"] = false,
--         ["shift_down"] = false,
--         ["shift_neutral"] = false,

--         -- Aircraft controls 
--         ["pitch_up"] = false,
--         ["pitch_down"] = false,
--         ["yaw_left"] = false,
--         ["yaw_right"] = false,
--         ["roll_left"] = false,
--         ["roll_right"] = false,
--         ["throttle_up"] = false,
--         ["throttle_down"] = false,
--         ["attack"] = false,
--         ["attack_alt"] = false,
--         ["free_look"] = false,
--         ["landing_gear"] = false,
--         ["countermeasures"] = false,

--         -- General controls
--         ["switch_weapon"] = false
--     }

--     -- サーバーに入力状態を送信
--     local function updateServer()
--         local vehicle = LocalPlayer():GetNWEntity("GlideVehicle")
--         if IsValid(vehicle) then
--             for action, state in pairs(actionStates) do
--                 net.Start("glide_vrsetinput")
--                 net.WriteString(action)
--                 net.WriteBool(state)
--                 net.SendToServer()
--             end
--         end
--     end

--     -- VR入力を処理
--     hook.Add("VRMod_Input", "vrmod_glide_input", function(action, pressed)
--         if action == "boolean_primaryfire" then
--             actionStates["attack"] = pressed
--         end

--         if action == "boolean_secondaryfire" then
--             actionStates["attack_alt"] = pressed
--         end

--         if action == "boolean_forword" then
--             actionStates["accelerate"] = pressed
--             actionStates["throttle_up"] = pressed
--         end

--         if action == "boolean_back" then
--             actionStates["brake"] = pressed
--             actionStates["throttle_down"] = pressed
--         end

--         if action == "boolean_left" then
--             actionStates["steer_left"] = pressed
--             actionStates["yaw_left"] = pressed
--             actionStates["roll_left"] = pressed
--         end

--         if action == "boolean_right" then
--             actionStates["steer_right"] = pressed
--             actionStates["yaw_right"] = pressed
--             actionStates["roll_right"] = pressed
--         end

--         if action == "boolean_sprint" then
--             actionStates["handbrake"] = pressed
--         end

--         if action == "boolean_walkkey" then
--             actionStates["free_look"] = pressed
--         end

--         if action == "boolean_use" then
--             -- Vehicle exit handling
--             if pressed then
--                 timer.Create("GlideVRExit", 0.4, 1, function()
--                     if vrmod.IsPlayerInVR() then
--                         local vehicle = LocalPlayer():GetNWEntity("GlideVehicle") 
--                         if IsValid(vehicle) then
--                             LocalPlayer():ExitVehicle()
--                         end
--                     end
--                 end)
--             else
--                 timer.Remove("GlideVRExit")
--             end
--         end

--         updateServer()
--     end)
-- end