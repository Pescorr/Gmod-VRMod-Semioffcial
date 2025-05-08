--------[vrmod_hud_left_hand.lua]Start--------
if SERVER then return end
local LH_HUD_RT_NAME = "vrmod_hud_lh_rt"
local LH_HUD_MAT_NAME = "!vrmod_hud_lh_mat" -- Adding "!" prefix to avoid potential conflicts if material is not found
local function CurvedPlane(w, h, segments, degrees, matrix)
    matrix = matrix or Matrix()
    degrees = math.rad(degrees)
    local mesh = Mesh()
    local verts = {}
    local startAng = (math.pi - degrees) / 2
    local segLen = 0.5 * math.tan(degrees / segments)
    local scale = w / (segLen * segments)
    local zoffset = math.sin(startAng) * 0.5 * scale
    for i = 0, segments - 1 do
        local fraction = i / segments
        local nextFraction = (i + 1) / segments
        local ang1 = startAng + fraction * degrees
        local ang2 = startAng + nextFraction * degrees
        local x1 = (math.cos(ang1) * -0.5) * scale
        local x2 = (math.cos(ang2) * -0.5) * scale
        local z1 = math.sin(ang1) * 0.5 * scale - zoffset
        local z2 = math.sin(ang2) * 0.5 * scale - zoffset
        verts[#verts + 1] = {
            pos = matrix * Vector(x1, 0, z1),
            u = fraction,
            v = 0
        }

        verts[#verts + 1] = {
            pos = matrix * Vector(x2, 0, z2),
            u = nextFraction,
            v = 0
        }

        verts[#verts + 1] = {
            pos = matrix * Vector(x2, h, z2),
            u = nextFraction,
            v = 1
        }

        verts[#verts + 1] = {
            pos = matrix * Vector(x2, h, z2),
            u = nextFraction,
            v = 1
        }

        verts[#verts + 1] = {
            pos = matrix * Vector(x1, h, z1),
            u = fraction,
            v = 1
        }

        verts[#verts + 1] = {
            pos = matrix * Vector(x1, 0, z1),
            u = fraction,
            v = 0
        }
    end

    mesh:BuildFromTriangles(verts)

    return mesh
end

local rt_lh = GetRenderTarget(LH_HUD_RT_NAME, 1366, 768, false)
local mat_lh = Material(LH_HUD_MAT_NAME)
mat_lh = not mat_lh:IsError() and mat_lh or CreateMaterial(
    LH_HUD_MAT_NAME,
    "UnlitGeneric",
    {
        ["$basetexture"] = rt_lh:GetName(),
        ["$translucent"] = 1
    }
)

local hudMeshes_lh = {}
local hudMesh_lh = nil
local convars_lh, convarValues_lh = vrmod.GetConvars() -- Use existing GetConvars, but store in local prefixed vars
-- HUDの左手からのオフセットと角度
-- Vector(X, Y, Z) : 手のローカル座標に対するHUD左下のオフセット
-- X: 手の左右方向 (右が正)
-- Y: 手の前後方向 (指先が正)
-- Z: 手の上下方向 (甲側が正)
-- Angle(P, Y, R) : 手のローカル角度に対するHUDの角度
-- P: ピッチ (X軸回り)
-- Y: ヨー (Y軸回り)
-- R: ロール (Z軸回り)
local HUD_LH_LOCAL_OFFSET_POS = Vector(1, 1.5, 0.2) -- 手の甲から少し浮かせる(Z=0.2)。X,Yはvr_hud.txtの値を参考に調整開始点とする。
local HUD_LH_LOCAL_OFFSET_ANG = Angle(1, -8, 90) -- 手の甲を向くようにRollを調整 (-90 -> 90)
local mtx_lh = Matrix()
local function RemoveHUD_LH()
    hook.Remove("VRMod_PreRender", "hud_lh_update_rt_and_matrix")
    hook.Remove("HUDShouldDraw", "vrmod_hud_lh_blacklist_check")
    hook.Remove("PostDrawTranslucentRenderables", "vrmod_hud_lh_draw_mesh")
end

