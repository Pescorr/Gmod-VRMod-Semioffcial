-- vrmod_adaptive_fps.lua
-- Adaptive FPS Optimization System for VRMod
-- FPSに応じて品質設定を自動調整し、VR酔いを防止する
--
-- 二段構え:
--   1) 離散ティア(0-6): 影・ディテール・スペキュラ・水面・LOD・テクスチャを段階的に調整
--   2) r_farz連続補間: 描画距離をFPS比率でシームレスに補間
--
-- 既存システムとの共存:
--   - vrmod_add_optimize.lua (Lv1-4) が管理するConVarとは復元責任を分離
--   - vrmod_fps_guard.lua の VRMod_PerformancePressure フックを消費して緊急対応

if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

-- ============================================================
-- ConVars
-- ============================================================
local cv_enabled       = CreateClientConVar("vrmod_adaptive_enabled",       "0",    true, FCVAR_ARCHIVE, "Enable adaptive FPS optimization", 0, 1)
local cv_target_fps    = CreateClientConVar("vrmod_adaptive_target_fps",    "90",   true, FCVAR_ARCHIVE, "Target FPS to maintain", 30, 144)
local cv_floor         = CreateClientConVar("vrmod_adaptive_floor",         "0",    true, FCVAR_ARCHIVE, "Minimum quality tier (0=best)", 0, 6)
local cv_ceiling       = CreateClientConVar("vrmod_adaptive_ceiling",       "6",    true, FCVAR_ARCHIVE, "Maximum quality tier (6=worst)", 0, 6)
local cv_degrade_time  = CreateClientConVar("vrmod_adaptive_degrade_time",  "1.5",  true, FCVAR_ARCHIVE, "Seconds below target before degrading", 0.5, 5.0)
local cv_recover_time  = CreateClientConVar("vrmod_adaptive_recover_time",  "7.0",  true, FCVAR_ARCHIVE, "Seconds above target before recovering", 3.0, 15.0)
local cv_farz_min      = CreateClientConVar("vrmod_adaptive_farz_min",      "1500", true, FCVAR_ARCHIVE, "Minimum r_farz value", 500, 10000)
local cv_hud_indicator = CreateClientConVar("vrmod_adaptive_hud_indicator", "1",    true, FCVAR_ARCHIVE, "Show quality level indicator in VR HUD", 0, 1)
local cv_debug         = CreateClientConVar("vrmod_adaptive_debug",         "0",    true, FCVAR_ARCHIVE, "Print state transitions to console", 0, 1)

