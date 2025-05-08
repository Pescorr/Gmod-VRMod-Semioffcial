--------[vrmod_lvs_inputbeta.lua]Start--------
-- クライアント側: 通常のLVS操作（特殊操作を除く）の状態管理と送信
if CLIENT then
    if not LVS then return end
    if not g_VR then return end
    local lvsInputMode = GetConVar("vrmod_lvs_input_mode")
    function vrmod_lvs_input_multiplay()
        local lvsautosetting = CreateClientConVar("vrmod_auto_lvs_keysetings", 1, true, FCVAR_ARCHIVE)
        local pickuphandle = CreateClientConVar("vrmod_lvs_pickup_handle", "1", true, FCVAR_ARCHIVE)
        local actionStates = {
            -- 特殊操作 (EXIT, WEAPON SELECT) はここでは管理しない
            ["ENGINE"] = false,
            ["VSPEC"] = false,
            ["ATTACK"] = false,
            ["CAR_THROTTLE"] = false,
            ["CAR_THROTTLE_MOD"] = false,
            ["CAR_BRAKE"] = false,
            ["CAR_HANDBRAKE"] = false,
            ["CAR_LIGHTS_TOGGLE"] = false,
            ["HELI_HOVER"] = false,
            ["ZOOM"] = false,
            ["FREELOOK"] = false,
            ["+THROTTLE"] = false,
            ["-THROTTLE"] = false,
            ["+THRUST_HELI"] = false,
            ["-THRUST_HELI"] = false,
            ["+THRUST_SF"] = false,
            ["-THRUST_SF"] = false,
            ["+VTOL_Z_SF"] = false,
            ["-VTOL_Z_SF"] = false,
            ["+VTOL_Y_SF"] = false,
            ["-VTOL_Y_SF"] = false,
            ["-VTOL_X_SF"] = false,
            ["CAR_SWAP_AMMO"] = false,
            -- Simfphys 用のキー入力もactionStatesに含める（もし必要なら）
            ["cl_simfphys_keygearup"] = false,
            ["cl_simfphys_keygeardown"] = false,
            ["cl_simfphys_keyhandbrake"] = false,
            ["cl_simfphys_lights"] = false,
        }

        local function GetVehicleType()
            if not g_VR.active then return end
            local vehicle = LocalPlayer():lvsGetVehicle()
            if not IsValid(vehicle) then return nil end
            if string.find(string.lower(vehicle:GetClass()), "wheeldrive") then return true end

            return false
        end

        -- Thinkフック: 全ての状態を一定間隔で送信
        local lastLvsThinkSentTime = 0
        local lvsSendInterval = 0.05 -- 50ms
        hook.Add(
            "Think",
            "VRMod_LVS_ThinkUpdate_multiplay",
            function()
                if not g_VR or not g_VR.active or not g_VR.input or not LocalPlayer():InVehicle() then return end
                if not IsValid(LocalPlayer():lvsGetVehicle()) then return end
                local now = CurTime()
                if now - lastLvsThinkSentTime > lvsSendInterval then
                    -- ベクトル入力（アクセル/ブレーキ）の状態を更新
                    local forward = g_VR.input.vector1_forward or 0
                    local reverse = g_VR.input.vector1_reverse or 0
                    actionStates["CAR_THROTTLE"] = forward > 0
                    actionStates["CAR_THROTTLE_MOD"] = actionStates["CAR_THROTTLE"] and forward >= 0.5
                    actionStates["CAR_BRAKE"] = reverse > 0
                    -- FREELOOK 状態を更新
                    local pickuphandle_cv = GetConVar("vrmod_lvs_pickup_handle")
                    if pickuphandle_cv and pickuphandle_cv:GetBool() then
                        actionStates["FREELOOK"] = not (g_VR.input.boolean_right_pickup or false) -- boolean_right_pickup が nil の場合 false
                    else
                        actionStates["FREELOOK"] = g_VR.input.boolean_walkkey or false -- boolean_walkkey が nil の場合 false
                    end

                    -- 全ての状態を送信
                    net.Start("lvs_setinput_batch")
                    net.WriteTable(actionStates) -- EXIT と WEAPON SELECT を含まないテーブルを送信
                    net.SendToServer()
                    lastLvsThinkSentTime = now
                end
            end
        )

        -- VRMod_Inputフック: ブール入力の状態変化時にactionStatesを更新 (特殊操作を除く)
        hook.Add(
            "VRMod_Input",
            "vrmod_LVSconcommand_multiplay",
            function(action, pressed)
                if not LocalPlayer():InVehicle() then return end
                if not IsValid(LocalPlayer():lvsGetVehicle()) then return end
                -- boolean_use と boolean_changeweapon は special ファイルで処理するため、ここでは何もしない
                if action == "boolean_use" or action == "boolean_changeweapon" then return end
                -- その他のLVS関連のアクションの状態を actionStates で更新
                if action == "boolean_turbo" then
                    actionStates["ENGINE"] = pressed
                elseif action == "boolean_jump" then
                    actionStates["VSPEC"] = pressed
                elseif GetVehicleType() == true then
                    -- ... (GetVehicleTypeとVSPECの状態に応じたATTACK処理) ...
                    if action == "boolean_right_pickup" then
                        actionStates["VSPEC"] = pressed
                    end

                    if action == "boolean_secondaryfire" then
                        actionStates["ATTACK"] = pressed
                        -- あるいは何もしない（Thinkフックで送信される状態に依存）
                    else
                        actionStates["ATTACK"] = false -- 例: VSPECなしでは攻撃不可
                    end
                else -- WheeledVehicleでない場合
                    if action == "boolean_primaryfire" then
                        actionStates["ATTACK"] = pressed
                    end
                end

                if action == "boolean_sprint" then
                    actionStates["HELI_HOVER"] = pressed
                    actionStates["+PITCH_SF"] = pressed
                    actionStates["CAR_SWAP_AMMO"] = pressed
                elseif action == "boolean_forword" then
                    actionStates["+THROTTLE"] = pressed
                    actionStates["+THRUST_HELI"] = pressed
                    actionStates["+THRUST_SF"] = pressed
                    actionStates["cl_simfphys_keygearup"] = pressed
                elseif action == "boolean_back" then
                    actionStates["-THROTTLE"] = pressed
                    actionStates["-THRUST_HELI"] = pressed
                    actionStates["-THRUST_SF"] = pressed
                    actionStates["-VTOL_X_SF"] = pressed
                    actionStates["cl_simfphys_keygeardown"] = pressed
                elseif action == "boolean_left" then
                    actionStates["-ROLL_SF"] = pressed
                    actionStates["CAR_STEER_LEFT"] = pressed
                    actionStates["-ROLL_HELI"] = pressed
                elseif action == "boolean_right" then
                    actionStates["+ROLL_SF"] = pressed
                    actionStates["CAR_STEER_RIGHT"] = pressed
                    actionStates["+ROLL_HELI"] = pressed
                elseif action == "boolean_handbrake" then
                    actionStates["CAR_HANDBRAKE"] = pressed
                    actionStates["HELI_HOVER"] = pressed
                    actionStates["cl_simfphys_keyhandbrake"] = pressed
                elseif action == "boolean_flashlight" then
                    actionStates["CAR_LIGHTS_TOGGLE"] = pressed
                    actionStates["cl_simfphys_lights"] = pressed
                elseif action == "boolean_walkkey" then
                    actionStates["FREELOOK"] = pressed
                    actionStates["CAR_SWAP_AMMO"] = pressed
                    actionStates["ZOOM"] = pressed
                elseif action == "boolean_spawnmenu" then
                    -- Spawnmenu はサーバー状態ではないので actionStates には入れない
                    if pressed then
                        if LocalPlayer():InVehicle() then
                            RunConsoleCommand("vr_dummy_menu_toggle", "1")
                        end
                    else
                        RunConsoleCommand("vr_dummy_menu_toggle", "0")
                    end
                end
            end
        )
        -- elseif pickuphandle:GetBool() and action == "boolean_right_pickup" then
        --     -- pickup ハンドルや walkkey による FREELOOK の更新は Think フックで行うため、ここでは不要
        --     actionStates["FREELOOK"] = not pressed
        -- 状態変化があった場合、Thinkフックで送信されるのを待つ
    end

    function vrmod_lvs_input_singleplay()
        local lvsautosetting = CreateClientConVar("vrmod_auto_lvs_keysetings", 1, true, FCVAR_ARCHIVE)
        local pickuphandle = CreateClientConVar("vrmod_lvs_pickup_handle", "1", true, FCVAR_ARCHIVE)
        local actionStates = {
            ["ENGINE"] = false,
            ["EXIT"] = false,
            ["VSPEC"] = false,
            ["CAR_REVERSE"] = false,
            ["ATTACK"] = false,
            ["CAR_THROTTLE"] = false,
            ["CAR_THROTTLE_MOD"] = false,
            ["CAR_BRAKE"] = false,
            ["CAR_HANDBRAKE"] = false,
            ["CAR_LIGHTS_TOGGLE"] = false,
            ["HELI_HOVER"] = false,
            ["ZOOM"] = false,
            ["FREELOOK"] = false,
            ["+THROTTLE"] = false,
            ["-THROTTLE"] = false,
            ["+THRUST_HELI"] = false,
            ["-THRUST_HELI"] = false,
            ["+THRUST_SF"] = false,
            ["-THRUST_SF"] = false,
            ["+VTOL_Z_SF"] = false,
            ["-VTOL_Z_SF"] = false,
            ["+VTOL_Y_SF"] = false,
            ["-VTOL_Y_SF"] = false,
            ["-VTOL_X_SF"] = false,
            ["CAR_SWAP_AMMO"] = false,
            ["~SELECT~WEAPON#1"] = false,
            ["~SELECT~WEAPON#2"] = false,
            ["~SELECT~WEAPON#3"] = false,
            ["~SELECT~WEAPON#4"] = false,
        }

        -- 車両タイプを判定する関数を追加
        local function GetVehicleType()
            if not g_VR.active then return end
            local vehicle = LocalPlayer():lvsGetVehicle()
            if not IsValid(vehicle) then return nil end
            -- エンティティ名に "wheeldrive" が含まれているかチェック
            if string.find(string.lower(vehicle:GetClass()), "wheeldrive") then return true end

            return false
        end

        local function updateServer()
            if LocalPlayer():InVehicle() then
                for action, state in pairs(actionStates) do
                    net.Start("lvs_setinput")
                    net.WriteString(action)
                    net.WriteBool(state)
                    net.SendToServer()
                end
            end
        end

        local function handleVectorInput()
            if not g_VR then return end
            if not g_VR.active then return end
            if not g_VR.input then return end
            local forward = g_VR.input.vector1_forward or 0
            local reverse = g_VR.input.vector1_reverse or 0
            if forward > 0 then
                if forward < 0.5 then
                    actionStates["CAR_THROTTLE"] = true
                    actionStates["CAR_THROTTLE_MOD"] = false
                else
                    actionStates["CAR_THROTTLE"] = true
                    actionStates["CAR_THROTTLE_MOD"] = true
                end
            else
                actionStates["CAR_THROTTLE"] = false
                actionStates["CAR_THROTTLE_MOD"] = false
            end

            actionStates["CAR_BRAKE"] = reverse > 0
            updateServer()
        end

        local usePressedTime = 0
        local useTimerRunning = false
        local lvsselectwep = 0
        hook.Add("Think", "VRMod_LVS_VectorInput", handleVectorInput)
        hook.Add(
            "VRMod_Input",
            "vrmod_LVSconcommand",
            function(action, pressed)
                if action == "boolean_turbo" then
                    actionStates["ENGINE"] = pressed
                end

                if action == "boolean_jump" then
                    actionStates["VSPEC"] = pressed
                end

                if GetVehicleType() == true then
                    if action == "boolean_right_pickup" then
                        actionStates["VSPEC"] = pressed
                    end

                    if action == "boolean_secondaryfire" then
                        actionStates["ATTACK"] = pressed
                    end
                else
                    if action == "boolean_primaryfire" then
                        actionStates["ATTACK"] = pressed
                    end
                end

                if action == "boolean_sprint" then
                    actionStates["HELI_HOVER"] = pressed
                    actionStates["+PITCH_SF"] = pressed
                end

                if action == "boolean_forword" then
                    actionStates["+THROTTLE"] = pressed
                    actionStates["+THRUST_HELI"] = pressed
                    actionStates["+THRUST_SF"] = pressed
                    actionStates["cl_simfphys_keygearup"] = pressed
                end

                if action == "boolean_back" then
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

                if action == "boolean_handbrake" then
                    actionStates["CAR_HANDBRAKE"] = pressed
                    actionStates["HELI_HOVER"] = pressed
                    actionStates["cl_simfphys_keyhandbrake"] = pressed
                end

                if pickuphandle:GetBool() then
                    if action == "boolean_right_pickup" then
                        actionStates["FREELOOK"] = not pressed
                    end
                end

                if action == "boolean_walkkey" then
                    actionStates["CAR_SWAP_AMMO"] = pressed
                    actionStates["ZOOM"] = pressed
                end

                if action == "boolean_flashlight" then
                    actionStates["CAR_LIGHTS_TOGGLE"] = pressed
                    actionStates["cl_simfphys_lights"] = pressed
                end

                if action == "boolean_spawnmenu" then
                    if pressed then
                        -- ネットワークを介してサーバーにコマンドを送信
                        if LocalPlayer():InVehicle() then
                            RunConsoleCommand("vr_dummy_menu_toggle", "1") -- メニューを閉じた時にConVarをリセット
                        end
                    else
                        RunConsoleCommand("vr_dummy_menu_toggle", "0") -- メニューを閉じた時にConVarをリセット
                    end
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

                -- 追加: boolean_changeweaponアクションの処理
                if action == "boolean_changeweapon" then
                    if pressed then
                        if lvsselectwep == 0 then
                            actionStates["~SELECT~WEAPON#1"] = true
                            gui.InternalMousePressed(MOUSE_WHEEL_DOWN)
                            lvsselectwep = 1
                        elseif lvsselectwep == 1 then
                            actionStates["~SELECT~WEAPON#2"] = true
                            gui.InternalMousePressed(MOUSE_WHEEL_UP)
                            lvsselectwep = 2
                        elseif lvsselectwep == 2 then
                            actionStates["~SELECT~WEAPON#3"] = true
                            gui.InternalMousePressed(MOUSE_MIDDLE)
                            lvsselectwep = 3
                        elseif lvsselectwep == 3 then
                            actionStates["~SELECT~WEAPON#4"] = true
                            gui.InternalMousePressed(MOUSE_4)
                            lvsselectwep = 4
                        elseif lvsselectwep == 4 then
                            lvsselectwep = 0
                        end
                    else
                        actionStates["~SELECT~WEAPON#1"] = false
                        actionStates["~SELECT~WEAPON#2"] = false
                        actionStates["~SELECT~WEAPON#3"] = false
                        actionStates["~SELECT~WEAPON#4"] = false
                    end
                end

                -- Update the server with the latest states
                updateServer()
            end
        )
    end

    -- 車両に乗っている場合、VRModの入力を有効にする
    if lvsInputMode:GetInt() == 1 then
        vrmod_lvs_input_multiplay()
    elseif lvsInputMode:GetInt() == 0 then
        vrmod_lvs_input_singleplay()
    end
end
--------[vrmod_lvs_inputbeta.lua]End--------