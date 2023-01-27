local att = {}

att.Name = "ammo_12g_slug"
att.PrintName = "Ammo Kit 12G - Slug"
att.Category = "Arctic VR INS2 - Attachments"
att.Bone = nil
att.Slot = "ammo_12g"
att.WorldModel = "models/items/arcticvr/12g_slug.mdl"

att.Override_Num = 1
att.Buff_DamageMax = 8
att.Buff_DamageMin = 5
att.Buff_MaxRange = 2.25
att.Buff_Spread = 0.15
att.Buff_MuzzleVelocity = 1.5
att.Buff_Recoil = 1.25

att.MuzzleEffectOverride = "arcticvr_ins2_muzz_slug"

ArcticVR.LoadAttachmentType(att)