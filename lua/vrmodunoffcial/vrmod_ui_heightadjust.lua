if SERVER then return end
g_VR = g_VR or {}
g_VR.characterYaw = 0
local convars, convarValues = vrmod.GetConvars()
local seatedOffset, crouchOffset = Vector(), Vector()
local function updateOffsetHook()
	seatedOffset.z = convarValues.vrmod_seated and convarValues.vrmod_seatedoffset or 0
	if seatedOffset.z == 0 and crouchOffset.z == 0 then
		hook.Remove("VRMod_Tracking", "seatedmode")

		return
	end

	hook.Add(
		"VRMod_Tracking",
		"seatedmode",
		function()
			g_VR.tracking.hmd.pos = g_VR.tracking.hmd.pos + seatedOffset + crouchOffset
			g_VR.tracking.pose_lefthand.pos = g_VR.tracking.pose_lefthand.pos + seatedOffset + crouchOffset
			g_VR.tracking.pose_righthand.pos = g_VR.tracking.pose_righthand.pos + seatedOffset + crouchOffset
		end
	)
end

vrmod.AddCallbackedConvar(
	"vrmod_seatedoffset",
	nil,
	"0",
	FCVAR_ARCHIVE,
	nil,
	nil,
	nil,
	tonumber,
	function(val)
		updateOffsetHook()
	end
)

vrmod.AddCallbackedConvar(
	"vrmod_seated",
	nil,
	"0",
	FCVAR_ARCHIVE,
	nil,
	nil,
	nil,
	tobool,
	function(val)
		updateOffsetHook()
	end
)

hook.Add(
	"VRMod_Menu",
	"vrmod_n_seated",
	function(frame)
		frame.SettingsForm:CheckBox("Enable seated offset", "vrmod_seated")
		frame.SettingsForm:ControlHelp("Adjust from height adjustment menu")
	end
)

hook.Add(
	"VRMod_Start",
	"seatedmode",
	function(ply)
		if ply ~= LocalPlayer() then return end
		updateOffsetHook()
	end
)

local crouchTarget = 0
hook.Add(
	"VRMod_Input",
	"crouching",
	function(action, pressed)
		if action == "boolean_crouch" and pressed then
			crouchTarget = (crouchTarget == 0) and math.min(0, 38 - (g_VR.tracking.hmd.pos.z - g_VR.origin.z)) or 0
			local speed = (crouchTarget == 0 and 36 or -36) * (1 / LocalPlayer():GetDuckSpeed())
			hook.Add(
				"PreRender",
				"vrmod_crouch",
				function()
					crouchOffset.z = crouchOffset.z + speed * FrameTime()
					if crouchOffset.z > 0 or crouchTarget < 0 and crouchOffset.z < crouchTarget then
						crouchOffset.z = crouchTarget
						hook.Remove("PreRender", "vrmod_crouch")
						updateOffsetHook()
					end
				end
			)

			crouchOffset.z = crouchOffset.z + 0.01
			updateOffsetHook()
		end
	end
)

