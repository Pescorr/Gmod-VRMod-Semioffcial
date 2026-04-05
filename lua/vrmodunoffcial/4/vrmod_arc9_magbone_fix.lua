--------[vrmod_arc9_magbone_fix.lua]Start--------
-- ARC9 マガジンボーン修正
-- ARC9のDoBodygroups()が毎フレーム全ボーンをリセットするため、
-- DoBodygroupsをインスタンスレベルでラップし、リセット後にマガジンボーン処理を再適用する。
--
-- さらにPreDrawViewModelもラップし、ARC9のInvalidateBoneCache()後に
-- マガジンボーン行列を左手位置へ上書きする（追従モード）。
--
-- ConVar: vrmod_arc9_magbone_track
--   0 = 旧仕様: マガジンボーンを非表示にするだけ
--   1 = 新仕様: vrmagent保持中はマガジンボーンを左手に追従させる

if SERVER then return end

local arc9MagState = 0          -- -1: pending hide (delay), 0: normal, 1: reload pressed (mag hidden), 2: vrmagent held
local arc9PendingHideTime = 0   -- CurTime() target for state -1 → 1 transition
local currentARC9Weapon = nil
local originalDoBodygroups = nil
local originalPreDrawViewModel = nil
local magBoneCache = {}         -- weapon entity → bone info table

-- オフセットConVar参照（遅延初期化 — vrmod_magbonesystem.luaで定義済み）
local cv_posX, cv_posY, cv_posZ
local cv_angP, cv_angY, cv_angR

local function CacheOffsetConVars()
    if cv_posX then return end
    cv_posX = GetConVar("vrmod_mag_pos_x")
    cv_posY = GetConVar("vrmod_mag_pos_y")
    cv_posZ = GetConVar("vrmod_mag_pos_z")
    cv_angP = GetConVar("vrmod_mag_ang_p")
    cv_angY = GetConVar("vrmod_mag_ang_y")
    cv_angR = GetConVar("vrmod_mag_ang_r")
end

-- マガジンボーン名の判定（既存vrmod_mag_bonesのキーワードを再利用）
local function IsMagazineBone(boneName)
    -- Override check: if user set a specific magbone, only that bone matches
    if vrmod.IsMagboneOverride then
        local ply = LocalPlayer()
        if IsValid(ply) then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) then
                local result = vrmod.IsMagboneOverride(wep:GetClass(), boneName)
                if result ~= nil then return result end -- override decided
            end
        end
    end
    -- Original auto-detect logic
    boneName = string.lower(boneName)
    local magBonesConVar = GetConVar("vrmod_mag_bones")
    local keywordStr = magBonesConVar and magBonesConVar:GetString() or "mag,ammo,clip,cylin,shell,magazine"
    local keywords = string.Explode(",", keywordStr)

    for _, keyword in ipairs(keywords) do
        keyword = string.Trim(string.lower(keyword))
        if keyword ~= "" and string.find(boneName, keyword, 1, true) then
            return true
        end
    end

    return false
end

