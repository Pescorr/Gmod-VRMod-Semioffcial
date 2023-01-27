local att = {}

att.Name = "ammo_12g_frag"
att.PrintName = "Ammo Kit 12G - Frag"
att.Category = "Arctic VR INS2 - Attachments"
att.Bone = nil
att.Slot = "ammo_12g"
att.WorldModel = "models/items/arcticvr/12g_frag.mdl"

att.Override_Num = 1
att.Override_ShootEntity = "arcticvr_frag12_proj"
att.Buff_Recoil = 1.25

att.MuzzleEffectOverride = "arcticvr_ins2_muzz_slug"

ArcticVR.LoadAttachmentType(att)