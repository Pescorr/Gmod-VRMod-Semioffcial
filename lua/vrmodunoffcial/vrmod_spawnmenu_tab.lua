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
-- Helper: Localization wrapper (safe if VRModL not loaded yet)
-- ============================================================
local L = VRModL or function(_, fb) return fb or "" end

-- ============================================================
-- Helper: Build CPanel from registry items
-- ============================================================
local function BuildRegistryPanel(panel, catDef)
	panel:ClearControls()

	for _, item in ipairs(catDef.items) do
		if item.type == "checkbox" then
			local cb = panel:CheckBox(L(item.label, item.label), item.cvar)

		elseif item.type == "slider" then
			panel:NumSlider(L(item.label, item.label), item.cvar, item.min or 0, item.max or 100, item.decimals or 0)

		elseif item.type == "text" then
			panel:TextEntry(L(item.label, item.label), item.cvar)

		elseif item.type == "combo" then
			local combo, label = panel:ComboBox(L(item.label, item.label), item.cvar)
			if combo and item.options then
				for _, opt in ipairs(item.options) do
					combo:AddChoice(L(opt.label, opt.label), opt.value)
				end
			end

		elseif item.type == "button" then
			local btn = panel:Button(L(item.label, item.label))
			if btn and item.command then
				btn.DoClick = function()
					RunConsoleCommand(item.command)
				end
			end

		elseif item.type == "help" then
			panel:Help(L(item.text, item.text))

		elseif item.type == "section" then
			local lbl = panel:Help("=== " .. L(item.text, item.text) .. " ===")
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
				L(catDef.label, catDef.label), "", "",
				function(panel)
					BuildRegistryPanel(panel, catDef)
				end)
		end
	end

	-- Standalone: Cardboard (not in Settings02 registry)
	spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_cardboard", L("Cardboard", "Cardboard"), "", "", function(panel)
		panel:ClearControls()
		panel:Help(L("Cardboard VR mode (phone sensor emulation)", "Cardboard VR mode (phone sensor emulation)"))
		local btnStart = panel:Button(L("Start Cardboard VR", "Start Cardboard VR"))
		btnStart.DoClick = function() RunConsoleCommand("cardboardmod_start") end
		local btnExit = panel:Button(L("Exit Cardboard VR", "Exit Cardboard VR"))
		btnExit.DoClick = function() RunConsoleCommand("cardboardmod_exit") end
	end)

	-- Standalone: Utility (quick actions)
	spawnmenu.AddToolMenuOption("VRMod", "VRMod", "vrmod_spawnmenu_utility", L("Utility", "Utility"), "", "", function(panel)
		panel:ClearControls()
		local btnMenu = panel:Button(L("Open VRMod Menu", "Open VRMod Menu"))
		btnMenu.DoClick = function() RunConsoleCommand("vrmod") end
		local btnStart = panel:Button(L("Start VR", "Start VR"))
		btnStart.DoClick = function() RunConsoleCommand("vrmod_start") end
		local btnExit = panel:Button(L("Exit VR", "Exit VR"))
		btnExit.DoClick = function() RunConsoleCommand("vrmod_exit") end
		local btnScr = panel:Button(L("Auto-Detect Resolution", "Auto-Detect Resolution"))
		btnScr.DoClick = function() RunConsoleCommand("vrmod_Scr_Auto") end
		local btnVgui = panel:Button(L("Reset VGUI Panels", "Reset VGUI Panels"))
		btnVgui.DoClick = function() RunConsoleCommand("vrmod_vgui_reset") end
		local btnReset = panel:Button(L("Reset All Settings", "Reset All Settings"))
		btnReset.DoClick = function() if VRModResetAll then VRModResetAll() end end
	end)

end)

local catCount = VRMOD_SETTINGS02_REGISTRY and #VRMOD_SETTINGS02_REGISTRY or 0
print("[VRMod] Spawnmenu tab registered (" .. catCount .. " registry + 2 standalone)")
