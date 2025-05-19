-- --[[
--     GmodVR Climbing Mod (Remake)
--     Originally based on the code from vrmod_climb.txt
-- ]]
-- -- Shared Variables and Constants
-- local CMD_CLIMB_START = 164
-- local CMD_CLIMB_END = 165
-- -- ConVars
-- CreateConVar("vrclimb_ignoreworld", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Disables gripping the world to climb", 0, 1)
-- CreateConVar("vrclimb_emptyhanded", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "0: Allow climb with any weapons - 1: Left hand only with weapons - 2: Empty handed only", 0, 2)
-- -- Shared Logic (sh_vrclimb.lua)
-- hook.Add(
--     "SetupMove",
--     "VRClimb_SetupMove",
--     function(ply, mv, cmd)
--         if not IsValid(ply) then return end
--         if cmd:GetImpulse() == CMD_CLIMB_START then
--             ply.vrclimb_isClimbing = true
--         elseif ply.vrclimb_isClimbing then
--             local climbEndReason = false
--             if cmd:GetImpulse() == CMD_CLIMB_END then
--                 climbEndReason = true
--             elseif not ply:Alive() then
--                 climbEndReason = true
--             end

--             -- The distance check seems to be problematic with how targetpos is set from client now.
--             -- It might be better to handle this purely client-side or rethink the server-side validation.
--             -- elseif mv:GetOrigin():Distance(Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())) > 400 then
--             -- climbEndReason = true
--             if climbEndReason then
--                 ply.vrclimb_isClimbing = false
--                 -- Apply velocity when climbing ends (e.g., throwing oneself off the wall)
--                 -- The velocity components are packed into move commands by the client
--                 local releaseVelocity = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
--                 mv:SetVelocity(releaseVelocity * 2) -- Original multiplier was 2
--                 -- It's important to clear the movement commands after using them for velocity
--                 cmd:ClearMovement()
--                 cmd:SetUpMove(0)
--                 cmd:SetForwardMove(0)
--                 cmd:SetSideMove(0)

--                 return true
--             end
--         end

--         if ply.vrclimb_isClimbing or (CLIENT and (g_VRClimb and (g_VRClimb.isLeftClimbing or g_VRClimb.isRightClimbing))) then
--             local targetPos = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
--             mv:SetVelocity(vector_origin) -- Stop any other momentum
--             cmd:ClearMovement() -- Prevent default movement processing
--             mv:SetUpSpeed(0)
--             mv:SetForwardSpeed(0)
--             mv:SetSideSpeed(0)
--             mv:SetOrigin(targetPos) -- Directly set player position

--             return true
--         end
--     end
-- )

-- if CLIENT then
--     g_VRClimb = g_VRClimb or {}
--     local IGNORE_WORLD_CVAR = GetConVar("vrclimb_ignoreworld")
--     local EMPTY_HANDED_CVAR = GetConVar("vrclimb_emptyhanded")
--     g_VRClimb.isLeftClimbing = false
--     g_VRClimb.isRightClimbing = false
--     local leftClimbWorldPos = Vector()
--     local rightClimbWorldPos = Vector()
--     -- Store the initial relative position/angle of the hand to the climb point
--     local leftClimbInitialLocalPos = Vector()
--     local leftClimbInitialLocalAng = Angle()
--     local rightClimbInitialLocalPos = Vector()
--     local rightClimbInitialLocalAng = Angle()
--     -- Store the player's position when climbing starts, relative to HMD
--     local playerClimbStartOffset = Vector()
--     local CLIMB_SURFACE_CHECK_SIZE = 5 -- How big the trace hull is
--     local function CanClimbWithHands(ply)
--         if not IsValid(ply) then return true end
--         local emptyHandedValue = EMPTY_HANDED_CVAR:GetInt()
--         if emptyHandedValue == 0 then return true end -- Always allow
--         if emptyHandedValue == 2 then return vrmod.UsingEmptyHands(ply) end -- Only empty handed
--         -- emptyHandedValue == 1 (Left hand only with weapons)
--         -- This logic is tricky as "vrmod.UsingEmptyHands" applies to both.
--         -- For simplicity now, if it's 1, we assume left hand can climb if empty, right hand cannot if holding weapon.
--         -- This might need adjustment based on how vrmod.UsingEmptyHands is implemented with specific hand states.
--         -- Simplified: if not empty handed, only left can initiate if that hand becomes free

