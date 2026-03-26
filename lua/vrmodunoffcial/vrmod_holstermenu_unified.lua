--------[vrmod_holstermenu_unified.lua]Start--------
AddCSLuaFile()
if SERVER then return end

local convars, convarValues = vrmod.GetConvars()

hook.Add(
	"VRMod_Menu",
	"addsettingsholster",
	function(frame)
		if not frame.pickupSheet then return end
		local sheet = vgui.Create("DPropertySheet", frame.pickupSheet)
		frame.pickupSheet:AddSheet("VRHolster", sheet)
		sheet:Dock(FILL)

		-- S20 Problem 6: Type2を最初に表示（Type1より使いやすいため）
		-- Type2 Settings Tab
		local type2Tab = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Type2", type2Tab, "icon16/basket.png")
		type2Tab.Paint = function(self, w, h) end

		local scrollPanel2 = vgui.Create("DScrollPanel", type2Tab)
		scrollPanel2:Dock(FILL)

		local form2 = vgui.Create("DForm", scrollPanel2)
		form2:SetName("Type2 Holster Settings")
		form2:Dock(TOP)
		form2:DockMargin(5, 5, 5, 5)
		form2.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Basic Settings
		local basicCategory = form2:Help("=== Basic Settings ===")
		basicCategory:SetFont("DermaDefaultBold")
		form2:CheckBox("System Enable", "vrmod_pouch_enabled")
		form2:CheckBox("Visible Name", "vrmod_pouch_visiblename")
		form2:CheckBox("Visible HUD", "vrmod_pouch_visiblename_hud")
		form2:CheckBox("Left Hand Weapon Enable", "vrmod_pouch_lefthandwep_enable")
		form2:CheckBox("L/R Sync Mode (share slots between hands)", "vrmod_pouch_lr_sync")
		form2:TextEntry("Pickup Sound", "vrmod_pouch_pickup_sound")

		-- Release / Tediore Settings
		local releaseCategory = form2:Help("=== Release / Tediore ===")
		releaseCategory:SetFont("DermaDefaultBold")
		form2:CheckBox("[release -> Emptyhand] Enable", "vrmod_pickupoff_weaponholster")
		form2:CheckBox("[Tediore like reload] Enable", "vrmod_weapondrop_enable")
		form2:CheckBox("Trash Weapon on Drop", "vrmod_weapondrop_trashwep")

		-- Dupe Settings
		local dupeCategory = form2:Help("=== Dupe Settings ===")
		dupeCategory:SetFont("DermaDefaultBold")
		form2:CheckBox("Reusable Dupe (infinite retrieve)", "vrmod_unoff_dupe_reusable")

		-- S20 Problem 3: スロット6-8（使いやすい）を最初に表示
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
			local slotCategory = form2:Help("=== " .. slotNames[i] .. " ===")
			slotCategory:SetFont("DermaDefaultBold")
			form2:CheckBox("Enable", "vrmod_unoff_pouch_slot_enabled_" .. i)
			form2:TextEntry("Weapon/Entity (Read-only)", "vrmod_pouch_weapon_" .. i)
			-- S20 Problem 1+2: 全スロットで左手用武器表示
			form2:TextEntry("Left Hand Weapon (Read-only)", "vrmod_pouch_weapon_" .. i .. "_left")
			form2:NumSlider("Sphere Size", "vrmod_pouch_size_" .. i, 0, 50, 1)

			local shapeCombo = form2:ComboBox("Shape", "vrmod_unoff_pouch_shape_" .. i)
			shapeCombo:AddChoice("sphere")
			shapeCombo:AddChoice("box")

			form2:NumSlider("Box Width (X)", "vrmod_unoff_pouch_box_width_" .. i, 1, 50, 2)
			form2:NumSlider("Box Height (Y)", "vrmod_unoff_pouch_box_height_" .. i, 1, 50, 2)
			form2:NumSlider("Box Depth Up (Z+)", "vrmod_unoff_pouch_box_depth_up_" .. i, 1, 50, 2)
			form2:NumSlider("Box Depth Down (Z-)", "vrmod_unoff_pouch_box_depth_down_" .. i, 1, 50, 2)
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
		sheet:AddSheet("Type1", type1Tab, "icon16/package.png")
		type1Tab.Paint = function(self, w, h) end

		local scrollPanel1 = vgui.Create("DScrollPanel", type1Tab)
		scrollPanel1:Dock(FILL)

		-- Type1 Right Hand Settings
		local form1Right = vgui.Create("DForm", scrollPanel1)
		form1Right:SetName("Right Hand Holster Settings")
		form1Right:Dock(TOP)
		form1Right:DockMargin(5, 5, 5, 5)
		form1Right.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Pelvis
		local pelvisCategory = form1Right:Help("=== Pelvis Holster ===")
		pelvisCategory:SetFont("DermaDefaultBold")
		form1Right:CheckBox("Enable Pelvis Holster", "vrmod_weppouch_Pelvis")
		form1Right:NumSlider("Range", "vrmod_weppouch_dist_Pelvis", 0, 100, 1)
		form1Right:CheckBox("Weapon Lock (Read-only)", "vrmod_weppouch_weapon_lock_Pelvis")
		form1Right:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_Pelvis")
		local customPelvisEnable = form1Right:CheckBox("Enable Custom Command", "vrmod_weppouch_customcvar_pelvis_enable")
		form1Right:TextEntry("Custom Pickup Command", "vrmod_weppouch_customcvar_pelvis_cmd")
		form1Right:TextEntry("Custom Put Command", "vrmod_weppouch_customcvar_pelvis_put_cmd")

		-- Head
		local headCategory = form1Right:Help("=== Head Holster ===")
		headCategory:SetFont("DermaDefaultBold")
		form1Right:CheckBox("Enable Head Holster", "vrmod_weppouch_Head")
		form1Right:NumSlider("Range", "vrmod_weppouch_dist_head", 0, 100, 1)
		form1Right:CheckBox("Weapon Lock (Read-only)", "vrmod_weppouch_weapon_lock_Head")
		form1Right:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_Head")
		local customHeadEnable = form1Right:CheckBox("Enable Custom Command", "vrmod_weppouch_customcvar_head_enable")
		form1Right:TextEntry("Custom Pickup Command", "vrmod_weppouch_customcvar_head_cmd")
		form1Right:TextEntry("Custom Put Command", "vrmod_weppouch_customcvar_head_put_cmd")

		-- Spine
		local spineCategory = form1Right:Help("=== Spine Holster ===")
		spineCategory:SetFont("DermaDefaultBold")
		form1Right:CheckBox("Enable Spine Holster", "vrmod_weppouch_Spine")
		form1Right:NumSlider("Range", "vrmod_weppouch_dist_spine", 0, 100, 1)
		form1Right:CheckBox("Weapon Lock (Read-only)", "vrmod_weppouch_weapon_lock_Spine")
		form1Right:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_Spine")
		local customSpineEnable = form1Right:CheckBox("Enable Custom Command", "vrmod_weppouch_customcvar_spine_enable")
		form1Right:TextEntry("Custom Pickup Command", "vrmod_weppouch_customcvar_spine_cmd")
		form1Right:TextEntry("Custom Put Command", "vrmod_weppouch_customcvar_spine_put_cmd")

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
		form1Left:SetName("Left Hand Holster Settings")
		form1Left:Dock(TOP)
		form1Left:DockMargin(5, 5, 5, 5)
		form1Left.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Pelvis Left
		local pelvisCategoryLeft = form1Left:Help("=== Pelvis Holster (Left) ===")
		pelvisCategoryLeft:SetFont("DermaDefaultBold")
		form1Left:CheckBox("Enable Pelvis Holster", "vrmod_weppouch_left_Pelvis")
		form1Left:NumSlider("Range", "vrmod_weppouch_dist_Pelvis_left", 0, 100, 1)
		form1Left:CheckBox("Weapon Lock (Read-only)", "vrmod_weppouch_weapon_lock_left_Pelvis")
		form1Left:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_left_Pelvis")

		-- Head Left
		local headCategoryLeft = form1Left:Help("=== Head Holster (Left) ===")
		headCategoryLeft:SetFont("DermaDefaultBold")
		form1Left:CheckBox("Enable Head Holster", "vrmod_weppouch_left_Head")
		form1Left:NumSlider("Range", "vrmod_weppouch_dist_head_left", 0, 100, 1)
		form1Left:CheckBox("Weapon Lock (Read-only)", "vrmod_weppouch_weapon_lock_left_Head")
		form1Left:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_left_Head")

		-- Spine Left
		local spineCategoryLeft = form1Left:Help("=== Spine Holster (Left) ===")
		spineCategoryLeft:SetFont("DermaDefaultBold")
		form1Left:CheckBox("Enable Spine Holster", "vrmod_weppouch_left_Spine")
		form1Left:NumSlider("Range", "vrmod_weppouch_dist_spine_left", 0, 100, 1)
		form1Left:CheckBox("Weapon Lock (Read-only)", "vrmod_weppouch_weapon_lock_left_Spine")
		form1Left:TextEntry("Stored Weapon (Read-only)", "vrmod_weppouch_weapon_left_Spine")

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
		sheet:AddSheet("Display", displayTab, "icon16/eye.png")
		displayTab.Paint = function(self, w, h) end

		local scrollPanel3 = vgui.Create("DScrollPanel", displayTab)
		scrollPanel3:Dock(FILL)

		local form3 = vgui.Create("DForm", scrollPanel3)
		form3:SetName("Display Settings (Type1/Type2 Common)")
		form3:Dock(TOP)
		form3:DockMargin(5, 5, 5, 5)
		form3.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Type1 Display
		local type1DisplayCategory = form3:Help("=== Type1 Display ===")
		type1DisplayCategory:SetFont("DermaDefaultBold")
		form3:CheckBox("Visible Range", "vrmod_weppouch_visiblerange")
		form3:CheckBox("Visible Name", "vrmod_weppouch_visiblename")
		form3:CheckBox("Head Visible", "vrmod_head_visible")

		-- Type1 Left Display
		local type1LeftDisplayCategory = form3:Help("=== Type1 Left Display ===")
		type1LeftDisplayCategory:SetFont("DermaDefaultBold")
		form3:CheckBox("Visible Range (Left)", "vrmod_weppouch_visiblerange_left")
		form3:CheckBox("Visible Name (Left)", "vrmod_weppouch_visiblename_left")
	end
)

hook.Remove("VRMod_Menu", "vrmod_holster_menu_type1")
hook.Remove("VRMod_Menu", "vrmod_holster_menu_type2")
hook.Remove("VRMod_Menu", "pVRholstermenutype2")
--------[vrmod_holstermenu_unified.lua]End--------
