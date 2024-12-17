-- if SERVER then return end
-- -- Configuration constants
-- local MENU_CONFIG_FILE = "vrmod/quickmenu_config.txt"
-- -- Main QuickMenu object to encapsulate all menu functionality
-- local QuickMenu = {
--     items = {}, -- Stores all menu items (both built-in and custom)
--     isDragging = false, -- Tracks drag state for UI
--     draggedItem = nil, -- Currently dragged item
--     moveMode = false, -- Tracks if we're in move mode
--     moveSourceIndex = nil, -- Source index for move operation
--     pendingChanges = false -- Tracks unsaved changes
-- }

-- -- Calculates the absolute position from row and column
-- function QuickMenu:CalculatePosition(row, column)
--     return (row * 6) + column
-- end

-- -- Converts absolute position back to row and column
-- function QuickMenu:GetRowAndColumn(position)
--     local row = math.floor(position / 6)
--     local column = position % 6

--     return row, column
-- end

-- -- Formats position for display in UI
-- function QuickMenu:FormatPosition(position)
--     local row, column = self:GetRowAndColumn(position)

--     return string.format("Row %d, Column %d", row + 1, column + 1)
-- end

-- -- Updates menu state by integrating built-in VR items with custom items
-- function QuickMenu:CaptureMenuState()
--     local menuState = {}
--     -- Capture built-in VR menu items
--     if g_VR and g_VR.menuItems then
--         for _, item in pairs(g_VR.menuItems) do
--             local position = self:CalculatePosition(item.slot, item.slotPos)
--             table.insert(
--                 menuState,
--                 {
--                     name = item.name,
--                     position = position,
--                     row = item.slot,
--                     column = item.slotPos,
--                     visible = true,
--                     action = item.func,
--                     isBuiltin = true
--                 }
--             )
--         end
--     end

--     -- Preserve custom items by merging them with built-in items
--     for _, customItem in pairs(self.items) do
--         if not customItem.isBuiltin then
--             table.insert(menuState, customItem)
--         end
--     end

--     -- Sort by position for consistent ordering
--     table.sort(menuState, function(a, b) return a.position < b.position end)
--     self.items = menuState
--     self:SaveConfig()
-- end

-- -- Initializes the menu system and loads saved configuration
-- function QuickMenu:Init()
--     if not file.Exists("vrmod", "DATA") then
--         file.CreateDir("vrmod")
--     end

--     -- Load saved configuration if it exists
--     if file.Exists(MENU_CONFIG_FILE, "DATA") then
--         self.items = util.JSONToTable(file.Read(MENU_CONFIG_FILE, "DATA")) or {}
--     end

--     self:CaptureMenuState()
-- end

-- -- Saves current configuration to file
-- function QuickMenu:SaveConfig()
--     file.Write(MENU_CONFIG_FILE, util.TableToJSON(self.items, true))
-- end

-- -- Updates the menu display in real-time
-- function QuickMenu:UpdateMenuDisplay()
--     -- Clear existing menu items
--     if g_VR and g_VR.menuItems then
--         for k, _ in pairs(g_VR.menuItems) do
--             vrmod.RemoveInGameMenuItem(k)
--         end
--     end

--     -- Add current items
--     for _, item in ipairs(self.items) do
--         if item.visible then
--             vrmod.AddInGameMenuItem(item.name, item.row, item.column, item.action)
--         end
--     end
-- end

-- -- Adds a new custom menu item
-- function QuickMenu:AddCustomItem(name, command)
--     if not name or name == "" or not command or command == "" then return end
--     -- Find next available position
--     local position = 0
--     for _, item in ipairs(self.items) do
--         position = math.max(position, item.position)
--     end

--     position = position + 1
--     local row, column = self:GetRowAndColumn(position)
--     -- Create and add new item
--     table.insert(
--         self.items,
--         {
--             name = name,
--             position = position,
--             row = row,
--             column = column,
--             visible = true,
--             action = function()
--                 RunConsoleCommand(command)
--             end,
--             command = command,
--             isBuiltin = false
--         }
--     )

--     self.pendingChanges = true
--     self:SaveConfig()
-- end

