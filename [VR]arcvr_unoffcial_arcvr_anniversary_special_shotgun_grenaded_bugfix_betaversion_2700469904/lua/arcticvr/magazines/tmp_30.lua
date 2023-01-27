mag = {}

mag.Name = "tmp_30"
mag.PrintName = "TMP Magazine"
mag.Capacity = 30
mag.MagType = "tmp"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/mag_tmp.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1}
}
mag.Pose = {
    pos = Vector(5, 1, 5),
    ang = Angle(0, 0, 0)
}

ArcticVR.LoadMagazineType(mag)