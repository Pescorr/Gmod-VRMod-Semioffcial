-- VRMod Semi-Official Addon Plus - Quick Menu Editor UI
-- クイックメニューエディタUIシステム
-- Version 1.0

if SERVER then return end

local PANEL = {}

-----------------------------------------------------------
-- Constants
-----------------------------------------------------------

local GRID_COLS = 6
local GRID_ROWS = 10
local CELL_WIDTH = 70
local CELL_HEIGHT = 40
local CELL_PADDING = 2

-----------------------------------------------------------
-- Editor Panel
-----------------------------------------------------------

function PANEL:Init()
    self.items = {}
    self.selectedIndex = nil

    self:SetSize(520, 500)

    -- Enable checkbox
    self.enableCheck = vgui.Create("DCheckBoxLabel", self)
    self.enableCheck:SetPos(10, 10)
    self.enableCheck:SetText("Enable Custom Quick Menu / カスタムクイックメニューを有効化")
    self.enableCheck:SetConVar("vrmod_quickmenu_use_custom")
    self.enableCheck:SizeToContents()

    -- Item list
    self.listLabel = vgui.Create("DLabel", self)
    self.listLabel:SetPos(10, 40)
    self.listLabel:SetText("Menu Items / メニューアイテム:")
    self.listLabel:SetTextColor(Color(255, 255, 255))
    self.listLabel:SizeToContents()

    self.itemList = vgui.Create("DListView", self)
    self.itemList:SetPos(10, 60)
    self.itemList:SetSize(300, 180)
    self.itemList:SetMultiSelect(false)
    self.itemList:AddColumn("Name"):SetWidth(100)
    self.itemList:AddColumn("Slot"):SetWidth(40)
    self.itemList:AddColumn("Pos"):SetWidth(35)
    self.itemList:AddColumn("Type"):SetWidth(60)
    self.itemList:AddColumn("Action"):SetWidth(60)

    self.itemList.OnRowSelected = function(_, index, row)
        self.selectedIndex = index
        self:UpdateButtonStates()
    end

    -- Buttons
    self.addBtn = vgui.Create("DButton", self)
    self.addBtn:SetPos(320, 60)
    self.addBtn:SetSize(90, 25)
    self.addBtn:SetText("Add / 追加")
    self.addBtn.DoClick = function()
        self:OpenItemDialog(nil)
    end

    self.editBtn = vgui.Create("DButton", self)
    self.editBtn:SetPos(320, 90)
    self.editBtn:SetSize(90, 25)
    self.editBtn:SetText("Edit / 編集")
    self.editBtn:SetEnabled(false)
    self.editBtn.DoClick = function()
        if self.selectedIndex and self.items[self.selectedIndex] then
            self:OpenItemDialog(self.selectedIndex)
        end
    end

    self.deleteBtn = vgui.Create("DButton", self)
    self.deleteBtn:SetPos(320, 120)
    self.deleteBtn:SetSize(90, 25)
    self.deleteBtn:SetText("Delete / 削除")
    self.deleteBtn:SetEnabled(false)
    self.deleteBtn.DoClick = function()
        if self.selectedIndex and self.items[self.selectedIndex] then
            table.remove(self.items, self.selectedIndex)
            self:RefreshList()
            self.selectedIndex = nil
            self:UpdateButtonStates()
        end
    end

    self.moveUpBtn = vgui.Create("DButton", self)
    self.moveUpBtn:SetPos(320, 160)
    self.moveUpBtn:SetSize(42, 25)
    self.moveUpBtn:SetText("Up")
    self.moveUpBtn:SetEnabled(false)
    self.moveUpBtn.DoClick = function()
        if self.selectedIndex and self.selectedIndex > 1 then
            local temp = self.items[self.selectedIndex]
            self.items[self.selectedIndex] = self.items[self.selectedIndex - 1]
            self.items[self.selectedIndex - 1] = temp
            self.selectedIndex = self.selectedIndex - 1
            self:RefreshList()
            self.itemList:SelectItem(self.itemList:GetLine(self.selectedIndex))
        end
    end

    self.moveDownBtn = vgui.Create("DButton", self)
    self.moveDownBtn:SetPos(368, 160)
    self.moveDownBtn:SetSize(42, 25)
    self.moveDownBtn:SetText("Down")
    self.moveDownBtn:SetEnabled(false)
    self.moveDownBtn.DoClick = function()
        if self.selectedIndex and self.selectedIndex < #self.items then
            local temp = self.items[self.selectedIndex]
            self.items[self.selectedIndex] = self.items[self.selectedIndex + 1]
            self.items[self.selectedIndex + 1] = temp
            self.selectedIndex = self.selectedIndex + 1
            self:RefreshList()
            self.itemList:SelectItem(self.itemList:GetLine(self.selectedIndex))
        end
    end

    -- Save/Load buttons
    self.saveBtn = vgui.Create("DButton", self)
    self.saveBtn:SetPos(320, 200)
    self.saveBtn:SetSize(90, 30)
    self.saveBtn:SetText("Save / 保存")
    self.saveBtn.DoClick = function()
        self:SaveConfig()
    end

    self.loadBtn = vgui.Create("DButton", self)
    self.loadBtn:SetPos(420, 200)
    self.loadBtn:SetSize(90, 30)
    self.loadBtn:SetText("Reload / 再読込")
    self.loadBtn.DoClick = function()
        self:LoadConfig()
    end

    -- Preview label
    self.previewLabel = vgui.Create("DLabel", self)
    self.previewLabel:SetPos(10, 250)
    self.previewLabel:SetText("Preview (6x10 Grid) / プレビュー:")
    self.previewLabel:SetTextColor(Color(255, 255, 255))
    self.previewLabel:SizeToContents()

    -- Preview panel
    self.previewPanel = vgui.Create("DPanel", self)
    self.previewPanel:SetPos(10, 270)
    self.previewPanel:SetSize(GRID_COLS * (CELL_WIDTH + CELL_PADDING) + CELL_PADDING,
                              GRID_ROWS * (CELL_HEIGHT + CELL_PADDING) + CELL_PADDING)
    self.previewPanel.Paint = function(pnl, w, h)
        self:PaintPreview(pnl, w, h)
    end

    -- Load existing config
    self:LoadConfig()