local function AddHUD_LH()
    RemoveHUD_LH()
    if not g_VR.active or not convarValues_lh.vrmod_hud_lh_enabled then return end
    local hud_width_scaled = 1366 * convarValues_lh.vrmod_hud_lh_scale
    local hud_height_scaled = 768 * convarValues_lh.vrmod_hud_lh_scale
    local mesh_local_transform = Matrix()
    -- HUDのメッシュ原点を、メッシュ自体の左下隅に設定
    mesh_local_transform:Translate(Vector(hud_width_scaled / 2, 0, 0))
    local meshName = convarValues_lh.vrmod_hud_lh_scale .. "_" .. convarValues_lh.vrmod_hud_lh_curve
    hudMeshes_lh[meshName] = hudMeshes_lh[meshName] or CurvedPlane(hud_width_scaled, hud_height_scaled, 10, convarValues_lh.vrmod_hud_lh_curve, mesh_local_transform)
    hudMesh_lh = hudMeshes_lh[meshName]
    local blacklist = {}
    for k, v in ipairs(string.Explode(",", convarValues_lh.vrmod_hud_lh_blacklist)) do
        blacklist[v] = #v > 0 and true or blacklist[v]
    end

    if table.Count(blacklist) > 0 then
        hook.Add(
            "HUDShouldDraw",
            "vrmod_hud_lh_blacklist_check",
            function(name)
                if blacklist[name] then return false end
            end
        )
    end

    hook.Add(
        "VRMod_PreRender",
        "hud_lh_update_rt_and_matrix",
        function()
            if not g_VR.threePoints then return end
            render.PushRenderTarget(rt_lh)
            render.OverrideAlphaWriteEnable(true, true)
            render.Clear(0, 0, 0, convarValues_lh.vrmod_hud_lh_testalpha, true, true)
            render.RenderHUD(0, 0, 1366, 768)
            render.OverrideAlphaWriteEnable(false)
            render.PopRenderTarget()
            local handPos, handAng = vrmod.GetLeftHandPose()
            if not handPos or not handAng then
                mtx_lh:Identity()

                return
            end

            local finalPos, finalAng = LocalToWorld(HUD_LH_LOCAL_OFFSET_POS, HUD_LH_LOCAL_OFFSET_ANG, handPos, handAng)
            mtx_lh:Identity()
            mtx_lh:SetAngles(finalAng)
            mtx_lh:SetTranslation(finalPos)
        end
    )

    hook.Add(
        "PostDrawTranslucentRenderables",
        "vrmod_hud_lh_draw_mesh",
        function(bDrawingDepth, bDrawingSkybox)
            if bDrawingDepth or bDrawingSkybox then return end
            if not g_VR.active or not convarValues_lh.vrmod_hud_lh_enabled or not hudMesh_lh or not IsValid(hudMesh_lh) then return end
            -- Ensure rendering only for VR eyes
            local currentEyePos = vrmod.GetEyePos()
            if currentEyePos ~= vrmod.GetLeftEyePos() and currentEyePos ~= vrmod.GetRightEyePos() then return end
            render.SetMaterial(mat_lh)
            cam.PushModelMatrix(mtx_lh)
            render.DepthRange(0, 0.01)
            hudMesh_lh:Draw()
            render.DepthRange(0, 1)
            cam.PopModelMatrix()
        end
    )
end

-- Register convars with unique names
vrmod.AddCallbackedConvar("vrmod_hud_lh_enabled", "vrmod_hud_lh_enabled", "0", FCVAR_ARCHIVE, "Enable/Disable Left Hand HUD", nil, nil, tobool, AddHUD_LH)
vrmod.AddCallbackedConvar("vrmod_hud_lh_blacklist", "vrmod_hud_lh_blacklist", "", FCVAR_ARCHIVE, "Comma separated list of HUD elements to hide for Left Hand HUD", nil, nil, nil, AddHUD_LH)
vrmod.AddCallbackedConvar("vrmod_hud_lh_curve", "vrmod_hud_lh_curve", "1", FCVAR_ARCHIVE, "Curvature of the Left Hand HUD (degrees)", 0, 90, tonumber, AddHUD_LH)
vrmod.AddCallbackedConvar("vrmod_hud_lh_scale", "vrmod_hud_lh_scale", "0.02", FCVAR_ARCHIVE, "Scale of the Left Hand HUD", 0.001, 0.1, tonumber, AddHUD_LH)
vrmod.AddCallbackedConvar("vrmod_hud_lh_testalpha", "vrmod_hud_lh_testalpha", "0", FCVAR_ARCHIVE, "Background alpha for Left Hand HUD (for testing)", 0, 255, tonumber)
hook.Add(
    "VRMod_Menu",
    "vrmod_hud_lh_settings",
    function(frame)
        local form = frame.SettingsForm
        if not form or not IsValid(form) then return end
        form:CheckBox("Enable Left Hand HUD", "vrmod_hud_lh_enabled")
        form:TextEntry("Left Hand HUD Blacklist", "vrmod_hud_lh_blacklist")
        form:NumSlider("Left Hand HUD Curve", "vrmod_hud_lh_curve", 0, 90, 0)
        form:NumSlider("Left Hand HUD Scale", "vrmod_hud_lh_scale", 0.001, 0.1, 3)
        form:NumSlider("Left Hand HUD Test Alpha", "vrmod_hud_lh_testalpha", 0, 255, 0)
    end
)

hook.Add(
    "VRMod_Start",
    "hud_lh_start",
    function(ply)
        if ply ~= LocalPlayer() then return end
        -- Initialize convar values as they are added after VRMod_Start might be called for other addons
        timer.Simple(
            0.1,
            function()
                -- Check if convars are initialized
                if convarValues_lh.vrmod_hud_lh_enabled == nil then
                    -- Force update convar values if they were not ready
                    RunConsoleCommand("vrmod_hud_lh_enabled", GetConVar("vrmod_hud_lh_enabled"):GetString())
                end

                AddHUD_LH()
            end
        )
    end
)

hook.Add(
    "VRMod_Exit",
    "hud_lh_exit",
    function(ply)
        if ply ~= LocalPlayer() then return end
        RemoveHUD_LH()
    end
)
--------[vrmod_hud_left_hand.lua]End--------