-- VRMod Beginner Guide - Core Framework
-- 初心者向けビジュアルガイドGUI
-- Opens via: vrmod_guide

AddCSLuaFile()
if SERVER then return end

vrmod = vrmod or {}
vrmod.guide = vrmod.guide or {}
vrmod.guide.widgets = vrmod.guide.widgets or {}
vrmod.guide.categories = vrmod.guide.categories or {}
vrmod.guide.categoryOrder = vrmod.guide.categoryOrder or {}
vrmod.guide.panelCache = vrmod.guide.panelCache or {}

-- Language system (separate from VRMOD_LANG)
VRMOD_GUIDE_LANG = VRMOD_GUIDE_LANG or {}
VRMOD_GUIDE_LANG.current = "en"

-- ConVar for language preference
CreateClientConVar("vrmod_guide_lang", "", true, false, "VRMod Guide language (en/ja/ru/zh)")

-- ============================================================
-- Localization helper
-- ============================================================
function vrmod.guide.L(key, fallback)
	local langTable = VRMOD_GUIDE_LANG[VRMOD_GUIDE_LANG.current]
	if langTable and langTable[key] then return langTable[key] end
	if VRMOD_GUIDE_LANG.current ~= "en" and VRMOD_GUIDE_LANG.en and VRMOD_GUIDE_LANG.en[key] then
		return VRMOD_GUIDE_LANG.en[key]
	end
	return fallback or key
end

-- ============================================================
-- Language auto-detection
-- ============================================================
local function DetectGuideLang()
	local saved = GetConVar("vrmod_guide_lang")
	if saved then
		local s = saved:GetString()
		if s and s ~= "" and VRMOD_GUIDE_LANG[s] then return s end
	end
	local gl = GetConVarString("gmod_language") or ""
	if gl == "ja" or gl == "japanese" then return "ja" end
	if gl == "ru" or gl == "russian" then return "ru" end
	if gl == "zh-CN" or gl == "schinese" then return "zh" end
	return "en"
end

-- ============================================================
-- Color palette
-- ============================================================
local COLORS = {
	bg_dark      = Color(30, 30, 35, 255),
	bg_sidebar   = Color(38, 38, 45, 255),
	bg_content   = Color(45, 45, 52, 255),
	bg_topbar    = Color(35, 35, 42, 255),
	bg_hover     = Color(60, 60, 72, 255),
	bg_active    = Color(70, 130, 220, 255),
	bg_active_hover = Color(80, 140, 230, 255),
	bg_server    = Color(60, 45, 30, 255),
	text_primary = Color(230, 230, 235, 255),
	text_secondary = Color(160, 160, 170, 255),
	text_active  = Color(255, 255, 255, 255),
	accent       = Color(70, 130, 220, 255),
	border       = Color(55, 55, 65, 255),
	reset_btn    = Color(180, 80, 80, 255),
	section_bg   = Color(50, 50, 60, 255),
}
vrmod.guide.COLORS = COLORS

-- ============================================================
-- Fonts
-- ============================================================
surface.CreateFont("VRGuide_Title", {
	font = "Roboto", size = 20, weight = 700, antialias = true,
})
surface.CreateFont("VRGuide_Category", {
	font = "Roboto", size = 15, weight = 500, antialias = true,
})
surface.CreateFont("VRGuide_CategorySmall", {
	font = "Roboto", size = 13, weight = 400, antialias = true,
})
surface.CreateFont("VRGuide_Body", {
	font = "Roboto", size = 14, weight = 400, antialias = true,
})
surface.CreateFont("VRGuide_BodyBold", {
	font = "Roboto", size = 14, weight = 700, antialias = true,
})
surface.CreateFont("VRGuide_Small", {
	font = "Roboto", size = 12, weight = 400, antialias = true,
})
surface.CreateFont("VRGuide_Section", {
	font = "Roboto", size = 16, weight = 700, antialias = true,
})
surface.CreateFont("VRGuide_Welcome", {
	font = "Roboto", size = 24, weight = 700, antialias = true,
})
surface.CreateFont("VRGuide_WelcomeBody", {
	font = "Roboto", size = 15, weight = 400, antialias = true,
})

