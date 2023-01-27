local att = {}

att.DoNotRegister = false -- do not register entity under any circumstances

att.PrintName = "Attachment" -- display name of the attachment
att.Name = "default" -- shortname of the attachment
att.Bone = nil -- effectively, the main bone of the attachment. Not always necessary.
att.Type = "" -- subtype used for single bone/multiple att types
att.Model = "" -- model of the attachment. Should have physics.
att.WorldModel = nil -- world model of the attachment if different to former. Not strictly necessary.
att.HideModel = false -- don't draw the model under any circumstances

att.GivesFlags = {} -- this attachment provides these attachment flags

att.MagReducer = false -- this attachment activates shrunk mags if applicable
att.MagExtender = false -- this attachment activates extended mags if applicable
-- normal mags will be used if both are active lmao

att.SniperizeRanges = false -- damage will start low and end high
att.DeSniperizeRanges = false -- damage will start high and end low

att.Holosight = false -- functions like on weapon
att.HolosightReticle = nil -- Material("path/to/sight/reticle")
att.HolosightDist = 32
att.HolosightSize = 3
att.HolosightPiece = nil -- model. This is the path to the holosight "piece" which is used to cull the reticle.

att.RTScope = false -- this attachment is an RT scope
att.RTScopeSubmatIndex = 0 -- what is the submaterial index of the scope material?
att.RTScopeFOV = 30 -- what is the field of view of the scope?
att.RTScopeRes = 256 -- resolution
att.RTScopeSurface = Material("effects/avr_rt") -- don't change this
att.RTScopeOffset = Vector(0, 0, 0) -- position offset. Not generally needed.

att.LaserSight = false -- same as on vm. Laser emits from "laser" attachment point.
att.LaserSightColor = Color(255, 0, 0)

att.OverrideForegrip = false -- takes over default foregrip behaviour
att.ForegripOffset = Vector(0, 0, 0) -- foregrip offset RELATIVE to base foregrip position
att.ForegripAngle = Angle(0, 0, 0) -- angle, NOT relative to base foregrip angle

att.OverrideMuzzle = false -- set to override the gun's muzzle with the attachment's
att.OverrideMuzzleEffect = nil -- set to override muzzle effect
att.OverrideShellEffect = nil
att.OverrideBulletEject = nil
att.Silencer = false -- switches weapon to use silenced shooting sound

att.OverrideTracerCol = nil -- overwrite to override tracer color
att.Buff_TracerWidth = 0 -- additive.

att.GivesStock = false -- this attachment gives the gun a stock

att.Buff_Recoil = 1 -- overall recoil multiplier
att.Buff_Recoil_Vertical = 1 -- vertical kick multiplier
att.Buff_Recoil_Side = 1 -- side kick multiplier

att.Buff_Recoil_TwoHand = 1 -- multiplies recoil while two handing
att.Buff_Recoil_TwoHand_Pistol = 1
att.Buff_Recoil_Stock = 1 -- multiplies recoil while using stock

att.Buff_StabilityFrames = 0 -- additive.
att.Buff_PassiveStabilityFrames = 0 -- additive.
att.Buff_WeightPenaltyFrames = 0 -- additive.

att.Buff_DamageMax = 1 -- max damage multiplier. Applies to whichever value out of DamageMin or DamageMax is highest.
att.Buff_DamageMin = 1 -- see above.
att.Buff_MaxRange = 1
att.Buff_Penetration = 1
att.Buff_MuzzleVelocity = 1

att.Buff_ShotVolume = 1

att.Buff_RPM = 1

att.Buff_Spread = 1

att.Override_ShootEntity = nil
att.Override_Num = nil -- overrides the number of bullets shot

att.AttThink = function(swep, vm, attmdl, attslot) -- use this to add per tick behaviour such as changing the appearance based on weapon state
end

att.AttachFunc = function(SWEP)
end

att.DetachFunc = function(SWEP)
end