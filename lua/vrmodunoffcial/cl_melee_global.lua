-- Assuming these ConVars are already defined in your script
local cv_allowgunmelee = CreateClientConVar("arcticvr_gunmelee", "1", FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE)
local cv_usegunmelee = CreateClientConVar("arcticvr_gunmelee_client", "1", FCVAR_ARCHIVE)
-- Global function for melee attacks
local function GlobalMeleeAttack(src, vel, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	local weapon = attacker:GetActiveWeapon()
	if not IsValid(weapon) then return end
	-- Define default values for melee attack
	local meleeDamage = 10 -- Default damage, adjust as needed
	local meleeDamageType = DMG_CLUB -- Default damage type, adjust as needed
	local meleeDelay = 0.1 -- Delay between melee attacks, adjust as needed
	-- Prevent rapid-fire melee attacks
	if weapon.NextMeleeAttack and weapon.NextMeleeAttack > CurTime() then return end
	attacker:LagCompensation(true)
	attacker:FireBullets(
		{
			Damage = meleeDamage,
			Src = src,
			Dir = vel:GetNormalized(),
			Tracer = 0,
			Distance = 8,
			Force = meleeDamage / 3,
			Callback = function(att, tr, dmg)
				dmg:SetDamageType(meleeDamageType)
			end
		}
	)

	attacker:LagCompensation(false)
	-- Store the time of the next allowed melee attack
	weapon.NextMeleeAttack = CurTime() + meleeDelay
end

-- Function to handle melee attacks
local function HandleplusMeleeAttack_weapon()
	local ply = LocalPlayer()
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end
	if cv_usegunmelee:GetBool() and cv_allowgunmelee:GetBool() then
		local vm = g_VR.viewModel
		if not vm then return end
		if not IsValid(vm) then return end
		if not vm:GetAttachment(1) then return end
		local vel = g_VR.tracking.pose_righthand.vel:Length() / 40
		-- detect hit targets
		local startbone = vm:GetAttachment(1).Pos
		local endbone = vm:GetAttachment(2).Pos
		local tr = util.TraceLine(
			{
				start = startbone,
				endpos = endbone,
				mask = MASK_ALL,
				filter = LocalPlayer()
			}
		)

		-- submit attack
		if tr.Hit then
			local src = tr.HitPos + (tr.HitNormal * -2)
			local tr2 = util.TraceLine(
				{
					start = src,
					endpos = src + (g_VR.tracking.pose_righthand.vel:GetNormalized() * 8),
					mask = MASK_ALL
				}
			)

			if not tr2.Hit then return end
			net.Start("avr_meleeattack_weapon")
			net.WriteFloat(src[1])
			net.WriteFloat(src[2])
			net.WriteFloat(src[3])
			net.WriteVector(g_VR.tracking.pose_righthand.vel)
			net.SendToServer()
		end

		print("Melee attack performed with weapon: " .. weapon:GetClass())
	end
end

-- local function HandleplusMeleeAttack_left()
-- 	local ply = LocalPlayer()
-- 	local weapon = ply:GetActiveWeapon()
-- 	if not IsValid(weapon) then return end
-- 	if cv_usegunmelee:GetBool() and cv_allowgunmelee:GetBool() then
-- 		local vm = g_VR.viewModel
-- 		if not vm then return end
-- 		if not IsValid(vm) then return end
-- 		local vel = g_VR.tracking.pose_lefthand.vel:Length() / 40
-- 		-- detect hit targets
-- 		local startbone = g_VR.tracking.pose_lefthand.pos
-- 		local endbone = g_VR.tracking.pose_lefthand.pos
-- 		local tr = util.TraceLine(
-- 			{
-- 				start = startbone,
-- 				endpos = endbone,
-- 				mask = MASK_ALL,
-- 				filter = LocalPlayer()
-- 			}
-- 		)

-- 		-- submit attack
-- 		if tr.Hit then
-- 			local src = tr.HitPos + (tr.HitNormal * -2)
-- 			local tr2 = util.TraceLine(
-- 				{
-- 					start = src,
-- 					endpos = src + (g_VR.tracking.pose_lefthand.vel:GetNormalized() * 8),
-- 					mask = MASK_ALL
-- 				}
-- 			)

-- 			if not tr2.Hit then return end
-- 			net.Start("avr_meleeattack_weapon")
-- 			net.WriteFloat(src[1])
-- 			net.WriteFloat(src[2])
-- 			net.WriteFloat(src[3])
-- 			net.WriteVector(g_VR.tracking.pose_lefthand.vel)
-- 			net.SendToServer()
-- 		end

-- 		print("Melee attack performed with weapon: " .. weapon:GetClass())
-- 	end
-- end

-- Hook into game loop to detect melee attacks
hook.Add(
	"Think",
	"CustomMeleeAttackDetection",
	function()
		HandleplusMeleeAttack_weapon()
		-- HandleplusMeleeAttack_left()
	end
)

-- Network handling for server-side melee attack logic
if SERVER then
	util.AddNetworkString("avr_meleeattack_weapon")
	net.Receive(
		"avr_meleeattack_weapon",
		function(len, ply)
			local src = Vector(0, 0, 0)
			src[1] = net.ReadFloat()
			src[2] = net.ReadFloat()
			src[3] = net.ReadFloat()
			local vel = net.ReadVector()
			local weapon = ply:GetActiveWeapon()
			-- Check if the weapon has the VR_Melee function (for compatibility)
			if weapon and weapon.VR_Melee then
				weapon:VR_Melee(src, vel)
			else
				-- Use the global melee attack function for weapons without VR_Melee
				GlobalMeleeAttack(src, vel, ply)
			end
		end
	)
else -- CLIENT
end
-- Client-side melee attack logic (if needed)...