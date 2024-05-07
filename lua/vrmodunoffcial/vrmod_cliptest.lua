-- if CLIENT then
--     -- ダミー用のconvarを作成
--     CreateClientConVar("clipboard_data", "", true, false)
--     -- 選択中のテキストを取得する関数
--     local function GetSelectedText()
--         local textEntry = vgui.GetKeyboardFocus()
--         if IsValid(textEntry) then
--             local text = textEntry:GetText()
--             local startPos, endPos = textEntry:GetSelection()
--             if startPos ~= endPos then return text:sub(startPos, endPos - 1) end
--         end

--         return nil
--     end

--     -- 右クリックメニューに "Copy (VR)" 項目を追加
--     hook.Add(
--         "OnContextMenuOpen",
--         "AddVRCopyOption",
--         function()
--             local ent = LocalPlayer():GetEyeTrace().Entity
--             if IsValid(ent) then
--                 local menuOption = "Copy (VR)"
--                 local function copyToClipboard()
--                     local entName = ent:GetName()
--                     local entClass = ent:GetClass()
--                     local entModel = ent:GetModel()
--                     local clipboardText = string.format("Name: %s\nClass: %s\nModel: %s", entName, entClass, entModel)
--                     SetClipboardText(clipboardText)
--                     print("Entity information copied to clipboard.")
--                 end

--                 hook.Add(
--                     "AddContextMenuOption",
--                     "AddVRCopyOption",
--                     function(menu)
--                         menu:AddOption(menuOption, copyToClipboard)
--                     end
--                 )
--             end
--         end
--     )

--     -- 選択中の文字列をclipboard_dataに記録するconcommand
--     concommand.Add(
--         "selection_to_clipboard",
--         function(ply, cmd, args)
--             local selectedText = GetSelectedText()
--             if selectedText then
--                 SetClipboardText(selectedText)
--                 print("Selected text copied to clipboard.")
--             else
--                 print("No text selected.")
--             end
--         end
--     )

--     -- gmodに保存した文字列を入力するconcommand
--     concommand.Add(
--         "test_input",
--         function(ply, cmd, args)
--             timer.Simple(
--                 0,
--                 function()
--                     local activeTextEntry = vgui.GetKeyboardFocus()
--                     if IsValid(activeTextEntry) then
--                         -- クリップボードから文字列を取得
--                         local clipboardText = GetClipboardText()
--                         activeTextEntry:SetText(clipboardText)
--                         print("Inserted clipboard text into the active text entry.")
--                     else
--                         print("No active text entry found.")
--                     end
--                 end
--             )
--         end
--     )
-- end