-- -- Reorders items and updates their positions
-- function QuickMenu:ReorderItems()
--     table.sort(self.items, function(a, b) return a.position < b.position end)
--     for i, item in ipairs(self.items) do
--         item.position = i - 1
--         item.row, item.column = self:GetRowAndColumn(item.position)
--     end

--     self.pendingChanges = true
--     self:SaveConfig()
-- end

-- -- Moves an item from one position to another
-- function QuickMenu:MoveItem(from, to)
--     if from == to then return end
--     local item = table.remove(self.items, from)
--     table.insert(self.items, to, item)
--     self:ReorderItems()
-- end

-- -- Moves item to specific position with validation
-- function QuickMenu:MoveItemToPosition(sourceIndex, targetIndex)
--     if not sourceIndex or not targetIndex or sourceIndex == targetIndex then return end
--     local item = table.remove(self.items, sourceIndex)
--     table.insert(self.items, targetIndex + 1, item)
--     self:ReorderItems()
--     self.pendingChanges = true
-- end

-- -- Opens the menu editor interface
-- function QuickMenu:OpenEditor()
--     if not g_VR.active then return end
--     -- Update current menu state before opening editor
--     self:CaptureMenuState()
--     -- Create main editor window
--     local frame = vgui.Create("DFrame")
--     frame:SetSize(800, 600)
--     frame:SetTitle("VR Quick Menu Editor")
--     frame:Center()
--     frame:MakePopup()
--     -- Create list view for menu items
--     local list = vgui.Create("DListView", frame)
--     list:Dock(FILL)
--     list:DockMargin(5, 5, 5, 5)
--     list:SetMultiSelect(false)
--     list:AddColumn("Name")
--     list:AddColumn("Position")
--     list:AddColumn("Type")
--     list:AddColumn("Command")
--     list:AddColumn("Visible")
--     -- Function to refresh the list view
--     local function RefreshList()
--         list:Clear()
--         for i, item in ipairs(self.items) do
--             local line = list:AddLine(item.name, self:FormatPosition(item.position), item.isBuiltin and "Built-in" or "Custom", item.command or "", item.visible and "Yes" or "No")
--             -- Highlight selected item during move operation
--             if self.moveMode and i == self.moveSourceIndex then
--                 line:SetColor(Color(255, 255, 0))
--             end
--         end
--     end

--     -- Control panel for buttons and inputs
--     local controlPanel = vgui.Create("DPanel", frame)
--     controlPanel:Dock(BOTTOM)
--     controlPanel:SetTall(130)
--     controlPanel:DockMargin(5, 5, 5, 5)
--     -- Move button
--     local moveBtn = vgui.Create("DButton", controlPanel)
--     moveBtn:SetText(self.moveMode and "Cancel Move" or "Move Item")
--     moveBtn:SetPos(10, 10)
--     moveBtn:SetSize(100, 25)
--     moveBtn.DoClick = function()
--         self.moveMode = not self.moveMode
--         self.moveSourceIndex = nil
--         moveBtn:SetText(self.moveMode and "Cancel Move" or "Move Item")
--         RefreshList()
--     end

--     -- Apply button
--     local applyBtn = vgui.Create("DButton", controlPanel)
--     applyBtn:SetText("Apply Changes")
--     applyBtn:SetPos(120, 10)
--     applyBtn:SetSize(100, 25)
--     applyBtn.DoClick = function()
--         self:SaveConfig()
--         self:UpdateMenuDisplay()
--         self.pendingChanges = false
--         notification.AddLegacy("Changes applied successfully", NOTIFY_GENERIC, 3)
--     end

--     -- New item inputs
--     local nameLabel = vgui.Create("DLabel", controlPanel)
--     nameLabel:SetText("Button Name:")
--     nameLabel:SetPos(10, 45)
--     local nameEntry = vgui.Create("DTextEntry", controlPanel)
--     nameEntry:SetPos(100, 45)
--     nameEntry:SetSize(200, 20)
--     local commandLabel = vgui.Create("DLabel", controlPanel)
--     commandLabel:SetText("Command:")
--     commandLabel:SetPos(310, 45)
--     local commandEntry = vgui.Create("DTextEntry", controlPanel)
--     commandEntry:SetPos(370, 45)
--     commandEntry:SetSize(200, 20)
--     -- Add button
--     local addBtn = vgui.Create("DButton", controlPanel)
--     addBtn:SetText("Add New Button")
--     addBtn:SetPos(580, 45)
--     addBtn:SetSize(100, 20)
--     addBtn.DoClick = function()
--         self:AddCustomItem(nameEntry:GetValue(), commandEntry:GetValue())
--         RefreshList()
--         nameEntry:SetValue("")
--         commandEntry:SetValue("")
--     end

