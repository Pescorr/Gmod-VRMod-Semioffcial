-- -- VRMod側修正ファイル：lua/vrmod/arc9_compat.lua

-- hook.Add("ARC9_PreRenderScope", "VRMod_Compatibility", function(wep)
--     -- スコープ用レンダーターゲットのVR対応
--     if VR.IsEnabled() then
--         wep.ScopeRT = GetRenderTarget("ARC9_VRScopeRT_" .. wep:EntIndex(), 2048, 2048)
--         render.PushRenderTarget(wep.ScopeRT)
--         render.Clear(0, 0, 0, 255, true, true)
--         render.PopRenderTarget()
--     end
-- end)

-- hook.Add("ARC9_AdjustCamera", "VRMod_ViewFix", function(wep, vm, oldpos, oldang, pos, ang)
--     -- VRカメラパラメータ調整
--     if VR.IsEnabled() then
--         cam.Start3D(nil, nil, VR.Config.FOV, 0, 0, VR.Config.LeftEye.w, VR.Config.LeftEye.h)
--         cam.Start3D2D(pos, ang, 1)
--         return true
--     end
-- end)

-- -- HUD表示切り替え
-- hook.Add("ARC9_ShouldDrawHUD", "VRMod_HUDOverride", function(wep)
--     return !VR.IsEnabled()
-- end)
