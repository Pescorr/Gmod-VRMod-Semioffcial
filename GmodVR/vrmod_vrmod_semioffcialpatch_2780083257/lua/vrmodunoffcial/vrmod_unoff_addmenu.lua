if SERVER then return end

local convars, convarValues = vrmod.GetConvars()


hook.Add("VRMod_Menu","addsettings",function(frame)

	local vrgrab1 = CreateClientConVar("vrgrab_gravitygloves", "1",true,FCVAR_ARCHIVE)
	local vrgrab2 = CreateClientConVar("vrgrab_gravitygloves_minrange","0",true,FCVAR_ARCHIVE)
	local vrgrab3 = CreateClientConVar("vrgrab_range","0",true,FCVAR_ARCHIVE)


	--Settings02 Start
		--add VRMod_Menu Settings02 propertysheet start
		local sheet = vgui.Create( "DPropertySheet", frame.DPropertySheet )
		frame.DPropertySheet:AddSheet( "Settings02", sheet )
		sheet:Dock( FILL )
		--add VRMod_Menu Settings02 propertysheet end
		--Panel1 "TAB1" Start
			local Panel1 = vgui.Create( "DPanel", sheet )
			Panel1.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
			sheet:AddSheet( "Client", Panel1, "icon16/cog_add.png" )
			
			
				--DCheckBoxLabel Start
				local lefthand = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					lefthand:SetPos( 20, 10 )						-- Set the position
					lefthand:SetText("LeftHand\n(WIP)")					-- Set the text next to the box
					lefthand:SetConVar( "vrmod_LeftHand" )				-- Change a ConVar when the box it ticked/unticked
					lefthand:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end

				--DCheckBoxLabel Start
				local lefthandleftfire = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					lefthandleftfire:SetPos( 130, 10 )						-- Set the position
					lefthandleftfire:SetText("lefthand leftfire\n(WIP)")					-- Set the text next to the box
					lefthandleftfire:SetConVar( "vrmod_lefthandleftfire" )				-- Change a ConVar when the box it ticked/unticked
					lefthandleftfire:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end
				
				--DCheckBoxLabel Start
				local lefthandholdmode = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					lefthandholdmode:SetPos( 250, 10 )						-- Set the position
					lefthandholdmode:SetText("lefthand holdmode\n(WIP)")					-- Set the text next to the box
					lefthandholdmode:SetConVar( "vrmod_LeftHandmode" )				-- Change a ConVar when the box it ticked/unticked
					lefthandholdmode:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end


				
				--vrmod_attach_quickmenu
				local attach_quickmenu= vgui.Create( "DComboBox", Panel1 )
					attach_quickmenu:SetPos( 20, 50 )				-- Set the position (X,Y)
					attach_quickmenu:SetSize( 320, 25 )			-- Set the size (X,Y)
					attach_quickmenu:SetText( "quickmenu Attach Position" )	-- Set the text above the slider
					attach_quickmenu:AddChoice( "left hand" )
					attach_quickmenu:AddChoice( "(buggy)" )
					attach_quickmenu:AddChoice( "HMD" )
					attach_quickmenu:AddChoice( "right hand" )
					attach_quickmenu.OnSelect = function( self, index, value )
						LocalPlayer():ConCommand("vrmod_attach_quickmenu " .. index )
					end
				--DNumSlider end
				
				--vrmod_attach_weaponmenu
				local attach_weaponmenu= vgui.Create( "DComboBox", Panel1 )
					attach_weaponmenu:SetPos( 20, 75 )				-- Set the position (X,Y)
					attach_weaponmenu:SetSize( 320, 25 )			-- Set the size (X,Y)
					attach_weaponmenu:SetText( "weaponmenu Attach Position" )	-- Set the text above the slider
					attach_weaponmenu:AddChoice( "left hand" )
					attach_weaponmenu:AddChoice( "(buggy)" )
					attach_weaponmenu:AddChoice( "HMD" )
					attach_weaponmenu:AddChoice( "right hand" )
					attach_weaponmenu.OnSelect = function( self, index, value )
						LocalPlayer():ConCommand("vrmod_attach_weaponmenu " .. index )
					end
				--DNumSlider end

				--vrmod_attach_popup
				local attach_popup= vgui.Create( "DComboBox", Panel1 )
					attach_popup:SetPos( 20, 100 )				-- Set the position (X,Y)
					attach_popup:SetSize( 320, 25 )			-- Set the size (X,Y)
					attach_popup:SetText( "popup Attach Position" )	-- Set the text above the slider
					attach_popup:AddChoice( "left hand" )
					attach_popup:AddChoice( "(buggy)" )
					attach_popup:AddChoice( "HMD" )
					attach_popup:AddChoice( "right hand" )
					attach_popup.OnSelect = function( self, index, value )
						LocalPlayer():ConCommand("vrmod_attach_popup " .. index )
					end
				--DNumSlider end

				--DCheckBoxLabel Start
				local vremenu_attach = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					vremenu_attach:SetPos( 20, 130 )						-- Set the position
					vremenu_attach:SetText("VRE UI AttachToLeftHand")					-- Set the text next to the box
					vremenu_attach:SetConVar( "vre_ui_attachtohand" )				-- Change a ConVar when the box it ticked/unticked
					vremenu_attach:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end
	
				--DCheckBoxLabel Start
				local ui_realtime = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					ui_realtime :SetPos( 20, 150 )						-- Set the position
					ui_realtime:SetText("ui_realtime")					-- Set the text next to the box
					ui_realtime:SetConVar( "vrmod_ui_realtime" )				-- Change a ConVar when the box it ticked/unticked
					ui_realtime:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end



				

				--DCheckBoxLabel Start
				local allow_teleport_client = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					allow_teleport_client:SetPos( 20, 170 )						-- Set the position
					allow_teleport_client:SetText("allow_teleport_client")					-- Set the text next to the box
					allow_teleport_client:SetConVar( "vrmod_allow_teleport_client" )				-- Change a ConVar when the box it ticked/unticked
					allow_teleport_client:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end

				--DCheckBoxLabel Start
				local pickup_disable_client = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					pickup_disable_client:SetPos( 20, 190 )						-- Set the position
					pickup_disable_client:SetText("VR Disable Pickup(Client)")					-- Set the text next to the box
					pickup_disable_client:SetConVar( "vr_pickup_disable_client" )				-- Change a ConVar when the box it ticked/unticked
					pickup_disable_client:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end
				
				--DCheckBoxLabel Start
				local vrmod_hud = Panel1:Add( "DCheckBoxLabel" ) -- Create the checkbox
					vrmod_hud:SetPos( 20, 210 )						-- Set the position
					vrmod_hud:SetText("Hud Enable")					-- Set the text next to the box
					vrmod_hud:SetConVar( "vrmod_hud" )				-- Change a ConVar when the box it ticked/unticked
					vrmod_hud:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end
				
			
				--DNumSlider Start
					--hudcurve
					local hudcurve= vgui.Create( "DNumSlider", Panel1 )
						hudcurve:SetPos( 20, 230 )				-- Set the position (X,Y)
						hudcurve:SetSize( 370, 25 )			-- Set the size (X,Y)
						hudcurve:SetText( "Hud curve" )	-- Set the text above the slider
						hudcurve:SetMin( 1 )				 	-- Set the minimum number you can slide to
						hudcurve:SetMax( 60 )				-- Set the maximum number you can slide to
						hudcurve:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
						hudcurve:SetConVar( "vrmod_hudcurve" )	-- Changes the ConVar when you slide

						-- If not using convars, you can use this hook + Panel.SetValue()
						hudcurve.OnValueChanged = function( self, value )
						
						-- Called when the slider value changes
						end
				--DNumSlider end
				
				--DNumSlider Start
					--huddistance
					local huddistance= vgui.Create( "DNumSlider", Panel1 )
						huddistance:SetPos( 20, 255 )			-- Set the position (X,Y)
						huddistance:SetSize( 370, 25 )			-- Set the size (X,Y)
						huddistance:SetText( "Hud distance" )	-- Set the text above the slider
						huddistance:SetMin( 1 )				 	-- Set the minimum number you can slide to
						huddistance:SetMax( 60 )				-- Set the maximum number you can slide to
						huddistance:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
						huddistance:SetConVar( "vrmod_huddistance" )	-- Changes the ConVar when you slide

						-- If not using convars, you can use this hook + Panel.SetValue()
						huddistance.OnValueChanged = function( self, value )
						
						-- Called when the slider value changes
						end
				--DNumSlider end

				--DNumSlider Start
					--hudscale
					local hudscale= vgui.Create( "DNumSlider", Panel1 )
						hudscale:SetPos( 20, 280 )			-- Set the position (X,Y)
						hudscale:SetSize( 370, 25 )			-- Set the size (X,Y)
						hudscale:SetText( "Hud scale" )	-- Set the text above the slider
						hudscale:SetMin( 0.01 )				 	-- Set the minimum number you can slide to
						hudscale:SetMax( 0.1 )				-- Set the maximum number you can slide to
						hudscale:SetDecimals( 2 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
						hudscale:SetConVar( "vrmod_hudscale" )	-- Changes the ConVar when you slide

						-- If not using convars, you can use this hook + Panel.SetValue()
						hudscale.OnValueChanged = function( self, value )
						
						-- Called when the slider value changes
						end
				--DNumSlider end


				--DNumSlider Start
					--hudtestalpha
					local hudtestalpha= vgui.Create( "DNumSlider", Panel1 )
						hudtestalpha:SetPos( 20, 305 )			-- Set the position (X,Y)
						hudtestalpha:SetSize( 370, 25 )			-- Set the size (X,Y)
						hudtestalpha:SetText( "Hud alpha Transparency" )	-- Set the text above the slider
						hudtestalpha:SetMin( 0 )				 	-- Set the minimum number you can slide to
						hudtestalpha:SetMax( 255 )				-- Set the maximum number you can slide to
						hudtestalpha:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
						hudtestalpha:SetConVar( "vrmod_hudtestalpha" )	-- Changes the ConVar when you slide

						-- If not using convars, you can use this hook + Panel.SetValue()
						hudtestalpha.OnValueChanged = function( self, value )
						
						-- Called when the slider value changes
						end
				--DNumSlider end



		--Panel1 "TAB1" end
				
		--Panel2 "TAB2" Start

			local Panel2 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "Character", Panel2, "icon16/user_edit.png" )
			Panel2.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
					
						
								
			--DNumSlider Start
				--scale
				local scale= vgui.Create( "DLabel", Panel2 )
					scale:SetPos( 20, 5 )				-- Set the position (X,Y)
					scale:SetText( "scale" )	-- Set the text above the slider					
					-- If not using convars, you can use this hook + Panel.SetValue()
			--DNumSlider end

				
			--DButton Start
				--scaleplus
				local scaleplus = vgui.Create( "DButton", Panel2 ) -- Create the button and parent it to the frame
				scaleplus:SetText( "+" )					-- Set the text on the button
				scaleplus:SetPos( 20, 25 )					-- Set the position on the frame
				scaleplus:SetSize( 160, 25 )					-- Set the size
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
				local scaleminus = vgui.Create( "DButton", Panel2 ) -- Create the button and parent it to the frame
				scaleminus:SetText( "-" )					-- Set the text on the button
				scaleminus:SetPos( 190, 25 )					-- Set the position on the frame
				scaleminus:SetSize( 160, 25 )					-- Set the size
				scaleminus.DoClick = function()	
					g_VR.scale = g_VR.scale - 0.5
					convars.vrmod_scale:SetFloat(g_VR.scale)
				end

				scaleminus.DoRightClick = function()
					g_VR.scale = g_VR.scale - 1.0
					convars.vrmod_scale:SetFloat(g_VR.scale)
				end
			--DButton end

				
			--DNumSlider Start
				--characterEyeHeight
				local characterEyeHeight= vgui.Create( "DNumSlider", Panel2 )
					characterEyeHeight:SetPos( 20, 60 )				-- Set the position (X,Y)
					characterEyeHeight:SetSize( 370, 25 )			-- Set the size (X,Y)
					characterEyeHeight:SetText( "characterEyeHeight" )	-- Set the text above the slider
					characterEyeHeight:SetMin( 25.0 )				 	-- Set the minimum number you can slide to
					characterEyeHeight:SetMax( 66.8 )				-- Set the maximum number you can slide to
					characterEyeHeight:SetDecimals( 1 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					characterEyeHeight:SetConVar( "vrmod_characterEyeHeight" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					characterEyeHeight.OnValueChanged = function( self, value )
							LocalPlayer():ConCommand("vrmod_character_apply")

					end
			--DNumSlider end				
				
			--DNumSlider Start
				--crouchthreshold
				local crouchthreshold= vgui.Create( "DNumSlider", Panel2 )
					crouchthreshold:SetPos( 20, 80 )				-- Set the position (X,Y)
					crouchthreshold:SetSize( 370, 25 )			-- Set the size (X,Y)
					crouchthreshold:SetText( "crouchthreshold" )	-- Set the text above the slider
					crouchthreshold:SetMin( 1.0 )				 	-- Set the minimum number you can slide to
					crouchthreshold:SetMax( 66.8 )				-- Set the maximum number you can slide to
					crouchthreshold:SetDecimals( 1 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					crouchthreshold:SetConVar( "vrmod_crouchthreshold" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					crouchthreshold.OnValueChanged = function( self, value )
					end
			--DNumSlider end				
				
								
				
			--DNumSlider Start
				--characterHeadToHmdDist
				local characterHeadToHmdDist= vgui.Create( "DNumSlider", Panel2 )
					characterHeadToHmdDist:SetPos( 20, 100 )				-- Set the position (X,Y)
					characterHeadToHmdDist:SetSize( 370, 25 )			-- Set the size (X,Y)
					characterHeadToHmdDist:SetText( "characterHeadToHmdDist" )	-- Set the text above the slider
					characterHeadToHmdDist:SetMin( -15.3 )				 	-- Set the minimum number you can slide to
					characterHeadToHmdDist:SetMax( 15.3 )				-- Set the maximum number you can slide to
					characterHeadToHmdDist:SetDecimals( 2 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					characterHeadToHmdDist:SetConVar( "vrmod_characterHeadToHmdDist" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					characterHeadToHmdDist.OnValueChanged = function( self, value )
					
					-- Called when the slider value changes
					end
			--DNumSlider end
								
			--DButton Start
				--character_restart
				local character_restart = vgui.Create( "DButton", Panel2 ) -- Create the button and parent it to the frame
				character_restart:SetText( "Apply \n (VRMod Restart)" )					-- Set the text on the button
				character_restart:SetPos( 190, 130 )					-- Set the position on the frame
				character_restart:SetSize( 160, 30 )					-- Set the size
				character_restart.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
					RunConsoleCommand( "vrmod_character_restart" )			-- Run the console command "say hi" when you click it ( command, args )
				end

				character_restart.DoRightClick = function()
					RunConsoleCommand( "vrmod_character_restart" )			-- Run the console command "say hi" when you click it ( command, args )
				end
			--DButton end

						--DButton Start
				--character_auto
				local character_auto = vgui.Create( "DButton", Panel2 ) -- Create the button and parent it to the frame
				character_auto:SetText( "AutoAdjest \n (VRMod Restart)" )					-- Set the text on the button
				character_auto:SetPos( 20, 130 )					-- Set the position on the frame
				character_auto:SetSize( 160, 30 )					-- Set the size
				character_auto.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
					RunConsoleCommand( "vrmod_character_auto" )			-- Run the console command "say hi" when you click it ( command, args )							
					timer.Simple(1, function()
						RunConsoleCommand( "vrmod_scale_auto" )			-- Run the console command "say hi" when you click it ( command, args )					
					end)
					timer.Simple(1, function()
						RunConsoleCommand( "vrmod_character_restart" )			-- Run the console command "say hi" when you click it ( command, args )
					end)
				end

				character_auto.DoRightClick = function()
					RunConsoleCommand( "vrmod_character_auto" )			-- Run the console command "say hi" when you click it ( command, args )							
				end
			--DButton end


			--DCheckBoxLabel Start
				local oldcharacteryaw = Panel2:Add( "DCheckBoxLabel" ) -- Create the checkbox
					oldcharacteryaw:SetPos( 20, 180 )						-- Set the position
					oldcharacteryaw:SetText("Alternative Character Yaw")					-- Set the text next to the box
					oldcharacteryaw:SetConVar( "vrmod_oldcharacteryaw" )				-- Change a ConVar when the box it ticked/unticked
					-- oldcharacteryaw:SetValue( true )						-- Initial value
					oldcharacteryaw:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end
				
			--DCheckBoxLabel Start
				local animation_Enable = Panel2:Add( "DCheckBoxLabel" ) -- Create the checkbox
					animation_Enable:SetPos( 20, 200 )						-- Set the position
					animation_Enable:SetText("Character_Animation_Enable (Client)")					-- Set the text next to the box
					animation_Enable:SetConVar( "vrmod_animation_Enable" )				-- Change a ConVar when the box it ticked/unticked
					animation_Enable:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local vrmod_characterlogic_alt = Panel2:Add( "DCheckBoxLabel" ) -- Create the checkbox
				vrmod_characterlogic_alt:SetPos( 20, 220 )						-- Set the position
				vrmod_characterlogic_alt:SetText("Character_logic_alt (Client)")					-- Set the text next to the box
				vrmod_characterlogic_alt:SetConVar( "vrmod_characterlogic_alt" )				-- Change a ConVar when the box it ticked/unticked
				vrmod_characterlogic_alt:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

				

			--DCheckBoxLabel Start
				local seatedmode = Panel2:Add( "DCheckBoxLabel" ) -- Create the checkbox
					seatedmode:SetPos( 20, 240 )						-- Set the position
					seatedmode:SetText("Enable seated mode")					-- Set the text next to the box
					seatedmode:SetConVar( "vrmod_seated" )				-- Change a ConVar when the box it ticked/unticked
					seatedmode:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end



			--DNumSlider Start
				--seatedoffset
				local seatedoffset = vgui.Create( "DNumSlider", Panel2 )
					seatedoffset:SetPos( 20, 260 )				-- Set the position (X,Y)
					seatedoffset:SetSize( 370, 25 )			-- Set the size (X,Y)
					seatedoffset:SetText( "Seated Offset" )	-- Set the text above the slider
					seatedoffset:SetMin( -66.80 )				 	-- Set the minimum number you can slide to
					seatedoffset:SetMax( 66.80 )				-- Set the maximum number you can slide to
					seatedoffset:SetDecimals( 2 )				-- Decimal places - zero for whole number(set 2 -> 0.00)
					seatedoffset:SetConVar( "vrmod_seatedoffset" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					seatedoffset.OnValueChanged = function( self, value )
						-- Called when the slider value changes
					end
			--DNumSlider end
								
				
			--DButton Start
				--character_restart
				local ToggleMirror = vgui.Create( "DButton", Panel2 ) -- Create the button and parent it to the frame
				ToggleMirror:SetText( "Toggle Mirror" )					-- Set the text on the button
				ToggleMirror:SetPos( 20, 310 )					-- Set the position on the frame
				ToggleMirror:SetSize( 160, 30 )					-- Set the size
				ToggleMirror.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
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
				local character_reset = vgui.Create( "DButton", Panel2 ) -- Create the button and parent it to the frame
				character_reset:SetText( "vrmod_character_reset" )					-- Set the text on the button
				character_reset:SetPos( 190, 310 )					-- Set the position on the frame
				character_reset:SetSize( 160, 30 )					-- Set the size
				character_reset.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
					RunConsoleCommand( "vrmod_character_reset" )			-- Run the console command "say hi" when you click it ( command, args )
				end

				character_reset.DoRightClick = function()

				end
			--DButton end

				
		--Panel2 "TAB2" end



			
			
			
			
			local Panel3 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "Client02", Panel3, "icon16/palette.png" )
			Panel3.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 

		--Panel3 "TAB3" Start

			--DNumSlider Start
					--cameraoverride
					local cameraoverride= vgui.Create( "DCheckBoxLabel", Panel3 )
						cameraoverride:SetPos( 20, 10 )			-- Set the position (X,Y)
						cameraoverride:SetSize( 320, 25 )			-- Set the size (X,Y)
						cameraoverride:SetText( "[Desktop_CameraOverride]\nON = Default. The VR view is directly reflected in the gmod window.\nOFF = If you use a TPSmod or similar, the gmod window will be\n            the screen of the camera mod.\n(If OFF,There is a bug that your body will not be reflected\nwhen you are not using a camera mod, etc.)" )	-- Set the text above the slider
						cameraoverride:SetConVar( "vrmod_cameraoverride" )	-- Changes the ConVar when you slide
						-- If not using convars, you can use this hook + Panel.SetValue()
						cameraoverride.OnValueChanged = function( self, value )
							
						-- Called when the slider value changes
						end
			--DNumSlider end


			--DNumSlider Start
				--vr_vrmod_znear
				local vrmod_znear= vgui.Create( "DNumSlider", Panel3 )
					vrmod_znear:SetPos( 20, 100 )				-- Set the position (X,Y)
					vrmod_znear:SetSize( 370, 120 )			-- Set the size (X,Y)
					vrmod_znear:SetText( "[znear]\n(VRMod Restart Requied)\nObjects at distances less than\nthis value become transparent\nIf you are using a player model\nwith hair or head parts\nthat appear in front of you\nyou may want to set a larger\nvalue." )	-- Set the text above the slider
					vrmod_znear:SetMin( 1.00 )				 	-- Set the minimum number you can slide to
					vrmod_znear:SetMax( 20.00 )				-- Set the maximum number you can slide to
					vrmod_znear:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					vrmod_znear:SetConVar( "vrmod_znear" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					vrmod_znear.OnValueChanged = function( self, value )
					-- Called when the slider value changes
					end
			--DNumSlider end

			--DCheckBoxLabel Start
				local vrmod_mapbrowser = Panel3:Add( "DCheckBoxLabel" ) -- Create the checkbox
					vrmod_mapbrowser:SetPos( 20, 250 )						-- Set the position
					vrmod_mapbrowser:SetText("[quickmenu_mapbrowser_enable]\nON = Show the Map Browser button in the Quick Menu\nOFF = Do not display the map browser button")					-- Set the text next to the box
					vrmod_mapbrowser:SetConVar( "vrmod_mapbrowser_enable" )				-- Change a ConVar when the box it ticked/unticked
					vrmod_mapbrowser:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end


			--DCheckBoxLabel Start
				local vrmod_shutdownmenu = Panel3:Add( "DCheckBoxLabel" ) -- Create the checkbox
				vrmod_shutdownmenu:SetPos( 20, 300 )						-- Set the position
				vrmod_shutdownmenu:SetText("[quickmenu VR EXIT button]\nON = Show the [VR EXIT] button in the Quick Menu\nOFF = Do not the [VR EXIT] in the Quick Menu")					-- Set the text next to the box
				vrmod_shutdownmenu:SetConVar( "vrmod_shutdownmenu" )				-- Change a ConVar when the box it ticked/unticked
				vrmod_shutdownmenu:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end



			
		--Panel3 "TAB3" end

			
		--Panel5 "TAB5" Start
			local Panel5 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "Server", Panel5, "icon16/ipod_cast_add.png" )
			Panel5.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
				
			--DNumSlider Start
				--vr_net_delay
				local net_delay= vgui.Create( "DNumSlider", Panel5 )
					net_delay:SetPos( 20, 25 )				-- Set the position (X,Y)
					net_delay:SetSize( 370, 25 )			-- Set the size (X,Y)
					net_delay:SetText( "net_delay" )	-- Set the text above the slider
					net_delay:SetMin(0.000)				 	-- Set the minimum number you can slide to
					net_delay:SetMax(1.000)				-- Set the maximum number you can slide to
					net_delay:SetDecimals( 3 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					net_delay:SetConVar( "vrmod_net_delay" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					net_delay.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end
				
			--DNumSlider Start
				--vr_net_delaymax
				local net_delaymax= vgui.Create( "DNumSlider", Panel5 )
					net_delaymax:SetPos( 20, 50 )				-- Set the position (X,Y)
					net_delaymax:SetSize( 370, 25 )			-- Set the size (X,Y)
					net_delaymax:SetText( "net_delaymax" )	-- Set the text above the slider
					net_delaymax:SetMin( 1.00 )				 	-- Set the minimum number you can slide to
					net_delaymax:SetMax( 100.00 )				-- Set the maximum number you can slide to
					net_delaymax:SetDecimals( 3 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					net_delaymax:SetConVar( "vrmod_net_delaymax" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					net_delaymax.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end
				
			--DNumSlider Start
				--vr_net_storedframes
				local net_storedframes= vgui.Create( "DNumSlider", Panel5 )
					net_storedframes:SetPos( 20, 75 )				-- Set the position (X,Y)
					net_storedframes:SetSize( 370, 25 )			-- Set the size (X,Y)
					net_storedframes:SetText( "net_storedframes" )	-- Set the text above the slider
					net_storedframes:SetMin( 1.00 )				 	-- Set the minimum number you can slide to
					net_storedframes:SetMax( 25.00 )				-- Set the maximum number you can slide to
					net_storedframes:SetDecimals( 3 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					net_storedframes:SetConVar( "vrmod_net_storedframes" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					net_storedframes.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DNumSlider Start
				--vr_net_tickrate
				local net_tickrate= vgui.Create( "DNumSlider", Panel5 )
					net_tickrate:SetPos( 20, 100 )				-- Set the position (X,Y)
					net_tickrate:SetSize( 370, 25 )			-- Set the size (X,Y)
					net_tickrate:SetText( "net_tickrate" )	-- Set the text above the slider
					net_tickrate:SetMin( 1.00 )				 	-- Set the minimum number you can slide to
					net_tickrate:SetMax( 100.00 )				-- Set the maximum number you can slide to
					net_tickrate:SetDecimals( 3 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					net_tickrate:SetConVar( "vrmod_net_tickrate" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					net_tickrate.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DCheckBoxLabel Start
				local allow_teleport = Panel5:Add( "DCheckBoxLabel" ) -- Create the checkbox
					allow_teleport:SetPos( 20, 130 )						-- Set the position
					allow_teleport:SetText("server allow VRteleport")					-- Set the text next to the box
					allow_teleport:SetConVar( "vrmod_allow_teleport" )				-- Change a ConVar when the box it ticked/unticked
					allow_teleport:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end


			--DNumSlider Start
				--vrmod_pickup_weight
				local pickup_weight= vgui.Create( "DNumSlider", Panel5 )
					pickup_weight:SetPos( 20, 175 )				-- Set the position (X,Y)
					pickup_weight:SetSize( 370, 25 )			-- Set the size (X,Y)
					pickup_weight:SetText( "pickup_weight(serverlimit)" )	-- Set the text above the slider
					pickup_weight:SetMin( 1 )				 	-- Set the minimum number you can slide to
					pickup_weight:SetMax( 1000 )				-- Set the maximum number you can slide to
					pickup_weight:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					pickup_weight:SetConVar( "vrmod_pickup_weight" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					pickup_weight.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DNumSlider Start
				--vr_vrmod_pickup_range
				local vrmod_pickup_range= vgui.Create( "DNumSlider", Panel5 )
					vrmod_pickup_range:SetPos( 20, 200 )				-- Set the position (X,Y)
					vrmod_pickup_range:SetSize( 370, 25 )			-- Set the size (X,Y)
					vrmod_pickup_range:SetText( "vrmod_pickup_range(serverlimit)" )	-- Set the text above the slider
					vrmod_pickup_range:SetMin( 1.0 )				 	-- Set the minimum number you can slide to
					vrmod_pickup_range:SetMax( 99.0 )				-- Set the maximum number you can slide to
					vrmod_pickup_range:SetDecimals( 1 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					vrmod_pickup_range:SetConVar( "vrmod_pickup_range" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					vrmod_pickup_range.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DNumSlider Start
				--vr_vrmod_pickup_limit
				local vrmod_pickup_limit= vgui.Create( "DNumSlider", Panel5 )
					vrmod_pickup_limit:SetPos( 20, 225 )				-- Set the position (X,Y)
					vrmod_pickup_limit:SetSize( 370, 25 )			-- Set the size (X,Y)
					vrmod_pickup_limit:SetText( "vrmod_pickup_limit" )	-- Set the text above the slider
					vrmod_pickup_limit:SetMin( 0 )				 	-- Set the minimum number you can slide to
					vrmod_pickup_limit:SetMax( 2 )				-- Set the maximum number you can slide to
					vrmod_pickup_limit:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					vrmod_pickup_limit:SetConVar( "vrmod_pickup_limit" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					vrmod_pickup_limit.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

		-- --Panel5 "TAB5" end
				
		--Panel6 "TAB6" Start
			local Panel6 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "FPS&Graphic", Panel6, "icon16/picture_key.png" )
			Panel6.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
				
			--DCheckBoxLabel Start
				local r_3dsky = Panel6:Add( "DCheckBoxLabel" ) -- Create the checkbox
					r_3dsky:SetPos( 20, 10 )						-- Set the position
					r_3dsky:SetText("Skybox Enable(Client)")					-- Set the text next to the box
					r_3dsky:SetConVar( "r_3dsky" )				-- Change a ConVar when the box it ticked/unticked
					r_3dsky:SizeToContents()						-- Make its size the same as the contents
				--DCheckBoxLabel end
				
				--DCheckBoxLabel Start
				local r_shadows = Panel6:Add( "DCheckBoxLabel" ) -- Create the checkbox
					r_shadows:SetPos( 20, 30 )						-- Set the position
					r_shadows:SetText("Shadows Enable(Client)")					-- Set the text next to the box
					r_shadows:SetConVar( "r_shadows" )				-- Change a ConVar when the box it ticked/unticked
					r_shadows:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

								
			--DNumSlider Start
				--vr_r_farz
				local r_farz= vgui.Create( "DNumSlider", Panel6 )
					r_farz:SetPos( 20, 50 )				-- Set the position (X,Y)
					r_farz:SetSize( 370, 25 )			-- Set the size (X,Y)
					r_farz:SetText( "[Visible range of map] \n (sv_cheats 1 is required)" )	-- Set the text above the slider
					r_farz:SetMin( 1000 )				 	-- Set the minimum number you can slide to
					r_farz:SetMax( 16384 )				-- Set the maximum number you can slide to
					r_farz:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					r_farz:SetConVar( "r_farz" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					r_farz.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end


			--DNumSlider Start
				--mat_queue_mode
				local mat_queue_mode= vgui.Create( "DNumSlider", Panel6 )
					mat_queue_mode:SetPos( 20, 80 )				-- Set the position (X,Y)
					mat_queue_mode:SetSize( 370, 120 )			-- Set the size (X,Y)
					mat_queue_mode:SetText( "[mat_queue_mode]\n(Blindness Warning!!!)\nSetting to [1] or [2] will\nenable the multi-core \nand increase FPS\nbut it will also make your right eye\nblink more intensely, which\nwill hurt your eyes.\n[0] is recommended." )	-- Set the text above the slider
					mat_queue_mode:SetMin( -1 )				 	-- Set the minimum number you can slide to
					mat_queue_mode:SetMax( 2 )				-- Set the maximum number you can slide to
					mat_queue_mode:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					mat_queue_mode:SetConVar( "mat_queue_mode" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					mat_queue_mode.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DNumSlider Start
				--fps_max
				local fps_max= vgui.Create( "DNumSlider", Panel6 )
					fps_max:SetPos( 20, 200 )				-- Set the position (X,Y)
					fps_max:SetSize( 370, 110 )			-- Set the size (X,Y)
					fps_max:SetText( "[fps_max]\nIf fps is reduced when the multi core test is set to [1]\n the blinking will be reduced.\nIf the fps does not change from 45\nthe fps may be limited by the\nSSW function of hmd." )	-- Set the text above the slider
					fps_max:SetMin( 15 )				 	-- Set the minimum number you can slide to
					fps_max:SetMax( 120 )				-- Set the maximum number you can slide to
					fps_max:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					fps_max:SetConVar( "fps_max" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					fps_max.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end


			--DButton Start
				--gmod_optimization
				local gmod_optimization = vgui.Create( "DButton", Panel6 ) -- Create the button and parent it to the frame
				gmod_optimization:SetText( "vrmod_gmod_optimization" )					-- Set the text on the button
				gmod_optimization:SetPos( 20, 310 )					-- Set the position on the frame
				gmod_optimization:SetSize( 330, 30 )					-- Set the size
				gmod_optimization.DoClick = function()				-- A custom function run when clicked ( note the . instead of : )
					RunConsoleCommand( "vrmod_gmod_optimization" )			-- Run the console command "say hi" when you click it ( command, args )
				end

				gmod_optimization.DoRightClick = function()
					RunConsoleCommand( "vrmod_gmod_optimization" )
				end
			--DButton end		
		--Panel6 "TAB6" end
				
		--Panel7 "TAB7" Start
			local Panel7 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "Misc", Panel7, "icon16/computer_edit.png" )
			Panel7.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
				
				
			--DCheckBoxLabel Start
				local showonstartup = Panel7:Add( "DCheckBoxLabel" ) -- Create the checkbox
					showonstartup:SetPos( 20, 10 )						-- Set the position
					showonstartup:SetText("[vrmod_showonstartup]")					-- Set the text next to the box
					showonstartup:SetConVar( "vrmod_showonstartup" )				-- Change a ConVar when the box it ticked/unticked
					showonstartup:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end



			--DCheckBoxLabel Start
				local pmchange = Panel7:Add( "DCheckBoxLabel" ) -- Create the checkbox
					pmchange:SetPos( 20, 30 )						-- Set the position
					pmchange:SetText("[vrmod_pmchange]")					-- Set the text next to the box
					pmchange:SetConVar( "vrmod_pmchange" )				-- Change a ConVar when the box it ticked/unticked
					pmchange:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DNumSlider Start
				--flashlight_attachment
				local flashlight_attachment= vgui.Create( "DNumSlider", Panel7 )
					flashlight_attachment:SetPos( 20, 60 )				-- Set the position (X,Y)
					flashlight_attachment:SetSize( 330, 25 )			-- Set the size (X,Y)
					flashlight_attachment:SetText( "[flashlight_attachment]" )	-- Set the text above the slider
					flashlight_attachment:SetMin( 0 )				 	-- Set the minimum number you can slide to
					flashlight_attachment:SetMax( 2 )				-- Set the maximum number you can slide to
					flashlight_attachment:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					flashlight_attachment:SetConVar( "vrmod_flashlight_attachment" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					flashlight_attachment.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DNumSlider Start
				--storedframes
				local storedframes= vgui.Create( "DNumSlider", Panel7 )
					storedframes:SetPos( 20, 90 )				-- Set the position (X,Y)
					storedframes:SetSize( 330, 25 )			-- Set the size (X,Y)
					storedframes:SetText( "[net_storedframes]" )	-- Set the text above the slider
					storedframes:SetMin( 0 )				 	-- Set the minimum number you can slide to
					storedframes:SetMax( 2 )				-- Set the maximum number you can slide to
					storedframes:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
					storedframes:SetConVar( "net_storedframes" )	-- Changes the ConVar when you slide

					-- If not using convars, you can use this hook + Panel.SetValue()
					storedframes.OnValueChanged = function( self, value )

					-- Called when the slider value changes
					end
			--DNumSlider end

			--DCheckBoxLabel Start
				local manualpickup = Panel7:Add( "DCheckBoxLabel" ) -- Create the checkbox
					manualpickup:SetPos( 10, 120 )						-- Set the position
					manualpickup:SetText("[vrmod_manualpickups(Server)]\nUse of this requires\n{VRMod Manual Item Pickup}\nby Dr. Hugo.\nhttps://steamcommunity.com/sharedfiles/filedetails/?id=2910621738\nAllows manual pickup of supplies and weaponsto increase immersion.\nDisables automatic pickup when walkin over an item.")-- Set the text next to the box
					manualpickup:SetConVar( "vrmod_manualpickups" )				-- Change a ConVar when the box it ticked/unticked
					manualpickup:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			
			--DCheckBoxLabel Start
				local vrmod_error_check_method = Panel7:Add( "DCheckBoxLabel" ) -- Create the checkbox
				vrmod_error_check_method:SetPos( 20, 220 )						-- Set the position
				vrmod_error_check_method:SetText("[error_check_method]\nIf it does not start VRMod\n change this and restart.")					-- Set the text next to the box
				vrmod_error_check_method:SetConVar( "vrmod_error_check_method" )				-- Change a ConVar when the box it ticked/unticked
				vrmod_error_check_method:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			-- --DCheckBoxLabel Start
			-- 	local vrmod_test_keydown = Panel7:Add( "DCheckBoxLabel" ) -- Create the checkbox
			-- 	vrmod_test_keydown:SetPos( 20, 270 )						-- Set the position
			-- 	vrmod_test_keydown:SetText("[keydown_inputtest]")					-- Set the text next to the box
			-- 	vrmod_test_keydown:SetConVar( "keydown_inputtest" )				-- Change a ConVar when the box it ticked/unticked
			-- 	vrmod_test_keydown:SizeToContents()						-- Make its size the same as the contents
			-- --DCheckBoxLabel end
			
			-- --DLabel&DTextEntry Start
				-- local emptyhanded_swep_label = Panel7:Add( "DLabel" )
				-- emptyhanded_swep_label:SetPos( 10, 215 ) -- Set the position of the label
				-- emptyhanded_swep_label:SetText( "vrmod_emptyhanded_swep" ) --  Set the text of the label
				-- emptyhanded_swep_label:SizeToContents() -- Size the label to fit the text in it
				-- emptyhanded_swep_label:SetDark( 0 ) -- Set the colour of the text inside the label to a darker one

				-- local emptyhanded_swep = Panel7:Add( "DTextEntry" )
				-- emptyhanded_swep_String = GetConVar("vrmod_emptyhanded_swep"):GetString()
				-- emptyhanded_swep:SetPos( 20, 230 )						-- Set the position
				-- emptyhanded_swep:SetSize( 330, 25 )			-- Set the size (X,Y)
				-- emptyhanded_swep:SetUpdateOnType(0)						-- Set the position
				-- emptyhanded_swep:SetValue( emptyhanded_swep_String )
				-- emptyhanded_swep.OnEnter = function( self )
					-- emptyhanded_swep:UpdateConvarValue( "vrmod_emptyhanded_swep" )				-- Change a ConVar when the box it ticked/unticked
				-- end
			-- --DLabel&DTextEntry end



		-- Panel7 "TAB7" End


		--Panel8 "TAB8" Start
			local Panel8 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "Misc02", Panel8, "icon16/computer_edit.png" )
			Panel8.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
				
				
			--DCheckBoxLabel Start
				local menu_automcore = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				menu_automcore:SetPos( 20, 10 )						-- Set the position
				menu_automcore:SetText("[VRMenu Auto Set mcore_0]")					-- Set the text next to the box
				menu_automcore:SetConVar( "vrmod_open_menu_automcore" )				-- Change a ConVar when the box it ticked/unticked
				menu_automcore:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local autojumpduck = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				autojumpduck:SetPos( 20, 30 )						-- Set the position
				autojumpduck:SetText("[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP")					-- Set the text next to the box
				autojumpduck:SetConVar( "vrmod_autojumpduck" )				-- Change a ConVar when the box it ticked/unticked
				autojumpduck:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local contextmenu_button = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				contextmenu_button:SetPos( 20, 80 )						-- Set the position
				contextmenu_button:SetText("[enable_contextmenu_button]")					-- Set the text next to the box
				contextmenu_button:SetConVar( "vrmod_enable_contextmenu_button" )				-- Change a ConVar when the box it ticked/unticked
				contextmenu_button:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local arccwbenchview_button = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				arccwbenchview_button:SetPos( 20, 110 )						-- Set the position
				arccwbenchview_button:SetText("[arccw_dev_benchgun]")					-- Set the text next to the box
				arccwbenchview_button:SetConVar( "arccw_dev_benchgun" )				-- Change a ConVar when the box it ticked/unticked
				arccwbenchview_button:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local arc9benchview_button = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				arc9benchview_button:SetPos( 20, 140 )						-- Set the position
				arc9benchview_button:SetText("[arc9_dev_benchgun]")					-- Set the text next to the box
				arc9benchview_button:SetConVar( "arc9_dev_benchgun" )				-- Change a ConVar when the box it ticked/unticked
				arc9benchview_button:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local autoarcbench_button = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				autoarcbench_button:SetPos( 20, 170 )						-- Set the position
				autoarcbench_button:SetText("[vrmod_auto_arc_benchgun]")					-- Set the text next to the box
				autoarcbench_button:SetConVar( "vrmod_auto_arc_benchgun" )				-- Change a ConVar when the box it ticked/unticked
				autoarcbench_button:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local cl_drawhud = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				cl_drawhud:SetPos( 20, 200 )						-- Set the position
				cl_drawhud:SetText("[cl_drawhud]")					-- Set the text next to the box
				cl_drawhud:SetConVar( "cl_drawhud" )				-- Change a ConVar when the box it ticked/unticked
				cl_drawhud:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local vrgrab_gravitygloves = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				vrgrab_gravitygloves:SetPos( 20, 230 )						-- Set the position
				vrgrab_gravitygloves:SetText("[vrgrab_gravitygloves]")					-- Set the text next to the box
				vrgrab_gravitygloves:SetConVar( "vrgrab_gravitygloves" )				-- Change a ConVar when the box it ticked/unticked
				vrgrab_gravitygloves:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local vrgrab_gravitygloves_minrange = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				vrgrab_gravitygloves_minrange:SetPos( 20, 260 )						-- Set the position
				vrgrab_gravitygloves_minrange:SetText("[vrgrab_gravitygloves_minrange]")					-- Set the text next to the box
				vrgrab_gravitygloves_minrange:SetConVar( "vrgrab_gravitygloves_minrange" )				-- Change a ConVar when the box it ticked/unticked
				vrgrab_gravitygloves_minrange:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end

			--DCheckBoxLabel Start
				local vrgrab_range = Panel8:Add( "DCheckBoxLabel" ) -- Create the checkbox
				vrgrab_range:SetPos( 20, 290 )						-- Set the position
				vrgrab_range:SetText("[vrgrab_range]")					-- Set the text next to the box
				vrgrab_range:SetConVar( "vrgrab_range" )				-- Change a ConVar when the box it ticked/unticked
				vrgrab_range:SizeToContents()						-- Make its size the same as the contents
			--DCheckBoxLabel end


		-- Panel8 "TAB8" End	

		--Panel9 "TAB9" Start
			local Panel9 = vgui.Create( "DPanel", sheet )
			sheet:AddSheet( "GameRebootRequied", Panel9, "icon16/computer_edit.png" )
			Panel9.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, self:GetAlpha() ) ) end 
				
				
			--DNumSlider Start
			--vrmod_ScrH
			local vrmod_ScrH = vgui.Create( "DNumSlider", Panel9 )
			vrmod_ScrH:SetPos( 20, 10 )				-- Set the position (X,Y)
			vrmod_ScrH:SetSize( 330, 25 )			-- Set the size (X,Y)
			vrmod_ScrH:SetText( "[VR_UI Height]" )	-- Set the text above the slider
			vrmod_ScrH:SetMin( 480 )				 	-- Set the minimum number you can slide to
			vrmod_ScrH:SetMax( ScrH() )				-- Set the maximum number you can slide to
			vrmod_ScrH:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
			vrmod_ScrH:SetConVar( "vrmod_ScrH" )	-- Changes the ConVar when you slide

				-- If not using convars, you can use this hook + Panel.SetValue()
				vrmod_ScrH.OnValueChanged = function( self, value )

				-- Called when the slider value changes
				end
			--DNumSlider end
		
			--DNumSlider Start
			--vrmod_ScrW
			local vrmod_ScrW = vgui.Create( "DNumSlider", Panel9 )
			vrmod_ScrW:SetPos( 20, 30 )				-- Set the position (X,Y)
			vrmod_ScrW:SetSize( 330, 25 )			-- Set the size (X,Y)
			vrmod_ScrW:SetText( "[VR_UI Weight]" )	-- Set the text above the slider
			vrmod_ScrW:SetMin( 640 )				 	-- Set the minimum number you can slide to
			vrmod_ScrW:SetMax( ScrW() )				-- Set the maximum number you can slide to
			vrmod_ScrW:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
			vrmod_ScrW:SetConVar( "vrmod_ScrW" )	-- Changes the ConVar when you slide

				-- If not using convars, you can use this hook + Panel.SetValue()
				vrmod_ScrW.OnValueChanged = function( self, value )

				-- Called when the slider value changes
				end
			--DNumSlider end



			--DNumSlider Start
			--vrmod_hud_ScrH
			local vrmod_hud_ScrH = vgui.Create( "DNumSlider", Panel9 )
			vrmod_hud_ScrH:SetPos( 20, 60 )				-- Set the position (X,Y)
			vrmod_hud_ScrH:SetSize( 330, 25 )			-- Set the size (X,Y)
			vrmod_hud_ScrH:SetText( "[VR_HUD Height]" )	-- Set the text above the slider
			vrmod_hud_ScrH:SetMin( 480 )				 	-- Set the minimum number you can slide to
			vrmod_hud_ScrH:SetMax( ScrH() )				-- Set the maximum number you can slide to
			vrmod_hud_ScrH:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
			vrmod_hud_ScrH:SetConVar( "vrmod_ScrH_hud" )	-- Changes the ConVar when you slide

				-- If not using convars, you can use this hook + Panel.SetValue()
				vrmod_hud_ScrH.OnValueChanged = function( self, value )

				-- Called when the slider value changes
				end
			--DNumSlider end
		
			--DNumSlider Start
			--vrmod_ScrW_hud
			local vrmod_ScrW_hud = vgui.Create( "DNumSlider", Panel9 )
			vrmod_ScrW_hud:SetPos( 20, 80 )				-- Set the position (X,Y)
			vrmod_ScrW_hud:SetSize( 330, 25 )			-- Set the size (X,Y)
			vrmod_ScrW_hud:SetText( "[VR_HUD Weight]" )	-- Set the text above the slider
			vrmod_ScrW_hud:SetMin( 640 )				 	-- Set the minimum number you can slide to
			vrmod_ScrW_hud:SetMax( ScrW() )				-- Set the maximum number you can slide to
			vrmod_ScrW_hud:SetDecimals( 0 )				-- Decimal places - zero for whole number (set 2 -> 0.00)
			vrmod_ScrW_hud:SetConVar( "vrmod_ScrW_hud" )	-- Changes the ConVar when you slide

				-- If not using convars, you can use this hook + Panel.SetValue()
				vrmod_ScrW_hud.OnValueChanged = function( self, value )

				-- Called when the slider value changes
				end
			--DNumSlider end

			--DLabel&DTextEntry Start
			local FlohandmodelL = Panel9:Add( "DLabel" )
			FlohandmodelL:SetPos( 10, 260 ) -- Set the position of the label
			FlohandmodelL:SetText( "floatinghands_model" ) --  Set the text of the label
			FlohandmodelL:SizeToContents() -- Size the label to fit the text in it
			FlohandmodelL:SetDark( 0 ) -- Set the colour of the text inside the label to a darker one

			local floatinghands_model = Panel9:Add( "DTextEntry" )
			Flohandmodel_String = GetConVar("vrmod_floatinghands_model"):GetString()
			floatinghands_model:SetPos( 20, 275 )						-- Set the position
			floatinghands_model:SetSize( 330, 25 )			-- Set the size (X,Y)
			floatinghands_model:SetUpdateOnType(0)						-- Set the position
			floatinghands_model:SetValue( Flohandmodel_String )
			floatinghands_model.OnEnter = function( self )
				floatinghands_model:UpdateConvarValue( "vrmod_floatinghands_model" )				-- Change a ConVar when the box it ticked/unticked
			end
			--DLabel&DTextEntry end

			--DLabel&DTextEntry Start
			local FlohandmatelialL = Panel9:Add( "DLabel" )
			FlohandmatelialL:SetPos( 10, 305 ) -- Set the position of the label
			FlohandmatelialL:SetText( "floatinghands_material" ) --  Set the text of the label
			FlohandmatelialL:SizeToContents() -- Size the label to fit the text in it
			FlohandmatelialL:SetDark( 0 ) -- Set the colour of the text inside the label to a darker one

			local floatinghands_material = Panel9:Add( "DTextEntry" )
			Flohandmat_String = GetConVar("vrmod_floatinghands_material"):GetString()
			floatinghands_material:SetPos( 20, 320 )						-- Set the position
			floatinghands_material:SetSize( 330, 25 )			-- Set the size (X,Y)
			floatinghands_material:SetUpdateOnType(0)						-- Set the position
			floatinghands_material:SetValue( Flohandmat_String )
			floatinghands_material.OnEnter = function( self )
				floatinghands_material:UpdateConvarValue( "vrmod_floatinghands_material" )				-- Change a ConVar when the box it ticked/unticked
			end
			--DLabel&DTextEntry end



		-- Panel9 "TAB9" End


				
	--Settings02 end
	

end)


