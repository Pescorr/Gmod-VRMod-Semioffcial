--------[vrmod_left_hud.lua]Start--------
if SERVER then return end
local SHARED_HUD_RT_ID = "VRModSharedGModHUD_RT_Hands"
local SHARED_HUD_MAT_ID = "VRModSharedGModHUD_MAT_Hands"
local gmod_hud_shared_rt = GetRenderTarget(SHARED_HUD_RT_ID, 1366, 768, false)
local gmod_hud_shared_mat = Material("!" .. SHARED_HUD_MAT_ID)
gmod_hud_shared_mat = not gmod_hud_shared_mat:IsError() and gmod_hud_shared_mat or CreateMaterial(
    SHARED_HUD_MAT_ID,
    "UnlitGeneric",
    {
        ["$basetexture"] = gmod_hud_shared_rt:GetName(),
        ["$translucent"] = 1
    }
)
local orig_VRUtilRenderMenuSystem_for_all_hand_huds = nil
local _VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func
local function CurvedPlane_HandHUD(w_display_portion, h_display_portion, _segments_unused, _degrees_unused, matrix_transform, uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y, is_right_hand)
    matrix_transform = matrix_transform or Matrix()
    local mesh = Mesh()
    local verts = {}
    local p1 = Vector(0, 0, 0)
    local p2 = Vector(w_display_portion, 0, 0)
    local p3 = Vector(w_display_portion, h_display_portion, 0)
    local p4 = Vector(0, h_display_portion, 0)
    local u_start, u_end
    if is_right_hand then -- 右手の場合 (元のまま)
        u_start = uv_offset_x + uv_scale_x
        u_end = uv_offset_x
    else -- 左手の場合
        -- 元のコード
        -- u_start = uv_offset_x
        -- u_end = uv_offset_x + uv_scale_x
        -- 修正: 左手が反転しているため、U座標の割り当てを逆にする
        u_start = uv_offset_x + uv_scale_x
        u_end   = uv_offset_x
    end
    local v_tex_bottom = uv_offset_y + uv_scale_y 
    local v_tex_top = uv_offset_y 
    verts[#verts + 1] = {
        pos = matrix_transform * p1,
        u = u_start,
        v = v_tex_bottom
    }
    verts[#verts + 1] = {
        pos = matrix_transform * p2,
        u = u_end,
        v = v_tex_bottom
    }
    verts[#verts + 1] = {
        pos = matrix_transform * p4,
        u = u_start,
        v = v_tex_top
    }
    verts[#verts + 1] = {
        pos = matrix_transform * p4,
        u = u_start,
        v = v_tex_top
    }
    verts[#verts + 1] = {
        pos = matrix_transform * p2,
        u = u_end,
        v = v_tex_bottom
    }
    verts[#verts + 1] = {
        pos = matrix_transform * p3,
        u = u_end,
        v = v_tex_top
    }
    mesh:BuildFromTriangles(verts)
    return mesh
end
local HandHUDs = {
    Left = {
        ID_PREFIX = "vrmod_left_hud", -- Changed for clarity and consistency
        poseFunc = vrmod.GetLeftHandPose,
        isRightHand = false,
        meshesCache = {},
        currentMesh = nil,
        worldTransform = Matrix(),
        convars = {},
        convarValues = {},
        menuLabel = "Left Hand HUD"
    },
    Right = {
        ID_PREFIX = "vrmod_right_hud", -- Changed for clarity and consistency
        poseFunc = vrmod.GetRightHandPose,
        isRightHand = true,
        meshesCache = {},
        currentMesh = nil,
        worldTransform = Matrix(),
        convars = {},
        convarValues = {},
        menuLabel = "Right Hand HUD"
    }
}
local function UpdateAndRenderSharedHUD()
    if not g_VR.threePoints then return end
    local anyHandHUDEnabled = false
    local primaryHUDData = nil -- Prefer left if enabled, otherwise right
    if HandHUDs.Left.convarValues[HandHUDs.Left.ID_PREFIX .. "_enabled"] then
        anyHandHUDEnabled = true
        primaryHUDData = HandHUDs.Left
    elseif HandHUDs.Right.convarValues[HandHUDs.Right.ID_PREFIX .. "_enabled"] then
        anyHandHUDEnabled = true
        primaryHUDData = HandHUDs.Right
    end
    if not anyHandHUDEnabled then return end
    render.PushRenderTarget(gmod_hud_shared_rt)
    render.OverrideAlphaWriteEnable(true, true)
    local alpha_value = 100
    if primaryHUDData then
        local alpha_convar_name = primaryHUDData.ID_PREFIX .. "_alpha"
        alpha_value = tonumber(primaryHUDData.convarValues[alpha_convar_name]) or 100
    end
    render.Clear(0, 0, 0, alpha_value, true, true)
    render.RenderHUD(0, 0, 1366, 768)
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
end
_VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func = function()
    if orig_VRUtilRenderMenuSystem_for_all_hand_huds and orig_VRUtilRenderMenuSystem_for_all_hand_huds ~= _VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func then
        orig_VRUtilRenderMenuSystem_for_all_hand_huds()
    end
    if not g_VR.active then return end
    for _, hudData in pairs(HandHUDs) do
        if hudData.convarValues[hudData.ID_PREFIX .. "_enabled"] and hudData.currentMesh and IsValid(hudData.currentMesh) then
            render.SetMaterial(gmod_hud_shared_mat)
            cam.PushModelMatrix(hudData.worldTransform)
            render.DepthRange(0, 0.001) 
            hudData.currentMesh:Draw()
            render.DepthRange(0, 1)
            cam.PopModelMatrix()
        end
    end
