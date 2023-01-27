mag = {}

mag.Name = "glock_17_aniv"
mag.PrintName = "Glock Magazine"
mag.Capacity = 17
mag.MagType = "glock"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/aniv/mag_glock.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1},
    [2] = {ind = 2, bg = 1},
    [3] = {ind = 3, bg = 1}
}
mag.Pose = {
    pos = Vector(-6.5, 3.2, -5),
    ang = Angle(0, 0, 90)
}

ArcticVR.LoadMagazineType(mag)