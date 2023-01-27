

AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR"
SWEP.AdminOnly = false
SWEP.UseHands = true

SWEP.Base = "arcticvr_base"

-- SWEP.ViewModel = "models/weapons/arcticvr/aniv/9mmbullet.mdl" -- I mean, you probably have to edit these too
-- SWEP.WorldModel = ""

SWEP.ViewModel = "models/weapons/arcticvr/aniv/9mmbullet.mdl" -- I mean, you probably have to edit these too
SWEP.WorldModel = ""


SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "VR FIST"
SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.DamageMin = 100
SWEP.DamageMax = 100
SWEP.MaxRange = 100
SWEP.Penetration = 1
SWEP.MuzzleVelocity = 14000
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 2
SWEP.Num = 8
SWEP.RPM = 500
SWEP.Recoil = 10
SWEP.RecoilVertical = 5
SWEP.RecoilSide = 2
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 7
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "buckshot"



SWEP.MuzzleEffect = "CS_MuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19"

SWEP.Attachments = {
   {
        Bone = "sight",
        Slot = "pic_sight",
        InstalledBG = {
            ind = 1,
            bg = 1
        },
    },
    {
        Bone = "muzzle",
        Slot = "9mmmuzz",
    },
    {
        Bone = "att",
        Slot = "pist_tac",
    },
    {
        Slot = "ammo_12g",
        Default = "ammo_12g_frag"
    }
}

SWEP.FireSound = "weapons/elite/elite-1.wav"
SWEP.FireSoundSil = "weapons/usp/usp1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.MagInSound = "weapons/elite/elite_leftclipin.wav"
SWEP.MagOutSound = "weapons/elite/elite_clipout.wav"
SWEP.OpenChamberSound = ""
SWEP.CloseChamberSound = ""
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

SWEP.NotAGun = true


SWEP.InternalMagazine = true
SWEP.InternalMagazineCapacity = 1

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_fisttest = {
    offsetPos = Vector(0, 0, 0), --forward, left, up
    offsetAng = Angle(0, 90, 0),
}

-- SWEP.StabilityFrames = 1
-- SWEP.PassiveStabilityFrames = 1
-- SWEP.WeightPenaltyFrames = 0

-- SWEP.NonAutoloading = true
-- SWEP.VolleyFire = true
-- SWEP.VolleyFireAlwaysAdvance = true
-- SWEP.VolleyFireAutoEject = true
-- SWEP.VolleyFireAutoEjectUnspent = false
-- SWEP.VolleyFireAlwaysFromChamberOne = true
-- SWEP.VolleyFireFromOneBarrel = true
-- SWEP.ChamberAtt = "chamber"




SWEP.MagazineInsertMins = Vector(-2, -2, -2)
SWEP.MagazineInsertMaxs = Vector(2, 2, 2)

SWEP.BoneIndices = {
    trigger = 0,
    slide = 0,
    bullet = 0,
    slidelock = 0,
    mag = 0,
    bladeend = 0,
    bladestart = 0,

}

SWEP.FingerAngles = {
	--right hand open angles
	Angle(0,0,0), Angle(0,-40,0), Angle(0,0,0), --finger 0
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 1
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 2
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 3
	Angle(0,30,0), Angle(0,10,0), Angle(0,0,0),
	--right hand closed angles
	Angle(30,0,0), Angle(0,0,0), Angle(0,30,0),
	Angle(0,-50,-10), Angle(0,-90,0), Angle(0,-70,0),
	Angle(0,-35.-8,0), Angle(0,-80,0), Angle(0,-70,0),
	Angle(0,-26.5,4.8), Angle(0,-70,0), Angle(0,-70,0),
	Angle(0,-30,12.7), Angle(0,-70,0), Angle(0,-70,0),
}



SWEP.BulletBones = {
    [1] = "bullet",
}
SWEP.CaseBones = {
    [1] = "case",
}

SWEP.Firemodes = {
    0,
}



end