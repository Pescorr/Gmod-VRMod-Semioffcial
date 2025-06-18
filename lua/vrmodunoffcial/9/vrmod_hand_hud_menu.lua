AddCSLuaFile()
if SERVER then return end
hook.Add(
    "VRMod_Menu",
    "VRhandhudsettings",
    function(frame)
        -- Add Hand HUD Settings propertysheet
        local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
        frame.DPropertySheet:AddSheet("VRHandHUDs", sheet)
        sheet:Dock(FILL)
        -- VRHandHUDs Settings Tab
        local VRhandHudsScrollPanel = vgui.Create("DScrollPanel", sheet)
        sheet:AddSheet("VRHandHUDs", VRhandHudsScrollPanel, "icon16/monitor_edit.png")
        local handHudsForm = vgui.Create("DForm", VRhandHudsScrollPanel) -- DForm自体はコンテナとして使用
        handHudsForm:Dock(FILL)
        handHudsForm:SetPadding(5)
        local HandHUDsData = {
            Left = {},
            Right = {}
        }

        HandHUDsData.Left.menuLabel = "Left Hand HUD"
        HandHUDsData.Left.id_prefix = "vrmod_left_hud"
        HandHUDsData.Right.menuLabel = "Right Hand HUD"
        HandHUDsData.Right.id_prefix = "vrmod_right_hud"
        for handKey, hudSettingsData in pairs(HandHUDsData) do
            local collapsibleCategory = vgui.Create("DCollapsibleCategory", handHudsForm) -- DCollapsibleCategoryを直接作成
            collapsibleCategory:SetLabel(hudSettingsData.menuLabel)
            collapsibleCategory:SetExpanded(true)
            handHudsForm:AddItem(collapsibleCategory) -- DFormにDCollapsibleCategoryを追加
            local categoryContents = vgui.Create("DForm", collapsibleCategory) -- DCollapsibleCategory内にDFormを作成してコントロールを追加
            categoryContents:Dock(TOP)
            categoryContents:SetPadding(5)
            categoryContents:CheckBox("Enable " .. hudSettingsData.menuLabel, hudSettingsData.id_prefix .. "_enabled")
            categoryContents:NumSlider("Scale", hudSettingsData.id_prefix .. "_scale", 0.001, 0.1, 3)
            categoryContents:NumSlider("Offset Pos X", hudSettingsData.id_prefix .. "_offset_pos_x", -50, 50, 2)
            categoryContents:NumSlider("Offset Pos Y", hudSettingsData.id_prefix .. "_offset_pos_y", -50, 50, 2)
            categoryContents:NumSlider("Offset Pos Z", hudSettingsData.id_prefix .. "_offset_pos_z", -50, 50, 2)
            categoryContents:NumSlider("Offset Ang Pitch", hudSettingsData.id_prefix .. "_offset_ang_p", -360, 360, 1)
            categoryContents:NumSlider("Offset Ang Yaw", hudSettingsData.id_prefix .. "_offset_ang_y", -360, 360, 1)
            categoryContents:NumSlider("Offset Ang Roll", hudSettingsData.id_prefix .. "_offset_ang_r", -360, 360, 1)
            categoryContents:NumSlider("UV Offset X", hudSettingsData.id_prefix .. "_uv_offset_x", 0, 1, 2)
            categoryContents:NumSlider("UV Offset Y", hudSettingsData.id_prefix .. "_uv_offset_y", 0, 1, 2)
            categoryContents:NumSlider("UV Scale X", hudSettingsData.id_prefix .. "_uv_scale_x", 0.01, 1, 2)
            categoryContents:NumSlider("UV Scale Y", hudSettingsData.id_prefix .. "_uv_scale_y", 0.01, 1, 2)
            categoryContents:TextEntry(hudSettingsData.menuLabel .. " Blacklist (comma separated)", hudSettingsData.id_prefix .. "_blacklist")
            categoryContents:NumSlider(hudSettingsData.menuLabel .. " Background Alpha", hudSettingsData.id_prefix .. "_alpha", 0, 255, 0)
            local restoreDefaultsButton = categoryContents:Button("Restore Defaults for " .. hudSettingsData.menuLabel)
            restoreDefaultsButton.DoClick = function()
                RunConsoleCommand(hudSettingsData.id_prefix .. "_enabled", "1")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_scale", "0.009")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_offset_pos_x", handKey == "Right" and "-6.78" or "0.70")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_offset_pos_y", handKey == "Right" and "0.70" or "-2.10")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_offset_pos_z", handKey == "Right" and "-0.70" or "-1.50")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_offset_ang_p", handKey == "Right" and "165" or "185")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_offset_ang_y", handKey == "Right" and "-180" or "0")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_offset_ang_r", "-90")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_uv_offset_x", handKey == "Right" and "0.73" or "0.5")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_uv_offset_y", "0.73")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_uv_scale_x", "0.63")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_uv_scale_y", "0.47")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_blacklist", "")
                RunConsoleCommand(hudSettingsData.id_prefix .. "_alpha", "0")
            end
        end
    end
)