-- Addon-only mode: skip to avoid overwriting other VRMod's ConVar table
if VRMOD_ADDON_ONLY_MODE then return end

local L = VRModL or function(_, fb) return fb or "" end

local addonVersion = 133
local requiredModuleVersion = 20
local latestModuleVersion = 103
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
			if not g_VR.moduleVersion or g_VR.moduleVersion == 0 then
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
			dlabel:SetText(L("Locomotion:", "Locomotion:"))
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
	-- -- Left eye rendering
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

	-- -- Right eye rendering
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
	-- 		-- Initialize semaphores
	-- 		leftEyeSemaphore = semaphore.new(1)
	-- 		rightEyeSemaphore = semaphore.new(0)
	-- 		-- Start left and right eye render threads
	-- 		local leftEyeThread = coroutine.create(LeftEyeRenderThread)
	-- 		local rightEyeThread = coroutine.create(RightEyeRenderThread)
	-- 		coroutine.resume(leftEyeThread)
	-- 		coroutine.resume(rightEyeThread)
	-- 		-- Wait until both eyes finish rendering
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

-- =========================================================================
-- v103 API: Event Polling, Frame Timing, Skeleton Bones, Overlay
-- All new features are opt-in and ConVar controlled.
-- C++ functions are called via pcall for safety.
-- =========================================================================

if CLIENT then

-- === ConVars for v103 features ===
local cvar_event_polling = CreateClientConVar("vrmod_unoff_event_polling", "1", true, FCVAR_ARCHIVE,
	"Enable VR event polling (device connect/disconnect detection)", 0, 1)
local cvar_fps_guard_frametiming = CreateClientConVar("vrmod_unoff_fps_guard_frametiming", "1", true, FCVAR_ARCHIVE,
	"FPS Guard: frame timing based performance monitoring", 0, 1)
local cvar_fps_guard_disconnect = CreateClientConVar("vrmod_unoff_fps_guard_disconnect", "1", true, FCVAR_ARCHIVE,
	"FPS Guard: auto suspend rendering on HMD disconnect", 0, 1)
local cvar_skeleton_bones = CreateClientConVar("vrmod_unoff_skeleton_bones", "0", true, FCVAR_ARCHIVE,
	"Enable full skeletal bone data (31 bones per hand, higher CPU cost)", 0, 1)
local cvar_overlay = CreateClientConVar("vrmod_unoff_overlay", "1", true, FCVAR_ARCHIVE,
	"Enable IVROverlay system", 0, 1)

-- === B4+B5: Event Polling API ===
-- Raw C++ functions (vrmod.PollNextEvent etc) are set by the module loader.
-- These wrapper functions add pcall protection and ConVar gating.

vrmod.Event = vrmod.Event or {}

function vrmod.Event.IsEnabled()
	return cvar_event_polling:GetBool()
end

