--------[vrmod_debugmenu.lua]Start--------
AddCSLuaFile()
if SERVER then return end

local convars, convarValues = vrmod.GetConvars()

-- Create developer mode ConVar
CreateClientConVar("vrmod_unoff_developer_mode", "0", true, FCVAR_ARCHIVE, "Enable developer mode for advanced settings", 0, 1)

hook.Add(
	"VRMod_Menu",
	"addsettingsdebug",
	function(frame)
		-- VRDebug root tab disabled: items redistributed into debug tab in Settings02
		-- Test handles → debug > Test > vehiclemode
		-- Emergency stop → VRStop Key in VRplay
		-- Error handling → debug > Settings
		-- Debug Monitor → debug > Debug Monitor (separate module)
		return
		sheet:Dock(FILL)

		-- Test Settings Tab
		local testTab = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Test", testTab, "icon16/bug.png")
		testTab.Paint = function(self, w, h) end

		local scrollPanel1 = vgui.Create("DScrollPanel", testTab)
		scrollPanel1:Dock(FILL)

		local form1 = vgui.Create("DForm", scrollPanel1)
		form1:SetName("Test Settings")
		form1:Dock(TOP)
		form1:DockMargin(5, 5, 5, 5)
		form1.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		form1:CheckBox("Test Right Handle", "vrmod_test_Righthandle")
		form1:CheckBox("Test Left Handle", "vrmod_test_lefthandle")

		-- Restore Defaults
		local resetButton1 = vgui.Create("DButton", scrollPanel1)
		resetButton1:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
		resetButton1:Dock(TOP)
		resetButton1:DockMargin(5, 5, 5, 5)
		resetButton1:SetTall(30)
		resetButton1.DoClick = function()
			VRModResetCategory("developer")
		end

		-- Emergency Stop Tab
		local emergencyTab = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Emergency", emergencyTab, "icon16/exclamation.png")
		emergencyTab.Paint = function(self, w, h) end

		local scrollPanel2 = vgui.Create("DScrollPanel", emergencyTab)
		scrollPanel2:Dock(FILL)

		local form2 = vgui.Create("DForm", scrollPanel2)
		form2:SetName("Emergency Stop Settings")
		form2:Dock(TOP)
		form2:DockMargin(5, 5, 5, 5)
		form2.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		form2:NumSlider("Emergency Stop Hold Time", "vrmod_emergencystop_time", 0, 10, 2)

		-- Error Handling Tab
		local errorTab = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Error", errorTab, "icon16/error.png")
		errorTab.Paint = function(self, w, h) end

		local scrollPanel3 = vgui.Create("DScrollPanel", errorTab)
		scrollPanel3:Dock(FILL)

		local form3 = vgui.Create("DForm", scrollPanel3)
		form3:SetName("Error Handling Settings")
		form3:Dock(TOP)
		form3:DockMargin(5, 5, 5, 5)
		form3.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		form3:CheckBox("Error Hard Mode", "vrmod_error_hard")

		-- Debug Monitor ボタン（デバッグシステム有効時のみ）
		if vrmod.debug and vrmod.debug.enabled then
			local debugMonTab = vgui.Create("DPanel", sheet)
			sheet:AddSheet("Monitor", debugMonTab, "icon16/monitor.png")
			debugMonTab.Paint = function(self, w, h) end

			local scrollPanel4 = vgui.Create("DScrollPanel", debugMonTab)
			scrollPanel4:Dock(FILL)

			local form4 = vgui.Create("DForm", scrollPanel4)
			form4:SetName("Debug Monitor")
			form4:Dock(TOP)
			form4:DockMargin(5, 5, 5, 5)

			local openBtn = form4:Button("Open Debug Monitor Panel")
			openBtn.DoClick = function()
				RunConsoleCommand("vrmod_unoff_debug_panel")
			end

			local recBtn = form4:Button("Start/Stop Recording")
			recBtn.DoClick = function()
				if vrmod.debug.export and vrmod.debug.export.IsRecording() then
					vrmod.debug.export.StopRecording()
				elseif vrmod.debug.export then
					vrmod.debug.export.StartRecording()
				end
			end

			local exportBtn = form4:Button("Export Session Data")
			exportBtn.DoClick = function()
				if vrmod.debug.export then
					vrmod.debug.export.ExportJSON()
				end
			end
		end
	end
)

--------[vrmod_debugmenu.lua]End--------
