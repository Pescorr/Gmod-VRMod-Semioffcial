if SERVER then return end -- クライアントサイドのみで実行
-- 新しい ConVar を作成
CreateClientConVar("vrmod_mirror_optimization", "0", true, FCVAR_ARCHIVE, "Enable mirror optimization", 0, 1)
CreateClientConVar("vrmod_reflective_glass_toggle", "0", true, FCVAR_ARCHIVE, "Toggle reflective glass visibility", 0, 1)
CreateClientConVar("vrmod_disable_mirrors", "0", true, FCVAR_ARCHIVE, "Disable mirrors", 0, 1)
-- 鏡の反射のパフォーマンスを向上させる関数
local function optimizeMirrorReflections(enable)
    if enable then

        hook.Remove("PreRender", "OptimizeMirrorReflections_AdjustResolution")

        -- 解像度を動的に調整する
        local function adjustReflectionResolution()
            local currentFPS = 1 / FrameTime()
            local targetFPS = 60 -- 目標のFPS
            local resolutionScale = math.sqrt(currentFPS / targetFPS)
            resolutionScale = math.Clamp(resolutionScale, 0.5, 1)
            -- 解像度を設定
            for _, ent in ipairs(ents.FindByClass("env_cubemap")) do
                ent:SetKeyValue("cubemapsize", tostring(math.floor(16 * resolutionScale)))
            end
        end

        -- 描画距離を制限する
        local maxReflectionDistance = 10 -- 反射の最大描画距離
        -- 反射の描画距離を設定
        for _, ent in ipairs(ents.FindByClass("env_cubemap")) do
            ent:SetKeyValue("farz", tostring(maxReflectionDistance))
        end

        -- オブジェクトの詳細度を調整する
        local reflectionLODDistance = 10 -- 反射でのLOD切り替え距離
        -- 反射でのLOD切り替え距離を設定
        for _, ent in ipairs(ents.FindByClass("env_cubemap")) do
            ent:SetKeyValue("loddistance", tostring(reflectionLODDistance))
        end

        -- 解像度の動的調整を有効化
        hook.Add("PreRender", "OptimizeMirrorReflections_AdjustResolution", adjustReflectionResolution)
    else
        -- 最適化を無効化
        hook.Remove("PreRender", "OptimizeMirrorReflections_AdjustResolution")
        -- 必要に応じて、他の設定を元に戻す処理を追加
    end
end

-- 鏡の描写を無効にする関数
local function disableMirrors(disable)
    for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
        ent:SetNoDraw(disable)
    end
end

-- 鏡の描写をトグルする処理
local isHidden = false
local hiddenEntities = {}
local function SetEntityVisibility(ent, hide)
    if IsValid(ent) then
        if hide then
            ent:SetNoDraw(true)
            ent:SetRenderMode(RENDERMODE_ENVIROMENTAL)
            ent:Activate(false)
            ent:SetColor(Color(255, 255, 255, 0))
            ent:SetNotSolid(true)
        else
            ent:SetNoDraw(false)
            ent:SetRenderMode(RENDERMODE_NORMAL)
            ent:Activate(true)
            ent:SetColor(Color(255, 255, 255, 255))
            ent:SetNotSolid(false)
        end
    end
end

local function ToggleReflectiveGlass(hide)
    isHidden = hide
    for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
        SetEntityVisibility(ent, isHidden)
        if isHidden then
            table.insert(hiddenEntities, ent:EntIndex())
        end
    end

    if isHidden then
        print("Reflective glass hidden.")
    else
        print("Reflective glass visible.")
        hiddenEntities = {} -- リセット
    end
end

-- ConVar 変更時のコールバック関数
local function OnMirrorOptimizationChanged(name, old, new)
    optimizeMirrorReflections(tobool(new))
end

local function OnReflectiveGlassToggleChanged(name, old, new)
    ToggleReflectiveGlass(tobool(new))
end

local function OnDisableMirrorsChanged(name, old, new)
    disableMirrors(tobool(new))
end

