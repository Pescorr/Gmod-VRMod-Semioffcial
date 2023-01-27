ArcticVR = ArcticVR or {}

ArcticVR.ShellSoundsTable_556 = {
    "arcvr_ins2/bullets/shells/concrete/9mm_shell_concrete_01.wav",
    "arcvr_ins2/bullets/shells/concrete/9mm_shell_concrete_02.wav",
    "arcvr_ins2/bullets/shells/concrete/9mm_shell_concrete_03.wav",
    "arcvr_ins2/bullets/shells/concrete/9mm_shell_concrete_04.wav",
    "arcvr_ins2/bullets/shells/concrete/9mm_shell_concrete_05.wav",
    "arcvr_ins2/bullets/shells/concrete/9mm_shell_concrete_06.wav",
}

ArcticVR.ShellSoundsTable_12g = {
    "arcvr_ins2/bullets/shells/concrete/shotgun_shell_concrete_01.wav",
    "arcvr_ins2/bullets/shells/concrete/shotgun_shell_concrete_02.wav",
    "arcvr_ins2/bullets/shells/concrete/shotgun_shell_concrete_03.wav",
    "arcvr_ins2/bullets/shells/concrete/shotgun_shell_concrete_04.wav",
    "arcvr_ins2/bullets/shells/concrete/shotgun_shell_concrete_05.wav",
    "arcvr_ins2/bullets/shells/concrete/shotgun_shell_concrete_06.wav",
}

ArcticVR.ShellSoundsTable_Flare = {
    "arcvr_ins2/bullets/shells/concrete/flare_shell_concrete_01.wav",
    "arcvr_ins2/bullets/shells/concrete/flare_shell_concrete_02.wav",
    "arcvr_ins2/bullets/shells/concrete/flare_shell_concrete_03.wav",
    "arcvr_ins2/bullets/shells/concrete/flare_shell_concrete_04.wav",
}

ArcticVR.ShellSoundsTable_40mm = {
    "arcvr_ins2/bullets/shells/concrete/m203_shell_concrete_01.wav",
    "arcvr_ins2/bullets/shells/concrete/m203_shell_concrete_02.wav",
    "arcvr_ins2/bullets/shells/concrete/m203_shell_concrete_03.wav",
    "arcvr_ins2/bullets/shells/concrete/m203_shell_concrete_04.wav",
}

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_556", "models/weapons/arcticvr_ins2/556case.mdl", 96, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_556", "models/weapons/arcticvr_ins2/556round.mdl", 101, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_545", "models/weapons/arcticvr_ins2/545case.mdl", 93, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_545", "models/weapons/arcticvr_ins2/545round.mdl", 96, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_762wp", "models/weapons/arcticvr_ins2/762wpcase.mdl", 90, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_762wp", "models/weapons/arcticvr_ins2/762wpbullet.mdl", 92, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_9mm", "models/weapons/arcticvr_ins2/9mmcase.mdl", 100, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_9mm", "models/weapons/arcticvr_ins2/9mmround.mdl", 103, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_308", "models/weapons/arcticvr_ins2/556case.mdl", 80, ArcticVR.ShellSoundsTable_556, 1.15, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_308", "models/weapons/arcticvr_ins2/556round.mdl", 85, ArcticVR.ShellSoundsTable_556, 1.15, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_shell_ins2_12g", "models/weapons/arcticvr_ins2/12g_shell.mdl", 100, ArcticVR.ShellSoundsTable_12g, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_76254r", "models/weapons/arcticvr_ins2/76254rcase.mdl", 75, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_76254r", "models/weapons/arcticvr_ins2/76254rround.mdl", 80, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_38spc", "models/weapons/arcticvr_ins2/38case.mdl", 100, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_38spc", "models/weapons/arcticvr_ins2/38round.mdl", 103, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_308_s", "models/weapons/arcticvr_ins2/308case_single.mdl", 75, ArcticVR.ShellSoundsTable_556, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_bullet_ins2_308_s", "models/weapons/arcticvr_ins2/308round_single.mdl", 80, ArcticVR.ShellSoundsTable_556, 1, nil, true)

ArcticVR.RegisterCustomShell("arcticvr_case_ins2_p2", "models/weapons/arcticvr_ins2/p2case.mdl", 100, ArcticVR.ShellSoundsTable_556, 1, nil, true)

game.AddParticles( "particles/muzzleflashes_test.pcf" )
game.AddParticles( "particles/muzzleflashes_test_b.pcf" )
PrecacheParticleSystem( "muzzleflash_smg" )
PrecacheParticleSystem( "muzzleflash_bizon" )
PrecacheParticleSystem( "muzzleflash_shotgun" )
PrecacheParticleSystem( "muzzleflash_slug" )
PrecacheParticleSystem( "muzzleflash_pistol" )
PrecacheParticleSystem( "muzzleflash_suppressed" )
PrecacheParticleSystem( "muzzleflash_mp5" )
PrecacheParticleSystem( "muzzleflash_MINIMI" )
PrecacheParticleSystem( "muzzleflash_m79" )
PrecacheParticleSystem( "muzzleflash_m14" )
PrecacheParticleSystem( "muzzleflash_ak74" )
PrecacheParticleSystem( "muzzleflash_m82" )
PrecacheParticleSystem( "muzzleflash_m3" )
PrecacheParticleSystem( "muzzleflash_1" )
PrecacheParticleSystem( "muzzleflash_3" )
PrecacheParticleSystem( "muzzleflash_4" )
PrecacheParticleSystem( "muzzleflash_5" )
PrecacheParticleSystem( "muzzleflash_6" )

if CLIENT then

local PhoneFont = "NinePin"

surface.CreateFont( "ArcVR_Phone_16", {
    font = PhoneFont,
    size = 16,
    weight = 0,
    additive = false,
    scanlines = 0,
    antialias = true,
} )

surface.CreateFont( "ArcVR_Phone_32", {
    font = PhoneFont,
    size = 32,
    weight = 0,
    additive = false,
    scanlines = 0,
    antialias = true,
} )

end