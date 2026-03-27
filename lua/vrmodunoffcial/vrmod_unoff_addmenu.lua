-- --------[vrmod_unoff_addmenu.lua]Start--------
-- DTree Navigation System (2026-03-15)
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
local menutype1 = CreateClientConVar("vrmod_menu_type", 1, true, FCVAR_ARCHIVE, "1 = type1 0 = type2", 0, 1)
local guidemode02 = CreateClientConVar("vrmod_unoff_settings02_guide_mode", "0", true, false, "0=tree view, 1=guide view", 0, 1)

-- DTree Navigation Helper: Creates a DHorizontalDivider with DTree (left) and content panel (right)
local function CreateTreeTab(parent)
	local divider = vgui.Create("DHorizontalDivider", parent)
	divider:Dock(FILL)
	divider:SetDividerWidth(4)
	divider:SetLeftMin(120)
	divider:SetRightMin(200)
	divider:SetLeftWidth(170)

	local tree = vgui.Create("DTree", divider)
	tree:SetShowIcons(true)

	local contentContainer = vgui.Create("DPanel", divider)
	contentContainer.Paint = function() end

	divider:SetLeft(tree)
	divider:SetRight(contentContainer)

	local panels = {}

	local function showPanel(key)
		for k, p in pairs(panels) do
			if IsValid(p) then
				p:SetVisible(k == key)
			end
		end
	end

	local function registerPanel(key, panel)
		panel:SetParent(contentContainer)
		panel:Dock(FILL)
		panel:SetVisible(false)
		panels[key] = panel
	end

	return tree, contentContainer, showPanel, registerPanel
end

-- DTree Navigation Helper: Adds a flat node to the DTree root
local function AddTreeNode(tree, label, key, icon, showPanel)
	local node = tree:AddNode(label, icon)
	node.DoClick = function()
		showPanel(key)
	end
	return node
end

-- DTree Navigation Helper: Extracts tabs from a hidden DPropertySheet into the DTree
local function ExtractSheet(hiddenSheet, tree, showPanel, registerPanel)
	if not IsValid(hiddenSheet) then return end
	local items = hiddenSheet:GetItems()
	if not items then return end
	for _, item in ipairs(items) do
		if item.Tab and item.Panel then
			local tabName = item.Tab:GetText():Trim()
			local key = "mod_" .. tabName
			registerPanel(key, item.Panel)
			AddTreeNode(tree, tabName, key, "icon16/plugin.png", showPanel)
		end
	end
	hiddenSheet:Remove()
end

-- Helper: Creates Utility panel (standalone, returns panel)
local function CreateUtilityPanel()
	local scrollPanel = vgui.Create("DScrollPanel")
	local utilityTab = vgui.Create("DPanel", scrollPanel)
	utilityTab:Dock(TOP)
	utilityTab:SetTall(365)
	utilityTab.Paint = function(self, w, h) end
	-- Preset Management Section
	local presetLabel = vgui.Create("DLabel", utilityTab)
	presetLabel:SetPos(20, 10)
	presetLabel:SetText("=== Settings Preset Management ===")
	presetLabel:SetFont("DermaDefaultBold")
	presetLabel:SizeToContents()
	local presetNameEntry = vgui.Create("DTextEntry", utilityTab)
	presetNameEntry:SetPos(20, 35)
	presetNameEntry:SetSize(330, 25)
	presetNameEntry:SetPlaceholderText("Enter preset name...")
	local savePresetBtn = vgui.Create("DButton", utilityTab)
	savePresetBtn:SetText("Save Preset")
	savePresetBtn:SetPos(20, 65)
	savePresetBtn:SetSize(100, 25)
	savePresetBtn.DoClick = function()
		local name = presetNameEntry:GetValue()
		if name == "" then
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "Please enter a preset name!")
			return
		end
		RunConsoleCommand("vrmod_preset_save", name)
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Preset '" .. name .. "' saved!")
	end
	local loadPresetBtn = vgui.Create("DButton", utilityTab)
	loadPresetBtn:SetText("Load Preset")
	loadPresetBtn:SetPos(130, 65)
	loadPresetBtn:SetSize(100, 25)
	loadPresetBtn.DoClick = function()
		local name = presetNameEntry:GetValue()
		if name == "" then
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "Please enter a preset name!")
			return
		end
		RunConsoleCommand("vrmod_preset_load", name)
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Preset '" .. name .. "' loaded!")
	end
	local listPresetsBtn = vgui.Create("DButton", utilityTab)
	listPresetsBtn:SetText("List Presets")
	listPresetsBtn:SetPos(240, 65)
	listPresetsBtn:SetSize(110, 25)
	listPresetsBtn.DoClick = function()
		RunConsoleCommand("vrmod_preset_list")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Preset list printed to console")
	end
	-- Screen & VGUI Section
	local screenLabel = vgui.Create("DLabel", utilityTab)
	screenLabel:SetPos(20, 105)
	screenLabel:SetText("=== Screen & VGUI ===")
	screenLabel:SetFont("DermaDefaultBold")
	screenLabel:SizeToContents()
	local scrAutoBtn = vgui.Create("DButton", utilityTab)
	scrAutoBtn:SetText("Auto-Detect Screen Resolution")
	scrAutoBtn:SetPos(20, 130)
	scrAutoBtn:SetSize(165, 25)
	scrAutoBtn.DoClick = function()
		RunConsoleCommand("vrmod_Scr_Auto")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Screen resolution auto-detected!")
	end
	local vguiResetBtn = vgui.Create("DButton", utilityTab)
	vguiResetBtn:SetText("Reset VGUI Panels")
	vguiResetBtn:SetPos(195, 130)
	vguiResetBtn:SetSize(155, 25)
	vguiResetBtn.DoClick = function()
		RunConsoleCommand("vrmod_vgui_reset")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "VGUI panels reset")
	end

	-- Config Data Generation Section
	local configLabel = vgui.Create("DLabel", utilityTab)
	configLabel:SetPos(20, 165)
	configLabel:SetText("=== VR Config Data Generation ===")
	configLabel:SetFont("DermaDefaultBold")
	configLabel:SizeToContents()

	local generateConfigBtn = vgui.Create("DButton", utilityTab)
	generateConfigBtn:SetText("Generate VR Config Data (Fix x64 Issues)")
	generateConfigBtn:SetPos(20, 190)
	generateConfigBtn:SetSize(330, 30)
	generateConfigBtn.DoClick = function()
		RunConsoleCommand("vrmod_data_vmt_generate_test")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "VR config data generated! (VMT files converted)")
	end

	local autoGenerateCheckbox = utilityTab:Add("DCheckBoxLabel")
	autoGenerateCheckbox:SetPos(20, 225)
	autoGenerateCheckbox:SetText("Auto-generate on VR startup (recommended for x64 compatibility)")
	autoGenerateCheckbox:SetConVar("vrmod_unoff_auto_generate_config")
	autoGenerateCheckbox:SizeToContents()

	-- Core VR Control Section
	local coreLabel = vgui.Create("DLabel", utilityTab)
	coreLabel:SetPos(20, 255)
	coreLabel:SetText("=== Core VR Control ===")
	coreLabel:SetFont("DermaDefaultBold")
	coreLabel:SizeToContents()
	local startVRBtn = vgui.Create("DButton", utilityTab)
	startVRBtn:SetText("Start VR")
	startVRBtn:SetPos(20, 280)
	startVRBtn:SetSize(80, 25)
	startVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_start")
	end
	local exitVRBtn = vgui.Create("DButton", utilityTab)
	exitVRBtn:SetText("Exit VR")
	exitVRBtn:SetPos(110, 280)
	exitVRBtn:SetSize(80, 25)
	exitVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_exit")
	end
	local resetVRBtn = vgui.Create("DButton", utilityTab)
	resetVRBtn:SetText("Reset All Settings")
	resetVRBtn:SetPos(200, 280)
	resetVRBtn:SetSize(150, 25)
	resetVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_reset")
		chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "All VR settings reset!")
	end
	local infoVRBtn = vgui.Create("DButton", utilityTab)
	infoVRBtn:SetText("Print VR Info")
	infoVRBtn:SetPos(20, 310)
	infoVRBtn:SetSize(165, 25)
	infoVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_info")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "VR info printed to console")
	end
	local luaResetBtn = vgui.Create("DButton", utilityTab)
	luaResetBtn:SetText("Reset Lua Modules")
	luaResetBtn:SetPos(195, 310)
	luaResetBtn:SetSize(155, 25)
	luaResetBtn.DoClick = function()
		RunConsoleCommand("vrmod_lua_reset")
		chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "Lua modules reset")
	end
	return scrollPanel
end

