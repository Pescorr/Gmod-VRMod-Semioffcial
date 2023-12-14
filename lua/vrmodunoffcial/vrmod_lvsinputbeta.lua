if CLIENT then
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
        ["ZOOM"] = false,
    }

    local function updateServer()
        for action, state in pairs(actionStates) do
            net.Start("lvs_setinput")
            net.WriteString(action)
            net.WriteBool(state)
            net.SendToServer()
        end
    end

    local usePressedTime = 0
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

            -- if action == "boolean_right_pickup" then
            --     actionStates["FREELOOK"] = not pressed
            -- end

            if action == "boolean_forword" then
                actionStates["CAR_THROTTLE"] = pressed
                actionStates["CAR_THROTTLE_MOD"] = pressed
                actionStates["+THROTTLE"] = pressed
                actionStates["+THRUST_HELI"] = pressed
            end

            if action == "boolean_back" then
                actionStates["CAR_BRAKE"] = pressed
                actionStates["-THROTTLE"] = pressed
                actionStates["-THRUST_HELI"] = pressed
            end

            if action == "boolean_handbrake" then
                actionStates["CAR_HANDBRAKE"] = pressed
                actionStates["HELI_HOVER"] = pressed
            end

            if action == "boolean_walkkey" then
                actionStates["FREELOOK"] = pressed
            end

            if action == "boolean_flashlight" then
                actionStates["CAR_LIGHTS_TOGGLE"] = pressed
            end

            if action == "boolean_spawnmenu" then
                actionStates["CAR_SWAP_AMMO"] = pressed
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
                                if CurTime() - usePressedTime > 0.2 then
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