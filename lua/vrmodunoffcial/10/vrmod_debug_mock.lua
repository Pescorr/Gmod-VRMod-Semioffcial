--------[vrmod_debug_mock.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- Desktop Mock VR Mode
-- VRヘッドセットなしでアドオンロジックをテスト
-- 既存ファイルへの変更ゼロ・削除で完全復旧
-- ========================================

local Log = vrmod.debug.Log

vrmod.debug.mock = vrmod.debug.mock or {}
local mock = vrmod.debug.mock

-- ----------------------------------------
-- ConVars
-- ----------------------------------------
local cv_enabled = CreateClientConVar("vrmod_unoff_debug_mock", "0", true, FCVAR_ARCHIVE,
	"Enable Mock VR mode availability")
local cv_hand_dist = CreateClientConVar("vrmod_unoff_debug_mock_hand_dist", "25", true, FCVAR_ARCHIVE,
	"Mock hand forward distance from eye (units)", 5, 60)
local cv_hand_drop = CreateClientConVar("vrmod_unoff_debug_mock_hand_drop", "30", true, FCVAR_ARCHIVE,
	"Mock hand vertical offset below eye (units)", 5, 60)

-- ----------------------------------------
-- 状態管理
-- ----------------------------------------
mock.active = false
local prevKeyState = {}

-- ----------------------------------------
-- キーボード → VRアクション マッピング
-- ----------------------------------------
local keyMap = {
	[MOUSE_LEFT]  = "boolean_primaryfire",
	[MOUSE_RIGHT] = "boolean_secondaryfire",
	[KEY_E]       = "boolean_use",
	[KEY_R]       = "boolean_reload",
	[KEY_F]       = "boolean_flashlight",
	[KEY_G]       = "boolean_right_pickup",
	[KEY_H]       = "boolean_left_pickup",
	[KEY_Q]       = "boolean_spawnmenu",
	[KEY_SPACE]   = "boolean_jump",
	[KEY_1]       = "boolean_slot1",
	[KEY_2]       = "boolean_slot2",
	[KEY_3]       = "boolean_slot3",
	[KEY_4]       = "boolean_slot4",
	[KEY_5]       = "boolean_slot5",
	[KEY_6]       = "boolean_slot6",
}

-- ----------------------------------------
-- デフォルト入力テーブル構築
-- buildClientFrame (vrmod_network.lua:45-89) が要求する全フィールドを含む
-- ----------------------------------------
local function BuildDefaultInput()
	return {
		-- Boolean actions
		boolean_primaryfire = false,
		boolean_secondaryfire = false,
		boolean_left_primaryfire = false,
		boolean_left_secondaryfire = false,
		boolean_use = false,
		boolean_jump = false,
		boolean_sprint = false,
		boolean_reload = false,
		boolean_flashlight = false,
		boolean_changeweapon = false,
		boolean_spawnmenu = false,
		boolean_left_pickup = false,
		boolean_right_pickup = false,
		boolean_undo = false,
		boolean_walk = false,
		boolean_turnleft = false,
		boolean_turnright = false,
		boolean_chat = false,
		boolean_menucontext = false,
		boolean_lefthandmode = false,
		boolean_righthandmode = false,
		boolean_exit = false,
		boolean_walkkey = false,
		boolean_slot1 = false,
		boolean_slot2 = false,
		boolean_slot3 = false,
		boolean_slot4 = false,
		boolean_slot5 = false,
		boolean_slot6 = false,
		boolean_invnext = false,
		boolean_invprev = false,
		boolean_turbo = false,
		boolean_handbrake = false,

		-- Vector1 actions
		vector1_primaryfire = 0,
		vector1_left_primaryfire = 0,
		vector1_forward = 0,
		vector1_reverse = 0,

		-- Vector2 actions
		vector2_walkdirection = { x = 0, y = 0 },
		vector2_smoothturn = { x = 0, y = 0 },
		vector2_steer = { x = 0, y = 0 },

		-- Skeleton data (required by buildClientFrame: fingerCurls[1-5])
		skeleton_lefthand = { fingerCurls = {0, 0, 0, 0, 0} },
		skeleton_righthand = { fingerCurls = {0, 0, 0, 0, 0} },
	}
end

-- ----------------------------------------
-- トラッキングデータ生成
-- vrmod.lua:548-567 のパターンを簡易再現
-- ----------------------------------------
local function UpdateMockTracking()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local eyePos = ply:EyePos()
	local eyeAng = ply:EyeAngles()
	local yawOnly = Angle(0, eyeAng.yaw, 0)
	local vel = ply:GetVelocity()

	-- HMD = プレイヤーの目の位置
	local hmd = g_VR.tracking.hmd
	hmd.pos = eyePos
	hmd.ang = eyeAng
	hmd.vel = vel
	-- angvelは0で十分（デスクトップでは計算困難）

	-- 手のオフセット
	local handDist = cv_hand_dist:GetFloat()
	local handDrop = cv_hand_drop:GetFloat()

	-- 右手 = 視線方向前方・右下
	local rh = g_VR.tracking.pose_righthand
	rh.pos, rh.ang = LocalToWorld(
		Vector(handDist, -10, -handDrop),
		Angle(60, 0, 0),
		eyePos, yawOnly
	)
	rh.vel = vel

	-- 左手 = ミラー
	local lh = g_VR.tracking.pose_lefthand
	lh.pos, lh.ang = LocalToWorld(
		Vector(handDist, 10, -handDrop),
		Angle(60, 0, 0),
		eyePos, yawOnly
	)
	lh.vel = vel

	-- characterYaw更新
	g_VR.characterYaw = eyeAng.yaw
end

-- ----------------------------------------
-- キーボード入力 → VR入力状態
-- 前フレームとの差分でchangedInputsを生成
-- ----------------------------------------
local function UpdateMockInput()
	g_VR.changedInputs = {}

	for key, action in pairs(keyMap) do
		local down = input.IsKeyDown(key)
		if down ~= prevKeyState[key] then
			g_VR.input[action] = down
			g_VR.changedInputs[action] = down
			prevKeyState[key] = down
		end
	end
end

-- ----------------------------------------
-- メインループ (Thinkフック)
-- vrmod.lua:680-704 のRenderSceneループの簡易版
-- ----------------------------------------
local function MockThink()
	if not g_VR.active or not g_VR.mockMode then return end

	-- リプレイシステムがアクティブならそちらに委譲
	if vrmod.debug.replay and vrmod.debug.replay.active then
		-- vrmod_debug_replay.luaがトラッキング更新を行う
		if vrmod.debug.replay.UpdateReplayFrame then
			vrmod.debug.replay.UpdateReplayFrame()
		end
	else
		-- 通常のデスクトップモック
		UpdateMockTracking()
	end

	hook.Call("VRMod_Tracking")

	-- 入力更新（リプレイ中はリプレイ側が処理、ここではデスクトップ入力のみ）
	if not (vrmod.debug.replay and vrmod.debug.replay.active and not vrmod.debug.replay.paused) then
		UpdateMockInput()
	end

	for k, v in pairs(g_VR.changedInputs) do
		hook.Call("VRMod_Input", nil, k, v)
	end

	hook.Call("VRMod_PreRender")
end

-- ----------------------------------------
-- Mock VR 起動
-- ----------------------------------------
function mock.Start()
	if not cv_enabled:GetBool() then
		Log.Warn("mock", "Mock VR is disabled. Set vrmod_unoff_debug_mock 1 first.")
		return false
	end

	if g_VR.active then
		Log.Warn("mock", "VR is already active. Cannot start mock mode.")
		return false
	end

	local ply = LocalPlayer()
	if not IsValid(ply) then
		Log.Error("mock", "LocalPlayer is not valid.")
		return false
	end

	Log.Info("mock", "Starting Desktop Mock VR Mode...")

	-- g_VR状態構築 (vrmod.lua:507-569 パターン)
	g_VR.tracking = {
		hmd = {
			pos = ply:EyePos(),
			ang = ply:EyeAngles(),
			vel = Vector(),
			angvel = Angle()
		},
		pose_lefthand = {
			pos = ply:GetPos(),
			ang = Angle(),
			vel = Vector(),
			angvel = Angle()
		},
		pose_righthand = {
			pos = ply:GetPos(),
			ang = Angle(),
			vel = Vector(),
			angvel = Angle()
		},
	}

	g_VR.input = BuildDefaultInput()
	g_VR.changedInputs = {}
	g_VR.characterYaw = ply:EyeAngles().yaw
	g_VR.origin = ply:GetPos()
	g_VR.originAngle = g_VR.originAngle or Angle()
	g_VR.scale = 1.0
	g_VR.rightControllerOffsetPos = Vector(0, 0, 0)
	g_VR.leftControllerOffsetPos = Vector(0, 0, 0)
	g_VR.rightControllerOffsetAng = Angle(0, 0, 0)
	g_VR.leftControllerOffsetAng = Angle(0, 0, 0)
	g_VR.viewModelMuzzle = nil
	g_VR.viewModel = nil
	g_VR.viewModelPos = Vector(0, 0, 0)
	g_VR.viewModelAng = Angle(0, 0, 0)
	g_VR.usingWorldModels = false

	-- finger angles (character systemが参照する可能性)
	g_VR.openHandAngles = g_VR.openHandAngles or {}
	g_VR.closedHandAngles = g_VR.closedHandAngles or {}
	g_VR.defaultOpenHandAngles = g_VR.defaultOpenHandAngles or {}
	g_VR.defaultClosedHandAngles = g_VR.defaultClosedHandAngles or {}

	g_VR.active = true
	g_VR.threePoints = true
	g_VR.sixPoints = false
	g_VR.mockMode = true

	-- ネットワーク初期化 (vrmod_network.lua:281-302)
	-- → vrmod_transmitタイマー作成 + vrutil_net_join送信
	-- → サーバー側でIsPlayerInVR()がtrueに
	local ok, err = pcall(VRUtilNetworkInit)
	if not ok then
		Log.Error("mock", "VRUtilNetworkInit failed: " .. tostring(err))
		g_VR.active = false
		g_VR.mockMode = nil
		g_VR.tracking = {}
		return false
	end

	-- 初回トラッキング更新
	UpdateMockTracking()

	-- VRMod_Startフック発火
	hook.Call("VRMod_Start")

	-- Thinkフック追加（メインループ）
	hook.Add("Think", "vrmod_mock_think", MockThink)

	-- キー状態リセット
	prevKeyState = {}

	mock.active = true
	Log.Info("mock", "Mock VR Mode started successfully.")
	Log.Info("mock", "Key mapping: G=right_pickup, H=left_pickup, E=use, R=reload, F=flashlight")
	return true
end

-- ----------------------------------------
-- Mock VR 停止
-- ----------------------------------------
function mock.Stop()
	if not g_VR.mockMode then
		Log.Warn("mock", "Mock VR is not active.")
		return false
	end

	Log.Info("mock", "Stopping Desktop Mock VR Mode...")

	-- リプレイが動いていたら停止
	if vrmod.debug.replay and vrmod.debug.replay.active then
		if vrmod.debug.replay.Stop then
			vrmod.debug.replay.Stop()
		end
	end

	-- Thinkフック削除
	hook.Remove("Think", "vrmod_mock_think")

	-- ネットワーククリーンアップ
	-- → vrmod_transmitタイマー削除 + vrutil_net_exit送信
	-- → サーバーがbroadcast → クライアントがVRMod_Exit発火
	local ok, err = pcall(VRUtilNetworkCleanup)
	if not ok then
		Log.Error("mock", "VRUtilNetworkCleanup failed: " .. tostring(err))
	end

	-- g_VR状態リセット
	g_VR.tracking = {}
	g_VR.threePoints = false
	g_VR.sixPoints = false
	g_VR.active = false
	g_VR.mockMode = nil

	-- キー状態リセット
	prevKeyState = {}

	mock.active = false
	Log.Info("mock", "Mock VR Mode stopped.")
	return true
end

-- ----------------------------------------
-- ステータス表示
-- ----------------------------------------
function mock.Status()
	MsgC(Color(100, 200, 255), "[VRMod Mock] ")
	if g_VR.mockMode then
		MsgC(Color(100, 255, 100), "ACTIVE\n")
		MsgC(Color(200, 200, 200), "  g_VR.active: ", tostring(g_VR.active), "\n")
		MsgC(Color(200, 200, 200), "  g_VR.threePoints: ", tostring(g_VR.threePoints), "\n")
		MsgC(Color(200, 200, 200), "  IsPlayerInVR: ", tostring(vrmod.IsPlayerInVR(LocalPlayer())), "\n")
		if g_VR.tracking and g_VR.tracking.hmd then
			MsgC(Color(200, 200, 200), "  HMD pos: ", tostring(g_VR.tracking.hmd.pos), "\n")
		end
		if g_VR.tracking and g_VR.tracking.pose_righthand then
			MsgC(Color(200, 200, 200), "  Right hand: ", tostring(g_VR.tracking.pose_righthand.pos), "\n")
		end
		if g_VR.tracking and g_VR.tracking.pose_lefthand then
			MsgC(Color(200, 200, 200), "  Left hand: ", tostring(g_VR.tracking.pose_lefthand.pos), "\n")
		end

		-- リプレイ状態
		if vrmod.debug.replay and vrmod.debug.replay.active then
			MsgC(Color(255, 200, 100), "  Replay: ACTIVE")
			MsgC(Color(200, 200, 200), " [", string.format("%.1f", vrmod.debug.replay.cursor or 0), "/",
				string.format("%.1f", vrmod.debug.replay.duration or 0), "s]")
			if vrmod.debug.replay.paused then
				MsgC(Color(255, 255, 100), " (PAUSED)")
			end
			MsgC(Color(200, 200, 200), " speed=", tostring(vrmod.debug.replay.speed or 1), "x\n")
		end
	else
		MsgC(Color(255, 100, 100), "INACTIVE\n")
		MsgC(Color(200, 200, 200), "  ConVar vrmod_unoff_debug_mock: ", cv_enabled:GetString(), "\n")
	end
end

-- ----------------------------------------
-- コンソールコマンド
-- ----------------------------------------
concommand.Add("vrmod_unoff_mock_start", function()
	mock.Start()
end)

concommand.Add("vrmod_unoff_mock_stop", function()
	mock.Stop()
end)

concommand.Add("vrmod_unoff_mock_status", function()
	mock.Status()
end)

Log.Info("mock", "Desktop Mock VR system loaded. Commands: vrmod_unoff_mock_start/stop/status")
--------[vrmod_debug_mock.lua]End--------
