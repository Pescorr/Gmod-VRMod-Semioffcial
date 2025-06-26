if SERVER then
    if not LVS then return end
    if not g_VR then return end
    util.AddNetworkString("lvs_setinput_batch")
    util.AddNetworkString("lvs_setinput")
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

    net.Receive(
        "lvs_setinput",
        function(len, ply)
            local inputName = net.ReadString()
            local inputValue = net.ReadBool()
            if IsValid(ply) then
                local vehicle = ply:lvsGetVehicle()
                if vehicle and vehicle.lvsSetInput then
                    vehicle:lvsSetInput(inputName, inputValue)
                elseif ply.lvsSetInput then
                    ply:lvsSetInput(inputName, inputValue)
                end
                if inputName == "EXIT" and inputValue == true then
                    ply:ExitVehicle()
                end
            end
        end
    )
end