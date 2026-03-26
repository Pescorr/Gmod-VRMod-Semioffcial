-- VRMod Feature Guide - Core Framework
-- 機能組合せガイド + トラブルシューター
-- Opens via: vrmod_fguide
-- Namespace: vrmod.fguide (separate from vrmod.guide / GUIDEv1)

AddCSLuaFile()
if SERVER then return end

vrmod = vrmod or {}
vrmod.fguide = vrmod.fguide or {}
vrmod.fguide.panelCache = vrmod.fguide.panelCache or {}

-- Language system (separate from VRMOD_LANG and VRMOD_GUIDE_LANG)
VRMOD_FGUIDE_LANG = VRMOD_FGUIDE_LANG or {}
VRMOD_FGUIDE_LANG.current = "en"

-- ConVar for language preference
CreateClientConVar("vrmod_fguide_lang", "", true, false, "VRMod Feature Guide language (en/ja/ru/zh)")

-- ============================================================
-- Localization helper
-- ============================================================
function vrmod.fguide.L(key, fallback)
	local langTable = VRMOD_FGUIDE_LANG[VRMOD_FGUIDE_LANG.current]
	if langTable and langTable[key] then return langTable[key] end
	-- Fallback to English
	if VRMOD_FGUIDE_LANG.current ~= "en" and VRMOD_FGUIDE_LANG.en and VRMOD_FGUIDE_LANG.en[key] then
		return VRMOD_FGUIDE_LANG.en[key]
	end
	return fallback or key
end

-- ============================================================
-- Language auto-detection
-- ============================================================
local function DetectLang()
	local saved = GetConVar("vrmod_fguide_lang")
	if saved then
		local s = saved:GetString()
		if s and s ~= "" and VRMOD_FGUIDE_LANG[s] then return s end
	end
	local gl = GetConVarString("gmod_language") or ""
	if gl == "ja" or gl == "japanese" then return "ja" end
	if gl == "ru" or gl == "russian" then return "ru" end
	if gl == "zh-CN" or gl == "schinese" then return "zh" end
	return "en"
end

-- ============================================================
-- Color palette (same aesthetic as GUIDEv1)
-- ============================================================
local COLORS = {
	bg_dark         = Color(30, 30, 35, 255),
	bg_sidebar      = Color(38, 38, 45, 255),
	bg_content      = Color(45, 45, 52, 255),
	bg_topbar       = Color(35, 35, 42, 255),
	bg_hover        = Color(60, 60, 72, 255),
	bg_active       = Color(70, 130, 220, 255),
	bg_active_hover = Color(80, 140, 230, 255),
	text_primary    = Color(230, 230, 235, 255),
	text_secondary  = Color(160, 160, 170, 255),
	text_active     = Color(255, 255, 255, 255),
	accent          = Color(70, 130, 220, 255),
	border          = Color(55, 55, 65, 255),
	section_bg      = Color(50, 50, 60, 255),
	toggle_on       = Color(60, 160, 80, 255),
	toggle_on_hover = Color(70, 180, 90, 255),
	toggle_off      = Color(160, 70, 70, 255),
	toggle_off_hover= Color(180, 80, 80, 255),
	step_bg         = Color(50, 50, 60, 255),
	step_border     = Color(65, 65, 80, 255),
	step_number     = Color(70, 130, 220, 255),
	wizard_btn      = Color(70, 130, 220, 255),
	wizard_btn_hover= Color(90, 150, 240, 255),
	ts_option       = Color(55, 55, 68, 255),
	ts_option_hover = Color(70, 70, 85, 255),
	ts_solution_bg  = Color(40, 65, 50, 255),
	ts_back_btn     = Color(80, 80, 95, 255),
	ts_back_hover   = Color(100, 100, 115, 255),
	sidebar_section = Color(45, 45, 55, 255),
}
vrmod.fguide.COLORS = COLORS

