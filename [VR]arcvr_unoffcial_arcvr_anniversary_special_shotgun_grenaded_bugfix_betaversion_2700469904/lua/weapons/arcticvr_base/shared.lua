-- Okay, listen up, because I'm going to take you on a tutorial to make VR weapons.
-- Before you even touch this file, you will need the following:
--  - A VR headset. I mean, you could technically do this without one, but what'd be the point?
--  - A model you want to convert. If this is already rigged then you don't need ANYTHING else.
--  - Blender: To do the rigging.
--  - Blender Source Tools: To import/export .SMD source models.
--  - Crowbar (For Source): To extract stuff and compile .QC files.
--  - Patience or a good internet connection: You will be looking up a *lot* of shit.

-- And a basic understanding of:
--  - Blender. Watch a tutorial if you don't know anything about it.
--  - Source Engine. Understanding can only be acquired through experience.

-- Step 0: Annoying Hurdles
-- Crowbar needs to be set up if your games are not in the default C: directory Steam uses.
-- Blender Source Tools needs to be set up. It has a panel in "Scene Properties" in Blender, the tab in the bottom right (By default) panel with a droplet and some other crap.
-- Not setting up BST can be a large source of beginner pain!
-- Turn on Word Wrap to read this file more easily.

-- Step 1: Preparation
-- The first thing you need to do is to get your model. Usually this will be in another game or addon or something.
-- If it's a Source game, Crowbar can extract them.
-- If it's a Gmod addon, Crowbar can extract them too.
-- After you have this model, you need to decompile it. This can be done with Crowbar, once it's set up. You don't need to touch any of the checkboxes, though "Folder For Each Model" can help.
-- Now, all you have to do is enable Blender Source Tools (They have a tutorial on how to do it) and import the .SMD model.

-- Step 2: The Model Itself
-- Fair warning, I'm not going to explain hotkeys here; if you need to learn how to do something, look it up. Yes, this will add time to the process, but trust me, having this tutorial is going to make life 400% easier for you.
-- Once you import a model, it'll usually have a skeleton, probably with some hands. You could work on the back of that, but I find it easier to just delete it all and start again from scratch.
-- Select the skeleton and delete it.
-- Then, select the model, go into the vertex group tab (The green triangle) and delete all vertex groups. There's a "Delete All" function in the dropdown to the right of all the vertex groups.
-- Next, you'll have to get a new skeleton. I recommend just taking one from one of my guns, because they're all setup about the same, and they're all setup *correctly* most importantly. Technically you don't need to do this, but they're all known values and... look, it's just easier this way.
-- Use your number pad to go into orthogonal view to line up the bones to where they need to be. This only really matters for the muzzle, eject position, slide bone, charging handle bone and scope bone where applicable.
-- The names of the bones don't matter, you can change them all later, though explanatory names are helpful.
-- All bones should point FORWARD.
-- Then, parent the gun to the skeleton with empty groups.
-- The bones will show up in the vertex group tab as vertex groups. In your gun, simply assign the appropriate vertex groups to all moving geometry. Generally this will just be the bullet, slide, and fire selector, though some guns will have a charging handle as well.
-- Use Select Linked to do this more easily.
-- After this is done, you need to make an idle animation. Select your skeleton.
-- Enter "Pose Mode".
-- Select all bones.
-- Hit "I" and make a full character keyframe.
-- in the outliner, go into the skeleton and select the animation. Rename it to "idle".

-- OPTIONAL Step 2.1: Adding a scope
-- Adding a scope is actually dead easy. All you need to do is to select your lens surface, then assign it to another material.
-- Then, just make sure it's UV unwrapped properly. The scope "output" is drawn to a 256x256 square, so just make sure you keep that in mind. Usually, U -> "Project From View" produces decent results, though it may not be oriented properly.
-- To find out whether it's oriented properly I usually get a material with a white square in the bottom left corner, because then if in the 3D view I see that it isn't in the bottom left corner of the scope, I know to flip the UV.

-- OPTIONAL Step 2.2: Adding a holographic sight
-- This is actually surprisingly a little harder than a scope, but still not difficult.
-- First, get the surface you want your holographic sight to be drawn "on". Think of this like the glass.
-- Split off this geometry. This should be a seperate model.
-- Make sure it's on the same skeleton (Armature) as the gun.

