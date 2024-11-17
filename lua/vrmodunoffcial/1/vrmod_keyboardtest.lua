-- if CLIENT then
--     local function VRKeyboardRemapping()
--         if not g_VR.active then return end
        
--         -- フレームワークの作成
--         local VRKeyMap = {
--             -- メインアクション
--             ["boolean_primaryfire"] = { key = KEY_LBUTTON },
--             ["boolean_secondaryfire"] = { key = KEY_RBUTTON },
--             ["boolean_use"] = { key = KEY_E },
--             ["boolean_jump"] = { key = KEY_SPACE },
--             ["boolean_reload"] = { key = KEY_R },
            
--             -- 移動
--             ["boolean_forward"] = { key = KEY_W },
--             ["boolean_back"] = { key = KEY_S }, 
--             ["boolean_left"] = { key = KEY_A },
--             ["boolean_right"] = { key = KEY_D },
--             ["boolean_sprint"] = { key = KEY_LSHIFT },
            
--             -- ユーティリティ
--             ["boolean_chat"] = { key = KEY_Y },
--             ["boolean_undo"] = { key = KEY_Z },
--             ["boolean_flashlight"] = { key = KEY_F },
            
--             -- メニュー
--             ["boolean_changeweapon"] = { key = KEY_Q },
--             ["boolean_spawnmenu"] = { key = KEY_C }
--         }

--         hook.Add("VRMod_Input", "vrmod_keyboard_remapping", function(action, pressed)
--             if not VRKeyMap[action] then return end
            
--             if pressed then
--                 input.ButtonDown(VRKeyMap[action].key)
--                 hook.Run("KeyPress", LocalPlayer(), VRKeyMap[action].key)
--             else
--                 input.ButtonUp(VRKeyMap[action].key)
--                 hook.Run("KeyRelease", LocalPlayer(), VRKeyMap[action].key) 
--             end
--         end)

--         -- キーボードエミュレーション関数のオーバーライド
--         local original_IsKeyDown = input.IsKeyDown
--         input.IsKeyDown = function(key)
--             if g_VR.active then
--                 for action, data in pairs(VRKeyMap) do
--                     if data.key == key then
--                         return g_VR.input[action] or false
--                     end
--                 end
--             end
--             return original_IsKeyDown(key)
--         end
--     end

--     -- VRモード開始時にリマッピングを有効化
--     hook.Add("VRMod_Start", "vrmod_init_keyboard_remapping", VRKeyboardRemapping)
-- end