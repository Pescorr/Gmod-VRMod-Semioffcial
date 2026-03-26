-- vrmod_spawnmenu_tab.lua
-- GMod Spawnmenu (Q Menu) tab for VRMod
-- Uses Guide's category definitions and localization for consistent UI
-- Rebuilds content from vrmod.guide.categories data

if SERVER then return end

-- ============================================================
-- Hook 1: Register the top-level "VRMod" tab
-- ============================================================
hook.Add("AddToolMenuTabs", "VRMod_SpawnMenu_AddTab", function()
	spawnmenu.AddToolTab("VRMod", "VRMod", "icon16/controller.png")
end)

-- ============================================================
-- Helper: Build Guide-style CPanel content from category items
-- ============================================================
local function BuildGuideCPanel(panel, catKey)
	panel:ClearControls()

	-- Wait for guide system
	if not vrmod or not vrmod.guide or not vrmod.guide.categories then
		panel:Help("Guide system not loaded yet. Reopen spawn menu.")
		return
	end

	local L = vrmod.guide.L or function(k, fb) return fb or k end
	local catDef = vrmod.guide.categories[catKey]
	if not catDef then
		panel:Help("Category not found: " .. tostring(catKey))
		return
	end

	-- Category help text
	local helpKey = "help_" .. catKey
	local helpText = L(helpKey, "")
	if helpText ~= "" and helpText ~= helpKey then
		local helpLabel = vgui.Create("DLabel", panel)
		helpLabel:SetFont("DermaDefaultBold")
		helpLabel:SetText(helpText)
		helpLabel:SetTextColor(Color(180, 200, 230))
		helpLabel:SetWrap(true)
		helpLabel:SetAutoStretchVertical(true)
		helpLabel:Dock(TOP)
		helpLabel:DockMargin(0, 0, 0, 8)
		panel:AddItem(helpLabel)
	end

	-- Items
	for _, item in ipairs(catDef.items or {}) do
		local itemType = item.type
		local label = L(item.lang_key or "", item.lang_key or "")
		local tip = L(item.tip_key or "", "")

		if itemType == "section" then
			-- Section header with accent styling
			local sectionPanel = vgui.Create("DPanel")
			sectionPanel:SetTall(26)
			sectionPanel.Paint = function(self, w, h)
				surface.SetDrawColor(70, 130, 220, 255)
				surface.DrawRect(0, 0, 3, h)
				surface.SetDrawColor(50, 50, 60, 200)
				surface.DrawRect(3, 0, w - 3, h)
			end
			local sectionLabel = vgui.Create("DLabel", sectionPanel)
			sectionLabel:SetFont("DermaDefaultBold")
			sectionLabel:SetText(label)
			sectionLabel:SetTextColor(Color(200, 210, 230))
			sectionLabel:Dock(FILL)
			sectionLabel:DockMargin(10, 0, 0, 0)
			panel:AddItem(sectionPanel)

		elseif itemType == "checkbox" then
			local cb = panel:CheckBox(label, item.cvar)
			if item.server then
				local serverBadge = vgui.Create("DLabel")
				serverBadge:SetFont("DermaDefault")
				serverBadge:SetText("  [SERVER]")
				serverBadge:SetTextColor(Color(220, 180, 100))
				serverBadge:SizeToContents()
				panel:AddItem(serverBadge)
			end
			if tip ~= "" and tip ~= (item.tip_key or "") then
				local tipLabel = vgui.Create("DLabel")
				tipLabel:SetFont("DermaDefault")
				tipLabel:SetText("  " .. tip)
				tipLabel:SetTextColor(Color(150, 150, 160))
				tipLabel:SetWrap(true)
				tipLabel:SetAutoStretchVertical(true)
				panel:AddItem(tipLabel)
			end

		elseif itemType == "slider" then
			panel:NumSlider(label, item.cvar, item.min or 0, item.max or 100, item.decimals or 0)
			if item.server then
				local serverBadge = vgui.Create("DLabel")
				serverBadge:SetFont("DermaDefault")
				serverBadge:SetText("  [SERVER]")
				serverBadge:SetTextColor(Color(220, 180, 100))
				serverBadge:SizeToContents()
				panel:AddItem(serverBadge)
			end
			if tip ~= "" and tip ~= (item.tip_key or "") then
				local tipLabel = vgui.Create("DLabel")
				tipLabel:SetFont("DermaDefault")
				tipLabel:SetText("  " .. tip)
				tipLabel:SetTextColor(Color(150, 150, 160))
				tipLabel:SetWrap(true)
				tipLabel:SetAutoStretchVertical(true)
				panel:AddItem(tipLabel)
			end

		elseif itemType == "text" then
			panel:TextEntry(label, item.cvar)
			if tip ~= "" and tip ~= (item.tip_key or "") then
				local tipLabel = vgui.Create("DLabel")
				tipLabel:SetFont("DermaDefault")
				tipLabel:SetText("  " .. tip)
				tipLabel:SetTextColor(Color(150, 150, 160))
				tipLabel:SetWrap(true)
				tipLabel:SetAutoStretchVertical(true)
				panel:AddItem(tipLabel)
			end

		elseif itemType == "dropdown" then
			local comboLabel = vgui.Create("DLabel")
			comboLabel:SetFont("DermaDefault")
			comboLabel:SetText(label)
			comboLabel:SetTextColor(Color(200, 200, 210))
			comboLabel:SizeToContents()
			panel:AddItem(comboLabel)

			local combo = vgui.Create("DComboBox")
			combo:SetTall(24)
			local currentVal = ""
			if item.cvar then
				local cv = GetConVar(item.cvar)
				if cv then currentVal = cv:GetString() end
			end
			for _, opt in ipairs(item.options or {}) do
				local optLabel = L(opt.lang_key or "", opt.label or opt.value)
				combo:AddChoice(optLabel, opt.value)
				if tostring(opt.value) == currentVal then
					combo:SetValue(optLabel)
				end
			end
			combo.OnSelect = function(self, index, value, data)
				if item.cvar then RunConsoleCommand(item.cvar, tostring(data)) end
			end
			panel:AddItem(combo)

			if tip ~= "" and tip ~= (item.tip_key or "") then
				local tipLabel = vgui.Create("DLabel")
				tipLabel:SetFont("DermaDefault")
				tipLabel:SetText("  " .. tip)
				tipLabel:SetTextColor(Color(150, 150, 160))
				tipLabel:SetWrap(true)
				tipLabel:SetAutoStretchVertical(true)
				panel:AddItem(tipLabel)
			end

		elseif itemType == "button" then
			local btn = panel:Button(label)
			if btn and btn.DoClick then
				local cmd = item.command
				local args = item.args
				btn.DoClick = function()
					if cmd then
						if args then
							RunConsoleCommand(cmd, args)
						else
							RunConsoleCommand(cmd)
						end
					end
				end
			end
			if tip ~= "" and tip ~= (item.tip_key or "") then
				local tipLabel = vgui.Create("DLabel")
				tipLabel:SetFont("DermaDefault")
				tipLabel:SetText("  " .. tip)
				tipLabel:SetTextColor(Color(150, 150, 160))
				tipLabel:SetWrap(true)
				tipLabel:SetAutoStretchVertical(true)
				panel:AddItem(tipLabel)
			end
		end
	end

	-- Reset button at bottom (if category has defaults)
	if catDef.defaults_category then
		-- Spacer
		local spacer = vgui.Create("DPanel")
		spacer:SetTall(10)
		spacer.Paint = function() end
		panel:AddItem(spacer)

		local resetBtn = vgui.Create("DButton")
		resetBtn:SetText(L("btn_reset_category", "Reset this category to defaults"))
		resetBtn:SetTall(28)
		resetBtn:SetTextColor(Color(255, 255, 255))
		resetBtn.Paint = function(self, w, h)
			local col = self:IsHovered() and Color(200, 80, 80) or Color(180, 80, 80)
			draw.RoundedBox(4, 0, 0, w, h, col)
		end
		resetBtn.DoClick = function()
			if VRModResetCategory then
				for _, cat in ipairs(catDef.defaults_category) do
					VRModResetCategory(cat)
				end
			end
		end
		panel:AddItem(resetBtn)
	end
