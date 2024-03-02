-- ConCommandを追加する
concommand.Add(
	"vrmod_preset_gui",
	function()
		local frame = vgui.Create("DFrame")
		frame:SetTitle("VRMod Presets")
		frame:SetSize(500, 400)
		frame:Center()
		frame:MakePopup()
		local presetControl = vgui.Create("DPanelList", frame)
		presetControl:Dock(FILL)
		presetControl:SetSpacing(5)
		presetControl:EnableVerticalScrollbar(true)
		local function LoadConVars()
			presetControl:Clear()
			local convars = {}
			for _, cvar in ipairs(cvars.GetConVarNames()) do
				if string.StartWith(cvar, "vrmod_") or string.StartWith(cvar, "arcticvr_") or string.StartWith(cvar, "vr_") then
					table.insert(convars, cvar)
				end
			end

			for _, cvar in ipairs(convars) do
				local slider = vgui.Create("DNumSlider")
				slider:SetMinMax(0, 1)
				slider:SetDecimals(2)
				slider:SetText(cvar)
				slider:SetValue(GetConVarNumber(cvar))
				slider.OnValueChanged = function(self, value)
					RunConsoleCommand(cvar, tostring(value))
				end

				presetControl:AddItem(slider)
			end
		end

		local saveButton = vgui.Create("DButton", frame)
		saveButton:Dock(BOTTOM)
		saveButton:SetText("Save Preset")
		saveButton.DoClick = function()
			local presetName = Derma_StringRequest(
				"Preset Name",
				"Enter the name of the new preset:",
				"",
				function(text)
					local values = {}
					for _, cvar in ipairs(convars) do
						values[cvar] = GetConVarString(cvar)
					end

					file.Write("vrmod_presets/" .. text .. ".txt", util.TableToJSON(values))
				end
			)
		end

		local loadButton = vgui.Create("DButton", frame)
		loadButton:Dock(BOTTOM)
		loadButton:SetText("Load Preset")
		loadButton.DoClick = function()
			local menu = DermaMenu()
			local files = file.Find("vrmod_presets/*.txt", "DATA")
			for _, f in ipairs(files) do
				menu:AddOption(
					f,
					function()
						local values = util.JSONToTable(file.Read("vrmod_presets/" .. f, "DATA"))
						for cvar, value in pairs(values) do
							RunConsoleCommand(cvar, value)
						end
					end
				)
			end

			menu:Open()
		end

		LoadConVars()
	end
)