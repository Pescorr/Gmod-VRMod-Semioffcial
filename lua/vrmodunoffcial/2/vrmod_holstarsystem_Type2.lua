--------[vrmod_holstarsystem_Type2.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local weppouch_slots = 5
local weppouch_weapons = {}
local weppouch_positions = {}
local weppouch_initial_positions = {}
local weppouch_sizes = {}
local weppouch_visible_name = CreateClientConVar("vrmod_weppouch_visiblename", 1, true, FCVAR_ARCHIVE, nil, 0, 1)
local weppouch_saved_positions = {}
local weppouch_locked = {}
local weppouch_enter_sound = CreateClientConVar("vrmod_weppouch_enter_sound", "buttons/button24.wav", true, FCVAR_ARCHIVE)
local weppouch_pickup_sound = CreateClientConVar("vrmod_weppouch_pickup_sound", "buttons/button5.wav", true, FCVAR_ARCHIVE)
for i = 1, weppouch_slots do
    CreateClientConVar("vrmod_weppouch_weapon_" .. i, "", true, FCVAR_ARCHIVE)
    weppouch_locked[i] = false
end

for i = 1, weppouch_slots do
    weppouch_positions[i] = Vector(0, 0, 0)
    weppouch_initial_positions[i] = Vector(0, 0, 0)
    weppouch_saved_positions[i] = Vector(0, 0, 0)
    weppouch_sizes[i] = 9
end

hook.Add(
    "VRMod_Tracking",
    "vrmod_holster_follow_player",
    function()
        if not g_VR.threePoints then return end
        local ply = LocalPlayer()
        local headPos, headAng = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
        local chestPos, chestAng = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Spine1"))
        local hipPos, hipAng = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Pelvis"))
        weppouch_positions[1] = headPos + (headAng:Right() * 7)
        weppouch_positions[2] = headPos - (headAng:Right() * 7)
        weppouch_positions[3] = chestPos + (headAng:Right() * 9)
        weppouch_positions[4] = chestPos - (headAng:Right() * 9)
        weppouch_positions[5] = hipPos + (hipAng:Right() * 1)
    end
)

hook.Add(
    "VRMod_Input",
    "vrutil_hook_weppouchinput",
    function(action, pressed)
        local function storeWeapon(leftHand)
            for i = 1, weppouch_slots do
                if weppouch_locked[i] then continue end
                local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
                if hand_pos:DistToSqr(weppouch_positions[i]) < (weppouch_sizes[i] * weppouch_sizes[i]) then
                    local heldEntity = leftHand and g_VR.heldEntityLeft or g_VR.heldEntityRight
                    if IsValid(heldEntity) then
                        LocalPlayer():ConCommand("vrmod_weppouch_weapon_" .. i .. " " .. heldEntity:GetClass())
                        heldEntity:Remove()
                        if leftHand then
                            g_VR.heldEntityLeft = nil
                        else
                            g_VR.heldEntityRight = nil
                        end

                        return
                    end

                    local activeWeapon = LocalPlayer():GetActiveWeapon()
                    if IsValid(activeWeapon) and activeWeapon:GetClass() ~= "weapon_vrmod_empty" and ((leftHand and GetConVar("vrmod_lefthand"):GetBool()) or (not leftHand and not GetConVar("vrmod_lefthand"):GetBool())) then
                        LocalPlayer():ConCommand("vrmod_weppouch_weapon_" .. i .. " " .. activeWeapon:GetClass())
                        LocalPlayer():ConCommand("use weapon_vrmod_empty")

                        return
                    end

                    break
                end
            end
        end

        local function equipWeaponOrEntity(leftHand)
            for i = 1, weppouch_slots do
                local hand_pos = leftHand and g_VR.tracking.pose_lefthand.pos or g_VR.tracking.pose_righthand.pos
                if hand_pos:DistToSqr(weppouch_positions[i]) < (weppouch_sizes[i] * weppouch_sizes[i]) then
                    local wepclass = GetConVar("vrmod_weppouch_weapon_" .. i):GetString()
                    if wepclass ~= "" then
                        if weapons.Get(wepclass) then
                            LocalPlayer():ConCommand("use " .. wepclass)
                            LocalPlayer():ConCommand("vrmod_lefthand " .. (leftHand and "1" or "0"))
                            surface.PlaySound(weppouch_pickup_sound:GetString())
                        else
                            net.Start("vrmod_test_spawn_entity")
                            net.WriteString(wepclass)
                            net.WriteVector(hand_pos)
                            net.WriteAngle(leftHand and g_VR.tracking.pose_lefthand.ang or g_VR.tracking.pose_righthand.ang)
                            net.WriteBool(leftHand)
                            net.SendToServer()
                            surface.PlaySound(weppouch_pickup_sound:GetString())
                        end
                        -- LocalPlayer():ConCommand("vrmod_weppouch_weapon_" .. i .. " ")
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
            for i = 1, weppouch_slots do
                if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouch_positions[i]) < (weppouch_sizes[i] * weppouch_sizes[i]) then
                    weppouch_locked[i] = not weppouch_locked[i]
                    break
                end

                if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouch_positions[i]) < (weppouch_sizes[i] * weppouch_sizes[i]) then
                    weppouch_locked[i] = not weppouch_locked[i]
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
        if not g_VR.active then return end
        for i = 1, weppouch_slots do
            if g_VR.tracking.pose_lefthand.pos:DistToSqr(weppouch_positions[i]) < (weppouch_sizes[i] * weppouch_sizes[i]) then
                local text = GetConVar("vrmod_weppouch_weapon_" .. i):GetString()
                if text ~= "" then
                    draw.SimpleText(text, "DermaLarge", ScrW() * 0.05, ScrH() * 0.9, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                if not IsValid(ply) then return end
                surface.PlaySound(weppouch_enter_sound:GetString())
                break
            end
        end
    end
)

