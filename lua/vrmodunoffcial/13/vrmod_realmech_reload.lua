--[[
    Module 13: RealMech - Animation Interact Reload System

    武器本来のリロードアニメーションを活かす方式:
    1. Gmodの通常リロードが発動 → アニメーション再生開始
    2. 一定時間後にアニメーションをフリーズ + 弾倉ボーン非表示
    3. vrmagentをピックアップ → idle復帰（武器が通常持ちに戻る）
    4. Module 4がvrmagent insertion を管理
    5. VRMag挿入完了 → 完了

    Clip1操作は一切行わない。
    Module 4は変更しない。ply.hasMagazineフラグで間接連携。
]]

AddCSLuaFile()
if SERVER then return end

-- ============================================================================
-- Reload Animation State
-- ============================================================================

local reloadAnim = {
    state = 0,              -- 0=IDLE, 1=ANIMATING, 2=FROZEN, 3=INSERTING, 4=COMPLETING
    freezeTime = 0,         -- CurTime() when freeze should trigger
    lastWeaponClass = "",   -- Weapon class when reload started
    completeTime = 0,       -- CurTime() when COMPLETING started
    cooldownUntil = 0,      -- CurTime() until which STATE 0 ignores reload detection
    idleSequence = -1,      -- Cached idle sequence index
    frozenSequence = -1,    -- Sequence captured at freeze moment
    frozenCycle = 0,        -- Cycle position captured at freeze moment
    hiddenMagBones = {},    -- Bone indices hidden by this system {[idx]=true}
}

-- Export for debug
vrmod.RealMech = vrmod.RealMech or {}
vrmod.RealMech.reloadAnim = reloadAnim

-- ============================================================================
-- Reload Animation Detection
-- ============================================================================

local RELOAD_ACTIVITIES = {
    [ACT_VM_RELOAD]          = true,  -- 181
    [ACT_VM_RELOAD_SILENCED] = true,  -- 188
}

if ACT_VM_RELOAD_EMPTY then
    RELOAD_ACTIVITIES[ACT_VM_RELOAD_EMPTY] = true  -- 189
end

local function IsReloadAnimation(vm)
    if not IsValid(vm) then return false end
    local seq = vm:GetSequence()
    if not seq then return false end
    local act = vm:GetSequenceActivity(seq)
    return RELOAD_ACTIVITIES[act] == true
end

-- ============================================================================
-- Find Idle Sequence
-- ============================================================================

local function FindIdleSequence(vm)
    if not IsValid(vm) then return 0 end
    local idleSeq = vm:SelectWeightedSequence(ACT_VM_IDLE)
    if idleSeq and idleSeq >= 0 then
        return idleSeq
    end
    return 0
end

-- ============================================================================
-- Magazine Bone Hiding (independent of Module 4)
-- ============================================================================

-- Same keywords as Module 4 + core.lua magazine category
local MAG_KEYWORDS = {"mag", "clip", "magazine", "ammo", "cylin", "shell"}

local function IsMagBone(boneName)
    local lower = string.lower(boneName)
    for _, kw in ipairs(MAG_KEYWORDS) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

local function HideMagBones(vm)
    if not IsValid(vm) then return end
    reloadAnim.hiddenMagBones = {}

    for i = 0, vm:GetBoneCount() - 1 do
        local name = vm:GetBoneName(i)
        if name and IsMagBone(name) then
            reloadAnim.hiddenMagBones[i] = true
            vm:ManipulateBoneScale(i, Vector(0, 0, 0))
        end
    end
end

local function ShowMagBones(vm)
    if not IsValid(vm) then return end
    for i, _ in pairs(reloadAnim.hiddenMagBones) do
        vm:ManipulateBoneScale(i, Vector(1, 1, 1))
    end
    reloadAnim.hiddenMagBones = {}
end

local function KeepMagBonesHidden(vm)
    -- Re-apply hide each frame (in case animations reset scale)
    for i, _ in pairs(reloadAnim.hiddenMagBones) do
        vm:ManipulateBoneScale(i, Vector(0, 0, 0))
    end
end

-- ============================================================================
-- Cancel / Cleanup
-- ============================================================================

