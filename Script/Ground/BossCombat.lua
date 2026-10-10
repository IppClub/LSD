-- Big Taotie from the original authored requirements. This asset has no attack events;
-- impact windows are calibrated against native frozen Spine poses, not animation start.
local D=require("Dora")
local P=D.Platformer
local Animation=require("CombatAnimation")
local Combat={}; Combat.__index=Combat
local specs={
 trample={label="前肢拍击",impact=0.6,range=340,damage=20,knockX=480,knockY=1080},
 swing={label="后方尾击",impact=1.0,range=480,damage=20,knockX=1100,knockY=400,rear=true,multi=true},
 pounce={label="前扑攻击",impact=1.5,range=360,damage=20,knockX=900,knockY=850,multi=true},
 shot={label="机枪扫射",damage=8,shots={0.8,1.1,1.4}},
 rush={label="野蛮冲撞",damage=24,range=230,knockX=1200,knockY=650,multi=true},
}
Combat.specs=specs
function Combat:targets()
 local a=self.arena
 local rows={{unit=a.student,alive=function()return a.studentHP>0 end,damage=function(n) a.studentHP=math.max(0,a.studentHP-n); a.metrics.damageTaken=a.metrics.damageTaken+n end}}
 for _,target in ipairs(a.extraEnemyTargets or {}) do rows[#rows+1]=target end
 return rows
end
function Combat:damage(target,spec,strike,direction)
 target.damage(spec.damage); strike.damage=strike.damage+spec.damage
 if (spec.knockX or spec.knockY) and not target.immovable then
  require('Combat.Displacement').apply(target,direction*(spec.knockX or 0),spec.knockY,strike)
 elseif not target.immovable then
  require('Combat.Displacement').apply(target,0,nil,strike)
 end
end
function Combat:reset()
 self.index=0; self.stage=nil; self.stageDone=false; self.rushLoops=0;self.approaching=false
 self.arena.enemyStrike=nil; self.arena.enemyAttacks={}; self.arena.studentStaggerUntil=0
end
function Combat:play(name,loop)
 self.stage=name; self.stageDone=false
 local duration=Animation.play(self.arena.enemy,name,loop)
 assert(duration>0,"Missing boss animation "..name)
 return duration
end
function Combat:start(kind,target,keepFacing)
 local a=self.arena
 if a.enemyPhase=="attack" or not specs[kind] or a.enemyHP<=0 or a.studentHP<=0 then return false end
 if not keepFacing then a.enemy.faceRight=(target and target.unit.x or a.student.x)>=a.enemy.x end
 a.enemy.velocityX=0; a.enemyPhase="attack"
 self.rushLoops=0
 local strike={kind=kind,startedAt=D.App.runningTime,direction=a.enemy.faceRight and 1 or -1,damage=0,hitTargets={},shots=0,stages={}}
 if target then strike.selectedDistance=math.abs(target.unit.x-a.enemy.x);strike.selection='distance';strike.selectedTarget=target.unit.entity.name end
 a.enemyStrike=strike; a.enemyAttacks[#a.enemyAttacks+1]=strike
 strike.duration=self:play(kind); strike.stages[#strike.stages+1]={name=kind,startedAt=strike.startedAt,duration=strike.duration}
 return true
end
function Combat:nearestMobileTarget()
 local target,distance=nil,math.huge
 for _,row in ipairs(self:targets())do
  local gap=math.abs(row.unit.x-self.arena.enemy.x)
  if not row.immovable and (not row.alive or row.alive()) and gap<distance then target,distance=row,gap end
 end
 return target,distance
end
function Combat:chooseSkill(target,distance)
 if not target then return end
 local a=self.arena;local rear=(target.unit.x>=a.enemy.x)~=a.enemy.faceRight
 local level=math.abs(target.unit.y-a.enemy.y)<260
 local usable={trample=level and distance<=340,swing=level and rear and distance<=480,
  pounce=level and distance>300 and distance<=540,shot=level and distance>=450 and distance<=1250,
  rush=level and distance>=400 and distance<=1000}
 -- Continue round-robin among usable skills; never restart an active timeline.
 for offset=1,#self.skills do
  local i=(self.index+offset-1)%#self.skills+1;local kind=self.skills[i]
  if usable[kind]then self.index=i;return kind end
 end
end
function Combat:approach(target,distance)
 local a=self.arena;local speed=a.enemySpeed or 0;local u=a.enemy
 if not target or speed<=0 then u.velocityX=0;return end
 local direction=target.unit.x>=u.x and 1 or -1
 local edge=direction<0 and u.x<=(a.minX or -math.huge)+5 or direction>0 and u.x>=(a.maxX or math.huge)-5
 -- Hysteresis avoids restarting the locomotion loop at a single threshold.
 if self.approaching then self.approaching=distance>480 else self.approaching=distance>560 end
 if edge then self.approaching=false end
 u.faceRight=direction>0;u.velocityX=self.approaching and speed*direction or 0
 local animation=self.approaching and 'fmove' or u.data.combatRest
 if u.playable.current~=animation then Animation.play(u,animation,true)end
end
function Combat:melee(strike)
 local a=self.arena; local spec=specs[strike.kind]; local direction=spec.rear and -strike.direction or strike.direction
 strike.attackAt=strike.attackAt or D.App.runningTime
 for _,target in ipairs(self:targets()) do
  local delta=target.unit.x-a.enemy.x
  if not strike.hitTargets[target.unit] and math.abs(delta)<=spec.range and math.abs(target.unit.y-a.enemy.y)<260 and (strike.kind=="rush" or (delta*direction>=0)) then
   strike.hitTargets[target.unit]=true; self:damage(target,spec,strike,direction)
   if not spec.multi then break end
  end
 end
end
function Combat:shoot(strike)
 local a=self.arena; local spec=specs.shot
 strike.shots=strike.shots+1; strike.attackAt=strike.attackAt or D.App.runningTime
 local def=P.BulletDef(); def.lifeTime=1.6; def.highSpeedFix=true; def.gravity=D.Vec2.zero; def:setAsCircle(10); def:setVelocity(0,850)
 def.face=P.Face(function() local n=D.DrawNode(); n:drawDot(D.Vec2.zero,9,D.Color(0xffffb65b)); return n end)
 local bullet=P.Bullet(def,a.enemy); local allow=P.TargetAllow(); allow:allow("Enemy",true); allow.terrainAllowed=false; bullet.targetAllow=allow:toValue()
 bullet.position=a.enemy.position+D.Vec2(strike.direction*185,-70+(strike.shots-1)*30)
 bullet:slot("HitTarget",function(projectile,target)
  if not a.closed and (a.mode=="trial" or a.mode=="demo") and a.enemyHP>0 then
   for _,row in ipairs(self:targets()) do if row.unit==target then self:damage(row,spec,strike,strike.direction); strike.projectileHits=(strike.projectileHits or 0)+1; break end end
  end
  projectile.hitStop=true
 end)
 bullet:addTo(a.world); a.projectiles[#a.projectiles+1]=bullet
end
function Combat:update(now)
 local a=self.arena
 if a.closed or a.studentHP<=0 or a.enemyHP<=0 then a.enemy.velocityX=0; return end
 if a.enemyPhase=="attack" then
  local s=a.enemyStrike; local spec=specs[s.kind]; local age=now-s.startedAt
  if s.kind=="rush" then
   if self.stageDone and (self.stage=="rush" or self.stage=="rush1") then
    local nextName=self.stage=="rush" and "rush1" or "rush2"
    local duration=self:play(nextName,nextName=="rush2")
    s.stages[#s.stages+1]={name=nextName,startedAt=now,duration=duration}
   elseif self.stage=="rush2" then
    a.enemy.velocityX=s.direction*400; self:melee(s)
    if self.rushLoops>=3 then
     a.enemy.velocityX=0; local duration=self:play("rush3")
     s.stages[#s.stages+1]={name="rush3",startedAt=now,duration=duration}
    end
   elseif self.stage=="rush3" and self.stageDone then s.completedAt=now end
  else
   if s.kind=="pounce" then a.enemy.velocityX=age>=0.85 and age<1.5 and s.direction*300 or 0 end
   if spec.impact and age>=spec.impact and not s.hit then s.hit=true; self:melee(s) end
   if s.kind=="shot" and s.shots<#spec.shots and age>=spec.shots[s.shots+1] then self:shoot(s) end
   if self.stageDone then s.completedAt=s.completedAt or now end
  end
  if s.completedAt then a.enemy.velocityX=0; a.enemyPhase="recover"; a.nextEnemy=now+1.1; Animation.rest(a.enemy) end
 elseif now>=a.nextEnemy then
  if a.enemyPhase=="recover" then a.enemyPhase="idle"; a.nextEnemy=now+1.2
  elseif a.enemySpeed and a.enemySpeed>0 then
   local target,distance=self:nearestMobileTarget();local kind=self:chooseSkill(target,distance)
   if kind then self:start(kind,target,kind=='swing')else self:approach(target,distance)end
  else self.index=self.index%#self.skills+1; self:start(self.skills[self.index]) end
 elseif a.enemySpeed and a.enemyPhase=="idle" then
  self:approach(self:nearestMobileTarget())
 end
end
function Combat.new(arena,skills)
 local self=setmetatable({arena=arena,skills=skills or {"trample","swing","pounce","shot","rush"}},Combat)
 for _,kind in ipairs(self.skills) do assert(specs[kind],"Unknown boss skill") end
 assert(#self.skills>0)
 arena.enemy.playable:slot("AnimationEnd",function(name)
  if arena.enemyPhase~="attack" or name~=self.stage then return end
  local s=arena.enemyStrike
  if name=="rush2" then self.rushLoops=self.rushLoops+1; s.rushLoops=self.rushLoops
  else
   self.stageDone=true
   s.stages[#s.stages].completedAt=D.App.runningTime
   if s.kind~="rush" or name=="rush3" then s.completedAt=D.App.runningTime end
  end
 end)
 self:reset(); return self
end
return Combat
