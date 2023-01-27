AddCSLuaFile()

SWEP.Spawnable = false
SWEP.Spawnable = false -- this obviously has to be set to true
SWEP.Category = "Arctic VR" -- edit this if you like
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.ViewModel = "models/weapons/arcticvr/nade_frag.mdl" -- I mean, you probably have to edit these too
SWEP.WorldModel = "models/weapons/w_eq_hegrenade.mdl"

SWEP.ArcticVR = false
SWEP.ArcticVRNade = true -- always keep this true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 1000 -- edit this part just to tell other stuff about the gun. ArcVR doesn't use this data.
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "grenade"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- auto switch crap. Edit if you like.
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "VR Grenade Base" -- you should probably change this
SWEP.Slot = 5 -- you could edit these if you like
SWEP.SlotPos = 1

SWEP.DrawAmmo = false -- irrelevant
SWEP.DrawCrosshair = false

SWEP.ViewModelFOV = 90 -- ALWAYS set to 90

SWEP.ShootEntity = nil -- set to thrown grenade entity
SWEP.PinModel = nil -- set to released pin
SWEP.SpoonModel = nil -- set to released spoon

SWEP.ThrowSpeedMult = 100

SWEP.NetworkedSounds = {
	"ThrowSound",
	"PinOutSound",
	"SpoonOffSound",
	"PinGrabbedSound"
}

SWEP.ThrowSound = ""
SWEP.PinOutSound = "weapons/arcticvr/pinpull.wav"
SWEP.SpoonOffSound = ""
SWEP.PinGrabbedSound = ""

SWEP.SpoonUpOffset = {
	pos = Vector(0, 0, 0),
	ang = Angle(0, 0, 0)
}

SWEP.PinBodygroup = 1
SWEP.SpoonBodygroup = 2

SWEP.PinMins = Vector(-3, -3, -3)
SWEP.PinMaxs = Vector(3, 3, 3)

SWEP.PinDirIn = 1
SWEP.PinDirReverse = false
SWEP.PinDirVec = Vector(0, 0, -1)
SWEP.PinOutAmount = 1

SWEP.BoneIndices = {}

SWEP.FingerAngles = {
	--right hand open angles
	Angle(-25,-6.9,-20.1), Angle(0,0,0), Angle(0,60,0), --finger 0
	Angle(10,25,15), Angle(0,-50,0), Angle(0,-47.9,0), --finger 1
	Angle(0,-33.6,0), Angle(0,-60,0), Angle(0,-27,0), --finger 2
	Angle(0,-35.8,0), Angle(0,-40.6,0), Angle(0,-45.1,0), --finger 3
	Angle(0,-32.3,-8.2), Angle(0,-34.4,0), Angle(0,-22.5,0), --finger 4
	--right hand closed angles
	Angle(-25,-6.9,-20.1), Angle(0,0,0), Angle(0,60,0), --finger 0
	Angle(10,0,15), Angle(0,-50,0), Angle(0,-47.9,0), --finger 1
	Angle(0,-33.6,0), Angle(0,-60,0), Angle(0,-27,0), --finger 2
	Angle(0,-35.8,0), Angle(0,-40.6,0), Angle(0,-45.1,0), --finger 3
	Angle(0,-32.3,-8.2), Angle(0,-34.4,0), Angle(0,-22.5,0), --finger 4
}

SWEP.LeftHandFingerAngles = {
	-- open
	Angle(0,0,0), Angle(0,-40,0), Angle(0,0,0), --finger 0
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 1
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 2
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 3
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0),
	-- closed
	Angle(30,0,0), Angle(0,0,0), Angle(0,30,0),
	Angle(0,-50,-10), Angle(0,-90,0), Angle(0,-70,0),
	Angle(0,-35.-8,0), Angle(0,-80,0), Angle(0,-70,0),
	Angle(0,-26.5,4.8), Angle(0,-70,0), Angle(0,-70,0),
	Angle(0,-30,12.7), Angle(0,-70,0), Angle(0,-70,0),
}

if CLIENT then

SWEP.GrenadeGrabbed = false
SWEP.SpoonReleaseAmount = 0
SWEP.SpoonReleased = false
SWEP.PinPulledAmount = 0
SWEP.PinOut = false
SWEP.PinGrabbed = false
SWEP.PinOffset = 0

