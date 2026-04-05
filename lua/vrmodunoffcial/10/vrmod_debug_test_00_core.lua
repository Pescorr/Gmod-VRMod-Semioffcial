--------[vrmod_debug_test_00_core.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- 自動テストフレームワーク
-- 既存のMock VR + Hook Monitor + Error Bufferの上に
-- テストランナー + アサーション + レポーターを構築
-- ========================================

local Log = vrmod.debug.Log

vrmod.debug.test = vrmod.debug.test or {}
local test = vrmod.debug.test

-- ----------------------------------------
-- テストレジストリ
-- ----------------------------------------
test.suites = test.suites or {}
test.lastResults = nil

function test.Register(id, def)
	if not id or not def or not def.run then
		Log.Error("test", "Invalid test registration: " .. tostring(id))
		return
	end
	def.id = id
	def.category = def.category or "static"
	def.module = def.module or "core"
	def.timeout = def.timeout or 5
	test.suites[id] = def
end

-- ----------------------------------------
-- アサーション生成
-- ----------------------------------------
local function CreateAssertions(ctx)
	local a = {}

	local function record(passed, assertion, message, actual)
		table.insert(ctx._assertions, {
			passed = passed,
			assertion = assertion,
			message = message or "",
			actual = actual,
		})
		return passed
	end

	function a.isTrue(value, msg)
		return record(value == true, "isTrue", msg, tostring(value))
	end

	function a.isFalse(value, msg)
		return record(value == false, "isFalse", msg, tostring(value))
	end

	function a.isNil(value, msg)
		return record(value == nil, "isNil", msg, tostring(value))
	end

	function a.isNotNil(value, msg)
		return record(value ~= nil, "isNotNil", msg, tostring(value))
	end

	function a.equal(expected, actual, msg)
		return record(expected == actual, "equal", msg, "expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
	end

	function a.notEqual(expected, actual, msg)
		return record(expected ~= actual, "notEqual", msg, "both=" .. tostring(actual))
	end

	function a.isType(value, typeName, msg)
		return record(type(value) == typeName, "isType", msg, "expected=" .. typeName .. " actual=" .. type(value))
	end

	function a.greaterThan(value, threshold, msg)
		return record(isnumber(value) and value > threshold, "greaterThan", msg, tostring(value) .. " > " .. tostring(threshold))
	end

	function a.lessThan(value, threshold, msg)
		return record(isnumber(value) and value < threshold, "lessThan", msg, tostring(value) .. " < " .. tostring(threshold))
	end

	function a.hasKey(tbl, key, msg)
		return record(istable(tbl) and tbl[key] ~= nil, "hasKey", msg, "key=" .. tostring(key))
	end

	-- VRMod専用アサーション

	function a.noErrors(msg)
		local errors = vrmod.debug.GetErrors()
		local newErrors = #errors - ctx._errorCountAtStart
		if newErrors > 0 then
			local latest = errors[#errors]
			return record(false, "noErrors", msg, newErrors .. " new error(s), latest: " .. tostring(latest and latest.message))
		end
		return record(true, "noErrors", msg)
	end

	function a.hookFired(hookName, msg)
		local hookData = vrmod.debug.hooks[hookName]
		local before = ctx._hookCountsBefore[hookName] or 0
		local current = hookData and hookData.fireCount or 0
		return record(current > before, "hookFired", msg, hookName .. " fires: " .. before .. " -> " .. current)
	end

	function a.hookNotFired(hookName, msg)
		local hookData = vrmod.debug.hooks[hookName]
		local before = ctx._hookCountsBefore[hookName] or 0
		local current = hookData and hookData.fireCount or 0
		return record(current == before, "hookNotFired", msg, hookName .. " fires: " .. before .. " -> " .. current)
	end

	function a.hookFireCount(hookName, minCount, msg)
		local hookData = vrmod.debug.hooks[hookName]
		local before = ctx._hookCountsBefore[hookName] or 0
		local current = hookData and hookData.fireCount or 0
		local delta = current - before
		return record(delta >= minCount, "hookFireCount", msg, hookName .. " delta=" .. delta .. " (need>=" .. minCount .. ")")
	end

	function a.noStaleHooks(msg)
		local stale = vrmod.debug.staleHooks
		local count = stale and #stale or 0
		if count > 0 then
			local first = stale[1]
			return record(false, "noStaleHooks", msg, count .. " stale, first: " .. tostring(first and (first.hookName .. "/" .. first.callbackName)))
		end
		return record(true, "noStaleHooks", msg)
	end

	function a.convarExists(name, msg)
		local cv = GetConVar(name)
		return record(cv ~= nil, "convarExists", msg, name)
	end

	function a.convarValue(name, expected, msg)
		local cv = GetConVar(name)
		if not cv then
			return record(false, "convarValue", msg, name .. " not found")
		end
		local actual = cv:GetString()
		return record(actual == tostring(expected), "convarValue", msg, name .. "=" .. actual .. " expected=" .. tostring(expected))
	end

	function a.callbackRegistered(hookName, cbName, msg)
		local hookTable = hook.GetTable()
		local callbacks = hookTable[hookName]
		local found = callbacks and callbacks[cbName] ~= nil
		return record(found, "callbackRegistered", msg, hookName .. "/" .. tostring(cbName))
	end

	return a
end

-- ----------------------------------------
-- テストコンテキスト生成
-- ----------------------------------------
local function CreateContext(testDef)
	local ctx = {
		_assertions = {},
		_errorCountAtStart = #vrmod.debug.GetErrors(),
		_hookCountsBefore = {},
		_startTime = SysTime(),
		data = {},
	}

	-- Hook fire count スナップショット
	for name, data in pairs(vrmod.debug.hooks) do
		ctx._hookCountsBefore[name] = data.fireCount
	end

	ctx.assert = CreateAssertions(ctx)

	-- Mock VR ヘルパー
	ctx.mockVR = {
		start = function()
			-- ConVar有効化（mock.Startが内部でチェックする）
			RunConsoleCommand("vrmod_unoff_debug_mock", "1")
			-- ConVar反映を待つための1フレーム遅延なしで直接設定
			GetConVar("vrmod_unoff_debug_mock"):SetInt(1)
			return vrmod.debug.mock.Start()
		end,

		stop = function()
			return vrmod.debug.mock.Stop()
		end,

		waitFrames = function(n, callback)
			local count = 0
			local hookName = "vrmod_test_wf_" .. tostring(SysTime())
			table.insert(test._activeHooks, { hook = "Think", name = hookName })
			hook.Add("Think", hookName, function()
				count = count + 1
				if count >= n then
					hook.Remove("Think", hookName)
					callback()
				end
			end)
		end,

		simulateInput = function(action, pressed)
			if not g_VR.input then return end
			g_VR.input[action] = pressed
			g_VR.changedInputs = g_VR.changedInputs or {}
			g_VR.changedInputs[action] = pressed
			hook.Call("VRMod_Input", nil, action, pressed)
		end,

		waitForHook = function(hookName, timeout, callback)
			local startCount = (vrmod.debug.hooks[hookName] and vrmod.debug.hooks[hookName].fireCount) or 0
			local startTime = SysTime()
			local waitName = "vrmod_test_wh_" .. tostring(SysTime())
			table.insert(test._activeHooks, { hook = "Think", name = waitName })
			hook.Add("Think", waitName, function()
				local current = vrmod.debug.hooks[hookName] and vrmod.debug.hooks[hookName].fireCount or 0
				if current > startCount then
					hook.Remove("Think", waitName)
					callback(true)
				elseif SysTime() - startTime > timeout then
					hook.Remove("Think", waitName)
					callback(false)
				end
			end)
		end,
	}

	return ctx
end

-- ----------------------------------------
-- テストランナー
-- ----------------------------------------
local runQueue = {}
local runIndex = 0
local runResults = {}
local running = false

test._activeHooks = {}
test._activeTimers = {}

local function CleanupTestArtifacts()
	for _, entry in ipairs(test._activeHooks) do
		hook.Remove(entry.hook, entry.name)
	end
	test._activeHooks = {}

	for _, name in ipairs(test._activeTimers) do
		timer.Remove(name)
	end
	test._activeTimers = {}

	-- Mock VR安全停止
	if g_VR and g_VR.mockMode then
		pcall(vrmod.debug.mock.Stop)
	end
end

local function FinishRun(startTime)
	running = false
	CleanupTestArtifacts()

	local totalTime = SysTime() - startTime
	local passed, failed, skipped, timedOut, errored = 0, 0, 0, 0, 0

	for _, r in ipairs(runResults) do
		if r.status == "pass" then passed = passed + 1
		elseif r.status == "fail" then failed = failed + 1
		elseif r.status == "skip" then skipped = skipped + 1
		elseif r.status == "timeout" then timedOut = timedOut + 1
		elseif r.status == "error" then errored = errored + 1
		end
	end

	-- コンソール出力
	local COLOR_PASS = Color(100, 255, 100)
	local COLOR_FAIL = Color(255, 100, 100)
	local COLOR_SKIP = Color(255, 255, 100)
	local COLOR_TIMEOUT = Color(255, 180, 80)
	local COLOR_HEADER = Color(100, 200, 255)
	local COLOR_WHITE = Color(255, 255, 255)
	local PREFIX = "[VRMod Test] "

	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "------------------------------------\n")

	for _, r in ipairs(runResults) do
		local color = COLOR_PASS
		local label = "PASS"
		if r.status == "fail" then color = COLOR_FAIL; label = "FAIL"
		elseif r.status == "skip" then color = COLOR_SKIP; label = "SKIP"
		elseif r.status == "timeout" then color = COLOR_TIMEOUT; label = "TIMEOUT"
		elseif r.status == "error" then color = COLOR_FAIL; label = "ERROR"
		end

		MsgC(COLOR_HEADER, PREFIX, color, "[", label, "] ", COLOR_WHITE, r.name, " (", string.format("%.0f", r.duration * 1000), "ms)\n")

		-- 失敗詳細
		if r.status == "fail" or r.status == "error" then
			for _, a in ipairs(r.assertions or {}) do
				if not a.passed then
					MsgC(COLOR_HEADER, PREFIX, COLOR_FAIL, "  -> ", a.message or a.assertion, COLOR_WHITE, " [", tostring(a.actual), "]\n")
				end
			end
			if r.errorMsg then
				MsgC(COLOR_HEADER, PREFIX, COLOR_FAIL, "  -> ", r.errorMsg, "\n")
			end
		end
	end

	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "------------------------------------\n")
	MsgC(COLOR_HEADER, PREFIX)
	MsgC(COLOR_PASS, tostring(passed), " PASS")
	if failed > 0 then MsgC(COLOR_WHITE, ", ", COLOR_FAIL, tostring(failed), " FAIL") end
	if skipped > 0 then MsgC(COLOR_WHITE, ", ", COLOR_SKIP, tostring(skipped), " SKIP") end
	if timedOut > 0 then MsgC(COLOR_WHITE, ", ", COLOR_TIMEOUT, tostring(timedOut), " TIMEOUT") end
	if errored > 0 then MsgC(COLOR_WHITE, ", ", COLOR_FAIL, tostring(errored), " ERROR") end
	MsgC(COLOR_WHITE, " | ", string.format("%.1f", totalTime), "s\n")

	-- JSONファイル出力
	local report = {
		meta = {
			timestamp = os.date("%Y-%m-%d %H:%M:%S"),
			map = game.GetMap(),
			duration_sec = math.Round(totalTime, 1),
			totalTests = #runResults,
			passed = passed,
			failed = failed,
			skipped = skipped,
			timeout = timedOut,
			errored = errored,
		},
		tests = {},
	}

	for _, r in ipairs(runResults) do
		table.insert(report.tests, {
			id = r.id,
			name = r.name,
			category = r.category,
			module = r.module,
			status = r.status,
			duration_ms = math.Round(r.duration * 1000),
			assertions = r.assertions,
			errorMsg = r.errorMsg,
		})
	end

	local json = util.TableToJSON(report, true)
	local filename = "vrmod_debug/test_results_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
	file.CreateDir("vrmod_debug")
	file.Write(filename, json)
	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "-> data/", filename, "\n")
	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "====================================\n")

	test.lastResults = report
