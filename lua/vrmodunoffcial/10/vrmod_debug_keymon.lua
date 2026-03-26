--------[vrmod_debug_keymon.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- Key & VR Action Monitor
-- キーボード入力とVRアクションを統合ログに記録
--
-- DFrame/VGUIがキーボードフォーカスを奪う問題を回避するため、
-- PlayerButtonDownではなくThink内でinput.IsButtonDown()をポーリング。
-- パネルが閉じていてもモニタリングを継続可能。
-- ========================================

local Log = vrmod.debug.Log

local cv_keymon = CreateClientConVar("vrmod_unoff_debug_keymon", "0", true, false,
	"Auto-start key monitor on load (persists across panel open/close)", 0, 1)

-- ----------------------------------------
-- データストア
-- ----------------------------------------
vrmod.debug.keymon = vrmod.debug.keymon or {}
local keymon = vrmod.debug.keymon

keymon.active = false
keymon.log = keymon.log or {}
keymon.iskeydown_callers = keymon.iskeydown_callers or {}

local LOG_MAX = 200

-- ----------------------------------------
-- 色定義（vrmod_debug_panel.luaと揃える）
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
	red = Color(255, 100, 100),
	cyan = Color(100, 220, 255),
	separator = Color(60, 60, 60),
}

-- ----------------------------------------
-- ヘルパー: hookテーブルからコールバック情報取得
-- ----------------------------------------
local SELF_HOOK_NAMES = {
	["vrmod_debug_keymon_poll"] = true,
	["vrmod_debug_keymon_vr"] = true,
	["vrmod_debug_keymon_cleanup"] = true,
}

local function GetCallbackInfo(hookName)
	local result = {}
	local tbl = hook.GetTable()[hookName]
	if not tbl then return result end
	for name, fn in pairs(tbl) do
		if not SELF_HOOK_NAMES[name] then
			local ok, info = pcall(debug.getinfo, fn, "Sl")
			if ok and info then
				table.insert(result, {
					name = name,
					source = info.short_src or "?",
					line = info.linedefined or 0,
					lastline = info.lastlinedefined or 0,
				})
			end
		end
	end
	-- GAMEMODE メソッドも検出
	local gm = gmod and gmod.GetGamemode and gmod.GetGamemode() or GAMEMODE
	if gm and gm[hookName] then
		local ok, info = pcall(debug.getinfo, gm[hookName], "Sl")
		if ok and info then
			table.insert(result, {
				name = "GM:" .. hookName,
				source = info.short_src or "?",
				line = info.linedefined or 0,
				lastline = info.lastlinedefined or 0,
			})
		end
	end
	table.sort(result, function(a, b) return a.name < b.name end)
	return result
end

-- ----------------------------------------
-- ヘルパー: ログエントリ追加
-- ----------------------------------------
local function AddLogEntry(entryType, event, name, buttonCode, binding, callbacks, timings)
	local entry = {
		time = CurTime(),
		type = entryType,    -- "key" or "vr"
		event = event,       -- "PRESS" or "RELEASE"
		name = name,         -- キー名 or アクション名
		buttonCode = buttonCode,
		binding = binding or "",
		callbacks = callbacks or {},
		timings = timings or {},  -- コールバック名→実行時間(秒)
	}

	table.insert(keymon.log, 1, entry)

	-- 循環バッファ: 最大LOG_MAX件
	while #keymon.log > LOG_MAX do
		table.remove(keymon.log)
	end
end

