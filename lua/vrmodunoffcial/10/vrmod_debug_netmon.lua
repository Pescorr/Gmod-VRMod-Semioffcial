--------[vrmod_debug_netmon.lua]Start--------
AddCSLuaFile()

-- デバッグシステム必須
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end -- クライアント専用（リッスンサーバーではCLIENT側で全て計測可能）

local Log = vrmod.debug.Log

-- ========================================
-- Network Monitor — VRModネットワークメッセージ精密計測
-- ========================================
-- 機能:
--   1. net.Start / net.SendToServer デトアによる全送信メッセージ自動捕捉
--   2. メッセージ名ごとの rate/sec, bytes/sec, peak, total 計測
--   3. カテゴリ分類 (vehicle_lvs, vehicle_glide, tracking, pickup, etc.)
--   4. HUDオーバーレイ表示（リアルタイム）
--   5. デバッグパネル統合タブ（詳細表示 + レートグラフ）
--   6. コンソールコマンド（dump, csv等）
-- ========================================

vrmod.debug.netmon = vrmod.debug.netmon or {}
local netmon = vrmod.debug.netmon

-- ========================================
-- 定数
-- ========================================
local WINDOW_SIZE = 1.0          -- レート計算ウィンドウ (秒)
local HISTORY_SIZE = 120         -- 履歴保持秒数 (グラフ表示用)
local MAX_TIMESTAMPS = 300       -- メッセージごとの最大タイムスタンプ保持数
local ALERT_THRESHOLD = 50       -- msg/sec超過で警告色
local DANGER_THRESHOLD = 100     -- msg/sec超過で危険色

-- ========================================
-- メッセージカテゴリ定義
-- ========================================
local CATEGORIES = {
	vehicle_lvs = {
		label = "LVS",
		color = Color(255, 180, 80),
		patterns = {"lvs_setinput"},
	},
	vehicle_glide = {
		label = "Glide",
		color = Color(80, 200, 255),
		patterns = {"glide_vr_input", "glide_input_batch", "glide_input_bool", "glide_turret", "glide_vrsetinput"},
	},
	vehicle_simfphys = {
		label = "Simfphys",
		color = Color(200, 150, 255),
		patterns = {"vre_drivingfix"},
	},
	tracking = {
		label = "Tracking",
		color = Color(100, 255, 100),
		patterns = {"vrutil_net_tick", "vrmod_flex"},
	},
	session = {
		label = "Session",
		color = Color(255, 255, 100),
		patterns = {"vrutil_net_join", "vrutil_net_exit", "vrutil_net_switch", "vrutil_net_request", "vrutil_net_enter", "vrutil_net_exitvehicle"},
	},
	pickup = {
		label = "Pickup",
		color = Color(255, 100, 200),
		patterns = {"vrmod_pickup", "vrutil_net_pickup", "vrutil_net_drop", "vrmod_physgun"},
	},
	body = {
		label = "Body",
		color = Color(200, 255, 150),
		patterns = {"vrmod_fbt", "vrmod_doors", "vrmod_flashlight", "vrmod_teleport", "vrmod_pmchange"},
	},
	weapon = {
		label = "Weapon",
		color = Color(255, 150, 150),
		patterns = {"VRMod_Melee", "VRMod_Spawn", "RemoveMag", "SelectEmpty", "DropWeapon", "ChangeWeapon", "vrmod_unoff_holster"},
	},
	other = {
		label = "Other",
		color = Color(180, 180, 180),
		patterns = {},
	},
}

-- カテゴリ順序（表示用）
local CATEGORY_ORDER = {
	"tracking", "vehicle_lvs", "vehicle_glide", "vehicle_simfphys",
	"pickup", "body", "weapon", "session", "other",
}

local function GetCategory(msgName)
	for _, catName in ipairs(CATEGORY_ORDER) do
		local catDef = CATEGORIES[catName]
		if catName ~= "other" then
			for _, pattern in ipairs(catDef.patterns) do
				if string.find(msgName, pattern, 1, true) then
					return catName, catDef
				end
			end
		end
	end
	return "other", CATEGORIES.other
end

-- ========================================
-- データストア
-- ========================================
netmon.sends = netmon.sends or {}       -- [msgName] = entry
netmon._currentMsg = nil                -- 現在のnet.Start追跡用
netmon.active = false
netmon.startTime = 0

