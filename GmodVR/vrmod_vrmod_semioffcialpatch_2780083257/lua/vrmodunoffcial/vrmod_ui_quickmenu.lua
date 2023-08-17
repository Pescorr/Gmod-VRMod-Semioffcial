if CLIENT then
	local seatedswitch = 0

	local open = false
	function g_VR.MenuOpen()

		local vr_mapbrowser_enable = CreateClientConVar("vrmod_quickmenu_mapprowser", "1")
		local shutdownbutton = CreateClientConVar("vrmod_quickmenu_exit", "1")
		local vguireset = CreateClientConVar("vrmod_quickmenu_vgui_reset", "1")
		local seatedbutton = CreateClientConVar("vrmod_quickmenu_seatedbutton", "1")
		local vreaddmenubutton = CreateClientConVar("vrmod_quickmenu_VRE_addmenu", "1")
		local radialbutton = CreateClientConVar("vrmod_quickmenu_radial", "1")
	
		if hook.Call("VRMod_OpenQuickMenu") == false then return end
		if open then return end
		open = true
		--
		local items = {}
		for k, v in pairs(g_VR.menuItems) do
			local slot, slotPos = v.slot, v.slotPos
			local index = #items + 1
			for i = 1, #items do
				if items[i].slot > slot or items[i].slot == slot and items[i].slotPos > slotPos then
					index = i
					break
				end
			end

			table.insert(
				items,
				index,
				{
					index = k,
					slot = slot,
					slotPos = slotPos
				}
			)
		end

		local currentSlot, actualSlotPos = 0, 0
		for i = 1, #items do
			if items[i].slot ~= currentSlot then
				actualSlotPos = 0
				currentSlot = items[i].slot
			end

			items[i].actualSlotPos = actualSlotPos
			actualSlotPos = actualSlotPos + 1
		end

		--
		local prevHoveredItem = -2
		local ply = LocalPlayer()
		local renderCount = 0
		local _, convarValues = vrmod.GetConvars()
		local tmp = Angle(0, g_VR.tracking.hmd.ang.yaw - 90, 60) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
		local pos, ang = WorldToLocal(g_VR.tracking.pose_righthand.pos + g_VR.tracking.pose_righthand.ang:Forward() * 9 + tmp:Right() * -7.68 + tmp:Forward() * -6.45, tmp, g_VR.origin, g_VR.originAngle)
		--uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
		local mode = convarValues.vrmod_attach_quickmenu
		--add button start

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

		if vr_mapbrowser_enable:GetBool() then
			vrmod.AddInGameMenuItem(
				"Map Browser",
				0,
				1,
				function()
					LocalPlayer():ConCommand("vrmod_mapbrowser")
				end
			)
		else
			vrmod.RemoveInGameMenuItem("Map Browser")
		end


		if vguireset:GetBool() then
			vrmod.AddInGameMenuItem(
				"UI RESET",
				0,
				2,
				function()
					LocalPlayer():ConCommand("vrmod_vgui_reset")
				end
			)
		else
			vrmod.RemoveInGameMenuItem("UI RESET")
		end

		if vreaddmenubutton:GetBool() then
			vrmod.AddInGameMenuItem(
				"VRE addmenu",
				0,
				3,
				function()
					LocalPlayer():ConCommand("vre_addvrmenu")
				end
			)
		else
			vrmod.RemoveInGameMenuItem("VRE addmenu")
		end


		if radialbutton:GetBool() then
			vrmod.AddInGameMenuItem(
				"vre gb-radial",
				0,
				4,
				function()
					LocalPlayer():ConCommand("vre_gb-radial")
				end
			)
		else
			vrmod.RemoveInGameMenuItem("vre gb-radial")
		end

		if seatedbutton:GetBool() then
			vrmod.AddInGameMenuItem(
				"seated mode",
				1,
				2,
				function()
					if seatedswitch == 1 then
						seatedswitch = 0
						LocalPlayer():ConCommand("vrmod_seated 1")
					else
						seatedswitch = 1
						LocalPlayer():ConCommand("vrmod_seated 0")
					end
				end
			)
				else
			vrmod.RemoveInGameMenuItem("seated mode")
		end


		--add button end
		if mode == 1 then
			VRUtilMenuOpen(
				"miscmenu",
				512,
				512,
				nil,
				1,
				Vector(4, 6, 5.5),
				Angle(0, -90, 10),
				0.03,
				true,
				function()
					hook.Remove("PreRender", "vrutil_hook_renderigm")
					open = false
					if items[prevHoveredItem] and g_VR.menuItems[items[prevHoveredItem].index] then
						g_VR.menuItems[items[prevHoveredItem].index].func()
					end
				end
			)
			--
		elseif mode == 3 then
			--forw, left, up
			VRUtilMenuOpen(
				"miscmenu",
				512,
				512,
				nil,
				3,
				Vector(35, 20, 10),
				Angle(0, -90, 90),
				0.03,
				true,
				function()
					hook.Remove("PreRender", "vrutil_hook_renderigm")
					open = false
					if items[prevHoveredItem] and g_VR.menuItems[items[prevHoveredItem].index] then
						g_VR.menuItems[items[prevHoveredItem].index].func()
					end
				end
			)
		elseif mode == 4 then
			local newpos = pos
			local newang = ang
			--forw, left, up
			VRUtilMenuOpen(
				"miscmenu",
				512,
				512,
				nil,
				4,
				newpos,
				newang,
				0.03,
				true,
				function()
					hook.Remove("PreRender", "vrutil_hook_renderigm") -- 
					open = false
					if items[prevHoveredItem] and g_VR.menuItems[items[prevHoveredItem].index] then
						g_VR.menuItems[items[prevHoveredItem].index].func()
					end
				end
			)
		else
			-- --
			VRUtilMenuOpen(
				"miscmenu",
				512,
				512,
				nil,
				mode,
				pos,
				ang,
				0.03,
				true,
				function()
					hook.Remove("PreRender", "vrutil_hook_renderigm")
					open = false
					if items[prevHoveredItem] and g_VR.menuItems[items[prevHoveredItem].index] then
						g_VR.menuItems[items[prevHoveredItem].index].func()
					end
				end
			)
		end

		hook.Add(
			"PreRender",
			"vrutil_hook_renderigm",
			function()
				hoveredItem = -1
				local hoveredSlot, hoveredSlotPos = -1, -1
				if g_VR.menuFocus == "miscmenu" then
					hoveredSlot, hoveredSlotPos = math.floor(g_VR.menuCursorX / 86), math.floor((g_VR.menuCursorY - 230) / 57)
				end

				for i = 1, #items do
					if items[i].slot == hoveredSlot and items[i].actualSlotPos == hoveredSlotPos then
						hoveredItem = i
						break
					end
				end

				local changes = hoveredItem ~= prevHoveredItem
				prevHoveredItem = hoveredItem
				if not changes then return end
				VRUtilMenuRenderStart("miscmenu")
				--debug
				--surface.SetDrawColor(Color(255,0,0,255))
				--surface.DrawOutlinedRect(0,0,512,512)
				--renderCount = renderCount + 1
				--draw.SimpleText( renderCount, "HudSelectionText", 0, 512, Color( 255, 250, 0, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )
				--buttons
				local buttonWidth, buttonHeight = 82, 53
				local gap = (512 - buttonWidth * 6) / 5
				for i = 1, #items do
					local x, y = items[i].slot, items[i].actualSlotPos
					draw.RoundedBox(8, x * (buttonWidth + gap), 230 + y * (buttonHeight + gap), buttonWidth, buttonHeight, Color(0, 0, 0, hoveredItem == i and 200 or 128))
					local explosion = string.Explode(" ", g_VR.menuItems[items[i].index].name, false)
					for j = 1, #explosion do
						draw.SimpleText(explosion[j], "HudSelectionText", buttonWidth / 2 + x * (buttonWidth + gap), 230 + buttonHeight / 2 + y * (buttonHeight + gap) - (#explosion * 6 - 6 - (j - 1) * 12), Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end

				VRUtilMenuRenderEnd()
			end
		)
		---
	end

	function g_VR.MenuClose()
		VRUtilMenuClose("miscmenu")
	end
end