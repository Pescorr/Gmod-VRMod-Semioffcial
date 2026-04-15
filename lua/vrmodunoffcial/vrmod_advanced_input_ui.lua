if SERVER then return end

local L = VRModL or function(_, fb) return fb or "" end

--[[
	vrmod_advanced_input_ui.lua
	Configuration UI for Advanced VR Input Processor

	Opens via: vrmod_advanced_input_menu
	Provides a rule-based configuration panel for gesture-to-target mappings.
]]

g_VR = g_VR or {}

local TAG = "[VRMod AdvInput UI] "

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local GESTURE_SHORT  = "short_press"
local GESTURE_LONG   = "long_press"
local GESTURE_DOUBLE = "double_click"
local GESTURE_COMBO  = "combo"

local GESTURE_CHOICES = {
	{ GESTURE_SHORT,  "Short Press" },
	{ GESTURE_LONG,   "Long Press" },
	{ GESTURE_DOUBLE, "Double Click" },
	{ GESTURE_COMBO,  "Combo" },
}

local CONTEXT_CHOICES = {
	{ "both",    "Both" },
	{ "on_foot", "On Foot" },
	{ "driving", "Driving" },
}

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

local function GetAI()
	return g_VR.advancedInput
end

-- Build a list of keyboard key choices from InputEmu
local function GetKeyChoices()
	local keys = {}
	if vrmod and vrmod.InputEmu_GetAssignableKeys then
		local ok, list = pcall(vrmod.InputEmu_GetAssignableKeys)
		if ok and list then
			for _, entry in ipairs(list) do
				table.insert(keys, { entry.code, entry.name or ("KEY " .. entry.code) })
			end
		end
	end

	-- Fallback: add common keys manually if InputEmu not available
	if #keys == 0 then
		local common = {
			{KEY_A, "A"}, {KEY_B, "B"}, {KEY_C, "C"}, {KEY_D, "D"}, {KEY_E, "E"},
			{KEY_F, "F"}, {KEY_G, "G"}, {KEY_H, "H"}, {KEY_I, "I"}, {KEY_J, "J"},
			{KEY_K, "K"}, {KEY_L, "L"}, {KEY_M, "M"}, {KEY_N, "N"}, {KEY_O, "O"},
			{KEY_P, "P"}, {KEY_Q, "Q"}, {KEY_R, "R"}, {KEY_S, "S"}, {KEY_T, "T"},
			{KEY_U, "U"}, {KEY_V, "V"}, {KEY_W, "W"}, {KEY_X, "X"}, {KEY_Y, "Y"},
			{KEY_Z, "Z"},
			{KEY_0, "0"}, {KEY_1, "1"}, {KEY_2, "2"}, {KEY_3, "3"}, {KEY_4, "4"},
			{KEY_5, "5"}, {KEY_6, "6"}, {KEY_7, "7"}, {KEY_8, "8"}, {KEY_9, "9"},
			{KEY_F1, "F1"}, {KEY_F2, "F2"}, {KEY_F3, "F3"}, {KEY_F4, "F4"},
			{KEY_F5, "F5"}, {KEY_F6, "F6"}, {KEY_F7, "F7"}, {KEY_F8, "F8"},
			{KEY_F9, "F9"}, {KEY_F10, "F10"}, {KEY_F11, "F11"}, {KEY_F12, "F12"},
			{KEY_SPACE, "Space"}, {KEY_ENTER, "Enter"}, {KEY_TAB, "Tab"},
			{KEY_ESCAPE, "Escape"}, {KEY_BACKSPACE, "Backspace"},
			{KEY_LSHIFT, "LShift"}, {KEY_RSHIFT, "RShift"},
			{KEY_LCONTROL, "LCtrl"}, {KEY_RCONTROL, "RCtrl"},
			{KEY_LALT, "LAlt"}, {KEY_RALT, "RAlt"},
			{KEY_UP, "Up"}, {KEY_DOWN, "Down"}, {KEY_LEFT, "Left"}, {KEY_RIGHT, "Right"},
			{KEY_INSERT, "Insert"}, {KEY_DELETE, "Delete"},
			{KEY_HOME, "Home"}, {KEY_END, "End"},
			{KEY_PAGEUP, "PageUp"}, {KEY_PAGEDOWN, "PageDn"},
			{MOUSE_LEFT, "Mouse1"}, {MOUSE_RIGHT, "Mouse2"}, {MOUSE_MIDDLE, "Mouse3"},
			{MOUSE_4, "Mouse4"}, {MOUSE_5, "Mouse5"},
		}
		keys = common
	end

	return keys
