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
-- isAuto=true: VRMod_Startからの自動呼び出し（危険ConVarをスキップ）
-- isAuto=false/nil: 手動ボタン等からの呼び出し（全ConVar適用）
-- 危険ConVar: mat_specular, mat_queue_mode — マテリアル全リロードを引き起こしHMDフリーズの原因になる
local function ApplyVRModOptimization(isAuto)
    local optimizationLevel = GetConVar("vrmod_gmod_optimization"):GetInt()

    -- Lv1: VRModから変更を行わない
    if optimizationLevel == 1 then
        return
    end

    -- Lv2: 最適化を切る（リセット）
    if optimizationLevel == 2 then
        RunConsoleCommand("gmod_mcore_test", "0")
        RunConsoleCommand("r_WaterDrawReflection", "1")
        RunConsoleCommand("r_WaterDrawRefraction", "1")
        RunConsoleCommand("r_waterforceexpensive", "1")
        RunConsoleCommand("r_waterforcereflectentities", "1")
        RunConsoleCommand("vrmod_mirror_optimization", "0")
        RunConsoleCommand("vrmod_reflective_glass_toggle", "0")
        RunConsoleCommand("vrmod_disable_mirrors", "0")
        if not isAuto then
            RunConsoleCommand("mat_queue_mode", "-1")
            RunConsoleCommand("mat_specular", "1")
        end
    end

    -- Lv3: 最適化ON（gmod_mcore_test 0 = VR安全）
    if optimizationLevel == 3 then
        RunConsoleCommand("gmod_mcore_test", "0")
        RunConsoleCommand("vrmod_mirror_optimization", "1")
        RunConsoleCommand("vrmod_reflective_glass_toggle", "1")
        RunConsoleCommand("vrmod_disable_mirrors", "1")
        RunConsoleCommand("r_WaterDrawReflection", "0")
        RunConsoleCommand("r_WaterDrawRefraction", "0")
        RunConsoleCommand("r_waterforceexpensive", "0")
        RunConsoleCommand("r_waterforcereflectentities", "0")
        if not isAuto then
            RunConsoleCommand("mat_specular", "0")
        end
    end

    -- Lv4: 最大最適化（gmod_mcore_test 1 ※右目点滅の可能性あり）
    if optimizationLevel == 4 then
        RunConsoleCommand("gmod_mcore_test", "1")
        RunConsoleCommand("vrmod_mirror_optimization", "1")
        RunConsoleCommand("vrmod_reflective_glass_toggle", "1")
        RunConsoleCommand("vrmod_disable_mirrors", "1")
        RunConsoleCommand("r_WaterDrawReflection", "0")
        RunConsoleCommand("r_WaterDrawRefraction", "0")
        RunConsoleCommand("r_waterforceexpensive", "0")
        RunConsoleCommand("r_waterforcereflectentities", "0")
        if not isAuto then
            RunConsoleCommand("mat_queue_mode", "1")
            RunConsoleCommand("mat_specular", "0")
        end
    end
end

-- コンソールコマンド（Optimize Nowボタン）
-- VR稼働中: exit → 適用（マテリアルリロード） → 5秒後にstart で自動復帰
-- VR非稼働: そのまま全ConVar適用
concommand.Add("vrmod_apply_optimization", function()
    if g_VR and g_VR.active then
        RunConsoleCommand("vrmod_exit")
        timer.Simple(1.0, function()
            ApplyVRModOptimization(false)
            timer.Simple(4.0, function()
                RunConsoleCommand("vrmod_start")
            end)
        end)
    else
        ApplyVRModOptimization(false)
    end
end)

if SERVER then return end
local optimizeConVars = {"r_3dsky", "r_shadows", "r_farz", "r_WaterDrawReflection", "r_WaterDrawRefraction", "r_waterforceexpensive", "r_waterforcereflectentities", "vrmod_mirror_optimization", "vrmod_reflective_glass_toggle", "vrmod_disable_mirrors", "gmod_mcore_test", "mat_queue_mode", "mat_specular"}
local originalConVarValues = {}
local function RecordConVarValues()
    for _, name in ipairs(optimizeConVars) do
        local cv = GetConVar(name)
        if cv then
            originalConVarValues[name] = cv:GetString()
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

-- VRMod開始時: 元の値を記録してから安全なConVarのみ適用
hook.Add("VRMod_Start", "ApplyVRModOptimization", function()
    RecordConVarValues()
    ApplyVRModOptimization(true)
end)
-- VRMod終了時: 記録した元の値に復元のみ（再適用はしない）
hook.Add("VRMod_Exit", "RestoreVRModOptimization", function()
    RestoreConVarValues()
end)

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
        ApplyVRModOptimization(false)
    end
)

if CLIENT then
    local _, convars, convarValues = vrmod.GetConvars()
    local drivingmode = 0
    local bothmode = 0
    local ply = LocalPlayer()
    -- 以前のコマンドで設定されたconvarのリスト
    local optimizeConVars = {"r_3dsky", "r_shadows", "r_farz", "r_WaterDrawReflection", "r_WaterDrawRefraction", "r_waterforceexpensive", "r_waterforcereflectentities", "vrmod_mirror_optimization", "vrmod_reflective_glass_toggle", "vrmod_disable_mirrors", "gmod_mcore_test", "mat_queue_mode"}
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

-- VR HMD上でのweaponワールドモデル非表示
-- VR描画時のみactiveWeaponのworldmodelを非表示にし、デスクトップ/ミラーでは通常表示を維持
-- viewmodel(g_VR.viewModel)は別エンティティなので影響なし
local hideWmVr = CreateClientConVar("vrmod_unoff_hide_wm_vr", "1", true, FCVAR_ARCHIVE, "Hide weapon worldmodel in VR HMD", 0, 1)
local hiddenWeapon = nil

hook.Add("VRMod_PreRender", "vrmod_unoff_hide_worldmodel_vr", function()
    if not hideWmVr:GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        wep:SetNoDraw(true)
        hiddenWeapon = wep
    end
end)

hook.Add("VRMod_PostRender", "vrmod_unoff_restore_worldmodel_vr", function()
    if IsValid(hiddenWeapon) then
        hiddenWeapon:SetNoDraw(false)
        hiddenWeapon = nil
    end
end)