
--------[vrmod_lvs_input_special.lua]Start--------
-- クライアント側: 特殊なLVS操作（降車、武器切り替え）のイベント処理と送信
if CLIENT then
    if not LVS then return end
    if not g_VR then return end

    local usePressedTime_special = 0
    local useTimerRunning_special = false
    local lvsselectwep_special = 0 -- このファイル専用の武器選択状態

    hook.Add(
        "VRMod_Input",
        "vrmod_LVS_SpecialInput",
        function(action, pressed)
            if not LocalPlayer():InVehicle() then return end
            if not IsValid(LocalPlayer():lvsGetVehicle()) then return end

            if action == "boolean_use" then
                if pressed then
                    if not useTimerRunning_special then
                        usePressedTime_special = CurTime()
                        useTimerRunning_special = true
                        timer.Create(
                            "CheckUseDuration_Special",
                            0.1,
                            0,
                            function()
                                if not timer.Exists("CheckUseDuration_Special") then return end
                                -- 長押しチェック
                                if useTimerRunning_special and CurTime() - usePressedTime_special > 0.4 then
                                    -- 長押し確定時にサーバーにEXIT=trueを送信
                                    net.Start("lvs_setinput_special")
                                    net.WriteString("EXIT")
                                    net.WriteBool(true)
                                    net.SendToServer()

                                    useTimerRunning_special = false
                                    timer.Remove("CheckUseDuration_Special")
                                end
                            end
                        )
                    end
                else
                    if useTimerRunning_special then
                        useTimerRunning_special = false
                        timer.Remove("CheckUseDuration_Special")
                    end
                    -- ボタンを離した時にサーバーにEXIT=falseを送信（必要なら）
                    -- net.Start("lvs_setinput_special")
                    -- net.WriteString("EXIT")
                    -- net.WriteBool(false)
                    -- net.SendToServer()
                     usePressedTime_special = 0.0
                end
            elseif action == "boolean_changeweapon" then
                 if pressed then
                     local weaponToSelect = -1
                     if lvsselectwep_special == 0 then lvsselectwep_special = 1; weaponToSelect = 1;
                     elseif lvsselectwep_special == 1 then lvsselectwep_special = 2; weaponToSelect = 2;
                     elseif lvsselectwep_special == 2 then lvsselectwep_special = 3; weaponToSelect = 3;
                     elseif lvsselectwep_special == 3 then lvsselectwep_special = 4; weaponToSelect = 4;
                     elseif lvsselectwep_special == 4 then lvsselectwep_special = 0; weaponToSelect = -1; -- 0に戻る時は選択解除扱い
                     end

                     if weaponToSelect > 0 then
                         net.Start("lvs_setinput_special")
                         net.WriteString("~SELECT~WEAPON#" .. weaponToSelect)
                         net.WriteBool(true) -- value はここでは単純に true/false で良いか？ LVSの仕様による
                         net.SendToServer()
                          -- クライアント側のUI操作（必要なら）
                         if weaponToSelect == 1 then gui.InternalMousePressed(MOUSE_WHEEL_DOWN)
                         elseif weaponToSelect == 2 then gui.InternalMousePressed(MOUSE_WHEEL_UP)
                         elseif weaponToSelect == 3 then gui.InternalMousePressed(MOUSE_MIDDLE)
                         elseif weaponToSelect == 4 then gui.InternalMousePressed(MOUSE_4)
                         end
                     -- else -- 選択解除の場合、サーバーに通知が必要ならここに追加
                     end
                 -- else -- ボタンを離したときの処理 (通常は不要)
                 end
            end
        end
    )
end
--------[vrmod_lvs_input_special.lua]End--------
