if SERVER then return end

local open = false
local button1on = 0
local button2on = 0
local button3on = 0
local button4on = 0
local button5on = 0
local button6on = 0
local button7on = 0
local button8on = 0
local button9on = 0
local buttonAon = 0
local buttonBon = 0
local buttonCon = 0
local buttonDon = 0
local BUTTON_2TIER = {Color(80, 0, 51), Color(51, 120, 51)}
local BUTTON_3TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51)}
local BUTTON_4TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51), Color(0, 0, 139)}
local BUTTON_5TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51), Color(0, 0, 139),Color(139, 0, 139)}


function vre_svmenuToggle()
    if !open then
        vre_svmenuOpen()
    else
        VRUtilMenuClose("vre_svmenu")
    end
end


function vre_svmenuOpen()
	if open then return end
    open = true


    local vre_svmenuPanel = vgui.Create( "DPanel" )
    vre_svmenuPanel:SetPos( 0, 0 )
    vre_svmenuPanel:SetSize( 600, 650 )
    function vre_svmenuPanel:GetSize()
        return 450,310
    end



    local grid = vgui.Create("DGrid", vre_svmenuPanel)
    grid:SetPos( 10, 30 )
    grid:SetCols( 4 )
    grid:SetColWide( 150 )
    grid:SetRowHeight( 80 )


    local backbutton = vgui.Create("DButton", vre_svmenuPanel)

    backbutton:SetText("<---")
    backbutton:SetSize(60, 30)
    backbutton:SetPos(260, 270)
    backbutton:SetTextColor(Color(255, 255, 255))
    backbutton.DoClick = function()
            VRUtilMenuClose("vre_svmenu")

		
    end


    function backbutton:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
    end



	-- Activate bothmode to be able to press buttons even when using a vehicle.
	LocalPlayer():ConCommand("vrmod_keymode_both")
	
	


--button toggle start
			local button1 = vgui.Create("DButton")
			button1:SetText("pickup_hand_range:")
			button1:SetSize(120, 60)
			button1:SetTextColor(Color(255, 255, 255))
			grid:AddItem(button1)
			button1.DoClick = function()
			--command start
				if button1on == 0 then
				   button1on = 1
					LocalPlayer():ConCommand("vrmod_pickup_range 2.0")
				elseif button1on == 1 then
					button1on = 2
					LocalPlayer():ConCommand("vrmod_pickup_range 5.0")

				elseif button1on == 2 then
					button1on = 3
					LocalPlayer():ConCommand("vrmod_pickup_range 10.00")
				elseif button1on == 3 then
					button1on = 4
					LocalPlayer():ConCommand("vrmod_pickup_range 99.00")
				else
					button1on = 0
					LocalPlayer():ConCommand("vrmod_pickup_range 1.2")
				end
			--command end
			end

			function button1:Paint(w, h)
				button1:SetText("pickup_hand_range: "..GetConVar("vrmod_pickup_range"):GetFloat())
				draw.RoundedBox(8, 0, 0, w, h, BUTTON_5TIER[button1on+1])
			end
--button toggle end


--button toggle start
					local button2 = vgui.Create("DButton")
					button2:SetText("vrmod_pickup_weight \n (server):")
					button2:SetSize(120, 60)
					button2:SetTextColor(Color(255, 255, 255))
					grid:AddItem(button2)
					button2.DoClick = function()
					--command start
						if button2on == 0 then
						   button2on = 1
							LocalPlayer():ConCommand("vrgrab_maxmass 5")
							LocalPlayer():ConCommand("vrmod_pickup_weight 5")
						elseif button2on == 1 then
							button2on = 2
							LocalPlayer():ConCommand("vrgrab_maxmass 100")
							LocalPlayer():ConCommand("vrmod_pickup_weight 100")
						elseif button2on == 2 then
							button2on = 3
							LocalPlayer():ConCommand("vrgrab_maxmass 99999")
							LocalPlayer():ConCommand("vrmod_pickup_weight 99999")
						else
							button2on = 0
							LocalPlayer():ConCommand("vrgrab_maxmass 30")
							LocalPlayer():ConCommand("vrmod_pickup_weight 30")
						end
					--command end
					end

					function button2:Paint(w, h)
						button2:SetText("vrmod_pickup_weight \n (server): "..GetConVar("vrmod_pickup_weight"):GetFloat())
						draw.RoundedBox(8, 0, 0, w, h, BUTTON_4TIER[math.abs(button2on+1)])
					end
