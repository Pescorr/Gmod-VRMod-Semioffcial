--------[vrmod_holstersystem_type2.txt]Start--------
AddCSLuaFile()
if CLIENT then
    local convars, convarValues = vrmod.GetConvars()
    local pouch_slots = 5
    local pouch_weapons = {}
    local pouch_positions = {}
    local pouch_initial_positions = {}
    local pouch_sizes = {}
    local pouch_enabled = CreateClientConVar("vrmod_pouch_enabled", 1, true, FCVAR_ARCHIVE, nil, 0, 1) -- 新しく追加したconvar
    local pouch_visible_name = CreateClientConVar("vrmod_pouch_visiblename", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
    local pouch_lefthand_weapon_enable = CreateClientConVar("vrmod_pouch_lefthandwep_enable", "1", true, FCVAR_ARCHIVE)
    local pouch_visible_hud = CreateClientConVar("vrmod_pouch_visiblename_hud", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
    --local pouch_entitymode = CreateClientConVar("vrmod_pouch_entitymode_enable", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
    local pouch_saved_positions = {}
    local pouch_locked = {}
    -- local pouch_enter_sound = CreateClientConVar("vrmod_pouch_enter_sound", "common/wpn_moveselect.wav", true, FCVAR_ARCHIVE)
    local pouch_pickup_sound = CreateClientConVar("vrmod_pouch_pickup_sound", "common/wpn_select.wav", true, FCVAR_ARCHIVE)
    for i = 1, pouch_slots do
        CreateClientConVar("vrmod_pouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
        CreateClientConVar("vrmod_pouch_size_" .. i, 12, true, FCVAR_ARCHIVE) -- 新しく追加したconvar
        pouch_locked[i] = false
    end

    local function InitializeHolsterSystem()
        local convars = vrmod.GetConvars()
        local pouch = {
            slots = 5,
            weapons = {},
            positions = {},
            sizes = {},
            locked = {},
            enabled = CreateClientConVar("vrmod_pouch_enabled", 1, true, FCVAR_ARCHIVE)
        }

        -- ConVarの初期化
        for i = 1, pouch.slots do
            CreateClientConVar("vrmod_pouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_pouch_size_" .. i, 12, true, FCVAR_ARCHIVE)
            pouch.locked[i] = false
        end

        return pouch
    end

    -- 安全なポジション更新
    local function UpdatePouchPositions(ply, headPos, headAng)
        if not IsValid(ply) then return end
        local chestBone = ply:LookupBone("ValveBiped.Bip01_Spine")
        local hipBone = ply:LookupBone("ValveBiped.Bip01_Pelvis")
        if not chestBone or not hipBone then return end
        local chestPos = ply:GetBonePosition(chestBone)
        local hipPos = ply:GetBonePosition(hipBone)
        if not chestPos or not hipPos then return end

        return {
            [1] = headPos + (headAng:Right() * 7),
            [2] = headPos - (headAng:Right() * 7),
            [3] = chestPos + (headAng:Right() * 10),
            [4] = chestPos - (headAng:Right() * 10),
            [5] = hipPos - (hipAng:Right() * 16)
        }
    end

    -- VRの状態チェック
    local function IsVRReady()
        return g_VR and g_VR.active and g_VR.threePoints
    end

    -- 遅延初期化
    hook.Add(
        "VRMod_Start",
        "HolsterSystem_Init",
        function()
            local pouch = InitializeHolsterSystem()
            if not IsVRReady() then return end
        end
    )

    -- 各種フックの追加
    -- ...existing hook code with error checking...
    -- ConVarの値が変更されたことを検知するフックを追加
    for i = 1, pouch_slots do
        cvars.AddChangeCallback(
            "vrmod_pouch_size_" .. i,
            function(convar_name, value_old, value_new)
                pouch_sizes[i] = tonumber(value_new)
            end, "vrmod_pouch_size_callback"
        )
    end

    for i = 1, pouch_slots do
        pouch_positions[i] = Vector(0, 0, 0)
        pouch_initial_positions[i] = Vector(0, 0, 0)
        pouch_sizes[i] = GetConVar("vrmod_pouch_size_" .. i):GetFloat() -- convarから値を取得するように変更
    end

    hook.Add(
        "VRMod_Tracking",
        "vrmod_holster_follow_player",
        function()
            if not pouch_enabled:GetBool() then return end -- ホルスター機能が無効の場合は処理を行わない
            local ply = LocalPlayer()
            if not g_VR.active then return end
            if not g_VR.threePoints then return end
            if not IsValid(ply) then return end
            if not ply:Alive() then return end
            if ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Spine")) == nil then return end
            if ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Pelvis")) == nil then return end
            if not g_VR.tracking.hmd then return end
            local headPos, headAng = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
            local chestPos, chestAng = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Spine"))
            local hipPos, hipAng = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Pelvis"))
            pouch_positions[1] = headPos + (headAng:Right() * 7)
            pouch_positions[2] = headPos - (headAng:Right() * 7)
            pouch_positions[3] = chestPos + (headAng:Right() * 10)
            pouch_positions[4] = chestPos - (headAng:Right() * 10)
            pouch_positions[5] = hipPos - (hipAng:Right() * 16)
        end
    )

    hook.Add(
        "VRMod_Input",
        "vrutil_hook_pouchinput",
        function(action, pressed)
            if not g_VR.active then return end
            if not pouch_enabled:GetBool() then return end -- ホルスター機能が無効の場合は処理を行わない
            local function storeWeapon(leftHand)
                for i = 1, pouch_slots do
                    local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
                    if hand_pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                        local activeWeapon = LocalPlayer():GetActiveWeapon()
                        if IsValid(activeWeapon) and activeWeapon:GetClass() ~= "weapon_vrmod_empty" and ((leftHand and GetConVar("vrmod_lefthand"):GetBool()) or (not leftHand and not GetConVar("vrmod_lefthand"):GetBool())) then
                            if not pouch_locked[i] then
                                LocalPlayer():ConCommand("vrmod_pouch_weapon_" .. i .. " " .. activeWeapon:GetClass())
                            end

                            LocalPlayer():ConCommand("use weapon_vrmod_empty")

                            return
                        end

                        local heldEntity = leftHand and g_VR.heldEntityLeft or g_VR.heldEntityRight
                        if IsValid(heldEntity) then
                            if pouch_locked[i] then return end
                            LocalPlayer():ConCommand("vrmod_pouch_weapon_" .. i .. " " .. heldEntity:GetClass())
                            heldEntity:Remove() -- エンティティを消去
                            if leftHand then
                                g_VR.heldEntityLeft = nil
                            else
                                g_VR.heldEntityRight = nil
                            end

                            return
                        end

                        break
                    end
                end
            end

            local function equipWeaponOrEntity(leftHand)
                if not pouch_enabled:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
                    if hand_pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                        local wepclass = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                        if wepclass ~= "" then
                            if weapons.Get(wepclass) then
                                if leftHand and not pouch_lefthand_weapon_enable:GetBool() then return end
                                LocalPlayer():ConCommand("use " .. wepclass)
                                if leftHand and string.find(wepclass, "vr") then
                                    LocalPlayer():ConCommand("vrmod_LeftHandmode 0")
                                else
                                    LocalPlayer():ConCommand("vrmod_lefthand " .. (leftHand and "1" or "0"))
                                end

                                surface.PlaySound(pouch_pickup_sound:GetString())
                            else
                                net.Start("vrmod_test_spawn_entity")
                                net.WriteString(wepclass)
                                net.WriteVector(hand_pos)
                                net.WriteAngle(leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang)
                                net.WriteBool(leftHand)
                                net.SendToServer()
                                surface.PlaySound(pouch_pickup_sound:GetString())
                                if leftHand then
                                    LocalPlayer():ConCommand("vrmod_test_pickup_entteleport_left " .. wepclass)
                                else
                                    LocalPlayer():ConCommand("vrmod_test_pickup_entteleport_right " .. wepclass)
                                end
                            end
                        end

                        break
                    end
                end
            end

            if action == "boolean_left_pickup" and not pressed then
                storeWeapon(true)
            elseif action == "boolean_right_pickup" and not pressed then
                storeWeapon(false)
            end

            if action == "boolean_left_pickup" and pressed then
                equipWeaponOrEntity(true)
            elseif action == "boolean_right_pickup" and pressed then
                equipWeaponOrEntity(false)
            end

            if action == "boolean_use" and pressed then
                for i = 1, pouch_slots do
                    if g_VR.tracking.pose_lefthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                        pouch_locked[i] = not pouch_locked[i]
                        break
                    end

                    if g_VR.tracking.pose_righthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                        pouch_locked[i] = not pouch_locked[i]
                        break
                    end
                end
            end
        end
    )

    hook.Add(
        "HUDPaint",
        "vrmod_holstarsystem_left_hudpaint",
        function()
            if not pouch_enabled:GetBool() then return end -- ホルスター機能が無効の場合は処理を行わない
            if not pouch_visible_hud:GetBool() then return end
            if not g_VR.active then return end
            for i = 1, pouch_slots do
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                    local text = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                    if text ~= "" then
                        if pouch_locked[i] then
                            text = "＊" .. text .. "＊" -- ロックされている場合は文字列の始まりと終わりに「＊」をつける
                        end

                        draw.SimpleText(text, "DermaLarge", ScrW() * 0.05, ScrH() * 0.9, Color(255, 255, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end

                    if not IsValid(ply) then return end
                    -- surface.PlaySound(pouch_enter_sound:GetString())
                    break
                end
            end
        end
    )

    hook.Add(
        "HUDPaint",
        "vrmod_holstarsystem_right_hudpaint",
        function()
            if not pouch_enabled:GetBool() then return end -- ホルスター機能が無効の場合は処理を行わない
            if not pouch_visible_hud:GetBool() then return end
            if not g_VR.active then return end
            for i = 1, pouch_slots do
                if g_VR.tracking.pose_righthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                    local text = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                    if text ~= "" then
                        if pouch_locked[i] then
                            text = "＊" .. text .. "＊" -- ロックされている場合は文字列の始まりと終わりに「＊」をつける
                        end

                        draw.SimpleText(text, "DermaLarge", ScrW() * 0.95, ScrH() * 0.9, Color(255, 255, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end

                    if not IsValid(ply) then return end
                    -- surface.PlaySound(pouch_enter_sound:GetString())
                    break
                end
            end
        end
    )

    hook.Add(
        "PostDrawTranslucentRenderables",
        "vrmod_holstarsystem_draw",
        function(depth, sky)
            if not pouch_enabled:GetBool() then return end -- ホルスター機能が無効の場合は処理を行わない
            if not pouch_visible_name:GetBool() then return end
            if not g_VR.threePoints or EyePos() ~= g_VR.view.origin then return end
            for i = 1, pouch_slots do
                local pos = pouch_positions[i]
                local size = pouch_sizes[i]
                render.SetColorMaterial()
                local color = pouch_locked[i] and Color(146, 253, 110, 80) or Color(255, 255, 255, 128)
                render.DrawSphere(pos, size, 16, 50, color)
                local entClass = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                if entClass ~= "" then
                    local eyeAng = EyeAngles()
                    eyeAng:RotateAroundAxis(eyeAng:Right(), 60)
                    cam.Start3D2D(pos, eyeAng, 0.1)
                    draw.SimpleText(entClass, "CloseCaption_Normal", 0, 0, Color(108, 81, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end
    )
end

if SERVER then
    util.AddNetworkString("vrmod_test_spawn_entity")
    net.Receive(
        "vrmod_test_spawn_entity",
        function(len, ply)
            local entClass = net.ReadString()
            local handPos = net.ReadVector()
            local handAng = net.ReadAngle()
            local isLeftHand = net.ReadBool()
            local spawnedEnt = ents.Create(entClass)
            if not IsValid(spawnedEnt) then return end
            local function followAndTryPickup()
                if not IsValid(spawnedEnt) then return end
                spawnedEnt:Spawn()
                spawnedEnt:SetPos(handPos)
                spawnedEnt:SetAngles(handAng)
                spawnedEnt:Activate(false)
                if IsValid(spawnedEnt) then
                    timer.Simple(
                        0.20,
                        function()
                            pickup(ply, isLeftHand, spawnedEnt:GetPos(), spawnedEnt:GetAngles())
                            timer.Remove(ply:SteamID() .. "followAndTryPickup")
                        end
                    )
                end
            end

            timer.Create(ply:SteamID() .. "followAndTryPickup", 0, 11, followAndTryPickup)
        end
    )
end