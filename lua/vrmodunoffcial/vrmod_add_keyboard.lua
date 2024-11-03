if CLIENT then
	local pressTime = 0
	local chatLog = {}
	local chatPanel = nil
	local nametags = false
	local VRClipboard = CreateClientConVar("vrmod_Clipboard", "", false, false, "")
	hook.Add("VRMod_Start", "voicepermissions", function(ply) end)
	local function ToggleKeyboard()
		if VRUtilIsMenuOpen("keyboard_only") then
			VRUtilMenuClose("keyboard_only")

			return
		end

		local keyboardPanel = vgui.Create("DPanel")
		keyboardPanel:SetPos(0, 0)
		keyboardPanel:SetSize(555, 255) -- 幅を555に変更
		function keyboardPanel:Paint(w, h)
			surface.SetDrawColor(Color(0, 0, 0, 128))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(Color(0, 0, 0, 255))
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local lowerCase = "1234567890\1\nqwertyuiop\nasdfghjkl\2\n\3zxcvbnm.\4\3\n "
		local upperCase = "!@%\"/+=?-_\1\nQWERTYUIOP\nASDFGHJKL\2\n\3ZXCVBNM,\4\3\n "
		local selectedCase = lowerCase
		local keys = {}
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
			key:SetSize(selectedCase[i] == " " and 250 or selectedCase[i] == "\2" and 65 or selectedCase[i] == "\4" and 50 or 45, 45) -- chatボタンのサイズを50に変更
			key:SetTextColor(Color(255, 255, 255, 255))
			key:SetFont((selectedCase[i] == "\1" or selectedCase[i] == "\2" or selectedCase[i] == "\3" or selectedCase[i] == "\4") and "HudSelectionText" or "vrmod_Verdana37")
			key:SetText(selectedCase[i] == "\1" and "Back" or selectedCase[i] == "\2" and "Enter" or selectedCase[i] == "\4" and "Shift" or selectedCase[i])
			key:SetMouseInputEnabled(true)
			key:SetContentAlignment(5)
			key.OnMousePressed = function()
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
				elseif key:GetText() == "Shift" then
					selectedCase = (selectedCase == lowerCase) and upperCase or lowerCase
					updateKeyboard()
				-- elseif key:GetText() == "exit" then
				-- 	VRUtilMenuClose("keyboard_only")
					-- LocalPlayer():ConCommand("vrmod_chatmode")
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

			function key:Paint(w, h)
				surface.SetDrawColor(Color(0, 0, 0, 200))
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(Color(128, 128, 128, 255))
				surface.DrawOutlinedRect(0, 0, w, h)
			end

			x = x + (selectedCase[i] == "\4" and 55 or 50) -- chatボタンの後のxの増分を55に変更
		end

		VRUtilMenuOpen(
			"keyboard_only",
			605,
			255,
			keyboardPanel,
			1,
			Vector(4, 6, 5.5),
			Angle(0, -90, 10),
			0.03,
			true,
			function()
				keyboardPanel:Remove()
				keyboardPanel = nil
			end
		)
	end

	concommand.Add("vrmod_keyboard", ToggleKeyboard)
end