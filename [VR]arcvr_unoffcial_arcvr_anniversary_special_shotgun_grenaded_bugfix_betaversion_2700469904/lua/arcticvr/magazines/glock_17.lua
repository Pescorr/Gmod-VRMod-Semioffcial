mag = {}

mag.Name = "glock_17"
mag.PrintName = "Glock Magazine"
mag.Capacity = 17
mag.MagType = "glock"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/mag_glock.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1}
}
mag.Pose = {
    pos = Vector(5, 1, 2),
    ang = Angle(0, 0, 0)
}

ArcticVR.LoadMagazineType(mag)