-- -- VRMod Holster System
-- -- Enhanced version combining Type 1 and Type 2 functionality
-- -- Author: [Your Name]

-- local VRMOD = VRMOD or {}
-- VRMOD.HolsterSystem = VRMOD.HolsterSystem or {}

-- -- Configuration
-- local CONFIG = {
--     MAX_HOLSTERS = 5,
--     DEFAULT_HOLSTER_SIZE = 12,
--     DEFAULT_PICKUP_SOUND = "common/wpn_select.wav",
--     HAPTIC_INTENSITY = 1.0,
--     HAPTIC_DURATION = 0.5
-- }

-- -- ConVar Management
-- local function CreateHolsterConVars()
--     -- General Settings
--     CreateClientConVar("vrmod_holster_enabled", "1", true, FCVAR_ARCHIVE)
--     CreateClientConVar("vrmod_holster_visual_feedback", "1", true, FCVAR_ARCHIVE)
--     CreateClientConVar("vrmod_holster_haptic_feedback", "1", true, FCVAR_ARCHIVE)
    
--     -- Per-Holster Settings
--     for i = 1, CONFIG.MAX_HOLSTERS do
--         CreateClientConVar("vrmod_holster_" .. i .. "_enabled", "1", true, FCVAR_ARCHIVE)
--         CreateClientConVar("vrmod_holster_" .. i .. "_size", tostring(CONFIG.DEFAULT_HOLSTER_SIZE), true, FCVAR_ARCHIVE)
--         CreateClientConVar("vrmod_holster_" .. i .. "_weapon", "", true, FCVAR_ARCHIVE)
--         CreateClientConVar("vrmod_holster_" .. i .. "_locked", "0", true, FCVAR_ARCHIVE)
--     end
-- end

-- -- Holster Position Management
-- local function GetHolsterPositions(ply)
--     if not IsValid(ply) then return {} end
    
--     local positions = {}
--     local headPos = ply:LookupBone("ValveBiped.Bip01_Neck1")
--     local chestBone = ply:LookupBone("ValveBiped.Bip01_Spine2")
--     local hipBone = ply:LookupBone("ValveBiped.Bip01_Pelvis")
    
--     if not chestBone or not hipBone then return positions end
    
--     local chestPos = ply:GetBonePosition(chestBone)
--     local hipPos = ply:GetBonePosition(hipBone)
    
--     -- Define holster positions
--     positions[1] = { pos = headPos + Vector(0, 10, 0), name = "Right Shoulder" }
--     positions[2] = { pos = headPos + Vector(0, -10, 0), name = "Left Shoulder" }
--     positions[3] = { pos = chestPos + Vector(10, 0, 0), name = "Right Chest" }
--     positions[4] = { pos = chestPos + Vector(-10, 0, 0), name = "Left Chest" }
--     positions[5] = { pos = hipPos + Vector(0, 0, 0), name = "Hip" }
    
--     return positions
-- end

-- -- Weapon Management
-- local function StoreWeapon(ply, holsterIndex, weapon)
--     if not IsValid(ply) or not IsValid(weapon) then return false end
    
--     local holsterEnabled = GetConVar("vrmod_holster_" .. holsterIndex .. "_enabled"):GetBool()
--     local holsterLocked = GetConVar("vrmod_holster_" .. holsterIndex .. "_locked"):GetBool()
    
--     if not holsterEnabled or holsterLocked then return false end
    
--     RunConsoleCommand("vrmod_holster_" .. holsterIndex .. "_weapon", weapon:GetClass())
--     return true
-- end

-- local function RetrieveWeapon(ply, holsterIndex)
--     if not IsValid(ply) then return false end
    
--     local weaponClass = GetConVar("vrmod_holster_" .. holsterIndex .. "_weapon"):GetString()
--     if weaponClass == "" then return false end
    
--     local weapon = ply:GetWeapon(weaponClass)
--     if not IsValid(weapon) then return false end
    
--     ply:SelectWeapon(weaponClass)
--     return true
-- end

-- -- Visual Feedback
-- local function DrawHolsterVisuals()
--     if not GetConVar("vrmod_holster_visual_feedback"):GetBool() then return end
    
--     local ply = LocalPlayer()
--     local positions = GetHolsterPositions(ply)
    
--     for i, pos in ipairs(positions) do
--         local size = GetConVar("vrmod_holster_" .. i .. "_size"):GetFloat()
--         local locked = GetConVar("vrmod_holster_" .. i .. "_locked"):GetBool()
        
--         render.SetColorMaterial()
--         local color = locked and Color(255, 0, 0, 128) or Color(0, 255, 0, 128)
--         render.DrawSphere(pos.pos, size, 16, 16, color)
        
