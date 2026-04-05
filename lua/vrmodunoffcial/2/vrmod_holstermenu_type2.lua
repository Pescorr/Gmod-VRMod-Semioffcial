--------[vrmod_holstermenu_type2.lua]Start--------
AddCSLuaFile()
if SERVER then return end

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
		formBasic:SetName("Basic Settings")
		formBasic:Dock(TOP)
		formBasic:DockMargin(5, 5, 5, 5)

		formBasic:CheckBox("System Enable", "vrmod_pouch_enabled")
		formBasic:CheckBox("Visible Name (3D)", "vrmod_pouch_visiblename")
		formBasic:CheckBox("Visible HUD", "vrmod_pouch_visiblename_hud")
		formBasic:CheckBox("Left Hand Weapon Enable", "vrmod_pouch_lefthandwep_enable")
		formBasic:CheckBox("L/R Sync Mode (share slots between hands)", "vrmod_pouch_lr_sync")
		formBasic:TextEntry("Pickup Sound", "vrmod_pouch_pickup_sound")

		-- === Release / Tediore ===
		local formRelease = vgui.Create("DForm", scroll)
		formRelease:SetName("Release / Tediore")
		formRelease:Dock(TOP)
		formRelease:DockMargin(5, 5, 5, 5)

		formRelease:CheckBox("[release -> Emptyhand] Enable", "vrmod_pickupoff_weaponholster")
		formRelease:CheckBox("[Tediore like reload] Enable", "vrmod_weapondrop_enable")
		formRelease:CheckBox("Trash Weapon on Drop", "vrmod_weapondrop_trashwep")

		-- === Dupe Settings ===
		local formDupe = vgui.Create("DForm", scroll)
		formDupe:SetName("Dupe Settings")
		formDupe:Dock(TOP)
		formDupe:DockMargin(5, 5, 5, 5)

		formDupe:CheckBox("Reusable Dupe (infinite retrieve)", "vrmod_unoff_dupe_reusable")

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

			formSlot:CheckBox("Enable", "vrmod_unoff_pouch_slot_enabled_" .. i)
			formSlot:TextEntry("Weapon (Read-only)", "vrmod_pouch_weapon_" .. i)
			formSlot:TextEntry("Left Hand Weapon (Read-only)", "vrmod_pouch_weapon_" .. i .. "_left")
			formSlot:NumSlider("Sphere Size", "vrmod_pouch_size_" .. i, 0, 50, 1)

			local shapeCombo = formSlot:ComboBox("Shape", "vrmod_unoff_pouch_shape_" .. i)
			shapeCombo:AddChoice("sphere")
			shapeCombo:AddChoice("box")

			formSlot:NumSlider("Box Width (X)", "vrmod_unoff_pouch_box_width_" .. i, 1, 50, 2)
			formSlot:NumSlider("Box Height (Y)", "vrmod_unoff_pouch_box_height_" .. i, 1, 50, 2)
			formSlot:NumSlider("Box Depth Up (Z+)", "vrmod_unoff_pouch_box_depth_up_" .. i, 1, 50, 2)
			formSlot:NumSlider("Box Depth Down (Z-)", "vrmod_unoff_pouch_box_depth_down_" .. i, 1, 50, 2)
		end

		-- === Restore Defaults ===
		local resetButton = vgui.Create("DButton", scroll)
		resetButton:SetText("Restore Default Settings")
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
