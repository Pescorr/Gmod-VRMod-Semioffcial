--[[
    Module 14: VR Throw — Menu
    Settings02 DTree に VRThrow パネルを追加する（スタンドアロン時はタブ）。
]]

AddCSLuaFile()
if SERVER then return end

hook.Add(
    "VRMod_Menu",
    "addsettings_vrthrow",
    function(frame)
        if not frame or not frame.DPropertySheet then return end

        local ok, err = pcall(function()
        -- メインパネル
        local mainPanel = vgui.Create("DPanel")
        mainPanel.Paint = function(self, w, h) end

        local scroll = vgui.Create("DScrollPanel", mainPanel)
        scroll:Dock(FILL)

        -- Expose scroll panel for AutoPickup hook to merge into
        frame._vrthrow_scroll = scroll

        -- Settings Form
        local form = vgui.Create("DForm", scroll)
        form:SetName("VR Throw Settings")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function(self, w, h) end

        form:CheckBox("Enable VR Throwing", "vrmod_unoff_throw_enabled")
        form:NumSlider("Velocity Multiplier", "vrmod_unoff_throw_velocity_mult", 0.5, 5, 1)
        form:CheckBox("Auto-detect Throwable Weapons", "vrmod_unoff_throw_auto_detect")

        -- Whitelist
        form:Help("Manual Weapon Whitelist (comma-separated class names):")
        form:TextEntry("Whitelist", "vrmod_unoff_throw_whitelist")

        -- Animation / Hand Sync
        form:CheckBox("Force Idle Animation (prevent viewmodel jitter)", "vrmod_unoff_throw_anim_override")
        form:CheckBox("Desync Hand from Viewmodel During Throw", "vrmod_unoff_throw_hand_desync")

        -- Desync Method selector
        local methodCombo = form:ComboBox("Desync Method", "vrmod_unoff_throw_desync_method")
        methodCombo:AddChoice("Method 0: g_VR.net Direct Override", 0)
        methodCombo:AddChoice("Method 1: SetRightHandPose API (Recommended)", 1)

        -- Debug
        form:CheckBox("Debug: Log Throw Events", "vrmod_unoff_throw_debug")

        -- Test button
        local testBtn = form:Button("Test: Check Current Weapon")
        testBtn.DoClick = function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local wep = ply:GetActiveWeapon()
            if not IsValid(wep) then
                chat.AddText(Color(255, 100, 0), "[VRThrow] No weapon equipped")
                return
            end
            local class = wep:GetClass()
            local result = vrmod.VRThrow and vrmod.VRThrow.IsThrowable and vrmod.VRThrow.IsThrowable(wep)
            local ammoType = wep:GetPrimaryAmmoType()
            local ammoName = ammoType ~= -1 and game.GetAmmoName(ammoType) or "none"
            chat.AddText(
                result and Color(0, 255, 0) or Color(255, 80, 80),
                "[VRThrow] " .. class
                    .. " (ammo: " .. ammoName .. ")"
                    .. " = " .. (result and "THROWABLE" or "NOT throwable")
            )
        end

        -- Reset button
        local resetBtn = form:Button("Restore Default Settings")
        resetBtn.DoClick = function()
            RunConsoleCommand("vrmod_unoff_throw_enabled", "1")
            RunConsoleCommand("vrmod_unoff_throw_velocity_mult", "5")
            RunConsoleCommand("vrmod_unoff_throw_auto_detect", "1")
            RunConsoleCommand("vrmod_unoff_throw_whitelist", "")
            RunConsoleCommand("vrmod_unoff_throw_anim_override", "1")
            RunConsoleCommand("vrmod_unoff_throw_hand_desync", "1")
            RunConsoleCommand("vrmod_unoff_throw_desync_method", "1")
            RunConsoleCommand("vrmod_unoff_throw_debug", "0")
            chat.AddText(Color(0, 255, 0), "[VRThrow] Settings reset to defaults.")
        end

        -- Info
        form:Help(
            "VRThrow lets you physically throw grenades using VR hand motion. "
            .. "It works with any weapon mod that spawns projectile entities. "
            .. "Compatible with vrmod_improved_hl2_weapons (auto-skip)."
        )

        -- Dual-mode registration
        if frame.Settings02Register then
            local success = frame.Settings02Register("vrthrow", "VRThrow", "icon16/bomb.png", mainPanel)
            if not success then
                frame.DPropertySheet:AddSheet("VRThrow", mainPanel, "icon16/bomb.png")
            end
        else
            frame.DPropertySheet:AddSheet("VRThrow", mainPanel, "icon16/bomb.png")
        end

        end) -- pcall end
        if not ok then
            print("[VRMod] Menu hook error (addsettings_vrthrow): " .. tostring(err))
        end
    end
)
