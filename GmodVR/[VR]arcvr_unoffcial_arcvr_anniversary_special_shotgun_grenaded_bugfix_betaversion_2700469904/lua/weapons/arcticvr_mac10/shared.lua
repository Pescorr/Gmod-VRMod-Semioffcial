AddCSLuaFile()

SWEP.Spawnable = true
SWEP.Category = "Arctic VR"
SWEP.AdminOnly = false
SWEP.UseHands = false

SWEP.ViewModel = "models/weapons/arcticvr/smg_mac10.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mac10.mdl"

SWEP.Base = "arcticvr_base"

SWEP.ArcticVR = true

SWEP.Primary.ClipSize = 32
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

SWEP.PrintName = "VR MAC-10"
SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.DamageMin = 10
SWEP.DamageMax = 30
SWEP.MaxRange = 5000
SWEP.Penetration = 4
SWEP.MuzzleVelocity = 10000
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 3
SWEP.RPM = 1090
SWEP.Recoil = 0.95
SWEP.RecoilVertical = 3
SWEP.RecoilSide = 3.5
SWEP.RecoilBalance = Vector(-1, 0, 0.75)
SWEP.Spread = 1 / 105
SWEP.MeanShotsBetweenJams = 0
SWEP.AmmoType = "pistol"

SWEP.OpenBolt = true

SWEP.MagType = "mac10"
SWEP.DefaultMagazine = "mac10_32"

SWEP.MuzzleEffect = "CS_MuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19"
SWEP.BulletEffect = "arcticvr_bullet_9x19"

SWEP.FireSound = "weapons/mac10/mac10-1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/arcticvr/mac10_boltback.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/mac10_boltforward.wav"
SWEP.MagInSound = "weapons/arcticvr/mac10_magin.wav"
SWEP.MagOutSound = "weapons/mac10/mac10_clipout.wav"
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_mac10 = {
    offsetPos = Vector(5.5, 1.25, 2.0), --forward, left, up
    offsetAng = Angle(0, 0, 0),
}

SWEP.Firemode = 2

SWEP.CanLockBack = true
SWEP.MagCanDropFree = false
SWEP.BoltCanAutoRelease = false

SWEP.SlideMins = Vector(-4, -0.6, -4)
SWEP.SlideMaxs = Vector(4, 4, 4)

SWEP.MagazineInsertMins = Vector(-3, -7, -3)
SWEP.MagazineInsertMaxs = Vector(3, 0, 3)

SWEP.MagazineOffset = Vector(0, 0, 0)
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideLockbackAmount = 3.8
SWEP.SlideBlowbackAmount = 4.1

SWEP.SlideDir = Vector(0, 0, -1)

SWEP.BoneIndices = {
    trigger = 1,
    slide = 2,
    safety = 3,
    selector = 7,
    bullet = 4,
    mag = 0,
}

SWEP.Firemodes = {
    2,
    1,
    0
}

SWEP.FireSelectPoses = {
    [2] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
        safety = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
    },
    [1] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 179)},
        safety = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
    },
    [0] = {
        selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
        safety = {pos = Vector(0, 0, -0.5), ang = Angle(0, 0, 0)}
    }
}

end