--     -- Remove button
--     local removeBtn = vgui.Create("DButton", controlPanel)
--     removeBtn:SetText("Remove Selected")
--     removeBtn:SetPos(10, 75)
--     removeBtn:SetSize(100, 25)
--     removeBtn.DoClick = function()
--         local selected = list:GetSelectedLine()
--         if selected and not self.items[selected].isBuiltin then
--             table.remove(self.items, selected)
--             self:ReorderItems()
--             RefreshList()
--         end
--     end

--     -- Toggle visibility button
--     local toggleBtn = vgui.Create("DButton", controlPanel)
--     toggleBtn:SetText("Toggle Visibility")
--     toggleBtn:SetPos(120, 75)
--     toggleBtn:SetSize(100, 25)
--     toggleBtn.DoClick = function()
--         local selected = list:GetSelectedLine()
--         if selected then
--             self.items[selected].visible = not self.items[selected].visible
--             self.pendingChanges = true
--             RefreshList()
--         end
--     end

--     -- Handle list selection for move operation
--     function list:OnRowSelected(lineID, line)
--         if QuickMenu.moveMode then
--             if not QuickMenu.moveSourceIndex then
--                 -- Select source item
--                 QuickMenu.moveSourceIndex = lineID
--                 RefreshList()
--             else
--                 -- Move item to target position
--                 QuickMenu:MoveItemToPosition(QuickMenu.moveSourceIndex, lineID)
--                 QuickMenu.moveMode = false
--                 QuickMenu.moveSourceIndex = nil
--                 moveBtn:SetText("Move Item")
--                 RefreshList()
--             end
--         end
--     end

--     -- Handle window closing with unsaved changes
--     function frame:OnClose()
--         if QuickMenu.pendingChanges then
--             local confirm = vgui.Create("DFrame")
--             confirm:SetSize(300, 150)
--             confirm:SetTitle("Unsaved Changes")
--             confirm:Center()
--             confirm:MakePopup()
--             local label = vgui.Create("DLabel", confirm)
--             label:SetText("You have unsaved changes.\nDo you want to save before closing?")
--             label:SetPos(20, 30)
--             label:SizeToContents()
--             local saveBtn = vgui.Create("DButton", confirm)
--             saveBtn:SetText("Save and Close")
--             saveBtn:SetPos(20, 80)
--             saveBtn:SetSize(120, 25)
--             saveBtn.DoClick = function()
--                 QuickMenu:SaveConfig()
--                 QuickMenu:UpdateMenuDisplay()
--                 confirm:Close()
--                 frame:Remove()
--             end

--             local discardBtn = vgui.Create("DButton", confirm)
--             discardBtn:SetText("Discard Changes")
--             discardBtn:SetPos(160, 80)
--             discardBtn:SetSize(120, 25)
--             discardBtn.DoClick = function()
--                 confirm:Close()
--                 frame:Remove()
--             end
--         else
--             frame:Remove()
--         end
--     end

--     -- Show initial list
--     RefreshList()
-- end

-- -- Register console command to open editor
-- concommand.Add(
--     "vrmod_quickmenu_editor",
--     function()
--         QuickMenu:OpenEditor()
--     end
-- )

-- -- Initialize menu when VR starts
-- hook.Add(
--     "VRMod_Start",
--     "QuickMenuInit",
--     function(ply)
--         if ply == LocalPlayer() then
--             QuickMenu:Init()
--         end
--     end
-- )

-- -- Update menu items when quick menu opens
-- hook.Add(
--     "VRMod_OpenQuickMenu",
--     "CustomQuickMenu",
--     function()
--         QuickMenu:CaptureMenuState()
--         for _, item in ipairs(QuickMenu.items) do
--             if item.visible then
--                 vrmod.AddInGameMenuItem(item.name, item.row, item.column, item.action)
--             end
--         end
--     end
-- )

-- return QuickMenu