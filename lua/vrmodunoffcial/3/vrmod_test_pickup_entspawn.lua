-- Client-side code
if CLIENT then
    concommand.Add(
        "vrmod_test_pickup_entspawn_left",
        function(ply, cmd, args)
            if ply:InVehicle() then
                ply:ChatPrint("車両内では使用できません。")
                return
            end

            local entClass = args[1] -- Entity class from command argument
            if not entClass or entClass == "" then
                ply:ChatPrint("エンティティクラスを指定してください。")
                return
            end

            local handPos, _ = vrmod.GetLeftHandPose(ply)

            net.Start("vrmod_test_spawn_entity")
            net.WriteString(entClass)
            net.WriteVector(handPos)
            net.WriteBool(true) -- true for left hand
            net.SendToServer()
        end
    )
    -- Similar setup for right hand command...
end

-- Server-side code
if SERVER then
    util.AddNetworkString("vrmod_test_spawn_entity")

    net.Receive("vrmod_test_spawn_entity", function(len, ply)
        local entClass = net.ReadString()
        local handPos = net.ReadVector()
        local isLeftHand = net.ReadBool()

        local spawnedEnt = ents.Create(entClass)
        if not IsValid(spawnedEnt) then return end

        spawnedEnt:SetPos(handPos)
        spawnedEnt:Spawn()
        spawnedEnt:SetPos(handPos)
        spawnedEnt:Activate()

        pickup(ply, isLeftHand, handPos, Angle())
    end)
end
