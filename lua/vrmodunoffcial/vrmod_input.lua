local cl_bothkey = CreateClientConVar("vrmod_vehicle_bothkeymode", 1, true, FCVAR_ARCHIVE)
local cl_pickupdisable = CreateClientConVar("vr_pickup_disable_client", 0, true, FCVAR_ARCHIVE)
local cl_lefthand = CreateClientConVar("vrmod_LeftHand", 0, true, FCVAR_ARCHIVE)
local cl_lefthandfire = CreateClientConVar("vrmod_lefthandleftfire", 1, true, FCVAR_ARCHIVE)
local cl_hudonlykey = CreateClientConVar("vrmod_hud_visible_quickmenukey", 0, true, FCVAR_ARCHIVE)
if SERVER then return end
local ply = LocalPlayer()
local VRKeyStates = {}

local cl_auto_vehicle = CreateClientConVar("vrmod_auto_vehicle_scheme", "1", true, FCVAR_ARCHIVE,
	"Auto-detect vehicle type and switch control scheme", 0, 1)

-- Detection priority: LVS > Simfphys > Glide > Vanilla
-- Returns: "lvs_wheel", "lvs_air", "simfphys", "glide", "vanilla", or nil
local function DetectVehicleType()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:InVehicle() then return nil end

	-- LVS
	if ply.lvsGetVehicle then
		local lvsVeh = ply:lvsGetVehicle()
		if IsValid(lvsVeh) then
			local cls = string.lower(lvsVeh:GetClass())
			if string.find(cls, "wheeldrive") then
				return "lvs_wheel"
			end
			return "lvs_air"
		end
	end

	-- Simfphys
	if ply.GetSimfphys and ply.IsDrivingSimfphys then
		local simVeh = ply:GetSimfphys()
		if IsValid(simVeh) and ply:IsDrivingSimfphys() then
			return "simfphys"
		end
	end

	-- Glide
	if Glide then
		local glideVeh = ply:GetNWEntity("GlideVehicle")
		if IsValid(glideVeh) then
			return "glide"
		end
	end

	return "vanilla"
end

hook.Add(
	"VRMod_EnterVehicle",
	"vrmod_switchactionset",
	function()
		if cl_bothkey:GetBool() then
			LocalPlayer():ConCommand("vrmod_keymode_both")
		else
			VRMOD_SetActiveActionSets("/actions/base", "/actions/driving")
		end

		if not cl_auto_vehicle:GetBool() then return end

		-- Defer detection to allow vehicle entity to initialize
		timer.Simple(0.1, function()
			local vehType = DetectVehicleType()
			if not vehType then return end

			g_VR._activeVehicleType = vehType

			if vehType == "lvs_wheel" or vehType == "lvs_air" then
				if not game.SinglePlayer() then
					RunConsoleCommand("vrmod_lvs_input_mode", "1")
				end
			end

			print("[VRMod] Auto-detected vehicle: " .. vehType)
		end)
	end
)

hook.Add(
	"VRMod_ExitVehicle",
	"vrmod_switchactionset",
	function()
		VRMOD_SetActiveActionSets("/actions/base", "/actions/main")

		local prevType = g_VR._activeVehicleType
		g_VR._activeVehicleType = nil

		if prevType then
			print("[VRMod] Exited " .. prevType .. " vehicle, restored main controls")
		end
	end
)

