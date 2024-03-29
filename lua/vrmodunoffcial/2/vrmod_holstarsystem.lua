AddCSLuaFile()

if SERVER then return end
-- 既存のConVarはそのまま
local weppouch_pelvis = CreateClientConVar("vrmod_weppouch_Pelvis", 1, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_head = CreateClientConVar("vrmod_weppouch_Head", 1, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_spine = CreateClientConVar("vrmod_weppouch_Spine", 1, true, FCVAR_ARCHIVE, "", 0, 1)
-- 新しいConVarを作成して武器名を記録
local weppouch_weapon_pelvis = CreateClientConVar("vrmod_weppouch_weapon_Pelvis", "", true, FCVAR_ARCHIVE)
local weppouch_weapon_head = CreateClientConVar("vrmod_weppouch_weapon_Head", "", true, FCVAR_ARCHIVE)
local weppouch_weapon_spine = CreateClientConVar("vrmod_weppouch_weapon_Spine", "", true, FCVAR_ARCHIVE)
-- 設定した武器を上書きされないようにする
local weppouch_weapon_lock_pelvis = CreateClientConVar("vrmod_weppouch_weapon_lock_Pelvis", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_weapon_lock_head = CreateClientConVar("vrmod_weppouch_weapon_lock_Head", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local weppouch_weapon_lock_spine = CreateClientConVar("vrmod_weppouch_weapon_lock_Spine", 0, true, FCVAR_ARCHIVE, "", 0, 1)
-- 新しいConVarを作成してポーチの範囲を記録
local weppouchsize_pelvis = CreateClientConVar("vrmod_weppouch_dist_Pelvis", 12.5, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local weppouchsize_head = CreateClientConVar("vrmod_weppouch_dist_head", 10.0, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local weppouchsize_spine = CreateClientConVar("vrmod_weppouch_dist_spine", 0.0, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
--1に設定した場合、ポーチではなく、部位に応じて設定したconvarを使うモードに変更する。
local customconver_pelvis = CreateClientConVar("vrmod_weppouch_customcvar_pelvis_enable", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local customconver_head = CreateClientConVar("vrmod_weppouch_customcvar_head_enable", 0, true, FCVAR_ARCHIVE, "", 0, 1)
local customconver_spine = CreateClientConVar("vrmod_weppouch_customcvar_spine_enable", 0, true, FCVAR_ARCHIVE, "", 0, 1)
--カスタムコマンド用の記録ConVar
local customconver_pelvis_cmd = CreateClientConVar("vrmod_weppouch_customcvar_pelvis_cmd", "vrmod_test_pickup_entteleport_right", true, FCVAR_ARCHIVE)
local customconver_head_cmd = CreateClientConVar("vrmod_weppouch_customcvar_head_cmd", "vrmod_test_pickup_entteleport_right", true, FCVAR_ARCHIVE)
local customconver_spine_cmd = CreateClientConVar("vrmod_weppouch_customcvar_spine_cmd", "vrmod_test_pickup_entteleport_right", true, FCVAR_ARCHIVE)
--カスタムコマンド用の記録ConVar
local customconver_pelvis_cmd_put = CreateClientConVar("vrmod_weppouch_customcvar_pelvis_put_cmd", "+use,-use", true, FCVAR_ARCHIVE)
local customconver_head_cmd_put = CreateClientConVar("vrmod_weppouch_customcvar_head_put_cmd", "+use,-use", true, FCVAR_ARCHIVE)
local customconver_spine_cmd_put = CreateClientConVar("vrmod_weppouch_customcvar_spine_put_cmd", "+use,-use", true, FCVAR_ARCHIVE)
-- pelvis pouch
if weppouch_pelvis:GetBool() then
    hook.Add(
        "VRMod_Input",
        "vrutil_hook_weppouchinput_pelvis",
        function(action, pressed)
            local weppouchbone_pelvis = "ValveBiped.Bip01_R_Thigh"
            local weppouchdist = g_VR.eyePosRight
            if LocalPlayer():LookupBone(weppouchbone_pelvis) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_pelvis)) then
                weppouchdist = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_pelvis)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouchdist) < (weppouchsize_pelvis:GetFloat() * weppouchsize_pelvis:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist, weppouchsize_pelvis:GetFloat(), 1, Color(255, 0, 0, 255), true) -- 追加
                    VRMOD_TriggerHaptic("vibration_right", 0, 0.5, 20, 1)
                    if action == "boolean_right_pickup" and pressed then
                        if customconver_pelvis:GetBool() then
                            LocalPlayer():ConCommand(customconver_pelvis_cmd:GetString())
                            -- LocalPlayer():ConCommand("vrmod_lefthand 0")

                        else
                            LocalPlayer():ConCommand("use " .. weppouch_weapon_pelvis:GetString())
                            LocalPlayer():ConCommand("vrmod_lefthand 0")

                        end
                    elseif action == "boolean_right_pickup" and not pressed then
                        if customconver_pelvis:GetBool() then
                            LocalPlayer():ConCommand(customconver_pelvis_cmd_put:GetString())
                        else
                            if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                if not weppouch_weapon_lock_pelvis:GetBool() then
                                    LocalPlayer():ConCommand("vrmod_weppouch_weapon_Pelvis " .. LocalPlayer():GetActiveWeapon():GetClass())
                                end

                                LocalPlayer():ConCommand("use weapon_vrmod_empty")
                            end
                        end
                    end

                    if action == "boolean_use" and pressed then
                        if not weppouch_weapon_lock_pelvis:GetBool() then
                            LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_Pelvis 1")
                        else
                            LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_Pelvis 0")
                        end
                    end
                end
            end
        end
    )
end

-- head pouch
if weppouch_head:GetBool() then
    hook.Add(
        "VRMod_Input",
        "vrutil_hook_weppouchinput_head",
        function(action, pressed)
            local weppouchbone_head = "ValveBiped.Bip01_Head1"
            local weppouchdist = g_VR.eyePosRight
            if LocalPlayer():LookupBone(weppouchbone_head) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_head)) then
                weppouchdist = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_head)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouchdist) < (weppouchsize_head:GetFloat() * weppouchsize_head:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist, weppouchsize_head:GetFloat(), 1, Color(0, 255, 0, 255), true) -- 追加
                    VRMOD_TriggerHaptic("vibration_right", 0, 0.5, 20, 1)
                    if action == "boolean_right_pickup" and pressed then
                        if customconver_head:GetBool() then
                            LocalPlayer():ConCommand(customconver_head_cmd:GetString())
                            -- LocalPlayer():ConCommand("vrmod_lefthand 0")

                        else
                            LocalPlayer():ConCommand("use " .. weppouch_weapon_head:GetString())
                            LocalPlayer():ConCommand("vrmod_lefthand 0")
                        end
                    elseif action == "boolean_right_pickup" and not pressed then
                        if customconver_head:GetBool() then
                            LocalPlayer():ConCommand(customconver_head_cmd_put:GetString())
                        else
                            if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                if not weppouch_weapon_lock_head:GetBool() then
                                    LocalPlayer():ConCommand("vrmod_weppouch_weapon_head " .. LocalPlayer():GetActiveWeapon():GetClass())
                                end

                                LocalPlayer():ConCommand("use weapon_vrmod_empty")
                            end
                        end
                    end

                    if action == "boolean_use" and pressed then
                        if not weppouch_weapon_lock_head:GetBool() then
                            LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_Head 1")
                        else
                            LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_Head 0")
                        end
                    end
                end
            end
        end
    )
