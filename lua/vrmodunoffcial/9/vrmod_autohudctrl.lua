-- vrmod_convar_auto_controller.lua
if SERVER then return end
local CONVAR_AUTO_CONTROLLER_DEBUG = false -- デバッグメッセージの表示を切り替えるフラグ
-- デバッグメッセージを出力するヘルパー関数
local function Log(msg)
    if CONVAR_AUTO_CONTROLLER_DEBUG then
        print("[ConVarAutoCtrl] " .. msg)
    end
end

-- ConVarの元の値を保存するためのテーブル
-- originalConvars[owner][cvarName] = originalValue
local originalConvars = {}
-- ConVarの元の値を保存する関数
local function SaveOriginalConVar(cvarName, owner)
    owner = owner or "generic_owner" -- 所有者が指定されない場合のデフォルト名
    if not originalConvars[owner] then
        originalConvars[owner] = {}
    end

    -- まだ保存されていなければ
    if originalConvars[owner][cvarName] == nil then
        local convar = GetConVar(cvarName)
        if convar then
            originalConvars[owner][cvarName] = convar:GetString()
            Log("Saved original value for " .. cvarName .. " (" .. owner .. "): " .. originalConvars[owner][cvarName])
        else
            Log("Warning: Could not find ConVar '" .. cvarName .. "' to save original value.")
        end
    end
end

-- ConVarを元の値に戻す関数
local function RestoreOriginalConVar(cvarName, owner)
    owner = owner or "generic_owner"
    if originalConvars[owner] and originalConvars[owner][cvarName] ~= nil then
        local originalValue = originalConvars[owner][cvarName]
        RunConsoleCommand(cvarName, originalValue) -- ConVarを元の値に戻す
        Log("Restored original value for " .. cvarName .. " (" .. owner .. "): " .. originalValue)
        originalConvars[owner][cvarName] = nil -- 保存した値をクリアして再度保存できるようにする
    else
    end
    -- Log("Warning: No original value to restore for " .. cvarName .. " (" .. owner .. ") or already restored.")
end

-- 特定の所有者によって変更されたすべてのConVarを元の値に戻す関数
local function RestoreAllOriginalConvarsForOwner(owner)
    if originalConvars[owner] then
        Log("Restoring all ConVars for owner: " .. owner)
        for cvarName, _ in pairs(originalConvars[owner]) do
            RestoreOriginalConVar(cvarName, owner) -- 個別に復元（これによりnilクリアも行われる）
        end

        originalConvars[owner] = nil -- Ownerのテーブル自体をクリーンアップ
    end
end

-- ConVarを指定した値に変更し、元の値を保存する関数
local function SetConVarControlled(cvarName, newValue, owner)
    SaveOriginalConVar(cvarName, owner) -- まず元の値を保存
    local convar = GetConVar(cvarName)
    if convar then
        -- 現在の値と新しい値が異なる場合のみ設定
        if convar:GetString() ~= tostring(newValue) then
            RunConsoleCommand(cvarName, newValue)
            --Log("Set " .. cvarName .. " to " .. tostring(newValue) .. " (controlled by " .. owner .. ")")
        end
    else
        Log("Warning: Could not find ConVar '" .. cvarName .. "' to set controlled value.")
    end
end

