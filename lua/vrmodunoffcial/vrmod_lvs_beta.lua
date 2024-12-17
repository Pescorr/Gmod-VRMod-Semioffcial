if not LVS then return end


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