-- Step 3: Compile
-- The main focus of this step is in making a .QC file that Crowbar can compile for you into a working model Gmod can load.
-- Personally I recommend just using one from my guns, and editing it.
-- The main things you need to set are:
--  Model name/path.
--  Model .SMD source. Obviously.
--  CDMaterials. These are the directories the model will search for materials in. Copy these from the .QC you got from decompiling.
--  Attachments. These are crucial for the muzzle, eject pos, scope, and holosight, where applicable. **ATTACHMENT NAMES ARE NOT CODE NEGOTIABLE; USE "SCOPE", "HOLOSIGHT", ETC.**
--  Idle animation. This just needs to be one frame, because this is how Source interprets the "Base" form of the model.
-- After you write your .QC file (Easier than it sounds, really) you can have Crowbar compile it.
-- Beware! Not all Source games' compilers are the same. I recommend just using Gmod's.
-- Tick "No P4" if it isn't ticked for you. P4 is some professional bullshit. You don't have it. Just tick the box.
-- Direct the output straight to an addon's folder under /addons. This is because it'll have the models/weapons/whatever.mdl path already set. You could put it into a different folder or whatever, but why would you?

-- Step 4: Weapon Definition
-- This is the part where you make the gun work.
-- You could spend anywhere from a minute to a day on this part.
-- Don't worry! No actual coding knowledge is required!
-- You can just copy an existing gun and modify it. Every parameter that can be defined can be read about here.
-- The rest of this "tutorial" is underneath. I suggest you go through the whole thing at least once.
-- Important! SWEP.BoneIndices can be set near-automatically with the console command "arcticvr_printvmbones". You may need to edit the names if they don't match what ArcVR wants.
-- To define a magazine, see lua/arcticvr/magazines.
-- To define an ArcVR bullet case/bullet, see lua/autorun/cl_arcticvr_cases.lua.
-- Happy hunting! If you're still confused you can pop by the Discord server; a link is on the ArcVR workshop page.

-- Step 5: (Added in Attachment Update)
-- Okay, so: Attachments.
-- Reference arcticvr/attachments/default.lua for a list of all the possible parameters
-- Reference also SWEP.Attachments in this file
-- Attachments are bonemerged



-- AddCSLuaFile()



local cv_gunmeleedamage = GetConVar("arcticvr_gunmelee_damage"):GetFloat()
local cv_gunmeleeVel = GetConVar("arcticvr_gunmelee_velthreshold"):GetFloat()
local cv_gunmeleedelay = GetConVar("arcticvr_gunmelee_Delay"):GetFloat()
local cv_all_attachment = CreateClientConVar("arcticvr_allgun_allow_attachment","1",FCVAR_ARCHIVE)


SWEP.Spawnable = false -- this obviously has to be set to true
SWEP.Category = "Arctic VR" -- edit this if you like
SWEP.AdminOnly = false
SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arcticvr/aniv/pistol_m9.mdl" -- I mean, you probably have to edit these too
SWEP.WorldModel = "models/weapons/w_pist_elite_single.mdl"

SWEP.ArcticVR = true -- always keep this true

SWEP.Primary.ClipSize = 20
SWEP.Primary.DefaultClip = 1000 -- edit this part just to tell other stuff about the gun. ArcVR doesn't use this data.
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- auto switch crap. Edit if you like.
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.PrintName = "VR Gun Base" -- you should probably change this
SWEP.Slot = 3 -- you could edit these if you like
SWEP.SlotPos = 1

SWEP.DrawAmmo = false -- irrelevant
SWEP.DrawCrosshair = false

SWEP.ViewModelFOV = 90 -- ALWAYS set to 90

-- main gun stats. The fun part!
SWEP.DamageMin = 25
SWEP.DamageMax = 40
SWEP.MaxRange = 4000 -- Damage starts at Max and reaches Min at MaxRange. Max can be smaller than Min, or the same.
SWEP.ShootEntity = nil -- Set this to an entity name to shoot it out of the gun.
SWEP.ProjectileOffset = Angle(0, 0, 0)
SWEP.Penetration = 5
SWEP.MuzzleVelocity = 10000
SWEP.ShotVolume = 130 -- Volume of the gun. 149 is the maximum value.
SWEP.TracerCol = Color(255, 200, 0)
SWEP.TracerWidth = 4
SWEP.RPM = 300 -- "Rounds Per Minute"

