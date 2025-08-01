--------[vrmod_ui_crosshairhud.lua]Start--------
if SERVER then return end
local vrScrH = CreateClientConVar("vrmod_ScrH_hud", ScrH(), true, FCVAR_ARCHIVE)
local vrScrW = CreateClientConVar("vrmod_ScrW_hud", ScrW(), true, FCVAR_ARCHIVE)
-- vrmod_left_hud.lua で定義されている共有HUDレンダーターゲットとマテリアルを取得/作成
local SHARED_HUD_RT_ID = "VRModSharedGModHUD_RT_Hands"
local SHARED_HUD_MAT_ID = "VRModSharedGModHUD_MAT_Hands"
local gmod_hud_shared_rt = GetRenderTarget(SHARED_HUD_RT_ID, vrScrW:GetInt(), vrScrH:GetInt(), false)
local gmod_hud_shared_mat = Material("!" .. SHARED_HUD_MAT_ID)
gmod_hud_shared_mat = not gmod_hud_shared_mat:IsError() and gmod_hud_shared_mat or CreateMaterial(
    SHARED_HUD_MAT_ID,
    "UnlitGeneric",
    {
        ["$basetexture"] = gmod_hud_shared_rt:GetName(),
        ["$translucent"] = 1
    }
)

local isCrosshairHudVisible = false
-- 右手コントローラー/銃口からの相対的なオフセット位置と角度
local crosshairHudOffsetPos = Vector(0, 0, 0) -- Vector(0, 13.6, 7.6) -- 銃口基準の場合、(0,0,0) から調整開始が推奨
local crosshairHudOffsetAng = Angle(0, -90, 90) -- Angle(0, -90, 90)   -- 銃口基準の場合、(0,0,0) から調整開始が推奨
local crosshairHudScale = 0.1
local crosshairHudRenderWidth = vrScrW:GetInt()
local crosshairHudRenderHeight = vrScrH:GetInt()
local crosshairHudDistance = 60 -- 銃口または右手からのHUDの基本距離
local function RenderCrosshairHudInSpace()
    if not isCrosshairHudVisible or not g_VR.active or not g_VR.threePoints then return end
    if not gmod_hud_shared_mat or gmod_hud_shared_mat:IsError() then return end
    local worldPos, worldAng
    local muzzle = g_VR.viewModelMuzzle
    if muzzle and muzzle.Pos and muzzle.Ang then
        -- 銃口情報が利用可能な場合
        -- 1. HUDの基準角度を決定 (銃口の向き)
        local baseHudAng = muzzle.Ang
        -- 2. HUDの基準位置を決定 (銃口の位置から、基準角度の方向に一定距離進んだ点)
        local baseHudPos = muzzle.Pos + baseHudAng:Forward() * crosshairHudDistance
        -- 3. 基準位置・角度に対して、定義されたオフセットを適用
        worldPos, worldAng = LocalToWorld(crosshairHudOffsetPos, crosshairHudOffsetAng, baseHudPos, baseHudAng)
    else
        -- 銃口情報がない場合は、右手コントローラーを基準にする (フォールバック)
        local handPos, handAng = vrmod.GetRightHandPose()
        if not handPos or not handAng then return end -- 右手データもなければ描画しない
        local baseHudAng = handAng
        local baseHudPos = handPos + baseHudAng:Forward() * crosshairHudDistance
        worldPos, worldAng = LocalToWorld(crosshairHudOffsetPos, crosshairHudOffsetAng, baseHudPos, baseHudAng)
    end

    if not worldPos or not worldAng then return end -- 最終的な位置・角度が計算できなければ描画しない
    cam.Start3D2D(worldPos, worldAng, crosshairHudScale)
    surface.SetMaterial(gmod_hud_shared_mat)
    surface.SetDrawColor(255, 255, 255, 255) -- 完全不透明
    -- ソースとなるレンダーターゲットのサイズ
    local rtSourceWidth = vrScrW:GetInt()
    local rtSourceHeight = vrScrH:GetInt()
    -- レンダーターゲットの中央から指定サイズ (crosshairHudRenderWidth x crosshairHudRenderHeight) を切り出す
    local cropWidth = crosshairHudRenderWidth
    local cropHeight = crosshairHudRenderHeight
    -- UV座標の計算: (レンダーターゲットの中央部分を抽出)
    local u1 = (rtSourceWidth - cropWidth) / 2 / rtSourceWidth
    local v1 = (rtSourceHeight - cropHeight) / 2 / rtSourceHeight
    local u2 = u1 + cropWidth / rtSourceWidth
    local v2 = v1 + cropHeight / rtSourceHeight
    -- 3D2D空間の (0,0) を左上として、指定した幅と高さでテクスチャを描画
    surface.DrawTexturedRectUV(0, 0, crosshairHudRenderWidth, crosshairHudRenderHeight, u1, v1, u2, v2)
    cam.End3D2D() -- 3D2D描画を終了
end

-- HUD描画用フックの更新関数
local function UpdateCrosshairHudRenderHookState()
    -- 既存のフックを一度クリア
    hook.Remove("PostDrawTranslucentRenderables", "VRMod_RenderCrosshairHudDirect")
    -- HUDが表示可能で、VRがアクティブな場合のみフックを追加
    if isCrosshairHudVisible and g_VR.active then
        hook.Add("PostDrawTranslucentRenderables", "VRMod_RenderCrosshairHudDirect", RenderCrosshairHudInSpace)
    end
end

-- クライアントサイドのコンソール変数を作成 (保存しない設定)
CreateClientConVar("vr_crosshair_hud", "0", true, FCVAR_ARCHIVE, "Toggles the VR crosshair HUD display.")
-- コンソール変数の変更を監視するコールバック
cvars.AddChangeCallback(
    "vr_crosshair_hud",
    function(convar_name, old_value, new_value)
        isCrosshairHudVisible = new_value == "1"
        UpdateCrosshairHudRenderHookState()
    end, "VRModCrosshairHudToggleCallback"
)

hook.Add(
    "VRMod_Start",
    "VRModCrosshairHud_OnVRStart",
    function(ply)
        if ply ~= LocalPlayer() then return end -- ローカルプレイヤーのみ対象
        -- VR開始時にConVarの現在の値に基づいてHUDの表示状態を初期化
        isCrosshairHudVisible = GetConVar("vr_crosshair_hud"):GetBool()
        UpdateCrosshairHudRenderHookState()
    end
)

hook.Add(
    "VRMod_Exit",
    "VRModCrosshairHud_OnVRExit",
    function(ply)
        if ply ~= LocalPlayer() then return end
        hook.Remove("PostDrawTranslucentRenderables", "VRMod_RenderCrosshairHudDirect")
    end
)
--------[vrmod_ui_crosshairhud.lua]End--------