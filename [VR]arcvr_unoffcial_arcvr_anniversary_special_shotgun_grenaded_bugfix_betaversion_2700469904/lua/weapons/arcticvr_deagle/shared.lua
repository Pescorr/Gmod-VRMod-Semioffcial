AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR"
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.Base = "arcticvr_base"

SWEP.ViewModel = "models/weapons/arcticvr/pistol_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"

SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 1000
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "357"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "VR Desert Eagle"
SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.DamageMin = 30
SWEP.DamageMax = 75
SWEP.MaxRange = 1250
SWEP.Penetration = 7
SWEP.MuzzleVelocity = 15000
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 4
SWEP.RPM = 500
SWEP.Recoil = 2
SWEP.RecoilVertical = 20
SWEP.RecoilSide = 2.5
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 550
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "357"

SWEP.MagType = "deagle"
SWEP.DefaultMagazine = "deagle_7"

SWEP.MuzzleEffect = "CS_MuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_50ae"
SWEP.BulletEffect = "arcticvr_bullet_50ae"

SWEP.FireSound = "weapons/deagle/deagle-1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/deagle/de_slideback.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/p228_slideforward.wav"
SWEP.SlideReleaseSound = "weapons/usp/usp_sliderelease.wav"
SWEP.MagInSound = "weapons/elite/elite_leftclipin.wav"
SWEP.MagOutSound = "weapons/deagle/de_clipout.wav"
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_deagle = {
    offsetPos = Vector(5.5, 1.25, 2.5), --forward, left, up
    offsetAng = Angle(0, 0, 0),
}

SWEP.CanLockBack = true
SWEP.MagCanDropFree = true
SWEP.BoltCanAutoRelease = true
SWEP.PistolStabilize = true	


SWEP.SlideMins = Vector(-4, -0.6, -3)
SWEP.SlideMaxs = Vector(4, 5, 9)

SWEP.MagazineInsertMins = Vector(-3, -8, -3)
SWEP.MagazineInsertMaxs = Vector(3, 0, 3)

SWEP.MagazineOffset = Vector(0, 0, 0)
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideDir = Vector(0, 0, -1)

SWEP.SlideLockbackAmount = 2.6
SWEP.SlideBlowbackAmount = 2.75

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
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 26.5)}
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