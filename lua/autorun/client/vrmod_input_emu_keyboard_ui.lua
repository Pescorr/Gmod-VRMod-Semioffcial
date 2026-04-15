-- Visual Keyboard UI for VR Input Emulation Key Assignment
--
-- Opens a DFrame showing a full keyboard layout.
-- Flow: Click a keyboard key → Press VR controller button → Mapping saved
-- Fallback: If VR not active, shows a dropdown menu of available actions.
--
-- Requires: !vrmod_input_emu.lua (loaded first via autorun/client/ ! prefix)
-- Failsafe: If API not available, shows error message. Never crashes.

if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

local TAG = "[InputEmu Editor] "

-- ============================================================================
-- Layout Constants
-- ============================================================================

local KW  = 44   -- standard key width (pixels)
local KH  = 36   -- key height
local KG  = 3    -- gap between keys
local RG  = 4    -- gap between rows
local PAD = 12   -- frame edge padding

-- ============================================================================
-- Short display names for VR actions (fit on keyboard key face)
-- ============================================================================

local ACTION_SHORT = {
	["boolean_primaryfire"]        = "Prim(R)",
	["boolean_secondaryfire"]      = "Sec(R)",
	["boolean_left_primaryfire"]   = "Prim(L)",
	["boolean_left_secondaryfire"] = "Sec(L)",
	["boolean_reload"]             = "Reload",
	["boolean_use"]                = "Use",
	["boolean_flashlight"]         = "Flash",
	["boolean_sprint"]             = "Sprint",
	["boolean_jump"]               = "Jump",
	["boolean_crouch"]             = "Crouch",
	["boolean_walkkey"]            = "Walk",
	["boolean_forword"]            = "Fwd",
	["boolean_back"]               = "Back",
	["boolean_left"]               = "MvLeft",
	["boolean_right"]              = "MvRight",
	["boolean_undo"]               = "Undo",
	["boolean_chat"]               = "Chat",
	["boolean_menucontext"]        = "CtxMenu",
	["boolean_spawnmenu"]          = "Spawn",
	["boolean_slot1"]              = "Slot1",
	["boolean_slot2"]              = "Slot2",
	["boolean_slot3"]              = "Slot3",
	["boolean_slot4"]              = "Slot4",
	["boolean_slot5"]              = "Slot5",
	["boolean_slot6"]              = "Slot6",
}

--- Find full action label from ACTION_DEFS
local function GetActionFullLabel(action)
	if not vrmod or not vrmod.InputEmu_GetActionDefs then return action end
	for _, def in ipairs(vrmod.InputEmu_GetActionDefs()) do
		if def.action == action then return def.label end
	end
	return action
end

-- ============================================================================
-- Keyboard Layout: uses shared unified layout from !vrmod_input_emu.lua
-- ============================================================================
-- vrmod.UNIFIED_KEYBOARD_LAYOUT is loaded first (autorun/client/ ! prefix)
-- Each key: {buttonCode, label, widthMultiplier, shiftLabel}
--   buttonCode > 0  : interactive key (BUTTON_CODE constant)
--   buttonCode == -1 : invisible gap spacer (width only, no rendering)
--   buttonCode == -2 : numpad anchor (jumps x to fixed numpad start position)

-- ============================================================================
-- Key button paint function (reusable) — cached colors for performance
-- ============================================================================

local CLR_ASGN_YES_BG     = Color(25, 85, 35, 235)
local CLR_ASGN_YES_HOVER  = Color(35, 110, 50, 240)
local CLR_ASGN_BG         = Color(42, 42, 48, 235)
local CLR_ASGN_BG_HOVER   = Color(58, 58, 68, 240)
local CLR_RAW_YES_BG_D    = Color(20, 55, 85, 235)
local CLR_RAW_YES_HOVER_D = Color(30, 75, 110, 240)
local CLR_RAW_YES_BORDER_D = Color(50, 120, 180)
local CLR_RAW_YES_BRD_H_D = Color(70, 160, 220)
local CLR_RAW_TEXT_D       = Color(100, 180, 255, 210)
local CLR_SEL_BORDER      = Color(255, 220, 50)
local CLR_YES_BORDER      = Color(50, 140, 60)
local CLR_YES_BRD_HOVER   = Color(80, 180, 90)
local CLR_BORDER           = Color(70, 70, 80)
local CLR_BORDER_HOVER     = Color(120, 120, 150)
local CLR_LABEL_SEL        = Color(255, 255, 220)
local CLR_LABEL_NORMAL     = Color(210, 210, 215)
local CLR_ACTION_TEXT      = Color(140, 220, 155, 210)

