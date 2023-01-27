AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR"
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.ViewModel = "models/weapons/arcticvr/pistol_glock.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"

SWEP.Base = "arcticvr_base"

SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 17
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

SWEP.PrintName = "VR Glock 17"
SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Chambered = 0
SWEP.LoadedRounds = 0
SWEP.Magazine = nil

SWEP.DamageMin = 15
SWEP.DamageMax = 40
SWEP.MaxRange = 6000
SWEP.Penetration = 4
SWEP.MuzzleVelocity = 10000
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 2
SWEP.RPM = 700
SWEP.Recoil = 0.9
SWEP.RecoilVertical = 6
SWEP.RecoilSide = 1.5
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 125
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "pistol"

SWEP.MagType = "glock"
SWEP.DefaultMagazine = "glock_17"

SWEP.MuzzleEffect = "CS_MuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19"
SWEP.BulletEffect = "arcticvr_bullet_9x19"

SWEP.NextPrimaryFire = 0

SWEP.FireSound = "weapons/glock/glock18-1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/glock/glock_slideback.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/p228_slideforward.wav"
SWEP.SlideReleaseSound = "weapons/glock/glock_sliderelease.wav"
SWEP.MagInSound = "weapons/glock/glock_clipin.wav"
SWEP.MagOutSound = "weapons/glock/glock_clipout.wav"
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_glock = {
    offsetPos = Vector(5.5, 1.25, 2.0), --forward, left, up
    offsetAng = Angle(0, 0, 0),
}

SWEP.Firemode = 1

SWEP.CanLockBack = true
SWEP.MagCanDropFree = true
SWEP.BoltCanAutoRelease = true

SWEP.SlideMins = Vector(-3, -0.6, -7)
SWEP.SlideMaxs = Vector(3, 4, 2.5)

SWEP.MagazineInsertMins = Vector(-3, -7, -3)
SWEP.MagazineInsertMaxs = Vector(3, 0, 3)

SWEP.MagazineOffset = Vector(0, 0, 0)
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideLockbackAmount = 1.25
SWEP.SlideBlowbackAmount = 1.4

SWEP.SlideDir = Vector(0, 0, -1)

SWEP.BoneIndices = {
    trigger = 1,
    slide = 2,
    bullet = 4,
    slidelock = 6,
    mag = 0,
}

SWEP.SlidelockActivePose = {
    pos = Vector(-0.1, -0.147, 0),
    ang = Angle(0, 0, 0)
}

SWEP.Firemodes = {
    1,
	0
}

end