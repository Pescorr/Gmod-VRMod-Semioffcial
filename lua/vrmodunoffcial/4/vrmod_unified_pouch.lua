--------[vrmod_unified_pouch.lua]Start--------
-- Unified Pouch Position System
-- ArcVRとVRMagで共通のポーチ位置設定を提供し、ArcVRのConVarに同期する
AddCSLuaFile()
if SERVER then return end

vrmod.pouch = vrmod.pouch or {}

-- =============================================================================
-- ConVar定義（遅延初期化キャッシュ）
-- =============================================================================
local cv_location, cv_dist, cv_sync, cv_infinite

local function EnsureConVars()
    if cv_location then return end
    cv_location = CreateClientConVar("vrmod_unoff_pouch_location", "pelvis", true, false, "Pouch bone location: pelvis / head / spine")
    cv_dist     = CreateClientConVar("vrmod_unoff_pouch_dist", "16", true, false, "Pouch distance threshold")
    cv_sync     = CreateClientConVar("vrmod_unoff_pouch_sync_arcvr", "1", true, false, "Sync pouch settings to ArcVR ConVars")
    cv_infinite = CreateClientConVar("vrmod_unoff_pouch_infinite", "0", true, false, "Infinite pouch mode (any distance)")
end

-- =============================================================================
-- ボーン名マッピング
-- =============================================================================
local POUCH_BONES = {
    pelvis = "ValveBiped.Bip01_Pelvis",
    head   = "ValveBiped.Bip01_Head1",
    spine  = "ValveBiped.Bip01_Spine4",
}

-- =============================================================================
-- ArcVR存在チェック（キャッシュ付き）
-- =============================================================================
local arcvrChecked = false
local arcvrInstalled = false

local function IsArcVRInstalled()
    if arcvrChecked then return arcvrInstalled end
    arcvrChecked = true
    arcvrInstalled = (GetConVar("arcticvr_defpouchdist") ~= nil)
    return arcvrInstalled
end

-- =============================================================================
-- ArcVR ConVar同期
-- =============================================================================
local function SyncToArcVR()
    EnsureConVars()
    if not cv_sync:GetBool() then return end
    if not IsArcVRInstalled() then return end

    local location = cv_location:GetString()
    local dist = cv_dist:GetFloat()
    local infinite = cv_infinite:GetBool()

    -- ポーチ位置の排他的切替
    if location == "head" then
        RunConsoleCommand("arcticvr_headpouch", "1")
        RunConsoleCommand("arcticvr_hybridpouch", "0")
        RunConsoleCommand("arcticvr_headpouchdist", tostring(dist))
    elseif location == "spine" then
        RunConsoleCommand("arcticvr_headpouch", "0")
        RunConsoleCommand("arcticvr_hybridpouch", "1")
        RunConsoleCommand("arcticvr_hybridpouchdist", tostring(dist))
    else -- pelvis (デフォルト)
        RunConsoleCommand("arcticvr_headpouch", "0")
        RunConsoleCommand("arcticvr_hybridpouch", "0")
        RunConsoleCommand("arcticvr_defpouchdist", tostring(dist))
    end

    -- 無限ポーチ
    RunConsoleCommand("arcticvr_infpouch", infinite and "1" or "0")
end

-- =============================================================================
-- ConVar変更コールバック
-- =============================================================================
EnsureConVars()

cvars.AddChangeCallback("vrmod_unoff_pouch_location", function(_, _, _)
    SyncToArcVR()
end, "unified_pouch_sync")

cvars.AddChangeCallback("vrmod_unoff_pouch_dist", function(_, _, _)
    SyncToArcVR()
end, "unified_pouch_sync_dist")

cvars.AddChangeCallback("vrmod_unoff_pouch_sync_arcvr", function(_, _, newVal)
    if newVal == "1" then
        SyncToArcVR()
    end
end, "unified_pouch_sync_toggle")

cvars.AddChangeCallback("vrmod_unoff_pouch_infinite", function(_, _, _)
    SyncToArcVR()
end, "unified_pouch_sync_inf")

-- =============================================================================
-- 公開API
-- =============================================================================

--- 統一ポーチのワールド座標と距離閾値を返す
-- @param player Player エンティティ
-- @return Vector ポーチ位置, number 距離閾値
function vrmod.pouch.GetPosition(player)
    EnsureConVars()
    if not IsValid(player) then return Vector(0, 0, 0), 16 end

    local location = cv_location:GetString()
    local dist = cv_dist:GetFloat()

    if cv_infinite:GetBool() then
        dist = 99999
    end

    local boneName = POUCH_BONES[location] or POUCH_BONES.pelvis
    local boneIndex = player:LookupBone(boneName)
    if boneIndex then
        local boneMatrix = player:GetBoneMatrix(boneIndex)
        if boneMatrix then
            local charYaw = 0
            if g_VR and g_VR.characterYaw then
                charYaw = g_VR.characterYaw
            end
            local pos = LocalToWorld(
                Vector(3, 3, 0),
                Angle(0, 0, 0),
                boneMatrix:GetTranslation(),
                Angle(0, charYaw, 0)
            )
            return pos, dist
        end
    end

    -- フォールバック: VRアイポジション
    if g_VR and g_VR.eyePosLeft then
        return g_VR.eyePosLeft, 32
    end

    return player:GetPos() + Vector(0, 0, 40), dist
end

--- 手がポーチ範囲内かを判定
-- @param player Player エンティティ
-- @param handPos Vector 手の位置
-- @return boolean ポーチ範囲内か
function vrmod.pouch.IsHandNearPouch(player, handPos)
    local pouchPos, dist = vrmod.pouch.GetPosition(player)
    return handPos:DistToSqr(pouchPos) < (dist * dist)
end

--- 現在のポーチ設定情報を返す（デバッグ/UI用）
-- @return table {location, boneName, dist, infinite, syncArcVR, arcvrInstalled}
function vrmod.pouch.GetInfo()
    EnsureConVars()
    local location = cv_location:GetString()
    return {
        location = location,
        boneName = POUCH_BONES[location] or POUCH_BONES.pelvis,
        dist = cv_dist:GetFloat(),
        infinite = cv_infinite:GetBool(),
        syncArcVR = cv_sync:GetBool(),
        arcvrInstalled = IsArcVRInstalled(),
    }
end

--- VR開始時に初期同期を実行
hook.Add("VRMod_Start", "UnifiedPouchInitSync", function()
    -- ArcVRチェックをリセット（武器ベースの遅延ロード対応）
    arcvrChecked = false
    timer.Simple(2, function()
        SyncToArcVR()
    end)
end)

--------[vrmod_unified_pouch.lua]End--------