-- ============================================================
-- Fonts (VRFGuide_ prefix to avoid conflict with GUIDEv1)
-- ============================================================
surface.CreateFont("VRFGuide_Title", {
	font = "Roboto", size = 20, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_Category", {
	font = "Roboto", size = 15, weight = 500, antialias = true,
})
surface.CreateFont("VRFGuide_CategorySmall", {
	font = "Roboto", size = 13, weight = 400, antialias = true,
})
surface.CreateFont("VRFGuide_Body", {
	font = "Roboto", size = 14, weight = 400, antialias = true,
})
surface.CreateFont("VRFGuide_BodyBold", {
	font = "Roboto", size = 14, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_Small", {
	font = "Roboto", size = 12, weight = 400, antialias = true,
})
surface.CreateFont("VRFGuide_Section", {
	font = "Roboto", size = 16, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_SectionSmall", {
	font = "Roboto", size = 11, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_Welcome", {
	font = "Roboto", size = 24, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_WelcomeBody", {
	font = "Roboto", size = 15, weight = 400, antialias = true,
})
surface.CreateFont("VRFGuide_StepNumber", {
	font = "Roboto", size = 28, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_StepTitle", {
	font = "Roboto", size = 15, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_ToggleBtn", {
	font = "Roboto", size = 18, weight = 700, antialias = true,
})
surface.CreateFont("VRFGuide_TSQuestion", {
	font = "Roboto", size = 16, weight = 600, antialias = true,
})
surface.CreateFont("VRFGuide_TSOption", {
	font = "Roboto", size = 14, weight = 500, antialias = true,
})
surface.CreateFont("VRFGuide_TSSolution", {
	font = "Roboto", size = 14, weight = 400, antialias = true,
})

-- ============================================================
-- State
-- ============================================================
local guideFrame = nil
local activeMode = nil
local sidebarButtons = {}
local contentContainer = nil

-- ============================================================
-- Sidebar definition: mode groups and entries
-- ============================================================

-- Mode order for sidebar (matches vrmod.fguide.modes indices)
-- Defined here; actual mode data is in vrmod_fguide_modes.lua
local SIDEBAR_GROUPS = {
	{
		type = "header",
		lang_key = "sidebar_welcome",
		fallback = "Overview",
	},
	{
		type = "entry",
		key = "welcome",
		icon = "icon16/information.png",
		lang_key = "sidebar_welcome",
		fallback = "Overview",
	},
	{
		type = "header",
		lang_key = "sidebar_group_toggle",
		fallback = "QUICK TOGGLE",
	},
	{
		type = "entry",
		key = "streamer",
		icon = "icon16/television.png",
		lang_key = "mode_streamer_title",
		fallback = "Streamer Mode",
	},
	{
		type = "entry",
		key = "seated",
		icon = "icon16/user_go.png",
		lang_key = "mode_seated_title",
		fallback = "Seated Play",
	},
	{
		type = "entry",
		key = "lefthand",
		icon = "icon16/arrow_turn_left.png",
		lang_key = "mode_lefthand_title",
		fallback = "Left-Handed Mode",
	},
	{
		type = "header",
		lang_key = "sidebar_group_wizard",
		fallback = "SETUP WIZARD",
	},
	{
		type = "entry",
		key = "height",
		icon = "icon16/arrow_inout.png",
		lang_key = "mode_height_title",
		fallback = "Height & Appearance",
	},
	{
		type = "entry",
		key = "fbt",
		icon = "icon16/group.png",
		lang_key = "mode_fbt_title",
		fallback = "Full Body Tracking",
	},
	{
		type = "entry",
		key = "performance",
		icon = "icon16/lightning.png",
		lang_key = "mode_performance_title",
		fallback = "Performance",
	},
	{
		type = "header",
		lang_key = "sidebar_group_troubleshoot",
		fallback = "TROUBLESHOOT",
	},
	{
		type = "entry",
		key = "troubleshoot",
		icon = "icon16/exclamation.png",
		lang_key = "mode_troubleshoot_title",
		fallback = "Troubleshoot",
	},
}

