if CLIENT then return end
-- コンソールコマンド 'remove_reflective_glass' を追加して、func_reflective_glass エンティティを削除する
concommand.Add(
    "remove_reflective_glass",
    function(ply, cmd, args)
        -- 実行者が管理者か確認
        if not IsValid(ply) or ply:IsAdmin() then
            -- func_reflective_glass エンティティを検索して削除
            for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
                ent:Remove()
            end

            -- 実行者がいる場合は、操作が成功したことを通知
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTCONSOLE, "Removed all func_reflective_glass entities.")
            end
        else
            -- 実行者が管理者でない場合は、拒否メッセージを表示
            ply:PrintMessage(HUD_PRINTCONSOLE, "You must be an admin to use this command.")
        end
    end
)


-- local function ReadBindingDataFromVMT(fileName)
--     local filePath = "materials/vrmod/" .. fileName .. ".vmt"
--     if file.Exists(filePath, "GAME") then
--         local f = file.Open(filePath, "r", "GAME")
--         if f then
--             local vmt = f:Read(f:Size())
--             f:Close()

--             local bindingData = string.match(vmt, '%$bindingdata%s+"(.+)"')
--             if bindingData then
--                 return bindingData
--             else
--                 print("Error: $bindingdata not found in " .. filePath)
--             end
--         else
--             print("Error: Failed to open " .. filePath)
--         end
--     else
--         print("Error: " .. filePath .. " not found")
--     end
--     return nil
-- end

-- local function WriteBindingDataToTXT(fileName, bindingData)
--     local filePath = "materials/vrmod/" .. fileName .. ".txt"
--     local f = file.Open(filePath, "w", "GAME")
--     if f then
--         f:Write(bindingData)
--         f:Close()
--         print("Binding data written to " .. filePath)
--     else
--         print("Error: Failed to write binding data to " .. filePath)
--     end
-- end

-- local function ProcessBindingFile(fileName)
--     local bindingData = ReadBindingDataFromVMT(fileName)
--     if bindingData then
--         WriteBindingDataToTXT(fileName, bindingData)
--     end
-- end

-- local function Init()
--     if not file.Exists("materials/vrmod", "GAME") then
--         file.CreateDir("materials/vrmod")
--     end

--     ProcessBindingFile("vrmod_action_manifest")
--     ProcessBindingFile("vrmod_bindings_holographic_controller")
--     ProcessBindingFile("vrmod_bindings_oculus_touch")
--     ProcessBindingFile("vrmod_bindings_vive_controller")
--     ProcessBindingFile("vrmod_bindings_knuckles")
--     ProcessBindingFile("vrmod_bindings_vive_cosmos_controller")
--     ProcessBindingFile("vrmod_bindings_vive_tracker_left_foot")
--     ProcessBindingFile("vrmod_bindings_vive_tracker_right_foot")
--     ProcessBindingFile("vrmod_bindings_vive_tracker_waist")
-- end

-- hook.Add("InitPostEntity", "VRMod_InitBindings", Init)
