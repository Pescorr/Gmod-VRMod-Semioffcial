--------[vrmod_unoff_menu_melee.lua]Start--------
AddCSLuaFile()
if CLIENT then
    local convars, convarValues = vrmod.GetConvars()
    hook.Add(
        "VRMod_Menu",
        "addsettingsmelee",
        function(frame)
            if not frame.VRplaySheet then return end
            local sheet = vgui.Create("DPropertySheet", frame.VRplaySheet)
            frame.VRplaySheet:AddSheet("VRMelee", sheet)
            sheet:Dock(FILL)
            -- Basic Settings Tab
            local MenuTabmelee1 = vgui.Create("DPanel", sheet)
            sheet:AddSheet("Basic", MenuTabmelee1, "icon16/briefcase.png")
            MenuTabmelee1.Paint = function(self, w, h) end
            local scrollPanel1 = vgui.Create("DScrollPanel", MenuTabmelee1)
            scrollPanel1:Dock(FILL)
            local form1 = vgui.Create("DForm", scrollPanel1)
            form1:SetName("Basic Settings")
            form1:Dock(TOP)
            form1.Header:SetVisible(false)
            form1.Paint = function(self, w, h) end
            form1:CheckBox("Use Gun Melee", "vrmelee_usegunmelee")
            form1:CheckBox("Use Fist Attacks", "vrmelee_usefist")
            form1:CheckBox("Use Kick Attacks [FBT]", "vrmelee_usekick")
            form1:CheckBox("Play Hit Sounds", "vrmelee_hit_sound")
            form1:CheckBox("Enable Hit Feedback", "vrmelee_hit_feedback")
            form1:NumSlider("Attack Range", "vrmelee_range", 10, 100, 0)
            -- -- Ragdoll Pickup Settings
            -- form1:CheckBox("Ragdoll Pickup", "vrmelee_ragdoll_pickup")
            -- form1:NumSlider("Ragdoll Pickup Range", "vrmelee_ragdollpickup_range", 5, 50, 0)
            -- form1:CheckBox("Highlight Pickupable Ragdolls", "vrmelee_ragdollpickup_highlight")
            -- form1:CheckBox("Use Button for Ragdoll Pickup", "vrmelee_ragdollpickup_use")
            -- Visual Effects Settings
            form1:CheckBox("Fist Collision Effects", "vrmelee_fist_collision")
            form1:CheckBox("Visible Collision Model", "vrmelee_fist_visible")
            -- Damage Settings Tab
            local MenuTabmelee2 = vgui.Create("DPanel", sheet)
            sheet:AddSheet("Damage", MenuTabmelee2, "icon16/wand.png")
            MenuTabmelee2.Paint = function(self, w, h) end
            local scrollPanel2 = vgui.Create("DScrollPanel", MenuTabmelee2)
            scrollPanel2:Dock(FILL)
            local form2 = vgui.Create("DForm", scrollPanel2)
            form2:SetName("Damage Settings")
            form2:Dock(TOP)
            form2.Header:SetVisible(false)
            form2.Paint = function(self, w, h) end
            form2:NumSlider("Damage (Low)", "vrmelee_damage_low", 0, 100, 0)
            form2:NumSlider("Damage (Medium)", "vrmelee_damage_medium", 0, 100, 0)
            form2:NumSlider("Damage (High)", "vrmelee_damage_high", 0, 100, 0)
            form2:NumSlider("Velocity Threshold (Low)", "vrmelee_damage_velocity_low", 0, 5, 2)
            form2:NumSlider("Velocity Threshold (Medium)", "vrmelee_damage_velocity_medium", 0, 5, 2)
            form2:NumSlider("Velocity Threshold (High)", "vrmelee_damage_velocity_high", 0, 5, 2)
            form2:NumSlider("Impact Force", "vrmelee_impact", 0, 5, 2)
            form2:NumSlider("Attack Delay", "vrmelee_delay", 0.00000, 0.50, 2)
            form2:NumSlider("Attack Cooldown", "vrmelee_cooldown", 0.00000, 0.50, 2)
            -- Hitbox Settings
            form2:NumSlider("Hitbox Width", "vrmelee_hitbox_width", 1, 10, 0)
            form2:NumSlider("Hitbox Length", "vrmelee_hitbox_length", 1, 20, 0)
            -- Reset to defaults button
            form2:Button("Reset to Defaults", "vrmelee_default")
            -- Advanced Settings Tab
            local MenuTabmelee3 = vgui.Create("DPanel", sheet)
            sheet:AddSheet("Advanced", MenuTabmelee3, "icon16/cog.png")
            MenuTabmelee3.Paint = function(self, w, h) end
            local scrollPanel3 = vgui.Create("DScrollPanel", MenuTabmelee3)
            scrollPanel3:Dock(FILL)
            local form3 = vgui.Create("DForm", scrollPanel3)
            form3:SetName("Advanced Settings")
            form3:Dock(TOP)
            form3.Header:SetVisible(false)
            form3.Paint = function(self, w, h) end
            -- Commands to run when hitting with different limbs
            form3:TextEntry("Left Hand Hit Command", "vrmelee_lefthand_command")
            form3:TextEntry("Right Hand Hit Command", "vrmelee_righthand_command")
            form3:TextEntry("Left Foot Hit Command", "vrmelee_leftfoot_command")
            form3:TextEntry("Right Foot Hit Command", "vrmelee_rightfoot_command")
            form3:TextEntry("Gun Hit Command", "vrmelee_gunmelee_command")
            -- Visual settings
            form3:TextEntry("Collision Effect Model", "vrmelee_fist_collisionmodel")
            -- Blocking Settings
            form3:CheckBox("Enable Blocking", "vrmelee_emulateblocking")
            form3:TextEntry("Block Button", "vrmelee_emulateblockbutton")
            form3:TextEntry("Block Release", "vrmelee_emulateblockbutton_release")
            form3:NumSlider("Block Angle Min", "vrmelee_emulatebloack_Threshold_Low", 0, 180, 0)
            form3:NumSlider("Block Angle Max", "vrmelee_emulatebloack_Threshold_High", 0, 180, 0)
            -- Server Settings Tab (SERVER ConVars)
            local MenuTabmelee4 = vgui.Create("DPanel", sheet)
            sheet:AddSheet("Server", MenuTabmelee4, "icon16/server.png")
            MenuTabmelee4.Paint = function(self, w, h) end
            local scrollPanel4 = vgui.Create("DScrollPanel", MenuTabmelee4)
            scrollPanel4:Dock(FILL)
            local form4 = vgui.Create("DForm", scrollPanel4)
            form4:SetName("Server Settings")
            form4:Dock(TOP)
            form4.Header:SetVisible(false)
            form4.Paint = function(self, w, h) end
            -- Info message
            local infoLabel = vgui.Create("DLabel", scrollPanel4)
            infoLabel:SetText("NOTE: Server settings require admin/server owner privileges to change.")
            infoLabel:SetTextColor(Color(255, 100, 0))
            infoLabel:Dock(TOP)
            infoLabel:DockMargin(5, 5, 5, 5)
            infoLabel:SetWrap(true)
            infoLabel:SetAutoStretchVertical(true)
            -- Attack Type Enables
            form4:CheckBox("Allow Gun Melee", "vrmelee_gunmelee")
            form4:CheckBox("Allow Fist Attacks", "vrmelee_fist")
            form4:CheckBox("Allow Kick Attacks (FBT)", "vrmelee_kick")
            form4:Help("Enable/disable different types of melee attacks")
            -- Damage Settings
            form4:NumSlider("Damage (Low Velocity)", "vrmelee_damage_low", 0, 100, 2)
            form4:NumSlider("Damage (Medium Velocity)", "vrmelee_damage_medium", 0, 100, 2)
            form4:NumSlider("Damage (High Velocity)", "vrmelee_damage_high", 0, 100, 2)
            form4:Help("Damage values for different velocity levels")
            -- Velocity Thresholds
            form4:NumSlider("Velocity Threshold (Low)", "vrmelee_damage_velocity_low", 0, 10, 2)
            form4:NumSlider("Velocity Threshold (Medium)", "vrmelee_damage_velocity_medium", 0, 10, 2)
            form4:NumSlider("Velocity Threshold (High)", "vrmelee_damage_velocity_high", 0, 10, 2)
            form4:Help("Velocity thresholds to determine damage level")
            -- Other Server Settings
            form4:NumSlider("Impact Force", "vrmelee_impact", 0, 20, 2)
            form4:NumSlider("Attack Delay", "vrmelee_delay", 0, 2, 2)
            form4:NumSlider("Attack Range", "vrmelee_range", 0, 50, 0)
            form4:Help("Other server-side melee settings")
            -- Compatibility
            form4:CheckBox("High Velocity Fire Bullets", "vrmelee_high_velocity_fire_bullets")
            form4:Help("Enable bullet firing for high velocity attacks (compatibility mode)")
            -- Reset Server Settings Button
            local resetServerBtn = vgui.Create("DButton", scrollPanel4)
            resetServerBtn:SetText("Reset Server Settings to Defaults")
            resetServerBtn:Dock(TOP)
            resetServerBtn:DockMargin(5, 5, 5, 5)
            resetServerBtn:SetTall(30)
            resetServerBtn.DoClick = function()
                RunConsoleCommand("vrmelee_default")
                chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Server melee settings reset to defaults")
            end
        end
    )

    -- Reset to default values
    -- UPDATED: Now uses centralized default values system (vrmod_defaults.lua)
    concommand.Add(
        "vrmelee_default",
        function(ply, cmd, args)
            VRModResetCategory("melee")
            -- Notify user
            chat.AddText(Color(0, 255, 0), VRModL("msg_melee_reset", "VR Melee settings have been reset to defaults."))
        end
    )
end
--------[vrmod_unoff_menu_melee.lua]End--------