-- ============================================================
-- Quality Tier Definitions (視覚的影響が小さい順)
-- 各ティアは累積的: 上位ティアの設定を全て含む
-- ============================================================
-- 危険ConVar (ランタイム変更でフリーズを引き起こす — 絶対に使わない):
--   mat_specular     — マテリアル全リロード (vrmod_add_optimize.luaで既知)
--   mat_picmip       — 全テクスチャ再読込でフリーズ (Minimum落ち時に余計な負荷)
--   r_rootlod        — 全モデルのルートLOD再計算でヒッチ
--   mat_fastspecular  — シェーダー状態変更でヒッチ
local QUALITY_TIERS = {
    [0] = { -- Ultra: 全デフォルト
        name = "Ultra",
        convars = {},
    },
    [1] = { -- High: 影を削減
        name = "High",
        convars = {
            { "r_shadowmaxrendered", "8" },
            { "r_flashlightdepthres", "256" },
        },
    },
    [2] = { -- Med-High: +ディテール削減、描画距離縮小
        name = "Med-High",
        convars = {
            { "r_shadowmaxrendered", "4" },
            { "r_flashlightdepthres", "128" },
            { "r_drawdetailprops", "1" },
            { "cl_detaildist", "600" },
        },
    },
    [3] = { -- Medium: +3Dスカイボックス無効、水面反射無効
        name = "Medium",
        convars = {
            { "r_shadowmaxrendered", "2" },
            { "r_flashlightdepthres", "64" },
            { "r_drawdetailprops", "0" },
            { "cl_detaildist", "300" },
            { "r_3dsky", "0" },
            { "r_WaterDrawReflection", "0" },
            { "r_WaterDrawRefraction", "0" },
        },
    },
    [4] = { -- Med-Low: +影完全無効、動的ライト無効、デカール無効
        name = "Med-Low",
        convars = {
            { "r_shadowmaxrendered", "1" },
            { "r_flashlightdepthres", "1" },
            { "r_drawdetailprops", "0" },
            { "cl_detaildist", "100" },
            { "r_3dsky", "0" },
            { "r_WaterDrawReflection", "0" },
            { "r_WaterDrawRefraction", "0" },
            { "r_shadows", "0" },
            { "r_dynamic", "0" },
            { "r_decals", "0" },
        },
    },
    [5] = { -- Low: +LOD強制、ロープ・スプレー無効
        name = "Low",
        convars = {
            { "r_shadowmaxrendered", "1" },
            { "r_flashlightdepthres", "1" },
            { "r_drawdetailprops", "0" },
            { "cl_detaildist", "50" },
            { "r_3dsky", "0" },
            { "r_WaterDrawReflection", "0" },
            { "r_WaterDrawRefraction", "0" },
            { "r_shadows", "0" },
            { "r_dynamic", "0" },
            { "r_decals", "0" },
            { "r_lod", "4" },
            { "r_ropetranslucent", "0" },
            { "r_spray_lifetime", "0" },
        },
    },
    [6] = { -- Minimum: +水面品質最低、物理デブリ削減
        name = "Minimum",
        convars = {
            { "r_shadowmaxrendered", "1" },
            { "r_flashlightdepthres", "1" },
            { "r_drawdetailprops", "0" },
            { "cl_detaildist", "50" },
            { "r_3dsky", "0" },
            { "r_WaterDrawReflection", "0" },
            { "r_WaterDrawRefraction", "0" },
            { "r_shadows", "0" },
            { "r_dynamic", "0" },
            { "r_decals", "0" },
            { "r_lod", "6" },
            { "r_ropetranslucent", "0" },
            { "r_spray_lifetime", "0" },
            { "r_waterforceexpensive", "0" },
            { "r_waterforcereflectentities", "0" },
            { "props_break_max_pieces", "0" },
        },
    },
}

-- adaptive専用ConVar (optimizeシステムと重複しない → adaptiveが復元を担当)
-- optimizeシステムが管理するConVar (復元はoptimize側に任せる):
--   r_3dsky, r_shadows, r_farz, r_WaterDrawReflection, r_WaterDrawRefraction,
--   r_waterforceexpensive, r_waterforcereflectentities
local ADAPTIVE_ONLY_CVARS = {
    ["r_shadowmaxrendered"] = true,
    ["r_flashlightdepthres"] = true,
    ["r_drawdetailprops"] = true,
    ["cl_detaildist"] = true,
    ["r_dynamic"] = true,
    ["r_decals"] = true,
    ["r_lod"] = true,
    ["r_ropetranslucent"] = true,
    ["r_spray_lifetime"] = true,
    ["props_break_max_pieces"] = true,
}

-- 全ティアで使用されるConVar名のセット（復元判定用）
local ALL_TIER_CVARS = {}
for tier = 0, 6 do
    for _, entry in ipairs(QUALITY_TIERS[tier].convars) do
        ALL_TIER_CVARS[entry[1]] = true
    end
end

-- ============================================================
-- Runtime State
-- ============================================================
local state = {
    active = false,
    currentTier = 0,
    fpsEMA = 0,
    emaSamples = 0,
    degradeTimer = 0,
    recoverTimer = 0,
    lastThinkTime = 0,
    lastTierChangeTime = 0,
    savedConVars = {},       -- adaptive専用ConVarのベースライン値
    farzBaseline = 0,        -- r_farz のベースライン値
    lastFarzValue = -1,      -- r_farz の前回設定値（重複RunConsoleCommand防止）
}

-- ============================================================
-- Baseline Snapshot / Restore
-- ============================================================
local function SnapshotBaseline()
    state.savedConVars = {}
    for name in pairs(ADAPTIVE_ONLY_CVARS) do
        local cv = GetConVar(name)
        if cv then
            state.savedConVars[name] = cv:GetString()
        end
    end

    -- r_farz ベースライン (0 = 無制限 → フォールバック 30000)
    local farzCV = GetConVar("r_farz")
    local farzVal = farzCV and farzCV:GetFloat() or 0
    state.farzBaseline = (farzVal > 0) and farzVal or 30000

    if cv_debug:GetBool() then
        print("[VRMod Adaptive] Baseline snapshot: " .. table.Count(state.savedConVars) .. " ConVars, r_farz baseline=" .. state.farzBaseline)
    end
