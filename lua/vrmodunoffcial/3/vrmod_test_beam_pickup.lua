AddCSLuaFile()
CreateClientConVar("vrmod_pickup_beamrange02", 50, true, FCVAR_ARCHIVE, "Range to check for entities to grab")
CreateClientConVar("vrmod_pickup_weight", 100, true, FCVAR_ARCHIVE, "Max weight of entity to grab")
CreateClientConVar("vrmod_pickup_beam_enable", 1, true, FCVAR_ARCHIVE, "Enable/disable the pickup beam laser")
if SERVER then
    if util ~= nil then
        util.AddNetworkString("vrmod_pickup_beam")
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
                ent:SetPos(handPos)
                ent:Activate(false)
                -- 0.08秒後にpickup関数を実行
                pickup(ply, isLeftHand, handPos, Angle())
                ent:Activate(true)
            end
        end

        -- ネットワークメッセージを受信した時の処理
        net.Receive(
            "vrmod_pickup_beam",
            function(len, ply)
                if not IsValid(ply) or ply:InVehicle() then return end
                local isLeftHand = net.ReadBool()
                local grabRange = net.ReadFloat()
                local maxWeight = net.ReadFloat()
                local entClass = net.ReadString()
                local hitPos = net.ReadVector()
                local handPos = net.ReadVector()
                local foundEnt = nil
                local otherHandEnt = g_VR[ply:SteamID()].heldItems and g_VR[ply:SteamID()].heldItems[isLeftHand and 2 or 1] and g_VR[ply:SteamID()].heldItems[isLeftHand and 2 or 1].ent
                if entClass == "" then
                    foundEnt = FindNearestEntity(ply, hitPos, grabRange, maxWeight, otherHandEnt)
                else
                    for _, ent in ipairs(ents.FindInSphere(hitPos, grabRange)) do
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
    -- クライアント側のコンソール変数を作成
    local beamrange = CreateClientConVar("vrmod_pickup_beamrange", 500, true, FCVAR_ARCHIVE, "Range to check for beam")
    -- レーザーの描画関数
    local function DrawLaser(handPos, handAng, color)
        local traceRes = util.TraceLine(
            {
                start = handPos,
                endpos = handPos + handAng:Forward() * beamrange:GetFloat(),
                filter = LocalPlayer()
            }
        )

        render.SetMaterial(Material("cable/redlaser"))
        render.StartBeam(2)
        render.AddBeam(handPos, 2, 0, color)
        render.AddBeam(traceRes.HitPos, 2, traceRes.Fraction * beamrange:GetFloat(), color)
        render.EndBeam()

        return traceRes.HitPos
    end

    -- vrmod_pickup_beam_leftの改造
    concommand.Add(
        "vrmod_pickup_beam_left",
        function(ply, cmd, args)
            if ply:InVehicle() then return end
            if not GetConVar("vrmod_pickup_beam_enable"):GetBool() then return end
            local grabRange = GetConVar("vrmod_pickup_beamrange02"):GetFloat()
            local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
            local entClass = args[1] or ""
            local leftHandPos, leftHandAng = vrmod.GetLeftHandPose(ply)
            local hitPos = DrawLaser(leftHandPos, leftHandAng, Color(255, 0, 0))
            net.Start("vrmod_pickup_beam")
            net.WriteBool(true) -- isLeftHand
            net.WriteFloat(grabRange)
            net.WriteFloat(maxWeight)
            net.WriteString(entClass)
            net.WriteVector(hitPos)
            net.WriteVector(leftHandPos) -- 追加: VR左手の位置を送信
            net.SendToServer()
        end
    )

    -- vrmod_pickup_beam_rightの改造
    concommand.Add(
        "vrmod_pickup_beam_right",
        function(ply, cmd, args)
            if ply:InVehicle() then return end
            if not GetConVar("vrmod_pickup_beam_enable"):GetBool() then return end
            local grabRange = GetConVar("vrmod_pickup_beamrange02"):GetFloat()
            local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
            local entClass = args[1] or ""
            local rightHandPos, rightHandAng = vrmod.GetRightHandPose(ply)
            local hitPos = DrawLaser(rightHandPos, rightHandAng, Color(0, 255, 0))
            net.Start("vrmod_pickup_beam")
            net.WriteBool(false) -- isLeftHand
            net.WriteFloat(grabRange)
            net.WriteFloat(maxWeight)
            net.WriteString(entClass)
            net.WriteVector(hitPos)
            net.WriteVector(rightHandPos) -- 追加: VR右手の位置を送信
            net.SendToServer()
        end
    )

    -- レーザーを描画するためのフック
    hook.Add(
        "PostDrawTranslucentRenderables",
        "vrmod_pickup_beam_laser",
        function()
            if GetConVar("vrmod_pickup_beam_enable"):GetBool() then
                local leftHandPos, leftHandAng = vrmod.GetLeftHandPose(LocalPlayer())
                local rightHandPos, rightHandAng = vrmod.GetRightHandPose(LocalPlayer())
                DrawLaser(leftHandPos, leftHandAng, Color(255, 0, 0, 255))
                DrawLaser(rightHandPos, rightHandAng, Color(0, 255, 0, 255))
            end
        end
    )
end