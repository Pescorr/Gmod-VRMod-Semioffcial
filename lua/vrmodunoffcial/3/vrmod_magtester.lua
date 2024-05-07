AddCSLuaFile()
-- Entity removal should be done on server side, so we use a network message
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

-- Sound ConVars
if CLIENT then
    -- CreateClientConVar("vrmod_magpickup_sound", "items/ammo_pickup.wav", true, false, "Sound played when a magazine is picked up.")
    CreateClientConVar("vrmod_magent_sound", "weapons/shotgun/shotgun_reload3.wav", true, false, "Sound played when the weapon is reloaded with a magazine.")
end

hook.Add(
    "VRMod_Pickup",
    "CustomMagazineReloadPickup",
    function(player, entity)
        if not IsValid(entity) or entity:GetClass() == "vrmod_magent" and vrmod.IsPlayerInVR(player) then
            -- When the player picks up a magazine in VR, mark them as having a magazine
            player.hasMagazine = true
            player.magazineEntity = entity
            -- Play pickup sound on the client
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
                        -- Play reload sound on the client
                        if CLIENT then
                            local reloadSound = GetConVar("vrmod_magent_sound"):GetString()
                            player:EmitSound(reloadSound)
                            -- player:ConCommand("impulse 200")
                            -- timer.Simple(
                            --     0.1,
                            --     function()
                            --         player:ConCommand("impulse 200")
                            --     end
                            -- )
                        end
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