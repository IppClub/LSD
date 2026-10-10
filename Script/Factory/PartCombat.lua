-- Factory boss geometry and authoritative armor. Ordinary flowers keep their
-- physical bodies; all projectile contacts compete by distance with terrain.
local D=require('Dora')
local C={aimPolicy='commit-at-selection-v1'};C.__index=C
local weapons=require('Combat.WeaponProfiles')
function C.new(battle)
 local self=setmetatable({battle=battle,boss=battle.roots[3],serial=0,shots={},events={},known={},targetIds={},closed=false,manualAim={}},C)
 self.journal=require('Training.CombatJournal').new('factory-'..tostring(battle.attempt.id or D.App.totalTime),{observation=6,action=4,combat=1,partSet=2,contactScope='all-projectile',weaponRules=2,credit=2,vitals=1,aim=1,spatial=2,hitReaction=require('Factory.Rules').hitReaction,clock='simulation'},1500)
 self.targetIds[battle.roots[1]]='factory-flower-root-1';self.targetIds[battle.roots[2]]='factory-flower-root-2'
 self.vitals=require('Training.CombatVitals').new()
 self.credits=require('Training.FlowerCredit').new()
 local armor={['flower-head']=0,['flower-core']=40,['petal-left']=70,['petal-right']=70,roots=90};local parts={}
 for id,ap in pairs(armor)do parts[id]={maxAP=ap,armoredMultiplier=.1,exposedMultiplier=id=='flower-head' and 1.5 or 1,armoredResponse='stop'}end
 self.target=require('Combat.PartTarget').new(self.boss.enemy.playable,D.json.decode(D.Content:load('Data/Combat/flower-regions.json')),battle.arena.world,{id='factory-flower',maxHP=self.boss.enemyMaxHP,parts=parts},function(e)
  self.boss.enemyHP=e.hpAfter;self.events[#self.events+1]=e;self.known[e.part]={ap=e.apAfter,maxAP=self.target.damage.parts[e.part].maxAP}
  if self.view then self.view:hit(e,battle.arena.world)end
 end)
 self.bossCreditConfig={target='factory-flower',maxHP=self.boss.enemyMaxHP,parts=armor,summoned=false}
 self.boss.enemy.playable.look='default'
 self.aimSteps={};self.aimActive={}
 local aimNode=D.Node();aimNode:addTo(battle.arena.world)
 aimNode:schedule(function()
  if self.closed then return true end
  for _,a in ipairs(battle.learners)do
   local actor=a.character.id;local step=self.aimSteps[actor] and self.journal.steps[self.aimSteps[actor]]
   if step and step.action.aimSource=='part-policy-v1' and a.student:isDoing(a.physical.laser)then
    local angle=step.action.aimAngle
    if angle then a.student.playable:setBoneRotation('aim',-angle);self.aimActive[actor]=true end
   elseif self.aimActive[actor]then a.student.playable:setBoneRotation('aim',0);self.aimActive[actor]=nil end
  end
  return false
 end)
 battle.arena.world:slot('Cleanup',function()self:close()end)
 return self
end
function C:begin(owner,actor,kind,origin)
 local movement=kind=='fmove' or kind=='bmove' or kind=='idle'
 local weapon=movement and 'none' or kind=='melee' and 'blade' or actor=='mentor' and 'kinetic' or 'emp'
 local action={name=kind or 'shoot',actor=actor,weapon=weapon,intendedPart='unknown',origin=origin or 'scripted'}
 local aim=actor=='mentor' and self.battle.mentorAim or self.manualAim[actor]
 if kind=='shoot' and aim and aim.shot and (origin=='demo' or origin=='player')then action.aimAngle=aim.angle;action.aimSource='manual-sweep-v1' end
 if kind=='shoot' and origin=='model'then
  for _,a in ipairs(self.battle.learners)do if a.student==owner and a.flowerTargetPart then action.intendedPart=a.flowerTargetPart;action.aimSource='part-policy-v1'
   local planned=a.flowerTargetAim
   if planned then action.aimAngle=planned.angle;action.aimCommit=1;action.aimCommittedAt=D.App.totalTime;action.aimPoint={x=planned.point.x,y=planned.point.y}end end end
 end
 local step=self.journal:begin(require('Training.FlowerFeatures').capture(self.battle,owner,self.known),action,D.App.totalTime,true)
 if action.aimSource=='part-policy-v1' then self.aimSteps[actor]=step end
 return step
end
function C:muzzle(owner)
 return require('Combat.Muzzle').actual(self.battle.arena.world,owner)
end
function C:aim(owner,part,preview,faceRight)
 if self.closed or self.boss.enemyHP<=0 then return nil,'TARGET_UNAVAILABLE'end
 self:sample()
 if faceRight==nil then faceRight=owner.faceRight end
 local origin=preview and require('Combat.Muzzle').preview(self.battle.arena.world,owner,faceRight) or self:muzzle(owner)
 return require('Combat.PartAim').solve(origin,faceRight,part,self.target.regions,function(from,to)
  return self:aimBlocked(from,to)
 end)
end
-- PartAim already found the first Boss boundary on this ray. Its endpoint
-- is that contact: only nearer live enemies or terrain can block visibility.
-- Projectile contact still performs the full animated-shape sweep below.
function C:aimBlocked(from,to)
 local dx,dy=to.x-from.x,to.y-from.y;local length=dx*dx+dy*dy
 if length<1e-12 then return false end
 local blocked=false
 self.battle.arena.world:raycast(D.Vec2(from.x,from.y),D.Vec2(to.x,to.y),false,function(body,point)
  local terrain=body.group==D.Platformer.Data.groupTerrain;local enemy=false
  if not terrain then for _,e in ipairs(self.battle.enemies)do
   if e~=self.boss and e.enemy==body and e.enemyHP>0 then enemy=true;break end
  end end
  if terrain or enemy then
   local t=((point.x-from.x)*dx+(point.y-from.y)*dy)/length
   if t>=0 and t<=1 and (terrain or t<1-1e-8)then blocked=true;return true end
  end
  return false
 end)
 return blocked
end
function C:prepareShot(owner,stepId)
 local step=stepId and self.journal.steps[stepId];local action=step and step.action
 if action and action.aimSource=='part-policy-v1' then
  -- Commit like the player's released aim: animation/target motion may cause
  -- a miss or different contact, but never silently cancel or retarget the shot.
  if action.aimCommit~=1 or action.aimAngle==nil then action.shotRejected='AIM_NOT_COMMITTED';return nil,action.shotRejected end
  return {origin=self:muzzle(owner),angle=action.aimAngle}
 elseif action and action.aimSource=='manual-sweep-v1' then return {origin=self:muzzle(owner),angle=action.aimAngle}end
 return {origin=self:muzzle(owner),angle=0}
end
function C:finishMovement(step,owner,action)
 if not step or self.closed or self.battle.phase~='playing' then return end
 local reason=self.battle.effects:blocked(owner,action) and 'status-interrupted' or not owner.onSurface and 'airborne' or 'stopped'
 self.journal:finish(step,require('Training.FlowerFeatures').capture(self.battle,owner,self.known),D.App.totalTime,false,reason)
end
function C:finish(step,owner,status)
 if step and not self.closed then self.journal:finish(step,require('Training.FlowerFeatures').capture(self.battle,owner,self.known),D.App.totalTime,false,status=='interrupted'and'interrupted'or nil)end
end
-- Friends have no AP pool in this encounter. Apply the same weapon HP/AP
-- split as enemy contacts; an EMP contact therefore cannot invent HP damage.
function C:applyFriendly(hit,id,actor,weapon)
 local recipient=hit.friendly;local target,hp,readHP
 if recipient.unit==self.battle.mentor then target='mentor';readHP=function()return self.battle.mentorHP end
 else for _,a in ipairs(self.battle.learners)do if a.student==recipient.unit then target=a.character.id;readHP=function()return a.studentHP end;break end end end
 assert(target and readHP,'Unknown friendly recipient');hp=readHP()
 recipient.damage(weapon.healthDamage,{kind='virus-friendly-fire',source=actor,attackId=id})
 local after=readHP()
 local event={schemaVersion=1,attackId=id,hitId='impact',source=actor,target=target,relation='friendly',cause='virus',weapon=weapon.id,part='body',hpBefore=hp,hpAfter=after,apBefore=0,apAfter=0,healthDamage=hp-after,armorDamage=0,armorBroken=false,killed=after<=0,position=hit.position,normal=hit.normal}
 assert(self.journal:hit(event))
 if actor=='mentor' then self.battle.friendlyHits=(self.battle.friendlyHits or 0)+1
 else for _,a in ipairs(self.battle.learners)do if a.character.id==actor then a.metrics.friendlyHits=(a.metrics.friendlyHits or 0)+1 end end end
 return true,event
end
function C:sample()
 local now=D.App.totalTime
 if self.sampledAt~=now then self.target:sample();self.sampledAt=now end
end
function C:contact(from,to,previous,flip,friendlyOwner)
 self:sample()
 local hit
 if previous and flip==self.target.model.fliped then hit=self.target:probeMoving(from,to,previous)else hit=self.target:probe(from,to)end
 local dx,dy=to.x-from.x,to.y-from.y;local length=dx*dx+dy*dy
 if length<1e-12 then return hit end
 self.battle.arena.world:raycast(D.Vec2(from.x,from.y),D.Vec2(to.x,to.y),false,function(body,point)
  local terrain=body.group==D.Platformer.Data.groupTerrain;local enemy,friendly
  if not terrain then for _,e in ipairs(self.battle.enemies)do if e~=self.boss and e.enemy==body and e.enemyHP>0 then enemy=e;break end end end
  if friendlyOwner and body~=friendlyOwner and not terrain and not enemy then
   for _,recipient in ipairs(self.battle.targets())do if recipient.unit==body and recipient.alive()then friendly=recipient;break end end
  end
  if terrain or enemy or friendly then
   local t=((point.x-from.x)*dx+(point.y-from.y)*dy)/length
   if t>=0 and t<=1 and (not hit or t<hit.t-1e-8 or (terrain and t<=hit.t+1e-8))then
    hit={t=t,terrain=terrain,enemy=enemy,friendly=friendly,position={x=point.x,y=point.y},normal={x=0,y=0}}
   end
  end
  return false
 end)
 return hit
end
function C:apply(hit,id,actor,weaponName)
 if self.closed or self.battle.phase~='playing' or not hit or hit.terrain then return false end
 local weapon=assert(weapons[weaponName]);local event
 if hit.friendly then return self:applyFriendly(hit,id,actor,weapon)end
 if hit.enemy then
  local e=hit.enemy;local hp=e.enemyHP;e.enemyHP=math.max(0,hp-weapon.healthDamage)
  local targetId=self.targetIds[e];if not targetId then targetId=e.combatSource or 'flower-unit-'..id;self.targetIds[e]=targetId end
  event={schemaVersion=1,attackId=id,hitId='impact',source=actor,weapon=weapon.id,target=targetId,part='body',hpBefore=hp,hpAfter=e.enemyHP,apBefore=0,apAfter=0,healthDamage=hp-e.enemyHP,armorDamage=0,armorBroken=false,killed=e.enemyHP<=0,position=hit.position,normal=hit.normal}
 else event=self.target:apply(hit,{id=id,contactId='impact',source=actor,weapon=weapon})end
 if not event then return false end
 event.relation='hostile'
 local config=self.bossCreditConfig
 if hit.enemy then
  local e=hit.enemy;local isRoot=false;for _,root in ipairs(self.battle.roots)do if root==e then isRoot=true;break end end
  event.targetStage=e.enemyCombat and e.enemyCombat.budding and not e.enemyCombat.opening and 'bud' or 'flower'
  if event.targetStage=='bud' then event.killed=false end
  config={target=event.target,maxHP=e.enemyMaxHP,parts={body=0},summoned=not isRoot}
 else event.targetStage='boss'end
 event.credit=self.credits:hit(event,config,D.App.totalTime)
 assert(self.journal:hit(event))
 if actor=='mentor' then self.battle.mentorHits=self.battle.mentorHits+1
 else for _,a in ipairs(self.battle.learners)do if a.character.id==actor then a.metrics.hits=a.metrics.hits+1 end end end
 return true,event
end
function C:projectile(bullet,actor,weapon,step,redirected)
 if self.closed then bullet:removeFromParent();return end
 self.serial=self.serial+1;local id='flower-shot-'..self.serial
 if step then assert(self.journal:attach(step,id));local action=self.journal.steps[step].action;action.redirected=redirected==true;action.emitted=(action.emitted or 0)+1;action.muzzle={x=bullet.x,y=bullet.y};action.velocity={x=bullet.velocityX,y=bullet.velocityY}end
 local allow=D.Platformer.TargetAllow();allow.terrainAllowed=false;bullet.targetAllow=allow:toValue()
 -- Disable legacy fixed-HP collision callbacks; the sweep below is authoritative.
 bullet:slot('HitTarget'):clear()
 self:sample();local prior=self.target.regions;local flip=self.target.model.fliped
 local owner=self.battle.mentor
 if actor~='mentor' then for _,a in ipairs(self.battle.learners)do if a.character.id==actor then owner=a.student end end end
 -- Include the barrel segment: a close enemy may already overlap the muzzle,
 -- and physics raycasts do not report shapes when the ray starts inside them.
 local prev={x=owner.x,y=bullet.y}
 -- Describe the player's ray at emission, before any future pose/contact outcome.
 -- A wall or another flower in front is not labelled as a boss-part intention.
 local action=step and self.journal.steps[step].action
 if action and action.aimSource=='manual-sweep-v1' then
  action.aimAt=D.App.totalTime
  if redirected then action.aimStatus='redirected'
  else
   local hit=self:contact(prev,{x=bullet.x,y=bullet.y})
   hit=hit or self:contact({x=bullet.x,y=bullet.y},{x=bullet.x+bullet.velocityX,y=bullet.y+bullet.velocityY})
   action.aimStatus=not hit and 'miss' or hit.terrain and 'terrain' or hit.enemy and 'flower' or 'boss'
   action.intendedPart=hit and not hit.terrain and not hit.enemy and hit.part or 'unknown'
  end
 end
 local watcher=D.Node();watcher:addTo(self.battle.arena.world);self.shots[bullet]=watcher
 bullet:slot('Cleanup',function()self.shots[bullet]=nil;if watcher.parent then watcher:removeFromParent()end;self.target:expire(id);self.journal:expire(id)end)
 watcher:schedule(function()
  if self.closed or self.battle.phase~='playing' then bullet:removeFromParent();return true end
  local current={x=bullet.x,y=bullet.y};local hit=self:contact(prev,current,prior,flip,redirected and owner or nil)
  if hit then self:apply(hit,id,actor,weapon);bullet:removeFromParent();return true end
  prev=current;prior=self.target.regions;flip=self.target.model.fliped;return false
 end)
end
function C:melee(owner,actor,step)
 if self.closed then return 0 end
 local from={x=owner.x,y=owner.y};local to={x=owner.x+(owner.faceRight and 300 or -300),y=owner.y}
 local hit=self:contact(from,to);self.serial=self.serial+1;local id='flower-melee-'..self.serial
 if step then assert(self.journal:attach(step,id))end
 local ok=self:apply(hit,id,actor,'melee');self.target:expire(id);self.journal:expire(id)
 -- The adapter already records the hit; Arena must not count it twice.
 return ok and 1 or 0
end
function C:close()
 if self.closed then return end;self.closed=true
 local shots=self.shots;self.shots={};for bullet,watcher in pairs(shots)do if bullet.parent then bullet:removeFromParent()end;if watcher.parent then watcher:removeFromParent()end end
 for _,a in ipairs(self.battle.learners)do for _,bullet in ipairs(a.projectiles)do if bullet.parent then bullet:removeFromParent()end end end
 if self.view then self.view:close();self.view.node:removeFromParent()end
 self.credits:close();self.target:close();self.journal:close(self.battle.pendingStatus or 'INTERRUPTED')
end
return C
