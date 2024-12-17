-- プリセット機能のUIを追加
local function AddPresetUI(grid)
    local presetPanel = vgui.Create("DPanel")
    presetPanel:SetSize(300, 200)

    local presetList = vgui.Create("DListView", presetPanel)
    presetList:Dock(FILL)
    presetList:AddColumn("Presets")

    local function RefreshPresetList()
        presetList:Clear()
        for _, preset in ipairs(GetPresetList())  do
            presetList:AddLine(preset)
        end
    end

    RefreshPresetList()

    local saveButton = vgui.Create("DButton", presetPanel)
    saveButton:SetText("Save Preset")
    saveButton:Dock(BOTTOM)
    saveButton.DoClick = function()
        Derma_StringRequest(
            "Save Preset",
            "Enter a name for the preset:",
            "",
            function(text)
                SavePreset(text)
                RefreshPresetList()
            end
        )
    end

    local loadButton = vgui.Create("DButton", presetPanel)
    loadButton:SetText("Load Preset")
    loadButton:Dock(BOTTOM)
    loadButton.DoClick = function()
        local selected = presetList:GetSelectedLine()
        if selected then
            local preset = presetList:GetLine(selected):GetColumnText(1)
            LoadPreset(preset)
        end
    end

    local deleteButton = vgui.Create("DButton", presetPanel)
    deleteButton:SetText("Delete Preset")
    deleteButton:Dock(BOTTOM)
    deleteButton.DoClick = function()
        local selected = presetList:GetSelectedLine()
        if selected then
            local preset = presetList:GetLine(selected):GetColumnText(1)
            file.Delete(PRESET_FOLDER .. "/" .. preset .. PRESET_EXTENSION)
            RefreshPresetList()
        end
    end

    grid:AddItem(presetPanel)
end
