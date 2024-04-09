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
--カスタムコマンド用の記録ConVar
local vrmod_weppouch_visiblerange = CreateClientConVar("vrmod_weppouch_visiblerange", 0, true, FCVAR_ARCHIVE, nil, 0, 1)
local vrmod_weppouch_visiblename = CreateClientConVar("vrmod_weppouch_visiblename", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
-- pelvis pouch
-- if weppouch_pelvis:GetBool() then
hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput_pelvis",
    function(action, pressed)
        local weppouchbone_pelvis = "ValveBiped.Bip01_Pelvis"
        local weppouchdist = g_VR.eyePosLeft
        if weppouch_pelvis:GetBool() then
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
    end
)

-- end
-- head pouch
-- if weppouch_head:GetBool() then
hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput_head",
    function(action, pressed)
        local weppouchbone_head = "ValveBiped.Bip01_Head1"
        local weppouchdist = g_VR.eyePosLeft
        if weppouch_head:GetBool() then
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
    end
)

-- end
-- spine pouch
-- if weppouch_spine:GetBool() then
hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput_spine",
    function(action, pressed)
        local weppouchbone_spine = "ValveBiped.Bip01_Spine"
        local weppouchdist = g_VR.eyePosLeft
        if weppouch_spine:GetBool() then
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
    end
)

-- end
-- 各ホルスター範囲の可視化
hook.Add(
    "PostDrawTranslucentRenderables",
    "vrmod_holstarsystem_draw",
    function()
        if not g_VR.threePoints or EyePos() ~= g_VR.view.origin then return end
        if weppouch_pelvis:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            if LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis") and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis")) then
                local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_pelvis:GetFloat(), 16, 50, Color(255, 0, 0))
            end
        end

        if weppouch_head:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            if LocalPlayer():LookupBone("ValveBiped.Bip01_Head1") and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")) then
                local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_head:GetFloat(), 16, 50, Color(0, 255, 0))
            end
        end

        if weppouch_spine:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            if LocalPlayer():LookupBone("ValveBiped.Bip01_Spine") and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Spine")) then
                local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Spine")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_spine:GetFloat(), 16, 50, Color(0, 0, 255))
            end
        end
    end
)

hook.Add(
    "HUDPaint",
    "vrmod_holstarsystem_wepname",
    function()
        if not g_VR.threePoints then return end
        local eyeAng = EyeAngles()
        eyeAng:RotateAroundAxis(eyeAng:Right(), 90)
        if weppouch_pelvis:GetBool() and vrmod_weppouch_visiblename:GetBool() then
            local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
            if g_VR.tracking.pose_righthand.pos:DistToSqr(pos) < (weppouchsize_pelvis:GetFloat() * weppouchsize_pelvis:GetFloat()) then
                local wepclass = weppouch_weapon_pelvis:GetString()
                local wep = LocalPlayer():GetWeapon(wepclass)
                if IsValid(wep) then
                    local wepName = wep:GetPrintName()
                    if weppouch_weapon_lock_pelvis:GetBool() then
                        wepName = "＊ " .. wepName .. " ＊"
                    end

                    draw.SimpleText(wepName, "CloseCaption_Normal", 160, 45, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
        end

        if weppouch_head:GetBool() and vrmod_weppouch_visiblename:GetBool() then
            local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
            if g_VR.tracking.pose_righthand.pos:DistToSqr(pos) < (weppouchsize_head:GetFloat() * weppouchsize_head:GetFloat()) then
                local wepclass = weppouch_weapon_head:GetString()
                local wep = LocalPlayer():GetWeapon(wepclass)
                if IsValid(wep) then
                    local wepName = wep:GetPrintName()
                    if weppouch_weapon_lock_head:GetBool() then
                        wepName = "＊ " .. wepName .. " ＊"
                    end

                    draw.SimpleText(wepName, "CloseCaption_Normal", 160, 45, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
        end

        if weppouch_spine:GetBool() and vrmod_weppouch_visiblename:GetBool() then
            local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Spine")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
            if g_VR.tracking.pose_righthand.pos:DistToSqr(pos) < (weppouchsize_spine:GetFloat() * weppouchsize_spine:GetFloat()) then
                local wepclass = weppouch_weapon_spine:GetString()
                local wep = LocalPlayer():GetWeapon(wepclass)
                if IsValid(wep) then
                    local wepName = wep:GetPrintName()
                    if weppouch_weapon_lock_spine:GetBool() then
                        wepName = "＊ " .. wepName .. " ＊"
                    end

                    draw.SimpleText(wepName, "CloseCaption_Normal", 160, 45, Color(0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
        end
    end
)
-- 左手ホルスター範囲内の武器名表示はここに追加
-- 左手ホルスターの範囲描画はここに追加
-- ホルスター内の武器モデル表示
-- hook.Add(
--     "PostDrawTranslucentRenderables",
--     "vrmod_holstarsystem_wepmodel",
--     function()
--         if not g_VR.threePoints or EyePos() ~= g_VR.view.origin then return end
--         -- 右手ペルビスホルスター内武器モデル描画
--         if weppouch_pelvis:GetBool() and weppouch_weapon_pelvis:GetString() ~= "" then
--             local wepclass = weppouch_weapon_pelvis:GetString()
--             local wep = LocalPlayer():GetWeapon(wepclass)
--             if IsValid(wep) then
--                 local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_R_Thigh")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
--                 local ang = (pos - EyePos()):Angle()
--                 ang:RotateAroundAxis(ang:Right(), 90)
--                 cam.Start3D2D(pos, ang, 0.1)
--                 surface.SetMaterial(Material("models/weapons/w_" .. wep:GetClass() .. ".mdl"))
--                 surface.SetDrawColor(255, 255, 255)
--                 surface.DrawTexturedRectRotated(0, 0, 256, 256, 0)
--                 cam.End3D2D()
--             end
--         end
--         -- 右手ヘッドホルスター内武器モデル描画
--         if weppouch_head:GetBool() and weppouch_weapon_head:GetString() ~= "" then
--             local wepclass = weppouch_weapon_head:GetString()
--             local wep = LocalPlayer():GetWeapon(wepclass)
--             if IsValid(wep) then
--                 local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
--                 local ang = (pos - EyePos()):Angle()
--                 ang:RotateAroundAxis(ang:Right(), 90)
--                 cam.Start3D2D(pos, ang, 0.1)
--                 surface.SetMaterial(Material("models/weapons/w_" .. wep:GetClass() .. ".mdl"))
--                 surface.SetDrawColor(255, 255, 255)
--                 surface.DrawTexturedRectRotated(0, 0, 256, 256, 0)
--                 cam.End3D2D()
--             end
--         end
--         -- 右手スパインホルスター内武器モデル描画
--         if weppouch_spine:GetBool() and weppouch_weapon_spine:GetString() ~= "" then
--             local wepclass = weppouch_weapon_spine:GetString()
--             local wep = LocalPlayer():GetWeapon(wepclass)
--             if IsValid(wep) then
--                 local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Spine")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
--                 local ang = (pos - EyePos()):Angle()
--                 ang:RotateAroundAxis(ang:Right(), 90)
--                 cam.Start3D2D(pos, ang, 0.1)
--                 surface.SetMaterial(Material("models/weapons/w_" .. wep:GetClass() .. ".mdl"))
--                 surface.SetDrawColor(255, 255, 255)
--                 surface.DrawTexturedRectRotated(0, 0, 256, 256, 0)
--                 cam.End3D2D()
--             end
--         end
--     end
-- )
-- -- 左手ホルスター内の武器モデル描画はここに追加
-- VR右手がホルスター範囲内にある時に武器名表示