end

local function RestoreBaseline()
    for name, value in pairs(state.savedConVars) do
        if GetConVar(name) then
            RunConsoleCommand(name, value)
        end
    end
    -- r_farz はoptimizeシステムが復元するので、ここでは触らない

    if cv_debug:GetBool() then
        print("[VRMod Adaptive] Baseline restored: " .. table.Count(state.savedConVars) .. " ConVars")
    end
end

-- ============================================================
-- Tier Application
-- ============================================================
local function ApplyTier(newTier)
    local oldTier = state.currentTier
    local tierDef = QUALITY_TIERS[newTier]
    if not tierDef then return end

    -- 旧ティアにあって新ティアにないConVarをベースラインに戻す
    local newConVarSet = {}
    for _, entry in ipairs(tierDef.convars) do
        newConVarSet[entry[1]] = true
    end

    if QUALITY_TIERS[oldTier] then
        for _, entry in ipairs(QUALITY_TIERS[oldTier].convars) do
            local name = entry[1]
            if not newConVarSet[name] and ADAPTIVE_ONLY_CVARS[name] and state.savedConVars[name] then
                RunConsoleCommand(name, state.savedConVars[name])
            end
        end
    end

    -- 新ティアのConVarを適用
    for _, entry in ipairs(tierDef.convars) do
        RunConsoleCommand(entry[1], entry[2])
    end

    state.currentTier = newTier
    state.lastTierChangeTime = SysTime()

    if cv_debug:GetBool() then
        print(string.format("[VRMod Adaptive] Tier %d (%s) -> %d (%s) | FPS EMA: %.1f",
            oldTier, QUALITY_TIERS[oldTier] and QUALITY_TIERS[oldTier].name or "?",
            newTier, tierDef.name, state.fpsEMA))
    end
end

-- ============================================================
-- r_farz Continuous Interpolation
-- ============================================================
local function UpdateFarZ(targetFPS)
    local farzMin = cv_farz_min:GetFloat()
    local farzMax = state.farzBaseline

    if farzMax <= farzMin then return end

    -- ratio: 0 = worst (farz_min), 1 = best (baseline)
    -- FPS <= target*0.8 → 0, FPS >= target*1.2 → 1
    local lowThreshold = targetFPS * 0.8
    local highThreshold = targetFPS * 1.2
    local range = highThreshold - lowThreshold
    local ratio = (range > 0) and math.Clamp((state.fpsEMA - lowThreshold) / range, 0, 1) or 1

    local farz = math.floor(farzMin + (farzMax - farzMin) * ratio)

    -- 前回値と同じならRunConsoleCommandをスキップ
    if farz ~= state.lastFarzValue then
        RunConsoleCommand("r_farz", tostring(farz))
        state.lastFarzValue = farz
    end
end

-- ============================================================
-- Main Adaptation Loop (Think hook)
-- ============================================================
local function AdaptiveThink()
    if not cv_enabled:GetBool() then return end
    if not state.active then return end
    if not g_VR or not g_VR.active then return end

    local now = SysTime()
    local dt = now - state.lastThinkTime
    state.lastThinkTime = now

    -- 異常フレームをスキップ（ロード画面、初回フレーム等）
    local ft = FrameTime()
    if ft <= 0 or ft > 1.0 then return end

    local currentFPS = 1.0 / ft

    -- EMA計算 (起動時はalpha高めで速く収束)
    local alpha = (state.emaSamples < 30) and 0.3 or 0.1
    state.fpsEMA = alpha * currentFPS + (1 - alpha) * state.fpsEMA
    state.emaSamples = state.emaSamples + 1

    -- EMA安定待ち (最低10サンプル)
    if state.emaSamples < 10 then return end

    local targetFPS = cv_target_fps:GetInt()

    -- r_farz 連続補間 (毎フレーム)
    UpdateFarZ(targetFPS)

    -- ティア変更クールダウン (0.5秒)
    if now - state.lastTierChangeTime < 0.5 then return end

    local floor = math.Clamp(cv_floor:GetInt(), 0, 6)
    local ceiling = math.Clamp(cv_ceiling:GetInt(), floor, 6)

    -- ヒステリシス: 5%マージン
    local degradeThreshold = targetFPS * 0.95
    local recoverThreshold = targetFPS * 1.05

    if state.fpsEMA < degradeThreshold then
        -- FPS不足: degradeタイマー蓄積
        state.degradeTimer = state.degradeTimer + dt
        state.recoverTimer = 0

        if state.degradeTimer >= cv_degrade_time:GetFloat() then
            local newTier = math.min(state.currentTier + 1, ceiling)
            if newTier ~= state.currentTier then
                ApplyTier(newTier)
            end
            state.degradeTimer = 0
        end

    elseif state.fpsEMA > recoverThreshold then
        -- FPS余裕: recoverタイマー蓄積
        state.recoverTimer = state.recoverTimer + dt
        state.degradeTimer = 0

        if state.recoverTimer >= cv_recover_time:GetFloat() then
            local newTier = math.max(state.currentTier - 1, floor)
            if newTier ~= state.currentTier then
                ApplyTier(newTier)
            end
            state.recoverTimer = 0
        end

    else
        -- ヒステリシスゾーン: 両タイマーリセット
        state.degradeTimer = 0
        state.recoverTimer = 0
    end
