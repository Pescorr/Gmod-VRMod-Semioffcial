-- --------[vrmod_lvs_inputbeta.lua]Start--------
-- -- クライアント側: 通常のLVS操作（特殊操作を除く）の状態管理と送信
-- if CLIENT then
--     if not LVS then return end
--     if not g_VR then return end
--     local lvsInputMode = GetConVar("vrmod_lvs_input_mode")

--     function vrmod_lvs_input_singleplay()
--         local lvsautosetting = CreateClientConVar("vrmod_auto_lvs_keysetings", 1, true, FCVAR_ARCHIVE)
--         local pickuphandle = CreateClientConVar("vrmod_lvs_pickup_handle", "1", true, FCVAR_ARCHIVE)
--         local actionStates = {
--             ["ENGINE"] = false,
--             ["EXIT"] = false,
--             ["VSPEC"] = false,
--             ["CAR_REVERSE"] = false,
--             ["ATTACK"] = false,
--             ["CAR_THROTTLE"] = false,
--             ["CAR_THROTTLE_MOD"] = false,
--             ["CAR_BRAKE"] = false,
--             ["CAR_HANDBRAKE"] = false,
--             ["CAR_LIGHTS_TOGGLE"] = false,
--             ["HELI_HOVER"] = false,
--             ["ZOOM"] = false,
--             ["FREELOOK"] = false,
--             ["+THROTTLE"] = false,
--             ["-THROTTLE"] = false,
--             ["+THRUST_HELI"] = false,
--             ["-THRUST_HELI"] = false,
--             ["+THRUST_SF"] = false,
--             ["-THRUST_SF"] = false,
--             ["+VTOL_Z_SF"] = false,
--             ["-VTOL_Z_SF"] = false,
--             ["+VTOL_Y_SF"] = false,
--             ["-VTOL_Y_SF"] = false,
--             ["-VTOL_X_SF"] = false,
--             ["CAR_SWAP_AMMO"] = false,
--             ["~SELECT~WEAPON#1"] = false,
--             ["~SELECT~WEAPON#2"] = false,
--             ["~SELECT~WEAPON#3"] = false,
--             ["~SELECT~WEAPON#4"] = false,
--         }

--         -- 車両タイプを判定する関数を追加
--         local function GetVehicleType()
--             if not g_VR.active then return end
--             local vehicle = LocalPlayer():lvsGetVehicle()
--             if not IsValid(vehicle) then return nil end
--             -- エンティティ名に "wheeldrive" が含まれているかチェック
--             if string.find(string.lower(vehicle:GetClass()), "wheeldrive") then return true end

--             return false
--         end

--         local function updateServer()
--             if LocalPlayer():InVehicle() then
--                 for action, state in pairs(actionStates) do
--                     net.Start("lvs_setinput")
--                     net.WriteString(action)
--                     net.WriteBool(state)
--                     net.SendToServer()
--                 end
--             end
--         end

--         local function handleVectorInput()
--             if not g_VR then return end
--                         if not g_VR.active then return end

--             local forward = g_VR.input.vector1_forward or 0
--             local reverse = g_VR.input.vector1_reverse or 0
--             if forward > 0 then
--                 if forward < 0.5 then
--                     actionStates["CAR_THROTTLE"] = true
--                     actionStates["CAR_THROTTLE_MOD"] = false
--                 else
--                     actionStates["CAR_THROTTLE"] = true
--                     actionStates["CAR_THROTTLE_MOD"] = true
--                 end
--             else
--                 actionStates["CAR_THROTTLE"] = false
--                 actionStates["CAR_THROTTLE_MOD"] = false
--             end

--             actionStates["CAR_BRAKE"] = reverse > 0
--             updateServer()
--         end