-- ============================================================
-- State
-- ============================================================
local guideFrame = nil
local activeCategory = nil
local sidebarButtons = {}
local contentContainer = nil
local searchActive = false
local searchPanel = nil

-- ============================================================
-- Show a category page
-- ============================================================
function vrmod.guide.ShowCategory(catKey)
	if not contentContainer or not IsValid(contentContainer) then return end

	-- Hide search results if active
	if searchActive and IsValid(searchPanel) then
		searchPanel:SetVisible(false)
	end
	searchActive = false

	-- Hide all cached panels
	for k, panel in pairs(vrmod.guide.panelCache) do
		if IsValid(panel) then panel:SetVisible(false) end
	end

	-- Build or show cached panel
	if not vrmod.guide.panelCache[catKey] or not IsValid(vrmod.guide.panelCache[catKey]) then
		local panel = vrmod.guide.BuildCategoryPanel(contentContainer, catKey)
		if panel then
			vrmod.guide.panelCache[catKey] = panel
		end
	else
		vrmod.guide.panelCache[catKey]:SetVisible(true)
	end

	-- Update sidebar highlight
	activeCategory = catKey
	for k, btn in pairs(sidebarButtons) do
		if IsValid(btn) then btn:SetActive(k == catKey) end
	end
end

-- ============================================================
-- Build the Getting Started page
-- ============================================================
function vrmod.guide.BuildGettingStartedPanel(parent)
	local L = vrmod.guide.L
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)

	local inner = vgui.Create("DPanel", scroll)
	inner:Dock(TOP)
	inner:DockMargin(20, 20, 20, 20)
	inner:SetTall(800)
	inner.Paint = function() end

	-- Welcome title
	local title = vgui.Create("DLabel", inner)
	title:SetFont("VRGuide_Welcome")
	title:SetText(L("welcome_title", "Welcome to VRMod!"))
	title:SetTextColor(COLORS.text_primary)
	title:Dock(TOP)
	title:DockMargin(0, 0, 0, 10)
	title:SetAutoStretchVertical(true)

	-- Welcome description
	local desc = vgui.Create("DLabel", inner)
	desc:SetFont("VRGuide_WelcomeBody")
	desc:SetText(L("welcome_desc", "This guide helps you configure all VRMod settings with easy-to-understand descriptions.\nSelect a category from the left sidebar to get started.\n\nAll changes take effect immediately - no need to press Apply!"))
	desc:SetTextColor(COLORS.text_secondary)
	desc:Dock(TOP)
	desc:DockMargin(0, 0, 0, 20)
	desc:SetWrap(true)
	desc:SetAutoStretchVertical(true)

	-- Quick start tips
	local tipsHeader = vgui.Create("DLabel", inner)
	tipsHeader:SetFont("VRGuide_Section")
	tipsHeader:SetText(L("quickstart_title", "Quick Start"))
	tipsHeader:SetTextColor(COLORS.accent)
	tipsHeader:Dock(TOP)
	tipsHeader:DockMargin(0, 10, 0, 8)
	tipsHeader:SetAutoStretchVertical(true)

	local tips = {
		{icon = "icon16/user.png", key = "tip_body", fallback = "1. Go to 'Body & Scale' to match your VR body to your real height"},
		{icon = "icon16/controller.png", key = "tip_gameplay", fallback = "2. Check 'Gameplay' for basic controls like teleport and jump"},
		{icon = "icon16/monitor.png", key = "tip_hud", fallback = "3. Adjust 'HUD & UI' to position the interface comfortably"},
		{icon = "icon16/arrow_undo.png", key = "tip_reset", fallback = "4. Each setting has a reset button to restore defaults"},
		{icon = "icon16/magnifier.png", key = "tip_search", fallback = "5. Use the search bar at the top to find any setting quickly"},
	}

	for _, tip in ipairs(tips) do
		local row = vgui.Create("DPanel", inner)
		row:Dock(TOP)
		row:DockMargin(0, 2, 0, 2)
		row:SetTall(28)
		row.Paint = function() end

		local icon = vgui.Create("DImage", row)
		icon:SetImage(tip.icon)
		icon:SetSize(16, 16)
		icon:Dock(LEFT)
		icon:DockMargin(0, 6, 8, 6)

		local lbl = vgui.Create("DLabel", row)
		lbl:SetFont("VRGuide_Body")
		lbl:SetText(L(tip.key, tip.fallback))
		lbl:SetTextColor(COLORS.text_primary)
		lbl:Dock(FILL)
		lbl:SetAutoStretchVertical(true)
	end

	-- VR Status section
	local statusHeader = vgui.Create("DLabel", inner)
	statusHeader:SetFont("VRGuide_Section")
	statusHeader:SetText(L("vr_status_title", "VR Status"))
	statusHeader:SetTextColor(COLORS.accent)
	statusHeader:Dock(TOP)
	statusHeader:DockMargin(0, 20, 0, 8)
	statusHeader:SetAutoStretchVertical(true)

	local statusText = "N/A"
	if g_VR and g_VR.active then
		statusText = L("vr_status_active", "VR is ACTIVE")
	else
		statusText = L("vr_status_inactive", "VR is NOT active. Start VR from the main VRMod menu (console: vrmod)")
	end

	local statusLbl = vgui.Create("DLabel", inner)
	statusLbl:SetFont("VRGuide_Body")
	statusLbl:SetText(statusText)
	statusLbl:SetTextColor(g_VR and g_VR.active and Color(100, 220, 100) or Color(220, 160, 60))
	statusLbl:Dock(TOP)
	statusLbl:DockMargin(0, 0, 0, 10)
	statusLbl:SetAutoStretchVertical(true)

	-- Open main VRMod menu button
	local openMainBtn = vgui.Create("DButton", inner)
	openMainBtn:SetText(L("btn_open_main_menu", "Open Main VRMod Menu"))
	openMainBtn:SetFont("VRGuide_Body")
	openMainBtn:Dock(TOP)
	openMainBtn:DockMargin(0, 5, 300, 5)
	openMainBtn:SetTall(32)
	openMainBtn.DoClick = function()
		RunConsoleCommand("vrmod")
	end

	-- Reset all button
	local resetAllBtn = vgui.Create("DButton", inner)
	resetAllBtn:SetText(L("btn_reset_all", "Reset ALL Settings to Defaults"))
	resetAllBtn:SetFont("VRGuide_Body")
	resetAllBtn:SetTextColor(Color(255, 255, 255))
	resetAllBtn:Dock(TOP)
	resetAllBtn:DockMargin(0, 15, 300, 5)
	resetAllBtn:SetTall(32)
	resetAllBtn.Paint = function(self, w, h)
		local col = self:IsHovered() and Color(200, 80, 80) or COLORS.reset_btn
		draw.RoundedBox(4, 0, 0, w, h, col)
	end
	resetAllBtn.DoClick = function()
		Derma_Query(
			L("confirm_reset_all", "Are you sure you want to reset ALL settings to defaults?"),
			L("confirm_title", "Confirm Reset"),
			L("btn_yes", "Yes"),
			function()
				if VRModResetAll then VRModResetAll() end
			end,
			L("btn_no", "No"),
			function() end
		)
	end

	return scroll
