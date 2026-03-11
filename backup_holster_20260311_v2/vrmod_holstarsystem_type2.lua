--------[vrmod_holstarsystemtype2_type2.lua]Start--------
function vrholstersystem2()
    if CLIENT then
        local convars, convarValues = vrmod.GetConvars()

        -- AABB (Axis-Aligned Bounding Box) 判定関数
        local function IsHandInBox(hand_pos, box_center, box_width, box_height, box_depth)
            local half_x = box_width / 2
            local half_y = box_height / 2
            local half_z = box_depth / 2

            local dx = math.abs(hand_pos.x - box_center.x)
            local dy = math.abs(hand_pos.y - box_center.y)
            local dz = math.abs(hand_pos.z - box_center.z)

            return dx <= half_x and dy <= half_y and dz <= half_z
        end

        local pouch_slots = 8
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
        local pouch_slot_enabled = {}
        for i = 1, pouch_slots do
            CreateClientConVar("vrmod_pouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_pouch_size_" .. i, 12, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_slot_enabled_" .. i, 1, true, FCVAR_ARCHIVE, nil, 0, 1)
            -- Box形状用ConVar
            CreateClientConVar("vrmod_unoff_pouch_shape_" .. i, "sphere", true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_width_" .. i, 10, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_height_" .. i, 15, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_depth_" .. i, 5, true, FCVAR_ARCHIVE)
            pouch_locked[i] = false
            pouch_slot_enabled[i] = GetConVar("vrmod_unoff_pouch_slot_enabled_" .. i)
        end

        local function InitializeHolsterSystem()
            local convars = vrmod.GetConvars()
            local pouch = {
                slots = 8,
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

                -- Slot 6-8: ボーンベース追従（Type1と同一方式）
                local charYaw = Angle(0, g_VR.characterYaw, 0)
                -- Slot 6: Pelvis
                local pelvisBone = ply:LookupBone("ValveBiped.Bip01_Pelvis")
                if pelvisBone then
                    local pelvisMatrix = ply:GetBoneMatrix(pelvisBone)
                    if pelvisMatrix then
                        pouch_positions[6] = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), pelvisMatrix:GetTranslation(), charYaw)
                    end
                end
                -- Slot 7: Head（headVisible時はボーン、非表示時はHMD+10z）
                local headVisible = GetConVar("vrmod_head_visible")
                if headVisible and headVisible:GetBool() then
                    local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
                    if headBone then
                        local headMatrix = ply:GetBoneMatrix(headBone)
                        if headMatrix then
                            pouch_positions[7] = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), headMatrix:GetTranslation(), charYaw)
                        end
                    end
                else
                    pouch_positions[7] = g_VR.tracking.hmd.pos + Vector(0, 0, 10)
                end
                -- Slot 8: Spine
                local spineBone = ply:LookupBone("ValveBiped.Bip01_Neck1")
                if spineBone then
                    local spineMatrix = ply:GetBoneMatrix(spineBone)
                    if spineMatrix then
                        pouch_positions[8] = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), spineMatrix:GetTranslation(), charYaw)
                    end
                end
            end
        )

        local function equipWeaponOrEntity(leftHand)
            if not pouch_enabled:GetBool() then return end
            if not g_VR.active then return end
            for i = 1, pouch_slots do
                local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos

                -- 形状に応じた判定
                local is_in_holster = false
                if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                    local shape = GetConVar("vrmod_unoff_pouch_shape_" .. i):GetString()
                    if shape == "box" then
                        local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                        local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                        local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                        is_in_holster = IsHandInBox(hand_pos, pouch_positions[i], width, height, depth)
                    else
                        is_in_holster = hand_pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                    end
                end

                if is_in_holster then
                    local wepclass = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                    if wepclass ~= "" then
                        -- Dupeスロットの場合
                        if vrmod.HolsterDupe and vrmod.HolsterDupe.IsDupeSlot and vrmod.HolsterDupe.IsDupeSlot(i) then
                            vrmod.HolsterDupe.SpawnDupe(i, hand_pos,
                                leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang,
                                leftHand)
                            surface.PlaySound(pouch_pickup_sound:GetString())
                            break
                        end
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

                        -- 形状に応じた判定
                        local shape = GetConVar("vrmod_unoff_pouch_shape_" .. i):GetString()
                        local is_in_holster = false

                        if shape == "box" then
                            local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                            local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                            local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                            is_in_holster = IsHandInBox(hand_pos, pouch_positions[i], width, height, depth)
                        else
                            is_in_holster = hand_pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                        end

                        if is_in_holster then
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
                                -- Dupe保存: サーバー側でduplicator.Copyを実行
                                if vrmod.HolsterDupe and vrmod.HolsterDupe.StoreEntity then
                                    vrmod.HolsterDupe.StoreEntity(i, heldEntity, leftHand)
                                    -- サーバーがエンティティ群を削除するのでクライアント側Remove不要
                                else
                                    -- Fallback: 既存パス（クラス名のみ保存）
                                    LocalPlayer():ConCommand("vrmod_pouch_weapon_" .. i .. " " .. heldEntity:GetClass())
                                    heldEntity:Remove()
                                end
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
                elseif action == "boolean_right_pickup" and pressed then
                    equipWeaponOrEntity(false)
                end

                if action == "boolean_use" and pressed then
                    for i = 1, pouch_slots do
                        if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                            -- 形状に応じた判定（左手）
                            local shape = GetConVar("vrmod_unoff_pouch_shape_" .. i):GetString()
                            local is_in_holster_left = false

                            if shape == "box" then
                                local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                                local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                                local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                                is_in_holster_left = IsHandInBox(g_VR.tracking.pose_lefthand.pos, pouch_positions[i], width, height, depth)
                            else
                                is_in_holster_left = g_VR.tracking.pose_lefthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                            end

                            if is_in_holster_left then
                                pouch_locked[i] = not pouch_locked[i]
                                break
                            end

                            -- 形状に応じた判定（右手）
                            local is_in_holster_right = false

                            if shape == "box" then
                                local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                                local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                                local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                                is_in_holster_right = IsHandInBox(g_VR.tracking.pose_righthand.pos, pouch_positions[i], width, height, depth)
                            else
                                is_in_holster_right = g_VR.tracking.pose_righthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                            end

                            if is_in_holster_right then
                                pouch_locked[i] = not pouch_locked[i]
                                break
                            end
                        end
                    end
                end
            end
        )

        hook.Add(
            "HUDPaint",
            "vrmod_holstarsystemtype2_left_hudpaint",
            function()
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_hud:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    -- 形状に応じた判定（左手HUD）
                    local is_currently_in_holster_left = false
                    if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                        local shape = GetConVar("vrmod_unoff_pouch_shape_" .. i):GetString()
                        if shape == "box" then
                            local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                            local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                            local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                            is_currently_in_holster_left = IsHandInBox(g_VR.tracking.pose_lefthand.pos, pouch_positions[i], width, height, depth)
                        else
                            is_currently_in_holster_left = g_VR.tracking.pose_lefthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                        end
                    end

                    if is_currently_in_holster_left then
                        local text = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                        if text ~= "" then
                            if pouch_locked[i] then
                                text = "*" .. text .. "*"
                            end

                            draw.SimpleText(text, "DermaLarge", ScrW() * 0.05, ScrH() * 0.9, Color(255, 255, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end

                        -- if not (prev_hand_in_holster_left_status[i] == true) then
                        --     VRMOD_TriggerHaptic("vibration_left", 0, 0.01, 0.01, 0.01)
                        -- end

                        if not IsValid(ply) then break end
                    end

                    prev_hand_in_holster_left_status[i] = is_currently_in_holster_left
                end
            end
        )

        hook.Add(
            "HUDPaint",
            "vrmod_holstarsystemtype2_right_hudpaint",
            function()
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_hud:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    -- 形状に応じた判定（右手HUD）
                    local is_currently_in_holster_right = false
                    if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                        local shape = GetConVar("vrmod_unoff_pouch_shape_" .. i):GetString()
                        if shape == "box" then
                            local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                            local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                            local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                            is_currently_in_holster_right = IsHandInBox(g_VR.tracking.pose_righthand.pos, pouch_positions[i], width, height, depth)
                        else
                            is_currently_in_holster_right = g_VR.tracking.pose_righthand.pos:DistToSqr(pouch_positions[i]) < (pouch_sizes[i] * pouch_sizes[i])
                        end
                    end

                    if is_currently_in_holster_right then
                        local text = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                        if text ~= "" then
                            if pouch_locked[i] then
                                text = "*" .. text .. "*"
                            end

                            draw.SimpleText(text, "DermaLarge", ScrW() * 0.95, ScrH() * 0.9, Color(255, 255, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        end

                        -- if not (prev_hand_in_holster_right_status[i] == true) then
                        --     VRMOD_TriggerHaptic("vibration_right", 0, 0.01, 0.01, 0.01)
                        -- end

                        if not IsValid(ply) then break end
                    end

                    prev_hand_in_holster_right_status[i] = is_currently_in_holster_right
                end
            end
        )

        hook.Add(
            "PostDrawTranslucentRenderables",
            "vrmod_holstarsystemtype2_draw",
            function(depth, sky)
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_name:GetBool() then return end
                if not g_VR.threePoints or EyePos() ~= g_VR.view.origin then return end
                for i = 1, pouch_slots do
                  if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                    local pos = pouch_positions[i]
                    local shape = GetConVar("vrmod_unoff_pouch_shape_" .. i):GetString()
                    render.SetColorMaterial()
                    local color = pouch_locked[i] and Color(146, 253, 110, 80) or Color(255, 255, 255, 128)

                    -- 形状に応じた可視化
                    if shape == "box" then
                        local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                        local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                        local depth = GetConVar("vrmod_unoff_pouch_box_depth_" .. i):GetFloat()
                        local mins = Vector(-width/2, -height/2, -depth/2)
                        local maxs = Vector(width/2, height/2, depth/2)
                        render.DrawWireframeBox(pos, Angle(0,0,0), mins, maxs, color)
                    else
                        local size = pouch_sizes[i]
                        render.DrawSphere(pos, size, 16, 50, color)
                    end

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
                        timer.Simple(
                            0.08,
                            function()
                                -- pickup関数が存在し、引数が有効か確認
                                if IsValid(ply) and IsValid(spawnedEnt) then
                                    pickup(ply, isLeftHand, spawnedEnt:GetPos(), spawnedEnt:GetAngles())
                                    spawnedEnt:SetPos(handPos)
                                    spawnedEnt:SetAngles(handAng)
                                end

                                timer.Remove(ply:UserID() .. "followAndTryPickup")
                            end
                        )
                    end
                end

                timer.Create(ply:UserID() .. "followAndTryPickup", 0.08, 0, followAndTryPickup)
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
--------[vrmod_holstarsystemtype2_type2.lua]End--------   