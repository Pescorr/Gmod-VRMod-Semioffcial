-- VRMod Beginner Guide - Widget Factory
-- ウィジェット生成ファクトリ

AddCSLuaFile()
if SERVER then return end

local L = function(key, fallback) return vrmod.guide.L(key, fallback) end
local COLORS = nil

-- Lazy init colors (core may not be fully loaded at file-load time)
local function C()
	if not COLORS then COLORS = vrmod.guide.COLORS end
	return COLORS
end

-- ============================================================
-- Helper: Estimate text height for wrapping
-- ============================================================
local function EstimateTextHeight(text, font, availWidth)
	surface.SetFont(font)
	local textW, lineH = surface.GetTextSize(text)
	if textW <= 0 or availWidth <= 0 then return lineH + 2 end
	local numLines = math.max(1, math.ceil(textW / availWidth))
	return numLines * (lineH + 1) + 2
end

-- ============================================================
-- Helper: Safely set ConVar on a VGUI element
-- ============================================================
local function SafeSetConVar(element, cvarName)
	if not cvarName or cvarName == "" then return false end
	if not GetConVar(cvarName) then return false end
	element:SetConVar(cvarName)
	return true
end

-- ============================================================
-- Helper: Create per-item reset button
-- ============================================================
local function CreateResetButton(parent, cvarName, h)
	local default = nil
	if VRModGetDefault then default = VRModGetDefault(cvarName) end
	if default == nil then return end

	local resetBtn = vgui.Create("DImageButton", parent)
	resetBtn:SetImage("icon16/arrow_undo.png")
	resetBtn:Dock(RIGHT)
	resetBtn:SetSize(20, 20)
	resetBtn:DockMargin(4, (h - 20) / 2, 4, (h - 20) / 2)
	resetBtn:SetTooltip(L("tip_reset_to", "Reset to default") .. ": " .. tostring(default))
	resetBtn.DoClick = function()
		RunConsoleCommand(cvarName, tostring(default))
	end
	return resetBtn
end

-- ============================================================
-- Helper: Create description label below a control
-- ============================================================
local function CreateTipLabel(parent, item)
	if not item.tip_key then return end
	local tip = L(item.tip_key, "")
	if tip == "" then return end

	local tipLabel = vgui.Create("DLabel", parent)
	tipLabel:SetFont("VRGuide_Small")
	tipLabel:SetText("  " .. tip)
	tipLabel:SetTextColor(C().text_secondary)
	tipLabel:Dock(TOP)
	tipLabel:DockMargin(30, 0, 30, 4)
	tipLabel:SetWrap(true)
	-- Manual height calculation instead of SetAutoStretchVertical
	-- (AutoStretchVertical doesn't work reliably inside DScrollPanel)
	local h = EstimateTextHeight(tip, "VRGuide_Small", 520)
	tipLabel:SetTall(h)
	return tipLabel
end

-- ============================================================
-- Helper: Server-side indicator
-- ============================================================
local function CreateServerBadge(parent)
	local badge = vgui.Create("DLabel", parent)
	badge:SetFont("VRGuide_Small")
	badge:SetText("[SERVER]")
	badge:SetTextColor(Color(220, 160, 60))
	badge:Dock(RIGHT)
	badge:DockMargin(4, 0, 4, 0)
	badge:SizeToContents()
	badge:SetTooltip(L("tip_server_setting", "This is a server-side setting. Only the server host can change it."))
	return badge
end

-- ============================================================
-- Checkbox widget
-- ============================================================
function vrmod.guide.widgets.Checkbox(parent, item)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(8, 2, 8, 0)
	panel:SetTall(28)
	panel.Paint = function(self, w, h)
		if self:IsHovered() then
			draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 8))
		end
	end

	if item.server then CreateServerBadge(panel) end
	CreateResetButton(panel, item.cvar, 28)

	local check = vgui.Create("DCheckBoxLabel", panel)
	check:SetFont("VRGuide_Body")
	check:SetText(L(item.lang_key, item.cvar or ""))
	check:SetTextColor(C().text_primary)
	SafeSetConVar(check, item.cvar)
	check:Dock(FILL)
	check:DockMargin(8, 4, 4, 4)

	CreateTipLabel(parent, item)

	return panel
end

-- ============================================================
-- Slider widget
-- ============================================================
function vrmod.guide.widgets.Slider(parent, item)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(8, 2, 8, 0)
	panel:SetTall(36)
	panel.Paint = function(self, w, h)
		if self:IsHovered() then
			draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 8))
		end
	end

	if item.server then CreateServerBadge(panel) end
	CreateResetButton(panel, item.cvar, 36)

	local slider = vgui.Create("DNumSlider", panel)
	slider:SetText(L(item.lang_key, item.cvar or ""))
	-- DNumSlider has no SetFont; access sub-elements
	if IsValid(slider.Label) then slider.Label:SetFont("VRGuide_Body") end
	if IsValid(slider.TextArea) then slider.TextArea:SetFont("VRGuide_Small") end
	slider:SetMin(item.min or 0)
	slider:SetMax(item.max or 100)
	slider:SetDecimals(item.decimals or 2)
	SafeSetConVar(slider, item.cvar)
	slider:Dock(FILL)
	slider:DockMargin(8, 0, 4, 0)

	CreateTipLabel(parent, item)

	return panel
end