function VRUtilOpenHeightMenu()
	if not g_VR.threePoints or VRUtilIsMenuOpen("heightmenu") then return end
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
			local moded = GetConVar("vrmod_attach_heightmenu"):GetInt()
			if moded == 2 then
				g_VR.menus.heightmenu.pos = mirrorPos + Vector(0, 0, 30) + mirrorAng:Forward() * -15
				g_VR.menus.heightmenu.ang = mirrorAng
			end

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

	local mode = convarValues.vrmod_attach_heightmenu
	if mode == 0 then
		VRUtilMenuOpen(
			"heightmenu",
			300,
			512,
			nil,
			3,
			Vector(50, 8, 10),
			Angle(0, -90, 90),
			0.05,
			true,
			function()
				hook.Remove("PreDrawTranslucentRenderables", "vrmodheightmirror")
				hook.Remove("VRMod_Input", "vrmodheightmenuinput")
			end
		)
	elseif mode == 1 then
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
	else
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
		{
			x = 250,
			y = 395,
			w = 50,
			h = 50,
			text = "Reset\nConfig",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true,
			fn = function()
				RunConsoleCommand("vrmod_character_reset")
				convars.vrmod_scale:SetFloat(38.7)
				convars.vrmod_seatedoffset:SetFloat(0)
				RunConsoleCommand("vrmod_restart")
			end
		},
		{
			x = 250,
			y = 450,
			w = 50,
			h = 50,
			text = "Auto\nSet",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true,
			fn = function()
				RunConsoleCommand("vrmod_hide_head", 0)
				RunConsoleCommand("vrmod_character_stop")
				RunConsoleCommand("vrmod_scale", 38.7)
				RunConsoleCommand("vrmod_characterHeadToHmdDist", 6.3)
				RunConsoleCommand("vrmod_characterEyeHeight", 66.8)
				RunConsoleCommand("vrmod_seatedoffset", 66.8)
				AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
				include("vrmodunoffcial/vrmod_character.lua")
				RunConsoleCommand("vrmod_character_auto")
				RunConsoleCommand("vrmod_seatedoffset_auto")
				timer.Simple(
					3.5,
					function()
						RunConsoleCommand("vrmod_character_start")
					end
				)

				timer.Simple(
					3.0,
					function()
						if convarValues.vrmod_seated then
							convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z))
						else
							g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
							convars.vrmod_scale:SetFloat(g_VR.scale)
						end
					end
				)

				timer.Simple(
					4.0,
					function()
						if convarValues.vrmod_seated then
							convars.vrmod_seatedoffset:SetFloat(convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z))
						else
							g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
							convars.vrmod_scale:SetFloat(g_VR.scale)
						end
					end
				)

				timer.Simple(
					4.5,
					function()
						if convarValues.vrmod_characterEyeHeight < 2.0 and not convarValues.vrmod_seated then
							RunConsoleCommand("vrmod_character_reset")
							convars.vrmod_scale:SetFloat(38.7)
							convars.vrmod_characterHeadToHmdDist:SetFloat(6.3)
							convars.vrmod_characterHeadToHmdDist:SetFloat(6.3)
							convars.vrmod_characterEyeHeight:SetFloat(66.8)
							convars.vrmod_crouchthreshold:SetFloat(40)
							convars.vrmod_seatedoffset:SetFloat(66.8)
							convars.vrmod_znear:SetFloat(6.0)
						end

						RunConsoleCommand("vrmod_character_start")
					end
				)
			end
		},
		{
			x = 0,
			y = 450,
			w = 50,
			h = 50,
			text = "HideNear\nHMD\n-",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = g_VR.view.znear >= 0.5,
			fn = function()
				g_VR.view.znear = g_VR.view.znear - 0.5
			end
		},
		{
			x = 100,
			y = 450,
			w = 50,
			h = 50,
			text = "HideNear\nHMD\n+",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = g_VR.view.znear <= 20.0,
			fn = function()
				g_VR.view.znear = g_VR.view.znear + 0.5
			end
		},
		{
			x = 0,
			y = 350,
			w = 50,
			h = 50,
			text = "Hide\nHead",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true,
			fn = function()
				local current = GetConVar("vrmod_hide_head"):GetBool()
				RunConsoleCommand("vrmod_hide_head", current and "0" or "1")
				RunConsoleCommand("vrmod_character_stop")
				timer.Simple(
					1,
					function()
						RunConsoleCommand("vrmod_character_start")
					end
				)
			end
		},
		{
			x = 100,
			y = 350,
			w = 50,
			h = 50,
			text = "reset\nBody",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true,
			fn = function()
				-- local current = GetConVar("vrmod_hide_body"):GetBool()
				-- RunConsoleCommand("vrmod_hide_body", current and "0" or "1")
				RunConsoleCommand("vrmod_character_stop")
				timer.Simple(
					1,
					function()
						RunConsoleCommand("vrmod_character_start")
					end
				)
			end
		},
	}

	-- {
	-- 	x = 0,
	-- 	y = 405,
	-- 	w = 50,
	-- 	h = 50,
	-- 	text = "Hide\nArms",
	-- 	font = "Trebuchet18",
	-- 	text_x = 25,
	-- 	text_y = 5,
	-- 	enabled = true,
	-- 	fn = function()
	-- 		local current = GetConVar("vrmod_hide_arms"):GetBool()
	-- 		RunConsoleCommand("vrmod_hide_arms", current and "0" or "1")
	-- 		RunConsoleCommand("vrmod_character_stop")
	-- 		timer.Simple(2, function()
	-- 			 RunConsoleCommand("vrmod_character_start")
	-- 		end)
	-- 	end
	-- },
	-- {
	-- 	x = 100,
	-- 	y = 405,
	-- 	w = 50,
	-- 	h = 50,
	-- 	text = "Hide\nLegs",
	-- 	font = "Trebuchet18",
	-- 	text_x = 25,
	-- 	text_y = 5,
	-- 	enabled = true,
	-- 	fn = function()
	-- 		local current = GetConVar("vrmod_hide_legs"):GetBool()
	-- 		RunConsoleCommand("vrmod_hide_legs", current and "0" or "1")
	-- 		RunConsoleCommand("vrmod_character_stop")
	-- 		timer.Simple(2, function()
	-- 			 RunConsoleCommand("vrmod_character_start")
	-- 		end)
	-- 	end
	-- },
	renderControls = function()
		VRUtilMenuRenderStart("heightmenu")
		surface.SetDrawColor(0, 0, 0, 255)
		for k, v in ipairs(buttons) do
			local color = v.enabled and 255 or 128
			surface.SetDrawColor(0, 0, 0, color)
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