-- VRコントローラーのジェスチャー検出とコマンド実行
local gestures = {
    -- ジェスチャーの定義
    -- {
    --     name = "上向きスワイプ",
    --     check = function(controller)
    --         local vel = controller.vel
    --         return vel.z > 2.0 and math.abs(vel.x) < 0.5 and math.abs(vel.y) < 0.5
    --     end,
    --     command = "say Hello!" -- 実行するコマンド
    -- },
    -- {
    --     name = "下向きスワイプ", 
    --     check = function(controller)
    --         local vel = controller.vel
    --         return vel.z < -2.0 and math.abs(vel.x) < 0.5 and math.abs(vel.y) < 0.5
    --     end,
    --     command = "say Goodbye!"
    -- },
    -- 他のジェスチャーをここに追加
}

local gestureTimeout = 0.5 -- ジェスチャー検出のクールダウン時間
local lastGestureTime = 0

-- ジェスチャー検出のメイン処理
hook.Add("VRMod_Tracking", "gesture_detection", function()
    if not g_VR.active then return end
    
    -- クールダウンチェック
    if SysTime() - lastGestureTime < gestureTimeout then return end
    
    -- 右手コントローラーのチェック
    local rightHand = {
        pos = g_VR.tracking.pose_righthand.pos,
        ang = g_VR.tracking.pose_righthand.ang,
        vel = g_VR.tracking.pose_righthand.vel,
        angvel = g_VR.tracking.pose_righthand.angvel
    }
    
    -- 左手コントローラーのチェック
    local leftHand = {
        pos = g_VR.tracking.pose_lefthand.pos,
        ang = g_VR.tracking.pose_lefthand.ang,
        vel = g_VR.tracking.pose_lefthand.vel,
        angvel = g_VR.tracking.pose_lefthand.angvel
    }
    
    -- 各ジェスチャーをチェック
    for _, gesture in ipairs(gestures) do
        -- 右手でのジェスチャーチェック
        if gesture.check(rightHand) then
            RunConsoleCommand(unpack(string.Split(gesture.command, " ")))
            lastGestureTime = SysTime()
            print("Gesture detected: " .. gesture.name .. " (Right Hand)")
            return
        end
        
        -- 左手でのジェスチャーチェック
        if gesture.check(leftHand) then
            RunConsoleCommand(unpack(string.Split(gesture.command, " ")))
            lastGestureTime = SysTime()
            print("Gesture detected: " .. gesture.name .. " (Left Hand)")
            return
        end
    end
end)

-- ジェスチャーの追加用関数
function AddVRGesture(name, checkFunc, command)
    table.insert(gestures, {
        name = name,
        check = checkFunc,
        command = command
    })
end

-- ジェスチャーの追加例
-- AddVRGesture(
--     "右スワイプ",
--     function(controller)
--         local vel = controller.vel
--         return vel.x > 2.0 and math.abs(vel.y) < 0.5 and math.abs(vel.z) < 0.5
--     end,
--     "noclip"
-- )

-- ConVarの設定
CreateClientConVar("vrmod_gesture_timeout", "0.5", true, false, "ジェスチャー検出のクールダウン時間")

-- ConVarの更新を監視
cvars.AddChangeCallback("vrmod_gesture_timeout", function(name, old, new)
    gestureTimeout = tonumber(new)
end)