end

local function GetKeyName(code)
	if vrmod and vrmod.InputEmu_GetKeyDisplayName then
		local ok, name = pcall(vrmod.InputEmu_GetKeyDisplayName, code)
		if ok and name then return name end
	end
	return "KEY " .. tostring(code)
end

-------------------------------------------------------------------------------
-- ADD RULE POPUP
-------------------------------------------------------------------------------

local function OpenAddRulePopup(onAdded)
	local AI = GetAI()
	if not AI then return end

	local popup = vgui.Create("DFrame")
	popup:SetSize(420, 340)
	popup:Center()
	popup:SetTitle(L("Add Mapping Rule", "Add Mapping Rule"))
	popup:MakePopup()
	popup:SetDeleteOnClose(true)

	local y = 32

	-- Source button
	local lblSrc = vgui.Create("DLabel", popup)
	lblSrc:SetPos(10, y)
	lblSrc:SetText(L("Source Button:", "Source Button:"))
	lblSrc:SizeToContents()

	local cmbSrc = vgui.Create("DComboBox", popup)
	cmbSrc:SetPos(140, y - 2)
	cmbSrc:SetSize(260, 22)
	for _, name in ipairs(AI.GetAvailableRawBooleans()) do
		cmbSrc:AddChoice(AI.GetRawDisplayName(name), name)
	end
	cmbSrc:ChooseOptionID(1)
	y = y + 32

	-- Gesture type
	local lblGest = vgui.Create("DLabel", popup)
	lblGest:SetPos(10, y)
	lblGest:SetText(L("Gesture:", "Gesture:"))
	lblGest:SizeToContents()

	local cmbGest = vgui.Create("DComboBox", popup)
	cmbGest:SetPos(140, y - 2)
	cmbGest:SetSize(260, 22)
	for _, g in ipairs(GESTURE_CHOICES) do
		cmbGest:AddChoice(L(g[2], g[2]), g[1])
	end
	cmbGest:ChooseOptionID(1)
	y = y + 32

	-- Target type
	local lblTT = vgui.Create("DLabel", popup)
	lblTT:SetPos(10, y)
	lblTT:SetText(L("Target Type:", "Target Type:"))
	lblTT:SizeToContents()

	local cmbTT = vgui.Create("DComboBox", popup)
	cmbTT:SetPos(140, y - 2)
	cmbTT:SetSize(260, 22)
	cmbTT:AddChoice(L("Logical Action", "Logical Action"), "logical")
	cmbTT:AddChoice(L("Keyboard Key", "Keyboard Key"), "key")
	cmbTT:ChooseOptionID(1)
	y = y + 32

	-- Target value (logical action)
	local lblTarget = vgui.Create("DLabel", popup)
	lblTarget:SetPos(10, y)
	lblTarget:SetText(L("Target:", "Target:"))
	lblTarget:SizeToContents()

	local cmbLogical = vgui.Create("DComboBox", popup)
	cmbLogical:SetPos(140, y - 2)
	cmbLogical:SetSize(260, 22)
	for _, name in ipairs(AI.GetAvailableLogicalActions()) do
		cmbLogical:AddChoice(name, name)
	end
	cmbLogical:ChooseOptionID(1)

	-- Target value (keyboard key)
	local cmbKey = vgui.Create("DComboBox", popup)
	cmbKey:SetPos(140, y - 2)
	cmbKey:SetSize(260, 22)
	cmbKey:SetVisible(false)
	for _, k in ipairs(GetKeyChoices()) do
		cmbKey:AddChoice(k[2], k[1])
	end
	cmbKey:ChooseOptionID(1)
	y = y + 32

	-- Switch target combo visibility based on target type
	cmbTT.OnSelect = function(self, index, value, data)
		cmbLogical:SetVisible(data == "logical")
		cmbKey:SetVisible(data == "key")
	end

	-- Long press ms (shown only for long_press)
	local lblLong = vgui.Create("DLabel", popup)
	lblLong:SetPos(10, y)
	lblLong:SetText(L("Long Press (ms):", "Long Press (ms):"))
	lblLong:SizeToContents()
	lblLong:SetVisible(false)

	local numLong = vgui.Create("DNumberWang", popup)
	numLong:SetPos(140, y - 2)
	numLong:SetSize(100, 22)
	numLong:SetMin(200)
	numLong:SetMax(3000)
	numLong:SetValue(500)
	numLong:SetVisible(false)

	-- Double click ms (shown only for double_click)
	local lblDbl = vgui.Create("DLabel", popup)
	lblDbl:SetPos(250, y)
	lblDbl:SetText(L("Double Click (ms):", "Double Click (ms):"))
	lblDbl:SizeToContents()
	lblDbl:SetVisible(false)

	local numDbl = vgui.Create("DNumberWang", popup)
	numDbl:SetPos(380, y - 2)
	numDbl:SetSize(100, 22) -- will be repositioned
	numDbl:SetMin(100)
	numDbl:SetMax(1000)
	numDbl:SetValue(300)
	numDbl:SetVisible(false)

	-- Combo partner (shown only for combo)
	local lblPartner = vgui.Create("DLabel", popup)
	lblPartner:SetPos(10, y)
	lblPartner:SetText(L("Hold Button:", "Hold Button:"))
	lblPartner:SizeToContents()
	lblPartner:SetVisible(false)

	local cmbPartner = vgui.Create("DComboBox", popup)
	cmbPartner:SetPos(140, y - 2)
	cmbPartner:SetSize(260, 22)
	cmbPartner:SetVisible(false)
	for _, name in ipairs(AI.GetAvailableRawBooleans()) do
		cmbPartner:AddChoice(AI.GetRawDisplayName(name), name)
	end
	cmbPartner:ChooseOptionID(1)

	-- Show/hide gesture-specific fields
	cmbGest.OnSelect = function(self, index, value, data)
		lblLong:SetVisible(data == GESTURE_LONG)
		numLong:SetVisible(data == GESTURE_LONG)
		lblDbl:SetVisible(data == GESTURE_DOUBLE)
		numDbl:SetVisible(data == GESTURE_DOUBLE)
		lblPartner:SetVisible(data == GESTURE_COMBO)
		cmbPartner:SetVisible(data == GESTURE_COMBO)
	end
	y = y + 32

	-- Context
	local lblCtx = vgui.Create("DLabel", popup)
	lblCtx:SetPos(10, y)
	lblCtx:SetText(L("Context:", "Context:"))
	lblCtx:SizeToContents()

	local cmbCtx = vgui.Create("DComboBox", popup)
	cmbCtx:SetPos(140, y - 2)
	cmbCtx:SetSize(260, 22)
	for _, c in ipairs(CONTEXT_CHOICES) do
		cmbCtx:AddChoice(L(c[2], c[2]), c[1])
	end
	cmbCtx:ChooseOptionID(1)
	y = y + 40

	-- Add button
	local btnAdd = vgui.Create("DButton", popup)
	btnAdd:SetPos(140, y)
	btnAdd:SetSize(140, 30)
	btnAdd:SetText(L("Add Rule", "Add Rule"))
	btnAdd.DoClick = function()
		local _, rawName = cmbSrc:GetSelected()
		local _, gesture = cmbGest:GetSelected()
		local _, targetType = cmbTT:GetSelected()
		local target
		if targetType == "key" then
			_, target = cmbKey:GetSelected()
			target = tonumber(target)
		else
			_, target = cmbLogical:GetSelected()
		end
		local _, context = cmbCtx:GetSelected()

		if not rawName or not target then return end

		local opts = {
			long_press_ms = numLong:GetValue(),
			double_click_ms = numDbl:GetValue(),
			context = context or "both",
		}

		if gesture == GESTURE_COMBO then
			local _, partner = cmbPartner:GetSelected()
			opts.combo_partner = partner
		end

		AI.AddMapping(rawName, gesture, targetType, target, opts)
		popup:Close()

		if onAdded then onAdded() end
	end

	local btnCancel = vgui.Create("DButton", popup)
	btnCancel:SetPos(290, y)
	btnCancel:SetSize(100, 30)
	btnCancel:SetText(L("Cancel", "Cancel"))
	btnCancel.DoClick = function()
		popup:Close()
	end
