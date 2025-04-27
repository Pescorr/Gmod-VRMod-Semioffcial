-- -- 拡張ホルスターシステム
-- local holsterSystem = {}

-- -- コンフィグ設定
-- CreateClientConVar("vrmod_holster_slots", "4", true, FCVAR_ARCHIVE)
-- CreateClientConVar("vrmod_holster_save_enabled", "1", true, FCVAR_ARCHIVE)

-- -- ホルスターのデータ構造
-- local holsterData = {
--     slots = {},
--     savedItems = {} -- Dupeデータ用
-- }

-- -- ホルスタースロットの初期化
-- local function initializeHolsterSlots()
--     local slotCount = GetConVar("vrmod_holster_slots"):GetInt()
--     for i = 1, slotCount do
--         holsterData.slots[i] = {
--             entity = nil,
--             dupeData = nil,
--             position = Vector(0, i * 10, 0), -- ホルスター位置
--             active = false
--         }
--     end
-- end

-- -- エンティティの保存処理
-- function holsterSystem.SaveEntity(ent)
--     if not IsValid(ent) then return nil end
    
--     local dupeData = {
--         class = ent:GetClass(),
--         model = ent:GetModel(),
--         angles = ent:GetAngles(),
--         position = ent:GetPos(),
--         material = ent:GetMaterial(),
--         color = ent:GetColor(),
--         physicsObjects = {}
--     }
    
--     -- 物理オブジェクトのデータを保存
--     if ent:GetPhysicsObjectCount() > 0 then
--         for i = 0, ent:GetPhysicsObjectCount() - 1 do
--             local physObj = ent:GetPhysicsObjectNum(i)
--             if IsValid(physObj) then
--                 dupeData.physicsObjects[i] = {
--                     pos = physObj:GetPos(),
--                     ang = physObj:GetAngles(),
--                     mass = physObj:GetMass(),
--                     material = physObj:GetMaterial()
--                 }
--             end
--         end
--     end
    
--     -- カスタムデータの保存
--     if ent.GetTable then
--         dupeData.customData = table.Copy(ent:GetTable())
--     end
    
--     return dupeData
-- end

-- -- エンティティの復元処理
-- function holsterSystem.RestoreEntity(dupeData)
--     if not dupeData then return nil end
    
--     -- エンティティの作成
--     local ent = ents.Create(dupeData.class)
--     if not IsValid(ent) then return nil end
    
--     ent:SetModel(dupeData.model)
--     ent:SetPos(dupeData.position)
--     ent:SetAngles(dupeData.angles)
--     ent:SetMaterial(dupeData.material)
--     ent:SetColor(dupeData.color)
    
--     -- 物理オブジェクトの復元
--     ent:Spawn()
--     ent:Activate()
    
--     if dupeData.physicsObjects then
--         for i, physData in pairs(dupeData.physicsObjects) do
--             local physObj = ent:GetPhysicsObjectNum(i)
--             if IsValid(physObj) then
--                 physObj:SetPos(physData.pos)
--                 physObj:SetAngles(physData.ang)
--                 physObj:SetMass(physData.mass)
--                 physObj:SetMaterial(physData.material)
--             end
--         end
--     end
    
--     -- カスタムデータの復元
--     if dupeData.customData then
--         table.Merge(ent:GetTable(), dupeData.customData)
--     end
    
--     return ent
-- end

-- -- ホルスターへのアイテム格納
-- function holsterSystem.StoreItem(slotIndex, entity)
--     if not holsterData.slots[slotIndex] then return false end
    
--     local slot = holsterData.slots[slotIndex]
--     if IsValid(entity) then
--         -- 通常のエンティティ格納
--         slot.entity = entity
--         entity:SetNoDraw(true)
--         entity:SetNotSolid(true)
--     else
--         -- Dupeデータとして保存
--         slot.dupeData = holsterSystem.SaveEntity(entity)
--         if IsValid(entity) then
--             entity:Remove()
--         end
--     end
    
--     -- サーバーに状態を同期
--     net.Start("VRMod_HolsterSync")
--     net.WriteInt(slotIndex, 8)
--     net.WriteEntity(entity)
--     net.WriteBool(slot.dupeData ~= nil)
--     net.SendToServer()
    
--     return true
-- end

-- -- ホルスターからのアイテム取り出し
-- function holsterSystem.RetrieveItem(slotIndex)
--     local slot = holsterData.slots[slotIndex]
--     if not slot then return nil end
    
--     local item
--     if IsValid(slot.entity) then
--         item = slot.entity
--         item:SetNoDraw(false)
--         item:SetNotSolid(false)
--     elseif slot.dupeData then
--         item = holsterSystem.RestoreEntity(slot.dupeData)
--     end
    
--     slot.entity = nil
--     slot.dupeData = nil
    
--     -- サーバーに状態を同期
--     net.Start("VRMod_HolsterSync")
--     net.WriteInt(slotIndex, 8)
--     net.WriteEntity(nil)
--     net.WriteBool(false)
--     net.SendToServer()
    
--     return item
-- end

-- -- ホルスターのビジュアル表示
-- hook.Add("PostDrawTranslucentRenderables", "HolsterVisuals", function()
--     if not vrmod.IsPlayerInVR(LocalPlayer()) then return end
    
--     for i, slot in pairs(holsterData.slots) do
--         local pos = LocalPlayer():GetPos() + slot.position
        
--         -- スロットの表示
--         render.SetColorMaterial()
--         render.DrawWireframeSphere(pos, 5, 8, 8, 
--             slot.entity or slot.dupeData and Color(0, 255, 0) or Color(255, 255, 255))
        
--         -- アイテム情報の表示
--         if slot.entity or slot.dupeData then
--             local text = slot.entity and slot.entity:GetClass() or "Saved Item"
--             cam.Start3D2D(pos + Vector(0, 0, 10), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.1)
--             draw.SimpleText(text, "Default", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER)
--             cam.End3D2D()
--         end
--     end
-- end)

-- -- 入力処理
-- hook.Add("VRMod_Input", "HolsterSystemHandler", function(action, pressed)
--     if not vrmod.IsPlayerInVR(LocalPlayer()) then return end
    
--     -- ホルスターの操作
--     if action == "boolean_use" and pressed then
--         local handPos = vrmod.GetRightHandPos(LocalPlayer())
        
--         -- 最も近いホルスタースロットを探す
--         local closestSlot = nil
--         local closestDist = 20 -- 最大距離
        
--         for i, slot in pairs(holsterData.slots) do
--             local dist = (handPos - (LocalPlayer():GetPos() + slot.position)):Length()
--             if dist < closestDist then
--                 closestSlot = i
--                 closestDist = dist
--             end
--         end
        
--         if closestSlot then
--             -- アイテムの出し入れ
--             local heldEntity = g_VR.heldEntityRight
--             if IsValid(heldEntity) then
--                 holsterSystem.StoreItem(closestSlot, heldEntity)
--             else
--                 local item = holsterSystem.RetrieveItem(closestSlot)
--                 if IsValid(item) then
--                     g_VR.heldEntityRight = item
--                 end
--             end
--         end
--     end
-- end)

-- -- 初期化
-- initializeHolsterSlots()

-- return holsterSystem
