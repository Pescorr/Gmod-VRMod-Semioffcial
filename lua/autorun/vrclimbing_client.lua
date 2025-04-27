-- -- Client-side climbing functionality for GmodVR

-- -- local vrclimb_enable = CreateClientConVar("vrclimb_enable", 0, true, FCVAR_ARCHIVE, "Enable VR Wall Climbing", 0, 1)
-- local hasPlayerWalked = {}

-- function vrclimb_client()
--     if SERVER then return end
    
--     local vrclimb_ignoreworld = CreateConVar("vrclimb_ignoreworld", 0, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Disables gripping the world to climb", 0, 1)
--     local vrclimb_emptyhanded = CreateConVar("vrclimb_emptyhanded", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "0: Allow climb with any weapons - 1: Left hand only with weapons - 2: Empty handed only", 0, 2)
    
--     lclimb, rclimb = false, false 
--     local lclimbpos, rclimbpos = Vector(), Vector() 
--     local lclimbdir, rclimbdir = Vector(), Vector() 
--     local lclimbang, rclimbang = Angle(), Angle() 
--     local lclimblerp = 0 
--     local rclimblerp = 0 
--     local lclimbdeltaold = Vector() 
--     local rclimbdeltaold = Vector() 
--     local csize = 5 
    
--     local lclimbtr_out = {}
--     local lclimbtr = {
--         start = Vector(),
--         endpos = Vector(),
--         mins = Vector(-csize, -csize, -csize),
--         maxs = Vector(csize, csize, csize),
--         output = lclimbtr_out
--     }
    
--     local rclimbtr_out = {}
--     local rclimbtr = {
--         start = Vector(),
--         endpos = Vector(),
--         mins = Vector(-csize, -csize, -csize),
--         maxs = Vector(csize, csize, csize),
--         output = rclimbtr_out
--     }
    
--     local climbpos = Vector()
--     local lclimbhandpos = Vector()
--     local rclimbhandpos = Vector()
--     local CMD_CLIMBSTART, CMD_CLIMBEND = 164, 165 
--     local upVec = Vector(0, 0, 1)
--     local zeroVec = Vector()
    
--     local function ToggleClimbing(enabled)
--         if enabled then
--             hook.Add(
--                 "VRMod_Input",
--                 "vrclimbgrip",
--                 function(action, state)
--                     if action == "boolean_left_pickup" then
--                         lgrip = state
--                     elseif action == "boolean_right_pickup" then
--                         rgrip = state
--                     end
--                 end
--             )
            
--             hook.Add(
--                 "VRMod_PreRender",
--                 "vrclimbhand",
--                 function()
--                     if lclimb then
--                         lclimbhandpos:Set(vrmod.GetLeftHandPos())
--                         local ang = Angle(lclimbang)
--                         vrmod.SetLeftHandPose(lclimbpos, ang)
--                     end
--                     if rclimb then
--                         rclimbhandpos:Set(vrmod.GetRightHandPos())
--                         local ang = Angle(rclimbang)
--                         vrmod.SetRightHandPose(rclimbpos, ang)
--                     end
--                 end
--             )
--         else
--             hook.Remove("VRMod_Input", "vrclimbgrip")
--             hook.Remove("VRMod_PreRender", "vrclimbhand")
--             lclimb, rclimb = false, false
--         end
--     end
    
--     cvars.AddChangeCallback(
--         "vrclimb_enable",
--         function(convar_name, value_old, value_new)
--             ToggleClimbing(tobool(value_new))
--         end
--     )
    
--     ToggleClimbing(vrclimb_enable:GetBool())
    
--     local function GetClimbSurfacePos(left)
--         return (left and vrmod.GetLeftHandPos()) or vrmod.GetRightHandPos()
--     end
    
--     function CreateMove_VRClimb(cmd)
--         if not vrclimb_enable:GetBool() then return end
        
--         local ply = LocalPlayer()
--         if not vrmod or not vrmod.IsPlayerInVR(ply) then return end
        
--         local cvareh = vrclimb_emptyhanded:GetInt()
        
--         if not lclimb then
--             lclimblerp = math.Approach(lclimblerp, 0, FrameTime())
--         end
        
--         if not rclimb then
--             rclimblerp = math.Approach(rclimblerp, 0, FrameTime())
--         end
        
--         -- Left hand climbing logic
--         if lgrip and not lclimb and (cvareh ~= 2 or vrmod.UsingEmptyHands(ply)) then
--             lclimbtr.start:Set(vrmod.GetLeftHandPos())
--             lclimbtr.endpos:Set(lclimbtr.start)
--             lclimbtr.filter = ply
--             lclimbtr.ignoreworld = vrclimb_ignoreworld:GetBool()
--             util.TraceHull(lclimbtr)
            
--             if lclimbtr_out.Hit then
--                 if lclimbtr_out.HitWorld or (lclimbtr_out.Entity:GetClass() == "prop_physics" and 
--                   (not IsValid(lclimbtr_out.Entity:GetPhysicsObject()) or 
--                    not lclimbtr_out.Entity:GetPhysicsObject():IsMotionEnabled())) then
                    
--                     local spos = GetClimbSurfacePos(true)
--                     lclimbhandpos:Set(spos)
--                     lclimb = true
                    
--                     if vrmod.GetLeftHandVelocity():Length() > 50 then
--                         ply:EmitSound("ConcreteHandStepHard_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.75)
--                     else
--                         ply:EmitSound("ConcreteHandStepSoft_0" .. math.random(1, 4) .. ".wav", 75, 100, 0.5)
--                     end
                    
--                     lclimbdir = lclimbtr_out.HitNormal
--                     lclimbang = vrmod.GetLeftHandAng()
--                     lclimbhandpos:Set(spos)
                    
--                     if not rclimb then
--                         lclimblerp = 1
--                         climbpos:Set(ply:GetPos())
--                     end
                    
--                     lclimbpos:Set(spos)
--                     cmd:SetImpulse(CMD_CLIMBSTART)
--                 end
--             end
--         elseif not lgrip and lclimb then
--             lclimb = false
            
--             if vrmod.GetLeftHandVelocity():Length() > 50 then
--                 ply:EmitSound("ConcreteHandStepFastRelease_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.5)
--             end
            
--             if not rgrip then
--                 local targetpos = -vrmod.GetLeftHandVelocity()
--                 cmd:SetForwardMove(targetpos.x)
--                 cmd:SetSideMove(targetpos.y)
--                 cmd:SetUpMove(targetpos.z)
--                 cmd:SetImpulse(CMD_CLIMBEND)
--                 return true
--             end
--         end
        
--         -- Right hand climbing logic
--         if rgrip and not rclimb and (cvareh == 0 or (cvareh == 1 and vrmod.UsingEmptyHands(ply))) then
--             rclimbtr.start:Set(vrmod.GetRightHandPos())
--             rclimbtr.endpos:Set(rclimbtr.start)
--             rclimbtr.filter = ply
--             rclimbtr.ignoreworld = vrclimb_ignoreworld:GetBool()
--             util.TraceHull(rclimbtr)
            
--             if rclimbtr_out.Hit then
--                 if rclimbtr_out.HitWorld or (rclimbtr_out.Entity:GetClass() == "prop_physics" and 
--                   (not IsValid(rclimbtr_out.Entity:GetPhysicsObject()) or 
--                    not rclimbtr_out.Entity:GetPhysicsObject():IsMotionEnabled())) then
                    
--                     local spos = GetClimbSurfacePos()
--                     rclimbhandpos:Set(spos)
--                     rclimb = true
                    
--                     if vrmod.GetRightHandVelocity():Length() > 50 then
--                         ply:EmitSound("ConcreteHandStepHard_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.75)
--                     else
--                         ply:EmitSound("ConcreteHandStepSoft_0" .. math.random(1, 4) .. ".wav", 75, 100, 0.5)
--                     end
                    
--                     rclimbdir = rclimbtr_out.HitNormal
--                     rclimbang = vrmod.GetRightHandAng()
--                     rclimbhandpos:Set(spos)
                    
--                     if not lclimb then
--                         rclimblerp = 1
--                         climbpos:Set(ply:GetPos())
--                     end
                    
--                     rclimbpos:Set(spos)
--                     cmd:SetImpulse(CMD_CLIMBSTART)
--                 end
--             end
--         elseif not rgrip and rclimb then
--             rclimb = false
            
--             if vrmod.GetRightHandVelocity():Length() > 50 then
--                 ply:EmitSound("ConcreteHandStepFastRelease_0" .. math.random(1, 3) .. ".wav", 75, 100, 0.5)
--             end
            
--             if not lgrip then
--                 local targetpos = -vrmod.GetRightHandVelocity()
--                 cmd:SetForwardMove(targetpos.x)
--                 cmd:SetSideMove(targetpos.y)
--                 cmd:SetUpMove(targetpos.z)
--                 cmd:SetImpulse(CMD_CLIMBEND)
--                 return true
--             end
--         end
        
--         -- Climbing movement while gripping
--         if (lgrip and lclimb) or (rgrip and rclimb) then
--             cmd:SetImpulse(CMD_CLIMBSTART)
            
--             local plyTargetPos = g_VR.tracking.hmd.pos + upVec:Cross(g_VR.tracking.hmd.ang:Right()) * -10
--             local eyeang = EyeAngles()
--             eyeang.x = 0
--             local pos = EyePos() - Vector(0, 0, 64)
            
--             local lclimbdelta = LocalToWorld(lclimbpos - lclimbhandpos, angle_zero, lclimbpos - lclimbhandpos, lclimbdir:Angle())
--             local rclimbdelta = LocalToWorld(rclimbpos - rclimbhandpos, angle_zero, rclimbpos - rclimbhandpos, rclimbdir:Angle())
            
--             local targetpos = Vector(pos)
            
--             if lclimb or lclimblerp > 0 then
--                 if not lclimb then
--                     lclimbdelta:Set(lclimbdeltaold)
--                 else
--                     lclimbdeltaold:Set(lclimbdelta)
--                 end
                
--                 lclimblerp = math.Approach(lclimblerp, 1, FrameTime() * 0.5)
                
--                 if rclimb or rclimblerp > 0 then
--                     lclimbdelta:Mul(Lerp(rclimblerp, 1, 0.5))
--                 end
                
--                 targetpos:Add(LerpVector(lclimblerp, vector_origin, lclimbdelta))
--             end
            
--             if rclimb or rclimblerp > 0 then
--                 if not rclimb then
--                     rclimbdelta:Set(rclimbdeltaold)
--                 else
--                     rclimbdeltaold:Set(rclimbdelta)
--                 end
                
--                 rclimblerp = math.Approach(rclimblerp, 1, FrameTime() * 0.5)
                
--                 if lclimb or lclimblerp > 0 then
--                     rclimbdelta:Mul(Lerp(lclimblerp, 1, 0.5))
--                 end
                
--                 targetpos:Add(LerpVector(rclimblerp, vector_origin, rclimbdelta))
--             end
            
--             local plypos = ply:GetPos()
            
--             if targetpos:Distance(plypos) > 500 then
--                 targetpos:Set(plypos)
--             end
            
--             cmd:SetForwardMove(targetpos.x)
--             cmd:SetSideMove(targetpos.y)
--             cmd:SetUpMove(targetpos.z)
--         end
--     end
    
--     local function loco_detour()
--         local oldlocorender = OldLocoRender
--         if not oldlocorender then return end
        
--         oldlocorender()
        
--         if (lclimb or rclimb) and originVelocity:Length() < 15 then
--             local ply = LocalPlayer()
--             local plyPos = ply:GetPos()
--             local plyTargetPos = g_VR.tracking.hmd.pos + upVec:Cross(g_VR.tracking.hmd.ang:Right()) * -10
--             local followVec = (ply:GetMoveType() == MOVETYPE_NOCLIP) and zeroVec or Vector((plyTargetPos.x - plyPos.x) * 8, (plyPos.y - plyTargetPos.y) * -8, 0)
            
--             local groundEnt = ply:GetGroundEntity()
--             local groundVel = IsValid(groundEnt) and groundEnt:GetVelocity() or zeroVec
            
--             originVelocity = ply:GetVelocity() - followVec + groundVel
--             originVelocity.z = 0
            
--             g_VR.origin = g_VR.origin + originVelocity * FrameTime()
--             g_VR.origin.z = plyPos.z
--         end
--     end
    
--     local function locomove_detour(cmd)
--         OldLocoMove(cmd)
--         CreateMove_VRClimb(cmd)
--     end
    
--     hook.Add(
--         "Tick",
--         "vrclimb_locodetour",
--         function()
--             if not hook.GetTable().PreRender then return end
--             if not vrmod.IsPlayerInVR(LocalPlayer()) and not hook.GetTable().PreRender.vrmod_locomotion then
--                 OldLocoRender = nil
--                 return
--             end
            
--             if OldLocoRender then return end
            
--             OldLocoRender = hook.GetTable().PreRender.vrmod_locomotion
--             hook.GetTable().PreRender.vrmod_locomotion = loco_detour
--         end
--     )
    
--     hook.Add(
--         "Tick",
--         "vrclimb_cmdetour",
--         function()
--             if not hook.GetTable().CreateMove then return end
--             if not vrmod.IsPlayerInVR(LocalPlayer()) and not hook.GetTable().CreateMove.vrmod_locomotion then
--                 OldLocoMove = nil
--                 return
--             end
            
--             if OldLocoMove then return end
            
--             OldLocoMove = hook.GetTable().CreateMove.vrmod_locomotion
--             hook.GetTable().CreateMove.vrmod_locomotion = locomove_detour
--         end
--     )
    
--     hook.Add(
--         "VRMod_PreRender",
--         "vrclimbhand",
--         function()
--             if lclimb then
--                 lclimbhandpos:Set(vrmod.GetLeftHandPos())
--                 local ang = Angle(lclimbang)
--                 vrmod.SetLeftHandPose(lclimbpos, ang)
--             end
            
--             if rclimb then
--                 rclimbhandpos:Set(vrmod.GetRightHandPos())
--                 local ang = Angle(rclimbang)
--                 vrmod.SetRightHandPose(rclimbpos, ang)
--             end
--         end
--     )
-- end

-- vrclimb_client()

-- hook.Add(
--     "VRMod_Start",
--     "vrclimb_start",
--     function(ply)
--         if ply ~= LocalPlayer() then return end
--         vrclimb_client()
--     end
-- )

-- concommand.Add(
--     "vrclimb_lua_reset_cl",
--     function(ply, cmd, args)
--         vrclimb_client()
--     end
-- )
