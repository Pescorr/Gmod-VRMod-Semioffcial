ArcticVR.MatPenMultTable = {
   [MAT_ANTLION] = 0.3,
   [MAT_BLOODYFLESH] = 6,
   [MAT_CONCRETE] = 0.45,
   [MAT_DIRT] = 0.2,
   [MAT_EGGSHELL] = 0.1,
   [MAT_FLESH] = 0.2,
   [MAT_GRATE] = 0.25,
   [MAT_ALIENFLESH] = 6,
   [MAT_CLIP] = 1000,
   [MAT_SNOW] = 0.2,
   [MAT_PLASTIC] = 0.1,
   [MAT_METAL] = 1,
   [MAT_SAND] = 0.2,
   [MAT_FOLIAGE] = 0.25,
   [MAT_COMPUTER] = 0.25,
   [MAT_SLOSH] = 0.25,
   [MAT_TILE] = 1,
   [MAT_GRASS] = 0.2,
   [MAT_VENT] = 0.5,
   [MAT_WOOD] = 0.25,
   [MAT_DEFAULT] = 0.2,
   [MAT_GLASS] = 0.2,
   [MAT_WARPSHIELD] = 1
}

local pentracelen = 4

function ArcticVR:BulletPenetrate(tr, bullet)
   if tr.HitSky then return end

   if tr.DispFlags != 0 then return end

   if tr.Entity:IsNPC() or tr.Entity:IsPlayer() then return end

   if bullet.vel <= 0 then return end

   local penmult = ArcticVR.MatPenMultTable[tr.MatType] or 1

   if !tr.HitWorld then
      penmult = penmult * 1.25
   end

   penmult = penmult * math.Rand(0.8, 1.2) * math.Rand(0.8, 1.2)

   local dir = bullet.dir:GetNormalized()
   local endpos = tr.HitPos

   local ptr = util.TraceLine({
      start = endpos,
      endpos = endpos + (dir * pentracelen),
      mask = MASK_SHOT
   })

   local vel = bullet.vel
   local penleft = bullet.penleft

   penleft = penleft - 1

   while penleft > 0 and vel > 0 and (!ptr.StartSolid or ptr.AllSolid) and ptr.Fraction < 1 do
      penleft = penleft - (pentracelen * penmult)
      bullet.disttravelled = bullet.disttravelled + (pentracelen * penmult * 10)
      vel = vel - (vel * vel * (1 / 15000) * penmult * penmult)

      ptr = util.TraceLine({
         start = endpos,
         endpos = endpos + (dir * pentracelen),
         mask = MASK_SHOT
      })

      debugoverlay.Line(endpos, endpos + (dir * pentracelen), 5, Color(255,255,255), true)

      endpos = endpos + (dir * pentracelen)
   end

   if penleft > 0 and vel > pentracelen and bullet.disttravelled < bullet.maxrange then
      --print("bullet penetrated with " .. penleft .. "mm pen left")
      --print(vel)
      if (dir:Length() == 0) then return end
      ArcticVR:ShootPhysicalBullet(endpos, dir:Angle(), vel, bullet.appearance, bullet.mindamage, bullet.maxdamage, bullet.maxrange, bullet.inflictor, bullet.attacker, penleft, bullet.callback, bullet.disttravelled, bullet.lifetime)

      if !bullet.attacker then return end

      bullet.attacker:FireBullets({
         Damage = 0,
         Src = endpos,
         Dir = -dir,
         Distance = pentracelen * 2,
         Tracer = 0,
         Force = 0
      }, true)
   --else
      --print("bullet stopped")
   end
end