local att = {}

att.Name = "ammo_12g_riot"
att.PrintName = "Ammo Kit 12G - Riot Baton"
att.Category = "Arctic VR INS2 - Attachments"
att.Bone = nil
att.Slot = "ammo_12g"
att.WorldModel = "models/items/arcticvr/12g_riot.mdl"

att.Override_Num = 1
att.Buff_DamageMax = 1
att.Buff_DamageMin = 0.5
att.Buff_MaxRange = 0.25
att.Buff_Spread = 0.25
att.Buff_MuzzleVelocity = 0.25
att.Buff_Recoil = 0.25

att.Silencer = true
att.MuzzleEffectOverride = "arcticvr_ins2_muzz_gl"

att.OverrideTracerCol = Color(0, 0, 0)

ArcticVR.LoadAttachmentType(att)