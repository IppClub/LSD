-- Actual travelled segments decide the first body/terrain contact. The host
-- charges emission costs and records returned events in its mission journal.
local D=require('Dora');local G=require('Combat.HitGeometry');local P={};P.__index=P
function P.new(battle,boss,onHit)
 local self=setmetatable({battle=battle,boss=boss,serial=0,shots={},shotActors={},flightEnd={},targetIds=setmetatable({},{__mode='k'}),targetSerial=0,onHit=onHit},P)
 self.armor=require('Enemy.BigYingzhaoArmor').new(boss,battle.world,function(e)
  if self.view then self.view:hit(e,battle.world)end
 end)
 self.view=require('Combat.StatusView').new(self.armor.target.damage,'大英招',require('Enemy.BigYingzhaoArmor').partNames)
 self.view:observeParts({'head','torso','flank','arms','forelegs','hindlegs'})
 battle.world:slot('Cleanup',function()self:close()end)
 return self
end
function P:sample()
 local now=D.App.totalTime
 if self.sampledAt~=now then self.armor:sample();self.sampledAt=now end
end
function P:contact(from,to,previous,flip)
 self:sample();local hit
 if self.armor:available()then
  local t=self.armor.target
  if previous and flip==t.model.fliped then hit=t:probeMoving(from,to,previous)else hit=t:probe(from,to)end
 end
 -- Summoned units use their physical body rectangles, including rays starting
 -- inside one. Boss hulls never fall back to the large broad-phase body.
 for i,e in ipairs(self.battle.enemies)do
  local u=e.enemy
  if e~=self.boss and e.enemyHP>0 and u.visible and u.opacity>.1 then
   local w,h=u.unitDef.size.width/2,u.unitDef.size.height/2
   local c=G.nearest(from,to,{{id='body',vertices={{x=u.x-w,y=u.y-h},{x=u.x+w,y=u.y-h},{x=u.x+w,y=u.y+h},{x=u.x-w,y=u.y+h}}}})
   if c and (not hit or c.t<hit.t-1e-8)then c.enemy=e;if not self.targetIds[e]then self.targetSerial=self.targetSerial+1;self.targetIds[e]=e.combatSource or 'yingzhao-summon-'..self.targetSerial end;c.targetId=self.targetIds[e];hit=c end
  end
 end
 local resolved,terrain=require('Combat.TerrainSweep').first(self.battle.world,from,to,hit)
 return resolved,terrain
end
function P:projectile(bullet,actor,weaponName,owner,step,options)
 if self.closed or self.battle.phase~='playing'then bullet:removeFromParent();return end
 local weapon=options and options.weapon or assert(require('Combat.WeaponProfiles')[weaponName]);self.serial=self.serial+1
 local id='yingzhao-shot-'..self.serial
 local trace=self.battle.bossTrace
 local flight={id=id,kind=options and options.projectileKind or 'firearm',actor=actor,step=step,started=D.App.runningTime,origin={x=bullet.x,y=bullet.y},velocity={x=bullet.velocityX,y=bullet.velocityY}}
 if trace then
  trace.flightVersion=1;trace.flights=trace.flights or {}
  if #trace.flights<(trace.limit or 1500)then trace.flights[#trace.flights+1]=flight else trace.truncated=true end
 end
 local function finishFlight(reason,hit)
  if flight.ended then return end
  flight.ended=D.App.runningTime;flight.reason=reason;flight.position={x=bullet.x,y=bullet.y}
  if hit then flight.target=hit.target;flight.part=hit.part end
 end
 self.flightEnd[bullet]=finishFlight
 bullet.targetAllow=0;bullet:slot('HitTarget'):clear()
 self:sample();local previous=self.armor:available()and self.armor.target.regions or nil;local flip=self.armor.target.model.fliped
 local from={x=owner and owner.x or bullet.x,y=bullet.y}
 local watcher=D.Node();watcher:addTo(self.battle.world);self.shots[bullet]=watcher;self.shotActors[bullet]=actor
 bullet:slot('Cleanup',function()
  finishFlight('removed')
  self.shots[bullet]=nil;self.shotActors[bullet]=nil;self.flightEnd[bullet]=nil;if watcher.parent then watcher:removeFromParent()end;self.armor:expire(id)
 end)
 watcher:schedule(function()
  -- Bullet expiry hides the body before queued Cleanup reaches Lua. Finalize
  -- it before observing a later phase change; it was not cancelled by that change.
  if not bullet.parent or bullet.group==D.Platformer.Data.groupHide then finishFlight('removed');return true end
  if self.closed or self.battle.phase~='playing'then finishFlight('battle-ended');bullet:removeFromParent();return true end
  local to={x=bullet.x,y=bullet.y};local hit,terrain=self:contact(from,to,previous,flip)
  if hit or terrain then
   if hit then local profile=type(weapon)=='function'and weapon()or weapon;local event=self:apply(hit,id,actor,profile,step);finishFlight(event and 'contact' or 'contact-rejected',event);if event and options and options.onHit then options.onHit(event)end else finishFlight('terrain')end
   bullet:removeFromParent();return true
  end
  from=to;previous=self.armor:available()and self.armor.target.regions or nil;flip=self.armor.target.model.fliped
  return false
 end)
 return id
end
function P:pendingActor(actor)for _,owner in pairs(self.shotActors)do if owner==actor then return true end end;return false end
function P:apply(hit,id,actor,weapon,step)
 if self.closed or self.battle.phase~='playing' or not hit then return end
 local event
    if hit.enemy then
     local e=hit.enemy;local hp=e.enemyHP;e.enemyHP=math.max(0,hp-weapon.healthDamage)
     event={schemaVersion=1,attackId=id,hitId='impact',source=actor,target=hit.targetId,part='body',weapon=weapon.id,hpBefore=hp,hpAfter=e.enemyHP,apBefore=0,apAfter=0,healthDamage=hp-e.enemyHP,armorDamage=0,armorBroken=false,killed=e.enemyHP==0,position=hit.position,normal=hit.normal,response='stop',summoned=true}
    else event=self.armor:apply(hit,{id=id,contactId='impact',source=actor,weapon=weapon})end

 if event then event.step=step;if self.onHit then self.onHit(event)end end
 return event
end
function P:probeMelee(owner,faceRight)
 if faceRight==nil then faceRight=owner.faceRight end
 return self:contact({x=owner.x,y=owner.y},{x=owner.x+(faceRight and 300 or -300),y=owner.y})
end
function P:melee(owner,actor,step)
 local hit=self:probeMelee(owner)
 self.serial=self.serial+1;local id='yingzhao-melee-'..self.serial
 local e=self:apply(hit,id,actor,require('Combat.WeaponProfiles').melee,step);self.armor:expire(id)
 return e and 1 or 0
end
function P:close()
 if self.closed then return end;self.closed=true
 local bullets={};for b in pairs(self.shots)do bullets[#bullets+1]=b end
 for _,b in ipairs(bullets)do if self.flightEnd[b]then self.flightEnd[b](b.group==D.Platformer.Data.groupHide and 'removed'or'battle-ended')end;if b.parent then b:removeFromParent()end end
 self.view:close();if self.view.node.parent then self.view.node:removeFromParent()end
 self.armor:close()
end
return P
