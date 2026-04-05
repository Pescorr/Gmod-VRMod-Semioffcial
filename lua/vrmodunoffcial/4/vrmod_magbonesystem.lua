--------[vrmod_magbonesystem.lua]Start--------
AddCSLuaFile()
CreateClientConVar("vrmod_mag_system_enable", "1", true, FCVAR_ARCHIVE, "Enable/Disable the entire VR magazine system")
CreateClientConVar("vrmod_mag_pos_x", "3.15", true, FCVAR_ARCHIVE, "X offset for magazine position")
CreateClientConVar("vrmod_mag_pos_y", "0.31", true, FCVAR_ARCHIVE, "Y offset for magazine position")
CreateClientConVar("vrmod_mag_pos_z", "2.83", true, FCVAR_ARCHIVE, "Z offset for magazine position")
CreateClientConVar("vrmod_mag_ang_p", "-2.83", true, FCVAR_ARCHIVE, "Pitch offset for magazine angle")
CreateClientConVar("vrmod_mag_ang_y", "90", true, FCVAR_ARCHIVE, "Yaw offset for magazine angle")
CreateClientConVar("vrmod_mag_ang_r", "83", true, FCVAR_ARCHIVE, "Roll offset for magazine angle")
CreateClientConVar("vrmod_mag_bones", "mag,ammo,clip,cylin,shell,magazine", true, FCVAR_ARCHIVE, "Comma-separated list of magazine bone names")
CreateClientConVar("vrmod_mag_ejectbone_delay", "0", true, FCVAR_ARCHIVE, "Delay before magazine bones hide after reload press (0 = instant)")
function vrmod_advanced_magazine()
    if CLIENT then
        CreateClientConVar("vrmod_mag_ejectbone_enable", "1", true, FCVAR_ARCHIVE, "Enable/Disable magazine eject bone functionality")
        local magazineState = 0 -- -1: pending hide (delay), 0: normal, 1: reload button pressed, 2: magazine entity held
        local pendingHideTime = 0 -- CurTime() target for state -1 → 1 transition
        local hiddenBones = {}
        local hiddenBodygroups = {}
        local heldBoneIndex = nil
        local hasReloaded = false -- For tracking if reload occurred for secondary fire functionality
        local function IsFeatureEnabled()
            return GetConVar("vrmod_mag_ejectbone_enable"):GetBool() and GetConVar("vrmod_mag_system_enable"):GetBool()
        end

        local function IsMagazineBone(boneName)
            -- Override check: if user set a specific magbone, only that bone matches
            if vrmod.IsMagboneOverride then
                local ply = LocalPlayer()
                if IsValid(ply) then
                    local wep = ply:GetActiveWeapon()
                    if IsValid(wep) then
                        local result = vrmod.IsMagboneOverride(wep:GetClass(), boneName)
                        if result ~= nil then return result end -- override decided
                    end
                end
            end
            -- Original auto-detect logic
            boneName = string.lower(boneName)
            local magazineBones = string.Explode(",", GetConVar("vrmod_mag_bones"):GetString())
            for _, name in ipairs(magazineBones) do
                if string.find(boneName, string.lower(name), 1, true) then return true end
            end

            return false
        end

        -- Export for other modules (e.g., RealMech reload)
        vrmod.IsMagazineBone = IsMagazineBone

        local function IsMagazineBodygroup(bodygroupName)
            bodygroupName = string.lower(bodygroupName)
            local magazineBodygroups = string.Explode(",", GetConVar("vrmod_mag_bones"):GetString())
            for _, name in ipairs(magazineBodygroups) do
                if string.find(bodygroupName, string.lower(name), 1, true) then return true end
            end

            return false
        end

        local function HideMagazineBonesAndBodygroups(viewModel)
            local bonehide = CreateClientConVar("vrmod_mag_ejectbone_type", "0", true, FCVAR_ARCHIVE, "0 = bone move 1 = bone hide")
            for i = 0, viewModel:GetBoneCount() - 1 do
                local boneName = viewModel:GetBoneName(i)
                if IsMagazineBone(boneName) then
                    hiddenBones[i] = true
                    if bonehide:GetBool() then
                        viewModel:ManipulateBoneScale(i, Vector(0, 0, 0))
                    else
                        viewModel:ManipulateBoneScale(i, Vector(1, 1, 1))
                    end
                end
            end

            for i = 0, viewModel:GetNumBodyGroups() - 1 do
                local bodygroupName = viewModel:GetBodygroupName(i)
                if IsMagazineBodygroup(bodygroupName) then
                    hiddenBodygroups[i] = viewModel:GetBodygroup(i)
                    viewModel:SetBodygroup(i, 6)
                end
            end
        end

        local function ShowMagazineBonesAndBodygroups(viewModel)
            for i, _ in pairs(hiddenBones) do
                viewModel:ManipulateBoneScale(i, Vector(1, 1, 1))
            end

            hiddenBones = {}
            for i, originalValue in pairs(hiddenBodygroups) do
                viewModel:SetBodygroup(i, originalValue)
            end

            hiddenBodygroups = {}
        end

        local function ResetFeature(viewModel)
            magazineState = 0
            pendingHideTime = 0
            if IsValid(viewModel) then
                ShowMagazineBonesAndBodygroups(viewModel)
            end

            heldBoneIndex = nil
        end

        local function ApplyMagazineOffsets(handPos, handAng)
            local offsetPos = Vector(GetConVar("vrmod_mag_pos_x"):GetFloat(), GetConVar("vrmod_mag_pos_y"):GetFloat(), GetConVar("vrmod_mag_pos_z"):GetFloat())
            local offsetAng = Angle(GetConVar("vrmod_mag_ang_p"):GetFloat(), GetConVar("vrmod_mag_ang_y"):GetFloat(), GetConVar("vrmod_mag_ang_r"):GetFloat())
            local newPos, newAng = LocalToWorld(offsetPos, offsetAng, handPos, handAng)

            return newPos, newAng
        end

        -- Handle boolean_reload key to hide magazine bones
        -- State machine: -1=PENDING_HIDE, 0=NORMAL, 1=HIDDEN, 2=HELD
        hook.Add(
            "VRMod_Input",
            "VRAdvancedMagazineReloadKey",
            function(action, pressed)
                if not IsFeatureEnabled() then return end
                if action == "boolean_reload" and pressed then
                    local ply = LocalPlayer()
                    local viewModel = ply:GetViewModel()
                    if not IsValid(viewModel) then return end

                    if magazineState == -1 then
                        -- PENDING中に再押下 → キャンセル
                        magazineState = 0
                        pendingHideTime = 0
                    elseif magazineState == 0 then
                        local delay = GetConVar("vrmod_mag_ejectbone_delay"):GetFloat()
                        if delay <= 0 then
                            -- 即時（現行動作）
                            magazineState = 1
                            HideMagazineBonesAndBodygroups(viewModel)
                        else
                            -- ディレイ開始
                            magazineState = -1
                            pendingHideTime = CurTime() + delay
                        end
                    elseif magazineState == 1 or magazineState == 2 then
                        -- HIDDEN/HELD → 復元
                        magazineState = 0
                        pendingHideTime = 0
                        ShowMagazineBonesAndBodygroups(viewModel)
                    end
                end

                -- Handle secondary fire for slide release simulation
                if action == "boolean_secondaryfire" and pressed and hasReloaded then
                    local ply = LocalPlayer()
                    local weapon = ply:GetActiveWeapon()
                    if IsValid(weapon) then
                        -- Store current weapon and ammo state
                        local wepClass = weapon:GetClass()
                        local clip1 = weapon:Clip1()
                        local ammoType = weapon:GetPrimaryAmmoType()
                        local ammo = ply:GetAmmoCount(ammoType)
                        -- Switch away from weapon and back
                        input.SelectWeapon(ply:GetWeapons()[1]) -- Switch to any other weapon
                        timer.Simple(
                            0.05,
                            function()
                                input.SelectWeapon(ply:GetWeapon(wepClass)) -- Switch back
                                -- Reset hasReloaded flag
                                hasReloaded = false
                            end
                        )
                    end
                end
            end
        )

        hook.Add(
            "VRMod_PreRender",
            "VRAdvancedMagazineInteraction",
            function()
                if not g_VR or not g_VR.active or not IsFeatureEnabled() then return end
                local ply = LocalPlayer()
                local weapon = ply:GetActiveWeapon()
                local viewModel = ply:GetViewModel()
                if not IsValid(weapon) or not IsValid(viewModel) then
                    ResetFeature(viewModel)
                    return
                end

                local leftHandPos = g_VR.tracking.pose_lefthand.pos
                local leftHandAng = g_VR.tracking.pose_lefthand.ang
                leftHandPos, leftHandAng = ApplyMagazineOffsets(leftHandPos, leftHandAng)

                -- ============ 1. vrmagent保持チェック（最優先） ============
                if ply.hasMagazine and IsValid(ply.magazineEntity) and ply.magazineEntity:GetClass() == "vrmod_magent" then
                    -- どのステートからでもstate 2に強制遷移
                    if magazineState == -1 then
                        pendingHideTime = 0  -- Pending キャンセル
                    end
                    magazineState = 2
                    HideMagazineBonesAndBodygroups(viewModel)

                    local closestBone = nil
                    local closestDist = math.huge
                    for i = 0, viewModel:GetBoneCount() - 1 do
                        local boneName = viewModel:GetBoneName(i)
                        if IsMagazineBone(boneName) then
                            local bonePos = viewModel:GetBonePosition(i)
                            local dist = bonePos:DistToSqr(leftHandPos)
                            if dist < closestDist then
                                closestBone = i
                                closestDist = dist
                            end
                        end
                    end

                    heldBoneIndex = closestBone
                    if heldBoneIndex then
                        local boneMatrix = viewModel:GetBoneMatrix(heldBoneIndex)
                        if boneMatrix then
                            boneMatrix:SetTranslation(leftHandPos)
                            boneMatrix:SetAngles(leftHandAng)
                            viewModel:SetBoneMatrix(heldBoneIndex, boneMatrix)
                        end
                    end

                    for i = 0, viewModel:GetNumBodyGroups() - 1 do
                        local bodygroupName = viewModel:GetBodygroupName(i)
                        if IsMagazineBodygroup(bodygroupName) then
                            viewModel:SetBodygroup(i, 1)
                        end
                    end
                    return  -- vrmagent保持中は他のステート処理をスキップ
                end

                -- ============ 2. vrmagent解放時の復帰 ============
                if magazineState == 2 then
                    magazineState = 0
                    ShowMagazineBonesAndBodygroups(viewModel)
                    heldBoneIndex = nil
                    return
                end

                -- ============ 3. PENDINGタイマーチェック ============
                if magazineState == -1 then
                    if CurTime() >= pendingHideTime then
                        magazineState = 1
                        HideMagazineBonesAndBodygroups(viewModel)
                        pendingHideTime = 0
                    end
                    -- Timer未到達ならボーン操作なし（見えるまま）
                    return
                end

                -- ============ 4. HIDDEN維持 ============
                if magazineState == 1 then
                    HideMagazineBonesAndBodygroups(viewModel)
                end

                heldBoneIndex = nil
            end
        )

        hook.Add(
            "VRMod_Pickup",
            "VRAdvancedMagazinePickupSomething",
            function(player, entity)
                if not IsFeatureEnabled() then return end
                if not IsValid(entity) then return end
                if player == LocalPlayer() and entity:GetClass() == "vrmod_magent" then
                    player.hasMagazine = true
                    player.magazineEntity = entity
                    if GetConVar("vrmod_mag_ejectbone_type"):GetInt() == 0 then
                        entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                        entity:SetColor(Color(255, 255, 255, 0))
                    end
                end
            end
        )

        AddCSLuaFile()
        CreateClientConVar("vrmod_mag_system_enable", "1", true, FCVAR_ARCHIVE, "Enable/Disable the entire VR magazine system")
        CreateClientConVar("vrmod_mag_ejectbone_type", "0", true, FCVAR_ARCHIVE, "Magazine ejection bone type")
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
            CreateClientConVar("vrmod_magent_sound", "weapons/shotgun/shotgun_reload3.wav", true, FCVAR_ARCHIVE)
        end

        local function HasVRInWeaponName(player)
            local activeWeapon = player:GetActiveWeapon()
            if IsValid(activeWeapon) then
                local weaponName = string.lower(activeWeapon:GetClass())

                return string.find(weaponName, "vr") and true or false
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
                        if SERVER then
                            entity:Remove()
                        else
                            net.Start("RemoveMagEntity")
                            net.WriteEntity(entity)
                            net.SendToServer()
                        end

                        return false
                    else
                        player.hasMagazine = true
                        player.magazineEntity = entity
                        if CLIENT and GetConVar("vrmod_mag_ejectbone_type"):GetInt() == 0 then
                            entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                            entity:SetColor(Color(255, 255, 255, 0))
                        end
                    end
                end
            end
        )

        local function CheckHandTouch(player)
            local leftHandPos = vrmod.GetLeftHandPos(player)
            local rightViewModelPos = vrmod.GetRightHandPos(player)
            local threshold = CreateClientConVar("vrmod_magent_range", "12", true, FCVAR_ARCHIVE, "", 1, 20)

            return leftHandPos and rightViewModelPos and leftHandPos:Distance(rightViewModelPos) < threshold:GetFloat()
        end

        hook.Add(
            "Think",
            "CustomMagazineReloadThink",
            function()
                for _, player in ipairs(player.GetAll()) do
                    if not GetConVar("vrmod_mag_system_enable"):GetBool() then return end
                    -- magazineEntityが消滅していたらステートをリセット
                    if player.hasMagazine and not IsValid(player.magazineEntity) then
                        player.hasMagazine = false
                        player.magazineEntity = nil
                        if CLIENT and player == LocalPlayer() then
                            magazineState = 0
                            pendingHideTime = 0
                            local viewModel = player:GetViewModel()
                            if IsValid(viewModel) then
                                ShowMagazineBonesAndBodygroups(viewModel)
                            end
                        end
                    end
                    if CheckHandTouch(player) and player.hasMagazine and not HasVRInWeaponName(player) then
                        local wep = player:GetActiveWeapon()
                        if IsValid(wep) then
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
                                    player:EmitSound(GetConVar("vrmod_magent_sound"):GetString())
                                    -- Set hasReloaded flag for secondary fire functionality
                                    if player == LocalPlayer() then
                                        hasReloaded = true
                                    end
                                end
                            end
                        end

                        if SERVER then
                            if IsValid(player.magazineEntity) then
                                player.magazineEntity:Remove()
                            end
                        else
                            if IsValid(player.magazineEntity) then
                                net.Start("RemoveMagEntity")
                                net.WriteEntity(player.magazineEntity)
                                net.SendToServer()
                            end
                        end

                        player.hasMagazine = false
                        player.magazineEntity = nil
                        -- Reset magazine state to normal after using the magazine
                        if CLIENT and player == LocalPlayer() then
                            magazineState = 0
                            pendingHideTime = 0
                            local viewModel = player:GetViewModel()
                            if IsValid(viewModel) then
                                ShowMagazineBonesAndBodygroups(viewModel)
                            end
                        end
                    end
                end
            end
        )

        hook.Add(
            "VRMod_Drop",
            "VRAdvancedMagazineDropSomething",
            function(player, entity)
                if not IsFeatureEnabled() then return end
                if IsValid(entity) and player == LocalPlayer() and entity:GetClass() == "vrmod_magent" then
                    player.hasMagazine = false
                    player.magazineEntity = nil
                    entity:SetRenderMode(RENDERMODE_NORMAL)
                    entity:SetColor(Color(255, 255, 255, 255))
                end
            end
        )

        concommand.Add(
            "vrmod_magazine_reset",
            function()
                local viewModel = LocalPlayer():GetViewModel()
                ResetFeature(viewModel)
            end
        )

        cvars.AddChangeCallback(
            "vrmod_mag_ejectbone_enable",
            function(convar_name, value_old, value_new)
                local viewModel = LocalPlayer():GetViewModel()
                if value_new == "0" then
                    ResetFeature(viewModel)
                end
            end
        )

        -- =================================================================
        -- Magazine Pouch: Unified Pouch位置からvrmagentをスポーン
        -- Pickupボタン押下で発動。ホルスターとは完全に独立した仕組み
        -- =================================================================
        local cv_mag_pouch_enable = CreateClientConVar("vrmod_unoff_mag_pouch_enable", "1", true, FCVAR_ARCHIVE, "Enable magazine pouch (spawn vrmagent from body pouch on pickup)")
        local lastMagPouchSpawnTime = 0

        hook.Add(
            "VRMod_Input",
            "VRMagPouchSpawn",
            function(action, pressed)
                -- boolean_left_pickup pressed のみ反応
                if action ~= "boolean_left_pickup" or not pressed then return end
                -- 機能有効チェック
                if not GetConVar("vrmod_mag_system_enable"):GetBool() then return end
                if not cv_mag_pouch_enable:GetBool() then return end
                -- VRアクティブチェック
                if not g_VR or not g_VR.active then return end
                if not g_VR.tracking or not g_VR.tracking.pose_lefthand then return end
                -- VR武器は専用リロードがあるためスキップ
                if HasVRInWeaponName(LocalPlayer()) then return end
                -- 空手（weapon_vrmod_empty）ではスキップ
                local wep = LocalPlayer():GetActiveWeapon()
                if not IsValid(wep) or wep:GetClass() == "weapon_vrmod_empty" then return end
                -- クールダウン（0.5秒）
                if CurTime() - lastMagPouchSpawnTime < 0.5 then return end
                -- Unified Pouch範囲チェック
                if not vrmod.pouch or not vrmod.pouch.IsHandNearPouch then return end
                local leftHandPos = g_VR.tracking.pose_lefthand.pos
                if not leftHandPos then return end
                if not vrmod.pouch.IsHandNearPouch(LocalPlayer(), leftHandPos) then return end

                -- vrmagentをスポーン
                lastMagPouchSpawnTime = CurTime()
                net.Start("vrmod_test_spawn_entity")
                net.WriteString("vrmod_magent")
                net.WriteVector(leftHandPos)
                net.WriteAngle(g_VR.tracking.pose_lefthand.ang)
                net.WriteBool(true) -- isLeftHand
                net.SendToServer()

                -- フィードバック: サウンド + ハプティクス
                surface.PlaySound("common/wpn_select.wav")
                if VRMOD_TriggerHaptic then
                    pcall(VRMOD_TriggerHaptic, "vibration_left", 0, 0.5, 20, 1)
                end
            end
        )
    end
end

vrmod_advanced_magazine()
concommand.Add(
    "vrmod_lua_reset_magent",
    function(ply, cmd, args)
        vrmod_advanced_magazine()
    end
)
--------[vrmod_magbonesystem.lua]End--------