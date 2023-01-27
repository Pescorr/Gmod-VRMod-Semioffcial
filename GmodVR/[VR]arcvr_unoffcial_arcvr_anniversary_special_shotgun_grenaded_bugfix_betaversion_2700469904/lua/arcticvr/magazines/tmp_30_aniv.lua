mag = {}

mag.Name = "tmp_30_aniv"
mag.PrintName = "TMP Magazine"
mag.Capacity = 30
mag.MagType = "tmp"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/aniv/mag_tmp.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1},
    [2] = {ind = 2, bg = 1},
    [3] = {ind = 3, bg = 1}
}
mag.Pose = {
    pos = Vector(-5.5, 6.5, 7),
    ang = Angle(0, 0, 0)
}

ArcticVR.LoadMagazineType(mag)