-- ============================================================
-- Show a mode page
-- ============================================================
function vrmod.fguide.ShowMode(modeKey)
	if not contentContainer or not IsValid(contentContainer) then return end

	-- Hide all cached panels
	for k, panel in pairs(vrmod.fguide.panelCache) do
		if IsValid(panel) then panel:SetVisible(false) end
	end

	-- Build or show cached panel
	if not vrmod.fguide.panelCache[modeKey] or not IsValid(vrmod.fguide.panelCache[modeKey]) then
		local panel = vrmod.fguide.BuildModePanel(contentContainer, modeKey)
		if panel then
			vrmod.fguide.panelCache[modeKey] = panel
		end
	else
		vrmod.fguide.panelCache[modeKey]:SetVisible(true)
	end

	-- Update sidebar highlight
	activeMode = modeKey
	for k, btn in pairs(sidebarButtons) do
		if IsValid(btn) then btn:SetActive(k == modeKey) end
	end
end

-- ============================================================
-- Build Welcome page
-- ============================================================
function vrmod.fguide.BuildWelcomePanel(parent)
	local L = vrmod.fguide.L

	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)

	local inner = vgui.Create("DPanel", scroll)
	inner:Dock(TOP)
	inner:DockMargin(20, 20, 20, 20)
	inner:SetTall(700)
	inner.Paint = function() end

	-- Welcome title
	local title = vgui.Create("DLabel", inner)
	title:SetFont("VRFGuide_Welcome")
	title:SetText(L("welcome_title", "VR Feature Guide"))
	title:SetTextColor(COLORS.text_primary)
	title:Dock(TOP)
	title:DockMargin(0, 0, 0, 10)
	title:SetAutoStretchVertical(true)

	-- Welcome description
	local desc = vgui.Create("DLabel", inner)
	desc:SetFont("VRFGuide_WelcomeBody")
	desc:SetText(L("welcome_desc",
		"This addon has many features that work even better when combined.\n" ..
		"This guide shows you how to set up common play styles with just a few clicks.\n\n" ..
		"Select a mode from the left sidebar to get started."))
	desc:SetTextColor(COLORS.text_secondary)
	desc:Dock(TOP)
	desc:DockMargin(0, 0, 0, 20)
	desc:SetWrap(true)
	desc:SetAutoStretchVertical(true)

	-- Quick Toggle section
	local toggleHeader = vgui.Create("DLabel", inner)
	toggleHeader:SetFont("VRFGuide_Section")
	toggleHeader:SetText(L("welcome_section_toggle", "Quick Toggle"))
	toggleHeader:SetTextColor(COLORS.accent)
	toggleHeader:Dock(TOP)
	toggleHeader:DockMargin(0, 10, 0, 5)
	toggleHeader:SetAutoStretchVertical(true)

	local toggleDesc = vgui.Create("DLabel", inner)
	toggleDesc:SetFont("VRFGuide_Body")
	toggleDesc:SetText(L("welcome_toggle_desc",
		"One-click modes that instantly configure multiple settings.\n" ..
		"Streamer Mode, Seated Play, Left-Handed Mode."))
	toggleDesc:SetTextColor(COLORS.text_secondary)
	toggleDesc:Dock(TOP)
	toggleDesc:DockMargin(0, 0, 0, 10)
	toggleDesc:SetWrap(true)
	toggleDesc:SetAutoStretchVertical(true)

	-- Wizard section
	local wizardHeader = vgui.Create("DLabel", inner)
	wizardHeader:SetFont("VRFGuide_Section")
	wizardHeader:SetText(L("welcome_section_wizard", "Setup Wizard"))
	wizardHeader:SetTextColor(COLORS.accent)
	wizardHeader:Dock(TOP)
	wizardHeader:DockMargin(0, 10, 0, 5)
	wizardHeader:SetAutoStretchVertical(true)

	local wizardDesc = vgui.Create("DLabel", inner)
	wizardDesc:SetFont("VRFGuide_Body")
	wizardDesc:SetText(L("welcome_wizard_desc",
		"Step-by-step setup guides. Follow the steps from top to bottom.\n" ..
		"Height calibration, Full Body Tracking setup, Performance optimization."))
	wizardDesc:SetTextColor(COLORS.text_secondary)
	wizardDesc:Dock(TOP)
	wizardDesc:DockMargin(0, 0, 0, 10)
	wizardDesc:SetWrap(true)
	wizardDesc:SetAutoStretchVertical(true)

	-- Troubleshoot section
	local tsHeader = vgui.Create("DLabel", inner)
	tsHeader:SetFont("VRFGuide_Section")
	tsHeader:SetText(L("welcome_section_troubleshoot", "Troubleshoot"))
	tsHeader:SetTextColor(COLORS.accent)
	tsHeader:Dock(TOP)
	tsHeader:DockMargin(0, 10, 0, 5)
	tsHeader:SetAutoStretchVertical(true)

	local tsDesc = vgui.Create("DLabel", inner)
	tsDesc:SetFont("VRFGuide_Body")
	tsDesc:SetText(L("welcome_troubleshoot_desc",
		"Having a problem? Answer a few questions and get a solution.\n" ..
		"Covers movement, display, crashes, controls, and performance issues."))
	tsDesc:SetTextColor(COLORS.text_secondary)
	tsDesc:Dock(TOP)
	tsDesc:DockMargin(0, 0, 0, 15)
	tsDesc:SetWrap(true)
	tsDesc:SetAutoStretchVertical(true)

	-- VR Status
	local statusHeader = vgui.Create("DLabel", inner)
	statusHeader:SetFont("VRFGuide_Section")
	statusHeader:SetText(L("vr_status_title", "VR Status"))
	statusHeader:SetTextColor(COLORS.accent)
	statusHeader:Dock(TOP)
	statusHeader:DockMargin(0, 10, 0, 5)
	statusHeader:SetAutoStretchVertical(true)

	local isVRActive = g_VR and g_VR.active
	local statusText = isVRActive
		and L("vr_status_active", "VR is ACTIVE")
		or L("vr_status_inactive", "VR is NOT active. Start VR from the main VRMod menu (console: vrmod)")
	local statusColor = isVRActive and Color(100, 220, 100) or Color(220, 160, 60)

	local statusLbl = vgui.Create("DLabel", inner)
	statusLbl:SetFont("VRFGuide_Body")
	statusLbl:SetText(statusText)
	statusLbl:SetTextColor(statusColor)
	statusLbl:Dock(TOP)
	statusLbl:DockMargin(0, 0, 0, 10)
	statusLbl:SetAutoStretchVertical(true)

	-- Open VRMod Menu button
	local openBtn = vgui.Create("DButton", inner)
	openBtn:SetText(L("btn_open_main_menu", "Open Main VRMod Menu"))
	openBtn:SetFont("VRFGuide_Body")
	openBtn:Dock(TOP)
	openBtn:DockMargin(0, 5, 300, 5)
	openBtn:SetTall(32)
	openBtn.DoClick = function()
		RunConsoleCommand("vrmod")
	end

	return scroll
