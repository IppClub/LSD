local K=require('Combat.Displacement')
local Visuals=require('Combat.FirearmVisuals')
local Firearm=require('Combat.FirearmRules')
-- Two independent VR trials; mentor input and Liyena's physical actions stay distinct.
local D=require("Dora")
local P=D.Platformer
local A=require("CombatAnimation")
local Battle={}; Battle.__index=Battle
function Battle:target(unit)
 if self.duel then return unit==self.hero and self.npcHP>0 and self.npc or unit==self.npc and self.heroHP>0 and self.hero or nil end
 local nearest,dist
 for _,e in ipairs(self.enemies) do if e.enemyHP>0 then local d=math.abs(e.enemy.x-unit.x); if not dist or d<dist then nearest=e.enemy; dist=d end end end
 return nearest
end
function Battle:damageHero(n)
 if self.phase~="playing" or self.heroHP<=0 or n<=0 then return 0 end
 if self.hero:isDoing("trialHeroGuard") then self.blocks=self.blocks+1; return 0 end
 local dealt=math.min(self.heroHP,n);self.heroHP=self.heroHP-dealt; self.damageTaken=self.damageTaken+dealt; if self.heroHP==0 then self:death(self.hero) end; return dealt
end
function Battle:react(unit)
 local log=self.activeCasts[unit]
 local accepted=K.apply({unit=unit,alive=function()
  return self.phase=="playing" and (unit==self.hero and self.heroHP>0 or unit==self.npc and self.npcHP>0)
 end},0,nil)
 if accepted and log and not log.completedAt and not log.interruptedAt then
  log.interruptedAt=D.App.runningTime;log.reason="hit"
 end
end
function Battle:damage(target,n,who)
 if self.phase~="playing" or n<=0 then return end
 if target==self.hero then local dealt=self:damageHero(n); if dealt>0 then self.npcHits=self.npcHits+1;if self.heroHP>0 then self:react(self.hero)end end; return end
 if target==self.npc then
  if who=="hero" and self.duel and self.npcHP>0 then self.npcHP=math.max(0,self.npcHP-n); self.heroHits=self.heroHits+1
   if self.npcHP==0 then self:death(self.npc)else self:react(self.npc)end
  end
  return
 end
 for _,e in ipairs(self.enemies) do if target==e.enemy and e.enemyHP>0 then
  e.enemyHP=math.max(0,e.enemyHP-n); if who=="hero" then self.heroHits=self.heroHits+1 else self.npcHits=self.npcHits+1 end
  if e.enemyHP==0 then self:death(e.enemy) end; return
 end end
end
function Battle:death(unit)
 local log=self.activeCasts[unit]; if log and not log.completedAt then log.interruptedAt=D.App.runningTime; log.reason="defeated" end
 K.clear(unit);unit:stop(); unit.velocityX=0; unit.group=0; A.play(unit,"lose",false)