SWEP.Recoil = 2
SWEP.RecoilVertical = 10 -- The vertical component of the recoil. Dependent on SWEP.Recoil.
SWEP.RecoilSide = 1.5 -- The side component. Also dependent on SWEP.Recoil.
SWEP.RecoilTwoHandMult = 0.5 -- amount of recoil felt while two handing
SWEP.RecoilPistolTwoHandMult = 0.75 -- amount of recoil felt while "two handing" pistols
SWEP.RecoilStockMult = 0.5 -- amount of recoil felt while using weapon stock

SWEP.RecoilBalance = Vector(-1, 0, 0.75) -- The direction blowback goes. (Forward, Right, Up).
SWEP.Spread = 1 / 125 -- Spread in 1/10ths of a full circle.
SWEP.Num = 1 -- Number of bullets per shot. Useful for shotguns.
SWEP.MeanShotsBetweenJams = 0 -- Set to 0 to never jam. Not really recommended.
SWEP.AmmoType = "pistol" -- Just uses SWEP.Primary.Ammo now. Ignore.

SWEP.MeleeAttack = true -- whether this weapon can melee attack
SWEP.MeleeVelThreshold = cv_gunmeleeVel -- how fast you have to swing
SWEP.MeleeDelay = cv_gunmeleedelay
SWEP.MeleeDamage = cv_gunmeleedamage
SWEP.MeleeDamageType = DMG_CLUB

SWEP.OpenBolt = false
-- open bolt weapons work differently.
-- they can always be slidelocked.
-- shooting instead just opens the slide lock.
-- when the slide lock is released, a round is chambered.
-- the gun automatically fires when the bolt comes fully forward.
-- it then recocks itself.
-- open bolt guns can never dry eject bullets.

SWEP.MagType = "m9" -- Self-explanatory.
SWEP.BeltBoxType = "" -- if the mag is a belt box, this gun can accept these types of them
SWEP.DefaultMagazine = "m9_15"
SWEP.ExtendedMagazine = nil -- if set, this weapon can accept an "extended magazine" attachment and will spawn these instead.

SWEP.MuzzleEffectScale = 1
SWEP.DisableMuzzleEffect = false
SWEP.MuzzleEffect = "CS_MuzzleFlash"
SWEP.CaseEffect = "arcticvr_case_9x19"
SWEP.BulletEffect = "arcticvr_bullet_9x19" -- Unfired bullets

SWEP.NetworkedSounds = {
    "FireSound",
    "FireSoundSil",
    "DryFireSound",
    "SwitchModeSound",
    "SlidePulledSound",
    "SlideBackSound",
    "SlideForwardSound",
    "SlideReleaseSound",
    "BoltUpSound",
    "MagInSound",
    "MagOutSound",
    "DirectChamberSound",
    "OpenChamberSound",
    "CloseChamberSound",
    "MeleeStrikeSound",
    "MeleeHitSound",
    "SlideClickLockSound",
    "BeltPullSound",
    "BeltInSound",
    "BeltOutSound",
}

SWEP.InternalMagazine = false -- Weapon has an internal magazine; "magazines" inserted are consumed and automatically added into the gun.
-- Basically it's a shotgun.
SWEP.InternalMagazineCapacity = 5 -- do I REALLY need to explain this one

SWEP.NonAutoloading = false -- gun will not automatically blow back. e.g: SPB rifles, pump shotgun, bolt actions

SWEP.DisintegratingMagazine = false -- magazine disintegrates when ammo is depleted, .e.g RPG

SWEP.NotAGun = false -- this weapon is.... not a gun.

SWEP.BaseFlags = {} -- {"flag", "flag2"}...
if cv_all_attachment:GetBool() then
	SWEP.Attachments = {}
