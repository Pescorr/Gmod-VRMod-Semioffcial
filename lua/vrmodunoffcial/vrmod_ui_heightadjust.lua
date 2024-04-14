if SERVER then return end
g_VR = g_VR or {}
g_VR.characterYaw = 0
local convars, convarValues = vrmod.GetConvars()
function VRUtilOpenHeightMenu()
	if not g_VR.threePoints or VRUtilIsMenuOpen("heightmenu") then return end
	--create mirror
	rt_mirror = GetRenderTarget("rt_vrmod_heightcalmirror", 2048, 2048)
	mat_mirror = CreateMaterial(
		"mat_vrmod_heightcalmirror",
		"Core_DX90",
		{
			["$basetexture"] = "rt_vrmod_heightcalmirror",
			["$model"] = "1"
		}
	)

	local mirrorYaw = 0
	hook.Add(
		"PreDrawTranslucentRenderables",
		"vrmodheightmirror",
		function(depth, skybox)
			if depth or skybox or not (EyePos() == g_VR.eyePosLeft or EyePos() == g_VR.eyePosRight) then return end
			local ad = math.AngleDifference(EyeAngles().yaw, mirrorYaw)
			if math.abs(ad) > 45 then
				mirrorYaw = mirrorYaw + (ad > 0 and 45 or -45)
			end

			local mirrorPos = Vector(g_VR.tracking.hmd.pos.x, g_VR.tracking.hmd.pos.y, g_VR.origin.z + 45) + Angle(0, mirrorYaw, 0):Forward() * 50
			local mirrorAng = Angle(0, mirrorYaw - 90, 90)
			-- g_VR.menus.heightmenu.pos = mirrorPos + Vector(0,0,30) + mirrorAng:Forward()*-15
			-- g_VR.menus.heightmenu.ang = mirrorAng
			local camPos = LocalToWorld(WorldToLocal(EyePos(), Angle(), mirrorPos, mirrorAng) * Vector(1, 1, -1), Angle(), mirrorPos, mirrorAng)
			local camAng = EyeAngles()
			camAng = Angle(camAng.pitch, mirrorAng.yaw + (mirrorAng.yaw - camAng.yaw), 180 - camAng.roll)
			cam.Start(
				{
					x = 0,
					y = 0,
					w = 2048,
					h = 2048,
					type = "3D",
					fov = g_VR.view.fov,
					aspect = -g_VR.view.aspectratio,
					origin = camPos,
					angles = camAng
				}
			)

			render.PushRenderTarget(rt_mirror)
			render.Clear(200, 230, 255, 0, true, true)
			render.CullMode(1)
			local alloworig = g_VR.allowPlayerDraw
			g_VR.allowPlayerDraw = true
			cam.Start3D()
			cam.End3D()
			local ogEyePos = EyePos
			EyePos = function() return Vector(0, 0, 0) end
			local ogRenderOverride = LocalPlayer().RenderOverride
			LocalPlayer().RenderOverride = nil
			render.SuppressEngineLighting(true)
			LocalPlayer():DrawModel()
			render.SuppressEngineLighting(false)
			EyePos = ogEyePos
			LocalPlayer().RenderOverride = ogRenderOverride
			g_VR.allowPlayerDraw = alloworig
			cam.Start3D()
			cam.End3D()
			render.CullMode(0)
			render.PopRenderTarget()
			cam.End3D()
			render.SetMaterial(mat_mirror)
			render.DrawQuadEasy(mirrorPos, mirrorAng:Up(), 30, 60, Color(255, 255, 255, 255), 0)
		end
	)

	concommand.Add(
		"vrmod_scale_auto",
		function(ply, cmd, args)
			g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
	)

	concommand.Add(
		"vrmod_seatedoffset_auto",
		function(ply, cmd, args)
			convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z))
		end
	)

	--create controls
	local mode = convarValues.vrmod_attach_heightmenu
	if mode == 0 then
		VRUtilMenuOpen(
			"heightmenu",
			300,
			512,
			nil,
			0,
			Vector(),
			Angle(),
			0.1,
			true,
			function()
				hook.Remove("PreDrawTranslucentRenderables", "vrmodheightmirror")
				hook.Remove("VRMod_Input", "vrmodheightmenuinput")
			end
		)
	else
		VRUtilMenuOpen(
			"heightmenu",
			300,
			512,
			nil,
			1,
			Vector(4, 6, 15.5),
			Angle(0, -90, 60),
			0.03,
			true,
			function()
				hook.Remove("PreDrawTranslucentRenderables", "vrmodheightmirror")
				hook.Remove("VRMod_Input", "vrmodheightmenuinput")
			end
		)
	end

	local buttons, renderControls
	buttons = {
		{
			x = 250,
			y = 0,
			w = 50,
			h = 50,
			text = "X",
			font = "Trebuchet24",
			text_x = 25,
			text_y = 15,
			enabled = true,
			fn = function()
				VRUtilMenuClose("heightmenu")
				convars.vrmod_heightmenu:SetBool(false)
			end
		},
		{
			x = 250,
			y = 200,
			w = 50,
			h = 50,
			text = "+",
			font = "Trebuchet24",
			text_x = 25,
			text_y = 15,
			enabled = true,
			fn = function()
				if convarValues.vrmod_seated then
					convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_seatedoffset + 0.5)
				else
					g_VR.scale = g_VR.scale + 0.5
					convars.vrmod_scale:SetFloat(g_VR.scale)
				end
			end
		},
		{
			x = 250,
			y = 255,
			w = 50,
			h = 50,
			text = "Auto\nScale",
			font = "Trebuchet24",
			text_x = 25,
			text_y = 0,
			enabled = true,
			fn = function()
				if convarValues.vrmod_seated then
					convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z))
				else
					g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
					convars.vrmod_scale:SetFloat(g_VR.scale)
				end
			end
		},
		{
			x = 250,
			y = 310,
			w = 50,
			h = 50,
			text = "-",
			font = "Trebuchet24",
			text_x = 25,
			text_y = 15,
			enabled = true,
			fn = function()
				if convarValues.vrmod_seated then
					convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_seatedoffset - 0.5)
				else
					g_VR.scale = g_VR.scale - 0.5
					convars.vrmod_scale:SetFloat(g_VR.scale)
				end
			end
		},
		{
			x = 0,
			y = 200,
			w = 50,
			h = 50,
			text = convarValues.vrmod_seated and "Disable\nSeated\nOffset" or "Enable\nSeated\nOffset",
			font = "Trebuchet18",
			text_x = 25,
			text_y = -2,
			enabled = true,
			fn = function()
				buttons[5].text = (not convarValues.vrmod_seated) and "Disable\nSeated\nOffset" or "Enable\nSeated\nOffset"
				convars.vrmod_seated:SetBool(not convarValues.vrmod_seated)
				renderControls()
			end
		},
		-- 新しいボタン「Reset」の定義を追加
		{
			x = 250,
			y = 395, -- これは前のボタンの下に配置するためのY位置です
			w = 50,
			h = 50,
			text = "Reset\nConfig",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true, -- このボタンは常に有効です
			fn = function()
				RunConsoleCommand("vrmod_character_restart")
			end
		},
		-- 新しいボタン「AutoTestver」の定義を追加
		{
			x = 250,
			y = 450, -- 「Reset」ボタンの下に配置
			w = 50,
			h = 50,
			text = "Auto\nTestVer",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true, -- このボタンも常に有効
			fn = function()
				RunConsoleCommand("vrmod_scale_auto")
				RunConsoleCommand("vrmod_character_auto")
				g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
				convars.vrmod_scale:SetFloat(g_VR.scale)
				convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z))
				RunConsoleCommand("vrmod_character_restart")
			end
		},
		-- 新しいボタン「AutoTestver」の定義を追加
		{
			x = 0,
			y = 450, -- 「Reset」ボタンの下に配置
			w = 50,
			h = 50,
			text = "HideNear\nHMD\n-",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = g_VR.view.znear >= 0.5, -- このボタンも常に有効
			fn = function()
				g_VR.view.znear = g_VR.view.znear - 0.5
			end
		},
		-- 新しいボタン「AutoTestver」の定義を追加
		{
			x = 100,
			y = 450, -- 「Reset」ボタンの下に配置
			w = 50,
			h = 50,
			text = "HideNear\nHMD\n+",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = g_VR.view.znear <= 20.0, -- このボタンも常に有効
			fn = function()
				g_VR.view.znear = g_VR.view.znear + 0.5
			end
		},
	}

	renderControls = function()
		VRUtilMenuRenderStart("heightmenu")
		surface.SetDrawColor(0, 0, 0, 255)
		for k, v in ipairs(buttons) do
			surface.SetDrawColor(0, 0, 0, v.enabled and 255 or 128)
			surface.DrawRect(v.x, v.y, v.w, v.h)
			draw.DrawText(v.text, v.font, v.x + v.text_x, v.y + v.text_y, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		VRUtilMenuRenderEnd()
	end

	renderControls()
	hook.Add(
		"VRMod_Input",
		"vrmodheightmenuinput",
		function(action, pressed)
			if g_VR.menuFocus == "heightmenu" and action == "boolean_primaryfire" and pressed then
				for k, v in ipairs(buttons) do
					if v.enabled and g_VR.menuCursorX > v.x and g_VR.menuCursorX < v.x + v.w and g_VR.menuCursorY > v.y and g_VR.menuCursorY < v.y + v.h then
						v.fn()
					end
				end
			end
		end
	)
end

hook.Add(
	"VRMod_Start",
	"vrmod_OpenHeightMenuOnStartup",
	function(ply)
		if ply == LocalPlayer() and convars.vrmod_heightmenu:GetBool() then
			timer.Create(
				"vrmod_HeightMenuStartupWait",
				1,
				0,
				function()
					if g_VR.threePoints then
						timer.Remove("vrmod_HeightMenuStartupWait")
						VRUtilOpenHeightMenu()
					end
				end
			)
		end
	end
)