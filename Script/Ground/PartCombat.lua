-- Ground encounter integration. Numbers are initial tuning, not final balance.
local D=require('Dora');local Combat={};Combat.__index=Combat
local weapons={learner={id='emp',armorDamage=35,healthDamage=0},mentor={id='kinetic',armorDamage=0,healthDamage=20},rescue={id='blade',armorDamage=60,healthDamage=160}}
function Combat.new(battle)
 local self=setmetatable({battle=battle,serial=0,shots={},events={},knownParts={},closed=false},Combat)
 local a=battle.arena
 self.journal=require('Training.CombatJournal').new('ground-'..tostring(battle.attempt.id or D.App.runningTime),{observation=3,action=2,combat=1,credit=1,enemyTactics=1,hitReaction=2},1500)
 if battle.supplies then self.journal.versions.resources=1;self.journal.versions.resourceFeatures=1 end
 a.enemy.playable.look="default"
 local manifest=assert(D.json.decode(D.Content:load('Data/Combat/dataotie-regions.json')))
 local armor={head=80,['head-gem']=0,['back-front']=120,['back-rear']=100,['front-leg']=60,['rear-leg']=60,tail=40}
 self.credits=require('Training.PartCredit').new({target='ground-taotie',maxHP=a.enemyMaxHP,parts=armor})
 local parts={};for id,ap in pairs(armor)do parts[id]={maxAP=ap,armoredMultiplier=.05,exposedMultiplier=1,armoredResponse='stop'}end
 self.target=require('Combat.PartTarget').new(a.enemy.playable,manifest,a.world,{id='ground-taotie',maxHP=a.enemyMaxHP,parts=parts},function(e)
  a.enemyHP=e.hpAfter
  local actor=e.source=='learner' and a.character.id or e.source=='rescue' and 'wuyun' or e.source
  local credit,why=self.credits:hit(e,actor,D.App.runningTime)
  e.credit=credit;e.creditError=why;self.events[#self.events+1]=e
  self.journal:hit(e);self.observedPart=e.part
  self.knownParts[e.part]={ap=e.apAfter,maxAP=self.target.damage.parts[e.part].maxAP}
  if e.source=='learner'then a.metrics.hits=a.metrics.hits+1 elseif e.source=='mentor'then battle.mentorHits=battle.mentorHits+1 elseif e.source=='rescue'then battle.rescueHits=battle.rescueHits+1 end
  if self.view then self.view:hit(e,a.world)end
 end)
 a.partObservation=function()
  local part=self.observedPart;local p=part and self.target.damage.parts[part]
  return part,p and (p.maxAP==0 and 'unarmored' or p.ap<=0 and 'broken' or 'intact') or 'unknown'
 end
 a.targetSnapshot=function(state)
  self.target:sample()
  return require('Training.PartFeatures').capture(state or a:snapshot(),self.knownParts,function(part)return self:aim(a.student,part,true,true)~=nil end)
 end
 a.beginCombatAction=function(owner,source)return self:beginAction(owner,source)end
 a.finishCombatAction=function(step,owner,source,status)self:finishAction(step,owner,source,status)end
 a.observeProjectile=function(bullet,source,step)self:projectile(bullet,source,step)end
 a.prepareStudentShot=function(owner,step)return self:prepareShot(owner,step)end
 a.selectPart=function(part)return self:selectPart(part)end
 if not battle.managesPartCleanup and D.DB:existDB('lsd')then
  local store=require('Training.TargetStore').open(a.character.id)
  if store then local saved=store:load();if saved and not store.writeBlocked then self.policy=saved.adopted end end
 end
 a.selectTargetForAction=function(state)
  if not self.policy then return true end
  local observed=a.targetSnapshot(state)
  local part,why,fallback=require('Training.TargetPolicy').resolve(self.policy,observed,function(id)return require('Training.PartFeatures').reachable(observed,id)end,a.character.id,a.enemyAsset)
  if fallback then self:selectPart(nil);self.targetFallback=why;return true end
  if not part then return false,why end
  return self:selectPart(part)
 end
 self.aimNode=D.Node();self.aimNode:addTo(a.world)
 self.aimNode:schedule(function()
  if self.closed then return true end
  local step=self.aimStep and self.journal.steps[self.aimStep]
  if step and a.student:isDoing(a.physical.laser) and step.action.intendedPart~='unknown' then
   local angle=step.action.aimAngle
   if not angle then local solution=self:aim(a.student,step.action.intendedPart);angle=solution and solution.angle end
   if angle then a.student.playable:setBoneRotation('aim',-angle);self.aimActive=true end
  elseif self.aimActive then a.student.playable:setBoneRotation('aim',0);self.aimActive=false end
  return false
 end)
 if not battle.managesPartCleanup then a.world:slot('Cleanup',function()self:close()end)end
 return self
end
function Combat:muzzle(owner)
 return require('Combat.Muzzle').actual(self.battle.arena.world,owner)
end
function Combat:aim(owner,part,preview,prepared)
 if self.closed or not self.target.model.visible then return nil,'TARGET_UNAVAILABLE'end
 if not prepared then self.target:sample()end
 local origin=preview and require('Combat.Muzzle').preview(self.battle.arena.world,owner) or self:muzzle(owner)
 return require('Combat.PartAim').solve(origin,owner.faceRight,part,self.target.regions,function(from,to)
  local blocked=false
  self.battle.arena.world:raycast(D.Vec2(from.x,from.y),D.Vec2(to.x,to.y),false,function(body)
   if body.group==D.Platformer.Data.groupTerrain then blocked=true;return true end
   return false
  end)
  return blocked
 end)
end
function Combat:selectPart(part)
 self.targetFallback=nil
 if self.closed then return false,'CLOSED'end
 if part==nil then self.selectedPart=nil;return true end
 if not self.target.damage.parts[part]then return false,'UNKNOWN_PART'end
 local solution,why=self:aim(self.battle.arena.student,part,true)
 if not solution then return false,why end
 self.selectedPart=part;return true
end
function Combat:prepareShot(owner,stepId)
 local step=stepId and self.journal.steps[stepId]
 local part=step and step.action.intendedPart
 if not part or part=='unknown'then return {origin=self:muzzle(owner),angle=0}end
 local solution,why=self:aim(owner,part)
 if not solution then if step then step.action.shotRejected=why end;return nil,why end
 if step then step.action.aimAngle=solution.angle;step.action.muzzle=solution.origin end
 return solution
end
function Combat:nextId()self.serial=self.serial+1;return 'ground-shot-'..self.serial end
function Combat:observation(owner,source)
 local b=self.battle;local a=b.arena;local part=self.observedPart;local p=part and self.target.damage.parts[part]
 local observation={distance=math.abs(owner.x-a.enemy.x),facing=((a.enemy.x>=owner.x)==owner.faceRight) and 'yes' or 'no',enemyAction=a.enemyPhase,
  health=source=='learner' and a.studentHP or source=='mentor' and b.mentorHP or b.rescueHP,
  energy=source=='learner' and a.studentEnergy or 'unknown',weapon=weapons[source].id,
  observedPart=part or 'unknown',armor=p and p.ap or 'unknown',targetHealth=a.enemyHP}
 if b.supplies then observation.resources=b.supplies:observation(source=='learner' and a.character.id or source=='rescue' and 'wuyun' or source);observation.resourceFeatures=assert(require('Training.ResourceFeatures').project(observation))end
 return observation
end
function Combat:beginAction(owner,source)
 if self.closed then return nil end
 local step=self.journal:begin(self:observation(owner,source),{actor=source=='learner' and self.battle.arena.character.id or source=='rescue' and 'wuyun' or source,name=weapons[source].id,source=source,controller=source=='learner' and self.battle.arena.currentActionSource or nil,intendedPart=source=='learner' and self.selectedPart or 'unknown'},D.App.runningTime,true)
 if source=='learner'then
  self.aimStep=step
  if step then local action=self.journal.steps[step].action;if action.controller=='model' or action.controller=='target-model' then action.targetFallback=self.targetFallback end end
  self.targetFallback=nil
 end
 if step and self.battle.arena.onPartAction then self.battle.arena.onPartAction(self.journal.steps[step],source)end
 return step
end
function Combat:finishAction(step,owner,source,status)
 if step and not self.closed then self.journal:finish(step,self:observation(owner,source),D.App.runningTime,false,status=='interrupted'and'interrupted'or nil)end
end
function Combat:projectile(bullet,source,step)
 if self.closed then bullet:removeFromParent();return end
 local id=self:nextId();if step then self.journal:attach(step,id);local action=self.journal.steps[step].action;action.emitted=(action.emitted or 0)+1;if action.targetFallback then local m=self.battle.arena.metrics;m.targetFallback=(m.targetFallback or 0)+1 end end;local prev={x=bullet.x,y=bullet.y}
 local allow=D.Platformer.TargetAllow();allow.terrainAllowed=false;bullet.targetAllow=allow:toValue()
 self.target:sample();local previousRegions=self.target.regions;local previousFlip=self.target.model.fliped
 local watcher=D.Node();watcher:addTo(self.battle.arena.world)
 local shot={id=id,bullet=bullet};self.shots[#self.shots+1]=shot
 bullet:slot('Cleanup',function()if watcher.parent then watcher:removeFromParent()end;self.target:expire(id);self.journal:expire(id);for i,s in ipairs(self.shots)do if s==shot then table.remove(self.shots,i);break end end end)
 watcher:schedule(function()
  if self.closed or self.battle.phase~='playing' then bullet:removeFromParent();return true end
  self.target:sample();local current={x=bullet.x,y=bullet.y};local flip=self.target.model.fliped
  -- Facing is an instantaneous mirror, not a sweep through the body's center.
  local hit
  if flip~=previousFlip then hit=self.target:probe(prev,current)
  else hit=self.target:probeMoving(prev,current,previousRegions)end
  local blocked;hit,blocked=require('Combat.TerrainSweep').first(self.battle.arena.world,prev,current,hit)
  if blocked then
   if step then self.journal.steps[step].action.terrainBlocked=true end
   bullet:removeFromParent();return true
  end
  if hit then
   self.target:apply(hit,{id=id,contactId='impact',source=source,weapon=assert(weapons[source])})
   bullet:removeFromParent();return true
  end
  prev=current;previousRegions=self.target.regions;previousFlip=flip;return false
 end)
end
function Combat:melee(owner,step)
 if self.closed then return false end
 self.target:sample();local from={x=owner.x,y=owner.y};local to={x=owner.x+(owner.faceRight and 380 or -380),y=owner.y}
 local hit=self.target:probe(from,to);hit=require('Combat.TerrainSweep').first(self.battle.arena.world,from,to,hit);if not hit then return false end
 local id=self:nextId();if step then self.journal:attach(step,id)end;local e=self.target:apply(hit,{id=id,contactId='impact',source='rescue',weapon=weapons.rescue});self.target:expire(id);self.journal:expire(id)
 return e~=nil
end
function Combat:close(reason)
 if self.closed then return end;self.closed=true
 self.journal:close(reason or 'BATTLE_ENDED')
 self.credits:close()
 if self.aimNode then self.aimNode:removeFromParent()end
 local shots=self.shots;self.shots={};for _,s in ipairs(shots)do if s.bullet.parent then s.bullet:removeFromParent()end end
 if self.view then self.view.node:removeFromParent()end
 self.target:close()
end
return Combat