--[[
    1. Quickmenu表示中のHUD変更機能
]]
local QUICKMENU_HUD_OWNER_ID = "QuickmenuHUDController"
local cv_auto_hud_on_quickmenu = CreateClientConVar("vrmod_auto_hud_on_quickmenu", "1", true, FCVAR_ARCHIVE, "0: Disable, 1: Enable auto HUD control when quickmenu/weaponmenu is open")
local isQuickmenuHudActive = false -- この機能によってHUDが変更されたかを示すフラグ
local function UpdateQuickmenuHUD()
    if not cv_auto_hud_on_quickmenu:GetBool() then
        if isQuickmenuHudActive then
            RestoreAllOriginalConvarsForOwner(QUICKMENU_HUD_OWNER_ID)
            isQuickmenuHudActive = false
        end

        return
    end

    local quickMenuIsOpen = VRUtilIsMenuOpen("miscmenu") or VRUtilIsMenuOpen("weaponmenu")
    if quickMenuIsOpen then
        if not isQuickmenuHudActive then
            Log("Quickmenu/Weaponmenu opened, controlling HUDs.")
            SetConVarControlled("vrmod_left_hud_enabled", "0", QUICKMENU_HUD_OWNER_ID)
            SetConVarControlled("vrmod_right_hud_enabled", "0", QUICKMENU_HUD_OWNER_ID)
            SetConVarControlled("vrmod_hud", "1", QUICKMENU_HUD_OWNER_ID)
            isQuickmenuHudActive = true
        end
    else
        if isQuickmenuHudActive then
            Log("Quickmenu/Weaponmenu closed, restoring HUDs.")
            SetConVarControlled("vrmod_hud", "0", HOLSTER_HUD_OWNER_ID)
            SetConVarControlled("vrmod_left_hud_enabled", "1", HOLSTER_HUD_OWNER_ID)
            SetConVarControlled("vrmod_right_hud_enabled", "1", HOLSTER_HUD_OWNER_ID)
            --RestoreAllOriginalConvarsForOwner(QUICKMENU_HUD_OWNER_ID)
            isQuickmenuHudActive = false
        end
    end
end

--[[
    2. ホルスター範囲内のHUD変更機能
]]
local HOLSTER_HUD_OWNER_ID = "HolsterHUDController"
local cv_auto_hud_in_holster_range = CreateClientConVar("vrmod_auto_hud_in_holster_range", "0", true, FCVAR_ARCHIVE, "0: Disable, 1: Enable auto HUD control when hand is in holster range")
local isHolsterHudActive = false -- この機能によってHUDが変更されたかを示すフラグ
local wasHandInHolster = false -- 前回のフレームで手がホルスター範囲内にあったか
local function IsHandNearHolster()
    if not g_VR or not g_VR.tracking or not g_VR.tracking.pose_lefthand or not g_VR.tracking.pose_righthand then return false end
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end
    local handPositions = {
        left = g_VR.tracking.pose_lefthand.pos,
        right = g_VR.tracking.pose_righthand.pos
    }

    local holsters = {
        -- Right Hand Holsters (checked against both hands)
        {
            side = "right",
            type = "Pelvis",
            enabled_cvar = "vrmod_weppouch_Pelvis",
            bone = "ValveBiped.Bip01_Pelvis",
            size_cvar = "vrmod_weppouch_dist_Pelvis",
            offset = Vector(2, 2, 0)
        },
        {
            side = "right",
            type = "Head",
            enabled_cvar = "vrmod_weppouch_Head",
            bone_type = "head",
            size_cvar = "vrmod_weppouch_dist_head",
            offset = Vector(2, 2, 0)
        },
        {
            side = "right",
            type = "Spine",
            enabled_cvar = "vrmod_weppouch_Spine",
            bone = "ValveBiped.Bip01_Neck1",
            size_cvar = "vrmod_weppouch_dist_spine",
            offset = Vector(2, 2, 0)
        },
        -- Left Hand Holsters (checked against both hands)
        {
            side = "left",
            type = "Pelvis",
            enabled_cvar = "vrmod_weppouch_left_Pelvis",
            bone = "ValveBiped.Bip01_Pelvis",
            size_cvar = "vrmod_weppouch_left_dist_Pelvis",
            offset = Vector(2, -2, 0)
        },
        {
            side = "left",
            type = "Head",
            enabled_cvar = "vrmod_weppouch_left_Head",
            bone_type = "head",
            size_cvar = "vrmod_weppouch_left_dist_head",
            offset = Vector(2, -2, 0)
        },
        {
            side = "left",
            type = "Spine",
            enabled_cvar = "vrmod_weppouch_left_Spine",
            bone = "ValveBiped.Bip01_Neck1",
            size_cvar = "vrmod_weppouch_left_dist_spine",
            offset = Vector(2, -2, 0)
        }
    }

    for handName, handPos in pairs(handPositions) do
        if not handPos then continue end
        for _, holster in ipairs(holsters) do
            local enableCVar = GetConVar(holster.enabled_cvar)
            if enableCVar and enableCVar:GetBool() then
                local holsterWorldPos
                local characterYaw = g_VR.characterYaw or (ply:EyeAngles() and ply:EyeAngles().y or 0)
                if holster.bone_type == "head" then
                    local headVisibleCvar = GetConVar("vrmod_head_visible")
                    if headVisibleCvar and headVisibleCvar:GetBool() and ply:LookupBone("ValveBiped.Bip01_Head1") then
                        local headBoneMatrix = ply:GetBoneMatrix(ply:LookupBone("ValveBiped.Bip01_Head1"))
                        if headBoneMatrix then
                            holsterWorldPos = LocalToWorld(holster.offset, Angle(0, 0, 0), headBoneMatrix:GetTranslation(), Angle(0, characterYaw, 0))
                        end
                    elseif g_VR.tracking.hmd then
                        holsterWorldPos = g_VR.tracking.hmd.pos + Angle(0, characterYaw, 0):Forward() * holster.offset.x + Angle(0, characterYaw, 0):Right() * holster.offset.y + Vector(0, 0, holster.offset.z + 10)
                    end
                elseif holster.bone and ply:LookupBone(holster.bone) then
                    local boneMatrix = ply:GetBoneMatrix(ply:LookupBone(holster.bone))
                    if boneMatrix then
                        holsterWorldPos = LocalToWorld(holster.offset, Angle(0, 0, 0), boneMatrix:GetTranslation(), Angle(0, characterYaw, 0))
                    end
                end

                if holsterWorldPos then
                    local sizeCVar = GetConVar(holster.size_cvar)
                    if sizeCVar then
                        local range = sizeCVar:GetFloat()
                        if handPos:DistToSqr(holsterWorldPos) < (range * range) then return true end
                    end
                end
            end
        end
    end

    return false
