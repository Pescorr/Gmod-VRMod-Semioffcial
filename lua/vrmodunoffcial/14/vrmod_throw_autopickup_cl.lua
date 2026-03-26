--[[
    Module 15: VR Throw Auto-Pickup — Client Side
    グリップボタン（VR Pickupキー）を押しながらグレネードを投げると、
    サーバーにAuto-Pickupリクエストを送信する。

    Module 14の vrmod.VRThrow.IsThrowable() を再利用して投擲武器を検出。
    グリップ状態は VRMod_Input フックで追跡したローカル変数で取得。

    Module 14との共存:
    - Module 14は攻撃リリース時に速度データを送信（vrmod_throw_fire）
    - Module 15は攻撃リリース時 + グリップ押しで追加リクエストを送信（vrmod_throw_autopickup_req）
    - 両方のネットメッセージは独立して送信され、サーバー側で独立処理される
]]

AddCSLuaFile()
if SERVER then return end

-- ============================================================================
-- Defensive Init
-- ============================================================================

g_VR = g_VR or {}
vrmod = vrmod or {}

-- ============================================================================
-- ConVar Definitions
-- ============================================================================

CreateClientConVar("vrmod_unoff_throw_autopickup", "1", true, false,
    "Auto-pickup grenades when grip is held during throw", 0, 1)
CreateClientConVar("vrmod_unoff_throw_autopickup_debug", "0", true, false,
    "Debug: log auto-pickup events", 0, 1)

-- ConVar cache
local cv_enabled = GetConVar("vrmod_unoff_throw_autopickup")
local cv_debug = GetConVar("vrmod_unoff_throw_autopickup_debug")

-- ============================================================================
-- State
-- ============================================================================

local wasAttacking = false
local throwCooldown = 0
local COOLDOWN_TIME = 0.5
local rightGripHeld = false
local leftGripHeld = false

-- ============================================================================
-- Core Detection (CreateMove)
-- ============================================================================

local function AutoPickupCreateMove(cmd)
    if not cv_enabled:GetBool() then return end
    if not g_VR.active then return end
    if not g_VR.threePoints then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then wasAttacking = false return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then wasAttacking = false return end

    -- Module 14の IsThrowable を再利用（Module 14未ロード時はスキップ）
    if not vrmod.VRThrow or not vrmod.VRThrow.IsThrowable then
        wasAttacking = false
        return
    end
    if not vrmod.VRThrow.IsThrowable(wep) then wasAttacking = false return end

    local isAttacking = bit.band(cmd:GetButtons(), IN_ATTACK) > 0

    -- リリース検出: ボタンを離した瞬間
    if wasAttacking and not isAttacking then
        if CurTime() > throwCooldown then
            -- グリップ状態チェック（VRMod_Inputフックで追跡したローカル変数を使用）
            if rightGripHeld or leftGripHeld then
                -- 両方押されている場合は右手優先
                local isLeftHand = (leftGripHeld and not rightGripHeld) and true or false

                net.Start("vrmod_throw_autopickup_req")
                    net.WriteBool(isLeftHand)
                net.SendToServer()

                throwCooldown = CurTime() + COOLDOWN_TIME

                if cv_debug:GetBool() then
                    print("[VRThrow AutoPickup] Request sent"
                        .. " | Hand: " .. (isLeftHand and "Left" or "Right")
                        .. " | Weapon: " .. wep:GetClass()
                        .. " | RGrip: " .. tostring(rightGripHeld)
                        .. " | LGrip: " .. tostring(leftGripHeld))
                end
            end
        end
    end

    wasAttacking = isAttacking
end

-- ============================================================================
-- VR Lifecycle
-- ============================================================================

local function OnVRInput(action, pressed)
    if action == "boolean_right_pickup" then rightGripHeld = pressed end
    if action == "boolean_left_pickup" then leftGripHeld = pressed end
end

local function OnVRStart(ply)
    if ply ~= LocalPlayer() then return end
    hook.Add("CreateMove", "vrmod_throw_autopickup_createmove", AutoPickupCreateMove)
    hook.Add("VRMod_Input", "vrmod_throw_autopickup_grip", OnVRInput)
end

local function OnVRExit(ply)
    if ply ~= LocalPlayer() then return end
    hook.Remove("CreateMove", "vrmod_throw_autopickup_createmove")
    hook.Remove("VRMod_Input", "vrmod_throw_autopickup_grip")
    wasAttacking = false
    throwCooldown = 0
    rightGripHeld = false
    leftGripHeld = false
end

hook.Add("VRMod_Start", "vrmod_throw_autopickup_cl_start", OnVRStart)
hook.Add("VRMod_Exit", "vrmod_throw_autopickup_cl_exit", OnVRExit)

-- ============================================================================
-- VRMOD_DEFAULTS Registration
-- ============================================================================

timer.Simple(0, function()
    if VRMOD_DEFAULTS then
        VRMOD_DEFAULTS["throw_autopickup"] = {
            vrmod_unoff_throw_autopickup = 1,
            vrmod_unoff_throw_autopickup_debug = 0,
        }
    end
end)