hook.Add(
	"VRMod_Input",
	"vrutil_hook_defaultinput",
	function(action, pressed)
		if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
		if action == "boolean_primaryfire" then
			if not g_VR.menuFocus or g_VR.desktopMirrorTransparentInput then
				LocalPlayer():ConCommand(pressed and "+attack" or "-attack")
			end

			return
		end

		if action == "boolean_secondaryfire" then
			if not g_VR.menuFocus or g_VR.desktopMirrorTransparentInput then
				if cl_lefthand:GetBool() and cl_lefthandfire:GetBool() then return end
				LocalPlayer():ConCommand(pressed and "+attack2" or "-attack2")
			end

			return
		end

		if action == "boolean_forword" then
			LocalPlayer():ConCommand(pressed and "+forward" or "-forward")

			return
		end

		if action == "boolean_back" then
			LocalPlayer():ConCommand(pressed and "+back" or "-back")

			return
		end

		if action == "boolean_left" then
			LocalPlayer():ConCommand(pressed and "+moveleft" or "-moveleft")

			return
		end

		if action == "boolean_right" then
			LocalPlayer():ConCommand(pressed and "+moveright" or "-moveright")

			return
		end

		if action == "boolean_left_pickup" then
			if not pressed then
				vrmod.Pickup(true, true)
				return
			end
			if cl_pickupdisable:GetBool() then return end
			vrmod.Pickup(true, false)

			return
		end

		if action == "boolean_right_pickup" then
			if not pressed then
				vrmod.Pickup(false, true)
				return
			end
			if cl_pickupdisable:GetBool() then return end
			vrmod.Pickup(false, false)

			return
		end

		if action == "boolean_lefthandmode" then
			LocalPlayer():ConCommand("vrmod_lefthand 1")
		end

		if action == "boolean_righthandmode" then
			LocalPlayer():ConCommand("vrmod_lefthand 0")
		end

		if action == "boolean_use" or action == "boolean_exit" then
			if pressed then
				LocalPlayer():ConCommand("+use")
				local wep = LocalPlayer():GetActiveWeapon()
				if IsValid(wep) and wep:GetClass() == "weapon_physgun" then
					hook.Add(
						"CreateMove",
						"vrutil_hook_cmphysguncontrol",
						function(cmd)
							if g_VR.input.vector2_walkdirection.y > 0.9 then
								cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_FORWARD))
							elseif g_VR.input.vector2_walkdirection.y < -0.9 then
								cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_BACK))
							else
								cmd:SetMouseX(g_VR.input.vector2_walkdirection.x * 50)
								cmd:SetMouseY(g_VR.input.vector2_walkdirection.y * -50)
							end
						end
					)
				end
			else
				LocalPlayer():ConCommand("-use")
				hook.Remove("CreateMove", "vrutil_hook_cmphysguncontrol")
			end

			return
		end

		if action == "boolean_changeweapon" then
			if pressed then
				VRUtilWeaponMenuOpen()
				if cl_hudonlykey:GetBool() then
					LocalPlayer():ConCommand("vrmod_hud 1")
				end
			else
				VRUtilWeaponMenuClose()
				if cl_hudonlykey:GetBool() then
					LocalPlayer():ConCommand("vrmod_hud 0")
				end
			end

			return
		end

		if action == "boolean_flashlight" and pressed then
			LocalPlayer():ConCommand("impulse 100")

			return
		end

		if action == "boolean_reload" then
			LocalPlayer():ConCommand(pressed and "+reload" or "-reload")

			return
		end

		if action == "boolean_undo" then
			if pressed then
				LocalPlayer():ConCommand("gmod_undo")
			end

			return
		end

		if action == "boolean_spawnmenu" then
			if pressed then
				g_VR.MenuOpen()
				if cl_hudonlykey:GetBool() then
					LocalPlayer():ConCommand("vrmod_hud 1")
				end
			else
				g_VR.MenuClose()
				if cl_hudonlykey:GetBool() then
					LocalPlayer():ConCommand("vrmod_hud 0")
				end
			end

			return
		end

		if action == "boolean_chat" then
			LocalPlayer():ConCommand(pressed and "+zoom" or "-zoom")

			return
		end

		if action == "boolean_walkkey" then
			LocalPlayer():ConCommand(pressed and "+walk" or "-walk")

			return
		end

		if action == "boolean_menucontext" then
			LocalPlayer():ConCommand(pressed and "+menu_context" or "-menu_context")

			return
		end

		if (action == "boolean_left_primaryfire") and (not g_VR.menuFocus or g_VR.desktopMirrorTransparentInput) and cl_lefthand:GetBool() and cl_lefthandfire:GetBool() then
			LocalPlayer():ConCommand(pressed and "+attack" or "-attack")

			return
		end

		if (action == "boolean_left_secondaryfire") and (not g_VR.menuFocus or g_VR.desktopMirrorTransparentInput) and cl_lefthand:GetBool() and cl_lefthandfire:GetBool() then
			LocalPlayer():ConCommand(pressed and "+attack2" or "-attack2")

			return
		end

		if action == "boolean_slot1" then
			if pressed then
				LocalPlayer():ConCommand("slot1")
			end

			return
		end

		if action == "boolean_slot2" then
			if pressed then
				LocalPlayer():ConCommand("slot2")
			end

			return
		end

		if action == "boolean_slot3" then
			if pressed then
				LocalPlayer():ConCommand("slot3")
			end

			return
		end

		if action == "boolean_slot4" then
			if pressed then
				LocalPlayer():ConCommand("slot4")
			end

			return
		end

		if action == "boolean_slot5" then
			if pressed then
				LocalPlayer():ConCommand("slot5")
			end

			return
		end

		if action == "boolean_slot6" then
			if pressed then
				LocalPlayer():ConCommand("slot6")
			end

			return
		end

		if action == "boolean_invnext" then
			if pressed then
				LocalPlayer():ConCommand("invnext")
			end

			return
		end

		if action == "boolean_invprev" then
			if pressed then
				LocalPlayer():ConCommand("invprev")
			end

			return
		end


		for i = 1, #g_VR.CustomActions do
			if action == g_VR.CustomActions[i][1] then
				local commands = string.Explode(";", g_VR.CustomActions[i][pressed and 2 or 3], false)
				for j = 1, #commands do
					local args = string.Explode(" ", commands[j], false)
					RunConsoleCommand(args[1], unpack(args, 2))
				end
			end
		end
	end
)
-- VRMod_Input フックを追加し、入力アクションを監視します
-- hook.Add(
-- 	"VRMod_Input",
-- 	"vre_drop_items_on_release",
-- 	function(action, pressed)
-- 		-- "boolean_left_pickup" アクションが離されたとき
-- 		if action == "boolean_left_pickup" and not pressed then
-- 			DropItemsHeldByPlayer(LocalPlayer(), true)
-- 		end
-- 		-- "boolean_right_pickup" アクションが離されたとき
-- 		if action == "boolean_right_pickup" and not pressed then
-- 			DropItemsHeldByPlayer(LocalPlayer(), false)
-- 		end
-- 	end
-- )