if not Glide then return end
if not g_VR then return end

if CLIENT then 

    -- 地上車両かどうかをチェックする関数
    local function isGroundVehicle(vehicle)
        if not IsValid(vehicle) then return false end
        local vType = vehicle.VehicleType
        return vType == Glide.VEHICLE_TYPE.CAR or 
               vType == Glide.VEHICLE_TYPE.MOTORCYCLE or 
               vType == Glide.VEHICLE_TYPE.TANK
    end

    -- VRでのドライビング用Convar作成
    local cv_rightHandle = CreateClientConVar("glide_vr_righthandle", "0", true, nil)
    local cv_leftHandle = CreateClientConVar("glide_vr_lefthandle", "0", true, nil)
    local cv_handbrake = CreateClientConVar("glide_vr_handbrake", "0", true, nil)
    local cv_headlights = CreateClientConVar("glide_vr_headlights", "0", true, nil)
    local cv_horn = CreateClientConVar("glide_vr_horn", "0", true, nil)
    local cv_reducedThrottle = CreateClientConVar("glide_vr_reduced_throttle", "0", true, nil)

    -- VRコントローラーのボタン設定
    local VR_CONTROLS = {
        ["boolean_forword"] = "shift_up",      -- トリガー - シフトアップ
        ["boolean_back"] = "shift_down",  -- グリップ - シフトダウン
        ["boolean_right_pickup"] = "righthandle",  -- 右グラブ - 右ハンドル
        ["boolean_left_pickup"] = "lefthandle",    -- 左グラブ - 左ハンドル
        ["boolean_left"] = "shift_neutral",         -- Aボタン - ニュートラル
        ["boolean_handbrake"] = "handbrake",          -- Bボタン - ハンドブレーキ
        ["boolean_flashlight"] = "headlights",      -- 左メニュー - ヘッドライト
        ["boolean_turbo"] = "horn",           -- 右メニュー - クラクション
        ["boolean_reload"] = "reduce_throttle", -- 左ショルダー - スロットル制限
        ["boolean_spawnmenu"] = "switch_weapon"   -- 右ショルダー - 武器切替
    }

    -- VRのコントローラー入力処理
    hook.Add("VRMod_Input", "glide_vr_input", function(action, pressed)
        if not g_VR.active then return end
        local vehicle = LocalPlayer():GetNWEntity("GlideVehicle")
        if not isGroundVehicle(vehicle) then return end

        local control = VR_CONTROLS[action]
        if control then
            LocalPlayer():ConCommand(pressed and "glide_vr_" .. control .. " 1" or "glide_vr_" .. control .. " 0")
        end
    end)

    -- VR入力の更新処理
    hook.Add("Think", "glide_vr_update", function()

        if not g_VR.active then return end
        local vehicle = LocalPlayer():GetNWEntity("GlideVehicle")
        if not isGroundVehicle(vehicle) or not g_VR.net[LocalPlayer():SteamID()] then return end

        -- ステアリング操作の取得
        local steeringInput = 0
        if cv_rightHandle:GetBool() then
            steeringInput = g_VR.tracking.pose_righthand.ang.z * 0.01  
        elseif cv_leftHandle:GetBool() then
            steeringInput = g_VR.tracking.pose_lefthand.ang.z * 0.01
        end

        -- サーバーに入力を送信
        net.Start("glide_vr_input")
            net.WriteFloat(g_VR.input.vector1_forward) -- アクセル
            net.WriteFloat(g_VR.input.vector1_reverse) -- ブレーキ
            net.WriteFloat(steeringInput) -- ステアリング
            net.WriteBool(cv_handbrake:GetBool()) -- ハンドブレーキ
            net.WriteBool(cv_headlights:GetBool()) -- ヘッドライト
            net.WriteBool(cv_horn:GetBool()) -- クラクション
            net.WriteBool(cv_reducedThrottle:GetBool()) -- スロットル制限
            -- ギア操作状態を送信
            net.WriteBool(g_VR.input.boolean_forword) -- シフトアップ
            net.WriteBool(g_VR.input.boolean_back) -- シフトダウン
            net.WriteBool(g_VR.input.boolean_left) -- ニュートラル
            net.WriteBool(g_VR.input.boolean_spawnmenu) -- 武器切替
        net.SendToServer()
    end)

elseif SERVER then
    util.AddNetworkString("glide_vr_input")

    -- クライアントからの入力を受信して車両に適用
    net.Receive("glide_vr_input", function(len, ply)
        local vehicle = ply:GetNWEntity("GlideVehicle") 
        if not IsValid(vehicle) then return end
        
        -- 地上車両でない場合は処理しない
        local vType = vehicle.VehicleType
        if vType ~= Glide.VEHICLE_TYPE.CAR and 
           vType ~= Glide.VEHICLE_TYPE.MOTORCYCLE and 
           vType ~= Glide.VEHICLE_TYPE.TANK then 
            return 
        end

        -- 各種入力値を取得
        local throttle = net.ReadFloat()
        local brake = net.ReadFloat() 
        local steering = net.ReadFloat()
        local handbrake = net.ReadBool()
        local headlights = net.ReadBool()
        local horn = net.ReadBool()
        local reducedThrottle = net.ReadBool()
        local shiftUp = net.ReadBool()
        local shiftDown = net.ReadBool()
        local shiftNeutral = net.ReadBool()
        local switchWeapon = net.ReadBool()

        -- 車両に入力を反映
        vehicle:SetInputFloat(1, "accelerate", throttle)
        vehicle:SetInputFloat(1, "brake", brake)
        vehicle:SetInputFloat(1, "steer", steering)
        vehicle:SetInputBool(1, "handbrake", handbrake)
        vehicle:SetInputBool(1, "horn", horn)
        vehicle:SetInputBool(1, "reduce_throttle", reducedThrottle)
        
        -- ギア操作
        if shiftUp then
            vehicle:SetInputBool(1, "shift_up", true)
        elseif shiftDown then
            vehicle:SetInputBool(1, "shift_down", true)
        elseif shiftNeutral then
            vehicle:SetInputBool(1, "shift_neutral", true)
        end

        -- 武器切替
        if switchWeapon then
            vehicle:SetInputBool(1, "switch_weapon", true)
        end
        
        -- ヘッドライトの制御
        if headlights ~= (vehicle:GetHeadlightState() > 0) then
            vehicle:ChangeHeadlightState(headlights and 2 or 0)
        end
    end)
end