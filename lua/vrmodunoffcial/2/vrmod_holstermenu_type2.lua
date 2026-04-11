--------[vrmod_holstermenu_type2.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local L = VRModL or function(_, fb) return fb or "" end

hook.Add(
	"VRMod_Menu",
	"addsettings_holster_type2",
	function(frame)
		if not frame or not frame.DPropertySheet then return end

		local ok, err = pcall(function()

		local panel = vgui.Create("DPanel")
		panel:Dock(FILL)
		panel.Paint = function() end

		local scroll = vgui.Create("DScrollPanel", panel)
		scroll:Dock(FILL)

		-- === Basic Settings ===
		local formBasic = vgui.Create("DForm", scroll)
		formBasic:SetName(L("Basic Settings", "Basic Settings"))
		formBasic:Dock(TOP)
		formBasic:DockMargin(5, 5, 5, 5)

		formBasic:CheckBox(L("System Enable", "System Enable"), "vrmod_pouch_enabled")
		formBasic:CheckBox(L("Visible Name (3D)", "Visible Name (3D)"), "vrmod_pouch_visiblename")
		formBasic:CheckBox(L("Visible HUD", "Visible HUD"), "vrmod_pouch_visiblename_hud")
		formBasic:CheckBox(L("Left Hand Weapon Enable", "Left Hand Weapon Enable"), "vrmod_pouch_lefthandwep_enable")
		formBasic:CheckBox(L("L/R Sync Mode (share slots between hands)", "L/R Sync Mode (share slots between hands)"), "vrmod_pouch_lr_sync")
		formBasic:TextEntry(L("Pickup Sound", "Pickup Sound"), "vrmod_pouch_pickup_sound")

		-- === Release / Tediore ===
		local formRelease = vgui.Create("DForm", scroll)
		formRelease:SetName(L("Release / Tediore", "Release / Tediore"))
		formRelease:Dock(TOP)
		formRelease:DockMargin(5, 5, 5, 5)

		formRelease:CheckBox(L("[release -> Emptyhand] Enable", "[release -> Emptyhand] Enable"), "vrmod_pickupoff_weaponholster")
		formRelease:CheckBox(L("[Tediore like reload] Enable", "[Tediore like reload] Enable"), "vrmod_weapondrop_enable")
		formRelease:CheckBox(L("Trash Weapon on Drop", "Trash Weapon on Drop"), "vrmod_weapondrop_trashwep")

		-- === Dupe Settings ===
		local formDupe = vgui.Create("DForm", scroll)
		formDupe:SetName(L("Dupe Settings", "Dupe Settings"))
		formDupe:Dock(TOP)
		formDupe:DockMargin(5, 5, 5, 5)

		formDupe:CheckBox(L("Reusable Dupe (infinite retrieve)", "Reusable Dupe (infinite retrieve)"), "vrmod_unoff_dupe_reusable")

		-- === Per-Slot Settings ===
		local slotNames = {
			[1] = "Slot 1 - Head Right",
			[2] = "Slot 2 - Head Left",
			[3] = "Slot 3 - Chest Right",
			[4] = "Slot 4 - Chest Left",
			[5] = "Slot 5 - Chest Center",
			[6] = "Slot 6 - Pelvis (Bone)",
			[7] = "Slot 7 - Head (Bone)",
			[8] = "Slot 8 - Spine (Bone)",
		}
		local slotDisplayOrder = {6, 7, 8, 1, 2, 3, 4, 5}

		for _, i in ipairs(slotDisplayOrder) do
			local formSlot = vgui.Create("DForm", scroll)
			formSlot:SetName(slotNames[i])
			formSlot:Dock(TOP)
			formSlot:DockMargin(5, 5, 5, 5)

			formSlot:CheckBox(L("Enable", "Enable"), "vrmod_unoff_pouch_slot_enabled_" .. i)
			formSlot:TextEntry(L("Weapon (Read-only)", "Weapon (Read-only)"), "vrmod_pouch_weapon_" .. i)
			formSlot:TextEntry(L("Left Hand Weapon (Read-only)", "Left Hand Weapon (Read-only)"), "vrmod_pouch_weapon_" .. i .. "_left")
			formSlot:NumSlider(L("Sphere Size", "Sphere Size"), "vrmod_pouch_size_" .. i, 0, 50, 1)

			local shapeCombo = formSlot:ComboBox(L("Shape", "Shape"), "vrmod_unoff_pouch_shape_" .. i)
			shapeCombo:AddChoice("sphere")
			shapeCombo:AddChoice("box")

			formSlot:NumSlider(L("Box Width (X)", "Box Width (X)"), "vrmod_unoff_pouch_box_width_" .. i, 1, 50, 2)
			formSlot:NumSlider(L("Box Height (Y)", "Box Height (Y)"), "vrmod_unoff_pouch_box_height_" .. i, 1, 50, 2)
			formSlot:NumSlider(L("Box Depth Up (Z+)", "Box Depth Up (Z+)"), "vrmod_unoff_pouch_box_depth_up_" .. i, 1, 50, 2)
			formSlot:NumSlider(L("Box Depth Down (Z-)", "Box Depth Down (Z-)"), "vrmod_unoff_pouch_box_depth_down_" .. i, 1, 50, 2)
		end

		-- === Restore Defaults ===
		local resetButton = vgui.Create("DButton", scroll)
		resetButton:SetText(L("Restore Default Settings", "Restore Default Settings"))
		resetButton:Dock(TOP)
		resetButton:DockMargin(5, 10, 5, 10)
		resetButton:SetTall(30)
		resetButton.DoClick = function()
			RunConsoleCommand("vrmod_pouch_enabled", "1")
			RunConsoleCommand("vrmod_pouch_visiblename", "0")
			RunConsoleCommand("vrmod_pouch_visiblename_hud", "1")
			RunConsoleCommand("vrmod_pouch_lefthandwep_enable", "1")
			RunConsoleCommand("vrmod_pouch_lr_sync", "0")
			RunConsoleCommand("vrmod_pouch_pickup_sound", "common/wpn_select.wav")
			RunConsoleCommand("vrmod_pickupoff_weaponholster", "0")
			RunConsoleCommand("vrmod_weapondrop_enable", "0")
			RunConsoleCommand("vrmod_weapondrop_trashwep", "0")
			RunConsoleCommand("vrmod_unoff_dupe_reusable", "1")
			for j = 1, 8 do
				RunConsoleCommand("vrmod_unoff_pouch_slot_enabled_" .. j, "1")
				RunConsoleCommand("vrmod_pouch_size_" .. j, "12")
				RunConsoleCommand("vrmod_unoff_pouch_shape_" .. j, "box")
				RunConsoleCommand("vrmod_unoff_pouch_box_width_" .. j, "22")
				RunConsoleCommand("vrmod_unoff_pouch_box_height_" .. j, "22")
				RunConsoleCommand("vrmod_unoff_pouch_box_depth_up_" .. j, "5")
				RunConsoleCommand("vrmod_unoff_pouch_box_depth_down_" .. j, "5")
			end
		end

		-- Dual-mode registration
		if frame.Settings02Register then
			local success = frame.Settings02Register("holster_type2", "VRHolster2", "icon16/basket.png", panel)
			if not success then
				frame.DPropertySheet:AddSheet("VRHolster2", panel, "icon16/basket.png")
			end
		else
			frame.DPropertySheet:AddSheet("VRHolster2", panel, "icon16/basket.png")
		end

		end) -- pcall end
		if not ok then
			print("[VRMod] Menu hook error (addsettings_holster_type2): " .. tostring(err))
		end
	end
)

hook.Remove("VRMod_Menu", "pVRholstermenutype2")
--------[vrmod_holstermenu_type2.lua]End--------