--button toggle end


		if not !GetConVar("vrgrab_range") then
--button toggle start
			local button4 = vgui.Create("DButton")
			button4:SetText("vrgrab_pickup_range:")
			button4:SetSize(120, 60)
			button4:SetTextColor(Color(255, 255, 255))
			grid:AddItem(button4)
			button4.DoClick = function()
			--command start
				if button4on == 0 then
				   button4on = 1
					LocalPlayer():ConCommand("vrgrab_range 128")
				elseif button4on == 1 then
					button4on = 2
					LocalPlayer():ConCommand("vrgrab_range 256")
				elseif button4on == 2 then
					button4on = 3
					LocalPlayer():ConCommand("vrgrab_range 480")
				elseif button4on == 3 then
					button4on = 4
					LocalPlayer():ConCommand("vrgrab_range 0")
				else
					button4on = 0
					LocalPlayer():ConCommand("vrgrab_range 72")
				end
			--command end
			end

			function button4:Paint(w, h)
				button4:SetText("vrgrab_range: "..GetConVar("vrgrab_range"):GetFloat())
				draw.RoundedBox(8, 0, 0, w, h, BUTTON_5TIER[button4on+1])
			end
--button toggle end
		end
		
		if not !GetConVar("vrgrab_gravitygloves") then
--2button toggle start
			local button5 = vgui.Create("DButton")
			button5:SetText("vrgrab_gravitygloves: ")
			button5:SetSize(120, 60)
			button5:SetTextColor(Color(255, 255, 255))
			grid:AddItem(button5)
			button5.DoClick = function()
			--command start
				if button5on == 1 then
					button5on = 0
					LocalPlayer():ConCommand("vrgrab_gravitygloves 1")

				else
					button5on = 1
					LocalPlayer():ConCommand("vrgrab_gravitygloves 0")

				end
			--command end
			end

			function button5:Paint(w, h)
				button5:SetText("vrgrab_gravitygloves: "..GetConVar("vrgrab_gravitygloves"):GetInt())
				draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button5on -2)])
			end
--2button toggle end
end

		if not !GetConVar("vrgrab_gravitygloves_minrange") then
		--button toggle start
			local button6 = vgui.Create("DButton")
			button6:SetText("gravitygloves\nminrange:")
			button6:SetSize(120, 60)
			button6:SetTextColor(Color(255, 255, 255))
			grid:AddItem(button6)
			button6.DoClick = function()
			--command start
				if button6on == 0 then
				   button6on = 1
					LocalPlayer():ConCommand("vrgrab_gravitygloves_minrange 60.00")
				elseif button6on == 1 then
					button6on = 2
					LocalPlayer():ConCommand("vrgrab_gravitygloves_minrange 80.00")

				elseif button6on == 2 then
					button6on = 3
					LocalPlayer():ConCommand("vrgrab_gravitygloves_minrange 100.00")
				elseif button6on == 3 then
					button6on = 4
					LocalPlayer():ConCommand("vrgrab_gravitygloves_minrange 0.00")
				else
					button6on = 0
					LocalPlayer():ConCommand("vrgrab_gravitygloves_minrange 24.00")
				end
			--command end
			end

			function button6:Paint(w, h)
				button6:SetText("gravitygloves\nminrange: "..GetConVar("vrgrab_gravitygloves_minrange"):GetFloat())
				draw.RoundedBox(8, 0, 0, w, h, BUTTON_5TIER[button6on+1])
			end
		--button toggle end
		end
		



--2button toggle start
			local button7 = vgui.Create("DButton")
			local ccval7 = {"OFF", "ON"}
			button7:SetText("original pickup\noverride\nproof")
			button7:SetSize(120, 60)
			button7:SetTextColor(Color(255, 255, 255))
			grid:AddItem(button7)
			button7.DoClick = function()
			--command start
				if button7on == 1 then
					button7on = 0
					LocalPlayer():ConCommand("vrmod_pickup_retry 1")
				else
					button7on = 1
					LocalPlayer():ConCommand("vrmod_pickup_retry 0")
				end
			--command end
			end

			function button7:Paint(w, h)
				button7:SetText("original pickup\noverride\nproof"..ccval7[button7on+1])
				draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button7on -2)])
			end

--2button toggle end