end
function Battle:release(unit,who,kind,log)
 if self.phase~="playing" then return end
 log.releaseAt=D.App.runningTime
 local target=self:target(unit); if not target then return end
 if kind=="melee" then
  if math.abs(target.x-unit.x)<220 and math.abs(target.y-unit.y)<230 and ((target.x>=unit.x)==unit.faceRight) then self:damage(target,who=="hero" and 14 or 12,who); log.contacts=1 end
  return
 end
 local angle=who=="hero" and self.heroAim.angle or 0
 local def=P.BulletDef(); def.lifeTime=who=="hero" and Firearm.lifeTime or 1.5; def.highSpeedFix=true; def.gravity=D.Vec2.zero; def:setAsCircle(10); def:setVelocity(-angle,who=="hero" and Firearm.speed or 1700)
 def.face=P.Face(function()return Visuals.bulletFace(angle,unit.faceRight)end)
 local bullet=P.Bullet(def,unit); local allow=P.TargetAllow(); allow:allow("Enemy",true); allow.terrainAllowed=true; bullet.targetAllow=allow:toValue()
 local gun=unit.playable:getSlot("pistol")
 bullet.position=who=="hero" and gun and self.world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0))) or unit.position+D.Vec2(unit.faceRight and 70 or -70,-30)
 bullet:slot("HitTarget",function(projectile,victim) self:damage(victim,who=="hero" and 5 or self.duel and 6 or 10,who); log.contacts=(log.contacts or 0)+1; projectile.hitStop=true end)
 bullet:addTo(self.world); self.projectiles[#self.projectiles+1]=bullet
 require("Tutorial.LightStrip").LightStrip(bullet.position,bullet,0xccffffff)
 if gun then Visuals.casing(unit,gun,self.world,self.casings)end
end
function Battle:command(name)
 if self.phase~="playing" or self.heroHP<=0 then return false,"NOT_PLAYING" end
 if self:heroBusy() then return false,"ACTION_BUSY" end
 if name=="shoot" then local t=self:target(self.hero); if not t then return false,"NO_TARGET" end; self.hero.faceRight=t.x>=self.hero.x; return self.hero:start("trialHeroShot")
 elseif name=="melee" then local t=self:target(self.hero); if not t then return false,"NO_TARGET" end; self.hero.faceRight=t.x>=self.hero.x; return self.hero:start("trialHeroMelee")
 elseif name=="guard" then return self.hero:start("trialHeroGuard")
 elseif name=="left" or name=="right" then return require("Combat.Movement").command(self.hero,name)
 elseif name=="stop" then self.hero:stop(); self.hero.velocityX=0; A.rest(self.hero); return true end
 return false,"UNKNOWN_COMMAND"
end
function Battle:heroBusy() return K.blocked(self.hero) or self.hero:isDoing("trialHeroShot") or self.hero:isDoing("trialHeroMelee") or self.hero:isDoing("trialHeroGuard") end
function Battle:npcBusy() return K.blocked(self.npc) or self.npc:isDoing("trialNpcShot") or self.npc:isDoing("trialNpcMelee") end
function Battle:begin()
 if self.phase~="ready" then return false end
 self.phase="playing"; self.started=D.App.runningTime; self.nextNpc=self.started+1
 for _,e in ipairs(self.enemies) do e.nextEnemy=self.started+2 end
 return true
end
function Battle:finish(status,reason)
 if self.phase~="playing" and self.phase~="ready" then return end
 local played=self.phase=="playing"
 K.clear(self.hero);K.clear(self.npc)
 self.phase="saving"; self.pendingStatus=status; self.reason=reason
 for unit,log in pairs(self.activeCasts) do if not log.completedAt and not log.interruptedAt then log.interruptedAt=D.App.runningTime; log.reason=status end end
 self.hero:stop(); self.hero.velocityX=0; self.npc:stop(); self.npc.velocityX=0
 for _,e in ipairs(self.enemies) do e.mode="review"; e.enemy.velocityX=0 end
 self.report={seconds=played and D.App.runningTime-self.started or 0,duel=self.duel,heroHits=self.heroHits,npcHits=self.npcHits,blocks=self.blocks,damageTaken=self.damageTaken,heroHP=self.heroHP,npcHP=self.npcHP,opponents=self.duel and 1 or #self.enemies,casts=self.casts,reason=reason}
 self:saveResult()
end
function Battle:saveResult()
 if self.saving then return end; self.saving=true
 D.thread(function()
 local ok,r,e=xpcall(function() return self.service:finishAsync(self.attempt,self.pendingStatus,self.report) end,debug.traceback)
 if not ok then print('TrialBattle: finishAsync failed '..tostring(r)) end
 self.saving=false; self.phase=ok and r and self.pendingStatus or "save-error"; self.saveError=ok and e or tostring(r)
 end)
end
function Battle:frame()
 local lo,hi=math.min(self.hero.x,self.npc.x),math.max(self.hero.x,self.npc.x)
 for _,e in ipairs(self.enemies) do if e.enemyHP>0 then lo=math.min(lo,e.enemy.x); hi=math.max(hi,e.enemy.x) end end
 self.world.camera.position=D.Vec2((lo+hi)/2,self.world.offset+270); self.world.camera.zoom=math.min(1,D.View.size.width/(hi-lo+550))
end
function Battle:update()
 if self.closed then return true end
 if self.phase~="playing" then if self.phase=="ready" or self.phase=="briefing" then self:frame() end; return false end
 local now=D.App.runningTime
 for _,u in ipairs({self.hero,self.npc}) do u.x=math.max(350,math.min(3300,u.x)) end
 if self.npcHP>0 and not self:npcBusy() and self.npc.onSurface then
  local target=self:target(self.npc)
  if target then
   local delta=target.x-self.npc.x; self.npc.faceRight=delta>=0
   if math.abs(delta)>650 then self.npc:start("trialNpcMove")
   elseif now>=self.nextNpc then self.npc:start(math.abs(delta)<210 and "trialNpcMelee" or "trialNpcShot")
   else self.npc:stop(); self.npc.velocityX=0; if self.npc.playable.current~=self.npc.data.combatRest then A.rest(self.npc) end end
  else self.npc:stop(); self.npc.velocityX=0; A.rest(self.npc) end
 end
 for _,e in ipairs(self.enemies) do
  local target=self.heroHP>0 and self.hero or self.npc
  if self.npcHP>0 and math.abs(self.npc.x-e.enemy.x)<math.abs(target.x-e.enemy.x) then target=self.npc end
  e.student=target; e.studentHP=target==self.hero and self.heroHP or self.npcHP; e.enemyCombat:update(now)
 end
 self:frame()
 if self.heroHP<=0 or self.npcHP<=0 and not self.duel then self:finish("failed","训练队伍失去战斗能力，返回训练室调整后再来。")
 elseif now-self.started>=90 then self:finish("failed","训练超时，先返回训练室。")
 else
  local alive=self.duel and self.npcHP>0 or false; if not self.duel then for _,e in ipairs(self.enemies) do alive=alive or e.enemyHP>0 end end
  if not alive and not self:heroBusy() and not self:npcBusy() then
   if self.heroHits<2 or not self.duel and self.npcHits<2 then self:finish("failed","合作训练需要双方实际参与。请一起完成攻击与掩护。")
   else self:finish("won",self.duel and "对打训练完成。" or "双方共同清除了虚拟怪物。") end
  end
 end
 return false
end
function Battle.createAsync(service,attempt)
 local duel=attempt and attempt.mission=="c0-m04-duel"
 local b=setmetatable({service=service,attempt=attempt,duel=duel,phase=attempt and "ready" or "briefing",heroHP=100,npcHP=100,heroHits=0,npcHits=0,blocks=0,damageTaken=0,nextHeroShot=0,nextHeroMelee=0,nextGuard=0,nextNpc=0,casts={},activeCasts={},enemies={},projectiles={}},Battle)
 local heroName=require("Data.Config").char=="charF" and "charF" or "charM"
 for _,name in ipairs({heroName,"liyena","kineticgun","coldweapon","xiaotaotie"}) do D.Cache:loadAsync("spine:"..name) end
 local Scene=require("Scene.VRTraining"); Scene:loadAsync()
 D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren(); D.Entity:clear(); P.Data.store:clear(); P.Data:setRelation(1,2,"Enemy")
 b.world=Scene(); b.world:addTo(D.Director.entry); P.Data.store.world=b.world
 local function spawn(name,group,x,actions,player)
  local def=D.Dictionary(); def.playable="spine:"..name; def.bodyType="Dynamic"; def.size=D.Size(100,300); def.linearAcceleration=D.Vec2(0,-15); def.density=1; def.friction=1; def.defaultFaceRight=name~="liyena"; def.actions=D.Array(actions or {})
  local marker=D.Node(); D.Entity({trial=true,name=name,spawnMarker=marker,player=player or false}); local e=assert(D.Group({"trial","name"}):find(function(e) return e.spawnMarker==marker end))
  local u=assert(P.Unit(def,b.world,e,D.Vec2(x,b.world.offset+155))); u.group=group; u.playable.y=-150; u:addTo(b.world); e.unit=u; A.configure(u,name); b.world:addShadowTo(u); A.rest(u); return u
 end
 -- Global action definitions must not own a finished training world.
 local battleRef=setmetatable({b},{__mode="v"})
 local function move(name)
  P.UnitAction:add(name,{priority=1,reaction=0,recovery=0.2,available=function(u) local b=battleRef[1];return b~=nil and not b.closed and b.phase=="playing" and not K.blocked(u) and u.onSurface end,create=function(u) A.play(u,"fmove",true); return function(v) v.velocityX=v.faceRight and 240 or -240; return not v.onSurface end end,stop=function(u) u.velocityX=0; A.rest(u) end})
 end
 require("Combat.Movement").register("trialHeroMove",240); move("trialNpcMove")
 local function attack(name,who,kind)
  P.UnitAction:add(name,{priority=3,reaction=0,recovery=0.2,available=function(u) local b=battleRef[1];return b~=nil and not b.closed and b.phase=="playing" and not K.blocked(u) and u.onSurface and D.App.runningTime>=(who=="npc" and b.nextNpc or kind=="melee" and b.nextHeroMelee or b.nextHeroShot) end,
   create=function(u)
    local b=battleRef[1];if not b or b.closed then return function()return true end end
    local target=b:target(u); if target then u.faceRight=target.x>=u.x end; u.velocityX=0
    if who=="npc" then b.nextNpc=D.App.runningTime+(b.duel and 2.2 or 1.4) elseif kind=="melee" then b.nextHeroMelee=D.App.runningTime+1 else b.nextHeroShot=D.App.runningTime+1 end
    local prior=b.activeCasts[u]; if prior and not prior.completedAt and not prior.interruptedAt then prior.interruptedAt=D.App.runningTime; prior.reason="contact" end
    local log={role=who,skill=kind,startedAt=D.App.runningTime}; b.casts[#b.casts+1]=log; b.activeCasts[u]=log; local released=false
    u.playable:slot("attack"):set(function() if not released then released=true; b:release(u,who,kind,log) end end)
    return D.once(function() log.duration=A.playOnceAsync(u,kind); log.completedAt=D.App.runningTime; if not b.closed then A.rest(u) end; return true end)
   end})
 end
 attack("trialHeroShot","hero","pistol"); attack("trialHeroMelee","hero","melee"); attack("trialNpcShot","npc","pistol"); attack("trialNpcMelee","npc","melee")
 P.UnitAction:add("trialHeroGuard",{priority=3,reaction=0,recovery=0.2,available=function(u) local b=battleRef[1];return b~=nil and not b.closed and b.phase=="playing" and not K.blocked(u) and u.onSurface and D.App.runningTime>=b.nextGuard end,create=function(u)
  local b=battleRef[1];if not b or b.closed then return function()return true end end
  b.nextGuard=D.App.runningTime+2.5; u.velocityX=0; local log={role="hero",skill="parry",startedAt=D.App.runningTime}; b.casts[#b.casts+1]=log; b.activeCasts[u]=log
  return D.once(function() log.duration=A.playOnceAsync(u,"parry"); log.completedAt=D.App.runningTime; if not b.closed then A.rest(u) end; return true end)
 end})
 b.hero=spawn(heroName,1,900,{"trialHeroMove","trialHeroShot","trialHeroMelee","trialHeroGuard"},true)
 require("Combat.Movement").attach(b.hero,b,"trialHeroMove",240)
 b.npc=spawn("liyena",duel and 2 or 1,duel and 2200 or 1450,{"trialNpcMove","trialNpcShot","trialNpcMelee"})
 for _,u in ipairs({b.hero,b.npc}) do local gun=D.Spine("kineticgun"); gun.look="PT"; gun.scaleX=0.3; gun.scaleY=0.3; u.playable:setSlot("pistol",gun); local blade=D.Spine("coldweapon"); blade.look="sword"; blade.scaleX=0.2; blade.scaleY=0.2; u.playable:setSlot("melee",blade) end
 b.casings={}
 b.heroAim=require('Combat.Aim').new(b.hero,function()
  return b.phase=='playing' and b.heroHP>0 and not b:heroBusy() and b.hero.onSurface and D.App.runningTime>=b.nextHeroShot
 end,function()return b:command('shoot')end,'trialHeroShot')
 if attempt and not duel then
  for _,x in ipairs({1700,2300,2800}) do
   local e={world=b.world,enemy=spawn("xiaotaotie",2,x),enemyHP=40,student=b.hero,studentHP=100,mode="trial",enemyPhase="idle",nextEnemy=D.App.runningTime+2,enemySpeed=90,minX=350,maxX=3300,projectiles=b.projectiles,metrics={damageTaken=0}}
   e.enemyTargets=function()
    local targets={}
    if b.heroHP>0 then targets[#targets+1]={unit=b.hero,alive=function()return b.phase=="playing" and b.heroHP>0 end,damage=function(n) return b:damageHero(n) end} end
    if b.npcHP>0 then targets[#targets+1]={unit=b.npc,alive=function()return b.phase=="playing" and b.npcHP>0 end,damage=function(n)
     if b.phase~="playing" then return 0 end
     b.npcHP=math.max(0,b.npcHP-n); if b.npcHP==0 then b:death(b.npc) end; return n
    end} end
    return targets
   end
   e.enemyCombat=require("Training.EnemyCombat").new(e); b.enemies[#b.enemies+1]=e
  end
 end
 b.started=D.App.runningTime
 b.world:slot("Cleanup",function() b.closed=true; for _,e in ipairs(b.enemies) do e.closed=true end end)
 local tick=D.Node(); tick:addTo(b.world); tick:schedule(function() return b:update() end)
 return b
end
return Battle
