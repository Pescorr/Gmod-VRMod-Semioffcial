-- クライアント側のコンソール変数を作成
AddCSLuaFile()
CreateClientConVar("vrmelee_ragdollpickup_range", 25, true, FCVAR_ARCHIVE, "Range to check for entities to grab")
CreateClientConVar("vrmod_pickup_weight", 100, true, FCVAR_ARCHIVE, "Max weight of entity to grab")
-- サーバー側でFindNearestEntity関数とTeleportEntityToHand関数を定義
if SERVER then
    -- utilライブラリが利用可能かどうかを確認
    if util ~= nil then
        util.AddNetworkString("vrmelee_ragdollpickup")
        local function FindNearestRagdoll(ply, handPos, grabRange)
            local nearestRagdoll = nil
            local nearestDist = grabRange
            for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
                if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
                    local dist = handPos:Distance(ent:GetPos())
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestRagdoll = ent
                    end
                end
            end

            return nearestRagdoll
        end

        local function AttachRagdollToHand(ply, ragdoll, isLeftHand)
            if not IsValid(ragdoll) or not ragdoll:IsRagdoll() then return end
            local headBone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
            if not headBone then return end
            local handEnt = isLeftHand and ply:GetNWEntity("LeftHandEntity") or ply:GetNWEntity("RightHandEntity")
            if not IsValid(handEnt) then
                handEnt = ents.Create("prop_physics")
                handEnt:SetModel("models/props_junk/PopCan01a.mdl")
                handEnt:SetNoDraw(true)
                handEnt:SetPos(ply:GetPos())
                handEnt:SetParent(ply)
                handEnt:Spawn()
                if isLeftHand then
                    ply:SetNWEntity("LeftHandEntity", handEnt)
                else
                    ply:SetNWEntity("RightHandEntity", handEnt)
                end
            end

            constraint.NoCollide(ragdoll, handEnt, 0, headBone)
            local physObj = ragdoll:GetPhysicsObjectNum(headBone)
            if IsValid(physObj) then
                -- physObj:EnableMotion(false)
            end

            ragdoll:SetNWEntity(isLeftHand and "LeftHandAttachment" or "RightHandAttachment", handEnt)
        end

        net.Receive(
            "vrmelee_ragdollpickup",
            function(len, ply)
                if not IsValid(ply) or ply:InVehicle() then return end
                local isLeftHand = net.ReadBool()
                local grabRange = net.ReadFloat()
                local handPos
                if isLeftHand then
                    handPos, _ = vrmod.GetLeftHandPose(ply)
                else
                    handPos, _ = vrmod.GetRightHandPose(ply)
                end

                local ragdoll = FindNearestRagdoll(ply, handPos, grabRange)
                if ragdoll then
                    AttachRagdollToHand(ply, ragdoll, isLeftHand)
                end
            end
        )

        hook.Add(
            "Think",
            "UpdateRagdollHandPosition",
            function()
                for _, ply in ipairs(player.GetAll()) do
                    if vrmod.IsPlayerInVR(ply) then
                        local leftHandEnt = ply:GetNWEntity("LeftHandEntity")
                        local rightHandEnt = ply:GetNWEntity("RightHandEntity")
                        if IsValid(leftHandEnt) then
                            local pos, ang = vrmod.GetLeftHandPose(ply)
                            leftHandEnt:SetPos(pos)
                            leftHandEnt:SetAngles(ang)
                        end

                        if IsValid(rightHandEnt) then
                            local pos, ang = vrmod.GetRightHandPose(ply)
                            rightHandEnt:SetPos(pos)
                            rightHandEnt:SetAngles(ang)
                        end
                    end
                end
            end
        )
    else
        print("util library is not available. Skipping network string registration.")
    end
end

-- クライアント側のコマンド
if CLIENT then
    -- vrmelee_ragdollpickup_leftの改造
    concommand.Add(
        "vrmelee_ragdollpickup_left",
        function(ply, cmd, args)
            if ply:InVehicle() then return end
            local grabRange = GetConVar("vrmelee_ragdollpickup_range"):GetFloat()
            local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
            local entClass = args[1] or ""
            net.Start("vrmelee_ragdollpickup")
            net.WriteBool(true) -- isLeftHand
            net.WriteFloat(grabRange)
            net.WriteFloat(maxWeight)
            net.WriteString(entClass)
            net.SendToServer()
        end
    )

    -- vrmelee_ragdollpickup_rightの改造
    concommand.Add(
        "vrmelee_ragdollpickup_right",
        function(ply, cmd, args)
            if ply:InVehicle() then return end
            local grabRange = GetConVar("vrmelee_ragdollpickup_range"):GetFloat()
            local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
            local entClass = args[1] or ""
            net.Start("vrmelee_ragdollpickup")
            net.WriteBool(false) -- isLeftHand
            net.WriteFloat(grabRange)
            net.WriteFloat(maxWeight)
            net.WriteString(entClass)
            net.SendToServer()
        end
    )
end