end

local function RunNextTest(suiteStartTime)
	runIndex = runIndex + 1
	if runIndex > #runQueue then
		FinishRun(suiteStartTime)
		return
	end

	local testDef = runQueue[runIndex]

	-- 依存チェック
	if testDef.depends then
		for _, depId in ipairs(testDef.depends) do
			local depResult
			for _, r in ipairs(runResults) do
				if r.id == depId then depResult = r; break end
			end
			if not depResult or depResult.status ~= "pass" then
				table.insert(runResults, {
					id = testDef.id,
					name = testDef.name or testDef.id,
					category = testDef.category,
					module = testDef.module,
					status = "skip",
					duration = 0,
					assertions = {},
					errorMsg = "dependency " .. depId .. " not passed",
				})
				timer.Simple(0, function() RunNextTest(suiteStartTime) end)
				return
			end
		end
	end

	local ctx = CreateContext(testDef)
	local finished = false
	local testStartTime = SysTime()

	local function done()
		if finished then return end
		finished = true
		timer.Remove("vrmod_test_timeout")

		-- Teardown（常に実行）
		if testDef.teardown then
			pcall(testDef.teardown, ctx)
		end

		-- 結果集計
		local allPassed = true
		for _, a in ipairs(ctx._assertions) do
			if not a.passed then allPassed = false; break end
		end

		table.insert(runResults, {
			id = testDef.id,
			name = testDef.name or testDef.id,
			category = testDef.category,
			module = testDef.module,
			status = allPassed and "pass" or "fail",
			duration = SysTime() - testStartTime,
			assertions = ctx._assertions,
		})

		timer.Simple(0, function() RunNextTest(suiteStartTime) end)
	end

	-- Setup
	if testDef.setup then
		local ok, err = pcall(testDef.setup, ctx)
		if not ok then
			table.insert(runResults, {
				id = testDef.id,
				name = testDef.name or testDef.id,
				category = testDef.category,
				module = testDef.module,
				status = "error",
				duration = SysTime() - testStartTime,
				assertions = {},
				errorMsg = "setup failed: " .. tostring(err),
			})
			timer.Simple(0, function() RunNextTest(suiteStartTime) end)
			return
		end
	end

	-- タイムアウトガード
	timer.Create("vrmod_test_timeout", testDef.timeout, 1, function()
		if not finished then
			finished = true
			if testDef.teardown then pcall(testDef.teardown, ctx) end
			table.insert(runResults, {
				id = testDef.id,
				name = testDef.name or testDef.id,
				category = testDef.category,
				module = testDef.module,
				status = "timeout",
				duration = SysTime() - testStartTime,
				assertions = ctx._assertions,
				errorMsg = "timeout after " .. testDef.timeout .. "s",
			})
			timer.Simple(0, function() RunNextTest(suiteStartTime) end)
		end
	end)
	table.insert(test._activeTimers, "vrmod_test_timeout")

	-- 実行
	local ok, err = pcall(testDef.run, ctx, done)
	if not ok then
		if not finished then
			finished = true
			timer.Remove("vrmod_test_timeout")
			if testDef.teardown then pcall(testDef.teardown, ctx) end
			table.insert(runResults, {
				id = testDef.id,
				name = testDef.name or testDef.id,
				category = testDef.category,
				module = testDef.module,
				status = "error",
				duration = SysTime() - testStartTime,
				assertions = ctx._assertions,
				errorMsg = "run error: " .. tostring(err),
			})
			timer.Simple(0, function() RunNextTest(suiteStartTime) end)
		end
	end
