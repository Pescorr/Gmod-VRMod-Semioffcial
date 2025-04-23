AddCSLuaFile()

CreateClientConVar("vrmod_mag_system_enable", "1", true, FCVAR_ARCHIVE, "Enable/Disable the entire VR magazine system")
if SERVER then
    util.AddNetworkString("RemoveMagEntity")
    net.Receive(
        "RemoveMagEntity",
        function(len, ply)
            local ent = net.ReadEntity()
            if IsValid(ent) and ent:GetClass() == "vrmod_magent" then
                ent:Remove()
            end
        end
    )
end

if CLIENT then
    CreateClientConVar("vrmod_magent_sound", "weapons/shotgun/shotgun_reload3.wav", true, FCVAR_ARCHIVE, "Sound played when the weapon is reloaded with a magazine.")
end

local function HasVRInWeaponName(player)
    local activeWeapon = player:GetActiveWeapon()
    if IsValid(activeWeapon) then
        local weaponName = string.lower(activeWeapon:GetClass())
        if string.find(weaponName, "vr") then return true end
    end

    return false
end

hook.Add(
    "VRMod_Pickup",
    "CustomMagazineReloadPickup",
    function(player, entity)
        if not GetConVar("vrmod_mag_system_enable"):GetBool() then return end
        if IsValid(entity) and entity:GetClass() == "vrmod_magent" and vrmod.IsPlayerInVR(player) then
            if HasVRInWeaponName(player) then
                -- Cancel pickup and remove the entity
                if SERVER then
                    entity:Remove()
                else
                    net.Start("RemoveMagEntity")
                    net.WriteEntity(entity)
                    net.SendToServer()
                end
                -- Prevent the original pickup

                return false
            else
                player.hasMagazine = true
                player.magazineEntity = entity
            end
        end
    end
)

local function CheckHandTouch(player)
    local leftHandPos = vrmod.GetLeftHandPos(player)
    local rightViewModelPos = vrmod.GetRightHandPos(player)
    local threshold = CreateClientConVar("vrmod_magent_range", "12", true, FCVAR_ARCHIVE,"",1,20)
    if not leftHandPos or not rightViewModelPos then return false end
    if leftHandPos:Distance(rightViewModelPos) < threshold:GetFloat() then return true end

    return false
end

hook.Add(
    "Think",
    "CustomMagazineReloadThink",
    function()
        if not GetConVar("vrmod_mag_system_enable"):GetBool() then return end
        
        -- VRModが有効なプレイヤーのみを処理
        local players = player.GetAll()
        for i = 1, #players do
            local player = players[i]
            if vrmod.IsPlayerInVR(player) and player.hasMagazine then
                if CheckHandTouch(player) and not HasVRInWeaponName(player) then
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
                            if CLIENT then
                                local reloadSound = GetConVar("vrmod_magent_sound"):GetString()
                                player:EmitSound(reloadSound)
                            end
                        end
                    end

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
    end
)