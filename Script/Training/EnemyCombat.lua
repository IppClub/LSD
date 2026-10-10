-- Small Taotie skills from the original monster animation requirements.
local D=require("Dora")
local P=D.Platformer
local Animation=require("CombatAnimation")
local Combat={}; Combat.__index=Combat
local specs={
 blow={label="甩尾挥击",range=310,damage=20,knockX=350},
 swing={label="跳跃甩尾",range=260,damage=14},
 butt={label="用角顶撞",range=240,damage=18,knockY=420},
 roll={label="向前滚动",damage=16,knockX=280},
 bomb={label="滚动炸弹",damage=18,radius=170},
}
Combat.specs=specs
function Combat:targets()
 local a=self.arena
 if a.enemyTargets then return a.enemyTargets() end
 -- Attack phases iterate these adapters every frame; cache per arena and
 -- refresh the unit fields in place instead of rebuilding tables and closures.
 local result=a._defaultTargets
 if not result then
  result={{unit=a.student,alive=function()return a.studentHP>0 end,damage=function(n) a.studentHP=math.max(0,a.studentHP-n); a.metrics.damageTaken=a.metrics.damageTaken+n end}}
  a._defaultTargets=result
 end
 result[1].unit=a.student
 local count=1
 for _,target in ipairs(a.extraEnemyTargets or {}) do count=count+1;result[count]=target end
 for i=count+1,#result do result[i]=nil end
 return result
end
function Combat:damage(target,spec,strike)
 local a=self.arena; local u=target.unit
 -- Defense encounters drain the visual attack before removing a defeated unit.
 -- A drained attack (including a mine already in flight) must not deal damage.
 if a.finishActiveAttack and (a.enemyHP<=0 or a.studentHP<=0 or (a.mode~="demo" and a.mode~="trial")) then return end
 local dealt=target.damage(spec.damage,strike)
 if dealt==nil then dealt=spec.damage end
 strike.damage=(strike.damage or 0)+dealt
 if dealt>0 and not target.immovable then
  local direction=a.enemy.faceRight and 1 or -1
  require('Combat.Displacement').apply(target,spec.knockX and direction*spec.knockX or 0,spec.knockY,strike)
 end
end
function Combat:reset()
 self.index=0; self.stage=nil; self.stageDone=false; self.rollHits={}
 self.arena.enemy.playable.visible=true
 if self.rollSprite then self.rollSprite.visible=false end
 self.arena.enemyStrike=nil; self.arena.enemyAttacks={}; self.arena.studentStaggerUntil=0
end
function Combat:play(name)
 self.stage=name; self.stageDone=false
 return Animation.play(self.arena.enemy,name,false)
