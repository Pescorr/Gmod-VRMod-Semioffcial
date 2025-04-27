-- if CLIENT then
--     -- 設定とコンバーの作成
--     local cv_grab_distance = CreateClientConVar("vrmod_spawn_grab_distance", "100", true, FCVAR_ARCHIVE)
--     local cv_throw_force = CreateClientConVar("vrmod_spawn_throw_force", "1000", true, FCVAR_ARCHIVE)
--     local cv_scale_sensitivity = CreateClientConVar("vrmod_spawn_scale_sensitivity", "0.01", true, FCVAR_ARCHIVE)
--     local cv_rotation_sensitivity = CreateClientConVar("vrmod_spawn_rotation_sensitivity", "1", true, FCVAR_ARCHIVE)

--     -- スポーン用のローカル変数
--     local heldItem = nil
--     local initialGrabPos = nil
--     local initialItemScale = 1
--     local initialItemRotation = Angle(0,0,0)

--     -- ジェスチャー検出用の変数
--     local lastLeftPos = Vector(0,0,0)
--     local lastRightPos = Vector(0,0,0)
--     local scaleStartDistance = nil
    
--     -- アイテムのプレビュー表示用の関数
--     local function DrawItemPreview(item, pos, ang, scale)
--         render.SetColorModulation(1, 1, 1, 0.5)
--         render.SetBlend(0.5)
        
--         local mat = Matrix()
--         mat:SetScale(Vector(1,1,1) * scale)
--         item:EnableMatrix("RenderMultiply", mat)
        
--         item:SetPos(pos)
--         item:SetAngles(ang)
--         item:DrawModel()
        
--         render.SetBlend(1)
--     end

--     -- VRコントローラーの入力処理
--     hook.Add("VRMod_Input", "vrmod_itemspawner", function(action, pressed)
--         if action == "boolean_primaryfire" and pressed then
--             -- アイテムを掴む
--             if not heldItem and g_VR.menuFocus then
--                 local trace = util.TraceLine({
--                     start = g_VR.tracking.pose_righthand.pos,
--                     endpos = g_VR.tracking.pose_righthand.pos + g_VR.tracking.pose_righthand.ang:Forward() * cv_grab_distance:GetFloat(),
--                     filter = LocalPlayer()
--                 })
                
--                 if trace.Hit and IsValid(trace.Entity) then
--                     heldItem = trace.Entity
--                     initialGrabPos = WorldToLocal(trace.HitPos, Angle(), g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang)
--                     initialItemScale = 1
--                     initialItemRotation = heldItem:GetAngles()
                    
--                     net.Start("vrmod_spawn_grab")
--                     net.WriteEntity(heldItem)
--                     net.SendToServer()
--                 end
--             end
--         elseif action == "boolean_primaryfire" and not pressed then
--             -- アイテムを投げる/配置
--             if heldItem then
--                 local velocity = (g_VR.tracking.pose_righthand.pos - lastRightPos) * cv_throw_force:GetFloat()
                
--                 net.Start("vrmod_spawn_throw")
--                 net.WriteEntity(heldItem)
--                 net.WriteVector(velocity)
--                 net.WriteVector(heldItem:GetPos())
--                 net.WriteAngle(heldItem:GetAngles())
--                 net.WriteFloat(initialItemScale)
--                 net.SendToServer()
                
--                 heldItem = nil
--             end
--         end
--     end)

--     -- スケールと回転の処理
--     hook.Add("VRMod_Tracking", "vrmod_itemspawner_gestures", function()
--         if heldItem then
--             -- 両手でのスケール調整
--             if g_VR.input.boolean_left_pickup then
--                 local currentDistance = g_VR.tracking.pose_lefthand.pos:Distance(g_VR.tracking.pose_righthand.pos)
                
--                 if not scaleStartDistance then
--                     scaleStartDistance = currentDistance
--                 else
--                     local scaleFactor = (currentDistance - scaleStartDistance) * cv_scale_sensitivity:GetFloat()
--                     initialItemScale = math.Clamp(initialItemScale + scaleFactor, 0.1, 10)
--                 end
--             else
--                 scaleStartDistance = nil
--             end
            
--             -- 右手の回転で アイテムを回転
--             local rotDelta = g_VR.tracking.pose_righthand.ang - lastRightPos:Angle()
--             initialItemRotation = initialItemRotation + rotDelta * cv_rotation_sensitivity:GetFloat()
            
--             -- アイテムの位置とプレビューの更新
--             local itemPos = LocalToWorld(initialGrabPos, Angle(), g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang)
--             DrawItemPreview(heldItem, itemPos, initialItemRotation, initialItemScale)
--         end
        
--         -- 前フレームの位置を保存
--         lastLeftPos = g_VR.tracking.pose_lefthand.pos
--         lastRightPos = g_VR.tracking.pose_righthand.pos
--     end)

-- elseif SERVER then
--     -- ネットワーク文字列の登録
--     util.AddNetworkString("vrmod_spawn_grab")
--     util.AddNetworkString("vrmod_spawn_throw")
    
--     -- アイテムを掴む処理
--     net.Receive("vrmod_spawn_grab", function(len, ply)
--         local item = net.ReadEntity()
--         if not IsValid(item) then return end
        
--         -- アイテムの物理演算を無効化
--         local phys = item:GetPhysicsObject()
--         if IsValid(phys) then
--             phys:EnableMotion(false)
--         end
--     end)
    
--     -- アイテムを投げる/配置する処理
--     net.Receive("vrmod_spawn_throw", function(len, ply)
--         local item = net.ReadEntity()
--         local velocity = net.ReadVector()
--         local pos = net.ReadVector()
--         local ang = net.ReadAngle()
--         local scale = net.ReadFloat()
        
--         if not IsValid(item) then return end
        
--         -- アイテムの位置と回転を設定
--         item:SetPos(pos)
--         item:SetAngles(ang)
        
--         -- スケールを適用
--         local mat = Matrix()
--         mat:SetScale(Vector(1,1,1) * scale)
--         item:EnableMatrix("RenderMultiply", mat)
        
--         -- 物理演算を有効化して速度を設定
--         local phys = item:GetPhysicsObject()
--         if IsValid(phys) then
--             phys:EnableMotion(true)
--             phys:Wake()
--             phys:SetVelocity(velocity)
--         end
--     end)
-- end