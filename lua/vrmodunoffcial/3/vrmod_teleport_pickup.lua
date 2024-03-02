
concommand.Add("vrmod_test_pickup_nearest_left", function(ply)
    local plyPos = ply:GetPos()

    -- プレイヤーの周囲のエンティティを検索し、最も近いものを見つける
    local nearestEnt = nil
    local nearestDist = math.huge
    for _, ent in ipairs(ents.GetAll()) do
        if ent:IsValid() and ent:GetPos():DistToSqr(plyPos) < nearestDist then
            if not IsValid(ent) or not IsValid(ent:GetPhysicsObject()) or ent == ply or ply:InVehicle() or (ent.CPPICanPickup ~= nil and not ent:CPPICanPickup(ply)) then continue end
            
            nearestDist = ent:GetPos():DistToSqr(plyPos)
            nearestEnt = ent    
        end
    end

    
    if not IsValid(nearestEnt) then
        ply:ChatPrint("近くにエンティティが見つかりませんでした。")
        return
    end

    -- 手の位置と角度を取得
    local bLeftHand = true
    local handPos, handAng = vrmod.GetLeftHandPose(ply)

    if not handPos or not handAng then
        ply:ChatPrint("手の位置と角度を取得できませんでした。")
        return
    end

    handAng = handAng - Angle()


    -- エンティティを手の位置にテレポート
    nearestEnt:SetPos(handPos)
    nearestEnt:SetAngles(handAng)

    -- pickup関数を呼び出してエンティティを手に持たせる
    pickup(ply, bLeftHand, handPos, handAng)
end)


--右手用
concommand.Add("vrmod_test_pickup_nearest_right", function(ply)
    local plyPos = ply:GetPos()

    -- プレイヤーの周囲のエンティティを検索し、最も近いものを見つける
    local nearestEnt = nil
    local nearestDist = math.huge
    for _, ent in ipairs(ents.GetAll()) do
        if ent:IsValid() and ent:GetPos():DistToSqr(plyPos) < nearestDist then
            if not IsValid(ent) or not IsValid(ent:GetPhysicsObject()) or ent == ply or ply:InVehicle() or (ent.CPPICanPickup ~= nil and not ent:CPPICanPickup(ply)) then continue end
            
            nearestDist = ent:GetPos():DistToSqr(plyPos)
            nearestEnt = ent
        end
    end

    if not IsValid(nearestEnt) then
        ply:ChatPrint("近くにエンティティが見つかりませんでした。")
        return
    end

    -- 手の位置と角度を取得
    local bLeftHand = false
    local handPos, handAng = vrmod.GetRightHandPose(ply)

    if not handPos or not handAng then
        ply:ChatPrint("手の位置と角度を取得できませんでした。")
        return
    end

    handAng = handAng - Angle()

    -- エンティティを手の位置にテレポート
    nearestEnt:SetPos(handPos)
    nearestEnt:SetAngles(handAng)

    -- pickup関数を呼び出してエンティティを手に持たせる
    pickup(ply, bLeftHand, handPos, handAng)
end)

