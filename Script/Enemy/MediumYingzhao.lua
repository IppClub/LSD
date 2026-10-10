-- Medium Yingzhao shares finite-action, hit-recovery and death lifecycle with
-- the small unit; theft has its own distance/terrain check and weapon lease.
local D=require('Dora');local A=require('CombatAnimation');local Base=require('Enemy.SmallYingzhao');local Disarm=require('Combat.Disarm')
local Firearm=require('Enemy.StolenFirearm')
local E=setmetatable({asset='zhongyingzhao-weapon.skel|zhongyingzhao.atlas'},{__index=Base});E.__index=E
function E.create(world,x)
 local def=D.Dictionary();def.playable='spine:'..E.asset;def.bodyType='Dynamic';def.size=D.Size(200,420);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=false;def.scale=1;def.actions=D.Array({})
 local marker=D.Node();D.Entity({yingzhao=true,name='zhongyingzhao',spawnMarker=marker});local entity=assert(D.Group({'yingzhao','spawnMarker'}):find(function(e)return e.spawnMarker==marker end))
 local u=assert(D.Platformer.Unit(def,world,entity,D.Vec2(x,world.offset+215)));entity.unit=u;u.group=2;u.playable.y=-210;u:addTo(world);world:addShadowTo(u);A.configure(u,E.asset);A.rest(u);return u
end
-- The 2.67s rob windup plus hit recovery needs a longer flinch grace than
-- the small unit. Damage and weapon-return checks remain active throughout.
function E.new(battle,record)
 local self=setmetatable(Base.new(battle,record),E);self.timeline=require('Enemy.MediumYingzhaoTimeline');self.reactionCooldown=3.8;self.unit:slot('Cleanup',function()Firearm.clear(self)end);return self
end
function E:onClip(name)
 self.unit.velocityX=name=='rob2' and self.direction*420 or 0
end
function E:chooseSkill(distance,target)
 if self.lease and self.lease.active then return distance>=250 and Firearm.canFire(self) and 'shoot' or 'punch'end
 if target.data.combatWeaponAsset and not target.data.weaponDisarmed and D.App.runningTime>=(self.nextRob or 0) then return 'rob'end
 return 'punch'
end
function E:approachRange(target,distance)
 if Firearm.canFire(self) then return 1200 end
 -- Close into actual fist reach while theft is recovering, rather than
 -- repeatedly punching from the longer charge-start distance.
 if target and self:chooseSkill(distance,target)=='punch' then return 200 end
 return 310
end
function E:attack(skill,target)
 if skill=='shoot' and not Firearm.canFire(self)then return false,'WEAPON_UNAVAILABLE'end
 local ok,why=Base.attack(self,skill,target)
 if ok then
  self.strike.source='zhongyingzhao';self.chargeTarget=target
  if skill=='rob' then self.nextRob=D.App.runningTime+6 end
  if skill=='shoot' then self.shotAim={lease=self.lease,target=D.Vec2(target.x,target.y),rotation=0};self.unit.playable:setBoneRotation('weapon-aim',0)end
 end
 return ok,why
