if CLIENT then

local L = VRModL or function(_, fb) return fb or "" end

	-- Layout preference (0=Classic, 1=Full)
	local cv_layout = CreateClientConVar("vrmod_unoff_keyboard_layout", "0", true, false,
		"VR Keyboard layout: 0=Classic, 1=Full")

	-- ============================================================================
	-- Character -> BUTTON_CODE mapping (for classic key injection mode)
	-- ============================================================================

	local CHAR_TO_KEY = {
		["a"] = KEY_A, ["b"] = KEY_B, ["c"] = KEY_C, ["d"] = KEY_D,
		["e"] = KEY_E, ["f"] = KEY_F, ["g"] = KEY_G, ["h"] = KEY_H,
		["i"] = KEY_I, ["j"] = KEY_J, ["k"] = KEY_K, ["l"] = KEY_L,
		["m"] = KEY_M, ["n"] = KEY_N, ["o"] = KEY_O, ["p"] = KEY_P,
		["q"] = KEY_Q, ["r"] = KEY_R, ["s"] = KEY_S, ["t"] = KEY_T,
		["u"] = KEY_U, ["v"] = KEY_V, ["w"] = KEY_W, ["x"] = KEY_X,
		["y"] = KEY_Y, ["z"] = KEY_Z,
		["1"] = KEY_1, ["2"] = KEY_2, ["3"] = KEY_3, ["4"] = KEY_4,
		["5"] = KEY_5, ["6"] = KEY_6, ["7"] = KEY_7, ["8"] = KEY_8,
		["9"] = KEY_9, ["0"] = KEY_0,
		[" "] = KEY_SPACE, ["."] = KEY_PERIOD, [","] = KEY_COMMA,
	}
	for k, v in pairs(table.Copy(CHAR_TO_KEY)) do
		CHAR_TO_KEY[string.upper(k)] = v
	end

	-- ============================================================================
	-- Full keyboard sizing constants (for VR)
	-- ============================================================================

	local VR_KW  = 40   -- base key width
	local VR_KH  = 33   -- key height
	local VR_KG  = 2    -- gap between keys
	local VR_RG  = 3    -- gap between rows
	local VR_PAD = 6    -- panel padding

	-- ============================================================================
	-- Cached Color constants (avoid creating inside Paint functions)
	-- ============================================================================

	local CLR = {
		BLACK_128   = Color(0, 0, 0, 128),
		BLACK_160   = Color(0, 0, 0, 160),
		BLACK_200   = Color(0, 0, 0, 200),
		BLACK_255   = Color(0, 0, 0, 255),
		WHITE       = Color(255, 255, 255),
		WHITE_FULL  = Color(255, 255, 255, 255),
		GREEN_FLASH = Color(0, 255, 0),
		GRAY_128    = Color(128, 128, 128, 255),
		GRAY_HOVER  = Color(80, 80, 100, 200),
		LABEL_DIM   = Color(200, 200, 200),
		LABEL_CYAN  = Color(100, 200, 255),
		LABEL_GREEN = Color(100, 255, 150),
		LABEL_YELLOW = Color(200, 200, 150),
		TEXT_NORMAL  = Color(210, 210, 215),
		TEXT_ASSIGN  = Color(140, 220, 155, 210),
	}

	-- Input mode key backgrounds
	local CLR_INKEY = {
		BG         = Color(20, 20, 25, 220),
		BG_HOVER   = Color(60, 60, 70, 230),
		BG_HELD    = Color(30, 70, 50, 235),
		BORDER     = Color(80, 80, 90),
		BORDER_HOV = Color(130, 130, 160),
		BORDER_HELD = Color(60, 160, 80),
	}

	-- Assignment mode backgrounds
	local CLR_ASGN = {
		BG         = Color(42, 42, 48, 235),
		BG_HOVER   = Color(58, 58, 68, 240),
		YES_BG     = Color(25, 85, 35, 235),
		YES_HOVER  = Color(35, 110, 50, 240),
		BORDER     = Color(70, 70, 80),
		BORDER_HOV = Color(120, 120, 150),
		YES_BORDER = Color(50, 140, 60),
		YES_BRD_H  = Color(80, 180, 90),
		SEL_BORDER = Color(255, 220, 50),
		BTN_BG     = Color(80, 60, 20, 220),
		BTN_BORDER = Color(180, 150, 50, 255),
		BTN_TEXT   = Color(255, 200, 80),
	}

	-- Bottom bar button colors
	local CLR_BAR = {
		BG         = Color(50, 50, 50, 200),
		ACTIVE     = Color(30, 80, 130, 220),
		BORDER     = Color(100, 150, 200, 255),
		GREEN_BG   = Color(30, 80, 50, 220),
		GREEN_BD   = Color(60, 150, 80, 255),
		YELLOW_BG  = Color(60, 50, 30, 220),
		YELLOW_BD  = Color(150, 130, 60, 255),
		PAGE_BG    = Color(40, 40, 60, 220),
		PAGE_BD    = Color(90, 90, 140, 255),
		PAGE_ACT   = Color(60, 40, 80, 220),
		PAGE_ABD   = Color(140, 90, 180, 255),
	}

	-- Raw button assignment colors (cyan/blue family)
	local CLR_RAW = {
		YES_BG     = Color(20, 55, 85, 235),
		YES_HOVER  = Color(30, 75, 110, 240),
		YES_BORDER = Color(50, 120, 180),
		YES_BRD_H  = Color(70, 160, 220),
		TEXT       = Color(100, 180, 255, 210),
	}

	-- Status + Close button colors
	local CLR_UI = {
		STATUS_BG     = Color(20, 20, 30, 200),
		STATUS_BORDER = Color(60, 60, 80),
		STATUS_TEXT   = Color(180, 180, 200),
		STATUS_OK     = Color(100, 200, 120),
		STATUS_WARN   = Color(200, 150, 80),
		CLOSE_BG      = Color(100, 30, 30, 200),
		CLOSE_BG_HOVER = Color(180, 40, 40, 240),
		CLOSE_BORDER  = Color(200, 60, 60),
	}

	-- ============================================================================
	-- ACTION_SHORT table (short names for assignment mode key faces)
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

	-- ============================================================================
	-- Helper: inject a key with visual feedback on a DLabel/DButton
	-- ============================================================================

	local function InjectKeyWithFlash(buttonCode, keyPanel)
		if not buttonCode or buttonCode <= 0 then return end

		-- Dual-layer tap (0.1s hold)
		if vrmod and vrmod.InputEmu_TapKey then
			vrmod.InputEmu_TapKey(buttonCode)
		elseif vrmod and vrmod.InputEmu_SetKey then
			-- Fallback: Lua-only tap
			vrmod.InputEmu_SetKey(buttonCode, true)
			timer.Simple(0.1, function()
				if vrmod and vrmod.InputEmu_SetKey then
					vrmod.InputEmu_SetKey(buttonCode, nil)
				end
			end)
		end

		-- Visual feedback: flash green
		if IsValid(keyPanel) then
			keyPanel:SetTextColor(CLR.GREEN_FLASH)
			timer.Simple(0.15, function()
				if IsValid(keyPanel) then
					keyPanel:SetTextColor(CLR.WHITE)
				end
			end)
		end
	end

	-- ============================================================================
	-- Helper: inject Shift+key combo for Page 2 symbols
	-- ============================================================================

	local function InjectShiftCombo(baseCode, btn)
		if not vrmod or not vrmod.InputEmu_SetKeyDual then return end
		-- Hold shift (both Lua and C++ layers)
		vrmod.InputEmu_SetKeyDual(KEY_LSHIFT, true)
		-- Small delay, then tap the base key
		timer.Simple(0.03, function()
			if vrmod and vrmod.InputEmu_TapKey then
				vrmod.InputEmu_TapKey(baseCode)
			end
			-- Release shift after tap completes
			timer.Simple(0.12, function()
				if vrmod and vrmod.InputEmu_SetKeyDual then
					vrmod.InputEmu_SetKeyDual(KEY_LSHIFT, nil)
				end
			end)
		end)
		-- Visual feedback
		if IsValid(btn) then
			btn:SetTextColor(CLR.GREEN_FLASH)
			timer.Simple(0.15, function()
				if IsValid(btn) then btn:SetTextColor(CLR.WHITE) end
			end)
		end
	end

	-- ============================================================================
	-- Menu UIDs (separate UIDs = separate RenderTargets, avoids RT cache size mismatch)
	-- ============================================================================

	local UID_CLASSIC = "keyboard_classic"
	local UID_FULL    = "keyboard_full"

	-- ============================================================================
	-- Forward declare ToggleKeyboard (needed for layout switch callbacks)
	-- ============================================================================

	local ToggleKeyboard

	-- ============================================================================
	-- Auto-hide timer: close keyboard after 6 seconds of no VGUI cursor focus
	-- ============================================================================

	local KEYBOARD_AUTOHIDE_TIMER = "vrmod_keyboard_autohide"
	local keyboardNoFocusTime = 0

	local function StartKeyboardAutoHide(uid)
		keyboardNoFocusTime = 0
		timer.Create(KEYBOARD_AUTOHIDE_TIMER, 1, 0, function()
			if not VRUtilIsMenuOpen(uid) then
				timer.Remove(KEYBOARD_AUTOHIDE_TIMER)
				return
			end
			if g_VR.menuFocus then
				keyboardNoFocusTime = 0
			else
				keyboardNoFocusTime = keyboardNoFocusTime + 1
				if keyboardNoFocusTime >= 6 then
					--VRUtilMenuClose(uid)
					timer.Remove(KEYBOARD_AUTOHIDE_TIMER)
				end
			end
		end)
	end

	local function StopKeyboardAutoHide()
		timer.Remove(KEYBOARD_AUTOHIDE_TIMER)
		keyboardNoFocusTime = 0
	end

	-- ============================================================================
	-- Open Classic Keyboard (original compact layout)
	-- ============================================================================

	local function OpenClassicKeyboard()
		local injectMode = false

		local keyboardPanel = vgui.Create("DPanel")
		keyboardPanel:SetPos(0, 0)
		keyboardPanel:SetSize(555, 290)
		function keyboardPanel:Paint(w, h)
			surface.SetDrawColor(CLR.BLACK_128)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(CLR.BLACK_255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		-- Close button (top-right)
		local closeBtn = vgui.Create("DLabel", keyboardPanel)
		closeBtn:SetPos(555 - 32, 2)
		closeBtn:SetSize(28, 18)
		closeBtn:SetText("X")
		closeBtn:SetFont("DermaDefaultBold")
		closeBtn:SetTextColor(CLR.WHITE)
		closeBtn:SetContentAlignment(5)
		closeBtn:SetMouseInputEnabled(true)
		closeBtn:SetCursor("hand")
		closeBtn.Paint = function(self, w, h)
			local bg = self:IsHovered() and CLR_UI.CLOSE_BG_HOVER or CLR_UI.CLOSE_BG
			draw.RoundedBox(2, 0, 0, w, h, bg)
			surface.SetDrawColor(CLR_UI.CLOSE_BORDER)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		closeBtn.OnMousePressed = function()
			StopKeyboardAutoHide()
			VRUtilMenuClose(UID_CLASSIC)
		end

		local lowerCase = "1234567890\1\nqwertyuiop\nasdfghjkl\2\n\3zxcvbnm.\4\3\n "
		local upperCase = "!@%\"/+=?-_\1\nQWERTYUIOP\nASDFGHJKL\2\n\3ZXCVBNM,\4\3\n "
		local selectedCase = lowerCase
		local keys = {}

		-- Mode indicator label
		local modeLabel = vgui.Create("DLabel", keyboardPanel)
		modeLabel:SetPos(5, 260)
		modeLabel:SetSize(250, 25)
		modeLabel:SetFont("HudSelectionText")
		modeLabel:SetTextColor(CLR.LABEL_DIM)
		modeLabel:SetText(L("Mode: Text Input", "Mode: Text Input"))

		-- Mode toggle: Text / Inject
		local modeBtn = vgui.Create("DLabel", keyboardPanel)
		modeBtn:SetPos(260, 260)
		modeBtn:SetSize(120, 25)
		modeBtn:SetFont("HudSelectionText")
		modeBtn:SetTextColor(CLR.LABEL_CYAN)
		modeBtn:SetText(L("[Key Inject]", "[Key Inject]"))
		modeBtn:SetContentAlignment(5)
		modeBtn:SetMouseInputEnabled(true)
		modeBtn.Paint = function(self, w, h)
			surface.SetDrawColor(injectMode and CLR_BAR.ACTIVE or CLR_BAR.BG)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(CLR_BAR.BORDER)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		modeBtn.OnMousePressed = function()
			injectMode = not injectMode
			if injectMode then
				modeLabel:SetText(L("Mode: Key Inject", "Mode: Key Inject"))
				modeLabel:SetTextColor(CLR.LABEL_CYAN)
				modeBtn:SetText(L("[Text Input]", "[Text Input]"))
			else
				modeLabel:SetText(L("Mode: Text Input", "Mode: Text Input"))
				modeLabel:SetTextColor(CLR.LABEL_DIM)
				modeBtn:SetText(L("[Key Inject]", "[Key Inject]"))
			end
		end

		-- Layout switch: Classic -> Full (only if InputEmu API available)
		local fullAvailable = vrmod and vrmod.InputEmu_TapKey ~= nil
		if fullAvailable then
			local fullBtn = vgui.Create("DLabel", keyboardPanel)
			fullBtn:SetPos(385, 260)
			fullBtn:SetSize(165, 25)
			fullBtn:SetFont("HudSelectionText")
			fullBtn:SetTextColor(CLR.LABEL_GREEN)
			fullBtn:SetText(L("[Full Keyboard >>]", "[Full Keyboard >>]"))
			fullBtn:SetContentAlignment(5)
			fullBtn:SetMouseInputEnabled(true)
			fullBtn.Paint = function(self, w, h)
				surface.SetDrawColor(CLR_BAR.GREEN_BG)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(CLR_BAR.GREEN_BD)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			fullBtn.OnMousePressed = function()
				RunConsoleCommand("vrmod_unoff_keyboard_layout", "1")
				VRUtilMenuClose(UID_CLASSIC)
				timer.Simple(0.05, function()
					if ToggleKeyboard then ToggleKeyboard() end
				end)
			end
		end

		local function updateKeyboard()
			for i = 1, #selectedCase do
				if selectedCase[i] == "\n" then continue end
				keys[i]:SetText(selectedCase[i] == "\1" and "Back" or selectedCase[i] == "\2" and "Enter" or selectedCase[i] == "\4" and "Shift" or selectedCase[i] == "\3" and " " or selectedCase[i])
			end
		end

		local x, y = 5, 5
		for i = 1, #selectedCase do
			if selectedCase[i] == "\n" then
				y = y + 50
				x = (y == 205) and 127 or (y == 155) and 5 or 5 + ((y - 5) / 50 * 15)
				continue
			end

			keys[i] = vgui.Create("DLabel", keyboardPanel)
			local key = keys[i]
			key:SetPos(x, y)
			key:SetSize(selectedCase[i] == " " and 250 or selectedCase[i] == "\2" and 65 or selectedCase[i] == "\4" and 50 or 45, 45)
			key:SetTextColor(CLR.WHITE_FULL)
			key:SetFont((selectedCase[i] == "\1" or selectedCase[i] == "\2" or selectedCase[i] == "\3" or selectedCase[i] == "\4") and "HudSelectionText" or "vrmod_Verdana37")
			key:SetText(selectedCase[i] == "\1" and "Back" or selectedCase[i] == "\2" and "Enter" or selectedCase[i] == "\4" and "Shift" or selectedCase[i])
			key:SetMouseInputEnabled(true)
			key:SetContentAlignment(5)
			key.OnMousePressed = function()
				if injectMode then
					-- === Key Injection Mode ===
					local txt = key:GetText()
					if txt == "Shift" then
						selectedCase = (selectedCase == lowerCase) and upperCase or lowerCase
						updateKeyboard()
						return
					end
					local buttonCode
					if txt == "Back" then
						buttonCode = KEY_BACKSPACE
					elseif txt == "Enter" then
						buttonCode = KEY_ENTER
					elseif txt == " " then
						buttonCode = KEY_SPACE
					else
						buttonCode = CHAR_TO_KEY[txt]
					end
					InjectKeyWithFlash(buttonCode, key)
				else
					-- === Original Text Input Mode ===
					if key:GetText() == "Back" then
						local activeTextEntry = vgui.GetKeyboardFocus()
						if IsValid(activeTextEntry) then
							local text = activeTextEntry:GetText()
							local start, endt = activeTextEntry:GetSelectedTextRange()
							if start ~= endt then
								activeTextEntry:SetText(string.sub(text, 1, start) .. string.sub(text, endt + 1))
								activeTextEntry:SetCaretPos(start)
							else
								activeTextEntry:SetText(string.sub(text, 1, #text - 1))
							end
						end
					elseif key:GetText() == "Enter" then
						-- no-op in text mode
					elseif key:GetText() == "Shift" then
						selectedCase = (selectedCase == lowerCase) and upperCase or lowerCase
						updateKeyboard()
					else
						local activeTextEntry = vgui.GetKeyboardFocus()
						if IsValid(activeTextEntry) then
							local text = activeTextEntry:GetText()
							local start, endt = activeTextEntry:GetSelectedTextRange()
							if start ~= endt then
								activeTextEntry:SetText(string.sub(text, 1, start) .. key:GetText() .. string.sub(text, endt + 1))
								activeTextEntry:SetCaretPos(start + 1)
							else
								activeTextEntry:SetText(text .. key:GetText())
							end
						end
					end
				end
			end

			function key:Paint(w, h)
				local hovered = self:IsHovered()
				surface.SetDrawColor(hovered and CLR.GRAY_HOVER or CLR.BLACK_200)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(CLR.GRAY_128)
				surface.DrawOutlinedRect(0, 0, w, h)
			end

			x = x + (selectedCase[i] == "\4" and 55 or 50)
		end

		VRUtilMenuOpen(
			UID_CLASSIC,
			605,
			290,
			keyboardPanel,
			1,
			Vector(8, 6, 5.5),
			Angle(0, -90, 10),
			0.03,
			true,
			function()
				StopKeyboardAutoHide()
				keyboardPanel:Remove()
				keyboardPanel = nil
			end
		)
		StartKeyboardAutoHide(UID_CLASSIC)
	end

	-- ============================================================================
	-- Open Full Keyboard (unified layout, multi-mode)
	-- ============================================================================

	local function OpenFullKeyboard()
		-- Safety: fallback to classic if API not available
		if not vrmod or not vrmod.InputEmu_TapKey then
			print("[VR Keyboard] InputEmu API not available, falling back to Classic layout")
			RunConsoleCommand("vrmod_unoff_keyboard_layout", "0")
			OpenClassicKeyboard()
			return
		end

		local layout = vrmod.UNIFIED_KEYBOARD_LAYOUT
		if not layout then
			print("[VR Keyboard] UNIFIED_KEYBOARD_LAYOUT not found, falling back to Classic layout")
			RunConsoleCommand("vrmod_unoff_keyboard_layout", "0")
			OpenClassicKeyboard()
			return
		end

		-- Calculate dimensions from unified layout
		local basePanelW, basePanelH, numpadX = vrmod.CalcKeyboardDimensions(VR_KW, VR_KH, VR_KG, VR_RG, VR_PAD)

		-- Extra height for status bar + mode buttons bar
		local STATUS_BAR_H = 20
		local MODE_BAR_H   = 28
		local EXTRA_H      = STATUS_BAR_H + MODE_BAR_H + VR_RG * 2 + VR_PAD
		local fullPanelW = basePanelW
		local fullPanelH = basePanelH + EXTRA_H

		-- ====================================================================
		-- Mode state
		-- ====================================================================
		-- Modes: 1 = Key Inject, 2 = Text Input, 3 = Assignment
		local MODE_INJECT = 1
		local MODE_TEXT   = 2
		local MODE_ASSIGN = 3

		local hasCpp = vrmod.InputEmu_IsCppAvailable and pcall(vrmod.InputEmu_IsCppAvailable) and vrmod.InputEmu_IsCppAvailable()
		local KS = {
			currentMode = hasCpp and MODE_INJECT or MODE_TEXT,
			page = 1,             -- 1 = normal keys, 2 = shift/symbols
			selectedCode = nil,
			selectedPanel = nil,
			keyPanels = {},       -- code -> panel mapping
			rawAssignMode = false,       -- false=action, true=raw button
			selectedGesture = "short_press",
			heldKeyCode = nil,
			heldKeyBtn = nil,
		}

		local function CancelCapture()
			if IsValid(KS.selectedPanel) then KS.selectedPanel.isSelected = false end
			KS.selectedCode = nil
			KS.selectedPanel = nil
			if vrmod.InputEmu_CancelCapture then pcall(vrmod.InputEmu_CancelCapture) end
			if vrmod.InputEmu_CancelRawCapture then pcall(vrmod.InputEmu_CancelRawCapture) end
		end

		local function RefreshAssignments()
			local ok, reverseMap = pcall(vrmod.InputEmu_GetReverseMap)
			if not ok then reverseMap = {} end
			-- Also get raw button assignments from advanced input
			local rawReverseMap = {}
			local AI = g_VR.luaKeybinding
			if AI and AI.GetKeyReverseMap then
				local rok, rrm = pcall(AI.GetKeyReverseMap)
				if rok then rawReverseMap = rrm end
			end
			for code, btn in pairs(KS.keyPanels) do
				if IsValid(btn) then
					btn.assignedActions = reverseMap[code] or {}
					btn.assignedRawMappings = rawReverseMap[code] or {}
				end
			end
		end

		-- ====================================================================
		-- Key hold state (Inject mode Page 1: hold while VR trigger pressed)
		-- ====================================================================
		local function ReleaseHeldKey()
			if not KS.heldKeyCode then return end
			if vrmod and vrmod.InputEmu_SetKeyDual then
				pcall(vrmod.InputEmu_SetKeyDual, KS.heldKeyCode, nil)
			end
			if IsValid(KS.heldKeyBtn) then
				KS.heldKeyBtn.isHeld = false
			end
			KS.heldKeyCode = nil
			KS.heldKeyBtn = nil
		end

		-- VRMod_Exit failsafe: release held key on VR exit/death/disconnect
		local HOLD_CLEANUP_HOOK = "vrmod_keyboard_hold_cleanup"
		hook.Add("VRMod_Exit", HOLD_CLEANUP_HOOK, function()
			ReleaseHeldKey()
		end)

		-- ====================================================================
		-- Main panel
		-- ====================================================================
		local panel = vgui.Create("DPanel")
		panel:SetPos(0, 0)
		panel:SetSize(fullPanelW, fullPanelH)
		panel.Paint = function(self, w, h)
			surface.SetDrawColor(CLR.BLACK_160)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(CLR.BLACK_255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		-- Close button (top-right)
		local closeBtn = vgui.Create("DPanel", panel)
		closeBtn:SetPos(fullPanelW - VR_PAD - 30, 2)
		closeBtn:SetSize(28, 18)
		closeBtn:SetMouseInputEnabled(true)
		closeBtn:SetCursor("hand")
		closeBtn.Paint = function(self, w, h)
			local bg = self:IsHovered() and CLR_UI.CLOSE_BG_HOVER or CLR_UI.CLOSE_BG
			draw.RoundedBox(2, 0, 0, w, h, bg)
			surface.SetDrawColor(CLR_UI.CLOSE_BORDER)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText("X", "DermaDefaultBold", w / 2, h / 2, CLR.WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		closeBtn.OnMousePressed = function()
			CancelCapture()
			StopKeyboardAutoHide()
			VRUtilMenuClose(UID_FULL)
		end

		-- Forward-declare UI elements that need updating
		local statusLabel, statusInfoLabel, modeLabel
		local pageBtnRef, modeBtnInputRef, modeBtnAssignRef
		local statusBarPanel

		-- ====================================================================
		-- Update functions (called on mode/page change)
		-- ====================================================================
		local function GetKeyLabel(keyDef)
			local label = keyDef[2]
			local shiftLabel = keyDef[4]
			if KS.page == 2 and shiftLabel then
				return shiftLabel
			end
			return label
		end

		local function UpdateAllKeyLabels()
			for code, btn in pairs(KS.keyPanels) do
				if IsValid(btn) and btn.keyDef then
					btn.keyLabel = GetKeyLabel(btn.keyDef)
				end
			end
		end

		local function UpdateModeUI()
			ReleaseHeldKey()  -- Failsafe: release on mode switch
			if IsValid(modeLabel) then
				if KS.currentMode == MODE_INJECT then
					modeLabel:SetText(L("Mode: Key Inject", "Mode: Key Inject"))
					modeLabel:SetTextColor(CLR.LABEL_CYAN)
				elseif KS.currentMode == MODE_TEXT then
					modeLabel:SetText(L("Mode: Text Input", "Mode: Text Input"))
					modeLabel:SetTextColor(CLR.LABEL_DIM)
				elseif KS.currentMode == MODE_ASSIGN then
					modeLabel:SetText(L("Mode: Assignment", "Mode: Assignment"))
					modeLabel:SetTextColor(CLR_ASGN.BTN_TEXT)
				end
			end

			-- Page button: visible only in input modes
			if IsValid(pageBtnRef) then
				pageBtnRef:SetVisible(KS.currentMode ~= MODE_ASSIGN)
			end

			-- Status bar: visible only in assignment mode
			if IsValid(statusBarPanel) then
				statusBarPanel:SetVisible(KS.currentMode == MODE_ASSIGN)
			end

			-- Mode button highlighting
			if IsValid(modeBtnInputRef) then
				modeBtnInputRef.isActive = (KS.currentMode == MODE_INJECT or KS.currentMode == MODE_TEXT)
			end
			if IsValid(modeBtnAssignRef) then
				modeBtnAssignRef.isActive = (KS.currentMode == MODE_ASSIGN)
			end

			-- When entering assignment mode, refresh assignments and reset page
			if KS.currentMode == MODE_ASSIGN then
				KS.page = 1
				UpdateAllKeyLabels()
				RefreshAssignments()
			end
		end

		local function UpdatePageUI()
			if IsValid(pageBtnRef) then
				if KS.page == 1 then
					pageBtnRef:SetText(L("[Page 1: Keys]", "[Page 1: Keys]"))
				else
					pageBtnRef:SetText(L("[Page 2: Symbols]", "[Page 2: Symbols]"))
				end
			end
			UpdateAllKeyLabels()
		end

		-- ====================================================================
		-- Key paint functions
		-- ====================================================================
		local function PaintKeyInputMode(self, w, h)
			local isHeld = self.isHeld
			local isHovered = self:IsHovered()
			local bg = isHeld and CLR_INKEY.BG_HELD or (isHovered and CLR_INKEY.BG_HOVER or CLR_INKEY.BG)
			draw.RoundedBox(3, 0, 0, w, h, bg)
			local border = isHeld and CLR_INKEY.BORDER_HELD or (isHovered and CLR_INKEY.BORDER_HOV or CLR_INKEY.BORDER)
			surface.SetDrawColor(border)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			-- Label (centered)
			local textClr = isHeld and CLR.LABEL_GREEN or CLR.TEXT_NORMAL
			draw.SimpleText(self.keyLabel or "", "DermaDefaultBold", w / 2, h / 2, textClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local function PaintKeyAssignMode(self, w, h)
			local isAssigned = self.assignedActions and #self.assignedActions > 0
			local isRawAssigned = self.assignedRawMappings and #self.assignedRawMappings > 0
			local hasAny = isAssigned or isRawAssigned
			local isHovered = self:IsHovered()
			local isSel = self.isSelected

			local bg
			if isSel then
				local pulse = math.sin(CurTime() * 5) * 0.3 + 0.7
				bg = Color(math.floor(200 * pulse), math.floor(160 * pulse), 0, 235)
			elseif isAssigned and isRawAssigned then
				bg = isHovered and CLR_ASGN.YES_HOVER or CLR_ASGN.YES_BG
			elseif isRawAssigned then
				bg = isHovered and CLR_RAW.YES_HOVER or CLR_RAW.YES_BG
			elseif isAssigned then
				bg = isHovered and CLR_ASGN.YES_HOVER or CLR_ASGN.YES_BG
			else
				bg = isHovered and CLR_ASGN.BG_HOVER or CLR_ASGN.BG
			end
			draw.RoundedBox(3, 0, 0, w, h, bg)

			local border
			if isSel then
				border = CLR_ASGN.SEL_BORDER
			elseif isRawAssigned and isAssigned then
				-- Both: green bg + cyan border
				border = isHovered and CLR_RAW.YES_BRD_H or CLR_RAW.YES_BORDER
			elseif isRawAssigned then
				border = isHovered and CLR_RAW.YES_BRD_H or CLR_RAW.YES_BORDER
			elseif isAssigned then
				border = isHovered and CLR_ASGN.YES_BRD_H or CLR_ASGN.YES_BORDER
			else
				border = isHovered and CLR_ASGN.BORDER_HOV or CLR_ASGN.BORDER
			end
			surface.SetDrawColor(border)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			-- Key label position: shift up if we have assigned text below
			local labelY = hasAny and (h * 0.22) or (h * 0.5)
			draw.SimpleText(self.keyLabel or "", "DermaDefaultBold", w / 2, labelY, CLR.TEXT_NORMAL, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- Assigned action names (green)
			if isAssigned and not isSel then
				local txt = ""
				for i, act in ipairs(self.assignedActions) do
					if i > 1 then txt = txt .. " " end
					txt = txt .. (ACTION_SHORT[act] or "?")
				end
				local maxChars = math.max(3, math.floor(w / 6))
				if #txt > maxChars then txt = string.sub(txt, 1, maxChars - 1) .. ".." end
				local actionY = isRawAssigned and (h * 0.52) or (h * 0.65)
				draw.SimpleText(txt, "DermaDefault", w / 2, actionY, CLR.TEXT_ASSIGN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			-- Raw button assignments (cyan)
			if isRawAssigned and not isSel then
				local AI = g_VR.luaKeybinding
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
				if #txt > maxChars then txt = string.sub(txt, 1, maxChars - 1) .. ".." end
				draw.SimpleText(txt, "DermaDefault", w / 2, h * 0.80, CLR_RAW.TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		-- ====================================================================
		-- Key click handler
		-- ====================================================================
		local function OnKeyClicked(btn, code, keyDef)
			if code <= 0 then return end

			if KS.currentMode == MODE_INJECT then
				-- Key Inject mode
				if KS.page == 1 then
					-- Hold mode: press and hold until OnMouseReleased
					ReleaseHeldKey()  -- Release previous key first
					if vrmod and vrmod.InputEmu_SetKeyDual then
						pcall(vrmod.InputEmu_SetKeyDual, code, true)
					end
					KS.heldKeyCode = code
					KS.heldKeyBtn = btn
					btn.isHeld = true
				else
					-- Page 2: symbol key handling
					local shiftLabel = keyDef[4]
					if shiftLabel then
						-- PostMessage cannot simulate Shift+Key for text input
						-- (OS keyboard state unchanged → TranslateMessage ignores Shift)
						-- Hybrid fix: direct insertion for text entries + best-effort injection
						local activeTE = vgui.GetKeyboardFocus()
						if IsValid(activeTE) then
							activeTE:SetText(activeTE:GetText() .. shiftLabel)
						end
						InjectShiftCombo(code, btn)
					else
						-- Keys without shiftLabel (F1-F12, arrows, modifiers, mouse, numpad): inject normally
						InjectKeyWithFlash(code, btn)
					end
				end

			elseif KS.currentMode == MODE_TEXT then
				-- Text Input mode
				local activeTE = vgui.GetKeyboardFocus()
				if KS.page == 1 then
					-- Page 1: insert label character
					local label = keyDef[2]
					if code == KEY_BACKSPACE then
						if IsValid(activeTE) then
							local text = activeTE:GetText()
							local start, endt = activeTE:GetSelectedTextRange()
							if start ~= endt then
								activeTE:SetText(string.sub(text, 1, start) .. string.sub(text, endt + 1))
								activeTE:SetCaretPos(start)
							else
								activeTE:SetText(string.sub(text, 1, #text - 1))
							end
						end
					elseif code == KEY_ENTER then
						-- no-op for text input
					elseif code == KEY_SPACE then
						if IsValid(activeTE) then
							activeTE:SetText(activeTE:GetText() .. " ")
						end
					elseif code == KEY_TAB then
						if IsValid(activeTE) then
							activeTE:SetText(activeTE:GetText() .. "\t")
						end
					else
						-- Insert the label character (letters, numbers, symbols)
						if IsValid(activeTE) and label and #label == 1 then
							activeTE:SetText(activeTE:GetText() .. label)
						end
					end
				else
					-- Page 2: insert shiftLabel character
					local shiftLabel = keyDef[4]
					if shiftLabel and IsValid(activeTE) then
						activeTE:SetText(activeTE:GetText() .. shiftLabel)
					elseif not shiftLabel then
						-- No shiftLabel, fall back to page 1 behavior
						local label = keyDef[2]
						if code == KEY_BACKSPACE then
							if IsValid(activeTE) then
								local text = activeTE:GetText()
								local start, endt = activeTE:GetSelectedTextRange()
								if start ~= endt then
									activeTE:SetText(string.sub(text, 1, start) .. string.sub(text, endt + 1))
									activeTE:SetCaretPos(start)
								else
									activeTE:SetText(string.sub(text, 1, #text - 1))
								end
							end
						elseif code == KEY_ENTER then
							-- no-op for text input (same as Page 1)
						elseif code == KEY_SPACE then
							if IsValid(activeTE) then
								activeTE:SetText(activeTE:GetText() .. " ")
							end
						elseif code == KEY_TAB then
							if IsValid(activeTE) then
								activeTE:SetText(activeTE:GetText() .. "\t")
							end
						elseif IsValid(activeTE) and label and #label == 1 then
							activeTE:SetText(activeTE:GetText() .. label)
						end
					end
				end
				-- Visual feedback
				if IsValid(btn) then
					btn:SetTextColor(CLR.GREEN_FLASH)
					timer.Simple(0.15, function()
						if IsValid(btn) then btn:SetTextColor(CLR.WHITE) end
					end)
				end

			elseif KS.currentMode == MODE_ASSIGN then
				-- Assignment mode: click to select, then capture VR input
				if KS.selectedCode == code and IsValid(KS.selectedPanel) then
					-- Clicking same key again: cancel capture
					CancelCapture()
					if IsValid(statusLabel) then
						statusLabel:SetText(L("Capture cancelled. Click a key to assign.", "Capture cancelled. Click a key to assign."))
					end
					return
				end

				-- Deselect previous
				if IsValid(KS.selectedPanel) then KS.selectedPanel.isSelected = false end

				-- Select this key
				KS.selectedCode = code
				KS.selectedPanel = btn
				btn.isSelected = true

				if KS.rawAssignMode then
					-- === Raw Button Assignment Mode ===
					if IsValid(statusLabel) then
						local AI = g_VR.luaKeybinding
						local gestName = AI and AI.GetGestureDisplayName(KS.selectedGesture) or KS.selectedGesture
						statusLabel:SetText(string.format(L("Press a VR button to assign [%s] to [%s]...", "Press a VR button to assign [%s] to [%s]..."), gestName, btn.keyLabel or "?"))
					end

					if vrmod.InputEmu_StartRawCapture then
						pcall(vrmod.InputEmu_StartRawCapture, function(rawName)
							if not rawName then
								if IsValid(btn) then btn.isSelected = false end
								KS.selectedCode = nil
								KS.selectedPanel = nil
								if IsValid(statusLabel) then
									statusLabel:SetText(L("Capture cancelled. Click a key to assign.", "Capture cancelled. Click a key to assign."))
								end
								return
							end

							local AI = g_VR.luaKeybinding
							if AI and AI.AddMapping then
								AI.AddMapping(rawName, KS.selectedGesture, "key", code, {})
								AI.Save()
							end

							if IsValid(btn) then btn.isSelected = false end
							KS.selectedCode = nil
							KS.selectedPanel = nil
							RefreshAssignments()

							local shortName = AI and (AI.GetShortRawName(rawName) .. ":" .. AI.GetShortGestureChar(KS.selectedGesture)) or rawName
							if IsValid(statusLabel) then
								statusLabel:SetText(string.format(L("Assigned [%s] to [%s]. Click another key or switch mode.", "Assigned [%s] to [%s]. Click another key or switch mode."), shortName, btn.keyLabel or "?"))
							end
						end)
					end
				else
					-- === Action Assignment Mode (existing) ===
					if IsValid(statusLabel) then
						statusLabel:SetText(string.format(L("Press a VR controller button to assign to [%s]...", "Press a VR controller button to assign to [%s]..."), btn.keyLabel or "?"))
					end

					if vrmod.InputEmu_StartCapture then
						pcall(vrmod.InputEmu_StartCapture, function(action)
							if not action then
								if IsValid(btn) then btn.isSelected = false end
								KS.selectedCode = nil
								KS.selectedPanel = nil
								if IsValid(statusLabel) then
									statusLabel:SetText(L("Capture cancelled. Click a key to assign.", "Capture cancelled. Click a key to assign."))
								end
								return
							end

							if vrmod.InputEmu_AssignKeyToAction then
								pcall(vrmod.InputEmu_AssignKeyToAction, action, code)
							end

							if IsValid(btn) then btn.isSelected = false end
							KS.selectedCode = nil
							KS.selectedPanel = nil
							RefreshAssignments()

							local shortName = ACTION_SHORT[action] or action
							if IsValid(statusLabel) then
								statusLabel:SetText(string.format(L("Assigned [%s] to [%s]. Click another key or switch mode.", "Assigned [%s] to [%s]. Click another key or switch mode."), shortName, btn.keyLabel or "?"))
							end
						end)
					end
				end
			end
		end

		-- ====================================================================
		-- Key double-click handler (assignment mode: remove/reassign context menu)
		-- ====================================================================
		local function OnKeyDoubleClicked(btn, code)
			if KS.currentMode ~= MODE_ASSIGN then return end
			local hasActions = btn.assignedActions and #btn.assignedActions > 0
			local hasRaw = btn.assignedRawMappings and #btn.assignedRawMappings > 0
			if not hasActions and not hasRaw then return end

			local menu = DermaMenu()

			-- Action-based assignments (green)
			if hasActions then
				for _, act in ipairs(btn.assignedActions) do
					local shortName = ACTION_SHORT[act] or act
					menu:AddOption(L("Remove Action:", "Remove Action:") .. " " .. shortName, function()
						if vrmod.InputEmu_RemoveAction then
							pcall(vrmod.InputEmu_RemoveAction, act)
						end
						RefreshAssignments()
						if IsValid(statusLabel) then
							statusLabel:SetText(string.format(L("Removed [%s] from [%s].", "Removed [%s] from [%s]."), shortName, btn.keyLabel or "?"))
						end
					end)
				end
			end

			-- Raw button assignments (cyan)
			if hasRaw then
				local AI = g_VR.luaKeybinding
				for _, rm in ipairs(btn.assignedRawMappings) do
					local displayName = AI and (AI.GetShortRawName(rm.raw) .. " [" .. AI.GetGestureDisplayName(rm.gesture) .. "]") or rm.raw
					menu:AddOption(L("Remove Raw:", "Remove Raw:") .. " " .. displayName, function()
						if AI and AI.RemoveMapping then
							AI.RemoveMapping(rm)
							AI.Save()
						end
						RefreshAssignments()
						if IsValid(statusLabel) then
							statusLabel:SetText(string.format(L("Removed [%s] from [%s].", "Removed [%s] from [%s]."), displayName, btn.keyLabel or "?"))
						end
					end)
				end
			end

			menu:AddSpacer()
			menu:AddOption(L("Reassign (new capture)", "Reassign (new capture)"), function()
				OnKeyClicked(btn, code, btn.keyDef)
			end)
			menu:Open()
		end

		-- ====================================================================
		-- Build keyboard keys from unified layout
		-- ====================================================================
		local kbStartY = VR_PAD

		for rowIdx, row in ipairs(layout) do
			local x = VR_PAD
			local y = kbStartY + (rowIdx - 1) * (VR_KH + VR_RG)

			for _, keyDef in ipairs(row) do
				local code  = keyDef[1]
				local label = keyDef[2]
				local wMult = keyDef[3]
				local keyW  = math.floor(wMult * VR_KW)

				if code == -1 then
					-- Gap spacer
					x = x + keyW + VR_KG
					continue
				end

				if code == -2 then
					-- Numpad anchor: jump to fixed X position
					x = numpadX
					continue
				end

				local btn = vgui.Create("DPanel", panel)
				btn:SetPos(x, y)
				btn:SetSize(keyW, VR_KH)
				btn:SetMouseInputEnabled(true)
				btn:SetCursor("hand")

				-- Store metadata on the button
				btn.keyDef = keyDef
				btn.keyLabel = GetKeyLabel(keyDef)
				btn.assignedActions = {}
				btn.assignedRawMappings = {}
				btn.isSelected = false
				btn.ACTION_SHORT = ACTION_SHORT
				btn.lastClickTime = 0

				-- Dynamic paint based on current mode
				btn.Paint = function(self, w, h)
					if KS.currentMode == MODE_ASSIGN then
						PaintKeyAssignMode(self, w, h)
					else
						PaintKeyInputMode(self, w, h)
					end
				end

				-- Click handling
				btn.OnMousePressed = function(self, mouseCode)
					if mouseCode == MOUSE_LEFT then
						local now = CurTime()
						local timeSinceLast = now - self.lastClickTime
						self.lastClickTime = now
						if timeSinceLast < 0.4 and KS.currentMode == MODE_ASSIGN then
							-- Double-click in assignment mode
							OnKeyDoubleClicked(self, code)
						else
							OnKeyClicked(self, code, keyDef)
						end
					elseif mouseCode == MOUSE_RIGHT then
						-- Right-click: context menu in assignment mode
						if KS.currentMode == MODE_ASSIGN then
							OnKeyDoubleClicked(self, code)
						end
					end
				end

				-- Release held key on mouse up (Inject Page 1 hold mode)
				btn.OnMouseReleased = function(self, mouseCode)
					if mouseCode == MOUSE_LEFT then
						ReleaseHeldKey()
					end
				end

				-- Track key panels by code
				KS.keyPanels[code] = btn

				x = x + keyW + VR_KG
			end
		end

		-- ====================================================================
		-- Bottom area: status bar + mode buttons
		-- ====================================================================
		local kbBottomY = kbStartY + #layout * (VR_KH + VR_RG)

		-- Status bar (only visible in assignment mode)
		statusBarPanel = vgui.Create("DPanel", panel)
		statusBarPanel:SetPos(VR_PAD, kbBottomY)
		statusBarPanel:SetSize(fullPanelW - VR_PAD * 2, STATUS_BAR_H)
		statusBarPanel:SetVisible(KS.currentMode == MODE_ASSIGN)
		statusBarPanel.Paint = function(self, w, h)
			draw.RoundedBox(2, 0, 0, w, h, CLR_UI.STATUS_BG)
			surface.SetDrawColor(CLR_UI.STATUS_BORDER)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		statusLabel = vgui.Create("DLabel", statusBarPanel)
		statusLabel:SetPos(4, 0)
		statusLabel:SetSize(fullPanelW * 0.42, STATUS_BAR_H)
		statusLabel:SetFont("DermaDefault")
		statusLabel:SetTextColor(CLR_UI.STATUS_TEXT)
		statusLabel:SetText(L("Click a key to assign a VR controller action.", "Click a key to assign a VR controller action."))

		-- Sub-mode toggle: [Action] [Raw Button] + gesture selector (inside status bar)
		local subModeX = fullPanelW * 0.42 + 4
		local subBtnW = 52
		local subBtnH = STATUS_BAR_H - 4

		local btnActionMode = vgui.Create("DPanel", statusBarPanel)
		btnActionMode:SetPos(subModeX, 2)
		btnActionMode:SetSize(subBtnW, subBtnH)
		btnActionMode:SetMouseInputEnabled(true)
		btnActionMode:SetCursor("hand")
		btnActionMode.Paint = function(self, w, h)
			local bg = (not KS.rawAssignMode) and Color(30, 80, 50, 220) or Color(40, 40, 50, 200)
			draw.RoundedBox(2, 0, 0, w, h, bg)
			local bd = (not KS.rawAssignMode) and CLR_ASGN.YES_BORDER or CLR_UI.STATUS_BORDER
			surface.SetDrawColor(bd)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText("Action", "DermaDefault", w / 2, h / 2, CLR.TEXT_NORMAL, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btnActionMode.OnMousePressed = function()
			KS.rawAssignMode = false
			CancelCapture()
			statusLabel:SetText(L("Click a key to assign a VR controller action.", "Click a key to assign a VR controller action."))
		end

		local btnRawMode = vgui.Create("DPanel", statusBarPanel)
		btnRawMode:SetPos(subModeX + subBtnW + 2, 2)
		btnRawMode:SetSize(subBtnW + 10, subBtnH)
		btnRawMode:SetMouseInputEnabled(true)
		btnRawMode:SetCursor("hand")
		btnRawMode.Paint = function(self, w, h)
			local bg = KS.rawAssignMode and Color(20, 55, 85, 220) or Color(40, 40, 50, 200)
			draw.RoundedBox(2, 0, 0, w, h, bg)
			local bd = KS.rawAssignMode and CLR_RAW.YES_BORDER or CLR_UI.STATUS_BORDER
			surface.SetDrawColor(bd)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText("Raw Btn", "DermaDefault", w / 2, h / 2, CLR_RAW.TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btnRawMode.OnMousePressed = function()
			KS.rawAssignMode = true
			CancelCapture()
			statusLabel:SetText(L("Click a key to assign a raw VR button.", "Click a key to assign a raw VR button."))
		end

		-- Gesture selector buttons (visible only in raw mode)
		local gestureNames = { {"short_press", "S"}, {"long_press", "L"}, {"double_click", "D"}, {"combo", "C"} }
		local gestX = subModeX + (subBtnW + 2) * 2 + 14
		local gestBtns = {}
		for gi, gd in ipairs(gestureNames) do
			local gBtn = vgui.Create("DPanel", statusBarPanel)
			gBtn:SetPos(gestX + (gi - 1) * 22, 2)
			gBtn:SetSize(20, subBtnH)
			gBtn:SetMouseInputEnabled(true)
			gBtn:SetCursor("hand")
			gBtn.Paint = function(self, w, h)
				if not KS.rawAssignMode then
					self:SetAlpha(60)
				else
					self:SetAlpha(255)
				end
				local active = (KS.selectedGesture == gd[1])
				local bg = active and Color(60, 120, 180, 220) or Color(40, 40, 50, 200)
				draw.RoundedBox(1, 0, 0, w, h, bg)
				surface.SetDrawColor(active and CLR_RAW.YES_BORDER or CLR_UI.STATUS_BORDER)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				draw.SimpleText(gd[2], "DermaDefaultBold", w / 2, h / 2, CLR.TEXT_NORMAL, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			gBtn.OnMousePressed = function()
				KS.selectedGesture = gd[1]
			end
			gBtn:SetTooltip(gd[1]:gsub("_", " "))
			gestBtns[gi] = gBtn
		end

		-- System info (right side of status bar)
		statusInfoLabel = vgui.Create("DLabel", statusBarPanel)
		statusInfoLabel:SetPos(fullPanelW * 0.82, 0)
		statusInfoLabel:SetSize(fullPanelW * 0.18 - VR_PAD * 2, STATUS_BAR_H)
		statusInfoLabel:SetFont("DermaDefault")
		statusInfoLabel:SetContentAlignment(6)  -- right-aligned
		do
			local vrActive = g_VR and g_VR.active
			local cppOk = hasCpp
			local modVer = g_VR and g_VR.moduleVersion or 0
			local infoText = (vrActive and "VR:ON" or "VR:OFF") .. " | " .. (cppOk and "C++:OK" or "C++:NO") .. " | v" .. tostring(modVer)
			statusInfoLabel:SetTextColor(cppOk and CLR_UI.STATUS_OK or CLR_UI.STATUS_WARN)
			statusInfoLabel:SetText(infoText)
		end

		-- Mode buttons bar
		local modeBarY = kbBottomY + STATUS_BAR_H + VR_RG

		-- Mode label (left)
		modeLabel = vgui.Create("DLabel", panel)
		modeLabel:SetPos(VR_PAD, modeBarY)
		modeLabel:SetSize(140, MODE_BAR_H)
		modeLabel:SetFont("DermaDefaultBold")
		modeLabel:SetContentAlignment(4)  -- left-center

		-- Input mode toggle button
		local modeBtnInput = vgui.Create("DPanel", panel)
		modeBtnInput:SetPos(VR_PAD + 145, modeBarY)
		modeBtnInput:SetSize(70, MODE_BAR_H)
		modeBtnInput:SetMouseInputEnabled(true)
		modeBtnInput:SetCursor("hand")
		modeBtnInput.isActive = (KS.currentMode == MODE_INJECT or KS.currentMode == MODE_TEXT)
		modeBtnInput.Paint = function(self, w, h)
			local bg = self.isActive and CLR_BAR.ACTIVE or CLR_BAR.BG
			draw.RoundedBox(2, 0, 0, w, h, bg)
			surface.SetDrawColor(CLR_BAR.BORDER)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			local label = (KS.currentMode == MODE_INJECT) and L("[Inject]", "[Inject]") or L("[Input]", "[Input]")
			draw.SimpleText(label, "DermaDefaultBold", w / 2, h / 2, CLR.LABEL_CYAN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		modeBtnInput.OnMousePressed = function()
			CancelCapture()
			if KS.currentMode == MODE_ASSIGN then
				KS.currentMode = hasCpp and MODE_INJECT or MODE_TEXT
			else
				-- Toggle between inject and text
				if KS.currentMode == MODE_INJECT then
					KS.currentMode = MODE_TEXT
				else
					KS.currentMode = MODE_INJECT
				end
			end
			UpdateModeUI()
		end
		modeBtnInputRef = modeBtnInput

		-- Assignment mode button
		local modeBtnAssign = vgui.Create("DPanel", panel)
		modeBtnAssign:SetPos(VR_PAD + 220, modeBarY)
		modeBtnAssign:SetSize(70, MODE_BAR_H)
		modeBtnAssign:SetMouseInputEnabled(true)
		modeBtnAssign:SetCursor("hand")
		modeBtnAssign.isActive = (KS.currentMode == MODE_ASSIGN)
		modeBtnAssign.Paint = function(self, w, h)
			local bg = self.isActive and CLR_ASGN.BTN_BG or CLR_BAR.BG
			draw.RoundedBox(2, 0, 0, w, h, bg)
			surface.SetDrawColor(self.isActive and CLR_ASGN.BTN_BORDER or CLR_BAR.BORDER)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(L("[Assign]", "[Assign]"), "DermaDefaultBold", w / 2, h / 2, CLR_ASGN.BTN_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		modeBtnAssign.OnMousePressed = function()
			if KS.currentMode == MODE_ASSIGN then
				CancelCapture()
				KS.currentMode = hasCpp and MODE_INJECT or MODE_TEXT
			else
				KS.currentMode = MODE_ASSIGN
			end
			UpdateModeUI()
		end
		modeBtnAssignRef = modeBtnAssign

		-- Page toggle button (center)
		local pageBtn = vgui.Create("DPanel", panel)
		pageBtn:SetPos(VR_PAD + 300, modeBarY)
		pageBtn:SetSize(120, MODE_BAR_H)
		pageBtn:SetMouseInputEnabled(true)
		pageBtn:SetCursor("hand")
		pageBtn:SetVisible(KS.currentMode ~= MODE_ASSIGN)
		pageBtn.Paint = function(self, w, h)
			local isPage2 = (KS.page == 2)
			local bg = isPage2 and CLR_BAR.PAGE_ACT or CLR_BAR.PAGE_BG
			draw.RoundedBox(2, 0, 0, w, h, bg)
			surface.SetDrawColor(isPage2 and CLR_BAR.PAGE_ABD or CLR_BAR.PAGE_BD)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			local txt = isPage2 and L("[Page 2: Symbols]", "[Page 2: Symbols]") or L("[Page 1: Keys]", "[Page 1: Keys]")
			draw.SimpleText(txt, "DermaDefaultBold", w / 2, h / 2, CLR.WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		pageBtn.OnMousePressed = function()
			ReleaseHeldKey()  -- Failsafe: release on page switch
			if KS.page == 1 then
				KS.page = 2
			else
				KS.page = 1
			end
			UpdatePageUI()
		end
		pageBtnRef = pageBtn

		-- Classic switch button (right)
		local classicBtn = vgui.Create("DPanel", panel)
		classicBtn:SetPos(fullPanelW - VR_PAD - 120, modeBarY)
		classicBtn:SetSize(120, MODE_BAR_H)
		classicBtn:SetMouseInputEnabled(true)
		classicBtn:SetCursor("hand")
		classicBtn.Paint = function(self, w, h)
			draw.RoundedBox(2, 0, 0, w, h, CLR_BAR.YELLOW_BG)
			surface.SetDrawColor(CLR_BAR.YELLOW_BD)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(L("[<< Classic]", "[<< Classic]"), "DermaDefaultBold", w / 2, h / 2, CLR.LABEL_YELLOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		classicBtn.OnMousePressed = function()
			CancelCapture()
			RunConsoleCommand("vrmod_unoff_keyboard_layout", "0")
			VRUtilMenuClose(UID_FULL)
			timer.Simple(0.05, function()
				if ToggleKeyboard then ToggleKeyboard() end
			end)
		end

		-- Initialize mode UI
		UpdateModeUI()
		UpdatePageUI()

		-- ====================================================================
		-- Open VR menu
		-- ====================================================================
		VRUtilMenuOpen(
			UID_FULL,
			fullPanelW + 10,
			fullPanelH,
			panel,
			1,
			Vector(8, 6, 5.5),
			Angle(0, -90, 10),
			0.025,
			true,
			function()
				ReleaseHeldKey()
				CancelCapture()
				StopKeyboardAutoHide()
				hook.Remove("VRMod_Exit", HOLD_CLEANUP_HOOK)
				KS.keyPanels = {}
				panel:Remove()
				panel = nil
			end
		)
		StartKeyboardAutoHide(UID_FULL)
	end

	-- ============================================================================
	-- Keyboard toggle (dispatch based on layout preference)
	-- ============================================================================

	ToggleKeyboard = function()
		-- Close whichever layout is currently open
		if VRUtilIsMenuOpen(UID_CLASSIC) then
			StopKeyboardAutoHide()
			VRUtilMenuClose(UID_CLASSIC)
			return
		end
		if VRUtilIsMenuOpen(UID_FULL) then
			StopKeyboardAutoHide()
			VRUtilMenuClose(UID_FULL)
			return
		end

		local useFull = cv_layout:GetInt() == 1
		local fullAvailable = vrmod and vrmod.InputEmu_TapKey ~= nil

		if useFull and fullAvailable then
			OpenFullKeyboard()
		else
			OpenClassicKeyboard()
		end
	end

	concommand.Add("vrmod_keyboard", ToggleKeyboard)
end
