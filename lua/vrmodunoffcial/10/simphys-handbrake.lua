-- Simphys Handbrake Module
local simphysHandbrake = {}

-- コンバーの作成
CreateClientConVar("vrmod_simphys_handbrake_enabled", "1", true, FCVAR_ARCHIVE)
CreateClientConVar("vrmod_simphys_handbrake_button", "boolean_back", true, FCVAR_ARCHIVE)

-- ハンドブレーキの状態
local handbrakeActive = false

-- 入力処理
hook.Add("VRMod_Input", "SimphysHandbrakeHandler", function(action, pressed)
    if not vrmod.IsPlayerInVR(LocalPlayer()) then return end
    
    local handbrakeButton = GetConVar("vrmod_simphys_handbrake_button"):GetString()
    if action == handbrakeButton then
        local vehicle = LocalPlayer():GetVehicle()
        if IsValid(vehicle) and vehicle.GetHandBrakeEnabled then
            handbrakeActive = pressed
            
            -- サーバーに状態を送信
            net.Start("Simphys_Handbrake")
            net.WriteBool(handbrakeActive)
            net.SendToServer()
            
            -- エフェクトとサウンド
            if pressed then
                vehicle:EmitSound("vehicles/handbrake_on.wav")
            else
                vehicle:EmitSound("vehicles/handbrake_off.wav")
            end
        end
    end
end)

-- サーバーサイドの処理
if SERVER then
    util.AddNetworkString("Simphys_Handbrake")
    
    net.Receive("Simphys_Handbrake", function(len, ply)
        local vehicle = ply:GetVehicle()
        if IsValid(vehicle) and vehicle.GetHandBrakeEnabled then
            local active = net.ReadBool()
            vehicle:SetHandBrake(active)
        end
    end)
end

return simphysHandbrake