-- 履歴 (1秒ごとのスナップショット)
netmon.history = netmon.history or {}          -- [msgName] = { {time, rate, bytesRate}, ... }
netmon.totalHistory = netmon.totalHistory or {} -- { {time, totalRate, totalBytesRate}, ... }
netmon.categoryHistory = netmon.categoryHistory or {} -- [catName] = { {time, rate}, ... }
netmon.lastHistoryTime = 0

-- ========================================
-- データエントリ管理
-- ========================================
local function GetOrCreateEntry(msgName)
	if not netmon.sends[msgName] then
		local catName, catDef = GetCategory(msgName)
		netmon.sends[msgName] = {
			timestamps = {},
			bytes = {},
			totalCount = 0,
			totalBytes = 0,
			peak = 0,
			category = catName,
			categoryColor = catDef.color,
			categoryLabel = catDef.label,
			lastTime = 0,
		}
	end
	return netmon.sends[msgName]
end

-- 1秒ウィンドウ内のレートを計算（古いエントリの自動クリーンアップ含む）
local function CalcRate(entry)
	local now = SysTime()
	local cutoff = now - WINDOW_SIZE
	local count = 0
	local bytesSum = 0

	-- 古いエントリを削除しつつカウント
	local newTimestamps = {}
	local newBytes = {}
	for i, ts in ipairs(entry.timestamps) do
		if ts >= cutoff then
			count = count + 1
			local b = entry.bytes[i] or 0
			bytesSum = bytesSum + b
			table.insert(newTimestamps, ts)
			table.insert(newBytes, b)
		end
	end
	entry.timestamps = newTimestamps
	entry.bytes = newBytes

	local rate = count / WINDOW_SIZE
	if rate > entry.peak then
		entry.peak = rate
	end

	return rate, bytesSum / WINDOW_SIZE
end

-- ========================================
-- net.Start / net.SendToServer デトア
-- ========================================
-- デトアは常にインストールされるが、netmon.active == false なら記録しない
-- オーバーヘッド: boolean チェック1回のみ

local originalNetStart = net.Start
local originalNetSendToServer = net.SendToServer

function net.Start(msgName, unreliable)
	if netmon.active and type(msgName) == "string" then
		netmon._currentMsg = msgName
	end
	return originalNetStart(msgName, unreliable)
end

function net.SendToServer()
	if netmon.active and netmon._currentMsg then
		local entry = GetOrCreateEntry(netmon._currentMsg)
		local now = SysTime()

		table.insert(entry.timestamps, now)
		-- net.BytesWritten(): 現在のメッセージに書き込まれたバイト数
		local bytesWritten = 0
		if net.BytesWritten then
			bytesWritten = net.BytesWritten() / 8 -- ビット→バイト変換
		end
		table.insert(entry.bytes, bytesWritten)

		entry.totalCount = entry.totalCount + 1
		entry.totalBytes = entry.totalBytes + bytesWritten
		entry.lastTime = now

		-- タイムスタンプ上限
		if #entry.timestamps > MAX_TIMESTAMPS then
			table.remove(entry.timestamps, 1)
			table.remove(entry.bytes, 1)
		end
	end
	netmon._currentMsg = nil
	return originalNetSendToServer()
end

Log.Info("netmon", "net.Start/SendToServer detour installed")

-- ========================================
-- 公開API
-- ========================================
function netmon.GetSendRates()
	local rates = {}
	for name, entry in pairs(netmon.sends) do
		local rate, bytesRate = CalcRate(entry)
		rates[name] = {
			rate = rate,
			bytesRate = bytesRate,
			totalCount = entry.totalCount,
			totalBytes = entry.totalBytes,
			peak = entry.peak,
			category = entry.category,
			categoryColor = entry.categoryColor,
			categoryLabel = entry.categoryLabel,
			lastTime = entry.lastTime,
		}
	end
	return rates
end

function netmon.GetTotalSendRate()
	local totalRate = 0
	local totalBytesRate = 0
	for _, entry in pairs(netmon.sends) do
		local rate, bytesRate = CalcRate(entry)
		totalRate = totalRate + rate
		totalBytesRate = totalBytesRate + bytesRate
	end
	return totalRate, totalBytesRate