local function PaintKeyButton(self, w, h)
	local isAssigned = #self.assignedActions > 0
	local isRawAssigned = self.assignedRawMappings and #self.assignedRawMappings > 0
	local hasAny = isAssigned or isRawAssigned
	local isHovered  = self:IsHovered()
	local isSel      = self.isSelected

	-- Background color
	local bg
	if isSel then
		local pulse = math.sin(CurTime() * 5) * 0.3 + 0.7
		bg = Color(
			math.floor(200 * pulse),
			math.floor(160 * pulse),
			0, 235
		)
	elseif isAssigned and isRawAssigned then
		bg = isHovered and CLR_ASGN_YES_HOVER or CLR_ASGN_YES_BG
	elseif isRawAssigned then
		bg = isHovered and CLR_RAW_YES_HOVER_D or CLR_RAW_YES_BG_D
	elseif isAssigned then
		bg = isHovered and CLR_ASGN_YES_HOVER or CLR_ASGN_YES_BG
	else
		bg = isHovered and CLR_ASGN_BG_HOVER or CLR_ASGN_BG
	end

	draw.RoundedBox(3, 0, 0, w, h, bg)

	-- Border
	local border
	if isSel then
		border = CLR_SEL_BORDER
	elseif isRawAssigned and isAssigned then
		border = isHovered and CLR_RAW_YES_BRD_H_D or CLR_RAW_YES_BORDER_D
	elseif isRawAssigned then
		border = isHovered and CLR_RAW_YES_BRD_H_D or CLR_RAW_YES_BORDER_D
	elseif isAssigned then
		border = isHovered and CLR_YES_BRD_HOVER or CLR_YES_BORDER
	else
		border = isHovered and CLR_BORDER_HOVER or CLR_BORDER
	end
	surface.SetDrawColor(border)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	-- Key label text
	local labelY = hasAny and (h * 0.22) or (h * 0.5)
	local labelColor = isSel and CLR_LABEL_SEL or CLR_LABEL_NORMAL
	draw.SimpleText(
		self.keyLabel, "DermaDefaultBold",
		w / 2, labelY,
		labelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
	)

	-- Assigned action short name (green text)
	if isAssigned and not isSel then
		local txt = ""
		for i, act in ipairs(self.assignedActions) do
			if i > 1 then txt = txt .. " " end
			txt = txt .. (ACTION_SHORT[act] or "?")
		end
		local maxChars = math.max(3, math.floor(w / 6))
		if #txt > maxChars then
			txt = string.sub(txt, 1, maxChars - 1) .. ".."
		end
		local actionY = isRawAssigned and (h * 0.52) or (h * 0.65)
		draw.SimpleText(
			txt, "DermaDefault",
			w / 2, actionY,
			CLR_ACTION_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
		)
	end

	-- Raw button assignments (cyan text)
	if isRawAssigned and not isSel then
		local AI = g_VR and g_VR.advancedInput
		local txt = ""
		for i, rm in ipairs(self.assignedRawMappings) do
			if i > 1 then txt = txt .. " " end
			if AI then
				txt = txt .. AI.GetShortRawName(rm.raw) .. ":" .. AI.GetShortGestureChar(rm.gesture)
			else
				txt = txt .. "?"
			end
		end
		local maxChars = math.max(3, math.floor(w / 6))
		if #txt > maxChars then
			txt = string.sub(txt, 1, maxChars - 1) .. ".."
		end
		draw.SimpleText(
			txt, "DermaDefault",
			w / 2, h * 0.80,
			CLR_RAW_TEXT_D, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
		)
	end
end

-- ============================================================================
-- Main editor (singleton)
-- ============================================================================

local editorFrame = nil

