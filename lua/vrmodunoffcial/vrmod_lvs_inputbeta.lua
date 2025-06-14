if CLIENT then
    if not LVS then return end
    if not g_VR then return end
    -- ConVarの定義を追加（0=シングルプレイモード、1=マルチプレイモード、2=自動判定）
    local lvsInputMode = CreateClientConVar("vrmod_lvs_input_mode", "2", true, FCVAR_ARCHIVE)
    local lvsautosetting = CreateClientConVar("vrmod_auto_lvs_keysetings", 1, true, FCVAR_ARCHIVE)
    local pickuphandle = CreateClientConVar("vrmod_lvs_pickup_handle", "1", true, FCVAR_ARCHIVE)
    local actionStates = {
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

    local function IsUsingBatchMode()
        local mode = lvsInputMode:GetInt()
        if mode == 2 then
            return not game.SinglePlayer()
        else -- 自動判定モード
            return mode == 1
        end
    end

    local lastLvsThinkSentTime = 0
    local lvsSendInterval = 0.05
    local function UpdateServerBatch()
        net.Start("lvs_setinput_batch")
        net.WriteTable(actionStates)
        net.SendToServer()
    end

    local function UpdateServerIndividual()
        for action, state in pairs(actionStates) do
            net.Start("lvs_setinput")
            net.WriteString(action)
            net.WriteBool(state)
            net.SendToServer()
        end
    end

    local function UpdateServer()
        if IsUsingBatchMode() then
            UpdateServerBatch()
        else
            UpdateServerIndividual()
        end
    end

    hook.Add(
        "Think",
        "VRMod_LVS_ThinkUpdate",
        function()
            if not g_VR or not g_VR.active or not g_VR.input or not LocalPlayer():InVehicle() then return end
            if not IsValid(LocalPlayer():lvsGetVehicle()) then return end
            local now = CurTime()
            if now - lastLvsThinkSentTime > lvsSendInterval then
                local forward = g_VR.input.vector1_forward or 0
                local reverse = g_VR.input.vector1_reverse or 0
                actionStates["CAR_THROTTLE"] = forward > 0
                actionStates["CAR_THROTTLE_MOD"] = actionStates["CAR_THROTTLE"] and forward >= 0.5
                actionStates["CAR_BRAKE"] = reverse > 0
                local pickuphandle_cv = GetConVar("vrmod_lvs_pickup_handle")
                if pickuphandle_cv and pickuphandle_cv:GetBool() then
                    actionStates["FREELOOK"] = not (g_VR.input.boolean_right_pickup or false)
                else
                    actionStates["FREELOOK"] = g_VR.input.boolean_walkkey or false
                end

                UpdateServer()
                lastLvsThinkSentTime = now
            end
        end
    )

    hook.Add(
        "VRMod_Input",
        "vrmod_LVSconcommand",
        function(action, pressed)
            if not LocalPlayer():InVehicle() then return end
            if not IsValid(LocalPlayer():lvsGetVehicle()) then return end
            if action == "boolean_use" or action == "boolean_changeweapon" then return end
            if action == "boolean_turbo" then
                actionStates["ENGINE"] = pressed
            elseif action == "boolean_jump" then
                actionStates["VSPEC"] = pressed
            elseif GetVehicleType() == true then
                if action == "boolean_right_pickup" then
                    actionStates["VSPEC"] = pressed
                end

                if action == "boolean_secondaryfire" then
                    actionStates["ATTACK"] = pressed
                else
                    actionStates["ATTACK"] = false
                end
            else
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
end