ArcticVR = ArcticVR or {}

ArcticVR.ShellSoundsTable = {
    "arcticvr/shell/shell_1.wav",
    "arcticvr/shell/shell_2.wav",
    "arcticvr/shell/shell_3.wav",
    "arcticvr/shell/shell_4.wav",
    "arcticvr/shell/shell_5.wav",
    "arcticvr/shell/shell_6.wav",
    "arcticvr/shell/shell_7.wav",
    "arcticvr/shell/shell_8.wav",
    "arcticvr/shell/shell_9.wav",
    "arcticvr/shell/shell_10.wav",
    "arcticvr/shell/shell_11.wav",
}

ArcticVR.ShotgunShellSoundsTable = {
    "weapons/fx/tink/shotgun_shell1.wav",
    "weapons/fx/tink/shotgun_shell2.wav",
    "weapons/fx/tink/shotgun_shell3.wav"
}

local case = {}

case.Sounds = {}
case.Pitch = 90
case.Scale = 1.5
case.Model = nil
case.Material = nil
case.JustOnce = false
case.AlreadyPlayedSound = false

case.SpawnTime = 0

function case:Init(data)

    local att = data:GetAttachment()
    local ent = data:GetEntity()
    local mag = data:GetMagnitude()

    local origin, ang = ent:GetAttachment(att).Pos, ent:GetAttachment(att).Ang

    local dir = data:GetNormal()

    if dir:Length() == 0 then
        ang:RotateAroundAxis(ang:Up(), 100)
        dir = ang:Right()
    end

    self:SetPos(origin)
    self:SetModel(self.Model)
    self:SetModelScale(self.Scale)
    self:DrawShadow(false)
    self:SetAngles(ang)

    if self.Material then
        self:SetMaterial(self.Material)
    end

    local pb_vert = 2 * self.Scale
    local pb_hor = 0.5 * self.Scale

    self:PhysicsInitBox(Vector(-pb_vert,-pb_hor,-pb_hor), Vector(pb_vert,pb_hor,pb_hor))

    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
    self:SetCollisionBounds(Vector(-2 -2, -2), Vector(2, 2, 2))

    local phys = self:GetPhysicsObject()

    phys:Wake()
    phys:SetDamping(0, 5)
    phys:SetMaterial("gmod_silent")

    phys:SetVelocity(dir * mag * math.Rand(1, 2))
    phys:AddAngleVelocity(VectorRand() * 400)

    self.HitPitch = self.Pitch + math.Rand(-5,5)

    self.SpawnTime = CurTime()
end

function case:PhysicsCollide()
    if self.AlreadyPlayedSound and self.JustOnce then return end

    sound.Play(self.Sounds[math.random(#self.Sounds)], self:GetPos(), 65, self.HitPitch, 1)

    self.AlreadyPlayedSound = true
end

function case:Think()
    if (self.SpawnTime + 4) <= CurTime() then
        self:SetRenderFX( kRenderFxFadeFast )
        if (self.SpawnTime + 5) <= CurTime() then
            return false
        end
    end
    return true
end

function case:Render()
    self:DrawModel()
end

function ArcticVR.RegisterCustomShell(name, model, pitch, sounds, scale, material, justonce)
    if SERVER then return end

    local eff = table.Copy(case)

    eff.Model = model
    eff.Pitch = pitch or 100
    eff.Sounds = sounds or ArcticVR.ShellSoundsTable
    eff.Scale = scale or 1
    eff.Material = material or nil
    eff.JustOnce = justonce or false

    effects.Register(eff, name)
end

ArcticVR.RegisterCustomShell("arcticvr_case_9x19", "models/weapons/arcticvr/aniv/9mmcase.mdl", 105, ArcticVR.ShellSoundsTable, 1)
ArcticVR.RegisterCustomShell("arcticvr_case_9x19_alt", "models/weapons/arcticvr/aniv/9mmcase_alt.mdl", 105, ArcticVR.ShellSoundsTable, 1)
ArcticVR.RegisterCustomShell("arcticvr_bullet_9x19", "models/weapons/arcticvr/aniv/9mmbullet.mdl", 110, ArcticVR.ShellSoundsTable, 1)

ArcticVR.RegisterCustomShell("arcticvr_case_50ae", "models/weapons/arcticvr/aniv/50aecase.mdl", 80, ArcticVR.ShellSoundsTable, 1)
ArcticVR.RegisterCustomShell("arcticvr_bullet_50ae", "models/weapons/arcticvr/aniv/50aebullet.mdl", 90, ArcticVR.ShellSoundsTable, 1)

-- ArcticVR.RegisterCustomShell("arcticvr_shell_12g", "models/weapons/arcticvr/aniv/12gshell.mdl", 100, ArcticVR.ShotgunShellSoundsTable, 1, nil, true)
 
ArcticVR.RegisterCustomShell("arcticvr_shell_12g", "models/weapons/arcticvr/aniv/shellfull.mdl", 100, ArcticVR.ShotgunShellSoundsTable, 1, nil, true)
ArcticVR.RegisterCustomShell("arcticvr_shellspent_12g", "models/weapons/arcticvr/aniv/shellempty.mdl", 110, ArcticVR.ShotgunShellSoundsTable, 1, nil, true)