end

-- ============================================================
-- Hook 2: Populate categories from Guide system
-- ============================================================
hook.Add("PopulateToolMenu", "VRMod_SpawnMenu_Populate", function()

	-- Map catKey → spawnmenu display name (use Guide localization if available)
	local catOrder = {
		"body_scale",
		"gameplay",
		"movement",
		"hud_ui",
		"quickmenu",
		"melee",
		"weapons",
		"holster",
		"physgun",
		"climbing",
		"vehicles",
		"network",
		"optimization",
		"developer",
		"commands",
	}

	-- Register each category
	for i, catKey in ipairs(catOrder) do
		local L = (vrmod and vrmod.guide and vrmod.guide.L) or function(k, fb) return fb or k end
		local displayName = L("cat_" .. catKey, catKey)

		spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_" .. catKey, displayName, "", "", function(panel)
			BuildGuideCPanel(panel, catKey)
		end)
	end

	-- Cardboard (special, not in Guide categories but useful in spawnmenu)
	spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_cardboard", "Cardboard", "", "", function(panel)
		panel:ClearControls()
		local L = (vrmod and vrmod.guide and vrmod.guide.L) or function(k, fb) return fb or k end
		panel:Help(L("tip_cmd_cardboard", "Cardboard VR mode (phone sensor emulation)"))
		local btnStart = panel:Button(L("cmd_cardboardmod_start", "Start Cardboard VR"))
		btnStart.DoClick = function() RunConsoleCommand("cardboardmod_start") end
		local btnExit = panel:Button(L("cmd_cardboardmod_exit", "Exit Cardboard VR"))
		btnExit.DoClick = function() RunConsoleCommand("cardboardmod_exit") end
	end)

	-- Utility (special quick actions)
	spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_utility", "Utility", "", "", function(panel)
		panel:ClearControls()
		local L = (vrmod and vrmod.guide and vrmod.guide.L) or function(k, fb) return fb or k end

		-- Section: Quick Actions
		local sectionPanel = vgui.Create("DPanel")
		sectionPanel:SetTall(26)
		sectionPanel.Paint = function(self, w, h)
			surface.SetDrawColor(70, 130, 220, 255)
			surface.DrawRect(0, 0, 3, h)
			surface.SetDrawColor(50, 50, 60, 200)
			surface.DrawRect(3, 0, w - 3, h)
		end
		local sectionLabel = vgui.Create("DLabel", sectionPanel)
		sectionLabel:SetFont("DermaDefaultBold")
		sectionLabel:SetText("Quick Actions")
		sectionLabel:SetTextColor(Color(200, 210, 230))
		sectionLabel:Dock(FILL)
		sectionLabel:DockMargin(10, 0, 0, 0)
		panel:AddItem(sectionPanel)

		local btnMenu = panel:Button(L("cmd_vrmod", "Open VRMod Menu"))
		btnMenu.DoClick = function() RunConsoleCommand("vrmod") end
		local btnGuide = panel:Button(L("cmd_vrmod_guide", "Open Beginner Guide"))
		btnGuide.DoClick = function() RunConsoleCommand("vrmod_guide") end
		local btnStart = panel:Button("Start VR")
		btnStart.DoClick = function() RunConsoleCommand("vrmod_start") end
		local btnExit = panel:Button("Exit VR")
		btnExit.DoClick = function() RunConsoleCommand("vrmod_exit") end
		local btnScr = panel:Button("Auto-Detect Resolution")
		btnScr.DoClick = function() RunConsoleCommand("vrmod_Scr_Auto") end
		local btnVgui = panel:Button("Reset VGUI Panels")
		btnVgui.DoClick = function() RunConsoleCommand("vrmod_vgui_reset") end
		local btnReset = panel:Button(L("btn_reset_all", "Reset All Settings"))
		btnReset.DoClick = function() if VRModResetAll then VRModResetAll() end end
	end)

end)

print("[VRMod] Spawnmenu tab registered (Guide-style, " .. 17 .. " categories)")
