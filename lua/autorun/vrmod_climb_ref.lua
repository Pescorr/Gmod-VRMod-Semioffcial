-- --------[vrclimb-ref.txt]Start--------

-- --------[sh_vrclimb.lua]Start--------
do
	local vrclimb_enable = CreateClientConVar("vrclimb_enable", "0", true, true, "Enable VR Wall Grapping", 0, 1)
	local CMD_CLIMBSTART, CMD_CLIMBEND = 164, 165 -- Unique impulse commands for climbing
	local vrclimb_ignoreworld = CreateConVar("vrclimb_ignoreworld", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Disables gripping the world to climb", 0, 1)

	local function ToggleClimbingBehavior(enabled)
		if SERVER then -- Server-side climbing logic
			if enabled then
				hook.Add("SetupMove", "vrclimb_SetupMove_Server",
					function(ply, mv, cmd)
						if not IsValid(ply) then return end

						local impulse = cmd:GetImpulse()
						-- Data from client: if climbing, this is target position; if ending climb, this is release velocity.
						local climbDataVec = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())


						if impulse == CMD_CLIMBSTART then
							ply.vrclimb_is_climbing = true
						elseif ply.vrclimb_is_climbing and
							(impulse == CMD_CLIMBEND or
							not ply:Alive() or
							(IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or
							mv:GetOrigin():DistanceSqr(climbDataVec) > 400 * 400) then // Check distance to target position

							ply.vrclimb_is_climbing = false
							if impulse == CMD_CLIMBEND then
								mv:SetVelocity(climbDataVec * 2) // Apply release velocity
							end
							return true
						end

						if ply.vrclimb_is_climbing then
							mv:SetVelocity(vector_origin)
							cmd:ClearMovement()
							mv:SetUpSpeed(0)
							mv:SetForwardSpeed(0)
							mv:SetSideSpeed(0)
							mv:SetOrigin(climbDataVec) // Set origin to target position
							return true
						end
					end
				)
			else
				hook.Remove("SetupMove", "vrclimb_SetupMove_Server")
				for _, pEntity in ipairs(player.GetAll()) do
					if IsValid(pEntity) then
						pEntity.vrclimb_is_climbing = false
					end
				end
			end
		end
	end

	cvars.AddChangeCallback("vrclimb_enable", function(convar_name, value_old, value_new)
		ToggleClimbingBehavior(tobool(value_new))
	end, "vrclimb_ToggleCallback_Shared")

	if SERVER then
		ToggleClimbingBehavior(vrclimb_enable:GetBool())
	end

	concommand.Add("vrclimb_lua_reset_sh_ref", function(ply, cmd, args)
		if SERVER then
			ToggleClimbingBehavior(vrclimb_enable:GetBool())
		end
		print("VRClimb (Reforged) Shared script re-initialized.")
	end)
end
-- --------[sh_vrclimb.lua]End--------

-- --------[cl_vrclimb.lua]Start--------
if CLIENT then
	local vrclimb_enable_cl = GetConVar("vrclimb_enable")
	local vrclimb_ignoreworld_cl = GetConVar("vrclimb_ignoreworld")
	local vrclimb_emptyhanded_cl = CreateClientConVar("vrclimb_emptyhanded", "1", true, true, "0: Allow climb with any weapons - 1: Left hand only with weapons - 2: Empty handed only", 0, 2)

	g_VR_lclimb = false
	g_VR_rclimb = false
	local g_VR_lgrip = false
	local g_VR_rgrip = false

	local g_VR_lclimbpos = Vector()
	local g_VR_rclimbpos = Vector()
	local g_VR_lclimbdir = Vector()
	local g_VR_rclimbdir = Vector()
	local g_VR_lclimbang = Angle()
	local g_VR_rclimbang = Angle()

	local g_VR_lclimblerp = 0
	local g_VR_rclimblerp = 0
	local g_VR_lclimbdeltaold = Vector()
	local g_VR_rclimbdeltaold = Vector()

	local g_VR_climb_start_pos_player = Vector()
	local g_VR_lclimb_start_hand_pos_world = Vector()
	local g_VR_rclimb_start_hand_pos_world = Vector()

	local CMD_CLIMBSTART, CMD_CLIMBEND = 164, 165
	local TRACE_HULL_SIZE = 5
	local UP_VECTOR = Vector(0, 0, 1)
	local ZERO_VECTOR = Vector(0, 0, 0)
	local ZERO_ANGLE = Angle(0, 0, 0)
	local MAX_PLAYER_SPEED_SQR = 500 * 500 -- Used to cap teleport distance

	local g_VR_OldLocoRenderHook = nil
	local g_VR_OldLocoMoveHook = nil

	-- Helper function to check for NaN/Inf in numbers and vectors
	local function IsValidNumeric(val)
		return type(val) == "number" and val == val and math.abs(val) < 1e9 -- Check for NaN and non-huge Inf
	end

	local function IsValidVec(vec)
		if type(vec) ~= "Vector" then return false end
		return IsValidNumeric(vec.x) and IsValidNumeric(vec.y) and IsValidNumeric(vec.z)
	end

	local function SanitizeVector(vec, defaultVec)
		if IsValidVec(vec) then
			return vec
		end
		-- print("[VRClimb Warning] Sanitizing invalid vector. Original:", vec, "Defaulting to:", defaultVec)
		return Vector(defaultVec or ZERO_VECTOR)
	end


	local function TraceForClimbSurface(handPos, ply)
		local trace = {}
		trace.start = SanitizeVector(handPos, ply:GetPos()) -- Sanitize input position
		trace.endpos = Vector(trace.start)
		trace.mins = Vector(-TRACE_HULL_SIZE, -TRACE_HULL_SIZE, -TRACE_HULL_SIZE)
		trace.maxs = Vector(TRACE_HULL_SIZE, TRACE_HULL_SIZE, TRACE_HULL_SIZE)
		trace.filter = ply
		trace.ignoreworld = vrclimb_ignoreworld_cl:GetBool()
		return util.TraceHull(trace)
	end

	local function PlayClimbSound(ply, handVelocityLength, isRelease)
		if not IsValid(ply) then return end
		handVelocityLength = handVelocityLength or 0
		if isRelease then
			if handVelocityLength > 50 then
				ply:EmitSound("ConcreteHandStepFastRelease_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.5)
			end
		else
			if handVelocityLength > 50 then
				ply:EmitSound("ConcreteHandStepHard_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.75)
			else
				ply:EmitSound("ConcreteHandStepSoft_0" .. math.random(1, 4) .. ".wav", 75, 100, 0.5)
			end
		end
	end

	local function UpdateHandFixedPosition()
		if not vrmod.IsPlayerInVR(LocalPlayer()) then return end

		if g_VR_lclimb then
			vrmod.SetLeftHandPose(SanitizeVector(g_VR_lclimbpos), g_VR_lclimbang)
		end
		if g_VR_rclimb then
			vrmod.SetRightHandPose(SanitizeVector(g_VR_rclimbpos), g_VR_rclimbang)
		end
	end

	local function HandleClimbingLogic_CreateMove(cmd)
		if not vrclimb_enable_cl:GetBool() then return end

		local ply = LocalPlayer()
		if not IsValid(ply) or not vrmod.IsPlayerInVR(ply) then return end

		local emptyHandRule = vrclimb_emptyhanded_cl:GetInt()
		local canLeftClimbWithWeapon = (emptyHandRule ~= 2)
		local canRightClimbWithWeapon = (emptyHandRule == 0)
		local isUsingEmptyHands = vrmod.UsingEmptyHands(ply)

		if not g_VR_lclimb then g_VR_lclimblerp = math.Approach(g_VR_lclimblerp, 0, FrameTime()) end
		if not g_VR_rclimb then g_VR_rclimblerp = math.Approach(g_VR_rclimblerp, 0, FrameTime()) end

		if g_VR_lgrip and not g_VR_lclimb and (canLeftClimbWithWeapon or isUsingEmptyHands) then
			local currentLeftHandPos = vrmod.GetLeftHandPos()
			local traceResult = TraceForClimbSurface(currentLeftHandPos, ply)

			if traceResult.Hit and (traceResult.HitWorld or (IsValid(traceResult.Entity) and traceResult.Entity:GetClass() == "prop_physics" and (not IsValid(traceResult.Entity:GetPhysicsObject()) or not traceResult.Entity:GetPhysicsObject():IsMotionEnabled()))) then
				g_VR_lclimb = true
				PlayClimbSound(ply, vrmod.GetLeftHandVelocity():Length(), false)
				g_VR_lclimbdir = SanitizeVector(traceResult.HitNormal, UP_VECTOR)
				g_VR_lclimbang = vrmod.GetLeftHandAng()
				g_VR_lclimb_start_hand_pos_world:Set(SanitizeVector(currentLeftHandPos, ply:GetShootPos()))
				g_VR_lclimbpos:Set(g_VR_lclimb_start_hand_pos_world)

				if not g_VR_rclimb then
					g_VR_lclimblerp = 1
					g_VR_climb_start_pos_player:Set(SanitizeVector(ply:GetPos()))
				end
				cmd:SetImpulse(CMD_CLIMBSTART)
				local sanitizedStartPos = SanitizeVector(g_VR_climb_start_pos_player, ply:GetPos())
				cmd:SetForwardMove(sanitizedStartPos.x)
				cmd:SetSideMove(sanitizedStartPos.y)
				cmd:SetUpMove(sanitizedStartPos.z)
			end
		elseif not g_VR_lgrip and g_VR_lclimb then
			g_VR_lclimb = false
			PlayClimbSound(ply, vrmod.GetLeftHandVelocity():Length(), true)
			if not g_VR_rgrip then
				local releaseVelocity = SanitizeVector(vrmod.GetLeftHandVelocity() * -1, ZERO_VECTOR)
				cmd:SetForwardMove(releaseVelocity.x)
				cmd:SetSideMove(releaseVelocity.y)
				cmd:SetUpMove(releaseVelocity.z)
				cmd:SetImpulse(CMD_CLIMBEND)
			end
		end

		if g_VR_rgrip and not g_VR_rclimb and (canRightClimbWithWeapon or isUsingEmptyHands) then
			local currentRightHandPos = vrmod.GetRightHandPos()
			local traceResult = TraceForClimbSurface(currentRightHandPos, ply)

			if traceResult.Hit and (traceResult.HitWorld or (IsValid(traceResult.Entity) and traceResult.Entity:GetClass() == "prop_physics" and (not IsValid(traceResult.Entity:GetPhysicsObject()) or not traceResult.Entity:GetPhysicsObject():IsMotionEnabled()))) then
				g_VR_rclimb = true
				PlayClimbSound(ply, vrmod.GetRightHandVelocity():Length(), false)
				g_VR_rclimbdir = SanitizeVector(traceResult.HitNormal, UP_VECTOR)
				g_VR_rclimbang = vrmod.GetRightHandAng()
				g_VR_rclimb_start_hand_pos_world:Set(SanitizeVector(currentRightHandPos, ply:GetShootPos()))
				g_VR_rclimbpos:Set(g_VR_rclimb_start_hand_pos_world)

				if not g_VR_lclimb then
					g_VR_rclimblerp = 1
					g_VR_climb_start_pos_player:Set(SanitizeVector(ply:GetPos()))
				end
				cmd:SetImpulse(CMD_CLIMBSTART)
                local sanitizedStartPos = SanitizeVector(g_VR_climb_start_pos_player, ply:GetPos())
				cmd:SetForwardMove(sanitizedStartPos.x)
				cmd:SetSideMove(sanitizedStartPos.y)
				cmd:SetUpMove(sanitizedStartPos.z)
			end
		elseif not g_VR_rgrip and g_VR_rclimb then
			g_VR_rclimb = false
			PlayClimbSound(ply, vrmod.GetRightHandVelocity():Length(), true)
			if not g_VR_lclimb then
				local releaseVelocity = SanitizeVector(vrmod.GetRightHandVelocity() * -1, ZERO_VECTOR)
				cmd:SetForwardMove(releaseVelocity.x)
				cmd:SetSideMove(releaseVelocity.y)
				cmd:SetUpMove(releaseVelocity.z)
				cmd:SetImpulse(CMD_CLIMBEND)
			end
		end

		if g_VR_lclimb or g_VR_rclimb then
			cmd:SetImpulse(CMD_CLIMBSTART)

			local initialPlayerPos = SanitizeVector(g_VR_climb_start_pos_player, ply:GetPos())
			local targetPlayerPos = Vector(initialPlayerPos)
			local totalDelta = Vector(ZERO_VECTOR)
			local handsClimbing = 0

			if g_VR_lclimb then
				handsClimbing = handsClimbing + 1
				local currentLHandPos = SanitizeVector(vrmod.GetLeftHandPos(), g_VR_lclimb_start_hand_pos_world)
				local worldDeltaL = g_VR_lclimb_start_hand_pos_world - currentLHandPos
				worldDeltaL = SanitizeVector(worldDeltaL)
				
				local l_dir_ang = (g_VR_lclimbdir:LengthSqr() > 0.0001) and g_VR_lclimbdir:Angle() or ZERO_ANGLE
				g_VR_lclimbdeltaold = SanitizeVector(LocalToWorld(worldDeltaL, ZERO_ANGLE, worldDeltaL, l_dir_ang))
				totalDelta:Add(g_VR_lclimbdeltaold)
			elseif g_VR_lclimblerp > 0 then
				totalDelta:Add(SanitizeVector(g_VR_lclimbdeltaold))
			end

			if g_VR_rclimb then
				handsClimbing = handsClimbing + 1
				local currentRHandPos = SanitizeVector(vrmod.GetRightHandPos(), g_VR_rclimb_start_hand_pos_world)
				local worldDeltaR = g_VR_rclimb_start_hand_pos_world - currentRHandPos
				worldDeltaR = SanitizeVector(worldDeltaR)

				local r_dir_ang = (g_VR_rclimbdir:LengthSqr() > 0.0001) and g_VR_rclimbdir:Angle() or ZERO_ANGLE
				g_VR_rclimbdeltaold = SanitizeVector(LocalToWorld(worldDeltaR, ZERO_ANGLE, worldDeltaR, r_dir_ang))
				totalDelta:Add(g_VR_rclimbdeltaold)
			elseif g_VR_rclimblerp > 0 then
				totalDelta:Add(SanitizeVector(g_VR_rclimbdeltaold))
			end
			
			totalDelta = SanitizeVector(totalDelta)

			if handsClimbing > 0 then
				targetPlayerPos:Add(totalDelta * (1 / math.max(1, handsClimbing)))
			end
			targetPlayerPos = SanitizeVector(targetPlayerPos, ply:GetPos())
            
			local currentPlyPos = SanitizeVector(ply:GetPos())
			if targetPlayerPos:DistanceSqr(currentPlyPos) > MAX_PLAYER_SPEED_SQR then
				targetPlayerPos:Set(currentPlyPos + (targetPlayerPos - currentPlyPos):GetNormalized() * math.sqrt(MAX_PLAYER_SPEED_SQR * 0.9)) -- Cap distance
			end
			targetPlayerPos = SanitizeVector(targetPlayerPos, currentPlyPos)


			cmd:SetForwardMove(targetPlayerPos.x)
			cmd:SetSideMove(targetPlayerPos.y)
			cmd:SetUpMove(targetPlayerPos.z)
		end
	end

	local function DetourLocomotionRender()
		if not g_VR_OldLocoRenderHook then return end
		g_VR_OldLocoRenderHook() 

		if g_VR_lclimb or g_VR_rclimb then
			local ply = LocalPlayer()
			if not IsValid(ply) then return end
			local plyPos = SanitizeVector(ply:GetPos())

			local hmdPosForLoco = SanitizeVector(g_VR.tracking.hmd.pos, ply:GetShootPos()) + UP_VECTOR:Cross(g_VR.tracking.hmd.ang:Right()) * -10
			local followVecForLoco = (ply:GetMoveType() == MOVETYPE_NOCLIP) and ZERO_VECTOR or Vector((hmdPosForLoco.x - plyPos.x) * 8, (plyPos.y - hmdPosForLoco.y) * -8, 0)
			followVecForLoco = SanitizeVector(followVecForLoco)

			local groundEntForLoco = ply:GetGroundEntity()
			local groundVelForLoco = (IsValid(groundEntForLoco) and IsValidVec(groundEntForLoco:GetVelocity())) and groundEntForLoco:GetVelocity() or ZERO_VECTOR
			
			local currentLocoIntentVelocity = SanitizeVector(ply:GetVelocity()) - followVecForLoco + groundVelForLoco
			currentLocoIntentVelocity.z = 0
			currentLocoIntentVelocity = SanitizeVector(currentLocoIntentVelocity)


			if currentLocoIntentVelocity:LengthSqr() < (15 * 15) then
				g_VR.origin = SanitizeVector(g_VR.origin, plyPos - UP_VECTOR * 64) + currentLocoIntentVelocity * FrameTime()
			end
			g_VR.origin.z = plyPos.z
			g_VR.origin = SanitizeVector(g_VR.origin, plyPos - UP_VECTOR * 64)
		end
	end

	local function DetourLocomotionMove(cmd)
		if g_VR_OldLocoMoveHook then
			g_VR_OldLocoMoveHook(cmd)
		end
		HandleClimbingLogic_CreateMove(cmd)
	end

	local function SetupGmodVRHookDetours()
		local gmodVRHooks = hook.GetTable()
		if gmodVRHooks.PreRender and gmodVRHooks.PreRender.vrmod_locomotion then
			if not g_VR_OldLocoRenderHook then
				g_VR_OldLocoRenderHook = gmodVRHooks.PreRender.vrmod_locomotion
				gmodVRHooks.PreRender.vrmod_locomotion = DetourLocomotionRender
			end
		else
			g_VR_OldLocoRenderHook = nil
		end

		if gmodVRHooks.CreateMove and gmodVRHooks.CreateMove.vrmod_locomotion then
			if not g_VR_OldLocoMoveHook then
				g_VR_OldLocoMoveHook = gmodVRHooks.CreateMove.vrmod_locomotion
				gmodVRHooks.CreateMove.vrmod_locomotion = DetourLocomotionMove
			end
		else
			g_VR_OldLocoMoveHook = nil
		end
	end
	
	local function RevertGmodVRHookDetours()
		local gmodVRHooks = hook.GetTable()
		if g_VR_OldLocoRenderHook and gmodVRHooks.PreRender and gmodVRHooks.PreRender.vrmod_locomotion == DetourLocomotionRender then
			gmodVRHooks.PreRender.vrmod_locomotion = g_VR_OldLocoRenderHook
			g_VR_OldLocoRenderHook = nil
		end
		if g_VR_OldLocoMoveHook and gmodVRHooks.CreateMove and gmodVRHooks.CreateMove.vrmod_locomotion == DetourLocomotionMove then
			gmodVRHooks.CreateMove.vrmod_locomotion = g_VR_OldLocoMoveHook
			g_VR_OldLocoMoveHook = nil
		end
	end

	local function InitializeClimbingSystem()
		if not vrmod.IsPlayerInVR(LocalPlayer()) then return end
		
		SetupGmodVRHookDetours()

		hook.Add("VRMod_Input", "vrclimb_GripInput_Client",
			function(actionName, isPressed)
				if actionName == "boolean_left_pickup" then
					g_VR_lgrip = isPressed
				elseif actionName == "boolean_right_pickup" then
					g_VR_rgrip = isPressed
				end
			end
		)
		hook.Add("VRMod_PreRender", "vrclimb_HandFix_Client", UpdateHandFixedPosition)
	end

	local function ShutdownClimbingSystem()
		RevertGmodVRHookDetours() 

		hook.Remove("VRMod_Input", "vrclimb_GripInput_Client")
		hook.Remove("VRMod_PreRender", "vrclimb_HandFix_Client")
		
		g_VR_lclimb = false
		g_VR_rclimb = false
		g_VR_lgrip = false
		g_VR_rgrip = false
	end

	cvars.AddChangeCallback("vrclimb_enable", function(convar_name, value_old, value_new)
		if tobool(value_new) then
			InitializeClimbingSystem()
		else
			ShutdownClimbingSystem()
		end
	end, "vrclimb_ToggleCallback_Client")

	hook.Add("VRMod_Start", "vrclimb_OnVRStart_Client",
		function(ply)
			if ply ~= LocalPlayer() then return end
			if vrclimb_enable_cl:GetBool() then
				InitializeClimbingSystem()
			end
		end
	)

	hook.Add("VRMod_Exit", "vrclimb_OnVRExit_Client",
		function(ply)
			if ply ~= LocalPlayer() then return end
			ShutdownClimbingSystem()
		end
	)
	
	timer.Simple(0.1, function()
		if vrclimb_enable_cl:GetBool() and vrmod.IsPlayerInVR(LocalPlayer()) then
			InitializeClimbingSystem()
		end
	end)

	concommand.Add("vrclimb_lua_reset_cl_ref", function(ply, cmd, args)
		ShutdownClimbingSystem()
		if vrclimb_enable_cl:GetBool() and vrmod.IsPlayerInVR(LocalPlayer()) then
			InitializeClimbingSystem()
		end
		print("VRClimb (Reforged) Client script re-initialized.")
	end)
end
-- --------[cl_vrclimb.lua]End--------

-- --------[vrclimb-ref.txt]End--------