-- マガジンボーンのインデックスを取得（武器ごとにキャッシュ）
local function GetMagBoneIndices(vm, wep)
    if magBoneCache[wep] then return magBoneCache[wep] end

    local indices = {}
    if not IsValid(vm) then return indices end

    for i = 0, vm:GetBoneCount() - 1 do
        local boneName = vm:GetBoneName(i)
        if IsMagazineBone(boneName) then
            table.insert(indices, {index = i, name = boneName})
        end
    end

    magBoneCache[wep] = indices
    if #indices > 0 then
        vrmod.ARC9Log("Found " .. #indices .. " magazine bones for " .. wep:GetClass())
        for _, bone in ipairs(indices) do
            vrmod.ARC9Log("  [" .. bone.index .. "] " .. bone.name)
        end
    end

    return indices
end

-- 左手位置にvrmod_mag_pos/angオフセットを適用
local function ApplyARC9MagOffsets(handPos, handAng)
    CacheOffsetConVars()
    local offsetPos = Vector(cv_posX:GetFloat(), cv_posY:GetFloat(), cv_posZ:GetFloat())
    local offsetAng = Angle(cv_angP:GetFloat(), cv_angY:GetFloat(), cv_angR:GetFloat())
    return LocalToWorld(offsetPos, offsetAng, handPos, handAng)
end

-- ========================================================================
-- DoBodygroups ラップ
-- ARC9のリセット後にマガジンボーン処理を追加
-- ========================================================================
local function WrapDoBodygroups(wep)
    if not IsValid(wep) then return false end

    local original = wep.DoBodygroups
    if not original then
        vrmod.ARC9Log("ERROR: DoBodygroups not found on " .. tostring(wep))
        return false
    end

    if originalDoBodygroups then return true end -- 既にラップ済み

    originalDoBodygroups = original

    wep.DoBodygroups = function(self, wm, cm)
        originalDoBodygroups(self, wm, cm)

        -- ViewModelのみ介入（WorldModel/CustomModelには触らない）
        if wm then return end
        if cm then return end

        -- state 0 or -1 (pending): 何もしない（通常状態）
        if arc9MagState == 0 or arc9MagState == -1 then return end

        -- state 2 + 追従モード: ここでは骨を隠さない
        -- → PreDrawViewModelラップ側でSetBoneMatrixを使って追従させる
        if arc9MagState == 2 and vrmod.IsARC9MagTrackEnabled() then return end

        -- state 1（リロードボタン押下）または state 2 + 非追従モード（旧仕様）: 骨を非表示に
        local vm = LocalPlayer():GetViewModel()
        if not IsValid(vm) then return end

        local bones = GetMagBoneIndices(vm, self)
        for _, bone in ipairs(bones) do
            vm:ManipulateBoneScale(bone.index, Vector(0, 0, 0))
        end
    end

    vrmod.ARC9Log("DoBodygroups wrapped for " .. wep:GetClass())
    return true
end

-- ========================================================================
-- PreDrawViewModel ラップ
-- ARC9のInvalidateBoneCache()後に介入し、SetupBones→SetBoneMatrixで骨を左手へ追従
--
-- タイミング解説:
--   ARC9 PreDrawViewModel: DoBodygroups → InvalidateBoneCache → cam.Start3D
--   [ここにラップ後処理を注入]
--   Engine: DrawModel（キャッシュ有効なのでSetupBonesを再呼びしない）
--   ViewModelDrawn: DrawCustomModel → DoRHIK（手IK用）
-- ========================================================================
local function WrapPreDrawViewModel(wep)
    if not IsValid(wep) then return false end

    local original = wep.PreDrawViewModel
    if not original then
        vrmod.ARC9Log("ERROR: PreDrawViewModel not found on " .. tostring(wep))
        return false
    end

    if originalPreDrawViewModel then return true end -- 既にラップ済み

    originalPreDrawViewModel = original

    wep.PreDrawViewModel = function(self, vm2, weapon, ply, flags)
        -- 元のPreDrawViewModelを呼び出し（DoBodygroups + InvalidateBoneCache 含む）
        originalPreDrawViewModel(self, vm2, weapon, ply, flags)

        -- 追従モード + vrmagent保持中のみ介入
        if arc9MagState ~= 2 then return end
        if not vrmod.IsARC9MagTrackEnabled() then return end
        if not g_VR or not g_VR.active then return end
        if not g_VR.tracking then return end

        local myvm = LocalPlayer():GetViewModel()
        if not IsValid(myvm) then return end

        -- 左手位置 + オフセット計算
        local leftHandPos = g_VR.tracking.pose_lefthand.pos
        local leftHandAng = g_VR.tracking.pose_lefthand.ang
        leftHandPos, leftHandAng = ApplyARC9MagOffsets(leftHandPos, leftHandAng)

        -- InvalidateBoneCache後にSetupBonesでキャッシュを再構築
        -- → エンジンがDrawModel時にSetupBonesを呼び直さないようにする
        myvm:SetupBones()

        -- マガジンボーン行列を左手位置で上書き
        local bones = GetMagBoneIndices(myvm, self)
        for _, bone in ipairs(bones) do
            local mat = myvm:GetBoneMatrix(bone.index)
            if mat then
                mat:SetTranslation(leftHandPos)
                mat:SetAngles(leftHandAng)
                myvm:SetBoneMatrix(bone.index, mat)
                vrmod.ARC9Log("SetBoneMatrix [" .. bone.index .. "] -> left hand")
            end
        end
    end

    vrmod.ARC9Log("PreDrawViewModel wrapped for " .. wep:GetClass())
    return true
end

-- ========================================================================
-- アンラップ / リセット
-- ========================================================================
local function UnwrapDoBodygroups(wep)
    if IsValid(wep) then
        if originalDoBodygroups then
            wep.DoBodygroups = originalDoBodygroups
            vrmod.ARC9Log("DoBodygroups restored for " .. wep:GetClass())
        end
        if originalPreDrawViewModel then
            wep.PreDrawViewModel = originalPreDrawViewModel
            vrmod.ARC9Log("PreDrawViewModel restored for " .. wep:GetClass())
        end
    end
    originalDoBodygroups = nil
    originalPreDrawViewModel = nil
end

local function ResetARC9MagState()
    if IsValid(currentARC9Weapon) then
        UnwrapDoBodygroups(currentARC9Weapon)
    end
    arc9MagState = 0
    arc9PendingHideTime = 0
    currentARC9Weapon = nil
    originalDoBodygroups = nil
    originalPreDrawViewModel = nil
end

-- ========================================================================
-- フック
-- ========================================================================

-- VRMod_Input: boolean_reloadでマガジン状態をトグル
hook.Add("VRMod_Input", "VRMod_ARC9_MagBoneInput", function(action, pressed)
    if not g_VR or not g_VR.active then return end
    if not vrmod.IsARC9FixEnabled() then return end

    if action == "boolean_reload" and pressed then
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if not vrmod.IsARC9Weapon(wep) then return end

        if arc9MagState == -1 then
            -- PENDING中に再押下 → キャンセル
            arc9MagState = 0
            arc9PendingHideTime = 0
            vrmod.ARC9Log("Magazine state: -1 -> 0 (pending cancelled)")
        elseif arc9MagState == 0 then
            local delay = GetConVar("vrmod_mag_ejectbone_delay"):GetFloat()
            if delay <= 0 then
                arc9MagState = 1
                vrmod.ARC9Log("Magazine state: 0 -> 1 (hidden, instant)")
            else
                arc9MagState = -1
                arc9PendingHideTime = CurTime() + delay
                vrmod.ARC9Log("Magazine state: 0 -> -1 (pending, delay=" .. delay .. "s)")
            end
        else
            arc9MagState = 0
            arc9PendingHideTime = 0
            vrmod.ARC9Log("Magazine state: -> 0 (normal)")
        end
    end
end)

-- Think: ARC9武器の検出とラップ管理
hook.Add("Think", "VRMod_ARC9_MagBoneThink", function()
    if not g_VR or not g_VR.active then return end
    if not vrmod.IsARC9FixEnabled() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()

    if vrmod.IsARC9Weapon(wep) then
        if currentARC9Weapon ~= wep then
            -- 前の武器のラップを復元
            if IsValid(currentARC9Weapon) then
                UnwrapDoBodygroups(currentARC9Weapon)
            end

            currentARC9Weapon = wep
            arc9MagState = 0
            arc9PendingHideTime = 0

            -- 新しい武器をラップ
            WrapDoBodygroups(wep)
            WrapPreDrawViewModel(wep)
        end

        -- PENDINGタイマーチェック（vrmagent保持チェックの前に）
        if arc9MagState == -1 and CurTime() >= arc9PendingHideTime then
            arc9MagState = 1
            arc9PendingHideTime = 0
            vrmod.ARC9Log("Magazine state: -1 -> 1 (pending timer elapsed)")
        end

        -- vrmagent保持状態の更新（PENDING中でも優先）
        if ply.hasMagazine and arc9MagState ~= 2 then
            if arc9MagState == -1 then
                arc9PendingHideTime = 0  -- Pendingキャンセル
            end
            arc9MagState = 2
            vrmod.ARC9Log("Magazine state -> 2 (vrmagent held)")
        elseif not ply.hasMagazine and arc9MagState == 2 then
            arc9MagState = 0
            vrmod.ARC9Log("Magazine state -> 0 (vrmagent released)")
        end
    else
        if currentARC9Weapon ~= nil then
            ResetARC9MagState()
            vrmod.ARC9Log("Switched away from ARC9 weapon")
        end
    end
end)

-- VRMod_Exit: クリーンアップ
hook.Add("VRMod_Exit", "VRMod_ARC9_MagBoneCleanup", function()
    ResetARC9MagState()
    magBoneCache = {}
    vrmod.ARC9Log("ARC9 magbone fix cleaned up")
end)

-- Clear cache when weapon bone config changes
hook.Add("VRMod_WeaponBoneConfigChanged", "VRMod_ARC9_MagBoneCacheInvalidate", function(weaponClass)
    -- magBoneCache is keyed by weapon entity, not class string
    -- Clear all entries since we can't easily map class to entity
    magBoneCache = {}
end)
--------[vrmod_arc9_magbone_fix.lua]End--------