local function CancelReloadAnim(vm)
    if reloadAnim.state == 0 then return end

    -- Restore playback rate
    if IsValid(vm) then
        vm:SetPlaybackRate(1.0)
    end

    -- Restore magazine bones
    ShowMagBones(vm)

    -- Reset state
    reloadAnim.state = 0
    reloadAnim.freezeTime = 0
    reloadAnim.frozenSequence = -1
    reloadAnim.frozenCycle = 0
    reloadAnim.hiddenMagBones = {}
    -- cooldownUntil は意図的にリセットしない（キャンセル後も保護が必要な場合がある）
end

vrmod.RealMech.CancelReloadAnim = CancelReloadAnim

-- ============================================================================
-- Main State Machine (VRMod_PreRender)
-- ============================================================================

hook.Add("VRMod_PreRender", "VRRealMech_ReloadAnim", function()
    if not g_VR or not g_VR.active then return end
    if not vrmod.RealMech.IsEnabled() then return end

    local cv = vrmod.RealMech.cv
    if not cv.reload_enable:GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        CancelReloadAnim(nil)
        return
    end

    local wep = ply:GetActiveWeapon()
    local vm = ply:GetViewModel()
    if not IsValid(wep) or not IsValid(vm) then
        CancelReloadAnim(vm)
        return
    end

    if vrmod.RealMech.ShouldSkipWeapon(wep) then
        CancelReloadAnim(vm)
        return
    end

    local class = wep:GetClass()
    if reloadAnim.state > 0 and class ~= reloadAnim.lastWeaponClass then
        CancelReloadAnim(vm)
        return
    end

    local freezeRate = cv.reload_freeze_rate:GetFloat()

    -- ===== STATE 0: IDLE =====
    if reloadAnim.state == 0 then
        -- クールダウン中はリロード検出をスキップ
        -- （完了直後の再検出や武器内部タイマーとの競合を防ぐ）
        if CurTime() < reloadAnim.cooldownUntil then return end

        if IsReloadAnimation(vm) then
            reloadAnim.state = 1
            reloadAnim.freezeTime = CurTime() + cv.reload_freeze_delay:GetFloat()
            reloadAnim.lastWeaponClass = class
            reloadAnim.idleSequence = FindIdleSequence(vm)
        end
        return
    end

    -- ===== STATE 1: ANIMATING — アニメ再生中、freeze_delay待ち =====
    if reloadAnim.state == 1 then
        if not IsReloadAnimation(vm) then
            CancelReloadAnim(vm)
            return
        end

        if CurTime() >= reloadAnim.freezeTime then
            -- Capture current pose
            reloadAnim.frozenSequence = vm:GetSequence()
            reloadAnim.frozenCycle = vm:GetCycle()

            -- Freeze animation
            vm:SetPlaybackRate(freezeRate)

            -- Hide magazine bones
            HideMagBones(vm)

            reloadAnim.state = 2
        end
        return
    end

    -- ===== STATE 2: FROZEN — アニメ固定 + 弾倉非表示、vrmagent待ち =====
    if reloadAnim.state == 2 then
        -- Re-apply freeze every frame
        vm:SetSequence(reloadAnim.frozenSequence)
        vm:SetCycle(reloadAnim.frozenCycle)
        vm:SetPlaybackRate(freezeRate)

        -- Re-apply magazine bone hiding
        KeepMagBonesHidden(vm)

        -- vrmagent picked up → 挿入待ちへ
        if ply.hasMagazine then
            if cv.reload_idle_return:GetBool() then
                -- idle復帰モード（ピストル等）: 通常持ちポーズに戻す
                vm:SetSequence(reloadAnim.idleSequence)
                vm:SetCycle(0)
                vm:SetPlaybackRate(1.0)
            end
            -- idle_return = 0 の場合はアニメをフリーズ状態のまま維持
            -- （リボルバー・中折れ等: 開いた状態を保持する）

            -- 弾倉ボーンはModule 4が管理する（左手に追従させる）
            -- Module 13の非表示を解除し、Module 4に委譲
            ShowMagBones(vm)

            reloadAnim.state = 3
        end
        return
    end

    -- ===== STATE 3: INSERTING — Module 4がvrmagent管理中 =====
    if reloadAnim.state == 3 then
        -- idle_return = 0（フリーズ維持モード）: 毎フレームフリーズポーズを再適用
        -- （リボルバー・中折れ等で、挿入中も開いた状態を保持する）
        if not cv.reload_idle_return:GetBool() then
            vm:SetSequence(reloadAnim.frozenSequence)
            vm:SetCycle(reloadAnim.frozenCycle)
            vm:SetPlaybackRate(freezeRate)
            KeepMagBonesHidden(vm)  -- Module 4がShowするので実質無効だが保険
        end
        -- idle_return = 1 の場合はModule 4に完全委譲（何も強制しない）

        -- Module 4が挿入完了（hasMagazine=false）
        if not ply.hasMagazine then
            reloadAnim.state = 4
            reloadAnim.completeTime = CurTime()
        end
        return
    end

    -- ===== STATE 4: COMPLETING — 短い待ち後にIDLEへ =====
    if reloadAnim.state == 4 then
        if CurTime() > reloadAnim.completeTime + 0.1 then
            -- フリーズ維持モードの場合: idle復帰してから速度を戻す
            -- （リロードシーケンスのまま速度を戻すと STATE 0 が再検出するため）
            if not cv.reload_idle_return:GetBool() then
                vm:SetSequence(reloadAnim.idleSequence)
                vm:SetCycle(0)
            end
            vm:SetPlaybackRate(1.0)

            -- 完了後クールダウン: 武器内部タイマーの再発火を無視する
            reloadAnim.cooldownUntil = CurTime() + 0.5

            reloadAnim.state = 0
            reloadAnim.frozenSequence = -1
            reloadAnim.frozenCycle = 0
        end
        return
    end
end)