end

hook.Add("Think", "vrmod_adaptive_fps_think", AdaptiveThink)

-- ============================================================
-- Emergency: VRMod_PerformancePressure Integration
-- ============================================================
hook.Add("VRMod_PerformancePressure", "vrmod_adaptive_emergency", function(level, remaining)
    if not cv_enabled:GetBool() then return end
    if not state.active then return end

    local ceiling = math.Clamp(cv_ceiling:GetInt(), 0, 6)

    if level == "critical" then
        local newTier = math.min(state.currentTier + 2, ceiling)
        if newTier ~= state.currentTier then
            ApplyTier(newTier)
            state.degradeTimer = 0
            state.recoverTimer = 0
            if cv_debug:GetBool() then
                print("[VRMod Adaptive] EMERGENCY critical: jumped to tier " .. newTier)
            end
        end
    elseif level == "warning" then
        local newTier = math.min(state.currentTier + 1, ceiling)
        if newTier ~= state.currentTier then
            ApplyTier(newTier)
            state.degradeTimer = 0
            state.recoverTimer = 0
            if cv_debug:GetBool() then
                print("[VRMod Adaptive] EMERGENCY warning: jumped to tier " .. newTier)
            end
        end
    end
end)

-- ============================================================
-- VR Lifecycle
-- ============================================================
local function Activate()
    if state.active then return end
    if not cv_enabled:GetBool() then return end

    SnapshotBaseline()
    state.active = true
    state.currentTier = 0
    state.fpsEMA = 0
    state.emaSamples = 0
    state.degradeTimer = 0
    state.recoverTimer = 0
    state.lastThinkTime = SysTime()
    state.lastTierChangeTime = 0
    state.lastFarzValue = -1

    if cv_debug:GetBool() then
        print("[VRMod Adaptive] Activated")
    end
end

local function Deactivate()
    if not state.active then return end

    RestoreBaseline()
    state.active = false
    state.currentTier = 0
    state.lastFarzValue = -1

    if cv_debug:GetBool() then
        print("[VRMod Adaptive] Deactivated")
    end
end

-- VRMod_Start: optimizeシステムの後に起動 (0.5秒遅延)
hook.Add("VRMod_Start", "vrmod_adaptive_start", function(ply)
    if IsValid(ply) and ply ~= LocalPlayer() then return end

    timer.Simple(0.5, function()
        if g_VR and g_VR.active then
            Activate()
        end
    end)
end)

hook.Add("VRMod_Exit", "vrmod_adaptive_exit", function(ply)
    Deactivate()
end)

-- Mid-session toggle
cvars.AddChangeCallback("vrmod_adaptive_enabled", function(name, old, new)
    if tobool(new) then
        if g_VR and g_VR.active then
            Activate()
        end
    else
        Deactivate()
    end
end, "vrmod_adaptive_toggle")

-- ============================================================
-- Reset Command
-- ============================================================
concommand.Add("vrmod_adaptive_reset", function()
    if state.active then
        ApplyTier(0)
        state.degradeTimer = 0
        state.recoverTimer = 0
        state.lastFarzValue = -1
        if state.farzBaseline > 0 then
            RunConsoleCommand("r_farz", tostring(math.floor(state.farzBaseline)))
        end
        print("[VRMod Adaptive] Reset to tier 0")
    end
end)

