ArcticVR = ArcticVR or {}

ArcticVR.PhysBullets = {}
ArcticVR.BulletLifeTime = 15

ArcticVR.PenProbeLength = 4

if CLIENT then
   ArcticVR.TracerMat = Material("effects/white_tracer")
else
   util.AddNetworkString( "ArcticVR_ShootPhysBullet" )
end

if CLIENT then
   net.Receive("ArcticVR_ShootPhysBullet", function()
      local pos = net.ReadVector()
      local ang = net.ReadAngle()
      local vel = net.ReadFloat()
      local appearance = net.ReadTable()

      --print("Hmmm")

      ArcticVR:ShootPhysicalBullet(pos, ang, vel, appearance)
   end)
end

function ArcticVR:ShootPhysicalBullet(pos, ang, vel, appearance, mindamage, maxdamage, maxrange, inflictor, attacker, penleft, callback, disttravelled, lifetime)
   local bullet = {
      pos = pos,
      lastpos = pos,
      dir = ang:Forward() * vel,
      vel = vel,
      mindamage = mindamage or 0,
      maxdamage = maxdamage or 0,
      maxrange = maxrange or 1,
      inflictor = inflictor or NULL,
      attacker = attacker or NULL,
      lifetime = lifetime or 0,
      disttravelled = disttravelled or 0,
      callback = callback,
      appearance = appearance,
      penleft = penleft or 0,
      underwater = false,
   }

   if bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER then
      bullet.underwater = true
   end

   --print(lifetime)
   --print(disttravelled)

   --print(table.Count(ArcticVR.PhysBullets))

   table.insert(ArcticVR.PhysBullets, bullet)

   --PrintTable(ArcticVR.PhysBullets)

   if SERVER then
      net.Start("ArcticVR_ShootPhysBullet")
      net.WriteVector(pos)
      net.WriteAngle(ang)
      net.WriteFloat(vel)
      net.WriteTable(appearance)
      net.Broadcast()
   end
end

function ArcticVR:ProcessPhysicalBullets()
   local gravity = Vector(0, 0, -600 * FrameTime())

   for i, bullet in pairs(ArcticVR.PhysBullets) do
      local pos = bullet.pos
      bullet.lastpos = pos
      local dir = bullet.dir:GetNormalized()
      local vel = bullet.dir:Length()

      local drag = -dir * vel * vel * (1 / 15000) * FrameTime() * 2

      bullet.dir = bullet.dir + drag + gravity

      bullet.vel = bullet.dir:Length()

      local newpos = pos + (FrameTime() * bullet.dir)

      if bullet.visualonly then
         bullet.pos = newpos
         bullet.lifetime = bullet.lifetime + FrameTime()
         if bullet.lifetime >= ArcticVR.BulletLifeTime then
            table.remove(ArcticVR.PhysBullets, i)
         end
         continue
      end

      local delta = math.Clamp((bullet.maxrange - bullet.disttravelled) / bullet.maxrange, 0, 1)
      local dmg = Lerp(delta, bullet.mindamage, bullet.maxdamage)

      --print(newpos)

      local filter = bullet.attacker

      if CLIENT then
         filter = LocalPlayer()
      end

      if bullet.attacker and bullet.attacker:IsPlayer() then
         bullet.attacker:LagCompensation(true)
      end

      local btr = util.TraceLine({
         start = pos,
         endpos = newpos,
         mask = MASK_SHOT,
         filter = filter
      })

      if bit.band( util.PointContents( newpos ), CONTENTS_WATER ) == CONTENTS_WATER and !bullet.underwater then
         -- bullet entered water
         local wtr = util.TraceLine({
               start = bullet.pos,
               endpos = newpos,
               mask = MASK_WATER
         })

         if wtr.Hit then
               local fx = EffectData()
               fx:SetOrigin(wtr.HitPos)
               fx:SetScale((dmg / 5) + 2)
               util.Effect("gunshotsplash", fx)

               bullet.underwater = true
         end
      elseif bullet.underwater then
         -- bullet exited water

         local wtr = util.TraceLine({
               start = newpos,
               endpos = bullet.pos,
               mask = MASK_WATER
         })

         if !wtr.Hit then
               local fx = EffectData()
               fx:SetOrigin(wtr.HitPos)
               fx:SetScale((dmg / 5) + 2)
               util.Effect("gunshotsplash", fx)

               bullet.underwater = false
         end
      end

      -- if SERVER then
      --    print((pos - newpos):Length())
      --    print((btr.StartPos - btr.HitPos):Length())
      -- end

      debugoverlay.Line(pos, btr.HitPos, 5, Color( 255, 0, 0 ), true)

      bullet.lifetime = bullet.lifetime + FrameTime()
      bullet.disttravelled = bullet.disttravelled + (btr.StartPos - btr.HitPos):Length()

      if btr.HitSky then
         bullet.visualonly = true
         bullet.pos = newpos
         bullet.lifetime = 0
      elseif btr.Hit then
         table.remove(ArcticVR.PhysBullets, i)
         if SERVER then
            --print(bullet.disttravelled)
            if !IsValid(bullet.attacker) then return end
            --print(dmg)
            bullet.attacker:FireBullets({
               Attacker = bullet.attacker,
               Damage = dmg,
               Force = dmg / 3,
               Distance = vel * FrameTime(),
               Num = 1,
               Tracer = 0,
               Dir = bullet.dir,
               Src = bullet.pos,
               Callback = function(battacker, tr, dmginfo)
                  if bullet.callback then
                     bullet.callback(battacker, tr, dmginfo)
                  end

                  ArcticVR:BulletPenetrate(tr, bullet)
               end
            })
         end
      else
         bullet.pos = newpos
         bullet.lifetime = bullet.lifetime + FrameTime()
         if bullet.lifetime >= ArcticVR.BulletLifeTime then
            table.remove(ArcticVR.PhysBullets, i)
         elseif math.abs(bullet.pos.x) > 16384 or math.abs(bullet.pos.y) > 16384 or math.abs(bullet.pos.z) > 16384 then
            table.remove(ArcticVR.PhysBullets, i)
         end
      end

   end
end

hook.Add("Think", "ArcticVR.ProcessPhysicalBullets", ArcticVR.ProcessPhysicalBullets)

function ArcticVR:DrawPBullets()
   for i, bullet in pairs(ArcticVR.PhysBullets) do
      --local pos = bullet.pos
      --local dir = bullet.dir:GetNormalized()
      local alpha = math.Clamp((bullet.disttravelled - 128) / 1000, 0, 1)
      local col = Color(bullet.appearance.c.r * alpha, bullet.appearance.c.g * alpha, bullet.appearance.c.b * alpha)
      --print(col)
      --local len = bullet.appearance.l
      local width = bullet.appearance.w
      --local endpos = pos - (dir * len)

      local endpos = bullet.pos + ((bullet.lastpos - bullet.pos):GetNormalized() * 350)

      render.SetMaterial(ArcticVR.TracerMat)
      render.DrawBeam(bullet.pos, endpos, width, 0, 1, col)
   end
end

hook.Add("PreDrawEffects", "ArcticVR.DrawPBullets", ArcticVR.DrawPBullets)

hook.Add("PostCleanupMap", "ArcticVR.CleanUpMap", function()
    ArcticVR.PhysBullets = {}
end)