--         return vrmod.UsingEmptyHands(ply)
--     end

--     local function TryStartClimb(isLeftHand, ply, cmd)
--         if not vrmod.IsPlayerInVR(ply) then return false end
--         local handTracker = isLeftHand and g_VR.tracking.pose_lefthand or g_VR.tracking.pose_righthand
--         if not handTracker then return false end
--         local handPos = handTracker.pos
--         local handAng = handTracker.ang
--         local handVel = handTracker.vel
--         local trace = {}
--         trace.start = handPos
--         trace.endpos = handPos
--         trace.mins = Vector(-CLIMB_SURFACE_CHECK_SIZE, -CLIMB_SURFACE_CHECK_SIZE, -CLIMB_SURFACE_CHECK_SIZE)
--         trace.maxs = Vector(CLIMB_SURFACE_CHECK_SIZE, CLIMB_SURFACE_CHECK_SIZE, CLIMB_SURFACE_CHECK_SIZE)
--         trace.filter = ply
--         trace.ignoreworld = IGNORE_WORLD_CVAR:GetBool()
--         local tr = util.TraceHull(trace)
--         if tr.Hit then
--             local hitEntity = tr.Entity
--             local canGripSurface = false
--             if tr.HitWorld then
--                 canGripSurface = not IGNORE_WORLD_CVAR:GetBool()
--             elseif IsValid(hitEntity) and hitEntity:GetClass() == "prop_physics" then
--                 local physObj = hitEntity:GetPhysicsObject()
--                 -- Only static props
--                 if IsValid(physObj) and not physObj:IsMoveable() then
--                     canGripSurface = true
--                 end
--             end

--             -- Potentially add other grippable entity classes here
--             if canGripSurface then
--                 if isLeftHand then
--                     g_VRClimb.isLeftClimbing = true
--                     leftClimbWorldPos:Set(tr.HitPos) -- Store the exact point we grabbed
--                     -- Store offset of hand to world point
--                     leftClimbInitialLocalPos = WorldToLocal(handPos, Angle(), tr.HitPos, tr.HitNormal:Angle())
--                     leftClimbInitialLocalAng = Angle(0, 0, 0) --WorldToLocal(Angle(), handAng, Angle(), tr.HitNormal:Angle()).y -- Simplified relative angle
--                 else
--                     g_VRClimb.isRightClimbing = true
--                     rightClimbWorldPos:Set(tr.HitPos)
--                     rightClimbInitialLocalPos = WorldToLocal(handPos, Angle(), tr.HitPos, tr.HitNormal:Angle())
--                     rightClimbInitialLocalAng = Angle(0, 0, 0) --WorldToLocal(Angle(), handAng, Angle(), tr.HitNormal:Angle()).y
--                 end

