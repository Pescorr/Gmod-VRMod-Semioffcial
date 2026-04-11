--[[
    TIME CRISIS System ON VRmod — Menu Integration
    Adds Time Crisis tab to VRMod Settings02 menu (DTree).
    Only functional in semiofficial VRMod (original VRMod users use console commands).
]]

-- AddCSLuaFile is handled by vrmod_timecrisis_sv.lua
if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

hook.Add("VRMod_Menu", "addsettingsTimeCrisis", function(frame)
    if not frame or not frame.DPropertySheet then return end

    local ok, err = pcall(function()
    local sheet = vgui.Create("DPropertySheet")
    sheet:Dock(FILL)

    -- ========================================
    -- Main Settings Panel
    -- ========================================
    local mainTab = vgui.Create("DPanel", sheet)
    sheet:AddSheet("Settings", mainTab, "icon16/cog.png")
    mainTab.Paint = function() end

    local scroll = vgui.Create("DScrollPanel", mainTab)
    scroll:Dock(FILL)

    -- Header
    local header = vgui.Create("DLabel", scroll)
    header:SetText(L("TIME CRISIS System", "TIME CRISIS System"))
    header:SetFont("DermaDefaultBold")
    header:SetTextColor(Color(0, 200, 255))
    header:Dock(TOP)
    header:DockMargin(8, 8, 8, 4)
    header:SizeToContents()

    local desc = vgui.Create("DLabel", scroll)
    desc:SetText(
        L("Crouch in VR to enter cover mode:", "Crouch in VR to enter cover mode:") .. "\n" ..
        "  - " .. L("You become invincible while crouching", "You become invincible while crouching") .. "\n" ..
        "  - " .. L("You CANNOT attack while in cover", "You CANNOT attack while in cover") .. "\n" ..
        "  - " .. L("4 ground holsters appear in a fan pattern", "4 ground holsters appear in a fan pattern") .. "\n" ..
        "  - " .. L("Stand up to fight normally", "Stand up to fight normally") .. "\n\n" ..
        L("Inspired by TIME CRISIS arcade game.", "Inspired by TIME CRISIS arcade game.")
    )
    desc:SetWrap(true)
    desc:SetAutoStretchVertical(true)
    desc:SetTextColor(Color(200, 200, 200))
    desc:Dock(TOP)
    desc:DockMargin(8, 0, 8, 8)

    -- Separator
    local sep1 = vgui.Create("DPanel", scroll)
    sep1:Dock(TOP)
    sep1:SetTall(2)
    sep1:DockMargin(8, 4, 8, 4)
    sep1.Paint = function(self, w, h)
        surface.SetDrawColor(60, 60, 60)
        surface.DrawRect(0, 0, w, h)
    end

    -- Enable toggle
    local enableCheck = vgui.Create("DCheckBoxLabel", scroll)
    enableCheck:SetText(L("Enable Time Crisis Mode", "Enable Time Crisis Mode"))
    enableCheck:SetFont("DermaDefaultBold")
    enableCheck:SetConVar("vrmod_unoff_timecrisis")
    enableCheck:SetDark(true)
    enableCheck:Dock(TOP)
    enableCheck:DockMargin(8, 8, 8, 4)
    enableCheck:SizeToContents()

    -- Movement restriction toggle
    local moveCheck = vgui.Create("DCheckBoxLabel", scroll)
    moveCheck:SetText(L("Block movement while in cover", "Block movement while in cover"))
    moveCheck:SetConVar("vrmod_unoff_tc_block_movement")
    moveCheck:SetDark(true)
    moveCheck:Dock(TOP)
    moveCheck:DockMargin(8, 4, 8, 4)
    moveCheck:SizeToContents()

    -- Separator
    local sep2 = vgui.Create("DPanel", scroll)
    sep2:Dock(TOP)
    sep2:SetTall(2)
    sep2:DockMargin(8, 8, 8, 4)
    sep2.Paint = function(self, w, h)
        surface.SetDrawColor(60, 60, 60)
        surface.DrawRect(0, 0, w, h)
    end

    -- Holster section header
    local holsterHeader = vgui.Create("DLabel", scroll)
    holsterHeader:SetText(L("Ground Holster Settings", "Ground Holster Settings"))
    holsterHeader:SetFont("DermaDefaultBold")
    holsterHeader:SetTextColor(Color(60, 180, 255))
    holsterHeader:Dock(TOP)
    holsterHeader:DockMargin(8, 4, 8, 4)
    holsterHeader:SizeToContents()

    -- Holster distance slider
    local distSlider = vgui.Create("DNumSlider", scroll)
    distSlider:SetText(L("Holster distance", "Holster distance"))
    distSlider:SetMin(5)
    distSlider:SetMax(40)
    distSlider:SetDecimals(0)
    distSlider:SetConVar("vrmod_unoff_tc_holster_dist")
    distSlider:SetDark(true)
    distSlider:Dock(TOP)
    distSlider:DockMargin(8, 0, 8, 0)

    -- Holster detection radius slider
    local radiusSlider = vgui.Create("DNumSlider", scroll)
    radiusSlider:SetText(L("Detection radius", "Detection radius"))
    radiusSlider:SetMin(3)
    radiusSlider:SetMax(20)
    radiusSlider:SetDecimals(0)
    radiusSlider:SetConVar("vrmod_unoff_tc_holster_radius")
    radiusSlider:SetDark(true)
    radiusSlider:Dock(TOP)
    radiusSlider:DockMargin(8, 0, 8, 0)

    -- Separator
    local sep3 = vgui.Create("DPanel", scroll)
    sep3:Dock(TOP)
    sep3:SetTall(2)
    sep3:DockMargin(8, 8, 8, 4)
    sep3.Paint = function(self, w, h)
        surface.SetDrawColor(60, 60, 60)
        surface.DrawRect(0, 0, w, h)
    end

    -- Slot contents display
    local slotHeader = vgui.Create("DLabel", scroll)
    slotHeader:SetText(L("Holster Slot Contents", "Holster Slot Contents"))
    slotHeader:SetFont("DermaDefaultBold")
    slotHeader:SetTextColor(Color(60, 180, 255))
    slotHeader:Dock(TOP)
    slotHeader:DockMargin(8, 4, 8, 4)
    slotHeader:SizeToContents()

    local slotDesc = vgui.Create("DLabel", scroll)
    slotDesc:SetText(L("Store weapons by crouching and using the pickup button near a slot.", "Store weapons by crouching and using the pickup button near a slot.") .. "\n" .. L("Clear a slot with the button below.", "Clear a slot with the button below."))
    slotDesc:SetWrap(true)
    slotDesc:SetAutoStretchVertical(true)
    slotDesc:SetTextColor(Color(180, 180, 180))
    slotDesc:Dock(TOP)
    slotDesc:DockMargin(8, 0, 8, 8)

    -- Slot rows
    for i = 1, 4 do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:SetTall(28)
        row:DockMargin(8, 2, 8, 2)
        row.Paint = function(self, w, h)
            surface.SetDrawColor(40, 40, 40, 180)
            surface.DrawRect(0, 0, w, h)
        end

        local label = vgui.Create("DLabel", row)
        label:SetText("Slot " .. i .. ":")
        label:SetFont("DermaDefaultBold")
        label:SetDark(true)
        label:Dock(LEFT)
        label:SetWide(50)
        label:DockMargin(6, 0, 4, 0)

        local contentLabel = vgui.Create("DLabel", row)
        contentLabel:SetDark(true)
        contentLabel:Dock(FILL)
        contentLabel:DockMargin(4, 0, 4, 0)

        -- Update display from ConVar
        local function UpdateSlotDisplay()
            local cvarName = "vrmod_unoff_tc_slot_" .. i
            local cv = GetConVar(cvarName)
            local wepclass = cv and cv:GetString() or ""
            if wepclass == "" then
                contentLabel:SetText(L("[ Empty ]", "[ Empty ]"))
                contentLabel:SetTextColor(Color(120, 120, 120))
            else
                local displayName = wepclass
                local wepInfo = weapons.Get(wepclass)
                if wepInfo and wepInfo.PrintName then
                    displayName = wepInfo.PrintName .. " (" .. wepclass .. ")"
                end
                contentLabel:SetText(displayName)
                contentLabel:SetTextColor(Color(60, 180, 255))
            end
        end

        UpdateSlotDisplay()

        -- Clear button
        local clearBtn = vgui.Create("DButton", row)
        clearBtn:SetText(L("Clear", "Clear"))
        clearBtn:SetWide(50)
        clearBtn:Dock(RIGHT)
        clearBtn:DockMargin(4, 2, 4, 2)
        clearBtn.DoClick = function()
            RunConsoleCommand("vrmod_unoff_tc_slot_" .. i, "")
            timer.Simple(0.05, UpdateSlotDisplay)
        end

        -- Refresh button
        local refreshBtn = vgui.Create("DButton", row)
        refreshBtn:SetText("↻")
        refreshBtn:SetWide(24)
        refreshBtn:Dock(RIGHT)
        refreshBtn:DockMargin(0, 2, 0, 2)
        refreshBtn.DoClick = UpdateSlotDisplay
    end

    -- Separator
    local sep4 = vgui.Create("DPanel", scroll)
    sep4:Dock(TOP)
    sep4:SetTall(2)
    sep4:DockMargin(8, 8, 8, 4)
    sep4.Paint = function(self, w, h)
        surface.SetDrawColor(60, 60, 60)
        surface.DrawRect(0, 0, w, h)
    end

    -- Console commands reference
    local cmdHeader = vgui.Create("DLabel", scroll)
    cmdHeader:SetText(L("Console Commands", "Console Commands"))
    cmdHeader:SetFont("DermaDefaultBold")
    cmdHeader:SetTextColor(Color(180, 180, 180))
    cmdHeader:Dock(TOP)
    cmdHeader:DockMargin(8, 4, 8, 2)
    cmdHeader:SizeToContents()

    local cmdDesc = vgui.Create("DLabel", scroll)
    cmdDesc:SetText(
        "vrmod_unoff_timecrisis 0/1 — Enable/Disable\n" ..
        "vrmod_unoff_tc_block_movement 0/1 — Movement restriction\n" ..
        "vrmod_unoff_tc_holster_dist <5-40> — Holster distance\n" ..
        "vrmod_unoff_tc_holster_radius <3-20> — Detection radius\n" ..
        "vrmod_unoff_tc_slot_1..4 <class> — Set slot weapon"
    )
    cmdDesc:SetWrap(true)
    cmdDesc:SetAutoStretchVertical(true)
    cmdDesc:SetTextColor(Color(140, 140, 140))
    cmdDesc:Dock(TOP)
    cmdDesc:DockMargin(8, 0, 8, 8)

    -- Dual-mode registration
    if frame.Settings02Register then
        local success = frame.Settings02Register("timecrisis", "Time Crisis", "icon16/shield.png", sheet)
        if not success then
            frame.DPropertySheet:AddSheet("Time Crisis", sheet, "icon16/shield.png")
        end
    else
        frame.DPropertySheet:AddSheet("Time Crisis", sheet, "icon16/shield.png")
    end

    end) -- pcall end
    if not ok then
        print("[VRMod] Menu hook error (addsettingsTimeCrisis): " .. tostring(err))
    end
end)
