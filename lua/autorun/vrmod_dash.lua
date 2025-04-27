-- -- vrmod_dash.lua
-- -- クライアントサイド・サーバーサイド共通部分
-- local SPEED_THRESHOLD = 200 -- HMD移動を検知する速度のしきい値
-- local DASH_COOLDOWN = 0.5 -- ダッシュのクールダウン時間(秒)
-- local INVINCIBILITY_DURATION = 0.7 -- 無敵状態の持続時間(秒)

-- -- サーバー側のコード
-- if SERVER then
--     util.AddNetworkString("vrmod_dash_invincibility")
    
--     -- プレイヤーの無敵状態を管理するテーブル
--     local invinciblePlayers = {}
    
--     -- プレイヤーを無敵にする関数
--     local function MakePlayerInvincible(ply)
--         if not IsValid(ply) then return end
        
--         -- すでに無敵の場合はタイマーをリセット
--         if invinciblePlayers[ply] then
--             timer.Remove("vrmod_dash_invincibility_" .. ply:SteamID())
--         else
--             -- 無敵状態を設定
--             invinciblePlayers[ply] = true
            
--             -- 無敵状態を視覚的に表示
--             ply:SetRenderMode(RENDERMODE_TRANSALPHA)
--             ply:SetColor(Color(255, 255, 255, 180))
--         end
        
--         -- タイマーを設定して無敵状態を解除
--         timer.Create("vrmod_dash_invincibility_" .. ply:SteamID(), INVINCIBILITY_DURATION, 1, function()
--             if IsValid(ply) then
--                 -- 無敵状態を解除
--                 invinciblePlayers[ply] = nil
                
--                 -- 見た目を元に戻す
--                 ply:SetRenderMode(RENDERMODE_NORMAL)
--                 ply:SetColor(Color(255, 255, 255, 255))
--             end
--         end)
--     end
    
--     -- ダメージフックを追加
--     hook.Add("EntityTakeDamage", "VRDash_PreventDamage", function(target, dmginfo)
--         -- プレイヤーが無敵状態なら、ダメージを0に設定
--         if target:IsPlayer() and invinciblePlayers[target] then
--             dmginfo:SetDamage(0)
--             return true
--         end
--     end)
    
--     -- ネットメッセージを受信した際の処理
--     net.Receive("vrmod_dash_invincibility", function(len, ply)
--         MakePlayerInvincible(ply)
--     end)
    
--     -- プレイヤー切断時のクリーンアップ
--     hook.Add("PlayerDisconnected", "VRDash_Cleanup", function(ply)
--         if invinciblePlayers[ply] then
--             timer.Remove("vrmod_dash_invincibility_" .. ply:SteamID())
--             invinciblePlayers[ply] = nil
--         end
--     end)
    
--     return
-- end

-- -- ここからクライアントサイドのコード
-- -- ローカル変数
-- local lastDashTime = 0
-- local previousHMDPos = Vector(0, 0, 0)
-- local isInvincible = false
-- local invincibilityEndTime = 0

-- -- ConVarの作成
-- local cv_enabled = CreateClientConVar("vrmod_dash_enabled", "1", true, false, "Enable VR dash movement")
-- local cv_debug = CreateClientConVar("vrmod_dash_debug", "0", true, false, "Show debug info for VR dash")
-- local cv_invincibility = CreateClientConVar("vrmod_dash_invincibility", "1", true, false, "Enable invincibility during dash")
-- local cv_speed_threshold = CreateClientConVar("vrmod_dash_speed", tostring(SPEED_THRESHOLD), true, false, "Speed threshold for dash detection")

-- -- デバッグ表示用関数
-- local function DebugPrint(text)
--     if cv_debug:GetBool() then
--         print("[VRDash] " .. text)
--     end
-- end

-- -- サーバーに無敵化リクエストを送信
-- local function RequestInvincibility()
--     if not cv_invincibility:GetBool() then return end
    
--     net.Start("vrmod_dash_invincibility")
--     net.SendToServer()
    
--     -- クライアント側でも無敵状態を記録（デバッグ表示用）
--     isInvincible = true
--     invincibilityEndTime = CurTime() + INVINCIBILITY_DURATION
    
--     DebugPrint("Invincibility activated for " .. INVINCIBILITY_DURATION .. " seconds")
-- end

-- -- HMDの動きを検出する関数
-- local function CheckHMDMovement()
--     if not g_VR.active then return end
--     if CurTime() - lastDashTime < DASH_COOLDOWN then return end
    
