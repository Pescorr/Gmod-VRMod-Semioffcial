--------[vrmod_left_holstarsystem.lua]Start--------
AddCSLuaFile()
if SERVER then return end

-- 安全なボーンワールド位置取得（nilチェック付き）
local function SafeGetBoneWorldPos(ply, boneName, offset, yawAngle)
    if not IsValid(ply) then return nil end
    local boneId = ply:LookupBone(boneName)
    if not boneId then return nil end
    local matrix = ply:GetBoneMatrix(boneId)
    if not matrix then return nil end
    return LocalToWorld(offset or Vector(3, 3, 0), Angle(0, 0, 0), matrix:GetTranslation(), yawAngle or Angle(0, 0, 0))
end

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
        if vrmod.ClimbFilter and vrmod.ClimbFilter.ShouldBlockLeft() then return end
        if weppouch_left_pelvis:GetBool() then
            local weppouchdist_left = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Pelvis", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if weppouchdist_left then
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_pelvis_left:GetFloat() * weppouchsize_pelvis_left:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist_left, weppouchsize_pelvis_left:GetFloat(), 1, Color(255, 0, 0, 255), true)
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    if action == "boolean_left_pickup" and pressed then
                        if customconver_left_pelvis:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_pelvis_cmd:GetString())
                        else
                            local storedWeapon = weppouch_weapon_left_pelvis:GetString()
                            if storedWeapon ~= "" and not IsValid(LocalPlayer():GetWeapon(storedWeapon)) then
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Pelvis \"\"")
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Pelvis 0")
                            else
                                LocalPlayer():ConCommand("use " .. storedWeapon)
                                LocalPlayer():ConCommand("vrmod_lefthand 1")
                            end
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
        if vrmod.ClimbFilter and vrmod.ClimbFilter.ShouldBlockLeft() then return end
        if weppouch_left_head:GetBool() then
            local weppouchdist_left = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Head1", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if weppouchdist_left then
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_head_left:GetFloat() * weppouchsize_head_left:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist_left, weppouchsize_head_left:GetFloat(), 1, Color(0, 255, 0, 255), true)
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    if action == "boolean_left_pickup" and pressed then
                        if customconver_left_head:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_head_cmd:GetString())
                        else
                            local storedWeapon = weppouch_weapon_left_head:GetString()
                            if storedWeapon ~= "" and not IsValid(LocalPlayer():GetWeapon(storedWeapon)) then
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Head \"\"")
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Head 0")
                            else
                                LocalPlayer():ConCommand("use " .. storedWeapon)
                                LocalPlayer():ConCommand("vrmod_lefthand 1")
                            end
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
        if vrmod.ClimbFilter and vrmod.ClimbFilter.ShouldBlockLeft() then return end
        if weppouch_left_spine:GetBool() then
            local weppouchdist_left = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Neck1", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if weppouchdist_left then
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouchdist_left) < (weppouchsize_spine_left:GetFloat() * weppouchsize_spine_left:GetFloat()) then
                    debugoverlay.Sphere(weppouchdist_left, weppouchsize_spine_left:GetFloat(), 1, Color(0, 0, 255, 255), true)
                    VRMOD_TriggerHaptic("vibration_left", 0, 0.5, 20, 1)
                    if action == "boolean_left_pickup" and pressed then
                        if customconver_left_spine:GetBool() then
                            LocalPlayer():ConCommand(customconver_left_spine_cmd:GetString())
                        else
                            local storedWeapon = weppouch_weapon_left_spine:GetString()
                            if storedWeapon ~= "" and not IsValid(LocalPlayer():GetWeapon(storedWeapon)) then
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_left_Spine \"\"")
                                LocalPlayer():ConCommand("vrmod_weppouch_weapon_lock_left_Spine 0")
                            else
                                LocalPlayer():ConCommand("use " .. storedWeapon)
                                LocalPlayer():ConCommand("vrmod_lefthand 1")
                            end
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
            local pos = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Pelvis", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if pos then
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_pelvis_left:GetFloat(), 16, 50, Color(255, 0, 0, 255))
            end
        end

        if weppouch_left_head:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            local pos = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Head1", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if pos then
                render.SetColorMaterial()
                render.DrawSphere(pos, weppouchsize_head_left:GetFloat(), 16, 50, Color(0, 255, 0, 255))
            end
        end

        if weppouch_left_spine:GetBool() and vrmod_weppouch_visiblerange:GetBool() then
            local pos = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Neck1", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if pos then
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
            local pos = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Pelvis", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if pos and g_VR.tracking.pose_lefthand.pos:DistToSqr(pos) < (weppouchsize_pelvis_left:GetFloat() * weppouchsize_pelvis_left:GetFloat()) then
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
            local pos = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Head1", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if pos and g_VR.tracking.pose_lefthand.pos:DistToSqr(pos) < (weppouchsize_head_left:GetFloat() * weppouchsize_head_left:GetFloat()) then
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
            local pos = SafeGetBoneWorldPos(LocalPlayer(), "ValveBiped.Bip01_Neck1", Vector(3, 3, 0), Angle(0, g_VR.characterYaw, 0))
            if pos and g_VR.tracking.pose_lefthand.pos:DistToSqr(pos) < (weppouchsize_spine_left:GetFloat() * weppouchsize_spine_left:GetFloat()) then
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