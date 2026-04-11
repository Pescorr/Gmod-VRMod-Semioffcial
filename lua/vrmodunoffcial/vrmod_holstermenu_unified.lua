--------[vrmod_holstermenu_unified.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local L = VRModL or function(_, fb) return fb or "" end

local convars, convarValues = vrmod.GetConvars()

hook.Add(
	"VRMod_Menu",
	"addsettingsholster",
	function(frame)
		if not frame or not frame.DPropertySheet then return end

		local ok, err = pcall(function()
		local sheet = vgui.Create("DPropertySheet")
		sheet:Dock(FILL)

		-- S20 Problem 6: Type2を最初に表示（Type1より使いやすいため）
		-- Type2 Settings Tab
		local type2Tab = vgui.Create("DPanel", sheet)
		sheet:AddSheet(L("Type2", "Type2"), type2Tab, "icon16/basket.png")
		type2Tab.Paint = function(self, w, h) end

		local scrollPanel2 = vgui.Create("DScrollPanel", type2Tab)
		scrollPanel2:Dock(FILL)

		local form2 = vgui.Create("DForm", scrollPanel2)
		form2:SetName(L("Type2 Holster Settings", "Type2 Holster Settings"))
		form2:Dock(TOP)
		form2:DockMargin(5, 5, 5, 5)
		form2.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Basic Settings
		local basicCategory = form2:Help(L("=== Basic Settings ===", "=== Basic Settings ==="))
		basicCategory:SetFont("DermaDefaultBold")
		form2:CheckBox(L("System Enable", "System Enable"), "vrmod_pouch_enabled")
		form2:CheckBox(L("Visible Name", "Visible Name"), "vrmod_pouch_visiblename")
		form2:CheckBox(L("Visible HUD", "Visible HUD"), "vrmod_pouch_visiblename_hud")
		form2:CheckBox(L("Left Hand Weapon Enable", "Left Hand Weapon Enable"), "vrmod_pouch_lefthandwep_enable")
		form2:CheckBox(L("L/R Sync Mode (share slots between hands)", "L/R Sync Mode (share slots between hands)"), "vrmod_pouch_lr_sync")
		form2:TextEntry(L("Pickup Sound", "Pickup Sound"), "vrmod_pouch_pickup_sound")

		-- Release / Tediore Settings
		local releaseCategory = form2:Help(L("=== Release / Tediore ===", "=== Release / Tediore ==="))
		releaseCategory:SetFont("DermaDefaultBold")
		form2:CheckBox(L("[release -> Emptyhand] Enable", "[release -> Emptyhand] Enable"), "vrmod_pickupoff_weaponholster")
		form2:CheckBox(L("[Tediore like reload] Enable", "[Tediore like reload] Enable"), "vrmod_weapondrop_enable")
		form2:CheckBox(L("Trash Weapon on Drop", "Trash Weapon on Drop"), "vrmod_weapondrop_trashwep")

		-- Dupe Settings
		local dupeCategory = form2:Help(L("=== Dupe Settings ===", "=== Dupe Settings ==="))
		dupeCategory:SetFont("DermaDefaultBold")
		form2:CheckBox(L("Reusable Dupe (infinite retrieve)", "Reusable Dupe (infinite retrieve)"), "vrmod_unoff_dupe_reusable")

		-- S20 Problem 3: スロット6-8（使いやすい）を最初に表示
		local slotNames = {
			[1] = L("Slot 1 - Head Right", "Slot 1 - Head Right"),
			[2] = L("Slot 2 - Head Left", "Slot 2 - Head Left"),
			[3] = L("Slot 3 - Chest Right", "Slot 3 - Chest Right"),
			[4] = L("Slot 4 - Chest Left", "Slot 4 - Chest Left"),
			[5] = L("Slot 5 - Chest Center", "Slot 5 - Chest Center"),
			[6] = L("Slot 6 - Pelvis (Bone)", "Slot 6 - Pelvis (Bone)"),
			[7] = L("Slot 7 - Head (Bone)", "Slot 7 - Head (Bone)"),
			[8] = L("Slot 8 - Spine (Bone)", "Slot 8 - Spine (Bone)"),
		}
		local slotDisplayOrder = {6, 7, 8, 1, 2, 3, 4, 5}
		for _, i in ipairs(slotDisplayOrder) do
			local slotCategory = form2:Help("=== " .. slotNames[i] .. " ===")
			slotCategory:SetFont("DermaDefaultBold")
			form2:CheckBox(L("Enable", "Enable"), "vrmod_unoff_pouch_slot_enabled_" .. i)
			form2:TextEntry(L("Weapon/Entity (Read-only)", "Weapon/Entity (Read-only)"), "vrmod_pouch_weapon_" .. i)
			-- S20 Problem 1+2: 全スロットで左手用武器表示
			form2:TextEntry(L("Left Hand Weapon (Read-only)", "Left Hand Weapon (Read-only)"), "vrmod_pouch_weapon_" .. i .. "_left")
			form2:NumSlider(L("Sphere Size", "Sphere Size"), "vrmod_pouch_size_" .. i, 0, 50, 1)

			local shapeCombo = form2:ComboBox(L("Shape", "Shape"), "vrmod_unoff_pouch_shape_" .. i)
			shapeCombo:AddChoice(L("sphere", "sphere"))
			shapeCombo:AddChoice(L("box", "box"))

			form2:NumSlider(L("Box Width (X)", "Box Width (X)"), "vrmod_unoff_pouch_box_width_" .. i, 1, 50, 2)
			form2:NumSlider(L("Box Height (Y)", "Box Height (Y)"), "vrmod_unoff_pouch_box_height_" .. i, 1, 50, 2)
			form2:NumSlider(L("Box Depth Up (Z+)", "Box Depth Up (Z+)"), "vrmod_unoff_pouch_box_depth_up_" .. i, 1, 50, 2)
			form2:NumSlider(L("Box Depth Down (Z-)", "Box Depth Down (Z-)"), "vrmod_unoff_pouch_box_depth_down_" .. i, 1, 50, 2)
		end

		-- Restore Defaults
		local resetButton2 = vgui.Create("DButton", scrollPanel2)
		resetButton2:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
		resetButton2:Dock(TOP)
		resetButton2:DockMargin(5, 5, 5, 5)
		resetButton2:SetTall(30)
		resetButton2.DoClick = function()
			VRModResetCategory("holster_type2")
		end

		-- Type1 Settings Tab (legacy, Type2の後に配置)
		local type1Tab = vgui.Create("DPanel", sheet)
		sheet:AddSheet(L("Type1", "Type1"), type1Tab, "icon16/package.png")
		type1Tab.Paint = function(self, w, h) end

		local scrollPanel1 = vgui.Create("DScrollPanel", type1Tab)
		scrollPanel1:Dock(FILL)

		-- Type1 Right Hand Settings
		local form1Right = vgui.Create("DForm", scrollPanel1)
		form1Right:SetName(L("Right Hand Holster Settings", "Right Hand Holster Settings"))
		form1Right:Dock(TOP)
		form1Right:DockMargin(5, 5, 5, 5)
		form1Right.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Pelvis
		local pelvisCategory = form1Right:Help(L("=== Pelvis Holster ===", "=== Pelvis Holster ==="))
		pelvisCategory:SetFont("DermaDefaultBold")
		form1Right:CheckBox(L("Enable Pelvis Holster", "Enable Pelvis Holster"), "vrmod_weppouch_Pelvis")
		form1Right:NumSlider(L("Range", "Range"), "vrmod_weppouch_dist_Pelvis", 0, 100, 1)
		form1Right:CheckBox(L("Weapon Lock (Read-only)", "Weapon Lock (Read-only)"), "vrmod_weppouch_weapon_lock_Pelvis")
		form1Right:TextEntry(L("Stored Weapon (Read-only)", "Stored Weapon (Read-only)"), "vrmod_weppouch_weapon_Pelvis")
		local customPelvisEnable = form1Right:CheckBox(L("Enable Custom Command", "Enable Custom Command"), "vrmod_weppouch_customcvar_pelvis_enable")
		form1Right:TextEntry(L("Custom Pickup Command", "Custom Pickup Command"), "vrmod_weppouch_customcvar_pelvis_cmd")
		form1Right:TextEntry(L("Custom Put Command", "Custom Put Command"), "vrmod_weppouch_customcvar_pelvis_put_cmd")

		-- Head
		local headCategory = form1Right:Help(L("=== Head Holster ===", "=== Head Holster ==="))
		headCategory:SetFont("DermaDefaultBold")
		form1Right:CheckBox(L("Enable Head Holster", "Enable Head Holster"), "vrmod_weppouch_Head")
		form1Right:NumSlider(L("Range", "Range"), "vrmod_weppouch_dist_head", 0, 100, 1)
		form1Right:CheckBox(L("Weapon Lock (Read-only)", "Weapon Lock (Read-only)"), "vrmod_weppouch_weapon_lock_Head")
		form1Right:TextEntry(L("Stored Weapon (Read-only)", "Stored Weapon (Read-only)"), "vrmod_weppouch_weapon_Head")
		local customHeadEnable = form1Right:CheckBox(L("Enable Custom Command", "Enable Custom Command"), "vrmod_weppouch_customcvar_head_enable")
		form1Right:TextEntry(L("Custom Pickup Command", "Custom Pickup Command"), "vrmod_weppouch_customcvar_head_cmd")
		form1Right:TextEntry(L("Custom Put Command", "Custom Put Command"), "vrmod_weppouch_customcvar_head_put_cmd")

		-- Spine
		local spineCategory = form1Right:Help(L("=== Spine Holster ===", "=== Spine Holster ==="))
		spineCategory:SetFont("DermaDefaultBold")
		form1Right:CheckBox(L("Enable Spine Holster", "Enable Spine Holster"), "vrmod_weppouch_Spine")
		form1Right:NumSlider(L("Range", "Range"), "vrmod_weppouch_dist_spine", 0, 100, 1)
		form1Right:CheckBox(L("Weapon Lock (Read-only)", "Weapon Lock (Read-only)"), "vrmod_weppouch_weapon_lock_Spine")
		form1Right:TextEntry(L("Stored Weapon (Read-only)", "Stored Weapon (Read-only)"), "vrmod_weppouch_weapon_Spine")
		local customSpineEnable = form1Right:CheckBox(L("Enable Custom Command", "Enable Custom Command"), "vrmod_weppouch_customcvar_spine_enable")
		form1Right:TextEntry(L("Custom Pickup Command", "Custom Pickup Command"), "vrmod_weppouch_customcvar_spine_cmd")
		form1Right:TextEntry(L("Custom Put Command", "Custom Put Command"), "vrmod_weppouch_customcvar_spine_put_cmd")

		-- Restore Defaults
		local resetButton1Right = vgui.Create("DButton", scrollPanel1)
		resetButton1Right:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
		resetButton1Right:Dock(TOP)
		resetButton1Right:DockMargin(5, 5, 5, 5)
		resetButton1Right:SetTall(30)
		resetButton1Right.DoClick = function()
			VRModResetCategory("holster_type1_right")
		end

		-- Type1 Left Hand Settings
		local form1Left = vgui.Create("DForm", scrollPanel1)
		form1Left:SetName(L("Left Hand Holster Settings", "Left Hand Holster Settings"))
		form1Left:Dock(TOP)
		form1Left:DockMargin(5, 5, 5, 5)
		form1Left.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Pelvis Left
		local pelvisCategoryLeft = form1Left:Help(L("=== Pelvis Holster (Left) ===", "=== Pelvis Holster (Left) ==="))
		pelvisCategoryLeft:SetFont("DermaDefaultBold")
		form1Left:CheckBox(L("Enable Pelvis Holster", "Enable Pelvis Holster"), "vrmod_weppouch_left_Pelvis")
		form1Left:NumSlider(L("Range", "Range"), "vrmod_weppouch_dist_Pelvis_left", 0, 100, 1)
		form1Left:CheckBox(L("Weapon Lock (Read-only)", "Weapon Lock (Read-only)"), "vrmod_weppouch_weapon_lock_left_Pelvis")
		form1Left:TextEntry(L("Stored Weapon (Read-only)", "Stored Weapon (Read-only)"), "vrmod_weppouch_weapon_left_Pelvis")

		-- Head Left
		local headCategoryLeft = form1Left:Help(L("=== Head Holster (Left) ===", "=== Head Holster (Left) ==="))
		headCategoryLeft:SetFont("DermaDefaultBold")
		form1Left:CheckBox(L("Enable Head Holster", "Enable Head Holster"), "vrmod_weppouch_left_Head")
		form1Left:NumSlider(L("Range", "Range"), "vrmod_weppouch_dist_head_left", 0, 100, 1)
		form1Left:CheckBox(L("Weapon Lock (Read-only)", "Weapon Lock (Read-only)"), "vrmod_weppouch_weapon_lock_left_Head")
		form1Left:TextEntry(L("Stored Weapon (Read-only)", "Stored Weapon (Read-only)"), "vrmod_weppouch_weapon_left_Head")

		-- Spine Left
		local spineCategoryLeft = form1Left:Help(L("=== Spine Holster (Left) ===", "=== Spine Holster (Left) ==="))
		spineCategoryLeft:SetFont("DermaDefaultBold")
		form1Left:CheckBox(L("Enable Spine Holster", "Enable Spine Holster"), "vrmod_weppouch_left_Spine")
		form1Left:NumSlider(L("Range", "Range"), "vrmod_weppouch_dist_spine_left", 0, 100, 1)
		form1Left:CheckBox(L("Weapon Lock (Read-only)", "Weapon Lock (Read-only)"), "vrmod_weppouch_weapon_lock_left_Spine")
		form1Left:TextEntry(L("Stored Weapon (Read-only)", "Stored Weapon (Read-only)"), "vrmod_weppouch_weapon_left_Spine")

		-- Restore Defaults
		local resetButton1Left = vgui.Create("DButton", scrollPanel1)
		resetButton1Left:SetText(VRModL("btn_restore_defaults", "Restore Default Settings (Left)"))
		resetButton1Left:Dock(TOP)
		resetButton1Left:DockMargin(5, 5, 5, 5)
		resetButton1Left:SetTall(30)
		resetButton1Left.DoClick = function()
			VRModResetCategory("holster_type1_left")
		end

		-- Display Settings Tab
		local displayTab = vgui.Create("DPanel", sheet)
		sheet:AddSheet(L("Display", "Display"), displayTab, "icon16/eye.png")
		displayTab.Paint = function(self, w, h) end

		local scrollPanel3 = vgui.Create("DScrollPanel", displayTab)
		scrollPanel3:Dock(FILL)

		local form3 = vgui.Create("DForm", scrollPanel3)
		form3:SetName(L("Display Settings (Type1/Type2 Common)", "Display Settings (Type1/Type2 Common)"))
		form3:Dock(TOP)
		form3:DockMargin(5, 5, 5, 5)
		form3.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Type1 Display
		local type1DisplayCategory = form3:Help(L("=== Type1 Display ===", "=== Type1 Display ==="))
		type1DisplayCategory:SetFont("DermaDefaultBold")
		form3:CheckBox(L("Visible Range", "Visible Range"), "vrmod_weppouch_visiblerange")
		form3:CheckBox(L("Visible Name", "Visible Name"), "vrmod_weppouch_visiblename")
		form3:CheckBox(L("Head Visible", "Head Visible"), "vrmod_head_visible")

		-- Type1 Left Display
		local type1LeftDisplayCategory = form3:Help(L("=== Type1 Left Display ===", "=== Type1 Left Display ==="))
		type1LeftDisplayCategory:SetFont("DermaDefaultBold")
		form3:CheckBox(L("Visible Range (Left)", "Visible Range (Left)"), "vrmod_weppouch_visiblerange_left")
		form3:CheckBox(L("Visible Name (Left)", "Visible Name (Left)"), "vrmod_weppouch_visiblename_left")

		-- Dual-mode registration
		if frame.Settings02Register then
			local success = frame.Settings02Register("holster", L("VRHolster", "VRHolster"), "icon16/basket.png", sheet)
			if not success then
				frame.DPropertySheet:AddSheet(L("VRHolster", "VRHolster"), sheet, "icon16/basket.png")
			end
		else
			frame.DPropertySheet:AddSheet(L("VRHolster", "VRHolster"), sheet, "icon16/basket.png")
		end

		end) -- pcall end
		if not ok then
			print("[VRMod] Menu hook error (addsettingsholster): " .. tostring(err))
		end
	end
)

hook.Remove("VRMod_Menu", "vrmod_holster_menu_type1")
hook.Remove("VRMod_Menu", "vrmod_holster_menu_type2")
hook.Remove("VRMod_Menu", "pVRholstermenutype2")
--------[vrmod_holstermenu_unified.lua]End--------
