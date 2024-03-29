-- -- vrmod_clipboard.lua

-- if SERVER then return end

-- -- クリップボードの内容を保存するテーブル
-- local clipboardData = {}

-- -- クリップボードの内容が変更された時のフック
-- hook.Add("OnClipboardTextChanged", "VRMod_ClipboardChanged", function(text)
--     if not clipboardData then
--         clipboardData = {}
--     end

--     local shouldSave = true -- デフォルトでは保存する
--     table.insert(clipboardData, {text, shouldSave})
    
--     -- vrclipboard.jsonファイルへの書き込み
--     local jsonData = util.TableToJSON(clipboardData)
--     if file.Write("vrmod/vrclipboard.json", jsonData) then
--         print("Clipboard data saved to vrclipboard.json:")
--         print(jsonData)
--     else
--         print("Failed to save clipboard data to vrclipboard.json")
--     end
    
--     updateVRClipboardMenu() -- メニューを更新する
-- end)

-- -- VRクリップボードメニューを表示する関数
-- local function showVRClipboardMenu()
--     if not g_VR.active then return end

--     local menuPanel = vgui.Create("DPanel")
--     menuPanel:SetSize(300, 400)
--     menuPanel:SetPos(0, 0)
--     menuPanel:SetPaintedManually(true)

--     -- メニューを更新する関数
--     function updateVRClipboardMenu()
--         menuPanel:Clear()
--         local yPos = 10

--         if not clipboardData then
--             clipboardData = {}
--         end

--         for i, data in ipairs(clipboardData) do
--             local text, shouldSave = data[1], data[2]
--             if shouldSave then
--                 local button = vgui.Create("DButton", menuPanel)
--                 button:SetText(text)
--                 button:SetSize(280, 30)
--                 button:SetPos(10, yPos)
--                 yPos = yPos + 40

--                 button.DoClick = function()
--                     local activeTextEntry = vgui.GetKeyboardFocus()
--                     if IsValid(activeTextEntry) then
--                         activeTextEntry:SetText(text)
--                     end
--                 end
--             end
--         end
--     end

--     updateVRClipboardMenu() -- 初期表示時にメニューを更新する

--     VRUtilMenuOpen("vrclipboard", 300, 400, menuPanel, 1, Vector(4, 12, 10), Angle(0, -90, 60), 0.03, true, function()
--         menuPanel:Remove()
--     end)
-- end

-- -- VRMod_Startフックにメニューを表示する関数を追加
-- hook.Add("VRMod_Start", "VRMod_ShowClipboardMenu", function(ply)
--     if ply == LocalPlayer() then
--         showVRClipboardMenu()
--     end
-- end)

-- -- ゲーム開始時にvrclipboard.jsonからクリップボードデータを読み込む
-- if file.Exists("vrmod/vrclipboard.json", "DATA") then
--     local jsonData = file.Read("vrmod/vrclipboard.json", "DATA")
--     if jsonData then
--         clipboardData = util.JSONToTable(jsonData)
--         print("Loaded clipboard data from vrclipboard.json:")
--         print(jsonData)
--     else
--         print("Failed to load clipboard data from vrclipboard.json")
--     end
-- else
--     print("vrclipboard.json not found. Creating new file.")
-- end