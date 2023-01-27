local att = {}

att.Name = "ammo_12g_flec"
att.PrintName = "Ammo Kit 12G - Flechette"
att.Category = "Arctic VR INS2 - Attachments"
att.Bone = nil
att.Slot = "ammo_12g"
att.WorldModel = "models/items/arcticvr/12g_flec.mdl"

att.Override_Num = 4
att.Buff_DamageMax = 2
att.Buff_DamageMin = 1.25
att.Buff_MaxRange = 2.5
att.Buff_Spread = 0.4
att.Buff_MuzzleVelocity = 3
att.Buff_Recoil = 1.15

att.MuzzleEffectOverride = "arcticvr_ins2_muzz_m3"

ArcticVR.LoadAttachmentType(att)