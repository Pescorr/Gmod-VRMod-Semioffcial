--------[vrmod_lvs_beta.lua]Start--------
-- vrmod_lvs_beta.luaは同じ (サーバー側の処理は変更なし) --
if SERVER then
    if not LVS then return end
    if not g_VR then return end
    function vrmod_lvs_server_multiplay()
        util.AddNetworkString("lvs_setinput_batch") -- 通常操作用のバッチメッセージ
        net.Receive(
            "lvs_setinput_batch",
            function(len, ply)
                if not IsValid(ply) then return end
                local vehicle = ply:lvsGetVehicle()
                if not IsValid(vehicle) then return end
                local receivedStates = net.ReadTable()
                if not receivedStates then return end
                -- 受信した状態を適用 (EXIT と SELECT_WEAPON は除く)
                for inputName, inputValue in pairs(receivedStates) do
                    if inputName ~= "EXIT" and not string.startsWith(inputName, "~SELECT~WEAPON#") then
                        -- LVSの入力処理関数 (実際の関数名は要確認)
                        if vehicle.lvsSetInput then
                            vehicle:lvsSetInput(inputName, inputValue)
                        elseif ply.lvsSetInput then
                            ply:lvsSetInput(inputName, inputValue)
                        else
                        end
                    end
                end
            end
        )
    end

    function vrmod_lvs_server_singleplay()
        util.AddNetworkString("lvs_setinput")
        -- ネットワークメッセージを受け取る
        net.Receive(
            "lvs_setinput",
            function(len, ply)
                local inputName = net.ReadString()
                local inputValue = net.ReadBool()
                if IsValid(ply) then
                    local vehicle = ply:lvsGetVehicle()
                    ply:lvsSetInput(inputName, inputValue)
                    if inputName == "EXIT" and inputValue == true then
                        ply:ExitVehicle()
                    end
                end
            end
        )
    end

    vrmod_lvs_server_multiplay()
    vrmod_lvs_server_singleplay()
end
--------[vrmod_lvs_beta.lua]End--------