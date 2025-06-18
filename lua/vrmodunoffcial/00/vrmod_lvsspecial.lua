if SERVER then
    if not LVS then return end
    if not g_VR then return end
    util.AddNetworkString("lvs_setinput_special")
    net.Receive(
        "lvs_setinput_special",
        function(len, ply)
            if not IsValid(ply) then return end
            local vehicle = ply:lvsGetVehicle()
            if not IsValid(vehicle) then return end
            local actionName = net.ReadString()
            local actionValue = net.ReadBool()
            if actionName == "EXIT" and actionValue == true then
                ply:ExitVehicle()
            elseif string.StartWith(actionName, "~SELECT~WEAPON#") then
                if vehicle.lvsSetInput then
                    vehicle:lvsSetInput(actionName, true)
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
end