--         local usePressedTime = 0
--         local useTimerRunning = false
--         local lvsselectwep = 0
--         hook.Add("Think", "VRMod_LVS_VectorInput", handleVectorInput)
--         hook.Add(
--             "VRMod_Input",
--             "vrmod_LVSconcommand",
--             function(action, pressed)
--                 if action == "boolean_turbo" then
--                     actionStates["ENGINE"] = pressed
--                 end

--                 if action == "boolean_jump" then
--                     actionStates["VSPEC"] = pressed
--                 end

--                 if GetVehicleType() == true then
--                     if action == "boolean_right_pickup" then
--                         actionStates["VSPEC"] = pressed
--                     end

--                     if action == "boolean_secondaryfire" then
--                         actionStates["ATTACK"] = pressed
--                     end
--                 else
--                     if action == "boolean_primaryfire" then
--                         actionStates["ATTACK"] = pressed
--                     end
--                 end

--                 if action == "boolean_sprint" then
--                     actionStates["HELI_HOVER"] = pressed
--                     actionStates["+PITCH_SF"] = pressed
--                 end

--                 if action == "boolean_forword" then
--                     actionStates["+THROTTLE"] = pressed
--                     actionStates["+THRUST_HELI"] = pressed
--                     actionStates["+THRUST_SF"] = pressed
--                     actionStates["cl_simfphys_keygearup"] = pressed
--                 end

--                 if action == "boolean_back" then
--                     actionStates["-THROTTLE"] = pressed
--                     actionStates["-THRUST_HELI"] = pressed
--                     actionStates["-THRUST_SF"] = pressed
--                     actionStates["-VTOL_X_SF"] = pressed
--                     actionStates["cl_simfphys_keygeardown"] = pressed
--                 end

--                 if action == "boolean_left" then
--                     actionStates["-ROLL_SF"] = pressed
--                     actionStates["CAR_STEER_LEFT"] = pressed
--                     actionStates["-ROLL_HELI"] = pressed
--                 end

--                 if action == "boolean_right" then
--                     actionStates["+ROLL_SF"] = pressed
--                     actionStates["CAR_STEER_RIGHT"] = pressed
--                     actionStates["+ROLL_HELI"] = pressed
--                 end

--                 if action == "boolean_handbrake" then
--                     actionStates["CAR_HANDBRAKE"] = pressed
--                     actionStates["HELI_HOVER"] = pressed
--                     actionStates["cl_simfphys_keyhandbrake"] = pressed
--                 end

--                 if pickuphandle:GetBool() then
--                     if action == "boolean_right_pickup" then
--                         actionStates["FREELOOK"] = not pressed
--                     end
--                 end

--                 if action == "boolean_walkkey" then
--                     actionStates["CAR_SWAP_AMMO"] = pressed
--                     actionStates["ZOOM"] = pressed
--                 end

--                 if action == "boolean_flashlight" then
--                     actionStates["CAR_LIGHTS_TOGGLE"] = pressed
--                     actionStates["cl_simfphys_lights"] = pressed
--                 end

--                 if action == "boolean_spawnmenu" then
--                     if pressed then
--                         -- ネットワークを介してサーバーにコマンドを送信
--                         if LocalPlayer():InVehicle() then
--                             RunConsoleCommand("vr_dummy_menu_toggle", "1") -- メニューを閉じた時にConVarをリセット
--                         end
--                     else
--                         RunConsoleCommand("vr_dummy_menu_toggle", "0") -- メニューを閉じた時にConVarをリセット
--                     end
--                 end

--                 if action == "boolean_use" then
--                     if pressed then
--                         if not useTimerRunning then
--                             usePressedTime = CurTime()
--                             useTimerRunning = true
--                             timer.Create(
--                                 "CheckUseDuration",
--                                 0.1,
--                                 0,
--                                 function()
--                                     if CurTime() - usePressedTime > 0.4 then
--                                         actionStates["EXIT"] = true
--                                         useTimerRunning = false
--                                         timer.Remove("CheckUseDuration")
--                                         updateServer() -- 追加: サーバーへの即時更新
--                                     end
--                                 end
--                             )
--                         end
--                     else
--                         if useTimerRunning then
--                             useTimerRunning = false
--                             usePressedTime = 0.0
--                             timer.Remove("CheckUseDuration")
--                         end

--                         actionStates["EXIT"] = false
--                         updateServer() -- 追加: サーバーへの即時更新
--                     end
--                 end

--                 -- 追加: boolean_changeweaponアクションの処理
--                 if action == "boolean_changeweapon" then
--                     if pressed then
--                         if lvsselectwep == 0 then
--                             actionStates["~SELECT~WEAPON#1"] = true
--                             gui.InternalMousePressed(MOUSE_WHEEL_DOWN)
--                             lvsselectwep = 1
--                         elseif lvsselectwep == 1 then
--                             actionStates["~SELECT~WEAPON#2"] = true
--                             gui.InternalMousePressed(MOUSE_WHEEL_UP)
--                             lvsselectwep = 2
--                         elseif lvsselectwep == 2 then
--                             actionStates["~SELECT~WEAPON#3"] = true
--                             gui.InternalMousePressed(MOUSE_MIDDLE)
--                             lvsselectwep = 3
--                         elseif lvsselectwep == 3 then
--                             actionStates["~SELECT~WEAPON#4"] = true
--                             gui.InternalMousePressed(MOUSE_4)
--                             lvsselectwep = 4
--                         elseif lvsselectwep == 4 then
--                             lvsselectwep = 0
--                         end
--                     else
--                         actionStates["~SELECT~WEAPON#1"] = false
--                         actionStates["~SELECT~WEAPON#2"] = false
--                         actionStates["~SELECT~WEAPON#3"] = false
--                         actionStates["~SELECT~WEAPON#4"] = false
--                     end
--                 end

--                 -- Update the server with the latest states
--                 updateServer()
--             end
--         )
--     end

--     -- 車両に乗っている場合、VRModの入力を有効にする
--         vrmod_lvs_input_singleplay()
-- end
-- --------[vrmod_lvs_inputbeta.lua]End--------