-- ----------------------------------------
-- コールバック情報のサマリ文字列（ACTIVEなものを優先表示）
-- ----------------------------------------
local function CallbackSummary(callbacks, timings)
	if #callbacks == 0 then return "(none)" end

	-- タイミングがあればACTIVEなコールバックを先に表示
	if timings and next(timings) then
		local active = {}
		local inactive = {}
		for _, cb in ipairs(callbacks) do
			local t = timings[cb.name]
			if t and t > ACTIVE_THRESHOLD then
				table.insert(active, cb.name .. "*")
			else
				table.insert(inactive, cb.name)
			end
		end
		if #active > 0 then
			local str = table.concat(active, ", ")
			if #inactive > 0 then
				str = str .. " +" .. #inactive .. " idle"
			end
			return str
		end
	end

	-- タイミングなし or 全てidle
	local names = {}
	for i = 1, math.min(5, #callbacks) do
		table.insert(names, callbacks[i].name)
	end
	local str = table.concat(names, ", ")
	if #callbacks > 5 then
		str = str .. " +" .. (#callbacks - 5) .. " more"
	end
	return str
end

-- ----------------------------------------
-- コールバック詳細テキスト（タイミング付き）
-- ----------------------------------------
local ACTIVE_THRESHOLD = 0.00005 -- 0.05ms以上で「ACTIVE」判定

local function CallbackDetailText(entry)
	local lines = {}
	local hookName = entry.type == "key" and "PlayerButton" .. (entry.event == "PRESS" and "Down" or "Up")
		or "VRMod_Input"
	local hasTimings = entry.timings and next(entry.timings) ~= nil

	table.insert(lines, "Callbacks for " .. hookName .. (hasTimings and " (timed):" or ":"))
	table.insert(lines, "")

	if #entry.callbacks == 0 then
		table.insert(lines, "  (no callbacks registered)")
	else
		-- タイミングがある場合、実行時間の降順でソート（遅い=仕事した=上）
		local sorted = {}
		for _, cb in ipairs(entry.callbacks) do
			table.insert(sorted, cb)
		end
		if hasTimings then
			table.sort(sorted, function(a, b)
				local ta = entry.timings[a.name] or 0
				local tb = entry.timings[b.name] or 0
				return ta > tb
			end)
		end

		for _, cb in ipairs(sorted) do
			local elapsed = entry.timings and entry.timings[cb.name]
			local timeStr = ""
			local marker = ""
			if elapsed then
				timeStr = string.format("  %.3fms", elapsed * 1000)
				if elapsed > ACTIVE_THRESHOLD then
					marker = "  *** ACTIVE ***"
				end
			end
			table.insert(lines, string.format("  %s%s%s", cb.name, timeStr, marker))
			table.insert(lines, string.format("    -> %s:%d-%d", cb.source, cb.line, cb.lastline))
		end
	end

	if entry.type == "key" and entry.binding ~= "" then
		table.insert(lines, "")
		table.insert(lines, "Key binding: " .. entry.binding)
	end

	if hasTimings then
		table.insert(lines, "")
		table.insert(lines, "--- *** ACTIVE *** = >0.05ms = this callback did actual work for this key")
	end

	return table.concat(lines, "\n")
end

-- ----------------------------------------
-- Think ベースのキー状態ポーリング
-- DFrameのキーボードフォーカスを回避する
-- ----------------------------------------
local prevKeyState = {}
local BUTTON_MAX = BUTTON_CODE_LAST or 171

-- IsKeyDownキャプチャ用: "Press a key..."モードで最初に検出したキーをターゲットにする
local iskdWaitingForKey = false

local function PollKeyStates()
	for code = 1, BUTTON_MAX do
		local down = input.IsButtonDown(code)
		local wasDown = prevKeyState[code]

		if down and not wasDown then
			-- キーが押された
			-- IsKeyDownキャプチャ待ちなら、このキーをターゲットに
			if iskdWaitingForKey then
				iskdWaitingForKey = false
				keymon.StartIsKeyDownCapture(code)
			end

			local keyName = input.GetKeyName(code) or "?"
			local binding = input.LookupKeyBinding(code) or ""
			local callbacks = GetCallbackInfo("PlayerButtonDown")
			-- hook.Callラッパーが計測したタイミングを渡す
			-- （同フレーム内: PlayerButtonDown → Think の順なので既に計測済み）
			AddLogEntry("key", "PRESS", keyName .. " (" .. code .. ")", code, binding, callbacks, lastCallbackTimings)

		elseif not down and wasDown then
			-- キーが離された
			local keyName = input.GetKeyName(code) or "?"
			local binding = input.LookupKeyBinding(code) or ""
			local callbacks = GetCallbackInfo("PlayerButtonUp")
			AddLogEntry("key", "RELEASE", keyName .. " (" .. code .. ")", code, binding, callbacks, lastCallbackTimings)
		end

		prevKeyState[code] = down or nil
	end
end

-- ----------------------------------------
-- hook.Call ラッパー: PlayerButtonDown/Up の各コールバック実行時間を計測
-- 「どのコールバックが実際に仕事をしたか」を特定する
-- ----------------------------------------
local lastCallbackTimings = {} -- 直近のPlayerButtonDown/Up呼び出しのタイミング
local origHookCall = nil
local hookCallWrapper = nil

local function InstallHookCallWrapper()
	if hookCallWrapper then return end -- 既にインストール済み
	origHookCall = hook.Call

	hookCallWrapper = function(name, gm, ...)
		-- PlayerButtonDown/Up以外は素通し
		if not keymon.active or (name ~= "PlayerButtonDown" and name ~= "PlayerButtonUp") then
			return origHookCall(name, gm, ...)
		end

		-- 各コールバックを個別にタイミング計測しながら実行
		local timings = {}
		local hookTbl = hook.GetTable()[name]
		if hookTbl then
			for cbName, fn in pairs(hookTbl) do
				if not SELF_HOOK_NAMES[cbName] then
					local start = SysTime()
					local a, b, c, d, e, f = fn(...)
					timings[cbName] = SysTime() - start
					if a ~= nil then
						lastCallbackTimings = timings
						return a, b, c, d, e, f
					end
				else
					fn(...) -- 自分自身のフックはタイミング不要
				end
			end
		end

		-- GAMEMODE メソッドも計測
		if gm and gm[name] then
			local start = SysTime()
			local a, b, c, d, e, f = gm[name](gm, ...)
			timings["GM:" .. name] = SysTime() - start
			lastCallbackTimings = timings
			if a ~= nil then return a, b, c, d, e, f end
		end

		lastCallbackTimings = timings
	end

	hook.Call = hookCallWrapper
	Log.Debug("keymon", "hook.Call wrapper installed for PlayerButtonDown/Up timing")
end

local function RemoveHookCallWrapper()
	if not hookCallWrapper then return end
	-- 自分のラッパーがまだ最上位の場合のみ復元
	-- （別のシステムが上からラップしている場合は触らない）
	if hook.Call == hookCallWrapper then
		hook.Call = origHookCall
	end
	hookCallWrapper = nil
	origHookCall = nil
	lastCallbackTimings = {}
	Log.Debug("keymon", "hook.Call wrapper removed")
end

-- ----------------------------------------
-- モニタリング開始/停止
-- パネルとは独立して動作する
-- ----------------------------------------
local function StartMonitoring()
	if keymon.active then return end
	keymon.active = true
	prevKeyState = {}
	lastCallbackTimings = {}

	-- hook.Callラッパーでコールバック実行時間を計測
	InstallHookCallWrapper()

	-- Think内でキー状態をポーリング（VGUI focus無関係）
	hook.Add("Think", "vrmod_debug_keymon_poll", function()
		if not keymon.active then return end
		PollKeyStates()
	end)

	-- VRMod_Input
	hook.Add("VRMod_Input", "vrmod_debug_keymon_vr", function(action, pressed)
		if not keymon.active then return end
		local callbacks = GetCallbackInfo("VRMod_Input")
		AddLogEntry("vr", pressed and "PRESS" or "RELEASE", action, nil, "", callbacks)
	end)

	Log.Info("keymon", "Key & VR Action monitoring started (Think polling + callback timing)")
	print("[VRMod KeyMon] Monitoring started. Callback timing enabled.")
end

local function StopMonitoring()
	keymon.active = false
	prevKeyState = {}
	RemoveHookCallWrapper()
	hook.Remove("Think", "vrmod_debug_keymon_poll")
	hook.Remove("VRMod_Input", "vrmod_debug_keymon_vr")
	Log.Info("keymon", "Key & VR Action monitoring stopped")
	print("[VRMod KeyMon] Monitoring stopped.")
end

keymon.Start = StartMonitoring
keymon.Stop = StopMonitoring

-- ----------------------------------------
-- IsKeyDown スナップショット (2秒間限定)
-- アドオンは input.IsKeyDown / IsButtonDown / IsMouseDown の
-- いずれかを使うため、3関数全てをラップする
-- ----------------------------------------
local iskeydownCapturing = false
local iskeydownTargetKey = nil
local origIsKeyDown = nil
local origIsButtonDown = nil
local origIsMouseDown = nil

-- 前方宣言（StartIsKeyDownCaptureから参照されるため）
local StopIsKeyDownCapture

-- フルスタックトレースを取得
-- CaptureFullStack自身 + 呼び出し元ラッパーの2段を自動スキップ
-- → レベル3から開始 = 実際の外部呼び出し元から記録
local function CaptureFullStack()
	local frames = {}
	local level = 3 -- 1=自分, 2=ラッパー関数, 3=実際の呼び出し元
	while true do
		local info = debug.getinfo(level, "Sl")
		if not info then break end
		if info.short_src and info.currentline then
			table.insert(frames, info.short_src .. ":" .. info.currentline)
		end
		level = level + 1
		if level > 50 then break end -- 安全上限
	end
	return frames
end

-- 呼び出し元を記録するラッパーを生成
-- 自分自身のPollKeyStates()からの呼び出しは除外する
local function MakeCallerTracker(originalFn, funcName)
	return function(code)
		if code == iskeydownTargetKey then
			local frames = CaptureFullStack()
			if #frames > 0 then
				-- 自分自身のポーリングは除外（結果を汚染するため）
				local isSelf = string.find(frames[1], "vrmod_debug_keymon", 1, true)
				if not isSelf then
					local stackStr = table.concat(frames, " <- ")
					local label = funcName .. " | " .. stackStr
					keymon.iskeydown_callers[label] = (keymon.iskeydown_callers[label] or 0) + 1
				end
			end
		end
		return originalFn(code)
	end
end

local function StartIsKeyDownCapture(targetKey)
	if iskeydownCapturing then return end
	if not targetKey or targetKey < 1 then
		Log.Warn("keymon", "IsKeyDown capture: invalid target key")
		return
	end

	iskeydownCapturing = true
	iskeydownTargetKey = targetKey
	keymon.iskeydown_callers = {}

	-- 3関数全てをラップ
	-- 注意: !vrmod_input_emu.lua が既にデトアしている場合、そのデトア版をラップする
	origIsKeyDown = input.IsKeyDown
	origIsButtonDown = input.IsButtonDown
	origIsMouseDown = input.IsMouseDown

	input.IsKeyDown = MakeCallerTracker(origIsKeyDown, "IsKeyDown")
	input.IsButtonDown = MakeCallerTracker(origIsButtonDown, "IsButtonDown")
	input.IsMouseDown = MakeCallerTracker(origIsMouseDown, "IsMouseDown")

	-- 2秒後に自動停止
	timer.Create("vrmod_debug_keymon_iskeydown", 2, 1, function()
		StopIsKeyDownCapture()
	end)

	local keyName = input.GetKeyName(targetKey) or "?"
	Log.Info("keymon", "IsKeyDown capture started for " .. keyName .. " (" .. targetKey .. ") (2s)")
	print("[VRMod KeyMon] IsKeyDown capturing for " .. keyName .. " - press the key now!")
end

StopIsKeyDownCapture = function()
	if not iskeydownCapturing then return end
	iskeydownCapturing = false
	timer.Remove("vrmod_debug_keymon_iskeydown")

	-- 元の3関数を復元
	if origIsKeyDown then
		input.IsKeyDown = origIsKeyDown
		origIsKeyDown = nil
	end
	if origIsButtonDown then
		input.IsButtonDown = origIsButtonDown
		origIsButtonDown = nil
	end
	if origIsMouseDown then
		input.IsMouseDown = origIsMouseDown
		origIsMouseDown = nil
	end

	local count = table.Count(keymon.iskeydown_callers)
	Log.Info("keymon", "Input capture stopped. Found " .. count .. " callers")
	print("[VRMod KeyMon] Input capture done. " .. count .. " callers found.")
end

keymon.StartIsKeyDownCapture = StartIsKeyDownCapture
keymon.StopIsKeyDownCapture = StopIsKeyDownCapture
keymon.IsCapturingIsKeyDown = function() return iskeydownCapturing end
keymon.IsWaitingForKey = function() return iskdWaitingForKey end
keymon.SetWaitingForKey = function(v) iskdWaitingForKey = v end

-- ----------------------------------------
-- IsKeyDownスナップショット結果テキスト
-- ----------------------------------------
local function IsKeyDownResultText()
	local callers = keymon.iskeydown_callers
	if not callers or table.Count(callers) == 0 then
		return "No input polling callers captured yet.\nUse 'IsKeyDown Capture' and press the target key."
	end

	local lines = {}
	local keyName = iskeydownTargetKey and (input.GetKeyName(iskeydownTargetKey) or "?") or "?"
	table.insert(lines, "input.Is*Down(" .. keyName .. ") callers (2s snapshot):")
	table.insert(lines, "Wraps: IsKeyDown + IsButtonDown + IsMouseDown")
	table.insert(lines, "")

	-- 呼び出し回数でソート
	local sorted = {}
	for src, count in pairs(callers) do
		table.insert(sorted, { source = src, count = count })
	end
	table.sort(sorted, function(a, b) return a.count > b.count end)

	for _, entry in ipairs(sorted) do
		table.insert(lines, string.format("  %s  (%d calls)", entry.source, entry.count))
	end

	return table.concat(lines, "\n")
end

-- ----------------------------------------
-- クリーンアップ (L27準拠)
-- ----------------------------------------
hook.Add("VRMod_Exit", "vrmod_debug_keymon_cleanup", function()
	StopMonitoring()
	StopIsKeyDownCapture()
end)

-- ----------------------------------------
-- コンソールコマンド（パネル無しでも操作可能）
-- ----------------------------------------
concommand.Add("vrmod_keymon", function(_, _, args)
	local sub = args[1] or ""
	if sub == "start" then
		StartMonitoring()
	elseif sub == "stop" then
		StopMonitoring()
	elseif sub == "clear" then
		keymon.log = {}
		keymon.iskeydown_callers = {}
		print("[VRMod KeyMon] Log cleared.")
	elseif sub == "status" then
		print("[VRMod KeyMon] Active: " .. tostring(keymon.active))
		print("[VRMod KeyMon] Log entries: " .. #keymon.log)
		print("[VRMod KeyMon] IsKeyDown capturing: " .. tostring(iskeydownCapturing))
		print("[VRMod KeyMon] Target key: " .. tostring(iskeydownTargetKey))
	elseif sub == "diag" then
		-- ===== 汎用診断モード =====
		-- 1) input.Is*Down呼び出しをキャプチャ
		-- 2) 全Thinkフックの実行時間を計測（キー押下で重くなるフック=犯人）
		-- 3) 呼び出された関数をトレース
		print("===== KeyMon Diagnostic (1s) =====")
		print("[DIAG] Wrapping: input.Is*Down + hook.Call(Think) timing")
		print("[DIAG] Press any key during the next 1 second!")
		print("")

		-- --- Part 1: input.Is*Down ラッパー ---
		local origIsKeyDown = input.IsKeyDown
		local origIsButtonDown = input.IsButtonDown
		local origIsMouseDown = input.IsMouseDown
		local diagCallers = {}
		local diagCount = 0

		local function RecordCaller(funcName, code)
			diagCount = diagCount + 1
			if diagCount <= 800 then
				local info = debug.getinfo(3, "Sl")
				local src = info and info.short_src and info.short_src .. ":" .. (info.currentline or 0) or "?"
				local key = funcName .. " | " .. src .. " (code=" .. tostring(code) .. ")"
				diagCallers[key] = (diagCallers[key] or 0) + 1
			end
		end

		rawset(input, "IsKeyDown", function(code) RecordCaller("IsKeyDown", code) return origIsKeyDown(code) end)
		rawset(input, "IsButtonDown", function(code) RecordCaller("IsButtonDown", code) return origIsButtonDown(code) end)
		rawset(input, "IsMouseDown", function(code) RecordCaller("IsMouseDown", code) return origIsMouseDown(code) end)

		-- --- Part 2: Thinkフック実行時間計測 ---
		local thinkTimings = {} -- [callbackName] = {total=0, calls=0, source=""}
		local origHookCall = hook.Call

		hook.Call = function(name, gm, ...)
			if name ~= "Think" then
				return origHookCall(name, gm, ...)
			end

			-- Think: 各コールバックを個別に計測
			local hookTbl = hook.GetTable()["Think"]
			if hookTbl then
				for cbName, fn in pairs(hookTbl) do
					local start = SysTime()
					local a, b, c = fn(...)
					local elapsed = SysTime() - start

					if not thinkTimings[cbName] then
						local info = debug.getinfo(fn, "Sl")
						thinkTimings[cbName] = {
							total = 0,
							calls = 0,
							source = info and info.short_src or "?",
							line = info and info.linedefined or 0,
						}
					end
					thinkTimings[cbName].total = thinkTimings[cbName].total + elapsed
					thinkTimings[cbName].calls = thinkTimings[cbName].calls + 1

					if a ~= nil then return a, b, c end
				end
			end

			if gm and gm["Think"] then
				return gm["Think"](gm, ...)
			end
		end

		if jit and jit.flush then jit.flush() end

		timer.Simple(1, function()
			-- 復元
			rawset(input, "IsKeyDown", origIsKeyDown)
			rawset(input, "IsButtonDown", origIsButtonDown)
			rawset(input, "IsMouseDown", origIsMouseDown)
			hook.Call = origHookCall
			if jit and jit.flush then jit.flush() end

			-- ===== 結果出力 =====
			print("===== Diagnostic Result (1s) =====")
			print("")

			-- Part 1結果: IsKeyDown呼び出し元
			local sorted = {}
			for key, count in pairs(diagCallers) do
				if not string.find(key, "vrmod_debug_keymon", 1, true) then
					table.insert(sorted, { key = key, count = count })
				end
			end
			table.sort(sorted, function(a, b) return a.count > b.count end)

			print("--- input.Is*Down callers ---")
			if #sorted == 0 then
				print("  (No external callers detected)")
			else
				for i, entry in ipairs(sorted) do
					if i > 30 then
						print("  ... +" .. (#sorted - 30) .. " more")
						break
					end
					print("  " .. entry.key .. "  x" .. entry.count)
				end
			end

			-- Part 2結果: Thinkフック実行時間（遅い順=仕事してるフック）
			print("")
			print("--- Think hook timing (sorted by total time) ---")
			local thinkSorted = {}
			for cbName, data in pairs(thinkTimings) do
				if not string.find(cbName, "vrmod_debug_keymon", 1, true) then
					table.insert(thinkSorted, {
						name = cbName,
						total = data.total,
						calls = data.calls,
						avg = data.calls > 0 and (data.total / data.calls) or 0,
						source = data.source,
						line = data.line,
					})
				end
			end
			table.sort(thinkSorted, function(a, b) return a.total > b.total end)

			for i, entry in ipairs(thinkSorted) do
				if i > 30 then
					print("  ... +" .. (#thinkSorted - 30) .. " more")
					break
				end
				local marker = entry.avg * 1000 > 0.1 and " ***" or ""
				print(string.format("  [%.3fms total, %.3fms avg, %dx] %s%s",
					entry.total * 1000, entry.avg * 1000, entry.calls,
					entry.name, marker))
				print(string.format("    -> %s:%d", entry.source, entry.line))
			end

			print("")
			print("--- *** = avg >0.1ms = active Think hook (doing work)")
			print("===== End Diagnostic =====")
		end)
	else
		print("[VRMod KeyMon] Usage:")
		print("  vrmod_keymon start   - Start monitoring")
		print("  vrmod_keymon stop    - Stop monitoring")
		print("  vrmod_keymon clear   - Clear log")
		print("  vrmod_keymon status  - Show status")
		print("  vrmod_keymon diag    - Run 1s diagnostic (dumps ALL IsKeyDown callers)")
	end
end)

-- 自動開始（ConVar有効時、ファイルロード時）
if cv_keymon:GetBool() then
	timer.Simple(0, function()
		StartMonitoring()
	end)
end

-- ========================================
-- パネルUI（表示専用、モニタリングはパネルと独立）
-- ========================================

function keymon.CreatePanelTab(parent)
	local container = vgui.Create("DPanel", parent)
	container.Paint = function() end

	-- ========== 上部コントロールバー ==========
	local controlBar = vgui.Create("DPanel", container)
	controlBar:Dock(TOP)
	controlBar:SetTall(34)
	controlBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.headerBg)
	end

	-- Start/Stop トグルボタン
	local btnToggle = vgui.Create("DButton", controlBar)
	btnToggle:SetText("")
	btnToggle:SetSize(110, 24)
	btnToggle:SetPos(5, 5)
	btnToggle.Paint = function(self, w, h)
		local col = keymon.active and COLORS.green or COLORS.gray
		draw.RoundedBox(3, 0, 0, w, h, col)
		local label = keymon.active and "Stop Monitor" or "Start Monitor"
		draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnToggle.DoClick = function()
		if keymon.active then
			StopMonitoring()
		else
			StartMonitoring()
		end
	end

	-- Clear ボタン
	local btnClear = vgui.Create("DButton", controlBar)
	btnClear:SetText("")
	btnClear:SetSize(60, 24)
	btnClear:SetPos(120, 5)
	btnClear.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.orange)
		draw.SimpleText("Clear", "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnClear.DoClick = function()
		keymon.log = {}
		keymon.iskeydown_callers = {}
	end

	-- IsKeyDown Capture ボタン
	local btnIsKD = vgui.Create("DButton", controlBar)
	btnIsKD:SetText("")
	btnIsKD:SetSize(160, 24)
	btnIsKD:SetPos(190, 5)
	btnIsKD.Paint = function(self, w, h)
		local col
		if keymon.IsCapturingIsKeyDown() then
			col = COLORS.red
		elseif keymon.IsWaitingForKey() then
			col = COLORS.yellow
		else
			col = COLORS.cyan
		end
		draw.RoundedBox(3, 0, 0, w, h, col)

		local label
		if keymon.IsCapturingIsKeyDown() then
			label = "Capturing..."
		elseif keymon.IsWaitingForKey() then
			label = "Press a key..."
		else
			label = "IsKeyDown Capture"
		end
		draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnIsKD.DoClick = function()
		if keymon.IsCapturingIsKeyDown() then return end
		if keymon.IsWaitingForKey() then
			keymon.SetWaitingForKey(false)
			return
		end
		-- モニタリングがONなら、ポーリングで次のキー押下を検出する
		if keymon.active then
			keymon.SetWaitingForKey(true)
		else
			-- モニタリングOFFの場合は案内
			print("[VRMod KeyMon] Start monitoring first (Start Monitor button or 'vrmod_keymon start')")
		end
	end

	-- フィルター
	local filterMode = "all" -- "all", "key", "vr"
	local btnFilter = vgui.Create("DButton", controlBar)
	btnFilter:SetText("")
	btnFilter:SetSize(80, 24)
	btnFilter:SetPos(360, 5)
	btnFilter.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.bgLight)
		local label = filterMode == "all" and "All" or (filterMode == "key" and "Keys" or "VR")
		draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, COLORS.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnFilter.DoClick = function()
		if filterMode == "all" then
			filterMode = "key"
		elseif filterMode == "key" then
			filterMode = "vr"
		else
			filterMode = "all"
		end
	end

	-- ========== メイン分割: リスト + 詳細 ==========
	local mainSplit = vgui.Create("DVerticalDivider", container)
	mainSplit:Dock(FILL)
	mainSplit:DockMargin(0, 2, 0, 0)
	mainSplit:SetDividerHeight(4)
	mainSplit:SetTopHeight(400)
	mainSplit:SetTopMin(200)
	mainSplit:SetBottomMin(100)

	-- ========== ログリスト ==========
	local list = vgui.Create("DListView")
	list:AddColumn("Time"):SetFixedWidth(60)
	list:AddColumn("Type"):SetFixedWidth(40)
	list:AddColumn("Event"):SetFixedWidth(60)
	list:AddColumn("Key / Action"):SetFixedWidth(180)
	list:AddColumn("Binding"):SetFixedWidth(100)
	list:AddColumn("Callbacks")
	list:SetMultiSelect(false)
	list.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	-- ========== 詳細パネル ==========
	local detailPanel = vgui.Create("DTextEntry")
	detailPanel:SetMultiline(true)
	detailPanel:SetEditable(false)
	detailPanel:SetFont("VRDebugCode")
	detailPanel:SetText("Select a log entry to view callback details.\n\nUse 'IsKeyDown Capture' to find Think/Tick hooks polling a specific key.\n\nMonitoring works even with this panel closed.\nUse 'vrmod_keymon start/stop' in console.")
	detailPanel.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
		derma.SkinHook("Paint", "TextEntry", self, w, h)
	end

	mainSplit:SetTop(list)
	mainSplit:SetBottom(detailPanel)

	-- ========== 行選択で詳細表示 ==========
	list.OnRowSelected = function(self, idx, row)
		if row.logEntry then
			local text = CallbackDetailText(row.logEntry)
			-- IsKeyDownスナップショット結果があれば追加
			if table.Count(keymon.iskeydown_callers) > 0 then
				text = text .. "\n\n" .. string.rep("-", 50) .. "\n\n" .. IsKeyDownResultText()
			end
			detailPanel:SetText(text)
		end
	end

	-- ========== 更新ループ ==========
	local lastUpdate = 0
	local lastLogLen = 0
	local lastFilterMode = "all"
	list.Think = function(self)
		local now = SysTime()
		if now - lastUpdate < 0.15 then return end
		lastUpdate = now

		-- フィルタ適用
		local filtered = {}
		for _, entry in ipairs(keymon.log) do
			if filterMode == "all"
				or (filterMode == "key" and entry.type == "key")
				or (filterMode == "vr" and entry.type == "vr") then
				table.insert(filtered, entry)
			end
		end

		-- 変更がなければスキップ（フィルター変更も検知）
		if #filtered == lastLogLen and filterMode == lastFilterMode then return end
		lastLogLen = #filtered
		lastFilterMode = filterMode

		self:Clear()
		local curTime = CurTime()

		for i, entry in ipairs(filtered) do
			if i > 100 then break end -- 表示上限

			local age = curTime - entry.time
			local timeStr = age < 1 and string.format("%.1fs", age)
				or age < 60 and string.format("%.0fs", age)
				or string.format("%.0fm", age / 60)

			local typeStr = entry.type == "key" and "KEY" or "VR"
			local cbSummary = CallbackSummary(entry.callbacks, entry.timings)

			local row = self:AddLine(timeStr, typeStr, entry.event, entry.name, entry.binding, cbSummary)
			row.logEntry = entry

			-- 色分け
			local textColor
			if entry.type == "vr" then
				textColor = COLORS.cyan
			elseif entry.event == "PRESS" then
				textColor = age < 1 and COLORS.green or COLORS.white
			else
				textColor = COLORS.gray
			end

			for _, col in pairs(row.Columns) do
				col:SetTextColor(textColor)
			end
		end
	end

	-- ========== コンテナ破棄時のクリーンアップ ==========
	container.OnRemove = function()
		StopIsKeyDownCapture()
		-- モニタリング自体は停止しない（パネル閉じても続行）
	end

	return container
end

Log.Info("keymon", "Key & VR Action Monitor registered. Use 'vrmod_keymon start' or debug panel.")

-- ========================================
-- テスト用: ConCommandからキー入力 or 関数呼び出しをシミュレート
-- VRからキーボード処理・関数を呼び出せるかの実証
-- ========================================

-- ドットパス文字列からグローバル関数を解決する
-- 例: "ZoneNPC_ToggleMap" → _G.ZoneNPC_ToggleMap
-- 例: "GAMEMODE.PlayerButtonDown" → GAMEMODE.PlayerButtonDown
local function ResolveFunction(path)
	local parts = string.Explode(".", path)
	local current = _G
	for i, part in ipairs(parts) do
		if type(current) ~= "table" then return nil end
		current = current[part]
		if current == nil then return nil end
	end
	if type(current) == "function" then
		return current
	end
	return nil
end

concommand.Add("vrmod_keymon_tap", function(ply, cmd, args)
	if not args[1] then
		print("[KeyMon Tap] Usage:")
		print("  Key tap:   vrmod_keymon_tap h")
		print("             vrmod_keymon_tap 18")
		print("  Function:  vrmod_keymon_tap ZoneNPC_ToggleMap")
		print("             vrmod_keymon_tap MyAddon.DoSomething")
		print("  Hold key:  vrmod_keymon_tap h 0.5   (hold for 0.5s)")
		return
	end

	local arg1 = args[1]
	local holdTime = tonumber(args[2]) -- 省略時nil = 1フレームタップ

	-- 1) 数字ならキーコード直指定
	local keyCode = tonumber(arg1)

	-- 2) 1文字 or KEY_名ならキー名として解決
	if not keyCode then
		local upper = string.upper(arg1)
		keyCode = _G["KEY_" .. upper]
		-- MOUSE_もチェック
		if not keyCode then
			keyCode = _G["MOUSE_" .. upper]
		end
	end

	-- 3) キーとして解決できた → キー入力シミュレート
	if keyCode then
		local keyName = input.GetKeyName(keyCode) or "?"
		if holdTime and holdTime > 0 then
			-- ホールド: 指定秒数押し続ける
			print("[KeyMon Tap] Holding key: " .. keyName .. " (" .. keyCode .. ") for " .. holdTime .. "s")
			if vrmod and vrmod.InputEmu_SetKey then
				vrmod.InputEmu_SetKey(keyCode, true)
				timer.Simple(holdTime, function()
					vrmod.InputEmu_SetKey(keyCode, nil)
					print("[KeyMon Tap] Key released: " .. keyName)
				end)
			end
		else
			-- タップ: 1フレーム
			print("[KeyMon Tap] Tapping key: " .. keyName .. " (" .. keyCode .. ")")
			if vrmod and vrmod.InputEmu_TapKey then
				vrmod.InputEmu_TapKey(keyCode)
			end
		end
		return
	end

	-- 4) キーとして解決できない → 関数パスとして解決
	local fn = ResolveFunction(arg1)
	if fn then
		print("[KeyMon Tap] Calling function: " .. arg1)
		local ok, err = pcall(fn)
		if ok then
			print("[KeyMon Tap] Function called successfully!")
		else
			print("[KeyMon Tap] Function error: " .. tostring(err))
		end
		return
	end

	-- 5) どちらにも解決できない
	print("[KeyMon Tap] '" .. arg1 .. "' is not a valid key name, key code, or global function.")
	print("  Key examples: h, 18, space, mouse_left")
	print("  Function examples: ZoneNPC_ToggleMap, MyAddon.Toggle")