-- ConVar の変更を監視
cvars.AddChangeCallback("vrmod_mirror_optimization", OnMirrorOptimizationChanged)
cvars.AddChangeCallback("vrmod_reflective_glass_toggle", OnReflectiveGlassToggleChanged)
cvars.AddChangeCallback("vrmod_disable_mirrors", OnDisableMirrorsChanged)
CreateClientConVar("vrmod_gmod_optimization", "1", true, FCVAR_ARCHIVE, "VRMod optimization level", 0, 4)
-- VRMod開始時の最適化処理
local function ApplyVRModOptimization()
    local optimizationLevel = GetConVar("vrmod_gmod_optimization"):GetInt()
    if optimizationLevel == 1 then
        RunConsoleCommand("gmod_mcore_test", "0")
        RunConsoleCommand("r_WaterDrawReflection", "1")
        RunConsoleCommand("r_WaterDrawRefraction", "1")
        RunConsoleCommand("r_waterforceexpensive", "1")
        RunConsoleCommand("r_waterforcereflectentities", "1")
        RunConsoleCommand("vrmod_mirror_optimization", "0")
        RunConsoleCommand("vrmod_reflective_glass_toggle", "0")
        RunConsoleCommand("vrmod_disable_mirrors", "0")
    end

    if optimizationLevel == 2 then
        local conVars = {{"gmod_mcore_test", "0"}, {"vrmod_mirror_optimization", "0"}, {"vrmod_reflective_glass_toggle", "0"}, {"vrmod_disable_mirrors", "0"}, {"r_WaterDrawReflection", "0"}, {"r_WaterDrawRefraction", "0"}, {"r_waterforceexpensive", "0"}, {"r_waterforcereflectentities", "0"}}
        for _, cvar in ipairs(conVars) do
            RunConsoleCommand(cvar[1], cvar[2])
        end
    end

    if optimizationLevel == 3 then
        RunConsoleCommand("gmod_mcore_test", "0")
        RunConsoleCommand("vrmod_mirror_optimization", "1")
        RunConsoleCommand("vrmod_reflective_glass_toggle", "1")
        RunConsoleCommand("vrmod_disable_mirrors", "1")
        RunConsoleCommand("r_WaterDrawReflection", "0")
        RunConsoleCommand("r_WaterDrawRefraction", "0")
        RunConsoleCommand("r_waterforceexpensive", "0")
        RunConsoleCommand("r_waterforcereflectentities", "0")
    end

    if optimizationLevel == 4 then
        RunConsoleCommand("gmod_mcore_test", "1")
        RunConsoleCommand("vrmod_mirror_optimization", "1")
        RunConsoleCommand("vrmod_reflective_glass_toggle", "1")
        RunConsoleCommand("vrmod_disable_mirrors", "1")
        RunConsoleCommand("r_WaterDrawReflection", "0")
        RunConsoleCommand("r_WaterDrawRefraction", "0")
        RunConsoleCommand("r_waterforceexpensive", "0")
        RunConsoleCommand("r_waterforcereflectentities", "0")
    end
end

-- コンソールコマンド
concommand.Add("vrmod_apply_optimization", ApplyVRModOptimization)
if SERVER then return end
local optimizeConVars = {"r_3dsky", "r_shadows", "r_farz", "r_WaterDrawReflection", "r_WaterDrawRefraction", "r_waterforceexpensive", "r_waterforcereflectentities", "vrmod_mirror_optimization", "vrmod_reflective_glass_toggle", "vrmod_disable_mirrors", "gmod_mcore_test"}
-- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
local originalConVarValues = {}
local function RecordConVarValues()
    for _, cvar in ipairs(optimizeConVars) do
        local name = cvar[1]
        if GetConVar(name) then
            originalConVarValues[name] = GetConVar(name):GetString()
        end
    end
end

local function RestoreConVarValues()
    for name, value in pairs(originalConVarValues) do
        if GetConVar(name) then
            RunConsoleCommand(name, value)
            if CLIENT then
                print(name .. " restored to " .. value)
            end
        end
    end
end

-- VRMod開始時のフック
-- hook.Add(
--     "CreateMove",
--     "RecordVRModOptimization",
--     function()
--         hook.Remove("CreateMove", "RecordVRModOptimization")
--         timer.Simple(
--             2,
--             function()
--                 RecordConVarValues()
--             end
--         )
--     end
-- )
hook.Add("VRMod_Start", "ApplyVRModOptimization", ApplyVRModOptimization)
hook.Add(
    "VRMod_Exit",
    "RestoreVRModOptimization",
    function()
        RestoreConVarValues()
        ApplyVRModOptimization()
    end
)

concommand.Add(
    "vrmod_gmod_optimize_save",
    function(ply, cmd, args)
        RecordConVarValues()
    end
)

concommand.Add(
    "vrmod_gmod_optimize_load",
    function(ply, cmd, args)
        RestoreConVarValues()
        ApplyVRModOptimization()
    end
)

if CLIENT then
    local _, convars, convarValues = vrmod.GetConvars()
    local drivingmode = 0
    local bothmode = 0
    local ply = LocalPlayer()
    -- 以前のコマンドで設定されたconvarのリスト
    local optimizeConVars = {"r_3dsky", "r_shadows", "r_farz", "r_WaterDrawReflection", "r_WaterDrawRefraction", "r_waterforceexpensive", "r_waterforcereflectentities", "vrmod_mirror_optimization", "vrmod_reflective_glass_toggle", "vrmod_disable_mirrors", "gmod_mcore_test"}
    -- 新しいコマンド "vrmod_gmod_optimization_reset" を追加
    concommand.Add(
        "vrmod_gmod_optimization_reset",
        function(ply, cmd, args)
            for _, name in ipairs(optimizeConVars) do
                local default = GetConVar(name):GetDefault()
                LocalPlayer():ConCommand(name .. " " .. default)
            end

            timer.Simple(
                1,
                function()
                    if g_VR.active == true then
                        LocalPlayer():ConCommand("vrmod_restart")
                    end
                end
            )
        end
    )
end