end

function test.Run(options)
	if running then
		Log.Warn("test", "Test suite is already running")
		return
	end

	options = options or {}
	local categoryFilter = options.category
	local moduleFilter = options.module

	-- キュー構築
	runQueue = {}
	runIndex = 0
	runResults = {}
	running = true

	-- カテゴリ順序（staticが先、regressionが最後）
	local categoryOrder = { static = 1, lifecycle = 2, functional = 3, regression = 4 }

	for id, def in pairs(test.suites) do
		local include = true
		if categoryFilter and def.category ~= categoryFilter then include = false end
		if moduleFilter and def.module ~= moduleFilter then include = false end
		if include then
			table.insert(runQueue, def)
		end
	end

	-- ソート: カテゴリ順 → ID順
	table.sort(runQueue, function(a, b)
		local oa = categoryOrder[a.category] or 99
		local ob = categoryOrder[b.category] or 99
		if oa ~= ob then return oa < ob end
		return a.id < b.id
	end)

	local COLOR_HEADER = Color(100, 200, 255)
	local COLOR_WHITE = Color(255, 255, 255)
	local PREFIX = "[VRMod Test] "

	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "====================================\n")
	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "Running ", tostring(#runQueue), " tests")
	if categoryFilter then MsgC(COLOR_WHITE, " (category: ", categoryFilter, ")") end
	if moduleFilter then MsgC(COLOR_WHITE, " (module: ", moduleFilter, ")") end
	MsgC(COLOR_WHITE, "\n")
	MsgC(COLOR_HEADER, PREFIX, COLOR_WHITE, "------------------------------------\n")

	local suiteStartTime = SysTime()
	RunNextTest(suiteStartTime)
end

-- ----------------------------------------
-- コンソールコマンド
-- ----------------------------------------

concommand.Add("vrmod_unoff_test", function(_, _, args)
	local category = args and args[1]
	if category and category ~= "" then
		test.Run({ category = category })
	else
		test.Run()
	end
end)

concommand.Add("vrmod_unoff_test_module", function(_, _, args)
	local moduleName = args and args[1]
	if not moduleName or moduleName == "" then
		Log.Warn("test", "Usage: vrmod_unoff_test_module <module_name>")
		return
	end
	test.Run({ module = moduleName })
end)

concommand.Add("vrmod_unoff_test_list", function()
	local categoryOrder = { static = 1, lifecycle = 2, functional = 3, regression = 4 }
	local sorted = {}
	for id, def in pairs(test.suites) do
		table.insert(sorted, def)
	end
	table.sort(sorted, function(a, b)
		local oa = categoryOrder[a.category] or 99
		local ob = categoryOrder[b.category] or 99
		if oa ~= ob then return oa < ob end
		return a.id < b.id
	end)

	print("=== Registered Tests (" .. #sorted .. ") ===")
	local lastCat = nil
	for _, def in ipairs(sorted) do
		if def.category ~= lastCat then
			lastCat = def.category
			print("  [" .. lastCat .. "]")
		end
		print(string.format("    %-40s (%s) %s", def.id, def.module, def.name or ""))
	end
	print("=====================================")
end)

concommand.Add("vrmod_unoff_test_last", function()
	local r = test.lastResults
	if not r then
		print("No test results available. Run vrmod_unoff_test first.")
		return
	end

	print("=== Last Test Results ===")
	print("  Time: " .. r.meta.timestamp)
	print("  Map: " .. r.meta.map)
	print(string.format("  %d PASS, %d FAIL, %d SKIP, %d TIMEOUT, %d ERROR (%.1fs)",
		r.meta.passed, r.meta.failed, r.meta.skipped, r.meta.timeout, r.meta.errored, r.meta.duration_sec))
	print("  ---")
	for _, t in ipairs(r.tests) do
		local icon = t.status == "pass" and "[OK]" or "[" .. string.upper(t.status) .. "]"
		print(string.format("  %s %-40s %dms", icon, t.name or t.id, t.duration_ms))
		if t.status ~= "pass" and t.status ~= "skip" then
			for _, a in ipairs(t.assertions or {}) do
				if not a.passed then
					print("       -> " .. (a.message or a.assertion) .. " [" .. tostring(a.actual) .. "]")
				end
			end
			if t.errorMsg then
				print("       -> " .. t.errorMsg)
			end
		end
	end
	print("=========================")
end)

Log.Info("test", "Test framework loaded. Commands: vrmod_unoff_test [static|lifecycle|functional|regression]")

--------[vrmod_debug_test_00_core.lua]End--------
