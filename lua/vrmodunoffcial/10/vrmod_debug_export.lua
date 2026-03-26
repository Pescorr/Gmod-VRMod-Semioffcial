--------[vrmod_debug_export.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- データ記録エンジン（フライトレコーダー）
-- VRセッション中の全動作をJSON出力
-- Claude Codeに渡してリモートデバッグ可能に
-- ========================================

local Log = vrmod.debug.Log

vrmod.debug.export = vrmod.debug.export or {}

local export = vrmod.debug.export

-- ----------------------------------------
-- 状態管理
-- ----------------------------------------
export.recording = false
export.startTime = 0

-- データバッファ（循環バッファ制限）
local MAX_HOOK_EVENTS = 10000
local MAX_INPUT_EVENTS = 5000
local MAX_ENTITY_EVENTS = 2000
local SNAPSHOT_INTERVAL = 10 -- 秒

local MAX_ORDER_CHANGES = 500

local data = {
	session = {},
	hookEvents = {},
	inputEvents = {},
	entityEvents = {},
	errors = {},
	convarSnapshots = {},
	performance = {},
	-- 新規: コールバック単位プロファイル
	callbackProfile = {},
	-- 新規: 実行順序変化ログ
	executionOrderChanges = {},
	-- 新規: stale hook一覧
	staleHooks = {},
}

local function ResetData()
	data = {
		session = {},
		hookEvents = {},
		inputEvents = {},
		entityEvents = {},
		errors = {},
		convarSnapshots = {},
		performance = {},
		callbackProfile = {},
		executionOrderChanges = {},
		staleHooks = {},
	}
end

-- ----------------------------------------
-- 循環バッファ挿入
-- ----------------------------------------
local function BufferInsert(tbl, entry, maxSize)
	table.insert(tbl, entry)
	if #tbl > maxSize then
		table.remove(tbl, 1)
	end
end

-- ----------------------------------------
-- セッションメタデータ構築
-- ----------------------------------------
local function BuildSessionMeta()
	local meta = {
		startTime = os.date("%Y-%m-%dT%H:%M:%S"),
		map = game.GetMap(),
		vrActive = (g_VR and g_VR.active) or false,
		moduleVersion = (g_VR and g_VR.moduleVersion) or 0,
	}

	-- ロード済みモジュール
	meta.loadedModules = {}
	for folderName, files in pairs(vrmod.debug.fileTree) do
		for _, fileInfo in ipairs(files) do
			table.insert(meta.loadedModules, fileInfo.path)
		end
	end
	table.sort(meta.loadedModules)

	-- トラッキングモード
	if g_VR then
		if g_VR.sixPoints then
			meta.trackingMode = "6-point"
		elseif g_VR.threePoints then
			meta.trackingMode = "3-point"
		else
			meta.trackingMode = "unknown"
		end
	end

	return meta
end

-- ----------------------------------------
-- ConVarスナップショット
-- ----------------------------------------
local function TakeConvarSnapshot(label)
	local convars = {}

	-- vrmod関連ConVarを収集
	local convarNames = {}
	local cvTable, _ = vrmod.GetConvars()
	if cvTable then
		for name, _ in pairs(cvTable) do
			table.insert(convarNames, name)
		end
	end

	-- vrmod_unoff_* ConVarも追加
	for _, name in ipairs({
		"vrmod_unoff_debug", "vrmod_unoff_debug_hooks", "vrmod_unoff_debug_loglevel",
		"vrmod_unoff_developer_mode", "vrmod_error_hard",
	}) do
		table.insert(convarNames, name)
	end

	-- x64mode ConVarを動的に追加
	if vrmod.x64mode and vrmod.x64mode.features then
		table.insert(convarNames, "vrmod_unoff_x64_master")
		for featureId, feature in pairs(vrmod.x64mode.features) do
			table.insert(convarNames, feature.convar)
		end
	end

	for _, name in ipairs(convarNames) do
		local cv = GetConVar(name)
		if cv then
			convars[name] = cv:GetString()
		end
	end

	BufferInsert(data.convarSnapshots, {
		time = CurTime() - export.startTime,
		label = label,
		convars = convars,
	}, 100)
end

-- ----------------------------------------
-- パフォーマンスメトリクス
-- ----------------------------------------
local function TakePerformanceSnapshot()
	local rates = vrmod.debug.CalcHookRates()

	-- トップフック（所要時間順）
	local topHooks = {}
	for hookName, hookData in pairs(vrmod.debug.hooks) do
		if hookData.avgTime > 0.00001 then
			table.insert(topHooks, {
				name = hookName,
				avg_ms = math.Round(hookData.avgTime * 1000, 3),
				rate = math.Round(rates[hookName] or 0, 1),
			})
		end
	end
	table.sort(topHooks, function(a, b) return a.avg_ms > b.avg_ms end)

	-- 上位10件のみ
	local trimmed = {}
	for i = 1, math.min(10, #topHooks) do
		trimmed[i] = topHooks[i]
	end

	BufferInsert(data.performance, {
		time = CurTime() - export.startTime,
		fps = math.Round(1 / FrameTime(), 0),
		topHooks = trimmed,
	}, 500)
end

-- ----------------------------------------
-- フックイベント記録（hook.Callラッパーから呼ばれる）
-- ----------------------------------------
local function OnHookFire(hookName, elapsed, ...)
	if not export.recording then return end

	local args = {...}
	local argsSummary = ""

	-- VRMod_Inputの場合、引数を記録
	if hookName == "VRMod_Input" then
		local action = tostring(args[1] or "")
		local pressed = tostring(args[2] or "")
		argsSummary = "action=" .. action .. ", pressed=" .. pressed

		-- VR入力イベントも別途記録
		local inputEntry = {
			time = CurTime() - export.startTime,
			action = action,
			pressed = tobool(args[2]),
		}

		-- ハンド位置を取得（pcall保護）
		if g_VR and g_VR.tracking then
			if g_VR.tracking.pose_lefthand then
				local pos = g_VR.tracking.pose_lefthand.pos
				if pos then
					inputEntry.leftHandPos = { math.Round(pos.x, 1), math.Round(pos.y, 1), math.Round(pos.z, 1) }
				end
			end
			if g_VR.tracking.pose_righthand then
				local pos = g_VR.tracking.pose_righthand.pos
				if pos then
					inputEntry.rightHandPos = { math.Round(pos.x, 1), math.Round(pos.y, 1), math.Round(pos.z, 1) }
				end
			end
			if g_VR.tracking.hmd then
				local pos = g_VR.tracking.hmd.pos
				if pos then
					inputEntry.hmdPos = { math.Round(pos.x, 1), math.Round(pos.y, 1), math.Round(pos.z, 1) }
				end
			end
		end

		BufferInsert(data.inputEvents, inputEntry, MAX_INPUT_EVENTS)
	end

	-- Pickup/Dropイベント
	if hookName == "VRMod_Pickup" or hookName == "VRMod_Drop" then
		local ent = args[2] -- 通常: ply, ent
		local entEntry = {
			time = CurTime() - export.startTime,
			type = hookName == "VRMod_Pickup" and "pickup" or "drop",
		}
		if IsValid(ent) then
			entEntry.entity = tostring(ent)
			entEntry.entityClass = ent:GetClass()
			entEntry.entityModel = ent:GetModel() or ""
		end

		BufferInsert(data.entityEvents, entEntry, MAX_ENTITY_EVENTS)
	end

	-- 一般フックイベント（全フックを記録するとバッファが溢れるので、vrmod関連のみ）
	if string.StartWith(hookName, "VRMod") or string.find(hookName, "vrmod", 1, true) then
		-- コールバック情報を取得
		local callbackInfo = ""
		local inventory = vrmod.debug.hookInventory[hookName]
		if inventory then
			for cbName, _ in pairs(inventory) do
				if callbackInfo ~= "" then callbackInfo = callbackInfo .. ", " end
				callbackInfo = callbackInfo .. cbName
			end
		end

		BufferInsert(data.hookEvents, {
			time = CurTime() - export.startTime,
			hook = hookName,
			callbacks = callbackInfo,
			duration_ms = math.Round(elapsed * 1000, 3),
			args_summary = argsSummary,
		}, MAX_HOOK_EVENTS)
	end
end

-- ----------------------------------------
-- 記録制御
-- ----------------------------------------
function export.StartRecording()
	if export.recording then
		Log.Warn("export", "Already recording")
		return
	end

	ResetData()
	export.recording = true
	export.startTime = CurTime()

	-- セッションメタデータ
	data.session = BuildSessionMeta()

	-- フックインベントリ構築
	vrmod.debug.BuildHookInventory()

	-- 初期ConVarスナップショット
	TakeConvarSnapshot("session_start")

	-- hook.Callラッパーからの通知を登録
	vrmod.debug.onHookFire = OnHookFire

	-- コールバック単位プロファイリング有効化
	vrmod.debug.callbackProfiling = true
	vrmod.debug.callbackStats = {}
	vrmod.debug.executionOrders = {}

	-- 実行順序変化コールバック登録
	vrmod.debug.onOrderChange = function(hookName, oldOrder, newOrder)
		BufferInsert(data.executionOrderChanges, {
			time = CurTime() - export.startTime,
			hook = hookName,
			oldOrder = oldOrder,
			newOrder = newOrder,
		}, MAX_ORDER_CHANGES)
	end

	Log.Info("export", "Callback profiling enabled")

	-- 定期スナップショットタイマー
	timer.Create("vrmod_debug_export_snapshot", SNAPSHOT_INTERVAL, 0, function()
		if not export.recording then return end
		TakeConvarSnapshot("periodic")
		TakePerformanceSnapshot()
	end)

	-- エラー監視フック
	hook.Add("Think", "vrmod_debug_export_errors", function()
		if not export.recording then return end

		-- エラーバッファから新しいエラーを取得
		local errors = vrmod.debug.GetErrors()
		local newCount = #errors - #data.errors
		if newCount > 0 then
			for i = #errors - newCount + 1, #errors do
				local err = errors[i]
				if err then
					table.insert(data.errors, {
						time = err.time - export.startTime,
						level = "error",
						source = err.source,
						message = err.message,
						stacktrace = err.stack,
					})
				end
			end
		end
	end)

	Log.Info("export", "Recording started")
end

function export.StopRecording()
	if not export.recording then return end

	export.recording = false

	-- 最終スナップショット
	TakeConvarSnapshot("session_end")
	TakePerformanceSnapshot()

	-- セッション時間を記録
	data.session.duration_sec = math.Round(CurTime() - export.startTime, 1)

	-- 通知解除
	vrmod.debug.onHookFire = nil
	vrmod.debug.onOrderChange = nil

	-- コールバック単位プロファイリング無効化 + データ収集
	vrmod.debug.callbackProfiling = false

	-- コールバック統計をエクスポートデータにコピー
	local cbStats = vrmod.debug.callbackStats
	if cbStats then
		for hookName, callbacks in pairs(cbStats) do
			data.callbackProfile[hookName] = {}
			for cbName, s in pairs(callbacks) do
				data.callbackProfile[hookName][cbName] = {
					avg_ms = math.Round(s.avgTime * 1000, 3),
					max_ms = math.Round(s.maxTime * 1000, 3),
					total_ms = math.Round(s.totalTime * 1000, 1),
					calls = s.callCount,
					source = s.source,
					linedefined = s.linedefined,
				}
			end
		end
	end

	-- stale hookデータをコピー
	data.staleHooks = vrmod.debug.staleHooks or {}

	Log.Info("export", "Callback profile: " .. table.Count(data.callbackProfile) .. " hooks profiled")
	Log.Info("export", "Order changes: " .. #data.executionOrderChanges)
	Log.Info("export", "Stale hooks: " .. #data.staleHooks)

	-- タイマー/フック除去
	timer.Remove("vrmod_debug_export_snapshot")
	hook.Remove("Think", "vrmod_debug_export_errors")

	Log.Info("export", "Recording stopped. Duration: " .. data.session.duration_sec .. "s")
end

function export.IsRecording()
	return export.recording
end

-- ----------------------------------------
-- JSONエクスポート
-- ----------------------------------------
function export.ExportJSON()
	if export.recording then
		export.StopRecording()
	end

	-- データが空か確認
	local hasData = #data.hookEvents > 0 or #data.inputEvents > 0 or #data.errors > 0
		or next(data.callbackProfile) ~= nil or #data.executionOrderChanges > 0 or #data.staleHooks > 0
	if not hasData then
		Log.Warn("export", "No data to export")
		return nil
	end

	local jsonStr = util.TableToJSON(data, true) -- true = pretty print
	if not jsonStr then
		Log.Error("export", "Failed to serialize data to JSON")
		return nil
	end

	-- ファイル出力（.txt拡張子: GLuaのfile.Writeは.txtのみ確実動作）
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local fileName = "vrmod_debug/debug_session_" .. timestamp .. ".txt"

	-- フォルダ作成
	if not file.IsDir("vrmod_debug", "DATA") then
		file.CreateDir("vrmod_debug")
	end

	file.Write(fileName, jsonStr)

	local filePath = "garrysmod/data/" .. fileName
	Log.Info("export", "Exported to: " .. filePath)
	Log.Info("export", "Data: " .. #data.hookEvents .. " hook events, " .. #data.inputEvents .. " input events, " .. #data.errors .. " errors")

	return filePath
end

-- ----------------------------------------
-- VR終了時: 記録中なら自動停止+エクスポート
-- ----------------------------------------
hook.Add("VRMod_Exit", "vrmod_debug_export_cleanup", function(ply)
	if ply ~= LocalPlayer() then return end
	if export.recording then
		Log.Info("export", "VR exit detected - auto-exporting session data")
		export.ExportJSON()
	end
end)

-- ----------------------------------------
-- コンソールコマンド
-- ----------------------------------------
concommand.Add("vrmod_unoff_debug_record_start", function()
	export.StartRecording()
end)

concommand.Add("vrmod_unoff_debug_record_stop", function()
	export.StopRecording()
end)

concommand.Add("vrmod_unoff_debug_export", function()
	local path = export.ExportJSON()
	if path then
		print("Debug session exported to: " .. path)
	end
end)

Log.Info("export", "Data export engine initialized")

--------[vrmod_debug_export.lua]End--------
