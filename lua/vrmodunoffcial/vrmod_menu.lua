if SERVER then return end
surface.CreateFont(
	"vrmod_Trebuchet24",
	{
		font = "Trebuchet MS",
		size = 24,
		weight = 100
	}
)

local contexticon = CreateClientConVar("vrmod_enable_contextmenu_button", 1, true, FCVAR_ARCHIVE)
local autoscrsetting = CreateClientConVar("vrmod_scr_alwaysautosetting", 1, true, FCVAR_ARCHIVE)
local autooptimize = CreateClientConVar("vrmod_gmod_optimization_auto", 1, true, FCVAR_ARCHIVE)
local vrautobenchgun = CreateClientConVar("vrmod_auto_arc_benchgun", 1, true, FCVAR_ARCHIVE)
local lvsautosetting = CreateClientConVar("vrmod_auto_lvs_keysetings", 1, true, FCVAR_ARCHIVE)
-- local vrautogunsetting = CreateClientConVar("vrmod_auto_normalgunsetting", "1", true, FCVAR_ARCHIVE)
local frame = nil
local function OpenMenu()
	-- if vrautogunsetting:GetBool() then
	-- 	LocalPlayer():ConCommand("vrmod_normalgunsetting")	
	-- end
	if vrautobenchgun:GetBool() and g_VR.active then
		LocalPlayer():ConCommand("arc9_dev_benchgun 1")
		LocalPlayer():ConCommand("arc9_tpik 0")
	end

	if lvsautosetting:GetBool() and g_VR.active then
		LocalPlayer():ConCommand("vrmod_lfsmode")
	end

	if autoscrsetting:GetBool() then
		LocalPlayer():ConCommand("vrmod_Scr_Auto")
	end

	-- if autooptimize:GetBool() then
	-- 	LocalPlayer():ConCommand("vrmod_gmod_optimization")
	-- end
	if IsValid(frame) then return frame end
	frame = vgui.Create("DFrame")
	frame:SetSize(550, 600)
	frame:SetTitle("VRMod Menu")
	frame:MakePopup()
	frame:Center()
	local error = vrmod.GetStartupError()
	if error and error ~= "Already running" then
		local tmp = vgui.Create("DLabel", frame)
		tmp:SetText(error)
		tmp:SetWrap(true)
		tmp:SetSize(250, 100)
		tmp:SetAutoStretchVertical(true)
		tmp:SetFont("vrmod_Trebuchet24") --default Trebuchet24 causes this text to not show up on some systems for some reason (even though it works elsewhere...)
		function tmp:PerformLayout()
			tmp:Center()
		end

		return frame
	end

	local sheet = vgui.Create("DPropertySheet", frame)
	sheet:SetPadding(4)
	sheet:Dock(FILL)
	frame.DPropertySheet = sheet
	local panel1 = vgui.Create("DPanel", sheet)
	sheet:AddSheet("Settings", panel1)
	local scrollPanel = vgui.Create("DScrollPanel", panel1)
	scrollPanel:Dock(FILL)
	local form = vgui.Create("DForm", scrollPanel)
	form:SetName("Settings")
	form:Dock(TOP)
	form.Header:SetVisible(false)
	form.Paint = function(self, w, h) end
	frame.SettingsForm = form
	local panel = vgui.Create("DPanel", frame)
	panel:Dock(BOTTOM)
	panel:SetTall(35)
	panel.Paint = function(self, w, h) end
	local tmp = vgui.Create("DLabel", panel)
	if vrmod.GetModuleVersion() == 0 then
		tmp:SetText("Addon version: " .. vrmod.GetVersion() .. "semioffcial" .. "\n!!!!Module ERROR!!!!")
		tmp:SizeToContents()
		tmp:SetPos(5, 5)
	else
		tmp:SetText("Addon version: " .. vrmod.GetVersion() .. "semioffcial" .. "\nModule version: ")
		tmp:SizeToContents()
		tmp:SetPos(5, 5)
	end

	local tmp = vgui.Create("DButton", panel)
	tmp:SetText("Exit")
	tmp:Dock(RIGHT)
	tmp:DockMargin(0, 5, 5, 0)
	tmp:SetWide(96)
	tmp:SetEnabled(g_VR.active)
	function tmp:DoClick()
		frame:Remove()
		VRUtilClientExit()
	end

	local tmp = vgui.Create("DButton", panel)
	tmp:SetText(g_VR.active and "Restart" or "Start")
	tmp:Dock(RIGHT)
	tmp:DockMargin(0, 5, 5, 0)
	tmp:SetWide(96)
	function tmp:DoClick()
		frame:Remove()
		if g_VR.active then
			VRUtilClientExit()
			timer.Simple(
				1,
				function()
					VRUtilClientStart()
				end
			)
		else
			VRUtilClientStart()
		end
	end

	if not error or error == "Already running" then
		--hook.Call("VRMod_Menu",nil,frame)
		local hooks = hook.GetTable().VRMod_Menu
		local names = {}
		for k, v in pairs(hooks) do
			names[#names + 1] = k
		end

		table.sort(names)
		for k, v in ipairs(names) do
			hooks[v](frame)
		end
	end

	return frame
end

concommand.Add(
	"vrmod",
	function(ply, cmd, args)
		timer.Create(
			"vrmod_open_menu",
			0.1,
			0,
			function()
				if not vgui.CursorVisible() then
					OpenMenu()
					timer.Remove("vrmod_open_menu")
				end
			end
		)
	end
)

local convars = vrmod.AddCallbackedConvar("vrmod_showonstartup", nil, "0", FCVAR_ARCHIVE) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
if contexticon:GetBool() then
	list.Set(
		"DesktopWindows",
		"vrmod_context",
		{
			title = "VRMod_Menu",
			icon = "icon16/find.png",
			init = function()
				LocalPlayer():ConCommand("vrmod")
				LocalPlayer():ConCommand("-menu_context")
			end
		}
	)
end

if convars.vrmod_showonstartup:GetBool() then
	hook.Add(
		"CreateMove",
		"vrmod_showonstartup",
		function()
			hook.Remove("CreateMove", "vrmod_showonstartup")
			timer.Simple(
				1,
				function()
					RunConsoleCommand("vrmod")
				end
			)
		end
	)
end

hook.Add(
	"PopulateToolMenu",
	"vrmod_addspawnmenu",
	function()
		spawnmenu.AddToolMenuOption(
			"Utilities",
			"Virtual Reality",
			"VRMod SemiOffcial",
			"VRMod SemiOffcial",
			"",
			"",
			function(panel)
				--DButton Start
				--vrmod_spawnmenu
				local vrmod_spawnmenu = vgui.Create("DButton", panel) -- Create the button and parent it to the frame
				vrmod_spawnmenu:SetText("VRMOD MENU") -- Set the text on the button
				vrmod_spawnmenu:SetPos(20, 30) -- Set the position on the frame
				vrmod_spawnmenu:SetSize(330, 30) -- Set the size
				-- A custom function run when clicked ( note the . instead of : )
				vrmod_spawnmenu.DoClick = function()
					RunConsoleCommand("vrmod") -- Run the console command "say hi" when you click it ( command, args )
					LocalPlayer():ConCommand("-menu")
				end

				vrmod_spawnmenu.DoRightClick = function()
					RunConsoleCommand("vrmod")
					LocalPlayer():ConCommand("-menu")
				end
			end
		)
	end
)

--DButton end		
vrmod.AddInGameMenuItem(
	"Settings",
	4,
	0,
	function()
		OpenMenu()
		hook.Add(
			"VRMod_OpenQuickMenu",
			"closesettings",
			function()
				hook.Remove("VRMod_OpenQuickMenu", "closesettings")
				if IsValid(frame) then
					frame:Remove()
					frame = nil

					return false
				end
			end
		)
	end
)