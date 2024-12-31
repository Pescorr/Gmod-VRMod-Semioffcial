--------[vrmod_left_holstarsystem.lua]Start--------
AddCSLuaFile()
if SERVER then return end
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
local weppouchsize_pelvis_left = CreateClientConVar("vrmod_weppouch_left_dist_Pelvis", 12.5, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local weppouchsize_head_left = CreateClientConVar("vrmod_weppouch_left_dist_head", 10.0, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local weppouchsize_spine_left = CreateClientConVar("vrmod_weppouch_left_dist_spine", 0.0, true, FCVAR_ARCHIVE, "", 0.0, 99999.0)
local vrmod_weppouch_visiblerange = CreateClientConVar("vrmod_weppouch_visiblerange", 0, true, FCVAR_ARCHIVE, nil, 0, 1)
local vrmod_weppouch_visiblename = CreateClientConVar("vrmod_weppouch_visiblename", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput_pelvis_left",
    function(action, pressed)
        local weppouchbone_pelvis_left = "ValveBiped.Bip01_Pelvis"
        local weppouchdist_left = g_VR.eyePosRight
        if weppouch_left_pelvis:GetBool() then
            if LocalPlayer():LookupBone(weppouchbone_pelvis_left) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_pelvis_left)) then
                weppouchdist_left = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_pelvis_left)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_pelvis_left:GetFloat() * weppouchsize_pelvis_left:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist_left, weppouchsize_pelvis_left:GetFloat(), 1, Color(255, 0, 0, 255), true)
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    if action == "boolean_left_pickup" and pressed then
                        if customconver_left_pelvis:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_pelvis_cmd:GetString())
                        else
                            LocalPlayer():ConCommand("use " .. weppouch_weapon_left_pelvis:GetString())
                            LocalPlayer():ConCommand("vrmod_lefthand 1")
                        end
                    elseif action == "boolean_left_pickup" and not pressed then
                        if customconver_left_pelvis:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_pelvis_cmd_put:GetString())
                        else
                            if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_vrmod_empty" then
                                if not weppouch_weapon_lock_left_pelvis:GetBool() then
                                    LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Pelvis " .. LocalPlayer():GetActiveWeapon():GetClass())
                                end

                                LocalPlayer():ConCommand("use weapon_vrmod_empty")
                            end
                        end
                    end

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

hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput_head_left",
    function(action, pressed)
        local weppouchbone_head_left = "ValveBiped.Bip01_Head1"
        local weppouchdist_left = g_VR.eyePosRight
        if weppouch_left_head:GetBool() then
            if LocalPlayer():LookupBone(weppouchbone_head_left) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_head_left)) then
                weppouchdist_left = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_head_left)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_head_left:GetFloat() * weppouchsize_head_left:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist_left, weppouchsize_head_left:GetFloat(), 1, Color(0, 255, 0, 255), true)
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    if action == "boolean_left_pickup" and pressed then
                        if customconver_left_head:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_head_cmd:GetString())
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

hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput_spine_left",
    function(action, pressed)
        local weppouchbone_spine_left = "ValveBiped.Bip01_Neck1"
        local weppouchdist_left = g_VR.eyePosRight
        if weppouch_left_spine:GetBool() then
            if LocalPlayer():LookupBone(weppouchbone_spine_left) and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_spine_left)) then
                weppouchdist_left = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone(weppouchbone_spine_left)):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_spine_left:GetFloat() * weppouchsize_spine_left:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist_left, weppouchsize_spine_left:GetFloat(), 1, Color(0, 0, 255, 255), true)
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    if action == "boolean_left_pickup" and pressed then
                        if customconver_left_spine:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_spine_cmd:GetString())
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

hook.Add(
    "PostDrawTranslucentRenderables",
    "vrmod_holstarsystem_draw_left",
    function()
        if not g_VR.threePoints or EyePos() ~= g_VR.view.origin then return end
        if weppouch_left_pelvis:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            if LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis") and LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis")) then
                local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_pelvis_left:GetFloat(), 16, 50, Color(255, 0, 0, 255))
            end
        end

        if weppouch_left_head:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            if LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")) then
                local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_head_left:GetFloat(), 16, 50, Color(0, 255, 0, 255))
            end
        end

        if weppouch_left_spine:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            if LocalPlayer():LookupBone("ValveBiped.Bip01_Neck1")():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Neck1")) then
                local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Neck1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_spine_left:GetFloat(), 16, 50, Color(0, 0, 255, 255))
            end
        end
    end
)

hook.Add(
    "HUDPaint",
    "vrmod_holstarsystem_wepname_left",
    function()
        if not g_VR.threePoints then return end
        local eyeAng = EyeAngles()
        eyeAng:RotateAroundAxis(eyeAng:Right(), 90)
        if weppouch_left_pelvis:GetBool() and vrmod_weppouch_visiblename:GetBool() then
            local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Pelvis")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
            if g_VR.tracking.pose_lefthand.pos:DistToSqr(pos) < (weppouchsize_pelvis_left:GetFloat() * weppouchsize_pelvis_left:GetFloat()) then
                local wepclass = weppouch_weapon_left_pelvis:GetString()
                local wep = LocalPlayer():GetWeapon(wepclass)
                if IsValid(wep) then
                    local wepName = wep:GetPrintName()
                    if weppouch_weapon_lock_left_pelvis:GetBool() then
                        wepName = "白 " .. wepName .. " 白"
                    end

                    draw.SimpleText(wepName, "CloseCaption_Normal", 160, 45, Color(255, 0, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                end
            end
        end

        if weppouch_left_head:GetBool() and vrmod_weppouch_visiblename:GetBool() then
            local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Head1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
            if g_VR.tracking.pose_lefthand.pos:DistToSqr(pos) < (weppouchsize_head_left:GetFloat() * weppouchsize_head_left:GetFloat()) then
                local wepclass = weppouch_weapon_left_head:GetString()
                local wep = LocalPlayer():GetWeapon(wepclass)
                if IsValid(wep) then
                    local wepName = wep:GetPrintName()
                    if weppouch_weapon_lock_left_head:GetBool() then
                        wepName = "＊ " .. wepName .. " ＊"
                    end

                    draw.SimpleText(wepName, "CloseCaption_Normal", 160, 45, Color(0, 255, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                end
            end
        end

        if weppouch_left_spine:GetBool() and vrmod_weppouch_visiblename:GetBool() then
            local pos = LocalToWorld(Vector(3, 3, 0), Angle(0, 0, 0), LocalPlayer():GetBoneMatrix(LocalPlayer():LookupBone("ValveBiped.Bip01_Neck1")):GetTranslation(), Angle(0, g_VR.characterYaw, 0))
            if g_VR.tracking.pose_lefthand.pos:DistToSqr(pos) < (weppouchsize_spine_left:GetFloat() * weppouchsize_spine_left:GetFloat()) then
                local wepclass = weppouch_weapon_left_spine:GetString()
                local wep = LocalPlayer():GetWeapon(wepclass)
                if IsValid(wep) then
                    local wepName = wep:GetPrintName()
                    if weppouch_weapon_lock_left_spine:GetBool() then
                        wepName = "＊ " .. wepName .. " ＊"
                    end

                    draw.SimpleText(wepName, "CloseCaption_Normal", 160, 45, Color(0, 0, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                end
            end
        end
    end
)