mag = {}

mag.Name = "mac10_32"
mag.PrintName = "MAC-10 Magazine"
mag.Capacity = 32
mag.MagType = "mac10"
mag.AmmoType = "pistol"
mag.Model = "models/weapons/arcticvr/mag_mac10.mdl"

mag.IsBeltBox = false

mag.BodygroupsShowBullets = {
    [1] = {ind = 1, bg = 1}
}
mag.Pose = {
    pos = Vector(5, 1, 5),
    ang = Angle(0, 0, 0)
}

ArcticVR.LoadMagazineType(mag)