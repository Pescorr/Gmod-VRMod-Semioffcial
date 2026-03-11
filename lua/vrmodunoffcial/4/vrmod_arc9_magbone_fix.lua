--------[vrmod_arc9_magbone_fix.lua]Start--------
-- ARC9 マガジンボーン修正
-- ARC9のDoBodygroups()が毎フレーム全ボーンをリセットするため、
-- DoBodygroupsをインスタンスレベルでラップし、リセット後にマガジンボーン非表示を再適用する
--
-- 既存VRMagシステム（vrmod_magbonesystem.lua）は動作し続けるが、
-- ARC9のリセットにより効果がない。本ファイルがARC9専用の追加処理を行う。

if SERVER then return end

local arc9MagState = 0 -- 0: normal, 1: reload pressed (mag hidden), 2: vrmagent held
local currentARC9Weapon = nil
local originalDoBodygroups = nil
local magBoneCache = {} -- weapon entity → bone info table

-- マガジンボーン名の判定（既存vrmod_mag_bonesのキーワードを再利用）
local function IsMagazineBone(boneName)
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

-- DoBodygroupsをラップ: 元の処理の後にマガジンボーン非表示を追加
local function WrapDoBodygroups(wep)
    if not IsValid(wep) then return false end

    local original = wep.DoBodygroups
    if not original then
        vrmod.ARC9Log("ERROR: DoBodygroups not found on " .. tostring(wep))
        return false
    end

    -- 既にラップ済みなら何もしない
    if originalDoBodygroups then return true end

    originalDoBodygroups = original

    wep.DoBodygroups = function(self, wm, cm)
        -- 元のDoBodygroupsを呼び出し（ARC9のリセット+選択的非表示）
        originalDoBodygroups(self, wm, cm)

        -- ViewModelのみ介入（WorldModelやCustomModelには触らない）
        if wm then return end
        if cm then return end
        if arc9MagState == 0 then return end

        -- ARC9のリセット後にマガジンボーン非表示を追加
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

-- DoBodygroupsを復元
local function UnwrapDoBodygroups(wep)
    if IsValid(wep) and originalDoBodygroups then
        wep.DoBodygroups = originalDoBodygroups
        vrmod.ARC9Log("DoBodygroups restored for " .. wep:GetClass())
    end
    originalDoBodygroups = nil
end

-- 全状態リセット
local function ResetARC9MagState()
    if IsValid(currentARC9Weapon) then
        UnwrapDoBodygroups(currentARC9Weapon)
    end
    arc9MagState = 0
    currentARC9Weapon = nil
    originalDoBodygroups = nil
end

-- VRMod_Input: boolean_reloadでマガジン状態をトグル
hook.Add("VRMod_Input", "VRMod_ARC9_MagBoneInput", function(action, pressed)
    if not g_VR or not g_VR.active then return end
    if not vrmod.IsARC9FixEnabled() then return end

    if action == "boolean_reload" and pressed then
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if not vrmod.IsARC9Weapon(wep) then return end

        if arc9MagState == 0 then
            arc9MagState = 1
            vrmod.ARC9Log("Magazine state: 0 -> 1 (hidden)")
        else
            arc9MagState = 0
            vrmod.ARC9Log("Magazine state: " .. arc9MagState .. " -> 0 (normal)")
        end
    end
end)

-- Think: ARC9武器の検出とDoBodygroupsラップ管理
hook.Add("Think", "VRMod_ARC9_MagBoneThink", function()
    if not g_VR or not g_VR.active then return end
    if not vrmod.IsARC9FixEnabled() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()

    if vrmod.IsARC9Weapon(wep) then
        if currentARC9Weapon ~= wep then
            -- 前の武器のDoBodygroupsを復元
            if originalDoBodygroups and IsValid(currentARC9Weapon) then
                UnwrapDoBodygroups(currentARC9Weapon)
            end

            currentARC9Weapon = wep
            arc9MagState = 0
            originalDoBodygroups = nil

            -- 新しい武器のDoBodygroupsをラップ
            WrapDoBodygroups(wep)
        end

        -- vrmagent保持状態の更新
        if ply.hasMagazine and arc9MagState ~= 2 then
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
--------[vrmod_arc9_magbone_fix.lua]End--------