SWEP.NextNadeTime = 0

function SWEP:VRInput(action, state)
	local vm = g_VR.viewModel
	local cv_pinsys = CreateClientConVar("arcticvr_grenade_pin_enable","1")


	if cv_pinsys:GetBool() then
		if g_VR.input.boolean_primaryfire then
			local ammo = LocalPlayer():GetAmmoCount(self.Primary.Ammo)
			if !self.GrenadeGrabbed and self.NextNadeTime <= CurTime() and ammo > 0 then
				self.GrenadeGrabbed = true
			end
		elseif !g_VR.input.boolean_primaryfire then
			if self.GrenadeGrabbed and self.PinOut or self.GrenadeGrabbed and self.PinModel == "" then
				self:ReleaseGrenade()
				self.GrenadeGrabbed = false
				self.PinGrabbed = false
				self.PinOffset = 0
				self.PinOut = false
				self.SpoonReleased = false
				self.NextNadeTime = CurTime() + 1
			else
				self.GrenadeGrabbed = false
				self.PinGrabbed = false
			end
		end

		if !vm then return end
		if !IsValid(vm) then return end

		if self.GrenadeGrabbed and self.BoneIndices.pin then
			if action == "boolean_left_pickup" and state then
				self.PinGrabbed = true
				self.PinOffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos)[self.PinDirIn]
				return
				else
				self.PinGrabbed = false
				return
			end
		end
	else
		if g_VR.input.boolean_primaryfire then
			local ammo = LocalPlayer():GetAmmoCount(self.Primary.Ammo)
			if !self.GrenadeGrabbed and self.NextNadeTime <= CurTime() and ammo > 0 then
				self.GrenadeGrabbed = true
			end
		elseif !g_VR.input.boolean_primaryfire then
			if self.GrenadeGrabbed and !g_VR.input.boolean_right_pickup or self.GrenadeGrabbed and VR.input.boolean_reload then
				self:ReleaseGrenade()
				self.GrenadeGrabbed = false
				self.PinGrabbed = false
				self.PinOffset = 0
				self.PinOut = false
				self.SpoonReleased = false
				self.NextNadeTime = CurTime() + 1
			else
				self.GrenadeGrabbed = false
				self.PinGrabbed = false
			end
		end

		if !vm then return end
		if !IsValid(vm) then return end

		if self.GrenadeGrabbed and self.BoneIndices.pin then
			if g_VR.input.boolean_left_pickup and self:LeftHandInMaxs(self.BoneIndices.pin, self.PinMins, self.PinMaxs) then
				self.PinGrabbed = true
				self.PinOffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos)[self.PinDirIn]
				return
			elseif !g_VR.input.boolean_left_pickup then
				self.PinGrabbed = false
				return
			end
		end


	end
	end

function SWEP:VRDeploy()
	self.OGViewModel = self.ViewModel
	self.ViewModel = ""

	local vm = g_VR.viewModel

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
end

function SWEP:VRHolster()
	self.ViewModel = self.OGViewModel
end

function SWEP:VRThink()
	local vm = g_VR.viewModel

	if !vm then return end
	if !IsValid(vm) then return end

	local vec1 = Vector(1, 1, 1)
	local vec0 = vec1 * 0

	local vecv = vec0

	if self.GrenadeGrabbed then
		vecv = vec1
	end

	for i = 0, vm:GetBoneCount() do
		vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
		vm:ManipulateBoneScale(i, vecv)
	end

	if !self.PinOut and self.PinGrabbed then
		local coffset = vm:WorldToLocal(g_VR.tracking.pose_lefthand.pos)[self.PinDirIn]
		local pullback = self.PinOffset - coffset

		if self.PinDirReverse then
			pullback = -pullback
		end

		pullback = math.Clamp(pullback, 0, self.PinOutAmount)

		vm:ManipulateBonePosition(self.BoneIndices.pin, self.PinDirVec * pullback)

		if pullback >= self.PinOutAmount then
			self.PinOut = true
			self:PlayNetworkedSound(nil, "PinOutSound")
		end
	end

	if self.PinOut then
		vm:ManipulateBoneScale(self.BoneIndices.pin, vec0)
	end