end

-- ============================================================
-- Build category panel (delegates to render.lua)
-- ============================================================
function vrmod.guide.BuildCategoryPanel(parent, catKey)
	if catKey == "getting_started" then
		return vrmod.guide.BuildGettingStartedPanel(parent)
	end

	-- Delegate to render system
	if vrmod.guide.RenderCategory then
		return vrmod.guide.RenderCategory(parent, catKey)
	end

	-- Fallback if render.lua not loaded yet
	local lbl = vgui.Create("DLabel", parent)
	lbl:SetText("Category: " .. catKey .. " (render system not loaded)")
	lbl:SetFont("VRGuide_Body")
	lbl:SetTextColor(COLORS.text_primary)
	lbl:Dock(FILL)
	return lbl
end

-- ============================================================
-- Search functionality
-- ============================================================
function vrmod.guide.DoSearch(query)
	if not contentContainer or not IsValid(contentContainer) then return end

	query = string.Trim(query or "")
	if query == "" then
		-- Clear search, show active category
		if searchActive and IsValid(searchPanel) then
			searchPanel:SetVisible(false)
		end
		searchActive = false
		if activeCategory then
			vrmod.guide.ShowCategory(activeCategory)
		end
		return
	end

	-- Hide all category panels
	for k, panel in pairs(vrmod.guide.panelCache) do
		if IsValid(panel) then panel:SetVisible(false) end
	end

	-- Build or reuse search results panel
	if IsValid(searchPanel) then searchPanel:Remove() end
	searchPanel = vrmod.guide.BuildSearchResults(contentContainer, query)
	searchActive = true
