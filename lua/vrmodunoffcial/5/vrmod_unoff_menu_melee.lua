--------[vrmod_unoff_menu_melee.lua]Start--------
AddCSLuaFile()
if CLIENT then
    local convars, convarValues = vrmod.GetConvars()
    hook.Add(
        "VRMod_Menu",
        "addsettingsmelee",
        function(frame)
            local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
            frame.DPropertySheet:AddSheet("VRMelee", sheet)
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
        end
    )

    -- Reset to default values
    -- Reset to default values
    concommand.Add(
        "vrmelee_default",
        function(ply, cmd, args)
            -- Main settings
            LocalPlayer():ConCommand("vrmelee_gunmelee 1")
            LocalPlayer():ConCommand("vrmelee_fist 1")
            LocalPlayer():ConCommand("vrmelee_kick 1")
            -- Damage values
            LocalPlayer():ConCommand("vrmelee_damage_low 10.000")
            LocalPlayer():ConCommand("vrmelee_damage_medium 20.000")
            LocalPlayer():ConCommand("vrmelee_damage_high 30.000")
            -- Velocity thresholds
            LocalPlayer():ConCommand("vrmelee_damage_velocity_low 3.45")
            LocalPlayer():ConCommand("vrmelee_damage_velocity_medium 4.11")
            LocalPlayer():ConCommand("vrmelee_damage_velocity_high 4.35")
            -- Attack parameters
            LocalPlayer():ConCommand("vrmelee_impact 5.0")
            LocalPlayer():ConCommand("vrmelee_delay 0.00")
            LocalPlayer():ConCommand("vrmelee_range 22")
            -- Client settings
            LocalPlayer():ConCommand("vrmelee_usegunmelee 1")
            LocalPlayer():ConCommand("vrmelee_usefist 1")
            LocalPlayer():ConCommand("vrmelee_usekick 0")
            LocalPlayer():ConCommand("vrmelee_cooldown 0.2")
            -- Visual effects
            LocalPlayer():ConCommand("vrmelee_fist_collision 0")
            LocalPlayer():ConCommand("vrmelee_fist_visible 0")
            LocalPlayer():ConCommand("vrmelee_fist_collisionmodel models/hunter/plates/plate.mdl")
            -- Hit feedback
            LocalPlayer():ConCommand("vrmelee_hit_feedback 1")
            LocalPlayer():ConCommand("vrmelee_hit_sound 1")
            -- Hitbox settings
            LocalPlayer():ConCommand("vrmelee_hitbox_width 4")
            LocalPlayer():ConCommand("vrmelee_hitbox_length 6")
            -- High velocity settings
            LocalPlayer():ConCommand("vrmelee_high_velocity_fire_bullets 0")
            -- Blocking settings
            LocalPlayer():ConCommand("vrmelee_emulateblocking 0")
            LocalPlayer():ConCommand("vrmelee_emulateblockbutton +attack2")
            LocalPlayer():ConCommand("vrmelee_emulateblockbutton_release -attack2")
            LocalPlayer():ConCommand("vrmelee_emulatebloack_Threshold_Low 115")
            LocalPlayer():ConCommand("vrmelee_emulatebloack_Threshold_High 180")
            -- Command clearings
            LocalPlayer():ConCommand("vrmelee_lefthand_command \"\"")
            LocalPlayer():ConCommand("vrmelee_righthand_command \"\"")
            LocalPlayer():ConCommand("vrmelee_leftfoot_command \"\"")
            LocalPlayer():ConCommand("vrmelee_rightfoot_command \"\"")
            LocalPlayer():ConCommand("vrmelee_gunmelee_command \"\"")
            -- Notify user
            chat.AddText(Color(0, 255, 0), "VR Melee settings have been reset to defaults.")
        end
    )
end
--------[vrmod_unoff_menu_melee.lua]End--------