end

function PANEL:UpdateButtonStates()
    local hasSelection = self.selectedIndex ~= nil and self.items[self.selectedIndex] ~= nil
    self.editBtn:SetEnabled(hasSelection)
    self.deleteBtn:SetEnabled(hasSelection)
    self.moveUpBtn:SetEnabled(hasSelection and self.selectedIndex > 1)
    self.moveDownBtn:SetEnabled(hasSelection and self.selectedIndex < #self.items)
end

function PANEL:RefreshList()
    self.itemList:Clear()

    for i, item in ipairs(self.items) do
        local typeStr = item.actionType == "convar_toggle" and "Toggle" or "Cmd"
        local actionStr = string.sub(item.actionValue, 1, 15)
        if #item.actionValue > 15 then actionStr = actionStr .. "..." end

        self.itemList:AddLine(item.name, item.slot, item.slotPos, typeStr, actionStr)
    end

    self.previewPanel:InvalidateLayout()
end

function PANEL:LoadConfig()
    local config = vrmod.LoadQuickMenuConfig()
    if config and config.items then
        self.items = table.Copy(config.items)
    else
        self.items = {}
    end
    self.selectedIndex = nil
    self:RefreshList()
    self:UpdateButtonStates()
end

function PANEL:SaveConfig()
    local success = vrmod.SaveQuickMenuConfig(self.items)
    if success then
        notification.AddLegacy("Quick Menu config saved!", NOTIFY_GENERIC, 2)
        -- Re-apply if enabled
        if GetConVar("vrmod_quickmenu_use_custom"):GetBool() then
            vrmod.ApplyQuickMenuConfig()
        end
    else
        notification.AddLegacy("Failed to save config!", NOTIFY_ERROR, 3)
    end
end

function PANEL:PaintPreview(pnl, w, h)
    -- Background
    draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 255))

    -- Grid cells
    local grid = {}
    for i = 0, GRID_COLS - 1 do
        grid[i] = {}
    end

    -- Place items in grid
    for _, item in ipairs(self.items) do
        local slot = math.Clamp(item.slot, 0, GRID_COLS - 1)
        local pos = math.Clamp(item.slotPos, 0, GRID_ROWS - 1)
        if not grid[slot][pos] then
            grid[slot][pos] = item.name
        end
    end

    -- Draw grid
    for col = 0, GRID_COLS - 1 do
        for row = 0, GRID_ROWS - 1 do
            local x = CELL_PADDING + col * (CELL_WIDTH + CELL_PADDING)
            local y = CELL_PADDING + row * (CELL_HEIGHT + CELL_PADDING)

            local cellColor = grid[col][row] and Color(60, 100, 60, 255) or Color(50, 50, 50, 255)
            draw.RoundedBox(2, x, y, CELL_WIDTH, CELL_HEIGHT, cellColor)

            if grid[col][row] then
                local name = grid[col][row]
                if #name > 8 then name = string.sub(name, 1, 7) .. ".." end
                draw.SimpleText(name, "DermaDefault", x + CELL_WIDTH / 2, y + CELL_HEIGHT / 2,
                    Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText(col .. "," .. row, "DermaDefault", x + CELL_WIDTH / 2, y + CELL_HEIGHT / 2,
                    Color(80, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end

function PANEL:OpenItemDialog(editIndex)
    local isEdit = editIndex ~= nil
    local item = isEdit and self.items[editIndex] or {
        name = "",
        slot = 0,
        slotPos = 0,
        actionType = "command",
        actionValue = ""
    }

    local dialog = vgui.Create("DFrame")
    dialog:SetSize(350, 250)
    dialog:SetTitle(isEdit and "Edit Item / アイテム編集" or "Add Item / アイテム追加")
    dialog:Center()
    dialog:MakePopup()
    dialog:SetDeleteOnClose(true)

    local y = 30

    -- Name
    local nameLabel = vgui.Create("DLabel", dialog)
    nameLabel:SetPos(10, y)
    nameLabel:SetText("Name / 名前:")
    nameLabel:SetTextColor(Color(255, 255, 255))
    nameLabel:SizeToContents()

    local nameEntry = vgui.Create("DTextEntry", dialog)
    nameEntry:SetPos(120, y)
    nameEntry:SetSize(210, 20)
    nameEntry:SetText(item.name)
    y = y + 30

    -- Slot
    local slotLabel = vgui.Create("DLabel", dialog)
    slotLabel:SetPos(10, y)
    slotLabel:SetText("Slot (0-5):")
    slotLabel:SetTextColor(Color(255, 255, 255))
    slotLabel:SizeToContents()

    local slotSlider = vgui.Create("DNumSlider", dialog)
    slotSlider:SetPos(80, y - 10)
    slotSlider:SetSize(250, 30)
    slotSlider:SetMin(0)
    slotSlider:SetMax(5)
    slotSlider:SetDecimals(0)
    slotSlider:SetValue(item.slot)
    slotSlider:SetText("")
    y = y + 30

    -- SlotPos
    local posLabel = vgui.Create("DLabel", dialog)
    posLabel:SetPos(10, y)
    posLabel:SetText("Position (0-9):")
    posLabel:SetTextColor(Color(255, 255, 255))
    posLabel:SizeToContents()

    local posSlider = vgui.Create("DNumSlider", dialog)
    posSlider:SetPos(80, y - 10)
    posSlider:SetSize(250, 30)
    posSlider:SetMin(0)
    posSlider:SetMax(9)
    posSlider:SetDecimals(0)
    posSlider:SetValue(item.slotPos)
    posSlider:SetText("")
    y = y + 30

    -- Action Type
    local typeLabel = vgui.Create("DLabel", dialog)
    typeLabel:SetPos(10, y)
    typeLabel:SetText("Action Type:")
    typeLabel:SetTextColor(Color(255, 255, 255))
    typeLabel:SizeToContents()

    local typeCombo = vgui.Create("DComboBox", dialog)
    typeCombo:SetPos(120, y)
    typeCombo:SetSize(210, 20)
    typeCombo:AddChoice("Console Command", "command")
    typeCombo:AddChoice("ConVar Toggle", "convar_toggle")
    typeCombo:SetValue(item.actionType == "convar_toggle" and "ConVar Toggle" or "Console Command")
    y = y + 30

    -- Action Value
    local valueLabel = vgui.Create("DLabel", dialog)
    valueLabel:SetPos(10, y)
    valueLabel:SetText("Action Value:")
    valueLabel:SetTextColor(Color(255, 255, 255))
    valueLabel:SizeToContents()

    local valueEntry = vgui.Create("DTextEntry", dialog)
    valueEntry:SetPos(120, y)
    valueEntry:SetSize(210, 20)
    valueEntry:SetText(item.actionValue)
    y = y + 40

    -- OK Button
    local okBtn = vgui.Create("DButton", dialog)
    okBtn:SetPos(170, y)
    okBtn:SetSize(80, 30)
    okBtn:SetText("OK")
    okBtn.DoClick = function()
        local newName = nameEntry:GetValue()
        local newSlot = math.floor(slotSlider:GetValue())
        local newPos = math.floor(posSlider:GetValue())
        local _, newType = typeCombo:GetSelected()
        local newValue = valueEntry:GetValue()

        if newName == "" or newValue == "" then
            notification.AddLegacy("Name and Action Value are required!", NOTIFY_ERROR, 2)
            return
        end

        local newItem = {
            name = newName,
            slot = newSlot,
            slotPos = newPos,
            actionType = newType or "command",
            actionValue = newValue
        }

        if isEdit then
            self.items[editIndex] = newItem
        else
            table.insert(self.items, newItem)
        end

        self:RefreshList()
        dialog:Close()
    end

    -- Cancel Button
    local cancelBtn = vgui.Create("DButton", dialog)
    cancelBtn:SetPos(260, y)
    cancelBtn:SetSize(80, 30)
    cancelBtn:SetText("Cancel")
    cancelBtn.DoClick = function()
        dialog:Close()
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 255))
end

vgui.Register("VRMod_QuickMenuEditor", PANEL, "DPanel")

-----------------------------------------------------------
-- Menu Integration
-----------------------------------------------------------

hook.Add("VRMod_Menu", "addsettings_quickmenu_editor", function(frame)
    if not frame or not frame.quickmenuBtnSheet then return end
    local sheet = frame.quickmenuBtnSheet
    local container = vgui.Create("DPanel", sheet)
    container:Dock(FILL)
    container.Paint = function() end
    local scroll = vgui.Create("DScrollPanel", container)
    scroll:Dock(FILL)
    local editor = vgui.Create("VRMod_QuickMenuEditor", scroll)
    editor:Dock(TOP)
    editor:SetTall(520)
    sheet:AddSheet("Quick Menu Editor", container, "icon16/application_view_tile.png")
end)

print("[VRMod] Quick Menu Editor loaded (tab disabled)")
