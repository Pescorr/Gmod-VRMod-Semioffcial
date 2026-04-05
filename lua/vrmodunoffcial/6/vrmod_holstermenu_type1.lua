--------[vrmod_holstermenu_type1.lua]Start--------
AddCSLuaFile()
if SERVER then return end

hook.Add(
	"VRMod_Menu",
	"addsettings_holster_type1",
	function(frame)
		if not frame or not frame.DPropertySheet then return end

		local ok, err = pcall(function()

		local panel = vgui.Create("DPanel")
		panel:Dock(FILL)
		panel.Paint = function() end

		local scroll = vgui.Create("DScrollPanel", panel)
		scroll:Dock(FILL)

		-- === Right Hand Holster ===
		local formRight = vgui.Create("DForm", scroll)
		formRight:SetName("Right Hand Holster")
		formRight:Dock(TOP)
		formRight:DockMargin(5, 5, 5, 5)

		-- Pelvis
		local pelvisLabel = formRight:Help("=== Pelvis ===")
		pelvisLabel:SetFont("DermaDefaultBold")
		formRight:CheckBox("Enable Pelvis Holster", "vrmod_weppouch_Pelvis")
		formRight:NumSlider("Range", "vrmod_weppouch_dist_Pelvis", 0, 100, 1)
		formRight:CheckBox("Weapon Lock", "vrmod_weppouch_weapon_lock_Pelvis")
		formRight:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_Pelvis")
		formRight:CheckBox("Enable Custom Command", "vrmod_weppouch_customcvar_pelvis_enable")
		formRight:TextEntry("Custom Pickup Command", "vrmod_weppouch_customcvar_pelvis_cmd")
		formRight:TextEntry("Custom Put Command", "vrmod_weppouch_customcvar_pelvis_put_cmd")

		-- Head
		local headLabel = formRight:Help("=== Head ===")
		headLabel:SetFont("DermaDefaultBold")
		formRight:CheckBox("Enable Head Holster", "vrmod_weppouch_Head")
		formRight:NumSlider("Range", "vrmod_weppouch_dist_head", 0, 100, 1)
		formRight:CheckBox("Weapon Lock", "vrmod_weppouch_weapon_lock_Head")
		formRight:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_Head")
		formRight:CheckBox("Enable Custom Command", "vrmod_weppouch_customcvar_head_enable")
		formRight:TextEntry("Custom Pickup Command", "vrmod_weppouch_customcvar_head_cmd")
		formRight:TextEntry("Custom Put Command", "vrmod_weppouch_customcvar_head_put_cmd")

		-- Spine
		local spineLabel = formRight:Help("=== Spine ===")
		spineLabel:SetFont("DermaDefaultBold")
		formRight:CheckBox("Enable Spine Holster", "vrmod_weppouch_Spine")
		formRight:NumSlider("Range", "vrmod_weppouch_dist_spine", 0, 100, 1)
		formRight:CheckBox("Weapon Lock", "vrmod_weppouch_weapon_lock_Spine")
		formRight:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_Spine")
		formRight:CheckBox("Enable Custom Command", "vrmod_weppouch_customcvar_spine_enable")
		formRight:TextEntry("Custom Pickup Command", "vrmod_weppouch_customcvar_spine_cmd")
		formRight:TextEntry("Custom Put Command", "vrmod_weppouch_customcvar_spine_put_cmd")

		-- Restore Defaults (Right)
		local resetRight = vgui.Create("DButton", scroll)
		resetRight:SetText("Restore Defaults (Right)")
		resetRight:Dock(TOP)
		resetRight:DockMargin(5, 5, 5, 5)
		resetRight:SetTall(30)
		resetRight.DoClick = function()
			RunConsoleCommand("vrmod_weppouch_Pelvis", "0")
			RunConsoleCommand("vrmod_weppouch_Head", "0")
			RunConsoleCommand("vrmod_weppouch_Spine", "0")
			RunConsoleCommand("vrmod_weppouch_dist_Pelvis", "12.5")
			RunConsoleCommand("vrmod_weppouch_dist_head", "10")
			RunConsoleCommand("vrmod_weppouch_dist_spine", "0")
			RunConsoleCommand("vrmod_weppouch_weapon_lock_Pelvis", "0")
			RunConsoleCommand("vrmod_weppouch_weapon_lock_Head", "0")
			RunConsoleCommand("vrmod_weppouch_weapon_lock_Spine", "0")
			RunConsoleCommand("vrmod_weppouch_customcvar_pelvis_enable", "0")
			RunConsoleCommand("vrmod_weppouch_customcvar_head_enable", "0")
			RunConsoleCommand("vrmod_weppouch_customcvar_spine_enable", "0")
			RunConsoleCommand("vrmod_weppouch_customcvar_pelvis_cmd", "vrmod_test_pickup_entteleport_right")
			RunConsoleCommand("vrmod_weppouch_customcvar_head_cmd", "vrmod_test_pickup_entteleport_right")
			RunConsoleCommand("vrmod_weppouch_customcvar_spine_cmd", "vrmod_test_pickup_entteleport_right")
			RunConsoleCommand("vrmod_weppouch_customcvar_pelvis_put_cmd", "+use,-use")
			RunConsoleCommand("vrmod_weppouch_customcvar_head_put_cmd", "+use,-use")
			RunConsoleCommand("vrmod_weppouch_customcvar_spine_put_cmd", "+use,-use")
		end

		-- === Left Hand Holster ===
		local formLeft = vgui.Create("DForm", scroll)
		formLeft:SetName("Left Hand Holster")
		formLeft:Dock(TOP)
		formLeft:DockMargin(5, 5, 5, 5)

		-- Pelvis Left
		local pelvisLeftLabel = formLeft:Help("=== Pelvis ===")
		pelvisLeftLabel:SetFont("DermaDefaultBold")
		formLeft:CheckBox("Enable Pelvis Holster", "vrmod_weppouch_left_Pelvis")
		formLeft:NumSlider("Range", "vrmod_weppouch_left_dist_Pelvis", 0, 100, 1)
		formLeft:CheckBox("Weapon Lock", "vrmod_weppouch_weapon_lock_left_Pelvis")
		formLeft:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_left_Pelvis")

		-- Head Left
		local headLeftLabel = formLeft:Help("=== Head ===")
		headLeftLabel:SetFont("DermaDefaultBold")
		formLeft:CheckBox("Enable Head Holster", "vrmod_weppouch_left_Head")
		formLeft:NumSlider("Range", "vrmod_weppouch_left_dist_head", 0, 100, 1)
		formLeft:CheckBox("Weapon Lock", "vrmod_weppouch_weapon_lock_left_Head")
		formLeft:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_left_Head")

		-- Spine Left
		local spineLeftLabel = formLeft:Help("=== Spine ===")
		spineLeftLabel:SetFont("DermaDefaultBold")
		formLeft:CheckBox("Enable Spine Holster", "vrmod_weppouch_left_Spine")
		formLeft:NumSlider("Range", "vrmod_weppouch_left_dist_spine", 0, 100, 1)
		formLeft:CheckBox("Weapon Lock", "vrmod_weppouch_weapon_lock_left_Spine")
		formLeft:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_left_Spine")

		-- Restore Defaults (Left)
		local resetLeft = vgui.Create("DButton", scroll)
		resetLeft:SetText("Restore Defaults (Left)")
		resetLeft:Dock(TOP)
		resetLeft:DockMargin(5, 5, 5, 5)
		resetLeft:SetTall(30)
		resetLeft.DoClick = function()
			RunConsoleCommand("vrmod_weppouch_left_Pelvis", "0")
			RunConsoleCommand("vrmod_weppouch_left_Head", "0")
			RunConsoleCommand("vrmod_weppouch_left_Spine", "0")
			RunConsoleCommand("vrmod_weppouch_left_dist_Pelvis", "12.5")
			RunConsoleCommand("vrmod_weppouch_left_dist_head", "10")
			RunConsoleCommand("vrmod_weppouch_left_dist_spine", "0")
			RunConsoleCommand("vrmod_weppouch_weapon_lock_left_Pelvis", "0")
			RunConsoleCommand("vrmod_weppouch_weapon_lock_left_Head", "0")
			RunConsoleCommand("vrmod_weppouch_weapon_lock_left_Spine", "0")
		end

		-- === Display Settings ===
		local formDisplay = vgui.Create("DForm", scroll)
		formDisplay:SetName("Display Settings")
		formDisplay:Dock(TOP)
		formDisplay:DockMargin(5, 5, 5, 5)

		formDisplay:CheckBox("Visible Range (Right)", "vrmod_weppouch_visiblerange")
		formDisplay:CheckBox("Visible Name (Right)", "vrmod_weppouch_visiblename")
		formDisplay:CheckBox("Visible Range (Left)", "vrmod_weppouch_visiblerange_left")
		formDisplay:CheckBox("Visible Name (Left)", "vrmod_weppouch_visiblename_left")

		-- Dual-mode registration
		if frame.Settings02Register then
			local success = frame.Settings02Register("holster_type1", "VRHolster1", "icon16/package.png", panel)
			if not success then
				frame.DPropertySheet:AddSheet("VRHolster1", panel, "icon16/package.png")
			end
		else
			frame.DPropertySheet:AddSheet("VRHolster1", panel, "icon16/package.png")
		end

		end) -- pcall end
		if not ok then
			print("[VRMod] Menu hook error (addsettings_holster_type1): " .. tostring(err))
		end
	end
)

hook.Remove("VRMod_Menu", "pVRHolsterMenu1")
hook.Remove("VRMod_Menu", "pVRHolsterMenu_left")
--------[vrmod_holstermenu_type1.lua]End--------
