AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR"
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.Base = "arcticvr_base"

SWEP.ViewModel = "models/weapons/arcticvr/pistol_m9.mdl"
SWEP.WorldModel = "models/weapons/w_pist_elite_single.mdl"

SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 15
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

SWEP.PrintName = "VR Beretta M9"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Chambered = 0
SWEP.LoadedRounds = 0
SWEP.Magazine = nil

SWEP.DamageMin = 15
SWEP.DamageMax = 40
SWEP.MaxRange = 6500
SWEP.Penetration = 6
SWEP.MuzzleVelocity = 10000
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 2
SWEP.RPM = 700
SWEP.Recoil = 0.8
SWEP.RecoilVertical = 7
SWEP.RecoilSide = 1.5
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 125
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "pistol"

SWEP.MagType = "m9"
SWEP.DefaultMagazine = "m9_15"

SWEP.MuzzleEffect = "CS_MuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19"
SWEP.BulletEffect = "arcticvr_bullet_9x19"

SWEP.NextPrimaryFire = 0

SWEP.FireSound = "weapons/elite/elite-1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/usp/usp_slideback2.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/p228_slideforward.wav"
SWEP.SlideReleaseSound = "weapons/usp/usp_sliderelease.wav"
SWEP.MagInSound = "weapons/elite/elite_leftclipin.wav"
SWEP.MagOutSound = "weapons/elite/elite_clipout.wav"
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_m9 = {
    offsetPos = Vector(5.5, 1.25, 2.5), --forward, left, up
    offsetAng = Angle(0, 0, 0),
}

SWEP.CanLockBack = true
SWEP.MagCanDropFree = true
SWEP.BoltCanAutoRelease = true

SWEP.SlideMins = Vector(-3, -0.6, -9)
SWEP.SlideMaxs = Vector(3, 4, 3)

SWEP.MagazineInsertMins = Vector(-3, -8, -3)
SWEP.MagazineInsertMaxs = Vector(3, 0, 3)

SWEP.MagazineOffset = Vector(0, 0, 0)
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideDir = Vector(0, 0, -1)

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
SWEP.CSMagazine = nil
SWEP.CSMagazineInsertionTime = 0
SWEP.CSMagazineOriginal = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0)
}

SWEP.SlideLockbackAmount = 1.35
SWEP.SlideBlowbackAmount = 1.5

SWEP.BoneIndices = {
    hammer = 1,
    trigger = 2,
    slide = 3,
    selector = 4,
    bullet = 5,
    slidelock = 8,
    mag = 0,
}
SWEP.SlidelockActivePose = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 10)
}

SWEP.MiscLerps = {
}

SWEP.TargetMiscLerps = {
}

SWEP.FireSelectPoses = {
    [0] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 62)}
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