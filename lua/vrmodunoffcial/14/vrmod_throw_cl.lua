--[[
    Module 14: VR Throw — Client Side
    投擲武器の自動検出、VR手の速度取得、サーバーへの送信。
    エンティティ捕捉方式（B方式）: 武器の攻撃を妨げず、
    ボタンリリース時にVR手の速度をサーバーに送信する。
]]

AddCSLuaFile()
if SERVER then return end

-- ============================================================================
-- Defensive Init
-- ============================================================================

g_VR = g_VR or {}
vrmod = vrmod or {}
vrmod.VRThrow = vrmod.VRThrow or {}

-- ============================================================================
-- ConVar Definitions
-- ============================================================================

CreateClientConVar("vrmod_unoff_throw_enabled", "1", true, false, "Enable VR throwing override")
CreateClientConVar("vrmod_unoff_throw_velocity_mult", "2", true, false, "Throw velocity multiplier")
CreateClientConVar("vrmod_unoff_throw_auto_detect", "1", true, false, "Auto-detect throwable weapons by class name")
CreateClientConVar("vrmod_unoff_throw_whitelist", "", true, false, "Comma-separated weapon class whitelist")
CreateClientConVar("vrmod_unoff_throw_debug", "0", true, false, "Debug: show throw detection info")
CreateClientConVar("vrmod_unoff_throw_anim_override", "1", true, false, "Force idle animation on throwable weapons to prevent hand jitter")
CreateClientConVar("vrmod_unoff_throw_hand_desync", "1", true, false, "Desync right hand from viewmodel bone during throw (prevents hand jitter from throw animation)")
CreateClientConVar("vrmod_unoff_throw_desync_method", "1", true, false, "Desync method: 0=g_VR.net direct override, 1=SetRightHandPose API (recommended)", 0, 1)

-- ConVar cache (never call GetConVar in per-frame hooks)
local cv_enabled = GetConVar("vrmod_unoff_throw_enabled")
local cv_velocity_mult = GetConVar("vrmod_unoff_throw_velocity_mult")
local cv_auto_detect = GetConVar("vrmod_unoff_throw_auto_detect")
local cv_whitelist = GetConVar("vrmod_unoff_throw_whitelist")
local cv_debug = GetConVar("vrmod_unoff_throw_debug")
local cv_anim_override = GetConVar("vrmod_unoff_throw_anim_override")
local cv_hand_desync = GetConVar("vrmod_unoff_throw_hand_desync")
local cv_desync_method = GetConVar("vrmod_unoff_throw_desync_method")

-- Export cached ConVars
vrmod.VRThrow.cv = {
    enabled = cv_enabled,
    velocity_mult = cv_velocity_mult,
    auto_detect = cv_auto_detect,
    whitelist = cv_whitelist,
    debug = cv_debug,
    anim_override = cv_anim_override,
    hand_desync = cv_hand_desync,
    desync_method = cv_desync_method,
}

-- ============================================================================
-- Throwable Weapon Detection
-- ============================================================================

local THROWABLE_CLASS_PATTERNS = {
    "grenade", "frag", "throw", "molotov", "dynamite", "bomb",
    "flask", "jar", "ball", "bait", "mine", "c4", "flare",
    "flashbang", "smoke", "incendiary", "sticky",
}

local THROWABLE_AMMO_PATTERNS = {
    "grenade", "frag", "bugbait", "slam",
}

local function IsThrowableByClassName(class)
    local lowerClass = string.lower(class)
    for _, pattern in ipairs(THROWABLE_CLASS_PATTERNS) do
        if string.find(lowerClass, pattern, 1, true) then
            return true
        end
    end
    return false
end

local function IsThrowableByAmmoType(wep)
    if not IsValid(wep) then return false end
    local ammoType = wep:GetPrimaryAmmoType()
    if ammoType == -1 then return false end
    local ammoName = game.GetAmmoName(ammoType)
    if not ammoName then return false end
    local lowerAmmo = string.lower(ammoName)
    for _, pattern in ipairs(THROWABLE_AMMO_PATTERNS) do
        if string.find(lowerAmmo, pattern, 1, true) then
            return true
        end
    end
    return false
end

-- Whitelist cache (re-parsed only when ConVar string changes)
local whitelistCache = {}
local whitelistStr = ""