end
local function UpdateHandHUDTransform(hudData)
    if not g_VR.threePoints or not hudData.convarValues[hudData.ID_PREFIX .. "_enabled"] then return end
    local handPos, handAng = hudData.poseFunc()
    if not handPos or not handAng then
        hudData.worldTransform:Identity()
        return
    end
    local id_prefix = hudData.ID_PREFIX
    local offsetPos = Vector(hudData.convarValues[id_prefix .. "_offset_pos_x"] or 0, hudData.convarValues[id_prefix .. "_offset_pos_y"] or 0, hudData.convarValues[id_prefix .. "_offset_pos_z"] or 0)
    local offsetAng = Angle(hudData.convarValues[id_prefix .. "_offset_ang_p"] or 0, hudData.convarValues[id_prefix .. "_offset_ang_y"] or 0, hudData.convarValues[id_prefix .. "_offset_ang_r"] or 0)
    local finalPos, finalAng = LocalToWorld(offsetPos, offsetAng, handPos, handAng)
    hudData.worldTransform:Identity()
    hudData.worldTransform:SetAngles(finalAng)
    hudData.worldTransform:SetTranslation(finalPos)
end
local function PreRenderAllHandHUDs()
    UpdateAndRenderSharedHUD()
    for _, hudData in pairs(HandHUDs) do
        UpdateHandHUDTransform(hudData)
    end
end
local function ConfigureHandHUD(hudData)
    local id_prefix = hudData.ID_PREFIX
    local isThisHudEnabled = hudData.convarValues[id_prefix .. "_enabled"] or false
    if not g_VR.active or not isThisHudEnabled then
        hudData.currentMesh = nil
        hook.Remove("HUDShouldDraw", id_prefix .. "_HUDShouldDraw")
    else
        local scale_val = hudData.convarValues[id_prefix .. "_scale"]
        local uv_offset_x_val = hudData.convarValues[id_prefix .. "_uv_offset_x"]
        local uv_offset_y_val = hudData.convarValues[id_prefix .. "_uv_offset_y"]
        local uv_scale_x_val = hudData.convarValues[id_prefix .. "_uv_scale_x"]
        local uv_scale_y_val = hudData.convarValues[id_prefix .. "_uv_scale_y"]
        local hud_total_texture_width_scaled = 1366 * scale_val
        local hud_total_texture_height_scaled = 768 * scale_val
        local hud_display_world_width_on_hand = hud_total_texture_width_scaled * uv_scale_x_val
        local hud_display_world_height_on_hand = hud_total_texture_height_scaled * uv_scale_y_val
        local meshName = id_prefix .. "_" .. scale_val .. "_" .. uv_offset_x_val .. "_" .. uv_offset_y_val .. "_" .. uv_scale_x_val .. "_" .. uv_scale_y_val
        if not hudData.meshesCache[meshName] then
            hudData.meshesCache[meshName] = CurvedPlane_HandHUD(hud_display_world_width_on_hand, hud_display_world_height_on_hand, 10, 0, nil, uv_offset_x_val, uv_offset_y_val, uv_scale_x_val, uv_scale_y_val, hudData.isRightHand) 
        end
        hudData.currentMesh = hudData.meshesCache[meshName]
        local blacklist_hand_hud = {}
        local blacklist_str = hudData.convarValues[id_prefix .. "_blacklist"] or ""
        for k, v in ipairs(string.Explode(",", blacklist_str)) do
            local trimmed_v = string.Trim(v)
            if trimmed_v ~= "" then
                blacklist_hand_hud[trimmed_v] = true
            end
        end
        hook.Remove("HUDShouldDraw", id_prefix .. "_HUDShouldDraw")
        if table.Count(blacklist_hand_hud) > 0 then
            hook.Add(
                "HUDShouldDraw",
                id_prefix .. "_HUDShouldDraw",
                function(name)
                    if hudData.convarValues[id_prefix .. "_enabled"] then
                        if blacklist_hand_hud[name] then return false end
                    end
                end
            )
        end
    end
    local anyHandHUDNowEnabled = false
    for _, data in pairs(HandHUDs) do
        if data.convarValues[data.ID_PREFIX .. "_enabled"] then
            anyHandHUDNowEnabled = true
            break
        end
    end
    if anyHandHUDNowEnabled then
        if not hook.GetTable().VRMod_PreRender["AllHandHUDs_PreRender"] then
            hook.Add("VRMod_PreRender", "AllHandHUDs_PreRender", PreRenderAllHandHUDs)
        end
        if VRUtilRenderMenuSystem ~= _VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func then
            if orig_VRUtilRenderMenuSystem_for_all_hand_huds == nil then
                orig_VRUtilRenderMenuSystem_for_all_hand_huds = VRUtilRenderMenuSystem
            end
            VRUtilRenderMenuSystem = _VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func
        end
    else
        hook.Remove("VRMod_PreRender", "AllHandHUDs_PreRender")
        if VRUtilRenderMenuSystem == _VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func then
            VRUtilRenderMenuSystem = orig_VRUtilRenderMenuSystem_for_all_hand_huds
            orig_VRUtilRenderMenuSystem_for_all_hand_huds = nil
        end
    end