--                 -- Player position relative to HMD and the grabbed point.
--                 -- This helps maintain the player's relative position to their hands.
--                 local hmdPos = g_VR.tracking.hmd.pos
--                 local hmdAngYaw = Angle(0, g_VR.tracking.hmd.ang.y, 0)
--                 playerClimbStartOffset = WorldToLocal(ply:GetPos(), Angle(), hmdPos, hmdAngYaw)
--                 if handVel:Length() > 50 then
--                     ply:EmitSound("ConcreteHandStepHard_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.75)
--                 else
--                     ply:EmitSound("ConcreteHandStepSoft_0" .. math.random(1, 4) .. ".wav", 75, 100, 0.5)
--                 end

--                 cmd:SetImpulse(CMD_CLIMB_START)

--                 return true
--             end
--         end

--         return false
--     end

--     local function EndClimb(isLeftHand, ply, cmd)
--         local handVel = Vector()
--         if isLeftHand then
--             g_VRClimb.isLeftClimbing = false
--             if g_VR.tracking and g_VR.tracking.pose_lefthand then
--                 handVel = g_VR.tracking.pose_lefthand.vel
--             end
--         else
--             g_VRClimb.isRightClimbing = false
--             if g_VR.tracking and g_VR.tracking.pose_righthand then
--                 handVel = g_VR.tracking.pose_righthand.vel
--             end
--         end

--         if handVel:Length() > 50 then
--             ply:EmitSound("ConcreteHandStepFastRelease_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.5)
--         end

--         -- Only send climb end if both hands released
--         if not g_VRClimb.isLeftClimbing and not g_VRClimb.isRightClimbing then
--             local releaseVelocity = -handVel -- Use the velocity of the hand that just released
--             cmd:SetForwardMove(releaseVelocity.x)
--             cmd:SetSideMove(releaseVelocity.y)
--             cmd:SetUpMove(releaseVelocity.z)
--             cmd:SetImpulse(CMD_CLIMB_END)
--         end
--     end

--     hook.Add(
--         "CreateMove",
--         "VRClimb_CreateMove",
--         function(cmd)
--             local ply = LocalPlayer()
--             if not IsValid(ply) or not vrmod.IsPlayerInVR(ply) or not g_VR.tracking then return end
--             local leftGripState = g_VR.input.boolean_left_pickup
--             local rightGripState = g_VR.input.boolean_right_pickup
--             local emptyHandedSetting = EMPTY_HANDED_CVAR:GetInt()
--             -- Handle Left Hand
--             local canLeftClimbThisFrame = true
--             if emptyHandedSetting == 2 and not vrmod.UsingEmptyHands(ply) then
--                 canLeftClimbThisFrame = false
--             end

--             if leftGripState and not g_VRClimb.isLeftClimbing and canLeftClimbThisFrame then
--                 TryStartClimb(true, ply, cmd)
--             elseif not leftGripState and g_VRClimb.isLeftClimbing then
--                 EndClimb(true, ply, cmd)
--             end

--             -- Handle Right Hand
--             local canRightClimbThisFrame = true
--             if emptyHandedSetting == 2 and not vrmod.UsingEmptyHands(ply) then
--                 canRightClimbThisFrame = false
--             elseif emptyHandedSetting == 1 and not vrmod.UsingEmptyHands(ply) then
--                 -- Only left can climb if holding weapon
--                 canRightClimbThisFrame = false
--             end

--             if rightGripState and not g_VRClimb.isRightClimbing and canRightClimbThisFrame then
--                 TryStartClimb(false, ply, cmd)
--             elseif not rightGripState and g_VRClimb.isRightClimbing then
--                 EndClimb(false, ply, cmd)
--             end

--             -- If climbing with either hand
--             if g_VRClimb.isLeftClimbing or g_VRClimb.isRightClimbing then
--                 cmd:SetImpulse(CMD_CLIMB_START) -- Keep telling server we are in climb state
--                 local hmdPos = g_VR.tracking.hmd.pos
--                 local hmdAngYaw = Angle(0, g_VR.tracking.hmd.ang.y, 0)
--                 local currentTargetPlayerPos = LocalToWorld(playerClimbStartOffset, Angle(), hmdPos, hmdAngYaw)
--                 if g_VRClimb.isLeftClimbing and g_VRClimb.isRightClimbing then
--                     -- Both hands climbing: Average the movement based on initial grab points
--                     local leftHandTracker = g_VR.tracking.pose_lefthand
--                     local currentLeftHandWorldPos = LocalToWorld(leftClimbInitialLocalPos, leftClimbInitialLocalAng, leftHandTracker.pos, leftHandTracker.ang)
--                     local movementFromLeft = leftClimbWorldPos - currentLeftHandWorldPos
--                     local rightHandTracker = g_VR.tracking.pose_righthand
--                     local currentRightHandWorldPos = LocalToWorld(rightClimbInitialLocalPos, rightClimbInitialLocalAng, rightHandTracker.pos, rightHandTracker.ang)
--                     local movementFromRight = rightClimbWorldPos - currentRightHandWorldPos
--                     local combinedMovement = (movementFromLeft + movementFromRight) * 0.5
--                     currentTargetPlayerPos = currentTargetPlayerPos - combinedMovement
--                 elseif g_VRClimb.isLeftClimbing then
--                     local leftHandTracker = g_VR.tracking.pose_lefthand
--                     -- Calculate where the original grab point (leftClimbWorldPos) would be NOW,
--                     -- if the player hadn't moved relative to their hand since grabbing.
--                     -- Then, move the player so that this calculated point matches the actual current hand position.
--                     local currentVirtualGrabPoint = LocalToWorld(leftClimbInitialLocalPos, leftClimbInitialLocalAng, leftHandTracker.pos, leftHandTracker.ang)
--                     local movementDelta = leftClimbWorldPos - currentVirtualGrabPoint
--                     currentTargetPlayerPos = currentTargetPlayerPos - movementDelta
--                 elseif g_VRClimb.isRightClimbing then
--                     local rightHandTracker = g_VR.tracking.pose_righthand
--                     local currentVirtualGrabPoint = LocalToWorld(rightClimbInitialLocalPos, rightClimbInitialLocalAng, rightHandTracker.pos, rightHandTracker.ang)
--                     local movementDelta = rightClimbWorldPos - currentVirtualGrabPoint
--                     currentTargetPlayerPos = currentTargetPlayerPos - movementDelta
--                 end

--                 -- Safety check for extreme distances (e.g. if hand tracking glitches)
--                 if currentTargetPlayerPos:Distance(ply:GetPos()) > 500 then
--                     currentTargetPlayerPos = ply:GetPos() -- Don't move if delta is too large
--                 end

--                 cmd:SetForwardMove(currentTargetPlayerPos.x)
--                 cmd:SetSideMove(currentTargetPlayerPos.y)
--                 cmd:SetUpMove(currentTargetPlayerPos.z)
--             end
--         end
--     )

--     -- Detour existing locomotion if present (like in vrmod_climb.txt)
--     -- This part is highly dependent on the specific locomotion system being used in the full GmodVR setup.
--     -- The original vrmod_climb.txt had specific detours for "vrmod_locomotion".
--     -- We'll replicate the idea, but it might need adjustment for the user's actual vrmod setup.
--     local OldLocoRender, OldLocoMove
--     hook.Add(
--         "Tick",
--         "VRClimb_LocoDetour_Tick",
--         function()
--             if not vrmod.IsPlayerInVR(LocalPlayer()) then
--                 if OldLocoRender then
--                     if hook.GetTable().PreRender and hook.GetTable().PreRender.vrmod_locomotion == VRClimb_LocoDetour_Render then
--                         hook.GetTable().PreRender.vrmod_locomotion = OldLocoRender
--                     end

--                     OldLocoRender = nil
--                 end

--                 if OldLocoMove then
--                     if hook.GetTable().CreateMove and hook.GetTable().CreateMove.vrmod_locomotion == VRClimb_LocoDetour_Move then
--                         hook.GetTable().CreateMove.vrmod_locomotion = OldLocoMove
--                     end

--                     OldLocoMove = nil
--                 end

--                 return
--             end

--             if not OldLocoRender and hook.GetTable().PreRender and hook.GetTable().PreRender.vrmod_locomotion then
--                 OldLocoRender = hook.GetTable().PreRender.vrmod_locomotion
--                 hook.GetTable().PreRender.vrmod_locomotion = VRClimb_LocoDetour_Render
--             end

--             if not OldLocoMove and hook.GetTable().CreateMove and hook.GetTable().CreateMove.vrmod_locomotion then
--                 OldLocoMove = hook.GetTable().CreateMove.vrmod_locomotion
--                 hook.GetTable().CreateMove.vrmod_locomotion = VRClimb_LocoDetour_Move
--             end
--         end
--     )

--     function VRClimb_LocoDetour_Render()
--         if OldLocoRender then
--             OldLocoRender()
--         end

--         -- If climbing and the base locomotion has very low velocity (meaning it's trying to stop player due to no input),
--         -- re-apply the origin update logic from vrmod_climb to counteract it.
--         if (g_VRClimb.isLeftClimbing or g_VRClimb.isRightClimbing) and IsValid(g_VR) and g_VR.originVelocity and g_VR.originVelocity:Length() < 15 then
--             local ply = LocalPlayer()
--             local plyPos = ply:GetPos()
--             -- This part is tricky as g_VR.originVelocity and g_VR.origin might be managed differently
--             -- in the user's full vrmod_locomotion. We'll try to replicate the effect.
--             -- This assumes g_VR.origin is the playspace center.
--             if IsValid(g_VR.tracking.hmd) and IsValid(g_VR.origin) then
--                 local plyTargetPos = g_VR.tracking.hmd.pos + Vector(0, 0, g_VR.tracking.hmd.ang:Forward().z * -10) -- Simplified target
--                 local followVec = Vector((plyTargetPos.x - plyPos.x) * 8, (plyPos.y - plyTargetPos.y) * -8, 0)
--                 local groundEnt = ply:GetGroundEntity()
--                 local groundVel = IsValid(groundEnt) and groundEnt:GetVelocity() or vector_origin
--                 -- Recalculate originVelocity based on current state if needed by base locomotion
--                 -- This might not be perfect without knowing the exact base locomotion internals.
--                 local currentOriginVelocity = ply:GetVelocity() - followVec + groundVel
--                 currentOriginVelocity.z = 0
--                 g_VR.origin = g_VR.origin + currentOriginVelocity * FrameTime()
--                 g_VR.origin.z = plyPos.z
--             end
--         end
--     end

--     function VRClimb_LocoDetour_Move(cmd)
--         -- Call our climb logic first to potentially set climb state and impulse
--         hook.Run("CreateMove", "VRClimb_CreateMove", cmd)
--         -- If not climbing, or if the climbing logic didn't set an impulse (meaning it wants default move),
--         -- then call the original locomotion.
--         if not ply.vrclimb_isClimbing and OldLocoMove then
--             OldLocoMove(cmd)
--         elseif ply.vrclimb_isClimbing then
--         end
--         -- If we are climbing, SetupMove will handle setting the position directly.
--         -- We've already populated cmd with targetPos and CMD_CLIMB_START impulse.
--     end

--     -- Override hand positions when climbing to make them stick to the wall
--     hook.Add(
--         "VRMod_PreRender",
--         "VRClimb_HandStick",
--         function()
--             if not g_VR.active or not IsValid(LocalPlayer()) then return end
--             if g_VRClimb.isLeftClimbing and g_VR.tracking and g_VR.tracking.pose_lefthand then
--                 local currentHandPos = g_VR.tracking.pose_lefthand.pos
--                 local currentHandAng = g_VR.tracking.pose_lefthand.ang
--                 local targetWorldPos, targetWorldAng = LocalToWorld(leftClimbInitialLocalPos, leftClimbInitialLocalAng, leftClimbWorldPos, Angle(0, 0, 0)) -- Simplified angle reference for now
--                 vrmod.SetLeftHandPose(leftClimbWorldPos, currentHandAng) -- Stick position, keep current orientation
--             end

--             if g_VRClimb.isRightClimbing and g_VR.tracking and g_VR.tracking.pose_righthand then
--                 local currentHandPos = g_VR.tracking.pose_righthand.pos
--                 local currentHandAng = g_VR.tracking.pose_righthand.ang
--                 local targetWorldPos, targetWorldAng = LocalToWorld(rightClimbInitialLocalPos, rightClimbInitialLocalAng, rightClimbWorldPos, Angle(0, 0, 0))
--                 vrmod.SetRightHandPose(rightClimbWorldPos, currentHandAng)
--             end
--         end
--     )

--     hook.Add(
--         "VRMod_Exit",
--         "VRClimb_CleanupOnExit",
--         function(ply)
--             if ply == LocalPlayer() then
--                 g_VRClimb.isLeftClimbing = false
--                 g_VRClimb.isRightClimbing = false
--                 if OldLocoRender then
--                     if hook.GetTable().PreRender and hook.GetTable().PreRender.vrmod_locomotion == VRClimb_LocoDetour_Render then
--                         hook.GetTable().PreRender.vrmod_locomotion = OldLocoRender
--                     end

--                     OldLocoRender = nil
--                 end

--                 if OldLocoMove then
--                     if hook.GetTable().CreateMove and hook.GetTable().CreateMove.vrmod_locomotion == VRClimb_LocoDetour_Move then
--                         hook.GetTable().CreateMove.vrmod_locomotion = OldLocoMove
--                     end

--                     OldLocoMove = nil
--                 end

--                 hook.Remove("VRMod_PreRender", "VRClimb_HandStick")
--                 hook.Remove("CreateMove", "VRClimb_CreateMove")
--                 hook.Remove("Tick", "VRClimb_LocoDetour_Tick")
--             end
--         end
--     )

--     print("VRClimb Remake Loaded (Client-Side)")
-- end
-- -- CLIENT