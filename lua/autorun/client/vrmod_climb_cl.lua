-- --------[cl_vrclimb.lua]Start--------
local vrclimb_ignoreworld = CreateConVar("vrclimb_ignoreworld", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Disables gripping the world to climb", 0, 1)
local vrclimb_emptyhanded = CreateConVar("vrclimb_emptyhanded", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "0: Allow climb with any weapons - 1: Left hand only with weapons - 2: Empty handed only", 0, 2)
lclimb, rclimb = false, false
local lgrip, rgrip = false, false
local lclimbpos, rclimbpos = Vector(), Vector()
local lclimbdir, rclimbdir = Vector(), Vector()
local lclimbang, rclimbang = Angle(), Angle()
local lclimblerp = 0
local rclimblerp = 0
local lclimbdeltaold = Vector()
local rclimbdeltaold = Vector()
local csize = 5
local lclimbtr_out = {}
local lclimbtr = {
	start = Vector(),
	endpos = Vector(),
	mins = Vector(-csize, -csize, -csize),
	maxs = Vector(csize, csize, csize),
	output = lclimbtr_out
}

local rclimbtr_out = {}
local rclimbtr = {
	start = Vector(),
	endpos = Vector(),
	mins = Vector(-csize, -csize, -csize),
	maxs = Vector(csize, csize, csize),
	output = rclimbtr_out
}

local climbpos = Vector()
local lclimbhandpos = Vector()
local rclimbhandpos = Vector()
local CMD_CLIMBSTART, CMD_CLIMBEND = 164, 165
local upVec = Vector(0, 0, 1)
local zeroVec = Vector(0, 0, 0)
local angle_zero = Angle(0, 0, 0)
local OldLocoRender = nil
local OldLocoMove = nil
local originVelocity = Vector()
hook.Add(
	"VRMod_Input",
	"vrclimbgrip",
	function(action, state)
		if action == "boolean_left_pickup" then
			lgrip = state
		elseif action == "boolean_right_pickup" then
			rgrip = state
		end
	end
)

local function GetClimbSurfacePos(left)
	return (left and vrmod.GetLeftHandPos()) or vrmod.GetRightHandPos()
end

function CreateMove_VRClimb(cmd)
	local ply = LocalPlayer()
	if not vrmod or not vrmod.IsPlayerInVR(ply) then return end
	local cvareh = vrclimb_emptyhanded:GetInt()
	if not lclimb then
		lclimblerp = math.Approach(lclimblerp, 0, FrameTime())
	end

	if not rclimb then
		rclimblerp = math.Approach(rclimblerp, 0, FrameTime())
	end

	if lgrip and not lclimb and (cvareh ~= 2 or vrmod.UsingEmptyHands(ply)) then
		lclimbtr.start:Set(vrmod.GetLeftHandPos())
		lclimbtr.endpos:Set(lclimbtr.start)
		lclimbtr.filter = ply
		lclimbtr.ignoreworld = vrclimb_ignoreworld:GetBool()
		util.TraceHull(lclimbtr)
		if lclimbtr_out.Hit then
			if lclimbtr_out.HitWorld or (IsValid(lclimbtr_out.Entity) and lclimbtr_out.Entity:GetClass() == "prop_physics" and (not IsValid(lclimbtr_out.Entity:GetPhysicsObject()) or not lclimbtr_out.Entity:GetPhysicsObject():IsMotionEnabled())) then
				local spos = GetClimbSurfacePos(true)
				lclimbhandpos:Set(spos)
				lclimb = true
				if vrmod.GetLeftHandVelocity():Length() > 50 then
					ply:EmitSound("ConcreteHandStepHard_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.75)
				else
					ply:EmitSound("ConcreteHandStepSoft_0" .. math.random(1, 4) .. ".wav", 75, 100, 0.5)
				end

				lclimbdir:Set(lclimbtr_out.HitNormal)
				lclimbang:Set(vrmod.GetLeftHandAng())
				if not rclimb then
					lclimblerp = 1
					climbpos:Set(ply:GetPos())
				end

				lclimbpos:Set(spos)
				cmd:SetImpulse(CMD_CLIMBSTART)
			end
		end
	elseif not lgrip and lclimb then
		lclimb = false
		if vrmod.GetLeftHandVelocity():Length() > 50 then
			ply:EmitSound("ConcreteHandStepFastRelease_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.5)
		end

		if not rgrip then
			local targetpos_vel = -vrmod.GetLeftHandVelocity()
			cmd:SetForwardMove(targetpos_vel.x)
			cmd:SetSideMove(targetpos_vel.y)
			cmd:SetUpMove(targetpos_vel.z)
			cmd:SetImpulse(CMD_CLIMBEND)

			return true
		end
	end

	if rgrip and not rclimb and (cvareh == 0 or (cvareh == 1 and vrmod.UsingEmptyHands(ply))) then
		rclimbtr.start:Set(vrmod.GetRightHandPos())
		rclimbtr.endpos:Set(rclimbtr.start)
		rclimbtr.filter = ply
		rclimbtr.ignoreworld = vrclimb_ignoreworld:GetBool()
		util.TraceHull(rclimbtr)
		if rclimbtr_out.Hit then
			if rclimbtr_out.HitWorld or (IsValid(rclimbtr_out.Entity) and rclimbtr_out.Entity:GetClass() == "prop_physics" and (not IsValid(rclimbtr_out.Entity:GetPhysicsObject()) or not rclimbtr_out.Entity:GetPhysicsObject():IsMotionEnabled())) then
				local spos = GetClimbSurfacePos(false)
				rclimbhandpos:Set(spos)
				rclimb = true
				if vrmod.GetRightHandVelocity():Length() > 50 then
					ply:EmitSound("ConcreteHandStepHard_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.75)
				else
					ply:EmitSound("ConcreteHandStepSoft_0" .. math.random(1, 4) .. ".wav", 75, 100, 0.5)
				end

				rclimbdir:Set(rclimbtr_out.HitNormal)
				rclimbang:Set(vrmod.GetRightHandAng())
				if not lclimb then
					rclimblerp = 1
					climbpos:Set(ply:GetPos())
				end

				rclimbpos:Set(spos)
				cmd:SetImpulse(CMD_CLIMBSTART)
			end
		end
	elseif not rgrip and rclimb then
		rclimb = false
		if vrmod.GetRightHandVelocity():Length() > 50 then
			ply:EmitSound("ConcreteHandStepFastRelease_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.5)
		end

		if not lgrip then
			local targetpos_vel = -vrmod.GetRightHandVelocity()
			cmd:SetForwardMove(targetpos_vel.x)
			cmd:SetSideMove(targetpos_vel.y)
			cmd:SetUpMove(targetpos_vel.z)
			cmd:SetImpulse(CMD_CLIMBEND)

			return true
		end
	end

	if (lgrip and lclimb) or (rgrip and rclimb) then
		cmd:SetImpulse(CMD_CLIMBSTART)
		local pos = EyePos() - Vector(0, 0, 64)
		local final_lclimbdelta = Vector()
		local final_rclimbdelta = Vector()
		if lclimb or lclimblerp > 0 then
			if not lclimb then
				final_lclimbdelta:Set(lclimbdeltaold)
			else
				local current_lclimbdelta = LocalToWorld(lclimbpos - lclimbhandpos, angle_zero, vector_origin, lclimbdir:Angle())
				final_lclimbdelta:Set(current_lclimbdelta)
				lclimbdeltaold:Set(current_lclimbdelta)
			end
		end

		if rclimb or rclimblerp > 0 then
			if not rclimb then
				final_rclimbdelta:Set(rclimbdeltaold)
			else
				local current_rclimbdelta = LocalToWorld(rclimbpos - rclimbhandpos, angle_zero, vector_origin, rclimbdir:Angle())
				final_rclimbdelta:Set(current_rclimbdelta)
				rclimbdeltaold:Set(current_rclimbdelta)
			end
		end

		local targetpos_cmd = Vector(pos)
		if lclimb or lclimblerp > 0 then
			lclimblerp = math.Approach(lclimblerp, 1, FrameTime() * 0.5)
			local ldelta_to_apply = Vector(final_lclimbdelta)
			if rclimb or rclimblerp > 0 then
				ldelta_to_apply:Mul(Lerp(rclimblerp, 1, 0.5))
			end

			targetpos_cmd:Add(LerpVector(lclimblerp, zeroVec, ldelta_to_apply))
		end

		if rclimb or rclimblerp > 0 then
			rclimblerp = math.Approach(rclimblerp, 1, FrameTime() * 0.5)
			local rdelta_to_apply = Vector(final_rclimbdelta)
			if lclimb or lclimblerp > 0 then
				rdelta_to_apply:Mul(Lerp(lclimblerp, 1, 0.5))
			end

			targetpos_cmd:Add(LerpVector(rclimblerp, zeroVec, rdelta_to_apply))
		end

		local plypos_current = ply:GetPos()
		if targetpos_cmd:Distance(plypos_current) > 500 then
			targetpos_cmd:Set(plypos_current)
		end

		cmd:SetForwardMove(targetpos_cmd.x)
		cmd:SetSideMove(targetpos_cmd.y)
		cmd:SetUpMove(targetpos_cmd.z)
	end
end

local function loco_detour()
	local oldlocorender_func = OldLocoRender
	if not oldlocorender_func then return end
	oldlocorender_func()
	if (lclimb or rclimb) and originVelocity:Length() < 15 then
		local ply = LocalPlayer()
		local plyPos = ply:GetPos()
		local plyTargetPosHMD = g_VR.tracking.hmd.pos + upVec:Cross(g_VR.tracking.hmd.ang:Right()) * -10
		local followVecCalc = (ply:GetMoveType() == MOVETYPE_NOCLIP) and zeroVec or Vector((plyTargetPosHMD.x - plyPos.x) * 8, (plyPos.y - plyTargetPosHMD.y) * -8, 0)
		local groundEnt = ply:GetGroundEntity()
		local groundVel = IsValid(groundEnt) and groundEnt:GetVelocity() or zeroVec
		originVelocity:Set(ply:GetVelocity() - followVecCalc + groundVel)
		originVelocity.z = 0
		g_VR.origin = g_VR.origin + originVelocity * FrameTime()
		g_VR.origin.z = plyPos.z
	end
end

local function locomove_detour(cmd)
	if OldLocoMove then
		OldLocoMove(cmd)
	end

	CreateMove_VRClimb(cmd)
end

hook.Add(
	"Tick",
	"vrclimb_locodetour",
	function()
		if not hook.GetTable().PreRender then return end
		if not vrmod.IsPlayerInVR(LocalPlayer()) and (not hook.GetTable().PreRender.vrmod_locomotion or not OldLocoRender) then
			OldLocoRender = nil

			return
		end

		if OldLocoRender then return end
		if hook.GetTable().PreRender.vrmod_locomotion then
			OldLocoRender = hook.GetTable().PreRender.vrmod_locomotion
			hook.GetTable().PreRender.vrmod_locomotion = loco_detour
		end
	end
)

hook.Add(
	"Tick",
	"vrclimb_cmdetour",
	function()
		if not hook.GetTable().CreateMove then return end
		if not vrmod.IsPlayerInVR(LocalPlayer()) and (not hook.GetTable().CreateMove.vrmod_locomotion or not OldLocoMove) then
			OldLocoMove = nil

			return
		end

		if OldLocoMove then return end
		if hook.GetTable().CreateMove.vrmod_locomotion then
			OldLocoMove = hook.GetTable().CreateMove.vrmod_locomotion
			hook.GetTable().CreateMove.vrmod_locomotion = locomove_detour
		end
	end
)

hook.Add(
	"VRMod_PreRender",
	"vrclimbhand",
	function()
		if lclimb then
			lclimbhandpos:Set(vrmod.GetLeftHandPos())
			local ang_render_l = Angle(lclimbang)
			vrmod.SetLeftHandPose(lclimbpos, ang_render_l)
		end

		if rclimb then
			rclimbhandpos:Set(vrmod.GetRightHandPos())
			local ang_render_r = Angle(rclimbang)
			vrmod.SetRightHandPose(rclimbpos, ang_render_r)
		end
	end
)
-- --------[cl_vrclimb.lua]End--------