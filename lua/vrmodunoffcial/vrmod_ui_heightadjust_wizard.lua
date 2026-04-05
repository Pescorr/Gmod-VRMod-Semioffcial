if SERVER then return end

-- ============================================
-- Character Setup Wizard
-- Step-by-step guided character calibration
-- Overlays on the height adjustment mirror panel (300x512)
-- ============================================

vrmod.HeightWizard = vrmod.HeightWizard or {}

local PANEL_W = 300
local PANEL_H = 512

local wizardState = nil -- nil = not active
local steps = {}

-- ========================================
-- Helpers
-- ========================================

local function GetModelShortName()
	local ply = LocalPlayer()
	if not IsValid(ply) then return "unknown" end
	local mdl = ply.vrmod_pm or ply:GetModel() or "unknown"
	return string.gsub(string.GetFileFromFilename(mdl) or mdl, "%.mdl$", "")
end

local function IsMenuOpen()
	return VRUtilIsMenuOpen and VRUtilIsMenuOpen("heightmenu")
end

local function IsSeated()
	local _, cv = vrmod.GetConvars()
	return cv and cv.vrmod_seated
end

-- Seated: adjust seatedoffset, Standing: adjust scale
local function AutoScaleOrOffset()
	local convars, cv = vrmod.GetConvars()
	if cv and cv.vrmod_seated then
		convars.vrmod_seatedoffset:SetFloat(cv.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - cv.vrmod_seatedoffset - g_VR.origin.z))
	else
		g_VR.scale = math.Clamp(cv.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale), 10, 100)
		convars.vrmod_scale:SetFloat(g_VR.scale)
	end
end

local function SetWizardStep(stepNum, substep)
	if not IsMenuOpen() then
		wizardState = nil
		return
	end
	wizardState = wizardState or {}
	wizardState.step = stepNum
	wizardState.substep = substep or nil
	wizardState.startTime = CurTime()

	local step = steps[stepNum]
	if step and step.onEnter then
		step.onEnter(substep)
	end

	vrmod.HeightWizard.Render()
end

-- ========================================
-- Drawing Primitives
-- ========================================

local function DrawBackground()
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, PANEL_W, PANEL_H)
end

local function DrawTitle(text, stepNum, totalSteps)
	draw.DrawText("Step " .. stepNum .. "/" .. totalSteps, "Trebuchet18",
		PANEL_W - 10, 8, Color(150, 150, 150), TEXT_ALIGN_RIGHT)
	draw.DrawText(text, "Trebuchet24", 10, 5, Color(255, 255, 255))
	surface.SetDrawColor(100, 100, 100)
	surface.DrawRect(10, 32, PANEL_W - 20, 1)
end

local function DrawDescription(lines, startY)
	local y = startY or 45
	for _, line in ipairs(lines) do
		draw.DrawText(line, "Trebuchet18", 15, y, Color(220, 220, 220))
		y = y + 20
	end
	return y
end

local function DrawButton(btn)
	local bgColor = (btn.enabled ~= false) and Color(40, 40, 40) or Color(20, 20, 20)
	local textColor = (btn.enabled ~= false) and Color(255, 255, 255) or Color(100, 100, 100)
	local borderColor = (btn.highlight) and Color(100, 200, 100) or Color(100, 100, 100)

	surface.SetDrawColor(bgColor)
	surface.DrawRect(btn.x, btn.y, btn.w, btn.h)
	surface.SetDrawColor(borderColor)
	surface.DrawOutlinedRect(btn.x, btn.y, btn.w, btn.h)

	-- Center text vertically and horizontally
	local font = btn.font or "Trebuchet18"
	surface.SetFont(font)
	local _, fontH = surface.GetTextSize("A")
	-- Count lines in text
	local lineCount = 1
	for _ in string.gmatch(btn.text, "\n") do lineCount = lineCount + 1 end
	local textY = btn.y + (btn.h - fontH * lineCount) / 2

	draw.DrawText(btn.text, font,
		btn.x + btn.w / 2, textY,
		textColor, TEXT_ALIGN_CENTER)
end

-- ========================================
-- Step 1: Welcome
-- ========================================

steps[1] = {
	title = "Character Setup",
	getButtons = function()
		return {
			{
				x = 75, y = 380, w = 150, h = 50,
				text = "Start Setup",
				highlight = true,
				fn = function() SetWizardStep(2) end
			},
			{
				x = 10, y = 470, w = 80, h = 30,
				text = "Cancel",
				fn = function() vrmod.HeightWizard.Cancel() end
			},
		}
	end,
	render = function()
		DrawBackground()
		DrawTitle("Character Setup", 1, 5)
		local mdlName = GetModelShortName()
		local seated = IsSeated()
		DrawDescription({
			"",
			seated and "Sit in your normal play" or "Stand up straight in your",
			seated and "position and look forward." or "play area and look forward.",
			"",
			"The wizard will automatically",
			"calibrate your character.",
			"",
			"Model: " .. mdlName,
			seated and "Mode: Seated" or "",
		})
	end,
}

