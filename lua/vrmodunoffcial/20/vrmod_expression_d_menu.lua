--[[
    Module 20: Expression System — Menu Integration (CL)
    Adds settings panel to VRMod menu (Settings02 DTree).
]]

AddCSLuaFile()
if SERVER then return end

vrmod.Expression = vrmod.Expression or {}

---------------------------------------------------------------------------
-- Settings panel in VRMod Menu (Settings02 DTree)
---------------------------------------------------------------------------
hook.Add("VRMod_Menu", "addsettings_expression", function(frame)
    if not frame or not frame.DPropertySheet then return end

    local ok, err = pcall(function()

        local mainPanel = vgui.Create("DPanel")
        mainPanel.Paint = function(self, w, h) end

        local scroll = vgui.Create("DScrollPanel", mainPanel)
        scroll:Dock(FILL)

        local form = vgui.Create("DForm", scroll)
        form:SetName("Expression Settings")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function(self, w, h) end

        -- Enable/Disable
        form:CheckBox("Enable Expression System", "vrmod_unoff_expression_enable")
        form:Help(
            "Enables VRChat-style facial expressions driven by VR controller gestures.\n"
            .. "Your character's face will change based on hand poses (peace sign, fist, thumbs up, etc.)."
        )

        -- Gesture auto-detection
        form:CheckBox("Auto-detect gestures (finger tracking)", "vrmod_unoff_expression_gesture")
        form:Help(
            "ON: Automatically detect hand gestures from finger tracking data (best with Index controllers).\n"
            .. "OFF: Use only manual expression selection."
        )

        -- Sensitivity
        local sensCombo = form:ComboBox("Detection Sensitivity", "vrmod_unoff_expression_sensitivity")
        sensCombo:AddChoice("Low (wide dead zone)", "0")
        sensCombo:AddChoice("Medium (default)", "1")
        sensCombo:AddChoice("High (narrow dead zone)", "2")
        form:Help(
            "Adjusts how easily gestures are triggered.\n"
            .. "Low = harder to trigger (fewer false positives).\n"
            .. "High = easier to trigger (more responsive)."
        )

        -- Intensity slider (10-500%)
        form:NumSlider("Expression Intensity (%)", "vrmod_unoff_expression_intensity", 10, 500, 0)
        form:Help(
            "Maximum expression intensity when gesture is fully matched.\n"
            .. "100% = normal, 200%+ = exaggerated (GMod broken face style).\n"
            .. "Works as analog blend with Index controllers."
        )

        -- Manual Expression Select
        form:Help("\n--- Manual Expression Select ---")

        local selectLabel = vgui.Create("DLabel")
        selectLabel:SetText("Expression Override")
        selectLabel:SetDark(true)
        local selectCombo = vgui.Create("DComboBox")
        form:AddItem(selectLabel, selectCombo)
        selectCombo:SetSortItems(false)
        selectCombo:AddChoice("Auto (Gesture Detection)", "-1")
        for i = 0, vrmod.Expression.GESTURE_COUNT - 1 do
            local preset = vrmod.Expression.PRESETS[i]
            local exprName = preset and preset.name or "?"
            local gestName = vrmod.Expression.GESTURE_NAMES[i] or "?"
            if i == 0 then
                selectCombo:AddChoice("Neutral (Default)", "0")
            else
                selectCombo:AddChoice(exprName .. " (" .. gestName .. ")", tostring(i))
            end
        end
        selectCombo:ChooseOptionID(1) -- Default: Auto

        selectCombo.OnSelect = function(self, index, value, data)
            local num = tonumber(data)
            if not num then return end
            if num == -1 then
                vrmod.Expression.SetAutoMode()
            else
                vrmod.Expression.SetManualExpression(num)
            end
        end

        -- Sync combo display with current state
        selectCombo.Think = function(self)
            if not self._nextSync or RealTime() > self._nextSync then
                self._nextSync = RealTime() + 0.5
                local state = vrmod.Expression.GetState and vrmod.Expression.GetState() or {}
                if not state.manualOverride then
                    if self._lastShown ~= -1 then
                        self:SetValue("Auto (Gesture Detection)")
                        self._lastShown = -1
                    end
                elseif self._lastShown ~= state.gestureID then
                    local preset = vrmod.Expression.PRESETS[state.gestureID]
                    local gestName = vrmod.Expression.GESTURE_NAMES[state.gestureID] or "?"
                    if state.gestureID == 0 then
                        self:SetValue("Neutral (Default)")
                    else
                        self:SetValue((preset and preset.name or "?") .. " (" .. gestName .. ")")
                    end
                    self._lastShown = state.gestureID
                end
            end
        end

        form:Help(
            "Select an expression manually, or choose Auto to use gesture detection.\n"
            .. "Manual selection overrides gesture detection until Auto is selected again."
        )

        -----------------------------------------------------------------
        -- Per-gesture flex weight editor (collapsible sections)
        -----------------------------------------------------------------
        form:Help("\n--- Flex Editor (per gesture) ---")
        form:Help("Expand a gesture to edit its flex weights. Changes are saved automatically.")

        -- Gather available flex names from the current player model
        local availableFlexes = vrmod.Expression.GetModelFlexNames()

        for gestID = 1, vrmod.Expression.GESTURE_COUNT - 1 do
            local preset = vrmod.Expression.PRESETS[gestID]
            if not preset then continue end

            local gestName = vrmod.Expression.GESTURE_NAMES[gestID] or "?"

            local editorForm = vgui.Create("DForm", scroll)
            editorForm:SetName(gestName .. " -> " .. preset.name)
            editorForm:Dock(TOP)
            editorForm:DockMargin(0, 2, 0, 0)
            editorForm:SetExpanded(false)

            -- Build / rebuild the editor contents
            local function RebuildEditor()
                editorForm:Clear()

                -- Sliders for each assigned flex
                local sortedFlexes = {}
                for flexName in pairs(preset.flexes) do
                    table.insert(sortedFlexes, flexName)
                end
                table.sort(sortedFlexes)

                for _, flexName in ipairs(sortedFlexes) do
                    local weight = preset.flexes[flexName]
                    if not weight then continue end

                    local slider = vgui.Create("DNumSlider")
                    slider:SetText(flexName)
                    slider:SetMin(0)
                    slider:SetMax(1)
                    slider:SetDecimals(2)
                    editorForm:AddItem(slider)
                    slider:SetValue(weight)
                    slider.OnValueChanged = function(self, val)
                        vrmod.Expression.SetPresetFlex(gestID, flexName, val)
                    end

                    -- Remove button (tiny "X" next to each slider)
                    local removeBtn = vgui.Create("DButton", slider)
                    removeBtn:SetText("X")
                    removeBtn:SetSize(20, 20)
                    removeBtn:SetPos(0, 0)
                    removeBtn.DoClick = function()
                        vrmod.Expression.SetPresetFlex(gestID, flexName, 0)
                        RebuildEditor()
                    end
                end

                -- "Add Flex" combo + button
                if #availableFlexes > 0 then
                    local addRow = vgui.Create("DPanel", editorForm)
                    addRow:SetTall(28)
                    addRow.Paint = function() end

                    local addCombo = vgui.Create("DComboBox", addRow)
                    addCombo:Dock(FILL)
                    addCombo:DockMargin(0, 2, 4, 2)
                    addCombo:SetSortItems(false)
                    addCombo:SetValue("(select flex to add)")
                    for _, name in ipairs(availableFlexes) do
                        if not preset.flexes[name] then
                            addCombo:AddChoice(name, name)
                        end
                    end

                    local addBtn = vgui.Create("DButton", addRow)
                    addBtn:Dock(RIGHT)
                    addBtn:SetWide(60)
                    addBtn:SetText("Add")
                    addBtn.DoClick = function()
                        local _, data = addCombo:GetSelected()
                        if data and data ~= "" then
                            vrmod.Expression.SetPresetFlex(gestID, data, 0.5)
                            RebuildEditor()
                        end
                    end

                    editorForm:AddItem(addRow)
                end

                -- Reset button
                local resetBtn = editorForm:Button("Reset to Default")
                resetBtn.DoClick = function()
                    vrmod.Expression.ResetPreset(gestID)
                    RebuildEditor()
                end
            end

            RebuildEditor()
        end

        -- Reset ALL button
        local resetAllBtn = form:Button("Reset All Expressions to Default")
        resetAllBtn.DoClick = function()
            vrmod.Expression.ResetAllPresets()
            -- Re-open menu to refresh all editors
            Derma_Message("All expressions reset to default.\nReopen the menu to see changes.", "Expression Reset", "OK")
        end

        -- Status display
        local statusLabel = vgui.Create("DLabel", scroll)
        statusLabel:Dock(TOP)
        statusLabel:DockMargin(8, 12, 8, 0)
        statusLabel:SetFont("DermaDefaultBold")
        statusLabel:SetTextColor(Color(200, 200, 200))
        statusLabel:SetText("Status: Checking...")
        statusLabel:SetAutoStretchVertical(true)

        -- Update status periodically
        statusLabel.Think = function(self)
            if not self._nextUpdate or RealTime() > self._nextUpdate then
                self._nextUpdate = RealTime() + 0.5

                local state = vrmod.Expression.GetState and vrmod.Expression.GetState() or {}
                local parts = {}

                if state.active then
                    table.insert(parts, "Active")
                else
                    table.insert(parts, "Inactive (enter VR to activate)")
                end

                if state.hasFlexes == false and state.hasBodygroups == false then
                    table.insert(parts, "Model has no compatible flexes or bodygroups")
                elseif state.hasFlexes then
                    table.insert(parts, "Flex: OK")
                end

                if state.hasBodygroups then
                    table.insert(parts, "Bodygroup: " .. (state.bodygroupName or "?"))
                end

                if state.hasFingerTracking then
                    table.insert(parts, "Finger tracking: Available")
                else
                    table.insert(parts, "Finger tracking: Not detected")
                end

                if state.manualOverride then
                    local name = vrmod.Expression.GESTURE_NAMES[state.gestureID] or "?"
                    local preset = vrmod.Expression.PRESETS[state.gestureID]
                    table.insert(parts, "Manual: " .. (preset and preset.name or name))
                elseif state.gestureID and state.gestureID > 0 then
                    local name = vrmod.Expression.GESTURE_NAMES[state.gestureID] or "?"
                    local preset = vrmod.Expression.PRESETS[state.gestureID]
                    table.insert(parts, "Gesture: " .. name .. " -> " .. (preset and preset.name or "?"))
                end

                if state.blendFactor and state.blendFactor < 0.99 then
                    table.insert(parts, "Blend: " .. math.floor(state.blendFactor * 100) .. "%")
                end

                self:SetText("Status: " .. table.concat(parts, " | "))
            end
        end

        -- Dual-mode registration (Settings02 DTree preferred, tab fallback)
        if frame.Settings02Register then
            local success = frame.Settings02Register("expression", "Expression", "icon16/emoticon_smile.png", mainPanel)
            if not success then
                frame.DPropertySheet:AddSheet("Expression", mainPanel, "icon16/emoticon_smile.png")
            end
        else
            frame.DPropertySheet:AddSheet("Expression", mainPanel, "icon16/emoticon_smile.png")
        end

    end) -- pcall end

    if not ok then
        print("[VRMod Expression] Menu hook error: " .. tostring(err))
    end
end)
