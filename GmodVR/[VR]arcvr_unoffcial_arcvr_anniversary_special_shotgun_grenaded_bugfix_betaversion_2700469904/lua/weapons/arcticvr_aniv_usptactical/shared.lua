AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR - Aniversary"
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.Base = "arcticvr_base"

SWEP.ViewModel = "models/weapons/arcticvr/aniv/pistol_usp.mdl"
SWEP.WorldModel = "models/weapons/w_pist_usp_silencer.mdl"


SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 1000
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "VR USP Tactical"
SWEP.Slot = 1
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Chambered = 0
SWEP.LoadedRounds = 0
SWEP.Magazine = nil

SWEP.DamageMin = 20
SWEP.DamageMax = 22
SWEP.MaxRange = 6500
SWEP.Penetration = 5
SWEP.MuzzleVelocity = 1500
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 4
SWEP.RPM = 400
SWEP.Firemode = 1
SWEP.Recoil = 0.8
SWEP.RecoilVertical = 7
SWEP.RecoilSide = 1.5
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 175
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "pistol"

SWEP.MagType = "usp"
SWEP.DefaultMagazine = "usp_12_aniv"

SWEP.MuzzleEffect = "AirboatMuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19"
SWEP.BulletEffect = "arcticvr_bullet_9x19"

SWEP.NextPrimaryFire = 0

SWEP.FireSound = "weapons/usp/usp1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/usp/usp_slideback2.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/p228_slideforward.wav"
SWEP.SlideReleaseSound = "weapons/usp/usp_sliderelease.wav"
SWEP.MagInSound = "weapons/usp/usp_clipin.wav"
SWEP.MagOutSound = "weapons/usp/usp_clipout.wav"
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_aniv_usptactical = {
    offsetPos = Vector(-4.9, -4, 1.3), --forward, left, up
    offsetAng = Angle(10, 0, 0),
}

SWEP.TriggerPulledOffset = { -- the offset of the trigger bone when it is fully pulled.
    pos = Vector(0, 0, -0),
    ang = Angle(0, 0, 15)
}

SWEP.CanLockBack = true
SWEP.MagCanDropFree = true
SWEP.BoltCanAutoRelease = true
SWEP.PistolStabilize = false	
SWEP.ReverseForegrip = false

SWEP.TwoHanded = true

SWEP.RecoilTwoHandMult = 0.01

SWEP.ForegripAngle = Angle(0, -0, 0)
SWEP.ForegripOffset = Vector(0, -3, 0)

SWEP.ForegripMins = Vector(-7, -4, -2)
SWEP.ForegripMaxs = Vector(5, 4, 6)

SWEP.SlideMins = Vector(-3, -0.6, -3.6)
SWEP.SlideMaxs = Vector(3, 4, 7)

SWEP.MagazineInsertMins = Vector(-2, -2, -3)
SWEP.MagazineInsertMaxs = Vector(2, 1, 4)

SWEP.MagazineOffset = Vector(-0.5, 0, -5)
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideDir = Vector(0, 0, -1)

SWEP.FullBackOffset = {
    hammer = {
        pos = Vector(0, -0, 0),
        ang = Angle(0, 0, 0)
    }
}


SWEP.FingerAngles = {
    --right hand open angles
    Angle(-0,-7,-5), Angle(0,40,0), Angle(0,10,0), --finger 0
    Angle(-5,35,10), Angle(0,5,0), Angle(0,-7.9,0), --finger 1   This is the index finger, off the trigger
    Angle(-10,10.6,0), Angle(0,-60,0), Angle(0,-47,0), --finger 2
    Angle(-10,0.8,0), Angle(0,-50,0), Angle(0, -50.1,0), --finger 3
    Angle(-10,0.3,-8.2), Angle(0,-50,0), Angle(0,-30.5,0), --finger 4
    --right hand closed angles
    Angle(-5,-7,-5), Angle(0,40,0), Angle(0,10,0), --finger 0
    Angle(-5,35,17), Angle(0,-5,0), Angle(0,-25.9,0), --finger 1   This is the index finger, on the trigger
    Angle(-10,10.6,0), Angle(0,-60,0), Angle(0,-47,0), --finger 2
    Angle(-10,0.8,0), Angle(0,-50,0), Angle(0, -50.1,0), --finger 3
    Angle(-10,0.3,-8.2), Angle(0,-50,0), Angle(0,-30.5,0), --finger 4
}

SWEP.LeftHandFingerAngles = {
    -- open
    Angle(0,0,0), Angle(0,-40,0), Angle(0,0,0), --finger 0
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 1
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 2
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 3
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0),
    -- closed
    Angle(0,0,0), Angle(0,0,0), Angle(0,30,0),
    Angle(0,-5,-10), Angle(0,-30,0), Angle(0,-20,0),
    Angle(0,5.-8,0), Angle(0,-30,0), Angle(0,-10,0),
    Angle(0,10.5,4.8), Angle(0,-30,0), Angle(0,-10,0),
    Angle(0,15,12.7), Angle(0,-30,0), Angle(0,-10,0),
}

SWEP.BurstLength = 0
SWEP.SlideGrabbed = false
SWEP.SlideReleasing = false
SWEP.SlidePos = 0
SWEP.SlideLockedBack = false
SWEP.NeedAnotherTriggerPull = false
SWEP.OpenBolt = false
SWEP.LastSlidePos = 0
SWEP.Firemode = 1 -- 0 = safe, 1 = semi, 2 = auto, negative = burst
SWEP.RecoilAngles = Angle(0, 0, 0)
SWEP.RecoilBlowback = 0

SWEP.SlideLockbackAmount = 1.9
SWEP.SlideBlowbackAmount = 2

SWEP.BulletBones = {
    [1] = "bullet"
}

SWEP.BoneIndices = {
 pistol = 0,
 magazine = 1,
 trigger = 2,
 slide = 3,
 bullet = 4,
 selector = 5,
 muzzle = 6,
 eject = 7,
 slidelock = 8,
 foregrip = 9,
 hammer = 10,
}



SWEP.MiscLerps = {
}

SWEP.TargetMiscLerps = {
}

SWEP.SlidelockActivePose = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 10)
}

SWEP.FireSelectPoses = {
    [0] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, -30)}
    },
    [1] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
    }
}

SWEP.Firemodes = {
    1,
    0
}

end