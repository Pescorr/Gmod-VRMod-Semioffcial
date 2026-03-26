--[[
    Module 15: Hand Sync Mode
    全武器でempty hand同等の自然な指トラッキングを実現する。
    vrthrow方式: VRMod_PreRenderで外部上書き。中核変更なし。

    問題: 武器切替時にopenHandAngles == closedHandAngles == 武器固有ポーズに
    上書きされるため、VRコントローラのfingerCurlsが無効化される
    (LerpAngle(curl, same, same) = 常に同じ値)。

    解決: VRMod_PreRenderでopenHandAngles/closedHandAnglesを
    defaultOpen/defaultClosedに復元 → 全武器でVR指追従が有効に。

    Mode 0 = Default: 従来の武器固有指ポーズ（VR指追従なし）
    Mode 1 = Natural Fingers: VR指追従あり、手の位置はviewmodelボーンから
    Mode 2 = Full Natural: VR指追従 + 手の位置はコントローラ直
]]

AddCSLuaFile()
if SERVER then return end

-- ConVar定義
local cv_mode = CreateClientConVar("vrmod_unoff_hand_sync_mode", "0", true, false,
    "Hand sync: 0=Default, 1=Natural fingers, 2=Full natural (raw controller pos)", 0, 2)

--- VRMod_PreRender: ボーン同期後、レンダリング前に発火
-- vrmod.luaのRenderScene内フロー:
--   VRMod_Tracking → ボーン同期(netFrame上書き) → VRMod_PreRender → RenderView
-- RenderView中にBuildBonePositionsが呼ばれ、openHandAngles/closedHandAnglesを参照する。
-- 武器切替でopen==closedに上書きされた角度をdefaultに復元することで
-- VRコントローラのfingerCurlsが自然に指に反映される。
local function HandSyncPreRender()
    local mode = cv_mode:GetInt()
    if mode == 0 then return end

    if not g_VR or not g_VR.active then return end
    if not g_VR.defaultOpenHandAngles or not g_VR.defaultClosedHandAngles then return end

    -- Mode 1 & 2: デフォルトの手アングルに復元 → VR指追従を有効化
    -- 武器切替時にSetRightHandOpenFingerAngles/SetRightHandClosedFingerAnglesで
    -- 上書きされた値を、毎フレームdefaultに戻す。
    -- netFrame.finger1-10は生のVRコントローラ入力のまま（触らない）。
    g_VR.openHandAngles = g_VR.defaultOpenHandAngles
    g_VR.closedHandAngles = g_VR.defaultClosedHandAngles

    -- Mode 2: 手の位置もコントローラ直接に復元
    if mode >= 2 then
        local tracking = g_VR.tracking
        if not tracking then return end

        local rh = tracking.pose_righthand
        if rh and vrmod.SetRightHandPose then
            pcall(vrmod.SetRightHandPose, rh.pos, rh.ang)
        end

        local lh = tracking.pose_lefthand
        if lh and vrmod.SetLeftHandPose then
            pcall(vrmod.SetLeftHandPose, lh.pos, lh.ang)
        end
    end
end

-- VRライフサイクル
local function OnVRStart(ply)
    if ply ~= LocalPlayer() then return end
    hook.Add("VRMod_PreRender", "vrmod_hand_sync_mode", HandSyncPreRender)
end

local function OnVRExit(ply)
    if ply ~= LocalPlayer() then return end
    hook.Remove("VRMod_PreRender", "vrmod_hand_sync_mode")
end

hook.Add("VRMod_Start", "vrmod_hand_sync_mode_start", OnVRStart)
hook.Add("VRMod_Exit", "vrmod_hand_sync_mode_exit", OnVRExit)