-- ============================================================
-- HUD Indicator (VR overlay)
-- ============================================================
local TIER_COLORS = {
    [0] = Color(100, 220, 100), -- Green
    [1] = Color(140, 220, 100), -- Green-Yellow
    [2] = Color(220, 220, 80),  -- Yellow
    [3] = Color(220, 180, 60),  -- Yellow-Orange
    [4] = Color(220, 140, 40),  -- Orange
    [5] = Color(220, 80, 40),   -- Orange-Red
    [6] = Color(220, 40, 40),   -- Red
}

hook.Add("VRMod_PostRender", "vrmod_adaptive_hud_indicator", function()
    if not cv_hud_indicator:GetBool() then return end
    if not state.active then return end

    local tier = state.currentTier
    local color = TIER_COLORS[tier] or Color(255, 255, 255)
    local tierName = QUALITY_TIERS[tier] and QUALITY_TIERS[tier].name or "?"

    cam.Start2D()

    local barW = 120
    local barH = 6
    local x = 10
    local y = ScrH() - 30

    -- Background
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(x - 2, y - 16, barW + 4, barH + 20)

    -- Tier bar (width proportional to tier level)
    local fillW = math.floor(barW * (tier / 6))
    surface.SetDrawColor(color.r, color.g, color.b, 200)
    surface.DrawRect(x, y, math.max(fillW, 2), barH)

    -- Label
    draw.SimpleText(
        string.format("T%d %s", tier, tierName),
        "DermaDefault",
        x + 2, y - 14,
        Color(color.r, color.g, color.b, 220),
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
    )

    cam.End2D()
end)

