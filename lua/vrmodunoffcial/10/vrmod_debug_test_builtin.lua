--------[vrmod_debug_test_builtin.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if not vrmod.debug.test then return end
if SERVER then return end

-- ========================================
-- 組み込みテストスイート
-- Level 1: 静的チェック（VRセッション不要）
-- Level 2: ライフサイクルテスト（Mock VR使用）
-- ========================================

local test = vrmod.debug.test
local Log = vrmod.debug.Log

-- ========================================
-- Level 1: Static Tests
-- ========================================

-- --- 1-1: g_VRテーブル初期化 ---
test.Register("static_g_vr_table", {
	name = "g_VR global table initialized",
	category = "static",
	module = "core",
	run = function(ctx, done)
		ctx.assert.isType(g_VR, "table", "g_VR exists and is table")
		ctx.assert.isType(g_VR.net, "table", "g_VR.net initialized")
		ctx.assert.isType(g_VR.menuItems, "table", "g_VR.menuItems initialized")
		ctx.assert.isType(g_VR.locomotionOptions, "table", "g_VR.locomotionOptions initialized")
		ctx.assert.isType(g_VR.viewModelInfo, "table", "g_VR.viewModelInfo initialized")
		done()
	end,
})

-- --- 1-2: コアAPI関数存在 ---
test.Register("static_core_api", {
	name = "Core API functions exist",
	category = "static",
	module = "core",
	run = function(ctx, done)
		ctx.assert.isType(vrmod, "table", "vrmod table exists")
		ctx.assert.isType(vrmod.GetVersion, "function", "vrmod.GetVersion")
		ctx.assert.isType(vrmod.GetConvars, "function", "vrmod.GetConvars")
		ctx.assert.isType(vrmod.GetModuleVersion, "function", "vrmod.GetModuleVersion")
		ctx.assert.isType(vrmod.IsPlayerInVR, "function", "vrmod.IsPlayerInVR")
		ctx.assert.isType(vrmod.GetStartupError, "function", "vrmod.GetStartupError")
		ctx.assert.isType(vrmod.AddCallbackedConvar, "function", "vrmod.AddCallbackedConvar")
		ctx.assert.isType(vrmod.GetInput, "function", "vrmod.GetInput")
		ctx.assert.isType(vrmod.GetHMDPos, "function", "vrmod.GetHMDPos")
		ctx.assert.isType(vrmod.GetHMDAng, "function", "vrmod.GetHMDAng")
		ctx.assert.isType(vrmod.GetLeftHandPos, "function", "vrmod.GetLeftHandPos")
		ctx.assert.isType(vrmod.GetRightHandPos, "function", "vrmod.GetRightHandPos")
		ctx.assert.isType(vrmod.SetOrigin, "function", "vrmod.SetOrigin")
		ctx.assert.isType(vrmod.AddLocomotionOption, "function", "vrmod.AddLocomotionOption")
		ctx.assert.isType(vrmod.AddInGameMenuItem, "function", "vrmod.AddInGameMenuItem")
		done()
	end,
})

-- --- 1-3: API戻り値チェック ---
test.Register("static_api_return_values", {
	name = "Core API return values valid",
	category = "static",
	module = "core",
	depends = {"static_core_api"},
	run = function(ctx, done)
		local version = vrmod.GetVersion()
		ctx.assert.isType(version, "number", "GetVersion returns number")
		ctx.assert.greaterThan(version, 0, "Version > 0")

		local convars, convarValues = vrmod.GetConvars()
		ctx.assert.isType(convars, "table", "GetConvars returns convars table")
		ctx.assert.isType(convarValues, "table", "GetConvars returns convarValues table")

		local current, required, latest = vrmod.GetModuleVersion()
		ctx.assert.isType(required, "number", "GetModuleVersion required is number")
		ctx.assert.isType(latest, "number", "GetModuleVersion latest is number")

		done()
	end,
})

-- --- 1-4: コアConVar存在 ---
test.Register("static_core_convars", {
	name = "Core ConVars created",
	category = "static",
	module = "core",
	run = function(ctx, done)
		ctx.assert.convarExists("vrmod_error_hard", "vrmod_error_hard")
		ctx.assert.convarExists("vrmod_locomotion", "vrmod_locomotion")
		-- デバッグ系
		ctx.assert.convarExists("vrmod_unoff_debug", "vrmod_unoff_debug")
		ctx.assert.convarExists("vrmod_unoff_debug_hooks", "vrmod_unoff_debug_hooks")
		ctx.assert.convarExists("vrmod_unoff_debug_mock", "vrmod_unoff_debug_mock")
		ctx.assert.convarExists("vrmod_unoff_debug_loglevel", "vrmod_unoff_debug_loglevel")
		done()
	end,
})

-- --- 1-5: デバッグシステムAPI ---
test.Register("static_debug_api", {
	name = "Debug system APIs available",
	category = "static",
	module = "debug",
	run = function(ctx, done)
		ctx.assert.isTrue(vrmod.debug.enabled, "debug.enabled is true")
		ctx.assert.isType(vrmod.debug.GetErrors, "function", "GetErrors")
		ctx.assert.isType(vrmod.debug.ClearErrors, "function", "ClearErrors")
		ctx.assert.isType(vrmod.debug.IsHooksEnabled, "function", "IsHooksEnabled")
		ctx.assert.isType(vrmod.debug.hooks, "table", "debug.hooks table")
		ctx.assert.isType(vrmod.debug.BuildHookInventory, "function", "BuildHookInventory")
		-- Mock VR
		ctx.assert.isType(vrmod.debug.mock, "table", "debug.mock table")
		ctx.assert.isType(vrmod.debug.mock.Start, "function", "mock.Start")
		ctx.assert.isType(vrmod.debug.mock.Stop, "function", "mock.Stop")
		done()
	end,
})

-- --- 1-6: VRMod_Startフックにコールバック登録あり ---
test.Register("static_hooks_registered", {
	name = "VRMod hooks have callbacks",
	category = "static",
	module = "core",
	run = function(ctx, done)
		local hookTable = hook.GetTable()

		-- VRMod_Start: 各モジュールの初期化が登録されているはず
		local startCallbacks = hookTable["VRMod_Start"]
		ctx.assert.isNotNil(startCallbacks, "VRMod_Start has callbacks")
		if startCallbacks then
			ctx.assert.greaterThan(table.Count(startCallbacks), 0, "VRMod_Start callback count > 0")
		end

		-- VRMod_Exit: クリーンアップ
		local exitCallbacks = hookTable["VRMod_Exit"]
		ctx.assert.isNotNil(exitCallbacks, "VRMod_Exit has callbacks")
		if exitCallbacks then
			ctx.assert.greaterThan(table.Count(exitCallbacks), 0, "VRMod_Exit callback count > 0")
		end

		-- VRMod_Menu: メニュータブ登録
		local menuCallbacks = hookTable["VRMod_Menu"]
		ctx.assert.isNotNil(menuCallbacks, "VRMod_Menu has callbacks")

		done()
	end,
})

-- --- 1-7: VR非アクティブ状態 ---
test.Register("static_vr_inactive", {
	name = "VR is not active at rest",
	category = "static",
	module = "core",
	run = function(ctx, done)
		ctx.assert.isFalse(g_VR.active, "g_VR.active is false")
		ctx.assert.isNil(g_VR.mockMode, "g_VR.mockMode is nil")
		done()
	end,
})

-- --- 1-8: エラーバッファ正常動作 ---
test.Register("static_error_buffer", {
	name = "Error buffer operations work",
	category = "static",
	module = "debug",
	run = function(ctx, done)
		local countBefore = #vrmod.debug.GetErrors()
		-- テスト用エラーを追加
		vrmod.debug.AddError("test_builtin", "test error for validation")
		local countAfter = #vrmod.debug.GetErrors()
		ctx.assert.equal(countBefore + 1, countAfter, "AddError increments error count")

		-- 最新エラーの内容確認
		local errors = vrmod.debug.GetErrors()
		local latest = errors[#errors]
		ctx.assert.isNotNil(latest, "Latest error exists")
		if latest then
			ctx.assert.equal("test_builtin", latest.source, "Error source matches")
			ctx.assert.equal("test error for validation", latest.message, "Error message matches")
		end

		done()
	end,
})

-- --- 1-9: 個別モジュール存在チェック（動的生成） ---
-- addons/vrmod_*フォルダの存在をもとに、各モジュールのinitファイルがロードされたか確認
test.Register("static_modules_loaded", {
	name = "Individual modules loaded (hook presence)",
	category = "static",
	module = "core",
	run = function(ctx, done)
		-- 各モジュールが何らかのVRMod hookに登録されているか確認
		-- （正確なコールバック名は不定だが、hook.GetTable()の中にvrmod関連の名前があるはず）
		local hookTable = hook.GetTable()
		local totalCallbacks = 0

		for hookName, callbacks in pairs(hookTable) do
			-- VRMod系hookのコールバック数をカウント
			if string.StartWith(hookName, "VRMod_") then
				for cbName, _ in pairs(callbacks) do
					totalCallbacks = totalCallbacks + 1
				end
			end
		end

		-- 最低限のVRMod hookコールバック数（コア+数モジュール）
		ctx.assert.greaterThan(totalCallbacks, 5, "VRMod hooks have > 5 total callbacks (" .. totalCallbacks .. " found)")
		done()
	end,
})

-- --- 1-10: hookラップ正常動作 ---
test.Register("static_hook_wrapping", {
	name = "hook.Call/Run wrapping active",
	category = "static",
	module = "debug",
	run = function(ctx, done)
		ctx.assert.isTrue(vrmod.debug.IsHooksEnabled(), "Hook monitoring enabled")
		-- hook.Callがオリジナルと異なること（ラップ済み）
		ctx.assert.isNotNil(vrmod._origHookCall, "Original hook.Call preserved")
		ctx.assert.isNotNil(vrmod._origHookRun, "Original hook.Run preserved")
		ctx.assert.notEqual(hook.Call, vrmod._origHookCall, "hook.Call is wrapped")
		done()
	end,
})

-- ========================================
-- Level 2: Lifecycle Tests
-- ========================================

-- --- 2-1: Mock VR 起動/停止サイクル ---
test.Register("lifecycle_mock_start_stop", {
	name = "Mock VR start/stop lifecycle",
	category = "lifecycle",
	module = "core",
	timeout = 10,
	setup = function(ctx)
		ctx._errorCountAtStart = #vrmod.debug.GetErrors()
	end,
	run = function(ctx, done)
		local ok = ctx.mockVR.start()
		ctx.assert.isTrue(ok, "mock.Start() returns true")
		if not ok then done() return end

		-- 数フレーム待って状態確認
		ctx.mockVR.waitFrames(3, function()
			ctx.assert.isTrue(g_VR.active, "g_VR.active is true")
			ctx.assert.isTrue(g_VR.mockMode, "g_VR.mockMode is true")
			ctx.assert.isNotNil(g_VR.tracking, "g_VR.tracking exists")
			ctx.assert.isNotNil(g_VR.tracking.hmd, "g_VR.tracking.hmd exists")
			ctx.assert.isNotNil(g_VR.tracking.pose_lefthand, "left hand tracking exists")
			ctx.assert.isNotNil(g_VR.tracking.pose_righthand, "right hand tracking exists")
			ctx.assert.hookFired("VRMod_Start", "VRMod_Start fired")
			ctx.assert.hookFired("VRMod_Tracking", "VRMod_Tracking firing")
			ctx.assert.noErrors("No errors during mock start")

			-- 停止
			ctx.mockVR.stop()

			-- hookmon stale検出が0.5s遅延するのでそれ以上待つ
			timer.Simple(1.5, function()
				ctx.assert.isFalse(g_VR.active, "g_VR.active false after stop")
				ctx.assert.isNil(g_VR.mockMode, "g_VR.mockMode nil after stop")
				ctx.assert.noStaleHooks("No stale hooks after exit")
				ctx.assert.noErrors("No errors during mock stop")
				done()
			end)
		end)
	end,
	teardown = function(ctx)
		if g_VR.mockMode then pcall(vrmod.debug.mock.Stop) end
	end,
})

-- --- 2-2: VRMod_Trackingが継続発火 ---
test.Register("lifecycle_tracking_continuous", {
	name = "VRMod_Tracking fires continuously",
	category = "lifecycle",
	module = "core",
	timeout = 8,
	depends = {"lifecycle_mock_start_stop"},
	run = function(ctx, done)
		ctx.mockVR.start()

		-- 2秒後にトラッキング発火回数を確認
		timer.Simple(2, function()
			-- 2秒あればThinkフックから60+回発火しているはず
			ctx.assert.hookFireCount("VRMod_Tracking", 30, "VRMod_Tracking fired >= 30 times in 2s")
			ctx.assert.hookFired("VRMod_PreRender", "VRMod_PreRender also firing")
			ctx.assert.noErrors("No errors during tracking")

			ctx.mockVR.stop()
			timer.Simple(1, function() done() end)
		end)
	end,
	teardown = function(ctx)
		if g_VR.mockMode then pcall(vrmod.debug.mock.Stop) end
	end,
})

-- --- 2-3: 5秒間エラーフリーセッション ---
test.Register("lifecycle_error_free_session", {
	name = "5s mock VR session error-free",
	category = "lifecycle",
	module = "core",
	timeout = 12,
	depends = {"lifecycle_mock_start_stop"},
	setup = function(ctx)
		vrmod.debug.ClearErrors()
	end,
	run = function(ctx, done)
		-- エラーバッファクリア後のカウントをリセット
		ctx._errorCountAtStart = 0

		ctx.mockVR.start()

		timer.Simple(5, function()
			ctx.assert.noErrors("No errors after 5s mock VR")
			ctx.assert.isTrue(g_VR.active, "VR still active after 5s")

			ctx.mockVR.stop()
			timer.Simple(1.5, function()
				ctx.assert.noStaleHooks("Clean exit after session")
				ctx.assert.noErrors("No errors during cleanup")
				done()
			end)
		end)
	end,
	teardown = function(ctx)
		if g_VR.mockMode then pcall(vrmod.debug.mock.Stop) end
	end,
})

Log.Info("test", "Built-in test suite registered: " .. table.Count(test.suites) .. " tests")

--------[vrmod_debug_test_builtin.lua]End--------
