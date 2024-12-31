-- -- ArcCW VR Scope Override
-- -- このスクリプトはArcCWのスコープ描画をVR用に修正します

-- local SCOPE_RT_SIZE = 2048 -- RTの解像度を大きく設定

-- if CLIENT then
--     -- RTとマテリアルを事前に作成
--     local rtLeft = GetRenderTarget("arccw_scope_rt_left", SCOPE_RT_SIZE, SCOPE_RT_SIZE)
--     local rtRight = GetRenderTarget("arccw_scope_rt_right", SCOPE_RT_SIZE, SCOPE_RT_SIZE)
    
--     local matLeft = CreateMaterial("arccw_scope_mat_left", "UnlitGeneric", {
--         ["$basetexture"] = rtLeft:GetName(),
--         ["$ignorez"] = 1
--     })
    
--     local matRight = CreateMaterial("arccw_scope_mat_right", "UnlitGeneric", {
--         ["$basetexture"] = rtRight:GetName(),
--         ["$ignorez"] = 1
--     })

--     -- スコープの描画をオーバーライド
--     local function VR_RenderScope(wep, rt, origin, angles, fov)
--         if not IsValid(wep) then return end
        
--         local scrW, scrH = SCOPE_RT_SIZE, SCOPE_RT_SIZE
--         local sight = wep:GetActiveSights()
        
--         -- スコープの設定を取得
--         local magnification = sight.ScopeMagnification or 1
--         local scopefov = math.deg(math.atan(1 / magnification))
        
--         render.PushRenderTarget(rt)
--         render.Clear(0, 0, 0, 255, true, true)
        
--         -- カメラ設定
--         local view = {
--             x = 0,
--             y = 0,
--             w = scrW,
--             h = scrH,
--             origin = origin,
--             angles = angles,
--             fov = scopefov,
--             drawviewmodel = false,
--             dopostprocess = false
--         }
        
--         -- レンダリング
--         render.RenderView(view)
        
--         -- スコープのオーバーレイを描画
--         cam.Start2D()
--             if sight.Scope_Reticle then
--                 surface.SetDrawColor(255, 255, 255, 255)
--                 surface.SetMaterial(sight.Scope_Reticle)
--                 surface.DrawTexturedRect(0, 0, scrW, scrH)
--             end
--         cam.End2D()
        
--         render.PopRenderTarget()
--     end

--     -- フックを設定してArcCWのスコープ処理をオーバーライド
--     hook.Add("PreRender", "ArcCW_VR_ScopeOverride", function()
--         if not g_VR.active then return end
        
--         local ply = LocalPlayer()
--         local wep = ply:GetActiveWeapon()
        
--         if not IsValid(wep) or not wep.ArcCW or not wep:GetSightDelta() > 0.7 then return end
        
--         -- 左目用のスコープを描画
--         VR_RenderScope(
--             wep,
--             rtLeft,
--             g_VR.eyePosLeft,
--             g_VR.tracking.hmd.ang,
--             g_VR.view.fov
--         )
        
--         -- 右目用のスコープを描画
--         VR_RenderScope(
--             wep,
--             rtRight,
--             g_VR.eyePosRight,
--             g_VR.tracking.hmd.ang,
--             g_VR.view.fov
--         )
--     end)

--     -- ArcCWのスコープ描画をフック
--     hook.Add("PostDrawTranslucentRenderables", "ArcCW_VR_ScopeDisplay", function(bDrawingDepth, bDrawingSkybox)
--         if bDrawingDepth or bDrawingSkybox or not g_VR.active then return end
        
--         local ply = LocalPlayer()
--         local wep = ply:GetActiveWeapon()
        
--         if not IsValid(wep) or not wep.ArcCW or not wep:GetSightDelta() > 0.7 then return end
        
--         local sight = wep:GetActiveSights()
--         if not sight then return end
        
--         -- スコープの位置を計算
--         local pos = wep:GetOwner():EyePos()
--         local ang = wep:GetOwner():EyeAngles()
        
--         -- 左目用スコープを描画
--         cam.Start3D2D(pos + ang:Right() * -3, ang, 0.05)
--             surface.SetMaterial(matLeft)
--             surface.SetDrawColor(255, 255, 255, 255)
--             surface.DrawTexturedRect(-50, -50, 100, 100)
--         cam.End3D2D()
        
--         -- 右目用スコープを描画
--         cam.Start3D2D(pos + ang:Right() * 3, ang, 0.05)
--             surface.SetMaterial(matRight)
--             surface.SetDrawColor(255, 255, 255, 255)
--             surface.DrawTexturedRect(-50, -50, 100, 100)
--         cam.End3D2D()
--     end)

--     -- VRモード開始時の設定
--     hook.Add("VRMod_Start", "ArcCW_VR_Init", function()
--         -- スコープのブラーを無効化
--         RunConsoleCommand("arccw_blur", "0")
--         RunConsoleCommand("arccw_blur_toytown", "0")
--         RunConsoleCommand("arccw_cheapscopes", "1")
        
--         -- その他の最適化設定
--         RunConsoleCommand("arccw_vm_fov", tostring(GetConVar("fov_desired"):GetFloat()))
--         RunConsoleCommand("arccw_vm_sway_mult", "0")
--     end)
-- end

-- -- ArcCWの元の関数をオーバーライド
-- hook.Add("InitPostEntity", "ArcCW_VR_Override", function()
--     if ArcCW then
--         -- スコープ関連の関数をオーバーライド
--         local oldDrawScopeStuff = ArcCW.DrawScopeStuff
--         ArcCW.DrawScopeStuff = function(...)
--             if g_VR and g_VR.active then return end
--             return oldDrawScopeStuff(...)
--         end
--     end
-- end)