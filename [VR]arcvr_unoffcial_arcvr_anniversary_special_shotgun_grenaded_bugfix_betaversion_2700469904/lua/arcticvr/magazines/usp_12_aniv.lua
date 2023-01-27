mag = {}

mag.Name = "usp_12_aniv"
mag.PrintName = "USP Tactical Magazine"
mag.Capacity = 12
mag.MagType = "usp"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/aniv/mag_usp.mdl"

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