-- ========================================
-- Step 2: Auto Calibration
-- ========================================

steps[2] = {
	title = "Calibrating...",
	onEnter = function()
		-- Full Auto Set sequence (same as mirror Auto Set button)
		RunConsoleCommand("vrmod_hide_head", "0")
		RunConsoleCommand("vrmod_character_stop")

		-- Reset to defaults
		if VRModGetDefault then
			RunConsoleCommand("vrmod_scale", tostring(VRModGetDefault("vrmod_scale") or 38.7))
			RunConsoleCommand("vrmod_characterHeadToHmdDist", tostring(VRModGetDefault("vrmod_characterHeadToHmdDist") or 6.3))
			RunConsoleCommand("vrmod_characterEyeHeight", tostring(VRModGetDefault("vrmod_characterEyeHeight") or 66.8))
			RunConsoleCommand("vrmod_seatedoffset", tostring(VRModGetDefault("vrmod_seatedoffset") or 0))
		end

		-- Re-include character system and run auto calibration
		pcall(function()
			AddCSLuaFile("vrmodunoffcial/vrmod_character.lua")
			include("vrmodunoffcial/vrmod_character.lua")
		end)
		RunConsoleCommand("vrmod_character_auto")
		RunConsoleCommand("vrmod_seatedoffset_auto")

		-- Auto Scale/Offset at 3.0s
		timer.Simple(3.0, function()
			if not vrmod.HeightWizard.IsActive() or not IsMenuOpen() then return end
			AutoScaleOrOffset()
		end)

		-- character_start at 3.5s
		timer.Simple(3.5, function()
			if not vrmod.HeightWizard.IsActive() or not IsMenuOpen() then return end
			RunConsoleCommand("vrmod_character_start")
		end)

		-- Auto Scale/Offset again at 4.0s
		timer.Simple(4.0, function()
			if not vrmod.HeightWizard.IsActive() or not IsMenuOpen() then return end
			AutoScaleOrOffset()
		end)

		-- Safety check + advance to next step at 5.0s
		timer.Simple(5.0, function()
			if not vrmod.HeightWizard.IsActive() or not IsMenuOpen() then return end
			RunConsoleCommand("vrmod_character_start")
			SetWizardStep(3)
		end)

		-- Progress bar animation timer (re-render every 0.5s)
		timer.Create("vrmod_wizard_progress", 0.5, 10, function()
			if vrmod.HeightWizard.IsActive() and wizardState and wizardState.step == 2 then
				vrmod.HeightWizard.Render()
			else
				timer.Remove("vrmod_wizard_progress")
			end
		end)
	end,
	getButtons = function()
		return {
			{
				x = 10, y = 470, w = 80, h = 30,
				text = "Cancel",
				fn = function() vrmod.HeightWizard.Cancel() end
			},
		}
	end,
	render = function()
		DrawBackground()
		DrawTitle("Calibrating...", 2, 5)

		DrawDescription({
			"",
			"Please stay still.",
			"",
			"Automatically adjusting your",
			"character proportions...",
		})

		-- Progress bar
		local elapsed = CurTime() - (wizardState and wizardState.startTime or CurTime())
		local progress = math.Clamp(elapsed / 5.0, 0, 1)
		local barW = PANEL_W - 40
		local barY = 180

		surface.SetDrawColor(60, 60, 60)
		surface.DrawRect(20, barY, barW, 20)
		surface.SetDrawColor(80, 180, 80)
		surface.DrawRect(20, barY, math.floor(barW * progress), 20)
		surface.SetDrawColor(100, 100, 100)
		surface.DrawOutlinedRect(20, barY, barW, 20)
		draw.DrawText(math.floor(progress * 100) .. "%", "Trebuchet18",
			PANEL_W / 2, barY + 2, Color(255, 255, 255), TEXT_ALIGN_CENTER)
	end,
}

-- ========================================
-- Step 3: Body Check
-- ========================================

