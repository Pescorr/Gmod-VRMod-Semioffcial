AddCSLuaFile()

-- Entity removal should be done on server side, so we use a network message
if SERVER then
    util.AddNetworkString("RemoveMagEntity")

    net.Receive("RemoveMagEntity", function(len, ply)
        local ent = net.ReadEntity()
        if IsValid(ent) and ent:GetClass() == "vrmod_magent" then
            ent:Remove()
        end
    end)
end

hook.Add(
    "VRMod_Pickup",
    "CustomMagazineReloadPickup",
    function(player, entity)
        if entity:GetClass() == "vrmod_magent" and vrmod.IsPlayerInVR(player) then
            -- When the player picks up a magazine in VR, mark them as having a magazine
            player.hasMagazine = true
            player.magazineEntity = entity
        end
    end
)

local function CheckHandTouch(player)
    local leftHandPos = vrmod.GetLeftHandPos(player)
    local rightViewModelPos = vrmod.GetRightHandPos(player)
    local threshold = CreateClientConVar("vrmod_magent_range", "13", true, FCVAR_ARCHIVE)

    if not leftHandPos or not rightViewModelPos then return false end
    if leftHandPos:Distance(rightViewModelPos) < threshold:GetFloat() then return true end

    return false
end

hook.Add(
    "Think",
    "CustomMagazineReloadThink",
    function()
        for _, player in ipairs(player.GetAll()) do
            if CheckHandTouch(player) and player.hasMagazine then
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

                -- Instead of directly removing the entity, send a network message to the server to do it
                if SERVER then
                    if IsValid(player.magazineEntity) then
                        player.magazineEntity:Remove()
                    end
                else
                    net.Start("RemoveMagEntity")
                    net.WriteEntity(player.magazineEntity)
                    net.SendToServer()
                end

                player.hasMagazine = false
                player.magazineEntity = nil
            end
        end
    end
)
