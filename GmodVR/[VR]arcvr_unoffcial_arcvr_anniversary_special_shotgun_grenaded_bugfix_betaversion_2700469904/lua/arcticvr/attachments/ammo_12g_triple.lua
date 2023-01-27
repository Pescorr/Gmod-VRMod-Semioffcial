local att = {}

att.Name = "ammo_12g_triple"
att.PrintName = "Ammo Kit 12G - Triple"
att.Category = "Arctic VR INS2 - Attachments"
att.Bone = nil
att.Slot = "ammo_12g"
att.WorldModel = "models/items/arcticvr/12g_triple.mdl"

att.Override_Num = 3
att.Buff_DamageMax = 2
att.Buff_DamageMin = 1.15
att.Buff_MaxRange = 1.15
att.Buff_Spread = 0.65
att.Buff_MuzzleVelocity = 1.15
att.Buff_Recoil = 1.15

att.MuzzleEffectOverride = "arcticvr_ins2_muzz_slug"

ArcticVR.LoadAttachmentType(att)