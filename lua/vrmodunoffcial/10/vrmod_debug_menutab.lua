--------[vrmod_debug_menutab.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- VRModメニュー統合タブ（コントロール専用）
-- vrmod_unoff_debug=1 のとき表示
-- モニター表示はvrmod_unoff_debug_panelに任せ、
-- ここではON/OFF・モード切替のみ行う
-- ========================================

local Log = vrmod.debug.Log

hook.Add(
	"VRMod_Menu",
	"addsettings_debug_monitor",
	function(frame)
		-- vrmod_unoff_debug ゲート
		local cv = GetConVar("vrmod_unoff_debug")
		if not cv or not cv:GetBool() then return end

		if not frame or not frame.DPropertySheet then return end

		local ok, err = pcall(function()

		local panel = vgui.Create("DPanel", frame.DPropertySheet)
		panel:Dock(FILL)
		panel.Paint = function() end

		local scroll = vgui.Create("DScrollPanel", panel)
		scroll:Dock(FILL)

		-- ========================================
		-- Open Debug Panel ボタン（最上部・大）
		-- ========================================
		local openBtn = vgui.Create("DButton", scroll)
		openBtn:SetText("Open Debug Monitor Panel")
		openBtn:Dock(TOP)
		openBtn:DockMargin(5, 8, 5, 5)
		openBtn:SetTall(35)
		openBtn:SetFont("DermaDefaultBold")
		openBtn.DoClick = function()
			RunConsoleCommand("vrmod_unoff_debug_panel")
		end

		-- ========================================
		-- Core
		-- ========================================
		local coreForm = vgui.Create("DForm", scroll)
		coreForm:SetName("Core")
		coreForm:Dock(TOP)
		coreForm:DockMargin(5, 5, 5, 0)

		coreForm:CheckBox("Hook Monitoring", "vrmod_unoff_debug_hooks")
		coreForm:NumSlider("Log Level", "vrmod_unoff_debug_loglevel", 0, 4, 0)

		-- ========================================
		-- Key & Input
		-- ========================================
		local keyForm = vgui.Create("DForm", scroll)
		keyForm:SetName("Key & Input")
		keyForm:Dock(TOP)
		keyForm:DockMargin(5, 5, 5, 0)

		keyForm:CheckBox("Key Monitor Auto-Start", "vrmod_unoff_debug_keymon")

		-- ========================================
		-- Mock VR
		-- ========================================
		local mockForm = vgui.Create("DForm", scroll)
		mockForm:SetName("Mock VR")
		mockForm:Dock(TOP)
		mockForm:DockMargin(5, 5, 5, 0)

		mockForm:CheckBox("Enable Mock Mode", "vrmod_unoff_debug_mock")
		mockForm:NumSlider("Hand Distance", "vrmod_unoff_debug_mock_hand_dist", 5, 60, 0)
		mockForm:NumSlider("Hand Drop", "vrmod_unoff_debug_mock_hand_drop", 5, 60, 0)

		-- ========================================
		-- Tracking
		-- ========================================
		local trackForm = vgui.Create("DForm", scroll)
		trackForm:SetName("Tracking")
		trackForm:Dock(TOP)
		trackForm:DockMargin(5, 5, 5, 5)

		trackForm:CheckBox("Auto-Record on VR Start", "vrmod_unoff_debug_mock_autorecord")
		trackForm:NumSlider("Track Rate (Hz)", "vrmod_unoff_debug_mock_trackrate", 5, 30, 0)

		-- ========================================
		-- Dual-mode registration
		-- ========================================
		if frame.Settings02Register then
			local success = frame.Settings02Register("debug", "Debug", "icon16/bug.png", panel)
			if not success then
				frame.DPropertySheet:AddSheet("Debug", panel, "icon16/bug.png")
			end
		else
			frame.DPropertySheet:AddSheet("Debug", panel, "icon16/bug.png")
		end

		end) -- pcall end
		if not ok then
			print("[VRMod] Menu hook error (addsettings_debug_monitor): " .. tostring(err))
		end
	end
)

Log.Info("menutab", "VRMod debug menu tab registered")

--------[vrmod_debug_menutab.lua]End--------
