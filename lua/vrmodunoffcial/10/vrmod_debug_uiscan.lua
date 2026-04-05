--------[vrmod_debug_uiscan.lua]Start--------
AddCSLuaFile()
if not vrmod.debug or not vrmod.debug.enabled then return end
if SERVER then return end

-- ========================================
-- UI/HUD/VGUI 全描画イントロスペクション
-- Gmod/Source Engineの7カテゴリ描画システムを走査し、
-- VRModの5捕捉メカニズム(M1-M5)に照合してギャップ分析
--
-- カテゴリ:
--   A: Hook-Based Rendering (28種+)
--   B: Entity/Weapon Rendering
--   C: VGUI Panel System
--   D: Engine-Level (C++)
--   E: Render Target操作
--   F: 3D-in-World UI
--   G: Special Systems
--
-- VRMod捕捉メカニズム:
--   M1: render.RenderHUD() → 湾曲メッシュ (vrmod_hud.lua)
--   M2: VRUtilMenuOpen() → RT → 3D2D (vrmod_ui.lua)
--   M3: MakePopup() インターセプト (vrmod_dermapopups.lua)
--   M4: 独自3D描画 (vrmod_worldtips, vrmod_halos等)
--   M5: Hand HUD RT共有 (vrmod_left_hud等)
-- ========================================

local Log = vrmod.debug.Log

vrmod.debug.uiscan = vrmod.debug.uiscan or {}
local uiscan = vrmod.debug.uiscan

-- ----------------------------------------
-- 色定義（既存パネルと統一）
-- ----------------------------------------
local COLORS = {
	bg = Color(30, 30, 30),
	bgLight = Color(40, 40, 40),
	bgCode = Color(25, 25, 30),
	headerBg = Color(45, 45, 55),
	white = Color(255, 255, 255),
	gray = Color(150, 150, 150),
	green = Color(100, 255, 100),
	yellow = Color(255, 255, 100),
	orange = Color(255, 180, 80),
	cyan = Color(100, 220, 255),
	red = Color(255, 100, 100),
	darkGreen = Color(40, 80, 40),
	darkRed = Color(80, 30, 30),
	darkYellow = Color(80, 80, 30),
	darkGray = Color(50, 50, 50),
}

-- ----------------------------------------
-- VR捕捉ステータス定義
-- ----------------------------------------
local VR_STATUS = {
	CAPTURED = "captured",
	NOT_CAPTURED = "not_captured",
	PARTIAL = "partial",
	ENGINE = "engine",
	UNKNOWN = "unknown",
}

local VR_STATUS_COLORS = {
	[VR_STATUS.CAPTURED] = COLORS.green,
	[VR_STATUS.NOT_CAPTURED] = COLORS.red,
	[VR_STATUS.PARTIAL] = COLORS.yellow,
	[VR_STATUS.ENGINE] = COLORS.gray,
	[VR_STATUS.UNKNOWN] = COLORS.gray,
}

local VR_STATUS_BG = {
	[VR_STATUS.CAPTURED] = COLORS.darkGreen,
	[VR_STATUS.NOT_CAPTURED] = COLORS.darkRed,
	[VR_STATUS.PARTIAL] = COLORS.darkYellow,
	[VR_STATUS.ENGINE] = COLORS.darkGray,
	[VR_STATUS.UNKNOWN] = COLORS.darkGray,
}