end
function E:impact(name)
 if name=='shoot' then return Firearm.fire(self)end
 if name~='rob3' then
  -- A normal fist has no hoof knockback; only the original 10 HP hit response.
  return Base.impact(self,name)
 end
 local b,u=self.battle,self.unit;local strike=self.strike
 if b.phase~='playing' or self.record.enemyHP<=0 then return end
 local selected,distance
 for _,target in ipairs(b:targets())do
  local dx=(target.unit.x-u.x)*self.direction
  if target.hp()>0 and target.unit.data.combatWeaponAsset and not target.unit.data.weaponDisarmed and dx>=0 and dx<=240 and math.abs(target.unit.y-u.y)<=240 and (not distance or dx<distance)then
   local blocked=false;b.world:raycast(u.position,target.unit.position,false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
   if not blocked then selected=target;distance=dx end
  end
 end
 strike.impacts[#strike.impacts+1]={clip=name,at=D.App.runningTime,x=u.x,y=u.y}
 if selected then
  local lease,why=Disarm.take(selected.unit,u,{leftAuthored=true,duration=6,valid=function()return b.phase=='playing' and self.record.enemyHP>0 and selected.hp()>0 end})
  strike.disarmReason=why
  if lease then self.lease=lease;strike.disarmed=true;strike.weapon=lease.asset;strike.takenAt=lease.started;u.data.combatRest='gunidle' end
 end
end
-- After closing in to steal, turn and move away before firing. Hysteresis
-- prevents switching between move/idle at a single distance boundary.
function E:spaceForShot(now)
 local u,b=self.unit,self.battle
 local allowed=Firearm.canFire(self) and b.phase=='playing' and self.record.enemyHP>0 and self.record.enemyHP==self.lastHP and not self.busy and not self.reacting and not self.dying and u.onSurface
 if not allowed then
  if self.repositioning then self.repositioning.reason='INTERRUPTED';self.repositioning.ended=now;self.repositioning=nil;u.velocityX=0;self.approaching=false end
  return false
 end
 if now<self.nextAttack or now<(self.spacingRetry or 0)then return false end
 local target,distance
 for _,t in ipairs(b:targets())do
  local d=math.abs(t.unit.x-u.x)
  if t.hp()>0 and (not distance or d<distance)then target=t.unit;distance=d end
 end
 if not target then return false end
 if not self.repositioning and distance>=360 then return false end
 local move=self.repositioning
 if not move then
  move={started=now,startX=u.x,direction=u.x>=target.x and 1 or -1};self.repositioning=move
  self.spacingMoves=self.spacingMoves or {};self.spacingMoves[#self.spacingMoves+1]=move
 end
 local reason
 if distance>=550 then reason='IN_RANGE'
 elseif now-move.started>=1.2 then reason='TIME_LIMIT'
 else
  local x=u.x+move.direction*100;local blocked=false;local ground=false
  b.world:raycast(u.position,D.Vec2(x,u.y),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
  b.world:raycast(D.Vec2(x,u.y-180),D.Vec2(x,u.y-330),false,function(body)if body.group==D.Platformer.Data.groupTerrain then ground=true end;return false end)
  if blocked then reason='WALL'elseif not ground then reason='LEDGE'end
 end
 if reason then
  move.reason=reason;move.ended=now;move.endX=u.x;self.repositioning=nil;self.spacingRetry=now+1.5;self.approaching=false;u.velocityX=0;A.rest(u);return false
 end
 u.faceRight=move.direction>0;u.velocityX=move.direction*260
 if not self.approaching then self.approaching=true;A.play(u,'move',true)end
 return true
end
function E:update(now)
 -- Ground friction consumes a one-off velocity assignment. Drive only the
 -- authored charge clip, then stop on contact range or clip completion.
 if self.busy and self.unit.playable.current=='rob2' and self.chargeTarget then
  self.unit.velocityX=(self.chargeTarget.x-self.unit.x)*self.direction>120 and self.direction*420 or 0
 end
 if self.lease and self.lease.active and (self.battle.phase~='playing' or self.record.enemyHP<self.lastHP)then Disarm.release(self.lease,self.record.enemyHP<=0 and 'DEFEATED' or self.battle.phase~='playing' and 'BATTLE_ENDED' or 'HIT')end
 self.unit.data.combatRest=self.lease and self.lease.active and 'gunidle' or 'idle'
 if self.busy and self.strike.skill=='shoot' and (not self.shotAim or not self.shotAim.lease.active)then self.sequence:cancel('WEAPON_RETURNED');self.nextAttack=now+.9 end
 Firearm.update(self,now)
 if self:spaceForShot(now)then return end
 Base.update(self,now)
 if not self.busy and not self.reacting and not self.dying and not self.approaching then A.rest(self.unit)end
end
return E
