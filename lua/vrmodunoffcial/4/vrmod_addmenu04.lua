--------[vrmod_addmenu04.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
    "VRMod_Menu",
    "addsettings04",
    function(frame)
        if not frame or not frame.DPropertySheet then return end

        local ok, err = pcall(function()
        local ScrollPanel = vgui.Create("DScrollPanel")
        local MenuTab14 = vgui.Create("DPanel", ScrollPanel)
        MenuTab14:Dock(TOP)
        MenuTab14:SetHeight(830)
        MenuTab14.Paint = function(self, w, h) end
        local function AddControl(control, height)
            control:Dock(TOP)
            control:DockMargin(20, 5, 20, 0)
            control:SetHeight(height)
        end

        local mag_system_enable = MenuTab14:Add("DCheckBoxLabel")
        AddControl(mag_system_enable, 20)
        mag_system_enable:SetText("Enable VR Magazine System")
        mag_system_enable:SetConVar("vrmod_mag_system_enable")
        local mag_pouch_enable = MenuTab14:Add("DCheckBoxLabel")
        AddControl(mag_pouch_enable, 20)
        mag_pouch_enable:SetText("Enable Magazine Pouch (spawn vrmagent from body pouch)")
        mag_pouch_enable:SetConVar("vrmod_unoff_mag_pouch_enable")
        local mag_system_type = MenuTab14:Add("DCheckBoxLabel")
        AddControl(mag_system_type, 20)
        mag_system_type:SetText("VR Magazine bone or bonegroup")
        mag_system_type:SetConVar("vrmod_mag_ejectbone_type")
        local magent_sound = vgui.Create("DTextEntry", MenuTab14)
        AddControl(magent_sound, 25)
        magent_sound:SetText("Magazine Enter Sound")
        magent_sound:SetConVar("vrmod_magent_sound")
        local magent_range = vgui.Create("DNumSlider", MenuTab14)
        AddControl(magent_range, 25)
        magent_range:SetText("Magazine Enter Range")
        magent_range:SetMin(1)
        magent_range:SetMax(100)
        magent_range:SetDecimals(0)
        magent_range:SetConVar("vrmod_magent_range")
        local magent_model = vgui.Create("DTextEntry", MenuTab14)
        AddControl(magent_model, 25)
        magent_model:SetText("Magazine Enter Model")
        magent_model:SetConVar("vrmod_magent_model")
        local magent_eject = MenuTab14:Add("DCheckBoxLabel")
        AddControl(magent_eject, 20)
        magent_eject:SetText("[WIP]WeaponModel Mag Grab/Eject")
        magent_eject:SetConVar("vrmod_mag_ejectbone_enable")
        local magEjectDelay = vgui.Create("DNumSlider", MenuTab14)
        AddControl(magEjectDelay, 25)
        magEjectDelay:SetText("Mag Bone Hide Delay (seconds)")
        magEjectDelay:SetMin(0)
        magEjectDelay:SetMax(2)
        magEjectDelay:SetDecimals(2)
        magEjectDelay:SetConVar("vrmod_mag_ejectbone_delay")
        local function CreateSlider(convar, label, min, max)
            local slider = vgui.Create("DNumSlider", MenuTab14)
            AddControl(slider, 25)
            slider:SetText(label)
            slider:SetMin(min)
            slider:SetMax(max)
            slider:SetDecimals(2)
            slider:SetConVar(convar)
        end

        CreateSlider("vrmod_mag_pos_x", "Position X", -20, 20)
        CreateSlider("vrmod_mag_pos_y", "Position Y", -20, 20)
        CreateSlider("vrmod_mag_pos_z", "Position Z", -20, 20)
        CreateSlider("vrmod_mag_ang_p", "Angle Pitch", -180, 180)
        CreateSlider("vrmod_mag_ang_y", "Angle Yaw", -180, 180)
        CreateSlider("vrmod_mag_ang_r", "Angle Roll", -180, 180)
        local resetButton = vgui.Create("DButton", MenuTab14)
        AddControl(resetButton, 25)
        resetButton:SetText("Restore Default Settings")
        resetButton.DoClick = function()
            RunConsoleCommand("vrmod_mag_system_enable", "1")
            RunConsoleCommand("vrmod_mag_ejectbone_enable", "1")
            RunConsoleCommand("vrmod_mag_ejectbone_delay", "0")
            RunConsoleCommand("vrmod_mag_ejectbone_type", "0")
            RunConsoleCommand("vrmod_mag_pos_x", "3.15")
            RunConsoleCommand("vrmod_mag_pos_y", "0.31")
            RunConsoleCommand("vrmod_mag_pos_z", "2.83")
            RunConsoleCommand("vrmod_mag_ang_p", "-2.83")
            RunConsoleCommand("vrmod_mag_ang_y", "90")
            RunConsoleCommand("vrmod_mag_ang_r", "83")
            RunConsoleCommand("vrmod_mag_bones", "mag,ammo,clip,cylin,shell,magazine")
            RunConsoleCommand("vrmod_magent_sound", "weapons/shotgun/shotgun_reload3.wav")
            RunConsoleCommand("vrmod_magent_range", "12")
            RunConsoleCommand("vrmod_unoff_mag_pouch_enable", "1")
            RunConsoleCommand("vrmod_unoff_pouch_location", "pelvis")
            RunConsoleCommand("vrmod_unoff_pouch_dist", "16")
            RunConsoleCommand("vrmod_unoff_pouch_infinite", "0")
            RunConsoleCommand("vrmod_unoff_pouch_sync_arcvr", "1")
            RunConsoleCommand("vrmod_arc9_enable", "1")
            RunConsoleCommand("vrmod_arc9_magbone_fix_enable", "1")
            RunConsoleCommand("vrmod_arc9_magbone_track", "1")
        end

        local magBonesLabel = vgui.Create("DLabel", MenuTab14)
        AddControl(magBonesLabel, 20)
        magBonesLabel:SetText("Magazine Bone Names (comma-separated):")
        local magBonesEntry = vgui.Create("DTextEntry", MenuTab14)
        AddControl(magBonesEntry, 25)
        magBonesEntry:SetConVar("vrmod_mag_bones")
        local buttonPanel = vgui.Create("DPanel", MenuTab14)
        AddControl(buttonPanel, 25)
        buttonPanel.Paint = function() end
        local applyButton = vgui.Create("DButton", buttonPanel)
        applyButton:Dock(LEFT)
        applyButton:SetWide(150)
        applyButton:SetText("Apply Magazine Bone Names")
        applyButton.DoClick = function()
            RunConsoleCommand("vrmod_mag_bones", magBonesEntry:GetValue())
        end

        local defaultButton = vgui.Create("DButton", buttonPanel)
        defaultButton:Dock(RIGHT)
        defaultButton:SetWide(150)
        defaultButton:SetText("Default Magazine Bone Names")
        defaultButton.DoClick = function()
            local defaultBones = "mag,ammo,clip,cylin,shell,magazine"
            RunConsoleCommand("vrmod_mag_bones", defaultBones)
            magBonesEntry:SetValue(defaultBones)
        end

        local spacer = vgui.Create("DPanel", MenuTab14)
        AddControl(spacer, 10)
        spacer.Paint = function() end

        -- =============================================================================
        -- Unified Pouch Settings
        -- =============================================================================
        local pouchHeader = vgui.Create("DLabel", MenuTab14)
        AddControl(pouchHeader, 25)
        pouchHeader:SetFont("DermaDefaultBold")
        pouchHeader:SetText("--- Pouch Settings (ArcVR Sync) ---")

        local pouchLocLabel = vgui.Create("DLabel", MenuTab14)
        AddControl(pouchLocLabel, 20)
        pouchLocLabel:SetText("Pouch Location:")

        local pouchLocCombo = vgui.Create("DComboBox", MenuTab14)
        AddControl(pouchLocCombo, 25)
        pouchLocCombo:AddChoice("Pelvis (Hip)", "pelvis")
        pouchLocCombo:AddChoice("Head", "head")
        pouchLocCombo:AddChoice("Spine (Chest)", "spine")
        local curLoc = GetConVar("vrmod_unoff_pouch_location")
        if curLoc then
            local locVal = curLoc:GetString()
            if locVal == "head" then
                pouchLocCombo:ChooseOptionID(2)
            elseif locVal == "spine" then
                pouchLocCombo:ChooseOptionID(3)
            else
                pouchLocCombo:ChooseOptionID(1)
            end
        end
        pouchLocCombo.OnSelect = function(_, _, _, data)
            RunConsoleCommand("vrmod_unoff_pouch_location", data)
        end

        local pouchDist = vgui.Create("DNumSlider", MenuTab14)
        AddControl(pouchDist, 25)
        pouchDist:SetText("Pouch Distance")
        pouchDist:SetMin(1)
        pouchDist:SetMax(50)
        pouchDist:SetDecimals(1)
        pouchDist:SetConVar("vrmod_unoff_pouch_dist")

        local pouchInfinite = MenuTab14:Add("DCheckBoxLabel")
        AddControl(pouchInfinite, 20)
        pouchInfinite:SetText("Infinite Pouch (any distance)")
        pouchInfinite:SetConVar("vrmod_unoff_pouch_infinite")

        local pouchSync = MenuTab14:Add("DCheckBoxLabel")
        AddControl(pouchSync, 20)
        pouchSync:SetText("Sync to ArcVR ConVars")
        pouchSync:SetConVar("vrmod_unoff_pouch_sync_arcvr")
        if not GetConVar("arcticvr_defpouchdist") then
            pouchSync:SetEnabled(false)
            pouchSync:SetText("Sync to ArcVR ConVars (ArcVR not found)")
        end

        local pouchInfoLabel = vgui.Create("DLabel", MenuTab14)
        AddControl(pouchInfoLabel, 20)
        pouchInfoLabel:SetTextColor(Color(180, 180, 180))
        if vrmod.pouch and vrmod.pouch.GetInfo then
            local info = vrmod.pouch.GetInfo()
            local statusText = "Bone: " .. info.boneName .. " | Dist: " .. info.dist
            if info.infinite then statusText = statusText .. " (Infinite)" end
            if info.arcvrInstalled then
                statusText = statusText .. " | ArcVR: Installed"
            else
                statusText = statusText .. " | ArcVR: Not found"
            end
            pouchInfoLabel:SetText(statusText)
        else
            pouchInfoLabel:SetText("Unified Pouch system not loaded")
        end

        local spacer2 = vgui.Create("DPanel", MenuTab14)
        AddControl(spacer2, 10)
        spacer2.Paint = function() end

        -- =============================================================================
        -- ARC9 Settings
        -- =============================================================================
        local arc9Header = vgui.Create("DLabel", MenuTab14)
        AddControl(arc9Header, 25)
        arc9Header:SetFont("DermaDefaultBold")
        arc9Header:SetText("--- ARC9 Weapon Settings ---")

        local arc9Enable = MenuTab14:Add("DCheckBoxLabel")
        AddControl(arc9Enable, 20)
        arc9Enable:SetText("Enable ARC9 VR Integration")
        arc9Enable:SetConVar("vrmod_arc9_enable")

        local arc9MagFix = MenuTab14:Add("DCheckBoxLabel")
        AddControl(arc9MagFix, 20)
        arc9MagFix:SetText("Enable ARC9 Magazine Bone Fix")
        arc9MagFix:SetConVar("vrmod_arc9_magbone_fix_enable")

        local arc9MagTrack = MenuTab14:Add("DCheckBoxLabel")
        AddControl(arc9MagTrack, 20)
        arc9MagTrack:SetText("ARC9 Mag Bone: Follow Left Hand (New) / Hide Only (Old)")
        arc9MagTrack:SetConVar("vrmod_arc9_magbone_track")

        -- Dual-mode registration
        if frame.Settings02Register then
            local success = frame.Settings02Register("magazine", "Magazine", "icon16/basket.png", ScrollPanel)
            if not success then
                frame.DPropertySheet:AddSheet("Magazine", ScrollPanel, "icon16/basket.png")
            end
        else
            frame.DPropertySheet:AddSheet("Magazine", ScrollPanel, "icon16/basket.png")
        end

        end) -- pcall end
        if not ok then
            print("[VRMod] Menu hook error (addsettings04): " .. tostring(err))
        end
    end
)
--------[vrmod_addmenu04.lua]End--------