end
function Combat:start(kind)
 local a=self.arena
 if a.enemyPhase=="attack" or not specs[kind] or a.enemyHP<=0 or a.studentHP<=0 then return false end
 a.enemy.faceRight=a.student.x>=a.enemy.x; a.enemy.velocityX=0
 a.enemyPhase="attack"; self.rollHits={}
 local strike={kind=kind,startedAt=D.App.runningTime,hit=false,damage=0}
 a.enemyStrike=strike; a.enemyAttacks[#a.enemyAttacks+1]=strike
 strike.duration=self:play(kind=="roll" and "rollStart" or kind)
 assert(strike.duration>0,"Missing Taotie animation: "..kind)
 return true
end
function Combat:bomb(strike)
 local a=self.arena; local spec=specs.bomb
 local def=P.BulletDef(); def.lifeTime=3; def.highSpeedFix=true; def.gravity=D.Vec2.zero
 def:setAsCircle(18); def:setVelocity(0,430)
 -- Existing bone has no detached bomb texture: build a mechanical rolling mine.
 def.face=P.Face(function()
  local node=D.DrawNode()
  node:drawDot(D.Vec2.zero,20,D.Color(0xff313b47)); node:drawDot(D.Vec2.zero,15,D.Color(0xff9baab8))
  node:drawDot(D.Vec2.zero,10,D.Color(0xff293442)); node:drawDot(D.Vec2.zero,5,D.Color(0xffffb34b))
  for _,x in ipairs({-12,12}) do node:drawDot(D.Vec2(x,0),2,D.Color(0xffffb34b)) end
  node:schedule(function() node.angle=node.angle+8; return false end)
  return node
 end)
 local bullet=P.Bullet(def,a.enemy)
 local allow=P.TargetAllow(); allow:allow("Enemy",true); allow.terrainAllowed=false; bullet.targetAllow=allow:toValue()
 local exploded=false
 bullet:slot("HitTarget",function(projectile)
  if exploded or a.closed or (a.mode~="demo" and a.mode~="trial") then projectile.hitStop=true; return end
  exploded=true; strike.explodedAt=D.App.runningTime; strike.explosionX=projectile.x; strike.blastTargets=0
  for _,target in ipairs(self:targets()) do
   local dx=math.max(0,math.abs(target.unit.x-projectile.x)-50)
   local dy=math.max(0,math.abs(target.unit.y-projectile.y)-150)
   if dx*dx+dy*dy<=spec.radius*spec.radius then self:damage(target,spec,strike); strike.blastTargets=strike.blastTargets+1 end
  end
  local flash=D.DrawNode(); flash:drawDot(D.Vec2.zero,spec.radius,D.Color(0x66ffb34b)); flash.position=projectile.position; flash:addTo(a.world)
  local began=D.App.runningTime
  flash:schedule(function()
   local t=(D.App.runningTime-began)/0.3; flash.opacity=math.max(0,1-t); flash.scaleX=1+t*0.2; flash.scaleY=flash.scaleX
   if t>=1 then flash:removeFromParent(); return true end; return false
  end)
  projectile.hitStop=true
 end)
 bullet.position=D.Vec2(a.enemy.x+(a.enemy.faceRight and 65 or -65),a.world.offset+35); bullet:addTo(a.world)
 a.projectiles[#a.projectiles+1]=bullet; strike.projectile=bullet
end
function Combat:attackEvent()
 local a=self.arena; local strike=a.enemyStrike
 if a.closed or (a.mode~="demo" and a.mode~="trial") or a.enemyPhase~="attack" or not strike or strike.hit or a.enemyHP<=0 or a.studentHP<=0 then return end
 strike.hit=true; strike.attackAt=D.App.runningTime
 if strike.kind=="bomb" then self:bomb(strike); return end
 local spec=specs[strike.kind]
 for _,target in ipairs(self:targets()) do
  local delta=target.unit.x-a.enemy.x
  if math.abs(delta)<spec.range and math.abs(target.unit.y-a.enemy.y)<230 and ((delta>=0)==a.enemy.faceRight) then
   self:damage(target,spec,strike); break -- melee skills are single target
  end
 end
end
function Combat:update(now)
 local a=self.arena
 if (a.studentHP<=0 or a.enemyHP<=0) and not (a.finishActiveAttack and a.enemyPhase=="attack") then a.enemy.velocityX=0; a.enemy.playable.visible=true; self.rollSprite.visible=false; return end
 if a.enemyPhase=="attack" then
  local strike=a.enemyStrike
  if strike.kind=="roll" then
   if self.stage=="rollStart" and self.stageDone then
    self.stage="rolling"; self.rollBegan=now; self.rollUntil=now+1.2; strike.attackAt=now; strike.hit=true
    a.enemy.playable.visible=false; self.rollSprite.visible=true; self.rollSprite.angle=0
   elseif self.stage=="rolling" then
    a.enemy.velocityX=a.enemy.faceRight and 320 or -320
    self.rollSprite.angle=-(a.enemy.faceRight and 1 or -1)*(now-self.rollBegan)*320/125*180/math.pi
    for _,target in ipairs(self:targets()) do
     if not self.rollHits[target.unit] and math.abs(target.unit.x-a.enemy.x)<130 and math.abs(target.unit.y-a.enemy.y)<220 then
      self.rollHits[target.unit]=true; self:damage(target,specs.roll,strike)
     end
    end
    if now>=self.rollUntil or a.enemy.x<=(a.minX or 350)+5 or a.enemy.x>=(a.maxX or 1500)-5 then a.enemy.velocityX=0; self.rollSprite.visible=false; a.enemy.playable.visible=true; self:play("rollEnd") end
   elseif self.stage=="rollEnd" and self.stageDone then strike.completedAt=now end
  elseif self.stageDone then strike.completedAt=strike.completedAt or now end
  if strike.completedAt then
   a.enemy.velocityX=0; a.enemyPhase="recover"; a.nextEnemy=now+1.1; Animation.rest(a.enemy)
  end
 elseif now>=a.nextEnemy then
  if a.enemyPhase=="recover" then a.enemyPhase="idle"; a.nextEnemy=now+1.2
  else
   self.index=self.index%#self.skills+1
   self:start(self.skills[self.index])
  end
 elseif a.enemySpeed and a.enemyPhase=="idle" then
  local delta=a.student.x-a.enemy.x; a.enemy.faceRight=delta>=0
  a.enemy.velocityX=math.abs(delta)>280 and (delta>=0 and a.enemySpeed or -a.enemySpeed) or 0
  local desired=a.enemy.velocityX~=0 and "fmove" or a.enemy.data.combatRest
  if a.enemy.playable.current~=desired then Animation.play(a.enemy,desired,true) end
 end
end
function Combat.new(arena,skills)
 local self=setmetatable({arena=arena,skills=skills or {"blow","swing","butt","roll","bomb"}},Combat)
 -- Atlas region taotiegungunjsonfuben/tucheng; existing curled-body art.
 self.rollSprite=assert(D.Sprite("xiaotaotie.png"))
 self.rollSprite.textureRect=D.Rect(2,224,249,249)
 self.rollSprite.size=D.Size(249,249)
 self.rollSprite.position=D.Vec2(0,-25); self.rollSprite.visible=false; self.rollSprite:addTo(arena.enemy)
 assert(#self.skills>0)
 for _,kind in ipairs(self.skills) do assert(specs[kind],"Unknown Taotie skill") end
 arena.enemy.playable:slot("attack"):set(function() self:attackEvent() end)
 arena.enemy.playable:slot("AnimationEnd",function(name)
  if arena.enemyPhase=="attack" and name==self.stage then
   self.stageDone=true
   if arena.enemyStrike and (arena.enemyStrike.kind~="roll" or name=="rollEnd") then arena.enemyStrike.completedAt=D.App.runningTime end
  end
 end)
 self:reset(); return self
end
return Combat
