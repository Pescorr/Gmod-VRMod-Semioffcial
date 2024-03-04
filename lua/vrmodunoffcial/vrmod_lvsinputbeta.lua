if CLIENT then
    if not LVS then return end
    local actionStates = {
        ["ENGINE"] = false,
        ["EXIT"] = false,
        ["VSPEC"] = false,
        ["CAR_REVERSE"] = false,
        ["ATTACK"] = false,
        ["CAR_THROTTLE"] = false,
        ["CAR_BRAKE"] = false,
        ["CAR_HANDBRAKE"] = false,
        ["HELI_HOVER"] = false,
        ["+THROTTLE"] = false,
        ["+THRUST_HELI"] = false,
        ["-THROTTLE"] = false,
        ["-THRUST_HELI"] = false,
        ["FREELOOK"] = false,
        ["CAR_THROTTLE_MOD"] = false,
        ["CAR_LIGHTS_TOGGLE"] = false,
        ["CAR_SWAP_AMMO"] = false,
        ["+THRUST_SF"] = false,
        ["-THRUST_SF"] = false,
        ["+VTOL_Z_SF"] = false,
        ["-VTOL_Z_SF"] = false,
        ["+VTOL_Y_SF"] = false,
        ["-VTOL_Y_SF"] = false,
        ["-VTOL_X_SF"] = false,
        ["ZOOM"] = false,
        ["cl_simfphys_keyforward"] = false,
        ["cl_simfphys_keyreverse"] = false,
        ["cl_simfphys_keyleft"] = false,
        ["cl_simfphys_keyright"] = false,
        ["cl_simfphys_keywot"] = false,
        ["cl_simfphys_keyclutch"] = false,
        ["cl_simfphys_keygearup"] = false,
        ["cl_simfphys_keygeardown"] = false,
        ["cl_simfphys_keyhandbrake"] = false,
        ["cl_simfphys_cruisecontrol"] = false,
        ["cl_simfphys_lights"] = false,
        ["cl_simfphys_foglights"] = false,
        ["cl_simfphys_keyhorn"] = false,
        ["cl_simfphys_keyengine"] = false,
        ["cl_simfphys_key_air_forward"] = false,
        ["cl_simfphys_key_air_reverse"] = false,
        ["cl_simfphys_key_air_right"] = false,
        ["cl_simfphys_key_turnmenu"] = false,
    }

    local function updateServer()
        -- プレイヤーが車両に乗っているか確認
        if LocalPlayer():InVehicle() then
            for action, state in pairs(actionStates) do
                net.Start("lvs_setinput")
                net.WriteString(action)
                net.WriteBool(state)
                net.SendToServer()
            end
        end
    end

    local usePressedTime = 0
    local pickuphandle = CreateClientConVar("vrmod_lvs_pickup_handle", "1", true)
    local useTimerRunning = false
    hook.Add(
        "VRMod_Input",
        "vrmod_LVSconcommand",
        function(action, pressed)
            -- Update action states based on input...
            -- For example:
            if action == "boolean_turbo" then
                actionStates["ENGINE"] = pressed
            end

            if action == "boolean_jump" then
                actionStates["VSPEC"] = pressed
                actionStates["CAR_REVERSE"] = pressed
            end

            if action == "boolean_primaryfire" then
                actionStates["ATTACK"] = pressed
            end

            if action == "boolean_secondaryfire" then
                actionStates["CAR_SWAP_AMMO"] = pressed
                actionStates["ZOOM"] = pressed
            end


            if action == "vector1_forward" then
                local throttleValue = vrmod.GetInput("vector1_forward") -- vector1_forward の現在の値を取得
                if throttleValue > 0 then
                    if throttleValue < 50 then
                        actionStates["CAR_THROTTLE"] = true
                        actionStates["CAR_THROTTLE_MOD"] = false
                    elseif throttleValue >= 50 then
                        actionStates["CAR_THROTTLE"] = true
                        actionStates["CAR_THROTTLE_MOD"] = true
                    end
                else
                    actionStates["CAR_THROTTLE"] = false
                    actionStates["CAR_THROTTLE_MOD"] = false
                end
            end

            if action == "vector1_reverse" then
                local throttleValue = vrmod.GetInput("vector1_reverse") -- vector1_forward の現在の値を取得
                actionStates["CAR_BRAKE"] = throttleValue > 0 -- throttleValue が 0 より大きい場合、CAR_THROTTLE を有効にする
            end


            if action == "boolean_sprint" then
                actionStates["HELI_HOVER"] = pressed
                actionStates["+PITCH_SF"] = pressed
            end

            if action == "boolean_forword" then
                actionStates["CAR_THROTTLE"] = pressed
                actionStates["CAR_THROTTLE_MOD"] = pressed
                actionStates["+THROTTLE"] = pressed
                actionStates["+THRUST_HELI"] = pressed
                actionStates["+THRUST_SF"] = pressed
                actionStates["cl_simfphys_keygearup"] = pressed
            end

            if action == "boolean_back" then
                actionStates["CAR_BRAKE"] = pressed
                actionStates["-THROTTLE"] = pressed
                actionStates["-THRUST_HELI"] = pressed
                actionStates["-THRUST_SF"] = pressed
                actionStates["-VTOL_X_SF"] = pressed
                actionStates["cl_simfphys_keygeardown"] = pressed
            end

            if action == "boolean_left" then
                actionStates["-ROLL_SF"] = pressed
                actionStates["CAR_STEER_LEFT"] = pressed
                actionStates["-ROLL_HELI"] = pressed
            end

            if action == "boolean_right" then
                actionStates["+ROLL_SF"] = pressed
                actionStates["CAR_STEER_RIGHT"] = pressed
                actionStates["+ROLL_HELI"] = pressed
            end

            if action == "boolean_back" then
                actionStates["CAR_BRAKE"] = pressed
                actionStates["-THROTTLE"] = pressed
                actionStates["-THRUST_HELI"] = pressed
                actionStates["-THRUST_SF"] = pressed
                actionStates["-VTOL_X_SF"] = pressed
            end

            if action == "boolean_handbrake" then
                actionStates["CAR_HANDBRAKE"] = pressed
                actionStates["HELI_HOVER"] = pressed
                actionStates["cl_simfphys_keyhandbrake"] = pressed
            end

            if action == "boolean_walkkey" then
                actionStates["FREELOOK"] = pressed
            end

            if pickuphandle:GetBool() then
                if action == "boolean_right_pickup" then
                    actionStates["FREELOOK"] = not pressed
                    RunConsoleCommand("lvs_mouseaim", "1")
                end
            end

            if action == "boolean_flashlight" then
                actionStates["CAR_LIGHTS_TOGGLE"] = pressed
                actionStates["cl_simfphys_lights"] = pressed
            end

            if action == "boolean_spawnmenu" and pressed then
                -- ネットワークを介してサーバーにコマンドを送信
                if LocalPlayer():InVehicle() then
                    -- 車両がLFS車両かどうか確認
                    RunConsoleCommand("vr_dummy_menu_toggle", "1") -- メニューを閉じた時にConVarをリセット
                end
            else
                RunConsoleCommand("vr_dummy_menu_toggle", "0") -- メニューを閉じた時にConVarをリセット
            end

            if action == "boolean_use" then
                if pressed then
                    if not useTimerRunning then
                        usePressedTime = CurTime()
                        useTimerRunning = true
                        timer.Create(
                            "CheckUseDuration",
                            0.1,
                            0,
                            function()
                                if CurTime() - usePressedTime > 0.4 then
                                    actionStates["EXIT"] = true
                                    useTimerRunning = false
                                    timer.Remove("CheckUseDuration")
                                    updateServer() -- 追加: サーバーへの即時更新
                                end
                            end
                        )
                    end
                else
                    if useTimerRunning then
                        useTimerRunning = false
                        usePressedTime = 0.0
                        timer.Remove("CheckUseDuration")
                    end

                    actionStates["EXIT"] = false
                    updateServer() -- 追加: サーバーへの即時更新
                end
            end

            -- Update the server with the latest states
            updateServer()
        end
    )
end