steps[3] = {
	title = "Body Check",
	getButtons = function(substep)
		local seated = IsSeated()
		if substep == "manual" then
			return {
				{
					x = 30, y = 350, w = 70, h = 45,
					text = seated and "Offset -" or "Scale -",
					fn = function()
						local convars, cv = vrmod.GetConvars()
						if seated then
							convars.vrmod_seatedoffset:SetFloat((cv.vrmod_seatedoffset or 0) - 0.5)
						elseif g_VR then
							g_VR.scale = g_VR.scale - 0.5
							convars.vrmod_scale:SetFloat(g_VR.scale)
						end
						vrmod.HeightWizard.Render()
					end
				},
				{
					x = 110, y = 350, w = 80, h = 45,
					text = seated and "Auto\nOffset" or "Auto\nScale",
					fn = function()
						AutoScaleOrOffset()
						timer.Simple(0.1, function()
							vrmod.HeightWizard.Render()
						end)
					end
				},
				{
					x = 200, y = 350, w = 70, h = 45,
					text = seated and "Offset +" or "Scale +",
					fn = function()
						local convars, cv = vrmod.GetConvars()
						if seated then
							convars.vrmod_seatedoffset:SetFloat((cv.vrmod_seatedoffset or 0) + 0.5)
						elseif g_VR then
							g_VR.scale = g_VR.scale + 0.5
							convars.vrmod_scale:SetFloat(g_VR.scale)
						end
						vrmod.HeightWizard.Render()
					end
				},
				{
					x = 75, y = 420, w = 150, h = 45,
					text = "Done Adjusting",
					highlight = true,
					fn = function() SetWizardStep(4) end
				},
				{
					x = 10, y = 470, w = 80, h = 30,
					text = "Cancel",
					fn = function() vrmod.HeightWizard.Cancel() end
				},
			}
		elseif substep == "recheck" then
			return {
				{
					x = 20, y = 380, w = 120, h = 50,
					text = "Yes, Better",
					highlight = true,
					fn = function() SetWizardStep(4) end
				},
				{
					x = 160, y = 380, w = 120, h = 50,
					text = "Manual\nAdjust",
					fn = function() SetWizardStep(3, "manual") end
				},
				{
					x = 10, y = 470, w = 80, h = 30,
					text = "Cancel",
					fn = function() vrmod.HeightWizard.Cancel() end
				},
			}
		else
			return {
				{
					x = 20, y = 370, w = 120, h = 50,
					text = "Yes",
					highlight = true,
					fn = function() SetWizardStep(4) end
				},
				{
					x = 160, y = 370, w = 120, h = 50,
					text = "No",
					fn = function()
						-- Try auto scale/offset 2 more times then re-ask
						AutoScaleOrOffset()
						timer.Simple(1, function()
							if not vrmod.HeightWizard.IsActive() or not IsMenuOpen() then return end
							AutoScaleOrOffset()
							timer.Simple(1, function()
								if not vrmod.HeightWizard.IsActive() or not IsMenuOpen() then return end
								SetWizardStep(3, "recheck")
							end)
						end)
					end
				},
				{
					x = 75, y = 435, w = 150, h = 35,
					text = "Reset All",
					fn = function()
						if VRModResetCategory then
							VRModResetCategory("character")
						end
						RunConsoleCommand("vrmod_restart")
						vrmod.HeightWizard.Cancel()
					end
				},
				{
					x = 10, y = 470, w = 80, h = 30,
					text = "Cancel",
					fn = function() vrmod.HeightWizard.Cancel() end
				},
			}
		end
	end,
	render = function(substep)
		DrawBackground()
		DrawTitle("Body Check", 3, 5)
		local seated = IsSeated()

		if substep == "manual" then
			local currentVal
			if seated then
				local _, cv = vrmod.GetConvars()
				currentVal = cv and string.format("%.1f", cv.vrmod_seatedoffset or 0) or "?"
			else
				currentVal = g_VR and string.format("%.1f", g_VR.scale) or "?"
			end
			DrawDescription({
				"",
				seated and "Use +/- to adjust offset." or "Use +/- to adjust scale.",
				"",
				(seated and "Current offset: " or "Current scale: ") .. currentVal,
				"",
				"Press 'Done' when your body",
				"looks correct in the mirror.",
			})
		elseif substep == "recheck" then
			DrawDescription({
				"",
				"Re-calibration complete.",
				"",
				"Is it better now?",
				"",
				"If not, try manual adjustment.",
			})
		else
			DrawDescription({
				"",
				"Look in the mirror.",
				"Does your character's body",
				"look normal?",
				"",
				"Check:",
				"  - Body proportions",
				"  - Arm length",
				"  - Standing position",
			})
		end
	end,
}

-- ========================================
-- Step 4: Head Clipping
-- ========================================

