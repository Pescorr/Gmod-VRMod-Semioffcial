--------[vrmod_fps_guard.lua]Start--------
-- VR FPS Guard v2.0: フォーカス保護 + コンポジターブロック検知
--
-- 2層のFPS崩壊防止:
--   Layer 1: system.HasFocus() チェック — フォーカスロス時にVR描画を完全スキップ
--   Layer 2: WaitGetPoses() タイミング検知 — コンポジターブロック時にスキップ＆リトライ
--
-- 統一ConVar: vrmod_unoff_fps_guard (0=無効, 1=有効)
if SERVER then return end

local GUARD_VERSION = "2.0"

-- === ConVars ===
local cvar_enable = CreateClientConVar("vrmod_unoff_fps_guard", "1", true, FCVAR_ARCHIVE,
	"VR FPS protection (focus check + compositor block detection) 0=off 1=on", 0, 1)
local cvar_threshold = CreateClientConVar("vrmod_unoff_fps_guard_threshold_ms", "40", true, FCVAR_ARCHIVE,
	"Block detection threshold in ms", 10, 200)
local cvar_retry = CreateClientConVar("vrmod_unoff_fps_guard_retry", "2", true, FCVAR_ARCHIVE,
	"Retry interval in seconds while blocked", 0.5, 10)

-- === State ===
local origUpdate = nil
local origSubmit = nil
local isBlocked = false
local lastRetryTime = 0
local blockDetectCount = 0

-- === Layer 2: Timing-based guard (wraps global C++ bridge functions) ===
local function ApplyGuard()
	if not VRMOD_UpdatePosesAndActions then return false end
	if type(VRMOD_UpdatePosesAndActions) ~= "function" then return false end
	-- 二重ラップ防止
	if VRMOD_UpdatePosesAndActions_Original then return false end

	origUpdate = VRMOD_UpdatePosesAndActions
	origSubmit = VRMOD_SubmitSharedTexture

	-- オリジナル関数をグローバルに保存（デバッグ・手動復帰用）
	VRMOD_UpdatePosesAndActions_Original = origUpdate
	if origSubmit and type(origSubmit) == "function" then
		VRMOD_SubmitSharedTexture_Original = origSubmit
	end

	-- UpdatePosesAndActions ラッパー
	VRMOD_UpdatePosesAndActions = function()
		if not cvar_enable:GetBool() then
			return origUpdate()
		end

		-- ブロック中: リトライ間隔まではスキップ
		if isBlocked then
			local retryInterval = cvar_retry:GetFloat()
			if SysTime() - lastRetryTime < retryInterval then
				return
			end
			lastRetryTime = SysTime()
		end

		-- 計測付き呼び出し
		local t0 = SysTime()
		origUpdate()
		local elapsedMs = (SysTime() - t0) * 1000

		local threshold = cvar_threshold:GetFloat()
		if elapsedMs > threshold then
			if not isBlocked then
				blockDetectCount = blockDetectCount + 1
				print("[VRMod FPS Guard] Compositor block detected ("
					.. string.format("%.0fms", elapsedMs)
					.. "). Guard mode ON. (#" .. blockDetectCount .. ")")
			end
			isBlocked = true
			lastRetryTime = SysTime()
		else
			if isBlocked then
				print("[VRMod FPS Guard] Compositor recovered ("
					.. string.format("%.1fms", elapsedMs)
					.. "). Resuming normal operation.")
			end
			isBlocked = false
		end
	end

	-- SubmitSharedTexture ラッパー（ブロック中はSubmitもスキップ）
	if origSubmit and type(origSubmit) == "function" then
		VRMOD_SubmitSharedTexture = function()
			if cvar_enable:GetBool() and isBlocked then
				return
			end
			return origSubmit()
		end
	end

	return true
end

-- === Layer 1: Focus check (RenderScene hook) ===
-- ASCIIソート順: "vrmod_unoff_fps_guard_focus" < "vrutil_hook_renderscene"
-- → メインRenderSceneフックより先に実行され、return trueで後続を全スキップ
hook.Add("VRMod_Start", "vrmod_unoff_fps_guard_start", function()
	-- 旧windowfocusフックが残っていれば除去（v1.0→v2.0移行用）
	hook.Remove("RenderScene", "vrmod_unoff_windowfocus")

	hook.Add("RenderScene", "vrmod_unoff_fps_guard_focus", function()
		if not cvar_enable:GetBool() then return end
		if not system.HasFocus() then
			render.Clear(0, 0, 0, 255, true, true)
			cam.Start2D()
			draw.DrawText("Please focus the game window", "DermaLarge",
				ScrW() / 2, ScrH() / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
			cam.End2D()
			return true
		end
	end)
end)

hook.Add("VRMod_Exit", "vrmod_unoff_fps_guard_exit", function()
	hook.Remove("RenderScene", "vrmod_unoff_fps_guard_focus")
	isBlocked = false
end)

-- === Public API ===
vrmod = vrmod or {}
vrmod.FPSGuard = vrmod.FPSGuard or {}

function vrmod.FPSGuard.IsBlocked() return isBlocked end
function vrmod.FPSGuard.GetBlockCount() return blockDetectCount end
function vrmod.FPSGuard.GetVersion() return GUARD_VERSION end

-- === Initialize ===
timer.Simple(0, function()
	if ApplyGuard() then
		print("[VRMod FPS Guard] v" .. GUARD_VERSION .. " initialized")
	else
		-- モジュール遅延読み込み対応: 1秒後にリトライ
		timer.Simple(1, function()
			if ApplyGuard() then
				print("[VRMod FPS Guard] v" .. GUARD_VERSION .. " initialized (delayed)")
			end
		end)
	end
end)
--------[vrmod_fps_guard.lua]End--------