end

local function SetupConvarsForHand(hudData)
    local id_prefix = hudData.ID_PREFIX
    local _, globalConvarValues = vrmod.GetConvars() -- Get global convar values table
    local function reconfigureThisHUD()
        -- Ensure convarValues for this specific HUD are up-to-date from global table
        hudData.convarValues[id_prefix .. "_enabled"] = globalConvarValues[id_prefix .. "_enabled_val"]
        hudData.convarValues[id_prefix .. "_scale"] = globalConvarValues[id_prefix .. "_scale_val"]
        hudData.convarValues[id_prefix .. "_offset_pos_x"] = globalConvarValues[id_prefix .. "_offset_pos_x_val"]
        hudData.convarValues[id_prefix .. "_offset_pos_y"] = globalConvarValues[id_prefix .. "_offset_pos_y_val"]
        hudData.convarValues[id_prefix .. "_offset_pos_z"] = globalConvarValues[id_prefix .. "_offset_pos_z_val"]
        hudData.convarValues[id_prefix .. "_offset_ang_p"] = globalConvarValues[id_prefix .. "_offset_ang_p_val"]
        hudData.convarValues[id_prefix .. "_offset_ang_y"] = globalConvarValues[id_prefix .. "_offset_ang_y_val"]
        hudData.convarValues[id_prefix .. "_offset_ang_r"] = globalConvarValues[id_prefix .. "_offset_ang_r_val"]
        hudData.convarValues[id_prefix .. "_uv_offset_x"] = globalConvarValues[id_prefix .. "_uv_offset_x_val"]
        hudData.convarValues[id_prefix .. "_uv_offset_y"] = globalConvarValues[id_prefix .. "_uv_offset_y_val"]
        hudData.convarValues[id_prefix .. "_uv_scale_x"] = globalConvarValues[id_prefix .. "_uv_scale_x_val"]
        hudData.convarValues[id_prefix .. "_uv_scale_y"] = globalConvarValues[id_prefix .. "_uv_scale_y_val"]
        hudData.convarValues[id_prefix .. "_blacklist"] = globalConvarValues[id_prefix .. "_blacklist_val"]
        hudData.convarValues[id_prefix .. "_alpha"] = globalConvarValues[id_prefix .. "_alpha_val"]
        ConfigureHandHUD(hudData)
    end

    -- Enable
    vrmod.AddCallbackedConvar(id_prefix .. "_enabled", id_prefix .. "_enabled_val", "1", FCVAR_ARCHIVE, "Enable " .. hudData.menuLabel, nil, nil, tobool, reconfigureThisHUD)
    -- Scale
    vrmod.AddCallbackedConvar(id_prefix .. "_scale", id_prefix .. "_scale_val", "0.009", FCVAR_ARCHIVE, hudData.menuLabel .. " Scale", 0.001, 0.1, tonumber, reconfigureThisHUD)
    -- OffsetPos
    vrmod.AddCallbackedConvar(id_prefix .. "_offset_pos_x", id_prefix .. "_offset_pos_x_val", hudData.isRightHand and "-6.78" or "0.7", FCVAR_ARCHIVE, "X Offset", -50, 50, tonumber, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_offset_pos_y", id_prefix .. "_offset_pos_y_val", hudData.isRightHand and "0.7" or "-2.10", FCVAR_ARCHIVE, "Y Offset", -50, 50, tonumber, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_offset_pos_z", id_prefix .. "_offset_pos_z_val", "-1.5", FCVAR_ARCHIVE, "Z Offset", -50, 50, tonumber, reconfigureThisHUD)
    -- OffsetAng
    vrmod.AddCallbackedConvar(id_prefix .. "_offset_ang_p", id_prefix .. "_offset_ang_p_val", hudData.isRightHand and "165" or "185", FCVAR_ARCHIVE, "Pitch Offset", -360, 360, tonumber, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_offset_ang_y", id_prefix .. "_offset_ang_y_val", hudData.isRightHand and "-180" or "0", FCVAR_ARCHIVE, "Yaw Offset", -360, 360, tonumber, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_offset_ang_r", id_prefix .. "_offset_ang_r_val", "-90", FCVAR_ARCHIVE, "Roll Offset", -360, 360, tonumber, reconfigureThisHUD)
    -- UV Offset
    vrmod.AddCallbackedConvar(id_prefix .. "_uv_offset_x", id_prefix .. "_uv_offset_x_val", hudData.isRightHand and "0.73" or "0.5", FCVAR_ARCHIVE, "UV X Offset", 0, 1, tonumber, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_uv_offset_y", id_prefix .. "_uv_offset_y_val", "0.73", FCVAR_ARCHIVE, "UV Y Offset", 0, 1, tonumber, reconfigureThisHUD)
    -- UV Scale
    vrmod.AddCallbackedConvar(id_prefix .. "_uv_scale_x", id_prefix .. "_uv_scale_x_val", "0.5", FCVAR_ARCHIVE, "UV X Scale", 0.01, 1, tonumber, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_uv_scale_y", id_prefix .. "_uv_scale_y_val", "0.4", FCVAR_ARCHIVE, "UV Y Scale", 0.01, 1, tonumber, reconfigureThisHUD)
    -- Existing ConVars
    vrmod.AddCallbackedConvar(id_prefix .. "_blacklist", id_prefix .. "_blacklist_val", "", FCVAR_ARCHIVE, hudData.menuLabel .. " Blacklist", nil, nil, tostring, reconfigureThisHUD)
    vrmod.AddCallbackedConvar(id_prefix .. "_alpha", id_prefix .. "_alpha_val", "0", FCVAR_ARCHIVE, hudData.menuLabel .. " Background Alpha", 0, 255, tonumber, reconfigureThisHUD)
    -- Initialize convarValues for this HUD from the global table immediately after registration
    reconfigureThisHUD()
end
for _, hudData in pairs(HandHUDs) do
    SetupConvarsForHand(hudData)
end
local function InitializeAllHandHUDs()
    for _, hudData in pairs(HandHUDs) do
        -- The reconfigureThisHUD function called during SetupConvarsForHand already handles initialization
        -- So, we just need to ensure ConfigureHandHUD is called once if not already by callbacks.
        ConfigureHandHUD(hudData)
    end
end
hook.Add(
    "VRMod_Start",
    "AllHandHUDs_VRStart",
    function(ply)
        if ply ~= LocalPlayer() then return end
        timer.Simple(3.4, InitializeAllHandHUDs) -- Delay to ensure all convars are loaded
    end
)
hook.Add(
    "VRMod_Exit",
    "AllHandHUDs_VRExit",
    function(ply)
        if ply ~= LocalPlayer() then return end
        for _, hudData in pairs(HandHUDs) do
            hudData.convarValues[hudData.ID_PREFIX .. "_enabled"] = false -- Force disable
            ConfigureHandHUD(hudData) -- This will trigger cleanup due to enabled being false
        end
        hook.Remove("VRMod_PreRender", "AllHandHUDs_PreRender")
        if VRUtilRenderMenuSystem == _VRUtilRenderMenuSystem_AllHandHUDs_Hooked_Func then
            VRUtilRenderMenuSystem = orig_VRUtilRenderMenuSystem_for_all_hand_huds
        end
        orig_VRUtilRenderMenuSystem_for_all_hand_huds = nil
    end
)

-- Initial setup if VR is already active when script loads
if vrmod.IsPlayerInVR and vrmod.IsPlayerInVR(LocalPlayer()) then
    timer.Simple(3.4, InitializeAllHandHUDs)
end
--------[vrmod_left_hud.lua]End--------