end

function SWEP:LeftHandInMaxs(bone, mins, maxs)
	local vm = g_VR.viewModel

	if !vm then return end
	if !IsValid(vm) then return end

	-- vm:WorldToLocal(vm:GetBonePosition(bone), Angle(0, 0, 0))

	local pos = WorldToLocal(LocalToWorld(Vector(3.5,-1.5,1.2), Angle(0,0,0), g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang), Angle(0,0,0),
		vm:GetBoneMatrix(bone):GetTranslation(),
		vm:GetBoneMatrix(bone):GetAngles()
	)
	if pos.x > mins[1] and pos.x < maxs[1] and pos.y > mins[2] and pos.y < maxs[2] and pos.z > mins[3] and pos.z < maxs[3] then
		return true
	end

	return false
end

function SWEP:ReleaseGrenade()
	local ammo = LocalPlayer():GetAmmoCount(self.Primary.Ammo)

	if ammo <= 0 then return end

	local src = g_VR.tracking.pose_righthand.pos
	local vel = g_VR.tracking.pose_righthand.vel / 25
	local ang = g_VR.tracking.pose_righthand.ang
	local angvel = g_VR.tracking.pose_righthand.angvel / 25

	net.Start("avr_nadethrow")
	net.WriteFloat(src[1])
	net.WriteFloat(src[2])
	net.WriteFloat(src[3])
	net.WriteVector(vel)
	net.WriteAngle(ang)
	net.WriteAngle(angvel:Angle())
	net.SendToServer()

	self.GrenadeGrabbed = false
end

else

-- SERVER

function SWEP:VR_PreThrow() --arguments: src, ang, vel, angvel, rocket
end

function SWEP:VR_Throw(src, ang, vel, angvel)
	local owner = self:GetOwner()
	local rocket = ents.Create(self.ShootEntity)

	if !rocket:IsValid() then print("!!! INVALID ROUND " .. self.ShootEntity) return false end

	rocket.ExtraProjectileData = self.ExtraProjectileData or {}
	rocket:SetAngles(ang)
	rocket:SetPos(src)
	rocket:SetOwner(owner)
	rocket:Spawn()
	rocket:Activate()
	constraint.NoCollide(owner, rocket, 0, 0)
	rocket:GetPhysicsObject():SetVelocity(vel * self.ThrowSpeedMult)
	rocket:SetLocalAngularVelocity(angvel)

	self:VR_PreThrow(src, ang, vel, angvel, rocket)

	if self.SpoonModel then
		-- local spoon = ents.Create( "prop_physics" )

		-- spoon:SetAngles(ang)
		-- spoon:SetPos(src)
		-- spoon:SetModel(self.SpoonModel)
		-- spoon:Spawn()
		-- spoon:Activate()
		-- spoon:SetLocalAngularVelocity(angvel)
		-- spoon:GetPhysicsObject():SetDragCoefficient(10)
		-- spoon:GetPhysicsObject():SetVelocity((vel * self.ThrowSpeedMult) + (ang:Right() * -100))

		-- timer.Simple(5, function()
			-- SafeRemoveEntity(spoon)
		-- end)
	end

	self:TakePrimaryAmmo(1)
end

end

-- SHARED

function SWEP:PlayNetworkedSound(sindex, soundn)
	sindex = sindex or table.KeyFromValue(self.NetworkedSounds, soundn)

	if sindex then
		local vol = 75
		local chan = CHAN_AUTO

		if sindex == 1 then
			vol = self.ShotVolume
			chan = CHAN_WEAPON
		end

		local sname = self.NetworkedSounds[sindex]
		local spath = self[sname]

		if CLIENT then
			local vm = g_VR.viewModel
			vm:EmitSound(spath, vol, 100, 1, chan)

			net.Start("avr_playsound")
			net.WriteUInt(sindex, 8)
			net.SendToServer()
		else
			SuppressHostEvents(self:GetOwner())
			self:EmitSound(spath, vol, 100, 1, chan)
			SuppressHostEvents(NULL)
		end
	end
end

function SWEP:PrimaryAttack()
	return
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:Reload()
	return
end