-- --------[vrmod_unoff_addmenu.lua]Start--------
-- DTree Navigation System (2026-03-15)
if SERVER then return end
local L = VRModL or function(_, fb) return fb or "" end
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
-- ExtractSheet removed (S32: modules now use frame.DPropertySheet directly)

-- Helper: Creates Utility panel (standalone, returns panel)
local function CreateUtilityPanel()
	local scrollPanel = vgui.Create("DScrollPanel")
	local utilityTab = vgui.Create("DPanel", scrollPanel)
	utilityTab:Dock(TOP)
	utilityTab:SetTall(270)
	utilityTab.Paint = function(self, w, h) end
	-- Screen & VGUI Section
	local screenLabel = vgui.Create("DLabel", utilityTab)
	screenLabel:SetPos(20, 10)
	screenLabel:SetText(L("=== Screen & VGUI ===", "=== Screen & VGUI ==="))
	screenLabel:SetFont("DermaDefaultBold")
	screenLabel:SizeToContents()
	local scrAutoBtn = vgui.Create("DButton", utilityTab)
	scrAutoBtn:SetText(L("Auto-Detect Screen Resolution", "Auto-Detect Screen Resolution"))
	scrAutoBtn:SetPos(20, 35)
	scrAutoBtn:SetSize(165, 25)
	scrAutoBtn.DoClick = function()
		RunConsoleCommand("vrmod_Scr_Auto")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Screen resolution auto-detected!", "Screen resolution auto-detected!"))
	end
	local vguiResetBtn = vgui.Create("DButton", utilityTab)
	vguiResetBtn:SetText(L("Reset VGUI Panels", "Reset VGUI Panels"))
	vguiResetBtn:SetPos(195, 35)
	vguiResetBtn:SetSize(155, 25)
	vguiResetBtn.DoClick = function()
		RunConsoleCommand("vrmod_vgui_reset")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("VGUI panels reset", "VGUI panels reset"))
	end

	-- Config Data Generation Section
	local configLabel = vgui.Create("DLabel", utilityTab)
	configLabel:SetPos(20, 70)
	configLabel:SetText(L("=== VR Config Data Generation ===", "=== VR Config Data Generation ==="))
	configLabel:SetFont("DermaDefaultBold")
	configLabel:SizeToContents()

	local generateConfigBtn = vgui.Create("DButton", utilityTab)
	generateConfigBtn:SetText(L("Generate VR Config Data", "Generate VR Config Data"))
	generateConfigBtn:SetPos(20, 95)
	generateConfigBtn:SetSize(330, 30)
	generateConfigBtn.DoClick = function()
		RunConsoleCommand("vrmod_data_vmt_generate_test")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("VR config data generated! (VMT files converted)", "VR config data generated! (VMT files converted)"))
	end

	local autoGenerateCheckbox = utilityTab:Add("DCheckBoxLabel")
	autoGenerateCheckbox:SetPos(20, 130)
	autoGenerateCheckbox:SetText(L("Auto-generate on VR startup", "Auto-generate on VR startup"))
	autoGenerateCheckbox:SetConVar("vrmod_unoff_auto_generate_config")
	autoGenerateCheckbox:SizeToContents()

	-- Core VR Control Section
	local coreLabel = vgui.Create("DLabel", utilityTab)
	coreLabel:SetPos(20, 160)
	coreLabel:SetText(L("=== Core VR Control ===", "=== Core VR Control ==="))
	coreLabel:SetFont("DermaDefaultBold")
	coreLabel:SizeToContents()
	local startVRBtn = vgui.Create("DButton", utilityTab)
	startVRBtn:SetText(L("Start VR", "Start VR"))
	startVRBtn:SetPos(20, 185)
	startVRBtn:SetSize(80, 25)
	startVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_start")
	end
	local exitVRBtn = vgui.Create("DButton", utilityTab)
	exitVRBtn:SetText(L("Exit VR", "Exit VR"))
	exitVRBtn:SetPos(110, 185)
	exitVRBtn:SetSize(80, 25)
	exitVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_exit")
	end
	local resetVRBtn = vgui.Create("DButton", utilityTab)
	resetVRBtn:SetText(L("Reset All Settings", "Reset All Settings"))
	resetVRBtn:SetPos(200, 185)
	resetVRBtn:SetSize(150, 25)
	resetVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_reset")
		chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), L("All VR settings reset!", "All VR settings reset!"))
	end
	local infoVRBtn = vgui.Create("DButton", utilityTab)
	infoVRBtn:SetText(L("Print VR Info", "Print VR Info"))
	infoVRBtn:SetPos(20, 215)
	infoVRBtn:SetSize(165, 25)
	infoVRBtn.DoClick = function()
		RunConsoleCommand("vrmod_info")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("VR info printed to console", "VR info printed to console"))
	end
	local luaResetBtn = vgui.Create("DButton", utilityTab)
	luaResetBtn:SetText(L("Reset Lua Modules", "Reset Lua Modules"))
	luaResetBtn:SetPos(195, 215)
	luaResetBtn:SetSize(155, 25)
	luaResetBtn.DoClick = function()
		RunConsoleCommand("vrmod_lua_reset")
		chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), L("Lua modules reset", "Lua modules reset"))
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
	cardboardLabel:SetText(L("=== Cardboard VR Settings ===", "=== Cardboard VR Settings ==="))
	cardboardLabel:SetFont("DermaDefaultBold")
	cardboardLabel:SizeToContents()

	-- Cardboard Scale Slider
	local cardboardScale = vgui.Create("DNumSlider", cardboardTab)
	cardboardScale:SetPos(20, 35)
	cardboardScale:SetSize(330, 25)
	cardboardScale:SetText(L("Cardboard Scale", "Cardboard Scale"))
	cardboardScale:SetMin(1)
	cardboardScale:SetMax(100)
	cardboardScale:SetDecimals(2)
	cardboardScale:SetConVar("cardboardmod_scale")

	-- Cardboard Sensitivity Slider
	local cardboardSens = vgui.Create("DNumSlider", cardboardTab)
	cardboardSens:SetPos(20, 65)
	cardboardSens:SetSize(330, 25)
	cardboardSens:SetText(L("Cardboard Sensitivity", "Cardboard Sensitivity"))
	cardboardSens:SetMin(0.001)
	cardboardSens:SetMax(0.1)
	cardboardSens:SetDecimals(3)
	cardboardSens:SetConVar("cardboardmod_sensitivity")

	-- Info Label
	local cardboardInfo = vgui.Create("DLabel", cardboardTab)
	cardboardInfo:SetPos(20, 95)
	cardboardInfo:SetText(L("Alternative VR mode using phone sensors (no HMD required)", "Alternative VR mode using phone sensors (no HMD required)"))
	cardboardInfo:SetWrap(true)
	cardboardInfo:SetSize(330, 40)
	cardboardInfo:SetAutoStretchVertical(true)

	-- Commands Label
	local cardboardCmdLabel = vgui.Create("DLabel", cardboardTab)
	cardboardCmdLabel:SetPos(20, 145)
	cardboardCmdLabel:SetText(L("=== Cardboard Commands ===", "=== Cardboard Commands ==="))
	cardboardCmdLabel:SetFont("DermaDefaultBold")
	cardboardCmdLabel:SizeToContents()

	-- Start Cardboard Button
	local cardboardStartBtn = vgui.Create("DButton", cardboardTab)
	cardboardStartBtn:SetText(L("Start Cardboard VR Mode", "Start Cardboard VR Mode"))
	cardboardStartBtn:SetPos(20, 170)
	cardboardStartBtn:SetSize(165, 30)
	cardboardStartBtn.DoClick = function()
		RunConsoleCommand("cardboardmod_start")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Cardboard VR mode started", "Cardboard VR mode started"))
	end

	-- Exit Cardboard Button
	local cardboardExitBtn = vgui.Create("DButton", cardboardTab)
	cardboardExitBtn:SetText(L("Exit Cardboard VR Mode", "Exit Cardboard VR Mode"))
	cardboardExitBtn:SetPos(195, 170)
	cardboardExitBtn:SetSize(155, 30)
	cardboardExitBtn.DoClick = function()
		RunConsoleCommand("cardboardmod_exit")
		chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Cardboard VR mode exited", "Cardboard VR mode exited"))
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
		frame.DPropertySheet:AddSheet(L("Settings02", "Settings02"), settings02)
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
		modeBtn:SetVisible(false) -- Guide View disabled — guide system disabled

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
				modeBtn:SetText(L("<< Tree View", "<< Tree View"))
				if not guideBuilt and vrmod.guide and vrmod.guide.CreateEmbedded then
					vrmod.guide.CreateEmbedded(guideContainer)
					guideBuilt = true
				end
			else
				modeBtn:SetText(L(">> Guide View", ">> Guide View"))
			end
			guidemode02:SetBool(isGuide)
		end
		modeBtn.DoClick = function()
			setGuideMode(treeContainer:IsVisible())
		end
		setGuideMode(guidemode02:GetBool())

		-- DTree + content area (inside treeContainer)
		local tree, contentContainer, showPanel, registerPanel = CreateTreeTab(treeContainer)

		-- Module hidden sheets removed (S32: modules are now individual addons using frame.DPropertySheet directly)

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
		jumpduck:SetText(L("[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP", "[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP"))
		jumpduck:SetConVar("vrmod_autojumpduck")
		AddControl(jumpduck)
		local teleport = vgui.Create("DCheckBoxLabel", gameplaySettings)
		teleport:SetText(L("[Teleport Enable]", "[Teleport Enable]"))
		teleport:SetConVar("vrmod_allow_teleport_client")
		AddControl(teleport)
		local tphand = vgui.Create("DNumSlider", gameplaySettings)
		tphand:SetText(L("[Teleport Hand]\n0 = Left Hand  1 = Right Hand  2 = Head", "[Teleport Hand]\n0 = Left Hand  1 = Right Hand  2 = Head"))
		tphand:SetMin(0)
		tphand:SetMax(2)
		tphand:SetDecimals(0)
		tphand:SetConVar("vrmod_unoff_teleport_hand")
		tphand:SetTooltip("Select which source is used to aim the teleport beam.\n0 = Left Hand, 1 = Right Hand, 2 = Head (HMD)")
		AddControl(tphand)
		local flashlightattach = vgui.Create("DNumSlider", gameplaySettings)
		flashlightattach:SetText(L("[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD", "[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD"))
		flashlightattach:SetMin(0)
		flashlightattach:SetMax(2)
		flashlightattach:SetDecimals(0)
		flashlightattach:SetConVar("vrmod_flashlight_attachment")
		flashlightattach:SetTooltip("0 = Right Hand, 1 = Left Hand, 2 = HMD")
		AddControl(flashlightattach)
		local laserpointer = vgui.Create("DButton", gameplaySettings)
		laserpointer:SetText(L("Toggle Laser Pointer", "Toggle Laser Pointer"))
		laserpointer.DoClick = function()
			RunConsoleCommand("vrmod_togglelaserpointer")
		end
		AddControl(laserpointer)
		local weaponconfig = vgui.Create("DButton", gameplaySettings)
		weaponconfig:SetText(L("Weapon Viewmodel Setting", "Weapon Viewmodel Setting"))
		weaponconfig.DoClick = function()
			RunConsoleCommand("vrmod_weaponconfig")
		end
		AddControl(weaponconfig)
		local muzzleboneBtn = vgui.Create("DButton", gameplaySettings)
		muzzleboneBtn:SetText(L("Weapon Bone Config", "Weapon Bone Config"))
		muzzleboneBtn.DoClick = function()
			RunConsoleCommand("vrmod_weapon_bone_config")
		end
		AddControl(muzzleboneBtn)
		local pickupweight = vgui.Create("DNumSlider", gameplaySettings)
		pickupweight:SetText(L("Pickup Weight (Server)", "Pickup Weight (Server)"))
		pickupweight:SetMin(0)
		pickupweight:SetMax(1000)
		pickupweight:SetDecimals(0)
		pickupweight:SetConVar("vrmod_pickup_weight")
		AddControl(pickupweight)
		local pickuprange = vgui.Create("DNumSlider", gameplaySettings)
		pickuprange:SetText(L("Pickup Range (Server)", "Pickup Range (Server)"))
		pickuprange:SetMin(0)
		pickuprange:SetMax(5)
		pickuprange:SetDecimals(2)
		pickuprange:SetConVar("vrmod_pickup_range")
		AddControl(pickuprange)
		local pickuplimit = vgui.Create("DNumSlider", gameplaySettings)
		pickuplimit:SetText(L("Pickup Limit (Server)", "Pickup Limit (Server)"))
		pickuplimit:SetMin(0)
		pickuplimit:SetMax(3)
		pickuplimit:SetDecimals(0)
		pickuplimit:SetConVar("vrmod_pickup_limit")
		AddControl(pickuplimit)
			local manualpickups = vgui.Create("DCheckBoxLabel", gameplaySettings)
			manualpickups:SetText(L("Manual Pickup (by Hugo)", "Manual Pickup (by Hugo)"))
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
		vrNode = AddTreeNode(tree, L("VR", "VR"), "vr", "icon16/basket.png", showPanel)
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
		scaleDefaultButton:SetText(L("Default", "Default"))
		scaleDefaultButton:SetWidth(60)
		scaleDefaultButton.DoClick = function()
			g_VR.scale = VRMOD_DEFAULTS.character.vrmod_scale
			convars.vrmod_scale:SetFloat(g_VR.scale)
		end
		local eyeheight = vgui.Create("DNumSlider", vrSettings)
		eyeheight:SetText(L("Character Eye Height", "Character Eye Height"))
		eyeheight:SetMin(0)
		eyeheight:SetMax(100)
		eyeheight:SetDecimals(2)
		eyeheight:SetConVar("vrmod_characterEyeHeight")
		AddControl(eyeheight)
		local crouchthreshold = vgui.Create("DNumSlider", vrSettings)
		crouchthreshold:SetText(L("Crouch Threshold", "Crouch Threshold"))
		crouchthreshold:SetMin(0)
		crouchthreshold:SetMax(100)
		crouchthreshold:SetDecimals(2)
		crouchthreshold:SetConVar("vrmod_crouchthreshold")
		AddControl(crouchthreshold)
		local headtohmd = vgui.Create("DNumSlider", vrSettings)
		headtohmd:SetText(L("Character Head to HMD Distance", "Character Head to HMD Distance"))
		headtohmd:SetMin(-20)
		headtohmd:SetMax(20)
		headtohmd:SetDecimals(2)
		headtohmd:SetConVar("vrmod_characterHeadToHmdDist")
		AddControl(headtohmd)
		local znear = vgui.Create("DNumSlider", vrSettings)
		znear:SetText(L("Z Near", "Z Near"))
		znear:SetMin(0)
		znear:SetMax(20)
		znear:SetDecimals(2)
		znear:SetConVar("vrmod_znear")
		znear:SetTooltip("Objects closer than this will become transparent. Increase if you see parts of your head.")
		AddControl(znear)
		local seatedmode = vgui.Create("DCheckBoxLabel", vrSettings)
		seatedmode:SetText(L("Enable Seated Mode", "Enable Seated Mode"))
		seatedmode:SetConVar("vrmod_seated")
		AddControl(seatedmode)
		local seatedoffset = vgui.Create("DNumSlider", vrSettings)
		seatedoffset:SetText(L("Seated Offset", "Seated Offset"))
		seatedoffset:SetMin(-100)
		seatedoffset:SetMax(100)
		seatedoffset:SetDecimals(2)
		seatedoffset:SetConVar("vrmod_seatedoffset")
		AddControl(seatedoffset)
		local althead = vgui.Create("DCheckBoxLabel", vrSettings)
		althead:SetText(L("Alternative Character Yaw", "Alternative Character Yaw"))
		althead:SetConVar("vrmod_oldcharacteryaw")
		AddControl(althead)
		local animationenable = vgui.Create("DCheckBoxLabel", vrSettings)
		animationenable:SetText(L("Character Animation Enable (Client)", "Character Animation Enable (Client)"))
		animationenable:SetConVar("vrmod_animation_Enable")
		AddControl(animationenable)

		-- Head Hide Settings
		local hideHead = vgui.Create("DCheckBoxLabel", vrSettings)
		hideHead:SetText(L("Hide Head", "Hide Head"))
		hideHead:SetConVar("vrmod_hide_head")
		AddControl(hideHead)
		local hideHeadPosX = vgui.Create("DNumSlider", vrSettings)
		hideHeadPosX:SetText(L("Head Hide Position X", "Head Hide Position X"))
		hideHeadPosX:SetMin(-1000)
		hideHeadPosX:SetMax(1000)
		hideHeadPosX:SetDecimals(1)
		hideHeadPosX:SetConVar("vrmod_hide_head_pos_x")
		AddControl(hideHeadPosX)
		local hideHeadPosY = vgui.Create("DNumSlider", vrSettings)
		hideHeadPosY:SetText(L("Head Hide Position Y", "Head Hide Position Y"))
		hideHeadPosY:SetMin(-1000)
		hideHeadPosY:SetMax(1000)
		hideHeadPosY:SetDecimals(1)
		hideHeadPosY:SetConVar("vrmod_hide_head_pos_y")
		AddControl(hideHeadPosY)
		local hideHeadPosZ = vgui.Create("DNumSlider", vrSettings)
		hideHeadPosZ:SetText(L("Head Hide Position Z", "Head Hide Position Z"))
		hideHeadPosZ:SetMin(-1000)
		hideHeadPosZ:SetMax(1000)
		hideHeadPosZ:SetDecimals(1)
		hideHeadPosZ:SetConVar("vrmod_hide_head_pos_z")
		AddControl(hideHeadPosZ)

		-- Animation Settings
		local idleAct = vgui.Create("DTextEntry", vrSettings)
		idleAct:SetPlaceholderText(L("Idle Animation (default: ACT_HL2MP_IDLE)", "Idle Animation (default: ACT_HL2MP_IDLE)"))
		idleAct:SetConVar("vrmod_idle_act")
		AddControl(idleAct)
		local walkAct = vgui.Create("DTextEntry", vrSettings)
		walkAct:SetPlaceholderText(L("Walk Animation (default: ACT_HL2MP_WALK)", "Walk Animation (default: ACT_HL2MP_WALK)"))
		walkAct:SetConVar("vrmod_walk_act")
		AddControl(walkAct)
		local runAct = vgui.Create("DTextEntry", vrSettings)
		runAct:SetPlaceholderText(L("Run Animation (default: ACT_HL2MP_RUN)", "Run Animation (default: ACT_HL2MP_RUN)"))
		runAct:SetConVar("vrmod_run_act")
		AddControl(runAct)
		local jumpAct = vgui.Create("DTextEntry", vrSettings)
		jumpAct:SetPlaceholderText(L("Jump Animation (default: ACT_HL2MP_JUMP_PASSIVE)", "Jump Animation (default: ACT_HL2MP_JUMP_PASSIVE)"))
		jumpAct:SetConVar("vrmod_jump_act")
		AddControl(jumpAct)

		local lefthand = vgui.Create("DCheckBoxLabel", vrSettings)
		lefthand:SetText(L("Left Hand (WIP)", "Left Hand (WIP)"))
		lefthand:SetConVar("vrmod_LeftHand")
		AddControl(lefthand)
		local lefthandfire = vgui.Create("DCheckBoxLabel", vrSettings)
		lefthandfire:SetText(L("Left Hand Fire (WIP)", "Left Hand Fire (WIP)"))
		lefthandfire:SetConVar("vrmod_lefthandleftfire")
		AddControl(lefthandfire)
		local lefthandhold = vgui.Create("DCheckBoxLabel", vrSettings)
		lefthandhold:SetText(L("Left Hand Hold Mode (WIP)", "Left Hand Hold Mode (WIP)"))
		lefthandhold:SetConVar("vrmod_LeftHandmode")
		AddControl(lefthandhold)
		local togglemirror = vgui.Create("DButton", vrSettings)
		togglemirror:SetText(L("Toggle Mirror", "Toggle Mirror"))
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
		applybutton:SetText(L("Apply VR Settings (Requires VRMod Restart)", "Apply VR Settings (Requires VRMod Restart)"))
		applybutton.DoClick = function()
			RunConsoleCommand("vrmod_restart")
		end
		AddControl(applybutton)
		local autoadjust = vgui.Create("DButton", vrSettings)
		autoadjust:SetText(L("Auto Adjust VR Settings (Requires VRMod Restart)", "Auto Adjust VR Settings (Requires VRMod Restart)"))
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
		AddTreeNode(tree, L("Character", "Character"), "character", "icon16/user.png", showPanel)
		end -- Character panel

		-- ========================================
		-- Panel: UI
		-- ========================================
		do
		local uiScrollPanel = vgui.Create("DScrollPanel")
		local uiSettings = vgui.Create("DForm", uiScrollPanel)
		uiSettings:Dock(TOP)
		uiSettings:DockPadding(0, 0, 0, 0)
		local hudenable = uiSettings:CheckBox(L("HUD Enable", "HUD Enable"))
		hudenable:SetConVar("vrmod_hud")
		local hudcurve = uiSettings:NumSlider(L("HUD Curve", "HUD Curve"), "vrmod_hudcurve", 1, 100, 0)
		local huddistance = uiSettings:NumSlider(L("HUD Distance", "HUD Distance"), "vrmod_huddistance", 1, 200, 0)
		local hudscale = uiSettings:NumSlider(L("HUD Scale", "HUD Scale"), "vrmod_hudscale", 0.01, 0.20, 2)
		local hudalpha = uiSettings:NumSlider(L("HUD Alpha", "HUD Alpha"), "vrmod_hudtestalpha", 0, 255, 0)
		local hudonlykey = uiSettings:CheckBox(L("HUD Only While Pressing Menu Key", "HUD Only While Pressing Menu Key"))
		hudonlykey:SetConVar("vrmod_hud_visible_quickmenukey")
		local quickmenuattach = uiSettings:ComboBox(L("Quickmenu Attach Position", "Quickmenu Attach Position"), "vrmod_attach_quickmenu")
		quickmenuattach:AddChoice(L("Left Hand", "Left Hand"), "1")
		quickmenuattach:AddChoice(L("Right Hand", "Right Hand"), "4")
		quickmenuattach:AddChoice(L("HMD", "HMD"), "3")
		local weaponmenuattach = uiSettings:ComboBox(L("Weapon Menu Attach Position", "Weapon Menu Attach Position"), "vrmod_attach_weaponmenu")
		weaponmenuattach:AddChoice(L("Left Hand", "Left Hand"), "1")
		weaponmenuattach:AddChoice(L("Right Hand", "Right Hand"), "4")
		weaponmenuattach:AddChoice(L("HMD", "HMD"), "3")
		local popupattach = uiSettings:ComboBox(L("Popup Window Attach Position", "Popup Window Attach Position"), "vrmod_attach_popup")
		popupattach:AddChoice(L("Left Hand", "Left Hand"), "1")
		popupattach:AddChoice(L("Right Hand", "Right Hand"), "4")
		popupattach:AddChoice(L("HMD", "HMD"), "3")
		local menuoutline = uiSettings:CheckBox(L("Menu & UI Red Outline", "Menu & UI Red Outline"))
		menuoutline:SetConVar("vrmod_ui_outline")
		local uirender = uiSettings:CheckBox(L("UI Render Alternative", "UI Render Alternative"))
		uirender:SetConVar("vrmod_ui_realtime")
		local cameraoverride = uiSettings:CheckBox(L("Desktop 3rd Person Camera", "Desktop 3rd Person Camera"))
		cameraoverride:SetTooltip("ON: Desktop shows 3rd person camera view. OFF: Desktop shows VR HMD perspective.")
		cameraoverride:SetConVar("vrmod_cameraoverride")
		local keyboarduichat = uiSettings:CheckBox(L("Keyboard UI Chat Key", "Keyboard UI Chat Key"))
		keyboarduichat:SetConVar("vrmod_keyboard_uichatkey")
		local VRElefthand = uiSettings:CheckBox(L("VRE Attach Left Hands", "VRE Attach Left Hands"))
		VRElefthand:SetConVar("vre_ui_attachtohand")
		local desktopUIMirror = uiSettings:CheckBox(L("Show VR UI on Desktop Window", "Show VR UI on Desktop Window"))
		desktopUIMirror:SetConVar("vrmod_unoff_desktop_ui_mirror")
		desktopUIMirror:SetTooltip("Keep menus and popups visible on the desktop window while in VR")
		local uidefault = uiSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		uidefault.DoClick = function()
			VRModResetCategory("ui")
		end

		-- VR Keyboard Button
		local keyboardButton = uiSettings:Button(L("Toggle VR Keyboard", "Toggle VR Keyboard"))
		keyboardButton.DoClick = function()
			RunConsoleCommand("vrmod_keyboard")
		end
		uiSettings:Help(L("Show/hide the virtual keyboard for text input in VR", "Show/hide the virtual keyboard for text input in VR"))

		-- Action Editor Button
		local actionEditorButton = uiSettings:Button(L("Open Action Editor", "Open Action Editor"))
		actionEditorButton.DoClick = function()
			RunConsoleCommand("vrmod_actioneditor")
		end
		uiSettings:Help(L("Configure VR controller bindings (Note: Disabled while VR is active)", "Configure VR controller bindings (Note: Disabled while VR is active)"))

		-- Screen Resolution Settings (from old menu GameRebootRequied)
		local screenResCategory = uiSettings:Help(L("=== Screen Resolution Settings ===", "=== Screen Resolution Settings ==="))
		screenResCategory:SetFont("DermaDefaultBold")

		uiSettings:Help(L("WARNING: Changing these settings requires VR restart to take effect", "WARNING: Changing these settings requires VR restart to take effect"))

		uiSettings:NumSlider(L("VR UI Height", "VR UI Height"), "vrmod_ScrH", 480, ScrH() * 2, 0)
		uiSettings:NumSlider(L("VR UI Width", "VR UI Width"), "vrmod_ScrW", 640, ScrW() * 2, 0)
		uiSettings:NumSlider(L("VR HUD Height", "VR HUD Height"), "vrmod_ScrH_hud", 480, ScrH() * 2, 0)
		uiSettings:NumSlider(L("VR HUD Width", "VR HUD Width"), "vrmod_ScrW_hud", 640, ScrW() * 2, 0)

		local scrAutoCheckbox = uiSettings:CheckBox(L("Always Auto-Detect Resolution on VR Start", "Always Auto-Detect Resolution on VR Start"))
		scrAutoCheckbox:SetConVar("vrmod_scr_alwaysautosetting")
		uiSettings:Help(L("Automatically detect and set optimal screen resolution when entering VR", "Automatically detect and set optimal screen resolution when entering VR"))

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
		AddTreeNode(tree, L("UI", "UI"), "ui", "icon16/photos.png", showPanel)
		end -- UI panel
		-- ========================================
		-- Panel: Optimize
		-- ========================================
		do
		local graphicsScrollPanel = vgui.Create("DScrollPanel")
		local graphicsSettings = vgui.Create("DForm", graphicsScrollPanel)
		graphicsSettings:Dock(TOP)
		graphicsSettings:DockPadding(0, 0, 0, 0)
		local skybox = graphicsSettings:CheckBox(L("Skybox Enable (Client)", "Skybox Enable (Client)"))
		skybox:SetConVar("r_3dsky")
		local shadows = graphicsSettings:CheckBox(L("Shadows & Flashlights Effect Enable (Client)", "Shadows & Flashlights Effect Enable (Client)"))
		shadows:SetConVar("r_shadows")
		local farz = graphicsSettings:NumSlider(L("Visible Range of Map", "Visible Range of Map"), "r_farz", 0, 16384, 0)
		farz:SetTooltip("sv_cheats 1 is required")
		local optimizationLevel = graphicsSettings:NumSlider(L("VRMod Optimization Level", "VRMod Optimization Level"), "vrmod_gmod_optimization", 0, 4, 0)
		optimizationLevel:SetTooltip("0: No optimization\n1: No changes from VRMod\n2: Reset (disable optimizations)\n3: Optimization ON (VR safe)\n4: Max optimization (Eye Flash WARNING)")
		local optimizationDescription = graphicsSettings:Help(L("Optimization Levels:\n0: No optimization applied\n1: No changes - VRMod does not modify any ConVars\n2: Reset - Restores water reflections, disables mirror optimization\n3: Optimization ON - Water/mirrors/specular OFF, gmod_mcore_test 0 (VR safe)\n4: Max optimization - All of Lv3 + gmod_mcore_test 1 (!!Right eye flash WARNING!!)", "Optimization Levels:\n0: No optimization applied\n1: No changes - VRMod does not modify any ConVars\n2: Reset - Restores water reflections, disables mirror optimization\n3: Optimization ON - Water/mirrors/specular OFF, gmod_mcore_test 0 (VR safe)\n4: Max optimization - All of Lv3 + gmod_mcore_test 1 (!!Right eye flash WARNING!!)"))
		optimizationDescription:SetAutoStretchVertical(true)

		-- Apply Optimization Button
		local applyOptButton = graphicsSettings:Button(L("Apply Optimization Now", "Apply Optimization Now"))
		applyOptButton.DoClick = function()
			RunConsoleCommand("vrmod_apply_optimization")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Optimization applied!", "Optimization applied!"))
		end
		graphicsSettings:Help(L("Manually trigger optimization based on current vrmod_gmod_optimization level", "Manually trigger optimization based on current vrmod_gmod_optimization level"))

		-- Mirror/Reflection Management
		local mirrorCategory = graphicsSettings:Help(L("=== Mirror & Reflection Management ===", "=== Mirror & Reflection Management ==="))
		mirrorCategory:SetFont("DermaDefaultBold")

		local removeGlassBtn = graphicsSettings:Button(L("Remove All Reflective Glass from Map", "Remove All Reflective Glass from Map"))
		removeGlassBtn.DoClick = function()
			RunConsoleCommand("remove_reflective_glass")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), L("All reflective glass removed from map", "All reflective glass removed from map"))
		end
		graphicsSettings:Help(L("Forcibly removes all reflective surfaces from the map (may cause visual glitches)", "Forcibly removes all reflective surfaces from the map (may cause visual glitches)"))

		-- Render Target Settings (from old menu Misc03)
		local renderTargetCategory = graphicsSettings:Help(L("=== Render Target Settings ===", "=== Render Target Settings ==="))
		renderTargetCategory:SetFont("DermaDefaultBold")

		graphicsSettings:NumSlider(L("Render Target Width Multiplier", "Render Target Width Multiplier"), "vrmod_rtWidth_Multiplier", 0.1, 5.0, 1)
		graphicsSettings:NumSlider(L("Render Target Height Multiplier", "Render Target Height Multiplier"), "vrmod_rtHeight_Multiplier", 0.1, 5.0, 1)

		local resetRenderBtn = graphicsSettings:Button(L("Reset Render Targets", "Reset Render Targets"))
		resetRenderBtn.DoClick = function()
			RunConsoleCommand("vrmod_reset_render_targets")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), L("Render targets reset (VR will exit)", "Render targets reset (VR will exit)"))
		end
		graphicsSettings:Help(L("Reset VR render targets (VR mode will exit)", "Reset VR render targets (VR mode will exit)"))

		local updateRenderBtn = graphicsSettings:Button(L("Update Render Targets", "Update Render Targets"))
		updateRenderBtn.DoClick = function()
			RunConsoleCommand("vrmod_update_render_targets")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Render targets updated", "Render targets updated"))
		end
		graphicsSettings:Help(L("Update render targets with current multiplier settings", "Update render targets with current multiplier settings"))

		local quest2PresetBtn = graphicsSettings:Button(L("Apply Quest 2 + Virtual Desktop Preset", "Apply Quest 2 + Virtual Desktop Preset"))
		quest2PresetBtn.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.5")
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "1.2")
			RunConsoleCommand("vrmod_restart")
			chat.AddText(Color(255, 165, 0), "[VRMod] ", Color(255, 255, 255), L("Quest 2 preset applied, VR restarting...", "Quest 2 preset applied, VR restarting..."))
		end
		graphicsSettings:Help(L("Set optimal render target multipliers for Quest 2 + Virtual Desktop (VR will restart)", "Set optimal render target multipliers for Quest 2 + Virtual Desktop (VR will restart)"))

		local renderDefaultBtn = graphicsSettings:Button(L("Reset Render Target Multipliers to Default", "Reset Render Target Multipliers to Default"))
		renderDefaultBtn.DoClick = function()
			RunConsoleCommand("vrmod_rtWidth_Multiplier", "2.0")
			RunConsoleCommand("vrmod_rtHeight_Multiplier", "2.0")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Render target multipliers reset to default (2.0)", "Render target multipliers reset to default (2.0)"))
		end
		graphicsSettings:Help(L("Reset both multipliers to default value (2.0)", "Reset both multipliers to default value (2.0)"))

		registerPanel("optimize", graphicsScrollPanel)
		AddTreeNode(tree, L("Optimize", "Optimize"), "optimize", "icon16/picture.png", showPanel)
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
			defaultButton:SetText(L("Default", "Default"))
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
		applyButton:SetText(L("Apply", "Apply"))
		applyButton:SetHeight(30)
		applyButton.DoClick = function()
			for name, value in pairs(changedValues) do
				RunConsoleCommand(name, tostring(value))
			end
			changedValues = {}
		end
		registerPanel("optvr", MenuTab11)
		AddTreeNode(tree, L("Opt.VR", "Opt.VR"), "optvr", "icon16/cog_add.png", showPanel)
		end -- Opt.VR panel

		-- ========================================
		-- Panel: Opt.Gmod
		-- ========================================
		do
		local MenuTab12 = vgui.Create("DPanel")
		MenuTab12.Paint = function(self, w, h) end
		local scroll = vgui.Create("DScrollPanel", MenuTab12)
		scroll:Dock(FILL)
		local optimizeconvar2 = {{"r_shadowmaxrendered", 1, 32, "Maximum number of shadows rendered", 32}, {"r_flashlightdepthres", 1, 1024, "Flashlight shadow map resolution", 512}, {"mat_picmip", -10, 20, "Texture quality (lower is better)", 0}, {"r_lod", -1, 10, "Level of detail", 0}, {"r_rootlod", -1, 10, "Root level of detail", 0}, {"ai_expression_frametime", 0.1, 2, "AI expression update frequency", 0.5}, {"cl_detaildist", 1, 8000, "Distance at which details are visible", 1200}, {"mat_fastspecular", 0, 1, "Distance at which details are visible", 1}, {"mat_wateroverlaysize", 2, 1200, "Distance at which details are visible", 256}, {"r_drawdetailprops", 0, 2, "Draw detail props", 1}, {"mat_specular", 0, 1, "Specular reflections", 1}}
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
			defaultButton:SetText(L("Default", "Default"))
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
		applyButton:SetText(L("Apply", "Apply"))
		applyButton:SetHeight(30)
		applyButton.DoClick = function()
			for name, value in pairs(changedValues) do
				RunConsoleCommand(name, tostring(value))
			end
			changedValues = {}
		end
		registerPanel("optgmod", MenuTab12)
		AddTreeNode(tree, L("Opt.Gmod", "Opt.Gmod"), "optgmod", "icon16/cog_add.png", showPanel)
		end -- Opt.Gmod panel

		-- ========================================
		-- Panel: Quick Menu (DPropertySheet with Settings + Editor tabs)
		-- ========================================
		do
		local quickMenuSheet = vgui.Create("DPropertySheet")
		local quickMenuSettings = vgui.Create("DForm")
		quickMenuSettings:DockPadding(0, 0, 0, 0)
		local mapbrowser = quickMenuSettings:CheckBox(L("Map Browser", "Map Browser"))
		mapbrowser:SetConVar("vrmod_quickmenu_mapbrowser_enable")
		local vrexit = quickMenuSettings:CheckBox(L("VR Exit", "VR Exit"))
		vrexit:SetConVar("vrmod_quickmenu_exit")
		local uireset = quickMenuSettings:CheckBox(L("UI Reset", "UI Reset"))
		uireset:SetConVar("vrmod_quickmenu_vgui_reset_menu")
		local gbradial = quickMenuSettings:CheckBox(L("VRE GBRadial & Add Menu", "VRE GBRadial & Add Menu"))
		gbradial:SetConVar("vrmod_quickmenu_vre_gbradial_menu")
		local chat = quickMenuSettings:CheckBox(L("Chat", "Chat"))
		chat:SetConVar("vrmod_quickmenu_chat")
		local seatedmenu = quickMenuSettings:CheckBox(L("Seated Mode", "Seated Mode"))
		seatedmenu:SetConVar("vrmod_quickmenu_seated_menu")
		local mirrortoggle = quickMenuSettings:CheckBox(L("Toggle Mirror", "Toggle Mirror"))
		mirrortoggle:SetConVar("vrmod_quickmenu_togglemirror")
		local spawnmenu = quickMenuSettings:CheckBox(L("Spawn Menu", "Spawn Menu"))
		spawnmenu:SetConVar("vrmod_quickmenu_spawn_menu")
		local noclip = quickMenuSettings:CheckBox(L("No Clip", "No Clip"))
		noclip:SetConVar("vrmod_quickmenu_noclip")
		local contextmenu = quickMenuSettings:CheckBox(L("Context Menu", "Context Menu"))
		contextmenu:SetConVar("vrmod_quickmenu_context_menu")
		local arccw = quickMenuSettings:CheckBox(L("ArcCW Customize", "ArcCW Customize"))
		arccw:SetConVar("vrmod_quickmenu_arccw")
		local vehiclemode = quickMenuSettings:CheckBox(L("Toggle Vehicle Mode", "Toggle Vehicle Mode"))
		vehiclemode:SetConVar("vrmod_quickmenu_togglevehiclemode")
		local quickmenudefault = quickMenuSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		quickmenudefault.DoClick = function()
			VRModResetCategory("quickmenu")
		end
		quickMenuSheet:AddSheet(L("Settings", "Settings"), quickMenuSettings, "icon16/cog.png")
		frame.quickmenuBtnSheet = quickMenuSheet
		registerPanel("quickmenu", quickMenuSheet)
		AddTreeNode(tree, L("Quick Menu", "Quick Menu"), "quickmenu", "icon16/application_view_tile.png", showPanel)
		end -- Quick Menu panel

		-- ========================================
		-- Panel: VRStop Key
		-- ========================================
		do
		local stopScroll = vgui.Create("DScrollPanel")
		local stopForm = vgui.Create("DForm", stopScroll)
		stopForm:Dock(TOP)
		stopForm:DockMargin(5, 5, 5, 5)
		stopForm:SetName(L("Emergency Stop", "Emergency Stop"))
		stopForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		local binderLabel = stopForm:Help(L("Emergency Stop Key:", "Emergency Stop Key:"))
		local binderContainer = vgui.Create("DPanel")
		binderContainer:SetTall(25)
		binderContainer.Paint = function() end
		local emergStopKeyBinder = vgui.Create("DBinder", binderContainer)
		emergStopKeyBinder:Dock(FILL)
		emergStopKeyBinder:SetConVar("vrmod_emergencystop_key")
		stopForm:AddItem(binderContainer)
		stopForm:NumSlider(L("Hold Time (Seconds)", "Hold Time (Seconds)"), "vrmod_emergencystop_time", 0, 10, 2)

		local fpsForm = vgui.Create("DForm", stopScroll)
		fpsForm:Dock(TOP)
		fpsForm:DockMargin(5, 5, 5, 5)
		fpsForm:SetName(L("FPS Guard", "FPS Guard"))
		fpsForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		fpsForm:CheckBox(L("FPS Guard Enable", "FPS Guard Enable"), "vrmod_unoff_fps_guard")
		fpsForm:NumSlider(L("FPS Drop Threshold (ms)", "FPS Drop Threshold (ms)"), "vrmod_unoff_fps_guard_threshold_ms", 10, 200, 0)
		fpsForm:NumSlider(L("Retry Count", "Retry Count"), "vrmod_unoff_fps_guard_retry", 0, 10, 0)
		fpsForm:Help(L("Automatically stops VR when frame time exceeds threshold.", "Automatically stops VR when frame time exceeds threshold."))

		local emergFpsForm = vgui.Create("DForm", stopScroll)
		emergFpsForm:Dock(TOP)
		emergFpsForm:DockMargin(5, 5, 5, 5)
		emergFpsForm:SetName(L("Emergency FPS Stop", "Emergency FPS Stop"))
		emergFpsForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		emergFpsForm:CheckBox(L("Emergency FPS Enable", "Emergency FPS Enable"), "vrmod_unoff_emergency_fps_enabled")
		emergFpsForm:NumSlider(L("FPS Threshold", "FPS Threshold"), "vrmod_unoff_emergency_fps_threshold", 1, 30, 0)
		emergFpsForm:NumSlider(L("Duration (Seconds)", "Duration (Seconds)"), "vrmod_unoff_emergency_fps_duration", 0, 15, 1)
		emergFpsForm:Help(L("Stops VR if FPS stays below threshold for the specified duration.", "Stops VR if FPS stays below threshold for the specified duration."))

		registerPanel("vrstop", stopScroll)
		AddTreeNode(tree, L("VRStop Key", "VRStop Key"), "vrstop", "icon16/stop.png", showPanel)
		end -- VRStop Key panel

		-- ========================================
		-- Panel: Misc
		-- ========================================
		do
		local generalSettings = vgui.Create("DForm")
		generalSettings:DockPadding(0, 0, 0, 0)
		local showonstartup = generalSettings:CheckBox(L("VRMod Menu Show on Startup", "VRMod Menu Show on Startup"))
		showonstartup:SetConVar("vrmod_showonstartup")
		local errorcheck = generalSettings:CheckBox(L("Error Check Method", "Error Check Method"))
		errorcheck:SetConVar("vrmod_error_check_method")
		local errorlock = generalSettings:CheckBox(L("ModuleError VRMod Menu Lock", "ModuleError VRMod Menu Lock"))
		errorlock:SetConVar("vrmod_error_hard")
		local pmchange = generalSettings:CheckBox(L("Player Model Change (forPAC3)", "Player Model Change (forPAC3)"))
		pmchange:SetConVar("vrmod_pmchange")
		local vrdisablepickup = generalSettings:CheckBox(L("VR Disable Pickup (Client)", "VR Disable Pickup (Client)"))
		vrdisablepickup:SetConVar("vr_pickup_disable_client")
		local lvspickuphandle = generalSettings:CheckBox(L("Enable LVS Pickup Handle", "Enable LVS Pickup Handle"))
		lvspickuphandle:SetConVar("vrmod_lvs_input_mode")
		local vrmodmenutype = generalSettings:CheckBox(L("VRMod Menu Type", "VRMod Menu Type"))
		vrmodmenutype:SetConVar("vrmod_menu_type")

		-- Additional Misc Settings
		local quickmenuCustom = generalSettings:CheckBox(L("Use Custom QuickMenu", "Use Custom QuickMenu"))
		quickmenuCustom:SetConVar("vrmod_quickmenu_use_custom")
		local autoSeatReset = generalSettings:CheckBox(L("Auto Seat Reset", "Auto Seat Reset"))
		autoSeatReset:SetConVar("vrmod_auto_seat_reset")
		local sightBodypart = generalSettings:CheckBox(L("Sight Bodypart", "Sight Bodypart"))
		sightBodypart:SetConVar("vrmod_sight_bodypart")

		-- Developer Mode Toggle
		local devModeToggle = generalSettings:CheckBox(L("Enable Developer Mode (requires VRMod restart)", "Enable Developer Mode (requires VRMod restart)"))
		devModeToggle:SetConVar("vrmod_unoff_developer_mode")
		local devModeHelp = generalSettings:Help(L("Developer Mode enables advanced debug settings.\nToggle this and restart VRMod to apply changes.", "Developer Mode enables advanced debug settings.\nToggle this and restart VRMod to apply changes."))
		devModeHelp:SetTextColor(Color(255, 0, 0))

		-- Restore Defaults for Misc
		local miscDefault = generalSettings:Button(VRModL("btn_restore_defaults", "Restore Misc Defaults"))
		miscDefault.DoClick = function()
			VRModResetCategory("misc")
		end
		registerPanel("misc", generalSettings)
		AddTreeNode(tree, L("Misc", "Misc"), "misc", "icon16/cog.png", showPanel)
		end -- Misc panel

		-- ========================================
		-- Panel: Animation
		-- ========================================
		do
		local animationSettings = vgui.Create("DForm")
		animationSettings:DockPadding(0, 0, 0, 0)
		animationSettings:TextEntry(L("Idle Animation", "Idle Animation"), "vrmod_idle_act")
		animationSettings:TextEntry(L("Walk Animation", "Walk Animation"), "vrmod_walk_act")
		animationSettings:TextEntry(L("Run Animation", "Run Animation"), "vrmod_run_act")
		animationSettings:TextEntry(L("Jump Animation", "Jump Animation"), "vrmod_jump_act")
		local helpText = animationSettings:Help(L("Enter animation names (e.g., ACT_HL2MP_IDLE)", "Enter animation names (e.g., ACT_HL2MP_IDLE)"))
		helpText:DockMargin(0, 10, 0, 0)
		local defaultButton = vgui.Create("DButton", animationSettings)
		defaultButton:SetText(L("Reset to Default", "Reset to Default"))
		defaultButton:Dock(TOP)
		defaultButton:DockMargin(0, 10, 0, 0)
		defaultButton.DoClick = function()
			RunConsoleCommand("vrmod_idle_act", "ACT_HL2MP_IDLE")
			RunConsoleCommand("vrmod_walk_act", "ACT_HL2MP_WALK")
			RunConsoleCommand("vrmod_run_act", "ACT_HL2MP_WALK")
			RunConsoleCommand("vrmod_jump_act", "ACT_HL2MP_WALK")
		end
		registerPanel("animation", animationSettings)
		AddTreeNode(tree, L("Animation", "Animation"), "animation", "icon16/user_edit.png", showPanel)
		end -- Animation panel

		-- ========================================
		-- Panel: Graphics02
		-- ========================================
		do
		local advancedSettings = vgui.Create("DForm")
		advancedSettings:DockPadding(0, 0, 0, 0)
		local autores = advancedSettings:CheckBox(L("Automatic Resolution Set", "Automatic Resolution Set"))
		autores:SetConVar("vrmod_scr_alwaysautosetting")
		local rtwidth = advancedSettings:NumSlider(L("Render Target Width Multiplier", "Render Target Width Multiplier"), "vrmod_rtWidth_Multiplier", 0.1, 10, 1)
		local rtheight = advancedSettings:NumSlider(L("Render Target Height Multiplier", "Render Target Height Multiplier"), "vrmod_rtHeight_Multiplier", 0.1, 10, 1)
		local uiwidth = advancedSettings:NumSlider(L("VR UI Width", "VR UI Width"), "vrmod_ScrW", 640, ScrW() * 2, 0)
		local uiheight = advancedSettings:NumSlider(L("VR UI Height", "VR UI Height"), "vrmod_ScrH", 480, ScrH() * 2, 0)
		local hudwidth = advancedSettings:NumSlider(L("VR HUD Width", "VR HUD Width"), "vrmod_ScrW_hud", 640, ScrW() * 2, 0)
		local hudheight = advancedSettings:NumSlider(L("VR HUD Height", "VR HUD Height"), "vrmod_ScrH_hud", 480, ScrH() * 2, 0)
		local customres = advancedSettings:Button(L("Custom Width & Height (Quest 2 / Virtual Desktop)", "Custom Width & Height (Quest 2 / Virtual Desktop)"))
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
		AddTreeNode(tree, L("Graphics02", "Graphics02"), "graphics02", "icon16/wrench.png", showPanel)
		end -- Graphics02 panel

		-- ========================================
		-- Panel: Network(Server)
		-- ========================================
		do
		local networkSettings = vgui.Create("DForm")
		networkSettings:DockPadding(0, 0, 0, 0)
		local netdelay = networkSettings:NumSlider(L("Net Delay", "Net Delay"), "vrmod_net_delay", 0, 1, 3)
		local netdelaymax = networkSettings:NumSlider(L("Net Delay Max", "Net Delay Max"), "vrmod_net_delaymax", 0, 100, 3)
		local netstoredframes = networkSettings:NumSlider(L("Net Stored Frames", "Net Stored Frames"), "vrmod_net_storedframes", 1, 25, 3)
		local nettickrate = networkSettings:NumSlider(L("Net Tickrate", "Net Tickrate"), "vrmod_net_tickrate", 1, 100, 3)
		local allowteleport = networkSettings:CheckBox(L("Allow VR Teleport (Server)", "Allow VR Teleport (Server)"))
		allowteleport:SetConVar("vrmod_allow_teleport")
		local netdefault = networkSettings:Button(VRModL("btn_restore_defaults", "Restore Default Settings"))
		netdefault.DoClick = function()
			VRModResetCategory("network")
		end
		registerPanel("network", networkSettings)
		AddTreeNode(tree, L("Network(Server)", "Network(Server)"), "network", "icon16/connect.png", showPanel)
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
		commandsForm:SetName(L("VR Commands", "VR Commands"))
		commandsForm:Dock(TOP)
		commandsForm:DockMargin(5, 5, 5, 5)
		commandsForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end

		-- Debug Visualization
		local debugCategory = commandsForm:Help(L("=== Debug Visualization ===", "=== Debug Visualization ==="))
		debugCategory:SetFont("DermaDefaultBold")

		local doorDebugBtn = commandsForm:Button(L("Toggle Door Collision Debug", "Toggle Door Collision Debug"))
		doorDebugBtn.DoClick = function()
			RunConsoleCommand("vrmod_doordebug")
		end

		local locoDebugBtn = commandsForm:Button(L("Toggle Playspace Debug", "Toggle Playspace Debug"))
		locoDebugBtn.DoClick = function()
			RunConsoleCommand("vrmod_debuglocomotion")
		end

		local netDebugBtn = commandsForm:Button(L("Toggle Network Debug", "Toggle Network Debug"))
		netDebugBtn.DoClick = function()
			RunConsoleCommand("vrmod_net_debug")
		end

		commandsForm:Help(L("Visualize collision boxes, playspace boundaries, and network traffic", "Visualize collision boxes, playspace boundaries, and network traffic"))

		-- Device Information
		local deviceCategory = commandsForm:Help(L("=== Device Information ===", "=== Device Information ==="))
		deviceCategory:SetFont("DermaDefaultBold")

		local printDevicesBtn = commandsForm:Button(L("Print VR Devices Info", "Print VR Devices Info"))
		printDevicesBtn.DoClick = function()
			RunConsoleCommand("vrmod_print_devices")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("VR devices info printed to console", "VR devices info printed to console"))
		end

		commandsForm:Help(L("Display all connected VR tracking devices and FBT status", "Display all connected VR tracking devices and FBT status"))

		-- Cardboard VR Support
		local cardboardCategory = commandsForm:Help(L("=== Cardboard VR Support ===", "=== Cardboard VR Support ==="))
		cardboardCategory:SetFont("DermaDefaultBold")

		local cardboardStartBtn = commandsForm:Button(L("Start Cardboard VR Mode", "Start Cardboard VR Mode"))
		cardboardStartBtn.DoClick = function()
			RunConsoleCommand("cardboardmod_start")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Cardboard VR mode started", "Cardboard VR mode started"))
		end

		local cardboardExitBtn = commandsForm:Button(L("Exit Cardboard VR Mode", "Exit Cardboard VR Mode"))
		cardboardExitBtn.DoClick = function()
			RunConsoleCommand("cardboardmod_exit")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Cardboard VR mode exited", "Cardboard VR mode exited"))
		end

		commandsForm:Help(L("Alternative VR mode using phone sensors (for testing without HMD)", "Alternative VR mode using phone sensors (for testing without HMD)"))

		-- VRE Integration
		local vreCategory = commandsForm:Help(L("=== VRE (VR Essentials) Integration ===", "=== VRE (VR Essentials) Integration ==="))
		vreCategory:SetFont("DermaDefaultBold")

		local radialMenuBtn = commandsForm:Button(L("Toggle Radial Menu", "Toggle Radial Menu"))
		radialMenuBtn.DoClick = function()
			RunConsoleCommand("vre_gb-radial")
		end

		local serverMenuBtn = commandsForm:Button(L("Toggle Server Menu", "Toggle Server Menu"))
		serverMenuBtn.DoClick = function()
			RunConsoleCommand("vre_svmenu")
		end

		commandsForm:Help(L("VRE addon must be installed for these commands to work", "VRE addon must be installed for these commands to work"))

		registerPanel("commands", commandsTab)
		AddTreeNode(tree, L("Commands", "Commands"), "commands", "icon16/application_xp_terminal.png", showPanel)
		end -- Commands panel

		-- ========================================
		-- Panel: Vehicle
		-- ========================================
		do
		local vehicleTab = vgui.Create("DPanel")
		vehicleTab.Paint = function(self, w, h) end
		-- Input Mode Switching Buttons
		local keymodeMainBtn = vgui.Create("DButton", vehicleTab)
		keymodeMainBtn:SetText(L("Main Mode\n(On-Foot)", "Main Mode\n(On-Foot)"))
		keymodeMainBtn:SetPos(20, 10)
		keymodeMainBtn:SetSize(160, 40)
		keymodeMainBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_main")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Switched to Main input mode", "Switched to Main input mode"))
		end
		keymodeMainBtn:SetTooltip(L("Use main controller bindings (on-foot controls)", "Use main controller bindings (on-foot controls)"))
		local keymodeDrivingBtn = vgui.Create("DButton", vehicleTab)
		keymodeDrivingBtn:SetText(L("Driving Mode\n(Vehicle)", "Driving Mode\n(Vehicle)"))
		keymodeDrivingBtn:SetPos(190, 10)
		keymodeDrivingBtn:SetSize(160, 40)
		keymodeDrivingBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_driving")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Switched to Driving input mode", "Switched to Driving input mode"))
		end
		keymodeDrivingBtn:SetTooltip(L("Use driving controller bindings (vehicle controls)", "Use driving controller bindings (vehicle controls)"))
		local keymodeBothBtn = vgui.Create("DButton", vehicleTab)
		keymodeBothBtn:SetText(L("Both Modes\n(Main + Driving)", "Both Modes\n(Main + Driving)"))
		keymodeBothBtn:SetPos(20, 60)
		keymodeBothBtn:SetSize(160, 40)
		keymodeBothBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_both")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Both input modes enabled", "Both input modes enabled"))
		end
		keymodeBothBtn:SetTooltip(L("Use both main and driving bindings simultaneously", "Use both main and driving bindings simultaneously"))
		local keymodeRestoreBtn = vgui.Create("DButton", vehicleTab)
		keymodeRestoreBtn:SetText(L("Auto Mode\n(Restore)", "Auto Mode\n(Restore)"))
		keymodeRestoreBtn:SetPos(190, 60)
		keymodeRestoreBtn:SetSize(160, 40)
		keymodeRestoreBtn.DoClick = function()
			RunConsoleCommand("vrmod_keymode_restore")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Input mode restored to automatic", "Input mode restored to automatic"))
		end
		keymodeRestoreBtn:SetTooltip("Restore automatic mode switching")
		-- LVS Input Mode
		local lvsInputMode = vehicleTab:Add("DCheckBoxLabel")
		lvsInputMode:SetPos(20, 120)
		lvsInputMode:SetText(L("LVS Networked Mode (1 = multiplayer, 0 = singleplayer)", "LVS Networked Mode (1 = multiplayer, 0 = singleplayer)"))
		lvsInputMode:SetConVar("vrmod_lvs_input_mode")
		lvsInputMode:SizeToContents()
		-- LFS/SimfPhys Mode Buttons
		local lfsModeBtn = vgui.Create("DButton", vehicleTab)
		lfsModeBtn:SetText(L("LFS Mode", "LFS Mode"))
		lfsModeBtn:SetPos(20, 160)
		lfsModeBtn:SetSize(160, 30)
		lfsModeBtn.DoClick = function()
			RunConsoleCommand("vrmod_lfsmode")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Switched to LFS mode", "Switched to LFS mode"))
		end
		lfsModeBtn:SetTooltip("Switch reticle mode for LFS addon")
		local simfModeBtn = vgui.Create("DButton", vehicleTab)
		simfModeBtn:SetText(L("SimfPhys Mode", "SimfPhys Mode"))
		simfModeBtn:SetPos(190, 160)
		simfModeBtn:SetSize(160, 30)
		simfModeBtn.DoClick = function()
			RunConsoleCommand("vrmod_simfmode")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Switched to SimfPhys mode", "Switched to SimfPhys mode"))
		end
		simfModeBtn:SetTooltip("Switch reticle mode for SimfPhys addon")
		-- Auto Seat Reset
		local autoSeatReset = vehicleTab:Add("DCheckBoxLabel")
		autoSeatReset:SetPos(20, 210)
		autoSeatReset:SetText(L("[Auto Seat Reset] Disable seat mode when entering vehicle", "[Auto Seat Reset] Disable seat mode when entering vehicle"))
		autoSeatReset:SetConVar("vrmod_auto_seat_reset")
		autoSeatReset:SizeToContents()
		-- Reset Vehicle Settings Button
		local resetVehicleBtn = vgui.Create("DButton", vehicleTab)
		resetVehicleBtn:SetText(L("Reset Vehicle Settings", "Reset Vehicle Settings"))
		resetVehicleBtn:SetPos(20, 240)
		resetVehicleBtn:SetSize(330, 30)
		resetVehicleBtn.DoClick = function()
			VRModResetCategory("vehicle")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Vehicle settings reset to defaults", "Vehicle settings reset to defaults"))
		end
		registerPanel("vehicle", vehicleTab)
		AddTreeNode(tree, L("Vehicle", "Vehicle"), "vehicle", "icon16/car.png", showPanel)
		end -- Vehicle panel

		-- ========================================
		-- Panel: Magazine
		-- ========================================
		do
		local magScroll = vgui.Create("DScrollPanel")

		local magForm = vgui.Create("DForm", magScroll)
		magForm:Dock(TOP)
		magForm:DockMargin(5, 5, 5, 5)
		magForm:SetName(L("VR Magazine System", "VR Magazine System"))
		magForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		magForm:CheckBox(L("Enable VR Magazine System", "Enable VR Magazine System"), "vrmod_mag_system_enable")
		magForm:CheckBox(L("Enable Magazine Pouch", "Enable Magazine Pouch"), "vrmod_unoff_mag_pouch_enable")
		magForm:Help(L("Magazine Pouch: reach left hand to body pouch + Pickup to spawn vrmagent.", "Magazine Pouch: reach left hand to body pouch + Pickup to spawn vrmagent."))
		magForm:CheckBox(L("VR Magazine bone or bonegroup", "VR Magazine bone or bonegroup"), "vrmod_mag_ejectbone_type")
		magForm:TextEntry(L("Magazine Enter Sound", "Magazine Enter Sound"), "vrmod_magent_sound")
		magForm:NumSlider(L("Magazine Enter Range", "Magazine Enter Range"), "vrmod_magent_range", 1, 100, 0)
		magForm:TextEntry(L("Magazine Enter Model", "Magazine Enter Model"), "vrmod_magent_model")
		magForm:CheckBox(L("[WIP] WeaponModel Mag Grab/Eject", "[WIP] WeaponModel Mag Grab/Eject"), "vrmod_mag_ejectbone_enable")

		local magPosForm = vgui.Create("DForm", magScroll)
		magPosForm:Dock(TOP)
		magPosForm:DockMargin(5, 5, 5, 5)
		magPosForm:SetName(L("Magazine Position", "Magazine Position"))
		magPosForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		magPosForm:NumSlider(L("Position X", "Position X"), "vrmod_mag_pos_x", -20, 20, 2)
		magPosForm:NumSlider(L("Position Y", "Position Y"), "vrmod_mag_pos_y", -20, 20, 2)
		magPosForm:NumSlider(L("Position Z", "Position Z"), "vrmod_mag_pos_z", -20, 20, 2)
		magPosForm:NumSlider(L("Angle Pitch", "Angle Pitch"), "vrmod_mag_ang_p", -180, 180, 2)
		magPosForm:NumSlider(L("Angle Yaw", "Angle Yaw"), "vrmod_mag_ang_y", -180, 180, 2)
		magPosForm:NumSlider(L("Angle Roll", "Angle Roll"), "vrmod_mag_ang_r", -180, 180, 2)
		magPosForm:TextEntry(L("Magazine Bone Names", "Magazine Bone Names"), "vrmod_mag_bones")

		local pouchForm = vgui.Create("DForm", magScroll)
		pouchForm:Dock(TOP)
		pouchForm:DockMargin(5, 5, 5, 5)
		pouchForm:SetName(L("Pouch Position (shared with ArcVR)", "Pouch Position (shared with ArcVR)"))
		pouchForm.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		local pouchLocCombo = pouchForm:ComboBox(L("Pouch Location", "Pouch Location"), "vrmod_unoff_pouch_location")
		pouchLocCombo:AddChoice(L("Pelvis (Hip)", "Pelvis (Hip)"), "pelvis")
		pouchLocCombo:AddChoice(L("Head", "Head"), "head")
		pouchLocCombo:AddChoice(L("Spine (Chest)", "Spine (Chest)"), "spine")
		pouchForm:NumSlider(L("Pouch Distance", "Pouch Distance"), "vrmod_unoff_pouch_dist", 1, 50, 1)
		pouchForm:CheckBox(L("Infinite Pouch (any distance)", "Infinite Pouch (any distance)"), "vrmod_unoff_pouch_infinite")
		pouchForm:CheckBox(L("Sync to ArcVR ConVars", "Sync to ArcVR ConVars"), "vrmod_unoff_pouch_sync_arcvr")

		local arc9Form = vgui.Create("DForm", magScroll)
		arc9Form:Dock(TOP)
		arc9Form:DockMargin(5, 5, 5, 5)
		arc9Form:SetName(L("ARC9 Weapon Settings", "ARC9 Weapon Settings"))
		arc9Form.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(240, 240, 240))
		end
		arc9Form:CheckBox(L("Enable ARC9 VR Integration", "Enable ARC9 VR Integration"), "vrmod_arc9_enable")
		arc9Form:CheckBox(L("Enable ARC9 Magazine Bone Fix", "Enable ARC9 Magazine Bone Fix"), "vrmod_arc9_magbone_fix_enable")
		arc9Form:CheckBox(L("ARC9 Mag Bone: Follow Left Hand / Hide Only", "ARC9 Mag Bone: Follow Left Hand / Hide Only"), "vrmod_arc9_magbone_track")

		registerPanel("magazine", magScroll)
		AddTreeNode(tree, L("Magazine", "Magazine"), "magazine", "icon16/basket.png", showPanel)
		end -- Magazine panel

		-- ========================================
		-- Panel: Utility
		-- ========================================
		do
		local utilityPanel = CreateUtilityPanel()
		registerPanel("utility", utilityPanel)
		AddTreeNode(tree, L("Utility", "Utility"), "utility", "icon16/wrench.png", showPanel)
		end -- Utility panel

		-- ========================================
		-- Panel: Cardboard
		-- ========================================
		do
		local cardboardPanel = CreateCardboardPanel()
		registerPanel("cardboard", cardboardPanel)
		AddTreeNode(tree, L("Cardboard", "Cardboard"), "cardboard", "icon16/phone.png", showPanel)
		end -- Cardboard panel

		-- ========================================
		-- Panel: C++ Module (Status, Settings, Actions)
		-- ========================================
		do
		local scrollPanel = vgui.Create("DScrollPanel")

		-- === Section 1: Module Status ===
		local statusSection = vgui.Create("DLabel", scrollPanel)
		statusSection:Dock(TOP)
		statusSection:DockMargin(10, 10, 10, 4)
		statusSection:SetText(L("=== Module Status ===", "=== Module Status ==="))
		statusSection:SetFont("DermaDefaultBold")
		statusSection:SizeToContents()

		-- Status info panel with color-coded background
		local statusPanel = vgui.Create("DPanel", scrollPanel)
		statusPanel:Dock(TOP)
		statusPanel:DockMargin(10, 2, 10, 8)
		statusPanel:SetTall(140)

		local moduleVerRaw = g_VR and g_VR.moduleVersion or nil
		local moduleSemiVer = g_VR and g_VR.moduleSemiVersion or nil
		local moduleVer = (moduleSemiVer and moduleSemiVer > 0) and moduleSemiVer or moduleVerRaw
		local moduleName = g_VR and g_VR.moduleName or "unknown"
		local isInstalled = moduleVerRaw and moduleVerRaw > 0
		local _, _, latestVer = vrmod.GetModuleVersion()

		local isLinux = system.IsLinux()
		local dll32Name = isLinux and "gmcl_vrmod_linux.dll" or "gmcl_vrmod_win32.dll"
		local dll64Name = isLinux and "gmcl_vrmod_linux64.dll" or "gmcl_vrmod_win64.dll"
		local dat32Name = isLinux and "gmcl_vrmod_linux.dat" or "gmcl_vrmod_win32.dat"
		local win32Exists = file.Exists("lua/bin/" .. dll32Name, "GAME")
		local win64Exists = file.Exists("lua/bin/" .. dll64Name, "GAME")
		local datExtracted = file.Exists("vrmod_module/" .. dat32Name, "DATA")

		local statusColor
		if isInstalled then
			statusColor = Color(30, 80, 30, 200)
		elseif moduleVer == 0 then
			statusColor = Color(120, 30, 30, 200)
		else
			statusColor = Color(100, 80, 20, 200)
		end

		statusPanel.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, statusColor)
		end

		local statusKey
		if isInstalled then
			statusKey = "installed"
		elseif moduleVer == 0 then
			statusKey = "error"
		else
			statusKey = "notinstalled"
		end

		local infoLines = {
			{ L("Status:", "Status:"), statusKey == "installed" and L("Installed", "Installed") or statusKey == "error" and L("Error (loaded but failed)", "Error (loaded but failed)") or L("Not installed", "Not installed"), statusKey },
			{ L("Version:", "Version:"), isInstalled and ("v" .. tostring(moduleVer)) or "N/A", "info" },
			{ L("Type:", "Type:"), isInstalled and moduleName or "N/A", "info" },
			{ L("Latest:", "Latest:"), latestVer and ("v" .. tostring(latestVer)) or "N/A", "info" },
			{ (isLinux and "linux" or "win32") .. " DLL:", win32Exists and L("Found", "Found") or L("Missing", "Missing"), win32Exists and "found" or "missing" },
			{ (isLinux and "linux64" or "win64") .. " DLL:", win64Exists and L("Found", "Found") or L("Missing", "Missing"), win64Exists and "found" or "missing" },
			{ L("Extracted .dat:", "Extracted .dat:"), datExtracted and L("Found", "Found") or L("Missing", "Missing"), datExtracted and "found" or "missing" },
		}

		local yPos = 8
		for _, line in ipairs(infoLines) do
			local lbl = vgui.Create("DLabel", statusPanel)
			lbl:SetPos(12, yPos)
			lbl:SetText(line[1])
			lbl:SetFont("DermaDefaultBold")
			lbl:SetTextColor(Color(200, 200, 200))
			lbl:SizeToContents()

			local val = vgui.Create("DLabel", statusPanel)
			val:SetPos(130, yPos)
			val:SetText(line[2])
			local k = line[3]
			if k == "missing" or k == "error" then
				val:SetTextColor(Color(255, 100, 100))
			elseif k == "found" or k == "installed" then
				val:SetTextColor(Color(100, 255, 100))
			elseif k == "notinstalled" then
				val:SetTextColor(Color(255, 220, 100))
			else
				val:SetTextColor(Color(255, 255, 255))
			end
			val:SizeToContents()
			yPos = yPos + 18
		end

		-- === Section 2: Settings ===
		local settingsSection = vgui.Create("DLabel", scrollPanel)
		settingsSection:Dock(TOP)
		settingsSection:DockMargin(10, 6, 10, 4)
		settingsSection:SetText(L("=== Settings ===", "=== Settings ==="))
		settingsSection:SetFont("DermaDefaultBold")
		settingsSection:SizeToContents()

		-- Input Mode combo
		local modePanel = vgui.Create("DPanel", scrollPanel)
		modePanel:Dock(TOP)
		modePanel:DockMargin(10, 2, 10, 4)
		modePanel:SetTall(28)
		modePanel:SetPaintBackground(false)

		local modeLabel = vgui.Create("DLabel", modePanel)
		modeLabel:SetPos(4, 5)
		modeLabel:SetText(L("Input Mode:", "Input Mode:"))
		modeLabel:SizeToContents()

		local modeCombo = vgui.Create("DComboBox", modePanel)
		modeCombo:SetPos(130, 2)
		modeCombo:SetSize(220, 24)
		modeCombo:AddChoice(L("SteamVR Bindings (Default)", "SteamVR Bindings (Default)"), 0)
		modeCombo:AddChoice(L("Lua Keybinding", "Lua Keybinding"), 1)
		local cv_inputmode = GetConVar("vrmod_unoff_inputmode")
		if cv_inputmode then
			modeCombo:SetValue(cv_inputmode:GetInt() == 1 and "Lua Keybinding" or "SteamVR Bindings (Default)")
		end
		modeCombo.OnSelect = function(self, index, value, data)
			RunConsoleCommand("vrmod_unoff_inputmode", tostring(data))
		end

		-- Module Error Lock checkbox
		local errorLock = vgui.Create("DCheckBoxLabel", scrollPanel)
		errorLock:Dock(TOP)
		errorLock:DockMargin(14, 2, 10, 4)
		errorLock:SetText(L("Module Error: Lock VRMod Menu", "Module Error: Lock VRMod Menu"))
		errorLock:SetConVar("vrmod_error_hard")
		errorLock:SizeToContents()

		-- === Section 3: Actions ===
		local actionsSection = vgui.Create("DLabel", scrollPanel)
		actionsSection:Dock(TOP)
		actionsSection:DockMargin(10, 8, 10, 4)
		actionsSection:SetText(L("=== Actions ===", "=== Actions ==="))
		actionsSection:SetFont("DermaDefaultBold")
		actionsSection:SizeToContents()

		local reExtractBtn = vgui.Create("DButton", scrollPanel)
		reExtractBtn:Dock(TOP)
		reExtractBtn:DockMargin(10, 2, 10, 2)
		reExtractBtn:SetTall(26)
		reExtractBtn:SetText(L("Re-extract Module Files", "Re-extract Module Files"))
		reExtractBtn.DoClick = function()
			RunConsoleCommand("vrmod_module_extract")
			chat.AddText(Color(255, 200, 0), "[VRMod] ", Color(255, 255, 255), L("Module files re-extracted. Check console for details.", "Module files re-extracted. Check console for details."))
		end

		local keybindBtn = vgui.Create("DButton", scrollPanel)
		keybindBtn:Dock(TOP)
		keybindBtn:DockMargin(10, 2, 10, 2)
		keybindBtn:SetTall(26)
		keybindBtn:SetText(L("Open Keybinding Editor", "Open Keybinding Editor"))
		keybindBtn.DoClick = function()
			RunConsoleCommand("vrmod_keybinding_menu")
		end

		local folderBtn = vgui.Create("DButton", scrollPanel)
		folderBtn:Dock(TOP)
		folderBtn:DockMargin(10, 2, 10, 2)
		folderBtn:SetTall(26)
		folderBtn:SetText(L("Open Module Folder Guide", "Open Module Folder Guide"))
		folderBtn.DoClick = function()
			if vrmod_OpenModuleFolder then
				vrmod_OpenModuleFolder()
			else
				chat.AddText(Color(255, 200, 0), "[VRMod] ", Color(255, 255, 255), L("Go to: garrysmod/data/vrmod_module/", "Go to: garrysmod/data/vrmod_module/"))
			end
		end

		local diagBtn = vgui.Create("DButton", scrollPanel)
		diagBtn:Dock(TOP)
		diagBtn:DockMargin(10, 2, 10, 2)
		diagBtn:SetTall(26)
		diagBtn:SetText(L("Print Module Diagnostics", "Print Module Diagnostics"))
		diagBtn.DoClick = function()
			local ver, req, latest = vrmod.GetModuleVersion()
			print("========================================")
			print("[VRMod Module Diagnostics]")
			print("  Module Version (compat): " .. tostring(ver))
			print("  Module Version (semi): " .. tostring(g_VR and g_VR.moduleSemiVersion or "N/A"))
			print("  Required Version: " .. tostring(req))
			print("  Latest Version: " .. tostring(latest))
			print("  Module Name: " .. tostring(g_VR and g_VR.moduleName or "N/A"))
			local _isLinux = system.IsLinux()
			local _d32 = _isLinux and "gmcl_vrmod_linux.dll" or "gmcl_vrmod_win32.dll"
			local _d64 = _isLinux and "gmcl_vrmod_linux64.dll" or "gmcl_vrmod_win64.dll"
			local _dat32 = _isLinux and "gmcl_vrmod_linux.dat" or "gmcl_vrmod_win32.dat"
			local _dat64 = _isLinux and "gmcl_vrmod_linux64.dat" or "gmcl_vrmod_win64.dat"
			print("  Platform: " .. (system.IsWindows() and "Windows" or _isLinux and "Linux" or system.IsOSX() and "OSX" or "Unknown"))
			print("  " .. _d32 .. ": " .. (file.Exists("lua/bin/" .. _d32, "GAME") and "Found" or "Missing"))
			print("  " .. _d64 .. ": " .. (file.Exists("lua/bin/" .. _d64, "GAME") and "Found" or "Missing"))
			print("  Extracted " .. _dat32 .. ": " .. (file.Exists("vrmod_module/" .. _dat32, "DATA") and "Found" or "Missing"))
			print("  Extracted " .. _dat64 .. ": " .. (file.Exists("vrmod_module/" .. _dat64, "DATA") and "Found" or "Missing"))
			print("  install.txt: " .. (file.Exists("vrmod_module/install.txt", "DATA") and "Found" or "Missing"))
			print("========================================")
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), L("Module diagnostics printed to console.", "Module diagnostics printed to console."))
		end

		-- === Section 4: Troubleshooting ===
		local troubleSection = vgui.Create("DLabel", scrollPanel)
		troubleSection:Dock(TOP)
		troubleSection:DockMargin(10, 10, 10, 4)
		troubleSection:SetText(L("=== Troubleshooting ===", "=== Troubleshooting ==="))
		troubleSection:SetFont("DermaDefaultBold")
		troubleSection:SizeToContents()

		local troubleText = vgui.Create("DLabel", scrollPanel)
		troubleText:Dock(TOP)
		troubleText:DockMargin(14, 2, 10, 4)
		troubleText:SetText(L(
			"If module is not working:\n" ..
			"1. Go to garrysmod/data/vrmod_module/\n" ..
			"2. Rename install.txt -> install.bat\n" ..
			"3. Run install.bat, then restart Gmod\n" ..
			"4. If antivirus blocks it, add GarrysMod\n" ..
			"   folder to your AV exclusions\n" ..
			"5. Windows Defender: Settings > Virus\n" ..
			"   protection > Exclusions",
			"If module is not working:\n" ..
			"1. Go to garrysmod/data/vrmod_module/\n" ..
			"2. Rename install.txt -> install.bat\n" ..
			"3. Run install.bat, then restart Gmod\n" ..
			"4. If antivirus blocks it, add GarrysMod\n" ..
			"   folder to your AV exclusions\n" ..
			"5. Windows Defender: Settings > Virus\n" ..
			"   protection > Exclusions"
		))
		troubleText:SetAutoStretchVertical(true)
		troubleText:SetWrap(true)
		troubleText:SetTextColor(Color(200, 200, 180))

		registerPanel("cppmodule", scrollPanel)
		AddTreeNode(tree, L("C++ Module", "C++ Module"), "cppmodule", "icon16/brick.png", showPanel)
		end -- C++ Module panel

		-- ========================================
		-- Panel: Key Mapping (VR Action → Keyboard Key)
		-- ========================================
		do
		local keyMapScroll = vgui.Create("DScrollPanel")

		-- === Enable / Layer Status ===
		local enableSection = vgui.Create("DLabel", keyMapScroll)
		enableSection:Dock(TOP)
		enableSection:DockMargin(10, 10, 10, 4)
		enableSection:SetText(L("=== Input Emulation Status ===", "=== Input Emulation Status ==="))
		enableSection:SetFont("DermaDefaultBold")
		enableSection:SizeToContents()

		local statusPanel = vgui.Create("DPanel", keyMapScroll)
		statusPanel:Dock(TOP)
		statusPanel:DockMargin(10, 2, 10, 6)
		statusPanel:SetTall(62)

		local hasCpp = (VRMOD_SendKeyEvent ~= nil)
		local hasLua = (vrmod ~= nil and vrmod.InputEmu_SetKey ~= nil)
		local statusBgColor = (hasLua and hasCpp) and Color(30, 80, 30, 200) or (hasLua and Color(80, 80, 20, 200) or Color(100, 30, 30, 200))
		statusPanel.Paint = function(self, w, h) draw.RoundedBox(6, 0, 0, w, h, statusBgColor) end

		local statusLines = {
			{ "Layer 1 (Lua detour):", hasLua and "Available" or "Unavailable", hasLua },
			{ "Layer 2 (C++ PostMessage):", hasCpp and "Available (v102+)" or "Not available (module v102+ required)", hasCpp },
			{ "Note:", hasCpp and "Both layers active — full compatibility" or "Lua-only mode: covers Lua callers. C++ layer needs module v102+", nil },
		}
		local yOff = 6
		for _, info in ipairs(statusLines) do
			local lbl = vgui.Create("DLabel", statusPanel)
			lbl:SetPos(10, yOff)
			lbl:SetText(info[1])
			lbl:SetFont("DermaDefaultBold")
			lbl:SetTextColor(Color(200, 200, 200))
			lbl:SizeToContents()
			local val = vgui.Create("DLabel", statusPanel)
			val:SetPos(180, yOff)
			val:SetText(info[2])
			if info[3] == true then val:SetTextColor(Color(100, 255, 100))
			elseif info[3] == false then val:SetTextColor(Color(255, 180, 80))
			else val:SetTextColor(Color(180, 180, 180)) end
			val:SizeToContents()
			yOff = yOff + 18
		end

		-- Enable checkbox
		local enableCheck = vgui.Create("DCheckBoxLabel", keyMapScroll)
		enableCheck:Dock(TOP)
		enableCheck:DockMargin(14, 4, 10, 2)
		enableCheck:SetText(L("Enable Input Emulation (vrmod_unoff_input_emu)", "Enable Input Emulation (vrmod_unoff_input_emu)"))
		enableCheck:SetConVar("vrmod_unoff_input_emu")
		enableCheck:SizeToContents()

		-- C++ inject checkbox
		local cppCheck = vgui.Create("DCheckBoxLabel", keyMapScroll)
		cppCheck:Dock(TOP)
		cppCheck:DockMargin(14, 2, 10, 4)
		cppCheck:SetText(L("Enable C++ Engine Injection (vrmod_unoff_cpp_keyinject)", "Enable C++ Engine Injection (vrmod_unoff_cpp_keyinject)"))
		cppCheck:SetConVar("vrmod_unoff_cpp_keyinject")
		cppCheck:SizeToContents()

		-- === Key Assignment ===
		local mapSection = vgui.Create("DLabel", keyMapScroll)
		mapSection:Dock(TOP)
		mapSection:DockMargin(10, 8, 10, 4)
		mapSection:SetText(L("=== Key Assignment ===", "=== Key Assignment ==="))
		mapSection:SetFont("DermaDefaultBold")
		mapSection:SizeToContents()

		local helpText = vgui.Create("DLabel", keyMapScroll)
		helpText:Dock(TOP)
		helpText:DockMargin(14, 0, 10, 6)
		helpText:SetText(L("Click a keyboard key, then press a VR controller button to assign.", "Click a keyboard key, then press a VR controller button to assign."))
		helpText:SetTextColor(Color(180, 180, 160))
		helpText:SizeToContents()

		local editorBtn = vgui.Create("DButton", keyMapScroll)
		editorBtn:Dock(TOP)
		editorBtn:DockMargin(10, 2, 10, 4)
		editorBtn:SetTall(30)
		editorBtn:SetText(L("Open Visual Keyboard Editor", "Open Visual Keyboard Editor"))
		editorBtn.DoClick = function()
			RunConsoleCommand("vrmod_input_emu_editor")
		end

		-- === Debug ===
		local debugSection = vgui.Create("DLabel", keyMapScroll)
		debugSection:Dock(TOP)
		debugSection:DockMargin(10, 8, 10, 4)
		debugSection:SetText(L("=== Debug ===", "=== Debug ==="))
		debugSection:SetFont("DermaDefaultBold")
		debugSection:SizeToContents()

		local diagBtn = vgui.Create("DButton", keyMapScroll)
		diagBtn:Dock(TOP)
		diagBtn:DockMargin(10, 2, 10, 4)
		diagBtn:SetTall(26)
		diagBtn:SetText(L("Print Current Mapping", "Print Current Mapping"))
		diagBtn.DoClick = function()
			RunConsoleCommand("vrmod_unoff_input_emu_status")
		end

		registerPanel("keymapping", keyMapScroll)
		AddTreeNode(tree, L("Key Mapping", "Key Mapping"), "keymapping", "icon16/keyboard.png", showPanel)
		end -- Key Mapping panel

		-- ========================================
		-- Settings02Register API: 個別モジュールアドオン用
		-- frame.Settings02Register(key, label, icon, panel) を公開
		-- モジュール側: frame.Settings02Register が存在すれば DTree に登録、
		--              なければ frame.DPropertySheet:AddSheet() にフォールバック
		-- ========================================
		frame.Settings02Register = function(key, label, icon, panel)
			if not key or not label then
				print("[VRMod Settings02] Register failed: missing key or label (" .. tostring(key) .. ", " .. tostring(label) .. ")")
				return false
			end
			if not IsValid(panel) then
				print("[VRMod Settings02] Register failed: invalid panel for '" .. tostring(label) .. "'")
				return false
			end
			local ok, err = pcall(function()
				registerPanel(key, panel)
				AddTreeNode(tree, label, key, icon or "icon16/plugin.png", showPanel)
			end)
			if not ok then
				print("[VRMod Settings02] Register error for '" .. tostring(label) .. "': " .. tostring(err))
				return false
			end
			return true
		end

		-- ========================================
		-- Panel: Modules (Feature Loading Control) — disabled: unstable
		-- ========================================
		--[[
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
			folderNames["0"] = "Core(API)"
		end
		if GetConVar("vrmod_unoff_load_1") then
			folderNames["1"] = "Core(Modules)"
		end

		-- ソート用キー
		local sortedFolders = {}
		for k in pairs(folderNames) do sortedFolders[#sortedFolders + 1] = k end
		table.sort(sortedFolders, function(a, b) return tonumber(a) < tonumber(b) end)

		-- 再起動警告
		local restartWarning = vgui.Create("DLabel", modulesScroll)
		restartWarning:Dock(TOP)
		restartWarning:DockMargin(10, 8, 10, 4)
		restartWarning:SetText(L("Changes require Gmod restart to take effect.", "Changes require Gmod restart to take effect."))
		restartWarning:SetFont("DermaDefaultBold")
		restartWarning:SetTextColor(Color(255, 80, 80))
		restartWarning:SetAutoStretchVertical(true)

		-- === Addon-Only Mode セクション ===
		local addonOnlySectionLabel = vgui.Create("DLabel", modulesScroll)
		addonOnlySectionLabel:Dock(TOP)
		addonOnlySectionLabel:DockMargin(10, 10, 10, 2)
		addonOnlySectionLabel:SetText(L("=== Addon-Only Mode ===", "=== Addon-Only Mode ==="))
		addonOnlySectionLabel:SetFont("DermaDefaultBold")
		addonOnlySectionLabel:SizeToContents()

		local addonOnlyCheck = vgui.Create("DCheckBoxLabel", modulesScroll)
		addonOnlyCheck:Dock(TOP)
		addonOnlyCheck:DockMargin(10, 4, 10, 2)
		addonOnlyCheck:SetText(L("Addon-Only Mode (skip root files, use external VRMod)", "Addon-Only Mode (skip root files, use external VRMod)"))
		addonOnlyCheck:SetConVar("vrmod_unoff_addon_only_mode")
		addonOnlyCheck:SizeToContents()

		local addonOnlyDesc = vgui.Create("DLabel", modulesScroll)
		addonOnlyDesc:Dock(TOP)
		addonOnlyDesc:DockMargin(20, 0, 10, 8)
		addonOnlyDesc:SetText(L("ON = Root files (vrmod.lua, input, character, etc.) are not loaded.\nUse this with legacy/original VRMod as your base VRMod.\nOnly numbered folder modules are loaded as add-on features.", "ON = Root files (vrmod.lua, input, character, etc.) are not loaded.\nUse this with legacy/original VRMod as your base VRMod.\nOnly numbered folder modules are loaded as add-on features."))
		addonOnlyDesc:SetAutoStretchVertical(true)
		addonOnlyDesc:SetWrap(true)
		addonOnlyDesc:SetTextColor(Color(180, 180, 180))

		-- === Legacy Mode セクション ===
		local legacySectionLabel = vgui.Create("DLabel", modulesScroll)
		legacySectionLabel:Dock(TOP)
		legacySectionLabel:DockMargin(10, 10, 10, 2)
		legacySectionLabel:SetText(L("=== Legacy Mode ===", "=== Legacy Mode ==="))
		legacySectionLabel:SetFont("DermaDefaultBold")
		legacySectionLabel:SizeToContents()

		local legacyCheck = vgui.Create("DCheckBoxLabel", modulesScroll)
		legacyCheck:Dock(TOP)
		legacyCheck:DockMargin(10, 4, 10, 2)
		legacyCheck:SetText(L("Legacy Mode (load only core features)", "Legacy Mode (load only core features)"))
		legacyCheck:SetConVar("vrmod_unoff_legacy_mode")
		legacyCheck:SizeToContents()

		local legacyDesc = vgui.Create("DLabel", modulesScroll)
		legacyDesc:Dock(TOP)
		legacyDesc:DockMargin(20, 0, 10, 8)
		legacyDesc:SetText(L("ON = only folders 0 (Core) and 1 (Auto-settings) load.\nAll features below are disabled regardless of their individual setting.", "ON = only folders 0 (Core) and 1 (Auto-settings) load.\nAll features below are disabled regardless of their individual setting."))
		legacyDesc:SetAutoStretchVertical(true)
		legacyDesc:SetWrap(true)
		legacyDesc:SetTextColor(Color(180, 180, 180))

		-- === Feature Modules セクション ===
		local featureSectionLabel = vgui.Create("DLabel", modulesScroll)
		featureSectionLabel:Dock(TOP)
		featureSectionLabel:DockMargin(10, 6, 10, 2)
		featureSectionLabel:SetText(L("=== Feature Modules ===", "=== Feature Modules ==="))
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
		AddTreeNode(tree, L("Modules", "Modules"), "modules", "icon16/bricks.png", showPanel)
		end -- Modules panel
		--]]

		-- Show first panel (VR) by default
		showPanel("vr")
		tree:SetSelectedItem(vrNode)

		-- ExtractSheet removed (S32: modules are now individual addons using frame.DPropertySheet directly)
	end
)
