--------[vrmod_holstarsystemtype2_type2.lua]Start--------
function vrholstersystem2()
    if CLIENT then
        local convars, convarValues = vrmod.GetConvars()

        -- 安全なボーンワールド位置取得（nilチェック付き）
        local function SafeGetBoneWorldPos(ply, boneName, offset, yawAngle)
            if not IsValid(ply) then return nil end
            local boneId = ply:LookupBone(boneName)
            if not boneId then return nil end
            local matrix = ply:GetBoneMatrix(boneId)
            if not matrix then return nil end
            return LocalToWorld(offset or Vector(3, 3, 0), Angle(0, 0, 0), matrix:GetTranslation(), yawAngle or Angle(0, 0, 0))
        end

        -- 安全なボーン位置取得（pos, ang返却版）
        local function SafeGetBonePosition(ply, boneName)
            if not IsValid(ply) then return nil, nil end
            local boneId = ply:LookupBone(boneName)
            if not boneId then return nil, nil end
            return ply:GetBonePosition(boneId)
        end

        -- S20 Problem 5: OBB判定（キャラクターYawで回転、Z軸非対称）
        local function IsHandInBox(hand_pos, box_center, box_width, box_height, depth_up, depth_down, yaw)
            local half_x = box_width / 2
            local half_y = box_height / 2
            local offset = hand_pos - box_center
            -- キャラクターYawの逆回転で手の位置をボックスローカル座標に変換
            local rad = math.rad(-(yaw or 0))
            local cos_r, sin_r = math.cos(rad), math.sin(rad)
            local local_x = offset.x * cos_r - offset.y * sin_r
            local local_y = offset.x * sin_r + offset.y * cos_r
            return math.abs(local_x) <= half_x and math.abs(local_y) <= half_y and offset.z <= depth_up and offset.z >= -depth_down
        end

        local pouch_slots = 8
        local pouch_weapons = {}
        local pouch_positions = {}
        local pouch_initial_positions = {}
        local pouch_sizes = {}
        local pouch_enabled = CreateClientConVar("vrmod_pouch_enabled", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
        local pouch_visible_name = CreateClientConVar("vrmod_pouch_visiblename", 0, true, FCVAR_ARCHIVE, nil, 0, 1)
        local pouch_lefthand_weapon_enable = CreateClientConVar("vrmod_pouch_lefthandwep_enable", "1", true, FCVAR_ARCHIVE)
        local pouch_visible_hud = CreateClientConVar("vrmod_pouch_visiblename_hud", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
        local pouch_saved_positions = {}
        local pouch_locked_cvars_left = {}
        local pouch_locked_cvars_right = {}
        local pouch_locked_left = {}
        local pouch_locked_right = {}
        local pouch_lr_sync = CreateClientConVar("vrmod_pouch_lr_sync", "0", true, FCVAR_ARCHIVE)
        local pouch_pickup_sound = CreateClientConVar("vrmod_pouch_pickup_sound", "common/wpn_select.wav", true, FCVAR_ARCHIVE)
        local prev_hand_in_holster_left_status = {}
        local prev_hand_in_holster_right_status = {}
        local holster_pickup_pending = {}
        -- heldEntityキャッシュ: VRMod_Inputのhook実行順序に依存しないためのフレーム先行キャッシュ
        -- vrmod.Pickup(hand,true) がheldEntityを消去した後でもstoreWeapon()が読めるようにする
        local cachedHeldLeft, cachedHeldRight
        hook.Add("Think", "vrutil_holster_heldcache", function()
            if g_VR then
                cachedHeldLeft = g_VR.heldEntityLeft
                cachedHeldRight = g_VR.heldEntityRight
            end
        end)
        local pouch_slot_enabled = {}
        for i = 1, pouch_slots do
            CreateClientConVar("vrmod_pouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_pouch_size_" .. i, 12, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_slot_enabled_" .. i, 1, true, FCVAR_ARCHIVE, nil, 0, 1)
            -- Box形状用ConVar（改善1: depth → depth_up + depth_down）
            CreateClientConVar("vrmod_unoff_pouch_shape_" .. i, "box", true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_width_" .. i, 22, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_height_" .. i, 22, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_depth_up_" .. i, 5, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_box_depth_down_" .. i, 5, true, FCVAR_ARCHIVE)
            CreateClientConVar("vrmod_unoff_pouch_locked_" .. i, 0, true, FCVAR_ARCHIVE, nil, 0, 1) -- legacy compat
            CreateClientConVar("vrmod_unoff_pouch_locked_" .. i .. "_left", 0, true, FCVAR_ARCHIVE, nil, 0, 1)
            CreateClientConVar("vrmod_unoff_pouch_locked_" .. i .. "_right", 0, true, FCVAR_ARCHIVE, nil, 0, 1)
            pouch_locked_cvars_left[i] = GetConVar("vrmod_unoff_pouch_locked_" .. i .. "_left")
            pouch_locked_cvars_right[i] = GetConVar("vrmod_unoff_pouch_locked_" .. i .. "_right")
            pouch_locked_left[i] = pouch_locked_cvars_left[i]:GetBool()
            pouch_locked_right[i] = pouch_locked_cvars_right[i]:GetBool()
            pouch_slot_enabled[i] = GetConVar("vrmod_unoff_pouch_slot_enabled_" .. i)
        end

        -- S20 Problem 1+2: 全スロットの左手用weapon ConVar（旧: 6-8のみ）
        for i = 1, 8 do
            CreateClientConVar("vrmod_pouch_weapon_" .. i .. "_left", "", true, FCVAR_ARCHIVE)
        end

        -- 改善3: スロット別カラーコーディング
        local SLOT_COLORS = {
            Color(0, 255, 0, 200),    -- Slot 1: Head Right    → GREEN
            Color(0, 255, 0, 200),    -- Slot 2: Head Left     → GREEN
            Color(0, 128, 255, 200),  -- Slot 3: Chest Right   → LIGHT BLUE
            Color(0, 128, 255, 200),  -- Slot 4: Chest Left    → LIGHT BLUE
            Color(255, 128, 0, 200),  -- Slot 5: Chest Center  → ORANGE
            Color(255, 0, 0, 200),    -- Slot 6: Pelvis (Bone) → RED
            Color(0, 255, 128, 200),  -- Slot 7: Head (Bone)   → CYAN-GREEN
            Color(128, 0, 255, 200),  -- Slot 8: Spine (Bone)  → PURPLE
        }

        -- S20 Problem 1+2: 全スロットでL/R独立対応 + L/R同期モード
        local BONE_SLOT_START = 6
        local function GetWeaponConVarName(slotIndex, leftHand)
            if leftHand and not pouch_lr_sync:GetBool() then
                return "vrmod_pouch_weapon_" .. slotIndex .. "_left"
            end
            return "vrmod_pouch_weapon_" .. slotIndex
        end
        local function GetDupeSlotIndex(slotIndex, leftHand)
            if not leftHand or pouch_lr_sync:GetBool() then return slotIndex end
            if slotIndex >= BONE_SLOT_START then
                return slotIndex + 3  -- 6→9, 7→10, 8→11（既存互換）
            end
            return slotIndex + 11  -- 1→12, 2→13, 3→14, 4→15, 5→16
        end
        -- S20追加: 左右手別ロック判定
        local function IsSlotLocked(slotIndex, leftHand)
            if pouch_lr_sync:GetBool() then
                return pouch_locked_right[slotIndex]
            end
            if leftHand then
                return pouch_locked_left[slotIndex]
            end
            return pouch_locked_right[slotIndex]
        end

        -- sphere/box共通判定ヘルパー
        local function IsHandInSlot(hand_pos, slotIndex)
            local shape = GetConVar("vrmod_unoff_pouch_shape_" .. slotIndex):GetString()
            if shape == "box" then
                local width = GetConVar("vrmod_unoff_pouch_box_width_" .. slotIndex):GetFloat()
                local height = GetConVar("vrmod_unoff_pouch_box_height_" .. slotIndex):GetFloat()
                local depth_up = GetConVar("vrmod_unoff_pouch_box_depth_up_" .. slotIndex):GetFloat()
                local depth_down = GetConVar("vrmod_unoff_pouch_box_depth_down_" .. slotIndex):GetFloat()
                -- S20 Problem 5: キャラクターYawで回転するOBB判定
                local yaw = g_VR and g_VR.characterYaw or 0
                return IsHandInBox(hand_pos, pouch_positions[slotIndex], width, height, depth_up, depth_down, yaw)
            else
                return hand_pos:DistToSqr(pouch_positions[slotIndex]) < (pouch_sizes[slotIndex] * pouch_sizes[slotIndex])
            end
        end

        -- 最近接スロット選択（重複スロットで意図したスロットを選ぶ）
        local function FindClosestSlot(hand_pos)
            local closest_slot = nil
            local closest_dist = math.huge
            for i = 1, pouch_slots do
                if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                    if pouch_positions[i] and IsHandInSlot(hand_pos, i) then
                        local dist = hand_pos:DistToSqr(pouch_positions[i])
                        if dist < closest_dist then
                            closest_dist = dist
                            closest_slot = i
                        end
                    end
                end
            end
            return closest_slot
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
                holster_pickup_pending = {}
                for i = 1, pouch_slots do
                    prev_hand_in_holster_left_status[i] = false
                    prev_hand_in_holster_right_status[i] = false
                    -- ロック状態をConVarから復元（死亡→リスポーンでも保持される）
                    if pouch_locked_cvars_left[i] then
                        pouch_locked_left[i] = pouch_locked_cvars_left[i]:GetBool()
                    end
                    if pouch_locked_cvars_right[i] then
                        pouch_locked_right[i] = pouch_locked_cvars_right[i]:GetBool()
                    end
                end

                RunConsoleCommand("vrmod_lua_reset_holster2")
            end
        )

        hook.Add(
            "VRMod_Exit",
            "HolsterSystem_Cleanup",
            function()
                hook.Remove("Think", "vrutil_holster_heldcache")
                hook.Remove("Think", "HolsterSystem_CleanupPending")
                prev_hand_in_holster_left_status = {}
                prev_hand_in_holster_right_status = {}
                holster_pickup_pending = {}
                cachedHeldLeft = nil
                cachedHeldRight = nil
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
                if not g_VR.tracking.hmd then return end
                local chestPos, chestAng = SafeGetBonePosition(ply, "ValveBiped.Bip01_Spine")
                local hipPos, hipAng = SafeGetBonePosition(ply, "ValveBiped.Bip01_Pelvis")
                if not chestPos or not hipPos then return end
                local headPos, headAng = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
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
                -- 改善4: Slot 7: HMD位置を直接使用（Type1と同一方式）
                pouch_positions[7] = g_VR.tracking.hmd.pos
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

        -- 改善5: 左右手分離対応のequip
        local function equipWeaponOrEntity(leftHand)
            if not pouch_enabled:GetBool() then return end
            if not g_VR.active then return end
            local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
            local i = FindClosestSlot(hand_pos)
            if i then
                local wepConVar = GetWeaponConVarName(i, leftHand)
                local wepclass = GetConVar(wepConVar):GetString()
                if wepclass ~= "" then
                        -- Dupeスロットの場合
                        if string.StartWith(wepclass, "dupe:") then
                            if vrmod.HolsterDupe and vrmod.HolsterDupe.SpawnDupe then
                                vrmod.HolsterDupe.SpawnDupe(GetDupeSlotIndex(i, leftHand), hand_pos,
                                    leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang,
                                    leftHand)
                                surface.PlaySound(pouch_pickup_sound:GetString())
                            end
                            return
                        end
                        -- 武器の場合
                        if weapons.Get(wepclass) then
                            if leftHand and not pouch_lefthand_weapon_enable:GetBool() then return end
                            -- S20 Problem 4: 未所持武器チェック（Type1同等）
                            if not IsValid(LocalPlayer():GetWeapon(wepclass)) then
                                RunConsoleCommand(wepConVar, "")
                                return
                            end
                            LocalPlayer():ConCommand("use " .. wepclass)
                            if leftHand and string.find(wepclass, "vr") then
                                LocalPlayer():ConCommand("vrmod_LeftHandmode 0")
                            else
                                LocalPlayer():ConCommand("vrmod_lefthand " .. (leftHand and "1" or "0"))
                            end

                            surface.PlaySound(pouch_pickup_sound:GetString())
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
                            holster_pickup_pending[wepclass] = {
                                leftHand = leftHand,
                                time = CurTime()
                            }
                        end
                    end
                end
            end

        hook.Add(
            "VRMod_Input",
            "vrutil_hook_pouchinput",
            function(action, pressed)
                if not g_VR.active then return end
                if not pouch_enabled:GetBool() then return end
                -- クライミング中はホルスター入力をブロック
                if vrmod.ClimbFilter and vrmod.ClimbFilter.ShouldBlockAll() then return end

                -- 改善2: 最近接スロット方式ハプティック（入力イベント時のみ振動）
                local leftSlot = FindClosestSlot(g_VR.tracking.pose_lefthand.pos)
                if leftSlot then
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                end
                local rightSlot = FindClosestSlot(g_VR.tracking.pose_righthand.pos)
                if rightSlot then
                    VRMOD_TriggerHaptic("vibration_right", 0, 0.5, 20, 1)
                end

                -- 改善5: 左右手分離対応のstore
                local function storeWeapon(leftHand)
                    local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
                    local i = FindClosestSlot(hand_pos)
                    if not i then return end

                    local activeWeapon = LocalPlayer():GetActiveWeapon()
                    if IsValid(activeWeapon) and activeWeapon:GetClass() ~= "weapon_vrmod_empty" and ((leftHand and GetConVar("vrmod_lefthand"):GetBool()) or (not leftHand and not GetConVar("vrmod_lefthand"):GetBool())) then
                        if not IsSlotLocked(i, leftHand) then
                            local wepConVar = GetWeaponConVarName(i, leftHand)
                            RunConsoleCommand(wepConVar, activeWeapon:GetClass())
                        end

                        LocalPlayer():ConCommand("use weapon_vrmod_empty")
                        return
                    end

                    local heldEntity
                    if leftHand then
                        heldEntity = g_VR.heldEntityLeft or cachedHeldLeft
                    else
                        heldEntity = g_VR.heldEntityRight or cachedHeldRight
                    end
                    if IsValid(heldEntity) then
                        if IsSlotLocked(i, leftHand) then return end
                        if vrmod.HolsterDupe and vrmod.HolsterDupe.StoreEntity then
                            vrmod.HolsterDupe.StoreEntity(GetDupeSlotIndex(i, leftHand), heldEntity, leftHand)
                        else
                            local wepConVar = GetWeaponConVarName(i, leftHand)
                            RunConsoleCommand(wepConVar, heldEntity:GetClass())
                            heldEntity:Remove()
                        end
                        if leftHand then
                            g_VR.heldEntityLeft = nil
                            cachedHeldLeft = nil
                        else
                            g_VR.heldEntityRight = nil
                            cachedHeldRight = nil
                        end
                        return
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

                -- S20追加: 左右手別ロック切替
                if action == "boolean_use" and pressed then
                    local leftLockSlot = FindClosestSlot(g_VR.tracking.pose_lefthand.pos)
                    local rightLockSlot = FindClosestSlot(g_VR.tracking.pose_righthand.pos)
                    if leftLockSlot then
                        if pouch_lr_sync:GetBool() then
                            -- 同期モード: 共有ロック（right）を切替
                            pouch_locked_right[leftLockSlot] = not pouch_locked_right[leftLockSlot]
                            RunConsoleCommand("vrmod_unoff_pouch_locked_" .. leftLockSlot .. "_right", pouch_locked_right[leftLockSlot] and "1" or "0")
                        else
                            pouch_locked_left[leftLockSlot] = not pouch_locked_left[leftLockSlot]
                            RunConsoleCommand("vrmod_unoff_pouch_locked_" .. leftLockSlot .. "_left", pouch_locked_left[leftLockSlot] and "1" or "0")
                        end
                        VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    end
                    -- 同期モード＋同一スロットなら二重切替を防止
                    if rightLockSlot and not (pouch_lr_sync:GetBool() and rightLockSlot == leftLockSlot) then
                        pouch_locked_right[rightLockSlot] = not pouch_locked_right[rightLockSlot]
                        RunConsoleCommand("vrmod_unoff_pouch_locked_" .. rightLockSlot .. "_right", pouch_locked_right[rightLockSlot] and "1" or "0")
                        VRMOD_TriggerHaptic("vibration_right", 0, 0.5, 20, 1)
                    end
                end
            end
        )

        -- 改善3+5: 左手HUD（スロット色 + 左右分離）
        hook.Add(
            "HUDPaint",
            "vrmod_holstarsystemtype2_left_hudpaint",
            function()
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_hud:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    local is_currently_in_holster_left = false
                    if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                        is_currently_in_holster_left = IsHandInSlot(g_VR.tracking.pose_lefthand.pos, i)
                    end

                    if is_currently_in_holster_left then
                        local wepConVar = GetWeaponConVarName(i, true)
                        local text = GetConVar(wepConVar):GetString()
                        if text ~= "" then
                            if IsSlotLocked(i, true) then
                                text = "*" .. text .. "*"
                            end
                            draw.SimpleText(text, "DermaLarge", ScrW() * 0.05, ScrH() * 0.9, SLOT_COLORS[i], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end

                        if not IsValid(LocalPlayer()) then break end
                    end

                    prev_hand_in_holster_left_status[i] = is_currently_in_holster_left
                end
            end
        )

        -- 改善3+5: 右手HUD（スロット色 + 左右分離）
        hook.Add(
            "HUDPaint",
            "vrmod_holstarsystemtype2_right_hudpaint",
            function()
                if not pouch_enabled:GetBool() then return end
                if not pouch_visible_hud:GetBool() then return end
                if not g_VR.active then return end
                for i = 1, pouch_slots do
                    local is_currently_in_holster_right = false
                    if pouch_slot_enabled[i] and pouch_slot_enabled[i]:GetBool() then
                        is_currently_in_holster_right = IsHandInSlot(g_VR.tracking.pose_righthand.pos, i)
                    end

                    if is_currently_in_holster_right then
                        local wepConVar = GetWeaponConVarName(i, false)
                        local text = GetConVar(wepConVar):GetString()
                        if text ~= "" then
                            if IsSlotLocked(i, false) then
                                text = "*" .. text .. "*"
                            end
                            draw.SimpleText(text, "DermaLarge", ScrW() * 0.95, ScrH() * 0.9, SLOT_COLORS[i], TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        end

                        if not IsValid(LocalPlayer()) then break end
                    end

                    prev_hand_in_holster_right_status[i] = is_currently_in_holster_right
                end
            end
        )

        -- 改善1+3+5: 3D可視化（非対称ボックス + スロット色 + 左右テキスト）
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
                    local isAnyLocked = pouch_locked_left[i] or pouch_locked_right[i]
                    local color = isAnyLocked and Color(146, 253, 110, 80) or Color(255, 255, 255, 128)

                    if shape == "box" then
                        local width = GetConVar("vrmod_unoff_pouch_box_width_" .. i):GetFloat()
                        local height = GetConVar("vrmod_unoff_pouch_box_height_" .. i):GetFloat()
                        local d_up = GetConVar("vrmod_unoff_pouch_box_depth_up_" .. i):GetFloat()
                        local d_down = GetConVar("vrmod_unoff_pouch_box_depth_down_" .. i):GetFloat()
                        local mins = Vector(-width/2, -height/2, -d_down)
                        local maxs = Vector(width/2, height/2, d_up)
                        -- S20 Problem 5: キャラクターYawで回転描画
                        render.DrawWireframeBox(pos, Angle(0, g_VR.characterYaw or 0, 0), mins, maxs, color)
                    else
                        local size = pouch_sizes[i]
                        render.DrawSphere(pos, size, 16, 50, color)
                    end

                    local slotColor = Color(SLOT_COLORS[i].r, SLOT_COLORS[i].g, SLOT_COLORS[i].b)
                    local eyeAng = EyeAngles()
                    eyeAng:RotateAroundAxis(eyeAng:Right(), 60)

                    local rightClass = GetConVar("vrmod_pouch_weapon_" .. i):GetString()
                    local leftClass = GetConVar("vrmod_pouch_weapon_" .. i .. "_left"):GetString()
                    if pouch_lr_sync:GetBool() then
                        -- 同期モード: 単一表示（R/Lプレフィックスなし）
                        if rightClass ~= "" then
                            cam.Start3D2D(pos, eyeAng, 0.1)
                            draw.SimpleText(rightClass, "CloseCaption_Normal", 0, 0, slotColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            cam.End3D2D()
                        end
                    else
                        -- 独立モード: R/L両方表示
                        if rightClass ~= "" or leftClass ~= "" then
                            cam.Start3D2D(pos, eyeAng, 0.1)
                            if rightClass ~= "" then
                                draw.SimpleText("R: " .. rightClass, "CloseCaption_Normal", 0, -10, slotColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                            if leftClass ~= "" then
                                draw.SimpleText("L: " .. leftClass, "CloseCaption_Normal", 0, 10, slotColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                            cam.End3D2D()
                        end
                    end
                  end
                end
            end
        )

        hook.Add(
            "VRMod_Pickup",
            "HolsterSystem_ClientPickupAfterServer",
            function(ply, ent)
                if ply ~= LocalPlayer() then return end
                if not IsValid(ent) then return end
                local entClass = ent:GetClass()
                if holster_pickup_pending[entClass] then
                    local data = holster_pickup_pending[entClass]
                    if CurTime() - data.time < 2.0 then
                        if vrmod and vrmod.Pickup then
                            vrmod.Pickup(data.leftHand, false)
                        end
                        holster_pickup_pending[entClass] = nil
                    end
                end
            end
        )

        hook.Add(
            "Think",
            "HolsterSystem_CleanupPending",
            function()
                if not holster_pickup_pending then return end
                for class, data in pairs(holster_pickup_pending) do
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
