mag = {}

mag.Name = "deagle_7_aniv"
mag.PrintName = "Desert Eagle Magazine"
mag.Capacity = 7
mag.MagType = "deagle"
mag.AmmoType = "357"
mag.Model = "models/weapons/arcticvr/aniv/mag_deagle.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1},
    [2] = {ind = 2, bg = 1},
    [3] = {ind = 3, bg = 1}
}
mag.Pose = {
    pos = Vector(-6.5, 4, -5),
    ang = Angle(0, 0, 90)
}

ArcticVR.LoadMagazineType(mag)