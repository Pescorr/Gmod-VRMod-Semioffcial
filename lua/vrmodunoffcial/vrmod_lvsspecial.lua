--------[vrmod_lvs_special.lua]Start--------
-- サーバー側: 特殊なLVS操作（降車、武器切り替え）の受信処理
if SERVER then
    if not LVS then return end
    if not g_VR then return end
    util.AddNetworkString("lvs_setinput_special") -- 特殊操作用のメッセージ
    net.Receive(
        "lvs_setinput_special",
        function(len, ply)
            if not IsValid(ply) then return end
            local vehicle = ply:lvsGetVehicle()
            if not IsValid(vehicle) then return end
            local actionName = net.ReadString()
            local actionValue = net.ReadBool() -- または ReadUInt(4) など、送信内容に合わせる
            -- 降車処理
            if actionName == "EXIT" and actionValue == true then
                ply:ExitVehicle()
                -- 武器切り替え処理
            elseif string.startsWith(actionName, "~SELECT~WEAPON#") then
                -- LVSの武器切り替え処理 (lvsSetInputを使用するか、専用の関数があるか？)
                if vehicle.lvsSetInput then
                    vehicle:lvsSetInput(actionName, true) -- 選択した武器をtrueに
                    -- 他の武器選択をfalseにする必要があるか確認
                    local weaponNum = tonumber(string.sub(actionName, -1))
                    for i = 1, 4 do
                        if i ~= weaponNum then
                            vehicle:lvsSetInput("~SELECT~WEAPON#" .. i, false)
                        end
                    end
                elseif ply.lvsSetInput then
                    ply:lvsSetInput(actionName, true)
                    local weaponNum = tonumber(string.sub(actionName, -1))
                    for i = 1, 4 do
                        if i ~= weaponNum then
                            ply:lvsSetInput("~SELECT~WEAPON#" .. i, false)
                        end
                    end
                else
                end
            end
        end
    )
    -- print("[VRMod LVS] Warning: lvsSetInput function not found for weapon selection.")
end
--------[vrmod_lvs_special.lua]End--------