end

-------------------------------------------------------------------------------
-- MAIN CONFIG PANEL
-------------------------------------------------------------------------------

local activeFrame = nil

concommand.Add("vrmod_advanced_input_menu", function()
	local AI = GetAI()
	if not AI then
		print(TAG .. "Advanced Input module not loaded")
		return
	end

	if IsValid(activeFrame) then activeFrame:Remove() end

	local frame = vgui.Create("DFrame")
	frame:SetSize(780, 560)
	frame:Center()
	frame:SetTitle(L("Advanced Input Configuration", "Advanced Input Configuration"))
	frame:MakePopup()
	frame:SetDeleteOnClose(true)
	activeFrame = frame

	-- === Top bar: toggles ===
	local topBar = vgui.Create("DPanel", frame)
	topBar:Dock(TOP)
	topBar:SetTall(36)
	topBar:DockMargin(0, 0, 0, 4)
	topBar:SetPaintBackground(false)

	local chkEnabled = vgui.Create("DCheckBoxLabel", topBar)
	chkEnabled:SetPos(8, 8)
	chkEnabled:SetText(L("Enable Advanced Input", "Enable Advanced Input"))
	chkEnabled:SetConVar("vrmod_unoff_advanced_input")
	chkEnabled:SizeToContents()

	local chkSteamVR = vgui.Create("DCheckBoxLabel", topBar)
	chkSteamVR:SetPos(250, 8)
	chkSteamVR:SetText(L("Disable SteamVR Default Input", "Disable SteamVR Default Input"))
	chkSteamVR:SetConVar("vrmod_unoff_disable_steamvr_input")
	chkSteamVR:SizeToContents()

	local btnAddRule = vgui.Create("DButton", topBar)
	btnAddRule:SetPos(frame:GetWide() - 130, 6)
	btnAddRule:SetSize(110, 24)
	btnAddRule:SetText(L("+ Add Rule", "+ Add Rule"))

	-- === Rule list area ===
	local listPanel = vgui.Create("DPanel", frame)
	listPanel:Dock(FILL)
	listPanel:DockMargin(0, 0, 0, 4)

	-- Header
	local headerPanel = vgui.Create("DPanel", listPanel)
	headerPanel:Dock(TOP)
	headerPanel:SetTall(24)
	headerPanel.Paint = function(self, w, h)
		surface.SetDrawColor(40, 40, 50, 200)
		surface.DrawRect(0, 0, w, h)
	end

	local headers = {
		{ 8,   130, L("Source Button", "Source Button") },
		{ 140, 100, L("Gesture", "Gesture") },
		{ 242, 50,  L("Type", "Type") },
		{ 294, 170, L("Target", "Target") },
		{ 466, 80,  L("Params", "Params") },
		{ 548, 70,  L("Context", "Context") },
	}
	for _, h in ipairs(headers) do
		local lbl = vgui.Create("DLabel", headerPanel)
		lbl:SetPos(h[1], 4)
		lbl:SetWide(h[2])
		lbl:SetText(h[3])
		lbl:SetFont("DermaDefaultBold")
	end

	-- Scrollable rule list
	local scroll = vgui.Create("DScrollPanel", listPanel)
	scroll:Dock(FILL)

	-- Function to rebuild the rule list
	local function RebuildList()
		scroll:Clear()

		local mappings = AI.GetMappings()
		if #mappings == 0 then
			local emptyLabel = vgui.Create("DLabel", scroll)
			emptyLabel:Dock(TOP)
			emptyLabel:SetTall(40)
			emptyLabel:SetContentAlignment(5)
			emptyLabel:SetText(L("No mapping rules configured. Click '+ Add Rule' to begin.",
				"No mapping rules configured. Click '+ Add Rule' to begin."))
			emptyLabel:SetTextColor(Color(160, 160, 170))
			return
		end

		for i, m in ipairs(mappings) do
			local row = vgui.Create("DPanel", scroll)
			row:Dock(TOP)
			row:SetTall(26)
			row:DockMargin(0, 0, 0, 1)
			local rowIdx = i
			row.Paint = function(self, w, h)
				local bg = (rowIdx % 2 == 0) and Color(35, 35, 45, 180) or Color(28, 28, 38, 180)
				surface.SetDrawColor(bg)
				surface.DrawRect(0, 0, w, h)
			end

			-- Source button name
			local lblSrc = vgui.Create("DLabel", row)
			lblSrc:SetPos(8, 4)
			lblSrc:SetWide(130)
			lblSrc:SetText(AI.GetRawDisplayName(m.raw))

			-- Gesture
			local lblGest = vgui.Create("DLabel", row)
			lblGest:SetPos(140, 4)
			lblGest:SetWide(100)
			lblGest:SetText(AI.GetGestureDisplayName(m.gesture))

			-- Target type
			local lblTT = vgui.Create("DLabel", row)
			lblTT:SetPos(242, 4)
			lblTT:SetWide(50)
			lblTT:SetText(m.target_type == "key" and "Key" or "Action")
			lblTT:SetTextColor(m.target_type == "key" and Color(100, 200, 255) or Color(200, 255, 100))

			-- Target value
			local lblTarget = vgui.Create("DLabel", row)
			lblTarget:SetPos(294, 4)
			lblTarget:SetWide(170)
			if m.target_type == "key" then
				lblTarget:SetText(GetKeyName(tonumber(m.target) or 0))
			else
				lblTarget:SetText(tostring(m.target))
			end

			-- Params
			local paramStr = ""
			if m.gesture == GESTURE_LONG then
				paramStr = tostring(m.long_press_ms or 500) .. "ms"
			elseif m.gesture == GESTURE_DOUBLE then
				paramStr = tostring(m.double_click_ms or 300) .. "ms"
			elseif m.gesture == GESTURE_COMBO and m.combo_partner then
				paramStr = "+" .. AI.GetRawDisplayName(m.combo_partner)
			end
			local lblParam = vgui.Create("DLabel", row)
			lblParam:SetPos(466, 4)
			lblParam:SetWide(80)
			lblParam:SetText(paramStr)
			lblParam:SetTextColor(Color(180, 180, 200))

			-- Context
			local lblCtx = vgui.Create("DLabel", row)
			lblCtx:SetPos(548, 4)
			lblCtx:SetWide(70)
			local ctxDisplay = { on_foot = "On Foot", driving = "Driving", both = "Both" }
			lblCtx:SetText(ctxDisplay[m.context or "both"] or m.context or "Both")
			lblCtx:SetTextColor(Color(160, 160, 180))

			-- Delete button
			local btnDel = vgui.Create("DButton", row)
			btnDel:SetPos(row:GetWide() - 36, 2)
			btnDel:SetSize(22, 22)
			btnDel:SetText("X")
			btnDel:SetTextColor(Color(255, 80, 80))
			btnDel.Paint = function(self, w, h)
				local bg = self:IsHovered() and Color(120, 30, 30, 200) or Color(60, 20, 20, 150)
				draw.RoundedBox(2, 0, 0, w, h, bg)
			end
			btnDel.DoClick = function()
				AI.RemoveMapping(rowIdx)
				RebuildList()
			end

			-- Fix delete button position after layout
			row.PerformLayout = function(self, w, h)
				btnDel:SetPos(w - 36, 2)
			end
		end
	end

	RebuildList()

	-- Add Rule button callback
	btnAddRule.DoClick = function()
		OpenAddRulePopup(function()
			RebuildList()
		end)
	end

	-- === Bottom bar ===
	local bottomBar = vgui.Create("DPanel", frame)
	bottomBar:Dock(BOTTOM)
	bottomBar:SetTall(40)
	bottomBar:DockMargin(0, 4, 0, 0)
	bottomBar:SetPaintBackground(false)

	local btnSave = vgui.Create("DButton", bottomBar)
	btnSave:SetPos(8, 8)
	btnSave:SetSize(100, 28)
	btnSave:SetText(L("Save", "Save"))
	btnSave.DoClick = function()
		AI.Save()
		-- Brief visual feedback
		btnSave:SetText(L("Saved!", "Saved!"))
		timer.Simple(1, function()
			if IsValid(btnSave) then btnSave:SetText(L("Save", "Save")) end
		end)
	end

	local btnReset = vgui.Create("DButton", bottomBar)
	btnReset:SetPos(120, 8)
	btnReset:SetSize(140, 28)
	btnReset:SetText(L("Clear All Rules", "Clear All Rules"))
	btnReset.DoClick = function()
		Derma_Query(
			L("Clear all advanced input rules?", "Clear all advanced input rules?"),
			L("Confirm", "Confirm"),
			L("Yes", "Yes"), function()
				AI.ClearMappings()
				RebuildList()
			end,
			L("No", "No"), function() end
		)
	end

	local btnImport = vgui.Create("DButton", bottomBar)
	btnImport:SetPos(272, 8)
	btnImport:SetSize(220, 28)
	btnImport:SetText(L("Import from Lua Keybinding", "Import from Lua Keybinding"))
	btnImport.DoClick = function()
		local count = AI.ImportFromLuaKeybinding()
		RebuildList()
		Derma_Message(
			string.format(L("Imported %d rules from Lua Keybinding.", "Imported %d rules from Lua Keybinding."), count),
			L("Import Complete", "Import Complete"),
			L("OK", "OK")
		)
	end

	local btnDiag = vgui.Create("DButton", bottomBar)
	btnDiag:SetPos(504, 8)
	btnDiag:SetSize(100, 28)
	btnDiag:SetText(L("Diagnostics", "Diagnostics"))
	btnDiag.DoClick = function()
		RunConsoleCommand("vrmod_advanced_diag")
	end
end)

print(TAG .. "UI module loaded")