else
	SWEP.Attachments = {
    {
        Bone = "sight",
        Slot = "pic_sight",
        InstalledBG = {
            ind = 1,
            bg = 1
        },
    },
    {
        Bone = "sight",
        Slot = "pic_sightatt"
    },
    {
        Bone = "att",
        Slot = "pic_tac",
        InstalledBG = {
            ind = 3,
            bg = 1
        },
    },
    {
        Bone = "muzzle",
        -- Slot = "9mmmuzz",
    },
    {
        Bone = "foregrip",
        Slot = "pic_fg",
        InstalledBG = {
            ind = 2,
            bg = 1
        },
    },
    {
        Slot = "ammo_12g",
    },
    {
        Slot = "ammo",
        Default = "ammo_fmj"
    }
}
end
-- SWEP.Attachments = {
--     { -- slot
--         Slot = "pic_sight",
--         Bone = "sight", -- relevant bone any attachments will be mostly referring to
--         Prereqs = { -- these slots need to be filled in order to use this slot.
--             "mount"
--         },
--         BlacklistFlags = { -- if ANY of these flags are active, prohibit this slot.
--         },
--         WhitelistFlags = { -- if any of these flags are NOT active, prohibit this slot.
--         },
--         GivesFlags = {
--         },
--         InstalledBG = { -- activate this bodygroup if this attachment is installed
--             ind = 1,
--             bg = 1
--         },
--         ParentToSlot = 2, -- parent this attachment to the attachment in this slot, if applicable
--         Installed = nil,
--         Default = "optic_aimpoint" -- this attachment will be given by default on spawn
--     }
-- }

SWEP.FireSound = "weapons/elite/elite-1.wav"
SWEP.FireSoundSil = "weapons/usp/usp1.wav"
SWEP.DryFireSound = "weapons/clipempty_pistol.wav"
SWEP.SwitchModeSound = "weapons/ar2/ar2_empty.wav"
SWEP.SlidePulledSound = ""
SWEP.SlideBackSound = "weapons/usp/usp_slideback2.wav"
SWEP.SlideForwardSound = "weapons/arcticvr/p228_slideforward.wav"
SWEP.SlideReleaseSound = "weapons/usp/usp_sliderelease.wav"
SWEP.SlideClickLockSound = ""
SWEP.BoltUpSound = ""
SWEP.MagInSound = "weapons/elite/elite_leftclipin.wav"
SWEP.MagOutSound = "weapons/elite/elite_clipout.wav"
SWEP.DirectChamberSound = nil
SWEP.SpawnMagSound = "foley/eli_hand_pat.wav"
SWEP.OpenChamberSound = ""
SWEP.CloseChamberSound = ""
SWEP.MeleeHitSound = "Weapon_Crowbar.Melee_Hit"
SWEP.MeleeStrikeSound = "Weapon_Crowbar.Melee_Hit"
SWEP.BeltPullSound = ""
SWEP.BeltInSound = ""
SWEP.BeltOutSound = ""

-- don't touch
SWEP.Chambered = 0
SWEP.LoadedRounds = 0
SWEP.Magazine = nil
SWEP.NextPrimaryFire = 0
SWEP.NextMeleeAttack = 0
SWEP.TotalLaserStrength = 0
SWEP.AverageLaserColor = nil

if SERVER then
    include("sv_server.lua")
end

AddCSLuaFile("cl_misc.lua")
AddCSLuaFile("cl_melee.lua")
AddCSLuaFile("cl_reload.lua")
AddCSLuaFile("cl_shooting.lua")
AddCSLuaFile("cl_sights.lua")
AddCSLuaFile("cl_think.lua")
AddCSLuaFile("cl_input.lua")

if CLIENT then
    include("cl_misc.lua")
    include("cl_melee.lua")
    include("cl_reload.lua")
    include("cl_shooting.lua")
    include("cl_sights.lua")
    include("cl_think.lua")
    include("cl_input.lua")
end

AddCSLuaFile("sh_attachments.lua")
include("sh_attachments.lua")

if CLIENT then

g_VR.viewModelInfo = g_VR.viewModelInfo or {}

g_VR.viewModelInfo.arcticvr_m9 = { -- this needs to be g_VR.viewModelInfo.your_gun_name
    offsetPos = Vector(5.5, 1.25, 2.5), --forward, left, up
    offsetAng = Angle(0, 0, 0),
}