end)

-- ========================================
-- PlayerButtonDown 手動発火テストコマンド
-- Wiremod等がPlayerButtonDownフックに依存しているため、
-- VRからhook.Runで手動発火して反応するかテストする
-- ========================================

concommand.Add("vrmod_keymon_fire_pbd", function(ply, cmd, args)
	if not args[1] then
		print("[KeyMon FirePBD] Usage:")
		print("  vrmod_keymon_fire_pbd w            - Fire PlayerButtonDown for KEY_W")
		print("  vrmod_keymon_fire_pbd 18           - Fire for key code 18")
		print("  vrmod_keymon_fire_pbd w 0.5        - Hold for 0.5s then release")
		print("  vrmod_keymon_fire_pbd w tap        - Tap: fire Down, next frame fire Up")
		print("  vrmod_keymon_fire_pbd w combo      - Combo: SetKey + PBD + ConCommand")
		print("")
		print("This fires hook.Run('PlayerButtonDown') to test if Wire/other addons respond.")
		return
	end

	local arg1 = args[1]
	local mode = args[2] or "tap" -- "tap", 数字(秒数), "combo"
	local holdTime = tonumber(mode)

	-- キーコード解決（ResolveFunction前に定義されたものを再利用）
	local keyCode = tonumber(arg1)
	if not keyCode then
		local upper = string.upper(arg1)
		keyCode = _G["KEY_" .. upper]
		if not keyCode then
			keyCode = _G["MOUSE_" .. upper]
		end
	end

	if not keyCode then
		print("[KeyMon FirePBD] Unknown key: " .. arg1)
		return
	end

	local keyName = input.GetKeyName(keyCode) or "?"
	local lp = LocalPlayer()

	if mode == "combo" then
		-- コンボモード: 3つのメソッドを同時実行
		-- A) vrKeys注入（input.IsKeyDownポーリング対応）
		-- B) PlayerButtonDown手動発火（Wireフック対応）
		-- C) バインドされたConCommand実行
		print("[KeyMon FirePBD] COMBO mode: " .. keyName .. " (" .. keyCode .. ")")

		-- A: vrKeys注入
		if vrmod and vrmod.InputEmu_SetKey then
			vrmod.InputEmu_SetKey(keyCode, true)
			print("  [A] vrKeys injected")
		end

		-- B: PlayerButtonDown発火
		hook.Run("PlayerButtonDown", lp, keyCode)
		print("  [B] PlayerButtonDown fired")

		-- C: バインドコマンド実行
		local binding = input.LookupKeyBinding(keyCode)
		if binding and binding ~= "" then
			local cmdParts = string.Explode(" ", binding)
			if #cmdParts > 0 then
				RunConsoleCommand(unpack(cmdParts))
				print("  [C] ConCommand: " .. binding)
			end
		else
			print("  [C] No binding for this key")
		end

		-- リリース（次フレーム）
		timer.Simple(0, function()
			if vrmod and vrmod.InputEmu_SetKey then
				vrmod.InputEmu_SetKey(keyCode, nil)
			end
			hook.Run("PlayerButtonUp", lp, keyCode)
			if binding and string.StartWith(binding, "+") then
				local releaseCmd = "-" .. string.sub(binding, 2)
				RunConsoleCommand(releaseCmd)
			end
			print("  [RELEASE] All methods released")
		end)

	elseif holdTime and holdTime > 0 then
		-- ホールドモード: 指定秒数だけPlayerButtonDownを維持
		print("[KeyMon FirePBD] Holding PBD: " .. keyName .. " for " .. holdTime .. "s")
		hook.Run("PlayerButtonDown", lp, keyCode)

		timer.Simple(holdTime, function()
			hook.Run("PlayerButtonUp", lp, keyCode)
			print("[KeyMon FirePBD] Released: " .. keyName)
		end)

	else
		-- タップモード: Down → 次フレームでUp
		print("[KeyMon FirePBD] Tapping PBD: " .. keyName .. " (" .. keyCode .. ")")
		hook.Run("PlayerButtonDown", lp, keyCode)

		timer.Simple(0, function()
			hook.Run("PlayerButtonUp", lp, keyCode)
		end)
	end

	-- 発火後のフック登録状況を表示
	local pbdHooks = hook.GetTable()["PlayerButtonDown"]
	if pbdHooks then
		local count = 0
		local names = {}
		for name, _ in pairs(pbdHooks) do
			count = count + 1
			if count <= 10 then
				table.insert(names, name)
			end
		end
		table.sort(names)
		print("[KeyMon FirePBD] PlayerButtonDown has " .. count .. " callbacks:")
		for _, name in ipairs(names) do
			print("  - " .. name)
		end
		if count > 10 then
			print("  ... +" .. (count - 10) .. " more")
		end
	else
		print("[KeyMon FirePBD] No PlayerButtonDown callbacks registered!")
	end
