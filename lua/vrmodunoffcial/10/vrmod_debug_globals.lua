--------[vrmod_debug_globals.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- Global Function & Hook Scanner
-- _Gを再帰走査して全関数・全hookを収集
-- デバッグパネルのタブ + コンソールコマンドとして提供
-- ========================================

local Log = vrmod.debug.Log

vrmod.debug.globals = vrmod.debug.globals or {}
local globals = vrmod.debug.globals

globals.functions = nil -- スキャン結果（遅延初期化）
globals.hooks = nil
globals.lastScanTime = nil

-- ----------------------------------------
-- 色定義
-- ----------------------------------------
local COLORS = {
	bg = Color(30, 30, 30),
	bgLight = Color(40, 40, 40),
	bgCode = Color(25, 25, 30),
	headerBg = Color(45, 45, 55),
	white = Color(255, 255, 255),
	gray = Color(150, 150, 150),
	green = Color(100, 255, 100),
	yellow = Color(255, 255, 100),
	orange = Color(255, 180, 80),
	cyan = Color(100, 220, 255),
}

-- ----------------------------------------
-- スキャンロジック
-- ----------------------------------------

-- GMod基盤テーブル（スキップ対象）
local SKIP_TABLES = {
	math = true, string = true, table = true,
	coroutine = true, os = true, io = true,
	debug = true, bit = true, jit = true,
	ffi = true, package = true,
	render = true, cam = true, surface = true,
	draw = true, mesh = true, Matrix = true,
	Vector = true, Angle = true, Color = true,
	derma = true, dragndrop = true,
	vrmod = true,
}

function globals.RunScan()
	local startTime = SysTime()
	local visited = {}
	local funcResults = {}
	local hookResults = {}
	local funcCount = 0
	local tableCount = 0

	local function ScanTable(tbl, path, depth)
		if depth > 5 then return end
		if visited[tbl] then return end
		visited[tbl] = true
		tableCount = tableCount + 1

		for key, val in pairs(tbl) do
			if type(key) ~= "string" then continue end

			local fullPath = path ~= "" and (path .. "." .. key) or key

			if type(val) == "function" then
				local info = debug.getinfo(val, "Sl")
				local src = info and info.short_src or "[C]"
				local line = info and info.linedefined or 0

				if src ~= "[C]" and src ~= "=[C]" then
					funcCount = funcCount + 1
					table.insert(funcResults, {
						path = fullPath,
						source = src,
						line = line,
						lastline = info and info.lastlinedefined or 0,
					})
				end
			elseif type(val) == "table" then
				if depth == 0 and SKIP_TABLES[key] then continue end
				if val == _G then continue end
				if key == "__index" or key == "__newindex" then continue end
				ScanTable(val, fullPath, depth + 1)
			end
		end
	end

	-- _G走査
	ScanTable(_G, "", 0)

	-- GAMEMODE走査
	local gm = GAMEMODE or (gmod and gmod.GetGamemode and gmod.GetGamemode())
	if gm then
		ScanTable(gm, "GAMEMODE", 1)
	end

	-- hook.GetTable()走査
	local hookTable = hook.GetTable()
	for hookName, callbacks in pairs(hookTable) do
		for cbName, fn in pairs(callbacks) do
			local info = debug.getinfo(fn, "Sl")
			local src = info and info.short_src or "[C]"
			if src ~= "[C]" and src ~= "=[C]" then
				table.insert(hookResults, {
					hook = hookName,
					callback = cbName,
					source = src,
					line = info and info.linedefined or 0,
					lastline = info and info.lastlinedefined or 0,
				})
			end
		end
	end

	-- ソート
	table.sort(funcResults, function(a, b) return a.path < b.path end)
	table.sort(hookResults, function(a, b)
		if a.hook == b.hook then return a.callback < b.callback end
		return a.hook < b.hook
	end)

	local elapsed = SysTime() - startTime

	globals.functions = funcResults
	globals.hooks = hookResults
	globals.lastScanTime = elapsed
	globals.tableCount = tableCount

	Log.Info("globals", string.format("Scan complete: %d functions, %d hooks, %d tables, %.1fs",
		funcCount, #hookResults, tableCount, elapsed))

	return funcResults, hookResults, elapsed
end

-- ----------------------------------------
-- JSON保存
-- ----------------------------------------
function globals.SaveToFile()
	if not globals.functions then
		print("[GLOBALS] No scan results. Run scan first.")
		return
	end

	local output = {
		scan_time = os.date("%Y-%m-%d %H:%M:%S"),
		elapsed_seconds = globals.lastScanTime,
		total_functions = #globals.functions,
		total_hooks = #globals.hooks,
		functions = globals.functions,
		hooks = globals.hooks,
	}

	local jsonStr = util.TableToJSON(output, true)
	file.Write("vrmod/vrmod_keymon_scan_globals.txt", jsonStr)
	print("[GLOBALS] Saved to: garrysmod/data/vrmod/vrmod_keymon_scan_globals.txt")
end

-- ----------------------------------------
-- パネルUI
-- ----------------------------------------
function globals.CreatePanelTab(parent)
	local container = vgui.Create("DPanel", parent)
	container.Paint = function() end

	-- ========== コントロールバー ==========
	local controlBar = vgui.Create("DPanel", container)
	controlBar:Dock(TOP)
	controlBar:SetTall(34)
	controlBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.headerBg)
	end

	-- Scanボタン
	local btnScan = vgui.Create("DButton", controlBar)
	btnScan:SetText("")
	btnScan:SetSize(100, 24)
	btnScan:SetPos(5, 5)
	btnScan.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.green)
		draw.SimpleText("Scan _G", "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- Save JSONボタン
	local btnSave = vgui.Create("DButton", controlBar)
	btnSave:SetText("")
	btnSave:SetSize(100, 24)
	btnSave:SetPos(110, 5)
	btnSave.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.orange)
		draw.SimpleText("Save JSON", "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnSave.DoClick = function()
		globals.SaveToFile()
	end

	-- 検索フィルター
	local searchEntry = vgui.Create("DTextEntry", controlBar)
	searchEntry:SetPos(220, 5)
	searchEntry:SetSize(200, 24)
	searchEntry:SetPlaceholderText("Search functions...")
	searchEntry:SetFont("VRDebugUISmall")

	-- 表示モード切替
	local viewMode = "functions" -- "functions" or "hooks"
	local btnMode = vgui.Create("DButton", controlBar)
	btnMode:SetText("")
	btnMode:SetSize(80, 24)
	btnMode:SetPos(430, 5)
	btnMode.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.bgLight)
		local label = viewMode == "functions" and "Functions" or "Hooks"
		draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnMode.DoClick = function()
		viewMode = viewMode == "functions" and "hooks" or "functions"
	end

	-- ステータスラベル
	local statusLabel = vgui.Create("DLabel", controlBar)
	statusLabel:SetPos(520, 8)
	statusLabel:SetFont("VRDebugUISmall")
	statusLabel:SetTextColor(COLORS.gray)
	statusLabel:SetText("Not scanned yet")

	-- ========== メイン分割: リスト + 詳細 ==========
	local mainSplit = vgui.Create("DVerticalDivider", container)
	mainSplit:Dock(FILL)
	mainSplit:DockMargin(0, 2, 0, 0)
	mainSplit:SetDividerHeight(4)
	mainSplit:SetTopHeight(400)
	mainSplit:SetTopMin(200)
	mainSplit:SetBottomMin(80)

	-- リストコンテナ（Functions/Hooks切替用）
	local listContainer = vgui.Create("DPanel")
	listContainer.Paint = function() end

	-- Functions用リスト
	local funcList = vgui.Create("DListView", listContainer)
	funcList:Dock(FILL)
	funcList:SetMultiSelect(false)
	funcList:AddColumn("Path"):SetFixedWidth(250)
	funcList:AddColumn("Source"):SetFixedWidth(350)
	funcList:AddColumn("Line"):SetFixedWidth(60)
	funcList.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	-- Hooks用リスト
	local hookList = vgui.Create("DListView", listContainer)
	hookList:Dock(FILL)
	hookList:SetMultiSelect(false)
	hookList:AddColumn("Hook"):SetFixedWidth(180)
	hookList:AddColumn("Callback"):SetFixedWidth(200)
	hookList:AddColumn("Source"):SetFixedWidth(250)
	hookList:AddColumn("Line"):SetFixedWidth(60)
	hookList.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end
	hookList:SetVisible(false)

	-- 詳細パネル
	local detailPanel = vgui.Create("DTextEntry")
	detailPanel:SetMultiline(true)
	detailPanel:SetEditable(false)
	detailPanel:SetFont("VRDebugCode")
	detailPanel:SetText("Click 'Scan _G' to discover all global functions and hooks.\nResults can be saved as JSON for analysis.")

	mainSplit:SetTop(listContainer)
	mainSplit:SetBottom(detailPanel)

	-- ========== リスト更新 ==========
	local listData = {}

	local function RefreshList()
		local filter = string.lower(string.Trim(searchEntry:GetValue() or ""))
		listData = {}

		if viewMode == "functions" then
			funcList:SetVisible(true)
			hookList:SetVisible(false)
			funcList:Clear()

			local data = globals.functions or {}
			for _, r in ipairs(data) do
				if filter == "" or string.find(string.lower(r.path), filter, 1, true)
					or string.find(string.lower(r.source), filter, 1, true) then
					local row = funcList:AddLine(r.path, r.source, r.line)
					row._data = r
					table.insert(listData, r)
				end
			end

			statusLabel:SetText(string.format("%d / %d functions", #listData, #data))
		else
			funcList:SetVisible(false)
			hookList:SetVisible(true)
			hookList:Clear()

			local data = globals.hooks or {}
			for _, r in ipairs(data) do
				if filter == "" or string.find(string.lower(r.hook), filter, 1, true)
					or string.find(string.lower(r.callback), filter, 1, true)
					or string.find(string.lower(r.source), filter, 1, true) then
					local row = hookList:AddLine(r.hook, r.callback, r.source, r.line)
					row._data = r
					table.insert(listData, r)
				end
			end

			statusLabel:SetText(string.format("%d / %d hooks", #listData, #data))
		end

		statusLabel:SizeToContents()
	end

	-- Scanボタンのクリック
	btnScan.DoClick = function()
		statusLabel:SetText("Scanning... (game may freeze)")
		statusLabel:SizeToContents()

		-- 1フレーム遅延でスキャン（UIが更新されるように）
		timer.Simple(0, function()
			globals.RunScan()
			RefreshList()
		end)
	end

	-- 検索変更時
	searchEntry.OnChange = function()
		-- 少し遅延してリフレッシュ（タイピング中の負荷軽減）
		timer.Create("vrmod_debug_globals_search", 0.3, 1, function()
			if IsValid(list) then RefreshList() end
		end)
	end

	-- モード切替時
	local lastCheckMode = viewMode
	funcList.Think = function(self)
		if viewMode ~= lastCheckMode then
			lastCheckMode = viewMode
			RefreshList()
		end
	end

	-- 行選択で詳細表示（両リスト共通ハンドラ）
	local function OnRowSelected(self, idx, row)
		local data = row._data
		if not data then return end

		local lines = {}
		if data.path then
			-- function entry
			table.insert(lines, "Function: " .. data.path)
			table.insert(lines, "Source:   " .. data.source .. ":" .. data.line .. "-" .. (data.lastline or "?"))
			table.insert(lines, "")

			-- ソースコード読み取り試行
			local content = file.Read(data.source, "GAME")
			if content then
				table.insert(lines, "--- Source Code ---")
				local allLines = {}
				for l in string.gmatch(content .. "\n", "([^\r\n]*)\r?\n") do
					table.insert(allLines, l)
				end
				local startL = math.max(1, data.line - 3)
				local endL = math.min(#allLines, (data.lastline or data.line) + 5)
				for i = startL, endL do
					local prefix = (i == data.line) and ">>>" or "   "
					table.insert(lines, string.format("%s %4d: %s", prefix, i, allLines[i] or ""))
				end
			else
				table.insert(lines, "(Source file not readable via file.Read)")
			end
		elseif data.hook then
			-- hook entry
			table.insert(lines, "Hook:     " .. data.hook)
			table.insert(lines, "Callback: " .. data.callback)
			table.insert(lines, "Source:   " .. data.source .. ":" .. data.line .. "-" .. (data.lastline or "?"))
			table.insert(lines, "")

			local content = file.Read(data.source, "GAME")
			if content then
				table.insert(lines, "--- Source Code ---")
				local allLines = {}
				for l in string.gmatch(content .. "\n", "([^\r\n]*)\r?\n") do
					table.insert(allLines, l)
				end
				local startL = math.max(1, data.line - 3)
				local endL = math.min(#allLines, (data.lastline or data.line) + 5)
				for i = startL, endL do
					local prefix = (i == data.line) and ">>>" or "   "
					table.insert(lines, string.format("%s %4d: %s", prefix, i, allLines[i] or ""))
				end
			end
		end

		detailPanel:SetText(table.concat(lines, "\n"))
	end

	funcList.OnRowSelected = OnRowSelected
	hookList.OnRowSelected = OnRowSelected

	-- 既にスキャン済みならリスト表示
	if globals.functions then
		RefreshList()
	end

	return container
end

-- ========================================
-- コンソールコマンド（パネルなしでも使える）
-- ========================================
concommand.Add("vrmod_keymon_scan_globals", function()
	print("[GLOBALS] Scanning...")
	local funcs, hooks, elapsed = globals.RunScan()
	print(string.format("[GLOBALS] Found %d functions, %d hooks (%.1fs)", #funcs, #hooks, elapsed))
	globals.SaveToFile()
end)

Log.Info("globals", "Global Function Scanner registered")

--------[vrmod_debug_globals.lua]End--------
