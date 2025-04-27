-- -- Shared climbing functionality for GmodVR

-- function vrclimb_share()
--     local vrclimb_enable = CreateClientConVar("vrclimb_enable", 0, true, FCVAR_ARCHIVE, "Enable VR Wall Climbing", 0, 1)
--     local CMD_CLIMBSTART, CMD_CLIMBEND = 164, 165
--     local vrclimb_ignoreworld = CreateConVar("vrclimb_ignoreworld", 0, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Disables gripping the world to climb", 0, 1)
    
--     local function ToggleClimbing(enabled)
--         if enabled then
--             hook.Add(
--                 "SetupMove",
--                 "vrclimb",
--                 function(ply, mv, cmd)
--                     if cmd:GetImpulse() == CMD_CLIMBSTART then
--                         ply.vrclimb = true
--                     elseif ply.vrclimb and (cmd:GetImpulse() == CMD_CLIMBEND or not ply:Alive() or mv:GetOrigin():Distance(Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())) > 400) then
--                         ply.vrclimb = false
--                         mv:SetVelocity(Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove()) * 2)
--                         return true
--                     end
                    
--                     if ply.vrclimb or (CLIENT and (lclimb or rclimb)) then
--                         local targetpos = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
--                         mv:SetVelocity(vector_origin)
--                         cmd:ClearMovement()
--                         mv:SetUpSpeed(0)
--                         mv:SetForwardSpeed(0)
--                         mv:SetSideSpeed(0)
--                         mv:SetOrigin(targetpos)
--                         return true
--                     end
--                 end
--             )
--         else
--             hook.Remove("SetupMove", "vrclimb")
--         end
--     end
    
--     cvars.AddChangeCallback(
--         "vrclimb_enable",
--         function(convar_name, value_old, value_new)
--             ToggleClimbing(tobool(value_new))
--         end, 
--         "vrclimb_toggle"
--     )
    
--     ToggleClimbing(vrclimb_enable:GetBool())
-- end

-- vrclimb_share()

-- concommand.Add(
--     "vrclimb_lua_reset_sh",
--     function(ply, cmd, args)
--         vrclimb_share()
--     end
-- )