end)

-- ========================================
-- 全Luaファイル キーボード入力スキャナー
-- GMod上の全アドオンのLuaファイルから「キーボード入力関連記述」を検索
-- ========================================

local SCAN_PATTERNS = {
	-- カテゴリ: vrKeys注入（TapKey/SetKey）で対応可能
	{
		category = "TAPKEY_COMPATIBLE",
		label = "input.IsKeyDown polling (TapKey works)",
		pattern = "input%.IsKeyDown",
	},
	{
		category = "TAPKEY_COMPATIBLE",
		label = "input.IsButtonDown polling (TapKey works)",
		pattern = "input%.IsButtonDown",
	},
	{
		category = "TAPKEY_COMPATIBLE",
		label = "input.IsMouseDown polling (TapKey works for mouse codes)",
		pattern = "input%.IsMouseDown",
	},
	{
		category = "TAPKEY_COMPATIBLE",
		label = "input.WasKeyPressed (single-frame, TapKey compatible)",
		pattern = "input%.WasKeyPressed",
	},
	{
		category = "TAPKEY_COMPATIBLE",
		label = "input.WasKeyReleased (single-frame)",
		pattern = "input%.WasKeyReleased",
	},
	-- カテゴリ: PlayerButtonDown系（エンジンイベント、vrKeysでは不可）
	{
		category = "ENGINE_HOOK",
		label = "PlayerButtonDown hook",
		pattern = "PlayerButtonDown",
	},
	{
		category = "ENGINE_HOOK",
		label = "PlayerButtonUp hook",
		pattern = "PlayerButtonUp",
	},
	-- カテゴリ: サーバーサイド / CreateMove（最も困難）
	{
		category = "SERVER_SIDE",
		label = "KeyPress (server-side IN_* detection)",
		pattern = "KeyPress",
	},
	{
		category = "SERVER_SIDE",
		label = "KeyRelease (server-side)",
		pattern = "KeyRelease",
	},
	-- カテゴリ: その他の入力関連
	{
		category = "OTHER_INPUT",
		label = "input.LookupKeyBinding",
		pattern = "input%.LookupKeyBinding",
	},
	{
		category = "OTHER_INPUT",
		label = "input.GetKeyName",
		pattern = "input%.GetKeyName",
	},
	{
		category = "OTHER_INPUT",
		label = "input.SelectWeapon / weapon slot",
		pattern = "input%.SelectWeapon",
	},
	-- カテゴリ: KEY_*定数の使用（どのキーに反応するか特定可能）
	{
		category = "KEY_CONSTANT",
		label = "KEY_* constant reference",
		pattern = "KEY_[A-Z][A-Z0-9_]+",
	},
	{
		category = "KEY_CONSTANT",
		label = "MOUSE_* constant reference",
		pattern = "MOUSE_[A-Z][A-Z0-9_]+",
	},
	{
		category = "KEY_CONSTANT",
		label = "IN_* constant (movement/action flags)",
		pattern = "IN_[A-Z][A-Z0-9_]+",
	},
	-- カテゴリ: 関数呼び出し / GUI操作（VRから直接呼べる可能性）
	{
		category = "CALLABLE_FUNCTION",
		label = "gui.EnableScreenClicker (cursor toggle)",
		pattern = "gui%.EnableScreenClicker",
	},
	{
		category = "CALLABLE_FUNCTION",
		label = "gui.ActivateGameUI",
		pattern = "gui%.ActivateGameUI",
	},
	{
		category = "CALLABLE_FUNCTION",
		label = "vgui.Create (panel creation)",
		pattern = "vgui%.Create",
	},
	{
		category = "CALLABLE_FUNCTION",
		label = "RunConsoleCommand",
		pattern = "RunConsoleCommand",
	},
	{
		category = "CALLABLE_FUNCTION",
		label = "LocalPlayer():ConCommand",
		pattern = "ConCommand",
	},
}

