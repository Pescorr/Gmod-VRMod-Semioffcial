if CLIENT then
	g_VR = g_VR or {}
	g_VR.viewModelInfo = g_VR.viewModelInfo or {}
	g_VR.viewModelInfo.autoOffsetAddPos = Vector(1, 0.2, 0)
	g_VR.currentvmi = nil
	g_VR.viewModelInfo.gmod_tool = {
		--modelOverride = "models/weapons/w_toolgun.mdl",
		offsetPos = Vector(-12, 6.5, 7), --forw, left, up
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_physgun = {
		offsetPos = Vector(-24.5, 13.4, 14.5),
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_physcannon = {
		offsetPos = Vector(-24.5, 13.4, 14.5),
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_shotgun = {
		offsetPos = Vector(-14.5, 10, 8.5),
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_rpg = {
		offsetPos = Vector(-27.5, 19, 10.5),
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_crossbow = {
		offsetPos = Vector(-14.5, 10, 8.5),
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_medkit = {
		offsetPos = Vector(-23, 10, 5),
		offsetAng = Angle(0, 0, 0),
	}

	g_VR.viewModelInfo.weapon_crowbar = {
		wrongMuzzleAng = true --lol
	}

	g_VR.viewModelInfo.weapon_stunstick = {
		wrongMuzzleAng = true
	}

	g_VR.viewModelInfo.weapon_mp_powersuit = {
		--modelOverride = "models/weapons/w_toolgun.mdl",
		offsetPos = Vector(-14.5, 6, 8.5), --forw, left, up
		offsetAng = Angle(0, 0, 0),
	}


	g_VR.swepOriginalFovs = g_VR.swepOriginalFovs or {}
	g_VR.lastUpdatedWeapon = ""
	local function ResetViewmodelInfo()
		g_VR.viewModel = nil
		g_VR.openHandAngles = g_VR.defaultOpenHandAngles
		g_VR.closedHandAngles = g_VR.defaultClosedHandAngles
		g_VR.currentvmi = nil
		g_VR.viewModelMuzzle = nil
	end

	function vrmod.UpdateViewmodelInfo(wep, force)
		if not IsValid(wep) then
			ResetViewmodelInfo()
			g_VR.lastUpdatedWeapon = ""

			return
		end

		local class = wep:GetClass()
		if class == g_VR.lastUpdatedWeapon and not force then return end
		local vm = wep:GetWeaponViewModel()
		if vm == "" or vm == "models/weapons/c_arms.mdl" then
			ResetViewmodelInfo()
			g_VR.lastUpdatedWeapon = class

			return
		end

		-----------------------
		-- Drawing with worldmodels
		--[[if vrmod.GetWeaponDrawMode(wep) == VR_WEPDRAWMODE_VIEWMODEL then
			ResetViewmodelInfo()
			vrmod.SetRightHandOpenFingerAngles( g_VR.zeroHandAngles )
			vrmod.SetRightHandClosedFingerAngles( g_VR.zeroHandAngles )
			g_VR.viewModel = wep
			return
		end]]
		-------------------------
		local drawWorld = vrmod.GetWeaponDrawMode(wep) ~= VR_WEPDRAWMODE_VIEWMODEL
		g_VR.viewModel = not drawWorld and LocalPlayer():GetViewModel() or wep
		if wep.ViewModelFOV then
			if not g_VR.swepOriginalFovs[class] then
				g_VR.swepOriginalFovs[class] = wep.ViewModelFOV
			end

			wep.ViewModelFOV = GetConVar("fov_desired"):GetFloat()
		end

		local vmi = g_VR.viewModelInfo[class] or {}
		local model = vmi.modelOverride or g_VR.viewModel:GetModel()
		--create offsets if they don't exist
		if vmi.offsetPos == nil or vmi.offsetAng == nil then
			vmi.offsetPos, vmi.offsetAng = Vector(), Angle()
			local cm = ClientsideModel(vm)
			if IsValid(cm) then
				cm:SetNoDraw(true)
				cm:SetupBones()
				local bone = cm:LookupBone("ValveBiped.Bip01_R_Hand")
				if bone then
					local boneMat = cm:GetBoneMatrix(bone)
					local bonePos, boneAng = boneMat:GetTranslation(), boneMat:GetAngles()
					boneAng:RotateAroundAxis(boneAng:Forward(), 180)
					vmi.offsetPos, vmi.offsetAng = WorldToLocal(vector_origin, angle_zero, bonePos, boneAng)
					vmi.offsetPos = vmi.offsetPos + g_VR.viewModelInfo.autoOffsetAddPos
				end

				cm:Remove()
			end
		end

		--create finger poses
		vmi.closedHandAngles = vrmod.GetRightHandFingerAnglesFromModel(model)
		-- TODO: ArcVR weapons set this manually, but only on deploy so we want to avoid breaking it
		vrmod.SetRightHandClosedFingerAngles(vmi.closedHandAngles)
		vrmod.SetRightHandOpenFingerAngles(vmi.closedHandAngles)
		g_VR.viewModelInfo[class] = vmi
		g_VR.currentvmi = vmi
		g_VR.lastUpdatedWeapon = class
	end
end

if CLIENT then
	-- 読み込み関数の修正
	local function LoadViewModelConfig()
		if file.Exists("vrmod/viewmodelinfo.json", "DATA") then
			local json = file.Read("vrmod/viewmodelinfo.json", "DATA")
			viewModelConfig = util.JSONToTable(json)
		else
			viewModelConfig = {}
		end
	end

	LoadViewModelConfig()
	-- GUIの作成
	function CreateWeaponConfigGUI()
		local frame = vgui.Create("DFrame")
		frame:SetSize(600, 400)
		frame:Center()
		frame:SetTitle("Weapon ViewModel Configuration")
		frame:MakePopup()
		local listview = vgui.Create("DListView", frame)
		listview:Dock(FILL)
		listview:AddColumn("Weapon Class")
		listview:AddColumn("Offset Position")
		listview:AddColumn("Offset Angle")
		-- 一覧の更新
		local function UpdateListView()
			if not viewModelConfig then return end -- 追加: viewModelConfigが空の場合は何もしない
			listview:Clear()
			for class, data in pairs(viewModelConfig) do
				listview:AddLine(class, tostring(data.offsetPos), tostring(data.offsetAng))
			end
		end

		-- 一覧にデータを追加
		UpdateListView()
		-- 新規追加ボタン
		local addButton = vgui.Create("DButton", frame)
		addButton:SetText("New")
		addButton:Dock(BOTTOM)
		addButton.DoClick = function()
			local currentWeapon = LocalPlayer():GetActiveWeapon()
			if IsValid(currentWeapon) then
				CreateAddWeaponConfigGUI(currentWeapon:GetClass())
				frame:Close()
			end
		end

		-- 編集ボタン
		local editButton = vgui.Create("DButton", frame)
		editButton:SetText("Edit")
		editButton:Dock(BOTTOM)
		editButton.DoClick = function()
			local selected = listview:GetSelectedLine()
			if selected then
				local class = listview:GetLine(selected):GetValue(1)
				CreateAddWeaponConfigGUI(class, true)
				frame:Close()
			end
		end

		-- 削除ボタン
		local deleteButton = vgui.Create("DButton", frame)
		deleteButton:SetText("Delete")
		deleteButton:Dock(BOTTOM)
		deleteButton.DoClick = function()
			local selected = listview:GetSelectedLine()
			if selected then
				local class = listview:GetLine(selected):GetValue(1)
				viewModelConfig[class] = nil
				UpdateListView()
				SaveViewModelConfig()
			end
		end
	end

	-- viewModelConfigのグローバル宣言
	viewModelConfig = viewModelConfig or {}
	-- 読み込み関数の修正
	local function LoadViewModelConfig()
		if file.Exists("vrmod/viewmodelinfo.json", "DATA") then
			local json = file.Read("vrmod/viewmodelinfo.json", "DATA")
			viewModelConfig = util.JSONToTable(json)
		else
			viewModelConfig = {}
		end
	end

	-- 新規追加・編集画面の作成
	function CreateAddWeaponConfigGUI(class, isEditing)
		local frame = vgui.Create("DFrame")
		frame:SetSize(300, 300)
		frame:Center()
		frame:SetTitle(isEditing and "Edit ViewModel Config" or "Add ViewModel Config")
		frame:MakePopup()
		local data = viewModelConfig[class] or {
			offsetPos = Vector(),
			offsetAng = Angle()
		}

		-- 元の設定を保持
		local originalData = table.Copy(data)
		-- Offset Positionの設定
		local posPanel = vgui.Create("DPanel", frame)
		posPanel:Dock(TOP)
		posPanel:SetHeight(100)
		posPanel:SetPaintBackground(false)
		local posLabel = vgui.Create("DLabel", posPanel)
		posLabel:SetText("Offset Position:")
		posLabel:Dock(TOP)
		local posSliders = {}
		for i, axis in ipairs({"X", "Y", "Z"}) do
			local slider = vgui.Create("DNumSlider", posPanel)
			slider:Dock(TOP)
			slider:SetText(axis)
			slider:SetMin(-100)
			slider:SetMax(100)
			slider:SetValue(data.offsetPos[i])
			slider:SetDecimals(3)
			posSliders[i] = slider
		end

		-- Offset Angleの設定
		local angPanel = vgui.Create("DPanel", frame)
		angPanel:Dock(TOP)
		angPanel:SetHeight(100)
		angPanel:SetPaintBackground(false)
		local angLabel = vgui.Create("DLabel", angPanel)
		angLabel:SetText("Offset Angle:")
		angLabel:Dock(TOP)
		local angSliders = {}
		for i, axis in ipairs({"P", "Y", "R"}) do
			local slider = vgui.Create("DNumSlider", angPanel)
			slider:Dock(TOP)
			slider:SetText(axis)
			slider:SetMin(-180)
			slider:SetMax(180)
			slider:SetValue(data.offsetAng[i])
			slider:SetDecimals(3)
			angSliders[i] = slider
		end

		-- Offset Position スライダーのイベントハンドラ
		for i, slider in ipairs(posSliders) do
			slider.OnValueChanged = function()
				local pos = Vector(posSliders[1]:GetValue(), posSliders[2]:GetValue(), posSliders[3]:GetValue())
				local ang = Angle(angSliders[1]:GetValue(), angSliders[2]:GetValue(), angSliders[3]:GetValue())
				-- ViewModelにリアルタイムで反映
				vrmod.SetViewModelOffsetForWeaponClass(class, pos, ang)
			end
		end

		-- Offset Angle スライダーのイベントハンドラ
		for i, slider in ipairs(angSliders) do
			slider.OnValueChanged = function()
				local pos = Vector(posSliders[1]:GetValue(), posSliders[2]:GetValue(), posSliders[3]:GetValue())
				local ang = Angle(angSliders[1]:GetValue(), angSliders[2]:GetValue(), angSliders[3]:GetValue())
				-- ViewModelにリアルタイムで反映
				vrmod.SetViewModelOffsetForWeaponClass(class, pos, ang)
			end
		end

		-- SaveViewModelConfig関数の定義
		local function SaveViewModelConfig()
			if not viewModelConfig then return end
			local json = util.TableToJSON(viewModelConfig, true) -- JSON形式で保存
			file.Write("vrmod/viewmodelinfo.json", json)
		end

		-- 適用ボタン
		local applyButton = vgui.Create("DButton", frame)
		applyButton:SetText("Apply")
		applyButton:Dock(BOTTOM)
		-- 適用ボタンのイベントハンドラ内
		applyButton.DoClick = function()
			data.offsetPos = Vector(posSliders[1]:GetValue(), posSliders[2]:GetValue(), posSliders[3]:GetValue())
			data.offsetAng = Angle(angSliders[1]:GetValue(), angSliders[2]:GetValue(), angSliders[3]:GetValue())
			-- 新しい設定を適用
			vrmod.SetViewModelOffsetForWeaponClass(class, data.offsetPos, data.offsetAng)
			-- 設定を保存
			viewModelConfig[class] = data
			SaveViewModelConfig()
			frame:Close()
		end

		-- 破棄ボタン
		local cancelButton = vgui.Create("DButton", frame)
		-- 元の設定に戻す
		vrmod.SetViewModelOffsetForWeaponClass(class, originalData.offsetPos, originalData.offsetAng)
		cancelButton:SetText("Cancel")
		cancelButton:Dock(BOTTOM)
		cancelButton.DoClick = function()
			frame:Close()
		end
	end

	-- GUI呼び出し時の初期化チェック
	concommand.Add(
		"vrmod_weaponconfig",
		function()
			if not viewModelConfig then
				LoadViewModelConfig() -- 念のための再読み込み
			end

			CreateWeaponConfigGUI()
		end
	)

	-- VRModが初期化されたときに呼び出される関数
	local function InitializeVRModViewModelSettings()
		-- 設定を読み込む
		LoadViewModelConfig()
		-- 各武器クラスに設定を適用する
		for classname, settings in pairs(viewModelConfig) do
			if settings.offsetPos and settings.offsetAng then
				vrmod.SetViewModelOffsetForWeaponClass(classname, settings.offsetPos, settings.offsetAng)
			end
		end
	end

	-- VRModの初期化時に上記の関数を呼び出す
	hook.Add("VRMod_Start", "InitializeViewModelSettings", InitializeVRModViewModelSettings)
end