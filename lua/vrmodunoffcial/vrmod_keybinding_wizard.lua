if SERVER then return end
local L = VRModL or function(_, fb) return fb or "" end

-- ============================================
-- VR Keybinding Wizard
-- Step-by-step guided VR button assignment
-- Opens its own VR panel (400x512)
-- ============================================

vrmod.KeybindWizard = vrmod.KeybindWizard or {}

local PANEL_W = 400
local PANEL_H = 512
local MENU_UID = "keybindwizard"

local wizardState = nil -- nil = not active
local prevCaptureValues = {}

-- ========================================
-- Display Name Tables
-- ========================================

local RAW_DISPLAY_NAMES = {
	raw_right_trigger_bool = "Right Trigger",
	raw_left_trigger_bool  = "Left Trigger",
	raw_right_grip_bool    = "Right Grip",
	raw_left_grip_bool     = "Left Grip",
	raw_right_a            = "Right A/X",
	raw_right_b            = "Right B/Y",
	raw_left_a             = "Left A/X",
	raw_left_b             = "Left B/Y",
	raw_right_stick_click  = "Right Stick Click",
	raw_left_stick_click   = "Left Stick Click",
	raw_right_trigger_pull = "Right Trigger (Analog)",
	raw_left_trigger_pull  = "Left Trigger (Analog)",
	raw_right_grip_pull    = "Right Grip (Analog)",
	raw_left_grip_pull     = "Left Grip (Analog)",
	raw_right_stick        = "Right Stick",
	raw_left_stick         = "Left Stick",
}

local LOGICAL_DISPLAY_NAMES = {
	-- Core combat
	boolean_primaryfire        = "Primary Fire",
	boolean_secondaryfire      = "Secondary Fire",
	boolean_left_primaryfire   = "Left Primary Fire",
	boolean_left_secondaryfire = "Left Secondary Fire",
	-- Interaction
	boolean_use                = "Use / Interact",
	boolean_reload             = "Reload",
	boolean_right_pickup       = "Right Pickup",
	boolean_left_pickup        = "Left Pickup",
	-- Movement
	boolean_jump               = "Jump",
	boolean_crouch             = "Crouch",
	boolean_sprint             = "Sprint",
	boolean_walk               = "Walk",
	-- Menu/UI
	boolean_spawnmenu          = "Spawn Menu",
	boolean_changeweapon       = "Change Weapon",
	boolean_flashlight         = "Flashlight",
	-- Vehicle
	boolean_turret             = "Turret Fire",
	boolean_handbrake          = "Handbrake",
	boolean_turbo              = "Turbo / Boost",
	-- Analog
	vector1_primaryfire        = "Trigger (Analog)",
	vector1_left_primaryfire   = "Left Trigger (Analog)",
	vector1_forward            = "Throttle",
	vector1_reverse            = "Brake / Reverse",
	-- Sticks
	vector2_walkdirection      = "Walk Direction",
	vector2_smoothturn         = "Smooth Turn",
	vector2_steer              = "Steering",
}

-- ========================================
-- Action Lists (iteration order)
-- ========================================

local ONFOOT_ACTIONS = {
	-- Boolean
	"boolean_primaryfire", "boolean_secondaryfire",
	"boolean_left_primaryfire",
	"boolean_use", "boolean_reload",
	"boolean_right_pickup", "boolean_left_pickup",
	"boolean_jump", "boolean_crouch", "boolean_sprint",
	"boolean_spawnmenu", "boolean_changeweapon", "boolean_flashlight",
	-- Vector1
	"vector1_primaryfire", "vector1_left_primaryfire",
	-- Vector2
	"vector2_walkdirection", "vector2_smoothturn",
}

local DRIVING_ACTIONS = {
	-- Boolean
	"boolean_turret", "boolean_handbrake", "boolean_turbo",
	"boolean_right_pickup", "boolean_left_pickup", "boolean_spawnmenu",
	-- Vector1
	"vector1_forward", "vector1_reverse",
	-- Vector2
	"vector2_steer",
}