-- ----------------------------------------
-- レンダリングフック定義（Phase分類 + VR捕捉ステータス）
-- ----------------------------------------
local RENDER_HOOKS = {
	-- Phase 0: Pre-Scene
	{ name = "PreRender",          phase = 0, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Very first rendering hook" },
	{ name = "RenderScene",        phase = 0, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Scene override" },

	-- Phase 1: Skybox
	{ name = "PreDrawSkyBox",      phase = 1, vrStatus = VR_STATUS.PARTIAL, desc = "Before skybox" },
	{ name = "PostDrawSkyBox",     phase = 1, vrStatus = VR_STATUS.PARTIAL, desc = "After skybox" },
	{ name = "PostDraw2DSkyBox",   phase = 1, vrStatus = VR_STATUS.PARTIAL, desc = "After 2D skybox" },
	{ name = "SetupSkyboxFog",     phase = 1, vrStatus = VR_STATUS.PARTIAL, desc = "Skybox fog" },
	{ name = "SetupWorldFog",      phase = 2, vrStatus = VR_STATUS.PARTIAL, desc = "World fog" },

	-- Phase 2: World
	{ name = "NeedsDepthPass",     phase = 2, vrStatus = VR_STATUS.PARTIAL, desc = "Depth pre-pass" },
	{ name = "GetMotionBlurValues", phase = 2, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Motion blur params" },
	{ name = "DrawMonitors",       phase = 2, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "In-world monitors" },

	-- Phase 3: Opaque
	{ name = "PreDrawOpaqueRenderables",  phase = 3, vrStatus = VR_STATUS.PARTIAL, desc = "Before opaque entities" },
	{ name = "PostDrawOpaqueRenderables", phase = 3, vrStatus = VR_STATUS.PARTIAL, desc = "After opaque entities (VRMod主要3Dフック)" },
	{ name = "PrePlayerDraw",     phase = 3, vrStatus = VR_STATUS.PARTIAL, desc = "Before player draw" },
	{ name = "PostPlayerDraw",    phase = 3, vrStatus = VR_STATUS.PARTIAL, desc = "After player draw" },

	-- Phase 4: Translucent
	{ name = "PreDrawTranslucentRenderables",  phase = 4, vrStatus = VR_STATUS.PARTIAL, desc = "Before translucent entities" },
	{ name = "PostDrawTranslucentRenderables", phase = 4, vrStatus = VR_STATUS.PARTIAL, desc = "After translucent (VRMod主要3Dフック)" },
	{ name = "DrawPhysgunBeam",   phase = 4, vrStatus = VR_STATUS.PARTIAL, desc = "Physgun beam" },

	-- Phase 5: ViewModel
	{ name = "PreDrawViewModels",  phase = 5, vrStatus = VR_STATUS.PARTIAL, desc = "Before viewmodels" },
	{ name = "PreDrawViewModel",   phase = 5, vrStatus = VR_STATUS.PARTIAL, desc = "Before specific VM" },
	{ name = "PostDrawViewModel",  phase = 5, vrStatus = VR_STATUS.PARTIAL, desc = "After specific VM" },
	{ name = "PreDrawPlayerHands", phase = 5, vrStatus = VR_STATUS.PARTIAL, desc = "Before hand models" },
	{ name = "PostDrawPlayerHands", phase = 5, vrStatus = VR_STATUS.PARTIAL, desc = "After hand models" },

	-- Phase 6: Effects & Post-Processing
	{ name = "PreDrawEffects",     phase = 6, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Before effects" },
	{ name = "RenderScreenspaceEffects", phase = 6, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Post-processing (bloom, color etc)" },
	{ name = "PostDrawEffects",    phase = 6, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "After effects + halos" },
	{ name = "PreDrawHalos",       phase = 6, vrStatus = VR_STATUS.PARTIAL, desc = "Before halo render (M4で独自実装)" },

	-- Phase 7: HUD (DrawActiveHUD) — render.RenderHUD()で捕捉 (M1)
	{ name = "PreDrawHUD",         phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "Before HUD (M1)" },
	{ name = "HUDPaintBackground", phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "HUD background (M1)" },
	{ name = "HUDPaint",           phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "Primary HUD hook (M1)" },
	{ name = "HUDDrawTargetID",    phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "Player info overlay (M1)" },
	{ name = "HUDDrawPickupHistory", phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "Pickup notifications (M1)" },
	{ name = "DrawDeathNotice",    phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "Kill feed (M1)" },
	{ name = "HUDDrawScoreBoard",  phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "Scoreboard (M1)" },
	{ name = "HUDShouldDraw",      phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "HUD element visibility (M1)" },
	{ name = "PostDrawHUD",        phase = 7, vrStatus = VR_STATUS.CAPTURED, desc = "After HUD (M1)" },

	-- Phase 8: Overlay & Post
	{ name = "DrawOverlay",        phase = 8, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Screen overlays" },
	{ name = "PostRenderVGUI",     phase = 8, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "After VGUI rendering" },
	{ name = "PostRender",         phase = 8, vrStatus = VR_STATUS.NOT_CAPTURED, desc = "Very last hook" },

	-- CalcView
	{ name = "CalcView",           phase = 9, vrStatus = VR_STATUS.PARTIAL, desc = "View override" },
	{ name = "CalcViewModelView",  phase = 9, vrStatus = VR_STATUS.PARTIAL, desc = "VM view override" },
	{ name = "ShouldDrawLocalPlayer", phase = 9, vrStatus = VR_STATUS.PARTIAL, desc = "Local player visibility" },
}

-- Phase 7のフック名セット（高速ルックアップ用）
local PHASE7_HOOKS = {}
for _, h in ipairs(RENDER_HOOKS) do
	if h.phase == 7 then
		PHASE7_HOOKS[h.name] = true
	end
end

-- フック名→定義のルックアップ
local HOOK_DEFS = {}
for _, h in ipairs(RENDER_HOOKS) do
	HOOK_DEFS[h.name] = h
end

-- Phase名
local PHASE_NAMES = {
	[0] = "Pre-Scene",
	[1] = "Skybox",
	[2] = "World",
	[3] = "Opaque",
	[4] = "Translucent",
	[5] = "ViewModel",
	[6] = "Effects/PP",
	[7] = "HUD (M1 Captured)",
	[8] = "Overlay/Post",
	[9] = "CalcView",
}

-- Engine HUD要素（C++レンダリング、Luaでは捕捉不能）
local ENGINE_HUD_ELEMENTS = {
	"CHudAmmo", "CHudBattery", "CHudChat", "CHudCrosshair",
	"CHudCloseCaption", "CHudDamageIndicator", "CHudDeathNotice",
	"CHudGeiger", "CHudGMod", "CHudHealth", "CHudHintDisplay",
	"CHudHistoryResource", "CHudMenu", "CHudMessage",
	"CHudPoisonDamageIndicator", "CHudSecondaryAmmo", "CHudSquadStatus",
	"CHudTrain", "CHudVehicle", "CHudWeapon", "CHudWeaponSelection",
	"CHudZoom", "NetGraph", "CFPSPanel", "CHUDQuickInfo", "CHudSuitPower",
}

-- ----------------------------------------
-- 静的スキャンパターン定義（60種）
-- ----------------------------------------
local STATIC_PATTERNS = {
	-- A: Hook registration
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(HUDPaint[^"]*)"',    desc = "HUD Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(HUDPaintBackground)"', desc = "HUDPaintBG Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PostDrawHUD)"',       desc = "PostDrawHUD Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PreDrawHUD)"',        desc = "PreDrawHUD Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(DrawOverlay)"',       desc = "DrawOverlay Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PostRenderVGUI)"',    desc = "PostRenderVGUI Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(RenderScreenspaceEffects)"', desc = "ScreenspaceEffects Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PostDrawEffects)"',   desc = "PostDrawEffects Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PreDrawEffects)"',    desc = "PreDrawEffects Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PostDrawOpaqueRenderables)"',      desc = "PostDrawOpaque Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PostDrawTranslucentRenderables)"', desc = "PostDrawTranslucent Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PreDrawOpaqueRenderables)"',       desc = "PreDrawOpaque Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PreDrawTranslucentRenderables)"',  desc = "PreDrawTranslucent Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(PreDrawHalos)"',      desc = "PreDrawHalos Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(DrawDeathNotice)"',   desc = "DrawDeathNotice Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(HUDDrawTargetID)"',   desc = "HUDDrawTargetID Hook" },
	{ cat = "A", pattern = 'hook%.Add%s*%(%s*"(HUDShouldDraw)"',     desc = "HUDShouldDraw Hook" },

	-- A: Post-Processing
	{ cat = "A", pattern = 'DrawBloom%s*%(', desc = "PP: DrawBloom" },
	{ cat = "A", pattern = 'DrawColorModify%s*%(', desc = "PP: DrawColorModify" },
	{ cat = "A", pattern = 'DrawMotionBlur%s*%(', desc = "PP: DrawMotionBlur" },
	{ cat = "A", pattern = 'DrawSharpen%s*%(', desc = "PP: DrawSharpen" },
	{ cat = "A", pattern = 'DrawSobel%s*%(', desc = "PP: DrawSobel" },
	{ cat = "A", pattern = 'DrawMaterialOverlay%s*%(', desc = "PP: DrawMaterialOverlay" },

	-- B: Entity/Weapon rendering
	{ cat = "B", pattern = 'function%s+ENT[:%.]Draw%s*%(', desc = "ENT:Draw" },
	{ cat = "B", pattern = 'function%s+ENT[:%.]DrawTranslucent%s*%(', desc = "ENT:DrawTranslucent" },
	{ cat = "B", pattern = 'function%s+ENT[:%.]RenderOverride%s*%(', desc = "ENT:RenderOverride" },
	{ cat = "B", pattern = 'function%s+SWEP[:%.]DrawHUD%s*%(', desc = "SWEP:DrawHUD" },
	{ cat = "B", pattern = 'function%s+SWEP[:%.]DrawHUDBackground%s*%(', desc = "SWEP:DrawHUDBackground" },
	{ cat = "B", pattern = 'function%s+SWEP[:%.]DrawWorldModel%s*%(', desc = "SWEP:DrawWorldModel" },
	{ cat = "B", pattern = 'function%s+SWEP[:%.]DrawWorldModelTranslucent%s*%(', desc = "SWEP:DrawWorldModelTranslucent" },
	{ cat = "B", pattern = 'function%s+SWEP[:%.]RenderScreen%s*%(', desc = "SWEP:RenderScreen" },
	{ cat = "B", pattern = 'function%s+SWEP[:%.]DoDrawCrosshair%s*%(', desc = "SWEP:DoDrawCrosshair" },
	{ cat = "B", pattern = 'function%s+EFFECT[:%.]Render%s*%(', desc = "EFFECT:Render" },
	{ cat = "B", pattern = 'function%s+TOOL[:%.]DrawToolScreen%s*%(', desc = "TOOL:DrawToolScreen" },
	{ cat = "B", pattern = 'function%s+TOOL[:%.]DrawHUD%s*%(', desc = "TOOL:DrawHUD" },

	-- C: VGUI
	{ cat = "C", pattern = 'vgui%.Create%s*%(', desc = "vgui.Create" },
	{ cat = "C", pattern = 'vgui%.Register%s*%(', desc = "vgui.Register" },
	{ cat = "C", pattern = 'function%s+PANEL[:%.]Paint%s*%(', desc = "PANEL:Paint" },
	{ cat = "C", pattern = 'function%s+PANEL[:%.]PaintOver%s*%(', desc = "PANEL:PaintOver" },
	{ cat = "C", pattern = 'PaintManual%s*%(', desc = "PaintManual()" },
	{ cat = "C", pattern = 'SetPaintedManually%s*%(', desc = "SetPaintedManually()" },
	{ cat = "C", pattern = 'GetHTMLMaterial%s*%(', desc = "GetHTMLMaterial()" },

	-- C: Derma
	{ cat = "C", pattern = 'derma%.SkinHook', desc = "derma.SkinHook" },
	{ cat = "C", pattern = 'Derma_StringRequest%s*%(', desc = "Derma_StringRequest" },
	{ cat = "C", pattern = 'Derma_Query%s*%(', desc = "Derma_Query" },
	{ cat = "C", pattern = 'Derma_Message%s*%(', desc = "Derma_Message" },
	{ cat = "C", pattern = 'DermaMenu%s*%(', desc = "DermaMenu()" },

	-- E: Render Target
	{ cat = "E", pattern = 'render%.PushRenderTarget%s*%(', desc = "RT: PushRenderTarget" },
	{ cat = "E", pattern = 'render%.PopRenderTarget%s*%(', desc = "RT: PopRenderTarget" },
	{ cat = "E", pattern = 'GetRenderTarget%s*%(', desc = "RT: GetRenderTarget" },
	{ cat = "E", pattern = 'GetRenderTargetEx%s*%(', desc = "RT: GetRenderTargetEx" },
	{ cat = "E", pattern = 'render%.RenderView%s*%(', desc = "RT: RenderView" },
	{ cat = "E", pattern = 'render%.RenderHUD%s*%(', desc = "RT: RenderHUD" },
	{ cat = "E", pattern = 'render%.Capture%s*%(', desc = "RT: Capture" },

	-- F: 3D-in-World
	{ cat = "F", pattern = 'cam%.Start3D2D%s*%(', desc = "cam.Start3D2D" },
	{ cat = "F", pattern = 'cam%.PushModelMatrix%s*%(', desc = "cam.PushModelMatrix" },
	{ cat = "F", pattern = 'mesh%.Begin%s*%(', desc = "mesh.Begin" },
	{ cat = "F", pattern = 'render%.DrawBeam%s*%(', desc = "render.DrawBeam" },
	{ cat = "F", pattern = 'render%.DrawSprite%s*%(', desc = "render.DrawSprite" },
	{ cat = "F", pattern = 'render%.DrawQuadEasy%s*%(', desc = "render.DrawQuadEasy" },

	-- G: Special Systems
	{ cat = "G", pattern = 'halo%.Add%s*%(', desc = "halo.Add" },
	{ cat = "G", pattern = 'killicon%.Add[^A]', desc = "killicon.Add" },
	{ cat = "G", pattern = 'notification%.Add', desc = "notification.Add*" },
	{ cat = "G", pattern = 'chat%.AddText%s*%(', desc = "chat.AddText" },
	{ cat = "G", pattern = 'markup%.Parse%s*%(', desc = "markup.Parse" },
	{ cat = "G", pattern = 'matproxy%.Add%s*%(', desc = "matproxy.Add" },
	{ cat = "G", pattern = 'render%.SetStencilEnable%s*%(', desc = "Stencil ops" },
}

-- ----------------------------------------
-- カテゴリ名
-- ----------------------------------------
local CAT_NAMES = {
	A = "Hook-Based Rendering",
	B = "Entity/Weapon Rendering",
	C = "VGUI/Derma/Drawing",
	D = "Engine (C++)",
	E = "Render Target",
	F = "3D-in-World",
	G = "Special Systems",
}

-- ========================================
-- Scan 1: レンダリングフック走査
-- ========================================
function uiscan.ScanRenderHooks()
	local startTime = SysTime()
	local results = {}

	local hookTable = hook.GetTable()
	local gm = GAMEMODE or (gmod and gmod.GetGamemode and gmod.GetGamemode())

	for _, hookDef in ipairs(RENDER_HOOKS) do
		local entry = {
			name = hookDef.name,
			phase = hookDef.phase,
			phaseName = PHASE_NAMES[hookDef.phase] or "Unknown",
			vrStatus = hookDef.vrStatus,
			desc = hookDef.desc,
			cat = "A",
			callbacks = {},
			gamemodeMethod = nil,
		}

		-- hook.GetTable() からコールバック収集
		local cbs = hookTable[hookDef.name]
		if cbs then
			for cbName, fn in pairs(cbs) do
				local info = debug.getinfo(fn, "Sl")
				table.insert(entry.callbacks, {
					name = cbName,
					source = info and info.short_src or "[C]",
					line = info and info.linedefined or 0,
					lastline = info and info.lastlinedefined or 0,
				})
			end
			table.sort(entry.callbacks, function(a, b) return a.name < b.name end)
		end

		-- GAMEMODE メソッドチェック
		if gm and gm[hookDef.name] then
			local info = debug.getinfo(gm[hookDef.name], "Sl")
			entry.gamemodeMethod = {
				source = info and info.short_src or "[C]",
				line = info and info.linedefined or 0,
			}
		end

		entry.totalCallbacks = #entry.callbacks + (entry.gamemodeMethod and 1 or 0)
		table.insert(results, entry)
	end

	uiscan.renderHooks = results
	local elapsed = SysTime() - startTime
	Log.Info("uiscan", string.format("ScanRenderHooks: %d hooks, %d with callbacks (%.3fs)",
		#results,
		#table.filter(results, function(_, e) return e.totalCallbacks > 0 end),
		elapsed))
	return results
end

-- ========================================
-- Scan 2: VGUIパネル全走査
-- ========================================
function uiscan.ScanAllPanels()
	local startTime = SysTime()
	local results = {}

	local allPanels = vgui.GetAll()
	if not allPanels then
		Log.Warn("uiscan", "vgui.GetAll() returned nil")
		return {}
	end

	local worldPanel = vgui.GetWorldPanel()
	local hudPanel = vgui.GetHUDPanel()

	for _, panel in ipairs(allPanels) do
		if not IsValid(panel) then continue end

		local className = panel:GetClassName() or "unknown"
		local name = panel:GetName() or ""
		local x, y = panel:GetPos()
		local w, h = panel:GetSize()
		local visible = panel:IsVisible()
		local alpha = panel:GetAlpha()

		-- Paint メソッド情報
		local hasPaint = false
		local paintSource = nil
		local paintLine = 0
		local hasPaintOver = false

		if panel.Paint and type(panel.Paint) == "function" then
			hasPaint = true
			local ok, info = pcall(debug.getinfo, panel.Paint, "Sl")
			if ok and info then
				paintSource = info.short_src
				paintLine = info.linedefined or 0
			end
		end

		if panel.PaintOver and type(panel.PaintOver) == "function" then
			hasPaintOver = true
		end

		-- SetPaintedManually 状態チェック
		local isPaintedManually = false
		if panel.IsPaintedManually and type(panel.IsPaintedManually) == "function" then
			local ok, val = pcall(panel.IsPaintedManually, panel)
			if ok then isPaintedManually = val end
		end

		-- 親パネル分類
		local parentType = "unknown"
		local parent = panel:GetParent()
		if not IsValid(parent) or parent == worldPanel then
			parentType = "world"
		elseif parent == hudPanel then
			parentType = "hud"
		else
			-- DFrame配下チェック
			local p = parent
			local depth = 0
			while IsValid(p) and depth < 20 do
				if p:GetClassName() == "DFrame" then
					parentType = "dframe"
					break
				elseif p:GetClassName() == "DMenu" or p:GetClassName() == "DMenuBar" then
					parentType = "menu"
					break
				elseif p == hudPanel then
					parentType = "hud_descendant"
					break
				elseif p == worldPanel then
					parentType = "world_descendant"
					break
				end
				p = p:GetParent()
				depth = depth + 1
			end
		end

		-- パネル分類ヒューリスティック
		local panelType = "unknown"
		if className == "DFrame" or className == "DMenu" or className == "DMenuBar"
			or className == "DTooltip" or className == "DScrollPanel" then
			panelType = "interactive"
		elseif className == "RichText" or className == "ChatInput" then
			panelType = "system"
		elseif parentType == "hud" or parentType == "hud_descendant" then
			panelType = "hud_like"
		elseif isPaintedManually then
			panelType = "manual_paint"
		elseif parentType == "dframe" or parentType == "menu" then
			panelType = "interactive"
		elseif hasPaint and visible and (parentType == "world" or parentType == "world_descendant") then
			panelType = "hud_like"
		else
			panelType = "other"
		end

		-- VR捕捉ステータス判定
		local vrStatus = VR_STATUS.NOT_CAPTURED
		if isPaintedManually then
			-- PaintManual対象はM2/M3経由の可能性あり
			vrStatus = VR_STATUS.PARTIAL
		end
		if parentType == "dframe" then
			-- DFrame系はMakePopup()インターセプト(M3)で捕捉される可能性
			vrStatus = VR_STATUS.PARTIAL
		end
		if not visible then
			vrStatus = VR_STATUS.UNKNOWN
		end

		table.insert(results, {
			id = tostring(panel),
			className = className,
			name = name,
			x = x, y = y, w = w, h = h,
			visible = visible,
			alpha = alpha,
			hasPaint = hasPaint,
			paintSource = paintSource,
			paintLine = paintLine,
			hasPaintOver = hasPaintOver,
			isPaintedManually = isPaintedManually,
			parentType = parentType,
			panelType = panelType,
			vrStatus = vrStatus,
			cat = "C",
		})
	end

	-- クラス名でソート
	table.sort(results, function(a, b)
		if a.className == b.className then return a.name < b.name end
		return a.className < b.className
	end)

	uiscan.panels = results
	local elapsed = SysTime() - startTime

	-- 統計
	local stats = { total = #results, visible = 0, hasPaint = 0, hudLike = 0 }
	for _, p in ipairs(results) do
		if p.visible then stats.visible = stats.visible + 1 end
		if p.hasPaint then stats.hasPaint = stats.hasPaint + 1 end
		if p.panelType == "hud_like" then stats.hudLike = stats.hudLike + 1 end
	end

	Log.Info("uiscan", string.format("ScanAllPanels: %d total, %d visible, %d with Paint, %d HUD-like (%.3fs)",
		stats.total, stats.visible, stats.hasPaint, stats.hudLike, elapsed))
	return results
end

-- ========================================
-- Scan 3: Entity/Weapon描画走査
-- ========================================
function uiscan.ScanEntityRendering()
	local startTime = SysTime()
	local results = {}

	-- スクリプトエンティティ走査
	local allEnts = ents.GetAll()
	local seenClasses = {}
	for _, ent in ipairs(allEnts) do
		if not IsValid(ent) then continue end
		local class = ent:GetClass()
		if seenClasses[class] then continue end

		local tbl = ent:GetTable()
		if not tbl then continue end

		local hasDraw = type(tbl.Draw) == "function"
		local hasDrawTranslucent = type(tbl.DrawTranslucent) == "function"
		local hasRenderOverride = type(tbl.RenderOverride) == "function"

		if hasDraw or hasDrawTranslucent or hasRenderOverride then
			seenClasses[class] = true
			local entry = {
				cat = "B",
				subType = "entity",
				class = class,
				methods = {},
				vrStatus = VR_STATUS.PARTIAL, -- 3D空間描画はVRでそのまま見える
			}

			if hasDraw then
				local info = debug.getinfo(tbl.Draw, "Sl")
				table.insert(entry.methods, {
					name = "ENT:Draw",
					source = info and info.short_src or "[C]",
					line = info and info.linedefined or 0,
				})
			end
			if hasDrawTranslucent then
				local info = debug.getinfo(tbl.DrawTranslucent, "Sl")
				table.insert(entry.methods, {
					name = "ENT:DrawTranslucent",
					source = info and info.short_src or "[C]",
					line = info and info.linedefined or 0,
				})
			end
			if hasRenderOverride then
				local info = debug.getinfo(tbl.RenderOverride, "Sl")
				table.insert(entry.methods, {
					name = "ENT:RenderOverride",
					source = info and info.short_src or "[C]",
					line = info and info.linedefined or 0,
				})
			end

			table.insert(results, entry)
		end
	end

	-- 武器走査
	local weaponList = weapons.GetList()
	if weaponList then
		for _, swep in ipairs(weaponList) do
			local class = swep.ClassName or swep.Folder or "unknown"
			local entry = nil

			local checkMethods = {
				{ key = "DrawHUD", name = "SWEP:DrawHUD", vrStatus = VR_STATUS.CAPTURED },
				{ key = "DrawHUDBackground", name = "SWEP:DrawHUDBackground", vrStatus = VR_STATUS.CAPTURED },
				{ key = "DoDrawCrosshair", name = "SWEP:DoDrawCrosshair", vrStatus = VR_STATUS.CAPTURED },
				{ key = "DrawWorldModel", name = "SWEP:DrawWorldModel", vrStatus = VR_STATUS.PARTIAL },
				{ key = "DrawWorldModelTranslucent", name = "SWEP:DrawWorldModelTranslucent", vrStatus = VR_STATUS.PARTIAL },
				{ key = "RenderScreen", name = "SWEP:RenderScreen", vrStatus = VR_STATUS.NOT_CAPTURED },
			}

			for _, m in ipairs(checkMethods) do
				if swep[m.key] and type(swep[m.key]) == "function" then
					if not entry then
						entry = {
							cat = "B",
							subType = "weapon",
							class = class,
							methods = {},
							vrStatus = VR_STATUS.PARTIAL,
						}
					end
					local info = debug.getinfo(swep[m.key], "Sl")
					table.insert(entry.methods, {
						name = m.name,
						source = info and info.short_src or "[C]",
						line = info and info.linedefined or 0,
						vrStatus = m.vrStatus,
					})
				end
			end

			if entry then
				table.insert(results, entry)
			end
		end
	end

	-- Effect走査
	local effectList = effects and effects.GetList and effects.GetList()
	if effectList then
		for _, eff in ipairs(effectList) do
			if eff.Render and type(eff.Render) == "function" then
				local info = debug.getinfo(eff.Render, "Sl")
				table.insert(results, {
					cat = "B",
					subType = "effect",
					class = eff.Name or "unknown",
					methods = {
						{
							name = "EFFECT:Render",
							source = info and info.short_src or "[C]",
							line = info and info.linedefined or 0,
						}
					},
					vrStatus = VR_STATUS.PARTIAL,
				})
			end
		end
	end

	table.sort(results, function(a, b)
		if a.subType == b.subType then return a.class < b.class end
		return a.subType < b.subType
	end)

	uiscan.entities = results
	local elapsed = SysTime() - startTime
	Log.Info("uiscan", string.format("ScanEntityRendering: %d items (%.3fs)", #results, elapsed))
	return results
end

-- ========================================
-- Scan 4: 静的Luaファイルスキャン
-- ========================================
function uiscan.RunStaticScan(scope)
	scope = scope or "all"
	local startTime = SysTime()
	local results = {}
	local totalFiles = 0
	local matchedFiles = 0
	local MAX_FILES = 2000
	local MAX_FILE_SIZE = 512 * 1024 -- 500KB

	-- ファイル収集（再帰）
	local allFiles = {}

	local function CollectFiles(dir, baseDir)
		if #allFiles >= MAX_FILES then return end
		local files, dirs = file.Find(dir .. "/*", baseDir)
		if files then
			for _, f in ipairs(files) do
				if string.GetExtensionFromFilename(f) == "lua" then
					table.insert(allFiles, dir .. "/" .. f)
					if #allFiles >= MAX_FILES then return end
				end
			end
		end
		if dirs then
			for _, d in ipairs(dirs) do
				CollectFiles(dir .. "/" .. d, baseDir)
				if #allFiles >= MAX_FILES then return end
			end
		end
	end

	-- スコープに応じてスキャンディレクトリ決定
	if scope == "addons" then
		local _, addonDirs = file.Find("addons/*", "GAME")
		if addonDirs then
			for _, addon in ipairs(addonDirs) do
				CollectFiles("addons/" .. addon .. "/lua", "GAME")
			end
		end
	elseif scope == "gamemodes" then
		local _, gmDirs = file.Find("gamemodes/*", "GAME")
		if gmDirs then
			for _, gm in ipairs(gmDirs) do
				CollectFiles("gamemodes/" .. gm, "GAME")
			end
		end
	else -- "all"
		CollectFiles("lua", "GAME")
		local _, addonDirs = file.Find("addons/*", "GAME")
		if addonDirs then
			for _, addon in ipairs(addonDirs) do
				CollectFiles("addons/" .. addon .. "/lua", "GAME")
			end
		end
		local _, gmDirs = file.Find("gamemodes/*", "GAME")
		if gmDirs then
			for _, gm in ipairs(gmDirs) do
				CollectFiles("gamemodes/" .. gm, "GAME")
			end
		end
	end

	totalFiles = #allFiles

	-- パターンごとの集計
	local patternSummary = {}
	for _, p in ipairs(STATIC_PATTERNS) do
		patternSummary[p.desc] = { cat = p.cat, count = 0, files = {} }
	end

	-- ファイルスキャン
	for _, filePath in ipairs(allFiles) do
		local content = file.Read(filePath, "GAME")
		if not content then continue end
		if #content > MAX_FILE_SIZE then continue end

		local fileMatches = {}
		for _, p in ipairs(STATIC_PATTERNS) do
			-- 各パターンで行単位マッチ
			local lineNum = 0
			for line in string.gmatch(content, "[^\r\n]+") do
				lineNum = lineNum + 1
				local match = string.find(line, p.pattern)
				if match then
					table.insert(fileMatches, {
						cat = p.cat,
						pattern = p.desc,
						line = lineNum,
						context = string.sub(string.Trim(line), 1, 120),
					})
					patternSummary[p.desc].count = patternSummary[p.desc].count + 1
					-- ファイル一覧に追加（重複排除）
					local alreadyIn = false
					for _, f in ipairs(patternSummary[p.desc].files) do
						if f == filePath then alreadyIn = true break end
					end
					if not alreadyIn then
						table.insert(patternSummary[p.desc].files, filePath)
					end
				end
			end
		end

		if #fileMatches > 0 then
			matchedFiles = matchedFiles + 1

			-- ソース分類（addon名 or gamemode名 or core）
			local source = "core"
			local addonMatch = string.match(filePath, "^addons/([^/]+)/")
			if addonMatch then
				source = addonMatch
			else
				local gmMatch = string.match(filePath, "^gamemodes/([^/]+)/")
				if gmMatch then source = "gm:" .. gmMatch end
			end

			table.insert(results, {
				filePath = filePath,
				source = source,
				matches = fileMatches,
				matchCount = #fileMatches,
			})
		end
	end

	-- マッチ数でソート
	table.sort(results, function(a, b) return a.matchCount > b.matchCount end)

	uiscan.staticScan = {
		scope = scope,
		totalFiles = totalFiles,
		matchedFiles = matchedFiles,
		results = results,
		patternSummary = patternSummary,
	}

	local elapsed = SysTime() - startTime
	Log.Info("uiscan", string.format("RunStaticScan(%s): %d/%d files matched, %d patterns (%.1fs)",
		scope, matchedFiles, totalFiles, #STATIC_PATTERNS, elapsed))
	return uiscan.staticScan
end

-- ========================================
-- Scan 5: Paint活動計測
-- ========================================
function uiscan.MeasurePaintActivity(duration)
	duration = duration or 2
	duration = math.Clamp(duration, 0.5, 10)

	if uiscan._paintMeasuring then
		Log.Warn("uiscan", "Paint measurement already in progress")
		return
	end

	if not uiscan.panels then
		Log.Warn("uiscan", "Run ScanAllPanels first")
		return
	end

	uiscan._paintMeasuring = true
	local results = {}
	local origPaints = {}
	local MAX_PANELS = 50

	-- 可視 + Paint付きパネルを選択
	local targets = {}
	for _, pData in ipairs(uiscan.panels) do
		if #targets >= MAX_PANELS then break end
		if pData.visible and pData.hasPaint then
			-- パネルを再発見（IDはアドレス文字列）
			local allPanels = vgui.GetAll()
			for _, panel in ipairs(allPanels) do
				if IsValid(panel) and tostring(panel) == pData.id then
					table.insert(targets, { panel = panel, data = pData })
					break
				end
			end
		end
	end

	Log.Info("uiscan", string.format("Measuring Paint on %d panels for %.1fs...", #targets, duration))

	-- Paintラップ
	for _, t in ipairs(targets) do
		local panel = t.panel
		local origPaint = panel.Paint
		origPaints[t.data.id] = { panel = panel, origPaint = origPaint }

		local callCount = 0
		local totalTime = 0
		local maxTime = 0

		panel.Paint = function(self, w, h)
			local st = SysTime()
			origPaint(self, w, h)
			local elapsed = SysTime() - st
			callCount = callCount + 1
			totalTime = totalTime + elapsed
			if elapsed > maxTime then maxTime = elapsed end
		end

		results[t.data.id] = {
			className = t.data.className,
			name = t.data.name,
			getCount = function() return callCount end,
			getTotalTime = function() return totalTime end,
			getMaxTime = function() return maxTime end,
		}
	end

	-- 自動復元タイマー
	timer.Simple(duration, function()
		-- 全Paint復元
		for id, orig in pairs(origPaints) do
			if IsValid(orig.panel) then
				orig.panel.Paint = orig.origPaint
			end
		end

		-- 結果収集
		local paintResults = {}
		for id, r in pairs(results) do
			table.insert(paintResults, {
				id = id,
				className = r.className,
				name = r.name,
				callCount = r.getCount(),
				totalTime_ms = math.Round(r.getTotalTime() * 1000, 3),
				maxTime_ms = math.Round(r.getMaxTime() * 1000, 3),
				avgTime_ms = r.getCount() > 0 and math.Round(r.getTotalTime() / r.getCount() * 1000, 3) or 0,
				isActive = r.getCount() > 0,
				measuredDuration = duration,
			})
		end

		table.sort(paintResults, function(a, b) return a.callCount > b.callCount end)

		uiscan.paintActivity = paintResults
		uiscan._paintMeasuring = false

		local activeCount = 0
		for _, p in ipairs(paintResults) do
			if p.isActive then activeCount = activeCount + 1 end
		end

		Log.Info("uiscan", string.format("MeasurePaintActivity: %d/%d panels active", activeCount, #paintResults))
	end)
end

-- ========================================
-- Scan 6: RT使用状況モニタ
-- ========================================
function uiscan.MonitorRenderTargets(duration)
	duration = duration or 5
	duration = math.Clamp(duration, 1, 30)

	if uiscan._rtMonitoring then
		Log.Warn("uiscan", "RT monitoring already in progress")
		return
	end

	uiscan._rtMonitoring = true
	local rtLog = {}
	local rtCounts = {}

	-- render.PushRenderTarget ラップ
	local origPush = render.PushRenderTarget
	local origPop = render.PopRenderTarget
	local stackDepth = 0

	render.PushRenderTarget = function(rt, ...)
		stackDepth = stackDepth + 1
		local rtName = "unknown"
		if rt then
			local ok, name = pcall(function() return rt:GetName() end)
			if ok and name then rtName = name end
		end

		rtCounts[rtName] = (rtCounts[rtName] or 0) + 1

		-- 最初の100回だけログ
		if #rtLog < 100 then
			-- debug.getinfoのコスト軽減: 最初の10回だけソース取得
			local source = nil
			if #rtLog < 10 then
				local info = debug.getinfo(2, "Sl")
				source = info and (info.short_src .. ":" .. (info.linedefined or 0)) or nil
			end

			table.insert(rtLog, {
				time = SysTime(),
				action = "push",
				rtName = rtName,
				depth = stackDepth,
				source = source,
			})
		end

		return origPush(rt, ...)
	end

	render.PopRenderTarget = function(...)
		stackDepth = math.max(0, stackDepth - 1)
		return origPop(...)
	end

	Log.Info("uiscan", string.format("Monitoring RenderTargets for %.0fs...", duration))

	-- 自動復元タイマー
	timer.Simple(duration, function()
		render.PushRenderTarget = origPush
		render.PopRenderTarget = origPop
		uiscan._rtMonitoring = false

		-- RT使用状況をまとめる
		local rtResults = {}
		for rtName, count in pairs(rtCounts) do
			table.insert(rtResults, {
				name = rtName,
				pushCount = count,
				perSecond = math.Round(count / duration, 1),
			})
		end
		table.sort(rtResults, function(a, b) return a.pushCount > b.pushCount end)

		uiscan.renderTargets = {
			duration = duration,
			totalPushes = 0,
			log = rtLog,
			summary = rtResults,
		}

		for _, r in ipairs(rtResults) do
			uiscan.renderTargets.totalPushes = uiscan.renderTargets.totalPushes + r.pushCount
		end

		Log.Info("uiscan", string.format("MonitorRenderTargets: %d RT names, %d total pushes in %.0fs",
			#rtResults, uiscan.renderTargets.totalPushes, duration))
	end)
end

-- ========================================
-- Scan 7: System UI走査
-- ========================================
function uiscan.ScanSystemUI()
	local startTime = SysTime()
	local results = {}

	local allPanels = vgui.GetAll()
	if not allPanels then return {} end

	for _, panel in ipairs(allPanels) do
		if not IsValid(panel) then continue end

		local className = panel:GetClassName() or ""
		local entry = nil

		-- チャットパネル検出
		if className == "RichText" or className == "ChatInput" then
			entry = {
				cat = "G",
				systemType = "chat",
				className = className,
				name = panel:GetName() or "",
				visible = panel:IsVisible(),
				x = 0, y = 0, w = 0, h = 0,
				vrStatus = VR_STATUS.NOT_CAPTURED,
				desc = "Chat system panel",
			}
			entry.x, entry.y = panel:GetPos()
			entry.w, entry.h = panel:GetSize()
		end

		-- DHTML/HTMLパネル検出
		if className == "DHTML" or className == "HTML" or className == "DHTMLControls" then
			entry = {
				cat = "G",
				systemType = "html",
				className = className,
				name = panel:GetName() or "",
				visible = panel:IsVisible(),
				x = 0, y = 0, w = 0, h = 0,
				vrStatus = VR_STATUS.NOT_CAPTURED,
				desc = "HTML/Web rendering panel",
			}
			entry.x, entry.y = panel:GetPos()
			entry.w, entry.h = panel:GetSize()
		end

		-- コンテキストメニュー検出
		if className == "DMenu" or className == "DMenuOption" then
			entry = {
				cat = "G",
				systemType = "menu",
				className = className,
				name = panel:GetName() or "",
				visible = panel:IsVisible(),
				x = 0, y = 0, w = 0, h = 0,
				vrStatus = VR_STATUS.PARTIAL, -- MakePopup経由(M3)で捕捉される可能性
				desc = "Context menu panel",
			}
			entry.x, entry.y = panel:GetPos()
			entry.w, entry.h = panel:GetSize()
		end

		-- DTooltip検出
		if className == "DTooltip" then
			entry = {
				cat = "G",
				systemType = "tooltip",
				className = className,
				name = panel:GetName() or "",
				visible = panel:IsVisible(),
				x = 0, y = 0, w = 0, h = 0,
				vrStatus = VR_STATUS.NOT_CAPTURED,
				desc = "Tooltip panel",
			}
			entry.x, entry.y = panel:GetPos()
			entry.w, entry.h = panel:GetSize()
		end

		if entry then
			table.insert(results, entry)
		end
	end

	-- Engine HUD要素を追加（Category D）
	for _, elem in ipairs(ENGINE_HUD_ELEMENTS) do
		table.insert(results, {
			cat = "D",
			systemType = "engine_hud",
			className = elem,
			name = elem,
			visible = true,
			vrStatus = VR_STATUS.ENGINE,
			desc = "C++ engine HUD element (HUDShouldDrawで制御可能)",
		})
	end

	uiscan.systemUI = results
	local elapsed = SysTime() - startTime
	Log.Info("uiscan", string.format("ScanSystemUI: %d items (%.3fs)", #results, elapsed))
	return results
end

-- ========================================
-- Scan 8: VR捕捉ギャップ分析
-- ========================================
function uiscan.AnalyzeFullGap()
	local startTime = SysTime()
	local gapItems = {}

	local counts = {
		total = 0,
		captured = 0,
		not_captured = 0,
		partial = 0,
		engine = 0,
		unknown = 0,
	}

	local function AddItem(item)
		table.insert(gapItems, item)
		counts.total = counts.total + 1
		counts[item.vrStatus] = (counts[item.vrStatus] or 0) + 1
	end

	-- A: レンダリングフック
	if uiscan.renderHooks then
		for _, h in ipairs(uiscan.renderHooks) do
			if h.totalCallbacks > 0 then
				local mechanism = ""
				if h.vrStatus == VR_STATUS.CAPTURED then mechanism = "M1" end
				AddItem({
					cat = "A",
					name = h.name,
					source = #h.callbacks > 0 and h.callbacks[1].source or
						(h.gamemodeMethod and h.gamemodeMethod.source or ""),
					vrStatus = h.vrStatus,
					mechanism = mechanism,
					detail = string.format("Phase %d, %d callbacks", h.phase, h.totalCallbacks),
				})
			end
		end
	end

	-- B: Entity/Weapon
	if uiscan.entities then
		for _, e in ipairs(uiscan.entities) do
			local methodNames = {}
			for _, m in ipairs(e.methods) do
				table.insert(methodNames, m.name)
			end
			local source = #e.methods > 0 and e.methods[1].source or ""
			AddItem({
				cat = "B",
				name = e.class,
				source = source,
				vrStatus = e.vrStatus,
				mechanism = "",
				detail = table.concat(methodNames, ", "),
			})
		end
	end

	-- C: VGUIパネル（重要なもののみ: HUD-like + system + manual_paint）
	if uiscan.panels then
		for _, p in ipairs(uiscan.panels) do
			if p.panelType == "hud_like" or p.panelType == "system" or p.panelType == "manual_paint" then
				local mechanism = ""
				if p.isPaintedManually then mechanism = "M2?" end
				if p.parentType == "dframe" then mechanism = "M3?" end
				AddItem({
					cat = "C",
					name = p.className .. (p.name ~= "" and (" \"" .. p.name .. "\"") or ""),
					source = p.paintSource or "",
					vrStatus = p.vrStatus,
					mechanism = mechanism,
					detail = string.format("type=%s, %dx%d, visible=%s",
						p.panelType, p.w, p.h, tostring(p.visible)),
				})
			end
		end
	end

	-- D: Engine HUD
	if uiscan.systemUI then
		for _, s in ipairs(uiscan.systemUI) do
			if s.cat == "D" then
				AddItem({
					cat = "D",
					name = s.className,
					source = "(C++ engine)",
					vrStatus = VR_STATUS.ENGINE,
					mechanism = "",
					detail = s.desc,
				})
			end
		end
	end

	-- G: Special Systems
	if uiscan.systemUI then
		for _, s in ipairs(uiscan.systemUI) do
			if s.cat == "G" then
				local mechanism = ""
				if s.vrStatus == VR_STATUS.PARTIAL then mechanism = "M3?" end
				AddItem({
					cat = "G",
					name = s.className .. (s.name ~= "" and (" \"" .. s.name .. "\"") or ""),
					source = "",
					vrStatus = s.vrStatus,
					mechanism = mechanism,
					detail = s.desc,
				})
			end
		end
	end

	-- ソート: NOT_CAPTURED優先、次にカテゴリ
	local statusOrder = {
		[VR_STATUS.NOT_CAPTURED] = 1,
		[VR_STATUS.PARTIAL] = 2,
		[VR_STATUS.UNKNOWN] = 3,
		[VR_STATUS.ENGINE] = 4,
		[VR_STATUS.CAPTURED] = 5,
	}
	table.sort(gapItems, function(a, b)
		local sa = statusOrder[a.vrStatus] or 3
		local sb = statusOrder[b.vrStatus] or 3
		if sa ~= sb then return sa < sb end
		if a.cat ~= b.cat then return a.cat < b.cat end
		return a.name < b.name
	end)

	uiscan.gapAnalysis = {
		items = gapItems,
		counts = counts,
	}

	local elapsed = SysTime() - startTime
	Log.Info("uiscan", string.format(
		"AnalyzeFullGap: %d total (captured=%d, not_captured=%d, partial=%d, engine=%d) (%.3fs)",
		counts.total, counts.captured, counts.not_captured, counts.partial, counts.engine, elapsed))
	return uiscan.gapAnalysis
end

-- ========================================
-- JSON Export
-- ========================================
function uiscan.ExportJSON()
	local output = {
		timestamp = os.date("%Y-%m-%dT%H:%M:%S"),
		map = game.GetMap(),
		vrActive = (g_VR and g_VR.active) or false,
	}

	if uiscan.renderHooks then
		output.renderHooks = uiscan.renderHooks
	end
	if uiscan.panels then
		-- パネルデータは大きくなりがちなので要約
		output.panelSummary = {
			total = #uiscan.panels,
		}
		local byType = {}
		for _, p in ipairs(uiscan.panels) do
			byType[p.panelType] = (byType[p.panelType] or 0) + 1
		end
		output.panelSummary.byType = byType

		-- HUD-likeとsystemのパネルのみフル出力
		output.importantPanels = {}
		for _, p in ipairs(uiscan.panels) do
			if p.panelType == "hud_like" or p.panelType == "system" or p.panelType == "manual_paint" then
				table.insert(output.importantPanels, p)
			end
		end
	end
	if uiscan.entities then
		output.entities = uiscan.entities
	end
	if uiscan.staticScan then
		output.staticScan = {
			scope = uiscan.staticScan.scope,
			totalFiles = uiscan.staticScan.totalFiles,
			matchedFiles = uiscan.staticScan.matchedFiles,
			patternSummary = uiscan.staticScan.patternSummary,
			-- results は大きいのでtop30のみ
			topFiles = {},
		}
		for i = 1, math.min(30, #uiscan.staticScan.results) do
			table.insert(output.staticScan.topFiles, uiscan.staticScan.results[i])
		end
	end
	if uiscan.paintActivity then
		output.paintActivity = uiscan.paintActivity
	end
	if uiscan.renderTargets then
		output.renderTargets = uiscan.renderTargets
	end
	if uiscan.systemUI then
		output.systemUI = uiscan.systemUI
	end
	if uiscan.gapAnalysis then
		output.gapAnalysis = uiscan.gapAnalysis
	end

	local jsonStr = util.TableToJSON(output, true)
	if not jsonStr then
		Log.Error("uiscan", "Failed to serialize to JSON")
		return nil
	end

	if not file.IsDir("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end

	local fileName = "vrmod/vrmod_uiscan_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
	file.Write(fileName, jsonStr)

	local filePath = "garrysmod/data/" .. fileName
	Log.Info("uiscan", "Exported to: " .. filePath)
	return filePath
end

-- ========================================
-- 全スキャン実行
-- ========================================
function uiscan.RunAllScans(scope)
	Log.Info("uiscan", "Running all scans...")
	uiscan.ScanRenderHooks()
	uiscan.ScanAllPanels()
	uiscan.ScanEntityRendering()
	uiscan.RunStaticScan(scope or "all")
	uiscan.ScanSystemUI()
	uiscan.AnalyzeFullGap()
	Log.Info("uiscan", "All scans complete")
end

-- ========================================
-- UI: Render Scanner タブ
-- ========================================
function uiscan.CreateScannerTab(parent)
	local container = vgui.Create("DPanel", parent)
	container.Paint = function() end

	-- ========== コントロールバー ==========
	local controlBar = vgui.Create("DPanel", container)
	controlBar:Dock(TOP)
	controlBar:SetTall(34)
	controlBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.headerBg)
	end

	local buttons = {}
	local btnX = 5

	local function AddBtn(label, color, width, onClick)
		local btn = vgui.Create("DButton", controlBar)
		btn:SetText("")
		btn:SetSize(width, 24)
		btn:SetPos(btnX, 5)
		btn.Paint = function(self, w, h)
			draw.RoundedBox(3, 0, 0, w, h, color)
			draw.SimpleText(label, "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = onClick
		btnX = btnX + width + 5
		table.insert(buttons, btn)
		return btn
	end

	-- ステータスラベル
	local statusLabel = vgui.Create("DLabel", controlBar)
	statusLabel:SetFont("VRDebugUISmall")
	statusLabel:SetTextColor(COLORS.gray)
	statusLabel:SetText("Not scanned")

	-- ========== メイン分割: ツリー + リスト + 詳細 ==========
	local mainSplit = vgui.Create("DHorizontalDivider", container)
	mainSplit:Dock(FILL)
	mainSplit:DockMargin(0, 2, 0, 0)
	mainSplit:SetDividerWidth(4)
	mainSplit:SetLeftWidth(250)
	mainSplit:SetLeftMin(150)
	mainSplit:SetRightMin(300)

	-- 左: DTree
	local tree = vgui.Create("DTree")
	tree.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	-- 右: リスト + 詳細
	local rightPanel = vgui.Create("DPanel")
	rightPanel.Paint = function() end

	local vertSplit = vgui.Create("DVerticalDivider", rightPanel)
	vertSplit:Dock(FILL)
	vertSplit:SetDividerHeight(4)
	vertSplit:SetTopHeight(400)
	vertSplit:SetTopMin(150)
	vertSplit:SetBottomMin(80)

	-- リスト
	local list = vgui.Create("DListView")
	list:SetMultiSelect(false)
	list:AddColumn("Name"):SetFixedWidth(200)
	list:AddColumn("Source"):SetFixedWidth(250)
	list:AddColumn("VR Status"):SetFixedWidth(100)
	list:AddColumn("Detail"):SetFixedWidth(300)
	list.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	-- 詳細
	local detailPanel = vgui.Create("DTextEntry")
	detailPanel:SetMultiline(true)
	detailPanel:SetEditable(false)
	detailPanel:SetFont("VRDebugCode")
	detailPanel:SetText("Click 'Scan All' to start comprehensive UI/rendering scan.\n\n7 Categories: A(Hooks) B(Entity) C(VGUI) D(Engine) E(RT) F(3D) G(Special)\n5 VR Mechanisms: M1(RenderHUD) M2(MenuOpen) M3(MakePopup) M4(Custom3D) M5(HandHUD)")

	vertSplit:SetTop(list)
	vertSplit:SetBottom(detailPanel)

	mainSplit:SetLeft(tree)
	mainSplit:SetRight(rightPanel)

	-- ========== ツリー・リスト更新 ==========
	local currentItems = {}

	local function PopulateList(items)
		list:Clear()
		currentItems = items or {}

		for _, item in ipairs(currentItems) do
			local row = list:AddLine(
				item.name or "",
				item.source or "",
				item.vrStatus or "",
				item.detail or ""
			)
			row._data = item

			-- VRステータスで行背景色
			local statusColor = VR_STATUS_BG[item.vrStatus]
			if statusColor then
				local origPaint = row.Paint
				row.Paint = function(self, w, h)
					if self:IsSelected() then
						draw.RoundedBox(0, 0, 0, w, h, COLORS.cyan)
					else
						draw.RoundedBox(0, 0, 0, w, h, statusColor)
					end
				end
			end
		end
	end

	local function RefreshTree()
		tree:Clear()

		-- A: Hooks (Phase別)
		if uiscan.renderHooks then
			local nodeA = tree:AddNode("A: Hook-Based Rendering", "icon16/chart_bar.png")
			local byPhase = {}
			for _, h in ipairs(uiscan.renderHooks) do
				if h.totalCallbacks > 0 then
					byPhase[h.phase] = byPhase[h.phase] or {}
					table.insert(byPhase[h.phase], h)
				end
			end

			local phaseOrder = {7, 6, 8, 3, 4, 5, 0, 1, 2, 9}
			for _, phase in ipairs(phaseOrder) do
				if byPhase[phase] then
					local phaseName = PHASE_NAMES[phase] or "Phase " .. phase
					local phaseNode = nodeA:AddNode(
						string.format("Phase %d: %s (%d)", phase, phaseName, #byPhase[phase]),
						phase == 7 and "icon16/accept.png" or "icon16/bullet_orange.png"
					)
					phaseNode.DoClick = function()
						local items = {}
						for _, h in ipairs(byPhase[phase]) do
							table.insert(items, {
								name = h.name,
								source = #h.callbacks > 0 and h.callbacks[1].source or
									(h.gamemodeMethod and h.gamemodeMethod.source or ""),
								vrStatus = h.vrStatus,
								detail = string.format("%d callbacks. %s", h.totalCallbacks, h.desc),
								_hookData = h,
							})
						end
						PopulateList(items)
					end
				end
			end

			nodeA:SetExpanded(true)
		end

		-- B: Entity/Weapon
		if uiscan.entities and #uiscan.entities > 0 then
			local nodeB = tree:AddNode(string.format("B: Entity/Weapon (%d)", #uiscan.entities), "icon16/brick.png")
			local bySubType = {}
			for _, e in ipairs(uiscan.entities) do
				bySubType[e.subType] = bySubType[e.subType] or {}
				table.insert(bySubType[e.subType], e)
			end

			for subType, items in pairs(bySubType) do
				local subNode = nodeB:AddNode(string.format("%s (%d)", subType, #items), "icon16/plugin.png")
				subNode.DoClick = function()
					local listItems = {}
					for _, e in ipairs(items) do
						local methodNames = {}
						for _, m in ipairs(e.methods) do table.insert(methodNames, m.name) end
						table.insert(listItems, {
							name = e.class,
							source = #e.methods > 0 and e.methods[1].source or "",
							vrStatus = e.vrStatus,
							detail = table.concat(methodNames, ", "),
						})
					end
					PopulateList(listItems)
				end
			end
		end

		-- C: VGUI Panels
		if uiscan.panels and #uiscan.panels > 0 then
			local nodeC = tree:AddNode(string.format("C: VGUI Panels (%d)", #uiscan.panels), "icon16/application.png")
			local byType = {}
			for _, p in ipairs(uiscan.panels) do
				byType[p.panelType] = byType[p.panelType] or {}
				table.insert(byType[p.panelType], p)
			end

			local typeOrder = {"hud_like", "system", "manual_paint", "interactive", "other", "unknown"}
			local typeIcons = {
				hud_like = "icon16/monitor.png",
				system = "icon16/cog.png",
				manual_paint = "icon16/paintcan.png",
				interactive = "icon16/application_form.png",
				other = "icon16/bullet_white.png",
				unknown = "icon16/help.png",
			}
			for _, pt in ipairs(typeOrder) do
				if byType[pt] then
					local subNode = nodeC:AddNode(
						string.format("%s (%d)", pt, #byType[pt]),
						typeIcons[pt] or "icon16/bullet_white.png"
					)
					subNode.DoClick = function()
						local listItems = {}
						for _, p in ipairs(byType[pt]) do
							table.insert(listItems, {
								name = p.className .. (p.name ~= "" and (" \"" .. p.name .. "\"") or ""),
								source = p.paintSource or "",
								vrStatus = p.vrStatus,
								detail = string.format("%dx%d vis=%s paint=%s manual=%s parent=%s",
									p.w, p.h, tostring(p.visible), tostring(p.hasPaint),
									tostring(p.isPaintedManually), p.parentType),
							})
						end
						PopulateList(listItems)
					end
				end
			end
		end

		-- D: Engine
		if uiscan.systemUI then
			local engineItems = {}
			for _, s in ipairs(uiscan.systemUI) do
				if s.cat == "D" then table.insert(engineItems, s) end
			end
			if #engineItems > 0 then
				local nodeD = tree:AddNode(string.format("D: Engine C++ (%d)", #engineItems), "icon16/server.png")
				nodeD.DoClick = function()
					local listItems = {}
					for _, s in ipairs(engineItems) do
						table.insert(listItems, {
							name = s.className,
							source = "(C++ engine)",
							vrStatus = VR_STATUS.ENGINE,
							detail = s.desc,
						})
					end
					PopulateList(listItems)
				end
			end
		end

		-- E: Render Targets
		if uiscan.renderTargets and uiscan.renderTargets.summary then
			local nodeE = tree:AddNode(
				string.format("E: Render Targets (%d)", #uiscan.renderTargets.summary),
				"icon16/picture.png"
			)
			nodeE.DoClick = function()
				local listItems = {}
				for _, rt in ipairs(uiscan.renderTargets.summary) do
					table.insert(listItems, {
						name = rt.name,
						source = "",
						vrStatus = VR_STATUS.UNKNOWN,
						detail = string.format("%d pushes (%.1f/s)", rt.pushCount, rt.perSecond),
					})
				end
				PopulateList(listItems)
			end
		end

		-- G: Special Systems
		if uiscan.systemUI then
			local specialItems = {}
			for _, s in ipairs(uiscan.systemUI) do
				if s.cat == "G" then table.insert(specialItems, s) end
			end
			if #specialItems > 0 then
				local nodeG = tree:AddNode(string.format("G: Special Systems (%d)", #specialItems), "icon16/star.png")
				local bySystemType = {}
				for _, s in ipairs(specialItems) do
					bySystemType[s.systemType] = bySystemType[s.systemType] or {}
					table.insert(bySystemType[s.systemType], s)
				end
				for sysType, items in pairs(bySystemType) do
					local subNode = nodeG:AddNode(string.format("%s (%d)", sysType, #items), "icon16/bullet_star.png")
					subNode.DoClick = function()
						local listItems = {}
						for _, s in ipairs(items) do
							table.insert(listItems, {
								name = s.className .. (s.name ~= "" and (" \"" .. s.name .. "\"") or ""),
								source = "",
								vrStatus = s.vrStatus,
								detail = s.desc,
							})
						end
						PopulateList(listItems)
					end
				end
			end
		end

		-- Static Scan Results
		if uiscan.staticScan then
			local nodeS = tree:AddNode(
				string.format("Static Scan (%d files)", uiscan.staticScan.matchedFiles),
				"icon16/magnifier.png"
			)

			-- By source (addon)
			local bySrc = {}
			for _, r in ipairs(uiscan.staticScan.results) do
				bySrc[r.source] = bySrc[r.source] or {}
				table.insert(bySrc[r.source], r)
			end
			local srcNames = {}
			for name, _ in pairs(bySrc) do table.insert(srcNames, name) end
			table.sort(srcNames)

			for _, srcName in ipairs(srcNames) do
				local srcFiles = bySrc[srcName]
				local srcNode = nodeS:AddNode(
					string.format("%s (%d files)", srcName, #srcFiles),
					"icon16/folder.png"
				)
				srcNode.DoClick = function()
					local listItems = {}
					for _, r in ipairs(srcFiles) do
						-- マッチの最初のパターンを表示
						local patterns = {}
						local seen = {}
						for _, m in ipairs(r.matches) do
							if not seen[m.pattern] then
								table.insert(patterns, m.pattern)
								seen[m.pattern] = true
							end
						end
						table.insert(listItems, {
							name = r.filePath,
							source = r.source,
							vrStatus = VR_STATUS.UNKNOWN,
							detail = string.format("%d matches: %s", r.matchCount, table.concat(patterns, ", ")),
							_staticData = r,
						})
					end
					PopulateList(listItems)
				end
			end
		end
	end

	-- 行選択で詳細表示
	list.OnRowSelected = function(self, idx, row)
		local data = row._data
		if not data then return end

		local lines = {}
		table.insert(lines, "Name: " .. (data.name or ""))
		table.insert(lines, "Source: " .. (data.source or ""))
		table.insert(lines, "VR Status: " .. (data.vrStatus or ""))
		if data.mechanism and data.mechanism ~= "" then
			table.insert(lines, "Mechanism: " .. data.mechanism)
		end
		table.insert(lines, "Detail: " .. (data.detail or ""))
		table.insert(lines, "")

		-- フックデータの場合はコールバック一覧
		if data._hookData then
			local h = data._hookData
			table.insert(lines, "--- Callbacks ---")
			for _, cb in ipairs(h.callbacks) do
				table.insert(lines, string.format("  [%s] %s:%d-%d", cb.name, cb.source, cb.line, cb.lastline))
			end
			if h.gamemodeMethod then
				table.insert(lines, string.format("  [GAMEMODE] %s:%d", h.gamemodeMethod.source, h.gamemodeMethod.line))
			end
		end

		-- 静的スキャンデータの場合はマッチ一覧
		if data._staticData then
			local r = data._staticData
			table.insert(lines, "--- Matches ---")
			for _, m in ipairs(r.matches) do
				table.insert(lines, string.format("  L%d [%s] %s: %s", m.line, m.cat, m.pattern, m.context))
			end
		end

		-- ソースコード読み取り（source + line がある場合）
		if data.source and data.source ~= "" and data.source ~= "(C++ engine)" then
			local lineNum = 0
			if data._hookData and #data._hookData.callbacks > 0 then
				lineNum = data._hookData.callbacks[1].line
			end
			if lineNum > 0 then
				local content = file.Read(data.source, "GAME")
				if content then
					table.insert(lines, "")
					table.insert(lines, "--- Source Code ---")
					local allLines = {}
					for l in string.gmatch(content .. "\n", "([^\r\n]*)\r?\n") do
						table.insert(allLines, l)
					end
					local startL = math.max(1, lineNum - 3)
					local endL = math.min(#allLines, lineNum + 10)
					for i = startL, endL do
						local prefix = (i == lineNum) and ">>>" or "   "
						table.insert(lines, string.format("%s %4d: %s", prefix, i, allLines[i] or ""))
					end
				end
			end
		end

		detailPanel:SetText(table.concat(lines, "\n"))
	end

	-- ========== ボタン定義 ==========
	AddBtn("Scan All", COLORS.green, 80, function()
		statusLabel:SetText("Scanning... (may freeze)")
		statusLabel:SizeToContents()
		timer.Simple(0, function()
			uiscan.RunAllScans("all")
			RefreshTree()
			statusLabel:SetText(string.format("A:%d B:%d C:%d D:%d G:%d | Static:%d files",
				uiscan.renderHooks and #table.filter(uiscan.renderHooks, function(_, h) return h.totalCallbacks > 0 end) or 0,
				uiscan.entities and #uiscan.entities or 0,
				uiscan.panels and #uiscan.panels or 0,
				#ENGINE_HUD_ELEMENTS,
				uiscan.systemUI and #table.filter(uiscan.systemUI, function(_, s) return s.cat == "G" end) or 0,
				uiscan.staticScan and uiscan.staticScan.matchedFiles or 0
			))
			statusLabel:SizeToContents()
		end)
	end)

	AddBtn("Hooks", COLORS.cyan, 55, function()
		timer.Simple(0, function()
			uiscan.ScanRenderHooks()
			RefreshTree()
		end)
	end)

	AddBtn("Panels", COLORS.cyan, 55, function()
		timer.Simple(0, function()
			uiscan.ScanAllPanels()
			RefreshTree()
		end)
	end)

	AddBtn("Entities", COLORS.cyan, 65, function()
		timer.Simple(0, function()
			uiscan.ScanEntityRendering()
			RefreshTree()
		end)
	end)

	AddBtn("Static", COLORS.cyan, 55, function()
		statusLabel:SetText("Static scanning...")
		statusLabel:SizeToContents()
		timer.Simple(0, function()
			uiscan.RunStaticScan("all")
			RefreshTree()
			statusLabel:SetText(string.format("Static: %d/%d files", uiscan.staticScan.matchedFiles, uiscan.staticScan.totalFiles))
			statusLabel:SizeToContents()
		end)
	end)

	AddBtn("Paint", COLORS.orange, 50, function()
		uiscan.MeasurePaintActivity(2)
	end)

	AddBtn("RT", COLORS.orange, 35, function()
		uiscan.MonitorRenderTargets(5)
	end)

	AddBtn("Export", COLORS.yellow, 55, function()
		local path = uiscan.ExportJSON()
		if path then
			statusLabel:SetText("Exported: " .. path)
			statusLabel:SizeToContents()
		end
	end)

	-- ステータスラベル位置更新
	statusLabel:SetPos(btnX + 10, 10)
	statusLabel:SizeToContents()

	-- 既存データがあればツリー表示
	if uiscan.renderHooks or uiscan.panels then
		RefreshTree()
	end

	return container
end

-- ========================================
-- UI: VR Gap Analysis タブ
-- ========================================
function uiscan.CreateGapTab(parent)
	local container = vgui.Create("DPanel", parent)
	container.Paint = function() end

	-- サマリーバー
	local summaryBar = vgui.Create("DPanel", container)
	summaryBar:Dock(TOP)
	summaryBar:SetTall(50)
	summaryBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.headerBg)

		if uiscan.gapAnalysis then
			local c = uiscan.gapAnalysis.counts
			draw.SimpleText(
				string.format("Total: %d elements", c.total),
				"VRDebugUI", 10, 8, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
			)
			draw.SimpleText(
				string.format("CAPTURED: %d | NOT CAPTURED: %d | PARTIAL: %d | ENGINE: %d",
					c.captured, c.not_captured, c.partial, c.engine),
				"VRDebugUISmall", 10, 28, COLORS.gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
			)
		else
			draw.SimpleText("Run 'Scan All' in Render Scanner tab first, then 'Run Analysis' here",
				"VRDebugUI", 10, 15, COLORS.gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	-- コントロールバー
	local ctrlBar = vgui.Create("DPanel", container)
	ctrlBar:Dock(TOP)
	ctrlBar:SetTall(34)
	ctrlBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.bgLight)
	end

	local btnAnalyze = vgui.Create("DButton", ctrlBar)
	btnAnalyze:SetText("")
	btnAnalyze:SetSize(120, 24)
	btnAnalyze:SetPos(5, 5)
	btnAnalyze.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.green)
		draw.SimpleText("Run Analysis", "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local btnExportGap = vgui.Create("DButton", ctrlBar)
	btnExportGap:SetText("")
	btnExportGap:SetSize(120, 24)
	btnExportGap:SetPos(130, 5)
	btnExportGap.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, COLORS.yellow)
		draw.SimpleText("Export Report", "VRDebugUISmall", w / 2, h / 2, COLORS.bg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btnExportGap.DoClick = function()
		uiscan.ExportJSON()
	end

	-- 凡例
	local legendBar = vgui.Create("DPanel", container)
	legendBar:Dock(BOTTOM)
	legendBar:SetTall(24)
	legendBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COLORS.bg)
		local x = 10
		local legends = {
			{ color = COLORS.green, label = "CAPTURED" },
			{ color = COLORS.red, label = "NOT CAPTURED" },
			{ color = COLORS.yellow, label = "PARTIAL" },
			{ color = COLORS.gray, label = "ENGINE (N/A)" },
		}
		for _, leg in ipairs(legends) do
			draw.RoundedBox(2, x, 6, 12, 12, leg.color)
			x = x + 16
			draw.SimpleText(leg.label, "VRDebugUISmall", x, 6, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			x = x + surface.GetTextSize(leg.label) + 20
		end
	end

	-- メインリスト
	local gapList = vgui.Create("DListView", container)
	gapList:Dock(FILL)
	gapList:DockMargin(0, 2, 0, 2)
	gapList:SetMultiSelect(false)
	gapList:AddColumn("Cat"):SetFixedWidth(50)
	gapList:AddColumn("Name"):SetFixedWidth(200)
	gapList:AddColumn("Source"):SetFixedWidth(250)
	gapList:AddColumn("VR Status"):SetFixedWidth(110)
	gapList:AddColumn("Mechanism"):SetFixedWidth(60)
	gapList:AddColumn("Detail"):SetFixedWidth(350)
	gapList.Paint = function(self, w, h)
		draw.RoundedBox(2, 0, 0, w, h, COLORS.bgCode)
	end

	local function RefreshGapList()
		gapList:Clear()
		if not uiscan.gapAnalysis then return end

		for _, item in ipairs(uiscan.gapAnalysis.items) do
			local row = gapList:AddLine(
				item.cat,
				item.name,
				item.source,
				item.vrStatus,
				item.mechanism or "",
				item.detail or ""
			)

			-- 行背景色
			local bgColor = VR_STATUS_BG[item.vrStatus]
			if bgColor then
				row.Paint = function(self, w, h)
					if self:IsSelected() then
						draw.RoundedBox(0, 0, 0, w, h, COLORS.cyan)
					else
						draw.RoundedBox(0, 0, 0, w, h, bgColor)
					end
				end
			end
		end
	end

	btnAnalyze.DoClick = function()
		timer.Simple(0, function()
			-- まだスキャンされてなければ先に実行
			if not uiscan.renderHooks then uiscan.ScanRenderHooks() end
			if not uiscan.panels then uiscan.ScanAllPanels() end
			if not uiscan.entities then uiscan.ScanEntityRendering() end
			if not uiscan.systemUI then uiscan.ScanSystemUI() end

			uiscan.AnalyzeFullGap()
			RefreshGapList()
		end)
	end

	-- 既存データがあればリスト表示
	if uiscan.gapAnalysis then
		RefreshGapList()
	end

	return container
end

-- ========================================
-- table.filter ユーティリティ（GLuaにはない）
-- ========================================
if not table.filter then
	function table.filter(tbl, func)
		local out = {}
		for k, v in pairs(tbl) do
			if func(k, v) then
				table.insert(out, v)
			end
		end
		return out
	end
end

-- ========================================
-- コンソールコマンド
-- ========================================
concommand.Add("vrmod_unoff_debug_uiscan_all", function(_, _, args)
	local scope = args[1] or "all"
	print("[UISCAN] Running all scans (scope: " .. scope .. ")...")
	uiscan.RunAllScans(scope)
	print("[UISCAN] All scans complete")
end)

concommand.Add("vrmod_unoff_debug_uiscan_hooks", function()
	print("[UISCAN] Scanning render hooks...")
	local results = uiscan.ScanRenderHooks()
	for _, h in ipairs(results) do
		if h.totalCallbacks > 0 then
			local status = h.vrStatus == VR_STATUS.CAPTURED and "[CAPT]" or
				h.vrStatus == VR_STATUS.NOT_CAPTURED and "[MISS]" or "[PART]"
			MsgC(VR_STATUS_COLORS[h.vrStatus], string.format("  %s Phase %d %-30s %d callbacks\n",
				status, h.phase, h.name, h.totalCallbacks))
		end
	end
end)

concommand.Add("vrmod_unoff_debug_uiscan_panels", function()
	print("[UISCAN] Scanning all VGUI panels...")
	local results = uiscan.ScanAllPanels()
	local byType = {}
	for _, p in ipairs(results) do
		byType[p.panelType] = (byType[p.panelType] or 0) + 1
	end
	for t, c in pairs(byType) do
		print(string.format("  %s: %d", t, c))
	end
end)

concommand.Add("vrmod_unoff_debug_uiscan_entities", function()
	print("[UISCAN] Scanning entity/weapon rendering...")
	local results = uiscan.ScanEntityRendering()
	for _, e in ipairs(results) do
		local methods = {}
		for _, m in ipairs(e.methods) do table.insert(methods, m.name) end
		print(string.format("  [%s] %s: %s", e.subType, e.class, table.concat(methods, ", ")))
	end
end)

concommand.Add("vrmod_unoff_debug_uiscan_static", function(_, _, args)
	local scope = args[1] or "all"
	print("[UISCAN] Static scan (scope: " .. scope .. ")...")
	local results = uiscan.RunStaticScan(scope)
	print(string.format("[UISCAN] %d/%d files matched", results.matchedFiles, results.totalFiles))
	for desc, summary in pairs(results.patternSummary) do
		if summary.count > 0 then
			print(string.format("  [%s] %s: %d matches in %d files", summary.cat, desc, summary.count, #summary.files))
		end
	end
end)

concommand.Add("vrmod_unoff_debug_uiscan_systemui", function()
	print("[UISCAN] Scanning system UI...")
	local results = uiscan.ScanSystemUI()
	for _, s in ipairs(results) do
		local statusStr = s.vrStatus == VR_STATUS.ENGINE and "[ENGINE]" or
			s.vrStatus == VR_STATUS.NOT_CAPTURED and "[MISS]" or "[PART]"
		print(string.format("  %s [%s] %s: %s", statusStr, s.cat, s.className, s.desc))
	end
end)

concommand.Add("vrmod_unoff_debug_uiscan_paint", function(_, _, args)
	local dur = tonumber(args[1]) or 2
	print("[UISCAN] Measuring Paint activity for " .. dur .. "s...")
	uiscan.MeasurePaintActivity(dur)
end)

concommand.Add("vrmod_unoff_debug_uiscan_rt", function(_, _, args)
	local dur = tonumber(args[1]) or 5
	print("[UISCAN] Monitoring render targets for " .. dur .. "s...")
	uiscan.MonitorRenderTargets(dur)
end)

concommand.Add("vrmod_unoff_debug_uiscan_gap", function()
	print("[UISCAN] Running gap analysis...")
	uiscan.AnalyzeFullGap()
	if uiscan.gapAnalysis then
		local c = uiscan.gapAnalysis.counts
		print(string.format("[UISCAN] Total: %d | Captured: %d | Not Captured: %d | Partial: %d | Engine: %d",
			c.total, c.captured, c.not_captured, c.partial, c.engine))
		print("[UISCAN] NOT CAPTURED items:")
		for _, item in ipairs(uiscan.gapAnalysis.items) do
			if item.vrStatus == VR_STATUS.NOT_CAPTURED then
				MsgC(COLORS.red, string.format("  [%s] %s - %s\n", item.cat, item.name, item.detail or ""))
			end
		end
	end
end)

concommand.Add("vrmod_unoff_debug_uiscan_export", function()
	print("[UISCAN] Exporting...")
	local path = uiscan.ExportJSON()
	if path then
		print("[UISCAN] Exported to: " .. path)
	else
		print("[UISCAN] Export failed (no data?)")
	end
end)

Log.Info("uiscan", "UI/HUD/VGUI Render Scanner initialized (8 scans, 10 commands)")

--------[vrmod_debug_uiscan.lua]End--------
