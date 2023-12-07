if SERVER then return end
local vrmod_cmd_spawnmenu_open = CreateClientConVar("vrmod_cmd_spawnmenu_open", "+menu")
local vrmod_cmd_spawnmenu_close = CreateClientConVar("vrmod_cmd_spawnmenu_close", "-menu")
local vrmod_cmd_contextmenu_open = CreateClientConVar("vrmod_cmd_contextmenu_open", "+menu_context")
local vrmod_cmd_contextmenu_close = CreateClientConVar("vrmod_cmd_contextmenu_close", "-menu_context")
local vr_mapbrowser_enable = CreateClientConVar("vrmod_quickmenu_mapbrowser_enable", "1")
local shutdownbutton = CreateClientConVar("vrmod_quickmenu_exit", 1)
local seated_menu = CreateClientConVar("vrmod_quickmenu_seated_menu", 1)
local vguireset = CreateClientConVar("vrmod_quickmenu_vgui_reset_menu", 1)
local vre_gbradial_menu = CreateClientConVar("vrmod_quickmenu_vre_gbradial_menu", 1)
local vrmod_quickmenu_chat = CreateClientConVar("vrmod_quickmenu_chat", 1)

local button1on = 0
vrmod.AddInGameMenuItem(
	"Spawn Menu",
	2,
	0,
	function()
		if not IsValid(g_SpawnMenu) then return end
		LocalPlayer():ConCommand(vrmod_cmd_spawnmenu_open:GetString())
		hook.Add(
			"VRMod_OpenQuickMenu",
			"close_spawnmenu",
			function()
				hook.Remove("VRMod_OpenQuickMenu", "close_spawnmenu")
				g_SpawnMenu:Close()
				LocalPlayer():ConCommand(vrmod_cmd_spawnmenu_close:GetString())

				return false
			end
		)
	end
)

vrmod.AddInGameMenuItem(
	"Context Menu",
	3,
	0,
	function()
		if not IsValid(g_ContextMenu) then return end
		LocalPlayer():ConCommand(vrmod_cmd_contextmenu_open:GetString())
		hook.Add(
			"VRMod_OpenQuickMenu",
			"closecontextmenu",
			function()
				hook.Remove("VRMod_OpenQuickMenu", "closecontextmenu")
				g_ContextMenu:Close()
				LocalPlayer():ConCommand(vrmod_cmd_contextmenu_close:GetString())

				return false
			end
		)
	end
)

if seated_menu:GetBool() then
	vrmod.AddInGameMenuItem(
		"seated mode",
		1,
		2,
		function()
			if button1on == 1 then
				button1on = 0
				LocalPlayer():ConCommand("vrmod_seated 1")
			else
				button1on = 1
				LocalPlayer():ConCommand("vrmod_seated 0")
			end
		end
	)
else
	vrmod.RemoveInGameMenuItem("seated mode")
end

if vre_gbradial_menu:GetBool() then
	vrmod.AddInGameMenuItem(
		"VRE addmenu",
		0,
		2,
		function()
			LocalPlayer():ConCommand("vre_addvrmenu")
		end
	)
else
	vrmod.RemoveInGameMenuItem("VRE addmenu")
end

--add button start
if vre_gbradial_menu:GetBool() then
	vrmod.AddInGameMenuItem(
		"vre gb-radial",
		0,
		3,
		function()
			LocalPlayer():ConCommand("vre_gb-radial")
		end
	)
else
	vrmod.RemoveInGameMenuItem("vre gb-radial")
end

--add button start
if vr_mapbrowser_enable:GetBool() then
	vrmod.AddInGameMenuItem(
		"Map Browser",
		0,
		0,
		function()
			LocalPlayer():ConCommand("vrmod_mapbrowser")
		end
	)
else
	vrmod.RemoveInGameMenuItem("Map Browser")
end

if shutdownbutton:GetBool() then
	vrmod.AddInGameMenuItem(
		"VR EXIT",
		0,
		0,
		function()
			LocalPlayer():ConCommand("vrmod_exit")
		end
	)
else
	vrmod.RemoveInGameMenuItem("VR EXIT")
end

if vguireset:GetBool() then
	vrmod.AddInGameMenuItem(
		"UI RESET",
		0,
		0,
		function()
			LocalPlayer():ConCommand("vrmod_vgui_reset")
		end
	)
else
	vrmod.RemoveInGameMenuItem("UI RESET")
end

if vrmod_quickmenu_chat:GetBool() then
	vrmod.AddInGameMenuItem(
		"chat",
		1,
		0,
		function()
			LocalPlayer():ConCommand("vrmod_chatmode")
		end
	)
else
	vrmod.RemoveInGameMenuItem("chat")
end



hook.Add(
	"VRMod_Exit",
	"restore_spawnmenu",
	function(ply)
		if ply ~= LocalPlayer() then return end
		timer.Simple(
			0.1,
			function()
				if IsValid(g_SpawnMenu) and g_SpawnMenu.HorizontalDivider ~= nil then
					g_SpawnMenu.HorizontalDivider:SetLeftWidth(ScrW())
				end
			end
		)
	end
)