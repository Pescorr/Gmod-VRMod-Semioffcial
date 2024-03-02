-- 必要なフックや関数がGmodVR環境で設定されていることを前提とします。
-- エンティティがピックアップされたときに呼ばれる関数
hook.Add(
    "VRMod_Pickup",
    "CustomMagazineReloadPickup",
    function(player, entity)
        if entity:GetClass() == "vrmod_magent" and vrmod.IsPlayerInVR(player) then
            -- プレイヤーがマガジンをピックアップしたことを記録
            player.hasMagazine = true
            player.magazineEntity = entity -- ピックアップされたエンティティを記録
        end
    end
)

local function CheckHandTouch(player)
    local leftHandPos = vrmod.GetLeftHandPos(player)
    local rightViewModelPos = vrmod.GetRightHandPos(player)
    local some_threshold = CreateClientConVar("vrmod_magent_range","13",true,FCVAR_ARCHIVE) -- 必要に応じて調整
    if not leftHandPos or not rightViewModelPos then return false end -- 一方または両方の位置が nil のため、チェックを実行できない
    if leftHandPos:Distance(rightViewModelPos) < some_threshold:GetFloat() then return true end

    return false
end

-- 'リロード'アクションを実行するメインロジック
hook.Add(
    "Think",
    "CustomMagazineReloadThink",
    function()
        for _, player in ipairs(player.GetAll()) do
            if CheckHandTouch(player) and player.hasMagazine then
                -- リロード処理をここで独立して実行
                local wep = player:GetActiveWeapon()
                if wep:IsValid() then
                    local ammoType = wep:GetPrimaryAmmoType()
                    local ammoCount = player:GetAmmoCount(ammoType)
                    local clipSize = wep:GetMaxClip1()
                    local currentClip = wep:Clip1()
                    if ammoCount > 0 and currentClip < clipSize then
                        local ammoNeeded = clipSize - currentClip
                        local ammoToGive = math.min(ammoNeeded, ammoCount)
                        wep:SetClip1(currentClip + ammoToGive)
                        player:RemoveAmmo(ammoToGive, ammoType)
                    end
                end

                -- 左手に持っているエンティティを放し、削除する
                if IsValid(player.magazineEntity) then
                    player.magazineEntity:Remove()
                end

                -- フラグをリセット
                player.hasMagazine = false
                player.magazineEntity = nil
            end
        end
    end
)