AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR - Aniversary"
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.Base = "arcticvr_base"

SWEP.ViewModel = "models/weapons/arcticvr/aniv/smg_tmp.mdl"
SWEP.WorldModel = "models/weapons/w_smg_tmp.mdl"


SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 30
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

SWEP.PrintName = "VR Steyr TMP"
SWEP.Slot = 2
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Chambered = 0
SWEP.LoadedRounds = 0
SWEP.Magazine = nil

SWEP.DamageMin = 10
SWEP.DamageMax = 20
SWEP.MaxRange = 3000
SWEP.Penetration = 6
SWEP.MuzzleVelocity = 200000
SWEP.ShotVolume = 100
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 4
SWEP.RPM = 900
SWEP.Firemode = 2
SWEP.Recoil = 0.85
SWEP.RecoilVertical = 3
SWEP.RecoilSide = 1.5
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 125
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "pistol"

SWEP.MagType = "tmp"
SWEP.DefaultMagazine = "tmp_30_aniv"

SWEP.MuzzleEffect = "AirboatMuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19_alt"
SWEP.BulletEffect = "arcticvr_bullet_9x19"

SWEP.NextPrimaryFire = 0

SWEP.FireSound = "weapons/tmp/tmp-1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/arcticvr/mp5_slideback.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/mp5_slideforward.wav"
SWEP.SlideReleaseSound = "weapons/usp/usp_sliderelease.wav"
SWEP.MagInSound = "weapons/tmp/tmp_clipin.wav"
SWEP.MagOutSound = "weapons/tmp/tmp_clipout.wav"
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_aniv_tmp = {
    offsetPos = Vector(-4.9, -4, 3.7), --forward, left, up
    offsetAng = Angle(10, 0, 0),
}

SWEP.TriggerPulledOffset = { -- the offset of the trigger bone when it is fully pulled.
    pos = Vector(0, 0, -0),
    ang = Angle(0, 0, 15)
}

SWEP.NonReciprocatingChargingHandle = true
SWEP.CanLockBack = true
SWEP.MagCanDropFree = true
SWEP.BoltCanAutoRelease = true
SWEP.PistolStabilize = false	
SWEP.ReverseForegrip = false

SWEP.TwoHanded = true

SWEP.RecoilTwoHandMult = 0.01

SWEP.ForegripAngle = Angle(-10, -30, 0)
SWEP.ForegripOffset = Vector(7.5, -4, -1)

SWEP.ForegripMins = Vector(-4, -6, -4)
SWEP.ForegripMaxs = Vector(4, 4, 4)

SWEP.SlideMins = Vector(-3, -2, -3)
SWEP.SlideMaxs = Vector(3, 2, 3)

SWEP.MagazineInsertMins = Vector(-2, -4, -3)
SWEP.MagazineInsertMaxs = Vector(2, 1, 4)

SWEP.MagazineOffset = Vector(-0.5, 0, -5)
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideDir = Vector(0, 0, -1)

SWEP.FingerAngles = {
    --right hand open angles
    Angle(-0,-7,-5), Angle(0,40,0), Angle(0,10,0), --finger 0
    Angle(0,35,10), Angle(0,5,0), Angle(0,-7.9,0), --finger 1   This is the index finger, off the trigger
    Angle(0,-10.6,0), Angle(0,-60,0), Angle(0,-47,0), --finger 2
    Angle(0,-10.8,0), Angle(0,-40,0), Angle(0, -60.1,0), --finger 3
    Angle(0,-10.3,-8.2), Angle(0,-40,0), Angle(0,-30.5,0), --finger 4
    --right hand closed angles
    Angle(-0,-7,-5), Angle(0,40,0), Angle(0,10,0), --finger 0
    Angle(0,25,17), Angle(0,-5,0), Angle(0,-50.9,0), --finger 1   This is the index finger, on the trigger
    Angle(0,-10.6,0), Angle(0,-60,0), Angle(0,-47,0), --finger 2
    Angle(0,-10.8,0), Angle(0,-40,0), Angle(0, -60.1,0), --finger 3
    Angle(0,-10.3,-8.2), Angle(0,-40,0), Angle(0,-30.5,0), --finger 4
}

SWEP.LeftHandFingerAngles = {
    -- open
    Angle(0,0,0), Angle(0,-40,0), Angle(0,0,0), --finger 0
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 1
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 2
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 3
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0),
    -- closed
    Angle(20,0,0), Angle(0,-10,0), Angle(0,30,0),
    Angle(0,-25,-10), Angle(0,-50,0), Angle(0,-60,0),
    Angle(0,5.-28,0), Angle(0,-50,0), Angle(0,-50,0),
    Angle(0,-10.5,4.8), Angle(0,-50,0), Angle(0,-35,0),
    Angle(0,-15,12.7), Angle(0,-50,0), Angle(0,-10,0),
}

SWEP.BurstLength = 0
SWEP.SlideGrabbed = false
SWEP.SlideReleasing = false
SWEP.SlidePos = 0
SWEP.SlideLockedBack = false
SWEP.NeedAnotherTriggerPull = false
SWEP.OpenBolt = false
SWEP.LastSlidePos = 0
SWEP.Firemode = 2 -- 0 = safe, 1 = semi, 2 = auto, negative = burst
SWEP.RecoilAngles = Angle(0, 0, 0)
SWEP.RecoilBlowback = 0

SWEP.SlideLockbackAmount = 2.14
SWEP.SlideBlowbackAmount = 2.4

SWEP.BulletBones = {
    [1] = "bullet"
}

SWEP.BoneIndices = {
 pistol = 0,
 magazine = 1,
 trigger = 2,
 chandle = 3,
 selector = 4,
 muzzle = 5,
 eject = 6,
 slidelock = 7,
 slide = 8,
 bullet = 9,
 foregrip = 10,
}



SWEP.MiscLerps = {
}

SWEP.TargetMiscLerps = {
}

SWEP.SlidelockActivePose = {
    pos = Vector(0, 0.1, 0),
    ang = Angle(0, 0, 0)
}

SWEP.FireSelectPoses = {
    [0] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
    },
    [2] = {
        selector = {pos = Vector(-0.088, 0, 0), ang = Angle(0, 0, 0)}
    },
    [1] = {
        selector = {pos = Vector(-0.171, 0, 0), ang = Angle(0, 0, 0)}
    }
}

SWEP.Firemodes = {
    2,
    1,
    0
}

end