if SERVER then return end

local vrScrH = CreateClientConVar("vrmod_ScrH_hud", ScrH(), true, FCVAR_ARCHIVE)
local vrScrW = CreateClientConVar("vrmod_ScrW_hud", ScrW(), true, FCVAR_ARCHIVE)

-- 新しいConVarを追加: HUDモードの選択用
local vrmod_hud_mode = CreateClientConVar("vrmod_hud_mode", "0", true, FCVAR_ARCHIVE, "0: Normal, 1: Wrist")


local function CurvedPlane(w, h, segments, degrees, matrix)
end

local rt = GetRenderTarget("vrmod_hud", vrScrW:GetInt(), vrScrH:GetInt(), false)
local mat = Material("!vrmod_hud")
mat = not mat:IsError() and mat or CreateMaterial(
    "vrmod_hud",
    "UnlitGeneric",
    {
        ["$basetexture"] = rt:GetName(),
        ["$translucent"] = 1
    }
)

local hudMeshes = {}
local hudMesh = nil
local orig = nil
local convars, convarValues = vrmod.GetConvars()

local function RemoveHUD()
    hook.Remove("VRMod_PreRender", "hud")
    hook.Remove("HUDShouldDraw", "vrmod_hud")
    VRUtilRenderMenuSystem = orig or VRUtilRenderMenuSystem
end

local function AddHUD()
    RemoveHUD()
    if not g_VR.active or not convarValues.vrmod_hud then return end
    
    local mtx = Matrix()
    mtx:Translate(Vector(0, 0, vrScrH:GetInt() * convarValues.vrmod_hudscale / 2))
    mtx:Rotate(Angle(0, -90, -90))
    local meshName = convarValues.vrmod_hudscale .. "_" .. convarValues.vrmod_hudcurve
    hudMeshes[meshName] = hudMeshes[meshName] or CurvedPlane(vrScrW:GetInt() * convarValues.vrmod_hudscale, vrScrH:GetInt() * convarValues.vrmod_hudscale, 10, convarValues.vrmod_hudcurve, mtx)
    hudMesh = hudMeshes[meshName]

    local blacklist = {}
    for k, v in ipairs(string.Explode(",", convarValues.vrmod_hudblacklist)) do
        blacklist[v] = #v > 0 and true or blacklist[v]
    end
    if table.Count(blacklist) > 0 then
        hook.Add(
            "HUDShouldDraw",
            "vrmod_hud",
            function(name)
                if blacklist[name] then return false end
            end
        )
    end

    hook.Add(
        "VRMod_PreRender",
        "hud",
        function()
            if not g_VR.threePoints then return end
            render.PushRenderTarget(rt)
            render.OverrideAlphaWriteEnable(true, true)
            render.Clear(0, 0, 0, convarValues.vrmod_hudtestalpha, true, true)
            render.RenderHUD(0, 0, vrScrW:GetInt(), vrScrH:GetInt())
            render.OverrideAlphaWriteEnable(false)
            render.PopRenderTarget()

            -- HUDモードに基づいて位置と角度を設定
            local hudMode = vrmod_hud_mode:GetInt()
            if hudMode == 0 then
                -- 通常モード: HMDの前
                mtx:Identity()
                mtx:Translate(g_VR.tracking.hmd.pos + g_VR.tracking.hmd.ang:Forward() * convarValues.vrmod_huddistance)
                mtx:Rotate(g_VR.tracking.hmd.ang)
            else
                -- 腕時計モード: 左手の手の甲
                local leftHandPos, leftHandAng = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang
                mtx:Identity()
                mtx:Translate(leftHandPos + leftHandAng:Forward() * 5 + leftHandAng:Up() * 2)  -- 手首の上に少し浮かせる
                mtx:Rotate(leftHandAng * Angle(30, 0, 0))  -- 少し傾ける
            end
        end
    )

    orig = orig or VRUtilRenderMenuSystem
    VRUtilRenderMenuSystem = function()
        render.SetMaterial(mat)
        cam.PushModelMatrix(mtx)
        render.DepthRange(0, 0.01)
        hudMesh:Draw()
        render.DepthRange(0, 1)
        cam.PopModelMatrix()
        orig()
    end
end

vrmod.AddCallbackedConvar("vrmod_hud", nil, 1, nil, nil, nil, nil, tobool, AddHUD)
vrmod.AddCallbackedConvar("vrmod_hudblacklist", nil, "", nil, nil, nil, nil, nil, AddHUD)
vrmod.AddCallbackedConvar("vrmod_hudcurve", nil, "60", nil, nil, nil, nil, tonumber, AddHUD)
vrmod.AddCallbackedConvar("vrmod_hudscale", nil, "0.05", nil, nil, nil, nil, tonumber, AddHUD)
vrmod.AddCallbackedConvar("vrmod_huddistance", nil, "60", nil, nil, nil, nil, tonumber)
vrmod.AddCallbackedConvar("vrmod_hudtestalpha", nil, "0", nil, nil, nil, nil, tonumber)

-- HUDモードの変更を監視し、変更時にHUDを更新
cvars.AddChangeCallback("vrmod_hud_mode", function(convar_name, value_old, value_new)
    AddHUD()
end, "VRModHUDModeChange")

hook.Add(
    "VRMod_Menu",
    "vrmod_hud",
    function(frame)
        frame.SettingsForm:CheckBox("Enable HUD", "vrmod_hud")
        
        -- HUDモード選択のドロップダウンを追加
        local hudModeDropdown = frame.SettingsForm:ComboBox("HUD Mode", "vrmod_hud_mode")
        hudModeDropdown:AddChoice("Normal", "0")
        hudModeDropdown:AddChoice("Wrist", "1")
    end
)

hook.Add(
    "VRMod_Start",
    "hud",
    function(ply)
        if ply ~= LocalPlayer() then return end
        AddHUD()
    end
)

hook.Add(
    "VRMod_Exit",
    "hud",
    function(ply)
        if ply ~= LocalPlayer() then return end
        RemoveHUD()
    end
)