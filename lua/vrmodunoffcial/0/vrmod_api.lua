local addonVersion = 133
local requiredModuleVersion = 20
local latestModuleVersion = 21
g_VR = g_VR or {}
vrmod = vrmod or {}
local convars, convarValues = {}, {}
function vrmod.AddCallbackedConvar(cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc)
	valueName, flags, conversionFunc = valueName or cvarName, flags or FCVAR_ARCHIVE, conversionFunc or function(val) return val end
	local cv = CreateClientConVar(cvarName, defaultValue, true, flags, helptext, min, max)
	convars[cvarName], convarValues[valueName] = cv, conversionFunc(cv:GetString())
	cvars.AddChangeCallback(
		cvarName,
		function(cv_name, val_old, val_new)
			convarValues[valueName] = conversionFunc(val_new)
			if callbackFunc then
				callbackFunc(convarValues[valueName])
			end
		end, "vrmod"
	)

	return convars, convarValues
end

function vrmod.GetConvars()
	return convars, convarValues
end

function vrmod.GetVersion()
	return addonVersion
end

if CLIENT then
	local errorenable = CreateClientConVar("vrmod_error_hard", 0, true, FCVAR_ARCHIVE)
	g_VR.net = g_VR.net or {}
	g_VR.viewModelInfo = g_VR.viewModelInfo or {}
	g_VR.locomotionOptions = g_VR.locomotionOptions or {}
	g_VR.menuItems = g_VR.menuItems or {}
	function vrmod.GetStartupError()
		local error = nil
		if errorenable:GetBool() then
			if not g_VR.moduleVersion then
				if not file.Exists("lua/bin/gmcl_vrmod_win32.dll", "GAME") then
					error = "Module not installed. Read the workshop description for instructions.\n"
				else
					error = "Failed to load module\n"
				end
			elseif g_VR.active then
				error = "Already running"
			elseif VRMOD_IsHMDPresent and not VRMOD_IsHMDPresent() then
				error = "VR headset not detected\n"
			end
		else
			error = nil
		end

		return error
	end

	function vrmod.GetModuleVersion()
		return g_VR.moduleVersion, requiredModuleVersion, latestModuleVersion
	end

	function vrmod.IsPlayerInVR(ply)
		return g_VR.net[ply and ply:SteamID() or LocalPlayer():SteamID()] ~= nil
	end

	function vrmod.UsingEmptyHands(ply)
		local wep = ply and ply:GetActiveWeapon() or LocalPlayer():GetActiveWeapon()

		return IsValid(wep) and wep:GetClass() == "weapon_vrmod_empty" or false
	end

	function vrmod.GetHMDPos(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]

		return t and t.lerpedFrame and t.lerpedFrame.hmdPos or Vector()
	end

	function vrmod.GetHMDAng(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]

		return t and t.lerpedFrame and t.lerpedFrame.hmdAng or Angle()
	end

	function vrmod.GetHMDPose(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then return t.lerpedFrame.hmdPos, t.lerpedFrame.hmdAng end

		return Vector(), Angle()
	end

	function vrmod.GetHMDVelocity()
		return g_VR.threePoints and g_VR.tracking.hmd.vel or Vector()
	end

	function vrmod.GetHMDAngularVelocity()
		return g_VR.threePoints and g_VR.tracking.hmd.angvel or Vector()
	end

	function vrmod.GetHMDVelocities()
		if g_VR.threePoints then return g_VR.tracking.hmd.vel, g_VR.tracking.hmd.angvel end

		return Vector(), Vector()
	end

	function vrmod.GetLeftHandPos(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]

		return t and t.lerpedFrame and t.lerpedFrame.lefthandPos or Vector()
	end

	function vrmod.GetLeftHandAng(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]

		return t and t.lerpedFrame and t.lerpedFrame.lefthandAng or Angle()
	end

	function vrmod.GetLeftHandPose(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then return t.lerpedFrame.lefthandPos, t.lerpedFrame.lefthandAng end

		return Vector(), Angle()
	end

	function vrmod.GetLeftHandVelocity()
		return g_VR.threePoints and g_VR.tracking.pose_lefthand.vel or Vector()
	end

	function vrmod.GetLeftHandAngularVelocity()
		return g_VR.threePoints and g_VR.tracking.pose_lefthand.angvel or Vector()
	end

	function vrmod.GetLeftHandVelocities()
		if g_VR.threePoints then return g_VR.tracking.pose_lefthand.vel, g_VR.tracking.pose_lefthand.angvel end

		return Vector(), Vector()
	end

	function vrmod.GetRightHandPos(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]

		return t and t.lerpedFrame and t.lerpedFrame.righthandPos or Vector()
	end

	function vrmod.GetRightHandAng(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]

		return t and t.lerpedFrame and t.lerpedFrame.righthandAng or Angle()
	end

	function vrmod.GetRightHandPose(ply)
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then return t.lerpedFrame.righthandPos, t.lerpedFrame.righthandAng end

		return Vector(), Angle()
	end

	function vrmod.GetRightHandVelocity()
		return g_VR.threePoints and g_VR.tracking.pose_righthand.vel or Vector()
	end

	function vrmod.GetRightHandAngularVelocity()
		return g_VR.threePoints and g_VR.tracking.pose_righthand.angvel or Vector()
	end

	function vrmod.GetRightHandVelocities()
		if g_VR.threePoints then return g_VR.tracking.pose_righthand.vel, g_VR.tracking.pose_righthand.angvel end

		return Vector(), Vector()
	end

	function vrmod.SetLeftHandPose(pos, ang)
		local t = g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then
			t.lerpedFrame.lefthandPos, t.lerpedFrame.lefthandAng = pos, ang
		end
	end

	function vrmod.SetRightHandPose(pos, ang)
		local t = g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then
			t.lerpedFrame.righthandPos, t.lerpedFrame.righthandAng = pos, ang
		end
	end

	function vrmod.GetLeftHandOpenFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.openHandAngles[i]
		end

		return r
	end

	function vrmod.GetLeftHandClosedFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.closedHandAngles[i]
		end

		return r
	end

	function vrmod.GetRightHandOpenFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.openHandAngles[15 + i]
		end

		return r
	end

	function vrmod.GetRightHandClosedFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.closedHandAngles[15 + i]
		end

		return r
	end

	function vrmod.SetLeftHandOpenFingerAngles(tbl)
		local t = table.Copy(g_VR.openHandAngles)
		for i = 1, 15 do
			t[i] = tbl[i]
		end

		g_VR.openHandAngles = t
	end

	function vrmod.SetLeftHandClosedFingerAngles(tbl)
		local t = table.Copy(g_VR.closedHandAngles)
		for i = 1, 15 do
			t[i] = tbl[i]
		end

		g_VR.closedHandAngles = t
	end

	function vrmod.SetRightHandOpenFingerAngles(tbl)
		local t = table.Copy(g_VR.openHandAngles)
		for i = 1, 15 do
			t[15 + i] = tbl[i]
		end

		g_VR.openHandAngles = t
	end

	function vrmod.SetRightHandClosedFingerAngles(tbl)
		local t = table.Copy(g_VR.closedHandAngles)
		for i = 1, 15 do
			t[15 + i] = tbl[i]
		end

		g_VR.closedHandAngles = t
	end

	function vrmod.GetDefaultLeftHandOpenFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.defaultOpenHandAngles[i]
		end

		return r
	end

	function vrmod.GetDefaultLeftHandClosedFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.defaultClosedHandAngles[i]
		end

		return r
	end

	function vrmod.GetDefaultRightHandOpenFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.defaultOpenHandAngles[15 + i]
		end

		return r
	end

	function vrmod.GetDefaultRightHandClosedFingerAngles()
		local r = {}
		for i = 1, 15 do
			r[i] = g_VR.defaultClosedHandAngles[15 + i]
		end

		return r
	end

	local fingerAngleCache = {}
	local fingerAngleCachePM = ""
	local function GetFingerAnglesFromModel(modelName, sequenceNumber)
		sequenceNumber = sequenceNumber or 0
		local pm = convars.vrmod_floatinghands:GetBool() and "models/weapons/c_arms.mdl" or LocalPlayer():GetModel()
		if fingerAngleCachePM ~= pm then
			fingerAngleCachePM = pm
			fingerAngleCache = {}
		end

		local cache = fingerAngleCache[modelName .. sequenceNumber]
		if cache then return cache end
		local pmdl = ClientsideModel(pm)
		pmdl:SetupBones()
		local tmdl = ClientsideModel(modelName)
		tmdl:ResetSequence(sequenceNumber)
		tmdl:SetupBones()
		local tmp = {"0", "01", "02", "1", "11", "12", "2", "21", "22", "3", "31", "32", "4", "41", "42"}
		local r = {}
		for i = 1, 30 do
			r[i] = Angle() -- Default angle
			local fingerBoneName = "ValveBiped.Bip01_" .. ((i < 16) and "L" or "R") .. "_Finger" .. tmp[i - (i < 16 and 0 or 15)]
			local pfinger = pmdl:LookupBone(fingerBoneName) or -1
			local tfinger = tmdl:LookupBone(fingerBoneName) or -1
			local pBoneMatrix = pmdl:GetBoneMatrix(pfinger)
			local pParentBoneMatrix = pmdl:GetBoneMatrix(pmdl:GetBoneParent(pfinger))
			if pBoneMatrix and pParentBoneMatrix then
				local _, pmoffset = WorldToLocal(Vector(0, 0, 0), pBoneMatrix:GetAngles(), Vector(0, 0, 0), pParentBoneMatrix:GetAngles())
				if tfinger ~= -1 then
					local tBoneMatrix = tmdl:GetBoneMatrix(tfinger)
					local tParentBoneMatrix = tmdl:GetBoneMatrix(tmdl:GetBoneParent(tfinger))
					if tBoneMatrix and tParentBoneMatrix then
						local _, tmoffset = WorldToLocal(Vector(0, 0, 0), tBoneMatrix:GetAngles(), Vector(0, 0, 0), tParentBoneMatrix:GetAngles())
						r[i] = tmoffset - pmoffset
					end
				end
			end
		end

		pmdl:Remove()
		tmdl:Remove()
		fingerAngleCache[modelName .. sequenceNumber] = r

		return r
	end

	function vrmod.GetLeftHandFingerAnglesFromModel(modelName, sequenceNumber)
		local angles = GetFingerAnglesFromModel(modelName, sequenceNumber)
		local r = {}
		for i = 1, 15 do
			r[i] = angles[i]
		end

		return r
	end

	function vrmod.GetRightHandFingerAnglesFromModel(modelName, sequenceNumber)
		local angles = GetFingerAnglesFromModel(modelName, sequenceNumber)
		local r = {}
		for i = 1, 15 do
			r[i] = angles[15 + i]
		end

		return r
	end

	local function GetRelativeBonePoseFromModel(modelName, sequenceNumber, boneName, refBoneName)
		local ent = ClientsideModel(modelName)
		ent:ResetSequence(sequenceNumber or 0)
		ent:SetupBones()
		local mtx, mtxRef = ent:GetBoneMatrix(ent:LookupBone(boneName)), ent:GetBoneMatrix(refBoneName and ent:LookupBone(refBoneName) or 0)
		local relativePos, relativeAng = WorldToLocal(mtx:GetTranslation(), mtx:GetAngles(), mtxRef:GetTranslation(), mtxRef:GetAngles())
		ent:Remove()

		return relativePos, relativeAng
	end

	function vrmod.GetLeftHandPoseFromModel(modelName, sequenceNumber, refBoneName)
		return GetRelativeBonePoseFromModel(modelName, sequenceNumber, "ValveBiped.Bip01_L_Hand", refBoneName)
	end

	function vrmod.GetRightHandPoseFromModel(modelName, sequenceNumber, refBoneName)
		return GetRelativeBonePoseFromModel(modelName, sequenceNumber, "ValveBiped.Bip01_R_Hand", refBoneName)
	end

	function vrmod.GetLerpedFingerAngles(fraction, from, to)
		local r = {}
		for i = 1, 15 do
			r[i] = LerpAngle(fraction, from[i], to[i])
		end

		return r
	end

	function vrmod.GetLerpedHandPose(fraction, fromPos, fromAng, toPos, toAng)
		return LerpVector(fraction, fromPos, toPos), LerpAngle(fraction, fromAng, toAng)
	end

	function vrmod.GetInput(name)
		return g_VR.input[name]
	end

	vrmod.MenuCreate = function() end
	vrmod.MenuClose = function() end
	vrmod.MenuExists = function() end
	vrmod.MenuRenderStart = function() end
	vrmod.MenuRenderEnd = function() end
	vrmod.MenuCursorPos = function() return g_VR.menuCursorX, g_VR.menuCursorY end
	vrmod.MenuFocused = function() return g_VR.menuFocus end
	timer.Simple(
		0,
		function()
			vrmod.MenuCreate = VRUtilMenuOpen
			vrmod.MenuClose = VRUtilMenuClose
			vrmod.MenuExists = VRUtilIsMenuOpen
			vrmod.MenuRenderStart = VRUtilMenuRenderStart
			vrmod.MenuRenderEnd = VRUtilMenuRenderEnd
		end
	)

	function vrmod.SetViewModelOffsetForWeaponClass(classname, pos, ang)
		g_VR.viewModelInfo[classname] = g_VR.viewModelInfo[classname] or {}
		g_VR.viewModelInfo[classname].offsetPos = pos
		g_VR.viewModelInfo[classname].offsetAng = ang
	end

	--
	vrmod.AddCallbackedConvar("vrmod_locomotion", nil, "1",FCVAR_ARCHIVE)
	function vrmod.AddLocomotionOption(name, startfunc, stopfunc, buildcpanelfunc)
		g_VR.locomotionOptions[#g_VR.locomotionOptions + 1] = {
			name = name,
			startfunc = startfunc,
			stopfunc = stopfunc,
			buildcpanelfunc = buildcpanelfunc
		}
	end

	function vrmod.StartLocomotion()
		local selectedOption = g_VR.locomotionOptions[convars.vrmod_locomotion:GetInt()]
		if selectedOption then
			selectedOption.startfunc()
		end
	end

	function vrmod.StopLocomotion()
		local selectedOption = g_VR.locomotionOptions[convars.vrmod_locomotion:GetInt()]
		if selectedOption then
			selectedOption.stopfunc()
		end
	end

	hook.Add(
		"VRMod_Menu",
		"locomotion_selection",
		function(frame)
			local locomotionPanel = vgui.Create("DPanel")
			frame.SettingsForm:AddItem(locomotionPanel)
			local dlabel = vgui.Create("DLabel", locomotionPanel)
			dlabel:SetSize(100, 30)
			dlabel:SetPos(5, -3)
			dlabel:SetText("Locomotion:")
			dlabel:SetColor(Color(0, 0, 0))
			local locomotionControls = nil
			local function updateLocomotionCPanel(index)
				if IsValid(locomotionControls) then
					locomotionControls:Remove()
				end

				locomotionControls = vgui.Create("DPanel")
				locomotionControls.Paint = function() end
				g_VR.locomotionOptions[index].buildcpanelfunc(locomotionControls)
				locomotionControls:InvalidateLayout(true)
				locomotionControls:SizeToChildren(true, true)
				locomotionPanel:Add(locomotionControls)
				locomotionControls:Dock(TOP)
				locomotionPanel:InvalidateLayout(true)
				locomotionPanel:SizeToChildren(true, true)
			end

			local DComboBox = vgui.Create("DComboBox")
			locomotionPanel:Add(DComboBox)
			DComboBox:Dock(TOP)
			DComboBox:DockMargin(70, 0, 0, 5)
			DComboBox:SetValue("!ERROR!(Click me to select another item)")
			for i = 1, #g_VR.locomotionOptions do
				DComboBox:AddChoice(g_VR.locomotionOptions[i].name)
			end

			DComboBox.OnSelect = function(self, index, value)
				convars.vrmod_locomotion:SetInt(index)
				vrmod.StopLocomotion()
				vrmod.StartLocomotion()
			end

			DComboBox.Think = function(self)
				local v = convars.vrmod_locomotion:GetInt()
				if self.ConvarVal ~= v then
					self.ConvarVal = v
					if g_VR.locomotionOptions[v] then
						self:ChooseOptionID(v)
						updateLocomotionCPanel(v)
					end
				end
			end
		end
	)

	--
	function vrmod.GetOrigin()
		return g_VR.origin, g_VR.originAngle
	end

	function vrmod.GetOriginPos()
		return g_VR.origin
	end

	function vrmod.GetOriginAng()
		return g_VR.originAngle
	end

	function vrmod.SetOrigin(pos, ang)
		g_VR.origin = pos
		g_VR.originAngle = ang
	end

	function vrmod.SetOriginPos(pos)
		g_VR.origin = pos
	end

	function vrmod.SetOriginAng(ang)
		g_VR.originAngle = ang
	end

	function vrmod.AddInGameMenuItem(name, slot, slotpos, func)
		local index = #g_VR.menuItems + 1
		for i = 1, #g_VR.menuItems do
			if g_VR.menuItems[i].name == name then
				index = i
			end
		end

		g_VR.menuItems[index] = {
			name = name,
			slot = slot,
			slotPos = slotpos,
			func = func
		}
	end

	function vrmod.RemoveInGameMenuItem(name)
		for i = 1, #g_VR.menuItems do
			if g_VR.menuItems[i].name == name then
				table.remove(g_VR.menuItems, i)

				return
			end
		end
	end

	function vrmod.GetLeftEyePos()
		return g_VR.eyePosLeft or Vector()
	end

	function vrmod.GetRightEyePos()
		return g_VR.eyePosRight or Vector()
	end

	function vrmod.GetEyePos()
		return g_VR.view and g_VR.view.origin or Vector()
	end

	function vrmod.GetTrackedDeviceNames()
		return g_VR.active and VRMOD_GetTrackedDeviceNames and VRMOD_GetTrackedDeviceNames() or {}
	end

	-- local leftEyeSemaphore = nil
	-- local rightEyeSemaphore = nil
	-- -- 左目の描画処理
	-- local function LeftEyeRenderThread()
	-- 	while true do
	-- 		leftEyeSemaphore:wait()
	-- 		g_VR.view.origin = g_VR.eyePosLeft
	-- 		g_VR.view.x = 0
	-- 		g_VR.view.fov = hfovLeft
	-- 		g_VR.view.aspectratio = aspectLeft
	-- 		hook.Call("VRMod_PreRender")
	-- 		render.RenderView(g_VR.view)
	-- 		leftEyeSemaphore:post()
	-- 	end
	-- end

	-- -- 右目の描画処理
	-- local function RightEyeRenderThread()
	-- 	while true do
	-- 		rightEyeSemaphore:wait()
	-- 		g_VR.view.origin = g_VR.eyePosRight
	-- 		g_VR.view.x = rtWidthright
	-- 		g_VR.view.fov = hfovRight
	-- 		g_VR.view.aspectratio = aspectRight
	-- 		hook.Call("VRMod_PreRenderRight")
	-- 		render.RenderView(g_VR.view)
	-- 		rightEyeSemaphore:post()
	-- 	end
	-- end

	-- hook.Add(
	-- 	"RenderScene",
	-- 	"vrutil_hook_renderscene",
	-- 	function()
	-- 		VRMOD_SubmitSharedTexture()
	-- 		VRMOD_UpdatePosesAndActions()
	-- 		local rawPoses = VRMOD_GetPoses()
	-- 		for k, v in pairs(rawPoses) do
	-- 			g_VR.tracking[k] = g_VR.tracking[k] or {}
	-- 			local worldPose = g_VR.tracking[k]
	-- 			worldPose.pos, worldPose.ang = LocalToWorld(v.pos * g_VR.scale, v.ang, g_VR.origin, g_VR.originAngle)
	-- 			worldPose.vel = LocalToWorld(v.vel, Angle(0, 0, 0), Vector(0, 0, 0), g_VR.originAngle) * g_VR.scale
	-- 			worldPose.angvel = LocalToWorld(Vector(v.angvel.pitch, v.angvel.yaw, v.angvel.roll), Angle(0, 0, 0), Vector(0, 0, 0), g_VR.originAngle)
	-- 			if k == "pose_righthand" then
	-- 				worldPose.pos, worldPose.ang = LocalToWorld(g_VR.rightControllerOffsetPos * 0.01 * g_VR.scale, g_VR.rightControllerOffsetAng, worldPose.pos, worldPose.ang)
	-- 			elseif k == "pose_lefthand" then
	-- 				worldPose.pos, worldPose.ang = LocalToWorld(g_VR.leftControllerOffsetPos * 0.01 * g_VR.scale, g_VR.leftControllerOffsetAng, worldPose.pos, worldPose.ang)
	-- 			end
	-- 		end

	-- 		g_VR.sixPoints = (g_VR.tracking.pose_waist and g_VR.tracking.pose_leftfoot and g_VR.tracking.pose_rightfoot) ~= nil
	-- 		hook.Call("VRMod_Tracking")
	-- 		g_VR.input, g_VR.changedInputs = VRMOD_GetActions()
	-- 		for k, v in pairs(g_VR.changedInputs) do
	-- 			hook.Call("VRMod_Input", nil, k, v)
	-- 		end

	-- 		if g_VR.menuFocus then return end
	-- 		render.PushRenderTarget(g_VR.rt)
	-- 		-- セマフォの初期化
	-- 		leftEyeSemaphore = semaphore.new(1)
	-- 		rightEyeSemaphore = semaphore.new(0)
	-- 		-- 左目と右目の描画スレッドを開始
	-- 		local leftEyeThread = coroutine.create(LeftEyeRenderThread)
	-- 		local rightEyeThread = coroutine.create(RightEyeRenderThread)
	-- 		coroutine.resume(leftEyeThread)
	-- 		coroutine.resume(rightEyeThread)
	-- 		-- 両目の描画が完了するまで待機
	-- 		leftEyeSemaphore:wait()
	-- 		rightEyeSemaphore:wait()
	-- 		render.PopRenderTarget(g_VR.rt)
	-- 		if not LocalPlayer():Alive() then
	-- 			cam.Start2D()
	-- 			surface.SetDrawColor(14, 14, 14, 220)
	-- 			surface.DrawRect(0, 0, rtWidth, rtHeight)
	-- 			cam.End2D()
	-- 		end

	-- 		local desktopView = convars.vrmod_desktopview:GetInt()
	-- 		if desktopView > 1 then
	-- 			surface.SetDrawColor(255, 255, 255, 255)
	-- 			surface.SetMaterial(mat_rt)
	-- 			render.CullMode(1)
	-- 			surface.DrawTexturedRectUV(-1, -1, 2, 2, cropHorizontalOffset, cropVerticalMargin02, cropHorizontalOffset02, cropVerticalMargin)
	-- 			render.CullMode(0)
	-- 		end

	-- 		hook.Call("VRMod_PostRender")

	-- 		return cameraover:GetBool()
	-- 	end
	-- )
elseif SERVER then
	function vrmod.NetReceiveLimited(msgName, maxCountPerSec, maxLen, callback)
		local msgCounts = {}
		net.Receive(
			msgName,
			function(len, ply)
				local t = msgCounts[ply] or {
					count = 0,
					time = 0
				}

				msgCounts[ply], t.count = t, t.count + 1
				if SysTime() - t.time >= 1 then
					t.count, t.time = 1, SysTime()
				end

				if t.count > maxCountPerSec or len > maxLen then return end --print("VRMod: netmsg limit exceeded by "..ply:SteamID().." | "..msgName.." | "..t.count.."/"..maxCountPerSec.." msgs/sec | "..len.."/"..maxLen.." bits")
				callback(len, ply)
			end
		)
	end

	function vrmod.IsPlayerInVR(ply)
		return g_VR[ply:SteamID()] ~= nil
	end

	function vrmod.UsingEmptyHands(ply)
		local wep = ply:GetActiveWeapon()

		return IsValid(wep) and wep:GetClass() == "weapon_vrmod_empty" or false
	end

	local function UpdateWorldPoses(ply, playerTable)
		if not playerTable.latestFrameWorld or playerTable.latestFrameWorld.tick ~= engine.TickCount() then
			playerTable.latestFrameWorld = playerTable.latestFrameWorld or {}
			local lf = playerTable.latestFrame
			local lfw = playerTable.latestFrameWorld
			lfw.tick = engine.TickCount()
			local refPos, refAng = ply:GetPos(), ply:InVehicle() and ply:GetVehicle():GetAngles() or Angle()
			lfw.hmdPos, lfw.hmdAng = LocalToWorld(lf.hmdPos, lf.hmdAng, refPos, refAng)
			lfw.lefthandPos, lfw.lefthandAng = LocalToWorld(lf.lefthandPos, lf.lefthandAng, refPos, refAng)
			lfw.righthandPos, lfw.righthandAng = LocalToWorld(lf.righthandPos, lf.righthandAng, refPos, refAng)
		end
	end

	function vrmod.GetHMDPos(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.hmdPos
	end

	function vrmod.GetHMDAng(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Angle() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.hmdAng
	end

	function vrmod.GetHMDPose(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector(), Angle() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.hmdPos, playerTable.latestFrameWorld.hmdAng
	end

	function vrmod.GetLeftHandPos(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.lefthandPos
	end

	function vrmod.GetLeftHandAng(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Angle() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.lefthandAng
	end

	function vrmod.GetLeftHandPose(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector(), Angle() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.lefthandPos, playerTable.latestFrameWorld.lefthandAng
	end

	function vrmod.GetRightHandPos(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.righthandPos
	end

	function vrmod.GetRightHandAng(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Angle() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.righthandAng
	end

	function vrmod.GetRightHandPose(ply)
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector(), Angle() end
		UpdateWorldPoses(ply, playerTable)

		return playerTable.latestFrameWorld.righthandPos, playerTable.latestFrameWorld.righthandAng
	end
end

local hookTranslations = {
	VRUtilEventTracking = "VRMod_Tracking",
	VRUtilEventInput = "VRMod_Input",
	VRUtilEventPreRender = "VRMod_PreRender",
	VRUtilEventPreRenderRight = "VRMod_PreRenderRight",
	VRUtilEventPostRender = "VRMod_PostRender",
	VRUtilStart = "VRMod_Start",
	VRUtilExit = "VRMod_Exit",
	VRUtilEventPickup = "VRMod_Pickup",
	VRUtilEventDrop = "VRMod_Drop",
	VRUtilAllowDefaultAction = "VRMod_AllowDefaultAction"
}

local hooks = hook.GetTable()
for k, v in pairs(hooks) do
	local translation = hookTranslations[k]
	if translation then
		hooks[translation] = hooks[translation] or {}
		for k2, v2 in pairs(v) do
			hooks[translation][k2] = v2
		end

		hooks[k] = nil
	end
end

local orig = hook.Add
hook.Add = function(...)
	local args = {...}
	args[1] = hookTranslations[args[1]] or args[1]
	orig(unpack(args))
end

local orig = hook.Remove
hook.Remove = function(...)
	local args = {...}
	args[1] = hookTranslations[args[1]] or args[1]
	orig(unpack(args))
end