-- ============================================================================
-- VRMod_Input: Cancel on fire/secondaryfire during FROZEN state
-- ============================================================================

hook.Add("VRMod_Input", "VRRealMech_ReloadCancel", function(action, pressed)
    if not pressed then return end
    if reloadAnim.state ~= 2 then return end

    if action == "boolean_primaryfire" or action == "boolean_secondaryfire" then
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local vm = ply:GetViewModel()
        CancelReloadAnim(vm)
    end
end)

-- ============================================================================
-- Cleanup Hooks
-- ============================================================================

hook.Add("VRMod_Exit", "VRRealMech_ReloadCleanup", function()
    local ply = LocalPlayer()
    local vm = IsValid(ply) and ply:GetViewModel() or nil
    CancelReloadAnim(vm)
end)

hook.Add("Shutdown", "VRRealMech_ReloadShutdown", function()
    local ply = LocalPlayer()
    local vm = IsValid(ply) and ply:GetViewModel() or nil
    if IsValid(vm) then
        ShowMagBones(vm)
        vm:SetPlaybackRate(1.0)
    end
end)

cvars.AddChangeCallback("vrmod_unoff_realmech_reload_enable", function(_, _, new)
    if new == "0" then
        local ply = LocalPlayer()
        local vm = IsValid(ply) and ply:GetViewModel() or nil
        CancelReloadAnim(vm)
    end
end, "VRRealMech_ReloadAnimToggle")

-- ============================================================================
-- Debug Command
-- ============================================================================

concommand.Add("vrmod_realmech_reload_state", function()
    print("[RealMech Reload] State: " .. reloadAnim.state)
    print("  frozenSequence: " .. reloadAnim.frozenSequence)
    print("  frozenCycle: " .. string.format("%.3f", reloadAnim.frozenCycle))
    print("  lastWeaponClass: " .. reloadAnim.lastWeaponClass)
    print("  hiddenMagBones: " .. table.Count(reloadAnim.hiddenMagBones))
    local cdRemain = reloadAnim.cooldownUntil - CurTime()
    print("  cooldown: " .. (cdRemain > 0 and string.format("%.2fs remaining", cdRemain) or "none"))

    local ply = LocalPlayer()
    if IsValid(ply) then
        print("  hasMagazine: " .. tostring(ply.hasMagazine or false))
        local vm = ply:GetViewModel()
        if IsValid(vm) then
            local seq = vm:GetSequence()
            print("  Current sequence: " .. seq .. " (" .. (vm:GetSequenceName(seq) or "?") .. ")")
            print("  Current cycle: " .. string.format("%.3f", vm:GetCycle()))
            print("  Current rate: " .. vm:GetPlaybackRate())
            print("  Activity: " .. vm:GetSequenceActivity(seq))
            print("  IsReload: " .. tostring(IsReloadAnimation(vm)))
        end
    end
end)

print("[RealMech] Reload loaded - Animation Interact system")
