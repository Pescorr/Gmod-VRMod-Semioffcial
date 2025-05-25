--------[vrmod_holstarsystem_type2.lua]Start--------
function vrholstersystem2()
    if CLIENT then
        local convars, convarValues = vrmod.GetConvars()
        local pouch_slots = 5
        local pouch_weapons = {}
        local pouch_positions = {}
        local pouch_initial_positions = {}
        local pouch_sizes = {}
        local pouch_enabled = CreateClientConVar("vrmod_pouch_enabled", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
        local pouch_visible_name = CreateClientConVar("vrmod_pouch_visiblename", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
        local pouch_lefthand_weapon_enable = CreateClientConVar("vrmod_pouch_lefthandwep_enable", "1", true, FCVAR_ARCHIVE)
        local pouch_visible_hud = CreateClientConVar("vrmod_pouch_visiblename_hud", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
        local pouch_saved_positions = {}
        local pouch_locked = {}
        local pouch_pickup_sound = CreateClientConVar("vrmod_pouch_pickup_sound", "common/wpn_select.wav", true, FCVAR_ARCHIVE)
        local prev_hand_in_holster_left_status = {}
        local prev_hand_in_holster_right_status = {}
        -- ホルスターから取り出し保留中のエンティティ情報を格納するテーブル (クライアント専用)
        local holster_pickup_pending = {}
        for i = 1, pouch_slots do
            CreateClientConVar("vrmod_pouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_pouch_size_" .. i, 12, true, FCVAR_ARCHIVE)
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

            for i = 1, pouch.slots do
                CreateClientConVar("vrmod_pouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
                CreateClientConVar("vrmod_pouch_size_" .. i, 12, true, FCVAR_ARCHIVE)
                pouch.locked[i] = false
            end

            return pouch
        end

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

        local function IsVRReady()
            return g_VR and g_VR.active and g_VR.threePoints
        end

        hook.Add(
            "VRMod_Start",
            "HolsterSystem_Init",
            function()
                local pouch = InitializeHolsterSystem()
                if not IsVRReady() then return end
                prev_hand_in_holster_left_status = {}
                prev_hand_in_holster_right_status = {}
                holster_pickup_pending = {} -- VR開始時にクリア
                for i = 1, pouch_slots do
                    prev_hand_in_holster_left_status[i] = false
                    prev_hand_in_holster_right_status[i] = false
                end

                RunConsoleCommand("vrmod_lua_reset_holster2")
            end
        )

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
            pouch_sizes[i] = GetConVar("vrmod_pouch_size_" .. i):GetFloat()
        end

        hook.Add(
            "VRMod_Tracking",
            "vrmod_holster_follow_player",
            function()
                if not pouch_enabled:GetBool() then return end
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

        local function equipWeaponOrEntity(leftHand)
            if not pouch_enabled:GetBool() then return end
            if not g_VR.active then return end
            for i = 1, pouch_slots do
                local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
                if hand_pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i]) then
                    local wepclass = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                    if wepclass ~= "" then
                        -- 武器の場合
                        if weapons.Get(wepclass) then
                            if leftHand and not pouch_lefthand_weapon_enable:GetBool() then return end
                            LocalPlayer():ConCommand("use " .. wepclass)
                            if leftHand and string.find(wepclass, "vr") then
                                LocalPlayer():ConCommand("vrmod_LeftHandmode 0")
                            else
                                LocalPlayer():ConCommand("vrmod_lefthand " .. (leftHand and "1" or "0"))
                            end

                            surface.PlaySound(pouch_pickup_sound:GetString())
                            -- 武器を取り出した後、手に追従させるためにvrmod.Pickupを呼び出す
                            -- 武器がアクティブになるのを少し待つ
                            timer.Simple(
                                0.1,
                                function()
                                    if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == wepclass then
                                        if vrmod and vrmod.Pickup then
                                            vrmod.Pickup(leftHand, false)
                                        end
                                    end
                                end
                            )
                        else -- エンティティの場合
                            net.Start("vrmod_test_spawn_entity")
                            net.WriteString(wepclass)
                            net.WriteVector(hand_pos)
                            net.WriteAngle(leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang)
                            net.WriteBool(leftHand)
                            net.SendToServer()
                            surface.PlaySound(pouch_pickup_sound:GetString())
                            -- どのエンティティがホルスターからのものかを識別するため、クラス名とリクエスト時刻を保存
                            holster_pickup_pending[wepclass] = {
                                leftHand = leftHand,
                                time = CurTime()
                            }
                        end
                    end

                    break
                end
            end
        end

        hook.Add(
            "VRMod_Input",
            "vrutil_hook_pouchinput",
            function(action, pressed)
                if not g_VR.active then return end
                if not pouch_enabled:GetBool() then return end
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
                                heldEntity:Remove()
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

                -- equipWeaponOrEntity は修正済み関数が使われる
                if action == "boolean_left_pickup" and not pressed then
                    storeWeapon(true)
                elseif action == "boolean_right_pickup" and not pressed then
                    storeWeapon(false)
                end

                if action == "boolean_left_pickup" and pressed then
                    equipWeaponOrEntity(true)
                    timer.Simple(
                        0.30,
                        function()
                            vrmod.Pickup(true, not pressed)
                        end
                    )
                elseif action == "boolean_right_pickup" and pressed then
                    equipWeaponOrEntity(false)
                    timer.Simple(
                        0.30,
                        function()
                            vrmod.Pickup(false, not pressed)
                        end
                    )
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
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_hud:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    local is_currently_in_holster_left = g_VR.tracking.pose_lefthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                    if is_currently_in_holster_left then
                        local text = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                        if text ~= "" then
                            if pouch_locked[i] then
                                text = "*" .. text .. "*"
                            end

                            draw.SimpleText(text, "DermaLarge", ScrW() * 0.05, ScrH() * 0.9, Color(255, 255, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end

                        if not (prev_hand_in_holster_left_status[i] == true) then
                            VRMOD_TriggerHaptic("vibration_left", 0, 0.01, 0.01, 0.01)
                        end

                        if not IsValid(ply) then break end
                    end

                    prev_hand_in_holster_left_status[i] = is_currently_in_holster_left
                end
            end
        )

        hook.Add(
            "HUDPaint",
            "vrmod_holstarsystem_right_hudpaint",
            function()
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_hud:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    local is_currently_in_holster_right = g_VR.tracking.pose_righthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                    if is_currently_in_holster_right then
                        local text = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                        if text ~= "" then
                            if pouch_locked[i] then
                                text = "*" .. text .. "*"
                            end

                            draw.SimpleText(text, "DermaLarge", ScrW() * 0.95, ScrH() * 0.9, Color(255, 255, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        end

                        if not (prev_hand_in_holster_right_status[i] == true) then
                            VRMOD_TriggerHaptic("vibration_right", 0, 0.01, 0.01, 0.01)
                        end

                        if not IsValid(ply) then break end
                    end

                    prev_hand_in_holster_right_status[i] = is_currently_in_holster_right
                end
            end
        )

        hook.Add(
            "PostDrawTranslucentRenderables",
            "vrmod_holstarsystem_draw",
            function(depth, sky)
                if not pouch_enabled:GetBool() then return end
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

        -- エンティティがピックアップされた際にvrmod.Pickupを呼び出すフック
        hook.Add(
            "VRMod_Pickup",
            "HolsterSystem_ClientPickupAfterServer",
            function(ply, ent)
                if ply ~= LocalPlayer() then return end
                if not IsValid(ent) then return end
                local entClass = ent:GetClass()
                if holster_pickup_pending[entClass] then
                    local data = holster_pickup_pending[entClass]
                    -- スポーンリクエストから時間が経ちすぎている場合は無視
                    -- 2秒以内
                    if CurTime() - data.time < 2.0 then
                        if vrmod and vrmod.Pickup then
                            vrmod.Pickup(data.leftHand, false)
                        end

                        holster_pickup_pending[entClass] = nil -- 処理済み
                    end
                end
            end
        )

        -- holster_pickup_pending のクリーンアップ処理
        hook.Add(
            "Think",
            "HolsterSystem_CleanupPending",
            function()
                if not holster_pickup_pending then return end
                for class, data in pairs(holster_pickup_pending) do
                    -- 5秒以上経過したものは削除
                    if CurTime() - data.time >= 5.0 then
                        holster_pickup_pending[class] = nil
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
                function followAndTryPickup()
                    if not IsValid(spawnedEnt) then return end
                    spawnedEnt:Spawn()
                    spawnedEnt:SetPos(handPos)
                    spawnedEnt:SetAngles(handAng)
                    if IsValid(spawnedEnt) then
                        pickup(ply, isLeftHand, spawnedEnt:GetPos(), spawnedEnt:GetAngles())
                        timer.Simple(
                            0.30,
                            function()
                                -- pickup関数が存在し、引数が有効か確認
                                if IsValid(ply) and IsValid(spawnedEnt) then
                                    spawnedEnt:SetPos(handPos)
                                    spawnedEnt:SetAngles(handAng)
                                end

                                timer.Remove(ply:UserID() .. "followAndTryPickup")
                            end
                        )
                    end
                end

                timer.Create(ply:UserID() .. "followAndTryPickup", 0.30, 0, followAndTryPickup)
            end
        )
    end
end

vrholstersystem2()
concommand.Add(
    "vrmod_lua_reset_holster2",
    function(ply, cmd, args)
        AddCSLuaFile("vrmodunoffcial/2/vrmod_holstarsystem_type2.lua")
        include("vrmodunoffcial/2/vrmod_holstarsystem_type2.lua")
        vrholstersystem2()
    end
)
--------[vrmod_holstarsystem_type2.lua]End--------   