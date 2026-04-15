if CLIENT then
	local L = VRModL or function(_, fb) return fb or "" end

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
	-- マズルアタッチメント基準の精密オフセット自動計算
	function vrmod.AutoAdjustCurrentWeaponViewmodel()
		local ply = LocalPlayer()
		if not IsValid(ply) then
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "Player not valid")
			return false
		end

		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "No weapon equipped")
			return false
		end

		local class = wep:GetClass()
		local vm = wep:GetWeaponViewModel()
		if vm == "" or vm == "models/weapons/c_arms.mdl" then
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "Weapon has no viewmodel: " .. class)
			return false
		end

		local cm = ClientsideModel(vm)
		if not IsValid(cm) then
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "Failed to create model for: " .. class)
			return false
		end

		cm:SetNoDraw(true)
		cm:SetupBones()

		local bone = cm:LookupBone("ValveBiped.Bip01_R_Hand")
		if not bone then
			cm:Remove()
			chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "No hand bone found: " .. class)
			return false
		end

		local boneMat = cm:GetBoneMatrix(bone)
		local bonePos, boneAng = boneMat:GetTranslation(), boneMat:GetAngles()
		boneAng:RotateAroundAxis(boneAng:Forward(), 180)

		-- 基本角度オフセット（手ボーンをVR手に合わせる）
		local _, baseAng = WorldToLocal(vector_origin, angle_zero, bonePos, boneAng)

		local vmi = g_VR.viewModelInfo[class] or {}

		-- マズルアタッチメントによる角度補正
		local muzzleData = cm:GetAttachment(1)
		if muzzleData then
			-- マズル方向を手ボーン基準の角度に変換
			local _, muzzleLocalAng = WorldToLocal(vector_origin, muzzleData.Ang, vector_origin, boneAng)

			-- 角度補正: マズルが前方を向くように（roll含む全3成分）
			vmi.offsetAng = baseAng - Angle(muzzleLocalAng.p, muzzleLocalAng.y, muzzleLocalAng.r)

			-- 位置再計算: 角度補正後もハンドボーンがVR手に一致するように
			-- 条件: offsetPos + Rotate(bonePos, offsetAng) = 0
			local rotBonePos = Vector(bonePos)
			rotBonePos:Rotate(vmi.offsetAng)
			vmi.offsetPos = -rotBonePos

			chat.AddText(
				Color(0, 255, 0), "[VRMod] ",
				Color(255, 255, 255), "Auto-adjusted (muzzle): " .. class,
				Color(180, 180, 180), " Pos=" .. tostring(vmi.offsetPos),
				Color(180, 180, 180), " Ang=" .. tostring(vmi.offsetAng)
			)
		else
			-- マズルなし: 手ボーンのみでフォールバック
			vmi.offsetAng = baseAng
			local rotBonePos = Vector(bonePos)
			rotBonePos:Rotate(vmi.offsetAng)
			vmi.offsetPos = -rotBonePos

			chat.AddText(
				Color(255, 200, 0), "[VRMod] ",
				Color(255, 255, 255), "Auto-adjusted (no muzzle, fallback): " .. class,
				Color(180, 180, 180), " Pos=" .. tostring(vmi.offsetPos)
			)
		end

		cm:Remove()

		-- 指ポーズ更新
		local model = vmi.modelOverride or vm
		vmi.closedHandAngles = vrmod.GetRightHandFingerAnglesFromModel(model)

		-- g_VR.viewModelInfoに適用
		g_VR.viewModelInfo[class] = vmi
		g_VR.currentvmi = vmi

		-- viewmodelinfo.jsonに永続保存
		viewModelConfig = viewModelConfig or {}
		viewModelConfig[class] = {
			offsetPos = vmi.offsetPos,
			offsetAng = vmi.offsetAng
		}
		local json = util.TableToJSON(viewModelConfig, true)
		file.Write("vrmod/viewmodelinfo.json", json)

		-- 即座にviewmodelに反映
		if vrmod.SetViewModelOffsetForWeaponClass then
			vrmod.SetViewModelOffsetForWeaponClass(class, vmi.offsetPos, vmi.offsetAng)
		end

		return true
	end

	concommand.Add("vrmod_viewmodel_autoadjust", function()
		vrmod.AutoAdjustCurrentWeaponViewmodel()
	end)
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

	-- 保存関数（ファイルスコープ — 一覧UIと編集ダイアログの両方から呼ばれる）
	local function SaveViewModelConfig()
		if not viewModelConfig then return end
		local json = util.TableToJSON(viewModelConfig, true)
		file.Write("vrmod/viewmodelinfo.json", json)
	end

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
		addButton:SetText(L("New", "New") or "New")
		addButton:Dock(BOTTOM)
		addButton.DoClick = function()
			local currentWeapon = LocalPlayer():GetActiveWeapon()
			if IsValid(currentWeapon) then
				CreateAddWeaponConfigGUI(currentWeapon:GetClass())
				frame:Close()
			end
		end

		-- リセットボタン（現在持っている武器のプリセットを全て0に初期化）
		local resetButton = vgui.Create("DButton", frame)
		resetButton:SetText(L("Reset Current Weapon", "Reset Current Weapon"))
		resetButton:Dock(BOTTOM)
		resetButton.DoClick = function()
			local wep = LocalPlayer():GetActiveWeapon()
			if not IsValid(wep) then return end
			local class = wep:GetClass()
			viewModelConfig[class] = { offsetPos = Vector(0, 0, 0), offsetAng = Angle(0, 0, 0) }
			vrmod.SetViewModelOffsetForWeaponClass(class, Vector(0, 0, 0), Angle(0, 0, 0))
			SaveViewModelConfig()
			UpdateListView()
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Reset viewmodel offset: " .. class)
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
		frame:SetSize(300, 420)
		frame:Center()
		frame:SetTitle(isEditing and "Edit ViewModel Config" or "Add ViewModel Config")
		frame:MakePopup()
		local data = viewModelConfig[class] or {
			offsetPos = Vector(),
			offsetAng = Angle()
		}

		-- 元の設定を保持
		local originalData = table.Copy(data)

		-- ドラッグヒント
		local tipLabel = vgui.Create("DLabel", frame)
		tipLabel:SetText(L("Tip: Drag slider labels for fine adjustment", "Tip: Drag slider labels for fine adjustment"))
		tipLabel:SetTextColor(Color(180, 180, 180))
		tipLabel:Dock(TOP)
		tipLabel:DockMargin(5, 2, 5, 2)

		-- Offset Positionの設定
		local posPanel = vgui.Create("DPanel", frame)
		posPanel:Dock(TOP)
		posPanel:SetHeight(100)
		posPanel:SetPaintBackground(false)
		local posLabel = vgui.Create("DLabel", posPanel)
		posLabel:SetText(L("Offset Position:", "Offset Position:"))
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
		angLabel:SetText(L("Offset Angle:", "Offset Angle:"))
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

		-- ユーティリティボタン（Auto Adjust / Reset to Zero）
		local utilPanel = vgui.Create("DPanel", frame)
		utilPanel:Dock(TOP)
		utilPanel:SetHeight(30)
		utilPanel:SetPaintBackground(false)
		utilPanel:DockMargin(0, 5, 0, 5)

		local autoBtn = vgui.Create("DButton", utilPanel)
		autoBtn:SetText(L("Auto Adjust", "Auto Adjust"))
		autoBtn:Dock(LEFT)
		autoBtn:SetWide(140)
		autoBtn.DoClick = function()
			local success = vrmod.AutoAdjustCurrentWeaponViewmodel()
			if success then
				-- 自動調節の結果をスライダーに反映
				local vmi = g_VR.viewModelInfo[class]
				if vmi and vmi.offsetPos and vmi.offsetAng then
					for i = 1, 3 do
						posSliders[i]:SetValue(vmi.offsetPos[i])
						angSliders[i]:SetValue(vmi.offsetAng[i])
					end
				end
			end
		end

		local resetBtn = vgui.Create("DButton", utilPanel)
		resetBtn:SetText(L("Reset to Zero", "Reset to Zero"))
		resetBtn:Dock(FILL)
		resetBtn.DoClick = function()
			for i = 1, 3 do
				posSliders[i]:SetValue(0)
				angSliders[i]:SetValue(0)
			end
			vrmod.SetViewModelOffsetForWeaponClass(class, Vector(0, 0, 0), Angle(0, 0, 0))
		end

		-- 適用ボタン
		local applyButton = vgui.Create("DButton", frame)
		applyButton:SetText(L("Apply", "Apply"))
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
		cancelButton:SetText(L("Cancel", "Cancel"))
		cancelButton:Dock(BOTTOM)
		cancelButton.DoClick = function()
			-- 元の設定に戻す（ダイアログを開く前の値）
			vrmod.SetViewModelOffsetForWeaponClass(class, originalData.offsetPos, originalData.offsetAng)
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