local function OpenKeyboardEditor()
	-- Toggle: close if already open
	if IsValid(editorFrame) then
		editorFrame:Close()
		return
	end

	-- Validate API availability (failsafe)
	if not vrmod or not vrmod.InputEmu_GetMapping then
		print(TAG .. "ERROR: VR Input Emulation system is not loaded.")
		chat.AddText(Color(255, 100, 100), "[VRMod] ", Color(255, 255, 255), "Input Emulation system not loaded. Check addon installation.")
		return
	end

	if not vrmod.InputEmu_GetReverseMap then
		print(TAG .. "ERROR: VR Input Emulation API is outdated. Restart Garry's Mod.")
		chat.AddText(Color(255, 100, 100), "[VRMod] ", Color(255, 255, 255), "Input Emulation API outdated. Restart Garry's Mod.")
		return
	end

	-- Failsafe: shared layout must be loaded
	if not vrmod.UNIFIED_KEYBOARD_LAYOUT then
		print(TAG .. "ERROR: UNIFIED_KEYBOARD_LAYOUT not found. !vrmod_input_emu.lua may not be loaded.")
		chat.AddText(Color(255, 100, 100), "[VRMod] ", Color(255, 255, 255), "Keyboard layout not found. Check addon installation.")
		return
	end

	-- ===================================================================
	-- State variables (upvalues shared by all helper functions below)
	-- ===================================================================
	local selectedCode  = nil   -- BUTTON_CODE of key being captured
	local selectedPanel = nil   -- panel reference for the selected key
	local keyPanels     = {}    -- buttonCode → DButton

	-- ===================================================================
	-- Pre-calculate layout size (using shared unified layout)
	-- ===================================================================
	local KEYBOARD_LAYOUT = vrmod.UNIFIED_KEYBOARD_LAYOUT
	local kbW, kbH, numpadStartX = vrmod.CalcKeyboardDimensions(KW, KH, KG, RG, PAD)
	-- kbW/kbH already include PAD*2 from shared calculator
	local frameW = kbW + 10
	local checkboxBarH = 22
	local statusAreaH  = 78
	local frameH = checkboxBarH + kbH + statusAreaH + 28

	-- ===================================================================
	-- Forward-declared helper references
	-- ===================================================================
	local statusLabel -- set later after frame creation

	local function UpdateStatus(text, color)
		if IsValid(statusLabel) then
			statusLabel:SetText(text or "")
			statusLabel:SetTextColor(color or Color(200, 200, 200))
		end
	end

	-- Raw assignment sub-mode state
	local rawAssignMode = false
	local selectedGesture = "short_press"

	local function RefreshKeyStates()
		local ok, reverseMap = pcall(vrmod.InputEmu_GetReverseMap)
		if not ok then reverseMap = {} end
		-- Also get raw button assignments from advanced input
		local rawReverseMap = {}
		local AI = g_VR and g_VR.advancedInput
		if AI and AI.GetKeyReverseMap then
			local rok, rrm = pcall(AI.GetKeyReverseMap)
			if rok then rawReverseMap = rrm end
		end
		for code, panel in pairs(keyPanels) do
			if IsValid(panel) then
				panel.assignedActions = reverseMap[code] or {}
				panel.assignedRawMappings = rawReverseMap[code] or {}
			end
		end
	end

	local function CancelCapture()
		if IsValid(selectedPanel) then selectedPanel.isSelected = false end
		selectedCode  = nil
		selectedPanel = nil
		if vrmod.InputEmu_CancelCapture then
			pcall(vrmod.InputEmu_CancelCapture)
		end
		if vrmod.InputEmu_CancelRawCapture then
			pcall(vrmod.InputEmu_CancelRawCapture)
		end
	end

	-- ===================================================================
	-- Show action dropdown (fallback for non-VR, or right-click)
	-- ===================================================================
	local function ShowActionDropdown(buttonCode, keyLabel)
		local ok, defs = pcall(vrmod.InputEmu_GetActionDefs)
		if not ok or not defs then return end

		local menu = DermaMenu()
		for _, def in ipairs(defs) do
			menu:AddOption(def.label, function()
				vrmod.InputEmu_AssignKeyToAction(def.action, buttonCode)
				CancelCapture()
				RefreshKeyStates()
				UpdateStatus(
					"Assigned: " .. def.label .. " -> [" .. keyLabel .. "]",
					Color(100, 255, 100)
				)
				surface.PlaySound("buttons/button14.wav")
			end)
		end
		menu:AddSpacer()
		menu:AddOption(L("Cancel", "Cancel"), function()
			CancelCapture()
			UpdateStatus(L("Click a key to assign a VR controller action.", "Click a key to assign a VR controller action."))
		end)
		menu:Open()
	end

	-- ===================================================================
	-- Show raw button dropdown (fallback for non-VR in raw mode)
	-- ===================================================================
	local function ShowRawDropdown(buttonCode, keyLabel)
		local AI = g_VR and g_VR.advancedInput
		if not AI then return end
		local rawBooleans = AI.GetAvailableRawBooleans()
		if #rawBooleans == 0 then return end

		local menu = DermaMenu()
		for _, rawName in ipairs(rawBooleans) do
			menu:AddOption(AI.GetRawDisplayName(rawName), function()
				AI.AddMapping(rawName, selectedGesture, "key", buttonCode, {})
				AI.Save()
				CancelCapture()
				RefreshKeyStates()
				local shortName = AI.GetShortRawName(rawName) .. ":" .. AI.GetShortGestureChar(selectedGesture)
				UpdateStatus(
					"Assigned: " .. shortName .. " -> [" .. keyLabel .. "]",
					Color(100, 200, 255)
				)
				surface.PlaySound("buttons/button14.wav")
			end)
		end
		menu:AddSpacer()
		menu:AddOption(L("Cancel", "Cancel"), function()
			CancelCapture()
			UpdateStatus(L("Click a key to assign.", "Click a key to assign."))
		end)
		menu:Open()
	end

	-- ===================================================================
	-- Start capture mode for a selected key
	-- ===================================================================
	local function StartCapture(buttonCode, keyLabel)
		local vrActive = g_VR and g_VR.active

		if rawAssignMode then
			-- === Raw Button Assignment Mode ===
			local AI = g_VR and g_VR.advancedInput
			local gestName = AI and AI.GetGestureDisplayName(selectedGesture) or selectedGesture
			if vrActive then
				UpdateStatus(
					"[" .. keyLabel .. "]  --  Press a VR button to assign [" .. gestName .. "]. Right-click for list.",
					Color(100, 200, 255)
				)
			else
				UpdateStatus(
					"[" .. keyLabel .. "]  --  VR not active. Choose from raw button list.",
					Color(100, 180, 255)
				)
			end

			if vrActive and vrmod.InputEmu_StartRawCapture then
				pcall(vrmod.InputEmu_StartRawCapture, function(rawName)
					if not IsValid(editorFrame) then return end
					if not rawName then
						CancelCapture()
						UpdateStatus(L("Capture cancelled.", "Capture cancelled."))
						return
					end

					if AI and AI.AddMapping then
						AI.AddMapping(rawName, selectedGesture, "key", buttonCode, {})
						AI.Save()
					end

					CancelCapture()
					RefreshKeyStates()
					local shortName = AI and (AI.GetShortRawName(rawName) .. ":" .. AI.GetShortGestureChar(selectedGesture)) or rawName
					UpdateStatus(
						"Assigned: " .. shortName .. " -> [" .. keyLabel .. "]",
						Color(100, 200, 255)
					)
					surface.PlaySound("buttons/button14.wav")
				end)
			end

			if not vrActive then
				ShowRawDropdown(buttonCode, keyLabel)
			end
		else
			-- === Action Assignment Mode (existing) ===
			if vrActive then
				UpdateStatus(
					"[" .. keyLabel .. "] selected  --  Press a VR controller button to assign. Right-click for action list.",
					Color(255, 200, 50)
				)
			else
				UpdateStatus(
					"[" .. keyLabel .. "] selected  --  VR not active. Choose from action list.",
					Color(255, 180, 50)
				)
			end

			if vrmod.InputEmu_StartCapture then
				pcall(vrmod.InputEmu_StartCapture, function(action)
					if not IsValid(editorFrame) then return end

					local fullLabel = GetActionFullLabel(action)
					vrmod.InputEmu_AssignKeyToAction(action, buttonCode)

					CancelCapture()
					RefreshKeyStates()
					UpdateStatus(
						"Assigned: " .. fullLabel .. " -> [" .. keyLabel .. "]",
						Color(100, 255, 100)
					)
					surface.PlaySound("buttons/button14.wav")
				end)
			end

			if not vrActive then
				ShowActionDropdown(buttonCode, keyLabel)
			end
		end
	end

	-- ===================================================================
	-- Create the frame
	-- ===================================================================
	local frame = vgui.Create("DFrame")
	frame:SetSize(frameW, frameH)
	frame:Center()
	frame:SetTitle(L("VR Key Assignment Editor", "VR Key Assignment Editor"))
	frame:MakePopup()
	frame:SetDeleteOnClose(true)
	frame:SetSizable(false)
	frame:SetDraggable(true)
	editorFrame = frame

	-- Custom frame background (colors cached at file scope)
	local CLR_FRAME_BG    = Color(30, 30, 35, 250)
	local CLR_FRAME_TITLE = Color(40, 40, 50, 250)
	local CLR_FRAME_TEXT  = Color(200, 200, 220)
	frame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, CLR_FRAME_BG)
		draw.RoundedBox(4, 0, 0, w, 25, CLR_FRAME_TITLE)
		draw.SimpleText(self:GetTitle(), "DermaDefaultBold", 8, 4, CLR_FRAME_TEXT)
	end

	-- ===================================================================
	-- Enable toggles (top bar below title)
	-- ===================================================================
	local topY = 30

	local cv_emu = GetConVar("vrmod_unoff_input_emu")
	local enableCheck = vgui.Create("DCheckBoxLabel", frame)
	enableCheck:SetPos(PAD, topY)
	enableCheck:SetSize(200, 18)
	enableCheck:SetText(L("Enable Input Emulation", "Enable Input Emulation"))
	enableCheck:SetTextColor(Color(200, 200, 200))
	enableCheck:SetConVar("vrmod_unoff_input_emu")

	local cv_cpp = GetConVar("vrmod_unoff_cpp_keyinject")
	local cppCheck = vgui.Create("DCheckBoxLabel", frame)
	cppCheck:SetPos(PAD + 220, topY)
	cppCheck:SetSize(200, 18)
	cppCheck:SetText(L("C++ Engine Injection", "C++ Engine Injection"))
	cppCheck:SetTextColor(Color(180, 180, 180))
	cppCheck:SetConVar("vrmod_unoff_cpp_keyinject")

	-- ===================================================================
	-- Build keyboard keys
	-- ===================================================================
	local kbStartY = topY + checkboxBarH + 4

	for rowIdx, row in ipairs(KEYBOARD_LAYOUT) do
		local x = PAD
		local y = kbStartY + (rowIdx - 1) * (KH + RG)

		for _, keyDef in ipairs(row) do
			local code  = keyDef[1]
			local label = keyDef[2]
			local wMult = keyDef[3]
			local keyW  = math.floor(wMult * KW)

			-- Gap spacer: advance x, no visual element
			if code == -1 then
				x = x + keyW + KG
				continue
			end

			-- Numpad anchor: jump to fixed numpad X position
			if code == -2 then
				x = numpadStartX
				continue
			end

			-- Create interactive key button
			local btn = vgui.Create("DButton", frame)
			btn:SetPos(x, y)
			btn:SetSize(keyW, KH)
			btn:SetText("")
			btn:SetCursor("hand")
			btn.buttonCode      = code
			btn.keyLabel         = label
			btn.isSelected       = false
			btn.assignedActions  = {}
			btn.assignedRawMappings = {}

			keyPanels[code] = btn

			-- Paint
			btn.Paint = PaintKeyButton

			-- Left click: enter/toggle capture mode
			btn.DoClick = function(self)
				if selectedCode == self.buttonCode then
					-- Click same key again → cancel
					CancelCapture()
					UpdateStatus("Click a key to assign a VR controller action.")
				else
					-- Cancel previous, select this one
					CancelCapture()
					self.isSelected = true
					selectedCode  = self.buttonCode
					selectedPanel = self
					StartCapture(self.buttonCode, self.keyLabel)
				end
			end

			-- Right click: context menu (remove/assign/clear)
			btn.DoRightClick = function(self)
				local hasActions = #self.assignedActions > 0
				local hasRaw = self.assignedRawMappings and #self.assignedRawMappings > 0
				if not hasActions and not hasRaw then
					-- No assignments → show dropdown to assign
					CancelCapture()
					self.isSelected = true
					selectedCode  = self.buttonCode
					selectedPanel = self
					if rawAssignMode then
						ShowRawDropdown(self.buttonCode, self.keyLabel)
					else
						ShowActionDropdown(self.buttonCode, self.keyLabel)
					end
					return
				end

				-- Build context menu
				local menu = DermaMenu()

				-- List each assigned action with "Remove" option
				for _, act in ipairs(self.assignedActions) do
					local fullLabel = GetActionFullLabel(act)
					menu:AddOption("Remove Action: " .. fullLabel, function()
						vrmod.InputEmu_RemoveAction(act)
						RefreshKeyStates()
						UpdateStatus("Removed: " .. fullLabel .. " from [" .. self.keyLabel .. "]")
					end)
				end

				-- List raw button assignments with "Remove" option
				if hasRaw then
					local AI = g_VR and g_VR.advancedInput
					for _, rm in ipairs(self.assignedRawMappings) do
						local displayName = AI and (AI.GetShortRawName(rm.raw) .. " [" .. AI.GetGestureDisplayName(rm.gesture) .. "]") or rm.raw
						menu:AddOption("Remove Raw: " .. displayName, function()
							if AI and AI.RemoveMapping then
								AI.RemoveMapping(rm.index)
								AI.Save()
							end
							RefreshKeyStates()
							UpdateStatus("Removed: " .. displayName .. " from [" .. self.keyLabel .. "]")
						end)
					end
				end

				-- "Clear All" if multiple actions
				if #self.assignedActions > 1 then
					menu:AddSpacer()
					menu:AddOption("Clear ALL from [" .. self.keyLabel .. "]", function()
						local copy = table.Copy(self.assignedActions)
						for _, act in ipairs(copy) do
							vrmod.InputEmu_RemoveAction(act)
						end
						RefreshKeyStates()
						UpdateStatus("Cleared all from [" .. self.keyLabel .. "]")
					end)
				end

				-- "Assign new" option
				menu:AddSpacer()
				menu:AddOption(L("Assign new action...", "Assign new action..."), function()
					CancelCapture()
					self.isSelected = true
					selectedCode  = self.buttonCode
					selectedPanel = self
					StartCapture(self.buttonCode, self.keyLabel)
				end)

				menu:Open()
			end

			-- Tooltip on hover
			btn.OnCursorEntered = function(self)
				if #self.assignedActions > 0 then
					local tip = "Assigned VR Actions:\n"
					for _, act in ipairs(self.assignedActions) do
						tip = tip .. "  - " .. GetActionFullLabel(act) .. "\n"
					end
					tip = tip .. "\nLeft-click: Assign new action"
					tip = tip .. "\nRight-click: Remove / Edit"
					self:SetTooltip(tip)
				else
					self:SetTooltip("Left-click: Assign VR action\nRight-click: Choose from list")
				end
			end

			x = x + keyW + KG
		end
	end

	-- ===================================================================
	-- Status area (below keyboard)
	-- ===================================================================
	local statusY = kbStartY + #KEYBOARD_LAYOUT * (KH + RG) + 4

	statusLabel = vgui.Create("DLabel", frame)
	statusLabel:SetPos(PAD, statusY)
	statusLabel:SetSize(frameW - PAD * 2, 20)
	statusLabel:SetFont("DermaDefaultBold")
	statusLabel:SetTextColor(Color(200, 200, 200))
	statusLabel:SetText(L("Click a key to assign a VR controller action.", "Click a key to assign a VR controller action."))

	-- System info line
	local infoLabel = vgui.Create("DLabel", frame)
	infoLabel:SetPos(PAD, statusY + 20)
	infoLabel:SetSize(frameW - PAD * 2, 16)
	infoLabel:SetFont("DermaDefault")

	local vrSt  = (g_VR and g_VR.active) and "VR Active" or "VR Inactive"
	local cppSt = (vrmod.InputEmu_IsCppAvailable and vrmod.InputEmu_IsCppAvailable())
		and "C++ ON" or "C++ OFF"
	local rawModV = (g_VR and g_VR.moduleSemiVersion and g_VR.moduleSemiVersion > 0) and g_VR.moduleSemiVersion or (g_VR and g_VR.moduleVersion)
	local modV  = rawModV and ("v" .. rawModV) or "N/A"
	infoLabel:SetTextColor(Color(130, 130, 140))
	infoLabel:SetText("VR: " .. vrSt .. " | C++ Inject: " .. cppSt .. " | Module: " .. modV)

	-- ===================================================================
	-- Bottom buttons
	-- ===================================================================
	local btnY  = statusY + 42
	local btnH  = 26
	local btnGap = 6

	-- "Clear All" — double-click to confirm (no Derma_Query, VR-safe)
	local clearBtn = vgui.Create("DButton", frame)
	clearBtn:SetPos(PAD, btnY)
	clearBtn:SetSize(100, btnH)
	clearBtn:SetText(L("Clear All", "Clear All"))
	clearBtn:SetTextColor(Color(255, 150, 150))
	clearBtn.confirmPending = false
	clearBtn.DoClick = function(self)
		if self.confirmPending then
			-- Second click: execute
			CancelCapture()
			vrmod.InputEmu_ClearAll()
			RefreshKeyStates()
			UpdateStatus(L("All key assignments cleared.", "All key assignments cleared."), Color(255, 180, 100))
			self.confirmPending = false
			self:SetText(L("Clear All", "Clear All"))
			self:SetTextColor(Color(255, 150, 150))
		else
			-- First click: enter confirm state
			self.confirmPending = true
			self:SetText(L("Sure? Click!", "Sure? Click!"))
			self:SetTextColor(Color(255, 80, 80))
			UpdateStatus(L("Click 'Sure? Click!' again to clear all, or click elsewhere to cancel.", "Click 'Sure? Click!' again to clear all, or click elsewhere to cancel."), Color(255, 180, 100))
			-- Auto-cancel after 3 seconds
			timer.Simple(3, function()
				if IsValid(self) and self.confirmPending then
					self.confirmPending = false
					self:SetText(L("Clear All", "Clear All"))
					self:SetTextColor(Color(255, 150, 150))
					UpdateStatus(L("Clear cancelled.", "Clear cancelled."), Color(200, 200, 200))
				end
			end)
		end
	end

	-- "Reset Defaults" — double-click to confirm (VR-safe)
	local resetBtn = vgui.Create("DButton", frame)
	resetBtn:SetPos(PAD + 100 + btnGap, btnY)
	resetBtn:SetSize(130, btnH)
	resetBtn:SetText(L("Reset Defaults", "Reset Defaults"))
	resetBtn.confirmPending = false
	resetBtn.DoClick = function(self)
		if self.confirmPending then
			-- Second click: execute
			CancelCapture()
			vrmod.InputEmu_ResetMapping()
			RefreshKeyStates()
			UpdateStatus(L("Key assignments reset to defaults.", "Key assignments reset to defaults."), Color(100, 200, 255))
			self.confirmPending = false
			self:SetText(L("Reset Defaults", "Reset Defaults"))
		else
			-- First click: enter confirm state
			self.confirmPending = true
			self:SetText(L("Sure? Click!", "Sure? Click!"))
			self:SetTextColor(Color(255, 200, 80))
			UpdateStatus(L("Click 'Sure? Click!' again to reset to defaults, or click elsewhere to cancel.", "Click 'Sure? Click!' again to reset to defaults, or click elsewhere to cancel."), Color(255, 200, 80))
			-- Auto-cancel after 3 seconds
			timer.Simple(3, function()
				if IsValid(self) and self.confirmPending then
					self.confirmPending = false
					self:SetText(L("Reset Defaults", "Reset Defaults"))
					self:SetTextColor(Color(255, 255, 255))
					UpdateStatus(L("Reset cancelled.", "Reset cancelled."), Color(200, 200, 200))
				end
			end)
		end
	end

	-- "Auto Assign" — detect keys from current keybinds, double-click to confirm
	local autoBtn = vgui.Create("DButton", frame)
	autoBtn:SetPos(PAD + 100 + btnGap + 130 + btnGap, btnY)
	autoBtn:SetSize(130, btnH)
	autoBtn:SetText(L("Auto Assign", "Auto Assign"))
	autoBtn:SetTextColor(Color(150, 200, 255))
	autoBtn.confirmPending = false
	autoBtn.DoClick = function(self)
		if self.confirmPending then
			-- Second click: execute
			CancelCapture()
			local count = vrmod.InputEmu_AutoAssign()
			RefreshKeyStates()
			UpdateStatus("Auto-assigned " .. count .. " actions from current keybinds.", Color(100, 200, 255))
			surface.PlaySound("buttons/button14.wav")
			self.confirmPending = false
			self:SetText(L("Auto Assign", "Auto Assign"))
			self:SetTextColor(Color(150, 200, 255))
		else
			-- First click: enter confirm state
			self.confirmPending = true
			self:SetText(L("Sure? Click!", "Sure? Click!"))
			self:SetTextColor(Color(100, 180, 255))
			UpdateStatus(L("Click 'Sure? Click!' again to auto-assign from current keybinds.", "Click 'Sure? Click!' again to auto-assign from current keybinds."), Color(150, 200, 255))
			-- Auto-cancel after 3 seconds
			timer.Simple(3, function()
				if IsValid(self) and self.confirmPending then
					self.confirmPending = false
					self:SetText(L("Auto Assign", "Auto Assign"))
					self:SetTextColor(Color(150, 200, 255))
					UpdateStatus(L("Auto assign cancelled.", "Auto assign cancelled."), Color(200, 200, 200))
				end
			end)
		end
	end

	-- Sub-mode toggle: [Action] / [Raw Button] + gesture selector
	local modeToggleX = PAD + 100 + btnGap + 130 + btnGap + 130 + btnGap
	local actionModeBtn = vgui.Create("DButton", frame)
	actionModeBtn:SetPos(modeToggleX, btnY)
	actionModeBtn:SetSize(60, btnH)
	actionModeBtn:SetText("Action")
	actionModeBtn:SetTextColor(Color(100, 255, 150))
	actionModeBtn.Paint = function(self, w, h)
		local bg = (not rawAssignMode) and Color(30, 80, 50, 220) or Color(40, 40, 50, 200)
		draw.RoundedBox(2, 0, 0, w, h, bg)
		local bd = (not rawAssignMode) and Color(50, 140, 60) or Color(70, 70, 80)
		surface.SetDrawColor(bd)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	actionModeBtn.DoClick = function()
		rawAssignMode = false
		CancelCapture()
		UpdateStatus(L("Click a key to assign a VR controller action.", "Click a key to assign a VR controller action."))
	end

	local rawModeBtn = vgui.Create("DButton", frame)
	rawModeBtn:SetPos(modeToggleX + 62, btnY)
	rawModeBtn:SetSize(70, btnH)
	rawModeBtn:SetText("Raw Btn")
	rawModeBtn:SetTextColor(Color(100, 180, 255))
	rawModeBtn.Paint = function(self, w, h)
		local bg = rawAssignMode and Color(20, 55, 85, 220) or Color(40, 40, 50, 200)
		draw.RoundedBox(2, 0, 0, w, h, bg)
		local bd = rawAssignMode and Color(50, 120, 180) or Color(70, 70, 80)
		surface.SetDrawColor(bd)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	rawModeBtn.DoClick = function()
		rawAssignMode = true
		CancelCapture()
		UpdateStatus(L("Click a key to assign a raw VR button.", "Click a key to assign a raw VR button."))
	end

	-- Gesture selector (next to raw mode button)
	local gestNames = { {"short_press", "S"}, {"long_press", "L"}, {"double_click", "D"}, {"combo", "C"} }
	local gestStartX = modeToggleX + 62 + 72
	for gi, gd in ipairs(gestNames) do
		local gBtn = vgui.Create("DButton", frame)
		gBtn:SetPos(gestStartX + (gi - 1) * 24, btnY)
		gBtn:SetSize(22, btnH)
		gBtn:SetText(gd[2])
		gBtn:SetFont("DermaDefaultBold")
		gBtn:SetTextColor(Color(200, 200, 210))
		gBtn:SetTooltip(gd[1]:gsub("_", " "))
		gBtn.Paint = function(self, w, h)
			if not rawAssignMode then self:SetAlpha(80) else self:SetAlpha(255) end
			local active = (selectedGesture == gd[1])
			local bg = active and Color(60, 120, 180, 220) or Color(40, 40, 50, 200)
			draw.RoundedBox(1, 0, 0, w, h, bg)
			surface.SetDrawColor(active and Color(50, 120, 180) or Color(70, 70, 80))
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		gBtn.DoClick = function()
			selectedGesture = gd[1]
		end
	end

	-- "Close"
	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetPos(frameW - PAD - 80, btnY)
	closeBtn:SetSize(80, btnH)
	closeBtn:SetText(L("Close", "Close"))
	closeBtn.DoClick = function()
		frame:Close()
	end

	-- ===================================================================
	-- Initial state: populate key assignments from current mapping
	-- ===================================================================
	RefreshKeyStates()

	-- ===================================================================
	-- Cleanup on close: cancel capture, clear singleton reference
	-- ===================================================================
	frame.OnClose = function()
		CancelCapture()
		editorFrame = nil
	end

	print(TAG .. "Editor opened")
end

-- ============================================================================
-- Console command registration
-- ============================================================================

concommand.Add("vrmod_input_emu_editor", OpenKeyboardEditor)

print(TAG .. "Visual Keyboard Editor loaded. Command: vrmod_input_emu_editor")
