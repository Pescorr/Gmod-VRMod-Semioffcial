mag = {}

mag.Name = "m9_15_aniv"
mag.PrintName = "M9 Magazine"
mag.Capacity = 15
mag.MagType = "m9"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/aniv/mag_m9.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1},
    [2] = {ind = 2, bg = 1},
    [3] = {ind = 3, bg = 1}
}
mag.Pose = {
    pos = Vector(-6.5, 3.5, -5),
    ang = Angle(0, 0, 90)
}

ArcticVR.LoadMagazineType(mag)