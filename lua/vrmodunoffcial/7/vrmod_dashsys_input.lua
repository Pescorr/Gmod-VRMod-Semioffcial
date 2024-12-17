-- vrmod_dash.lua
if SERVER then return end -- クライアントサイドのみで実行
-- 設定値
local DASH_THRESHOLD = 50 -- ダッシュを検知する速度のしきい値
local CROUCH_THRESHOLD = 40 -- しゃがみを検知する高さのしきい値 
local DASH_COOLDOWN = 0.5 -- ダッシュのクールダウン時間(秒)
-- ローカル変数
local lastCrouchTime = 0
local lastDashTime = 0
local isCrouched = false
local previousHMDPos = Vector(0, 0, 0)
local crouchStartPos = Vector(0, 0, 0)
-- ConVarの作成
local cv_enabled = CreateClientConVar("vrmod_dash_enabled", "1", true, false, "Enable VR dash movement")
local cv_debug = CreateClientConVar("vrmod_dash_debug", "0", true, false, "Show debug info for VR dash")
-- デバッグ表示用関数
local function DebugPrint(text)
    if cv_debug:GetBool() then
        print("[VRDash] " .. text)
    end
end

-- しゃがみ状態を検出する関数
local function CheckCrouch()
    if not g_VR.active then return end
    local currentHMDHeight = g_VR.tracking.hmd.pos.z - g_VR.origin.z
    local wasCrouched = isCrouched
    isCrouched = currentHMDHeight < CROUCH_THRESHOLD
    -- しゃがみ開始時の処理
    if isCrouched and not wasCrouched then
        crouchStartPos = g_VR.tracking.hmd.pos
        lastCrouchTime = CurTime()
        RunConsoleCommand("vrmod_vrdash_crouch")
        DebugPrint("Crouch detected")
    end
end

-- ダッシュ方向を検出する関数
local function CheckDash()
    if not g_VR.active or not isCrouched then return end
    if CurTime() - lastDashTime < DASH_COOLDOWN then return end
    local currentPos = g_VR.tracking.hmd.pos
    local moveVec = currentPos - crouchStartPos
    local moveSpeed = moveVec:Length()
    -- 動きが閾値を超えた場合にダッシュ判定
    if moveSpeed > DASH_THRESHOLD then
        local forward = math.abs(moveVec.x)
        local side = math.abs(moveVec.y)
        lastDashTime = CurTime()
        -- 移動方向に応じてコマンド実行
        if forward > side then
            if moveVec.x > 0 then
                RunConsoleCommand("vrmod_vrdash_forword")
                DebugPrint("Forward dash")
            else
                RunConsoleCommand("vrmod_vrdash_back")
                DebugPrint("Back dash")
            end
        else
            if moveVec.y > 0 then
                RunConsoleCommand("vrmod_vrdash_right")
                DebugPrint("Right dash")
            else
                RunConsoleCommand("vrmod_vrdash_left")
                DebugPrint("Left dash")
            end
        end
    end

    previousHMDPos = currentPos
end

-- メインの更新処理
hook.Add(
    "Think",
    "VRDash_Think",
    function()
        if not cv_enabled:GetBool() then return end
        CheckCrouch()
        CheckDash()
    end
)

-- デバッグ表示
if cv_debug:GetBool() then
    hook.Add(
        "HUDPaint",
        "VRDash_DebugHUD",
        function()
            if not g_VR.active then return end
            local text = string.format("VR Dash Debug\nCrouched: %s\nLast Crouch: %.2f\nLast Dash: %.2f", tostring(isCrouched), CurTime() - lastCrouchTime, CurTime() - lastDashTime)
            draw.SimpleText(text, "Default", 10, 10, Color(255, 255, 255, 255))
        end
    )
end

-- ConCommand Helper
concommand.Add(
    "vrmod_dash_reset",
    function()
        lastCrouchTime = 0
        lastDashTime = 0
        isCrouched = false
        previousHMDPos = Vector(0, 0, 0)
        crouchStartPos = Vector(0, 0, 0)
        DebugPrint("VR Dash state reset")
    end
)