SWEP.FingerAngles = {
    --right hand open angles
    Angle(-25,-6.9,-20.1), Angle(0,0,0), Angle(0,60,0), --finger 0
    Angle(10,25,15), Angle(0,-50,0), Angle(0,-47.9,0), --finger 1
    Angle(0,-33.6,0), Angle(0,-60,0), Angle(0,-27,0), --finger 2
    Angle(0,-35.8,0), Angle(0,-40.6,0), Angle(0,-45.1,0), --finger 3
    Angle(0,-32.3,-8.2), Angle(0,-34.4,0), Angle(0,-22.5,0), --finger 4
    --right hand closed angles
    Angle(-25,-6.9,-20.1), Angle(0,0,0), Angle(0,60,0), --finger 0
    Angle(10,0,15), Angle(0,-50,0), Angle(0,-47.9,0), --finger 1
    Angle(0,-33.6,0), Angle(0,-60,0), Angle(0,-27,0), --finger 2
    Angle(0,-35.8,0), Angle(0,-40.6,0), Angle(0,-45.1,0), --finger 3
    Angle(0,-32.3,-8.2), Angle(0,-34.4,0), Angle(0,-22.5,0), --finger 4
}

SWEP.LeftHandFingerAngles = {
    -- open
    Angle(0,0,0), Angle(0,-40,0), Angle(0,0,0), --finger 0
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 1
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 2
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0), --finger 3
    Angle(0,30,0), Angle(0,10,0), Angle(0,0,0),
    -- closed
    Angle(30,0,0), Angle(0,0,0), Angle(0,30,0),
    Angle(0,-50,-10), Angle(0,-90,0), Angle(0,-70,0),
    Angle(0,-35.-8,0), Angle(0,-80,0), Angle(0,-70,0),
    Angle(0,-26.5,4.8), Angle(0,-70,0), Angle(0,-70,0),
    Angle(0,-30,12.7), Angle(0,-70,0), Angle(0,-70,0),
}

SWEP.DefaultBodygroups = "000"

-- what are the names of the boneindices of the bone to shrink if current capacity is >= this number
SWEP.BulletBones = {
    [1] = "bullet"
}

-- like above but for guns that don't auto eject.
SWEP.CaseBones = {
}

-- like above but for machine gun belts
SWEP.BeltBones = {
}

SWEP.AlwaysShoot = false -- bypass slide checks
SWEP.CanLockBack = false -- slide automatically locks back when empty.
SWEP.MagCanDropFree = false -- magazine will auto eject when a new magazine is brought in.
SWEP.BoltCanAutoRelease = false -- when locked back, the bolt can automatically release 
SWEP.SlideNoAutoReciprocate = false -- slide will not automatically move back into place. e.g: Shotguns
SWEP.PumpAction = false -- slide will move in accordance with foregrip hand. NOTE: Parent "Foregrip" bone to "Slide" bone.
SWEP.CanDirectChamber = false -- internal magazine guns can chamber a round directly into the chamber, based on the "Chamber" bone.
SWEP.MustBeOpenToLoad = false -- gun must be fully locked back to load rounds.
SWEP.TwoHanded = false -- Weapon has a foregrip that can be gripped with the off hand.
SWEP.NonReciprocatingChargingHandle = false -- if true, chandle is the grippable charging handle
SWEP.CHandleRaise = false -- if true, the charging handle can be set into a "raised" latch, like the MP5.
SWEP.CHandleRaiseAtStart = false -- if true, the charging handle must be raised before it can be pulled back, like on a bolt-action rifle.
SWEP.HKSlap = false -- while the charging handle is raised, a fast downward motion will release it.
SWEP.TwoStageTrigger = false -- fully automatic fire modes require a full trigger press to activate full auto.
SWEP.PistolStabilize = false -- can stabilize like pistol even if two handed.
SWEP.PumpSlideOffset = nil -- override pump slide offset
SWEP.CycleDoesNotEject = false -- cycle does not eject empty chambered rounds
SWEP.MagEjectOnOpen = false -- mag ejects when empty and slide is fully opened
SWEP.ShootStraightFromMag = false -- if not open bolt, shoots straight from magazine
SWEP.AlwaysCycle = false -- always cycle the gun when fired
SWEP.BeltFed = false -- when a box magazine is inserted, a belt must be pulled out of the magazine and inserted into the gun to use it.
SWEP.DustCover = false -- gun has machine gun dust cover that must be raised to insert a belt
SWEP.SafetyBlocksSlide = false -- when the safety is on, the gun is limited to 0 - lockbackpos position slide

