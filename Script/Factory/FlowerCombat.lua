-- Authored flower timelines have no attack event. Impact windows are pose-calibrated.
local D=require("Dora")
local Animation=require("CombatAnimation")
local Combat={}; Combat.__index=Combat
local specs={
 leech={small=true,parts={"leech"},impact=1.5,range=360,damage=12,group=true,heal=true},
 pull={small=true,parts={"pull"},impact=0.6,range=780,damage=0,group=true,pull=true},
 attack={parts={"attack"},impact=0.55,range=500,damage=18},
 twine={parts={"twine"},impact=1.05,range=850,damage=8,group=true,poison=true,confuse=true},
 transv={parts={"transv1","transv2","transv3"},impact=0.5,releasePart=2,range=900,damage=0,group=true,virus=true},
 seed={parts={"seed1","seed2","seed3"},impact=0.7,releasePart=2,damage=0,seed=true},
}
Combat.specs=specs; Combat.budAsset="hualei.skel|xiaohuayao.atlas"
function Combat:targets()
 if self.arena.enemyTargets then return self.arena.enemyTargets() end
 local a=self.arena
 return {{unit=a.student,alive=function() return a.studentHP>0 end,isAttacking=function() return a:isAttacking() end,damage=function(n) local dealt=math.min(a.studentHP,n); a.studentHP=a.studentHP-dealt; a.metrics.damageTaken=a.metrics.damageTaken+dealt; return dealt end}}
