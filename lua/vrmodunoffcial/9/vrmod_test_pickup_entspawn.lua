AddCSLuaFile()
-- Server-side code
if SERVER then
    util.AddNetworkString("vrmod_test_spawn_entity")
    net.Receive(
        "vrmod_test_spawn_entity",
        function(len, ply)
            local entClass = net.ReadString()
            local handPos = net.ReadVector()
            local handAng = net.ReadAngle()
            local isLeftHand = net.ReadBool()
            local spawnedEnt = ents.Create(entClass)
            if not IsValid(spawnedEnt) then return end
            -- Ensure the entity follows the hand until successfully picked up using the pickup function from vrmod_pickup.lua
            function followAndTryPickup()
                if not IsValid(spawnedEnt) then return end
                spawnedEnt:SetPos(handPos) -- Adjust this value as needed
                spawnedEnt:Spawn()

                -- spawnedEnt:SetAngles(handAng)
                -- Attempt to pick up using the pickup function from vrmod_pickup.lua
                -- if IsValid(spawnedEnt) then
                    -- Using the custom pickup function tailored for VRMod
                    pickup(ply, isLeftHand, handPos, Angle())
                    -- vrmod.Pickup(isLeftHand, not pressed)
                    -- 追従タイマーを停止するロジックをここに追加
                    timer.Remove(ply:UserID() .. "followAndTryPickup")
                -- end
            end

            -- Repeatedly try to follow and pickup until the entity is picked up or becomes invalid
            timer.Create(ply:UserID() .. "followAndTryPickup", 0.11, 0, followAndTryPickup)
        end
    )
end

-- Client-side code
if SERVER then return end
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