-- --2button toggle start

			-- local buttonD = vgui.Create("DButton")
			-- buttonD:SetText("character \n toggle")
			-- buttonD:SetSize(120, 60)
			-- buttonD:SetTextColor(Color(255, 255, 255))
			-- grid:AddItem(buttonD)
			-- buttonD.DoClick = function()
			-- --command start
				-- if buttonDon == 1 then
					-- buttonDon = 0
					-- LocalPlayer():ConCommand("vrmod_character_stop")

				-- else
					-- buttonDon = 1
					-- LocalPlayer():ConCommand("vrmod_character_start")

				-- end
			-- --command end
			-- end

			-- function buttonD:Paint(w, h)
				-- buttonD:SetText("character \n toggle")
				-- draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(buttonDon -2)])
			-- end

-- -- A
-- -- Laserpointer
-- -- vrmod_togglelaserpointer
-- --2button toggle end





-- --2button toggle start

			-- local button(valuehere) = vgui.Create("DButton")
			-- local button(valuehere)on = 0
			-- button(valuehere):SetText("(namehere): ")
			-- button(valuehere):SetSize(120, 60)
			-- button(valuehere):SetTextColor(Color(255, 255, 255))
			-- grid:AddItem(button(valuehere))
			-- button(valuehere).DoClick = function()
			-- --command start
				-- if button(valuehere)on == 1 then
					-- button(valuehere)on = 0
					-- LocalPlayer():ConCommand("(converhere) 0")

				-- else
					-- button(valuehere)on = 1
					-- LocalPlayer():ConCommand("(converhere) 1")

				-- end
			-- --command end
			-- end

			-- function button(valuehere):Paint(w, h)
				-- button(valuehere):SetText("(namehere): "..GetConVar("(converhere)"):GetInt())
				-- draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button(valuehere)on -2)])
			-- end

-- -- (valuehere)
-- -- (namehere)
-- -- (converhere)
-- --2button toggle end


 
-- --2button toggle start

			-- local button(valuehere) = vgui.Create("DButton")
			-- local button(valuehere)on = 0
			-- button(valuehere):SetText("(namehere): ")
			-- button(valuehere):SetSize(120, 60)
			-- button(valuehere):SetTextColor(Color(255, 255, 255))
			-- grid:AddItem(button(valuehere))
			-- button(valuehere).DoClick = function()
			-- --command start
				-- if button(valuehere)on == 1 then
					-- button(valuehere)on = 0
					-- LocalPlayer():ConCommand("(converhere) 0")

				-- else
					-- button(valuehere)on = 1
					-- LocalPlayer():ConCommand("(converhere) 1")

				-- end
			-- --command end
			-- end

			-- function button(valuehere):Paint(w, h)
				-- button(valuehere):SetText("(namehere): "..GetConVar("(converhere)"):GetInt())
				-- draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button(valuehere)on -2)])
			-- end

-- -- (valuehere)
-- -- (namehere)
-- -- (converhere)
-- --2button toggle end




-- Menu code ends here







	
	
	local ply = LocalPlayer()
	
	local renderCount = 0
	
	local tmp = Angle(0,g_VR.tracking.hmd.ang.yaw-90,60) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
    local pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
    local mode = 4
    --uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
    
    if vre_menuguiattachment:GetInt("vre_ui_attachtohand") == 1 then
        pos, ang = Vector(4,6,5.5), Angle(0,-90,10)  --Forward(), Right(), Up() --Vector(10,6,13), Angle(0,-90,50)
        mode = 1
    else
        pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
        mode = 4
    end

    VRUtilMenuOpen("vre_svmenu", 600, 310, vre_svmenuPanel, mode, pos, ang, 0.03, true, function()
        vre_svmenuPanel:Remove()
        vre_svmenuPanel = nil
         hook.Remove("PreRender","vre_renderaddvrmenu")
			
		 open = false
	end)
	
    hook.Add("PreRender","vre_renderaddvrmenumenu",function()
        if VRUtilIsMenuOpen("miscmenu") or VRUtilIsMenuOpen("vremenu") then
	

            VRUtilMenuClose("vre_svmenu")
        elseif IsValid(vre_svmenuPanel) then
            function vre_svmenuPanel:Paint( w, h )
                surface.SetDrawColor( Color( 51, 51, 51, 200 ) )
                surface.DrawRect(0,0,w,h)
            end
            VRUtilMenuRenderPanel("vre_svmenu")
        end
	end)
	
end

	concommand.Add( "vre_svmenu", function( ply, cmd, args )
		if g_VR.net[ply:SteamID()] then
			VREMenuClose()
			vre_svmenuToggle()
		end
	end)

