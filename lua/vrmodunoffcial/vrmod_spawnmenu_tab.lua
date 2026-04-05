-- vrmod_spawnmenu_tab.lua
-- GMod Spawnmenu (Q Menu) tab for VRMod
-- Reads VRMOD_SETTINGS02_REGISTRY to mirror Settings02 content.

if SERVER then return end

-- ============================================================
-- Hook 1: Register the top-level "VRMod" tab
-- ============================================================
hook.Add("AddToolMenuTabs", "VRMod_SpawnMenu_AddTab", function()
	spawnmenu.AddToolTab("VRMod", "VRMod", "icon16/controller.png")
end)

-- ============================================================
-- Helper: Build CPanel from registry items
-- ============================================================
local function BuildRegistryPanel(panel, catDef)
	panel:ClearControls()

	for _, item in ipairs(catDef.items) do
		if item.type == "checkbox" then
			local cb = panel:CheckBox(item.label, item.cvar)

		elseif item.type == "slider" then
			panel:NumSlider(item.label, item.cvar, item.min or 0, item.max or 100, item.decimals or 0)

		elseif item.type == "text" then
			panel:TextEntry(item.label, item.cvar)

		elseif item.type == "combo" then
			local combo, label = panel:ComboBox(item.label, item.cvar)
			if combo and item.options then
				for _, opt in ipairs(item.options) do
					combo:AddChoice(opt.label, opt.value)
				end
			end

		elseif item.type == "button" then
			local btn = panel:Button(item.label)
			if btn and item.command then
				btn.DoClick = function()
					RunConsoleCommand(item.command)
				end
			end

		elseif item.type == "help" then
			panel:Help(item.text)

		elseif item.type == "section" then
			local lbl = panel:Help("=== " .. item.text .. " ===")
			if IsValid(lbl) then
				lbl:SetFont("DermaDefaultBold")
			end
		end
	end
end

-- ============================================================
-- Hook 2: Populate categories from Settings02 registry
-- ============================================================
hook.Add("PopulateToolMenu", "VRMod_SpawnMenu_Populate", function()

	-- Registry-based categories (mirrors Settings02)
	if VRMOD_SETTINGS02_REGISTRY then
		for _, catDef in ipairs(VRMOD_SETTINGS02_REGISTRY) do
			spawnmenu.AddToolMenuOption("VRMod", "VRMod",
				"vrmod_spawnmenu_" .. catDef.key,
				catDef.label, "", "",
				function(panel)
					BuildRegistryPanel(panel, catDef)
				end)
		end
	end

	-- Standalone: Cardboard (not in Settings02 registry)
	spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_cardboard", "Cardboard", "", "", function(panel)
		panel:ClearControls()
		panel:Help("Cardboard VR mode (phone sensor emulation)")
		local btnStart = panel:Button("Start Cardboard VR")
		btnStart.DoClick = function() RunConsoleCommand("cardboardmod_start") end
		local btnExit = panel:Button("Exit Cardboard VR")
		btnExit.DoClick = function() RunConsoleCommand("cardboardmod_exit") end
	end)

	-- Standalone: Utility (quick actions)
	spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_utility", "Utility", "", "", function(panel)
		panel:ClearControls()
		local btnMenu = panel:Button("Open VRMod Menu")
		btnMenu.DoClick = function() RunConsoleCommand("vrmod") end
		local btnStart = panel:Button("Start VR")
		btnStart.DoClick = function() RunConsoleCommand("vrmod_start") end
		local btnExit = panel:Button("Exit VR")
		btnExit.DoClick = function() RunConsoleCommand("vrmod_exit") end
		local btnScr = panel:Button("Auto-Detect Resolution")
		btnScr.DoClick = function() RunConsoleCommand("vrmod_Scr_Auto") end
		local btnVgui = panel:Button("Reset VGUI Panels")
		btnVgui.DoClick = function() RunConsoleCommand("vrmod_vgui_reset") end
		local btnReset = panel:Button("Reset All Settings")
		btnReset.DoClick = function() if VRModResetAll then VRModResetAll() end end
	end)

end)

local catCount = VRMOD_SETTINGS02_REGISTRY and #VRMOD_SETTINGS02_REGISTRY or 0
print("[VRMod] Spawnmenu tab registered (" .. catCount .. " registry + 2 standalone)")
