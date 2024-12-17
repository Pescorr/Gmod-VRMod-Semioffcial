AddCSLuaFile()
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
    "VRMod_Menu",
    "addsettings04",
    function(frame)
        local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
        frame.DPropertySheet:AddSheet("VRMag", sheet)
        sheet:Dock(FILL)
        local ScrollPanel = vgui.Create("DScrollPanel", sheet)
        sheet:AddSheet("Magazine", ScrollPanel, "icon16/basket.png")
        local MenuTab14 = vgui.Create("DPanel", ScrollPanel)
        MenuTab14:Dock(TOP)
        MenuTab14:SetHeight(500) -- 適切な高さに調整
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
        resetButton:SetText("Reset Magazine Adjustments")
        resetButton.DoClick = function()
            RunConsoleCommand("vrmod_mag_pos_x", "0")
            RunConsoleCommand("vrmod_mag_pos_y", "0")
            RunConsoleCommand("vrmod_mag_pos_z", "0")
            RunConsoleCommand("vrmod_mag_ang_p", "0")
            RunConsoleCommand("vrmod_mag_ang_y", "0")
            RunConsoleCommand("vrmod_mag_ang_r", "0")
        end

        local magBonesLabel = vgui.Create("DLabel", MenuTab14)
        AddControl(magBonesLabel, 20)
        magBonesLabel:SetText("Magazine Bone Names (comma-separated):")
        local magBonesEntry = vgui.Create("DTextEntry", MenuTab14)
        AddControl(magBonesEntry, 25)
        magBonesEntry:SetConVar("vrmod_mag_bones")
        -- 既存のコードは変更なし
        -- magBonesEntry の後に以下のコードを追加/変更します
        local buttonPanel = vgui.Create("DPanel", MenuTab14)
        AddControl(buttonPanel, 25)
        buttonPanel.Paint = function() end -- 背景を透明にする
        local applyButton = vgui.Create("DButton", buttonPanel)
        applyButton:Dock(LEFT)
        applyButton:SetWide(150) -- ボタンの幅を半分に
        applyButton:SetText("Apply Magazine Bone Names")
        applyButton.DoClick = function()
            RunConsoleCommand("vrmod_mag_bones", magBonesEntry:GetValue())
        end

        local defaultButton = vgui.Create("DButton", buttonPanel)
        defaultButton:Dock(RIGHT)
        defaultButton:SetWide(150) -- ボタンの幅を半分に
        defaultButton:SetText("Default Magazine Bone Names")
        defaultButton.DoClick = function()
            local defaultBones = "mag,ammo,clip,cylin,shell,magazine"
            RunConsoleCommand("vrmod_mag_bones", defaultBones)
            magBonesEntry:SetValue(defaultBones)
        end

        -- buttonPanel の後にスペースを追加（オプション）
        local spacer = vgui.Create("DPanel", MenuTab14)
        AddControl(spacer, 10)
        spacer.Paint = function() end
    end
)