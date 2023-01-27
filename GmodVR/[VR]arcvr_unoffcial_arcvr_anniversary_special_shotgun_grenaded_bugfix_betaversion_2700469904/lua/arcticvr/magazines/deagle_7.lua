mag = {}

mag.Name = "deagle_7"
mag.PrintName = "Desert Eagle Magazine"
mag.Capacity = 7
mag.MagType = "deagle"
mag.AmmoType = "357"
mag.Model = "models/weapons/arcticvr/mag_deagle.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1}
}
mag.Pose = {
    pos = Vector(4.5, 1, 5),
    ang = Angle(0, 0, 0)
}

ArcticVR.LoadMagazineType(mag)