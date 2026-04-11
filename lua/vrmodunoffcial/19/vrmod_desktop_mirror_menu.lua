--------[vrmod_desktop_mirror_menu.lua]Start--------
-- VRMod Menu tab for Desktop Mirror settings
-- Dual-mode: Settings02 DTree (semiofficial) + DPropertySheet fallback (original)
AddCSLuaFile()
if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

hook.Add("VRMod_Menu", "addsettings_desktop_mirror", function(frame)
    if not frame or not frame.DPropertySheet then return end

    local ok, err = pcall(function()

    local panel = vgui.Create("DPanel", frame.DPropertySheet)
    panel:Dock(FILL)
    panel.Paint = function() end

    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)

    -- ========================================
    -- Core Settings
    -- ========================================
    local coreForm = vgui.Create("DForm", scroll)
    coreForm:SetName("Desktop Mirror")
    coreForm:Dock(TOP)
    coreForm:DockMargin(5, 5, 5, 0)

    coreForm:CheckBox(L("Enable Desktop Mirror", "Enable Desktop Mirror"), "vrmod_desktop_mirror")
    coreForm:CheckBox("Realtime Capture", "vrmod_desktop_mirror_realtime")
    -- V2 features: only show when semiofficial is detected
    -- (g_VR.moduleSemiVersion >= 100 on semiofficial, 0 or nil on original)
    local isSemi = g_VR and g_VR.moduleSemiVersion and g_VR.moduleSemiVersion >= 100
    if isSemi then
        coreForm:CheckBox("Mirror Mode (replace VR UI interaction)", "vrmod_desktop_mirror_mode")
        coreForm:CheckBox("Transparent Input (allow shooting while menu open)", "vrmod_desktop_mirror_transparent_input")
        coreForm:CheckBox("Selective Desktop Mirror (VR menus stay in VR)", "vrmod_ui_desktop_mirror")
    end
    coreForm:NumSlider("Capture Interval (sec)", "vrmod_desktop_mirror_interval", 0.01, 5.0, 2)

    -- ========================================
    -- Display Settings
    -- ========================================
    local dispForm = vgui.Create("DForm", scroll)
    dispForm:SetName("Display")
    dispForm:Dock(TOP)
    dispForm:DockMargin(5, 5, 5, 0)

    dispForm:NumSlider("Panel Scale", "vrmod_desktop_mirror_scale", 0.005, 0.1, 3)
    dispForm:NumSlider("Distance (units)", "vrmod_desktop_mirror_distance", 20, 200, 0)

    -- Attachment Mode (DComboBox via DForm:AddItem)
    local attachLabel = vgui.Create("DLabel")
    attachLabel:SetText(L("Attachment Mode", "Attachment Mode"))
    attachLabel:SetDark(true)

    local attachCombo = vgui.Create("DComboBox")
    attachCombo:SetSortItems(false)
    attachCombo:AddChoice("Left Hand", 1)
    attachCombo:AddChoice("Right Hand", 2)
    attachCombo:AddChoice("HMD Follow", 3)
    attachCombo:AddChoice("World Fixed", 4)

    local currentAttach = GetConVar("vrmod_desktop_mirror_attach")
    if currentAttach then
        local val = currentAttach:GetInt()
        if val >= 1 and val <= 4 then
            attachCombo:ChooseOptionID(val)
        end
    end

    attachCombo.OnSelect = function(_, _, _, data)
        RunConsoleCommand("vrmod_desktop_mirror_attach", tostring(data))
    end

    dispForm:AddItem(attachLabel, attachCombo)

    -- ========================================
    -- Position/Angle Offset (Hand & HMD modes)
    -- ========================================
    local offsetForm = vgui.Create("DForm", scroll)
    offsetForm:SetName("Position/Angle Offset (Hand & HMD modes)")
    offsetForm:Dock(TOP)
    offsetForm:DockMargin(5, 5, 5, 5)

    offsetForm:NumSlider("Position X (forward)", "vrmod_desktop_mirror_pos_x", -50, 50, 1)
    offsetForm:NumSlider("Position Y (right)", "vrmod_desktop_mirror_pos_y", -50, 50, 1)
    offsetForm:NumSlider("Position Z (up)", "vrmod_desktop_mirror_pos_z", -50, 50, 1)
    offsetForm:NumSlider("Angle Pitch", "vrmod_desktop_mirror_ang_p", -180, 180, 1)
    offsetForm:NumSlider("Angle Yaw", "vrmod_desktop_mirror_ang_y", -180, 180, 1)
    offsetForm:NumSlider("Angle Roll", "vrmod_desktop_mirror_ang_r", -180, 180, 1)

    -- ========================================
    -- Dual-mode registration (vrmod_debug_menutab.lua pattern)
    -- ========================================
    if frame.Settings02Register then
        local success = frame.Settings02Register(
            "desktop_mirror", "Desktop Mirror", "icon16/monitor.png", panel)
        if not success then
            frame.DPropertySheet:AddSheet("Desktop Mirror", panel, "icon16/monitor.png")
        end
    else
        frame.DPropertySheet:AddSheet("Desktop Mirror", panel, "icon16/monitor.png")
    end

    end) -- pcall end
    if not ok then
        print("[VRMod Desktop Mirror] Menu hook error: " .. tostring(err))
    end
end)
--------[vrmod_desktop_mirror_menu.lua]End--------
