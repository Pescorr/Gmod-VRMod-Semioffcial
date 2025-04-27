-- if CLIENT then
--     local inputMap = {
--         -- VRMod標準入力とglueコマンドのマッピング
--         ["boolean_primaryfire"] = "attack",
--         ["boolean_secondaryfire"] = "attack2", 
--         ["boolean_use"] = "use",
--         ["boolean_jump"] = "jump",
--         ["boolean_sprint"] = "sprint",
--         ["boolean_reload"] = "reload",
--         ["boolean_walk"] = "walk",
--         ["boolean_flashlight"] = "flashlight"
--     }

--     -- VR入力ハンドラー
--     hook.Add("VRMod_Input", "Glue_VRInputHandler", function(action, pressed)
--         if not g_VR.active then return end
        
--         local glueCommand = inputMap[action]
--         if glueCommand then
--             -- glueコマンドに変換して送信
--             net.Start("Glue_VRInput")
--             net.WriteString(glueCommand)
--             net.WriteBool(pressed)
--             net.SendToServer()
--         end
--     end)

--     -- VRの位置トラッキング情報をglueに送信
--     hook.Add("VRMod_Tracking", "Glue_VRTracking", function()
--         if not g_VR.active then return end
        
--         local trackingData = {
--             hmd = {
--                 pos = g_VR.tracking.hmd.pos,
--                 ang = g_VR.tracking.hmd.ang
--             },
--             leftHand = {
--                 pos = g_VR.tracking.pose_lefthand.pos,
--                 ang = g_VR.tracking.pose_lefthand.ang
--             },
--             rightHand = {
--                 pos = g_VR.tracking.pose_righthand.pos, 
--                 ang = g_VR.tracking.pose_righthand.ang
--             }
--         }

--         net.Start("Glue_VRTracking")
--         net.WriteTable(trackingData)
--         net.SendToServer()
--     end)
-- end

-- if SERVER then
--     util.AddNetworkString("Glue_VRInput")
--     util.AddNetworkString("Glue_VRTracking")

--     -- VR入力をglueコマンドに変換して処理
--     net.Receive("Glue_VRInput", function(len, ply)
--         if not IsValid(ply) or not vrmod.IsPlayerInVR(ply) then return end
        
--         local command = net.ReadString()
--         local pressed = net.ReadBool()

--         -- glueコマンドシステムに入力を渡す
--         if GLUE and GLUE.HandleCommand then
--             GLUE:HandleCommand(ply, command, pressed)
--         end
--     end)

--     -- VRトラッキングデータの処理
--     net.Receive("Glue_VRTracking", function(len, ply)
--         if not IsValid(ply) or not vrmod.IsPlayerInVR(ply) then return end

--         local trackingData = net.ReadTable()
        
--         -- トラッキングデータをglueシステムで利用可能に
--         if GLUE and GLUE.UpdateVRTracking then
--             GLUE:UpdateVRTracking(ply, trackingData)
--         end
--     end)

--     -- glueコマンドシステムの拡張
--     hook.Add("Glue:SetupCommand", "VRInputHandler", function(ply, cmd)
--         if not IsValid(ply) or not vrmod.IsPlayerInVR(ply) then return end
        
--         -- VR使用時の特別な処理
--         local vrNet = g_VR and g_VR.net[ply:SteamID()]
--         if vrNet and vrNet.lerpedFrame then
--             -- VRの視点方向をプレイヤーの向きに反映
--             cmd:SetViewAngles(vrNet.lerpedFrame.hmdAng)
            
--             -- その他VR特有の動作処理
--             if vrmod.GetInput then
--                 local vrInput = vrmod.GetInput(ply)
--                 if vrInput then
--                     -- 移動入力の処理
--                     if vrInput.vector2_walkdirection then
--                         local walk = vrInput.vector2_walkdirection
--                         cmd:SetForwardMove(walk.y * ply:GetMaxSpeed())
--                         cmd:SetSideMove(walk.x * ply:GetMaxSpeed())
--                     end
--                 end
--             end
--         end
--     end)
-- end