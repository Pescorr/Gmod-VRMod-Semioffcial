if CLIENT then
	g_VR = g_VR or {}
	g_VR.menuFocus = false
	g_VR.menuCursorX = 0
	g_VR.menuCursorY = 0
	local _, convarValues = vrmod.GetConvars()
	
	vrmod.AddCallbackedConvar("vrmod_test_ui_testver", nil, 0,nil, "", 0, 1, tonumber)--cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
	vrmod.AddCallbackedConvar("vrmod_ui_realtime", nil, 1,nil, "", 0, 1, tonumber)--cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
	vrmod.AddCallbackedConvar("vrmod_attach_weaponmenu", nil, 1,nil, "", 0, 4, tonumber)
	vrmod.AddCallbackedConvar("vrmod_attach_quickmenu", nil, 1,nil, "", 0, 4, tonumber)
	vrmod.AddCallbackedConvar("vrmod_attach_popup", nil, 1,nil, "", 0, 4, tonumber)
	vrmod.AddCallbackedConvar("vrmod_attach_heightmenu", nil, 1,nil, "", 0, 4, tonumber)

	local VRClipboard = CreateClientConVar("vrmod_Clipboard","",false,false,"")


	
	local rt_beam = GetRenderTarget("vrmod_rt_beam",64,64,false)
	local mat_beam = CreateMaterial("vrmod_mat_beam", "UnlitGeneric",{ ["$basetexture"] = rt_beam:GetName() })
	render.PushRenderTarget(rt_beam)
	render.Clear(0,0,255,255)
	render.PopRenderTarget()
	
	g_VR.menus = {}
	local menus = g_VR.menus
	local menuOrder = {}
	local menusExist = false
	local prevFocusPanel = nil
	
	function VRUtilMenuRenderPanel(uid)
		timer.Simple(0.1,function()
			if menus[uid] == nil or menus[uid].panel == nil or not menus[uid].panel:IsValid() then return end
			render.PushRenderTarget(menus[uid].rt)
			cam.Start2D()
			render.ClearDepth()
			render.Clear(0,0,0,0)
			menus[uid].panel:PaintManual()
			cam.End2D()
			render.PopRenderTarget()
		end)
	end
	
	function VRUtilMenuRenderStart(uid)
		render.PushRenderTarget(menus[uid].rt)
		cam.Start2D()
		render.ClearDepth()
		render.Clear(0,0,0,0)
	end
	
	function VRUtilMenuRenderEnd()
		cam.End2D()
		render.PopRenderTarget()
	end
	
	function VRUtilIsMenuOpen(uid)
		return menus[uid] ~= nil
	end
	
	function VRUtilRenderMenuSystem()
		if menusExist == false then return end
		render.DepthRange(0,0.001)
		g_VR.menuFocus = false
		local menuFocusDist = 99999
		local menuFocusPanel = nil
		local menuFocusCursorWorldPos = nil
		local tms = render.GetToneMappingScaleLinear()
		render.SetToneMappingScaleLinear(g_VR.view.dopostprocess and Vector(0.75,0.75,0.75) or Vector(1,1,1))
		for k,v in ipairs(menuOrder) do
			k = v.uid
			if v.panel then
				if not IsValid(v.panel) or not v.panel:IsVisible() then
					VRUtilMenuClose(k)
					continue
				end
			end
			local pos, ang = v.pos, v.ang
			if v.attachment == 1 then
				pos, ang = LocalToWorld(pos, ang, g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang)
			elseif v.attachment == 2 then
				pos, ang = LocalToWorld(pos, ang, g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang)
			elseif v.attachment == 3 then
				pos, ang = LocalToWorld(pos, ang, g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang)
			elseif v.attachment == 4 then
				pos, ang = LocalToWorld(pos, ang, g_VR.origin, g_VR.originAngle)
			end
			cam.Start3D2D( pos, ang, v.scale )
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(v.mat)
				surface.DrawTexturedRect(0,0,v.width,v.height)
				--debug outline
				--surface.SetDrawColor(255,0,0,255)
				--surface.DrawOutlinedRect(0,0,v.width,v.height)
			cam.End3D2D()
			if v.cursorEnabled then
				local cursorX, cursorY = -1,-1
				local cursorWorldPos = Vector(0,0,0)
				local start = g_VR.tracking.pose_righthand.pos
				local dir = g_VR.tracking.pose_righthand.ang:Forward()
				local dist = nil
				local normal = ang:Up()
				local A = normal:Dot(dir)
				if A < 0 then
					local B = normal:Dot(pos-start)
					if B <  0 then
						dist = B/A
						cursorWorldPos = start+dir*dist
						local tp, unused = WorldToLocal( cursorWorldPos, Angle(0,0,0), pos, ang)
						cursorX = tp.x*(1/v.scale)
						cursorY = -tp.y*(1/v.scale)
					end
				end
				if cursorX > 0 and cursorY > 0 and cursorX < v.width and cursorY < v.height and dist < menuFocusDist then
					g_VR.menuFocus = k
					g_VR.menuCursorX = cursorX
					g_VR.menuCursorY = cursorY
					menuFocusDist = dist
					menuFocusPanel = v.panel
					menuFocusCursorWorldPos = cursorWorldPos
				end
			end
		end
		render.SetToneMappingScaleLinear(tms)
		if menuFocusPanel ~= prevFocusPanel then
			if IsValid(prevFocusPanel) then
				prevFocusPanel:SetMouseInputEnabled(false)
			end
			if IsValid(menuFocusPanel) then
				menuFocusPanel:SetMouseInputEnabled(true)
			end
			gui.EnableScreenClicker(menuFocusPanel ~= nil)
			prevFocusPanel = menuFocusPanel
		end
		if g_VR.menuFocus then
			render.SetMaterial(mat_beam)
			render.DrawBeam(g_VR.tracking.pose_righthand.pos, menuFocusCursorWorldPos, 0.1, 0, 0, Color(255,255,255,255))
			input.SetCursorPos(g_VR.menuCursorX,g_VR.menuCursorY)
		-- realtime ui start
				if convarValues.vrmod_ui_realtime == 1 then
					VRUtilMenuRenderPanel(g_VR.menuFocus)
				end
		end
		render.DepthRange(0,1)
	end
	
	function VRUtilMenuOpen(uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc)
		if menus[uid] then
			return
		end
		
		menus[uid] = {
			uid = uid,
			panel = panel,
			closeFunc = closeFunc,
			attachment = attachment,
			pos = pos,
			ang = ang,
			scale = scale,
			cursorEnabled = cursorEnabled,
			rt = GetRenderTarget("vrmod_rt_ui_"..uid, width, height, false),
			width = width,
			height = height,
		}
		
		menuOrder[#menuOrder+1] = menus[uid]
		
		local mat = Material("!vrmod_mat_ui_"..uid)
		menus[uid].mat = not mat:IsError() and mat or CreateMaterial("vrmod_mat_ui_"..uid, "UnlitGeneric",{ ["$basetexture"] = menus[uid].rt:GetName(), ["$translucent"] = 1 })
		
		if panel then
			panel:SetPaintedManually( true )
			VRUtilMenuRenderPanel(uid)
		end
		
		render.PushRenderTarget(menus[uid].rt)
		render.Clear(0,0,0,0)
		render.PopRenderTarget()

		if GetConVar("vrmod_useworldmodels"):GetBool() then
			hook.Add( "PostDrawTranslucentRenderables", "vrutil_hook_drawmenus", function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox then return end
				VRUtilRenderMenuSystem()
			end)
		end
		
		menusExist = true
		
	end
	
	function VRUtilMenuClose(uid)
		for k,v in pairs(menus) do
			if k == uid or not uid then
				if IsValid(v.panel) then
					v.panel:SetPaintedManually(false)
				end
				if v.closeFunc then
					v.closeFunc()
				end
				for k2,v2 in ipairs(menuOrder) do
					if v2 == v then
						table.remove(menuOrder,k2)
						break
					end
				end
				menus[k] = nil
			end
		end
		if table.Count(menus) == 0 then
			hook.Remove( "PostDrawTranslucentRenderables", "vrutil_hook_drawmenus")
			g_VR.menuFocus = false
			menusExist = false
			gui.EnableScreenClicker(false)
		end
	end


	function ReloadKeyPressed()
		local VRClipboard = GetConVar("vrmod_Clipboard"):GetString()
		-- マウスカーソル下にあるパネルを取得する
		local panel = vgui.GetHoveredPanel()
		-- パネルがDTextEntryであるかどうかを確認する
		if IsValid(panel)  then
		-- テキストボックスにConVarの文字列を設定する
			panel:SetValue(VRClipboard)
		end
	end
	
	hook.Add("VRMod_Input","ui",function(action, pressed)
		if g_VR.menuFocus and action == "boolean_primaryfire" then
			if pressed then
				gui.InternalMousePressed(MOUSE_LEFT)
			else
				gui.InternalMouseReleased(MOUSE_LEFT)
			end
			VRUtilMenuRenderPanel(g_VR.menuFocus)
		end
		
		if g_VR.menuFocus and action == "boolean_secondaryfire" then
			if pressed then
				gui.InternalMousePressed(MOUSE_RIGHT)
			else
				gui.InternalMouseReleased(MOUSE_RIGHT)
			end
			VRUtilMenuRenderPanel(g_VR.menuFocus)
		end
		
		-- if g_VR.menuFocus and action == "boolean_right_pickup" then
			-- VRUtilMenuRenderPanel(g_VR.menuFocus)
		-- end
		
		if g_VR.menuFocus and action == "boolean_reload" then
			if pressed then
				-- キー入力イベントをフックする
				ReloadKeyPressed()	
			else
				ReloadKeyPressed()	
			end
			VRUtilMenuRenderPanel(g_VR.menuFocus)
		end

		if g_VR.menuFocus and action == "boolean_back" then
			if pressed then
				gui.InternalMouseWheeled(-1)
			else
				gui.InternalMouseWheeled(-1)
			end
			VRUtilMenuRenderPanel(g_VR.menuFocus)
		end

		if g_VR.menuFocus and action == "boolean_forword" then
			if pressed then
				gui.InternalMouseWheeled(1)
			else
				gui.InternalMouseWheeled(1)
			end
			VRUtilMenuRenderPanel(g_VR.menuFocus)
		end

		-- if g_VR.menuFocus and action == "boolean_left_pickup" then
			-- if pressed then
				-- gui.InternalKeyCodePressed(KEY_LCONTROL)
				-- gui.InternalKeyCodePressed(KEY_V)
			-- else
				-- gui.InternalKeyCodeReleased(KEY_LCONTROL)
				-- gui.InternalKeyCodeReleased(KEY_V)
			-- end
			-- VRUtilMenuRenderPanel(g_VR.menuFocus)
		-- end


	end)

	
end