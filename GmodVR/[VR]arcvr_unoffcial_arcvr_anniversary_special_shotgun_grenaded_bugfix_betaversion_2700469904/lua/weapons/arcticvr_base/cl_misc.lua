local cv_lefthandmax_mode = CreateClientConVar("arcticvr_test_cl_misc_fix","1",FCVAR_ARCHIVE)


function SWEP:VRDeploy()
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    vm:SetupBones()
    vm:SetSubMaterial()

    local tmp = self.FingerAngles

    for i = 1,15 do
        g_VR.openHandAngles[15 + i] = tmp[i]
        g_VR.closedHandAngles[15 + i] = tmp[15 + i]
    end

    tmp = self.LeftHandFingerAngles

    for i = 1,15 do
        g_VR.openHandAngles[i] = tmp[i]
        g_VR.closedHandAngles[i] = tmp[15 + i]
    end

    SafeRemoveEntity(ArcticVR.CSMagazine)
    SafeRemoveEntity(ArcticVR.SightPiece)

    self:CleanAttModels()

    self:RebuildAttModels()

    self.ForegripGrabbed = false

    if self.Magazine != nil then
        local mag = ArcticVR.MagazineTable[self.Magazine]

        if !mag.Model then return end

        ArcticVR.CSMagazine = ClientsideModel(mag.Model)
        ArcticVR.CSMagazine:SetParent(vm)
        ArcticVR.CSMagazine:AddEffects(EF_BONEMERGE)
    end

    for i, k in pairs(self.BoneIndices) do
        if !self.MiscLerps[k] then
            self.MiscLerps[k] = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
        end
    end

    if self.HolosightReticle then
        self.HolosightReticle:SetInt("ignorez", 1)
    end

    for i = 1, self.InternalMagazineCapacity do
        if self.VolleyFireChambers[i] then continue end
        self.VolleyFireChambers[i] = 0
    end

    if !self.ClientInitialized then
        self:Initialize()
    end
end

 function SWEP:VRHolster()
     SafeRemoveEntity(ArcticVR.CSMagazine)
     SafeRemoveEntity(ArcticVR.SightPiece)

     self:CleanAttModels()
end

function SWEP:UngripForegrip()
    self.ForegripGrabbed = false

    tmp = self.LeftHandFingerAngles

    for i = 1,15 do
        g_VR.openHandAngles[i] = tmp[i]
        g_VR.closedHandAngles[i] = tmp[15 + i]
    end
end

function SWEP:GripForegrip()
    self.ForegripGrabbed = true
    self.SlideGrabOffset = self.ForegripOffset[1]
    ArcticVR.StabilityFrames = {}
    ArcticVR.StabilityFrameIndex = 1

    if self.ForegripOnPivot then
        self:CloseChambers()
    end

    tmp = self.LeftHandFingerAngles

    for i = 1,15 do
        g_VR.openHandAngles[i] = tmp[15 + i]
        g_VR.closedHandAngles[i] = tmp[15 + i]
    end
end

function SWEP:LeftHandInMaxs(bone, mins, maxs)
	local boneMatrix
    local vm = g_VR.viewModel

	if cv_lefthandmax_mode:GetBool() then

		if !vm then return end
		if !IsValid(vm) then return end
		if vm:GetBoneMatrix(bone) == nil then return end
		-- vm:WorldToLocal(vm:GetBonePosition(bone), Angle(0, 0, 0))

		local tl = Vector(3.5,-1.5,1.2)

		-- Vector(3.5,-1.5,1.2)
		
		-- --Anniversary zone
		local boneMatrix = vm:GetBoneMatrix(bone)
		if (!boneMatrix) then
			return false
		end
		-- --Anniversary zone

		local pos = WorldToLocal(LocalToWorld(tl, Angle(0,0,0), g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang), Angle(0,0,0),
			boneMatrix:GetTranslation(),
			boneMatrix:GetAngles()
		)
		if pos.x > mins[1] and pos.x < maxs[1] and pos.y > mins[2] and pos.y < maxs[2] and pos.z > mins[3] and pos.z < maxs[3] then
			return true
		end

		return false	
	else
	    if !vm then return end
		if !IsValid(vm) then return end
		local tl = Vector(3.5,-1.5,1.2)


		local pos = WorldToLocal(LocalToWorld(tl, Angle(0,0,0), g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang), Angle(0,0,0),
			vm:GetBoneMatrix(bone):GetTranslation(),
			vm:GetBoneMatrix(bone):GetAngles()
		)
		if pos.x > mins[1] and pos.x < maxs[1] and pos.y > mins[2] and pos.y < maxs[2] and pos.z > mins[3] and pos.z < maxs[3] then
			return true
		end

		return false
	end
end
	
function SWEP:PositionInMaxs(pos, poss, mins, maxs)
    mins = mins + poss
    maxs = maxs + poss
    if pos.x > mins[1] and pos.x < maxs[1] and pos.y > mins[2] and pos.y < maxs[2] and pos.z > mins[3] and pos.z < maxs[3] then
        return true
    end

    return false
end

function SWEP:FiremodeSwitch()
    if self.SpecialFiremodeSwitch then
        self:SpecialFiremodeSwitch()
        return
    end
    local vm = g_VR.viewModel

    if !vm then return end
    if !IsValid(vm) then return end

    if table.Count(self.Firemodes) == 1 then return end

    self:PlayNetworkedSound(nil, "SwitchModeSound")

    local fmindex = table.KeyFromValue(self.Firemodes, self.Firemode) or 0

    fmindex = fmindex + 1

    if fmindex > #self.Firemodes then
        fmindex = 1
    end

    self.Firemode = self.Firemodes[fmindex]
end

function SWEP:BoneTap(bone, offset, time)
    self.TargetMiscLerps[bone] = offset
    self.BoneTaps[bone] = CurTime() + time
end

function SWEP:MinimumVel(target)
    local vm = g_VR.viewModel
    local vel = g_VR.tracking.pose_righthand.vel/25

    vel = WorldToLocal(vel, Angle(0, 0, 0), Vector(0, 0, 0), vm:GetAngles())

    local ok = true

    if target[1] > 0 then
        if vel[1] < target[1] then
            ok = false
        end
    elseif target[1] < 0 then
        if vel[1] > target[1] then
            ok = false
        end
    end

    if target[2] > 0 then
        if vel[2] < target[2] then
            ok = false
        end
    elseif target[2] < 0 then
        if vel[2] > target[2] then
            ok = false
        end
    end

    if target[3] > 0 then
        if vel[3] < target[3] then
            ok = false
        end
    elseif target[3] < 0 then
        if vel[3] > target[3] then
            ok = false
        end
    end

    return ok
end

function SWEP:EjectEmptyChambered()
    local vm = g_VR.viewModel

    if self.EmptyChambered > 0 then
        if self.CaseEffect then
            local fx2 = EffectData()
            fx2:SetAttachment(2)
            fx2:SetMagnitude(150)
            fx2:SetNormal(Vector(0, 0, 0))
            fx2:SetEntity(vm)
            util.Effect(self.CaseEffect, fx2)
        end

        self.EmptyChambered = self.EmptyChambered - 1
    end
end