--[[
    Module 17: VR Ragdoll Puppeteer — Menu Integration (v3)
    Adds Puppeteer tab to VRMod Settings02 menu (DTree).
    Rigging checkboxes are backed by JSON persistence (data/vrmod/puppeteer_rig.json).
    Changes are auto-saved and sent to server in real-time.
]]

AddCSLuaFile()
if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

g_VR = g_VR or {}
vrmod = vrmod or {}

-- Bone display names for rigging UI (matches BONE_TABLE order 1-15)
local BONE_LABELS = {
    { section = "Core",      bones = { { 1, "Pelvis" }, { 2, "Chest (Spine2)" }, { 3, "Head" } } },
    { section = "Left Arm",  bones = { { 6, "L UpperArm" }, { 5, "L Forearm" }, { 4, "L Hand" } } },
    { section = "Right Arm", bones = { { 12, "R UpperArm" }, { 11, "R Forearm" }, { 10, "R Hand" } } },
    { section = "Left Leg",  bones = { { 9, "L Thigh" }, { 8, "L Calf" }, { 7, "L Foot" } } },
    { section = "Right Leg", bones = { { 15, "R Thigh" }, { 14, "R Calf" }, { 13, "R Foot" } } },
}

hook.Add("VRMod_Menu", "addsettingsPuppeteer", function(frame)
    if not frame or not frame.DPropertySheet then return end

    local ok, err = pcall(function()
    -- Load saved rigging on menu open
    if vrmod.Puppeteer and vrmod.Puppeteer.ReloadFromJSON then
        vrmod.Puppeteer.ReloadFromJSON()
    end

    local sheet = vgui.Create("DPropertySheet")
    sheet:Dock(FILL)

    -- ========================================
    -- Tab 1: Controls & Settings
    -- ========================================
    local mainTab = vgui.Create("DPanel", sheet)
    sheet:AddSheet("Controls", mainTab, "icon16/cog.png")
    mainTab.Paint = function() end

    local scroll = vgui.Create("DScrollPanel", mainTab)
    scroll:Dock(FILL)

    -- Header
    local header = vgui.Create("DLabel", scroll)
    header:SetText(L("VR Ragdoll Puppeteer (Experimental)", "VR Ragdoll Puppeteer (Experimental)"))
    header:SetFont("DermaDefaultBold")
    header:SetTextColor(Color(255, 200, 80))
    header:Dock(TOP)
    header:DockMargin(8, 8, 8, 4)
    header:SizeToContents()

    local desc = vgui.Create("DLabel", scroll)
    desc:SetText(
        L("Control a ragdoll puppet with VR tracking.\nDriven bones follow VR (kinematic). Free bones use physics (ragdoll).\nRigging settings are saved to data/vrmod/puppeteer_rig.json.",
          "Control a ragdoll puppet with VR tracking.\nDriven bones follow VR (kinematic). Free bones use physics (ragdoll).\nRigging settings are saved to data/vrmod/puppeteer_rig.json.")
    )
    desc:SetWrap(true)
    desc:SetAutoStretchVertical(true)
    desc:Dock(TOP)
    desc:DockMargin(8, 0, 8, 12)

    -- Toggle buttons
    local ctrlForm = vgui.Create("DForm", scroll)
    ctrlForm:SetName(L("Puppet Control", "Puppet Control"))
    ctrlForm:Dock(TOP)
    ctrlForm:DockMargin(4, 0, 4, 8)

    ctrlForm:Button(L("Toggle Puppet ON/OFF", "Toggle Puppet ON/OFF"), "vrmod_puppeteer_toggle")
    ctrlForm:Button(L("Force ON", "Force ON"), "vrmod_puppeteer_on")
    ctrlForm:Button(L("Force OFF", "Force OFF"), "vrmod_puppeteer_off")
    ctrlForm:Button(L("Freeze All Bones (Pose Mode)", "Freeze All Bones (Pose Mode)"), "vrmod_puppeteer_freeze")
    ctrlForm:Button(L("Unfreeze (Resume Rigging)", "Unfreeze (Resume Rigging)"), "vrmod_puppeteer_unfreeze")

    -- Settings
    local setForm = vgui.Create("DForm", scroll)
    setForm:SetName("Settings")
    setForm:Dock(TOP)
    setForm:DockMargin(4, 0, 4, 8)

    setForm:CheckBox(L("Enable Module", "Enable Module"), "vrmod_unoff_puppeteer_enable")
    setForm:CheckBox(L("Show in Quick Menu", "Show in Quick Menu"), "vrmod_unoff_puppeteer_quickmenu")
    setForm:CheckBox(L("Hide Player Model", "Hide Player Model"), "vrmod_unoff_puppeteer_hide_player")
    setForm:CheckBox(L("Leg Animation (auto: procedural walk / FBT IK)", "Leg Animation (auto: procedural walk / FBT IK)"), "vrmod_unoff_puppeteer_leg_mode")
    setForm:CheckBox(L("Physics Affects Player (momentum)", "Physics Affects Player (momentum)"), "vrmod_unoff_puppeteer_phys_effects_ply")

    -- Tuning
    local tuneForm = vgui.Create("DForm", scroll)
    tuneForm:SetName(L("Body Tuning", "Body Tuning"))
    tuneForm:Dock(TOP)
    tuneForm:DockMargin(4, 0, 4, 8)

    tuneForm:NumSlider(L("Pelvis Offset (from HMD)", "Pelvis Offset (from HMD)"), "vrmod_unoff_puppeteer_pelvis_offset", 10, 60, 0)
    tuneForm:NumSlider(L("Shoulder Half-Width", "Shoulder Half-Width"), "vrmod_unoff_puppeteer_shoulder_width", 4, 16, 1)
    tuneForm:NumSlider(L("Momentum Scale", "Momentum Scale"), "vrmod_unoff_puppeteer_momentum_scale", 0, 0.5, 2)

    -- VR Input Binding
    local inputForm = vgui.Create("DForm", scroll)
    inputForm:SetName(L("VR Input Binding", "VR Input Binding"))
    inputForm:Dock(TOP)
    inputForm:DockMargin(4, 0, 4, 8)

    inputForm:TextEntry(L("Toggle Action", "Toggle Action"), "vrmod_unoff_puppeteer_toggle_action")

    local actionHelp = vgui.Create("DLabel", scroll)
    actionHelp:SetText(
        "VR action name to toggle puppet with controller.\n" ..
        "Examples: boolean_left_menu, boolean_right_menu\n" ..
        "Leave empty = use menu buttons only."
    )
    actionHelp:SetWrap(true)
    actionHelp:SetAutoStretchVertical(true)
    actionHelp:Dock(TOP)
    actionHelp:DockMargin(8, 0, 8, 8)

    -- Head Hiding
    local headForm = vgui.Create("DForm", scroll)
    headForm:SetName(L("Head Hiding (VR First Person)", "Head Hiding (VR First Person)"))
    headForm:Dock(TOP)
    headForm:DockMargin(4, 0, 4, 8)

    local headDesc = vgui.Create("DLabel", headForm)
    headDesc:SetText(L("Hide the puppet's head from your VR view to prevent it blocking your vision.\nOther players and desktop view will still see the head normally.", "Hide the puppet's head from your VR view to prevent it blocking your vision.\nOther players and desktop view will still see the head normally."))
    headDesc:SetWrap(true)
    headDesc:SetAutoStretchVertical(true)
    headDesc:Dock(TOP)
    headDesc:DockMargin(4, 0, 4, 4)

    local headCombo = headForm:ComboBox(L("Hide Head Mode", "Hide Head Mode"), "vrmod_unoff_puppeteer_hide_head")
    headCombo:AddChoice(L("Scale (hide completely)", "Scale (hide completely)"), "0")
    headCombo:AddChoice(L("Offset (push behind)", "Offset (push behind)"), "1")
    headCombo:AddChoice(L("Disabled (show head)", "Disabled (show head)"), "2")

    headForm:NumSlider("Offset Distance (Y)", "vrmod_unoff_puppeteer_hide_head_y", -50, 50, 0)

    -- Display
    local dispForm = vgui.Create("DForm", scroll)
    dispForm:SetName("Display")
    dispForm:Dock(TOP)
    dispForm:DockMargin(4, 0, 4, 8)

    dispForm:CheckBox(L("Show HUD Indicator", "Show HUD Indicator"), "vrmod_unoff_puppeteer_show_hud")

    -- ========================================
    -- Tab 2: Rigging (per-bone control)
    -- ========================================
    local rigTab = vgui.Create("DPanel", sheet)
    sheet:AddSheet("Rigging", rigTab, "icon16/connect.png")
    rigTab.Paint = function() end

    local rigScroll = vgui.Create("DScrollPanel", rigTab)
    rigScroll:Dock(FILL)

    -- Rigging header
    local rigHeader = vgui.Create("DLabel", rigScroll)
    rigHeader:SetText(L("Bone Rigging (Driven vs Physics)", "Bone Rigging (Driven vs Physics)"))
    rigHeader:SetFont("DermaDefaultBold")
    rigHeader:SetTextColor(Color(255, 200, 80))
    rigHeader:Dock(TOP)
    rigHeader:DockMargin(8, 8, 8, 4)
    rigHeader:SizeToContents()

    local rigDesc = vgui.Create("DLabel", rigScroll)
    rigDesc:SetText(
        L("DRIVEN (checked) = follows VR tracking, stable\nPHYSICS (unchecked) = ragdoll physics, dangles\nChanges auto-save and apply immediately.",
          "DRIVEN (checked) = follows VR tracking, stable\nPHYSICS (unchecked) = ragdoll physics, dangles\nChanges auto-save and apply immediately.")
    )
    rigDesc:SetWrap(true)
    rigDesc:SetAutoStretchVertical(true)
    rigDesc:Dock(TOP)
    rigDesc:DockMargin(8, 0, 8, 8)

    -- Get current rigging from client API
    local rig = vrmod.Puppeteer and vrmod.Puppeteer.GetCurrentRig and vrmod.Puppeteer.GetCurrentRig()

    -- Per-bone checkboxes by section
    local boneCheckboxes = {}

    for _, section in ipairs(BONE_LABELS) do
        local secForm = vgui.Create("DForm", rigScroll)
        secForm:SetName(section.section)
        secForm:Dock(TOP)
        secForm:DockMargin(4, 0, 4, 4)

        for _, boneInfo in ipairs(section.bones) do
            local idx = boneInfo[1]
            local label = boneInfo[2]

            local cb = secForm:CheckBox(label)

            -- Initialize from saved state
            local initVal = rig and rig[idx] or true
            cb:SetValue(initVal)

            -- On change: update state, auto-save, send to server
            cb.OnChange = function(self, val)
                if vrmod.Puppeteer and vrmod.Puppeteer.SetBoneRig then
                    vrmod.Puppeteer.SetBoneRig(idx, val)
                end
            end

            boneCheckboxes[idx] = cb
        end
    end

    -- Quick actions
    local quickForm = vgui.Create("DForm", rigScroll)
    quickForm:SetName(L("Quick Actions", "Quick Actions"))
    quickForm:Dock(TOP)
    quickForm:DockMargin(4, 0, 4, 8)

    local allDrivenBtn = quickForm:Button(L("All DRIVEN", "All DRIVEN"))
    allDrivenBtn.DoClick = function()
        local newRig = {}
        for i = 1, 15 do newRig[i] = true end
        if vrmod.Puppeteer and vrmod.Puppeteer.SetFullRig then
            vrmod.Puppeteer.SetFullRig(newRig)
        end
        for idx, cb in pairs(boneCheckboxes) do
            cb:SetValue(true)
        end
    end

    local allPhysBtn = quickForm:Button(L("All PHYSICS (full ragdoll)", "All PHYSICS (full ragdoll)"))
    allPhysBtn.DoClick = function()
        local newRig = {}
        for i = 1, 15 do newRig[i] = false end
        if vrmod.Puppeteer and vrmod.Puppeteer.SetFullRig then
            vrmod.Puppeteer.SetFullRig(newRig)
        end
        for idx, cb in pairs(boneCheckboxes) do
            cb:SetValue(false)
        end
    end

    -- Head + Hands only: only the 3 VR tracking points are driven, everything else physics
    -- Pelvis(1)=off, Spine2(2)=off, Head(3)=ON,
    -- L_Hand(4)=ON, L_Forearm(5)=off, L_Upper(6)=off,
    -- L_Foot(7)=off, L_Calf(8)=off, L_Thigh(9)=off,
    -- R_Hand(10)=ON, R_Forearm(11)=off, R_Upper(12)=off,
    -- R_Foot(13)=off, R_Calf(14)=off, R_Thigh(15)=off
    local headHandsBtn = quickForm:Button(L("Head + Hands Only (recommended)", "Head + Hands Only (recommended)"))
    headHandsBtn.DoClick = function()
        local newRig = { false, false, true, true, false, false, false, false, false, true, false, false, false, false, false }
        if vrmod.Puppeteer and vrmod.Puppeteer.SetFullRig then
            vrmod.Puppeteer.SetFullRig(newRig)
        end
        for idx, cb in pairs(boneCheckboxes) do
            cb:SetValue(newRig[idx])
        end
    end

    -- ========================================
    -- Tab 3: Info
    -- ========================================
    local infoTab = vgui.Create("DPanel", sheet)
    sheet:AddSheet("Info", infoTab, "icon16/information.png")
    infoTab.Paint = function() end

    local infoScroll = vgui.Create("DScrollPanel", infoTab)
    infoScroll:Dock(FILL)

    local infoLabel = vgui.Create("DLabel", infoScroll)
    infoLabel:SetText(
        "=== VR Ragdoll Puppeteer ===\n" ..
        "\n" ..
        "How it works:\n" ..
        "1. Start VR, then Toggle Puppet ON\n" ..
        "2. A ragdoll copy of your model spawns\n" ..
        "3. Driven bones follow VR tracking (kinematic)\n" ..
        "4. Physics bones dangle freely (ragdoll)\n" ..
        "5. Arms use 2-bone IK (elbow auto-calculated)\n" ..
        "\n" ..
        "Rigging:\n" ..
        "- Each of 15 bones is DRIVEN or PHYSICS\n" ..
        "- Settings saved in data/vrmod/puppeteer_rig.json\n" ..
        "- Loaded automatically when puppet starts\n" ..
        "\n" ..
        "Puppet is removed on death, vehicle, or VR exit.\n" ..
        "\n" ..
        "=== Console Commands ===\n" ..
        "vrmod_puppeteer_toggle\n" ..
        "vrmod_puppeteer_on / off\n" ..
        "vrmod_puppeteer_freeze / unfreeze\n" ..
        "vrmod_puppeteer_rig_bone <1-15> <0|1>"
    )
    infoLabel:SetWrap(true)
    infoLabel:SetAutoStretchVertical(true)
    infoLabel:Dock(TOP)
    infoLabel:DockMargin(8, 8, 8, 8)
    infoLabel:SetTextColor(Color(200, 200, 200))

    -- Dual-mode registration
    if frame.Settings02Register then
        local success = frame.Settings02Register("puppeteer", "Puppeteer", "icon16/user_go.png", sheet)
        if not success then
            frame.DPropertySheet:AddSheet("Puppeteer", sheet, "icon16/user_go.png")
        end
    else
        frame.DPropertySheet:AddSheet("Puppeteer", sheet, "icon16/user_go.png")
    end

    end) -- pcall end
    if not ok then
        print("[VRMod] Menu hook error (addsettingsPuppeteer): " .. tostring(err))
    end
end)

print("[VRMod] Module 17: VR Ragdoll Puppeteer Menu v3 loaded (CL)")
