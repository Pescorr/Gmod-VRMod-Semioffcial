local _, convars, convarValues = vrmod.GetConvars()
local drivingmode = 0
local bothmode = 0
local ply = LocalPlayer()
concommand.Add(
	"vrmod_rehook_pickup",
	function(ply, cmd, args)
		local cvar_mass = CreateConVar("vrgrab_maxmass", "35", bit.bor(FCVAR_REPLICATED, FCVAR_CHEAT), "The heaviest an object can be to get grabbed, in kilograms.", 0)
		function vrgrab.CanGrab(e, pl)
			if CLIENT then
				-- Most entities won't have a PhysObj on the client
				local mass
				local info = util.GetModelInfo(e:GetModel())
				if info and info.KeyValues then
					info = util.KeyValuesToTable(info.KeyValues)
					if info.solid and info.solid.mass then
						mass = info.solid.mass
					end
				end

				return not mass or mass <= cvar_mass:GetFloat()
			end

			local phys = e:GetPhysicsObject()

			return phys:IsValid() and phys:IsMoveable()
		end
	end
)

concommand.Add(
	"vrmod_rehook_arcticvr",
	function(ply, cmd, args)
		hook.Remove("VRMod_SetupOverrides", "ArcVR_GrabOverride")
		CreateConVar("arcticvr_net_magtimertime","0.8",FCVAR_ARCHIVE,"",0.00,9.00)
		if CLIENT then
			hook.Add(
				"VRMod_SetupOverrides",
				"ArcVR_GrabOverride",
				function()
					if ArcticVR then
						hook.Remove("VRMod_Pickup", "avr_pose")
					end
				end
			)
		else
			local function GrabAndPose(ent, pos, ang, lefthand, ply)
				if not IsValid(ent) or not ent.ArcticVR then return end
				if hook.Call("VRMod_Pickup", nil, ply, ent) == false then return end
				vrgrab.NewPickup(ply, lefthand, pos, ang, ent)
			end

			hook.Add("VRMod_SetupOverrides", "ArcVR_GrabOverride", function() end)
			if not ArcticVR then return end
			net.Receive(
				"avr_magout",
				function(len, ply)
					local grab = net.ReadBool()
					local pos = net.ReadVector()
					local ang = net.ReadAngle()
					local wpn = ply:GetActiveWeapon()
					local hpos, hang, lefthand
					if grab then
						hpos = net.ReadVector()
						hang = net.ReadAngle()
						lefthand = net.ReadBool()
					end

					if not wpn.ArcticVR then return end
					if not wpn.Magazine then return end
					local loaded = wpn.LoadedRounds or 0
					local mag = ArcticVR.CreateMag(wpn.Magazine, loaded)
					mag:SetAngles(ang)
					mag:SetPos(pos)
					wpn.Magazine = nil
					wpn.LoadedRounds = 0
					if grab then
						local timertime = 0
						-- if !game.SinglePlayer() then
						timertime = GetConVar("arcticvr_net_magtimertime"):GetFloat()
						-- end
						timer.Simple(
							timertime,
							function()
								GrabAndPose(mag, hpos, hang, lefthand, ply)
							end
						)
					end
				end
			)

			net.Receivers["avr_pose"] = nil
			net.Receive(
				"avr_spawnmag",
				function(len, ply)
					local pos = net.ReadVector()
					local ang = net.ReadAngle()
					local wpn = ply:GetActiveWeapon()
					if not wpn.ArcticVR then return end
					for k, v in pairs(g_VR[ply:SteamID()].heldItems) do
						if v.left then return end
					end

					local magid = wpn.DefaultMagazine
					if wpn:GetAttOverride("MagExtender") then
						if wpn.ExtendedMagazine then
							magid = wpn.ExtendedMagazine
						end
					end

					if wpn:GetAttOverride("MagReducer") then
						if wpn.ReducedMagazine then
							magid = wpn.ReducedMagazine
						end

						if wpn:GetAttOverride("MagExtender") then
							magid = wpn.DefaultMagazine
						end
					end

					local magtbl = ArcticVR.MagazineTable[magid]
					local cap = magtbl.Capacity
					local ammotype = wpn.Primary.Ammo
					local reserve = ply:GetAmmoCount(ammotype)
					local toload = math.Clamp(reserve, 0, cap)
					local mag = ArcticVR.CreateMag(magid, toload)
					if not mag then return end
					ply:SetAmmo(reserve - toload, ammotype)
					mag:SetAngles(ang)
					mag:SetPos(pos)
					local timertime = 0
					-- if !game.SinglePlayer() then
					timertime = GetConVar("arcticvr_net_magtimertime"):GetFloat()
					-- end
					timer.Simple(
						timertime,
						function()
							GrabAndPose(mag, pos, ang, true, ply)
						end
					)
				end
			)
		end
	end
)