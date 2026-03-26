--------[vrmod_debug_hookmon.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- フック監視エンジン
-- hook.Call/Run ラップ + 行レベルトレース
-- + コールバック単位プロファイリング（Rec ON時）
-- + 実行順序記録（L25対策）
-- + stale hook検出（L27対策）
-- ========================================

local Log = vrmod.debug.Log

-- ----------------------------------------
-- hook.Call / hook.Run ラップ
-- ----------------------------------------

-- 二重ラップ防止（L12パターン）
vrmod._origHookCall = vrmod._origHookCall or hook.Call
vrmod._origHookRun = vrmod._origHookRun or hook.Run

local origCall = vrmod._origHookCall
local origRun = vrmod._origHookRun
local hooks = vrmod.debug.hooks

-- フック発火データ記録用
-- hooks[hookName] = { fireCount, lastFire, lastElapsed, avgTime, callbacks = {} }

-- エクスポートシステム用コールバック（vrmod_debug_export.luaで設定）
vrmod.debug.onHookFire = nil

-- ----------------------------------------
-- コールバック単位プロファイリング（Rec ON時のみ有効）
-- ----------------------------------------
vrmod.debug.callbackStats = vrmod.debug.callbackStats or {}
vrmod.debug.callbackProfiling = false -- export.luaが制御

-- 実行順序記録（L25: pairs()の非決定的順序を検出）
vrmod.debug.executionOrders = vrmod.debug.executionOrders or {}
local MAX_ORDER_HISTORY = 100

-- stale hook検出（L27: VR終了後に残留するhookを検出）
vrmod.debug.hookSnapshots = vrmod.debug.hookSnapshots or {}
vrmod.debug.staleHooks = vrmod.debug.staleHooks or {}

-- ----------------------------------------
-- コールバック単位計測付きhook.Call（手動イテレーション版）
-- hook.Callの本来の挙動を再現:
--   1. hook.GetTable()[name]の各コールバックを実行
--   2. コールバックがnon-nilを返したら中断しその値を返す
--   3. 全コールバック実行後、gm[name](gm, ...)を呼ぶ
-- ----------------------------------------
local callbackStats = vrmod.debug.callbackStats
local executionOrders = vrmod.debug.executionOrders
local frameCounter = 0

local function ProfiledHookCall(name, gm, ...)
	local hookTable = hook.GetTable()
	local callbacks = hookTable[name]

	-- コールバック単位の統計テーブルを初期化
	if not callbackStats[name] then
		callbackStats[name] = {}
	end
	local stats = callbackStats[name]

	-- 実行順序記録用
	local orderList = {}

	-- 各コールバックを個別に実行 + 計測
	if callbacks then
		for cbName, func in pairs(callbacks) do
			if isfunction(func) then
				table.insert(orderList, cbName)

				local t0 = SysTime()
				local ok, a, b, c, d, e, f = pcall(func, ...)
				local cbElapsed = SysTime() - t0

				-- 統計更新
				if not stats[cbName] then
					local info = debug.getinfo(func, "Sl")
					stats[cbName] = {
						totalTime = 0,
						callCount = 0,
						avgTime = 0,
						maxTime = 0,
						source = info and info.short_src or "unknown",
						linedefined = info and info.linedefined or 0,
					}
				end
				local s = stats[cbName]
				s.totalTime = s.totalTime + cbElapsed
				s.callCount = s.callCount + 1
				s.avgTime = s.avgTime * 0.95 + cbElapsed * 0.05
				if cbElapsed > s.maxTime then
					s.maxTime = cbElapsed
				end

				if not ok then
					-- pcailエラー: コールバック名とエラーをログ
					Log.Error("profiler", name .. "/" .. cbName .. ": " .. tostring(a))
				elseif a ~= nil then
					-- non-nil返却 → 中断（hook.Callの本来の挙動）
					-- 順序記録を保存してから返す
					if executionOrders[name] then
						local prev = executionOrders[name]
						if prev[#prev] then
							local prevOrder = prev[#prev].order
							-- 順序変化を検出
							local changed = (#prevOrder ~= #orderList)
							if not changed then
								for i, v in ipairs(orderList) do
									if prevOrder[i] ~= v then
										changed = true
										break
									end
								end
							end
							if changed and vrmod.debug.onOrderChange then
								vrmod.debug.onOrderChange(name, prevOrder, orderList)
							end
						end
					end
					if not executionOrders[name] then executionOrders[name] = {} end
					table.insert(executionOrders[name], { frame = frameCounter, order = orderList })
					if #executionOrders[name] > MAX_ORDER_HISTORY then
						table.remove(executionOrders[name], 1)
					end

					return a, b, c, d, e, f
				end
			end
		end
	end

	-- 実行順序記録
	if #orderList > 0 then
		if not executionOrders[name] then executionOrders[name] = {} end
		local prev = executionOrders[name]
		if prev[#prev] then
			local prevOrder = prev[#prev].order
			local changed = (#prevOrder ~= #orderList)
			if not changed then
				for i, v in ipairs(orderList) do
					if prevOrder[i] ~= v then
						changed = true
						break
					end
				end
			end
			if changed and vrmod.debug.onOrderChange then
				vrmod.debug.onOrderChange(name, prevOrder, orderList)
			end
		end
		table.insert(executionOrders[name], { frame = frameCounter, order = orderList })
		if #executionOrders[name] > MAX_ORDER_HISTORY then
			table.remove(executionOrders[name], 1)
		end
	end

	-- GMフック呼び出し（hook.Callの本来の挙動）
	if gm and isfunction(gm[name]) then
		return gm[name](gm, ...)
	end
end

hook.Call = function(name, gm, ...)
	if not vrmod.debug.IsHooksEnabled() then
		return origCall(name, gm, ...)
	end

	local entry = hooks[name]
	if not entry then
		entry = {
			fireCount = 0,
			lastFire = 0,
			lastElapsed = 0,
			avgTime = 0,
		}
		hooks[name] = entry
	end

	local startTime = SysTime()
	local results

	-- Rec ON + プロファイリング有効 → 手動イテレーション版
	if vrmod.debug.callbackProfiling then
		frameCounter = frameCounter + 1
		results = { ProfiledHookCall(name, gm, ...) }
	else
		results = { origCall(name, gm, ...) }
	end

	local elapsed = SysTime() - startTime

	entry.fireCount = entry.fireCount + 1
	entry.lastFire = CurTime()
	entry.lastElapsed = elapsed
	-- 指数移動平均
	entry.avgTime = entry.avgTime * 0.95 + elapsed * 0.05

	-- エクスポート通知
	if vrmod.debug.onHookFire then
		vrmod.debug.onHookFire(name, elapsed, ...)
	end

	return unpack(results)
end

hook.Run = function(name, ...)
	if not vrmod.debug.IsHooksEnabled() then
		return origRun(name, ...)
	end

	local entry = hooks[name]
	if not entry then
		entry = {
			fireCount = 0,
			lastFire = 0,
			lastElapsed = 0,
			avgTime = 0,
		}
		hooks[name] = entry
	end

	local startTime = SysTime()
	local results

	-- Rec ON + プロファイリング有効 → 手動イテレーション版
	if vrmod.debug.callbackProfiling then
		frameCounter = frameCounter + 1
		-- hook.Runはhook.Call(name, GAMEMODE or gmod.GetGamemode(), ...)と同等
		results = { ProfiledHookCall(name, gmod.GetGamemode(), ...) }
	else
		results = { origRun(name, ...) }
	end

	local elapsed = SysTime() - startTime

	entry.fireCount = entry.fireCount + 1
	entry.lastFire = CurTime()
	entry.lastElapsed = elapsed
	entry.avgTime = entry.avgTime * 0.95 + elapsed * 0.05

	if vrmod.debug.onHookFire then
		vrmod.debug.onHookFire(name, elapsed, ...)
	end

	return unpack(results)
end

-- ----------------------------------------
-- フックインベントリ
-- hook.GetTable() + debug.getinfo で各コールバックのソースを特定
-- ----------------------------------------

function vrmod.debug.BuildHookInventory()
	local inventory = {}
	local hookTable = hook.GetTable()

	for hookName, callbacks in pairs(hookTable) do
		inventory[hookName] = {}
		for callbackName, func in pairs(callbacks) do
			if isfunction(func) then
				local info = debug.getinfo(func, "Sl")
				inventory[hookName][callbackName] = {
					source = info.short_src or "unknown",
					linedefined = info.linedefined or 0,
					lastlinedefined = info.lastlinedefined or 0,
				}
			end
		end
	end

	vrmod.debug.hookInventory = inventory
	return inventory
end

-- 特定ファイルに属するフックコールバックを取得
function vrmod.debug.GetCallbacksForFile(filePath)
	local results = {}
	local inventory = vrmod.debug.hookInventory

	-- インベントリが空なら構築
	if not next(inventory) then
		inventory = vrmod.debug.BuildHookInventory()
	end

	for hookName, callbacks in pairs(inventory) do
		for callbackName, info in pairs(callbacks) do
			-- short_srcの末尾がfilePathと一致するか
			if string.EndsWith(info.source, filePath) or string.find(info.source, filePath, 1, true) then
				table.insert(results, {
					hookName = hookName,
					callbackName = callbackName,
					source = info.source,
					linedefined = info.linedefined,
					lastlinedefined = info.lastlinedefined,
				})
			end
		end
	end

	return results
end

-- フック発火時に、ファイルの行範囲をアクティブとしてマーク
function vrmod.debug.UpdateActiveRangesForFile(filePath)
	local callbacks = vrmod.debug.GetCallbacksForFile(filePath)
	local now = CurTime()
	local activeLines = vrmod.debug.activeLines

	for _, cb in ipairs(callbacks) do
		local hookData = hooks[cb.hookName]
		if hookData and (now - hookData.lastFire) < 0.5 then
			-- この関数の行範囲をアクティブにマーク
			for line = cb.linedefined, cb.lastlinedefined do
				activeLines[line] = hookData.lastFire
			end
		end
	end
end

-- ----------------------------------------
-- 行レベルトレース（debug.sethook使用）
-- ----------------------------------------

local LINE_TRACE_TIMEOUT = 30 -- 秒

local function lineHookFunc()
	local info = debug.getinfo(2, "Sl")
	if not info then return end

	local src = info.short_src
	if not src then return end

	-- 選択ファイルと一致しなければ即return
	local traceFile = vrmod.debug.lineTraceFile
	if not traceFile then return end

	if not string.find(src, traceFile, 1, true) then return end

	-- 行番号を記録
	local lineNum = info.currentline
	if lineNum and lineNum > 0 then
		vrmod.debug.activeLines[lineNum] = CurTime()
	end
end

function vrmod.debug.StartLineTrace(filePath)
	if vrmod.debug.lineTraceActive then
		vrmod.debug.StopLineTrace()
	end

	vrmod.debug.lineTraceFile = filePath
	vrmod.debug.lineTraceActive = true
	vrmod.debug.lineTraceStartTime = CurTime()
	vrmod.debug.activeLines = {}

	debug.sethook(lineHookFunc, "l")

	Log.Info("hookmon", "Line trace started for: " .. filePath)

	-- 自動タイムアウト
	timer.Create("vrmod_debug_linetrace_timeout", LINE_TRACE_TIMEOUT, 1, function()
		if vrmod.debug.lineTraceActive then
			vrmod.debug.StopLineTrace()
			Log.Warn("hookmon", "Line trace auto-stopped after " .. LINE_TRACE_TIMEOUT .. "s timeout")
		end
	end)
end

function vrmod.debug.StopLineTrace()
	if not vrmod.debug.lineTraceActive then return end

	debug.sethook()
	vrmod.debug.lineTraceActive = false
	vrmod.debug.lineTraceFile = nil
	timer.Remove("vrmod_debug_linetrace_timeout")

	Log.Info("hookmon", "Line trace stopped")
end

-- ----------------------------------------
-- フック発火レートの計算
-- ----------------------------------------

local lastRateCalcTime = 0
local lastFireCounts = {}
vrmod.debug.hookRates = vrmod.debug.hookRates or {}

function vrmod.debug.CalcHookRates()
	local now = SysTime()
	local dt = now - lastRateCalcTime
	if dt < 0.5 then return vrmod.debug.hookRates end

	for hookName, data in pairs(hooks) do
		local prevCount = lastFireCounts[hookName] or 0
		local rate = (data.fireCount - prevCount) / dt
		vrmod.debug.hookRates[hookName] = rate
		lastFireCounts[hookName] = data.fireCount
	end

	lastRateCalcTime = now
	return vrmod.debug.hookRates
end

-- ----------------------------------------
-- Stale Hook検出（L27対策）
-- VR開始時と終了時のhookテーブルを比較
-- ----------------------------------------

-- hookテーブルのディープコピー（source情報付き）
local function SnapshotHookTable()
	local snapshot = {}
	local hookTable = hook.GetTable()

	for hookName, callbacks in pairs(hookTable) do
		snapshot[hookName] = {}
		for cbName, func in pairs(callbacks) do
			if isfunction(func) then
				local info = debug.getinfo(func, "Sl")
				snapshot[hookName][cbName] = {
					source = info and info.short_src or "unknown",
					linedefined = info and info.linedefined or 0,
				}
			end
		end
	end

	return snapshot
end

-- VR開始時にスナップショット取得
hook.Add("VRMod_Start", "vrmod_debug_hookmon_snapshot_start", function(ply)
	if ply ~= LocalPlayer() then return end

	vrmod.debug.hookSnapshots.vrStart = SnapshotHookTable()
	vrmod.debug.hookSnapshots.vrStartTime = CurTime()
	Log.Info("hookmon", "Hook snapshot taken at VR start (" .. table.Count(vrmod.debug.hookSnapshots.vrStart) .. " hooks)")
end)

-- VR終了時にスナップショット取得 + stale検出
hook.Add("VRMod_Exit", "vrmod_debug_hookmon_snapshot_exit", function(ply)
	if ply ~= LocalPlayer() then return end

	-- 少し遅延させて、正常なクリーンアップが終わった後に比較
	timer.Simple(0.5, function()
		vrmod.debug.hookSnapshots.vrExit = SnapshotHookTable()
		vrmod.debug.hookSnapshots.vrExitTime = CurTime()

		-- stale hook検出: VR開始時に存在し、VR終了後も残っているhook
		-- （VR関連のhookが残留していたら問題）
		local startSnap = vrmod.debug.hookSnapshots.vrStart
		local exitSnap = vrmod.debug.hookSnapshots.vrExit
		local stale = {}

		if startSnap and exitSnap then
			for hookName, callbacks in pairs(exitSnap) do
				for cbName, info in pairs(callbacks) do
					-- VR開始時に存在していたコールバックがまだ残っている
					if startSnap[hookName] and startSnap[hookName][cbName] then
						-- vrmod/VRMod関連のコールバックのみチェック
						local isVRRelated = string.find(cbName, "vrmod", 1, true)
							or string.find(cbName, "VRMod", 1, true)
							or string.find(info.source, "vrmod", 1, true)
						if isVRRelated then
							table.insert(stale, {
								hookName = hookName,
								callbackName = cbName,
								source = info.source,
								linedefined = info.linedefined,
							})
						end
					end
				end
			end

			-- VR開始時になかったが終了後に追加された新規hook（異常なケース）
			for hookName, callbacks in pairs(exitSnap) do
				for cbName, info in pairs(callbacks) do
					if not startSnap[hookName] or not startSnap[hookName][cbName] then
						local isVRRelated = string.find(cbName, "vrmod", 1, true)
							or string.find(cbName, "VRMod", 1, true)
							or string.find(info.source, "vrmod", 1, true)
						if isVRRelated then
							table.insert(stale, {
								hookName = hookName,
								callbackName = cbName,
								source = info.source,
								linedefined = info.linedefined,
								note = "VR中に追加され、終了後も残留",
							})
						end
					end
				end
			end
		end

		vrmod.debug.staleHooks = stale

		if #stale > 0 then
			Log.Warn("hookmon", "Stale hooks detected after VR exit: " .. #stale)
			for _, s in ipairs(stale) do
				Log.Warn("hookmon", "  " .. s.hookName .. "/" .. s.callbackName .. " (" .. s.source .. ":" .. s.linedefined .. ")" .. (s.note and " [" .. s.note .. "]" or ""))
			end
		else
			Log.Info("hookmon", "No stale hooks detected after VR exit")
		end
	end)
end)

-- ----------------------------------------
-- コンソールコマンド
-- ----------------------------------------

concommand.Add("vrmod_unoff_debug_hooks_list", function()
	local inventory = vrmod.debug.BuildHookInventory()
	print("=== VRMod Hook Inventory ===")
	for hookName, callbacks in SortedPairs(inventory) do
		local data = hooks[hookName]
		local fireInfo = data and string.format(" [fires: %d, avg: %.3fms]", data.fireCount, data.avgTime * 1000) or ""
		print("  " .. hookName .. fireInfo)
		for cbName, info in SortedPairs(callbacks) do
			print(string.format("    %-40s %s:%d-%d", cbName, info.source, info.linedefined, info.lastlinedefined))
		end
	end
	print("============================")
end)

-- コールバック単位プロファイル結果をコンソール出力
concommand.Add("vrmod_unoff_debug_callback_profile", function()
	local stats = vrmod.debug.callbackStats
	if not next(stats) then
		print("No callback profiling data. Start recording first.")
		return
	end

	print("=== Callback Profile (sorted by avgTime) ===")
	for hookName, callbacks in SortedPairs(stats) do
		print("  [" .. hookName .. "]")
		-- avgTimeでソート
		local sorted = {}
		for cbName, s in pairs(callbacks) do
			table.insert(sorted, { name = cbName, data = s })
		end
		table.sort(sorted, function(a, b) return a.data.avgTime > b.data.avgTime end)

		for _, item in ipairs(sorted) do
			local s = item.data
			print(string.format("    %-40s avg:%.3fms  max:%.3fms  calls:%d  %s:%d",
				item.name, s.avgTime * 1000, s.maxTime * 1000, s.callCount, s.source, s.linedefined))
		end
	end
	print("=============================================")
end)

-- stale hook一覧表示
concommand.Add("vrmod_unoff_debug_stale_hooks", function()
	local stale = vrmod.debug.staleHooks
	if not stale or #stale == 0 then
		print("No stale hooks detected. (Run VR session first)")
		return
	end

	print("=== Stale Hooks (remained after VR exit) ===")
	for _, s in ipairs(stale) do
		local note = s.note and (" [" .. s.note .. "]") or ""
		print(string.format("  %s / %-30s %s:%d%s", s.hookName, s.callbackName, s.source, s.linedefined, note))
	end
	print("=============================================")
end)

Log.Info("hookmon", "Hook monitor initialized. hook.Call/Run wrapped. Callback profiler ready.")

--------[vrmod_debug_hookmon.lua]End--------
