if SERVER then return end
local L = VRModL or function(_, fb) return fb or "" end
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
		frame.SettingsForm:CheckBox(L("Enable seated offset", "Enable seated offset"), "vrmod_seated")
		frame.SettingsForm:ControlHelp(L("Adjust from height adjustment menu", "Adjust from height adjustment menu"))
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
			g_VR.scale = math.Clamp(convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale), 10, 100)
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

	-- Auto reset body on mirror open
	RunConsoleCommand("vrmod_character_stop")
	timer.Simple(0.5, function()
		RunConsoleCommand("vrmod_character_start")
	end)

	local expandedGroup = nil -- nil, "head", or "save"
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
					g_VR.scale = math.Clamp(convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale), 10, 100)
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
			x = 250,
			y = 363,
			w = 50,
			h = 28,
			text = "Reset\nScale",
			font = "Trebuchet18",
			text_x = 25,
			text_y = 0,
			enabled = true,
			fn = function()
				g_VR.scale = VRMOD_DEFAULTS.character.vrmod_scale
				convars.vrmod_scale:SetFloat(g_VR.scale)
			end
		},
		{
			x = 0,
			y = 200,
			w = 50,
			h = 50,
			text = convarValues.vrmod_seated and VRModL("btn_disable_seated", "Disable\nSeated\nOffset") or VRModL("btn_enable_seated", "Enable\nSeated\nOffset"),
			font = "Trebuchet18",
			text_x = 25,
			text_y = -2,
			enabled = true,
			fn = function()
				buttons[6].text = (not convarValues.vrmod_seated) and VRModL("btn_disable_seated", "Disable\nSeated\nOffset") or VRModL("btn_enable_seated", "Enable\nSeated\nOffset")
				convars.vrmod_seated:SetBool(not convarValues.vrmod_seated)
				renderControls()
			end
		},
		{
			x = 250,
			y = 395,
			w = 50,
			h = 50,
			text = VRModL("btn_reset_config", "Reset\nConfig"),
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true,
			fn = function()
				VRModResetCategory("character")
				RunConsoleCommand("vrmod_restart")
			end
		},
		{
			x = 250,
			y = 450,
			w = 50,
			h = 50,
			text = VRModL("btn_auto_set", "Auto\nSet"),
			font = "Trebuchet18",
			text_x = 25,
			text_y = 5,
			enabled = true,
			fn = function()
				RunConsoleCommand("vrmod_hide_head", 0)
				RunConsoleCommand("vrmod_character_stop")
				-- Use centralized defaults
				RunConsoleCommand("vrmod_scale", VRModGetDefault("vrmod_scale"))
				RunConsoleCommand("vrmod_characterHeadToHmdDist", VRModGetDefault("vrmod_characterHeadToHmdDist"))
				RunConsoleCommand("vrmod_characterEyeHeight", VRModGetDefault("vrmod_characterEyeHeight"))
				RunConsoleCommand("vrmod_seatedoffset", VRModGetDefault("vrmod_seatedoffset"))
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
							g_VR.scale = math.Clamp(convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale), 10, 100)
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
							g_VR.scale = math.Clamp(convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale), 10, 100)
							convars.vrmod_scale:SetFloat(g_VR.scale)
						end
					end
				)

				timer.Simple(
					4.5,
					function()
						if convarValues.vrmod_characterEyeHeight < 2.0 and not convarValues.vrmod_seated then
							VRModResetCategory("character")
						end

						RunConsoleCommand("vrmod_character_start")
					end
				)
			end
		},
	}

	-- Accordion group: Head (Hide Head, HMD znear)
	local headGroupButtons = {
		{x = 0, y = 0, w = 100, h = 50, text = "Hide\nHead", font = "Trebuchet18", text_x = 50, text_y = 5, enabled = true,
			fn = function()
				local current = GetConVar("vrmod_hide_head"):GetBool()
				RunConsoleCommand("vrmod_hide_head", current and "0" or "1")
				RunConsoleCommand("vrmod_character_stop")
				timer.Simple(1, function() RunConsoleCommand("vrmod_character_start") end)
			end},
		{x = 0, y = 0, w = 50, h = 50, text = "HideNear\nHMD\n-", font = "Trebuchet18", text_x = 25, text_y = 5,
			enabled = g_VR.view.znear >= 0.5,
			fn = function() g_VR.view.znear = g_VR.view.znear - 0.5 end},
		{x = 55, y = 0, w = 50, h = 50, text = "HideNear\nHMD\n+", font = "Trebuchet18", text_x = 25, text_y = 5,
			enabled = g_VR.view.znear <= 20.0,
			fn = function() g_VR.view.znear = g_VR.view.znear + 0.5 end},
	}

	-- Accordion group: Save (Save, Load, Wizard)
	local saveGroupButtons = {
		{x = 0, y = 0, w = 48, h = 35, text = "Save", font = "Trebuchet18", text_x = 24, text_y = 9, enabled = true,
			fn = function()
				if vrmod.PlayerModelPresets then vrmod.PlayerModelPresets.SaveCurrentModel() end
			end},
		{x = 52, y = 0, w = 48, h = 35, text = "Load", font = "Trebuchet18", text_x = 24, text_y = 9, enabled = true,
			fn = function()
				if vrmod.PlayerModelPresets then vrmod.PlayerModelPresets.LoadCurrentModel() end
			end},
		{x = 0, y = 0, w = 100, h = 40, text = "Setup\nWizard", font = "Trebuchet18", text_x = 50, text_y = 3, enabled = true,
			fn = function()
				if vrmod.HeightWizard then vrmod.HeightWizard.Start() end
			end},
	}

	-- Accordion layout constants
	local ACCORDION_Y = 255
	local HEADER_H = 30
	local HEADER_W = 100
	local GROUP_GAP = 5

	-- Compute dynamic y positions for accordion contents
	local function getAccordionPositions()
		local headY = ACCORDION_Y
		local nextY = headY + HEADER_H + GROUP_GAP

		if expandedGroup == "head" then
			headGroupButtons[1].y = nextY
			nextY = nextY + headGroupButtons[1].h + GROUP_GAP
			headGroupButtons[2].y = nextY
			headGroupButtons[3].y = nextY
			nextY = nextY + headGroupButtons[2].h + GROUP_GAP
		end

		local saveY = nextY
		if expandedGroup == "save" then
			local sy = saveY + HEADER_H + GROUP_GAP
			saveGroupButtons[1].y = sy
			saveGroupButtons[2].y = sy
			sy = sy + saveGroupButtons[1].h + GROUP_GAP
			saveGroupButtons[3].y = sy
		end

		return headY, saveY
	end

	-- Helper: draw a single button
	local function drawButton(v)
		local alpha = v.enabled and 255 or 128
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawRect(v.x, v.y, v.w, v.h)
		draw.DrawText(v.text, v.font, v.x + v.text_x, v.y + v.text_y, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- Helper: draw accordion header
	local function drawHeader(y, label, isExpanded)
		surface.SetDrawColor(40, 40, 40, 255)
		surface.DrawRect(0, y, HEADER_W, HEADER_H)
		local prefix = isExpanded and "[-] " or "[+] "
		draw.DrawText(prefix .. label, "Trebuchet18", HEADER_W / 2, y + 7, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	renderControls = function()
		VRUtilMenuRenderStart("heightmenu")

		-- Always-visible buttons (right column + Seated)
		for k, v in ipairs(buttons) do
			drawButton(v)
		end

		-- Compute accordion layout
		local headY, saveY = getAccordionPositions()

		-- Head accordion
		drawHeader(headY, "Head", expandedGroup == "head")
		if expandedGroup == "head" then
			for _, v in ipairs(headGroupButtons) do drawButton(v) end
		end

		-- Save accordion
		drawHeader(saveY, "Save", expandedGroup == "save")
		if expandedGroup == "save" then
			for _, v in ipairs(saveGroupButtons) do drawButton(v) end
		end

		VRUtilMenuRenderEnd()
	end

	renderControls()
	vrmod.HeightMenuRender = renderControls
	hook.Add(
		"VRMod_Input",
		"vrmodheightmenuinput",
		function(action, pressed)
			if g_VR.menuFocus == "heightmenu" and action == "boolean_primaryfire" and pressed then
				if vrmod.HeightWizard and vrmod.HeightWizard.IsActive() then
					vrmod.HeightWizard.HandleInput(g_VR.menuCursorX, g_VR.menuCursorY)
					return
				end

				local cx, cy = g_VR.menuCursorX, g_VR.menuCursorY

				-- Always-visible buttons
				for k, v in ipairs(buttons) do
					if v.enabled and cx > v.x and cx < v.x + v.w and cy > v.y and cy < v.y + v.h then
						v.fn()
						return
					end
				end

				-- Accordion headers and group buttons
				local headY, saveY = getAccordionPositions()

				-- Head header click
				if cx >= 0 and cx <= HEADER_W and cy >= headY and cy <= headY + HEADER_H then
					if expandedGroup == "head" then
						expandedGroup = nil
					else
						expandedGroup = "head"
					end
					renderControls()
					return
				end

				-- Head group buttons (only when expanded)
				if expandedGroup == "head" then
					for _, v in ipairs(headGroupButtons) do
						if v.enabled and cx > v.x and cx < v.x + v.w and cy > v.y and cy < v.y + v.h then
							v.fn()
							return
						end
					end
				end

				-- Save header click
				if cx >= 0 and cx <= HEADER_W and cy >= saveY and cy <= saveY + HEADER_H then
					if expandedGroup == "save" then
						expandedGroup = nil
					else
						expandedGroup = "save"
					end
					renderControls()
					return
				end

				-- Save group buttons (only when expanded)
				if expandedGroup == "save" then
					for _, v in ipairs(saveGroupButtons) do
						if v.enabled and cx > v.x and cx < v.x + v.w and cy > v.y and cy < v.y + v.h then
							v.fn()
							return
						end
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