end

function vrmod.guide.BuildSearchResults(parent, query)
	local L = vrmod.guide.L
	local lowerQuery = string.lower(query)

	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)

	local header = vgui.Create("DLabel", scroll)
	header:SetFont("VRGuide_Section")
	header:SetText(L("search_results", "Search Results") .. ": \"" .. query .. "\"")
	header:SetTextColor(COLORS.accent)
	header:Dock(TOP)
	header:DockMargin(10, 10, 10, 10)
	header:SetAutoStretchVertical(true)

	local resultCount = 0

	-- Search through all categories
	for _, catKey in ipairs(vrmod.guide.categoryOrder) do
		local catDef = vrmod.guide.categories[catKey]
		if catDef and catDef.items then
			for _, item in ipairs(catDef.items) do
				if item.type ~= "section" then
					local searchText = string.lower(
						(item.cvar or item.command or "") .. " " ..
						L(item.lang_key or "", "") .. " " ..
						L(item.tip_key or "", "")
					)
					if string.find(searchText, lowerQuery, 1, true) then
						resultCount = resultCount + 1
						-- Category label for context
						if resultCount <= 100 then
							local catLabel = vgui.Create("DLabel", scroll)
							catLabel:SetFont("VRGuide_Small")
							catLabel:SetText("  [" .. L("cat_" .. catKey, catKey) .. "]")
							catLabel:SetTextColor(COLORS.text_secondary)
							catLabel:Dock(TOP)
							catLabel:DockMargin(10, 8, 10, 0)
							catLabel:SetAutoStretchVertical(true)

							-- Create the widget
							if vrmod.guide.widgets.CreateFromItem then
								local widget = vrmod.guide.widgets.CreateFromItem(scroll, item)
								if IsValid(widget) then
									widget:DockMargin(10, 0, 10, 0)
								end
							end
						end
					end
				end
			end
		end
	end

	if resultCount == 0 then
		local noResults = vgui.Create("DLabel", scroll)
		noResults:SetFont("VRGuide_Body")
		noResults:SetText(L("no_results", "No settings found matching your search."))
		noResults:SetTextColor(COLORS.text_secondary)
		noResults:Dock(TOP)
		noResults:DockMargin(10, 10, 10, 10)
		noResults:SetAutoStretchVertical(true)
	elseif resultCount > 100 then
		local tooMany = vgui.Create("DLabel", scroll)
		tooMany:SetFont("VRGuide_Small")
		tooMany:SetText(L("too_many_results", "Showing first 100 results. Please refine your search."))
		tooMany:SetTextColor(COLORS.text_secondary)
		tooMany:Dock(TOP)
		tooMany:DockMargin(10, 5, 10, 5)
		tooMany:SetAutoStretchVertical(true)
	end

	local countLabel = vgui.Create("DLabel", scroll)
	countLabel:SetFont("VRGuide_Small")
	countLabel:SetText(string.format("%d %s", resultCount, L("results_found", "result(s) found")))
	countLabel:SetTextColor(COLORS.text_secondary)
	countLabel:Dock(TOP)
	countLabel:DockMargin(10, 5, 10, 10)
	countLabel:SetAutoStretchVertical(true)

	return scroll
