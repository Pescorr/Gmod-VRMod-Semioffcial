--------[vrmod_debug_panel.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- ライブコードビューア GUI
-- ========================================

local Log = vrmod.debug.Log

-- フォント定義
surface.CreateFont("VRDebugCode", {
	font = "Courier New",
	size = 14,
	weight = 500,
})

surface.CreateFont("VRDebugCodeBold", {
	font = "Courier New",
	size = 14,
	weight = 700,
})

surface.CreateFont("VRDebugUI", {
	font = "Arial",
	size = 14,
	weight = 500,
})

surface.CreateFont("VRDebugUISmall", {
	font = "Arial",
	size = 12,
	weight = 500,
})

surface.CreateFont("VRDebugUIBold", {
	font = "Arial",
	size = 14,
	weight = 700,
})

-- ----------------------------------------
-- 色定義
-- ----------------------------------------
local COLORS = {
	bg = Color(30, 30, 30),
	bgLight = Color(40, 40, 40),
	bgCode = Color(25, 25, 30),
	lineNum = Color(100, 100, 100),
	lineNumActive = Color(200, 200, 100),
	code = Color(220, 220, 220),
	highlight = Color(255, 255, 50, 80),
	highlightBright = Color(255, 255, 50, 150),
	separator = Color(60, 60, 60),
	fileActive = Color(255, 255, 100),
	headerBg = Color(45, 45, 55),
	buttonHook = Color(80, 180, 80),
	buttonLine = Color(200, 80, 80),
	buttonRec = Color(220, 60, 60),
	buttonExport = Color(80, 150, 220),
	buttonStop = Color(180, 100, 50),
	white = Color(255, 255, 255),
	gray = Color(150, 150, 150),
	red = Color(255, 100, 100),
	green = Color(100, 255, 100),
	yellow = Color(255, 255, 100),
	orange = Color(255, 180, 80),
}

-- ----------------------------------------
-- パネル参照（シングルトン）
-- ----------------------------------------
local debugFrame = nil
local currentFile = nil
local currentFileSource = nil
local currentFilePath = nil
local autoScroll = true
local traceMode = "hook" -- "hook" or "line"

-- ----------------------------------------
-- メインパネル作成
-- ----------------------------------------
local function CreateDebugPanel()
	-- 既存パネルがあれば閉じる
	if IsValid(debugFrame) then
		debugFrame:Remove()
	end

	-- フックインベントリを構築
	vrmod.debug.BuildHookInventory()

	debugFrame = vgui.Create("DFrame")
	debugFrame:SetSize(1100, 750)
	debugFrame:SetTitle("VRMod Debug Monitor")
	debugFrame:SetDraggable(true)
	debugFrame:SetSizable(true)
	debugFrame:SetMinWidth(800)
	debugFrame:SetMinHeight(500)
	debugFrame:MakePopup()
	debugFrame:Center()
	debugFrame:SetDeleteOnClose(true)
	debugFrame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLORS.bg)
		draw.RoundedBox(4, 0, 0, w, 25, COLORS.headerBg)
	end

	debugFrame.OnClose = function()
		-- Line Trace停止
		if vrmod.debug.lineTraceActive then
			vrmod.debug.StopLineTrace()
		end
		-- Key Monitor停止
		if vrmod.debug.keymon and vrmod.debug.keymon.Stop then
			vrmod.debug.keymon.Stop()
		end
		-- Think更新フック除去
		hook.Remove("Think", "vrmod_debug_panel_update")
		debugFrame = nil
	end

	-- メインタブシート
	local tabs = vgui.Create("DPropertySheet", debugFrame)
	tabs:Dock(FILL)
	tabs:DockMargin(4, 4, 4, 4)

	-- タブ1: Code Viewer（メイン）
	local codeViewerTab = CreateCodeViewerTab(tabs)
	tabs:AddSheet("Code Viewer", codeViewerTab, "icon16/page_white_code.png")

	-- タブ2: Hook Monitor
	local hookMonTab = CreateHookMonitorTab(tabs)
	tabs:AddSheet("Hook Monitor", hookMonTab, "icon16/chart_bar.png")

	-- タブ3: Error Log
	local errorTab = CreateErrorLogTab(tabs)
	tabs:AddSheet("Error Log", errorTab, "icon16/error.png")

	-- タブ4: ConVar Inspector
	local convarTab = CreateConvarTab(tabs)
	tabs:AddSheet("ConVar Inspector", convarTab, "icon16/cog.png")

	-- タブ5: Network Monitor
	if vrmod.debug.netmon and vrmod.debug.netmon.CreatePanelTab then
		local netmonTab = vrmod.debug.netmon.CreatePanelTab(tabs)
		tabs:AddSheet("Network Monitor", netmonTab, "icon16/transmit.png")
	end

	-- タブ6: Key & VR Action Monitor
	if vrmod.debug.keymon and vrmod.debug.keymon.CreatePanelTab then
		local keymonTab = vrmod.debug.keymon.CreatePanelTab(tabs)
		tabs:AddSheet("Key Monitor", keymonTab, "icon16/keyboard.png")
	end

	-- タブ7: Global Functions & Hooks
	if vrmod.debug.globals and vrmod.debug.globals.CreatePanelTab then
		local globalsTab = vrmod.debug.globals.CreatePanelTab(tabs)
		tabs:AddSheet("Functions", globalsTab, "icon16/brick.png")
	end

	-- タブ8: Render Scanner (UI/HUD/VGUI全描画イントロスペクション)
	if vrmod.debug.uiscan and vrmod.debug.uiscan.CreateScannerTab then
		local scanTab = vrmod.debug.uiscan.CreateScannerTab(tabs)
		tabs:AddSheet("Render Scanner", scanTab, "icon16/application_view_tile.png")
	end

	-- タブ9: VR Gap Analysis
	if vrmod.debug.uiscan and vrmod.debug.uiscan.CreateGapTab then
		local gapTab = vrmod.debug.uiscan.CreateGapTab(tabs)
		tabs:AddSheet("VR Gap Analysis", gapTab, "icon16/chart_pie.png")
	end

	-- Think更新ループ（パネル表示中のみ）
	local lastUpdate = 0
	hook.Add("Think", "vrmod_debug_panel_update", function()
		if not IsValid(debugFrame) then
			hook.Remove("Think", "vrmod_debug_panel_update")
			return
		end

		local now = SysTime()
		if now - lastUpdate < 0.1 then return end
		lastUpdate = now

		-- Hook Trackingモードの場合、ファイルのアクティブ行範囲を更新
		if traceMode == "hook" and currentFilePath then
			vrmod.debug.UpdateActiveRangesForFile(currentFilePath)
		end
	end)

	return debugFrame
