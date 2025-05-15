-- --------[sh_vrclimb.lua]Start--------
local CMD_CLIMBSTART, CMD_CLIMBEND = 164, 165
local vrclimb_ignoreworld = CreateConVar("vrclimb_ignoreworld", "0", { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Disables gripping the world to climb", 0, 1)

hook.Add("SetupMove", "vrclimb", function(ply, mv, cmd)
	if cmd:GetImpulse() == CMD_CLIMBSTART then
		ply.vrclimb = true
	elseif ply.vrclimb and (cmd:GetImpulse() == CMD_CLIMBEND or not ply:Alive() or mv:GetOrigin():Distance(Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())) > 400) then
		ply.vrclimb = false
		mv:SetVelocity(Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove()) * 2)
		return true
	end

	if ply.vrclimb or (CLIENT and (lclimb or rclimb)) then -- Ensure lclimb and rclimb are accessible if this part is ever reached on client in this shared script
		local targetpos = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
		mv:SetVelocity(vector_origin)
		cmd:ClearMovement()
		mv:SetUpSpeed(0)
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		mv:SetOrigin(targetpos)
		return true
	end
end)
-- --------[sh_vrclimb.lua]End--------