end

-- ============================================================
-- Main Open function
-- ============================================================
function vrmod.guide.Open(forceLang)
	if IsValid(guideFrame) then guideFrame:Remove() end

	-- Language handling:
	-- If forceLang is provided (from dropdown), use it directly
	-- Otherwise, only auto-detect on the very first open
	if forceLang and VRMOD_GUIDE_LANG[forceLang] then
		VRMOD_GUIDE_LANG.current = forceLang
	elseif not vrmod.guide._langInitialized then
		VRMOD_GUIDE_LANG.current = DetectGuideLang()
		vrmod.guide._langInitialized = true
	end

	-- Clear panel cache
	vrmod.guide.panelCache = {}
	sidebarButtons = {}
	searchActive = false
	searchPanel = nil
	activeCategory = nil

	local L = vrmod.guide.L

	-- Main frame
	guideFrame = vgui.Create("DFrame")
	guideFrame:SetSize(900, 720)
	guideFrame:SetTitle("")
	guideFrame:MakePopup()
	guideFrame:Center()
	guideFrame:SetDraggable(true)
	guideFrame:SetSizable(true)
	guideFrame:SetMinWidth(700)
	guideFrame:SetMinHeight(500)
	guideFrame.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLORS.bg_dark)
		-- Title bar
		draw.RoundedBoxEx(6, 0, 0, w, 30, COLORS.bg_topbar, true, true, false, false)
		draw.SimpleText(L("window_title", "VRMod Beginner Guide"), "VRGuide_Title", 10, 5, COLORS.text_primary)
	end

	-- Close button (custom)
	local closeBtn = vgui.Create("DButton", guideFrame)
	closeBtn:SetText("X")
	closeBtn:SetFont("VRGuide_BodyBold")
	closeBtn:SetTextColor(COLORS.text_primary)
	closeBtn:SetPos(900 - 30, 3)
	closeBtn:SetSize(24, 24)
	closeBtn.Paint = function(self, w, h)
		if self:IsHovered() then
			draw.RoundedBox(4, 0, 0, w, h, Color(200, 60, 60))
		end
	end
	closeBtn.DoClick = function() guideFrame:Remove() end
	guideFrame.OnSizeChanged = function(self, w, h)
		closeBtn:SetPos(w - 30, 3)
	end

	-- Top bar (below title): language switcher + search
	local topBar = vgui.Create("DPanel", guideFrame)
	topBar:Dock(TOP)
	topBar:DockMargin(0, 0, 0, 0)
	topBar:SetTall(34)
	topBar.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_topbar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(0, h - 1, w, h - 1)
	end

	-- Language label
	local langLabel = vgui.Create("DLabel", topBar)
	langLabel:SetFont("VRGuide_Small")
	langLabel:SetText(L("lang_label", "Language:"))
	langLabel:SetTextColor(COLORS.text_secondary)
	langLabel:Dock(RIGHT)
	langLabel:DockMargin(8, 0, 4, 0)
	langLabel:SizeToContents()

	-- Language dropdown
	local langCombo = vgui.Create("DComboBox", topBar)
	langCombo:Dock(RIGHT)
	langCombo:SetWide(130)
	langCombo:DockMargin(0, 4, 0, 4)
	langCombo:SetFont("VRGuide_Body")
	langCombo:AddChoice("English", "en")
	langCombo:AddChoice("日本語 (Japanese)", "ja")
	langCombo:AddChoice("Русский (Russian)", "ru")
	langCombo:AddChoice("中文 (Chinese)", "zh")

	-- Select current language
	local langMap = {en = 1, ja = 2, ru = 3, zh = 4}
	langCombo:ChooseOptionID(langMap[VRMOD_GUIDE_LANG.current] or 1)

	langCombo.OnSelect = function(self, index, value, data)
		if not data or data == "" then return end
		-- Save to ConVar for persistence
		RunConsoleCommand("vrmod_guide_lang", data)
		-- Rebuild with the explicitly chosen language (pass directly, don't rely on async ConVar)
		vrmod.guide.Open(data)
	end

	-- Search box
	local searchBox = vgui.Create("DTextEntry", topBar)
	searchBox:Dock(FILL)
	searchBox:DockMargin(8, 4, 8, 4)
	searchBox:SetFont("VRGuide_Body")
	searchBox:SetPlaceholderText(L("search_placeholder", "Search settings... (ConVar name or description)"))
	searchBox:SetUpdateOnType(true)
	searchBox.OnValueChange = function(self, value)
		vrmod.guide.DoSearch(value)
	end

	-- Main body: sidebar + content
	local body = vgui.Create("DPanel", guideFrame)
	body:Dock(FILL)
	body.Paint = function() end

	-- Sidebar
	local sidebar = vgui.Create("DScrollPanel", body)
	sidebar:Dock(LEFT)
	sidebar:SetWide(210)
	sidebar.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_sidebar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(w - 1, 0, w - 1, h)
	end

	-- Content area
	contentContainer = vgui.Create("DPanel", body)
	contentContainer:Dock(FILL)
	contentContainer.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_content)
		surface.DrawRect(0, 0, w, h)
	end

	-- Build sidebar buttons
	local order = vrmod.guide.categoryOrder
	if #order == 0 then
		-- Fallback ordering if categories not loaded yet
		order = {"getting_started"}
	end

	for _, catKey in ipairs(order) do
		local catDef = vrmod.guide.categories[catKey]
		local catName = L("cat_" .. catKey, catKey)
		local catIcon = catDef and catDef.icon or "icon16/page.png"
		local itemCount = catDef and catDef.items and #catDef.items or 0

		local btn = vgui.Create("DButton", sidebar)
		btn:Dock(TOP)
		btn:SetTall(42)
		btn:DockMargin(4, 2, 4, 0)
		btn:SetText("")
		btn.catKey = catKey
		btn.isActive = false

		btn.SetActive = function(self, active)
			self.isActive = active
		end

		btn.Paint = function(self, w, h)
			local bgCol
			if self.isActive then
				bgCol = self:IsHovered() and COLORS.bg_active_hover or COLORS.bg_active
			else
				bgCol = self:IsHovered() and COLORS.bg_hover or Color(0, 0, 0, 0)
			end
			draw.RoundedBox(4, 0, 0, w, h, bgCol)

			-- Icon
			local iconMat = Material(catIcon, "smooth")
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(iconMat)
			surface.DrawTexturedRect(10, (h - 16) / 2, 16, 16)

			-- Category name
			local textCol = self.isActive and COLORS.text_active or COLORS.text_primary
			draw.SimpleText(catName, "VRGuide_Category", 34, h / 2 - 8, textCol)

			-- Item count (small, right side)
			if itemCount > 0 and catKey ~= "getting_started" then
				draw.SimpleText(tostring(itemCount), "VRGuide_Small", w - 10, h / 2 - 6, COLORS.text_secondary, TEXT_ALIGN_RIGHT)
			end
		end

		btn.DoClick = function(self)
			vrmod.guide.ShowCategory(catKey)
		end

		sidebarButtons[catKey] = btn
	end

	-- Bottom status bar
	local statusBar = vgui.Create("DPanel", guideFrame)
	statusBar:Dock(BOTTOM)
	statusBar:SetTall(22)
	statusBar.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_topbar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(0, 0, w, 0)

		local totalCvars = 0
		for _, catDef in pairs(vrmod.guide.categories) do
			if catDef.items then totalCvars = totalCvars + #catDef.items end
		end

		local statusText = string.format("VRMod Beginner Guide | %d %s | %s",
			totalCvars,
			L("status_settings", "settings"),
			L("status_lang_" .. VRMOD_GUIDE_LANG.current, VRMOD_GUIDE_LANG.current))
		draw.SimpleText(statusText, "VRGuide_Small", 8, 4, COLORS.text_secondary)
	end

	-- Show Getting Started by default
	vrmod.guide.ShowCategory("getting_started")
