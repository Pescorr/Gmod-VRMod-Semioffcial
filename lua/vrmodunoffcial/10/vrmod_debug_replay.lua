--------[vrmod_debug_replay.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- トラッキング記録 + リプレイエンジン
-- Part A: 実VR/Mock中の連続位置データを記録
-- Part B: 録画データをMockシステムに注入して再生
-- 既存ファイルへの変更ゼロ・削除で完全復旧
-- ========================================

local Log = vrmod.debug.Log

-- ========================================
-- Part A: トラッキング記録
-- ========================================

vrmod.debug.trackRecorder = vrmod.debug.trackRecorder or {}
local rec = vrmod.debug.trackRecorder

rec.recording = false
rec.startTime = 0

-- バッファ制限
local MAX_TRACKING_FRAMES = 36000  -- 15Hz × 40分
local MAX_INPUT_EVENTS = 10000
local MAX_ANALOG_FRAMES = 36000

local cv_trackrate = CreateClientConVar("vrmod_unoff_debug_mock_trackrate", "15", true, FCVAR_ARCHIVE,
	"Tracking record rate in Hz", 5, 30)
local cv_autorecord = CreateClientConVar("vrmod_unoff_debug_mock_autorecord", "0", true, FCVAR_ARCHIVE,
	"Auto-start tracking recording on VR start")

-- ----------------------------------------
-- 循環バッファ
-- ----------------------------------------
local function BufferInsert(tbl, entry, maxSize)
	tbl[#tbl + 1] = entry
	if #tbl > maxSize then
		table.remove(tbl, 1)
	end
end

-- ----------------------------------------
-- コンパクトフォーマットヘルパー
-- JSONサイズ最小化: 小数点1桁に丸め
-- ----------------------------------------
local mathRound = math.Round

local function CompactVec(v)
	if not v then return {0, 0, 0} end
	return {mathRound(v.x, 1), mathRound(v.y, 1), mathRound(v.z, 1)}
end

local function CompactAng(a)
	if not a then return {0, 0, 0} end
	return {mathRound(a.p or a.pitch or a[1] or 0, 1),
	        mathRound(a.y or a.yaw or a[2] or 0, 1),
	        mathRound(a.r or a.roll or a[3] or 0, 1)}
end

-- ----------------------------------------
-- 記録データ初期化
-- ----------------------------------------
local data = {}

local function ResetData()
	data = {
		session = {},
		trackingFrames = {},
		inputEvents = {},
		analogFrames = {},
	}
end

ResetData()

-- ----------------------------------------
-- セッションメタデータ
-- ----------------------------------------
local function BuildSessionMeta()
	return {
		startTime = os.date("%Y-%m-%dT%H:%M:%S"),
		map = game.GetMap(),
		mockMode = (g_VR and g_VR.mockMode) or false,
		vrActive = (g_VR and g_VR.active) or false,
		recordRate = cv_trackrate:GetInt(),
	}
end

-- ----------------------------------------
-- 記録開始
-- ----------------------------------------
function rec.Start()
	if rec.recording then
		Log.Warn("trackRecorder", "Already recording.")
		return false
	end

	if not g_VR or not g_VR.active then
		Log.Warn("trackRecorder", "VR (or Mock VR) must be active to record.")
		return false
	end

	ResetData()
	rec.startTime = CurTime()
	data.session = BuildSessionMeta()
	rec.recording = true

	-- トラッキングフレーム記録タイマー
	local interval = 1 / cv_trackrate:GetInt()
	timer.Create("vrmod_track_recorder", interval, 0, function()
		if not rec.recording then return end
		if not g_VR or not g_VR.tracking or not g_VR.tracking.hmd then return end

		local t = g_VR.tracking
		local relTime = mathRound(CurTime() - rec.startTime, 2)

		-- トラッキングフレーム
		BufferInsert(data.trackingFrames, {
			t = relTime,
			h = CompactVec(t.hmd.pos),
			ha = CompactAng(t.hmd.ang),
			l = CompactVec(t.pose_lefthand and t.pose_lefthand.pos),
			la = CompactAng(t.pose_lefthand and t.pose_lefthand.ang),
			r = CompactVec(t.pose_righthand and t.pose_righthand.pos),
			ra = CompactAng(t.pose_righthand and t.pose_righthand.ang),
			lv = CompactVec(t.pose_lefthand and t.pose_lefthand.vel),
			rv = CompactVec(t.pose_righthand and t.pose_righthand.vel),
		}, MAX_TRACKING_FRAMES)

		-- アナログ入力フレーム
		if g_VR.input then
			local inp = g_VR.input
			BufferInsert(data.analogFrames, {
				t = relTime,
				tr = mathRound(inp.vector1_primaryfire or 0, 2),
				w = inp.vector2_walkdirection and
					{mathRound(inp.vector2_walkdirection.x or 0, 2),
					 mathRound(inp.vector2_walkdirection.y or 0, 2)} or {0, 0},
				fl = inp.skeleton_lefthand and inp.skeleton_lefthand.fingerCurls or {0,0,0,0,0},
				fr = inp.skeleton_righthand and inp.skeleton_righthand.fingerCurls or {0,0,0,0,0},
			}, MAX_ANALOG_FRAMES)
		end
	end)

	Log.Info("trackRecorder", "Recording started at " .. cv_trackrate:GetString() .. " Hz")
	return true
end

-- ----------------------------------------
-- 記録停止
-- ----------------------------------------
function rec.Stop()
	if not rec.recording then
		Log.Warn("trackRecorder", "Not recording.")
		return false
	end

	timer.Remove("vrmod_track_recorder")
	rec.recording = false

	data.session.endTime = os.date("%Y-%m-%dT%H:%M:%S")
	data.session.duration = mathRound(CurTime() - rec.startTime, 2)
	data.session.totalTrackingFrames = #data.trackingFrames
	data.session.totalInputEvents = #data.inputEvents

	Log.Info("trackRecorder", "Recording stopped. "
		.. #data.trackingFrames .. " tracking frames, "
		.. #data.inputEvents .. " input events, "
		.. string.format("%.1f", data.session.duration) .. "s duration")
	return true
end

-- ----------------------------------------
-- JSONエクスポート
-- ----------------------------------------
function rec.Export()
	if #data.trackingFrames == 0 then
		Log.Warn("trackRecorder", "No tracking data to export.")
		return false
	end

	-- data/vrmod_debug/ ディレクトリ確保
	if not file.IsDir("vrmod_debug", "DATA") then
		file.CreateDir("vrmod_debug")
	end

	local filename = "vrmod_debug/track_session_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
	local json = util.TableToJSON(data, true)

	if not json then
		Log.Error("trackRecorder", "Failed to serialize data to JSON.")
		return false
	end

	file.Write(filename, json)
	Log.Info("trackRecorder", "Exported to data/" .. filename
		.. " (" .. string.format("%.1f", #json / 1024) .. " KB)")
	return true, filename
end

-- ----------------------------------------
-- VRMod_Inputフックで入力イベントを記録
-- ----------------------------------------
hook.Add("VRMod_Input", "vrmod_track_recorder_input", function(action, pressed)
	if not rec.recording then return end
	BufferInsert(data.inputEvents, {
		t = mathRound(CurTime() - rec.startTime, 2),
		a = action,
		p = pressed,
	}, MAX_INPUT_EVENTS)
end)

-- ----------------------------------------
-- 自動記録（VRMod_Start時）
-- ----------------------------------------
hook.Add("VRMod_Start", "vrmod_track_recorder_autostart", function()
	if not vrmod.debug or not vrmod.debug.enabled then return end
	if cv_autorecord:GetBool() then
		rec.Start()
	end
end)

-- ----------------------------------------
-- 自動停止（VRMod_Exit時）
-- ----------------------------------------
hook.Add("VRMod_Exit", "vrmod_track_recorder_autostop", function()
	if rec.recording then
		rec.Stop()
		-- 自動エクスポート
		rec.Export()
	end
end)

-- ========================================
-- Part B: リプレイエンジン
-- ========================================

vrmod.debug.replay = vrmod.debug.replay or {}
local replay = vrmod.debug.replay

replay.active = false
replay.paused = false
replay.speed = 1.0
replay.cursor = 0.0
replay.duration = 0.0
replay.data = nil
replay.trackingIndex = 1
replay.inputIndex = 1

-- ----------------------------------------
-- セッション読み込み
-- ----------------------------------------
function replay.Load(filename)
	-- data/フォルダからの相対パス
	local content = file.Read(filename, "DATA")
	if not content then
		Log.Error("replay", "File not found: " .. filename)
		return false
	end

	local parsed = util.JSONToTable(content)
	if not parsed then
		Log.Error("replay", "Failed to parse JSON.")
		return false
	end

	if not parsed.trackingFrames or #parsed.trackingFrames == 0 then
		Log.Error("replay", "No tracking frames in file.")
		return false
	end

	replay.data = parsed
	replay.duration = parsed.session and parsed.session.duration or 0
	replay.cursor = 0
	replay.trackingIndex = 1
	replay.inputIndex = 1
	replay.paused = true  -- 読み込み直後はpause

	Log.Info("replay", "Loaded: " .. #parsed.trackingFrames .. " tracking frames, "
		.. #(parsed.inputEvents or {}) .. " input events, "
		.. string.format("%.1f", replay.duration) .. "s duration")
	return true
end

-- ----------------------------------------
-- トラッキングフレーム適用
-- コンパクト形式 → g_VR.tracking
-- ----------------------------------------
local function ApplyTrackingFrame(frame)
	if not frame or not g_VR.tracking then return end

	local h = frame.h
	local ha = frame.ha
	if h and ha then
		g_VR.tracking.hmd.pos = Vector(h[1], h[2], h[3])
		g_VR.tracking.hmd.ang = Angle(ha[1], ha[2], ha[3])
	end

	local l = frame.l
	local la = frame.la
	if l and la and g_VR.tracking.pose_lefthand then
		g_VR.tracking.pose_lefthand.pos = Vector(l[1], l[2], l[3])
		g_VR.tracking.pose_lefthand.ang = Angle(la[1], la[2], la[3])
	end

	local r = frame.r
	local ra = frame.ra
	if r and ra and g_VR.tracking.pose_righthand then
		g_VR.tracking.pose_righthand.pos = Vector(r[1], r[2], r[3])
		g_VR.tracking.pose_righthand.ang = Angle(ra[1], ra[2], ra[3])
	end

	-- velocity
	local lv = frame.lv
	if lv and g_VR.tracking.pose_lefthand then
		g_VR.tracking.pose_lefthand.vel = Vector(lv[1], lv[2], lv[3])
	end
	local rv = frame.rv
	if rv and g_VR.tracking.pose_righthand then
		g_VR.tracking.pose_righthand.vel = Vector(rv[1], rv[2], rv[3])
	end

	-- characterYaw (HMDのyawから)
	if ha then
		g_VR.characterYaw = ha[2]
	end
end

-- ----------------------------------------
-- 入力イベントの再構築（seek用）
-- seek位置での入力状態を全イベントから再構築
-- ----------------------------------------
local function RebuildInputState(targetTime)
	if not replay.data or not replay.data.inputEvents then return end

	-- 全入力をリセット
	for k, v in pairs(g_VR.input) do
		if type(v) == "boolean" then
			g_VR.input[k] = false
		end
	end

	-- targetTimeまでの全イベントを適用
	replay.inputIndex = 1
	for i, ev in ipairs(replay.data.inputEvents) do
		if ev.t > targetTime then
			replay.inputIndex = i
			return
		end
		if g_VR.input[ev.a] ~= nil then
			g_VR.input[ev.a] = ev.p
		end
	end
	replay.inputIndex = #replay.data.inputEvents + 1
end

-- ----------------------------------------
-- リプレイフレーム更新
-- vrmod_debug_mock.luaのThinkから呼ばれる
-- ----------------------------------------
function replay.UpdateReplayFrame()
	if not replay.active or not replay.data then return end

	if replay.paused then
		-- pause中もカーソル位置のフレームを適用（seek後の表示用）
		local frames = replay.data.trackingFrames
		if frames and replay.trackingIndex <= #frames then
			ApplyTrackingFrame(frames[replay.trackingIndex])
		end
		return
	end

	-- カーソル進行
	replay.cursor = replay.cursor + FrameTime() * replay.speed

	-- 終端チェック
	if replay.cursor >= replay.duration then
		replay.cursor = replay.duration
		replay.paused = true
		Log.Info("replay", "Reached end of recording.")
		return
	end

	-- トラッキングフレーム検索・適用
	local frames = replay.data.trackingFrames
	if frames then
		while replay.trackingIndex < #frames
			and frames[replay.trackingIndex + 1]
			and frames[replay.trackingIndex + 1].t <= replay.cursor do
			replay.trackingIndex = replay.trackingIndex + 1
		end
		ApplyTrackingFrame(frames[replay.trackingIndex])
	end

	-- 入力イベント発火（カーソル以前の未処理イベント）
	local events = replay.data.inputEvents
	if events then
		g_VR.changedInputs = g_VR.changedInputs or {}
		while replay.inputIndex <= #events
			and events[replay.inputIndex].t <= replay.cursor do
			local ev = events[replay.inputIndex]
			if g_VR.input[ev.a] ~= nil then
				g_VR.input[ev.a] = ev.p
				g_VR.changedInputs[ev.a] = ev.p
			end
			replay.inputIndex = replay.inputIndex + 1
		end
	end
end

-- ----------------------------------------
-- リプレイ開始
-- ----------------------------------------
function replay.Start()
	if not replay.data then
		Log.Error("replay", "No data loaded. Use vrmod_unoff_replay_load first.")
		return false
	end

	-- Mockが動いていなければ自動起動
	if not g_VR.mockMode then
		if vrmod.debug.mock and vrmod.debug.mock.Start then
			local ok = vrmod.debug.mock.Start()
			if not ok then
				Log.Error("replay", "Failed to start Mock VR for replay.")
				return false
			end
		else
			Log.Error("replay", "Mock VR system not available.")
			return false
		end
	end

	replay.cursor = 0
	replay.trackingIndex = 1
	replay.inputIndex = 1
	replay.paused = false
	replay.active = true

	Log.Info("replay", "Playback started. Speed=" .. replay.speed .. "x")
	return true
end

-- ----------------------------------------
-- リプレイ停止
-- ----------------------------------------
function replay.Stop()
	replay.active = false
	replay.paused = false
	replay.cursor = 0
	replay.trackingIndex = 1
	replay.inputIndex = 1
	Log.Info("replay", "Playback stopped.")
	return true
end

-- ----------------------------------------
-- シーク
-- ----------------------------------------
function replay.Seek(seconds)
	if not replay.data then
		Log.Warn("replay", "No data loaded.")
		return false
	end

	seconds = math.Clamp(seconds, 0, replay.duration)
	replay.cursor = seconds

	-- トラッキングindex再計算
	replay.trackingIndex = 1
	local frames = replay.data.trackingFrames
	if frames then
		for i, f in ipairs(frames) do
			if f.t > seconds then
				replay.trackingIndex = math.max(1, i - 1)
				break
			end
			replay.trackingIndex = i
		end
	end

	-- 入力状態再構築
	RebuildInputState(seconds)

	-- seek位置のフレーム即時適用
	if frames and replay.trackingIndex <= #frames then
		ApplyTrackingFrame(frames[replay.trackingIndex])
	end

	Log.Info("replay", "Seeked to " .. string.format("%.1f", seconds) .. "s")
	return true
end

-- ========================================
-- コンソールコマンド
-- ========================================

-- Recording
concommand.Add("vrmod_unoff_track_record", function()
	rec.Start()
end)

concommand.Add("vrmod_unoff_track_stop", function()
	rec.Stop()
end)

concommand.Add("vrmod_unoff_track_export", function()
	rec.Export()
end)

-- Replay
concommand.Add("vrmod_unoff_replay_list", function()
	local files = file.Find("vrmod/track_session_*.txt", "DATA")
	if not files or #files == 0 then
		MsgC(Color(255, 200, 100), "[VRMod Replay] No session files found in data/vrmod/\n")
		return
	end
	MsgC(Color(100, 200, 255), "[VRMod Replay] Available sessions:\n")
	for _, f in ipairs(files) do
		local size = file.Size("vrmod/" .. f, "DATA")
		MsgC(Color(200, 200, 200), "  vrmod/" .. f
			.. " (" .. string.format("%.1f", (size or 0) / 1024) .. " KB)\n")
	end
end)

concommand.Add("vrmod_unoff_replay_load", function(ply, cmd, args)
	if not args[1] then
		MsgC(Color(255, 200, 100), "[VRMod Replay] Usage: vrmod_unoff_replay_load <filename>\n")
		MsgC(Color(200, 200, 200), "  Example: vrmod_unoff_replay_load vrmod/track_session_20260314_120000.txt\n")
		return
	end
	replay.Load(args[1])
end)

concommand.Add("vrmod_unoff_replay_start", function()
	replay.Start()
end)

concommand.Add("vrmod_unoff_replay_pause", function()
	if not replay.active then
		Log.Warn("replay", "Replay not active.")
		return
	end
	replay.paused = not replay.paused
	Log.Info("replay", replay.paused and "Paused." or "Resumed.")
end)

concommand.Add("vrmod_unoff_replay_speed", function(ply, cmd, args)
	local speed = tonumber(args[1])
	if not speed then
		MsgC(Color(255, 200, 100), "[VRMod Replay] Usage: vrmod_unoff_replay_speed <0.25-4.0>\n")
		return
	end
	replay.speed = math.Clamp(speed, 0.25, 4.0)
	Log.Info("replay", "Speed set to " .. replay.speed .. "x")
end)

concommand.Add("vrmod_unoff_replay_seek", function(ply, cmd, args)
	local sec = tonumber(args[1])
	if not sec then
		MsgC(Color(255, 200, 100), "[VRMod Replay] Usage: vrmod_unoff_replay_seek <seconds>\n")
		return
	end
	replay.Seek(sec)
end)

concommand.Add("vrmod_unoff_replay_stop", function()
	replay.Stop()
end)

Log.Info("replay", "Tracking recorder + replay engine loaded.")
Log.Info("replay", "  Record: vrmod_unoff_track_record / _stop / _export")
Log.Info("replay", "  Replay: vrmod_unoff_replay_list / _load / _start / _pause / _speed / _seek / _stop")
--------[vrmod_debug_replay.lua]End--------