hook.Add(
    "HUDPaint",
    "vrmod_holstarsystem_right_hudpaint",
    function()
        if not g_VR.active then return end
        for i = 1, weppouch_slots do
            if g_VR.tracking.pose_righthand.pos:DistToSqr(weppouch_positions[i]) < (weppouch_sizes[i] * weppouch_sizes[i]) then
                local text = GetConVar("vrmod_weppouch_weapon_" .. i):GetString()
                if text ~= "" then
                    draw.SimpleText(text, "DermaLarge", ScrW() * 0.95, ScrH() * 0.9, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end

                if not IsValid(ply) then return end
                surface.PlaySound(weppouch_enter_sound:GetString())
                break
            end
        end
    end
)

hook.Add(
    "PostDrawTranslucentRenderables",
    "vrmod_holstarsystem_draw",
    function(depth, sky)
        if not g_VR.threePoints or EyePos() ~= g_VR.view.origin then return end
        for i = 1, weppouch_slots do
            local pos = weppouch_positions[i]
            local size = weppouch_sizes[i]
            render.SetColorMaterial()
            local color = weppouch_locked[i] and Color(64, 255, 0, 128) or Color(255, 255, 255, 128)
            render.DrawSphere(pos, size, 16, 50, color)
            if weppouch_visible_name:GetBool() then
                local entClass = GetConVar("vrmod_weppouch_weapon_" .. i):GetString()
                if entClass ~= "" then
                    local eyeAng = EyeAngles()
                    eyeAng:RotateAroundAxis(eyeAng:Right(), 90)
                    cam.Start3D2D(pos, eyeAng, 0.1)
                    draw.SimpleText(entClass, "CloseCaption_Normal", 0, 0, Color(108, 81, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end
    end
)

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
                spawnedEnt:SetAngles(handAng - Angle(4.9, 4, -3.5))
                if IsValid(spawnedEnt) then
                    pickup(ply, isLeftHand, spawnedEnt:GetPos(), spawnedEnt:GetAngles())
                    timer.Remove(ply:UserID() .. "followAndTryPickup")
                end
            end

            timer.Create(ply:UserID() .. "followAndTryPickup", 0.11, 0, followAndTryPickup)
        end
    )
end
--------[vrmod_holstarsystem_Type2.lua]End--------