local function IsThrowableByWhitelist(class)
    local currentStr = cv_whitelist:GetString()
    if currentStr ~= whitelistStr then
        whitelistStr = currentStr
        whitelistCache = {}
        for entry in string.gmatch(currentStr, "([^,]+)") do
            whitelistCache[string.Trim(entry)] = true
        end
    end
    return whitelistCache[class] == true
end

-- improved_hl2_weapons 競合回避
local function IsHandledByImprovedHL2(wepClass)
    if VRWep and VRWep.throw and VRWep.throw[wepClass] then
        return true
    end
    return false
end

--- 武器が投擲系かどうか判定する
-- @param wep Entity 武器エンティティ
-- @return boolean
function vrmod.VRThrow.IsThrowable(wep)
    if not IsValid(wep) then return false end
    local class = wep:GetClass()

    -- improved_hl2_weapons で既に処理されている場合はスキップ
    if IsHandledByImprovedHL2(class) then return false end

    -- ホワイトリスト（最優先）
    if IsThrowableByWhitelist(class) then return true end

    -- 自動検出
    if cv_auto_detect:GetBool() then
        if IsThrowableByClassName(class) then return true end
        if IsThrowableByAmmoType(wep) then return true end
    end

    return false
end

-- ============================================================================
-- Core Throw Detection (CreateMove)
-- ============================================================================

local wasAttacking = false
local throwCooldown = 0
local COOLDOWN_TIME = 0.5 -- アニメーション遅延を考慮してやや長め

local function ThrowCreateMove(cmd)
    if not cv_enabled:GetBool() then return end
    if not g_VR.active then return end
    if not g_VR.threePoints then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then wasAttacking = false return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then wasAttacking = false return end
    if not vrmod.VRThrow.IsThrowable(wep) then wasAttacking = false return end

    local isAttacking = bit.band(cmd:GetButtons(), IN_ATTACK) > 0

    -- リリース検出: ボタンを離した瞬間
    if wasAttacking and not isAttacking then
        if CurTime() > throwCooldown then
            throwCooldown = CurTime() + COOLDOWN_TIME

            local mult = cv_velocity_mult:GetFloat()
            local handVel = vrmod.GetRightHandVelocity() * mult
            local handAngVel = vrmod.GetRightHandAngularVelocity()

            net.Start("vrmod_throw_fire")
                net.WriteBool(false) -- isLeftHand (右手固定、将来拡張用)
                net.WriteVector(handVel)
                net.WriteVector(handAngVel)
            net.SendToServer()

            if cv_debug:GetBool() then
                print("[VRThrow] Throw! Weapon: " .. wep:GetClass()
                    .. " | Vel: " .. math.Round(handVel:Length(), 1)
                    .. " | Mult: " .. mult)
            end
        end
    end

    wasAttacking = isAttacking
end

-- ============================================================================
-- Throw Animation Override (アイドル強制)
-- ============================================================================

-- アイドルシーケンスキャッシュ（武器切り替え時にリセット）
local cachedIdleSeq = -1
local cachedIdleWeapon = ""

local IDLE_ACTIVITIES = {
    [ACT_VM_IDLE] = true,
}
if ACT_VM_IDLE_SILENCED then
    IDLE_ACTIVITIES[ACT_VM_IDLE_SILENCED] = true
end

local function FindIdleSequence(vm)
    local idleSeq = vm:SelectWeightedSequence(ACT_VM_IDLE)
    if idleSeq and idleSeq >= 0 then return idleSeq end
    return 0
end

local function ThrowAnimOverride()
    if not cv_anim_override:GetBool() then return end
    if not g_VR.active then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if not vrmod.VRThrow.IsThrowable(wep) then return end

    -- Module 13 RealMech が作動中なら介入しない
    if vrmod.RealMech and vrmod.RealMech.reloadAnim
       and vrmod.RealMech.reloadAnim.state > 0 then
        return
    end

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end

    -- アイドルシーケンスのキャッシュ（武器クラス変更時のみ再計算）
    local class = wep:GetClass()
    if class ~= cachedIdleWeapon then
        cachedIdleSeq = FindIdleSequence(vm)
        cachedIdleWeapon = class
    end

    -- 現在のアクティビティがアイドル以外ならアイドルに強制
    local seq = vm:GetSequence()
    local act = vm:GetSequenceActivity(seq)
    if not IDLE_ACTIVITIES[act] then
        vm:SetSequence(cachedIdleSeq)
        vm:SetCycle(0)
        vm:SetPlaybackRate(1.0)
    end
end

