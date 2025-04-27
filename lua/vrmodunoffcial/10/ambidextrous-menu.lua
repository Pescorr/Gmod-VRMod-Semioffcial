-- -- 両手でのメニュー操作とコンテキストメニューの拡張
-- local menuControls = {}

-- -- コンフィグ設定
-- CreateClientConVar("vrmod_menu_hand", "both", true, FCVAR_ARCHIVE) -- right/left/both
-- CreateClientConVar("vrmod_context_menu_interaction", "1", true, FCVAR_ARCHIVE)

-- -- メニュー操作の状態管理
-- local menuState = {
--     activeHand = "right",
--     menuOpen = false,
--     lastCursorPos = Vector(0,0,0),
--     targetEntity = nil
-- }

-- -- カーソル位置の計算
-- local function calculateCursorPosition(hand)
--     local handPos, handAng
--     if hand == "left" then
--         handPos = g_VR.tracking.pose_lefthand.pos
--         handAng = g_VR.tracking.pose_lefthand.ang
--     else
--         handPos = g_VR.tracking.pose_righthand.pos
--         handAng = g_VR.tracking.pose_righthand.ang
--     end

--     -- レイキャストでカーソル位置を計算
--     local trace = util.TraceLine({
--         start = handPos,
--         endpos = handPos + handAng:Forward() * 1000,
--         filter = LocalPlayer()
--     })

--     return trace.HitPos, trace.Entity
-- end

-- -- メニュー操作のハンドラー
-- hook.Add("VRMod_Input", "AmbidextrousMenuHandler", function(action, pressed)
--     if not vrmod.IsPlayerInVR(LocalPlayer()) then return end
    
--     local menuHand = GetConVar("vrmod_menu_hand"):GetString()
    
--     -- メニュー開閉の処理
--     if action == "boolean_spawnmenu" or action == "boolean_contextmenu" then
--         if menuHand == "both" or 
--            (action == "boolean_spawnmenu" and menuHand == "both") or
--            (action == "boolean_contextmenu" and menuHand == "both") then
            
--             menuState.menuOpen = pressed
--             menuState.activeHand = (action == "boolean_contextmenu") and "left" or "right"
            
--             -- メニューの表示/非表示を切り替え
--             if pressed then
--                 VRUtilMenuOpen("main_menu", 512, 512, nil, 
--                     menuState.activeHand == "left" and 1 or 2,
--                     Vector(4, 6, 5.5),
--                     Angle(0, -90, 10),
--                     0.03,
--                     true
--                 )
--             else
--                 VRUtilMenuClose("main_menu")
--             end
--         end
--     end
    
--     -- コンテキストメニューでのエンティティ操作
--     if menuState.menuOpen and GetConVar("vrmod_context_menu_interaction"):GetBool() then
--         local hitPos, hitEnt = calculateCursorPosition(menuState.activeHand)
--         menuState.targetEntity = hitEnt
        
--         if IsValid(menuState.targetEntity) then
--             if action == "boolean_primaryfire" and pressed then
--                 -- 左クリック処理
--                 hook.Run("VRMod_EntityLeftClick", menuState.targetEntity, hitPos)
--             elseif action == "boolean_secondaryfire" and pressed then
--                 -- 右クリック処理
--                 hook.Run("VRMod_EntityRightClick", menuState.targetEntity, hitPos)
--             end
--         end
--     end
-- end)

-- -- エンティティ操作のビジュアルフィードバック
-- hook.Add("PostDrawTranslucentRenderables", "ContextMenuHighlight", function()
--     if menuState.menuOpen and IsValid(menuState.targetEntity) then
--         render.SetColorMaterial()
--         render.DrawWireframeBox(
--             menuState.targetEntity:GetPos(),
--             menuState.targetEntity:GetAngles(),
--             menuState.targetEntity:OBBMins(),
--             menuState.targetEntity:OBBMaxs(),
--             Color(0, 255, 0),
--             true
--         )
--     end
-- end)

-- return menuControls