--         -- Draw weapon name if one is stored
--         local weaponClass = GetConVar("vrmod_holster_" .. i .. "_weapon"):GetString()
--         if weaponClass ~= "" then
--             local weapon = ply:GetWeapon(weaponClass)
--             if IsValid(weapon) then
--                 local name = weapon:GetPrintName()
--                 local ang = EyeAngles()
--                 ang:RotateAroundAxis(ang:Right(), 90)
--                 cam.Start3D2D(pos.pos, ang, 0.1)
--                 draw.SimpleText(name, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER)
--                 cam.End3D2D()
--             end
--         end
--     end
-- end

-- -- Input Handling
-- local function HandleVRInput(action, pressed)
--     if not GetConVar("vrmod_holster_enabled"):GetBool() then return end
    
--     local ply = LocalPlayer()
--     local positions = GetHolsterPositions(ply)
    
--     -- Handle right hand interactions
--     if action == "boolean_right_pickup" then
--         local handPos = g_VR.tracking.pose_righthand.pos
        
--         for i, pos in ipairs(positions) do
--             local size = GetConVar("vrmod_holster_" .. i .. "_size"):GetFloat()
--             if handPos:DistToSqr(pos.pos) < (size * size) then
--                 if pressed then
--                     RetrieveWeapon(ply, i)
--                 else
--                     local activeWeapon = ply:GetActiveWeapon()
--                     if IsValid(activeWeapon) then
--                         StoreWeapon(ply, i, activeWeapon)
--                     end
--                 end
                
--                 -- Haptic feedback
--                 if GetConVar("vrmod_holster_haptic_feedback"):GetBool() then
--                     VRMOD_TriggerHaptic("vibration_right", 0, CONFIG.HAPTIC_DURATION, 20, CONFIG.HAPTIC_INTENSITY)
--                 end
                
--                 break
--             end
--         end
--     end
-- end

-- -- Menu Integration
-- local function CreateHolsterMenu(frame)
--     local sheet = vgui.Create("DPropertySheet", frame)
--     sheet:Dock(FILL)
    
--     -- Settings Panel
--     local settingsPanel = vgui.Create("DPanel", sheet)
--     sheet:AddSheet("Holster Settings", settingsPanel, "icon16/gun.png")
    
--     local y = 10
    
--     -- Global Settings
--     local enabledBox = vgui.Create("DCheckBoxLabel", settingsPanel)
--     enabledBox:SetPos(10, y)
--     enabledBox:SetText("Enable Holster System")
--     enabledBox:SetConVar("vrmod_holster_enabled")
--     enabledBox:SizeToContents()
    
--     y = y + 30
    
--     -- Individual Holster Settings
--     for i = 1, CONFIG.MAX_HOLSTERS do
--         local holsterPanel = vgui.Create("DPanel", settingsPanel)
--         holsterPanel:SetPos(10, y)
--         holsterPanel:SetSize(380, 80)
        
--         local label = vgui.Create("DLabel", holsterPanel)
--         label:SetPos(5, 5)
--         label:SetText("Holster " .. i)
        
--         local enableBox = vgui.Create("DCheckBoxLabel", holsterPanel)
--         enableBox:SetPos(5, 25)
--         enableBox:SetText("Enabled")
--         enableBox:SetConVar("vrmod_holster_" .. i .. "_enabled")
        
--         local sizeSlider = vgui.Create("DNumSlider", holsterPanel)
--         sizeSlider:SetPos(5, 45)
--         sizeSlider:SetSize(370, 20)
--         sizeSlider:SetText("Size")
--         sizeSlider:SetMin(1)
--         sizeSlider:SetMax(30)
--         sizeSlider:SetDecimals(0)
--         sizeSlider:SetConVar("vrmod_holster_" .. i .. "_size")
        
--         y = y + 90
--     end
-- end

-- -- Initialization
-- local function Initialize()
--     CreateHolsterConVars()
    
--     hook.Add("PostDrawTranslucentRenderables", "VRModHolsterVisuals", DrawHolsterVisuals)
--     hook.Add("VRMod_Input", "VRModHolsterInput", HandleVRInput)
--     hook.Add("VRMod_Menu", "VRModHolsterMenu", CreateHolsterMenu)
-- end

-- Initialize()

-- -- Network Communication
-- if SERVER then
--     util.AddNetworkString("VRModHolster_SyncWeapons")
    
--     net.Receive("VRModHolster_SyncWeapons", function(len, ply)
--         local holsterIndex = net.ReadUInt(8)
--         local weaponClass = net.ReadString()
        
--         if not IsValid(ply) then return end
--         if holsterIndex < 1 or holsterIndex > CONFIG.MAX_HOLSTERS then return end
        
--         -- Validate weapon exists
--         local weapon = ply:GetWeapon(weaponClass)
--         if not IsValid(weapon) then return end
        
--         -- Update holster
--         ply:ConCommand("vrmod_holster_" .. holsterIndex .. "_weapon " .. weaponClass)
--     end)
-- end

-- return VRMOD.HolsterSystem