end

local function UpdateHolsterHUD()
    if not cv_auto_hud_in_holster_range:GetBool() then
        if isHolsterHudActive then
            RestoreAllOriginalConvarsForOwner(HOLSTER_HUD_OWNER_ID)
            isHolsterHudActive = false
            wasHandInHolster = false
        end

        return
    end

    local handIsCurrentlyInHolster = IsHandNearHolster()
    if handIsCurrentlyInHolster ~= wasHandInHolster then
        if handIsCurrentlyInHolster then
            if not isHolsterHudActive then
                Log("Hand entered holster range, controlling HUDs.")
                SetConVarControlled("vrmod_left_hud_enabled", "0", HOLSTER_HUD_OWNER_ID)
                SetConVarControlled("vrmod_right_hud_enabled", "0", HOLSTER_HUD_OWNER_ID)
                SetConVarControlled("vrmod_hud", "1", HOLSTER_HUD_OWNER_ID)
                isHolsterHudActive = true
            end
        else
            if isHolsterHudActive then
                Log("Hand left holster range, restoring HUDs.")
                SetConVarControlled("vrmod_hud", "0", HOLSTER_HUD_OWNER_ID)
                SetConVarControlled("vrmod_left_hud_enabled", "1", HOLSTER_HUD_OWNER_ID)
                SetConVarControlled("vrmod_right_hud_enabled", "1", HOLSTER_HUD_OWNER_ID)
                --RestoreAllOriginalConvarsForOwner(HOLSTER_HUD_OWNER_ID)
                isHolsterHudActive = false
            end
        end

        wasHandInHolster = handIsCurrentlyInHolster
    end
end

--[[
    3. 特定UI表示中のカメラオーバーライド変更機能
]]
local SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID = "SpecificMenuCameraOverrideController"
local cv_auto_camoverride_target_uids = CreateClientConVar("vrmod_auto_cameraoverride_target_uids", "dummymenu,heightmenu", true, FCVAR_ARCHIVE, "Comma-separated UIDs of menus to disable camera override for.")
local cv_auto_camoverride_for_specific_menu = CreateClientConVar("vrmod_auto_cameraoverride_for_specific_menu", "1", true, FCVAR_ARCHIVE, "0: Disable, 1: Enable auto camera override for specific menus")
local isSpecificMenuCamOverrideActive = false
local wasTargetMenuOpen = false
local targetMenuUIDsList = {}
local function ParseTargetMenuUIDs()
    targetMenuUIDsList = {}
    local uidsString = cv_auto_camoverride_target_uids:GetString()
    if uidsString and uidsString ~= "" then
        for uid in string.gmatch(uidsString, "[^,]+") do
            uid = string.Trim(uid)
            if uid ~= "" then
                table.insert(targetMenuUIDsList, uid)
            end
        end
    end

    Log("Target Menu UIDs for camera override: " .. table.concat(targetMenuUIDsList, ", "))
