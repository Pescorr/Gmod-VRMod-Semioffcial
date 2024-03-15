if SERVER then return end
-- 以下は左手用のコードです。基本的に右手用のコードを複製し、関連する部分を左手用に変更しています。
-- この部分は右手用の機能を左手用として追加するためのもので、基本的な構造は右手用のコードと同じです。
-- 左手用のConVar定義
local weppouch_left_pelvis = CreateClientConVar("vrmod_weppouch_left_Pelvis", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_left_head = CreateClientConVar("vrmod_weppouch_left_Head", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_left_spine = CreateClientConVar("vrmod_weppouch_left_Spine", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_weapon_left_pelvis = CreateClientConVar("vrmod_weppouch_weapon_left_Pelvis", "", true, FCVAR_ARCHIVE)
local weppouch_weapon_left_head = CreateClientConVar("vrmod_weppouch_weapon_left_Head", "", true, FCVAR_ARCHIVE)
local weppouch_weapon_left_spine = CreateClientConVar("vrmod_weppouch_weapon_left_Spine", "", true, FCVAR_ARCHIVE)
local weppouch_weapon_lock_left_pelvis = CreateClientConVar("vrmod_weppouch_weapon_lock_left_Pelvis", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_weapon_lock_left_head = CreateClientConVar("vrmod_weppouch_weapon_lock_left_Head", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_weapon_lock_left_spine = CreateClientConVar("vrmod_weppouch_weapon_lock_left_Spine", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local customconver_left_pelvis = CreateClientConVar("vrmod_weppouch_customcvar_left_pelvis_enable", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local customconver_left_head = CreateClientConVar("vrmod_weppouch_customcvar_left_head_enable", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local customconver_left_spine = CreateClientConVar("vrmod_weppouch_customcvar_left_spine_enable", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local customconver_left_pelvis_cmd = CreateClientConVar("vrmod_weppouch_customcvar_left_pelvis_cmd", "vrmod_test_pickup_entspawn_left vrmod_magent", true, FCVAR_ARCHIVE)
local customconver_left_head_cmd = CreateClientConVar("vrmod_weppouch_customcvar_left_head_cmd", "vrmod_test_pickup_entspawn_left vrmod_magent", true, FCVAR_ARCHIVE)
local customconver_left_spine_cmd = CreateClientConVar("vrmod_weppouch_customcvar_left_spine_cmd", "vrmod_test_pickup_entspawn_left vrmod_magent", true, FCVAR_ARCHIVE)
local customconver_left_pelvis_cmd_put = CreateClientConVar("vrmod_weppouch_customcvar_left_pelvis_put_cmd", "+use,-use", true, FCVAR_ARCHIVE)
local customconver_left_head_cmd_put = CreateClientConVar("vrmod_weppouch_customcvar_left_head_put_cmd", "+use,-use", true, FCVAR_ARCHIVE)
local customconver_left_spine_cmd_put = CreateClientConVar("vrmod_weppouch_customcvar_left_spine_put_cmd", "+use,-use", true, FCVAR_ARCHIVE)
-- 新しいConVarを作成してポーチの範囲を記録
local weppouchsize_pelvis_left = CreateClientConVar("vrmod_weppouch_left_dist_Pelvis", 12.5, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local weppouchsize_head_left = CreateClientConVar("vrmod_weppouch_left_dist_head", 10.0, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local weppouchsize_spine_left = CreateClientConVar("vrmod_weppouch_left_dist_spine", 0.0, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
-- pelvis pouch (左手バージョン)
-- if weppouch_left_pelvis:GetBool() then
    hook.Add(
        "VRMod_Input",
        "vrutil_hook_weppouchinput_pelvis_left",
        function(action, pressed)
            if weppouch_left_pelvis:GetBool() then
                local weppouchbone_pelvis_left = "ValveBiped.Bip01_Pelvis"
                local weppouchdist_left = g_VR.eyePosRight
                if LocalPlayer():LookupBone(weppouchbone_pelvis_left) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_pelvis_left)) then
                    weppouchdist_left = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_pelvis_left)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                    if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_pelvis_left:GetFloat() * weppouchsize_pelvis_left:GetFloat()) then
                        debugoverlay.Sphere(weppouchdist_left, weppouchsize_pelvis_left:GetFloat(), 1, Color(255, 0, 0, 255), true) -- 追加
                        VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                        if action == "boolean_left_pickup" and pressed then
                            if customconver_left_pelvis:GetBool() then
                                LocalPlayer():ConCommand(customconver_left_pelvis_cmd:GetString())
                                -- LocalPlayer():ConCommand("vrmod_lefthand 1")
                            else
                                -- 左手用の武器の取り出し処理
                                LocalPlayer():ConCommand("use " .. weppouch_weapon_left_pelvis:GetString())
                                LocalPlayer():ConCommand("vrmod_lefthand 1")
                            end
                        elseif action == "boolean_left_pickup" and not pressed then
                            if customconver_left_pelvis:GetBool() then
                                -- カスタムコマンド用の記録ConVarの実行
                                LocalPlayer():ConCommand(customconver_left_pelvis_cmd_put:GetString())
                            else
                                -- 現在の武器を記録し、武器を空にする
                                if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                    if not weppouch_weapon_lock_left_pelvis:GetBool() then
                                        LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Pelvis " .. LocalPlayer():GetActiveWeapon():GetClass())
                                    end

                                    LocalPlayer():ConCommand("use weapon_vrmod_empty")
                                end
                            end
                        end

                        -- 武器のロック/アンロック処理
                        if action == "boolean_use" and pressed then
                            if not weppouch_weapon_lock_left_pelvis:GetBool() then
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Pelvis 1")
                            else
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Pelvis 0")
                            end
                        end
                    end
                end
            end
        end
    )
-- end

-- head pouch (左手バージョン)
-- if weppouch_left_head:GetBool() then
    hook.Add(
        "VRMod_Input",
        "vrutil_hook_weppouchinput_head_left",
        function(action, pressed)
            if weppouch_left_head:GetBool() then
                local weppouchbone_head_left = "ValveBiped.Bip01_Head1"
                local weppouchdist_left = g_VR.eyePosRight
                if LocalPlayer():LookupBone(weppouchbone_head_left) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_head_left)) then
                    weppouchdist_left = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_head_left)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                    if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_head_left:GetFloat() * weppouchsize_head_left:GetFloat()) then
                        debugoverlay.Sphere(weppouchdist_left, weppouchsize_head_left:GetFloat(), 1, Color(0, 255, 0, 255), true)
                        VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                        if action == "boolean_left_pickup" and pressed then
                            if customconver_left_head:GetBool() then
                                LocalPlayer():ConCommand(customconver_left_head_cmd:GetString())
                                -- LocalPlayer():ConCommand("vrmod_lefthand 1")
                            else
                                LocalPlayer():ConCommand("use " .. weppouch_weapon_left_head:GetString())
                                LocalPlayer():ConCommand("vrmod_lefthand 1")
                            end
                        elseif action == "boolean_left_pickup" and not pressed then
                            if customconver_left_head:GetBool() then
                                LocalPlayer():ConCommand(customconver_left_head_cmd_put:GetString())
                            else
                                if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                    if not weppouch_weapon_lock_left_head:GetBool() then
                                        LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Head " .. LocalPlayer():GetActiveWeapon():GetClass())
                                    end

                                    LocalPlayer():ConCommand("use weapon_vrmod_empty")
                                end
                            end
                        end

                        if action == "boolean_use" and pressed then
                            if not weppouch_weapon_lock_left_head:GetBool() then
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Head 1")
                            else
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Head 0")
                            end
                        end
                    end
                end
            end
        end
    )
-- end

-- spine pouch (左手バージョン)
-- if weppouch_left_spine:GetBool() then
    hook.Add(
        "VRMod_Input",
        "vrutil_hook_weppouchinput_spine_left",
        function(action, pressed)
            if weppouch_left_spine:GetBool() then
                local weppouchbone_spine_left = "ValveBiped.Bip01_Spine"
                local weppouchdist_left = g_VR.eyePosRight
                if LocalPlayer():LookupBone(weppouchbone_spine_left) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_spine_left)) then
                    weppouchdist_left = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_spine_left)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                    if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_spine_left:GetFloat() * weppouchsize_spine_left:GetFloat()) then
                        debugoverlay.Sphere(weppouchdist_left, weppouchsize_spine_left:GetFloat(), 1, Color(0, 0, 255, 255), true)
                        VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                        if action == "boolean_left_pickup" and pressed then
                            if customconver_left_spine:GetBool() then
                                LocalPlayer():ConCommand(customconver_left_spine_cmd:GetString())
                                -- LocalPlayer():ConCommand("vrmod_lefthand 1")
                            else
                                LocalPlayer():ConCommand("use " .. weppouch_weapon_left_spine:GetString())
                                LocalPlayer():ConCommand("vrmod_lefthand 1")
                            end
                        elseif action == "boolean_left_pickup" and not pressed then
                            if customconver_left_spine:GetBool() then
                                LocalPlayer():ConCommand(customconver_left_spine_cmd_put:GetString())
                            else
                                if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                    if not weppouch_weapon_lock_left_spine:GetBool() then
                                        LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Spine " .. LocalPlayer():GetActiveWeapon():GetClass())
                                    end

                                    LocalPlayer():ConCommand("use weapon_vrmod_empty")
                                end
                            end
                        end

                        if action == "boolean_use" and pressed then
                            if not weppouch_weapon_lock_left_spine:GetBool() then
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Spine 1")
                            else
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Spine 0")
                            end
                        end
                    end
                end
            end
        end
    )
-- end
-- ここまでが左手用のコードです。右手用のコードと同様に、左手の位置に基づいて武器の出し入れを行います。
-- このコードは左手の位置とアクションに基づく処理を含んでおり、右手用の機能を左手用に対応させるために必要な変更を加えています。