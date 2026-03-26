-- VRMod Beginner Guide - Page Rendering Engine
-- カテゴリページ描画エンジン

AddCSLuaFile()
if SERVER then return end

local L = function(key, fallback) return vrmod.guide.L(key, fallback) end

-- ============================================================
-- Render a category page
-- ============================================================
function vrmod.guide.RenderCategory(parent, catKey)
	local catDef = vrmod.guide.categories[catKey]
	if not catDef then return end

	local COLORS = vrmod.guide.COLORS

	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)

	-- ========================================
	-- Category header
	-- ========================================
	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:DockMargin(0, 0, 0, 0)
	header:SetTall(50)
	header.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.bg_topbar)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(COLORS.border)
		surface.DrawLine(0, h - 1, w, h - 1)

		-- Icon
		local iconMat = Material(catDef.icon or "icon16/page.png", "smooth")
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(iconMat)
		surface.DrawTexturedRect(15, (h - 20) / 2, 20, 20)

		-- Category name
		draw.SimpleText(L("cat_" .. catKey, catKey), "VRGuide_Title", 45, h / 2 - 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	-- ========================================
	-- "What is this?" help panel (collapsible)
	-- ========================================
	local helpText = L("help_" .. catKey, "")
	if helpText ~= "" then
		local helpContainer = vgui.Create("DPanel", scroll)
		helpContainer:Dock(TOP)
		helpContainer:DockMargin(8, 4, 8, 0)
		helpContainer:SetTall(24)
		helpContainer.expanded = false
		helpContainer.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(50, 60, 80, 200))
		end

		local helpToggle = vgui.Create("DButton", helpContainer)
		helpToggle:SetText("  " .. L("help_prefix", "What is this?") .. " (click to expand)")
		helpToggle:SetFont("VRGuide_Small")
		helpToggle:SetTextColor(Color(130, 170, 230))
		helpToggle:Dock(TOP)
		helpToggle:SetTall(24)
		helpToggle.Paint = function() end

		local helpLabel = vgui.Create("DLabel", helpContainer)
		helpLabel:SetFont("VRGuide_Body")
		helpLabel:SetText(helpText)
		helpLabel:SetTextColor(COLORS.text_secondary)
		helpLabel:Dock(TOP)
		helpLabel:DockMargin(10, 2, 10, 6)
		helpLabel:SetWrap(true)
		helpLabel:SetAutoStretchVertical(true)
		helpLabel:SetVisible(false)

		helpToggle.DoClick = function()
			helpContainer.expanded = not helpContainer.expanded
			helpLabel:SetVisible(helpContainer.expanded)
			if helpContainer.expanded then
				helpToggle:SetText("  " .. L("help_prefix", "What is this?") .. " (click to collapse)")
				-- Calculate needed height
				helpLabel:InvalidateLayout(true)
				local textH = helpLabel:GetTall()
				helpContainer:SetTall(24 + textH + 10)
			else
				helpToggle:SetText("  " .. L("help_prefix", "What is this?") .. " (click to expand)")
				helpContainer:SetTall(24)
			end
		end
	end

	-- ========================================
	-- Reset buttons bar
	-- ========================================
	if catDef.defaults_category and #catDef.defaults_category > 0 then
		local resetBar = vgui.Create("DPanel", scroll)
		resetBar:Dock(TOP)
		resetBar:DockMargin(8, 4, 8, 4)
		resetBar:SetTall(30)
		resetBar.Paint = function() end

		local resetBtn = vgui.Create("DButton", resetBar)
		resetBtn:SetText(L("btn_reset_category", "Reset this category to defaults"))
		resetBtn:SetFont("VRGuide_Body")
		resetBtn:SetTextColor(Color(255, 255, 255))
		resetBtn:Dock(LEFT)
		resetBtn:SetWide(280)
		resetBtn.Paint = function(self, w, h)
			local col = self:IsHovered() and Color(200, 80, 80) or COLORS.reset_btn
			draw.RoundedBox(4, 0, 0, w, h, col)
		end
		resetBtn.DoClick = function()
			Derma_Query(
				L("confirm_reset_category", "Reset all settings in this category to defaults?"),
				L("confirm_title", "Confirm Reset"),
				L("btn_yes", "Yes"),
				function()
					for _, cat in ipairs(catDef.defaults_category) do
						if VRModResetCategory then VRModResetCategory(cat) end
					end
					-- Rebuild the panel
					if vrmod.guide.panelCache[catKey] and IsValid(vrmod.guide.panelCache[catKey]) then
						vrmod.guide.panelCache[catKey]:Remove()
					end
					vrmod.guide.panelCache[catKey] = nil
					vrmod.guide.ShowCategory(catKey)
				end,
				L("btn_no", "No"),
				function() end
			)
		end

		-- Item count
		local itemCount = 0
		for _, item in ipairs(catDef.items or {}) do
			if item.type ~= "section" then itemCount = itemCount + 1 end
		end
		local countLabel = vgui.Create("DLabel", resetBar)
		countLabel:SetFont("VRGuide_Small")
		countLabel:SetText(string.format("  %d %s", itemCount, L("status_settings", "settings")))
		countLabel:SetTextColor(COLORS.text_secondary)
		countLabel:Dock(FILL)
		countLabel:DockMargin(8, 0, 0, 0)
	end

	-- ========================================
	-- Settings items
	-- ========================================
	if catDef.items then
		for _, item in ipairs(catDef.items) do
			if vrmod.guide.widgets.CreateFromItem then
				vrmod.guide.widgets.CreateFromItem(scroll, item)
			end
		end
	end

	-- Bottom padding
	local bottomPad = vgui.Create("DPanel", scroll)
	bottomPad:Dock(TOP)
	bottomPad:SetTall(20)
	bottomPad.Paint = function() end

	return scroll
end

print("[VRMod] Beginner Guide render engine loaded")
