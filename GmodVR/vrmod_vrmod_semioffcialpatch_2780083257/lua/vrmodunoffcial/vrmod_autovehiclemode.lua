if SERVER then 
    return 
end

hook.Add("Think", "CheckPlayerInVehicle", function()
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