SWEP.HasStock = false -- weapon has virtual stock that can stabilize weapon near head

SWEP.BeltBullets = 15

SWEP.DustCoverLimitCCW = -90 -- one of these must be 0
SWEP.DustCoverLimitCW = 0
SWEP.DustCoverMinimums = 15 -- dust cover must be at least this open to do belt stuff
SWEP.DustCoverOffset = 90 -- offset for dust cover angle.

SWEP.TriggerPulledOffset = { -- the offset of the trigger bone when it is fully pulled.
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 25)
}

SWEP.HammerDownOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, -60)
}
SWEP.RevolverHammer = false -- hammer is not automatically cocked every time the slide cycles back

SWEP.VolleyFire = false
SWEP.VolleyFireAlwaysAdvance = false -- if true, chambers will always advance, even onto empty chambers.
-- Also allows the boneindex "cylinder" to revolve
SWEP.VolleyFireAutoEject = false -- if true, empty rounds will automatically eject from the gun.
SWEP.VolleyFireAutoEjectUnspent = false -- whether to autoeject unspent rounds.
SWEP.VolleyFireAlwaysFromChamberOne = false -- whether to always try all chambers for volley fire.
SWEP.VolleyFireRemoveDir = Vector(0, 0, -1) -- if true, which direction the gun has to be yanked to eject spent rounds.
SWEP.RevolverBoneRotAxis = Angle(0, 0, 1) -- which axis the revolver cylinder will revolve around
SWEP.VolleyFireFromOneBarrel = false -- revolvers, basically.
SWEP.VolleyFireBarrels = 0 -- how many barrels? assume muzzle names are muzzle1, muzzle2...
SWEP.VolleyFireBarrelToChamber = true -- barrel = chamber. Like a double barrel shotgun.
SWEP.BreakAction = false -- switch firemode button instead opens chamber.
SWEP.BreakActionOpenAng = Angle(0, 30, 0) -- what is the angle the chamber opens at
SWEP.BreakActionCloseVector = Vector(0, 0, 1) -- which direction the player needs to flick to close the chamber.
SWEP.EjectorTapOffset = Vector(0, 0, 1)

SWEP.Firemode = 1 -- 0 = safe, 1 = semi, 2 = auto, negative = burst
SWEP.Firemodes = nil -- {2, 1, 0}
-- table of firemodes this gun has. Don't put anything on it twice.

SWEP.RTScope = false -- weapon has an RT scope
SWEP.RTScopeSubmatIndex = 0 -- what is the submaterial index of the scope material?
SWEP.RTScopeFOV = 30 -- what is the field of view of the scope?
SWEP.RTScopeRes = 256 -- resolution
SWEP.RTScopeSurface = Material("effects/avr_rt") -- don't change this
SWEP.RTScopeOffset = Vector(0, 0, 0) -- position offset. Not generally needed.
SWEP.RTScopeReticle = nil

SWEP.Holosight = false -- weapon has holo sight
SWEP.HolosightReticle = nil -- Material("holosightreticle")
SWEP.HolosightDist = 32 -- Distance of the virtual image from the bone.
SWEP.HolosightSize = 3 -- Physical size of the virtual image.
SWEP.HolosightPiece = "" -- Model name of the model that's just the holosight glass.

SWEP.LaserSight = false -- whether the weapon has a laser sight. Laser emits from "laser" attachment.
SWEP.LaserSightColor = Color(255, 0, 0)
SWEP.LaserStrength = 1 -- multiplier to laser "power"

SWEP.StabilityFrames = 3 -- how many frames to average together in order to stabilize gun. More = more stable, but slower movement.
SWEP.PassiveStabilityFrames = 0
SWEP.WeightPenaltyFrames = 0 -- frames which average position but not angle. Basically makes the gun worse.