end

function netmon.GetCategoryRates()
	local catRates = {}
	for _, catName in ipairs(CATEGORY_ORDER) do
		catRates[catName] = { rate = 0, bytesRate = 0, totalCount = 0, color = CATEGORIES[catName].color, label = CATEGORIES[catName].label }
	end
	for _, entry in pairs(netmon.sends) do
		local rate, bytesRate = CalcRate(entry)
		local cat = entry.category
		if catRates[cat] then
			catRates[cat].rate = catRates[cat].rate + rate
			catRates[cat].bytesRate = catRates[cat].bytesRate + bytesRate
			catRates[cat].totalCount = catRates[cat].totalCount + entry.totalCount
		end
	end
	return catRates
end

function netmon.Reset()
	netmon.sends = {}
	netmon.history = {}
	netmon.totalHistory = {}
	netmon.categoryHistory = {}
	netmon._currentMsg = nil
	Log.Info("netmon", "Data reset")
end

function netmon.Start()
	netmon.active = true
	netmon.startTime = SysTime()
	Log.Info("netmon", "Monitoring started")
end

function netmon.Stop()
	netmon.active = false
	Log.Info("netmon", "Monitoring stopped")
end

function netmon.IsActive()
	return netmon.active
end

-- ========================================
-- 履歴スナップショット (1秒ごと)
-- ========================================
hook.Add("Think", "vrmod_debug_netmon_history", function()
	if not netmon.active then return end
	local now = SysTime()
	if now - netmon.lastHistoryTime < 1.0 then return end
	netmon.lastHistoryTime = now

	-- 全体レート
	local totalRate, totalBytesRate = netmon.GetTotalSendRate()
	table.insert(netmon.totalHistory, {
		time = now,
		totalRate = totalRate,
		totalBytesRate = totalBytesRate,
	})
	if #netmon.totalHistory > HISTORY_SIZE then
		table.remove(netmon.totalHistory, 1)
	end

	-- カテゴリ別
	local catRates = netmon.GetCategoryRates()
	for catName, data in pairs(catRates) do
		netmon.categoryHistory[catName] = netmon.categoryHistory[catName] or {}
		table.insert(netmon.categoryHistory[catName], {
			time = now,
			rate = data.rate,
		})
		if #netmon.categoryHistory[catName] > HISTORY_SIZE then
			table.remove(netmon.categoryHistory[catName], 1)
		end
	end

	-- メッセージ別
	local rates = netmon.GetSendRates()
	for name, data in pairs(rates) do
		netmon.history[name] = netmon.history[name] or {}
		table.insert(netmon.history[name], {
			time = now,
			rate = data.rate,
			bytesRate = data.bytesRate,
		})
		if #netmon.history[name] > HISTORY_SIZE then
			table.remove(netmon.history[name], 1)
		end
	end
end)

-- ========================================
-- HUDオーバーレイ
-- ========================================
local hudActive = false

surface.CreateFont("VRNetMonHUD", {
	font = "Courier New",
	size = 14,
	weight = 600,
})
surface.CreateFont("VRNetMonHUDSmall", {
	font = "Courier New",
	size = 12,
	weight = 500,
})
surface.CreateFont("VRNetMonHUDTitle", {
	font = "Arial",
	size = 16,
	weight = 700,
})

local function RateColor(rate)
	if rate >= DANGER_THRESHOLD then return Color(255, 60, 60) end
	if rate >= ALERT_THRESHOLD then return Color(255, 200, 80) end
	return Color(100, 255, 100)
end

