-- lua/autorun/server/vrmodUnoffcial/glide_server_handlers.lua
AddCSLuaFile()
if CLIENT then return end

-- 安全なAPI呼び出しラッパー（pcall保護）
local function SafeSetInputFloat(vehicle, seat, name, val)
    local ok, err = pcall(function()
        vehicle:SetInputFloat(seat, name, val)
    end)
    if not ok then
        MsgN("[VRMod] SetInputFloat failed:", name, "=", val, "|", err)
    end
end

local function SafeSetInputBool(vehicle, seat, name, val)
    local ok, err = pcall(function()
        vehicle:SetInputBool(seat, name, val)
    end)
    if not ok then
        MsgN("[VRMod] SetInputBool failed:", name, "=", val, "|", err)
    end
end

util.AddNetworkString("glide_input_batch_extended")
util.AddNetworkString("glide_input_bool_extended")
util.AddNetworkString("glide_turret_target_angle_extended") -- 砲塔目標角度用NetMessage
-- アナログ/バッチ入力処理
net.Receive(
    "glide_input_batch_extended",
    function(len, ply)
        if not IsValid(ply) then return end
        local vehicle = ply:GlideGetVehicle()
        if not IsValid(vehicle) or not vehicle.IsGlideVehicle then return end
        local vType = vehicle.VehicleType
        if vType == Glide.VEHICLE_TYPE.CAR or vType == Glide.VEHICLE_TYPE.MOTORCYCLE then return end
        local receivedStates = net.ReadTable()
        if not receivedStates then return end
        local seatIndex = ply:GetNWInt("GlideSeatIndex", 1)
        for inputName, inputValue in pairs(receivedStates) do
            if vehicle.SetInputFloat then
                SafeSetInputFloat(vehicle, seatIndex, inputName, inputValue)
            elseif vehicle.SetInputBool and (inputValue == 0 or inputValue == 1 or inputValue == -1) then
                if inputValue == 0 then
                    SafeSetInputBool(vehicle, seatIndex, inputName, false)
                else
                    SafeSetInputBool(vehicle, seatIndex, inputName, true)
                    if inputName == "steer" then
                        SafeSetInputBool(vehicle, seatIndex, "steer_left", inputValue < 0)
                        SafeSetInputBool(vehicle, seatIndex, "steer_right", inputValue > 0)
                    elseif inputName == "pitch" then
                        SafeSetInputBool(vehicle, seatIndex, "pitch_up", inputValue < 0)
                        SafeSetInputBool(vehicle, seatIndex, "pitch_down", inputValue > 0)
                    elseif inputName == "roll" then
                        SafeSetInputBool(vehicle, seatIndex, "roll_left", inputValue < 0)
                        SafeSetInputBool(vehicle, seatIndex, "roll_right", inputValue > 0)
                    elseif inputName == "yaw" then
                        SafeSetInputBool(vehicle, seatIndex, "yaw_left", inputValue < 0)
                        SafeSetInputBool(vehicle, seatIndex, "yaw_right", inputValue > 0)
                    end
                end
            end
        end
    end
)

-- Bool入力処理 (変更なし)
net.Receive(
    "glide_input_bool_extended",
    function(len, ply)
        if not IsValid(ply) then return end
        local vehicle = ply:GlideGetVehicle()
        if not IsValid(vehicle) or not vehicle.IsGlideVehicle then return end
        local vType = vehicle.VehicleType
        if vType == Glide.VEHICLE_TYPE.CAR or vType == Glide.VEHICLE_TYPE.MOTORCYCLE then return end
        local actionName = net.ReadString()
        local actionValue = net.ReadBool()
        local seatIndex = ply:GetNWInt("GlideSeatIndex", 1)
        if vehicle.SetInputBool then
            SafeSetInputBool(vehicle, seatIndex, actionName, actionValue)
        end
    end
)

-- 戦車砲塔制御 (目標角度方式に変更)
net.Receive(
    "glide_turret_target_angle_extended",
    function(len, ply)
        if not IsValid(ply) then return end
        local vehicle = ply:GlideGetVehicle()
        if not IsValid(vehicle) or not vehicle.IsGlideVehicle or vehicle.VehicleType ~= Glide.VEHICLE_TYPE.TANK then return end
        if not vehicle.SetTurretAngle then return end -- GetTurretAngleは不要になった --print("[Glide Extended Input] Warning: Vehicle "..tostring(vehicle).." does not support SetTurretAngle.")
        local targetPitch = net.ReadFloat()
        local targetYaw = net.ReadFloat()
        -- Glide側の制限に合わせてクランプ (base_glide_tank.lua参照)
        local minPitch = vehicle.HighPitchAng or -25
        local maxPitch = vehicle.LowPitchAng or 10
        local newPitch = math.Clamp(targetPitch, minPitch, maxPitch)
        local minYaw = vehicle.MinYaw or -1
        local maxYaw = vehicle.MaxYaw or -1
        local newYaw = targetYaw
        if minYaw ~= -1 and maxYaw ~= -1 then
            -- 角度の正規化と範囲チェック
            newYaw = math.NormalizeAngle(newYaw)
            -- ここでは単純なクランプ。実際には車両の旋回範囲ロジックに合わせる必要がある
            -- newYaw = math.Clamp(newYaw, minYaw, maxYaw)
        end

        local ok, err = pcall(function()
            vehicle:SetTurretAngle(Angle(newPitch, newYaw, 0))
        end)
        if not ok then
            MsgN("[VRMod] SetTurretAngle failed:", err)
        end
    end
)