--------[vrmod_debug_menutab.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- VRModメニュー統合タブ
-- ========================================

local Log = vrmod.debug.Log

hook.Add(
	"VRMod_Menu",
	"addsettings_debug_monitor",
	function(frame)
		-- developer_modeゲート
		local devMode = GetConVar("vrmod_unoff_developer_mode")
		if not devMode or not devMode:GetBool() then return end

		if not frame.debugSheet then return end
		local sheet = vgui.Create("DPropertySheet", frame.debugSheet)
		frame.debugSheet:AddSheet("Debug Monitor", sheet)
		sheet:Dock(FILL)

		-- サマリータブ
		local summaryTab = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Summary", summaryTab, "icon16/information.png")
		summaryTab.Paint = function(self, w, h) end

		local scrollPanel = vgui.Create("DScrollPanel", summaryTab)
		scrollPanel:Dock(FILL)

		local form = vgui.Create("DForm", scrollPanel)
		form:SetName("Debug System Status")
		form:Dock(TOP)
		form:DockMargin(5, 5, 5, 5)

		-- ステータス表示
		local statusLabel = vgui.Create("DLabel", form)
		statusLabel:SetText("Debug System: ACTIVE")
		statusLabel:SetFont("DermaDefaultBold")
		statusLabel:SetTextColor(Color(100, 255, 100))
		statusLabel:Dock(TOP)
		statusLabel:DockMargin(5, 5, 5, 0)

		local hooksLabel = vgui.Create("DLabel", form)
		hooksLabel:Dock(TOP)
		hooksLabel:DockMargin(5, 2, 5, 0)
		hooksLabel.Think = function(self)
			local hookCount = 0
			for _ in pairs(vrmod.debug.hooks) do hookCount = hookCount + 1 end
			local errCount = #vrmod.debug.GetErrors()
			self:SetText(string.format("Hooks tracked: %d | Errors: %d", hookCount, errCount))
		end

		local recLabel = vgui.Create("DLabel", form)
		recLabel:Dock(TOP)
		recLabel:DockMargin(5, 2, 5, 0)
		recLabel.Think = function(self)
			if vrmod.debug.export.IsRecording() then
				local elapsed = CurTime() - vrmod.debug.export.startTime
				self:SetText(string.format("Recording: %.1fs", elapsed))
				self:SetTextColor(Color(255, 100, 100))
			else
				self:SetText("Not recording")
				self:SetTextColor(Color(150, 150, 150))
			end
		end

		-- Open Debug Panel ボタン
		local openBtn = vgui.Create("DButton", scrollPanel)
		openBtn:SetText("Open Debug Monitor Panel")
		openBtn:Dock(TOP)
		openBtn:DockMargin(5, 10, 5, 5)
		openBtn:SetTall(35)
		openBtn:SetFont("DermaDefaultBold")
		openBtn.DoClick = function()
			RunConsoleCommand("vrmod_unoff_debug_panel")
		end

		-- クイックコントロール
		local controlForm = vgui.Create("DForm", scrollPanel)
		controlForm:SetName("Quick Controls")
		controlForm:Dock(TOP)
		controlForm:DockMargin(5, 5, 5, 5)

		controlForm:CheckBox("Enable Hook Monitoring", "vrmod_unoff_debug_hooks")
		controlForm:NumSlider("Log Level", "vrmod_unoff_debug_loglevel", 0, 4, 0)

		-- 記録コントロール
		local recBtn = controlForm:Button("Start/Stop Recording")
		recBtn.DoClick = function()
			if vrmod.debug.export.IsRecording() then
				vrmod.debug.export.StopRecording()
			else
				vrmod.debug.export.StartRecording()
			end
		end

		local exportBtn = controlForm:Button("Export Session Data (JSON)")
		exportBtn.DoClick = function()
			local path = vrmod.debug.export.ExportJSON()
			if path then
				chat.AddText(Color(100, 255, 100), "[VRMod Debug] ", Color(255, 255, 255), "Exported to: " .. path)
			end
		end

		-- Network Monitor クイックコントロール
		if vrmod.debug.netmon then
			local netForm = vgui.Create("DForm", scrollPanel)
			netForm:SetName("Network Monitor")
			netForm:Dock(TOP)
			netForm:DockMargin(5, 5, 5, 5)

			local netmonLabel = vgui.Create("DLabel", netForm)
			netmonLabel:Dock(TOP)
			netmonLabel:DockMargin(5, 2, 5, 0)
			netmonLabel.Think = function(self)
				if vrmod.debug.netmon.IsActive() then
					local totalRate = vrmod.debug.netmon.GetTotalSendRate()
					self:SetText(string.format("Net Monitor: ACTIVE | %.1f msg/s", totalRate))
					self:SetTextColor(totalRate > 100 and Color(255, 100, 100) or Color(100, 255, 100))
				else
					self:SetText("Net Monitor: OFF")
					self:SetTextColor(Color(150, 150, 150))
				end
			end

			local netToggleBtn = netForm:Button("Toggle Network Monitor")
			netToggleBtn.DoClick = function()
				if vrmod.debug.netmon.IsActive() then
					vrmod.debug.netmon.Stop()
				else
					vrmod.debug.netmon.Start()
				end
			end

			local netHudBtn = netForm:Button("Toggle HUD Overlay")
			netHudBtn.DoClick = function()
				RunConsoleCommand("vrmod_unoff_netmon_hud")
			end

			local netDumpBtn = netForm:Button("Dump to Console")
			netDumpBtn.DoClick = function()
				RunConsoleCommand("vrmod_unoff_netmon", "dump")
			end
		end
	end
)

Log.Info("menutab", "VRMod menu tab registered")

--------[vrmod_debug_menutab.lua]End--------
