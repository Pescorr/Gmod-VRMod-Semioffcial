if not Glide then return end

 

util.AddNetworkString("glide_vrsetinput")
net.Receive(
    "glide_vrsetinput",
    function(len, ply)
        local action = net.ReadString()
        local state = net.ReadBool()
        local vehicle = ply:GetNWEntity("GlideVehicle")
        if IsValid(vehicle) then
            local seatIndex = ply:GetNWInt("GlideSeatIndex", 1)
            if vehicle.SetInputBool then
                vehicle:SetInputBool(seatIndex, action, state)
            end
        end
    end
)