end

-- ========================================
-- タブ1: Code Viewer（ライブコードビューア）
-- ========================================
function CreateCodeViewerTab(parent)
	local container = vgui.Create("DPanel", parent)
	container.Paint = function() end

	-- ヘッダーバー
	local header = vgui.Create("DPanel", container)
	header:Dock(TOP)
	header:SetTall(30)
	header.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.headerBg)
	end

	-- ファイル名表示
	local fileLabel = vgui.Create("DLabel", header)
	fileLabel:SetPos(10, 5)
	fileLabel:SetFont("VRDebugUIBold")
	fileLabel:SetText("Select a file from the tree")
	fileLabel:SetTextColor(COLORS.white)
	fileLabel:SizeToContents()

	-- モード切替ボタン
	local btnAutoScroll = vgui.Create("DButton", header)
	btnAutoScroll:SetText("Auto-Scroll")
	btnAutoScroll:SetFont("VRDebugUISmall")
	btnAutoScroll:SetSize(80, 22)
	btnAutoScroll:SetPos(0, 4)
	btnAutoScroll.Paint = function(self, w, h)
		local col = autoScroll and COLORS.green or COLORS.gray
		draw.RoundedBox(3, 0, 0, w, h, col)
		draw.SimpleText(self:GetText(), "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnAutoScroll.DoClick = function()
		autoScroll = not autoScroll
	end

	local btnLine = vgui.Create("DButton", header)
	btnLine:SetText("Line")
	btnLine:SetFont("VRDebugUISmall")
	btnLine:SetSize(60, 22)
	btnLine:SetPos(0, 4)
	btnLine.Paint = function(self, w, h)
		local col = traceMode == "line" and COLORS.buttonLine or COLORS.gray
		draw.RoundedBox(3, 0, 0, w, h, col)
		draw.SimpleText(self:GetText(), "VRDebugUISmall", w / 2, h / 2, COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnLine.DoClick = function()
		if traceMode == "line" then
			traceMode = "hook"
			vrmod.debug.StopLineTrace()
		else
			if currentFilePath then
				traceMode = "line"
				vrmod.debug.activeLines = {}
				vrmod.debug.StartLineTrace(currentFilePath)
			end
		end
	end

	local btnHook = vgui.Create("DButton", header)
	btnHook:SetText("Hook")
	btnHook:SetFont("VRDebugUISmall")
	btnHook:SetSize(60, 22)
	btnHook:SetPos(0, 4)
	btnHook.Paint = function(self, w, h)
		local col = traceMode == "hook" and COLORS.buttonHook or COLORS.gray
		draw.RoundedBox(3, 0, 0, w, h, col)
		draw.SimpleText(self:GetText(), "VRDebugUISmall", w / 2, h / 2, COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnHook.DoClick = function()
		traceMode = "hook"
		if vrmod.debug.lineTraceActive then
			vrmod.debug.StopLineTrace()
		end
	end

	-- ヘッダーレイアウト
	header.PerformLayout = function(self, w, h)
		fileLabel:SetPos(10, 5)
		fileLabel:SizeToContents()
		btnAutoScroll:SetPos(w - 310, 4)
		btnHook:SetPos(w - 220, 4)
		btnLine:SetPos(w - 155, 4)
	end

	-- Line Trace警告ラベル
	local warnLabel = vgui.Create("DLabel", header)
	warnLabel:SetFont("VRDebugUISmall")
	warnLabel:SetTextColor(COLORS.red)
	warnLabel:SetText("")
	warnLabel.Think = function(self)
		if traceMode == "line" and vrmod.debug.lineTraceActive then
			local remaining = 30 - (CurTime() - vrmod.debug.lineTraceStartTime)
			if remaining > 0 then
				self:SetText(string.format("LINE TRACE ACTIVE (%.0fs)", remaining))
			else
				self:SetText("")
				traceMode = "hook"
			end
		else
			self:SetText("")
		end
		self:SizeToContents()
		self:SetPos(header:GetWide() - 90 - self:GetWide(), 7)
	end

	-- メイン分割パネル
	local mainSplit = vgui.Create("DHorizontalDivider", container)
	mainSplit:Dock(FILL)
	mainSplit:DockMargin(0, 2, 0, 0)
	mainSplit:SetDividerWidth(4)
	mainSplit:SetLeftWidth(230)
	mainSplit:SetLeftMin(150)
	mainSplit:SetRightMin(400)

	-- ========== 左パネル: ファイルツリー ==========
	local leftPanel = vgui.Create("DPanel")
	leftPanel.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgLight)
	end

	local fileTree = vgui.Create("DTree", leftPanel)
	fileTree:Dock(FILL)
	fileTree:DockMargin(2, 2, 2, 2)
	fileTree.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.bgLight)
	end

	-- ファイルツリー構築
	local tree = vrmod.debug.fileTree
	local sortedFolders = {}
	for folderName, _ in pairs(tree) do
		table.insert(sortedFolders, folderName)
	end
	table.sort(sortedFolders, function(a, b)
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then return na < nb end
		if na then return true end
		if nb then return false end
		return a < b
	end)

	for _, folderName in ipairs(sortedFolders) do
		local files = tree[folderName]
		if files and #files > 0 then
			local folderNode = fileTree:AddNode(folderName .. "/", "icon16/folder.png")
			folderNode:SetExpanded(false)

			for _, fileInfo in ipairs(files) do
				local fileNode = folderNode:AddNode(fileInfo.name, "icon16/page_white_code.png")
				fileNode.fileInfo = fileInfo
				fileNode.DoClick = function()
					SelectFile(fileInfo, fileLabel)
				end
			end
		end
	end

	-- ========== 右パネル: コード + ログ ==========
	local rightPanel = vgui.Create("DPanel")
	rightPanel.Paint = function() end

	-- 縦分割（コード上、ログ下）
	local vertSplit = vgui.Create("DVerticalDivider", rightPanel)
	vertSplit:Dock(FILL)
	vertSplit:SetDividerHeight(4)
	vertSplit:SetTopHeight(500)
	vertSplit:SetTopMin(200)
	vertSplit:SetBottomMin(100)

	-- コードビューア
	local codePanel = CreateCodeViewer(vertSplit)

	-- アクティビティログ + 記録コントロール
	local logPanel = CreateActivityLog(vertSplit)

	vertSplit:SetTop(codePanel)
	vertSplit:SetBottom(logPanel)

	mainSplit:SetLeft(leftPanel)
	mainSplit:SetRight(rightPanel)

	return container
end

-- ----------------------------------------
-- ファイル選択処理
-- ----------------------------------------
function SelectFile(fileInfo, fileLabel)
	currentFile = fileInfo.name
	currentFilePath = fileInfo.path
	currentFileSource = vrmod.debug.ReadSource(fileInfo.fullPath)

	if fileLabel then
		fileLabel:SetText(fileInfo.path)
		fileLabel:SizeToContents()
	end

	-- アクティブ行をリセット
	vrmod.debug.activeLines = {}

	-- Line Traceモードの場合、新ファイルでトレース再開
	if traceMode == "line" then
		vrmod.debug.StartLineTrace(fileInfo.path)
	end

	-- フックインベントリ再構築
	vrmod.debug.BuildHookInventory()

	Log.Debug("panel", "Selected file: " .. fileInfo.path)
end

-- ----------------------------------------
-- コードビューア（カスタムPaint描画）
-- ----------------------------------------
function CreateCodeViewer(parent)
	local scrollPanel = vgui.Create("DScrollPanel")
	scrollPanel.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	local LINE_HEIGHT = 18
	local LINE_NUM_WIDTH = 50
	local CODE_PADDING = 8

	local codeCanvas = vgui.Create("DPanel", scrollPanel)
	codeCanvas:Dock(TOP)
	codeCanvas.Paint = function(self, w, h)
		if not currentFileSource then
			draw.SimpleText("Select a file from the tree to view source code",
				"VRDebugUI", w / 2, h / 2, COLORS.gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end

		local lines = currentFileSource
		local activeLines = vrmod.debug.activeLines
		local now = CurTime()
		local latestActiveLine = 0
		local latestActiveTime = 0

		for i, lineText in ipairs(lines) do
			local y = (i - 1) * LINE_HEIGHT

			-- ハイライト判定
			local hitTime = activeLines[i]
			if hitTime then
				local age = now - hitTime
				if age < 0.5 then
					-- フェードアウトするハイライト
					local alpha = 150 * math.max(0, 1 - (age / 0.5))
					local hlColor = Color(255, 255, 50, alpha)
					surface.SetDrawColor(hlColor)
					surface.DrawRect(0, y, w, LINE_HEIGHT)

					if hitTime > latestActiveTime then
						latestActiveTime = hitTime
						latestActiveLine = i
					end
				elseif age < 2 then
					-- 薄い残留ハイライト
					local alpha = 30 * math.max(0, 1 - ((age - 0.5) / 1.5))
					surface.SetDrawColor(Color(255, 255, 50, alpha))
					surface.DrawRect(0, y, w, LINE_HEIGHT)
				end
			end

			-- 行番号
			local lineNumColor = hitTime and (now - hitTime < 1) and COLORS.lineNumActive or COLORS.lineNum
			draw.SimpleText(tostring(i), "VRDebugCode", LINE_NUM_WIDTH - 8, y + 2,
				lineNumColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

			-- 区切り線
			surface.SetDrawColor(COLORS.separator)
			surface.DrawLine(LINE_NUM_WIDTH, y, LINE_NUM_WIDTH, y + LINE_HEIGHT)

			-- コードテキスト
			draw.SimpleText(lineText, "VRDebugCode", LINE_NUM_WIDTH + CODE_PADDING, y + 2,
				COLORS.code, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	codeCanvas.Think = function(self)
		if not currentFileSource then
			self:SetTall(400)
			return
		end

		local targetHeight = #currentFileSource * LINE_HEIGHT + 20
		if self:GetTall() ~= targetHeight then
			self:SetTall(targetHeight)
		end

		-- 自動スクロール
		if autoScroll and currentFileSource then
			local activeLines = vrmod.debug.activeLines
			local now = CurTime()
			local latestLine = 0
			local latestTime = 0

			for lineNum, hitTime in pairs(activeLines) do
				if hitTime > latestTime and (now - hitTime) < 0.3 then
					latestTime = hitTime
					latestLine = lineNum
				end
			end

			if latestLine > 0 then
				local targetY = (latestLine - 5) * LINE_HEIGHT
				local vbar = scrollPanel:GetVBar()
				if vbar then
					vbar:AnimateTo(targetY, 0.2, 0, 0.5)
				end
			end
		end
	end

	return scrollPanel
end

-- ----------------------------------------
-- アクティビティログ + 記録コントロール
-- ----------------------------------------
function CreateActivityLog(parent)
	local panel = vgui.Create("DPanel")
	panel.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgLight)
	end

	-- 記録コントロールバー
	local controlBar = vgui.Create("DPanel", panel)
	controlBar:Dock(BOTTOM)
	controlBar:SetTall(30)
	controlBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.headerBg)
	end

	-- RECボタン
	local btnRec = vgui.Create("DButton", controlBar)
	btnRec:SetText("")
	btnRec:SetSize(100, 22)
	btnRec:SetPos(5, 4)
	btnRec.Paint = function(self, w, h)
		local isRec = vrmod.debug.export.IsRecording()
		local col = isRec and COLORS.buttonRec or COLORS.gray
		draw.RoundedBox(3, 0, 0, w, h, col)
		local label = isRec and "REC ●" or "Start REC"
		draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnRec.DoClick = function()
		if vrmod.debug.export.IsRecording() then
			vrmod.debug.export.StopRecording()
		else
			vrmod.debug.export.StartRecording()
		end
	end

	-- Export JSONボタン
	local btnExport = vgui.Create("DButton", controlBar)
	btnExport:SetText("")
	btnExport:SetSize(100, 22)
	btnExport:SetPos(110, 4)
	btnExport.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.buttonExport)
		draw.SimpleText("Export JSON", "VRDebugUISmall", w / 2, h / 2, COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnExport.DoClick = function()
		local path = vrmod.debug.export.ExportJSON()
		if path then
			chat.AddText(COLORS.green, "[VRMod Debug] ", COLORS.white, "Exported to: " .. path)
		end
	end

	-- 記録時間表示
	local recTimeLabel = vgui.Create("DLabel", controlBar)
	recTimeLabel:SetFont("VRDebugUISmall")
	recTimeLabel:SetTextColor(COLORS.white)
	recTimeLabel:SetPos(220, 7)
	recTimeLabel.Think = function(self)
		if vrmod.debug.export.IsRecording() then
			local elapsed = CurTime() - vrmod.debug.export.startTime
			self:SetText(string.format("Recording: %.1fs", elapsed))
		else
			self:SetText("")
		end
		self:SizeToContents()
	end

	-- アクティビティログリスト
	local logList = vgui.Create("DListView", panel)
	logList:Dock(FILL)
	logList:DockMargin(2, 2, 2, 2)
	logList:AddColumn("Time"):SetFixedWidth(60)
	logList:AddColumn("Hook"):SetFixedWidth(150)
	logList:AddColumn("Info")
	logList:SetMultiSelect(false)
	logList.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.bgCode)
	end

	-- ログ更新
	local lastLogUpdate = 0
	local lastLogCount = 0
	logList.Think = function(self)
		local now = SysTime()
		if now - lastLogUpdate < 0.25 then return end
		lastLogUpdate = now

		if not currentFilePath then return end

		-- フック発火情報からログエントリ構築
		local hookData = vrmod.debug.hooks
		local curTime = CurTime()
		local newEntries = {}

		for hookName, hd in pairs(hookData) do
			if hd.lastFire > 0 and (curTime - hd.lastFire) < 2 then
				-- このフックにファイルのコールバックがあるか
				local callbacks = vrmod.debug.GetCallbacksForFile(currentFilePath)
				for _, cb in ipairs(callbacks) do
					if cb.hookName == hookName then
						table.insert(newEntries, {
							time = hd.lastFire,
							hook = hookName,
							info = string.format("%s (L%d-%d)", cb.callbackName, cb.linedefined, cb.lastlinedefined),
						})
					end
				end
			end
		end

		-- 新しいエントリがあれば追加
		if #newEntries ~= lastLogCount then
			self:Clear()
			table.sort(newEntries, function(a, b) return a.time > b.time end)
			for i = 1, math.min(20, #newEntries) do
				local e = newEntries[i]
				local timeStr = string.format("%.1fs", curTime - e.time)
				self:AddLine(timeStr, e.hook, e.info)
			end
			lastLogCount = #newEntries
		end
	end

	return panel
end

-- ========================================
-- タブ2: Hook Monitor
-- ========================================
function CreateHookMonitorTab(parent)
	local panel = vgui.Create("DPanel", parent)
	panel.Paint = function() end

	local list = vgui.Create("DListView", panel)
	list:Dock(FILL)
	list:DockMargin(4, 4, 4, 4)
	list:AddColumn("Hook Name"):SetFixedWidth(250)
	list:AddColumn("Rate/s"):SetFixedWidth(70)
	list:AddColumn("Avg (ms)"):SetFixedWidth(70)
	list:AddColumn("Total Fires"):SetFixedWidth(80)
	list:AddColumn("Last Fire"):SetFixedWidth(80)
	list:SetMultiSelect(false)
	list.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	-- 更新
	local lastUpdate = 0
	list.Think = function(self)
		local now = SysTime()
		if now - lastUpdate < 0.5 then return end
		lastUpdate = now

		self:Clear()
		local rates = vrmod.debug.CalcHookRates()
		local hooks = vrmod.debug.hooks

		-- ソート用テーブル
		local sorted = {}
		for name, data in pairs(hooks) do
			table.insert(sorted, { name = name, data = data, rate = rates[name] or 0 })
		end
		table.sort(sorted, function(a, b) return a.data.avgTime > b.data.avgTime end)

		for _, entry in ipairs(sorted) do
			local d = entry.data
			local age = CurTime() - d.lastFire
			local timeStr = age < 1 and "NOW" or string.format("%.1fs ago", age)
			local line = self:AddLine(
				entry.name,
				string.format("%.1f", entry.rate),
				string.format("%.3f", d.avgTime * 1000),
				tostring(d.fireCount),
				timeStr
			)

			-- 色分け
			if age < 0.5 then
				for _, col in pairs(line.Columns) do col:SetTextColor(COLORS.green) end
			elseif d.avgTime * 1000 > 1 then
				for _, col in pairs(line.Columns) do col:SetTextColor(COLORS.red) end
			elseif age < 5 then
				for _, col in pairs(line.Columns) do col:SetTextColor(COLORS.yellow) end
			end
		end
	end

	-- クリックで詳細表示
	list.OnRowSelected = function(self, idx, row)
		local hookName = row:GetColumnText(1)
		local inventory = vrmod.debug.hookInventory[hookName]
		if not inventory then return end

		local msg = "Callbacks for " .. hookName .. ":\n"
		for cbName, info in pairs(inventory) do
			msg = msg .. string.format("  %s  →  %s:%d-%d\n", cbName, info.source, info.linedefined, info.lastlinedefined)
		end
		print(msg)
	end

	return panel
end

-- ========================================
-- タブ3: Error Log
-- ========================================
function CreateErrorLogTab(parent)
	local panel = vgui.Create("DPanel", parent)
	panel.Paint = function() end

	-- リフレッシュボタン
	local btnRefresh = vgui.Create("DButton", panel)
	btnRefresh:Dock(TOP)
	btnRefresh:SetTall(25)
	btnRefresh:DockMargin(4, 4, 4, 0)
	btnRefresh:SetText("Refresh Error Log")

	-- エラーリスト
	local list = vgui.Create("DListView", panel)
	list:Dock(FILL)
	list:DockMargin(4, 4, 4, 4)
	list:AddColumn("Time"):SetFixedWidth(80)
	list:AddColumn("Source"):SetFixedWidth(200)
	list:AddColumn("Message")
	list:SetMultiSelect(false)
	list.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	-- スタックトレース表示
	local stackPanel = vgui.Create("DTextEntry", panel)
	stackPanel:Dock(BOTTOM)
	stackPanel:SetTall(120)
	stackPanel:DockMargin(4, 0, 4, 4)
	stackPanel:SetMultiline(true)
	stackPanel:SetEditable(false)
	stackPanel:SetFont("VRDebugCode")
	stackPanel:SetText("Click an error to view stack trace")

	local function RefreshErrors()
		list:Clear()
		local errors = vrmod.debug.GetErrors()
		for i = #errors, 1, -1 do
			local err = errors[i]
			local timeStr = string.format("%.1fs", CurTime() - err.time)
			local line = list:AddLine(timeStr, err.source, err.message)
			line.errorData = err
			for _, col in pairs(line.Columns) do col:SetTextColor(COLORS.red) end
		end
	end

	btnRefresh.DoClick = RefreshErrors

	list.OnRowSelected = function(self, idx, row)
		if row.errorData then
			stackPanel:SetText(row.errorData.stack or "No stack trace available")
		end
	end

	-- 初期ロード
	RefreshErrors()

	return panel
end

-- ========================================
-- タブ4: ConVar Inspector
-- ========================================
function CreateConvarTab(parent)
	local panel = vgui.Create("DPanel", parent)
	panel.Paint = function() end

	-- リフレッシュボタン
	local btnRefresh = vgui.Create("DButton", panel)
	btnRefresh:Dock(TOP)
	btnRefresh:SetTall(25)
	btnRefresh:DockMargin(4, 4, 4, 0)
	btnRefresh:SetText("Refresh ConVars")

	-- ConVarリスト
	local list = vgui.Create("DListView", panel)
	list:Dock(FILL)
	list:DockMargin(4, 4, 4, 4)
	list:AddColumn("Name"):SetFixedWidth(300)
	list:AddColumn("Value"):SetFixedWidth(100)
	list:AddColumn("Default"):SetFixedWidth(100)
	list:AddColumn("Modified"):SetFixedWidth(60)
	list:SetMultiSelect(false)
	list.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	local function RefreshConvars()
		list:Clear()

		-- vrmod ConVarを収集
		local convarNames = {}
		local cvTable, cvDefaults = vrmod.GetConvars()
		if cvTable then
			for name, _ in pairs(cvTable) do
				convarNames[name] = true
			end
		end

		-- vrmod_unoff_debug ConVarも追加
		for _, name in ipairs({
			"vrmod_unoff_debug", "vrmod_unoff_debug_hooks",
			"vrmod_unoff_debug_loglevel", "vrmod_unoff_developer_mode",
			"vrmod_error_hard",
		}) do
			convarNames[name] = true
		end

		-- ソートして表示
		local sorted = {}
		for name, _ in pairs(convarNames) do
			table.insert(sorted, name)
		end
		table.sort(sorted)

		for _, name in ipairs(sorted) do
			local cv = GetConVar(name)
			if cv then
				local val = cv:GetString()
				local def = cv:GetDefault()
				local modified = val ~= def and "YES" or ""
				local line = list:AddLine(name, val, def, modified)

				if modified == "YES" then
					for _, col in pairs(line.Columns) do
						col:SetTextColor(COLORS.yellow)
					end
				end
			end
		end
	end

	btnRefresh.DoClick = RefreshConvars

	-- 初期ロード
	RefreshConvars()

	return panel
end

-- ========================================
-- コンソールコマンド
-- ========================================
concommand.Add("vrmod_unoff_debug_panel", function()
	if not vrmod.debug or not vrmod.debug.enabled then
		print("[VRMod Debug] Debug system is not enabled. Set vrmod_unoff_debug 1 and restart GMod.")
		return
	end
	CreateDebugPanel()
end)

Log.Info("panel", "Debug panel registered. Use 'vrmod_unoff_debug_panel' to open.")

--------[vrmod_debug_panel.lua]End--------