end

-- ============================================================
-- Build mode panel (delegates to mode/troubleshoot renderers)
-- ============================================================
function vrmod.fguide.BuildModePanel(parent, modeKey)
	if modeKey == "welcome" then
		return vrmod.fguide.BuildWelcomePanel(parent)
	end

	if modeKey == "troubleshoot" then
		-- Delegate to troubleshoot renderer
		if vrmod.fguide.RenderTroubleshoot then
			return vrmod.fguide.RenderTroubleshoot(parent)
		end
	else
		-- Delegate to mode renderer
		if vrmod.fguide.RenderMode then
			return vrmod.fguide.RenderMode(parent, modeKey)
		end
	end

	-- Fallback if renderer not loaded yet
	local lbl = vgui.Create("DLabel", parent)
	lbl:SetText("Mode: " .. modeKey .. " (renderer not loaded)")
	lbl:SetFont("VRFGuide_Body")
	lbl:SetTextColor(COLORS.text_primary)
	lbl:Dock(FILL)
	return lbl
end

-- ============================================================
-- Main Open function
-- ============================================================
function vrmod.fguide.Open(forceLang)
	if IsValid(guideFrame) then guideFrame:Remove() end

	-- Language handling
	if forceLang and VRMOD_FGUIDE_LANG[forceLang] then
		VRMOD_FGUIDE_LANG.current = forceLang
	elseif not vrmod.fguide._langInitialized then
		VRMOD_FGUIDE_LANG.current = DetectLang()
		vrmod.fguide._langInitialized = true
	end

	-- Clear panel cache
	vrmod.fguide.panelCache = {}
	sidebarButtons = {}
	activeMode = nil

	local L = vrmod.fguide.L

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
		draw.SimpleText(L("window_title", "VR Feature Guide"), "VRFGuide_Title", 10, 5, COLORS.text_primary)
	end

	-- Close button
	local closeBtn = vgui.Create("DButton", guideFrame)
	closeBtn:SetText("X")
	closeBtn:SetFont("VRFGuide_BodyBold")
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

	-- Top bar: language switcher
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
	langLabel:SetFont("VRFGuide_Small")
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
	langCombo:SetFont("VRFGuide_Body")
	langCombo:AddChoice("English", "en")
	langCombo:AddChoice("\230\151\165\230\156\172\232\170\158 (Japanese)", "ja")
	langCombo:AddChoice("\208\160\209\131\209\129\209\129\208\186\208\184\208\185 (Russian)", "ru")
	langCombo:AddChoice("\228\184\173\230\150\135 (Chinese)", "zh")

	local langMap = {en = 1, ja = 2, ru = 3, zh = 4}
	langCombo:ChooseOptionID(langMap[VRMOD_FGUIDE_LANG.current] or 1)

	langCombo.OnSelect = function(self, index, value, data)
		if not data or data == "" then return end
		RunConsoleCommand("vrmod_fguide_lang", data)
		vrmod.fguide.Open(data)
	end

	-- Subtitle in top bar
	local subtitle = vgui.Create("DLabel", topBar)
	subtitle:SetFont("VRFGuide_Small")
	subtitle:SetText(L("topbar_subtitle", "Combine features for the best VR experience"))
	subtitle:SetTextColor(COLORS.text_secondary)
	subtitle:Dock(LEFT)
	subtitle:DockMargin(8, 0, 0, 0)
	subtitle:SizeToContents()

	-- Bottom status bar
	local statusBar = vgui.Create("DPanel", guideFrame)
	statusBar:Dock(BOTTOM)
	statusBar:SetTall(22)
	statusBar.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_topbar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(0, 0, w, 0)

		local modeCount = vrmod.fguide.modes and #vrmod.fguide.modes or 0
		local statusText = string.format("VR Feature Guide | %d %s | %s",
			modeCount,
			L("status_modes", "modes"),
			L("status_lang_" .. VRMOD_FGUIDE_LANG.current, VRMOD_FGUIDE_LANG.current))
		draw.SimpleText(statusText, "VRFGuide_Small", 8, 4, COLORS.text_secondary)
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

	-- Build sidebar entries
	for _, entry in ipairs(SIDEBAR_GROUPS) do
		if entry.type == "header" then
			-- Section header (non-clickable label)
			local headerPanel = vgui.Create("DPanel", sidebar)
			headerPanel:Dock(TOP)
			headerPanel:SetTall(26)
			headerPanel:DockMargin(4, 8, 4, 0)
			local headerText = L(entry.lang_key, entry.fallback)
			headerPanel.Paint = function(self, w, h)
				draw.RoundedBox(2, 0, 0, w, h, COLORS.sidebar_section)
				draw.SimpleText(string.upper(headerText), "VRFGuide_SectionSmall", 10, h / 2,
					COLORS.text_secondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

		elseif entry.type == "entry" then
			-- Clickable mode button
			local modeKey = entry.key
			local catIcon = entry.icon
			local catName = L(entry.lang_key, entry.fallback)

			local btn = vgui.Create("DButton", sidebar)
			btn:Dock(TOP)
			btn:SetTall(38)
			btn:DockMargin(4, 2, 4, 0)
			btn:SetText("")
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

				-- Name
				local textCol = self.isActive and COLORS.text_active or COLORS.text_primary
				draw.SimpleText(catName, "VRFGuide_Category", 34, h / 2,
					textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			btn.DoClick = function(self)
				vrmod.fguide.ShowMode(modeKey)
			end

			sidebarButtons[modeKey] = btn
		end
	end

	-- Show Welcome by default
	vrmod.fguide.ShowMode("welcome")
end

-- ============================================================
-- ConCommand
-- ============================================================
concommand.Add("vrmod_fguide", function()
	vrmod.fguide.Open()
end)

print("[VRMod] Feature Guide core loaded")