-- ========================================
-- Helpers
-- ========================================

local function GetActionType(logicalName)
	if string.sub(logicalName, 1, 7) == "vector2" then return "vector2" end
	if string.sub(logicalName, 1, 7) == "vector1" then return "vector1" end
	return "boolean"
end

local function GetActionList()
	if not wizardState then return {} end
	return wizardState.isDriving and DRIVING_ACTIONS or ONFOOT_ACTIONS
end

local function GetCurrentAction()
	if not wizardState then return nil end
	local actions = GetActionList()
	return actions[wizardState.actionIndex]
end

local function GetDisplayName(logicalName)
	return LOGICAL_DISPLAY_NAMES[logicalName] or logicalName
end

local function GetRawDisplayName(rawName)
	return RAW_DISPLAY_NAMES[rawName] or rawName
end

-- Find which raw action maps to a given logical action in pendingMapping
local function FindRawForLogical(logicalName)
	if not wizardState then return nil end
	for raw, logical in pairs(wizardState.pendingMapping) do
		if logical == logicalName then return raw end
	end
	return nil
end

-- Find which logical action a raw button is currently assigned to
local function FindLogicalForRaw(rawName)
	if not wizardState then return nil end
	return wizardState.pendingMapping[rawName]
end

local function IsMenuOpen()
	return VRUtilIsMenuOpen and VRUtilIsMenuOpen(MENU_UID)
end

-- Seed prevCaptureValues with current raw input state.
-- Prevents held buttons from re-triggering on the next action.
local function SeedPrevCapture()
	prevCaptureValues = {}
	local rawValues = g_VR.luaKeybinding and g_VR.luaKeybinding.rawValues
	if rawValues then
		for _, rn in ipairs(g_VR.rawActionNames or {}) do
			if rawValues[rn] ~= nil then
				prevCaptureValues[rn] = rawValues[rn]
			end
		end
	end
end

-- ========================================
-- Drawing Primitives (same pattern as height wizard)
-- ========================================

local function DrawBackground()
	surface.SetDrawColor(0, 0, 0, 210)
	surface.DrawRect(0, 0, PANEL_W, PANEL_H)
end

