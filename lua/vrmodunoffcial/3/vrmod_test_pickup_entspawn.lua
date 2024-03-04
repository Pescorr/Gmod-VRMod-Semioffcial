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

            local handPos, handAng = vrmod.GetLeftHandPose(ply)

            net.Start("vrmod_test_spawn_entity")
            net.WriteString(entClass)
            net.WriteVector(handPos)
            net.WriteAngle(handAng)
            net.WriteBool(true) -- true for left hand
            net.SendToServer()
        end
    )

    -- Right hand command
    concommand.Add(
        "vrmod_test_pickup_entspawn_right",
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

            local handPos, handAng = vrmod.GetRightHandPose(ply)

            net.Start("vrmod_test_spawn_entity")
            net.WriteString(entClass)
            net.WriteVector(handPos)
            net.WriteAngle(handAng)
            net.WriteBool(false) -- false for right hand
            net.SendToServer()
        end
    )
end

-- Server-side code
if SERVER then
    util.AddNetworkString("vrmod_test_spawn_entity")

    net.Receive("vrmod_test_spawn_entity", function(len, ply)
        local entClass = net.ReadString()
        local handPos = net.ReadVector()
        local handAng = net.ReadAngle()
        local isLeftHand = net.ReadBool()

        local spawnedEnt = ents.Create(entClass)
        if not IsValid(spawnedEnt) then return end

        spawnedEnt:SetPos(handPos)
        -- Set angles with XYZ all rotated by 90 degrees
        spawnedEnt:SetAngles(handAng + Angle(90, 90, 90))

        timer.Simple(
            0,
            function()
                pickup(ply, isLeftHand, handPos, handAng)
            end
        )
        spawnedEnt:Spawn()

        spawnedEnt:Activate()

        -- Despawn the entity after 20 seconds
        timer.Simple(20, function()
            if IsValid(spawnedEnt) then
                spawnedEnt:Remove()
            end
        end)

    end)
end