SWEP.ForegripOnPivot = false -- foregrip cannot be grabbed when chamber is open
SWEP.ForegripAngle = Angle(0, 0, 0)
SWEP.ForegripOffset = Vector(0, 1, -12)
SWEP.ReverseForegrip = false -- foregrip is behind main hand.
SWEP.CenterForegrip = true -- foregrip offset is visual and does not physically offset aim

SWEP.ForegripMins = Vector(-4, -3, -4) -- bounding boxes
SWEP.ForegripMaxs = Vector(4, 3, 4)

SWEP.DustCoverMins = Vector(-2, -2, -2)
SWEP.DustCoverMaxs = Vector(2, 2, 2)

SWEP.BeltMins = Vector(-2, -2, -2)
SWEP.BeltMaxs = Vector(2, 2, 2)

SWEP.SlideMins = Vector(-3, -0.6, -9)
SWEP.SlideMaxs = Vector(3, 4, 3)

SWEP.MagazineInsertMins = Vector(-3, -8, -3)
SWEP.MagazineInsertMaxs = Vector(3, 0, 3)

SWEP.DirectChamberMins = Vector(-1, -1, -2)
SWEP.DirectChamberMaxs = Vector(1, 1, 2)

SWEP.MagazineOffset = Vector(0, 0, 0) -- strictly for ejecting magazines
SWEP.MagazineAngleOffset = Angle(0, 0, 0)

SWEP.SlideDir = Vector(0, 0, -1) -- which direction is "back"? Generally doesn't need to be changed.
SWEP.CHandleRaiseDir = Vector(0, 1, 0) -- which direction is "up"? For bolt action rifles or HK SMGs.
SWEP.ReverseSlide = false -- weapon blows forward

SWEP.CHandleBone = nil
SWEP.CHandleRaisedOffset = { -- offset for the charging handle in the "up" position if it can be raised.
    -- basically, what does it look like when raised? Make sure not to set the axis in which the slide travels backward.
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0)
}

SWEP.SlideLockbackAmount = 1.35 -- the distance back the slide should go when locked back.
SWEP.SlideBlowbackAmount = 1.5 -- despite the name, this is simply how far the slide/bolt/whatever can travel backward.
SWEP.ChargingHandlePullAmount = nil -- set in order to make the charging handle move an independent distance from the slide/bolt.

SWEP.FullBackOffset = nil -- offset applied to bones when slide fully back
-- {["chandle"] = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}}

SWEP.BoneIndices = nil
-- {mag = 1, selector = 2...}
-- IMPORTANT!!!
-- Names ArcVR uses are:
-- "slide": The bolt/slide of the gun
-- "chandle": Charging handle, used for independent charging handle behaviour
-- "mag": Magazine bone, used for inserting/removing magazines
-- "bullet": Will be disappeared if the gun is not chambered
-- "cylinder": will rotate according to volley fire index

SWEP.FireSelectPoses = nil
-- {[bonename] = {pos = Vector(), ang = Angle()}}

SWEP.SlidelockActivePose = nil

SWEP.FireSelectPoses = {
    -- [2] = {
    --     selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
    --     safety = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
    -- },
    -- [1] = {
    --     selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 179)},
    --     safety = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
    -- },
    -- [0] = {
    --     selector = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
    --     safety = {pos = Vector(0, 0, -0.5), ang = Angle(0, 0, 0)}
    -- },
    -- [firemode] = {
    --      indexbone = {pos = Vector(), ang = Angle()},
    --      ...
    -- }
}

-- stuff you should edit ends here.
-- don't touch these.
SWEP.MiscLerps = {
}