-- Helper: Creates Cardboard panel (standalone, returns panel)
local function CreateCardboardPanel()
	local cardboardTab = vgui.Create("DPanel")
	cardboardTab.Paint = function(self, w, h) end

	-- Cardboard Settings Label
	local cardboardLabel = vgui.Create("DLabel", cardboardTab)
	cardboardLabel:SetPos(20, 10)
	cardboardLabel:SetText("=== Cardboard VR Settings ===")
	cardboardLabel:SetFont("DermaDefaultBold")
	cardboardLabel:SizeToContents()

	-- Cardboard Scale Slider
	local cardboardScale = vgui.Create("DNumSlider", cardboardTab)
	cardboardScale:SetPos(20, 35)
	cardboardScale:SetSize(330, 25)
	cardboardScale:SetText("Cardboard Scale")
	cardboardScale:SetMin(1)
	cardboardScale:SetMax(100)
	cardboardScale:SetDecimals(2)
	cardboardScale:SetConVar("cardboardmod_scale")

	-- Cardboard Sensitivity Slider
	local cardboardSens = vgui.Create("DNumSlider", cardboardTab)
	cardboardSens:SetPos(20, 65)
	cardboardSens:SetSize(330, 25)
	cardboardSens:SetText("Cardboard Sensitivity")
	cardboardSens:SetMin(0.001)
	cardboardSens:SetMax(0.1)
	cardboardSens:SetDecimals(3)
	cardboardSens:SetConVar("cardboardmod_sensitivity")

	-- Info Label
	local cardboardInfo = vgui.Create("DLabel", cardboardTab)
	cardboardInfo:SetPos(20, 95)
	cardboardInfo:SetText("Alternative VR mode using phone sensors (no HMD required)")
	cardboardInfo:SetWrap(true)
	cardboardInfo:SetSize(330, 40)
	cardboardInfo:SetAutoStretchVertical(true)

	-- Commands Label
	local cardboardCmdLabel = vgui.Create("DLabel", cardboardTab)
	cardboardCmdLabel:SetPos(20, 145)
	cardboardCmdLabel:SetText("=== Cardboard Commands ===")
	cardboardCmdLabel:SetFont("DermaDefaultBold")
	cardboardCmdLabel:SizeToContents()

	-- Start Cardboard Button
	local cardboardStartBtn = vgui.Create("DButton", cardboardTab)
	cardboardStartBtn:SetText("Start Cardboard VR Mode")
	cardboardStartBtn:SetPos(20, 170)
	cardboardStartBtn:SetSize(165, 30)
	cardboardStartBtn.DoClick = function()
		RunConsoleCommand("cardboardmod_start")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Cardboard VR mode started")
	end

	-- Exit Cardboard Button
	local cardboardExitBtn = vgui.Create("DButton", cardboardTab)
	cardboardExitBtn:SetText("Exit Cardboard VR Mode")
	cardboardExitBtn:SetPos(195, 170)
	cardboardExitBtn:SetSize(155, 30)
	cardboardExitBtn.DoClick = function()
		RunConsoleCommand("cardboardmod_exit")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Cardboard VR mode exited")
	end

	-- Restore Defaults Button
	local resetCardboardBtn = vgui.Create("DButton", cardboardTab)
	resetCardboardBtn:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
	resetCardboardBtn:SetPos(20, 210)
	resetCardboardBtn:SetSize(200, 30)
	resetCardboardBtn.DoClick = function()
		VRModResetCategory("cardboard")
	end
	return cardboardTab
end