end

-- spine pouch
if weppouch_spine:GetBool() then
    hook.Add(
        "VRMod_Input",
        "vrutil_hook_weppouchinput_spine",
        function(action, pressed)
            local weppouchbone_spine = "ValveBiped.Bip01_Spine"
            local weppouchdist = g_VR.eyePosRight
            if LocalPlayer():LookupBone(weppouchbone_spine) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_spine)) then
                weppouchdist = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_spine)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouchdist) < (weppouchsize_spine:GetFloat() * weppouchsize_spine:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist, weppouchsize_spine:GetFloat(), 1, Color(0, 0, 255, 255), true) -- 追加
                    VRMOD_TriggerHaptic("vibration_right", 0, 0.5, 20, 1)
                    if action == "boolean_right_pickup" and pressed then
                        if customconver_spine:GetBool() then
                            LocalPlayer():ConCommand(customconver_spine_cmd:GetString())
                            -- LocalPlayer():ConCommand("vrmod_lefthand 0")
                        else
                            LocalPlayer():ConCommand("use " .. weppouch_weapon_spine:GetString())
                            LocalPlayer():ConCommand("vrmod_lefthand 0")

                        end
                    elseif action == "boolean_right_pickup" and not pressed then
                        if customconver_spine:GetBool() then
                            LocalPlayer():ConCommand(customconver_spine_cmd_put:GetString())
                        else
                            if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                if not weppouch_weapon_lock_spine:GetBool() then
                                    LocalPlayer():ConCommand("vrmod_weppouch_weapon_Spine " .. LocalPlayer():GetActiveWeapon():GetClass())
                                end

                                LocalPlayer():ConCommand("use weapon_vrmod_empty")
                            end
                        end
                    end

                    if action == "boolean_use" and pressed then
                        if not weppouch_weapon_lock_spine:GetBool() then
                            LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_Spine 1")
                        else
                            LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_Spine 0")
                        end
                    end
                end
            end
        end
    )
end