-- ============================================================
-- Text entry widget
-- ============================================================
function vrmod.guide.widgets.Text(parent, item)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(8, 2, 8, 0)
	panel:SetTall(30)
	panel.Paint = function(self, w, h)
		if self:IsHovered() then
			draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 8))
		end
	end

	if item.server then CreateServerBadge(panel) end
	CreateResetButton(panel, item.cvar, 30)

	local lbl = vgui.Create("DLabel", panel)
	lbl:SetFont("VRGuide_Body")
	lbl:SetText(L(item.lang_key, item.cvar or ""))
	lbl:SetTextColor(C().text_primary)
	lbl:Dock(LEFT)
	lbl:DockMargin(8, 0, 8, 0)
	lbl:SetWide(250)

	local entry = vgui.Create("DTextEntry", panel)
	entry:SetFont("VRGuide_Body")
	SafeSetConVar(entry, item.cvar)
	entry:Dock(FILL)
	entry:DockMargin(0, 3, 4, 3)

	CreateTipLabel(parent, item)

	return panel
end

-- ============================================================
-- Dropdown widget
-- ============================================================
function vrmod.guide.widgets.Dropdown(parent, item)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(8, 2, 8, 0)
	panel:SetTall(30)
	panel.Paint = function(self, w, h)
		if self:IsHovered() then
			draw.RoundedBox(2, 0, 0, w, h, Color(255, 255, 255, 8))
		end
	end

	if item.server then CreateServerBadge(panel) end
	CreateResetButton(panel, item.cvar, 30)

	local lbl = vgui.Create("DLabel", panel)
	lbl:SetFont("VRGuide_Body")
	lbl:SetText(L(item.lang_key, item.cvar or ""))
	lbl:SetTextColor(C().text_primary)
	lbl:Dock(LEFT)
	lbl:DockMargin(8, 0, 8, 0)
	lbl:SetWide(250)

	local combo = vgui.Create("DComboBox", panel)
	combo:SetFont("VRGuide_Body")
	combo:Dock(FILL)
	combo:DockMargin(0, 3, 4, 3)

	-- Populate options
	local currentVal = nil
	local cvar = GetConVar(item.cvar)
	if cvar then currentVal = cvar:GetString() end

	if item.options then
		for _, opt in ipairs(item.options) do
			combo:AddChoice(L(opt.lang_key, opt.label or opt.value), opt.value)
		end
	end

	-- Select current value
	if currentVal then
		for i, opt in ipairs(item.options or {}) do
			if opt.value == currentVal then
				combo:ChooseOptionID(i)
				break
			end
		end
	end

	combo.OnSelect = function(self, index, value, data)
		RunConsoleCommand(item.cvar, tostring(data))
	end

	CreateTipLabel(parent, item)

	return panel
end

-- ============================================================
-- Button widget (for ConCommands)
-- ============================================================
function vrmod.guide.widgets.Button(parent, item)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(8, 2, 8, 0)
	panel:SetTall(34)
	panel.Paint = function() end

	local btn = vgui.Create("DButton", panel)
	btn:SetFont("VRGuide_Body")
	btn:SetText(L(item.lang_key, item.command or ""))
	btn:Dock(LEFT)
	btn:SetWide(300)
	btn:DockMargin(8, 2, 4, 2)
	btn.Paint = function(self, w, h)
		local bgCol = self:IsHovered() and Color(80, 140, 230) or C().accent
		draw.RoundedBox(4, 0, 0, w, h, bgCol)
		local tx, ty = w / 2, h / 2
		draw.SimpleText(self:GetText(), "VRGuide_Body", tx, ty, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btn:SetTextColor(Color(0, 0, 0, 0)) -- Hide default text, custom paint above

	btn.DoClick = function()
		if item.command then
			if item.args then
				RunConsoleCommand(item.command, unpack(item.args))
			else
				RunConsoleCommand(item.command)
			end
		end
	end

	-- Show command name as info
	local cmdInfo = vgui.Create("DLabel", panel)
	cmdInfo:SetFont("VRGuide_Small")
	cmdInfo:SetText(item.command or "")
	cmdInfo:SetTextColor(C().text_secondary)
	cmdInfo:Dock(FILL)
	cmdInfo:DockMargin(8, 0, 4, 0)

	CreateTipLabel(parent, item)

	return panel
end

-- ============================================================
-- Section header widget
-- ============================================================
function vrmod.guide.widgets.Section(parent, item)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(4, 12, 4, 4)
	panel:SetTall(28)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, C().section_bg)
		surface.SetDrawColor(C().accent)
		surface.DrawRect(0, 0, 3, h)
	end

	local lbl = vgui.Create("DLabel", panel)
	lbl:SetFont("VRGuide_Section")
	lbl:SetText(L(item.lang_key, "Section"))
	lbl:SetTextColor(C().accent)
	lbl:Dock(FILL)
	lbl:DockMargin(12, 0, 0, 0)

	return panel
end

-- ============================================================
-- Dispatch function (with error protection)
-- ============================================================
function vrmod.guide.widgets.CreateFromItem(parent, item)
	if not item or not item.type then return end

	local creators = {
		checkbox = vrmod.guide.widgets.Checkbox,
		slider   = vrmod.guide.widgets.Slider,
		text     = vrmod.guide.widgets.Text,
		dropdown = vrmod.guide.widgets.Dropdown,
		button   = vrmod.guide.widgets.Button,
		section  = vrmod.guide.widgets.Section,
	}

	local fn = creators[item.type]
	if not fn then return end

	local ok, result = pcall(fn, parent, item)
	if not ok then
		-- Show error inline instead of breaking the whole page
		local errLabel = vgui.Create("DLabel", parent)
		errLabel:SetFont("VRGuide_Small")
		errLabel:SetText("  [Widget error: " .. tostring(item.cvar or item.command or "?") .. "]")
		errLabel:SetTextColor(Color(255, 100, 100))
		errLabel:Dock(TOP)
		errLabel:DockMargin(8, 2, 8, 2)
		errLabel:SetTall(16)
		return nil
	end
	return result
end

print("[VRMod] Beginner Guide widgets loaded")
