-- 新しいConVarの作成
CreateClientConVar("vrmod_test_entteleport_range", 50, true, FCVAR_ARCHIVE, "Range to check for entities to grab")
CreateClientConVar("vrmod_pickup_weight", 100, true, FCVAR_ARCHIVE, "Max weight of entity to grab")
local function FindNearestEntity(handPos, grabRange, maxWeight, excludeEnt)
    local nearestEnt = nil
    local nearestDist = grabRange
    for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
        if IsValid(ent) and not ent:IsPlayer() and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject():GetMass() <= maxWeight and ent ~= excludeEnt then
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
        -- 0.06秒後にpickup関数を実行
        timer.Simple(
            0.06,
            function()
                pickup(ply, isLeftHand, handPos, Angle())
            end
        )

        ent:Activate(true)
        -- else
        --     ply:ChatPrint("指定された範囲内に条件を満たすエンティティが見つかりませんでした。")
    end
end

-- vrmod_test_pickup_entteleport_leftの改造
concommand.Add(
    "vrmod_test_pickup_entteleport_left",
    function(ply, cmd, args)
        if ply:InVehicle() then return end -- ply:ChatPrint("車両内では使用できません。")
        local grabRange = GetConVar("vrmod_test_entteleport_range"):GetFloat()
        local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
        local handPos, _ = vrmod.GetLeftHandPose(ply)
        local entClass = args[1]
        local foundEnt = nil
        local rightHandEnt = g_VR[ply:SteamID()].heldItems and g_VR[ply:SteamID()].heldItems[2] and g_VR[ply:SteamID()].heldItems[2].ent
        if not entClass or entClass == "" then
            foundEnt = FindNearestEntity(handPos, grabRange, maxWeight, rightHandEnt)
        else
            for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
                if ent:GetClass() == entClass and ent ~= rightHandEnt then
                    foundEnt = ent
                    break
                end
            end
        end

        TeleportEntityToHand(ply, handPos, foundEnt, true) -- trueは左手用
    end
)

-- vrmod_test_pickup_entteleport_rightの改造
concommand.Add(
    "vrmod_test_pickup_entteleport_right",
    function(ply, cmd, args)
        if ply:InVehicle() then return end -- ply:ChatPrint("車両内では使用できません。")
        local grabRange = GetConVar("vrmod_test_entteleport_range"):GetFloat()
        local maxWeight = GetConVar("vrmod_pickup_weight"):GetFloat()
        local handPos, _ = vrmod.GetRightHandPose(ply)
        local entClass = args[1]
        local foundEnt = nil
        local leftHandEnt = g_VR[ply:SteamID()].heldItems and g_VR[ply:SteamID()].heldItems[1] and g_VR[ply:SteamID()].heldItems[1].ent
        if not entClass or entClass == "" then
            foundEnt = FindNearestEntity(handPos, grabRange, maxWeight, leftHandEnt)
        else
            for _, ent in ipairs(ents.FindInSphere(handPos, grabRange)) do
                if ent:GetClass() == entClass and ent ~= leftHandEnt then
                    foundEnt = ent
                    break
                end
            end
        end

        TeleportEntityToHand(ply, handPos, foundEnt, false) -- falseは右手用
    end
)