end

cvars.AddChangeCallback("vrmod_auto_cameraoverride_target_uids", ParseTargetMenuUIDs, "ConVarAutoCtrl_ParseUIDs")
ParseTargetMenuUIDs()
local function IsAnyTargetMenuCurrentlyOpen()
    if #targetMenuUIDsList == 0 then return false end
    for _, uid in ipairs(targetMenuUIDsList) do
        if VRUtilIsMenuOpen(uid) then return true end
    end

    return false
end

local function UpdateSpecificMenuCameraOverride()
    if not cv_auto_camoverride_for_specific_menu:GetBool() then
        if isSpecificMenuCamOverrideActive then
            RestoreOriginalConVar("vrmod_cameraoverride", SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID)
            isSpecificMenuCamOverrideActive = false
            wasTargetMenuOpen = false
        end

        return
    end

    if #targetMenuUIDsList == 0 then
        if isSpecificMenuCamOverrideActive then
            RestoreOriginalConVar("vrmod_cameraoverride", SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID)
            isSpecificMenuCamOverrideActive = false
            wasTargetMenuOpen = false
        end

        return
    end

    local targetMenuIsCurrentlyOpen = IsAnyTargetMenuCurrentlyOpen()
    if targetMenuIsCurrentlyOpen ~= wasTargetMenuOpen then
        if targetMenuIsCurrentlyOpen then
            if not isSpecificMenuCamOverrideActive then
                Log("Target menu opened, setting vrmod_cameraoverride to 0.")
                SetConVarControlled("vrmod_cameraoverride", "0", SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID)
                isSpecificMenuCamOverrideActive = true
            end
        else
            if isSpecificMenuCamOverrideActive then
                Log("Target menu closed, restoring vrmod_cameraoverride.")
                RestoreOriginalConVar("vrmod_cameraoverride", SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID)
                isSpecificMenuCamOverrideActive = false
            end
        end

        wasTargetMenuOpen = targetMenuIsCurrentlyOpen
    end
end

-- Main Thinkフック
local function ConVarAutoController_Think()
    if not g_VR or not g_VR.active then
        if isQuickmenuHudActive then
            RestoreAllOriginalConvarsForOwner(QUICKMENU_HUD_OWNER_ID)
            isQuickmenuHudActive = false
        end

        if isHolsterHudActive then
            RestoreAllOriginalConvarsForOwner(HOLSTER_HUD_OWNER_ID)
            isHolsterHudActive = false
            wasHandInHolster = false
        end

        if isSpecificMenuCamOverrideActive then
            RestoreOriginalConVar("vrmod_cameraoverride", SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID)
            isSpecificMenuCamOverrideActive = false
            wasTargetMenuOpen = false
        end

        return
    end

    UpdateQuickmenuHUD()
    UpdateHolsterHUD()
    UpdateSpecificMenuCameraOverride()
end

hook.Add("Think", "ConVarAutoController_MasterThink", ConVarAutoController_Think)
-- VRMod_Trackingフック
hook.Add(
    "VRMod_Tracking",
    "ConVarAutoController_HolsterUpdateTracking",
    function()
        if not g_VR or not g_VR.active then return end
        if cv_auto_hud_in_holster_range:GetBool() then
            UpdateHolsterHUD()
        end
    end
)

-- VR終了時に全てのConVarを復元する
hook.Add(
    "VRMod_Exit",
    "ConVarAutoController_CleanupOnExit",
    function(ply)
        if ply ~= LocalPlayer() then return end
        Log("VRMod_Exit called. Restoring all controlled ConVars.")
        RestoreAllOriginalConvarsForOwner(QUICKMENU_HUD_OWNER_ID)
        RestoreAllOriginalConvarsForOwner(HOLSTER_HUD_OWNER_ID)
        RestoreOriginalConVar("vrmod_cameraoverride", SPECIFIC_MENU_CAM_OVERRIDE_OWNER_ID)
        isQuickmenuHudActive = false
        isHolsterHudActive = false
        wasHandInHolster = false
        isSpecificMenuCamOverrideActive = false
        wasTargetMenuOpen = false
    end
)

Log("VRMod ConVar Auto Controller Initialized.")
-- メニューオプションの追加