end

-- ============================================================
-- Embedded mode (for Settings02 tab integration)
-- ============================================================
function vrmod.guide.CreateEmbedded(parent)
	if not vrmod.guide._langInitialized then
		VRMOD_GUIDE_LANG.current = DetectGuideLang()
		vrmod.guide._langInitialized = true
	end

	local L = vrmod.guide.L
	local embCache = {}
	local embSidebarBtns = {}
	local embActiveCat = nil
	local embSearchActive = false
	local embSearchPnl = nil
	local embContentArea = nil

	-- Main container
	local main = vgui.Create("DPanel", parent)
	main:Dock(FILL)
	main.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_dark)
		surface.DrawRect(0, 0, w, h)
	end

	-- Top bar: search + language
	local topBar = vgui.Create("DPanel", main)
	topBar:Dock(TOP)
	topBar:SetTall(34)
	topBar.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_topbar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(0, h - 1, w, h - 1)
	end

	-- Language label + dropdown (right side)
	local langLabel = vgui.Create("DLabel", topBar)
	langLabel:SetFont("VRGuide_Small")
	langLabel:SetText(L("lang_label", "Language:"))
	langLabel:SetTextColor(COLORS.text_secondary)
	langLabel:Dock(RIGHT)
	langLabel:DockMargin(8, 0, 4, 0)
	langLabel:SizeToContents()

	local langCombo = vgui.Create("DComboBox", topBar)
	langCombo:Dock(RIGHT)
	langCombo:SetWide(130)
	langCombo:DockMargin(0, 4, 0, 4)
	langCombo:SetFont("VRGuide_Body")
	langCombo:AddChoice("English", "en")
	langCombo:AddChoice("日本語 (Japanese)", "ja")
	langCombo:AddChoice("Русский (Russian)", "ru")
	langCombo:AddChoice("中文 (Chinese)", "zh")
	local langMap = {en = 1, ja = 2, ru = 3, zh = 4}
	langCombo:ChooseOptionID(langMap[VRMOD_GUIDE_LANG.current] or 1)
	langCombo.OnSelect = function(self, index, value, data)
		if not data or data == "" then return end
		RunConsoleCommand("vrmod_guide_lang", data)
		VRMOD_GUIDE_LANG.current = data
		main:Remove()
		vrmod.guide.CreateEmbedded(parent)
	end

	-- Search box
	local searchBox = vgui.Create("DTextEntry", topBar)
	searchBox:Dock(FILL)
	searchBox:DockMargin(8, 4, 8, 4)
	searchBox:SetFont("VRGuide_Body")
	searchBox:SetPlaceholderText(L("search_placeholder", "Search settings... (ConVar name or description)"))
	searchBox:SetUpdateOnType(true)

	-- Body: sidebar + content
	local body = vgui.Create("DPanel", main)
	body:Dock(FILL)
	body.Paint = function() end

	-- Sidebar
	local sidebar = vgui.Create("DScrollPanel", body)
	sidebar:Dock(LEFT)
	sidebar:SetWide(200)
	sidebar.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_sidebar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(w - 1, 0, w - 1, h)
	end

	-- Content area
	embContentArea = vgui.Create("DPanel", body)
	embContentArea:Dock(FILL)
	embContentArea.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_content)
		surface.DrawRect(0, 0, w, h)
	end

	-- Local show category
	local function showCat(catKey)
		if not embContentArea or not IsValid(embContentArea) then return end
		if embSearchActive and IsValid(embSearchPnl) then
			embSearchPnl:SetVisible(false)
		end
		embSearchActive = false
		for k, p in pairs(embCache) do
			if IsValid(p) then p:SetVisible(false) end
		end
		if not embCache[catKey] or not IsValid(embCache[catKey]) then
			local panel = vrmod.guide.BuildCategoryPanel(embContentArea, catKey)
			if panel then embCache[catKey] = panel end
		else
			embCache[catKey]:SetVisible(true)
		end
		embActiveCat = catKey
		for k, btn in pairs(embSidebarBtns) do
			if IsValid(btn) then btn:SetActive(k == catKey) end
		end
	end

	-- Local search
	local function doSearch(query)
		if not embContentArea or not IsValid(embContentArea) then return end
		query = string.Trim(query or "")
		if query == "" then
			if embSearchActive and IsValid(embSearchPnl) then
				embSearchPnl:SetVisible(false)
			end
			embSearchActive = false
			if embActiveCat then showCat(embActiveCat) end
			return
		end
		for k, p in pairs(embCache) do
			if IsValid(p) then p:SetVisible(false) end
		end
		if IsValid(embSearchPnl) then embSearchPnl:Remove() end
		embSearchPnl = vrmod.guide.BuildSearchResults(embContentArea, query)
		embSearchActive = true
	end

	searchBox.OnValueChange = function(self, value)
		doSearch(value)
	end

	-- Build sidebar buttons
	local order = vrmod.guide.categoryOrder
	if #order == 0 then order = {"getting_started"} end

	for _, catKey in ipairs(order) do
		local catDef = vrmod.guide.categories[catKey]
		local catName = L("cat_" .. catKey, catKey)
		local catIcon = catDef and catDef.icon or "icon16/page.png"
		local itemCount = catDef and catDef.items and #catDef.items or 0

		local btn = vgui.Create("DButton", sidebar)
		btn:Dock(TOP)
		btn:SetTall(36)
		btn:DockMargin(3, 1, 3, 0)
		btn:SetText("")
		btn.isActive = false
		btn.SetActive = function(self, active) self.isActive = active end
		btn.Paint = function(self, w, h)
			local bgCol
			if self.isActive then
				bgCol = self:IsHovered() and COLORS.bg_active_hover or COLORS.bg_active
			else
				bgCol = self:IsHovered() and COLORS.bg_hover or Color(0, 0, 0, 0)
			end
			draw.RoundedBox(4, 0, 0, w, h, bgCol)
			local iconMat = Material(catIcon, "smooth")
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(iconMat)
			surface.DrawTexturedRect(8, (h - 16) / 2, 16, 16)
			local textCol = self.isActive and COLORS.text_active or COLORS.text_primary
			draw.SimpleText(catName, "VRGuide_Category", 30, h / 2 - 8, textCol)
			if itemCount > 0 and catKey ~= "getting_started" then
				draw.SimpleText(tostring(itemCount), "VRGuide_Small", w - 8, h / 2 - 6, COLORS.text_secondary, TEXT_ALIGN_RIGHT)
			end
		end
		btn.DoClick = function() showCat(catKey) end
		embSidebarBtns[catKey] = btn
	end

	-- Show Getting Started by default
	showCat("getting_started")

	return main
end

-- ============================================================
-- ConCommand
-- ============================================================
concommand.Add("vrmod_guide", function()
	vrmod.guide.Open()
end)

-- Guide tab in VRMod Menu - DISABLED (Guide UI is now in spawn menu VRMod tab)
-- hook.Add("VRMod_Menu", "VRModGuide_MenuButton", function(frame) ... end)

print("[VRMod] Beginner Guide core loaded")
