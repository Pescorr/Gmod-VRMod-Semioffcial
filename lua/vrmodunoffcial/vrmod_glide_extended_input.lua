-- lua/autorun/client/vrmodUnoffcial/vrmod_glide_extended_input.lua
AddCSLuaFile()

if CLIENT then 
    if not g_VR then return end
    if not Glide then PrintTable({Error="Glideアドオンが見つかりません！"}); return end

    local lastSentTime = 0
    local sendInterval = 0.05
    local actionStatesFloat = {}
    local lastTurretAimDir = Vector(0,0,0) -- 砲塔の前回の目標方向ベクトル

    -- ステアリング感度 (0.0 から 1.0 の間で調整)
    local STEERING_SENSITIVITY_SHIP_TANK = 0.7
    -- 航空機のピッチ/ロール感度
    local AIRCRAFT_PITCH_SENSITIVITY = 1.0
    local AIRCRAFT_ROLL_SENSITIVITY = 1.0
    -- 戦車の砲塔回転速度 (度/秒)
    local TANK_TURRET_YAW_SPEED = 45
    local TANK_TURRET_PITCH_SPEED = 30


    -- 角度を指定範囲内に正規化するヘルパー関数
    local function NormalizeAngleSafe(angle, min, max)
        angle = math.NormalizeAngle(angle)
        if min ~= -1 and max ~= -1 then
            -- 角度のラップアラウンドを考慮したクランプは複雑なので、
            -- Glide側の SetTurretAngle がよしなに処理してくれることを期待する
            -- もし問題があれば、より詳細なクランプ処理が必要
            return math.Clamp(angle, min, max)
        end
        return angle
    end

    hook.Add("Think", "VRMod_Glide_Extended_ThinkUpdate", function()
        if not g_VR or not g_VR.active or not g_VR.input or not LocalPlayer():InVehicle() then
            return
        end

        local ply = LocalPlayer()
        local vehicle = ply:GetNWEntity("GlideVehicle")
        if not IsValid(vehicle) or not vehicle.IsGlideVehicle then
            return
        end

        local vType = vehicle.VehicleType
        if vType == Glide.VEHICLE_TYPE.CAR or vType == Glide.VEHICLE_TYPE.MOTORCYCLE then
            return
        end

        local now = CurTime()
        if now - lastSentTime > sendInterval then
            -- Floatアクションの基本状態
            actionStatesFloat["accelerate"] = g_VR.input.vector1_forward or 0
            actionStatesFloat["brake"]      = g_VR.input.vector1_reverse or 0
            actionStatesFloat["throttle"]   = g_VR.input.vector2_smoothturn and g_VR.input.vector2_smoothturn.y or 0 -- 航空機スロットル

            -- 車両タイプごとの入力処理
            if vType == Glide.VEHICLE_TYPE.PLANE or vType == Glide.VEHICLE_TYPE.HELICOPTER then
                actionStatesFloat["pitch"] = (g_VR.input.vector2_walkdirection and g_VR.input.vector2_walkdirection.y or 0) * AIRCRAFT_PITCH_SENSITIVITY
                actionStatesFloat["roll"]  = (g_VR.input.vector2_walkdirection and g_VR.input.vector2_walkdirection.x or 0) * AIRCRAFT_ROLL_SENSITIVITY
                actionStatesFloat["yaw"]   = g_VR.input.vector2_smoothturn and g_VR.input.vector2_smoothturn.x or 0
                actionStatesFloat["steer"] = 0 -- 航空機ではアナログスティックのsteerは使わない想定
            elseif vType == Glide.VEHICLE_TYPE.TANK or vType == Glide.VEHICLE_TYPE.BOAT then
                local steerValue = 0
                -- 右手コントローラーの傾きでステアリング (一般車両と同様のロジック)
                if IsValid(g_VR.tracking.pose_righthand) then
                    local handAng = g_VR.tracking.pose_righthand.ang
                    local vehicleAngY = vehicle:GetAngles().y
                    local relativeRoll = math.NormalizeAngle(handAng.r - vehicleAngY) -- 車両正面基準のロール
                    steerValue = math.Clamp(relativeRoll / 45, -1, 1) * STEERING_SENSITIVITY_SHIP_TANK -- 45度で最大舵角
                end
                actionStatesFloat["steer"] = steerValue
                actionStatesFloat["pitch"] = 0 -- 戦車・船では使用しない
                actionStatesFloat["roll"]  = 0 -- 戦車・船では使用しない
                actionStatesFloat["yaw"]   = 0 -- 戦車・船では使用しない
            else
                -- その他の未対応車両タイプ
                actionStatesFloat["steer"] = 0
                actionStatesFloat["pitch"] = 0
                actionStatesFloat["roll"]  = 0
                actionStatesFloat["yaw"]   = 0
            end

            net.Start("glide_input_batch_extended")
            net.WriteTable(actionStatesFloat)
            net.SendToServer()

            -- 戦車砲塔制御 (目標角度を直接送信)
            if vType == Glide.VEHICLE_TYPE.TANK then
                local aimRayStart = vrmod.GetRightHandPos(ply)
                local aimRayDir = vrmod.GetRightHandAng(ply):Forward()

                -- サーバーに送る砲塔の目標角度を計算
                local vehicleTransform = vehicle:GetWorldTransformMatrix()
                local localAimDir = vehicleTransform:VectorToObjectSpace(aimRayDir)
                local targetAng = localAimDir:Angle() -- 車両ローカルな目標角度

                -- Glide側の砲塔可動域に合わせて調整 (必要であれば)
                -- vehicle.HighPitchAng, vehicle.LowPitchAng, vehicle.MinYaw, vehicle.MaxYaw など
                local minPitch = vehicle.HighPitchAng or -25
                local maxPitch = vehicle.LowPitchAng or 10
                targetAng.p = math.Clamp(targetAng.p, minPitch, maxPitch)
                -- Yawは360度自由に回転できることが多いので、ここではクランプしない
                -- targetAng.y = NormalizeAngleSafe(targetAng.y, vehicle.MinYaw or -1, vehicle.MaxYaw or -1)

                net.Start("glide_turret_target_angle_extended")
                net.WriteFloat(targetAng.p) -- Pitch
                net.WriteFloat(targetAng.y) -- Yaw
                net.SendToServer()
            end

            lastSentTime = now
        end
    end)

    -- Inputフック: Boolアクション (変更なし)
    hook.Add("VRMod_Input", "VRMod_Glide_Extended_BoolInput", function(action, pressed)
        if not g_VR or not g_VR.active or not LocalPlayer():InVehicle() then return end

        local ply = LocalPlayer()
        local vehicle = ply:GetNWEntity("GlideVehicle")
        if not IsValid(vehicle) or not vehicle.IsGlideVehicle then return end

        local vType = vehicle.VehicleType
        if vType == Glide.VEHICLE_TYPE.CAR or vType == Glide.VEHICLE_TYPE.MOTORCYCLE then
            return
        end

        local targetAction = nil
        if action == "boolean_primaryfire" then     targetAction = "attack"
        elseif action == "boolean_right_pickup" then targetAction = "attack_alt"
        elseif action == "boolean_turbo" then       targetAction = "toggle_engine"
        elseif action == "boolean_jump" then        targetAction = "landing_gear"
        elseif action == "boolean_sprint" then      targetAction = "countermeasures"
        elseif action == "boolean_reload" then      targetAction = "switch_weapon"
        elseif action == "boolean_walkkey" then     targetAction = "free_look"
        elseif action == "boolean_handbrake" then   targetAction = "handbrake"
        elseif action == "boolean_flashlight" then  targetAction = "headlights"
        elseif action == "boolean_changeweapon" then targetAction = "horn"
        end

        if targetAction then
            net.Start("glide_input_bool_extended")
            net.WriteString(targetAction)
            net.WriteBool(pressed)
            net.SendToServer()
        end
    end)

    print("[Glide Extended Input] Initialized for Aircraft, Tanks, and Boats. Steering/Turret logic updated.")
end