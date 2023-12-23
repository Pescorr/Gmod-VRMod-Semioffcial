-- 新しいConVarの作成
CreateConVar("vrmod_test_summonandgrab_ent", "prop_physics", FCVAR_ARCHIVE, "The entity class to spawn and grab")

-- vrmod_pickup_nearest_leftの改造
concommand.Add("vrmod_pickup_nearest_left", function(ply)
    if ply:InVehicle() then
        ply:ChatPrint("車両内では使用できません。")
        return
    end

    -- ConVarからエンティティクラス名を取得
    local entClass = GetConVar("vrmod_test_summonandgrab_ent"):GetString()

    -- エンティティをスポーン
    local spawnPos = ply:GetEyeTrace().HitPos
    local spawnedEnt = ents.Create(entClass)
    if not IsValid(spawnedEnt) then
        ply:ChatPrint("エンティティを生成できませんでした。")
        return
    end
    spawnedEnt:SetPos(spawnPos)
    spawnedEnt:Spawn()

    -- 手の位置と角度を取得
    local handPos, handAng = vrmod.GetLeftHandPose(ply)
    if not handPos or not handAng then
        ply:ChatPrint("手の位置と角度を取得できませんでした。")
        return
    end
    handAng = handAng - Angle(0, 0, 180)

    -- エンティティを手の位置にテレポート
    spawnedEnt:SetPos(handPos)
    spawnedEnt:SetAngles(handAng)

    -- pickup関数を呼び出してエンティティを手に持たせる
    pickup(ply, true, handPos, handAng)
end)