hook.Add("HUDPaint", "vrmod_debug_netmon_hud", function()
	if not hudActive or not netmon.active then return end

	local x, y = 20, 100
	local w = 440
	local lineH = 16
	local pad = 8

	-- データ収集
	local totalRate, totalBytesRate = netmon.GetTotalSendRate()
	local rates = netmon.GetSendRates()

	-- レートでソート
	local sorted = {}
	for name, data in pairs(rates) do
		if data.rate > 0 or (SysTime() - data.lastTime < 5) then
			table.insert(sorted, { name = name, data = data })
		end
	end
	table.sort(sorted, function(a, b) return a.data.rate > b.data.rate end)

	local visibleCount = math.min(#sorted, 20)
	local h = pad * 2 + lineH * 3 + lineH * visibleCount + 8

	-- カテゴリサマリー行の追加
	local catRates = netmon.GetCategoryRates()
	local activeCats = {}
	for _, catName in ipairs(CATEGORY_ORDER) do
		if catRates[catName] and catRates[catName].rate > 0 then
			table.insert(activeCats, catRates[catName])
		end
	end
	h = h + lineH -- カテゴリ行

	-- 背景
	surface.SetDrawColor(0, 0, 0, 210)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(80, 80, 80)
	surface.DrawOutlinedRect(x, y, w, h)

	-- タイトル行
	local elapsed = SysTime() - netmon.startTime
	draw.SimpleText(
		string.format("VRMod Network Monitor [%.0fs]", elapsed),
		"VRNetMonHUDTitle", x + pad, y + pad,
		Color(100, 200, 255), TEXT_ALIGN_LEFT
	)

	-- 合計レート行
	draw.SimpleText(
		string.format("TOTAL: %.1f msg/s | %.1f KB/s | %d types active",
			totalRate, totalBytesRate / 1024, #sorted),
		"VRNetMonHUD", x + pad, y + pad + lineH + 2,
		RateColor(totalRate), TEXT_ALIGN_LEFT
	)

	-- カテゴリサマリー行
	local catY = y + pad + lineH * 2 + 4
	local catX = x + pad
	for _, cat in ipairs(activeCats) do
		local text = string.format("%s:%.0f ", cat.label, cat.rate)
		draw.SimpleText(text, "VRNetMonHUDSmall", catX, catY, cat.color)
		surface.SetFont("VRNetMonHUDSmall")
		local tw = surface.GetTextSize(text)
		catX = catX + tw + 4
	end

	-- ヘッダー
	local headerY = catY + lineH + 2
	surface.SetDrawColor(50, 50, 50)
	surface.DrawRect(x + pad, headerY, w - pad * 2, lineH)
	draw.SimpleText("Message", "VRNetMonHUDSmall", x + pad + 4, headerY + 1, Color(200, 200, 200))
	draw.SimpleText("Rate/s", "VRNetMonHUDSmall", x + 260, headerY + 1, Color(200, 200, 200))
	draw.SimpleText("Peak", "VRNetMonHUDSmall", x + 320, headerY + 1, Color(200, 200, 200))
	draw.SimpleText("KB/s", "VRNetMonHUDSmall", x + 370, headerY + 1, Color(200, 200, 200))
	draw.SimpleText("Total", "VRNetMonHUDSmall", x + 410, headerY + 1, Color(200, 200, 200))

	-- メッセージ一覧
	local listY = headerY + lineH
	for i = 1, visibleCount do
		local entry = sorted[i]
		local entryY = listY + (i - 1) * lineH

		-- 背景色（アクティブメッセージ強調）
		if entry.data.rate > 0 then
			local a = math.min(entry.data.rate / ALERT_THRESHOLD * 40, 60)
			surface.SetDrawColor(entry.data.categoryColor.r, entry.data.categoryColor.g, entry.data.categoryColor.b, a)
			surface.DrawRect(x + pad, entryY, w - pad * 2, lineH)
		end

		-- メッセージ名（末尾切り取り）
		local displayName = entry.name
		if #displayName > 30 then
			displayName = "..." .. string.sub(displayName, -27)
		end
		draw.SimpleText(displayName, "VRNetMonHUDSmall", x + pad + 4, entryY + 1, entry.data.categoryColor)
		draw.SimpleText(string.format("%.1f", entry.data.rate), "VRNetMonHUDSmall", x + 260, entryY + 1, RateColor(entry.data.rate))
		draw.SimpleText(string.format("%.0f", entry.data.peak), "VRNetMonHUDSmall", x + 320, entryY + 1, Color(180, 180, 180))
		draw.SimpleText(string.format("%.1f", entry.data.bytesRate / 1024), "VRNetMonHUDSmall", x + 370, entryY + 1, Color(180, 180, 180))
		draw.SimpleText(tostring(entry.data.totalCount), "VRNetMonHUDSmall", x + 410, entryY + 1, Color(150, 150, 150))
	end
end)

-- ========================================
-- デバッグパネル統合タブ
-- ========================================
-- vrmod_debug_panel.lua から呼ばれる

local PANEL_COLORS = {
	bg = Color(30, 30, 30),
	bgLight = Color(40, 40, 40),
	bgCode = Color(25, 25, 30),
	headerBg = Color(45, 45, 55),
	white = Color(255, 255, 255),
	gray = Color(150, 150, 150),
	green = Color(100, 255, 100),
	red = Color(255, 100, 100),
	yellow = Color(255, 255, 100),
	graphBg = Color(20, 20, 25),
	graphGrid = Color(50, 50, 50),
	graphLine = Color(100, 200, 255),
}

function netmon.CreatePanelTab(parent)
	local container = vgui.Create("DPanel", parent)
	container.Paint = function() end

	-- ========== コントロールバー ==========
	local controlBar = vgui.Create("DPanel", container)
	controlBar:Dock(TOP)
	controlBar:SetTall(36)
	controlBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, PANEL_COLORS.headerBg)
	end

	-- Start/Stop ボタン
	local btnToggle = vgui.Create("DButton", controlBar)
	btnToggle:SetText("")
	btnToggle:SetSize(120, 26)
	btnToggle:SetPos(8, 5)
	btnToggle.Paint = function(self, w, h)
		local col = netmon.active and Color(220, 60, 60) or Color(60, 180, 60)
		draw.RoundedBox(3, 0, 0, w, h, col)
		local label = netmon.active and "Stop Monitoring" or "Start Monitoring"
		draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, PANEL_COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnToggle.DoClick = function()
		if netmon.active then netmon.Stop() else netmon.Start() end
	end

	-- Reset ボタン
	local btnReset = vgui.Create("DButton", controlBar)
	btnReset:SetText("")
	btnReset:SetSize(70, 26)
	btnReset:SetPos(134, 5)
	btnReset.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color(80, 80, 80))
		draw.SimpleText("Reset", "VRDebugUISmall", w / 2, h / 2, PANEL_COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnReset.DoClick = function() netmon.Reset() end

	-- HUD overlay ボタン
	local btnHud = vgui.Create("DButton", controlBar)
	btnHud:SetText("")
	btnHud:SetSize(100, 26)
	btnHud:SetPos(210, 5)
	btnHud.Paint = function(self, w, h)
		local col = hudActive and Color(80, 180, 80) or Color(80, 80, 80)
		draw.RoundedBox(3, 0, 0, w, h, col)
		draw.SimpleText("HUD Overlay", "VRDebugUISmall", w / 2, h / 2, PANEL_COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnHud.DoClick = function()
		hudActive = not hudActive
		if hudActive and not netmon.active then netmon.Start() end
	end

	-- CSV Export ボタン
	local btnExport = vgui.Create("DButton", controlBar)
	btnExport:SetText("")
	btnExport:SetSize(90, 26)
	btnExport:SetPos(316, 5)
	btnExport.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color(80, 150, 220))
		draw.SimpleText("Export CSV", "VRDebugUISmall", w / 2, h / 2, PANEL_COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnExport.DoClick = function()
		local path = netmon.ExportCSV()
		if path then
			chat.AddText(PANEL_COLORS.green, "[NetMon] ", PANEL_COLORS.white, "Exported: " .. path)
		end
	end

	-- ステータスラベル
	local statusLabel = vgui.Create("DLabel", controlBar)
	statusLabel:SetFont("VRDebugUIBold")
	statusLabel:SetPos(420, 10)
	statusLabel.Think = function(self)
		if netmon.active then
			local totalRate = netmon.GetTotalSendRate()
			local elapsed = SysTime() - netmon.startTime
			self:SetText(string.format("ACTIVE %.0fs | %.1f msg/s", elapsed, totalRate))
			self:SetTextColor(RateColor(totalRate))
		else
			self:SetText("INACTIVE")
			self:SetTextColor(PANEL_COLORS.gray)
		end
		self:SizeToContents()
	end

	-- ========== メイン領域（上下分割）==========
	local mainArea = vgui.Create("DVerticalDivider", container)
	mainArea:Dock(FILL)
	mainArea:DockMargin(0, 2, 0, 0)
	mainArea:SetDividerHeight(4)
	mainArea:SetTopHeight(350)
	mainArea:SetTopMin(200)
	mainArea:SetBottomMin(120)

	-- ========== 上部: メッセージリスト ==========
	local listPanel = vgui.Create("DPanel")
	listPanel.Paint = function() end

	-- カテゴリフィルターバー
	local filterBar = vgui.Create("DPanel", listPanel)
	filterBar:Dock(TOP)
	filterBar:SetTall(22)
	filterBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(35, 35, 40))
	end

	-- カテゴリフィルター状態
	local categoryFilters = {}
	for _, catName in ipairs(CATEGORY_ORDER) do
		categoryFilters[catName] = true
	end

	local filterX = 4
	for _, catName in ipairs(CATEGORY_ORDER) do
		local catDef = CATEGORIES[catName]
		local btn = vgui.Create("DButton", filterBar)
		btn:SetText("")
		btn:SetSize(0, 18)
		btn:SetPos(filterX, 2)

		surface.SetFont("VRDebugUISmall")
		local tw = surface.GetTextSize(catDef.label)
		btn:SetSize(tw + 12, 18)

		btn.Paint = function(self, w, h)
			local enabled = categoryFilters[catName]
			local col = enabled and catDef.color or Color(60, 60, 60)
			draw.RoundedBox(2, 0, 0, w, h, col)
			local textCol = enabled and Color(0, 0, 0) or Color(120, 120, 120)
			draw.SimpleText(catDef.label, "VRDebugUISmall", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			categoryFilters[catName] = not categoryFilters[catName]
		end

		filterX = filterX + tw + 16
	end

	-- メッセージリスト
	local list = vgui.Create("DListView", listPanel)
	list:Dock(FILL)
	list:DockMargin(4, 2, 4, 4)
	list:AddColumn("Category"):SetFixedWidth(70)
	list:AddColumn("Message Name"):SetFixedWidth(250)
	list:AddColumn("Rate/s"):SetFixedWidth(65)
	list:AddColumn("Peak/s"):SetFixedWidth(65)
	list:AddColumn("Bytes/s"):SetFixedWidth(70)
	list:AddColumn("Total Count"):SetFixedWidth(80)
	list:AddColumn("Total KB"):SetFixedWidth(70)
	list:AddColumn("Last"):SetFixedWidth(60)
	list:SetMultiSelect(false)
	list.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, PANEL_COLORS.bgCode)
	end

	-- リスト更新
	local lastListUpdate = 0
	list.Think = function(self)
		local now = SysTime()
		if now - lastListUpdate < 0.5 then return end
		lastListUpdate = now

		self:Clear()
		local rates = netmon.GetSendRates()

		-- ソート
		local sorted = {}
		for name, data in pairs(rates) do
			if categoryFilters[data.category] then
				table.insert(sorted, { name = name, data = data })
			end
		end
		table.sort(sorted, function(a, b) return a.data.rate > b.data.rate end)

		for _, entry in ipairs(sorted) do
			local d = entry.data
			local age = now - d.lastTime
			local timeStr = d.lastTime == 0 and "-" or (age < 1 and "NOW" or string.format("%.0fs", age))

			local line = self:AddLine(
				d.categoryLabel,
				entry.name,
				string.format("%.1f", d.rate),
				string.format("%.0f", d.peak),
				string.format("%.0f", d.bytesRate),
				tostring(d.totalCount),
				string.format("%.1f", d.totalBytes / 1024),
				timeStr
			)

			-- 色分け
			if d.rate >= DANGER_THRESHOLD then
				for _, col in pairs(line.Columns) do col:SetTextColor(PANEL_COLORS.red) end
			elseif d.rate >= ALERT_THRESHOLD then
				for _, col in pairs(line.Columns) do col:SetTextColor(PANEL_COLORS.yellow) end
			elseif d.rate > 0 then
				for _, col in pairs(line.Columns) do col:SetTextColor(d.categoryColor) end
			elseif age < 10 then
				for _, col in pairs(line.Columns) do col:SetTextColor(PANEL_COLORS.gray) end
			end
		end
	end

	-- ========== 下部: レートグラフ ==========
	local graphPanel = vgui.Create("DPanel")
	graphPanel.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, PANEL_COLORS.graphBg)

		local padL, padR, padT, padB = 50, 10, 25, 20
		local gw = w - padL - padR
		local gh = h - padT - padB

		-- タイトル
		draw.SimpleText("Send Rate (msg/s) — Last " .. HISTORY_SIZE .. "s",
			"VRDebugUISmall", padL, 5, PANEL_COLORS.white)

		-- グリッド線とY軸ラベル
		local maxRate = 10
		for _, snapshot in ipairs(netmon.totalHistory) do
			if snapshot.totalRate > maxRate then maxRate = snapshot.totalRate end
		end
		maxRate = math.ceil(maxRate / 10) * 10 -- 10の倍数に切り上げ
		if maxRate < 10 then maxRate = 10 end

		for i = 0, 4 do
			local gy = padT + gh - (i / 4) * gh
			surface.SetDrawColor(PANEL_COLORS.graphGrid)
			surface.DrawLine(padL, gy, padL + gw, gy)
			local val = maxRate * (i / 4)
			draw.SimpleText(string.format("%.0f", val), "VRDebugUISmall",
				padL - 5, gy - 6, PANEL_COLORS.gray, TEXT_ALIGN_RIGHT)
		end

		-- 閾値ライン
		if ALERT_THRESHOLD <= maxRate then
			local alertY = padT + gh - (ALERT_THRESHOLD / maxRate) * gh
			surface.SetDrawColor(255, 200, 80, 60)
			surface.DrawLine(padL, alertY, padL + gw, alertY)
		end
		if DANGER_THRESHOLD <= maxRate then
			local dangerY = padT + gh - (DANGER_THRESHOLD / maxRate) * gh
			surface.SetDrawColor(255, 60, 60, 60)
			surface.DrawLine(padL, dangerY, padL + gw, dangerY)
		end

		-- X軸
		surface.SetDrawColor(PANEL_COLORS.graphGrid)
		surface.DrawLine(padL, padT + gh, padL + gw, padT + gh)

		-- カテゴリ別スタックエリアグラフ
		local now = SysTime()
		local timeSpan = HISTORY_SIZE

		-- 各カテゴリのラインを描画
		for catIdx = #CATEGORY_ORDER, 1, -1 do
			local catName = CATEGORY_ORDER[catIdx]
			if not categoryFilters[catName] then continue end

			local hist = netmon.categoryHistory[catName]
			if not hist or #hist < 2 then continue end

			local catColor = CATEGORIES[catName].color
			surface.SetDrawColor(catColor.r, catColor.g, catColor.b, 180)

			local prevX, prevY
			for j, snapshot in ipairs(hist) do
				local age = now - snapshot.time
				local fx = padL + (1 - age / timeSpan) * gw
				local fy = padT + gh - math.Clamp(snapshot.rate / maxRate, 0, 1) * gh

				if prevX then
					surface.DrawLine(prevX, prevY, fx, fy)
				end
				prevX, prevY = fx, fy
			end
		end

		-- 合計ライン（白、太め）
		if #netmon.totalHistory >= 2 then
			local prevX, prevY
			for j, snapshot in ipairs(netmon.totalHistory) do
				local age = now - snapshot.time
				local fx = padL + (1 - age / timeSpan) * gw
				local fy = padT + gh - math.Clamp(snapshot.totalRate / maxRate, 0, 1) * gh

				if prevX then
					surface.SetDrawColor(255, 255, 255, 200)
					surface.DrawLine(prevX, prevY, fx, fy)
					-- 太さを出すために1px上下にも描画
					surface.SetDrawColor(255, 255, 255, 80)
					surface.DrawLine(prevX, prevY - 1, fx, fy - 1)
					surface.DrawLine(prevX, prevY + 1, fx, fy + 1)
				end
				prevX, prevY = fx, fy
			end
		end

		-- 凡例
		local legendX = padL + 5
		local legendY = padT + 2
		for _, catName in ipairs(CATEGORY_ORDER) do
			if not categoryFilters[catName] then continue end
			local catDef = CATEGORIES[catName]
			local catHist = netmon.categoryHistory[catName]
			if not catHist or #catHist == 0 then continue end
			local lastRate = catHist[#catHist].rate
			if lastRate <= 0 then continue end

			surface.SetDrawColor(catDef.color)
			surface.DrawRect(legendX, legendY + 3, 8, 8)
			draw.SimpleText(string.format("%s:%.0f", catDef.label, lastRate),
				"VRDebugUISmall", legendX + 12, legendY, catDef.color)
			surface.SetFont("VRDebugUISmall")
			local tw = surface.GetTextSize(string.format("%s:%.0f", catDef.label, lastRate))
			legendX = legendX + tw + 22
		end
	end

	mainArea:SetTop(listPanel)
	mainArea:SetBottom(graphPanel)

	return container
end

-- ========================================
-- CSV エクスポート
-- ========================================
function netmon.ExportCSV()
	local rates = netmon.GetSendRates()
	local lines = { "message_name,category,rate_per_sec,peak_per_sec,bytes_per_sec,total_count,total_bytes" }

	local sorted = {}
	for name, data in pairs(rates) do
		table.insert(sorted, { name = name, data = data })
	end
	table.sort(sorted, function(a, b) return a.data.rate > b.data.rate end)

	for _, entry in ipairs(sorted) do
		local d = entry.data
		table.insert(lines, string.format("%s,%s,%.2f,%.0f,%.0f,%d,%d",
			entry.name, d.category, d.rate, d.peak, d.bytesRate, d.totalCount, d.totalBytes))
	end

	local csv = table.concat(lines, "\n")
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local filePath = "vrmod_debug/netmon_" .. timestamp .. ".txt" -- file.Write は .txt のみ
	file.CreateDir("vrmod_debug")
	file.Write(filePath, csv)

	Log.Info("netmon", "CSV exported: data/" .. filePath)
	return "data/" .. filePath
end

-- ========================================
-- コンソールコマンド
-- ========================================
concommand.Add("vrmod_unoff_netmon_hud", function()
	hudActive = not hudActive
	if hudActive and not netmon.active then
		netmon.Start()
	end
	print("[VRMod NetMon] HUD overlay: " .. (hudActive and "ON" or "OFF"))
end)

concommand.Add("vrmod_unoff_netmon", function(ply, cmd, args)
	local sub = args[1]
	if sub == "start" or (not netmon.active and not sub) then
		netmon.Start()
	elseif sub == "stop" or (netmon.active and not sub) then
		netmon.Stop()
	elseif sub == "reset" then
		netmon.Reset()
		print("[VRMod NetMon] Data reset")
	elseif sub == "dump" then
		local rates = netmon.GetSendRates()
		local sorted = {}
		for name, data in pairs(rates) do
			table.insert(sorted, { name = name, data = data })
		end
		table.sort(sorted, function(a, b) return a.data.rate > b.data.rate end)

		print("=== VRMod Network Monitor Dump ===")
		local totalRate, totalBytesRate = netmon.GetTotalSendRate()
		print(string.format("  TOTAL: %.1f msg/s | %.1f KB/s", totalRate, totalBytesRate / 1024))
		print(string.format("  %-35s %8s %8s %8s %10s", "Message", "Rate/s", "Peak", "B/s", "Total"))
		print(string.rep("-", 80))
		for _, entry in ipairs(sorted) do
			print(string.format("  [%s] %-28s %8.1f %8.0f %8.0f %10d",
				entry.data.categoryLabel, entry.name, entry.data.rate, entry.data.peak, entry.data.bytesRate, entry.data.totalCount))
		end
		print("==================================")
	elseif sub == "csv" then
		local path = netmon.ExportCSV()
		if path then
			print("[VRMod NetMon] Exported: " .. path)
		end
	else
		print("[VRMod NetMon] Usage: vrmod_unoff_netmon [start|stop|reset|dump|csv]")
		print("[VRMod NetMon] Status: " .. (netmon.active and "ACTIVE" or "INACTIVE"))
	end
end)

-- ========================================
-- VR終了時クリーンアップ
-- ========================================
hook.Add("VRMod_Exit", "vrmod_debug_netmon_cleanup", function(ply)
	if ply ~= LocalPlayer() then return end
	-- VR終了時はモニタリング停止（データは保持、パネルで確認可能）
	if netmon.active then
		netmon.Stop()
	end
end)

Log.Info("netmon", "Network Monitor initialized. Commands: vrmod_unoff_netmon, vrmod_unoff_netmon_hud")

--------[vrmod_debug_netmon.lua]End--------