-- 再帰的にディレクトリ内の.luaファイルを収集
local function CollectLuaFiles(basePath, results, depth)
	depth = depth or 0
	if depth > 15 then return end -- 無限再帰防止

	local files, dirs = file.Find(basePath .. "/*", "GAME")

	for _, f in ipairs(files or {}) do
		if string.sub(f, -4) == ".lua" then
			table.insert(results, basePath .. "/" .. f)
		end
	end

	for _, d in ipairs(dirs or {}) do
		CollectLuaFiles(basePath .. "/" .. d, results, depth + 1)
	end
end

-- ファイル内容をスキャンしてパターンマッチ（周辺コード付き）
local CONTEXT_LINES = 10 -- 前後10行

local function ScanFileContent(filePath, content)
	local matches = {}

	-- 全行をテーブルに分割（周辺コード抽出用）
	local allLines = {}
	for line in string.gmatch(content .. "\n", "([^\r\n]*)\r?\n") do
		table.insert(allLines, line)
	end

	for lineNum, line in ipairs(allLines) do
		for _, pat in ipairs(SCAN_PATTERNS) do
			if string.find(line, pat.pattern) then
				-- 前後N行のコンテキストを抽出
				local contextLines = {}
				local startLine = math.max(1, lineNum - CONTEXT_LINES)
				local endLine = math.min(#allLines, lineNum + CONTEXT_LINES)
				for i = startLine, endLine do
					local prefix = (i == lineNum) and ">>>" or "   "
					table.insert(contextLines, string.format("%s %4d: %s", prefix, i, allLines[i]))
				end

				table.insert(matches, {
					file = filePath,
					line = lineNum,
					category = pat.category,
					label = pat.label,
					code = string.Trim(line),
					context = table.concat(contextLines, "\n"),
					context_start = startLine,
					context_end = endLine,
				})
			end
		end
	end

	return matches
end

concommand.Add("vrmod_keymon_scan", function(ply, cmd, args)
	print("========================================")
	print("  VRMod Keyboard Input Scanner")
	print("  Scanning ALL Lua files for keyboard input patterns...")
	print("  Game may freeze momentarily.")
	print("========================================")

	local startTime = SysTime()

	-- Step 1: 全.luaファイルを収集
	print("[SCAN] Collecting Lua files...")
	local luaFiles = {}

	-- lua/ ディレクトリ（メインゲーム + アドオン統合パス）
	CollectLuaFiles("lua", luaFiles)

	-- addons/ 内の各アドオン
	local _, addonDirs = file.Find("addons/*", "GAME")
	for _, addonName in ipairs(addonDirs or {}) do
		CollectLuaFiles("addons/" .. addonName .. "/lua", luaFiles)
	end

	-- gamemodes/
	CollectLuaFiles("gamemodes", luaFiles)

	print("[SCAN] Found " .. #luaFiles .. " Lua files. Scanning content...")

	-- Step 2: 各ファイルをスキャン
	local allMatches = {}
	local scannedCount = 0
	local errorCount = 0

	for _, filePath in ipairs(luaFiles) do
		local content = file.Read(filePath, "GAME")
		if content then
			local matches = ScanFileContent(filePath, content)
			for _, m in ipairs(matches) do
				table.insert(allMatches, m)
			end
			scannedCount = scannedCount + 1
		else
			errorCount = errorCount + 1
		end

		-- 進捗表示（100ファイルごと）
		if scannedCount % 100 == 0 then
			print("[SCAN] " .. scannedCount .. " / " .. #luaFiles .. " files scanned...")
		end
	end

	local elapsed = SysTime() - startTime

	-- Step 3: カテゴリ別に整理
	local byCategory = {}
	local byFile = {}

	for _, m in ipairs(allMatches) do
		-- カテゴリ別
		byCategory[m.category] = byCategory[m.category] or {}
		table.insert(byCategory[m.category], m)

		-- ファイル別（重複除去用）
		byFile[m.file] = byFile[m.file] or {}
		byFile[m.file][m.category] = true
	end

	-- Step 4: サマリ出力
	print("")
	print("========================================")
	print("  SCAN COMPLETE")
	print(string.format("  Files: %d scanned, %d errors, %.1fs elapsed", scannedCount, errorCount, elapsed))
	print(string.format("  Total matches: %d", #allMatches))
	print("========================================")

	local catOrder = { "TAPKEY_COMPATIBLE", "ENGINE_HOOK", "SERVER_SIDE", "KEY_CONSTANT", "CALLABLE_FUNCTION", "OTHER_INPUT" }
	local catNames = {
		TAPKEY_COMPATIBLE = "TapKey/SetKey Compatible (VR bridge works!)",
		ENGINE_HOOK = "Engine Hooks (PlayerButtonDown - needs hook.Run bridge)",
		SERVER_SIDE = "Server-side (KeyPress - hardest to bridge)",
		KEY_CONSTANT = "KEY/MOUSE/IN Constants (identifies which keys are used)",
		CALLABLE_FUNCTION = "Callable Functions (GUI/command - VR can call directly)",
		OTHER_INPUT = "Other Input Functions (informational)",
	}

	for _, cat in ipairs(catOrder) do
		local matches = byCategory[cat]
		if matches then
			print("")
			print("--- " .. catNames[cat] .. " ---")
			print("  " .. #matches .. " occurrences")

			-- ファイル別集計
			local fileCounts = {}
			for _, m in ipairs(matches) do
				fileCounts[m.file] = (fileCounts[m.file] or 0) + 1
			end
			local sortedFiles = {}
			for f, c in pairs(fileCounts) do
				table.insert(sortedFiles, { file = f, count = c })
			end
			table.sort(sortedFiles, function(a, b) return a.count > b.count end)

			for i, entry in ipairs(sortedFiles) do
				if i > 15 then
					print("  ... +" .. (#sortedFiles - 15) .. " more files")
					break
				end
				print(string.format("  [%d] %s", entry.count, entry.file))
			end
		end
	end

	-- Step 5: JSONファイルに保存
	local output = {
		scan_time = os.date("%Y-%m-%d %H:%M:%S"),
		elapsed_seconds = elapsed,
		files_scanned = scannedCount,
		total_matches = #allMatches,
		categories = {},
		file_summary = {},
	}

	for _, cat in ipairs(catOrder) do
		local matches = byCategory[cat] or {}
		output.categories[cat] = {
			name = catNames[cat],
			count = #matches,
			matches = {},
		}
		for _, m in ipairs(matches) do
			table.insert(output.categories[cat].matches, {
				file = m.file,
				line = m.line,
				label = m.label,
				code = string.sub(m.code, 1, 200),
				context = m.context or "",
			})
		end
	end

	-- ファイル別サマリ（どのカテゴリの入力を使っているか）
	for filePath, cats in pairs(byFile) do
		local catList = {}
		for cat, _ in pairs(cats) do
			table.insert(catList, cat)
		end
		table.sort(catList)
		output.file_summary[filePath] = catList
	end

	local jsonStr = util.TableToJSON(output, true)
	file.Write("vrmod/vrmod_keymon_scan_result.txt", jsonStr)

	print("")
	print("[SCAN] Results saved to: garrysmod/data/vrmod/vrmod_keymon_scan_result.txt")
	print("[SCAN] Use the JSON to identify which addons can be VR-bridged with TapKey.")
	print("========================================")
end)

-- グローバル関数スキャナは vrmod_debug_globals.lua に移動済み

--------[vrmod_debug_keymon.lua]End--------
