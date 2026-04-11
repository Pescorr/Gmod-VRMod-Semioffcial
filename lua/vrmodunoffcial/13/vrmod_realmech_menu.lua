--[[
    Module 13: RealMech - Automatic Realistic Gun Mechanics
    Menu: Settings UI integration (VRMod_Menu hook)

    Adds "RealMech" tab to Settings02 DTree (or standalone tab).
]]

AddCSLuaFile()
if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

-- ============================================================================
-- Menu Integration
-- ============================================================================

hook.Add("VRMod_Menu", "addsettings_realmech", function(frame)
    if not frame or not frame.DPropertySheet then return end

    local ok, err = pcall(function()
    -- Create scrollable panel
    local scroll = vgui.Create("DScrollPanel")

    local panel = vgui.Create("DPanel", scroll)
    panel:Dock(TOP)
    panel:SetHeight(950)
    panel.Paint = function() end

    -- Helper: dock a control with consistent margins
    local function AddControl(control, height)
        control:Dock(TOP)
        control:DockMargin(20, 5, 20, 0)
        control:SetHeight(height or 20)
    end

    -- Helper: create section label
    local function AddSection(text)
        local label = vgui.Create("DLabel", panel)
        AddControl(label, 22)
        label:SetText(text)
        label:SetFont("DermaDefaultBold")
        label:SetTextColor(Color(220, 220, 220))

        -- Thin separator line
        local sep = vgui.Create("DPanel", panel)
        AddControl(sep, 2)
        sep.Paint = function(self, w, h)
            surface.SetDrawColor(100, 100, 100, 80)
            surface.DrawRect(0, 0, w, h)
        end
    end

    -- Helper: create checkbox
    local function AddCheckbox(text, convar)
        local cb = panel:Add("DCheckBoxLabel")
        AddControl(cb, 20)
        cb:SetText(text)
        cb:SetConVar(convar)
        return cb
    end

    -- Helper: create slider
    local function AddSlider(text, convar, min, max, decimals)
        local slider = vgui.Create("DNumSlider", panel)
        AddControl(slider, 28)
        slider:SetText(text)
        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetDecimals(decimals or 0)
        slider:SetConVar(convar)
        return slider
    end

    -- ===================== TITLE =====================

    local titleLabel = vgui.Create("DLabel", panel)
    AddControl(titleLabel, 28)
    titleLabel:SetText(L("RealMech - Realistic Gun Mechanics", "RealMech - Realistic Gun Mechanics"))
    titleLabel:SetFont("DermaLarge")
    titleLabel:SetTextColor(Color(255, 200, 80))

    local descLabel = vgui.Create("DLabel", panel)
    AddControl(descLabel, 18)
    descLabel:SetText(L("Automatically detects weapon bones and adds realistic animations.", "Automatically detects weapon bones and adds realistic animations."))
    descLabel:SetTextColor(Color(180, 180, 180))

    -- ===================== MASTER =====================

    AddSection(L("Master Control", "Master Control"))

    AddCheckbox(L("Enable RealMech", "Enable RealMech"), "vrmod_unoff_realmech_enable")

    -- ===================== SLIDE =====================

    AddSection(L("Slide / Bolt", "Slide / Bolt"))

    AddCheckbox(L("Slide Blowback Animation", "Slide Blowback Animation"), "vrmod_unoff_realmech_slide_enable")
    AddSlider(L("Slide Return Speed", "Slide Return Speed"), "vrmod_unoff_realmech_slide_speed", 1, 50, 0)
    AddSlider(L("Default Blowback Distance", "Default Blowback Distance"), "vrmod_unoff_realmech_blowback", 0.5, 10, 1)
    AddCheckbox(L("VR Slide Grab", "VR Slide Grab"), "vrmod_unoff_realmech_slide_grab_enable")
    AddSlider(L("Slide Grab Range", "Slide Grab Range"), "vrmod_unoff_realmech_slide_grab_range", 3, 25, 0)

    -- ===================== TRIGGER =====================

    AddSection(L("Trigger", "Trigger"))

    AddCheckbox(L("Trigger Pull Animation", "Trigger Pull Animation"), "vrmod_unoff_realmech_trigger_enable")
    AddSlider(L("Trigger Pull Angle", "Trigger Pull Angle"), "vrmod_unoff_realmech_trigger_angle", 5, 45, 0)

    -- ===================== ANIMATION INTERACT RELOAD =====================

    AddSection(L("Animation Interact Reload", "Animation Interact Reload"))

    AddCheckbox(L("Enable Reload Animation Interact", "Enable Reload Animation Interact"), "vrmod_unoff_realmech_reload_enable")
    if vrmod.RealMech and vrmod.RealMech._magboneMissing then
        local warnLabel = vgui.Create("DLabel", panel)
        AddControl(warnLabel, 20)
        warnLabel:SetText(L("vrmod_magbone not found - Reload system disabled", "vrmod_magbone not found - Reload system disabled"))
        warnLabel:SetTextColor(Color(255, 80, 80))
    end
    AddSlider(L("Freeze Delay (seconds)", "Freeze Delay (seconds)"), "vrmod_unoff_realmech_reload_freeze_delay", 0.1, 1.0, 1)
    AddSlider(L("Freeze Playback Rate", "Freeze Playback Rate"), "vrmod_unoff_realmech_reload_freeze_rate", 0.001, 0.1, 3)
    AddCheckbox(L("Return to Idle on VRMag Pickup (ON=pistol, OFF=revolver/break-action)", "Return to Idle on VRMag Pickup (ON=pistol, OFF=revolver/break-action)"), "vrmod_unoff_realmech_reload_idle_return")

    local reloadInfoLabel = vgui.Create("DLabel", panel)
    AddControl(reloadInfoLabel, 55)
    reloadInfoLabel:SetText(L("Reload animation plays, then freezes.\nPick up VRMag to insert. Press Reload again to cancel.\nOFF: keeps frozen pose during insert (revolver/break-action).", "Reload animation plays, then freezes.\nPick up VRMag to insert. Press Reload again to cancel.\nOFF: keeps frozen pose during insert (revolver/break-action)."))
    reloadInfoLabel:SetTextColor(Color(180, 180, 180))
    reloadInfoLabel:SetWrap(true)

    -- ===================== OTHER MECHANICS =====================

    AddSection(L("Other Mechanics", "Other Mechanics"))

    AddCheckbox(L("Bullet Bone Visibility", "Bullet Bone Visibility"), "vrmod_unoff_realmech_bullet_enable")
    AddCheckbox(L("Hammer Animation", "Hammer Animation"), "vrmod_unoff_realmech_hammer_enable")
    AddCheckbox(L("Fire Selector Animation", "Fire Selector Animation"), "vrmod_unoff_realmech_selector_enable")

    -- ===================== SLIDE DIRECTION =====================

    AddSection(L("Advanced", "Advanced"))

    local slideDirLabel = vgui.Create("DLabel", panel)
    AddControl(slideDirLabel, 18)
    slideDirLabel:SetText(L("Slide Direction Override (auto, -x, +x, -y, +y, -z, +z)", "Slide Direction Override (auto, -x, +x, -y, +y, -z, +z)"))
    slideDirLabel:SetTextColor(Color(180, 180, 180))

    local slideDirEntry = vgui.Create("DTextEntry", panel)
    AddControl(slideDirEntry, 22)
    slideDirEntry:SetConVar("vrmod_unoff_realmech_slide_dir")
    slideDirEntry:SetPlaceholderText("auto")

    -- ===================== DEBUG =====================

    AddSection(L("Debug Tools", "Debug Tools"))

    AddCheckbox(L("Debug: Log Detected Bones", "Debug: Log Detected Bones"), "vrmod_unoff_realmech_debug")

    local boneBtn = vgui.Create("DButton", panel)
    AddControl(boneBtn, 28)
    boneBtn:SetText(L("Print Detected Bones to Console", "Print Detected Bones to Console"))
    boneBtn.DoClick = function()
        RunConsoleCommand("vrmod_realmech_bones")
    end

    local refreshBtn = vgui.Create("DButton", panel)
    AddControl(refreshBtn, 28)
    refreshBtn:SetText(L("Refresh Bone Cache", "Refresh Bone Cache"))
    refreshBtn.DoClick = function()
        RunConsoleCommand("vrmod_realmech_refresh")
    end

    -- ===================== RESET =====================

    local spacer = vgui.Create("DPanel", panel)
    AddControl(spacer, 10)
    spacer.Paint = function() end

    local resetBtn = vgui.Create("DButton", panel)
    AddControl(resetBtn, 30)
    resetBtn:SetText(L("Restore Default Settings", "Restore Default Settings"))
    resetBtn.DoClick = function()
        RunConsoleCommand("vrmod_unoff_realmech_enable", "1")
        RunConsoleCommand("vrmod_unoff_realmech_slide_enable", "0")
        RunConsoleCommand("vrmod_unoff_realmech_trigger_enable", "0")
        RunConsoleCommand("vrmod_unoff_realmech_bullet_enable", "0")
        RunConsoleCommand("vrmod_unoff_realmech_hammer_enable", "0")
        RunConsoleCommand("vrmod_unoff_realmech_selector_enable", "0")
        RunConsoleCommand("vrmod_unoff_realmech_slide_speed", "15")
        RunConsoleCommand("vrmod_unoff_realmech_blowback", "2.5")
        RunConsoleCommand("vrmod_unoff_realmech_trigger_angle", "15")
        RunConsoleCommand("vrmod_unoff_realmech_slide_grab_enable", "0")
        RunConsoleCommand("vrmod_unoff_realmech_slide_grab_range", "10")
        RunConsoleCommand("vrmod_unoff_realmech_slide_dir", "auto")
        RunConsoleCommand("vrmod_unoff_realmech_reload_enable", "1")
        RunConsoleCommand("vrmod_unoff_realmech_reload_freeze_delay", "0.3")
        RunConsoleCommand("vrmod_unoff_realmech_reload_freeze_rate", "0.01")
        RunConsoleCommand("vrmod_unoff_realmech_reload_idle_return", "0")
        RunConsoleCommand("vrmod_unoff_realmech_debug", "0")
        chat.AddText(Color(0, 255, 0), L("RealMech settings reset to defaults.", "RealMech settings reset to defaults."))
    end

    -- ===================== INFO =====================

    local infoLabel = vgui.Create("DLabel", panel)
    AddControl(infoLabel, 36)
    infoLabel:SetText(L("Note: RealMech auto-detects bones from weapon viewmodels.\nArcVR weapons and VR-class weapons are automatically excluded.", "Note: RealMech auto-detects bones from weapon viewmodels.\nArcVR weapons and VR-class weapons are automatically excluded."))
    infoLabel:SetTextColor(Color(150, 150, 150))
    infoLabel:SetWrap(true)
    infoLabel:SetAutoStretchVertical(true)

    -- Dual-mode registration
    if frame.Settings02Register then
        local success = frame.Settings02Register("realmech", "RealMech", "icon16/wrench.png", scroll)
        if not success then
            frame.DPropertySheet:AddSheet("RealMech", scroll, "icon16/wrench.png")
        end
    else
        frame.DPropertySheet:AddSheet("RealMech", scroll, "icon16/wrench.png")
    end

    end) -- pcall end
    if not ok then
        print("[VRMod] Menu hook error (addsettings_realmech): " .. tostring(err))
    end
end)

print("[RealMech] Menu loaded - settings UI")
