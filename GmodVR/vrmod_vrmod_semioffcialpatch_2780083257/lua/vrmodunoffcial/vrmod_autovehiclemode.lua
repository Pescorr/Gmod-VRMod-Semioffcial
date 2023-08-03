if CLIENT then

    hook.Add("VRMod_EnterVehicle","CheckPlayerInVehicle",function()
        local ply = LocalPlayer() -- 自分自身のプレイヤーオブジェクトを取得

        if ply:InVehicle() then -- プレイヤーが車両に乗っているか確認
            local vehicle = ply:GetVehicle() -- プレイヤーが乗っている車両を取得

            if vehicle:GetClass() == "LFSVehicleClassName" then -- 車両がLFS車両かどうか確認
                RunConsoleCommand("vrmod_vehicle_reticlemode", "1") -- コンソールコマンドを実行
            end
            if vehicle:GetClass():find("gmod_sent_vehicle_fphysics_base") then -- 車両がSimfphys車両かどうか確認
                RunConsoleCommand("vrmod_vehicle_reticlemode", "0") -- コンソールコマンドを実行
            end

        end
    end)


    -- hook.Add("Think","Checkdermablur",function()

    --     hook.Add("HUDPaint", "OverrideBlur", function()
    --         -- 何もしない
    --     end)

    --     local panel = vgui.GetControlTable("DFrame") -- または適切なDermaコントロール
    --     panel.Paint = function(self, w, h)
    --         -- 何もしないか、異なる背景を描画
    --     end

    --     hook.Add("RenderScreenspaceEffects", "OverridePostProcess", function()
    --         DrawSharpen(0, 0) -- すべてのぼかし効果を取り除く
    --     end)


    -- end)
end