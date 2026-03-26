--------[vrmod_lvs_inputbeta.lua]Start--------
-- クライアント側: 通常のLVS操作（特殊操作を除く）の状態管理と送信
-- 修正: バッチ送信 + 50msインターバルで毎秒~1800→~20メッセージに削減
if CLIENT then
    if not LVS then return end
    if not g_VR then return end
    local lvsInputMode = GetConVar("vrmod_lvs_input_mode")

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

        -- バッチ送信: EXIT と WEAPON SELECT を除外して一括送信
        -- サーバー側 (vrmod_lvs_beta.lua) の lvs_setinput_batch ハンドラが受信
        local function updateServerBatch()
            if not LocalPlayer():InVehicle() then return end
            local batchStates = {}
            for action, state in pairs(actionStates) do
                if action ~= "EXIT" and not string.StartWith(action, "~SELECT~WEAPON#") then
                    batchStates[action] = state
                end
            end
            net.Start("lvs_setinput_batch")
            net.WriteTable(batchStates)
            net.SendToServer()
        end

        -- EXIT専用の即時送信（降車は遅延不可のため個別送信を維持）
        local function sendExitImmediate(exitState)
            if not LocalPlayer():InVehicle() and not exitState then return end
            net.Start("lvs_setinput")
            net.WriteString("EXIT")
            net.WriteBool(exitState)
            net.SendToServer()
        end

        -- 50ms送信インターバル（Glideと同じ方式）
        local lastLvsSentTime = 0
        local lvsSendInterval = 0.05

        local function handleVectorInput()
            if not g_VR then return end
            if not g_VR.active then return end
            if not LocalPlayer():InVehicle() then return end
            if not IsValid(LocalPlayer():lvsGetVehicle()) then return end

            -- アクセル/ブレーキの状態を毎フレーム更新
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

            -- 50ms間隔でバッチ送信（毎フレーム送信を防止）
            local now = CurTime()
            if now - lastLvsSentTime > lvsSendInterval then
                updateServerBatch()
                lastLvsSentTime = now
            end
        end

        local usePressedTime = 0
        local useTimerRunning = false
        local lvsselectwep = 0
        hook.Add("Think", "VRMod_LVS_VectorInput", handleVectorInput)
        hook.Add(
            "VRMod_Input",
            "vrmod_LVSconcommand",
            function(action, pressed)
                -- ボタン状態のみ actionStates に記録
                -- 送信はThink hookの50ms間隔バッチに委任（EXIT除く）

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
                                        sendExitImmediate(true) -- EXIT は即時送信
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
                        sendExitImmediate(false) -- EXIT解除も即時送信
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

                -- 注: バッチ送信はThink hookの50ms間隔で行われる
                -- ここでは updateServer() を呼ばない（旧コードではここで毎回30メッセージ送信していた）
            end
        )
    end

    -- 車両に乗っている場合、VRModの入力を有効にする
        vrmod_lvs_input_singleplay()
end
--------[vrmod_lvs_inputbeta.lua]End--------
