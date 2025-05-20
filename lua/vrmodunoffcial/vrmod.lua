function vrmod_lua()
	g_VR = g_VR or {}
	local convars, convarValues = vrmod.GetConvars()
	vrmod.AddCallbackedConvar("vrmod_configversion", nil, "5")
	if convars.vrmod_configversion:GetString() ~= convars.vrmod_configversion:GetDefault() then
		timer.Simple(
			1,
			function()
				for k, v in pairs(convars) do
					--reverting certain convars makes error
					pcall(
						function()
							v:Revert()
						end
					)
				end
			end
		)
	end

	if CLIENT then
		local errorout = CreateClientConVar("vrmod_error_check_method", 1, true, FCVAR_ARCHIVE)
		local vrScrH = CreateClientConVar("vrmod_ScrH", ScrH(), true, FCVAR_ARCHIVE)
		local vrScrW = CreateClientConVar("vrmod_ScrW", ScrW(), true, FCVAR_ARCHIVE)
		local rtWidthMul = CreateClientConVar("vrmod_rtWidth_Multiplier", "2.0", true, FCVAR_ARCHIVE)
		local rtHeightMul = CreateClientConVar("vrmod_rtHeight_Multiplier", "1.0", true, FCVAR_ARCHIVE)
		local autoarcbench = CreateClientConVar("vrmod_auto_arc_benchgun", "1", true, FCVAR_ARCHIVE)
		local uirendertype = CreateClientConVar("vrmod_dev_vr_rendertype_ex", 0, true, FCVAR_ARCHIVE, nil, 0, 1)
		g_VR.scale = 0
		g_VR.origin = Vector(0, 0, 0)
		g_VR.originAngle = Angle(0, 0, 0)
		g_VR.viewModel = nil --this will point to either the viewmodel, worldmodel or nil
		g_VR.viewModelMuzzle = nil
		g_VR.viewModelPos = Vector(0, 0, 0)
		g_VR.viewModelAng = Angle(0, 0, 0)
		g_VR.usingWorldModels = false
		g_VR.active = false
		g_VR.threePoints = false --hmd + 2 controllers
		g_VR.sixPoints = false --hmd + 2 controllers + 3 trackers
		g_VR.tracking = {}
		g_VR.input = {}
		g_VR.changedInputs = {}
		g_VR.errorText = ""
		--todo move some of these to the files where they belong
		vrmod.AddCallbackedConvar("vrmod_althead", nil, "1", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_autostart", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_scale", nil, "38.7", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_heightmenu", nil, "1", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_floatinghands", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_desktopview", nil, "3", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_useworldmodels", nil, "0", FCVAR_ARCHIVE, nil, 0, 1, tobool, UpdateWorldModelSetting)
		vrmod.AddCallbackedConvar("vrmod_laserpointer", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_characterEyeHeight", nil, "66.8", FCVAR_ARCHIVE, "", nil, nil, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		vrmod.AddCallbackedConvar("vrmod_characterHeadToHmdDist", nil, "6.3", FCVAR_ARCHIVE, "", nil, nil, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		vrmod.AddCallbackedConvar("vrmod_oldcharacteryaw", nil, "1", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_controlleroffset_x", nil, "-15", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_controlleroffset_y", nil, "-1", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_controlleroffset_z", nil, "5", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_controlleroffset_pitch", nil, "50", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_controlleroffset_yaw", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_controlleroffset_roll", nil, "0", FCVAR_ARCHIVE)
		-- ConVarの追加
		vrmod.AddCallbackedConvar("vrmod_hmdoffset_x", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_hmdoffset_y", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_hmdoffset_z", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_hmdoffset_pitch", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_hmdoffset_yaw", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar("vrmod_hmdoffset_roll", nil, "0", FCVAR_ARCHIVE)
		vrmod.AddCallbackedConvar(
			"vrmod_znear",
			nil,
			"6.0",
			FCVAR_ARCHIVE,
			nil,
			nil,
			nil,
			tonumber,
			function(val)
				if g_VR.view then
					g_VR.view.znear = val
				end
			end
		)

		vrmod.AddCallbackedConvar(
			"vrmod_postprocess",
			nil,
			"0",
			FCVAR_ARCHIVE,
			nil,
			nil,
			nil,
			tobool,
			function(val)
				if g_VR.view then
					g_VR.view.dopostprocess = val
				end
			end
		)

		hook.Add(
			"VRMod_Menu",
			"vrmod_options",
			function(frame)
				local form = frame.SettingsForm
				form:CheckBox("Use floating hands", "vrmod_floatinghands")
				form:CheckBox("Use weapon world models", "vrmod_useworldmodels")
				form:CheckBox("Add laser pointer to tools/weapons", "vrmod_laserpointer")
				--
				local tmp = form:CheckBox("Show height adjustment menu", "vrmod_heightmenu")
				local checkTime = 0
				function tmp:OnChange(checked)
					--only triggers when checked manually (not when using reset button)
					if checked and SysTime() - checkTime < 0.1 then
						VRUtilOpenHeightMenu()
					end

					checkTime = SysTime()
				end

				--
				form:CheckBox("Alternative head angle manipulation method", "vrmod_althead")
				form:ControlHelp("Less precise, compatibility for jigglebones")
				form:CheckBox("Automatically start VR after map loads", "vrmod_autostart")
				-- form:CheckBox("Replace climbing mechanics (when available)", "")
				form:CheckBox("Replace door use mechanics (when available)", "vrmod_doors")
				form:CheckBox("Enable engine postprocessing", "vrmod_postprocess")
				--
				local panel = vgui.Create("DPanel")
				panel:SetSize(300, 30)
				panel.Paint = function() end
				local dlabel = vgui.Create("DLabel", panel)
				dlabel:SetSize(100, 30)
				dlabel:SetPos(0, -3)
				dlabel:SetText("Desktop view:")
				dlabel:SetColor(Color(0, 0, 0))
				local DComboBox = vgui.Create("DComboBox", panel)
				DComboBox:Dock(TOP)
				DComboBox:DockMargin(70, 0, 0, 5)
				DComboBox:AddChoice("none")
				DComboBox:AddChoice("left eye")
				DComboBox:AddChoice("right eye")
				DComboBox.OnSelect = function(self, index, value)
					convars.vrmod_desktopview:SetInt(index)
				end

				DComboBox.Think = function(self)
					local v = convars.vrmod_desktopview:GetInt()
					if self.ConvarVal ~= v then
						self.ConvarVal = v
						self:ChooseOptionID(v)
					end
				end

				form:AddItem(panel)
				--
				form:Button("Edit custom controller input actions", "vrmod_actioneditor")
				form:Button("Reset settings to default", "vrmod_reset")
				--
				local offsetForm = vgui.Create("DForm", form)
				offsetForm:SetName("Controller offsets")
				offsetForm:Dock(TOP)
				offsetForm:DockMargin(10, 10, 10, 0)
				offsetForm:DockPadding(0, 0, 0, 0)
				offsetForm:SetExpanded(false)
				local tmp = offsetForm:NumSlider("X", "vrmod_controlleroffset_x", -30, 30, 0)
				tmp.PerformLayout = function(self)
					self.TextArea:SetWide(30)
					self.Label:SetWide(30)
				end

				tmp = offsetForm:NumSlider("Y", "vrmod_controlleroffset_y", -30, 30, 0)
				tmp.PerformLayout = function(self)
					self.TextArea:SetWide(30)
					self.Label:SetWide(30)
				end

				tmp = offsetForm:NumSlider("Z", "vrmod_controlleroffset_z", -30, 30, 0)
				tmp.PerformLayout = function(self)
					self.TextArea:SetWide(30)
					self.Label:SetWide(30)
				end

				tmp = offsetForm:NumSlider("Pitch", "vrmod_controlleroffset_pitch", -180, 180, 0)
				tmp.PerformLayout = function(self)
					self.TextArea:SetWide(30)
					self.Label:SetWide(30)
				end

				tmp = offsetForm:NumSlider("Yaw", "vrmod_controlleroffset_yaw", -180, 180, 0)
				tmp.PerformLayout = function(self)
					self.TextArea:SetWide(30)
					self.Label:SetWide(30)
				end

				tmp = offsetForm:NumSlider("Roll", "vrmod_controlleroffset_roll", -180, 180, 0)
				tmp.PerformLayout = function(self)
					self.TextArea:SetWide(30)
					self.Label:SetWide(30)
				end

				local tmp = offsetForm:Button("Apply offsets", "")
				function tmp:OnReleased()
					g_VR.rightControllerOffsetPos = Vector(convars.vrmod_controlleroffset_x:GetFloat(), convars.vrmod_controlleroffset_y:GetFloat(), convars.vrmod_controlleroffset_z:GetFloat())
					g_VR.leftControllerOffsetPos = g_VR.rightControllerOffsetPos * Vector(1, -1, 1)
					g_VR.rightControllerOffsetAng = Angle(convars.vrmod_controlleroffset_pitch:GetFloat(), convars.vrmod_controlleroffset_yaw:GetFloat(), convars.vrmod_controlleroffset_roll:GetFloat())
					g_VR.leftControllerOffsetAng = g_VR.rightControllerOffsetAng
				end
			end
		)

		--
		concommand.Add(
			"vrmod_start",
			function(ply, cmd, args)
				if vgui.CursorVisible() then
					print("vrmod: attempting startup when game is unpaused")
					--VRUtilClientStart()
				end

				timer.Create(
					"vrmod_start",
					0.1,
					0,
					function()
						if not vgui.CursorVisible() then
							timer.Remove("vrmod_start")
							VRUtilClientStart()
						end
					end
				)
			end
		)

		concommand.Add(
			"vrmod_exit",
			function(ply, cmd, args)
				timer.Remove("vrmod_start")
				VRUtilClientExit()
			end
		)

		concommand.Add(
			"vrmod_reset",
			function(ply, cmd, args)
				for k, v in pairs(vrmod.GetConvars()) do
					pcall(
						function()
							v:Revert()
						end
					)
				end

				hook.Call("VRMod_Reset")
			end
		)

		concommand.Add(
			"vrmod_info",
			function(ply, cmd, args)
				print("========================================================================")
				print(string.format("| %-30s %s", "Addon Version:", vrmod.GetVersion()))
				print(string.format("| %-30s %s", "Module Version:", vrmod.GetModuleVersion()))
				print(string.format("| %-30s %s", "GMod Version:", VERSION .. ", Branch: " .. BRANCH))
				print(string.format("| %-30s %s", "Operating System:", system.IsWindows() and "Windows" or system.IsLinux() and "Linux" or system.IsOSX() and "OSX" or "Unknown"))
				print(string.format("| %-30s %s", "Server Type:", game.SinglePlayer() and "Single Player" or "Multiplayer"))
				print(string.format("| %-30s %s", "Server Name:", GetHostName()))
				print(string.format("| %-30s %s", "Server Address:", game.GetIPAddress()))
				print(string.format("| %-30s %s", "Gamemode:", GAMEMODE_NAME))
				local workshopCount = 0
				for k, v in ipairs(engine.GetAddons()) do
					workshopCount = workshopCount + (v.mounted and 1 or 0)
				end

				local _, folders = file.Find("addons/*", "GAME")
				local legacyBlacklist = {
					checkers = true,
					chess = true,
					common = true,
					go = true,
					hearts = true,
					spades = true
				}

				local legacyCount = 0
				for k, v in ipairs(folders) do
					legacyCount = legacyCount + (legacyBlacklist[v] == nil and 1 or 0)
				end

				print(string.format("| %-30s %s", "Workshop Addons:", workshopCount))
				print(string.format("| %-30s %s", "Legacy Addons:", legacyCount))
				print("|----------")
				local function test(path)
					local files, folders = file.Find(path .. "/*", "GAME")
					for k, v in ipairs(folders) do
						test(path .. "/" .. v)
					end

					for k, v in ipairs(files) do
						print(string.format("| %-60s %X", path .. "/" .. v, util.CRC(file.Read(path .. "/" .. v, "GAME") or "")))
					end
				end

				test("data/vrmod")
				print("|----------")
				test("lua/bin")
				print("|----------")
				local convarNames = {}
				for k, v in pairs(convars) do
					convarNames[#convarNames + 1] = v:GetName()
				end

				table.sort(convarNames)
				for k, v in ipairs(convarNames) do
					v = GetConVar(v)
					print(string.format("| %-30s %-20s %s", v:GetName(), v:GetString(), v:GetString() == v:GetDefault() and "" or "*"))
				end

				print("========================================================================")
			end
		)

		local function CopyVMTsToTXT()
			-- "materials/vrmod/data/"フォルダのパスを指定
			local vmtFolderPath = "materials/vrmod/data/"
			-- "data/vrmod"フォルダが存在しない場合は作成
			if not file.Exists("vrmod", "GAME") then
				file.CreateDir("vrmod")
			end

			-- vmtファイルを検索
			local vmtFiles = file.Find(vmtFolderPath .. "*.vmt", "GAME")
			-- 各vmtファイルを処理
			for _, vmtFileName in ipairs(vmtFiles) do
				-- vmtファイルのフルパスを取得
				local vmtFilePath = vmtFolderPath .. vmtFileName
				-- vmtファイルをテキストとして読み込む
				local vmtText = file.Read(vmtFilePath, "GAME")
				-- txtファイル名を生成（.vmtを.txtに変更）
				local txtFileName = string.gsub(vmtFileName, "%.vmt$", ".txt")
				-- txtファイルのフルパスを生成
				local txtFilePath = "vrmod/" .. txtFileName
				-- txtファイルにvmtテキストを書き込む
				file.Write(txtFilePath, vmtText)
			end

			print("vrmod: CopyVMTsTotxt Active")
		end

		concommand.Add(
			"vrmod_data_vmt_generate_test",
			function(ply, cmd, args)
				CopyVMTsToTXT()
			end
		)

		-- 関数を呼び出してvmtをtxtにコピー
		concommand.Add(
			"vrmod_reset",
			function(ply, cmd, args)
				for k, v in pairs(vrmod.GetConvars()) do
					pcall(
						function()
							v:Revert()
						end
					)
				end

				CopyVMTsToTXT()
				hook.Call("VRMod_Reset")
			end
		)

		local moduleLoaded = false
		g_VR.moduleVersion = 0
		if file.Exists("lua/bin/gmcl_vrmod_win32.dll", "GAME") then
			local tmp = vrmod
			vrmod = {}
			moduleLoaded = pcall(
				function()
					require("vrmod")
				end
			)

			for k, v in pairs(vrmod) do
				_G["VRMOD_" .. k] = v
			end

			vrmod = tmp
			g_VR.moduleVersion = moduleLoaded and VRMOD_GetVersion and VRMOD_GetVersion() or 0
		end

		local convarOverrides = {}
		local function overrideConvar(name, value)
			local cv = GetConVar(name)
			if cv then
				convarOverrides[name] = cv:GetString()
				RunConsoleCommand(name, value)
			end
		end

		local function restoreConvarOverrides()
			for k, v in pairs(convarOverrides) do
				RunConsoleCommand(k, v)
			end

			convarOverrides = {}
		end

		local function pow2ceil(x)
			return math.pow(2, math.ceil(math.log(x, 2)))
		end

		function VRUtilClientStart()
			if g_VR.rt then
				g_VR.rt = nil
			end

			if GetConVar("godsenttools_gpu_saver") then
				overrideConvar("godsenttools_gpu_saver", "0")
			end

			if GetConVar("lithium_enable_gpusaver") then
				overrideConvar("lithium_enable_gpusaver", "0")
			end

			local rtWidthMul = CreateClientConVar("vrmod_rtWidth_Multiplier", "2.0", true, FCVAR_ARCHIVE)
			local rtHeightMul = CreateClientConVar("vrmod_rtHeight_Multiplier", "1.0", true, FCVAR_ARCHIVE)
			local error = vrmod.GetStartupError()
			if error then
				print("VRMod failed to start: " .. error)

				return
			end

			if errorout:GetBool() then
				VRMOD_Shutdown() --in case we're retrying after an error and shutdown wasn't called
			end

			if VRMOD_Init() == false then
				print("vr init failed")

				return
			end

			local displayInfo = VRMOD_GetDisplayInfo(1, 10)
			local rtWidth, rtHeight = displayInfo.RecommendedWidth * rtWidthMul:GetFloat(), displayInfo.RecommendedHeight * rtHeightMul:GetFloat()
			local rtWidthright = rtWidth / 2
			if system.IsLinux() then
				rtWidth, rtHeight = math.min(4096, pow2ceil(rtWidth)), math.min(4096, pow2ceil(rtHeight)) --todo pow2ceil might not be necessary
			end

			VRMOD_ShareTextureBegin()
			if uirendertype:GetBool() then
				g_VR.rt = GetRenderTarget("vrmod_rt" .. tostring(SysTime()), rtWidth, rtHeight)
			else
				g_VR.rt = GetRenderTargetEx("vrmod_rt" .. tostring(SysTime()), rtWidth, rtHeight, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, 16, CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_DEFAULT)
			end

			VRMOD_ShareTextureFinish()
			--
			local displayCalculations = {
				left = {},
				right = {}
			}

			for k, v in pairs(displayCalculations) do
				local mtx = (k == "left") and displayInfo.ProjectionLeft or displayInfo.ProjectionRight
				local xscale = mtx[1][1]
				local xoffset = mtx[1][3]
				local yscale = mtx[2][2]
				local yoffset = mtx[2][3]
				local tan_px = math.abs((1.0 - xoffset) / xscale)
				local tan_nx = math.abs((-1.0 - xoffset) / xscale)
				local tan_py = math.abs((1.0 - yoffset) / yscale)
				local tan_ny = math.abs((-1.0 - yoffset) / yscale)
				local w = tan_px + tan_nx
				local h = tan_py + tan_ny
				v.HorizontalFOV = math.atan(w / 2.0) * 180 / math.pi * 2
				v.AspectRatio = w / h
				v.HorizontalOffset = xoffset
				v.VerticalOffset = yoffset
			end

			local vMin = system.IsWindows() and 0 or 1
			local vMax = system.IsWindows() and 1 or 0
			local uMinLeft = 0.0 + displayCalculations.left.HorizontalOffset * 0.25
			local uMaxLeft = 0.5 + displayCalculations.left.HorizontalOffset * 0.25
			local vMinLeft = vMin - displayCalculations.left.VerticalOffset * 0.5
			local vMaxLeft = vMax - displayCalculations.left.VerticalOffset * 0.5
			local uMinRight = 0.5 + displayCalculations.right.HorizontalOffset * 0.25
			local uMaxRight = 1.0 + displayCalculations.right.HorizontalOffset * 0.25
			local vMinRight = vMin - displayCalculations.right.VerticalOffset * 0.5
			local vMaxRight = vMax - displayCalculations.right.VerticalOffset * 0.5
			VRMOD_SetSubmitTextureBounds(uMinLeft, vMinLeft, uMaxLeft, vMaxLeft, uMinRight, vMinRight, uMaxRight, vMaxRight)
			local hfovLeft = displayCalculations.left.HorizontalFOV
			local hfovRight = displayCalculations.right.HorizontalFOV
			local aspectLeft = displayCalculations.left.AspectRatio
			local aspectRight = displayCalculations.right.AspectRatio
			local ipd = displayInfo.TransformRight[1][4] * 2
			local eyez = displayInfo.TransformRight[3][4]
			--
			--set up active bindings
			VRMOD_SetActionManifest("vrmod/vrmod_action_manifest.txt")
			VRMOD_SetActiveActionSets("/actions/base", LocalPlayer():InVehicle() and "/actions/driving" or "/actions/main")
			VRUtilLoadCustomActions()
			g_VR.input, g_VR.changedInputs = VRMOD_GetActions() --make inputs immediately available
			--start transmit loop and send join msg to server
			VRUtilNetworkInit()
			--set initial origin
			g_VR.origin = LocalPlayer():GetPos()
			--
			g_VR.scale = convars.vrmod_scale:GetFloat()
			--
			g_VR.rightControllerOffsetPos = Vector(convars.vrmod_controlleroffset_x:GetFloat(), convars.vrmod_controlleroffset_y:GetFloat(), convars.vrmod_controlleroffset_z:GetFloat())
			g_VR.leftControllerOffsetPos = g_VR.rightControllerOffsetPos * Vector(1, -1, 1)
			g_VR.rightControllerOffsetAng = Angle(convars.vrmod_controlleroffset_pitch:GetFloat(), convars.vrmod_controlleroffset_yaw:GetFloat(), convars.vrmod_controlleroffset_roll:GetFloat())
			g_VR.leftControllerOffsetAng = g_VR.rightControllerOffsetAng
			g_VR.active = true
			--overrideConvar("engine_no_focus_sleep", "1")
			overrideConvar("playerscaling_clientspeed", "0")
			overrideConvar("playerscaling_clientjump", "0")

			if autoarcbench:GetBool() then
				overrideConvar("arccw_hud_size", "0")
				overrideConvar("arccw_dev_benchgun", "1")
				overrideConvar("arc9_dev_benchgun", "1")
				overrideConvar("arc9_cruelty_reload", "0")
				overrideConvar("arc9_tpik", "0")
			end

			--overrideConvar("pac_suppress_frames", "0")
			--overrideConvar("pac_override_fov", 1)
			--3D audio fix
			hook.Add(
				"CalcView",
				"vrutil_hook_calcview",
				function(ply, pos, ang, fv)
					return {
						origin = g_VR.tracking.hmd.pos,
						angles = g_VR.tracking.hmd.ang,
						fov = fv
					}
				end
			)

			vrmod.StartLocomotion()
			g_VR.tracking = {
				hmd = {
					pos = LocalPlayer():GetPos() + Vector(0, 0, convarValues.vrmod_characterEyeHeight),
					ang = Angle(),
					vel = Vector(),
					angvel = Angle()
				},
				pose_lefthand = {
					pos = LocalPlayer():GetPos(),
					ang = Angle(),
					vel = Vector(),
					angvel = Angle()
				},
				pose_righthand = {
					pos = LocalPlayer():GetPos(),
					ang = Angle(),
					vel = Vector(),
					angvel = Angle()
				},
			}

			g_VR.threePoints = true
			--simulate missing hands
			local simulate = {
				{
					pose = g_VR.tracking.pose_lefthand,
					offset = Vector(0, 0, 0)
				},
				{
					pose = g_VR.tracking.pose_righthand,
					offset = Vector(0, 0, 0)
				},
			}

			for k, v in ipairs(simulate) do
				v.pose.simulatedPos = v.pose.pos
			end

			hook.Add(
				"VRMod_Tracking",
				"simulatehands",
				function()
					for k, v in ipairs(simulate) do
						if v.pose.pos == v.pose.simulatedPos then
							v.pose.pos, v.pose.ang = LocalToWorld(v.offset, Angle(90, 0, 0), g_VR.tracking.hmd.pos, Angle(0, g_VR.tracking.hmd.ang.yaw, 0))
							v.pose.simulatedPos = v.pose.pos
						else
							v.pose.simulatedPos = nil
							table.remove(simulate, k)
						end
					end

					if #simulate == 0 then
						hook.Remove("VRMod_Tracking", "simulatehands")
					end
				end
			)

			--rendering
			g_VR.view = {
				x = 0,
				y = 0,
				w = rtWidthright,
				h = rtHeight,
				--aspectratio = aspect, --fov = hfov,
				drawmonitors = true,
				drawviewmodel = false,
				znear = convars.vrmod_znear:GetFloat(),
				dopostprocess = convars.vrmod_postprocess:GetBool()
			}

			local desktopView = convars.vrmod_desktopview:GetInt()
			local cropVerticalMargin = (1 - (vrScrH:GetInt() / vrScrW:GetInt() * rtWidthright / rtHeight)) / 2
			local cropVerticalMargin02 = 1 - cropVerticalMargin
			local cropHorizontalOffset = (desktopView == 3) and 0.5 or 0
			local cropHorizontalOffset02 = 0.5 + cropHorizontalOffset
			local mat_rt = CreateMaterial(
				"vrmod_mat_rt" .. tostring(SysTime()),
				"UnlitGeneric",
				{
					["$basetexture"] = g_VR.rt:GetName()
				}
			)

			local localply = LocalPlayer()
			local cameraover = CreateClientConVar("vrmod_cameraoverride", 1, true, FCVAR_ARCHIVE)
			local currentViewEnt = localply
			local pos1, ang1
			local uselefthand = CreateClientConVar("vrmod_LeftHand", 0, true, FCVAR_ARCHIVE)
			local lefthandmode = CreateClientConVar("vrmod_LeftHandmode", 0, true, FCVAR_ARCHIVE)
			local foregripmode = CreateClientConVar("vrmod_Foregripmode", 0, false)
			local cv_foregrip_rotation_sensitivity = CreateClientConVar("vrmod_foregrip_rotation_sensitivity", "1.0", true, FCVAR_ARCHIVE)
			local cv_foregrip_pitch_blend = CreateClientConVar("vrmod_foregrip_pitch_blend", "1.0", true, FCVAR_ARCHIVE)
			local cv_foregrip_yaw_blend = CreateClientConVar("vrmod_foregrip_yaw_blend", "1.0", true, FCVAR_ARCHIVE)
			local cv_foregrip_roll_blend = CreateClientConVar("vrmod_foregrip_roll_blend", "0.05", true, FCVAR_ARCHIVE)
			-- g_VR.LeftView = {
			-- 	x = 0,
			-- 	y = 0,
			-- 	w = rtWidthright,
			-- 	h = rtHeight,
			-- 	drawmonitors = false,
			-- 	drawviewmodel = false,
			-- 	znear = convars.vrmod_znear:GetFloat(),
			-- 	dopostprocess = convars.vrmod_postprocess:GetBool()
			-- }
			-- g_VR.RightView = {
			-- 	x = rtWidthright,
			-- 	y = 0,
			-- 	w = rtWidthright,
			-- 	h = rtHeight,
			-- 	drawmonitors = false,
			-- 	drawviewmodel = false,
			-- 	znear = convars.vrmod_znear:GetFloat(),
			-- 	dopostprocess = convars.vrmod_postprocess:GetBool()
			-- }
			-- local function RenderLeftEye()
			-- 	g_VR.LeftView.origin = g_VR.eyePosLeft
			-- 	g_VR.LeftView.fov = hfovLeft
			-- 	g_VR.LeftView.aspectratio = aspectLeft
			-- 	hook.Call("VRMod_PreRender")
			-- 	render.RenderView(g_VR.LeftView)
			-- end
			-- local function RenderRightEye()
			-- 	g_VR.RightView.origin = g_VR.eyePosRight
			-- 	g_VR.RightView.fov = hfovRight
			-- 	g_VR.RightView.aspectratio = aspectRight
			-- 	hook.Call("VRMod_PreRenderRight")
			-- 	render.RenderView(g_VR.RightView)
			-- end
			hook.Add(
				"RenderScene",
				"vrutil_hook_renderscene",
				function()
					VRMOD_SubmitSharedTexture()
					VRMOD_UpdatePosesAndActions()
					--handle tracking
					local rawPoses = VRMOD_GetPoses()
					for k, v in pairs(rawPoses) do
						g_VR.tracking[k] = g_VR.tracking[k] or {}
						local worldPose = g_VR.tracking[k]
						worldPose.pos, worldPose.ang = LocalToWorld(v.pos * g_VR.scale, v.ang, g_VR.origin, g_VR.originAngle)
						worldPose.vel = LocalToWorld(v.vel, Angle(0, 0, 0), Vector(0, 0, 0), g_VR.originAngle) * g_VR.scale
						worldPose.angvel = LocalToWorld(Vector(v.angvel.pitch, v.angvel.yaw, v.angvel.roll), Angle(0, 0, 0), Vector(0, 0, 0), g_VR.originAngle)
						if k == "pose_righthand" then
							worldPose.pos, worldPose.ang = LocalToWorld(g_VR.rightControllerOffsetPos * 0.01 * g_VR.scale, g_VR.rightControllerOffsetAng, worldPose.pos, worldPose.ang)
						elseif k == "pose_lefthand" then
							worldPose.pos, worldPose.ang = LocalToWorld(g_VR.leftControllerOffsetPos * 0.01 * g_VR.scale, g_VR.leftControllerOffsetAng, worldPose.pos, worldPose.ang)
						end
					end

					g_VR.sixPoints = (g_VR.tracking.pose_waist and g_VR.tracking.pose_leftfoot and g_VR.tracking.pose_rightfoot) ~= nil
					hook.Call("VRMod_Tracking")
					--handle input
					g_VR.input, g_VR.changedInputs = VRMOD_GetActions()
					for k, v in pairs(g_VR.changedInputs) do
						hook.Call("VRMod_Input", nil, k, v)
					end

					--lefthand&foregrip start
					--gripmode start
					if foregripmode:GetBool() then
						local netFrame = VRUtilNetUpdateLocalPly()
						if g_VR.currentvmi then
							local rightHandPos, rightHandAng = g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang
							local leftHandPos, leftHandAng = g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang
							-- 感度に基づいて左手と右手の角度を補間
							local sensitivity = cv_foregrip_rotation_sensitivity:GetFloat()
							local pitchBlend = cv_foregrip_pitch_blend:GetFloat()
							local yawBlend = cv_foregrip_yaw_blend:GetFloat()
							local rollBlend = cv_foregrip_roll_blend:GetFloat()
							local blendedAng = Angle(Lerp(pitchBlend, rightHandAng.p, leftHandAng.p), Lerp(yawBlend, rightHandAng.y, leftHandAng.y), Lerp(rollBlend, rightHandAng.r, leftHandAng.r))
							-- 全体的な感度を適用
							blendedAng = LerpAngle(sensitivity, rightHandAng, blendedAng)
							local pos, ang = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, rightHandPos, blendedAng)
							g_VR.viewModelPos = pos
							g_VR.viewModelAng = ang
						end

						if IsValid(g_VR.viewModel) then
							if not g_VR.usingWorldModels then
								g_VR.viewModel:SetPos(g_VR.viewModelPos)
								g_VR.viewModel:SetAngles(g_VR.viewModelAng)
								g_VR.viewModel:SetupBones()
								if netFrame then
									local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
									if b then
										local mtx = g_VR.viewModel:GetBoneMatrix(b)
										netFrame.righthandPos = mtx:GetTranslation()
										netFrame.righthandAng = mtx:GetAngles() - Angle(0, 0, 180)
									end

									local c = g_VR.viewModel:LookupBone("ValveBiped.Bip01_L_Hand")
									if c then
										local mtxl = g_VR.viewModel:GetBoneMatrix(c)
										netFrame.lefthandPos = mtxl:GetTranslation()
										netFrame.lefthandAng = mtxl:GetAngles() - Angle(0, 0, 0)
									end
								end
							end

							g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
						end
					else --lefthandmode start
						if uselefthand:GetBool() then
							if lefthandmode:GetBool() then
								--lefthand-Type2(RhandSimurate) Start
								local netFrame = VRUtilNetUpdateLocalPly()
								--update viewmodel position
								if g_VR.currentvmi then
									local pos, ang = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang)
									g_VR.viewModelPos = pos
									g_VR.viewModelAng = ang
								end

								if IsValid(g_VR.viewModel) then
									if not g_VR.usingWorldModels then
										g_VR.viewModel:SetPos(g_VR.viewModelPos)
										g_VR.viewModel:SetAngles(g_VR.viewModelAng)
										g_VR.viewModel:SetupBones()
										--override hand pose in net frame
										if netFrame then
											local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
											if b then
												local mtx = g_VR.viewModel:GetBoneMatrix(b)
												netFrame.lefthandPos = mtx:GetTranslation()
												netFrame.lefthandAng = mtx:GetAngles() - Angle(0, 0, 180)
											end
										end
									end

									g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
								end
								--lefthand-Type2(RhandSimurate) end
							else
								--lefthand-type1(Bip01_L_hand Posirion) start						
								local netFrame = VRUtilNetUpdateLocalPly()
								--update viewmodel position
								if g_VR.currentvmi then
									local pos, ang = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang)
									g_VR.viewModelPos = pos
									g_VR.viewModelAng = ang
								end

								if IsValid(g_VR.viewModel) then
									if not g_VR.usingWorldModels then
										g_VR.viewModel:SetPos(g_VR.viewModelPos)
										g_VR.viewModel:SetAngles(g_VR.viewModelAng)
										g_VR.viewModel:SetupBones()
										--override hand pose in net frame
										if netFrame then
											local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_L_Hand")
											if b then
												local mtx = g_VR.viewModel:GetBoneMatrix(b)
												netFrame.lefthandPos = mtx:GetTranslation()
												netFrame.lefthandAng = mtx:GetAngles() - Angle(0, 0, 0)
											end
										end
									end

									g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
								end
								--lefthand-type1(Bip01_L_hand Posirion) end
							end
							--lefthandmode end
						else
							--righthand start
							local netFrame = VRUtilNetUpdateLocalPly()
							--update viewmodel position
							if g_VR.currentvmi then
								local pos, ang = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang)
								g_VR.viewModelPos = pos
								g_VR.viewModelAng = ang
							end

							if IsValid(g_VR.viewModel) then
								if not g_VR.usingWorldModels then
									g_VR.viewModel:SetPos(g_VR.viewModelPos)
									g_VR.viewModel:SetAngles(g_VR.viewModelAng)
									g_VR.viewModel:SetupBones()
									--override hand pose in net frame
									if netFrame then
										local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
										if b then
											local mtx = g_VR.viewModel:GetBoneMatrix(b)
											netFrame.righthandPos = mtx:GetTranslation()
											netFrame.righthandAng = mtx:GetAngles() - Angle(0, 0, 180)
										end
									end
								end

								g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
							end
						end
						--righthand end
					end

					--lefthand&foregrip end
					--righthand end
					--set view according to viewentity
					local viewEnt = localply:GetViewEntity()
					if viewEnt ~= localply then
						local rawPos, rawAng = WorldToLocal(g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang, g_VR.origin, g_VR.originAngle)
						if viewEnt ~= currentViewEnt then
							local pos, ang = LocalToWorld(rawPos, rawAng, viewEnt:GetPos(), viewEnt:GetAngles())
							pos1, ang1 = WorldToLocal(viewEnt:GetPos(), viewEnt:GetAngles(), pos, ang)
						end

						rawPos, rawAng = LocalToWorld(rawPos, rawAng, pos1, ang1)
						g_VR.view.origin, g_VR.view.angles = LocalToWorld(rawPos, rawAng, viewEnt:GetPos(), viewEnt:GetAngles())
					else
						g_VR.view.origin, g_VR.view.angles = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
					end

					currentViewEnt = viewEnt
					local ipdeye = ipd * 0.5 * g_VR.scale
					--
					g_VR.view.origin = g_VR.view.origin + g_VR.view.angles:Forward() * -(eyez * g_VR.scale)
					g_VR.eyePosLeft = g_VR.view.origin + g_VR.view.angles:Right() * -ipdeye
					g_VR.eyePosRight = g_VR.view.origin + g_VR.view.angles:Right() * ipdeye
					render.PushRenderTarget(g_VR.rt)
					-- local rightEyeThread = coroutine.create(RenderRightEye)
					-- local leftEyeThread = coroutine.create(RenderLeftEye)
					-- left
					g_VR.view.origin = g_VR.eyePosLeft
					g_VR.view.x = 0
					g_VR.view.fov = hfovLeft
					g_VR.view.aspectratio = aspectLeft
					hook.Call("VRMod_PreRender")
					render.RenderView(g_VR.view)
					-- local rightEyeThread = coroutine.create(RenderRightEye)
					-- coroutine.resume(rightEyeThread) 
					--
					-- right
					g_VR.view.origin = g_VR.eyePosRight
					g_VR.view.x = rtWidthright
					g_VR.view.fov = hfovRight
					g_VR.view.aspectratio = aspectRight
					hook.Call("VRMod_PreRenderRight")
					render.RenderView(g_VR.view)
					-- local leftEyeThread = coroutine.create(RenderLeftEye)
					-- coroutine.resume(leftEyeThread)
					--
					if not LocalPlayer():Alive() then
						cam.Start2D()
						surface.SetDrawColor(14, 14, 14, 220)
						surface.DrawRect(0, 0, rtWidth, rtHeight)
						cam.End2D()
					end

					render.PopRenderTarget(g_VR.rt)
					if desktopView > 1 then
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(mat_rt)
						render.CullMode(1)
						surface.DrawTexturedRectUV(-1, -1, 2, 2, cropHorizontalOffset, cropVerticalMargin02, cropHorizontalOffset02, cropVerticalMargin)
						render.CullMode(0)
					end

					hook.Call("VRMod_PostRender")

					return cameraover:GetBool()
				end
			)

			--return true to override default scene rendering
			g_VR.usingWorldModels = convars.vrmod_useworldmodels:GetBool()
			if not g_VR.usingWorldModels then
				overrideConvar("viewmodel_fov", GetConVar("fov_desired"):GetString())
				hook.Add("CalcViewModelView", "vrutil_hook_calcviewmodelview", function(wep, vm, oldPos, oldAng, pos, ang) return g_VR.viewModelPos, g_VR.viewModelAng end)
				local blockViewModelDraw = true
				g_VR.allowPlayerDraw = false
				local hideplayer = convars.vrmod_floatinghands:GetBool()
				hook.Add(
					"PostDrawTranslucentRenderables",
					"vrutil_hook_drawplayerandviewmodel",
					function(bDrawingDepth, bDrawingSkybox)
						if bDrawingSkybox or not LocalPlayer():Alive() or not (EyePos() == g_VR.eyePosLeft or EyePos() == g_VR.eyePosRight) then return end
						if IsValid(g_VR.viewModel) then
							blockViewModelDraw = false
							g_VR.viewModel:DrawModel()
							blockViewModelDraw = true
						end

						if not hideplayer then
							g_VR.allowPlayerDraw = true
							cam.Start3D()
							cam.End3D()
							local tmp = render.GetBlend()
							render.SetBlend(1)
							LocalPlayer():DrawModel()
							render.SetBlend(tmp)
							cam.Start3D()
							cam.End3D()
							g_VR.allowPlayerDraw = false
						end

						VRUtilRenderMenuSystem()
					end
				)

				hook.Add("PreDrawPlayerHands", "vrutil_hook_predrawplayerhands", function() return true end)
				hook.Add("PreDrawViewModel", "vrutil_hook_predrawviewmodel", function(vm, ply, wep) return blockViewModelDraw or nil end)
			else
				g_VR.allowPlayerDraw = true
				hook.Add(
					"PostDrawTranslucentRenderables",
					"vrutil_hook_drawplayerandviewmodel",
					function(bDrawingDepth, bDrawingSkybox)
						if bDrawingSkybox or not LocalPlayer():Alive() or not (EyePos() == g_VR.eyePosLeft or EyePos() == g_VR.eyePosRight) then return end
						VRUtilRenderMenuSystem()
					end
				)
			end

			hook.Add("ShouldDrawLocalPlayer", "vrutil_hook_shoulddrawlocalplayer", function(ply) return g_VR.allowPlayerDraw end)
			-- add laser pointer
			if convars.vrmod_laserpointer:GetBool() then
				local mat = Material("cable/redlaser")
				hook.Add(
					"PostDrawTranslucentRenderables",
					"vr_laserpointer",
					function(bDrawingDepth, bDrawingSkybox)
						if bDrawingSkybox then return end
						if g_VR.viewModelMuzzle and not g_VR.menuFocus then
							render.SetMaterial(mat)
							render.DrawBeam(g_VR.viewModelMuzzle.Pos, g_VR.viewModelMuzzle.Pos + g_VR.viewModelMuzzle.Ang:Forward() * 10000, 1, 0, 1, Color(255, 255, 255, 255))
						end
					end
				)
			end
		end

		function VRUtilClientExit()
			if not g_VR.active then return end
			restoreConvarOverrides()
			VRUtilMenuClose()
			VRUtilNetworkCleanup()
			vrmod.StopLocomotion()

			RunConsoleCommand("vrmod_character_stop")
			overrideConvar("godsenttools_gpu_saver", "1")
			overrideConvar("lithium_enable_gpusaver", "1")
			if IsValid(g_VR.viewModel) and g_VR.viewModel:GetClass() == "class C_BaseFlex" then
				g_VR.viewModel:Remove()
			end

			if g_VR.rt then
				g_VR.rt = nil
			end

			g_VR.rt = nil
			g_VR.viewModel = nil
			g_VR.viewModelMuzzle = nil
			LocalPlayer():GetViewModel().RenderOverride = nil
			LocalPlayer():GetViewModel():RemoveEffects(EF_NODRAW)
			hook.Remove("RenderScene", "vrutil_hook_renderscene")
			hook.Remove("PreDrawViewModel", "vrutil_hook_predrawviewmodel")
			hook.Remove("DrawPhysgunBeam", "vrutil_hook_drawphysgunbeam")
			hook.Remove("PreDrawHalos", "vrutil_hook_predrawhalos")
			hook.Remove("EntityFireBullets", "vrutil_hook_entityfirebullets")
			hook.Remove("Tick", "vrutil_hook_tick")
			hook.Remove("PostDrawSkyBox", "vrutil_hook_postdrawskybox")
			hook.Remove("CalcView", "vrutil_hook_calcview")
			hook.Remove("PostDrawTranslucentRenderables", "vr_laserpointer")
			hook.Remove("CalcViewModelView", "vrutil_hook_calcviewmodelview")
			hook.Remove("PostDrawTranslucentRenderables", "vrutil_hook_drawplayerandviewmodel")
			hook.Remove("PreDrawPlayerHands", "vrutil_hook_predrawplayerhands")
			hook.Remove("PreDrawViewModel", "vrutil_hook_predrawviewmodel")
			hook.Remove("ShouldDrawLocalPlayer", "vrutil_hook_shoulddrawlocalplayer")
			g_VR.tracking = {}
			g_VR.threePoints = false
			g_VR.sixPoints = false
			VRMOD_Shutdown()
			g_VR.active = false

			if autoarcbench:GetBool() then
				overrideConvar("arccw_dev_benchgun", "0")
				overrideConvar("arccw_hud_size", "1")
				overrideConvar("arc9_dev_benchgun", "0")
			end


		end

		hook.Add(
			"ShutDown",
			"vrutil_hook_shutdown",
			function()
				if IsValid(LocalPlayer()) and g_VR.net[LocalPlayer():SteamID()] then
					VRUtilClientExit()
				end
			end
		)

		-- g_VR.rtとg_VR.viewをリセットするconcommandを追加
		concommand.Add(
			"vrmod_reset_render_targets",
			function(ply, cmd, args)
				if g_VR.active then
					VRUtilClientExit()
				end

				-- 現在のg_VR.rtを削除
				if g_VR.rt then
					render.ReleaseRenderTarget(g_VR.rt)
					g_VR.rt = nil
				end

				-- 新しいg_VR.rtを作成
				local rtWidth, rtHeight = g_VR.view.w * 2, g_VR.view.h
				g_VR.rt = GetRenderTargetEx("vrmod_rt" .. tostring(SysTime()), rtWidth, rtHeight, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, 16, CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_DEFAULT)
				-- g_VR.viewの設定をリセット
				g_VR.view.w = rtWidth / 2
				g_VR.view.h = rtHeight
				g_VR.view.aspectratio = g_VR.view.w / g_VR.view.h
				g_VR.view.fov = g_VR.defaultFOV
				g_VR.view.znear = convarValues.vrmod_znear
				g_VR.view.dopostprocess = convarValues.vrmod_postprocess
				print("VRMod render targets and view settings have been reset.")
			end
		)

		-- g_VR.rtとg_VR.viewを現在の設定で更新するconcommandを追加
		concommand.Add(
			"vrmod_update_render_targets",
			function(ply, cmd, args)
				if g_VR.active then
					VRUtilClientExit()
				end

				-- 現在のg_VR.rtを削除
				if g_VR.rt then
					render.ReleaseRenderTarget(g_VR.rt)
					g_VR.rt = nil
				end

				-- 新しいg_VR.rtを作成
				local rtWidth, rtHeight = g_VR.view.w * 2, g_VR.view.h
				g_VR.rt = GetRenderTargetEx("vrmod_rt" .. tostring(SysTime()), rtWidth, rtHeight, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, 16, CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_DEFAULT)
				print("VRMod render targets have been updated with current settings.")
			end
		)
	elseif SERVER then
		CreateClientConVar("vrmod_version", vrmod.GetVersion(), false, FCVAR_NOTIFY)
	end
end

vrmod_lua()
concommand.Add(
	"vrmod_lua_reset",
	function(ply, cmd, args)
		AddCSLuaFile("vrmodunoffcial/vrmod.lua")
		include("vrmodunoffcial/vrmod.lua")
		vrmod_lua()
	end
)