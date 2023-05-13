if SERVER then return end

surface.CreateFont( "vrmod_Trebuchet24", {
	font = "Trebuchet MS",
	size = 24,
	weight = 100
} )

local menushutdown = CreateClientConVar("vrmod_open_menu_shutdown","0",true,FCVAR_ARCHIVE)
local menumcore = CreateClientConVar("vrmod_open_menu_automcore","1",true,FCVAR_ARCHIVE)
local contexticon = CreateClientConVar("vrmod_enable_contextmenu_button","1",true,FCVAR_ARCHIVE)


local frame = nil

local function OpenMenu()

	if menushutdown:GetBool() then
		LocalPlayer():ConCommand("vrmod_exit")
	end

	if menumcore:GetBool() then
		LocalPlayer():ConCommand("gmod_mcore_test 0")
	end


	
	if IsValid(frame) then return frame end

	frame = vgui.Create("DFrame")
	frame:SetSize(400,485)
	frame:SetTitle("VRMod Menu")
	frame:MakePopup()
	frame:Center()
	
	local error = vrmod.GetStartupError()
	
	if error and error ~= "Already running" then
		local tmp = vgui.Create("DLabel", frame)
		tmp:SetText(error)
		tmp:SetWrap(true)
		tmp:SetSize(250,100)
		tmp:SetAutoStretchVertical(true)
		tmp:SetFont("vrmod_Trebuchet24") --default Trebuchet24 causes this text to not show up on some systems for some reason (even though it works elsewhere...)
		function tmp:PerformLayout()
			tmp:Center()
		end
		return frame
	end

	local sheet = vgui.Create( "DPropertySheet", frame )
	sheet:SetPadding(1)
	sheet:Dock( FILL )
	frame.DPropertySheet = sheet
	
	local panel1 = vgui.Create( "DPanel", sheet )
	sheet:AddSheet( "Settings", panel1 )

	local scrollPanel = vgui.Create("DScrollPanel", panel1)
	scrollPanel:Dock( FILL )
	
	local form = vgui.Create("DForm",scrollPanel)
	form:SetName("Settings")
	form:Dock(TOP)
	form.Header:SetVisible(false)
	form.Paint = function(self,w,h) end
	frame.SettingsForm = form
	
	local panel = vgui.Create( "DPanel", frame )
	panel:Dock(BOTTOM)
	panel:SetTall(35)
	panel.Paint = function(self,w,h) end
	
	local tmp = vgui.Create("DLabel", panel)
	if vrmod.GetModuleVersion() == 0 then
		tmp:SetText("Addon version: "..vrmod.GetVersion().."semioffcial".."\n!!!!Module ERROR!!!!")
		tmp:SizeToContents()
		tmp:SetPos(5,5)
	else
		tmp:SetText("Addon version: "..vrmod.GetVersion().."semioffcial".."\nModule version: "..vrmod.GetModuleVersion())
		tmp:SizeToContents()
		tmp:SetPos(5,5)
	end
	local tmp = vgui.Create("DButton", panel)
	tmp:SetText("Exit")
	tmp:Dock( RIGHT )
	tmp:DockMargin(0,5,0,0)
	tmp:SetWide(96)
	tmp:SetEnabled(g_VR.active)
	function tmp:DoClick()
		frame:Remove()
		VRUtilClientExit()
	end
	
	local tmp = vgui.Create("DButton", panel)
	tmp:SetText(g_VR.active and "Restart" or "Start")
	tmp:Dock( RIGHT )
	tmp:DockMargin(0,5,5,0)
	tmp:SetWide(96)
	function tmp:DoClick()
		frame:Remove()
		if g_VR.active then
			VRUtilClientExit()
			timer.Simple(1,function()
				VRUtilClientStart()
			end)
		else
			VRUtilClientStart()
		end
	end
	
	if not error or error == "Already running" then
		--hook.Call("VRMod_Menu",nil,frame)
		local hooks = hook.GetTable().VRMod_Menu
		local names = {}
		for k,v in pairs(hooks) do
			names[#names+1] = k
		end
		table.sort(names)
		for k,v in ipairs(names) do
			hooks[v](frame)
		end
	end
	
	return frame
end

concommand.Add( "vrmod", function( ply, cmd, args )
	if vgui.CursorVisible() then
		print("vrmod: menu will open when game is unpaused")

	end
	timer.Create("vrmod_open_menu",0.1,0,function()
		if not vgui.CursorVisible() then
			OpenMenu()
			timer.Remove("vrmod_open_menu")
		end
	end)
end )

local convars = vrmod.AddCallbackedConvar("vrmod_showonstartup", nil, "0")

if contexticon:GetBool() then
	list.Set( "DesktopWindows", "vrmod_context", {
		title = "VRMod_Menu",
		icon = "icon16/find.png",
		init		= function()
			LocalPlayer():ConCommand("vrmod")
			LocalPlayer():ConCommand("-menu_context")
		end
	})		
end

hook.Add( "PopulateToolMenu", "vrmod_addspawnmenu", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Virtual Reality", "VRMod SemiOffcial", "VRMod SemiOffcial", "", "", function( panel )
			--DButton Start
				--vrmod_spawnmenu
				local vrmod_spawnmenu = vgui.Create( "DButton", panel ) -- Create the button and parent it to the frame
				vrmod_spawnmenu:SetText( "VRMOD MENU" )					-- Set the text on the button
				vrmod_spawnmenu:SetPos( 20, 30 )					-- Set the position on the frame
				vrmod_spawnmenu:SetSize( 330, 30 )					-- Set the size
				vrmod_spawnmenu.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
					RunConsoleCommand( "vrmod" )			-- Run the console command "say hi" when you click it ( command, args )
					LocalPlayer():ConCommand("-menu")
				end

				vrmod_spawnmenu.DoRightClick = function()
					RunConsoleCommand( "vrmod" )					
					LocalPlayer():ConCommand("-menu")
					LocalPlayer():ConCommand("-menu")
				end
			--DButton end		




	end)
end)


vrmod.AddInGameMenuItem("Settings", 4, 0, function()
	OpenMenu()
	hook.Add("VRMod_OpenQuickMenu","closesettings",function()
		hook.Remove("VRMod_OpenQuickMenu","closesettings")
		if IsValid(frame) then
			frame:Remove()
			frame = nil
			return false
		end
	end)
end)