steps[4] = {
	title = "Head Check",
	getButtons = function()
		return {
			{
				x = 20, y = 380, w = 120, h = 50,
				text = "Yes, Head\nClips",
				fn = function()
					RunConsoleCommand("vrmod_hide_head", "1")
					RunConsoleCommand("vrmod_character_stop")
					timer.Simple(0.5, function()
						RunConsoleCommand("vrmod_character_start")
					end)
					SetWizardStep(5)
				end
			},
			{
				x = 160, y = 380, w = 120, h = 50,
				text = "No, All\nClear",
				highlight = true,
				fn = function()
					SetWizardStep(5)
				end
			},
			{
				x = 10, y = 470, w = 80, h = 30,
				text = "Cancel",
				fn = function() vrmod.HeightWizard.Cancel() end
			},
		}
	end,
	render = function()
		DrawBackground()
		DrawTitle("Head Check", 4, 5)
		DrawDescription({
			"",
			"Move your head around.",
			"Look up, down, left and right.",
			"",
			"Can you see parts of your",
			"model's head or face?",
			"",
			"(hat brims, hair, or",
			" face geometry in view)",
		})
	end,
}

-- ========================================
-- Step 5: Save Preset
-- ========================================

steps[5] = {
	title = "Save Settings",
	getButtons = function()
		return {
			{
				x = 20, y = 400, w = 120, h = 50,
				text = "Save",
				highlight = true,
				fn = function()
					if vrmod.PlayerModelPresets then
						vrmod.PlayerModelPresets.SaveCurrentModel()
					end
					vrmod.HeightWizard.Finish()
				end
			},
			{
				x = 160, y = 400, w = 120, h = 50,
				text = "Skip",
				fn = function()
					vrmod.HeightWizard.Finish()
				end
			},
		}
	end,
	render = function()
		DrawBackground()
		DrawTitle("Save Settings", 5, 5)
		local mdlName = GetModelShortName()
		local hasExisting = vrmod.PlayerModelPresets and
			vrmod.PlayerModelPresets.HasPreset(
				vrmod.PlayerModelPresets.GetCurrentModel()
			)
		DrawDescription({
			"",
			"Setup complete!",
			"",
			"Save these settings for",
			"\"" .. mdlName .. "\"?",
			"",
			"Settings will auto-load when",
			"you use this model again.",
			"",
			hasExisting and "(Overwrites existing preset)" or "",
		})
	end,
}

-- ========================================
-- Public API
-- ========================================

function vrmod.HeightWizard.IsActive()
	return wizardState ~= nil
end

function vrmod.HeightWizard.Start()
	wizardState = {}
	SetWizardStep(1)
end

function vrmod.HeightWizard.Cancel()
	wizardState = nil
	timer.Remove("vrmod_wizard_progress")
	-- Restore normal mirror buttons
	if vrmod.HeightMenuRender then
		vrmod.HeightMenuRender()
	end
end

function vrmod.HeightWizard.Finish()
	wizardState = nil
	timer.Remove("vrmod_wizard_progress")

	-- Show completion message briefly
	if IsMenuOpen() then
		VRUtilMenuRenderStart("heightmenu")
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, PANEL_W, PANEL_H)
		draw.DrawText("Setup Complete!", "Trebuchet24",
			PANEL_W / 2, PANEL_H / 2 - 15, Color(100, 255, 100), TEXT_ALIGN_CENTER)
		VRUtilMenuRenderEnd()
	end

	-- Restore normal buttons after brief display
	timer.Simple(1.5, function()
		if vrmod.HeightMenuRender then
			vrmod.HeightMenuRender()
		end
	end)
end

function vrmod.HeightWizard.Render()
	if not wizardState then return end
	if not IsMenuOpen() then
		wizardState = nil
		return
	end

	local step = steps[wizardState.step]
	if not step then return end

	VRUtilMenuRenderStart("heightmenu")

	-- Render step content (background, title, description)
	step.render(wizardState.substep)

	-- Render buttons
	local btns = step.getButtons(wizardState.substep)
	wizardState.currentButtons = btns
	for _, btn in ipairs(btns) do
		DrawButton(btn)
	end

	VRUtilMenuRenderEnd()
end

function vrmod.HeightWizard.HandleInput(cursorX, cursorY)
	if not wizardState or not wizardState.currentButtons then return end

	for _, btn in ipairs(wizardState.currentButtons) do
		if btn.fn and (btn.enabled ~= false) and
			cursorX > btn.x and cursorX < btn.x + btn.w and
			cursorY > btn.y and cursorY < btn.y + btn.h then
			btn.fn()
			return
		end
	end
end
