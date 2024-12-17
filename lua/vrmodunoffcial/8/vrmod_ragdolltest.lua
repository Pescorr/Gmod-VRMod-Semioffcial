-- if CLIENT then
--     local function ApplyBoneTransform(ent, boneID, pos, ang)
--         -- 重要: ManipulateBonePositionには必ずVector型を渡す必要があります
--         if not isvector(pos) then
--             pos = Vector(0, 0, 0) -- デフォルト値を設定
--         end
        
--         -- ボーンIDの有効性チェック
--         if not boneID or boneID < 0 then
--             return false
--         end
        
--         -- エンティティの有効性チェック
--         if not IsValid(ent) then
--             return false
--         end

--         -- ボーン操作を実行
--         ent:ManipulateBonePosition(boneID, pos)
--         ent:ManipulateBoneAngles(boneID, ang)
        
--         return true
--     end

--     local function UpdateVRPlayerPose(ply)
--         if not IsValid(ply) or not g_VR.active then return end

--         -- VRデータの取得
--         local vrData = {
--             head = {
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

--         -- ボーンのマッピング
--         local boneMap = {
--             head = ply:LookupBone("ValveBiped.Bip01_Head1"),
--             spine = ply:LookupBone("ValveBiped.Bip01_Spine2"),
--             leftHand = ply:LookupBone("ValveBiped.Bip01_L_Hand"),
--             rightHand = ply:LookupBone("ValveBiped.Bip01_R_Hand")
--         }

--         -- プレイヤーの基準位置
--         local playerPos = ply:GetPos()
--         local playerAng = ply:GetAngles()

--         -- 各ボーンの位置を更新
--         for boneName, boneID in pairs(boneMap) do
--             if boneID and vrData[boneName] then
--                 -- ローカル空間からワールド空間への変換
--                 local worldPos, worldAng = LocalToWorld(
--                     vrData[boneName].pos,
--                     vrData[boneName].ang,
--                     playerPos,
--                     playerAng
--                 )
                
--                 -- プレイヤーの位置を基準とした相対位置を計算
--                 local localPos = WorldToLocal(
--                     worldPos,
--                     worldAng,
--                     playerPos,
--                     playerAng
--                 )

--                 -- ボーンの変換を適用
--                 ApplyBoneTransform(ply, boneID, localPos, worldAng)
--             end
--         end
--     end

--     -- フレーム毎の更新処理を設定
--     hook.Add("Think", "VRPlayerPoseUpdate", function()
--         local ply = LocalPlayer()
--         if IsValid(ply) then
--             UpdateVRPlayerPose(ply)
--         end
--     end)
-- end