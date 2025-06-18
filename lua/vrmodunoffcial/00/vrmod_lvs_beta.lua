if SERVER then
    if not LVS then return end
    if not g_VR then return end
    local lvssingle = CreateClientConVar("vrmod_lvs_input_mode", "0", true, FCVAR_ARCHIVE, "Enable LVS single player mode for VRMod.")
    function vrmod_lvs_server_multiplay()
        util.AddNetworkString("lvs_setinput_batch")
        net.Receive(
            "lvs_setinput_batch",
            function(len, ply)
                if not IsValid(ply) then return end
                local vehicle = ply:lvsGetVehicle()
                if not IsValid(vehicle) then return end
                local receivedStates = net.ReadTable()
                if not receivedStates then return end
                for inputName, inputValue in pairs(receivedStates) do
                    if inputName ~= "EXIT" and not string.StartWith(inputName, "~SELECT~WEAPON#") then
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

    if lvssingle:GetBool() == false then
        vrmod_lvs_server_singleplay()
    else
        vrmod_lvs_server_multiplay()
    end
end