end
function Combat:play(name)
 self.stage=name; self.stageDone=false; self.partStarted=D.App.runningTime
 local strike=self.arena.enemyStrike
 local duration=Animation.play(self.arena.enemy,name,false); assert(duration>0,"Missing flower animation "..name);self.stageDuration=duration
 if strike then strike.segments[#strike.segments+1]={name=name,startedAt=self.partStarted,duration=duration} end
 return duration
end
function Combat:clearWaves()
 for wave in pairs(self.waves or {})do if wave.parent then wave:removeFromParent()end end;self.waves={}
end
function Combat:updatePhase(now)
 if not self.phaseEnabled or self.bossPhase==2 then return end
 local a=self.arena
 if a.enemyHP<=a.enemyMaxHP*.5 then self.phasePending=true end
 if self.phasePending and a.enemyPhase~="attack" then
  self.phasePending=false;self.bossPhase=2;self.skills={"seed","twine","transv","attack"};self.index=0
  self:clearWaves();a.enemyPhase="recover";a.nextEnemy=now+1.2
  self.phaseEvents[#self.phaseEvents+1]={phase=2,at=now,hp=a.enemyHP}
 end
end
function Combat:activeSummons()
 local count=0;for _,child in ipairs(self.children)do if child.enemyHP>0 and not child.closed then count=count+1 end end;return count
end
function Combat:retireChild(index)
 local child=table.remove(self.children,index);if not child then return end
 child.enemyCombat:close();local entity=child.enemy.entity
 child.enemy:removeFromParent();entity:destroy()
 if self.onDespawn then self.onDespawn(child)end
end
function Combat:close()
 if self.closed then return end;self.closed=true;self.arena.closed=true;self:clearWaves()
 for i=#self.children,1,-1 do self:retireChild(i)end
 if self.bud then self.bud:removeFromParent();self.bud=nil end
 if not self.sharedEffects then self.effects:clear()end
end
function Combat:reset()
 local a=self.arena
 self:clearWaves();self.bossPhase=1;self.phasePending=false;self.phaseEvents={}
 self.skills=self.phaseEnabled and {"attack","twine","transv"} or self.baseSkills
 if not self.sharedEffects then self.effects:clear() end; self.power=1; self.budCoefficient=nil; self.openedAt=nil; self.budEnded=false; self.index=0; self.stage=nil; self.stageDone=false; self.dead=false; self.deathEnded=false; self.closed=false; self.arena.closed=false; self.damageInBud=0; self.firstBudHit=nil; self.opening=false
 for i=#self.children,1,-1 do self:retireChild(i)end
 self.children={}; self.spawnSerial=0; a.seededEnemies=self.children
 self.observedHP=a.enemyHP; a.enemy.playable.visible=not self.startAsBud
 if self.bud then self.bud.visible=self.startAsBud; self.bud.speed=1; self.bud.recovery=0.2; self.bud:play("bud",true) end
 self.budding=self.startAsBud; a.enemy.velocityX=0
end
function Combat:start(kind)
 local a=self.arena; local spec=specs[kind]
 if self.closed or not spec or a.enemyHP<=0 or a.studentHP<=0 or a.enemyPhase=="attack" or self.budding or self.opening then return false end
 a.enemy.faceRight=a.student.x>=a.enemy.x; a.enemy.velocityX=0; a.enemyPhase="attack"
 self.attackSerial=(self.attackSerial or 0)+1
 a.enemyStrike={source=a.combatSource or a.enemyAsset,attackId=(a.combatSource or a.enemyAsset).."-attack-"..self.attackSerial,kind=kind,startedAt=D.App.runningTime,segments={},damage=0,targets=0}; a.enemyAttacks[#a.enemyAttacks+1]=a.enemyStrike
 self.part=1; self:play(spec.parts[1]); return true
end
function Combat:seed(strike)
 local a=self.arena
 strike.spawned=0
 local slots=math.max(0,self.maxSummons-self:activeSummons());strike.summonLimit=self.maxSummons;strike.summonBlocked=slots==0
 for i=1,math.min(3,slots) do
  local x=math.max((a.minX or 350)+100,math.min((a.maxX or 1500)-100,a.enemy.x+({-520,-280,280})[i]))
  local child={world=a.world,student=a.student,studentHP=a.studentHP,enemyHP=100,enemyMaxHP=100,metrics={damageTaken=0},mode=a.mode,enemyPhase="idle",nextEnemy=D.App.runningTime+1.2,enemyAsset="xiaohuayao",minX=a.minX,maxX=a.maxX,projectiles=a.projectiles,enemyAttacks={},spawnUnit=a.spawnUnit}
  self.spawnSerial=(self.spawnSerial or 0)+1
  child.enemy=a.spawnUnit("xiaohuayao",2,x,{},nil,self.spawnSerial%2==1 and "white" or "normal"); child.enemyTargets=function() return self:targets() end
  child.enemyCombat=Combat.new(child,{bud=true,effects=self.effects}); child.bud=child.enemyCombat.bud
  self.children[#self.children+1]=child; strike.spawned=strike.spawned+1
  if self.onSpawn then self.onSpawn(child) end
 end
end
function Combat:impact(strike)
 if strike.attackAt then return end
 local a=self.arena; local spec=specs[strike.kind]; strike.attackAt=D.App.runningTime
 if spec.seed then self:seed(strike); return end
 if strike.kind=="twine" then
  local waves=D.DrawNode(); waves.tag="flower-ground-vines"; waves.order=25; waves.position=D.Vec2(a.enemy.x,a.world.offset); waves:addTo(a.world);self.waves[waves]=true
  local direction=a.enemy.faceRight and 1 or -1; local origin=a.enemy.x; local began=D.App.runningTime; local emitted=0; local hit={}
  waves:schedule(function()
   local elapsed=D.App.runningTime-began
   if (a.mode~="demo" and a.mode~="trial") or a.closed or a.enemyHP<=0 then self.waves[waves]=nil;waves:removeFromParent(); return true end
   local wanted=math.min(5,math.floor(elapsed/0.15)+1)
   while emitted<wanted do
    emitted=emitted+1; local x=direction*(80+emitted*135)
    waves:drawSegment(D.Vec2(x,0),D.Vec2(x-30,155),8,D.Color(0xff536f67)); waves:drawSegment(D.Vec2(x-30,155),D.Vec2(x+25,240),5,D.Color(0xff819c94)); waves:drawDot(D.Vec2(x+25,240),12,D.Color(0xffc96383))
    for _,target in ipairs(self:targets()) do
     if not hit[target.unit] and self.effects:alive(target) and math.abs(target.unit.x-(origin+x))<=115 and math.abs(target.unit.y-(a.world.offset+155))<220 then
      hit[target.unit]=true; local dealt=target.damage(8*self.power,strike);dealt=dealt==nil and 8*self.power or dealt; if dealt>0 then require('Combat.Displacement').apply(target,0,nil,strike)end; strike.damage=strike.damage+dealt; strike.targets=strike.targets+1
      self.effects:apply(target,"poison",6,strike); self.effects:apply(target,"confuse",6,strike)
     end
    end
   end
   strike.waves=emitted; waves.opacity=math.max(0,1-elapsed/1.5)
   if elapsed>=1.5 then self.waves[waves]=nil;waves:removeFromParent(); return true end
   return false
  end)
  return
 end
 for _,target in ipairs(self:targets()) do
  local delta=target.unit.x-a.enemy.x
  if self.effects:alive(target) and math.abs(delta)<=spec.range and math.abs(target.unit.y-a.enemy.y)<300 and ((delta>=0)==a.enemy.faceRight) then
   local n=spec.damage*(self.power or 1); local dealt=target.damage(n,strike); dealt=dealt==nil and n or dealt
   strike.damage=strike.damage+dealt; strike.targets=strike.targets+1
   if dealt>0 then require('Combat.Displacement').apply(target,0,nil,strike)end
   if spec.heal then a.enemyHP=math.min(a.enemyMaxHP,a.enemyHP+dealt) end
   if spec.pull then self.effects:pull(target,a.enemy.x,strike) end
   if spec.poison then self.effects:apply(target,"poison",6,strike) end
   if spec.confuse then self.effects:apply(target,"confuse",6,strike) end
   if spec.virus then self.effects:apply(target,"virus",4,strike) end
   if not spec.group then break end
  end
 end

end
function Combat:updateBud(now)
 local a=self.arena
 if self.opening then
  if a.enemyHP<=0 then self.opening=false; self.budding=false; self.bud:stop(); self.bud.visible=false; a.enemy.playable:stop(); a.enemy.playable.visible=true; return false end
  if self.budEnded then self.opening=false; self.budding=false; self.bud.visible=false; a.enemy.playable:stop(); a.enemy.playable.visible=true; Animation.rest(a.enemy); a.enemyPhase="recover"; a.nextEnemy=now+1; self.openedAt=now end
  return true
 end
 if not self.budding then return false end
 if a.enemyHP<self.observedHP then self.firstBudHit=self.firstBudHit or now; self.damageInBud=self.damageInBud+self.observedHP-a.enemyHP end
 -- Damage over the complete five-second window controls the revealed flower, not early death.
 a.enemyHP=a.enemyMaxHP; self.observedHP=a.enemyHP; a.enemy.velocityX=0
 if self.firstBudHit and now-self.firstBudHit>=5 then
  self.budCoefficient=math.max(0.3,1-self.damageInBud/200); self.power=self.budCoefficient
  a.enemyMaxHP=math.max(30,100*self.budCoefficient); a.enemyHP=a.enemyMaxHP
  self.opening=true; self.budEnded=false; self.budOpenedAt=now; self.bud.recovery=0.2
  self.budDuration=self.bud:play("blossom",false); assert(self.budDuration>0,"Bud blossom missing")
 end
 return true
end
function Combat:update(now)
 if self.closed then return end
 local a=self.arena
 for i=#self.children,1,-1 do local child=self.children[i];child.mode=a.mode;child.studentHP=a.studentHP;child.enemyCombat:update(now)
  if child.enemyCombat.dead and child.enemyCombat.deathEnded then self:retireChild(i)end
 end
 if not self.sharedEffects then self.effects:update(now) end
 if self:updateBud(now) then return end
 if a.enemyHP<=0 then
  if not self.dead then
   self.dead=true; a.enemy.velocityX=0; a.enemy.group=0
   if a.enemyStrike and not a.enemyStrike.completedAt then a.enemyStrike.interruptedAt=now; a.enemyStrike.interruptedReason="defeated" end
   self.deathStarted=now;self.deathDuration=Animation.play(a.enemy,"lose",false)
  end
  return
 end
 if a.studentHP<=0 then a.enemy.velocityX=0; return end
 self:updatePhase(now)
 if a.enemyPhase=="attack" then
  local strike=a.enemyStrike; local spec=specs[strike.kind]
  if self.part==(spec.releasePart or 1) and now-self.partStarted>=spec.impact then self:impact(strike) end
  if self.stageDone and now-self.partStarted>=self.stageDuration then
   local segment=strike.segments[#strike.segments];if segment then segment.completedAt=now end
   if self.part<#spec.parts then self.part=self.part+1; self:play(spec.parts[self.part])
   else strike.completedAt=now; a.enemyPhase="recover"; a.nextEnemy=now+1.2; Animation.rest(a.enemy) end
  end
 elseif now>=a.nextEnemy then
  if a.enemyPhase=="recover" then a.enemyPhase="idle"; a.nextEnemy=now+0.5
  else
   for _=1,#self.skills do
    self.index=self.index%#self.skills+1;local kind=self.skills[self.index]
    if kind~="seed" or self:activeSummons()<self.maxSummons then self:start(kind);break end
   end
  end
 end
end
function Combat.new(arena,options)
 options=options or {}
 local self=setmetatable({arena=arena,phaseEnabled=options.phases==true,baseSkills=options.skills or (arena.enemyAsset=="xiaohuayao" and {"leech","pull"} or {"attack","twine","transv","seed"}),startAsBud=options.bud or arena.enemyBud,sharedEffects=options.effects~=nil,onSpawn=options.onSpawn,onDespawn=options.onDespawn,maxSummons=options.maxSummons or 3,children={}},Combat)
 self.effects=options.effects or require("Factory.Effects").new(function() return self:targets() end)
 arena.studentEffects=self.effects
 if arena.enemyAsset=="xiaohuayao" then
  self.bud=assert(D.Spine(Combat.budAsset)); self.bud.position=D.Vec2(0,-150); self.bud:addTo(arena.enemy)
  self.bud:slot("AnimationEnd",function(name) if self.opening and name=="blossom" then self.budEnded=true end end)
 end
 arena.enemy.playable:slot("AnimationEnd",function(name)
  if self.dead and name=="lose" then self.deathEnded=true end
  if arena.enemyPhase=="attack" and name==self.stage then
   self.stageDone=true
   local strike=arena.enemyStrike; local segment=strike and strike.segments[#strike.segments]
   if segment then segment.completedAt=D.App.runningTime end
  end
 end)
 self:reset(); return self
end
return Combat