SWEP.TargetMiscLerps = {
}
SWEP.NextCanSpawnMagTime = 0
SWEP.BurstLength = 0
SWEP.SlideGrabbed = false
SWEP.SlideReleasing = false
SWEP.CHandlePos = 0
SWEP.SlidePos = 0
SWEP.SlideLockedBack = false
SWEP.NeedAnotherTriggerPull = false
SWEP.LastSlidePos = 0
SWEP.RecoilAngles = Angle(0, 0, 0)
SWEP.RecoilBlowback = 0
SWEP.ForegripGrabbed = false
SWEP.EmptyChambered = 0
SWEP.CHandleRaisePos = 0
SWEP.LastCHandleRaisePos = 0
SWEP.BreakActionChamberOpen = false
SWEP.VolleyFireIndex = 1
SWEP.VolleyFireBarrelIndex = 1
SWEP.VolleyFireChambers = {} -- [1] = 0, 1, 2;
-- 0: not loaded
-- 1: empty case
-- 2: loaded
SWEP.BoneTaps = {} -- [bone] = endtaptime
SWEP.HammerDown = false
SWEP.ClientInitialized = false
SWEP.BeltGrabbed = false
SWEP.BeltAmountIn = 0
SWEP.DustCoverPos = 0
SWEP.NextAttachmentTime = 0

end

function SWEP:PrimaryAttack()
    return
end

function SWEP:SecondaryAttack()
    return
end

function SWEP:Reload()
    return
end

function SWEP:Initialize()
    if CLIENT and self.ClientInitialized then return end

    for i, k in pairs(self.Attachments) do
        if !k.Default then continue end

        k.Installed = k.Default
        local atttbl = ArcticVR.AttachmentTable[k.Default]

        if atttbl.AttachFunc then
            atttbl.AttachFunc(self)
        end
    end

    self.ClientInitialized = true
end

function SWEP:PlayNetworkedSound(sindex, soundn)
    sindex = sindex or table.KeyFromValue(self.NetworkedSounds, soundn)

    if sindex then
        local vol = 75
        local chan = CHAN_AUTO

        if sindex == 1 or sindex == 2 then
            vol = self.ShotVolume
            chan = CHAN_WEAPON

            vol = vol * self:GetBuff("Buff_ShotVolume")

            vol = math.Clamp(vol, 51, 149)
        end

        local sname = self.NetworkedSounds[sindex]
        local spath = self[sname]

        if CLIENT then
            local vm = g_VR.viewModel
            if(chan == CHAN_WEAPON) then
                vm = self.Owner
            end
            vm:EmitSound(spath, vol, 100, 1, chan)

            if sname == "" then return end

            net.Start("avr_playsound")
            net.WriteUInt(sindex, 8)
            net.SendToServer()
        else
            SuppressHostEvents(self.Owner)
            self:EmitSound(spath, vol, 100, 1, chan)
            SuppressHostEvents(NULL)
        end
    end
end

function SWEP:Cycle(blank)
    blank = blank or false
    if CLIENT then
        local vm = g_VR.viewModel

        if !vm then return end
        if !IsValid(vm) then return end


        local msbf = self.MeanShotsBetweenJams
        if !self.OpenBolt and msbf != 0 and 1 / msbf > math.Rand(0, 1) then
            -- JAM
            return
        end
		
		

        if blank and self.Chambered > 0 then
            if self.BulletEffect then
                local fx2 = EffectData()
                fx2:SetAttachment(2)
                fx2:SetMagnitude(150)
                fx2:SetNormal(Vector(0, 0, 0))
                fx2:SetEntity(vm)
                util.Effect(self.BulletEffect, fx2)
            end
        end

        if !self.CycleDoesNotEject and self.EmptyChambered > 0 then
            if self.CaseEffect then
                local fx2 = EffectData()
                fx2:SetAttachment(2)
                fx2:SetMagnitude(150)
                fx2:SetNormal(Vector(0, 0, 0))
                fx2:SetEntity(vm)
                util.Effect(self.CaseEffect, fx2)
            end

            self.EmptyChambered = self.EmptyChambered - 1
        end
    end

    if self.OpenBolt or self.ShootStraightFromMag then
        if self.LoadedRounds > 0 then
            self.LoadedRounds = self.LoadedRounds - 1
        end
    else
        if self.LoadedRounds > 0 then
            self.Chambered = 1
            self.LoadedRounds = self.LoadedRounds - 1
        else
            self.Chambered = 0
            self.LoadedRounds = 0
        end
    end

    if self.LoadedRounds <= 0 and self.DisintegratingMagazine then
        self.Magazine = nil
        if CLIENT then
            SafeRemoveEntity(ArcticVR.CSMagazine)
        end
    end
end