-- ============================================================
-- Menu Integration
-- ============================================================
hook.Add("VRMod_Menu", "vrmod_adaptive_fps_menu", function(frame)
    if not frame or not frame.DPropertySheet then return end

    local panel = vgui.Create("DPanel")
    panel:SetPaintBackground(false)

    local y = 10

    -- Title
    local title = panel:Add("DLabel")
    title:SetPos(20, y)
    title:SetSize(400, 20)
    title:SetText(L("Adaptive FPS Optimization", "Adaptive FPS Optimization"))
    title:SetFont("DermaDefaultBold")
    y = y + 30

    -- Enable
    local enableCB = panel:Add("DCheckBoxLabel")
    enableCB:SetPos(20, y)
    enableCB:SetText(L("Enable Adaptive FPS", "Enable Adaptive FPS"))
    enableCB:SetConVar("vrmod_adaptive_enabled")
    enableCB:SizeToContents()
    y = y + 25

    -- Target FPS
    local targetSlider = panel:Add("DNumSlider")
    targetSlider:SetPos(20, y)
    targetSlider:SetSize(400, 30)
    targetSlider:SetText(L("Target FPS", "Target FPS"))
    targetSlider:SetMin(30)
    targetSlider:SetMax(144)
    targetSlider:SetDecimals(0)
    targetSlider:SetConVar("vrmod_adaptive_target_fps")
    y = y + 35

    -- Quality Floor
    local floorSlider = panel:Add("DNumSlider")
    floorSlider:SetPos(20, y)
    floorSlider:SetSize(400, 30)
    floorSlider:SetText(L("Min Quality Tier (Floor)", "Min Quality Tier (Floor)"))
    floorSlider:SetMin(0)
    floorSlider:SetMax(6)
    floorSlider:SetDecimals(0)
    floorSlider:SetConVar("vrmod_adaptive_floor")
    y = y + 35

    -- Quality Ceiling
    local ceilingSlider = panel:Add("DNumSlider")
    ceilingSlider:SetPos(20, y)
    ceilingSlider:SetSize(400, 30)
    ceilingSlider:SetText(L("Max Quality Tier (Ceiling)", "Max Quality Tier (Ceiling)"))
    ceilingSlider:SetMin(0)
    ceilingSlider:SetMax(6)
    ceilingSlider:SetDecimals(0)
    ceilingSlider:SetConVar("vrmod_adaptive_ceiling")
    y = y + 35

    -- Degrade Time
    local degradeSlider = panel:Add("DNumSlider")
    degradeSlider:SetPos(20, y)
    degradeSlider:SetSize(400, 30)
    degradeSlider:SetText(L("Degrade Speed (sec)", "Degrade Speed (sec)"))
    degradeSlider:SetMin(0.5)
    degradeSlider:SetMax(5.0)
    degradeSlider:SetDecimals(1)
    degradeSlider:SetConVar("vrmod_adaptive_degrade_time")
    y = y + 35

    -- Recovery Time
    local recoverSlider = panel:Add("DNumSlider")
    recoverSlider:SetPos(20, y)
    recoverSlider:SetSize(400, 30)
    recoverSlider:SetText(L("Recovery Speed (sec)", "Recovery Speed (sec)"))
    recoverSlider:SetMin(3.0)
    recoverSlider:SetMax(15.0)
    recoverSlider:SetDecimals(1)
    recoverSlider:SetConVar("vrmod_adaptive_recover_time")
    y = y + 35

    -- Far Z Min
    local farzSlider = panel:Add("DNumSlider")
    farzSlider:SetPos(20, y)
    farzSlider:SetSize(400, 30)
    farzSlider:SetText(L("Min Draw Distance (r_farz)", "Min Draw Distance (r_farz)"))
    farzSlider:SetMin(500)
    farzSlider:SetMax(10000)
    farzSlider:SetDecimals(0)
    farzSlider:SetConVar("vrmod_adaptive_farz_min")
    y = y + 35

    -- HUD Indicator
    local hudCB = panel:Add("DCheckBoxLabel")
    hudCB:SetPos(20, y)
    hudCB:SetText(L("Show HUD Indicator", "Show HUD Indicator"))
    hudCB:SetConVar("vrmod_adaptive_hud_indicator")
    hudCB:SizeToContents()
    y = y + 25

    -- Debug
    local debugCB = panel:Add("DCheckBoxLabel")
    debugCB:SetPos(20, y)
    debugCB:SetText(L("Debug Output", "Debug Output"))
    debugCB:SetConVar("vrmod_adaptive_debug")
    debugCB:SizeToContents()
    y = y + 30

    -- Status display (live)
    local statusLabel = panel:Add("DLabel")
    statusLabel:SetPos(20, y)
    statusLabel:SetSize(400, 60)
    statusLabel:SetText("Status: Inactive")
    statusLabel:SetWrap(true)
    statusLabel.Think = function(self)
        if state.active then
            local tierName = QUALITY_TIERS[state.currentTier] and QUALITY_TIERS[state.currentTier].name or "?"
            self:SetText(string.format(
                "Status: Active\nTier: %d (%s) | FPS EMA: %.1f | r_farz: %d\nDegrade: %.1fs | Recover: %.1fs",
                state.currentTier, tierName, state.fpsEMA,
                state.lastFarzValue >= 0 and state.lastFarzValue or 0,
                state.degradeTimer, state.recoverTimer
            ))
        else
            self:SetText("Status: " .. (cv_enabled:GetBool() and "Waiting for VR start..." or "Disabled"))
        end
    end
    y = y + 70

    -- Reset button
    local resetBtn = panel:Add("DButton")
    resetBtn:SetPos(20, y)
    resetBtn:SetSize(200, 30)
    resetBtn:SetText(L("Force Reset to Tier 0", "Force Reset to Tier 0"))
    resetBtn.DoClick = function()
        RunConsoleCommand("vrmod_adaptive_reset")
    end

    frame.DPropertySheet:AddSheet(
        L("Adaptive FPS", "Adaptive FPS"),
        panel,
        "icon16/chart_curve.png"
    )
end)

-- ============================================================
-- Public API
-- ============================================================
vrmod = vrmod or {}
vrmod.AdaptiveFPS = vrmod.AdaptiveFPS or {}

function vrmod.AdaptiveFPS.IsActive()
    return state.active
end

function vrmod.AdaptiveFPS.GetCurrentTier()
    return state.currentTier
end

function vrmod.AdaptiveFPS.GetTierName()
    return QUALITY_TIERS[state.currentTier] and QUALITY_TIERS[state.currentTier].name or "Unknown"
end

function vrmod.AdaptiveFPS.GetFPSEMA()
    return state.fpsEMA
end

function vrmod.AdaptiveFPS.GetFarZValue()
    return state.lastFarzValue
end

print("[VRMod] Adaptive FPS Optimization system loaded")