function vrmod.Event.PollAll()
	if not cvar_event_polling:GetBool() then return nil end
	if not VRMOD_PollNextEvent then return nil end
	local events = {}
	while true do
		local ok, result = pcall(VRMOD_PollNextEvent)
		if not ok or not result then break end
		events[#events + 1] = result
	end
	return #events > 0 and events or nil
end

function vrmod.Event.IsDeviceConnected(deviceIndex)
	if not VRMOD_IsTrackedDeviceConnected then return nil end
	local ok, result = pcall(VRMOD_IsTrackedDeviceConnected, deviceIndex)
	if not ok then return nil end
	return result
end

function vrmod.Event.GetDeviceClass(deviceIndex)
	if not VRMOD_GetTrackedDeviceClass then return nil end
	local ok, result = pcall(VRMOD_GetTrackedDeviceClass, deviceIndex)
	if not ok then return nil end
	return result
end

function vrmod.Event.GetBatteryLevel(deviceIndex)
	if not VRMOD_GetFloatTrackedDeviceProperty then return nil end
	-- Prop_DeviceBatteryPercentage_Float = 1015
	local ok, result = pcall(VRMOD_GetFloatTrackedDeviceProperty, deviceIndex, 1015)
	if not ok or result == false then return nil end
	return result
end

function vrmod.Event.GetDeviceProperty(deviceIndex, propId)
	if not VRMOD_GetFloatTrackedDeviceProperty then return nil end
	local ok, result = pcall(VRMOD_GetFloatTrackedDeviceProperty, deviceIndex, propId)
	if not ok or result == false then return nil end
	return result
end

function vrmod.Event.GetDeviceStringProperty(deviceIndex, propId)
	if not VRMOD_GetStringTrackedDeviceProperty then return nil end
	local ok, result = pcall(VRMOD_GetStringTrackedDeviceProperty, deviceIndex, propId)
	if not ok or result == false then return nil end
	return result
end

function vrmod.Event.ShouldPause()
	if not VRMOD_ShouldApplicationPause then return false end
	local ok, result = pcall(VRMOD_ShouldApplicationPause)
	return ok and result or false
end

function vrmod.Event.ShouldReduceRendering()
	if not VRMOD_ShouldApplicationReduceRenderingWork then return false end
	local ok, result = pcall(VRMOD_ShouldApplicationReduceRenderingWork)
	return ok and result or false
end

-- === B3: Frame Timing API ===

vrmod.Performance = vrmod.Performance or {}

function vrmod.Performance.GetFrameTiming(framesAgo)
	if not VRMOD_GetFrameTiming then return nil end
	local ok, result = pcall(VRMOD_GetFrameTiming, framesAgo or 0)
	if not ok or result == false then return nil end
	return result
end

function vrmod.Performance.GetFrameTimeRemaining()
	if not VRMOD_GetFrameTimeRemaining then return nil end
	local ok, result = pcall(VRMOD_GetFrameTimeRemaining)
	if not ok then return nil end
	return result
end

function vrmod.Performance.IsMotionSmoothingEnabled()
	if not VRMOD_IsMotionSmoothingEnabled then return nil end
	local ok, result = pcall(VRMOD_IsMotionSmoothingEnabled)
	if not ok then return nil end
	return result
end

function vrmod.Performance.FadeToColor(seconds, r, g, b, a, background)
	if not VRMOD_FadeToColor then return end
	pcall(VRMOD_FadeToColor, seconds, r, g, b, a, background or false)
end

function vrmod.Performance.SuspendRendering(suspend)
	if not VRMOD_VRSuspendRendering then return end
	pcall(VRMOD_VRSuspendRendering, suspend)
end

function vrmod.Performance.IsFrameTimingEnabled()
	return cvar_fps_guard_frametiming:GetBool()
end

function vrmod.Performance.IsDisconnectGuardEnabled()
	return cvar_fps_guard_disconnect:GetBool()
end

-- === B1: Full Skeletal Bone Data API ===

vrmod.Skeleton = vrmod.Skeleton or {}

function vrmod.Skeleton.IsEnabled()
	return cvar_skeleton_bones:GetBool()
end

function vrmod.Skeleton.SetEnabled(enable)
	RunConsoleCommand("vrmod_unoff_skeleton_bones", enable and "1" or "0")
end

function vrmod.Skeleton.GetBoneData(actionName, motionRange)
	if not cvar_skeleton_bones:GetBool() then return nil end
	if not VRMOD_GetSkeletalBoneData then return nil end
	local ok, result = pcall(VRMOD_GetSkeletalBoneData, actionName, motionRange or 0)
	if not ok or result == false then return nil end
	return result
end

-- === A1: IVROverlay API ===

vrmod.Overlay = vrmod.Overlay or {}

function vrmod.Overlay.IsEnabled()
	return cvar_overlay:GetBool()
end

function vrmod.Overlay.IsSupported()
	return VRMOD_CreateOverlay ~= nil
end

function vrmod.Overlay.Create(key, name)
	if not cvar_overlay:GetBool() then return nil, "Overlay disabled by ConVar" end
	if not VRMOD_CreateOverlay then return nil, "Module does not support overlays" end
	local ok, handle, err = pcall(VRMOD_CreateOverlay, key, name)
	if not ok then return nil, "pcall failed: " .. tostring(handle) end
	if handle == false then return nil, err or "CreateOverlay failed" end
	return handle
end

function vrmod.Overlay.Destroy(handle)
	if not VRMOD_DestroyOverlay then return false end
	local ok, result = pcall(VRMOD_DestroyOverlay, handle)
	return ok and result or false
end

function vrmod.Overlay.SetTexture(handle)
	if not VRMOD_SetOverlayTexture then return false end
	local ok, result = pcall(VRMOD_SetOverlayTexture, handle)
	return ok and result or false
end

function vrmod.Overlay.Control(handle, cmdTable)
	if not VRMOD_OverlayControl then return false end
	local ok, result = pcall(VRMOD_OverlayControl, handle, cmdTable)
	return ok and result or false
end

-- Convenience wrappers
function vrmod.Overlay.Show(handle) return vrmod.Overlay.Control(handle, {cmd = "show"}) end
function vrmod.Overlay.Hide(handle) return vrmod.Overlay.Control(handle, {cmd = "hide"}) end
function vrmod.Overlay.SetWidth(handle, w) return vrmod.Overlay.Control(handle, {cmd = "setWidth", value = w}) end
function vrmod.Overlay.SetAlpha(handle, a) return vrmod.Overlay.Control(handle, {cmd = "setAlpha", value = a}) end
function vrmod.Overlay.SetColor(handle, r, g, b) return vrmod.Overlay.Control(handle, {cmd = "setColor", r = r, g = g, b = b}) end
function vrmod.Overlay.SetSortOrder(handle, order) return vrmod.Overlay.Control(handle, {cmd = "setSortOrder", value = order}) end
function vrmod.Overlay.SetTextureBounds(handle, uMin, vMin, uMax, vMax)
	return vrmod.Overlay.Control(handle, {cmd = "setTextureBounds", uMin = uMin, vMin = vMin, uMax = uMax, vMax = vMax})
end
function vrmod.Overlay.SetTransformAbsolute(handle, origin, matrix)
	return vrmod.Overlay.Control(handle, {cmd = "setTransformAbsolute", origin = origin, matrix = matrix})
end
function vrmod.Overlay.AttachToDevice(handle, deviceIndex, matrix)
	return vrmod.Overlay.Control(handle, {cmd = "setTransformTrackedDevice", deviceIndex = deviceIndex, matrix = matrix})
end
function vrmod.Overlay.IsVisible(handle)
	if not VRMOD_OverlayControl then return false end
	local ok, result = pcall(VRMOD_OverlayControl, handle, {cmd = "isVisible"})
	return ok and result or false
end

-- Overlay texture initialization (call after ShareTextureFinish, before creating overlays)
function vrmod.Overlay.InitTexture()
	if not cvar_overlay:GetBool() then return false, "Overlay disabled" end
	if not VRMOD_ShareOverlayTextureBegin then return false, "Module does not support overlay textures" end
	local ok, err = pcall(VRMOD_ShareOverlayTextureBegin)
	if not ok then return false, "ShareOverlayTextureBegin failed: " .. tostring(err) end
	return true
end

function vrmod.Overlay.FinishTexture()
	if not VRMOD_ShareOverlayTextureFinish then return false, "Module does not support overlay textures" end
	local ok, err = pcall(VRMOD_ShareOverlayTextureFinish)
	if not ok then return false, "ShareOverlayTextureFinish failed: " .. tostring(err) end
	return true
end

-- === v103 Event Constants (for Lua-side event type checking) ===
vrmod.VREvent = vrmod.VREvent or {}
vrmod.VREvent.TrackedDeviceActivated = 100
vrmod.VREvent.TrackedDeviceDeactivated = 101
vrmod.VREvent.TrackedDeviceUpdated = 102
vrmod.VREvent.UserInteractionStarted = 103
vrmod.VREvent.UserInteractionEnded = 104
vrmod.VREvent.IpdChanged = 105
vrmod.VREvent.EnterStandbyMode = 106
vrmod.VREvent.LeaveStandbyMode = 107
vrmod.VREvent.TrackedDeviceRoleChanged = 108
vrmod.VREvent.ButtonPress = 200
vrmod.VREvent.ButtonUnpress = 201
vrmod.VREvent.Quit = 700
vrmod.VREvent.ProcessQuit = 701

-- === v103 Device Property Constants ===
vrmod.VRProp = vrmod.VRProp or {}
vrmod.VRProp.BatteryPercentage = 1015
vrmod.VRProp.DeviceIsCharging = 1026

-- === v103 Device Class Constants ===
vrmod.VRDeviceClass = vrmod.VRDeviceClass or {}
vrmod.VRDeviceClass.Invalid = 0
vrmod.VRDeviceClass.HMD = 1
vrmod.VRDeviceClass.Controller = 2
vrmod.VRDeviceClass.GenericTracker = 3
vrmod.VRDeviceClass.TrackingReference = 4

-- === v103 Tracking Universe Constants (for overlay transforms) ===
vrmod.VRTrackingUniverse = vrmod.VRTrackingUniverse or {}
vrmod.VRTrackingUniverse.Seated = 0
vrmod.VRTrackingUniverse.Standing = 1
vrmod.VRTrackingUniverse.RawAndUncalibrated = 2

end -- CLIENT