--     local currentPos = g_VR.tracking.hmd.pos
    
--     -- 初回実行時の処理
--     if previousHMDPos == Vector(0, 0, 0) then
--         previousHMDPos = currentPos
--         return
--     end
    
--     -- HMDの移動速度を計算
--     local deltaTime = engine.TickInterval()
--     local moveVec = currentPos - previousHMDPos
--     local speed = moveVec:Length() / deltaTime
    
--     -- デバッグ情報
--     if cv_debug:GetBool() then
--         debugLastSpeed = speed
--     end
    
--     -- 速度が閾値を超えた場合に無敵発動
--     if speed > cv_speed_threshold:GetFloat() then
--         lastDashTime = CurTime()
        
--         -- 無敵状態をリクエスト
--         RequestInvincibility()
        
--         DebugPrint("HMD movement detected! Speed: " .. speed)
--     end

--     previousHMDPos = currentPos
-- end

-- -- 無敵状態の更新
-- local function UpdateInvincibilityState()
--     if isInvincible and CurTime() > invincibilityEndTime then
--         isInvincible = false
--         DebugPrint("Invincibility ended")
--     end
-- end

-- -- メインの更新処理
-- hook.Add("Think", "VRDash_Think", function()
--     if not cv_enabled:GetBool() then return end
--     CheckHMDMovement()
--     UpdateInvincibilityState()
-- end)

-- -- より精度の高い検出のためPreRenderにもフックする
-- hook.Add("VRMod_PreRender", "VRDash_PreRender", function()
--     if not cv_enabled:GetBool() then return end
--     CheckHMDMovement()
-- end)

-- -- デバッグ表示
-- local debugLastSpeed = 0

-- hook.Add("HUDPaint", "VRDash_DebugHUD", function()
--     if not cv_debug:GetBool() or not g_VR.active then return end
    
--     local text = string.format(
--         "VR Dash Debug\nSpeed: %.2f\nThreshold: %.2f\nLast Dash: %.2f\nInvincible: %s\nInvincibility Time Left: %.2f",
--         debugLastSpeed or 0,
--         cv_speed_threshold:GetFloat(),
--         CurTime() - lastDashTime,
--         tostring(isInvincible),
--         math.max(0, invincibilityEndTime - CurTime())
--     )
    
--     draw.SimpleText(text, "Default", 10, 10, Color(255, 255, 255, 255))
-- end)

-- -- プレイヤーに視覚的なフィードバックを提供
-- hook.Add("RenderScreenspaceEffects", "VRDash_InvincibilityEffect", function()
--     if isInvincible then
--         local intensity = math.min(1, (invincibilityEndTime - CurTime()) / INVINCIBILITY_DURATION)
--         DrawColorModify({
--             ["$pp_colour_addr"] = 0,
--             ["$pp_colour_addg"] = 0,
--             ["$pp_colour_addb"] = intensity * 0.3,
--             ["$pp_colour_brightness"] = 0,
--             ["$pp_colour_contrast"] = 1 + intensity * 0.2,
--             ["$pp_colour_colour"] = 1 + intensity * 0.5,
--             ["$pp_colour_mulr"] = 0,
--             ["$pp_colour_mulg"] = 0,
--             ["$pp_colour_mulb"] = intensity * 0.5
--         })
--     end
-- end)

-- -- ConCommand Helper
-- concommand.Add("vrmod_dash_reset", function()
--     lastDashTime = 0
--     previousHMDPos = Vector(0, 0, 0)
--     isInvincible = false
--     invincibilityEndTime = 0
--     DebugPrint("VR Dash state reset")
-- end)

-- -- メニューに設定を追加
-- hook.Add("VRMod_Menu", "VRDash_Settings", function(frame)
--     if not frame or not frame.SettingsForm then return end
    
--     local form = frame.SettingsForm
--     form:CheckBox("Enable VR Dash Movement", "vrmod_dash_enabled")
--     form:CheckBox("Enable Dash Invincibility", "vrmod_dash_invincibility")
--     form:CheckBox("Show Debug Information", "vrmod_dash_debug")
    
--     local slider = form:NumSlider("Speed Threshold", "vrmod_dash_speed", 50, 500, 0)
--     slider:SetTooltip("Speed threshold for dash detection")
-- end)

-- -- スクリプトのロードメッセージ
-- print("VRMod Dash script loaded - Simple HMD movement detection version")