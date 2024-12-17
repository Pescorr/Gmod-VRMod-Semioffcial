-- if SERVER then return end

-- -- Configuration and state management
-- local QuickMenu = {
--     items = {}, -- Stores all menu items
--     config = {}, -- Stores user configuration
--     defaultConVars = {
--         spawn_menu = CreateClientConVar("vrmod_quickmenu_spawn_menu", "1", true, FCVAR_ARCHIVE),
--         context_menu = CreateClientConVar("vrmod_quickmenu_context_menu", "1", true, FCVAR_ARCHIVE),
--         noclip = CreateClientConVar("vrmod_quickmenu_noclip", "1", true, FCVAR_ARCHIVE),
--         chat = CreateClientConVar("vrmod_quickmenu_chat", "1", true, FCVAR_ARCHIVE),
--         mirror = CreateClientConVar("vrmod_quickmenu_togglemirror", "1", true, FCVAR_ARCHIVE),
--         seated = CreateClientConVar("vrmod_quickmenu_seated_menu", "1", true, FCVAR_ARCHIVE),
--         vehicle_mode = CreateClientConVar("vrmod_quickmenu_togglevehiclemode", "1", true, FCVAR_ARCHIVE)
--     }
-- }

-- -- Item management functions
-- function QuickMenu:LoadConfig()
--     if file.Exists("vrmod/quickmenu_config.txt", "DATA") then
--         self.config = util.JSONToTable(file.Read("vrmod/quickmenu_config.txt", "DATA")) or {}
--     end
-- end

-- function QuickMenu:SaveConfig()
--     if not file.Exists("vrmod", "DATA") then
--         file.CreateDir("vrmod")
--     end
--     file.Write("vrmod/quickmenu_config.txt", util.TableToJSON(self.config, true))
-- end

-- function QuickMenu:UpdateMenuItems()
--     -- Clear existing menu items
--     for k, _ in pairs(g_VR.menuItems or {}) do
--         vrmod.RemoveInGameMenuItem(k)
--     end

--     -- Add configured items
--     for _, item in pairs(self.items) do
--         if item.enabled then
--             vrmod.AddInGameMenuItem(item.name, item.row, item.column, item.action)
--         end
--     end
-- end

-- function QuickMenu:AddCustomItem(name, command, row, column)
--     if not name or name == "" then return false end
    
--     local newItem = {
--         name = name,
--         command = command,
--         row = tonumber(row) or 0,
--         column = tonumber(column) or 0,
--         enabled = true,
--         action = function() 
--             RunConsoleCommand(command)
--         end,
--         isCustom = true
--     }

--     table.insert(self.items, newItem)
--     self:SaveConfig()
--     self:UpdateMenuItems()
--     return true
-- end

-- function QuickMenu:RemoveItem(index)
--     if self.items[index] and self.items[index].isCustom then
--         table.remove(self.items, index)
--         self:SaveConfig()
--         self:UpdateMenuItems()
--         return true
--     end
--     return false
-- end

-- function QuickMenu:CreateEditor()
--     if not g_VR.active then return end

--     local frame = vgui.Create("DFrame")
--     frame:SetSize(800, 600)
--     frame:SetTitle("VR Quick Menu Editor")
--     frame:Center()
--     frame:MakePopup()

--     -- List view for items
--     local list = vgui.Create("DListView", frame)
--     list:Dock(FILL)
--     list:AddColumn("Name")
--     list:AddColumn("Command")
--     list:AddColumn("Position")
--     list:AddColumn("Type")
    
--     -- Add item panel
--     local addPanel = vgui.Create("DPanel", frame)
--     addPanel:Dock(BOTTOM)
--     addPanel:SetTall(100)
    
--     local nameEntry = vgui.Create("DTextEntry", addPanel)
--     nameEntry:SetPlaceholderText("Button Name")
--     nameEntry:Dock(LEFT)
--     nameEntry:SetWide(200)
    
--     local cmdEntry = vgui.Create("DTextEntry", addPanel)
--     cmdEntry:SetPlaceholderText("Console Command")
--     cmdEntry:Dock(LEFT)
--     cmdEntry:SetWide(200)
    
--     local rowEntry = vgui.Create("DNumberWang", addPanel)
--     rowEntry:SetMinMax(0, 5)
--     rowEntry:SetValue(0)
--     rowEntry:Dock(LEFT)
--     rowEntry:SetWide(50)
    
--     local colEntry = vgui.Create("DNumberWang", addPanel)
--     colEntry:SetMinMax(0, 5)
--     colEntry:SetValue(0)
--     colEntry:Dock(LEFT)
--     colEntry:SetWide(50)

--     local addBtn = vgui.Create("DButton", addPanel)
--     addBtn:SetText("Add Item")
--     addBtn:Dock(RIGHT)
--     addBtn:SetWide(100)
--     addBtn.DoClick = function()
--         self:AddCustomItem(
--             nameEntry:GetValue(),
--             cmdEntry:GetValue(),
--             rowEntry:GetValue(),
--             colEntry:GetValue()
--         )
--         self:RefreshList(list)
--     end

--     -- Remove button
--     local removeBtn = vgui.Create("DButton", addPanel)
--     removeBtn:SetText("Remove Selected")
--     removeBtn:Dock(RIGHT)
--     removeBtn:SetWide(100)
--     removeBtn.DoClick = function()
--         local selected = list:GetSelectedLine()
--         if selected then
--             self:RemoveItem(selected)
--             self:RefreshList(list)
--         end
--     end

--     self:RefreshList(list)
-- end

-- function QuickMenu:RefreshList(list)
--     list:Clear()
--     for i, item in ipairs(self.items) do
--         list:AddLine(
--             item.name,
--             item.command or "",
--             string.format("Row: %d, Col: %d", item.row, item.column),
--             item.isCustom and "Custom" or "Built-in"
--         )
--     end
-- end

-- -- Initialize hooks
-- hook.Add("VRMod_Start", "QuickMenuInit", function(ply)
--     if ply == LocalPlayer() then
--         QuickMenu:LoadConfig()
--         QuickMenu:UpdateMenuItems()
--     end
-- end)

-- hook.Add("VRMod_OpenQuickMenu", "UpdateQuickMenuItems", function()
--     QuickMenu:UpdateMenuItems()
-- end)

-- -- Console command to open editor
-- concommand.Add("vrmod_quickmenu_editor", function()
--     QuickMenu:CreateEditor()
-- end)

-- return QuickMenu