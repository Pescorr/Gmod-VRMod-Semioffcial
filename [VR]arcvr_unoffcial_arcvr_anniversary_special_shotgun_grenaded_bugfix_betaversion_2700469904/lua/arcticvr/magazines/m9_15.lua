mag = {}

mag.Name = "m9_15"
mag.PrintName = "M9 Magazine"
mag.Capacity = 15
mag.MagType = "m9"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/mag_m9.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1}
}
mag.Pose = {
    pos = Vector(5, 1, 4),
    ang = Angle(0, 0, 0)
}

ArcticVR.LoadMagazineType(mag)