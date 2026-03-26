-- vrmod_ui_buttonguide.lua
-- 透明VGUIパネルのクリック可能要素にガイドアウトラインを表示
-- VRカーソルがパネル上にある時 or VR入力時のみ走査・描画（FPS負荷軽減）
if SERVER then return end

local _, convarValues = vrmod.GetConvars()
vrmod.AddCallbackedConvar("vrmod_unoff_ui_guide", nil, 0, FCVAR_ARCHIVE, "Draw outlines on clickable UI elements in VR", 0, 1, tonumber)

-- ガイド表示中フラグ: VR入力があった時にtrueにし、一定時間後にfalseに戻す
local guideActive = false
local guideExpireTime = 0
local GUIDE_DURATION = 2 -- 入力後2秒間ガイドを表示

-- キャッシュ: uid毎にスキャン結果を保持
local guideCache = {}
local CACHE_LIFETIME = 1.0

-- カテゴリ別の色
local GUIDE_COLORS = {
	button = Color(0, 255, 100, 180),
	input  = Color(100, 180, 255, 180),
	custom = Color(255, 100, 255, 150),
}

local OUTLINE_THICKNESS = 2

-- クリック可能な要素のクラス名セット
local CLICKABLE_CLASSES = {
	DButton = true, DImageButton = true, DCheckBox = true,
	DComboBox = true, SpawnIcon = true, DNumberScratch = true,
	DColorMixer = true, DSlider = true, DBinder = true,
	DMenuOption = true, DCheckBoxLabel = true,
}

local INPUT_CLASSES = {
	DTextEntry = true, DNumberWang = true,
}

-- 再帰的に子要素をスキャンしてクリック可能な要素を収集
-- LocalToScreenで画面上の絶対座標を取得（PaintManualの描画位置と一致させるため）
local function ScanClickableChildren(panel, results)
	if not IsValid(panel) then return end
	for _, child in ipairs(panel:GetChildren()) do
		if IsValid(child) and child:IsVisible() then
			local cw, ch = child:GetSize()
			local className = child:GetClassName()

			local category = nil
			if CLICKABLE_CLASSES[className] then
				category = "button"
			elseif INPUT_CLASSES[className] then
				category = "input"
			elseif child.DoClick or child.OnMousePressed then
				category = "custom"
			end

			if category and cw > 4 and ch > 4 then
				local absX, absY = child:LocalToScreen(0, 0)
				results[#results + 1] = {
					x = absX, y = absY,
					w = cw, h = ch,
					category = category,
				}
			end

			ScanClickableChildren(child, results)
		end
	end
end

-- VR入力があった時にガイドをアクティブにする
hook.Add("VRMod_Input", "vrmod_unoff_buttonguide_activate", function(action, pressed)
	if convarValues.vrmod_unoff_ui_guide ~= 1 then return end
	if not g_VR.menuFocus then return end
	-- カーソルがパネル上にあり、かつ何かしらの入力があった時のみ
	guideActive = true
	guideExpireTime = RealTime() + GUIDE_DURATION
	-- 入力時にキャッシュを無効化して即時リスキャン
	guideCache = {}
end)

-- RT描画後フック: ガイドアウトラインを描画
hook.Add("VRMod_PostRenderPanel", "vrmod_unoff_buttonguide", function(uid, menuData)
	if convarValues.vrmod_unoff_ui_guide ~= 1 then return end
	if not menuData or not IsValid(menuData.panel) then return end

	-- ガイド表示条件: カーソルがこのパネル上にある、かつ guideActive
	local isFocused = (g_VR.menuFocus == uid)
	if not isFocused then return end
	if not guideActive then return end

	-- 有効期限チェック
	local now = RealTime()
	if now > guideExpireTime then
		guideActive = false
		return
	end

	-- キャッシュからスキャン結果を取得 or リスキャン
	local cached = guideCache[uid]
	if not cached or (now - cached.time) > CACHE_LIFETIME then
		local results = {}
		ScanClickableChildren(menuData.panel, results)
		guideCache[uid] = { time = now, elements = results }
		cached = guideCache[uid]
	end

	-- フェードアウト: 残り0.5秒でアルファを減衰
	local remaining = guideExpireTime - now
	local alphaScale = 1
	if remaining < 0.5 then
		alphaScale = remaining / 0.5
	end

	-- 描画
	for _, elem in ipairs(cached.elements) do
		local col = GUIDE_COLORS[elem.category] or GUIDE_COLORS.custom
		surface.SetDrawColor(col.r, col.g, col.b, col.a * alphaScale)
		for i = 0, OUTLINE_THICKNESS - 1 do
			surface.DrawOutlinedRect(
				elem.x + i, elem.y + i,
				elem.w - i * 2, elem.h - i * 2
			)
		end
	end
end)

-- VR終了時クリーンアップ
hook.Add("VRMod_Exit", "vrmod_unoff_buttonguide_cleanup", function(ply)
	if ply ~= LocalPlayer() then return end
	guideCache = {}
	guideActive = false
end)
