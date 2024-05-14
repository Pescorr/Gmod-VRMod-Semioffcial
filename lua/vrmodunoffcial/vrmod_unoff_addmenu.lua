if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
	"VRMod_Menu",
	"addsettings",
	function(frame)
		--Settings02 Start
		--add VRMod_Menu Settings02 propertysheet start
		local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
		frame.DPropertySheet:AddSheet("Settings02", sheet)
		sheet:Dock(FILL)
		--add VRMod_Menu Settings02 propertysheet end
		--MenuTab01  Start
		local MenuTab01 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("FPS", MenuTab01, "icon16/cog_add.png")
		MenuTab01.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DCheckBoxLabel Start
		local r_3dsky = MenuTab01:Add("DCheckBoxLabel") -- Create the checkbox
		r_3dsky:SetPos(20, 10) -- Set the position
		r_3dsky:SetText("Skybox Enable(Client)") -- Set the text next to the box
		r_3dsky:SetConVar("r_3dsky") -- Change a ConVar when the box it ticked/unticked
		r_3dsky:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local r_shadows = MenuTab01:Add("DCheckBoxLabel") -- Create the checkbox
		r_shadows:SetPos(20, 30) -- Set the position
		r_shadows:SetText("Shadows&FlashLights Effect Enable(Client)") -- Set the text next to the box
		r_shadows:SetConVar("r_shadows") -- Change a ConVar when the box it ticked/unticked
		r_shadows:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--vr_r_farz
		local r_farz = vgui.Create("DNumSlider", MenuTab01)
		r_farz:SetPos(20, 50) -- Set the position (X,Y)
		r_farz:SetSize(370, 25) -- Set the size (X,Y)
		r_farz:SetText("[Visible range of map] \n (sv_cheats 1 is required)") -- Set the text above the slider
		r_farz:SetMin(-1) -- Set the minimum number you can slide to
		r_farz:SetMax(16384) -- Set the maximum number you can slide to
		r_farz:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		r_farz:SetConVar("r_farz") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		r_farz.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--mat_queue_mode
		local mat_queue_mode = vgui.Create("DNumSlider", MenuTab01)
		mat_queue_mode:SetPos(20, 80) -- Set the position (X,Y)
		mat_queue_mode:SetSize(370, 120) -- Set the size (X,Y)
		mat_queue_mode:SetText("[mat_queue_mode]\n(Blindness Warning!!!)\nSetting to [2] will\nenable the multi-core \nand increase FPS\nbut it will also make your right eye\nblink more intensely, which\nwill hurt your eyes.\n[1] is recommended.") -- Set the text above the slider
		mat_queue_mode:SetMin(-1) -- Set the minimum number you can slide to
		mat_queue_mode:SetMax(2) -- Set the maximum number you can slide to
		mat_queue_mode:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		mat_queue_mode:SetConVar("mat_queue_mode") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		mat_queue_mode.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--mat_queue_mode
		local gmod_mcore_test = vgui.Create("DNumSlider", MenuTab01)
		gmod_mcore_test:SetPos(20, 180) -- Set the position (X,Y)
		gmod_mcore_test:SetSize(370, 90) -- Set the size (X,Y)
		gmod_mcore_test:SetText("[gmod_mcore_test]") -- Set the text above the slider
		gmod_mcore_test:SetMin(-1) -- Set the minimum number you can slide to
		gmod_mcore_test:SetMax(1) -- Set the maximum number you can slide to
		gmod_mcore_test:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		gmod_mcore_test:SetConVar("gmod_mcore_test") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		gmod_mcore_test.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DButton end
		--DCheckBoxLabel Start
		local vrmod_open_menu_auto_optimization = MenuTab01:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_open_menu_auto_optimization:SetPos(20, 250) -- Set the position
		vrmod_open_menu_auto_optimization:SetText("[VRMenu Open -> Auto Basic Optimization]") -- Set the text next to the box
		vrmod_open_menu_auto_optimization:SetConVar("vrmod_gmod_optimization_auto") -- Change a ConVar when the box it ticked/unticked
		vrmod_open_menu_auto_optimization:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--MenuTab01  end
		--DButton Start
		--gmod_optimization
		local gmod_optimization = vgui.Create("DButton", MenuTab01) -- Create the button and parent it to the frame
		gmod_optimization:SetText("vrmod_gmod_optimization\n(Basic)") -- Set the text on the button
		gmod_optimization:SetPos(20, 270) -- Set the position on the frame
		gmod_optimization:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		gmod_optimization.DoClick = function()
			RunConsoleCommand("vrmod_gmod_optimization") -- Run the console command "say hi" when you click it ( command, args )
		end

		gmod_optimization.DoRightClick = function()
			RunConsoleCommand("remove_reflective_glass")
		end

		--DButton Start
		--gmod_optimization
		local gmod_optimization02 = vgui.Create("DButton", MenuTab01) -- Create the button and parent it to the frame
		gmod_optimization02:SetText("vrmod_gmod_optimization\n(buggy but Strong)") -- Set the text on the button
		gmod_optimization02:SetPos(190, 270) -- Set the position on the frame
		gmod_optimization02:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		gmod_optimization02.DoClick = function()
			RunConsoleCommand("vrmod_gmod_optimization_02") -- Run the console command "say hi" when you click it ( command, args )
		end

		gmod_optimization02.DoRightClick = function()
			RunConsoleCommand("vrmod_gmod_optimization_03")
		end

		--FPS_defaultbutton
		local FPS_defaultbutton = vgui.Create("DButton", MenuTab01) -- Create the button and parent it to the frame
		FPS_defaultbutton:SetText("setdefaultvalue\n(Gmod Default)") -- Set the text on the button
		FPS_defaultbutton:SetPos(190, 310) -- Set the position on the frame
		FPS_defaultbutton:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		FPS_defaultbutton.DoClick = function()
			RunConsoleCommand("vrmod_gmod_optimization_reset")
		end

		FPS_defaultbutton.DoRightClick = function()
			RunConsoleCommand("vrmod_gmod_optimization_reset")
		end

		--DButton end
		-- MenuTab02  Start
		local MenuTab02 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("GamePlay", MenuTab02, "icon16/joystick.png")
		MenuTab02.Paint = function(self, w, h) end -- -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DCheckBoxLabel Start
		local autojumpduck = MenuTab02:Add("DCheckBoxLabel") -- Create the checkbox
		autojumpduck:SetPos(20, 10) -- Set the position
		autojumpduck:SetText("[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP") -- Set the text next to the box
		autojumpduck:SetConVar("vrmod_autojumpduck") -- Change a ConVar when the box it ticked/unticked
		autojumpduck:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local allow_teleport_client = MenuTab02:Add("DCheckBoxLabel") -- Create the checkbox
		allow_teleport_client:SetPos(20, 60) -- Set the position
		allow_teleport_client:SetText("Teleport Button Enable(Client)") -- Set the text next to the box
		allow_teleport_client:SetConVar("vrmod_allow_teleport_client") -- Change a ConVar when the box it ticked/unticked
		allow_teleport_client:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--flashlight_attachment
		local flashlight_attachment = vgui.Create("DNumSlider", MenuTab02)
		flashlight_attachment:SetPos(20, 90) -- Set the position (X,Y)
		flashlight_attachment:SetSize(350, 25) -- Set the size (X,Y)
		flashlight_attachment:SetText("[flashlight_attachment]\n0 = Rhand1 = Lhand 2 = HMD") -- Set the text above the slider
		flashlight_attachment:SetMin(0) -- Set the minimum number you can slide to
		flashlight_attachment:SetMax(2) -- Set the maximum number you can slide to
		flashlight_attachment:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		flashlight_attachment:SetConVar("vrmod_flashlight_attachment") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		flashlight_attachment.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DButton Start
		--character_restart
		local togglelaserpointer = vgui.Create("DButton", MenuTab02) -- Create the button and parent it to the frame
		togglelaserpointer:SetText("Toggle Laser Pointer") -- Set the text on the button
		togglelaserpointer:SetPos(20, 130) -- Set the position on the frame
		togglelaserpointer:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		togglelaserpointer.DoClick = function()
			RunConsoleCommand("vrmod_togglelaserpointer") -- Run the console command "say hi" when you click it ( command, args )
		end

		togglelaserpointer.DoRightClick = function() end
		--DButton end
		--DButton Start
		--character_restart
		local vrmod_weaponconfig = vgui.Create("DButton", MenuTab02) -- Create the button and parent it to the frame
		vrmod_weaponconfig:SetText("Weapon Viewmodel Setting") -- Set the text on the button
		vrmod_weaponconfig:SetPos(190, 130) -- Set the position on the frame
		vrmod_weaponconfig:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		vrmod_weaponconfig.DoClick = function()
			RunConsoleCommand("vrmod_weaponconfig") -- Run the console command "say hi" when you click it ( command, args )
		end

		togglelaserpointer.DoRightClick = function() end
		--DButton end
		--DCheckBoxLabel Start
		local pickup_disable_client = MenuTab02:Add("DCheckBoxLabel") -- Create the checkbox
		pickup_disable_client:SetPos(20, 175) -- Set the position
		pickup_disable_client:SetText("VR Disable Pickup(Client)") -- Set the text next to the box
		pickup_disable_client:SetConVar("vr_pickup_disable_client") -- Change a ConVar when the box it ticked/unticked
		pickup_disable_client:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--vrmod_pickup_weight
		local pickup_weight = vgui.Create("DNumSlider", MenuTab02)
		pickup_weight:SetPos(20, 200) -- Set the position (X,Y)
		pickup_weight:SetSize(370, 25) -- Set the size (X,Y)
		pickup_weight:SetText("pickup_weight(server)") -- Set the text above the slider
		pickup_weight:SetMin(1) -- Set the minimum number you can slide to
		pickup_weight:SetMax(99999) -- Set the maximum number you can slide to
		pickup_weight:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		pickup_weight:SetConVar("vrmod_pickup_weight") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		pickup_weight.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vr_vrmod_pickup_range
		local vrmod_pickup_range = vgui.Create("DNumSlider", MenuTab02)
		vrmod_pickup_range:SetPos(20, 225) -- Set the position (X,Y)
		vrmod_pickup_range:SetSize(370, 25) -- Set the size (X,Y)
		vrmod_pickup_range:SetText("pickup_range(server)") -- Set the text above the slider
		vrmod_pickup_range:SetMin(0.0) -- Set the minimum number you can slide to
		vrmod_pickup_range:SetMax(10.0) -- Set the maximum number you can slide to
		vrmod_pickup_range:SetDecimals(1) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_pickup_range:SetConVar("vrmod_pickup_range") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_pickup_range.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vr_vrmod_pickup_limit
		local vrmod_pickup_limit = vgui.Create("DNumSlider", MenuTab02)
		vrmod_pickup_limit:SetPos(20, 250) -- Set the position (X,Y)
		vrmod_pickup_limit:SetSize(370, 25) -- Set the size (X,Y)
		vrmod_pickup_limit:SetText("pickup_limit(server)") -- Set the text above the slider
		vrmod_pickup_limit:SetMin(0) -- Set the minimum number you can slide to
		vrmod_pickup_limit:SetMax(3) -- Set the maximum number you can slide to
		vrmod_pickup_limit:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_pickup_limit:SetConVar("vrmod_pickup_limit") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_pickup_limit.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DButton Start
		--GamePlay_defaultbutton
		local GamePlay_defaultbutton = vgui.Create("DButton", MenuTab02) -- Create the button and parent it to the frame
		GamePlay_defaultbutton:SetText("setdefaultvalue") -- Set the text on the button
		GamePlay_defaultbutton:SetPos(190, 310) -- Set the position on the frame
		GamePlay_defaultbutton:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		GamePlay_defaultbutton.DoClick = function()
			RunConsoleCommand("vrmod_allow_teleport_client", "0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vr_pickup_disable_client", "0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_pickup_weight", "100") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_pickup_range", "1.1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_pickup_limit", "1") -- Run the console command "say hi" when you click it ( command, args )
		end

		GamePlay_defaultbutton.DoRightClick = function() end
		--DButton end
		-- MenuTab02  End
		--MenuTab03 "1" Start
		local MenuTab03 = vgui.Create("DPanel", sheet)
		MenuTab03.Paint = function(self, w, h) end -- -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		sheet:AddSheet("Quickmenu", MenuTab03, "icon16/application_view_gallery.png")
		-- DLabel start
		local titleLabel = MenuTab03:Add("DLabel")
		titleLabel:SetText("Quickmenu Visible Button")
		titleLabel:SetPos(20, -3)
		titleLabel:SizeToContents()
		--DLabel end
		--DCheckBoxLabel Start
		local vrmod_mapbrowser = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_mapbrowser:SetPos(20, 15) -- Set the position
		vrmod_mapbrowser:SetText("[Map Browser]") -- Set the text next to the box
		vrmod_mapbrowser:SetConVar("vrmod_quickmenu_mapbrowser_enable") -- Change a ConVar when the box it ticked/unticked
		vrmod_mapbrowser:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_exit = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_exit:SetPos(20, 40) -- Set the position
		vrmod_quickmenu_exit:SetText("[VR EXIT]") -- Set the text next to the box
		vrmod_quickmenu_exit:SetConVar("vrmod_quickmenu_exit") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_exit:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_vgui_reset_menu = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_vgui_reset_menu:SetPos(20, 65) -- Set the position
		vrmod_vgui_reset_menu:SetText("[UI RESET]") -- Set the text next to the box
		vrmod_vgui_reset_menu:SetConVar("vrmod_quickmenu_vgui_reset_menu") -- Change a ConVar when the box it ticked/unticked
		vrmod_vgui_reset_menu:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_vre_gbradial_menu = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_vre_gbradial_menu:SetPos(20, 90) -- Set the position
		vrmod_quickmenu_vre_gbradial_menu:SetText("[VRE gbradial] & [VRE Add menu]") -- Set the text next to the box
		vrmod_quickmenu_vre_gbradial_menu:SetConVar("vrmod_quickmenu_vre_gbradial_menu") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_vre_gbradial_menu:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_chat = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_chat:SetPos(20, 115) -- Set the position
		vrmod_quickmenu_chat:SetText("[Chat]") -- Set the text next to the box
		vrmod_quickmenu_chat:SetConVar("vrmod_quickmenu_chat") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_chat:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_seated_menu = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_seated_menu:SetPos(20, 140) -- Set the position
		vrmod_quickmenu_seated_menu:SetText("[Seated Mode]") -- Set the text next to the box
		vrmod_quickmenu_seated_menu:SetConVar("vrmod_quickmenu_seated_menu") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_seated_menu:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_togglemirror = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_togglemirror:SetPos(20, 165) -- Set the position
		vrmod_quickmenu_togglemirror:SetText("[Toggle Mirror]") -- Set the text next to the box
		vrmod_quickmenu_togglemirror:SetConVar("vrmod_quickmenu_togglemirror") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_togglemirror:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_spawn_menu = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_spawn_menu:SetPos(20, 190) -- Set the position
		vrmod_quickmenu_spawn_menu:SetText("[Spawn Menu]") -- Set the text next to the box
		vrmod_quickmenu_spawn_menu:SetConVar("vrmod_quickmenu_spawn_menu") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_spawn_menu:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_noclip = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_noclip:SetPos(20, 215) -- Set the position
		vrmod_quickmenu_noclip:SetText("[No Clip]") -- Set the text next to the box
		vrmod_quickmenu_noclip:SetConVar("vrmod_quickmenu_noclip") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_noclip:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_context_menu = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_context_menu:SetPos(20, 240) -- Set the position
		vrmod_quickmenu_context_menu:SetText("[Context Menu]") -- Set the text next to the box
		vrmod_quickmenu_context_menu:SetConVar("vrmod_quickmenu_context_menu") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_context_menu:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_arccw = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_arccw:SetPos(20, 265) -- Set the position
		vrmod_quickmenu_arccw:SetText("[ArcCW Customize]") -- Set the text next to the box
		vrmod_quickmenu_arccw:SetConVar("vrmod_quickmenu_arccw") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_arccw:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_quickmenu_vehiclemode = MenuTab03:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_quickmenu_vehiclemode:SetPos(20, 290) -- Set the position
		vrmod_quickmenu_vehiclemode:SetText("[Toggle Vehicle Mode]") -- Set the text next to the box
		vrmod_quickmenu_vehiclemode:SetConVar("vrmod_quickmenu_togglevehiclemode") -- Change a ConVar when the box it ticked/unticked
		vrmod_quickmenu_vehiclemode:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DButton Start
		--character_restart
		local UI_defaultbutton = vgui.Create("DButton", MenuTab03) -- Create the button and parent it to the frame
		UI_defaultbutton:SetText("setdefaultvalue") -- Set the text on the button
		UI_defaultbutton:SetPos(190, 315) -- Set the position on the frame
		UI_defaultbutton:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		UI_defaultbutton.DoClick = function()
			RunConsoleCommand("vrmod_quickmenu_mapbrowser_enable", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_quickmenu_exit", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_quickmenu_vgui_reset_menu", "0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_quickmenu_seated_menu", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_quickmenu_chat", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_quickmenu_vre_gbradial_menu", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_quickmenu_togglevehiclemode", "0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_attach_weaponmenu", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_attach_quickmenu", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_attach_popup", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vre_ui_attachtohand", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_ui_outline", "0") -- Run the console command "say hi" when you click it ( command, args )
		end

		UI_defaultbutton.DoRightClick = function() end
		--DButton end
		--MenuTab03 "1" end
		-- MenuTab04  Start
		local MenuTab04 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("HUD", MenuTab04, "icon16/layers.png")
		MenuTab04.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DCheckBoxLabel Start
		local vrmod_hud = MenuTab04:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_hud:SetPos(20, 10) -- Set the position
		vrmod_hud:SetText("Hud Enable") -- Set the text next to the box
		vrmod_hud:SetConVar("vrmod_hud") -- Change a ConVar when the box it ticked/unticked
		vrmod_hud:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--hudcurve
		local hudcurve = vgui.Create("DNumSlider", MenuTab04)
		hudcurve:SetPos(20, 30) -- Set the position (X,Y)
		hudcurve:SetSize(370, 25) -- Set the size (X,Y)
		hudcurve:SetText("Hud curve") -- Set the text above the slider
		hudcurve:SetMin(1) -- Set the minimum number you can slide to
		hudcurve:SetMax(60) -- Set the maximum number you can slide to
		hudcurve:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		hudcurve:SetConVar("vrmod_hudcurve") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		hudcurve.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--huddistance
		local huddistance = vgui.Create("DNumSlider", MenuTab04)
		huddistance:SetPos(20, 55) -- Set the position (X,Y)
		huddistance:SetSize(370, 25) -- Set the size (X,Y)
		huddistance:SetText("Hud distance") -- Set the text above the slider
		huddistance:SetMin(1) -- Set the minimum number you can slide to
		huddistance:SetMax(60) -- Set the maximum number you can slide to
		huddistance:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		huddistance:SetConVar("vrmod_huddistance") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		huddistance.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--hudscale
		local hudscale = vgui.Create("DNumSlider", MenuTab04)
		hudscale:SetPos(20, 80) -- Set the position (X,Y)
		hudscale:SetSize(370, 25) -- Set the size (X,Y)
		hudscale:SetText("Hud scale") -- Set the text above the slider
		hudscale:SetMin(0.01) -- Set the minimum number you can slide to
		hudscale:SetMax(0.1) -- Set the maximum number you can slide to
		hudscale:SetDecimals(2) -- Decimal places - zero for whole number (set 2 -> 0.00)
		hudscale:SetConVar("vrmod_hudscale") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		hudscale.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--hudtestalpha
		local hudtestalpha = vgui.Create("DNumSlider", MenuTab04)
		hudtestalpha:SetPos(20, 105) -- Set the position (X,Y)
		hudtestalpha:SetSize(370, 25) -- Set the size (X,Y)
		hudtestalpha:SetText("Hud alpha Transparency") -- Set the text above the slider
		hudtestalpha:SetMin(0) -- Set the minimum number you can slide to
		hudtestalpha:SetMax(255) -- Set the maximum number you can slide to
		hudtestalpha:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		hudtestalpha:SetConVar("vrmod_hudtestalpha") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		hudtestalpha.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DCheckBoxLabel Start
		local vrmod_test_ui_testver = MenuTab04:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_test_ui_testver:SetPos(20, 135) -- Set the position
		vrmod_test_ui_testver:SetText("vrmod_test_ui_testver") -- Set the text next to the box
		vrmod_test_ui_testver:SetConVar("vrmod_test_ui_testver") -- Change a ConVar when the box it ticked/unticked
		vrmod_test_ui_testver:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_hud_visible_quickmenukey = MenuTab04:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_hud_visible_quickmenukey:SetPos(20, 165) -- Set the position
		vrmod_hud_visible_quickmenukey:SetText("HUD only while pressing menu key") -- Set the text next to the box
		vrmod_hud_visible_quickmenukey:SetConVar("vrmod_hud_visible_quickmenukey") -- Change a ConVar when the box it ticked/unticked
		vrmod_hud_visible_quickmenukey:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel 
		--vrmod_attach_quickmenu
		local attach_quickmenu = vgui.Create("DComboBox", MenuTab04)
		attach_quickmenu:SetPos(20, 215) -- Set the position (X,Y)
		attach_quickmenu:SetSize(320, 25) -- Set the size (X,Y)
		attach_quickmenu:SetText("[quickmenu Attach Position]") -- Set the text above the slider
		attach_quickmenu:AddChoice("left hand")
		attach_quickmenu:AddChoice("ʄ(buggy)")
		attach_quickmenu:AddChoice("HMD")
		attach_quickmenu:AddChoice("Right Static")
		attach_quickmenu.OnSelect = function(self, index, value)
			LocalPlayer():ConCommand("vrmod_attach_quickmenu " .. index)
		end

		--DNumSlider end
		--vrmod_attach_weaponmenu
		local attach_weaponmenu = vgui.Create("DComboBox", MenuTab04)
		attach_weaponmenu:SetPos(20, 245) -- Set the position (X,Y)
		attach_weaponmenu:SetSize(320, 25) -- Set the size (X,Y)
		attach_weaponmenu:SetText("[weaponmenu Attach Position]") -- Set the text above the slider
		attach_weaponmenu:AddChoice("left hand")
		attach_weaponmenu:AddChoice("ʄ(buggy)")
		attach_weaponmenu:AddChoice("HMD")
		attach_weaponmenu:AddChoice("Right Static")
		attach_weaponmenu.OnSelect = function(self, index, value)
			LocalPlayer():ConCommand("vrmod_attach_weaponmenu " .. index)
		end

		--DNumSlider end
		--vrmod_attach_popup
		local attach_popup = vgui.Create("DComboBox", MenuTab04)
		attach_popup:SetPos(20, 275) -- Set the position (X,Y)
		attach_popup:SetSize(320, 25) -- Set the size (X,Y)
		attach_popup:SetText("[popup Window Attach Position]") -- Set the text above the slider
		attach_popup:AddChoice("left hand")
		attach_popup:AddChoice("ʄ(buggy)")
		attach_popup:AddChoice("HMD")
		attach_popup:AddChoice("Right Static")
		attach_popup.OnSelect = function(self, index, value)
			LocalPlayer():ConCommand("vrmod_attach_popup " .. index)
		end

		--DNumSlider end
		--DCheckBoxLabel Start
		local vremenu_attach = MenuTab04:Add("DCheckBoxLabel") -- Create the checkbox
		vremenu_attach:SetPos(20, 310) -- Set the position
		vremenu_attach:SetText("[VRE UI LeftHand]") -- Set the text next to the box
		vremenu_attach:SetConVar("vre_ui_attachtohand") -- Change a ConVar when the box it ticked/unticked
		vremenu_attach:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local vrmod_ui_outline = MenuTab04:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_ui_outline:SetPos(20, 335) -- Set the position
		vrmod_ui_outline:SetText("[Menu&UI Red outline]") -- Set the text next to the box
		vrmod_ui_outline:SetConVar("vrmod_ui_outline") -- Change a ConVar when the box it ticked/unticked
		vrmod_ui_outline:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		-- --DLabel&DTextEntry Start
		-- local vrmod_hudblacklist = MenuTab04:Add("DLabel")
		-- vrmod_hudblacklist:SetPos(10, 330) -- Set the position of the label
		-- vrmod_hudblacklist:SetText("vrmod_hudblacklist") --  Set the text of the label
		-- vrmod_hudblacklist:SizeToContents() -- Size the label to fit the text in it
		-- vrmod_hudblacklist:SetDark(0) -- Set the colour of the text inside the label to a darker one
		-- local vrmod_hudblacklist = MenuTab04:Add("DTextEntry")
		-- vrmod_hudblacklist_String = GetConVar("vrmod_hudblacklist"):GetString()
		-- vrmod_hudblacklist:SetPos(20, 275) -- Set the position
		-- vrmod_hudblacklist:SetSize(330, 25) -- Set the size (X,Y)
		-- vrmod_hudblacklist:SetUpdateOnType(0) -- Set the position
		-- vrmod_hudblacklist:SetValue(vrmod_hudblacklist_String)
		-- vrmod_hudblacklist.OnEnter = function(self)
		-- 	vrmod_hudblacklist:UpdateConvarValue("vrmod_hudblacklist") -- Change a ConVar when the box it ticked/unticked
		-- end
		--DLabel&DTextEntry end
		--DButton Start
		--HUD_defaultbutton
		local HUD_defaultbutton = vgui.Create("DButton", MenuTab04) -- Create the button and parent it to the frame
		HUD_defaultbutton:SetText("setdefaultvalue") -- Set the text on the button
		HUD_defaultbutton:SetPos(190, 310) -- Set the position on the frame
		HUD_defaultbutton:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		HUD_defaultbutton.DoClick = function()
			RunConsoleCommand("vrmod_hud", "1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_hudcurve", "60") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_huddistance", "60") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_hudscale", "0.05") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_hudtestalpha", "0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_test_ui_testver", "0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_hudblacklist", "") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_hud_visible_quickmenukey", "0") -- Run the console command "say hi" when you click it ( command, args )
		end

		HUD_defaultbutton.DoRightClick = function() end
		--DButton end
		-- MenuTab04  End
		--MenuTab05  Start
		local MenuTab05 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Character", MenuTab05, "icon16/user_edit.png")
		MenuTab05.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DNumSlider Start
		--characterEyeHeight
		local characterEyeHeight = vgui.Create("DNumSlider", MenuTab05)
		characterEyeHeight:SetPos(20, 10) -- Set the position (X,Y)
		characterEyeHeight:SetSize(370, 25) -- Set the size (X,Y)
		characterEyeHeight:SetText("characterEyeHeight") -- Set the text above the slider
		characterEyeHeight:SetMin(10.0) -- Set the minimum number you can slide to
		characterEyeHeight:SetMax(100.8) -- Set the maximum number you can slide to
		characterEyeHeight:SetDecimals(1) -- Decimal places - zero for whole number (set 2 -> 0.00)
		characterEyeHeight:SetConVar("vrmod_characterEyeHeight") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		characterEyeHeight.OnValueChanged = function(self, value) end
		--DNumSlider end				
		--DNumSlider Start
		--crouchthreshold
		local crouchthreshold = vgui.Create("DNumSlider", MenuTab05)
		crouchthreshold:SetPos(20, 30) -- Set the position (X,Y)
		crouchthreshold:SetSize(370, 25) -- Set the size (X,Y)
		crouchthreshold:SetText("crouchthreshold") -- Set the text above the slider
		crouchthreshold:SetMin(10.0) -- Set the minimum number you can slide to
		crouchthreshold:SetMax(100.0) -- Set the maximum number you can slide to
		crouchthreshold:SetDecimals(1) -- Decimal places - zero for whole number (set 2 -> 0.00)
		crouchthreshold:SetConVar("vrmod_crouchthreshold") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		crouchthreshold.OnValueChanged = function(self, value) end
		--DNumSlider end				
		--DNumSlider Start
		--characterHeadToHmdDist
		local characterHeadToHmdDist = vgui.Create("DNumSlider", MenuTab05)
		characterHeadToHmdDist:SetPos(20, 50) -- Set the position (X,Y)
		characterHeadToHmdDist:SetSize(370, 25) -- Set the size (X,Y)
		characterHeadToHmdDist:SetText("characterHeadToHmdDist") -- Set the text above the slider
		characterHeadToHmdDist:SetMin(-15.3) -- Set the minimum number you can slide to
		characterHeadToHmdDist:SetMax(15.3) -- Set the maximum number you can slide to
		characterHeadToHmdDist:SetDecimals(2) -- Decimal places - zero for whole number (set 2 -> 0.00)
		characterHeadToHmdDist:SetConVar("vrmod_characterHeadToHmdDist") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		characterHeadToHmdDist.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vr_vrmod_znear
		local vrmod_znear = vgui.Create("DNumSlider", MenuTab05)
		vrmod_znear:SetPos(20, 90) -- Set the position (X,Y)
		vrmod_znear:SetSize(370, 110) -- Set the size (X,Y)
		vrmod_znear:SetText("[znear]\n(VRMod Restart Requied)\nObjects at distances less than\nthis value become transparent\nIf you are using a player model\nwith hair or head parts\nthat appear in front of you\nyou may want to set a larger\nvalue.") -- Set the text above the slider
		vrmod_znear:SetMin(1.00) -- Set the minimum number you can slide to
		vrmod_znear:SetMax(20.00) -- Set the maximum number you can slide to
		vrmod_znear:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_znear:SetConVar("vrmod_znear") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_znear.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DButton Start
		--character_restart
		local character_restart = vgui.Create("DButton", MenuTab05) -- Create the button and parent it to the frame
		character_restart:SetText("Manual Apply \n (VRMod Restart)") -- Set the text on the button
		character_restart:SetPos(190, 220) -- Set the position on the frame
		character_restart:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		character_restart.DoClick = function()
			RunConsoleCommand("vrmod_character_restart") -- Run the console command "say hi" when you click it ( command, args )
		end

		character_restart.DoRightClick = function()
			RunConsoleCommand("vrmod_character_restart") -- Run the console command "say hi" when you click it ( command, args )
		end

		--DButton end
		--DButton Start
		--character_auto
		local character_auto = vgui.Create("DButton", MenuTab05) -- Create the button and parent it to the frame
		character_auto:SetText("AutoAdjest \n (VRMod Restart)") -- Set the text on the button
		character_auto:SetPos(20, 220) -- Set the position on the frame
		character_auto:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		character_auto.DoClick = function()
			RunConsoleCommand("vrmod_character_auto") -- Run the console command "say hi" when you click it ( command, args )							
			timer.Simple(
				2,
				function()
					RunConsoleCommand("vrmod_scale_auto") -- Run the console command "say hi" when you click it ( command, args )					
				end
			)

			timer.Simple(
				1,
				function()
					RunConsoleCommand("vrmod_character_restart") -- Run the console command "say hi" when you click it ( command, args )
				end
			)
		end

		character_auto.DoRightClick = function()
			RunConsoleCommand("vrmod_character_auto") -- Run the console command "say hi" when you click it ( command, args )		
		end

		--DButton end
		--DButton Start
		--character_restart
		local ToggleMirror = vgui.Create("DButton", MenuTab05) -- Create the button and parent it to the frame
		ToggleMirror:SetText("Toggle Mirror") -- Set the text on the button
		ToggleMirror:SetPos(20, 310) -- Set the position on the frame
		ToggleMirror:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		ToggleMirror.DoClick = function()
			if GetConVar("vrmod_heightmenu"):GetBool() then
				VRUtilMenuClose("heightmenu")
				convars.vrmod_heightmenu:SetBool(false)
			else
				VRUtilOpenHeightMenu()
				convars.vrmod_heightmenu:SetBool(true)
			end
		end

		--DButton end
		--DButton Start
		--character_restart
		local character_reset = vgui.Create("DButton", MenuTab05) -- Create the button and parent it to the frame
		character_reset:SetText("setdefaultvalue") -- Set the text on the button
		character_reset:SetPos(190, 310) -- Set the position on the frame
		character_reset:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		character_reset.DoClick = function()
			RunConsoleCommand("vrmod_character_reset") -- Run the console command "say hi" when you click it ( command, args )
		end

		character_reset.DoRightClick = function() end
		--DButton end
		--MenuTab05  end
		--MenuTab06  Start
		local MenuTab06 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Character02", MenuTab06, "icon16/user_edit.png")
		MenuTab06.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DNumSlider Start
		--scale
		local scale = vgui.Create("DLabel", MenuTab06)
		scale:SetPos(20, 5) -- Set the position (X,Y)
		scale:SetText("scale") -- Set the text above the slider					
		-- If not using convars, you can use this hook + Panel.SetValue()
		--DNumSlider end
		--DButton Start
		--scaleplus
		local scaleplus = vgui.Create("DButton", MenuTab06) -- Create the button and parent it to the frame
		scaleplus:SetText("+") -- Set the text on the button
		scaleplus:SetPos(20, 25) -- Set the position on the frame
		scaleplus:SetSize(160, 25) -- Set the size
		scaleplus.DoClick = function()
			g_VR.scale = g_VR.scale + 0.5
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end

		scaleplus.DoRightClick = function()
			g_VR.scale = g_VR.scale + 1.0
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end

		--DButton end
		--DButton Start
		--scalebutton
		local scaleminus = vgui.Create("DButton", MenuTab06) -- Create the button and parent it to the frame
		scaleminus:SetText("-") -- Set the text on the button
		scaleminus:SetPos(190, 25) -- Set the position on the frame
		scaleminus:SetSize(160, 25) -- Set the size
		scaleminus.DoClick = function()
			g_VR.scale = g_VR.scale - 0.5
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end

		scaleminus.DoRightClick = function()
			g_VR.scale = g_VR.scale - 1.0
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end

		--DButton end
		--DCheckBoxLabel Start
		local oldcharacteryaw = MenuTab06:Add("DCheckBoxLabel") -- Create the checkbox
		oldcharacteryaw:SetPos(20, 180) -- Set the position
		oldcharacteryaw:SetText("Alternative Character Yaw") -- Set the text next to the box
		oldcharacteryaw:SetConVar("vrmod_oldcharacteryaw") -- Change a ConVar when the box it ticked/unticked
		-- oldcharacteryaw:SetValue( true )						-- Initial value
		oldcharacteryaw:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local animation_Enable = MenuTab06:Add("DCheckBoxLabel") -- Create the checkbox
		animation_Enable:SetPos(20, 200) -- Set the position
		animation_Enable:SetText("Character_Animation_Enable (Client)") -- Set the text next to the box
		animation_Enable:SetConVar("vrmod_animation_Enable") -- Change a ConVar when the box it ticked/unticked
		animation_Enable:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local seatedmode = MenuTab06:Add("DCheckBoxLabel") -- Create the checkbox
		seatedmode:SetPos(20, 240) -- Set the position
		seatedmode:SetText("Enable seated mode") -- Set the text next to the box
		seatedmode:SetConVar("vrmod_seated") -- Change a ConVar when the box it ticked/unticked
		seatedmode:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--seatedoffset
		local seatedoffset = vgui.Create("DNumSlider", MenuTab06)
		seatedoffset:SetPos(20, 260) -- Set the position (X,Y)
		seatedoffset:SetSize(370, 25) -- Set the size (X,Y)
		seatedoffset:SetText("Seated Offset") -- Set the text above the slider
		seatedoffset:SetMin(-66.80) -- Set the minimum number you can slide to
		seatedoffset:SetMax(66.80) -- Set the maximum number you can slide to
		seatedoffset:SetDecimals(2) -- Decimal places - zero for whole number(set 2 -> 0.00)
		seatedoffset:SetConVar("vrmod_seatedoffset") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		seatedoffset.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DButton Start
		--character_restart
		local ToggleMirror = vgui.Create("DButton", MenuTab06) -- Create the button and parent it to the frame
		ToggleMirror:SetText("Toggle Mirror") -- Set the text on the button
		ToggleMirror:SetPos(20, 310) -- Set the position on the frame
		ToggleMirror:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		ToggleMirror.DoClick = function()
			if GetConVar("vrmod_heightmenu"):GetBool() then
				VRUtilMenuClose("heightmenu")
				convars.vrmod_heightmenu:SetBool(false)
			else
				VRUtilOpenHeightMenu()
				convars.vrmod_heightmenu:SetBool(true)
			end
		end

		--DButton end
		--DButton Start
		--character_restart
		local character_reset = vgui.Create("DButton", MenuTab06) -- Create the button and parent it to the frame
		character_reset:SetText("setdefaultvalue") -- Set the text on the button
		character_reset:SetPos(190, 310) -- Set the position on the frame
		character_reset:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		character_reset.DoClick = function()
			RunConsoleCommand("vrmod_character_reset") -- Run the console command "say hi" when you click it ( command, args )
		end

		character_reset.DoRightClick = function() end
		--DButton end
		--MenuTab06  end
		-- --MenuTab11 (Locomotion) Start
		-- local MenuTab11 = vgui.Create("DPanel", sheet)
		-- sheet:AddSheet("Locomotion", MenuTab11, "icon16/joystick.png")
		-- MenuTab11.Paint = function(self, w, h) end
		-- --DCheckBoxLabel Start
		-- local cv_allowtp = MenuTab11:Add("DCheckBoxLabel")
		-- cv_allowtp:SetPos(20, 10)
		-- cv_allowtp:SetText("Allow teleportation (Server)")
		-- cv_allowtp:SetConVar("vrmod_allow_teleport")
		-- cv_allowtp:SizeToContents()
		-- --DCheckBoxLabel End
		-- --DCheckBoxLabel Start 
		-- local cv_usetp = MenuTab11:Add("DCheckBoxLabel")
		-- cv_usetp:SetPos(20, 40)
		-- cv_usetp:SetText("Use teleportation (Client)")
		-- cv_usetp:SetConVar("vrmod_allow_teleport_client")
		-- cv_usetp:SizeToContents()
		-- --DCheckBoxLabel End
		-- --DComboBox Start
		-- local cv_vehicle_steer_source = vgui.Create("DComboBox", MenuTab11)
		-- cv_vehicle_steer_source:SetPos(20, 70)
		-- cv_vehicle_steer_source:SetSize(200, 20)
		-- cv_vehicle_steer_source:SetValue("Vehicle steer source")
		-- cv_vehicle_steer_source:AddChoice("Analog stick", 0)
		-- cv_vehicle_steer_source:AddChoice("Right hand", 1)
		-- cv_vehicle_steer_source:AddChoice("Left hand", 2)
		-- cv_vehicle_steer_source.OnSelect = function(self, index, value)
		-- 	LocalPlayer():ConCommand("vrmod_vehicle_steer_source " .. value)
		-- end
		-- --DComboBox End
		-- --DComboBox Start  
		-- local cv_weapon_aim_source = vgui.Create("DComboBox", MenuTab11)
		-- cv_weapon_aim_source:SetPos(20, 100)
		-- cv_weapon_aim_source:SetSize(200, 20)
		-- cv_weapon_aim_source:SetValue("Weapon aim source")
		-- cv_weapon_aim_source:AddChoice("HMD", 0)
		-- cv_weapon_aim_source:AddChoice("Right hand", 1)
		-- cv_weapon_aim_source:AddChoice("Left hand", 2)
		-- cv_weapon_aim_source.OnSelect = function(self, index, value)
		-- 	LocalPlayer():ConCommand("vrmod_weapon_aim_source " .. value)
		-- end
		-- --DComboBox End
		-- --DCheckBoxLabel Start
		-- local cv_analog_move_only = MenuTab11:Add("DCheckBoxLabel")
		-- cv_analog_move_only:SetPos(20, 130)
		-- cv_analog_move_only:SetText("Use analog stick only for movement")
		-- cv_analog_move_only:SetConVar("vrmod_analog_move_only")
		-- cv_analog_move_only:SizeToContents()
		-- --DCheckBoxLabel End
		-- --DCheckBoxLabel Start
		-- local cv_car_gun_mode = MenuTab11:Add("DCheckBoxLabel")
		-- cv_car_gun_mode:SetPos(20, 160)
		-- cv_car_gun_mode:SetText("Vehicle reticle mode")
		-- cv_car_gun_mode:SetConVar("vrmod_vehicle_reticle_mode")
		-- cv_car_gun_mode:SizeToContents()
		-- --DCheckBoxLabel End  
		-- --DCheckBoxLabel Start
		-- local cv_jump_duck = MenuTab11:Add("DCheckBoxLabel")
		-- cv_jump_duck:SetPos(20, 190)
		-- cv_jump_duck:SetText("Automatic jump and duck")
		-- cv_jump_duck:SetConVar("vrmod_auto_jump_duck")
		-- cv_jump_duck:SizeToContents()
		-- --DCheckBoxLabel End
		-- --DCheckBoxLabel Start 
		-- local cv_righthandle = MenuTab11:Add("DCheckBoxLabel")
		-- cv_righthandle:SetPos(20, 220)
		-- cv_righthandle:SetText("Right hand pickup")
		-- cv_righthandle:SetConVar("vrmod_test_Righthandle")
		-- cv_righthandle:SizeToContents()
		-- --DCheckBoxLabel End
		-- --DCheckBoxLabel Start
		-- local cv_lefthandle = MenuTab11:Add("DCheckBoxLabel")
		-- cv_lefthandle:SetPos(20, 250)
		-- cv_lefthandle:SetText("Left hand pickup")
		-- cv_lefthandle:SetConVar("vrmod_test_lefthandle")
		-- cv_lefthandle:SizeToContents()
		-- --DCheckBoxLabel End
		-- --DButton Start 
		-- local default_button = vgui.Create("DButton", MenuTab11)
		-- default_button:SetText("Set default values")
		-- default_button:SetPos(20, 280)
		-- default_button:SetSize(160, 30)
		-- default_button.DoClick = function()
		-- 	RunConsoleCommand("vrmod_allow_teleport", "1")
		-- 	RunConsoleCommand("vrmod_allow_teleport_client", "0")
		-- 	RunConsoleCommand("vrmod_vehicle_steer_source", "0")
		-- 	RunConsoleCommand("vrmod_weapon_aim_source", "0")
		-- 	RunConsoleCommand("vrmod_analog_move_only", "0")
		-- 	RunConsoleCommand("vrmod_vehicle_reticle_mode", "1")
		-- 	RunConsoleCommand("vrmod_auto_jump_duck", "1")
		-- 	RunConsoleCommand("vrmod_test_Righthandle", "0")
		-- 	RunConsoleCommand("vrmod_test_lefthandle", "0")
		-- end
		-- --DButton End
		-- --MenuTab11 (Locomotion) End
		--MenuTab07  Start
		local MenuTab07 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Network(Server)", MenuTab07, "icon16/ipod_cast_add.png")
		MenuTab07.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DNumSlider Start
		--vr_net_delay
		local net_delay = vgui.Create("DNumSlider", MenuTab07)
		net_delay:SetPos(20, 25) -- Set the position (X,Y)
		net_delay:SetSize(370, 25) -- Set the size (X,Y)
		net_delay:SetText("net_delay") -- Set the text above the slider
		net_delay:SetMin(0.000) -- Set the minimum number you can slide to
		net_delay:SetMax(1.000) -- Set the maximum number you can slide to
		net_delay:SetDecimals(3) -- Decimal places - zero for whole number (set 2 -> 0.00)
		net_delay:SetConVar("vrmod_net_delay") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		net_delay.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vr_net_delaymax
		local net_delaymax = vgui.Create("DNumSlider", MenuTab07)
		net_delaymax:SetPos(20, 50) -- Set the position (X,Y)
		net_delaymax:SetSize(370, 25) -- Set the size (X,Y)
		net_delaymax:SetText("net_delaymax") -- Set the text above the slider
		net_delaymax:SetMin(1.00) -- Set the minimum number you can slide to
		net_delaymax:SetMax(100.00) -- Set the maximum number you can slide to
		net_delaymax:SetDecimals(3) -- Decimal places - zero for whole number (set 2 -> 0.00)
		net_delaymax:SetConVar("vrmod_net_delaymax") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		net_delaymax.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vr_net_storedframes
		local net_storedframes = vgui.Create("DNumSlider", MenuTab07)
		net_storedframes:SetPos(20, 75) -- Set the position (X,Y)
		net_storedframes:SetSize(370, 25) -- Set the size (X,Y)
		net_storedframes:SetText("net_storedframes") -- Set the text above the slider
		net_storedframes:SetMin(1.00) -- Set the minimum number you can slide to
		net_storedframes:SetMax(25.00) -- Set the maximum number you can slide to
		net_storedframes:SetDecimals(3) -- Decimal places - zero for whole number (set 2 -> 0.00)
		net_storedframes:SetConVar("vrmod_net_storedframes") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		net_storedframes.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vr_net_tickrate
		local net_tickrate = vgui.Create("DNumSlider", MenuTab07)
		net_tickrate:SetPos(20, 100) -- Set the position (X,Y)
		net_tickrate:SetSize(370, 25) -- Set the size (X,Y)
		net_tickrate:SetText("net_tickrate") -- Set the text above the slider
		net_tickrate:SetMin(1.00) -- Set the minimum number you can slide to
		net_tickrate:SetMax(100.00) -- Set the maximum number you can slide to
		net_tickrate:SetDecimals(3) -- Decimal places - zero for whole number (set 2 -> 0.00)
		net_tickrate:SetConVar("vrmod_net_tickrate") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		net_tickrate.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DCheckBoxLabel Start
		local allow_teleport = MenuTab07:Add("DCheckBoxLabel") -- Create the checkbox
		allow_teleport:SetPos(20, 130) -- Set the position
		allow_teleport:SetText("server allow VRteleport") -- Set the text next to the box
		allow_teleport:SetConVar("vrmod_allow_teleport") -- Change a ConVar when the box it ticked/unticked
		allow_teleport:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DButton Start
		--character_restart
		local net_defaultbutton = vgui.Create("DButton", MenuTab07) -- Create the button and parent it to the frame
		net_defaultbutton:SetText("setdefaultvalue") -- Set the text on the button
		net_defaultbutton:SetPos(190, 310) -- Set the position on the frame
		net_defaultbutton:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		net_defaultbutton.DoClick = function()
			RunConsoleCommand("vrmod_net_tickrate", "67") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_net_storedframes", "15") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_net_delaymax", "0.2") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_net_delay", "0.1") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_allow_teleport", true) -- Run the console command "say hi" when you click it ( command, args )
		end

		net_defaultbutton.DoRightClick = function() end
		--DButton end
		--MenuTab07  end
		--MenuTab08  Start
		local MenuTab08 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Misc", MenuTab08, "icon16/computer_edit.png")
		MenuTab08.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DCheckBoxLabel Start
		local showonstartup = MenuTab08:Add("DCheckBoxLabel") -- Create the checkbox
		showonstartup:SetPos(20, 10) -- Set the position
		showonstartup:SetText("VRMod Menu showonstartup") -- Set the text next to the box
		showonstartup:SetConVar("vrmod_showonstartup") -- Change a ConVar when the box it ticked/unticked
		showonstartup:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local autoarcbench_button = MenuTab08:Add("DCheckBoxLabel") -- Create the checkbox
		autoarcbench_button:SetPos(20, 35) -- Set the position
		autoarcbench_button:SetText("Auto Optimize (ArcCW/Arc9/TFA)") -- Set the text next to the box
		autoarcbench_button:SetConVar("vrmod_auto_arc_benchgun") -- Change a ConVar when the box it ticked/unticked
		autoarcbench_button:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--DCheckBoxLabel Start
		local manualpickup = MenuTab08:Add("DCheckBoxLabel") -- Create the checkbox
		manualpickup:SetPos(20, 55) -- Set the position
		manualpickup:SetText("[vrmod_manualpickups(Server)]\nUse of this requires\n{VRMod Manual Item Pickup}\nby Dr. Hugo.") -- Set the text next to the box
		manualpickup:SetConVar("vrmod_manualpickups") -- Change a ConVar when the box it ticked/unticked
		manualpickup:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end

			--gmod_optimization
			local vrmod_data_vmt_generate_test = vgui.Create("DButton", MenuTab08) -- Create the button and parent it to the frame
			vrmod_data_vmt_generate_test:SetText("Config Data Generate\n") -- Set the text on the button
			vrmod_data_vmt_generate_test:SetPos(20, 210) -- Set the position on the frame
			vrmod_data_vmt_generate_test:SetSize(160, 30) -- Set the size
			-- A custom function run when clicked ( note the . instead of : )
			vrmod_data_vmt_generate_test.DoClick = function()
				RunConsoleCommand("vrmod_data_vmt_generate_test") -- Run the console command "say hi" when you click it ( command, args )
			end
	
		--DCheckBoxLabel Start
		local vrmod_error_check_method = MenuTab08:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_error_check_method:SetPos(20, 250) -- Set the position
		vrmod_error_check_method:SetText("[error_check_method]\nIf it does not start VRMod\n change this and restart.") -- Set the text next to the box
		vrmod_error_check_method:SetConVar("vrmod_error_check_method") -- Change a ConVar when the box it ticked/unticked
		vrmod_error_check_method:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		-- DCheckBoxLabel Start
		local error_hard = MenuTab08:Add("DCheckBoxLabel")
		error_hard:SetPos(20, 295)
		error_hard:SetText("Module Error VRMod Lock")
		error_hard:SetConVar("vrmod_error_hard")
		error_hard:SizeToContents()
		-- DCheckBoxLabel End
		--fov_desired
		local fov_desired = vgui.Create("DNumSlider", MenuTab08)
		fov_desired:SetPos(20, 320) -- Set the position (X,Y)
		fov_desired:SetSize(370, 50) -- Set the size (X,Y)
		fov_desired:SetText("[fov_desired]") -- Set the text above the slider
		fov_desired:SetMin(72) -- Set the minimum number you can slide to
		fov_desired:SetMax(100) -- Set the maximum number you can slide to
		fov_desired:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		fov_desired:SetConVar("fov_desired") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		fov_desired.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		-- MenuTab08  End

		--MenuTab09  Start
		local MenuTab09 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Misc02", MenuTab09, "icon16/computer_edit.png")
		MenuTab09.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DCheckBoxLabel Start
		local lefthand = MenuTab09:Add("DCheckBoxLabel") -- Create the checkbox
		lefthand:SetPos(20, 10) -- Set the position
		lefthand:SetText("LeftHand\n(WIP)") -- Set the text next to the box
		lefthand:SetConVar("vrmod_LeftHand") -- Change a ConVar when the box it ticked/unticked
		lefthand:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local lefthandleftfire = MenuTab09:Add("DCheckBoxLabel") -- Create the checkbox
		lefthandleftfire:SetPos(130, 10) -- Set the position
		lefthandleftfire:SetText("lefthand leftfire\n(WIP)") -- Set the text next to the box
		lefthandleftfire:SetConVar("vrmod_lefthandleftfire") -- Change a ConVar when the box it ticked/unticked
		lefthandleftfire:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local lefthandholdmode = MenuTab09:Add("DCheckBoxLabel") -- Create the checkbox
		lefthandholdmode:SetPos(250, 10) -- Set the position
		lefthandholdmode:SetText("lefthand holdmode\n(WIP)") -- Set the text next to the box
		lefthandholdmode:SetConVar("vrmod_LeftHandmode") -- Change a ConVar when the box it ticked/unticked
		lefthandholdmode:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DCheckBoxLabel Start
		local ui_realtime = MenuTab09:Add("DCheckBoxLabel") -- Create the checkbox
		ui_realtime:SetPos(20, 50) -- Set the position
		ui_realtime:SetText("UI Render Alternative") -- Set the text next to the box
		ui_realtime:SetConVar("vrmod_ui_realtime") -- Change a ConVar when the box it ticked/unticked
		ui_realtime:SizeToContents() -- Make its size the same as the contents
		--DCheckBoxLabel end
		--DNumSlider Start
		--cameraoverride
		local cameraoverride = vgui.Create("DCheckBoxLabel", MenuTab09)
		cameraoverride:SetPos(20, 90) -- Set the position (X,Y)
		cameraoverride:SetSize(320, 25) -- Set the size (X,Y)
		cameraoverride:SetText("[Desktop_CameraOverride]\nON = Default. The VR view is directly reflected in the gmod window.\nOFF = If you use a TPSmod or similar, the gmod window will be\n            the screen of the camera mod.\n(If OFF,There is a bug that your body will not be reflected\nwhen you are not using a camera mod, etc.)") -- Set the text above the slider
		cameraoverride:SetConVar("vrmod_cameraoverride") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		cameraoverride.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		-- DCheckBoxLabel Start
		local lvs_pickup_handle = MenuTab09:Add("DCheckBoxLabel")
		lvs_pickup_handle:SetPos(20, 210)
		lvs_pickup_handle:SetText("Enable LVS Pickup Handle")
		lvs_pickup_handle:SetConVar("vrmod_lvs_pickup_handle")
		lvs_pickup_handle:SizeToContents()
		-- DCheckBoxLabel End
		-- DCheckBoxLabel Start
		local pmchange = MenuTab09:Add("DCheckBoxLabel")
		pmchange:SetPos(20, 230)
		pmchange:SetText("Enable Player Model Change")
		pmchange:SetConVar("vrmod_pmchange")
		pmchange:SizeToContents()
		-- DCheckBoxLabel End
		-- DCheckBoxLabel Start
		local vrmod_keyboard_uichatkey = MenuTab09:Add("DCheckBoxLabel")
		vrmod_keyboard_uichatkey:SetPos(20, 250)
		vrmod_keyboard_uichatkey:SetText("vrmod_keyboard_uichatkey")
		vrmod_keyboard_uichatkey:SetConVar("vrmod_keyboard_uichatkey")
		vrmod_keyboard_uichatkey:SizeToContents()
		-- DCheckBoxLabel End
		-- DCheckBoxLabel Start
		local pickup_disable_client = MenuTab09:Add("DCheckBoxLabel")
		pickup_disable_client:SetPos(20, 270)
		pickup_disable_client:SetText("Disable Pickup Client")
		pickup_disable_client:SetConVar("vr_pickup_disable_client")
		pickup_disable_client:SizeToContents()
		-- DCheckBoxLabel End
		-- MenuTab09  End	
		-- MenuTab13 (Miscellaneous) Start
		local MenuTab13 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Misc03", MenuTab13, "icon16/wrench.png")
		MenuTab13.Paint = function(self, w, h) end
		--DNumSlider Start
		local vrmod_rtWidth_Multiplier = vgui.Create("DNumSlider", MenuTab13)
		vrmod_rtWidth_Multiplier:SetPos(20, 10) -- Set the position (X,Y)
		vrmod_rtWidth_Multiplier:SetSize(370, 25) -- Set the size (X,Y)
		vrmod_rtWidth_Multiplier:SetText("[vrmod_rtWidth_Multiplier]") -- Set the text above the slider
		vrmod_rtWidth_Multiplier:SetMin(0.1) -- Set the minimum number you can slide to
		vrmod_rtWidth_Multiplier:SetMax(5.0) -- Set the maximum number you can slide to
		vrmod_rtWidth_Multiplier:SetDecimals(1) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_rtWidth_Multiplier:SetConVar("vrmod_rtWidth_Multiplier") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_rtWidth_Multiplier.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		local vrmod_rtHeight_Multiplier = vgui.Create("DNumSlider", MenuTab13)
		vrmod_rtHeight_Multiplier:SetPos(20, 50) -- Set the position (X,Y)
		vrmod_rtHeight_Multiplier:SetSize(370, 25) -- Set the size (X,Y)
		vrmod_rtHeight_Multiplier:SetText("[vrmod_rtHeight_Multiplier]") -- Set the text above the slider
		vrmod_rtHeight_Multiplier:SetMin(0.1) -- Set the minimum number you can slide to
		vrmod_rtHeight_Multiplier:SetMax(5.0) -- Set the maximum number you can slide to
		vrmod_rtHeight_Multiplier:SetDecimals(1) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_rtHeight_Multiplier:SetConVar("vrmod_rtHeight_Multiplier") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_rtHeight_Multiplier.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DButton Start

		--DButton Start
		--character_restart
		local vrmod_reset_render_targets = vgui.Create("DButton", MenuTab13) -- Create the button and parent it to the frame
		vrmod_reset_render_targets:SetText("reset_render") -- Set the text on the button
		vrmod_reset_render_targets:SetPos(20, 280) -- Set the position on the frame
		vrmod_reset_render_targets:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		vrmod_reset_render_targets.DoClick = function()
			RunConsoleCommand("vrmod_reset_render_targets") -- Run the console command "say hi" when you click it ( command, args )
		end

		--DButton Start
		--character_restart
		local vrmod_update_render_targets = vgui.Create("DButton", MenuTab13) -- Create the button and parent it to the frame
		vrmod_update_render_targets:SetText("update_render") -- Set the text on the button
		vrmod_update_render_targets:SetPos(190, 280) -- Set the position on the frame
		vrmod_update_render_targets:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		vrmod_update_render_targets.DoClick = function()
			RunConsoleCommand("vrmod_update_render_targets") -- Run the console command "say hi" when you click it ( command, args )
		end


		--DButton Start
		--character_restart
		local Height_Beta = vgui.Create("DButton", MenuTab13) -- Create the button and parent it to the frame
		Height_Beta:SetText("Width&Height\nCustom (Quest2&VirtualDesktop)") -- Set the text on the button
		Height_Beta:SetPos(20, 315) -- Set the position on the frame
		Height_Beta:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		Height_Beta.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.5") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "1.2") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_character_restart") -- Run the console command "say hi" when you click it ( command, args )
		end

		Height_Beta.DoRightClick = function() end
		--DButton end
		--DButton Start
		--character_restart
		local misc3_defaultbutton = vgui.Create("DButton", MenuTab13) -- Create the button and parent it to the frame
		misc3_defaultbutton:SetText("setdefaultvalue") -- Set the text on the button
		misc3_defaultbutton:SetPos(190, 315) -- Set the position on the frame
		misc3_defaultbutton:SetSize(160, 30) -- Set the size
		-- A custom function run when clicked ( note the . instead of : )
		misc3_defaultbutton.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "1.0") -- Run the console command "say hi" when you click it ( command, args )
			RunConsoleCommand("vrmod_character_restart" )-- Run the console command "say hi" when you click it ( command, args )
		end

		misc3_defaultbutton.DoRightClick = function() end
		--DButton end
		-- MenuTab13 (Miscellaneous) End
		--MenuTab10  Start
		local MenuTab10 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("GameRebootRequied", MenuTab10, "icon16/computer_edit.png")
		MenuTab10.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		--DNumSlider Start
		--vrmod_ScrH
		local vrmod_ScrH = vgui.Create("DNumSlider", MenuTab10)
		vrmod_ScrH:SetPos(20, 10) -- Set the position (X,Y)
		vrmod_ScrH:SetSize(330, 25) -- Set the size (X,Y)
		vrmod_ScrH:SetText("[VR_UI Height]") -- Set the text above the slider
		vrmod_ScrH:SetMin(480) -- Set the minimum number you can slide to
		vrmod_ScrH:SetMax(ScrH() * 2) -- Set the maximum number you can slide to
		vrmod_ScrH:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_ScrH:SetConVar("vrmod_ScrH") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_ScrH.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vrmod_ScrW
		local vrmod_ScrW = vgui.Create("DNumSlider", MenuTab10)
		vrmod_ScrW:SetPos(20, 30) -- Set the position (X,Y)
		vrmod_ScrW:SetSize(330, 25) -- Set the size (X,Y)
		vrmod_ScrW:SetText("[VR_UI Weight]") -- Set the text above the slider
		vrmod_ScrW:SetMin(640) -- Set the minimum number you can slide to
		vrmod_ScrW:SetMax(ScrW() * 2) -- Set the maximum number you can slide to
		vrmod_ScrW:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_ScrW:SetConVar("vrmod_ScrW") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_ScrW.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vrmod_hud_ScrH
		local vrmod_hud_ScrH = vgui.Create("DNumSlider", MenuTab10)
		vrmod_hud_ScrH:SetPos(20, 60) -- Set the position (X,Y)
		vrmod_hud_ScrH:SetSize(330, 25) -- Set the size (X,Y)
		vrmod_hud_ScrH:SetText("[VR_HUD Height]") -- Set the text above the slider
		vrmod_hud_ScrH:SetMin(480) -- Set the minimum number you can slide to
		vrmod_hud_ScrH:SetMax(ScrH() * 2) -- Set the maximum number you can slide to
		vrmod_hud_ScrH:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_hud_ScrH:SetConVar("vrmod_ScrH_hud") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_hud_ScrH.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DNumSlider Start
		--vrmod_ScrW_hud
		local vrmod_ScrW_hud = vgui.Create("DNumSlider", MenuTab10)
		vrmod_ScrW_hud:SetPos(20, 80) -- Set the position (X,Y)
		vrmod_ScrW_hud:SetSize(330, 25) -- Set the size (X,Y)
		vrmod_ScrW_hud:SetText("[VR_HUD Weight]") -- Set the text above the slider
		vrmod_ScrW_hud:SetMin(640) -- Set the minimum number you can slide to
		vrmod_ScrW_hud:SetMax(ScrW() * 2) -- Set the maximum number you can slide to
		vrmod_ScrW_hud:SetDecimals(0) -- Decimal places - zero for whole number (set 2 -> 0.00)
		vrmod_ScrW_hud:SetConVar("vrmod_ScrW_hud") -- Changes the ConVar when you slide
		-- If not using convars, you can use this hook + Panel.SetValue()
		vrmod_ScrW_hud.OnValueChanged = function(self, value) end -- Called when the slider value changes
		--DNumSlider end
		--DCheckBoxLabel Start
		local vrmod_scr_alwaysautosetting = MenuTab10:Add("DCheckBoxLabel") -- Create the checkbox
		vrmod_scr_alwaysautosetting:SetPos(20, 120) -- Set the position
		vrmod_scr_alwaysautosetting:SetText("[Automatic resolution set]") -- Set the text next to the box
		vrmod_scr_alwaysautosetting:SetConVar("vrmod_scr_alwaysautosetting") -- Change a ConVar when the box it ticked/unticked
		vrmod_scr_alwaysautosetting:SizeToContents() -- Make its size the same as the contents
		-- MenuTab10  End
		-- PanelEMSTOP  Start
		local PanelEMSTOP = vgui.Create("DPanel", sheet)
		sheet:AddSheet("VRStop Key", PanelEMSTOP, "icon16/stop.png")
		PanelEMSTOP.Paint = function(self, w, h) end -- draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
		-- Emergency Stop Key Binder
		local emergStopKeyBinder = vgui.Create("DBinder", PanelEMSTOP)
		emergStopKeyBinder:SetPos(20, 20)
		emergStopKeyBinder:SetSize(300, 20)
		emergStopKeyBinder:SetConVar("vrmod_emergencystop_key")
		-- Emergency Stop Hold Time Slider
		local emergStopHoldTime = vgui.Create("DNumSlider", PanelEMSTOP)
		emergStopHoldTime:SetPos(20, 50)
		emergStopHoldTime:SetSize(330, 30)
		emergStopHoldTime:SetText("Hold Time for \n Emergency Stop (Seconds)")
		emergStopHoldTime:SetMin(0.0)
		emergStopHoldTime:SetMax(10.0)
		emergStopHoldTime:SetDecimals(2)
		emergStopHoldTime:SetConVar("vrmod_emergencystop_time")
	end
)
--Settings02 end
--
-- EXAMPLE Start
-- local EXAMPLE = vgui.Create("DPanel", sheet)
-- sheet:AddSheet("this is title", EXAMPLE, "icon16/user_edit.png")
-- EXAMPLE.Paint = function(self, w, h)
-- 	draw.RoundedBox(4, 0, 0, w, h, Color(126, 126, 128, self:GetAlpha()))
-- end
-- EXAMPLE End
--DCheckBoxLabel end
-- --DLabel&DTextEntry Start
-- local FlohandmodelL = Panel9:Add("DLabel")
-- FlohandmodelL:SetPos(10, 260) -- Set the position of the label
-- FlohandmodelL:SetText("floatinghands_model") --  Set the text of the label
-- FlohandmodelL:SizeToContents() -- Size the label to fit the text in it
-- FlohandmodelL:SetDark(0) -- Set the colour of the text inside the label to a darker one
-- local floatinghands_model = Panel9:Add("DTextEntry")
-- Flohandmodel_String = GetConVar("vrmod_floatinghands_model"):GetString()
-- floatinghands_model:SetPos(20, 275) -- Set the position
-- floatinghands_model:SetSize(330, 25) -- Set the size (X,Y)
-- floatinghands_model:SetUpdateOnType(0) -- Set the position
-- floatinghands_model:SetValue(Flohandmodel_String)
-- floatinghands_model.OnEnter = function(self)
-- 	floatinghands_model:UpdateConvarValue("vrmod_floatinghands_model") -- Change a ConVar when the box it ticked/unticked
-- end
-- --DLabel&DTextEntry end
-- --DLabel&DTextEntry Start
-- local FlohandmatelialL = Panel9:Add("DLabel")
-- FlohandmatelialL:SetPos(10, 305) -- Set the position of the label
-- FlohandmatelialL:SetText("floatinghands_material") --  Set the text of the label
-- FlohandmatelialL:SizeToContents() -- Size the label to fit the text in it
-- FlohandmatelialL:SetDark(0) -- Set the colour of the text inside the label to a darker one
-- local floatinghands_material = Panel9:Add("DTextEntry")
-- Flohandmat_String = GetConVar("vrmod_floatinghands_material"):GetString()
-- floatinghands_material:SetPos(20, 320) -- Set the position
-- floatinghands_material:SetSize(330, 25) -- Set the size (X,Y)
-- floatinghands_material:SetUpdateOnType(0) -- Set the position
-- floatinghands_material:SetValue(Flohandmat_String)
-- floatinghands_material.OnEnter = function(self)
-- 	floatinghands_material:UpdateConvarValue("vrmod_floatinghands_material") -- Change a ConVar when the box it ticked/unticked
-- end
-- --DLabel&DTextEntry end
-- Panel9  End