local function DrawTitle(text, info)
	draw.DrawText(info or "", "Trebuchet18",
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

local function DrawCenteredText(text, font, y, color)
	draw.DrawText(text, font or "Trebuchet24",
		PANEL_W / 2, y, color or Color(255, 255, 255), TEXT_ALIGN_CENTER)
end

local function DrawButton(btn)
	local bgColor = (btn.enabled ~= false) and Color(40, 40, 40) or Color(20, 20, 20)
	local textColor = (btn.enabled ~= false) and Color(255, 255, 255) or Color(100, 100, 100)
	local borderColor = (btn.highlight) and Color(100, 200, 100) or Color(100, 100, 100)

	surface.SetDrawColor(bgColor)
	surface.DrawRect(btn.x, btn.y, btn.w, btn.h)
	surface.SetDrawColor(borderColor)
	surface.DrawOutlinedRect(btn.x, btn.y, btn.w, btn.h)

	local font = btn.font or "Trebuchet18"
	surface.SetFont(font)
	local _, fontH = surface.GetTextSize("A")
	local lineCount = 1
	for _ in string.gmatch(btn.text, "\n") do lineCount = lineCount + 1 end
	local textY = btn.y + (btn.h - fontH * lineCount) / 2

	draw.DrawText(btn.text, font,
		btn.x + btn.w / 2, textY,
		textColor, TEXT_ALIGN_CENTER)
end

-- ========================================
-- State Machine
-- ========================================

local function SetWizardStep(stepNum, extra)
	if not IsMenuOpen() then
		wizardState = nil
		return
	end
	wizardState.step = stepNum
	wizardState.startTime = CurTime()
	wizardState.captureActive = false
	wizardState.lastCapturedRaw = nil
	wizardState.confirmAction = nil

	if extra then
		for k, v in pairs(extra) do
			wizardState[k] = v
		end
	end

	vrmod.KeybindWizard.Render()
end

-- ========================================
-- Raw Input Capture (Think hook)
-- ========================================

local function OnRawCaptured(rawName)
	if not wizardState or not wizardState.captureActive then return end

	local currentAction = GetCurrentAction()
	if not currentAction then return end

	-- Check for duplicate: is this raw button already assigned to another action?
	local existingLogical = FindLogicalForRaw(rawName)
	if existingLogical and existingLogical ~= currentAction then
		-- Enter confirm substep
		wizardState.captureActive = false
		wizardState.confirmAction = {
			rawName = rawName,
			existingLogical = existingLogical,
			targetLogical = currentAction,
		}
		vrmod.KeybindWizard.Render()
		return
	end

	-- Remove old mapping for this logical action (if any)
	local oldRaw = FindRawForLogical(currentAction)
	if oldRaw then
		wizardState.pendingMapping[oldRaw] = nil
	end

	-- Assign
	wizardState.pendingMapping[rawName] = currentAction
	wizardState.captureActive = false
	wizardState.lastCapturedRaw = rawName

	vrmod.KeybindWizard.Render()

	-- Auto-advance after 0.8s
	timer.Create("vrmod_kbwiz_advance", 0.8, 1, function()
		if not wizardState or wizardState.step ~= 2 then return end
		local actions = GetActionList()
		if wizardState.actionIndex < #actions then
			wizardState.actionIndex = wizardState.actionIndex + 1
			wizardState.captureActive = true
			wizardState.lastCapturedRaw = nil
			SeedPrevCapture()
			vrmod.KeybindWizard.Render()
		else
			-- All actions done -> review
			SetWizardStep(3)
		end
	end)
end

local function CaptureThink()
	if not wizardState or not wizardState.captureActive then return end

	-- VR no longer active: force cleanup
	if not g_VR or not g_VR.active then
		vrmod.KeybindWizard.Cancel()
		return
	end

	local LKB = g_VR.luaKeybinding
	local rawValues = LKB and LKB.rawValues
	if not rawValues then return end

	local targetType = wizardState.captureType
	if not targetType then return end

	-- When cursor is on our panel, skip only the trigger used for UI clicks
	-- (all other buttons remain capturable even while looking at the panel)
	local skipRaws = {}
	if g_VR.menuFocus == MENU_UID then
		local mapping = LKB and LKB.mapping
		if mapping then
			for raw, logical in pairs(mapping) do
				if logical == "boolean_primaryfire" then
					skipRaws[raw] = true
					-- Also skip the corresponding analog trigger
					-- raw_right_trigger_bool -> raw_right_trigger_pull
					local pullName = string.gsub(raw, "_bool$", "_pull")
					if pullName ~= raw then
						skipRaws[pullName] = true
					end
					break
				end
			end
		end
	end

	for _, rawName in ipairs(g_VR.rawActionNames or {}) do
		local rawType = g_VR.rawActionTypes and g_VR.rawActionTypes[rawName]
		if rawType ~= targetType then continue end

		-- Skip UI-click trigger (keep tracking prev to avoid false edges)
		if skipRaws[rawName] then
			prevCaptureValues[rawName] = rawValues[rawName]
			continue
		end

		local val = rawValues[rawName]
		local prev = prevCaptureValues[rawName]

		if rawType == "boolean" then
			if val == true and prev ~= true then
				OnRawCaptured(rawName)
				break
			end
		elseif rawType == "vector1" then
			local numVal = type(val) == "number" and val or 0
			local numPrev = type(prev) == "number" and prev or 0
			if numVal > 0.5 and numPrev <= 0.5 then
				OnRawCaptured(rawName)
				break
			end
		elseif rawType == "vector2" then
			if type(val) == "table" then
				local mag = math.sqrt((val.x or 0) ^ 2 + (val.y or 0) ^ 2)
				local prevMag = 0
				if type(prev) == "table" then
					prevMag = math.sqrt((prev.x or 0) ^ 2 + (prev.y or 0) ^ 2)
				end
				if mag > 0.5 and prevMag <= 0.5 then
					OnRawCaptured(rawName)
					break
				end
			end
		end

		prevCaptureValues[rawName] = val
	end
end

-- ========================================
-- Step Rendering
-- ========================================

local function RenderStep1_Welcome()
	DrawBackground()
	DrawTitle(L("Keybinding Wizard", "Keybinding Wizard"))

	DrawDescription({
		"",
		L("This wizard will guide you through", "This wizard will guide you through"),
		L("assigning VR controller buttons", "assigning VR controller buttons"),
		L("to game actions, one at a time.", "to game actions, one at a time."),
		"",
		L("For each action, press the VR", "For each action, press the VR"),
		L("button you want to use.", "button you want to use."),
		"",
		L("Choose a control scheme:", "Choose a control scheme:"),
	})

	return {
		{
			x = 100, y = 290, w = 200, h = 50,
			text = L("On-Foot Controls", "On-Foot Controls"),
			highlight = true,
			fn = function()
				wizardState.isDriving = false
				-- Pre-populate from current on-foot mapping
				local LKB = g_VR.luaKeybinding
				wizardState.pendingMapping = {}
				if LKB and LKB.mapping then
					for k, v in pairs(LKB.mapping) do
						wizardState.pendingMapping[k] = v
					end
				end
				SetWizardStep(2, {
					actionIndex = 1,
					captureActive = true,
					captureType = GetActionType(ONFOOT_ACTIONS[1]),
				})
				SeedPrevCapture()
			end
		},
		{
			x = 100, y = 355, w = 200, h = 50,
			text = L("Vehicle Controls", "Vehicle Controls"),
			fn = function()
				wizardState.isDriving = true
				local LKB = g_VR.luaKeybinding
				wizardState.pendingMapping = {}
				if LKB and LKB.drivingMapping then
					for k, v in pairs(LKB.drivingMapping) do
						wizardState.pendingMapping[k] = v
					end
				end
				SetWizardStep(2, {
					actionIndex = 1,
					captureActive = true,
					captureType = GetActionType(DRIVING_ACTIONS[1]),
				})
				SeedPrevCapture()
			end
		},
		{
			x = 10, y = 470, w = 80, h = 30,
			text = L("Cancel", "Cancel"),
			fn = function() vrmod.KeybindWizard.Cancel() end
		},
	}
end

local function RenderStep2_Capture()
	DrawBackground()

	local actions = GetActionList()
	local idx = wizardState.actionIndex
	local totalActions = #actions
	local currentAction = actions[idx]
	if not currentAction then return {} end

	local actionType = GetActionType(currentAction)
	wizardState.captureType = actionType

	local typeLabel = actionType == "boolean" and "Button" or
		(actionType == "vector1" and "Analog" or "Stick")
	DrawTitle(L("Keybinding Wizard", "Keybinding Wizard"),
		string.format("%d/%d (%s)", idx, totalActions, typeLabel))

	-- Current action name (large)
	DrawCenteredText(GetDisplayName(currentAction), "Trebuchet24", 55, Color(255, 255, 255))

	-- Separator
	surface.SetDrawColor(80, 80, 80)
	surface.DrawRect(40, 88, PANEL_W - 80, 1)

	-- Existing mapping
	local existingRaw = FindRawForLogical(currentAction)
	if existingRaw then
		DrawCenteredText(
			L("Current:", "Current:") .. " " .. GetRawDisplayName(existingRaw),
			"Trebuchet18", 100, Color(150, 150, 150))
	else
		DrawCenteredText(
			L("Current: (none)", "Current: (none)"),
			"Trebuchet18", 100, Color(100, 100, 100))
	end

	-- Confirm duplicate substep
	if wizardState.confirmAction then
		local ca = wizardState.confirmAction
		DrawDescription({
			"",
			"",
			GetRawDisplayName(ca.rawName) .. " " .. L("is already assigned to:", "is already assigned to:"),
			"  " .. GetDisplayName(ca.existingLogical),
			"",
			L("Replace it?", "Replace it?"),
		}, 130)

		return {
			{
				x = 80, y = 330, w = 100, h = 45,
				text = L("Yes", "Yes"),
				highlight = true,
				fn = function()
					-- Remove old mapping
					local oldRaw = FindRawForLogical(ca.targetLogical)
					if oldRaw then wizardState.pendingMapping[oldRaw] = nil end
					-- Remove the existing assignment from the conflicting action
					wizardState.pendingMapping[ca.rawName] = ca.targetLogical
					wizardState.confirmAction = nil
					wizardState.lastCapturedRaw = ca.rawName
					vrmod.KeybindWizard.Render()
					-- Auto-advance
					timer.Create("vrmod_kbwiz_advance", 0.8, 1, function()
						if not wizardState or wizardState.step ~= 2 then return end
						local acts = GetActionList()
						if wizardState.actionIndex < #acts then
							wizardState.actionIndex = wizardState.actionIndex + 1
							wizardState.captureActive = true
							wizardState.lastCapturedRaw = nil
							wizardState.captureType = GetActionType(acts[wizardState.actionIndex])
							SeedPrevCapture()
							vrmod.KeybindWizard.Render()
						else
							SetWizardStep(3)
						end
					end)
				end
			},
			{
				x = 220, y = 330, w = 100, h = 45,
				text = L("No", "No"),
				fn = function()
					wizardState.confirmAction = nil
					wizardState.captureActive = true
					SeedPrevCapture()
					vrmod.KeybindWizard.Render()
				end
			},
			{
				x = 10, y = 470, w = 80, h = 30,
				text = L("Cancel", "Cancel"),
				fn = function() vrmod.KeybindWizard.Cancel() end
			},
		}
	end

	-- Capture feedback or waiting state
	if wizardState.lastCapturedRaw then
		-- Just captured
		DrawCenteredText(
			GetRawDisplayName(wizardState.lastCapturedRaw),
			"Trebuchet24", 180, Color(100, 255, 100))

		-- Green confirmation bar
		surface.SetDrawColor(60, 180, 60)
		surface.DrawRect(60, 220, PANEL_W - 120, 4)
	else
		-- Waiting for input
		local promptText
		if actionType == "boolean" then
			promptText = L("Press the VR button you want to use", "Press the VR button you want to use")
		elseif actionType == "vector1" then
			promptText = L("Pull the trigger/grip to assign", "Pull the trigger/grip to assign")
		else
			promptText = L("Move the stick to assign", "Move the stick to assign")
		end
		DrawCenteredText(promptText, "Trebuchet18", 150, Color(200, 200, 200))

		-- Pulsing indicator
		local pulse = math.sin(CurTime() * 3) * 0.4 + 0.6
		local alpha = math.floor(pulse * 255)
		DrawCenteredText("...", "Trebuchet24", 190, Color(255, 255, 100, alpha))
	end

	-- Buttons
	local buttons = {}

	-- Advance helper (shared by Skip/Clear)
	local function AdvanceToNext()
		if idx < totalActions then
			wizardState.actionIndex = idx + 1
			wizardState.captureActive = true
			wizardState.lastCapturedRaw = nil
			wizardState.captureType = GetActionType(actions[idx + 1])
			SeedPrevCapture()
			vrmod.KeybindWizard.Render()
		else
			SetWizardStep(3)
		end
	end

	-- Skip (keep existing mapping, move to next)
	buttons[#buttons + 1] = {
		x = 20, y = 420, w = 80, h = 40,
		text = L("Skip", "Skip"),
		fn = function()
			timer.Remove("vrmod_kbwiz_advance")
			AdvanceToNext()
		end
	}

	-- Clear (remove mapping for this action, move to next)
	buttons[#buttons + 1] = {
		x = 110, y = 420, w = 80, h = 40,
		text = L("Clear", "Clear"),
		fn = function()
			timer.Remove("vrmod_kbwiz_advance")
			local oldRaw = FindRawForLogical(currentAction)
			if oldRaw then wizardState.pendingMapping[oldRaw] = nil end
			AdvanceToNext()
		end
	}

	-- Back
	if idx > 1 then
		buttons[#buttons + 1] = {
			x = 200, y = 420, w = 80, h = 40,
			text = L("Back", "Back"),
			fn = function()
				timer.Remove("vrmod_kbwiz_advance")
				wizardState.actionIndex = idx - 1
				wizardState.captureActive = true
				wizardState.lastCapturedRaw = nil
				wizardState.captureType = GetActionType(actions[idx - 1])
				SeedPrevCapture()
				vrmod.KeybindWizard.Render()
			end
		}
	end

	-- Cancel
	buttons[#buttons + 1] = {
		x = 10, y = 470, w = 80, h = 30,
		text = L("Cancel", "Cancel"),
		fn = function() vrmod.KeybindWizard.Cancel() end
	}

	return buttons
end

local function RenderStep3_Review()
	DrawBackground()
	DrawTitle(L("Review Mappings", "Review Mappings"),
		wizardState.isDriving and L("Vehicle", "Vehicle") or L("On-Foot", "On-Foot"))

	local actions = GetActionList()
	local y = 45

	for _, logicalName in ipairs(actions) do
		local rawName = FindRawForLogical(logicalName)
		local displayLogical = GetDisplayName(logicalName)
		local displayRaw = rawName and GetRawDisplayName(rawName) or "(none)"
		local rawColor = rawName and Color(100, 255, 100) or Color(120, 120, 120)

		-- Truncate display name if too long
		local maxLogicalLen = 18
		if #displayLogical > maxLogicalLen then
			displayLogical = string.sub(displayLogical, 1, maxLogicalLen - 2) .. ".."
		end

		draw.DrawText(displayLogical, "Trebuchet18", 15, y, Color(220, 220, 220))
		draw.DrawText("->", "Trebuchet18", 200, y, Color(100, 100, 100))
		draw.DrawText(displayRaw, "Trebuchet18", 225, y, rawColor)
		y = y + 20
	end

	return {
		{
			x = 30, y = 430, w = 100, h = 45,
			text = L("Redo", "Redo"),
			fn = function()
				SetWizardStep(2, {
					actionIndex = 1,
					captureActive = true,
					captureType = GetActionType(actions[1]),
				})
				SeedPrevCapture()
			end
		},
		{
			x = 160, y = 430, w = 120, h = 45,
			text = L("Save", "Save"),
			highlight = true,
			fn = function()
				vrmod.KeybindWizard.Save()
			end
		},
		{
			x = 310, y = 470, w = 80, h = 30,
			text = L("Cancel", "Cancel"),
			fn = function() vrmod.KeybindWizard.Cancel() end
		},
	}
end

local function RenderStep4_Done()
	DrawBackground()
	DrawCenteredText(L("Setup Complete!", "Setup Complete!"), "Trebuchet24", 200, Color(100, 255, 100))
	DrawCenteredText(L("Keybindings saved.", "Keybindings saved."), "Trebuchet18", 240, Color(180, 180, 180))
	return {}
end

-- ========================================
-- Public API
-- ========================================

function vrmod.KeybindWizard.IsActive()
	return wizardState ~= nil
end

function vrmod.KeybindWizard.Start()
	if not g_VR or not g_VR.active then
		print("[VRMod KeybindWizard] VR not active")
		return
	end

	-- Auto-enable Lua keybinding mode for raw input
	local cv = GetConVar("vrmod_unoff_inputmode")
	if cv and cv:GetInt() ~= 1 then
		RunConsoleCommand("vrmod_unoff_inputmode", "1")
	end

	-- Open VR panel if not already open
	if not IsMenuOpen() then
		VRUtilMenuOpen(
			MENU_UID,
			PANEL_W, PANEL_H,
			nil,          -- no VGUI panel, render directly
			3,            -- HMD follow
			Vector(50, 8, -5),
			Angle(0, -90, 90),
			0.04,         -- scale
			true,         -- cursor enabled
			function()    -- close callback
				vrmod.KeybindWizard.Cancel()
			end
		)
	end

	wizardState = {
		step = 1,
		isDriving = false,
		actionIndex = 1,
		pendingMapping = {},
		captureActive = false,
		captureType = nil,
		lastCapturedRaw = nil,
		confirmAction = nil,
		currentButtons = {},
		startTime = CurTime(),
	}

	-- Install hooks
	hook.Add("VRMod_Input", "vrmod_keybindwizard_input", function(action, pressed)
		if g_VR.menuFocus == MENU_UID and action == "boolean_primaryfire" and pressed then
			vrmod.KeybindWizard.HandleInput(g_VR.menuCursorX, g_VR.menuCursorY)
		end
	end)

	hook.Add("Think", "vrmod_keybindwizard_capture", CaptureThink)

	-- Animation timer: re-renders during capture waiting for pulsing indicator
	timer.Create("vrmod_kbwiz_anim", 0.15, 0, function()
		if not wizardState or not g_VR or not g_VR.active then
			timer.Remove("vrmod_kbwiz_anim")
			return
		end
		if wizardState.step == 2 and wizardState.captureActive then
			vrmod.KeybindWizard.Render()
		end
	end)

	vrmod.KeybindWizard.Render()
end

local cancellingNow = false

function vrmod.KeybindWizard.Cancel()
	if cancellingNow then return end -- re-entry guard (closeFunc calls Cancel)
	cancellingNow = true

	wizardState = nil
	prevCaptureValues = {}
	timer.Remove("vrmod_kbwiz_advance")
	timer.Remove("vrmod_kbwiz_close")
	timer.Remove("vrmod_kbwiz_anim")
	hook.Remove("VRMod_Input", "vrmod_keybindwizard_input")
	hook.Remove("Think", "vrmod_keybindwizard_capture")
	if IsMenuOpen() then
		VRUtilMenuClose(MENU_UID)
	end

	cancellingNow = false
end

function vrmod.KeybindWizard.Save()
	if not wizardState then return end

	local LKB = g_VR.luaKeybinding
	if not LKB then return end

	if wizardState.isDriving then
		LKB.drivingMapping = wizardState.pendingMapping
	else
		LKB.mapping = wizardState.pendingMapping
	end

	if LKB.SaveMapping then
		LKB.SaveMapping()
	end

	-- Show completion
	SetWizardStep(4)

	-- Auto-close after 1.5s
	timer.Create("vrmod_kbwiz_close", 1.5, 1, function()
		vrmod.KeybindWizard.Cancel()
	end)
end

function vrmod.KeybindWizard.Render()
	if not wizardState then return end
	if not IsMenuOpen() then
		wizardState = nil
		return
	end

	VRUtilMenuRenderStart(MENU_UID)

	local buttons = {}
	if wizardState.step == 1 then
		buttons = RenderStep1_Welcome()
	elseif wizardState.step == 2 then
		buttons = RenderStep2_Capture()
	elseif wizardState.step == 3 then
		buttons = RenderStep3_Review()
	elseif wizardState.step == 4 then
		buttons = RenderStep4_Done()
	end

	wizardState.currentButtons = buttons or {}
	for _, btn in ipairs(wizardState.currentButtons) do
		DrawButton(btn)
	end

	VRUtilMenuRenderEnd()
end

function vrmod.KeybindWizard.HandleInput(cursorX, cursorY)
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

-- ========================================
-- Console Command
-- ========================================

concommand.Add("vrmod_keybinding_wizard", function()
	if vrmod.KeybindWizard.IsActive() then
		vrmod.KeybindWizard.Cancel()
	else
		vrmod.KeybindWizard.Start()
	end
end)

-- ========================================
-- VR Exit / Emergency Stop Cleanup
-- ========================================

hook.Add("VRMod_Exit", "vrmod_keybindwizard_exit", function(ply)
	if ply ~= LocalPlayer() then return end
	if vrmod.KeybindWizard.IsActive() then
		vrmod.KeybindWizard.Cancel()
	end
end)

print("[VRMod] Keybinding wizard loaded (vrmod_keybinding_wizard)")