hook.Add(
	"VRMod_Menu",
	"addsettings",
	function(frame)
		if not menutype1:GetBool() then return end

		-- Settings02 container
		local settings02 = vgui.Create("DPanel", frame.DPropertySheet)
		frame.DPropertySheet:AddSheet("Settings02", settings02)
		settings02:Dock(FILL)
		settings02.Paint = function() end

		-- Mode toggle header
		local modeHeader = vgui.Create("DPanel", settings02)
		modeHeader:Dock(TOP)
		modeHeader:SetTall(26)
		modeHeader.Paint = function(self, w, h)
			surface.SetDrawColor(50, 50, 55)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(70, 70, 75)
			surface.DrawLine(0, h - 1, w, h - 1)
		end
		local modeBtn = vgui.Create("DButton", modeHeader)
		modeBtn:Dock(LEFT)
		modeBtn:SetWide(240)
		modeBtn:DockMargin(4, 2, 4, 2)

		-- Tree container (default view)
		local treeContainer = vgui.Create("DPanel", settings02)
		treeContainer:Dock(FILL)
		treeContainer.Paint = function() end

		-- Guide container (alternative view, initially hidden)
		local guideContainer = vgui.Create("DPanel", settings02)
		guideContainer:Dock(FILL)
		guideContainer.Paint = function() end
		guideContainer:SetVisible(false)

		local guideBuilt = false
		local function setGuideMode(isGuide)
			treeContainer:SetVisible(not isGuide)
			guideContainer:SetVisible(isGuide)
			if isGuide then
				modeBtn:SetText("<< Tree View")
				if not guideBuilt and vrmod.guide and vrmod.guide.CreateEmbedded then
					vrmod.guide.CreateEmbedded(guideContainer)
					guideBuilt = true
				end
			else
				modeBtn:SetText(">> Guide View")
			end
			guidemode02:SetBool(isGuide)
		end
		modeBtn.DoClick = function()
			setGuideMode(treeContainer:IsVisible())
		end
		setGuideMode(guidemode02:GetBool())

		-- DTree + content area (inside treeContainer)
		local tree, contentContainer, showPanel, registerPanel = CreateTreeTab(treeContainer)

		-- Hidden DPropertySheets for module compatibility
		local hiddenVRplay = vgui.Create("DPropertySheet", settings02)
		hiddenVRplay:SetVisible(false); hiddenVRplay:SetSize(0, 0)
		frame.VRplaySheet = hiddenVRplay

		local hiddenPickup = vgui.Create("DPropertySheet", settings02)
		hiddenPickup:SetVisible(false); hiddenPickup:SetSize(0, 0)
		frame.pickupSheet = hiddenPickup

		local hiddenNonVRGun = vgui.Create("DPropertySheet", settings02)
		hiddenNonVRGun:SetVisible(false); hiddenNonVRGun:SetSize(0, 0)
		frame.nonVRGunSheet = hiddenNonVRGun

		local hiddenHud = vgui.Create("DPropertySheet", settings02)
		hiddenHud:SetVisible(false); hiddenHud:SetSize(0, 0)
		frame.hudSheet = hiddenHud

		local hiddenDebug = vgui.Create("DPropertySheet", settings02)
		hiddenDebug:SetVisible(false); hiddenDebug:SetSize(0, 0)
		frame.debugSheet = hiddenDebug

		local hiddenQmBtn = vgui.Create("DPropertySheet", settings02)
		hiddenQmBtn:SetVisible(false); hiddenQmBtn:SetSize(0, 0)
		frame.quickmenuBtnSheet = hiddenQmBtn

		local hiddenSettings02 = vgui.Create("DPropertySheet", settings02)
		hiddenSettings02:SetVisible(false); hiddenSettings02:SetSize(0, 0)
		frame.Settings02Sheet = hiddenSettings02

		-- ========================================
		-- Panel: VR
		-- ========================================
		local vrNode
		do
		local scrollPanel = vgui.Create("DScrollPanel")
		local gameplaySettings = vgui.Create("DPanel", scrollPanel)
		gameplaySettings:Dock(TOP)
		gameplaySettings:SetPaintBackground(false)
		gameplaySettings:DockPadding(10, 10, 10, 10)
		local function AddControl(control)
			control:Dock(TOP)
			control:DockMargin(0, 0, 0, 5)
			gameplaySettings:SetTall(gameplaySettings:GetTall() + control:GetTall() + 5)
		end
		local jumpduck = vgui.Create("DCheckBoxLabel", gameplaySettings)
		jumpduck:SetText("[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP")
		jumpduck:SetConVar("vrmod_autojumpduck")
		AddControl(jumpduck)
		local teleport = vgui.Create("DCheckBoxLabel", gameplaySettings)
		teleport:SetText("[Teleport Enable]")
		teleport:SetConVar("vrmod_allow_teleport_client")
		AddControl(teleport)
		local flashlightattach = vgui.Create("DNumSlider", gameplaySettings)
		flashlightattach:SetText("[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD")
		flashlightattach:SetMin(0)
		flashlightattach:SetMax(2)
		flashlightattach:SetDecimals(0)
		flashlightattach:SetConVar("vrmod_flashlight_attachment")
		flashlightattach:SetTooltip("0 = Right Hand, 1 = Left Hand, 2 = HMD")
		AddControl(flashlightattach)
		local laserpointer = vgui.Create("DButton", gameplaySettings)
		laserpointer:SetText("Toggle Laser Pointer")
		laserpointer.DoClick = function()
			RunConsoleCommand("vrmod_togglelaserpointer")
		end
		AddControl(laserpointer)
		local weaponconfig = vgui.Create("DButton", gameplaySettings)
		weaponconfig:SetText("Weapon Viewmodel Setting")
		weaponconfig.DoClick = function()
			RunConsoleCommand("vrmod_weaponconfig")
		end
		AddControl(weaponconfig)
		local autoadjustvm = vgui.Create("DButton", gameplaySettings)
		autoadjustvm:SetText("Auto-adjust Current Weapon (Quick)")
		autoadjustvm.DoClick = function()
			RunConsoleCommand("vrmod_viewmodel_autoadjust")
		end
		AddControl(autoadjustvm)
		local muzzleboneBtn = vgui.Create("DButton", gameplaySettings)
		muzzleboneBtn:SetText("Weapon Bone Config")
		muzzleboneBtn.DoClick = function()
			RunConsoleCommand("vrmod_weapon_bone_config")
		end
		AddControl(muzzleboneBtn)
		local pickupweight = vgui.Create("DNumSlider", gameplaySettings)
		pickupweight:SetText("Pickup Weight (Server)")
		pickupweight:SetMin(0)
		pickupweight:SetMax(1000)
		pickupweight:SetDecimals(0)
		pickupweight:SetConVar("vrmod_pickup_weight")
		AddControl(pickupweight)
		local pickuprange = vgui.Create("DNumSlider", gameplaySettings)
		pickuprange:SetText("Pickup Range (Server)")
		pickuprange:SetMin(0)
		pickuprange:SetMax(5)
		pickuprange:SetDecimals(2)
		pickuprange:SetConVar("vrmod_pickup_range")
		AddControl(pickuprange)
		local pickuplimit = vgui.Create("DNumSlider", gameplaySettings)
		pickuplimit:SetText("Pickup Limit (Server)")
		pickuplimit:SetMin(0)
		pickuplimit:SetMax(3)
		pickuplimit:SetDecimals(0)
		pickuplimit:SetConVar("vrmod_pickup_limit")
		AddControl(pickuplimit)
			local manualpickups = vgui.Create("DCheckBoxLabel", gameplaySettings)
			manualpickups:SetText("Manual Pickup (by Hugo)")
			manualpickups:SetConVar("vrmod_manualpickups")
			manualpickups:SetConVar("vrmod_pickup_allow_default")
			AddControl(manualpickups)
		local GamePlay_defaultbutton = vgui.Create("DButton", gameplaySettings)
		GamePlay_defaultbutton:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
		GamePlay_defaultbutton.DoClick = function()
			VRModResetCategory("gameplay")
		end
		AddControl(GamePlay_defaultbutton)
		registerPanel("vr", scrollPanel)
		vrNode = AddTreeNode(tree, "VR", "vr", "icon16/basket.png", showPanel)
		end -- VR panel

		-- ========================================
		-- Panel: Character
		-- ========================================
		do
		local scrollPanel = vgui.Create("DScrollPanel")
		local vrSettings = vgui.Create("DPanel", scrollPanel)
		vrSettings:Dock(TOP)
		vrSettings:SetPaintBackground(false)
		vrSettings:DockPadding(10, 10, 10, 10)
		local function AddControl(control)
			control:Dock(TOP)
			control:DockMargin(0, 0, 0, 5)
			vrSettings:SetTall(vrSettings:GetTall() + control:GetTall() + 5)
		end
		local characterScale = vgui.Create("DPanel", vrSettings)
		characterScale:Dock(TOP)
		characterScale:SetTall(22)
		AddControl(characterScale)
		local scaleLabel = vgui.Create("DLabel", characterScale)
		scaleLabel:Dock(LEFT)
		scaleLabel:SetText(convars.vrmod_scale:GetFloat())
		scaleLabel:SetWidth(50)
		local scaleUpButton = vgui.Create("DButton", characterScale)
		scaleUpButton:Dock(RIGHT)
		scaleUpButton:SetText("+")
		scaleUpButton:SetWidth(50)
		scaleUpButton.DoClick = function()
			g_VR.scale = g_VR.scale + 0.5
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
		scaleUpButton.DoRightClick = function()
			g_VR.scale = g_VR.scale + 1.0
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
		local scaleDownButton = vgui.Create("DButton", characterScale)
		scaleDownButton:Dock(RIGHT)
		scaleDownButton:SetText("-")
		scaleDownButton:SetWidth(50)
		scaleDownButton.DoClick = function()
			g_VR.scale = g_VR.scale - 0.5
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
		scaleDownButton.DoRightClick = function()
			g_VR.scale = g_VR.scale - 1.0
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
		local scaleDefaultButton = vgui.Create("DButton", characterScale)
		scaleDefaultButton:Dock(RIGHT)
		scaleDefaultButton:SetText("Default")
		scaleDefaultButton:SetWidth(60)
		scaleDefaultButton.DoClick = function()
			g_VR.scale = VRMOD_DEFAULTS.character.vrmod_scale
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
		local eyeheight = vgui.Create("DNumSlider", vrSettings)
		eyeheight:SetText("Character Eye Height")
		eyeheight:SetMin(0)
		eyeheight:SetMax(100)
		eyeheight:SetDecimals(2)
		eyeheight:SetConVar("vrmod_characterEyeHeight")
		AddControl(eyeheight)
		local crouchthreshold = vgui.Create("DNumSlider", vrSettings)
		crouchthreshold:SetText("Crouch Threshold")
		crouchthreshold:SetMin(0)
		crouchthreshold:SetMax(100)
		crouchthreshold:SetDecimals(2)
		crouchthreshold:SetConVar("vrmod_crouchthreshold")
		AddControl(crouchthreshold)
		local headtohmd = vgui.Create("DNumSlider", vrSettings)
		headtohmd:SetText("Character Head to HMD Distance")
		headtohmd:SetMin(-20)
		headtohmd:SetMax(20)
		headtohmd:SetDecimals(2)
		headtohmd:SetConVar("vrmod_characterHeadToHmdDist")
		AddControl(headtohmd)
		local znear = vgui.Create("DNumSlider", vrSettings)
		znear:SetText("Z Near")
		znear:SetMin(0)
		znear:SetMax(20)
		znear:SetDecimals(2)
		znear:SetConVar("vrmod_znear")
		znear:SetTooltip("Objects closer than this will become transparent. Increase if you see parts of your head.")
		AddControl(znear)
		local seatedmode = vgui.Create("DCheckBoxLabel", vrSettings)
		seatedmode:SetText("Enable Seated Mode")
		seatedmode:SetConVar("vrmod_seated")
		AddControl(seatedmode)
		local seatedoffset = vgui.Create("DNumSlider", vrSettings)
		seatedoffset:SetText("Seated Offset")
		seatedoffset:SetMin(-100)
		seatedoffset:SetMax(100)
		seatedoffset:SetDecimals(2)
		seatedoffset:SetConVar("vrmod_seatedoffset")
		AddControl(seatedoffset)
		local althead = vgui.Create("DCheckBoxLabel", vrSettings)
		althead:SetText("Alternative Character Yaw")
		althead:SetConVar("vrmod_oldcharacteryaw")
		AddControl(althead)
		local animationenable = vgui.Create("DCheckBoxLabel", vrSettings)
		animationenable:SetText("Character Animation Enable (Client)")
		animationenable:SetConVar("vrmod_animation_Enable")
		AddControl(animationenable)

		-- Head Hide Settings
		local hideHead = vgui.Create("DCheckBoxLabel", vrSettings)
		hideHead:SetText("Hide Head")
		hideHead:SetConVar("vrmod_hide_head")
		AddControl(hideHead)
		local hideHeadPosX = vgui.Create("DNumSlider", vrSettings)
		hideHeadPosX:SetText("Head Hide Position X")
		hideHeadPosX:SetMin(-1000)
		hideHeadPosX:SetMax(1000)
		hideHeadPosX:SetDecimals(1)
		hideHeadPosX:SetConVar("vrmod_hide_head_pos_x")
		AddControl(hideHeadPosX)
		local hideHeadPosY = vgui.Create("DNumSlider", vrSettings)
		hideHeadPosY:SetText("Head Hide Position Y")
		hideHeadPosY:SetMin(-1000)
		hideHeadPosY:SetMax(1000)
		hideHeadPosY:SetDecimals(1)
		hideHeadPosY:SetConVar("vrmod_hide_head_pos_y")
		AddControl(hideHeadPosY)
		local hideHeadPosZ = vgui.Create("DNumSlider", vrSettings)
		hideHeadPosZ:SetText("Head Hide Position Z")
		hideHeadPosZ:SetMin(-1000)
		hideHeadPosZ:SetMax(1000)
		hideHeadPosZ:SetDecimals(1)
		hideHeadPosZ:SetConVar("vrmod_hide_head_pos_z")
		AddControl(hideHeadPosZ)

		-- Animation Settings
		local idleAct = vgui.Create("DTextEntry", vrSettings)
		idleAct:SetPlaceholderText("Idle Animation (default: ACT_HL2MP_IDLE)")
		idleAct:SetConVar("vrmod_idle_act")
		AddControl(idleAct)
		local walkAct = vgui.Create("DTextEntry", vrSettings)
		walkAct:SetPlaceholderText("Walk Animation (default: ACT_HL2MP_WALK)")
		walkAct:SetConVar("vrmod_walk_act")
		AddControl(walkAct)
		local runAct = vgui.Create("DTextEntry", vrSettings)
		runAct:SetPlaceholderText("Run Animation (default: ACT_HL2MP_RUN)")
		runAct:SetConVar("vrmod_run_act")
		AddControl(runAct)
		local jumpAct = vgui.Create("DTextEntry", vrSettings)
		jumpAct:SetPlaceholderText("Jump Animation (default: ACT_HL2MP_JUMP_PASSIVE)")
		jumpAct:SetConVar("vrmod_jump_act")
		AddControl(jumpAct)

		local lefthand = vgui.Create("DCheckBoxLabel", vrSettings)
		lefthand:SetText("Left Hand (WIP)")
		lefthand:SetConVar("vrmod_LeftHand")
		AddControl(lefthand)
		local lefthandfire = vgui.Create("DCheckBoxLabel", vrSettings)
		lefthandfire:SetText("Left Hand Fire (WIP)")
		lefthandfire:SetConVar("vrmod_lefthandleftfire")
		AddControl(lefthandfire)
		local lefthandhold = vgui.Create("DCheckBoxLabel", vrSettings)
		lefthandhold:SetText("Left Hand Hold Mode (WIP)")
		lefthandhold:SetConVar("vrmod_LeftHandmode")
		AddControl(lefthandhold)
		local togglemirror = vgui.Create("DButton", vrSettings)
		togglemirror:SetText("Toggle Mirror")
		togglemirror.DoClick = function()
			if GetConVar("vrmod_heightmenu"):GetBool() then
				VRUtilMenuClose("heightmenu")
				convars.vrmod_heightmenu:SetBool(false)
			else
				VRUtilOpenHeightMenu()
				convars.vrmod_heightmenu:SetBool(true)
			end
		end
		AddControl(togglemirror)
		local applybutton = vgui.Create("DButton", vrSettings)
		applybutton:SetText("Apply VR Settings (Requires VRMod Restart)")
		applybutton.DoClick = function()
			RunConsoleCommand("vrmod_restart")
		end
		AddControl(applybutton)
		local autoadjust = vgui.Create("DButton", vrSettings)
		autoadjust:SetText("Auto Adjust VR Settings (Requires VRMod Restart)")
		autoadjust.DoClick = function()
			RunConsoleCommand("vrmod_character_auto")
			timer.Simple(
				2,
				function()
					RunConsoleCommand("vrmod_scale_auto")
				end
			)
			timer.Simple(
				1,
				function()
					RunConsoleCommand("vrmod_restart")
				end
			)
		end
		AddControl(autoadjust)
		local vrdefault = vgui.Create("DButton", vrSettings)
		vrdefault:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
		vrdefault.DoClick = function()
			VRModResetCategory("character")
		end
		AddControl(vrdefault)
		registerPanel("character", scrollPanel)
		AddTreeNode(tree, "Character", "character", "icon16/user.png", showPanel)
		end -- Character panel

		-- ========================================
		-- Panel: UI
		-- ========================================
		do
		local uiScrollPanel = vgui.Create("DScrollPanel")
		local uiSettings = vgui.Create("DForm", uiScrollPanel)
		uiSettings:Dock(TOP)
		uiSettings:DockPadding(0, 0, 0, 0)
		local hudenable = uiSettings:CheckBox("HUD Enable")
		hudenable:SetConVar("vrmod_hud")
		local hudcurve = uiSettings:NumSlider("HUD Curve", "vrmod_hudcurve", 1, 100, 0)
		local huddistance = uiSettings:NumSlider("HUD Distance", "vrmod_huddistance", 1, 200, 0)
		local hudscale = uiSettings:NumSlider("HUD Scale", "vrmod_hudscale", 0.01, 0.20, 2)
		local hudalpha = uiSettings:NumSlider("HUD Alpha", "vrmod_hudtestalpha", 0, 255, 0)
		local hudonlykey = uiSettings:CheckBox("HUD Only While Pressing Menu Key")
		hudonlykey:SetConVar("vrmod_hud_visible_quickmenukey")
		local quickmenuattach = uiSettings:ComboBox("Quickmenu Attach Position", "vrmod_attach_quickmenu")
		quickmenuattach:AddChoice("Left Hand", "1")
		quickmenuattach:AddChoice("Right Hand", "4")
		quickmenuattach:AddChoice("HMD", "3")
		local weaponmenuattach = uiSettings:ComboBox("Weapon Menu Attach Position", "vrmod_attach_weaponmenu")
		weaponmenuattach:AddChoice("Left Hand", "1")
		weaponmenuattach:AddChoice("Right Hand", "4")
		weaponmenuattach:AddChoice("HMD", "3")
		local popupattach = uiSettings:ComboBox("Popup Window Attach Position", "vrmod_attach_popup")
		popupattach:AddChoice("Left Hand", "1")
		popupattach:AddChoice("Right Hand", "4")
		popupattach:AddChoice("HMD", "3")
		local menuoutline = uiSettings:CheckBox("Menu & UI Red Outline")
		menuoutline:SetConVar("vrmod_ui_outline")
		local uirender = uiSettings:CheckBox("UI Render Alternative")
		uirender:SetConVar("vrmod_ui_realtime")
		local cameraoverride = uiSettings:CheckBox("Desktop Camera Override")
		cameraoverride:SetTooltip("OFF: If using a camera mod, the GMod window will show the camera view")
		cameraoverride:SetConVar("vrmod_cameraoverride")
		local keyboarduichat = uiSettings:CheckBox("Keyboard UI Chat Key")
		keyboarduichat:SetConVar("vrmod_keyboard_uichatkey")
		local VRElefthand = uiSettings:CheckBox("VRE Attach Left Hands")
		VRElefthand:SetConVar("vre_ui_attachtohand")
		local desktopUIMirror = uiSettings:CheckBox("Show VR UI on Desktop Window")
		desktopUIMirror:SetConVar("vrmod_unoff_desktop_ui_mirror")
		desktopUIMirror:SetTooltip("Keep menus and popups visible on the desktop window while in VR")
		local uidefault = uiSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		uidefault.DoClick = function()
			VRModResetCategory("ui")
		end

		-- VR Keyboard Button
		local keyboardButton = uiSettings:Button("Toggle VR Keyboard")
		keyboardButton.DoClick = function()
			RunConsoleCommand("vrmod_keyboard")
		end
		uiSettings:Help("Show/hide the virtual keyboard for text input in VR")

		-- Action Editor Button
		local actionEditorButton = uiSettings:Button("Open Action Editor")
		actionEditorButton.DoClick = function()
			RunConsoleCommand("vrmod_actioneditor")
		end
		uiSettings:Help("Configure VR controller bindings (Note: Disabled while VR is active)")

		-- Screen Resolution Settings (from old menu GameRebootRequied)
		local screenResCategory = uiSettings:Help("=== Screen Resolution Settings ===")
		screenResCategory:SetFont("DermaDefaultBold")

		uiSettings:Help("WARNING: Changing these settings requires VR restart to take effect")

		uiSettings:NumSlider("VR UI Height", "vrmod_ScrH", 480, ScrH() * 2, 0)
		uiSettings:NumSlider("VR UI Width", "vrmod_ScrW", 640, ScrW() * 2, 0)
		uiSettings:NumSlider("VR HUD Height", "vrmod_ScrH_hud", 480, ScrH() * 2, 0)
		uiSettings:NumSlider("VR HUD Width", "vrmod_ScrW_hud", 640, ScrW() * 2, 0)

		local scrAutoCheckbox = uiSettings:CheckBox("Always Auto-Detect Screen Resolution on VR Start")
		scrAutoCheckbox:SetConVar("vrmod_scr_alwaysautosetting")
		uiSettings:Help("Automatically detect and set optimal screen resolution when entering VR")

		-- Column layout for checkboxes
		local leftColumn2 = vgui.Create("DPanel", uiSettings)
		leftColumn2:SetSize(200, 400)
		leftColumn2:Dock(LEFT)
		local rightColumn2 = vgui.Create("DPanel", uiSettings)
		rightColumn2:SetSize(200, 400)
		rightColumn2:Dock(RIGHT)
		leftColumn2:Add(VRElefthand)
		leftColumn2:Add(menuoutline)
		leftColumn2:Add(hudonlykey)
		leftColumn2:Add(keyboarduichat)
		rightColumn2:Add(cameraoverride)
		rightColumn2:Add(uirender)
		rightColumn2:Add(uidefault)

		registerPanel("ui", uiScrollPanel)
		AddTreeNode(tree, "UI", "ui", "icon16/photos.png", showPanel)
		end -- UI panel
		-- ========================================
		-- Panel: Optimize
		-- ========================================
		do
		local graphicsScrollPanel = vgui.Create("DScrollPanel")
		local graphicsSettings = vgui.Create("DForm", graphicsScrollPanel)
		graphicsSettings:Dock(TOP)
		graphicsSettings:DockPadding(0, 0, 0, 0)
		local skybox = graphicsSettings:CheckBox("Skybox Enable (Client)")
		skybox:SetConVar("r_3dsky")
		local shadows = graphicsSettings:CheckBox("Shadows & Flashlights Effect Enable (Client)")
		shadows:SetConVar("r_shadows")
		local farz = graphicsSettings:NumSlider("Visible Range of Map", "r_farz", 0, 16384, 0)
		farz:SetTooltip("sv_cheats 1 is required")
		local optimizationLevel = graphicsSettings:NumSlider("VRMod Optimization Level", "vrmod_gmod_optimization", 0, 4, 0)
		optimizationLevel:SetTooltip("0: No optimization\n1: No changes from VRMod\n2: Reset (disable optimizations)\n3: Optimization ON (VR safe)\n4: Max optimization (Eye Flash WARNING)")
		local optimizationDescription = graphicsSettings:Help("Optimization Levels:\n" .. "0: No optimization applied\n" .. "1: No changes - VRMod does not modify any ConVars\n" .. "2: Reset - Restores water reflections, disables mirror optimization\n" .. "3: Optimization ON - Water/mirrors/specular OFF, gmod_mcore_test 0 (VR safe)\n" .. "4: Max optimization - All of Lv3 + gmod_mcore_test 1 (!!Right eye flash WARNING!!)")
		optimizationDescription:SetAutoStretchVertical(true)

		-- Apply Optimization Button
		local applyOptButton = graphicsSettings:Button("Apply Optimization Now")
		applyOptButton.DoClick = function()
			RunConsoleCommand("vrmod_apply_optimization")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Optimization applied!")
		end
		graphicsSettings:Help("Manually trigger optimization based on current vrmod_gmod_optimization level")

		-- Mirror/Reflection Management
		local mirrorCategory = graphicsSettings:Help("=== Mirror & Reflection Management ===")
		mirrorCategory:SetFont("DermaDefaultBold")

		local removeGlassBtn = graphicsSettings:Button("Remove All Reflective Glass from Map")
		removeGlassBtn.DoClick = function()
			RunConsoleCommand("remove_reflective_glass")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "All reflective glass removed from map")
		end
		graphicsSettings:Help("Forcibly removes all reflective surfaces from the map (may cause visual glitches)")

		-- Render Target Settings (from old menu Misc03)
		local renderTargetCategory = graphicsSettings:Help("=== Render Target Settings ===")
		renderTargetCategory:SetFont("DermaDefaultBold")

		graphicsSettings:NumSlider("Render Target Width Multiplier", "vrmod_rtWidth_Multiplier", 0.1, 5.0, 1)
		graphicsSettings:NumSlider("Render Target Height Multiplier", "vrmod_rtHeight_Multiplier", 0.1, 5.0, 1)

		local resetRenderBtn = graphicsSettings:Button("Reset Render Targets")
		resetRenderBtn.DoClick = function()
			RunConsoleCommand("vrmod_reset_render_targets")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "Render targets reset (VR will exit)")
		end
		graphicsSettings:Help("Reset VR render targets (VR mode will exit)")

		local updateRenderBtn = graphicsSettings:Button("Update Render Targets")
		updateRenderBtn.DoClick = function()
			RunConsoleCommand("vrmod_update_render_targets")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Render targets updated")
		end
		graphicsSettings:Help("Update render targets with current multiplier settings")

		local quest2PresetBtn = graphicsSettings:Button("Apply Quest 2 + Virtual Desktop Preset")
		quest2PresetBtn.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.5")
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "1.2")
			RunConsoleCommand("vrmod_restart")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "Quest 2 preset applied, VR restarting...")
		end
		graphicsSettings:Help("Set optimal render target multipliers for Quest 2 + Virtual Desktop (VR will restart)")

		local renderDefaultBtn = graphicsSettings:Button("Reset Render Target Multipliers to Default")
		renderDefaultBtn.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.0")
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "2.0")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Render target multipliers reset to default (2.0)")
		end
		graphicsSettings:Help("Reset both multipliers to default value (2.0)")

		registerPanel("optimize", graphicsScrollPanel)
		AddTreeNode(tree, "Optimize", "optimize", "icon16/picture.png", showPanel)
		end -- Optimize panel

		-- ========================================
		-- Panel: Opt.VR
		-- ========================================
		do
		local MenuTab11 = vgui.Create("DPanel")
		MenuTab11.Paint = function(self, w, h) end
		local scroll = vgui.Create("DScrollPanel", MenuTab11)
		scroll:Dock(FILL)
		local optimizeconvar = {{"r_WaterDrawReflection", 0, 1, "Draw water reflections", 1}, {"r_WaterDrawRefraction", 0, 1, "Draw water refractions", 1}, {"r_waterforceexpensive", 0, 1, "Force expensive water", 0}, {"r_waterforcereflectentities", 0, 1, "Force water to reflect entities", 0}, {"vrmod_mirror_optimization", 0, 1, "Optimize VR mirrors", 0}, {"vrmod_reflective_glass_toggle", 0, 1, "Toggle reflective glass", 0}, {"vrmod_disable_mirrors", 0, 1, "Disable mirrors", 0}, {"gmod_mcore_test", 0, 1, "Enable multi-core rendering", 1}, {"mat_queue_mode", -1, 2, "Multicore rendering mode (Warning: 2 can cause flickering)", -1}}
		local changedValues = {}
		for i, convar_item in ipairs(optimizeconvar) do
			local name, min, max, description, default = unpack(convar_item)
			local panel = vgui.Create("DPanel", scroll)
			panel:Dock(TOP)
			panel:SetHeight(70)
			panel:DockMargin(0, 0, 0, 10)
			local label = vgui.Create("DLabel", panel)
			label:SetText(description)
			label:SetTextColor(Color(50, 50, 50))
			label:Dock(TOP)
			local slider = vgui.Create("DNumSlider", panel)
			slider:Dock(TOP)
			slider:SetText(name)
			slider:SetMin(min)
			slider:SetMax(max)
			slider:SetDecimals(0)
			slider:SetDark(true)
			local valueLabel = vgui.Create("DLabel", panel)
			valueLabel:Dock(LEFT)
			valueLabel:SetWidth(50)
			valueLabel:SetTextColor(Color(50, 50, 50))
			local defaultButton = vgui.Create("DButton", panel)
			defaultButton:Dock(RIGHT)
			defaultButton:SetText("Default")
			defaultButton:SetWidth(60)
			slider.OnValueChanged = function(self, value)
				changedValues[name] = math.Round(value)
				valueLabel:SetText(tostring(math.Round(value)))
			end
			local cvar = GetConVar(name)
			local currentValue = cvar and cvar:GetInt() or default
			slider:SetValue(currentValue)
			valueLabel:SetText(tostring(currentValue))
			defaultButton.DoClick = function()
				slider:SetValue(default)
				changedValues[name] = default
			end
		end
		local applyButton = vgui.Create("DButton", MenuTab11)
		applyButton:Dock(BOTTOM)
		applyButton:SetText("Apply")
		applyButton:SetHeight(30)
		applyButton.DoClick = function()
			for name, value in pairs(changedValues) do
				RunConsoleCommand(name, tostring(value))
			end
			changedValues = {}
		end
		registerPanel("optvr", MenuTab11)
		AddTreeNode(tree, "Opt.VR", "optvr", "icon16/cog_add.png", showPanel)
		end -- Opt.VR panel

		-- ========================================
		-- Panel: Opt.Gmod
		-- ========================================
		do
		local MenuTab12 = vgui.Create("DPanel")
		MenuTab12.Paint = function(self, w, h) end
		local scroll = vgui.Create("DScrollPanel", MenuTab12)
		scroll:Dock(FILL)
		local optimizeconvar2 = {{"r_shadowmaxrendered", 1, 32, "Maximum number of shadows rendered", 32}, {"r_flashlightdepthres", 1, 1024, "Flashlight shadow map resolution", 512}, {"mat_picmip", -10, 20, "Texture quality (lower is better)", 0}, {"r_lod", -1, 10, "Level of detail", 0}, {"r_rootlod", -1, 10, "Root level of detail", 0}, {"ai_expression_frametime", 0.1, 2, "AI expression update frequency", 0.5}, {"cl_detaildist", 1, 8000, "Distance at which details are visible", 1200}, {"mat_fastspecular", 0, 1, "Distance at which details are visible", 1}, {"mat_wateroverlaysize", 2, 1200, "Distance at which details are visible", 256}, {"r_drawdetailprops", 0, 2, "Draw detail props", 1}, {"mat_specular", 0, 1, "Specular reflections", 1}, {"mat_spectate", 0, 1, "Spectate rendering (disable for VR perf)", 0}}
		local changedValues = {}
		for i, convar_item in ipairs(optimizeconvar2) do
			local name, min, max, description, default = unpack(convar_item)
			local panel = vgui.Create("DPanel", scroll)
			panel:Dock(TOP)
			panel:SetHeight(70)
			panel:DockMargin(0, 0, 0, 10)
			local label = vgui.Create("DLabel", panel)
			label:SetText(description)
			label:SetTextColor(Color(50, 50, 50))
			label:Dock(TOP)
			local slider = vgui.Create("DNumSlider", panel)
			slider:Dock(TOP)
			slider:SetText(name)
			slider:SetMin(min)
			slider:SetMax(max)
			slider:SetDecimals(2)
			slider:SetDark(true)
			local valueLabel = vgui.Create("DLabel", panel)
			valueLabel:Dock(LEFT)
			valueLabel:SetWidth(50)
			valueLabel:SetTextColor(Color(50, 50, 50))
			local defaultButton = vgui.Create("DButton", panel)
			defaultButton:Dock(RIGHT)
			defaultButton:SetText("Default")
			defaultButton:SetWidth(60)
			slider.OnValueChanged = function(self, value)
				changedValues[name] = value
				valueLabel:SetText(string.format("%.2f", value))
			end
			local cvar = GetConVar(name)
			local currentValue = cvar and cvar:GetFloat() or default
			slider:SetValue(currentValue)
			valueLabel:SetText(string.format("%.2f", currentValue))
			defaultButton.DoClick = function()
				slider:SetValue(default)
				changedValues[name] = default
			end
		end
		local applyButton = vgui.Create("DButton", MenuTab12)
		applyButton:Dock(BOTTOM)
		applyButton:SetText("Apply")
		applyButton:SetHeight(30)
		applyButton.DoClick = function()
			for name, value in pairs(changedValues) do
				RunConsoleCommand(name, tostring(value))
			end
			changedValues = {}
		end
		registerPanel("optgmod", MenuTab12)
		AddTreeNode(tree, "Opt.Gmod", "optgmod", "icon16/cog_add.png", showPanel)
		end -- Opt.Gmod panel

		-- ========================================
		-- Panel: Quick Menu
		-- ========================================
		do
		local quickMenuSettings = vgui.Create("DForm")
		quickMenuSettings:DockPadding(0, 0, 0, 0)
		local mapbrowser = quickMenuSettings:CheckBox("Map Browser")
		mapbrowser:SetConVar("vrmod_quickmenu_mapbrowser_enable")
		local vrexit = quickMenuSettings:CheckBox("VR Exit")
		vrexit:SetConVar("vrmod_quickmenu_exit")
		local uireset = quickMenuSettings:CheckBox("UI Reset")
		uireset:SetConVar("vrmod_quickmenu_vgui_reset_menu")
		local gbradial = quickMenuSettings:CheckBox("VRE GBRadial & Add Menu")
		gbradial:SetConVar("vrmod_quickmenu_vre_gbradial_menu")
		local chat = quickMenuSettings:CheckBox("Chat")
		chat:SetConVar("vrmod_quickmenu_chat")
		local seatedmenu = quickMenuSettings:CheckBox("Seated Mode")
		seatedmenu:SetConVar("vrmod_quickmenu_seated_menu")
		local mirrortoggle = quickMenuSettings:CheckBox("Toggle Mirror")
		mirrortoggle:SetConVar("vrmod_quickmenu_togglemirror")
		local spawnmenu = quickMenuSettings:CheckBox("Spawn Menu")
		spawnmenu:SetConVar("vrmod_quickmenu_spawn_menu")
		local noclip = quickMenuSettings:CheckBox("No Clip")
		noclip:SetConVar("vrmod_quickmenu_noclip")
		local contextmenu = quickMenuSettings:CheckBox("Context Menu")
		contextmenu:SetConVar("vrmod_quickmenu_context_menu")
		local arccw = quickMenuSettings:CheckBox("ArcCW Customize")
		arccw:SetConVar("vrmod_quickmenu_arccw")
		local vehiclemode = quickMenuSettings:CheckBox("Toggle Vehicle Mode")
		vehiclemode:SetConVar("vrmod_quickmenu_togglevehiclemode")
		local quickmenudefault = quickMenuSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		quickmenudefault.DoClick = function()
			VRModResetCategory("quickmenu")
		end
		registerPanel("quickmenu", quickMenuSettings)
		AddTreeNode(tree, "Quick Menu", "quickmenu", "icon16/application_view_tile.png", showPanel)
		end -- Quick Menu panel

		-- ========================================
		-- Panel: VRStop Key
		-- ========================================
		do
		local PanelEMSTOP = vgui.Create("DPanel")
		PanelEMSTOP.Paint = function(self, w, h) end
		local emergStopKeyBinder = vgui.Create("DBinder", PanelEMSTOP)
		emergStopKeyBinder:SetPos(20, 20)
		emergStopKeyBinder:SetSize(300, 20)
		emergStopKeyBinder:SetConVar("vrmod_emergencystop_key")
		local emergStopHoldTime = vgui.Create("DNumSlider", PanelEMSTOP)
		emergStopHoldTime:SetPos(20, 50)
		emergStopHoldTime:SetSize(330, 30)
		emergStopHoldTime:SetText("Hold Time for \n Emergency Stop (Seconds)")
		emergStopHoldTime:SetMin(0.0)
		emergStopHoldTime:SetMax(10.0)
		emergStopHoldTime:SetDecimals(2)
		emergStopHoldTime:SetConVar("vrmod_emergencystop_time")
		registerPanel("vrstop", PanelEMSTOP)
		AddTreeNode(tree, "VRStop Key", "vrstop", "icon16/stop.png", showPanel)
		end -- VRStop Key panel

		-- ========================================
		-- Panel: Misc
		-- ========================================
		do
		local generalSettings = vgui.Create("DForm")
		generalSettings:DockPadding(0, 0, 0, 0)
		local showonstartup = generalSettings:CheckBox("VRMod Menu Show on Startup")
		showonstartup:SetConVar("vrmod_showonstartup")
		local errorcheck = generalSettings:CheckBox("Error Check Method")
		errorcheck:SetConVar("vrmod_error_check_method")
		local errorlock = generalSettings:CheckBox("ModuleError VRMod Menu Lock")
		errorlock:SetConVar("vrmod_error_hard")
		local pmchange = generalSettings:CheckBox("Player Model Change (forPAC3)")
		pmchange:SetConVar("vrmod_pmchange")
		local vrdisablepickup = generalSettings:CheckBox("VR Disable Pickup (Client)")
		vrdisablepickup:SetConVar("vr_pickup_disable_client")
		local lvspickuphandle = generalSettings:CheckBox("Enable LVS Pickup Handle")
		lvspickuphandle:SetConVar("vrmod_lvs_input_mode")
		local vrmodmenutype = generalSettings:CheckBox("VRMod Menu Type")
		vrmodmenutype:SetConVar("vrmod_menu_type")

		-- Additional Misc Settings
		local quickmenuCustom = generalSettings:CheckBox("Use Custom QuickMenu")
		quickmenuCustom:SetConVar("vrmod_quickmenu_use_custom")
		local autoSeatReset = generalSettings:CheckBox("Auto Seat Reset")
		autoSeatReset:SetConVar("vrmod_auto_seat_reset")
		local sightBodypart = generalSettings:CheckBox("Sight Bodypart")
		sightBodypart:SetConVar("vrmod_sight_bodypart")

		-- Developer Mode Toggle
		local devModeToggle = generalSettings:CheckBox("Enable Developer Mode (requires VRMod restart)")
		devModeToggle:SetConVar("vrmod_unoff_developer_mode")
		local devModeHelp = generalSettings:Help("Developer Mode enables advanced debug settings.\nToggle this and restart VRMod to apply changes.")
		devModeHelp:SetTextColor(Color(255, 0, 0))

		-- Restore Defaults for Misc
		local miscDefault = generalSettings:Button(VRModL("btn_restore_defaults", "Restore Misc Defaults"))
		miscDefault.DoClick = function()
			VRModResetCategory("misc")
		end
		registerPanel("misc", generalSettings)
		AddTreeNode(tree, "Misc", "misc", "icon16/cog.png", showPanel)
		end -- Misc panel

		-- ========================================
		-- Panel: Animation
		-- ========================================
		do
		local animationSettings = vgui.Create("DForm")
		animationSettings:DockPadding(0, 0, 0, 0)
		animationSettings:TextEntry("Idle Animation", "vrmod_idle_act")
		animationSettings:TextEntry("Walk Animation", "vrmod_walk_act")
		animationSettings:TextEntry("Run Animation", "vrmod_run_act")
		animationSettings:TextEntry("Jump Animation", "vrmod_jump_act")
		local helpText = animationSettings:Help("Enter animation names (e.g., ACT_HL2MP_IDLE)")
		helpText:DockMargin(0, 10, 0, 0)
		local defaultButton = vgui.Create("DButton", animationSettings)
		defaultButton:SetText("Reset to Default")
		defaultButton:Dock(TOP)
		defaultButton:DockMargin(0, 10, 0, 0)
		defaultButton.DoClick = function()
			RunConsoleCommand("vrmod_idle_act", "ACT_HL2MP_IDLE")
			RunConsoleCommand("vrmod_walk_act", "ACT_HL2MP_WALK")
			RunConsoleCommand("vrmod_run_act", "ACT_HL2MP_WALK")
			RunConsoleCommand("vrmod_jump_act", "ACT_HL2MP_WALK")
		end
		registerPanel("animation", animationSettings)
		AddTreeNode(tree, "Animation", "animation", "icon16/user_edit.png", showPanel)
		end -- Animation panel

		-- ========================================
		-- Panel: Graphics02
		-- ========================================
		do
		local advancedSettings = vgui.Create("DForm")
		advancedSettings:DockPadding(0, 0, 0, 0)
		local autores = advancedSettings:CheckBox("Automatic Resolution Set")
		autores:SetConVar("vrmod_scr_alwaysautosetting")
		local rtwidth = advancedSettings:NumSlider("Render Target Width Multiplier", "vrmod_rtWidth_Multiplier", 0.1, 10, 1)
		local rtheight = advancedSettings:NumSlider("Render Target Height Multiplier", "vrmod_rtHeight_Multiplier", 0.1, 10, 1)
		local uiwidth = advancedSettings:NumSlider("VR UI Width", "vrmod_ScrW", 640, ScrW() * 2, 0)
		local uiheight = advancedSettings:NumSlider("VR UI Height", "vrmod_ScrH", 480, ScrH() * 2, 0)
		local hudwidth = advancedSettings:NumSlider("VR HUD Width", "vrmod_ScrW_hud", 640, ScrW() * 2, 0)
		local hudheight = advancedSettings:NumSlider("VR HUD Height", "vrmod_ScrH_hud", 480, ScrH() * 2, 0)
		local customres = advancedSettings:Button("Custom Width & Height (Quest 2 / Virtual Desktop)")
		customres.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.5")
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "1.2")
		end
		customres.DoRightClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.5")
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "1.2")
			if g_VR.active then
				RunConsoleCommand("vrmod_ScrW_hud", g_VR.rt:Width() / 2)
				RunConsoleCommand("vrmod_ScrH_hud", g_VR.rt:Height())
			end
		end
		local advanceddefault = advancedSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		advanceddefault.DoClick = function()
			VRModResetCategory("advanced")
			RunConsoleCommand("vrmod_restart")
		end
		registerPanel("graphics02", advancedSettings)
		AddTreeNode(tree, "Graphics02", "graphics02", "icon16/wrench.png", showPanel)
		end -- Graphics02 panel

		-- ========================================
		-- Panel: Network(Server)
		-- ========================================
		do
		local networkSettings = vgui.Create("DForm")
		networkSettings:DockPadding(0, 0, 0, 0)
		local netdelay = networkSettings:NumSlider("Net Delay", "vrmod_net_delay", 0, 1, 3)
		local netdelaymax = networkSettings:NumSlider("Net Delay Max", "vrmod_net_delaymax", 0, 100, 3)
		local netstoredframes = networkSettings:NumSlider("Net Stored Frames", "vrmod_net_storedframes", 1, 25, 3)
		local nettickrate = networkSettings:NumSlider("Net Tickrate", "vrmod_net_tickrate", 1, 100, 3)
		local allowteleport = networkSettings:CheckBox("Allow VR Teleport (Server)")
		allowteleport:SetConVar("vrmod_allow_teleport")
		local netdefault = networkSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		netdefault.DoClick = function()
			VRModResetCategory("network")
		end
		registerPanel("network", networkSettings)
		AddTreeNode(tree, "Network(Server)", "network", "icon16/connect.png", showPanel)
		end -- Network panel

		-- ========================================
		-- Panel: Commands
		-- ========================================
		do
		local commandsTab = vgui.Create("DPanel")
		commandsTab.Paint = function(self, w, h) end

		local scrollPanel = vgui.Create("DScrollPanel", commandsTab)
		scrollPanel:Dock(FILL)

		local commandsForm = vgui.Create("DForm", scrollPanel)
		commandsForm:SetName("VR Commands")
		commandsForm:Dock(TOP)
		commandsForm:DockMargin(5, 5, 5, 5)
		commandsForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Debug Visualization
		local debugCategory = commandsForm:Help("=== Debug Visualization ===")
		debugCategory:SetFont("DermaDefaultBold")

		local doorDebugBtn = commandsForm:Button("Toggle Door Collision Debug")
		doorDebugBtn.DoClick = function()
			RunConsoleCommand("vrmod_doordebug")
		end

		local locoDebugBtn = commandsForm:Button("Toggle Playspace Debug")
		locoDebugBtn.DoClick = function()
			RunConsoleCommand("vrmod_debuglocomotion")
		end

		local netDebugBtn = commandsForm:Button("Toggle Network Debug")
		netDebugBtn.DoClick = function()
			RunConsoleCommand("vrmod_net_debug")
		end

		commandsForm:Help("Visualize collision boxes, playspace boundaries, and network traffic")

		-- Compatibility Testing
		local compatCategory = commandsForm:Help("=== Compatibility Testing ===")
		compatCategory:SetFont("DermaDefaultBold")

		local x64AnimBtn = commandsForm:Button("Switch to x64 Animation")
		x64AnimBtn.DoClick = function()
			RunConsoleCommand("vrmod_compat_test_x64")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "Switched to x64 animation. Map reload required.")
		end

		local semiAnimBtn = commandsForm:Button("Switch to Semiofficial Animation")
		semiAnimBtn.DoClick = function()
			RunConsoleCommand("vrmod_compat_test_semi")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), "Switched to semiofficial animation. Map reload required.")
		end

		local compatStatusBtn = commandsForm:Button("Show Compatibility Status")
		compatStatusBtn.DoClick = function()
			RunConsoleCommand("vrmod_compat_status")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Compatibility status printed to console")
		end

		commandsForm:Help("Test different animation systems (requires map reload)")

		-- Device Information
		local deviceCategory = commandsForm:Help("=== Device Information ===")
		deviceCategory:SetFont("DermaDefaultBold")

		local printDevicesBtn = commandsForm:Button("Print VR Devices Info")
		printDevicesBtn.DoClick = function()
			RunConsoleCommand("vrmod_print_devices")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "VR devices info printed to console")
		end

		commandsForm:Help("Display all connected VR tracking devices and FBT status")

		-- Cardboard VR Support
		local cardboardCategory = commandsForm:Help("=== Cardboard VR Support ===")
		cardboardCategory:SetFont("DermaDefaultBold")

		local cardboardStartBtn = commandsForm:Button("Start Cardboard VR Mode")
		cardboardStartBtn.DoClick = function()
			RunConsoleCommand("cardboardmod_start")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Cardboard VR mode started")
		end

		local cardboardExitBtn = commandsForm:Button("Exit Cardboard VR Mode")
		cardboardExitBtn.DoClick = function()
			RunConsoleCommand("cardboardmod_exit")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Cardboard VR mode exited")
		end

		commandsForm:Help("Alternative VR mode using phone sensors (for testing without HMD)")

		-- VRE Integration
		local vreCategory = commandsForm:Help("=== VRE (VR Essentials) Integration ===")
		vreCategory:SetFont("DermaDefaultBold")

		local radialMenuBtn = commandsForm:Button("Toggle Radial Menu")
		radialMenuBtn.DoClick = function()
			RunConsoleCommand("vre_gb-radial")
		end

		local serverMenuBtn = commandsForm:Button("Toggle Server Menu")
		serverMenuBtn.DoClick = function()
			RunConsoleCommand("vre_svmenu")
		end

		commandsForm:Help("VRE addon must be installed for these commands to work")

		registerPanel("commands", commandsTab)
		AddTreeNode(tree, "Commands", "commands", "icon16/application_xp_terminal.png", showPanel)
		end -- Commands panel

		-- ========================================
		-- Panel: Vehicle
		-- ========================================
		do
		local vehicleTab = vgui.Create("DPanel")
		vehicleTab.Paint = function(self, w, h) end
		-- Input Mode Switching Buttons
		local keymodeMainBtn = vgui.Create("DButton", vehicleTab)
		keymodeMainBtn:SetText("Main Mode\n(On-Foot)")
		keymodeMainBtn:SetPos(20, 10)
		keymodeMainBtn:SetSize(160, 40)
		keymodeMainBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_main")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Switched to Main input mode")
		end
		keymodeMainBtn:SetTooltip("Use main controller bindings (on-foot controls)")
		local keymodeDrivingBtn = vgui.Create("DButton", vehicleTab)
		keymodeDrivingBtn:SetText("Driving Mode\n(Vehicle)")
		keymodeDrivingBtn:SetPos(190, 10)
		keymodeDrivingBtn:SetSize(160, 40)
		keymodeDrivingBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_driving")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Switched to Driving input mode")
		end
		keymodeDrivingBtn:SetTooltip("Use driving controller bindings (vehicle controls)")
		local keymodeBothBtn = vgui.Create("DButton", vehicleTab)
		keymodeBothBtn:SetText("Both Modes\n(Main + Driving)")
		keymodeBothBtn:SetPos(20, 60)
		keymodeBothBtn:SetSize(160, 40)
		keymodeBothBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_both")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Both input modes enabled")
		end
		keymodeBothBtn:SetTooltip("Use both main and driving bindings simultaneously")
		local keymodeRestoreBtn = vgui.Create("DButton", vehicleTab)
		keymodeRestoreBtn:SetText("Auto Mode\n(Restore)")
		keymodeRestoreBtn:SetPos(190, 60)
		keymodeRestoreBtn:SetSize(160, 40)
		keymodeRestoreBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_restore")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Input mode restored to automatic")
		end
		keymodeRestoreBtn:SetTooltip("Restore automatic mode switching")
		-- LVS Input Mode
		local lvsInputMode = vehicleTab:Add("DCheckBoxLabel")
		lvsInputMode:SetPos(20, 120)
		lvsInputMode:SetText("LVS Networked Mode (1 = multiplayer, 0 = singleplayer)")
		lvsInputMode:SetConVar("vrmod_lvs_input_mode")
		lvsInputMode:SizeToContents()
		-- LFS/SimfPhys Mode Buttons
		local lfsModeBtn = vgui.Create("DButton", vehicleTab)
		lfsModeBtn:SetText("LFS Mode")
		lfsModeBtn:SetPos(20, 160)
		lfsModeBtn:SetSize(160, 30)
		lfsModeBtn.DoClick = function()
			RunConsoleCommand("vrmod_lfsmode")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Switched to LFS mode")
		end
		lfsModeBtn:SetTooltip("Switch reticle mode for LFS addon")
		local simfModeBtn = vgui.Create("DButton", vehicleTab)
		simfModeBtn:SetText("SimfPhys Mode")
		simfModeBtn:SetPos(190, 160)
		simfModeBtn:SetSize(160, 30)
		simfModeBtn.DoClick = function()
			RunConsoleCommand("vrmod_simfmode")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Switched to SimfPhys mode")
		end
		simfModeBtn:SetTooltip("Switch reticle mode for SimfPhys addon")
		-- Auto Seat Reset
		local autoSeatReset = vehicleTab:Add("DCheckBoxLabel")
		autoSeatReset:SetPos(20, 210)
		autoSeatReset:SetText("[Auto Seat Reset] Disable seat mode when entering vehicle")
		autoSeatReset:SetConVar("vrmod_auto_seat_reset")
		autoSeatReset:SizeToContents()
		-- Reset Vehicle Settings Button
		local resetVehicleBtn = vgui.Create("DButton", vehicleTab)
		resetVehicleBtn:SetText("Reset Vehicle Settings")
		resetVehicleBtn:SetPos(20, 240)
		resetVehicleBtn:SetSize(330, 30)
		resetVehicleBtn.DoClick = function()
			VRModResetCategory("vehicle")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Vehicle settings reset to defaults")
		end
		registerPanel("vehicle", vehicleTab)
		AddTreeNode(tree, "Vehicle", "vehicle", "icon16/car.png", showPanel)
		end -- Vehicle panel

		-- ========================================
		-- Panel: Utility
		-- ========================================
		do
		local utilityPanel = CreateUtilityPanel()
		registerPanel("utility", utilityPanel)
		AddTreeNode(tree, "Utility", "utility", "icon16/wrench.png", showPanel)
		end -- Utility panel

		-- ========================================
		-- Panel: Cardboard
		-- ========================================
		do
		local cardboardPanel = CreateCardboardPanel()
		registerPanel("cardboard", cardboardPanel)
		AddTreeNode(tree, "Cardboard", "cardboard", "icon16/phone.png", showPanel)
		end -- Cardboard panel

		-- ========================================
		-- Panel: Modules (Feature Loading Control)
		-- ========================================
		do
		local modulesScroll = vgui.Create("DScrollPanel")

		-- フォルダ番号 → 表示名
		local folderNames = {
			["2"]  = "Holster Type2",
			["3"]  = "Foregrip",
			["4"]  = "Magbone/ARC9",
			["5"]  = "Melee",
			["6"]  = "Holster Type1",
			["7"]  = "VR Hand HUD",
			["8"]  = "Physgun",
			["9"]  = "VR Pickup",
			["10"] = "Debug",
			["11"] = "(Reserved)",
			["12"] = "Guide",
			["13"] = "RealMech",
			["14"] = "Throw",
		}

		-- Addon-only ConVarが存在すればフォルダ0/1もリストに含める
		if GetConVar("vrmod_unoff_load_0") then
			folderNames["0"] = "Core/API"
		end
		if GetConVar("vrmod_unoff_load_1") then
			folderNames["1"] = "Auto-settings/Optimize"
		end

		-- ソート用キー
		local sortedFolders = {}
		for k in pairs(folderNames) do sortedFolders[#sortedFolders + 1] = k end
		table.sort(sortedFolders, function(a, b) return tonumber(a) < tonumber(b) end)

		-- 再起動警告
		local restartWarning = vgui.Create("DLabel", modulesScroll)
		restartWarning:Dock(TOP)
		restartWarning:DockMargin(10, 8, 10, 4)
		restartWarning:SetText("Changes require Gmod restart to take effect.")
		restartWarning:SetFont("DermaDefaultBold")
		restartWarning:SetTextColor(Color(255, 80, 80))
		restartWarning:SetAutoStretchVertical(true)

		-- === Addon-Only Mode セクション ===
		local addonOnlySectionLabel = vgui.Create("DLabel", modulesScroll)
		addonOnlySectionLabel:Dock(TOP)
		addonOnlySectionLabel:DockMargin(10, 10, 10, 2)
		addonOnlySectionLabel:SetText("=== Addon-Only Mode ===")
		addonOnlySectionLabel:SetFont("DermaDefaultBold")
		addonOnlySectionLabel:SizeToContents()

		local addonOnlyCheck = vgui.Create("DCheckBoxLabel", modulesScroll)
		addonOnlyCheck:Dock(TOP)
		addonOnlyCheck:DockMargin(10, 4, 10, 2)
		addonOnlyCheck:SetText("Addon-Only Mode (skip root files, use external VRMod)")
		addonOnlyCheck:SetConVar("vrmod_unoff_addon_only_mode")
		addonOnlyCheck:SizeToContents()

		local addonOnlyDesc = vgui.Create("DLabel", modulesScroll)
		addonOnlyDesc:Dock(TOP)
		addonOnlyDesc:DockMargin(20, 0, 10, 8)
		addonOnlyDesc:SetText("ON = Root files (vrmod.lua, input, character, etc.) are not loaded.\nUse this with legacy/original VRMod as your base VRMod.\nOnly numbered folder modules are loaded as add-on features.")
		addonOnlyDesc:SetAutoStretchVertical(true)
		addonOnlyDesc:SetWrap(true)
		addonOnlyDesc:SetTextColor(Color(180, 180, 180))

		-- === Legacy Mode セクション ===
		local legacySectionLabel = vgui.Create("DLabel", modulesScroll)
		legacySectionLabel:Dock(TOP)
		legacySectionLabel:DockMargin(10, 10, 10, 2)
		legacySectionLabel:SetText("=== Legacy Mode ===")
		legacySectionLabel:SetFont("DermaDefaultBold")
		legacySectionLabel:SizeToContents()

		local legacyCheck = vgui.Create("DCheckBoxLabel", modulesScroll)
		legacyCheck:Dock(TOP)
		legacyCheck:DockMargin(10, 4, 10, 2)
		legacyCheck:SetText("Legacy Mode (load only core features)")
		legacyCheck:SetConVar("vrmod_unoff_legacy_mode")
		legacyCheck:SizeToContents()

		local legacyDesc = vgui.Create("DLabel", modulesScroll)
		legacyDesc:Dock(TOP)
		legacyDesc:DockMargin(20, 0, 10, 8)
		legacyDesc:SetText("ON = only folders 0 (Core) and 1 (Auto-settings) load.\nAll features below are disabled regardless of their individual setting.")
		legacyDesc:SetAutoStretchVertical(true)
		legacyDesc:SetWrap(true)
		legacyDesc:SetTextColor(Color(180, 180, 180))

		-- === Feature Modules セクション ===
		local featureSectionLabel = vgui.Create("DLabel", modulesScroll)
		featureSectionLabel:Dock(TOP)
		featureSectionLabel:DockMargin(10, 6, 10, 2)
		featureSectionLabel:SetText("=== Feature Modules ===")
		featureSectionLabel:SetFont("DermaDefaultBold")
		featureSectionLabel:SizeToContents()

		local folderCheckboxes = {}

		for _, k in ipairs(sortedFolders) do
			local cb = vgui.Create("DCheckBoxLabel", modulesScroll)
			cb:Dock(TOP)
			cb:DockMargin(10, 3, 10, 0)
			cb:SetText("[" .. k .. "] " .. folderNames[k])
			cb:SetConVar("vrmod_unoff_load_" .. k)
			cb:SizeToContents()
			folderCheckboxes[#folderCheckboxes + 1] = cb
		end

		-- Addon-Only / Legacy 排他制御 + チェックボックス有効/無効切り替え
		local function updateFolderCheckboxStates()
			local legacyCV = GetConVar("vrmod_unoff_legacy_mode")
			local addonOnlyCV = GetConVar("vrmod_unoff_addon_only_mode")
			local isLegacy = legacyCV and legacyCV:GetBool() or false
			local isAddonOnly = addonOnlyCV and addonOnlyCV:GetBool() or false

			-- 排他: Addon-Only ON → Legacy チェックボックス無効化
			legacyCheck:SetEnabled(not isAddonOnly)
			if isAddonOnly then
				legacyCheck:SetTextColor(Color(120, 120, 120))
			else
				legacyCheck:SetTextColor(Color(255, 255, 255))
			end

			-- 排他: Legacy ON → Addon-Only チェックボックス無効化
			addonOnlyCheck:SetEnabled(not isLegacy)
			if isLegacy then
				addonOnlyCheck:SetTextColor(Color(120, 120, 120))
			else
				addonOnlyCheck:SetTextColor(Color(255, 255, 255))
			end

			-- フォルダチェックボックス
			for _, cb in ipairs(folderCheckboxes) do
				if isLegacy then
					cb:SetEnabled(false)
					cb:SetTextColor(Color(120, 120, 120))
				else
					cb:SetEnabled(true)
					cb:SetTextColor(Color(255, 255, 255))
				end
			end
		end

		-- チェックボックスの変更を監視
		legacyCheck.OnChange = function(self, val)
			updateFolderCheckboxStates()
		end
		addonOnlyCheck.OnChange = function(self, val)
			updateFolderCheckboxStates()
		end

		-- パネル表示時に状態を同期
		modulesScroll.OnShow = function(self)
			updateFolderCheckboxStates()
		end

		-- 初回状態同期（timer.Simple(0)でConVar読み込み後に実行）
		timer.Simple(0, function()
			if IsValid(modulesScroll) then
				updateFolderCheckboxStates()
			end
		end)

		registerPanel("modules", modulesScroll)
		AddTreeNode(tree, "Modules", "modules", "icon16/bricks.png", showPanel)
		end -- Modules panel

		-- Show first panel (VR) by default
		showPanel("vr")
		tree:SetSelectedItem(vrNode)

		-- Deferred module extraction: after all hooks run, extract hidden sheet tabs into DTree
		timer.Simple(0, function()
			if not IsValid(tree) then return end
			ExtractSheet(frame.VRplaySheet, tree, showPanel, registerPanel)
			ExtractSheet(frame.pickupSheet, tree, showPanel, registerPanel)
			ExtractSheet(frame.nonVRGunSheet, tree, showPanel, registerPanel)
			ExtractSheet(frame.hudSheet, tree, showPanel, registerPanel)
			ExtractSheet(frame.debugSheet, tree, showPanel, registerPanel)
			ExtractSheet(frame.quickmenuBtnSheet, tree, showPanel, registerPanel)
			ExtractSheet(frame.Settings02Sheet, tree, showPanel, registerPanel)
		end)
	end
)