-- ============================================================================
-- Hand Desync (VRMod_PreRender: ボーン同期後にnetFrameを復元)
-- ============================================================================

local primaryFireHeld = false

--- VRMod_Input: primaryfireの押下状態を追跡
local function OnThrowInput(action, pressed)
    if action == "boolean_primaryfire" then
        primaryFireHeld = pressed
    end
end

--- VRMod_PreRender: ボーン同期の後、レンダリングの前に発火
-- vrmod.luaのRenderScene内フロー:
--   VRMod_Tracking → ボーン同期(netFrame上書き) → VRMod_PreRender → RenderView
-- ボーン同期でnetFrame.righthandPosがviewmodelのR_Handボーン位置に上書きされるが、
-- 投擲アニメーション中はボーンが激しく動くため手がブレる。
--
-- 方式0: g_VR.net直接上書き（Post-hook Data Override）
--   g_VR.tracking（生のコントローラ位置）からnetFrameを復元する。
--   OCP△（内部データ構造に依存）
--
-- 方式1: vrmod.SetRightHandPose() API（公式API、推奨）
--   APIドキュメント記載の公式関数で手の位置を強制上書き。
--   OCP◎（vrmod.lua変更不要、完全外部完結）
--
local function ThrowHandDesync()
    if not cv_enabled:GetBool() or not cv_hand_desync:GetBool() then return end
    if not primaryFireHeld then return end
    if not g_VR.active then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if not vrmod.VRThrow.IsThrowable(wep) then return end

    local method = cv_desync_method:GetInt()

    if method == 0 then
        -- =============================================
        -- 方式0: g_VR.net lerpedFrame 直接上書き
        -- =============================================
        local steamid = ply:SteamID()
        local netData = g_VR.net and g_VR.net[steamid]
        if not netData or not netData.lerpedFrame then return end

        local tracking = g_VR.tracking and g_VR.tracking.pose_righthand
        if not tracking then return end

        netData.lerpedFrame.righthandPos = tracking.pos
        netData.lerpedFrame.righthandAng = tracking.ang
    else
        -- =============================================
        -- 方式1: vrmod.SetRightHandPose() 公式API（推奨）
        -- =============================================
        if not vrmod.SetRightHandPose then return end

        local ok1, pos = pcall(vrmod.GetRightHandPos)
        local ok2, ang = pcall(vrmod.GetRightHandAng)
        if not ok1 or not ok2 then return end
        if not pos or not ang then return end

        pcall(vrmod.SetRightHandPose, pos, ang)
    end
end

-- ============================================================================
-- VR Lifecycle
-- ============================================================================

local function OnVRStart(ply)
    if ply ~= LocalPlayer() then return end
    hook.Add("CreateMove", "vrmod_throw_createmove", ThrowCreateMove)
    hook.Add("VRMod_PreRender", "vrmod_throw_anim_override", ThrowAnimOverride)
    hook.Add("VRMod_PreRender", "vrmod_throw_hand_desync", ThrowHandDesync)
    hook.Add("VRMod_Input", "vrmod_throw_input", OnThrowInput)
end

local function OnVRExit(ply)
    if ply ~= LocalPlayer() then return end
    hook.Remove("CreateMove", "vrmod_throw_createmove")
    hook.Remove("VRMod_PreRender", "vrmod_throw_anim_override")
    hook.Remove("VRMod_PreRender", "vrmod_throw_hand_desync")
    hook.Remove("VRMod_Input", "vrmod_throw_input")
    wasAttacking = false
    throwCooldown = 0
    cachedIdleSeq = -1
    cachedIdleWeapon = ""
    primaryFireHeld = false
end

hook.Add("VRMod_Start", "vrmod_throw_cl_start", OnVRStart)
hook.Add("VRMod_Exit", "vrmod_throw_cl_exit", OnVRExit)

-- ============================================================================
-- VRMOD_DEFAULTS Registration
-- ============================================================================

timer.Simple(0, function()
    if VRMOD_DEFAULTS then
        VRMOD_DEFAULTS["throw"] = {
            vrmod_unoff_throw_enabled = 1,
            vrmod_unoff_throw_velocity_mult = 2,
            vrmod_unoff_throw_auto_detect = 1,
            vrmod_unoff_throw_whitelist = "",
            vrmod_unoff_throw_debug = 0,
            vrmod_unoff_throw_anim_override = 1,
            vrmod_unoff_throw_hand_desync = 1,
            vrmod_unoff_throw_desync_method = 1,
        }
    end
end)
