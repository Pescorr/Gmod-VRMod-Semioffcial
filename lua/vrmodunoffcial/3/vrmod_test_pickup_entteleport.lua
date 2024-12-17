-- クライアント側のコンソール変数を作成
AddCSLuaFile()
CreateClientConVar("vrmod_test_entteleport_range", 50, true, FCVAR_ARCHIVE, "Range to check for entities to grab")
CreateClientConVar("vrmod_pickup_weight", 100, true, FCVAR_ARCHIVE, "Max weight of entity to grab")
-- サーバー側でFindNearestEntity関数とTeleportEntityToHand関数を定義
if SERVER then
    -- utilライブラリが利用可能かどうかを確認
    if util ~= nil then
        -- ネットワークストリングを登録
        util.AddNetworkString("vrmod_test_pickup_entteleport")
        local function FindNearestEntity(ply, handPos, grabRange, maxWeight, excludeEnt)
            local nearestEnt = nil
            local nearestDist = grabRange
            for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
                if IsValid(ent) and not ent:IsPlayer() and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject():GetMass() <= maxWeight then
                    local dist = handPos:Distance(ent:GetPos())
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestEnt = ent
                    end
                end
            end

            return nearestEnt
        end

        local function TeleportEntityToHand(ply, handPos, ent, isLeftHand)
            if ent then
                -- ent:SetGravity(0.65)
                ent:SetPos(handPos)
                -- 0.08秒後にpickup関数を実行
                timer.Simple(
                    0.15,
                    function()
                        pickup(ply, isLeftHand, handPos, Angle())
                    end
                )
            end
        end

        -- ネットワークメッセージを受信した時の処理
        net.Receive(
            "vrmod_test_pickup_entteleport",
            function(len, ply)
                if not IsValid(ply) or ply:InVehicle() then return end
                local isLeftHand = net.ReadBool()
                local grabRange = net.ReadFloat()
                local maxWeight = net.ReadFloat()
                local entClass = net.ReadString()
                local handPos
                if isLeftHand then
                    handPos, _ = vrmod.GetLeftHandPose(ply)
                else
                    handPos, _ = vrmod.GetRightHandPose(ply)
                end

                local foundEnt = nil
                local otherHandEnt = g_VR[ply:SteamID()].heldItems and g_VR[ply:SteamID()].heldItems[isLeftHand and 2 or 1] and g_VR[ply:SteamID()].heldItems[isLeftHand and 2 or 1].ent
                if entClass == "" then
                    foundEnt = FindNearestEntity(ply, handPos, grabRange, maxWeight, otherHandEnt)
                else
                    for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
                        if ent:GetClass() == entClass and ent ~= otherHandEnt then
                            foundEnt = ent
                            break
                        end
                    end
                end

                TeleportEntityToHand(ply, handPos, foundEnt, isLeftHand)
            end
        )
    else
        print("util library is not available. Skipping network string registration.")
    end
end

-- クライアント側のコマンド
if CLIENT then
    -- vrmod_test_pickup_entteleport_leftの改造
    concommand.Add(
        "vrmod_test_pickup_entteleport_left",
        function(ply, cmd, args)
            if ply:InVehicle() then return end
            local grabRange = GetConVar("vrmod_test_entteleport_range"):GetFloat()
            local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
            local entClass = args[1] or ""
            net.Start("vrmod_test_pickup_entteleport")
            net.WriteBool(true) -- isLeftHand
            net.WriteFloat(grabRange)
            net.WriteFloat(maxWeight)
            net.WriteString(entClass)
            net.SendToServer()
        end
    )

    -- vrmod_test_pickup_entteleport_rightの改造
    concommand.Add(
        "vrmod_test_pickup_entteleport_right",
        function(ply, cmd, args)
            if ply:InVehicle() then return end
            local grabRange = GetConVar("vrmod_test_entteleport_range"):GetFloat()
            local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
            local entClass = args[1] or ""
            net.Start("vrmod_test_pickup_entteleport")
            net.WriteBool(false) -- isLeftHand
            net.WriteFloat(grabRange)
            net.WriteFloat(maxWeight)
            net.WriteString(entClass)
            net.SendToServer()
        end
    )
end