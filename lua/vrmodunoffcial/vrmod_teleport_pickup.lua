-- 新しいConVarの作成
CreateConVar("vrmod_test_summonandgrab_ent", "prop_physics", FCVAR_ARCHIVE, "The entity class to spawn and grab")
-- vrmod_pickup_lastspawn_leftの改造
concommand.Add(
    "vrmod_pickup_summonandgrab_left",
    function(ply)
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
    end
)

-- 新しいConVarの作成
CreateConVar("vrmod_test_summonandgrab_ent", "prop_physics", FCVAR_ARCHIVE, "The entity class to spawn and grab")
-- vrmod_pickup_lastspawn_rightの実装
concommand.Add(
    "vrmod_pickup_summonandgrab_right",
    function(ply)
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
        local handPos, handAng = vrmod.GetRightHandPose(ply)
        if not handPos or not handAng then
            ply:ChatPrint("手の位置と角度を取得できませんでした。")

            return
        end

        handAng = handAng - Angle(0, 0, 0)
        -- エンティティを手の位置にテレポート
        spawnedEnt:SetPos(handPos)
        spawnedEnt:SetAngles(handAng)
        -- pickup関数を呼び出してエンティティを手に持たせる
        pickup(ply, false, handPos, handAng)
    end
)

-- 最後にスポーンされたエンティティを追跡するための変数
local lastSpawnedEntity = nil
-- エンティティがスポーンされるたびにこの関数が呼ばれ、lastSpawnedEntityを更新する
local function updateLastSpawnedEntity(ply, ent)
    if IsValid(ent) then
        lastSpawnedEntity = ent
    end
end

-- さまざまなタイプのエンティティがスポーンされたときにフックを設定
hook.Add("PlayerSpawnedProp", "UpdateLastSpawnedEntity", updateLastSpawnedEntity)
hook.Add("PlayerSpawnedRagdoll", "UpdateLastSpawnedEntity", updateLastSpawnedEntity)
-- hook.Add("PlayerSpawnedVehicle", "UpdateLastSpawnedEntity", updateLastSpawnedEntity)
-- hook.Add("PlayerSpawnedNPC", "UpdateLastSpawnedEntity", updateLastSpawnedEntity)
hook.Add("PlayerSpawnedSENT", "UpdateLastSpawnedEntity", updateLastSpawnedEntity)
-- hook.Add("PlayerSpawnedSWEP", "UpdateLastSpawnedEntity", updateLastSpawnedEntity)
-- 以降は、pickupNearestHand 関数と vrmod_pickup_nearest_left/right の実装は同じ
-- エンティティを手に持たせる関数
local function pickuplastspawnHand(ply, isLeftHand)
    if not IsValid(lastSpawnedEntity) then
        ply:ChatPrint("最後にスポーンされたエンティティが見つかりません。")

        return
    end

    local handPoseFunc = isLeftHand and vrmod.GetLeftHandPose or vrmod.GetRightHandPose
    local handPos, handAng = handPoseFunc(ply)
    if not handPos or not handAng then
        ply:ChatPrint("手の位置と角度を取得できませんでした。")

        return
    end

    handAng = handAng - Angle(0, 0, 180)
    -- エンティティを手の位置にテレポート
    lastSpawnedEntity:SetPos(handPos)
    lastSpawnedEntity:SetAngles(handAng)
    -- pickup関数を呼び出してエンティティを手に持たせる
    pickup(ply, isLeftHand, handPos, handAng)
end

-- vrmod_pickup_lastspawn_leftの実装
concommand.Add(
    "vrmod_pickup_lastspawn_left",
    function(ply)
        pickuplastspawnHand(ply, true)
    end
)

-- vrmod_pickup_lastspawn_rightの実装
concommand.Add(
    "vrmod_pickup_lastspawn_right",
    function(ply)
        pickuplastspawnHand(ply, false)
    end
)