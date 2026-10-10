local D=require('Dora');local A=require('CombatAnimation');local Sequence=require('Enemy.Sequence')
local Timeline=require('Enemy.SmallYingzhaoTimeline');local K=require('Combat.Displacement')
local E={};E.__index=E
function E.create(world,x)
 local def=D.Dictionary();def.playable='spine:xiaoyingzhao';def.bodyType='Dynamic';def.size=D.Size(160,200);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=false;def.scale=1;def.actions=D.Array({})
 local marker=D.Node();D.Entity({yingzhao=true,name='xiaoyingzhao',spawnMarker=marker})
 local entity=assert(D.Group({'yingzhao','spawnMarker'}):find(function(e)return e.spawnMarker==marker end))
 local u=assert(D.Platformer.Unit(def,world,entity,D.Vec2(x,world.offset+105)));entity.unit=u;u.group=2;u.playable.y=-100;u:addTo(world);world:addShadowTo(u);A.configure(u,'xiaoyingzhao');A.rest(u);return u
end
function E.new(battle,record)
 local self=setmetatable({battle=battle,record=record,unit=record.enemy,lastHP=record.enemyHP,strikes={},hits={},nextAttack=0,serial=0},E)
 self.sequence=Sequence.new({now=function()return D.App.runningTime end,
  play=function(name,serial,index)
   local u=self.unit;local clip={name=name,started=D.App.runningTime};self.strike.clips[#self.strike.clips+1]=clip
   self.activeSerial,self.activeIndex=serial,index
   if self.onClip then self:onClip(name)
   elseif name=='jump2' then u.velocityX=self.direction*420;u.velocityY=320
   elseif name=='jump3' or name=='jump4' then u.velocityX=0 end
   clip.duration=A.play(u,name,false);return clip.duration
  end,
  impact=function(name)self:impact(name)end,
  complete=function()
   local now=D.App.runningTime
   local recovery=self.recoveryDuration and self:recoveryDuration(self.strike.skill)or .9
   self.strike.completed=now;self.busy=false;self.unit.velocityX=0
   self.nextAttack=now+recovery;self.strike.recoveryDuration=recovery;self.strike.recoveryUntil=self.nextAttack
   A.rest(self.unit)
  end,
  stop=function(reason)
   self.strike.cancelled=reason;self.busy=false
   -- PhysicsWorld clears bodies before children receive Cleanup. Cancellation
   -- still seals the sequence, but must not mutate a destroyed body.
   if reason~='CLEANUP'then self.unit.velocityX=0 end
  end})
 self.unit.playable:slot('AnimationEnd',function(name)
  if self.sequence:ended(name,self.activeSerial,self.activeIndex) then self.strike.clips[#self.strike.clips].ended=D.App.runningTime end
 end)
 return self
end
function E:impact(name)
 local b,u=self.battle,self.unit
 if b.phase~='playing' or self.record.enemyHP<=0 then return end
 local strike=self.strike;local selected,distance
 for _,t in ipairs(b:targets())do
  local dx=(t.unit.x-u.x)*self.direction;local dy=math.abs(t.unit.y-u.y)
  if t.hp()>0 and dx>=0 and dx<=220 and dy<=240 and (not distance or dx<distance)then
   local blocked=false
   b.world:raycast(u.position,t.unit.position,false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
   if not blocked then selected=t;distance=dx end
  end
 end
 local damage=strike.skill=='kick' and 12 or 10
 local impact={clip=name,at=D.App.runningTime,x=u.x,y=u.y,targets={}}
 strike.impacts[#strike.impacts+1]=impact
 if selected then
  impact.targets[1]={actor=selected.unit.entity.name,damage=damage}
  selected.damage(damage,{kind='enemy-melee',attacker=u,skill=strike.skill,strikeStarted=strike.started,attackerId=strike.source,hitIndex=#strike.impacts});strike.hits=strike.hits+1
  K.apply({unit=selected.unit,immovable=selected.immovable,displacementScale=selected.displacementScale,alive=function()return selected.hp()>0 end,onForcedMovement=selected.onForcedMovement},self.direction*(strike.skill=='kick' and 650 or 280),strike.skill=='kick' and 250 or 120,strike)
 end
end
function E:attack(skill,target)
 if self.busy or self.reacting or self.record.enemyHP<=0 or self.battle.phase~='playing' or not self.unit.onSurface then return false end
 local u=self.unit;u.faceRight=target.x>=u.x;self.direction=u.faceRight and 1 or -1;u.velocityX=0;self.approaching=false
 self.strike={skill=skill,kind=skill,source=self.record.combatSource or 'xiaoyingzhao',started=D.App.runningTime,hits=0,clips={},impacts={}};self.strikes[#self.strikes+1]=self.strike;self.busy=true
 return self.sequence:start((self.timeline or Timeline).stages(skill))
end
function E:update(now)
 local u=self.unit;local hp=self.record.enemyHP
 if self.approaching then self.approachTravel=(self.approachTravel or 0)+math.abs(u.x-(self.lastX or u.x));self.lastX=u.x end
 if hp<=0 then
  if not self.dying then
   self.sequence:cancel('DEFEATED');self.dying=true;self.busy=false;self.approaching=false;u.velocityX=0;u.group=3;self.loseStarted=now;self.loseDuration=A.play(u,'lose',false)
  elseif u.data.combatCompletedName=='lose' and u.data.combatCompletedAt>=self.loseStarted then self.dead=true;self.loseEnded=u.data.combatCompletedAt end
  self.lastHP=hp;return
 end
 if self.battle.phase~='playing' then self.sequence:cancel('BATTLE_ENDED');u.velocityX=0;self.approaching=false;if not self.reacting then A.rest(u)end;return end
 if hp<self.lastHP then
  local react=not self.reacting and now>=(self.nextReaction or 0)
  self.hits[#self.hits+1]={at=now,damage=self.lastHP-hp,reacted=react,clip=u.playable.current}
  -- Keep damage, but do not restart hit every projectile or let a team volley
  -- permanently pin the unit between hit recovery and attack preparation.
  if react then
   self.sequence:cancel('HIT');self.reacting=now;self.nextReaction=now+(self.reactionCooldown or 1.2);self.approaching=false;u.velocityX=0;A.play(u,'hit',false)
  end
 end
 self.lastHP=hp
 if self.reacting then
  if u.data.combatCompletedName=='hit' and u.data.combatCompletedAt>=self.reacting then self.reacting=nil;self.nextAttack=math.max(self.nextAttack,now+.15);A.rest(u)end
  return
 end
 if self.busy then self.sequence:update();return end
 if now<self.nextAttack or not u.onSurface then return end
 local selected,distance
 for _,t in ipairs(self.battle:targets())do local d=math.abs(t.unit.x-u.x);if t.hp()>0 and (not distance or d<distance)then selected=t.unit;distance=d end end
 if not selected then u.velocityX=0;self.approaching=false;A.rest(u);return end
 if distance>(self.approachRange and self:approachRange(selected,distance) or 310)then
  u.faceRight=selected.x>=u.x;u.velocityX=u.faceRight and 180 or -180
  if not self.approaching then self.approaching=true;self.lastX=u.x;A.play(u,'move',true)end
 else self:attack(self.chooseSkill and self:chooseSkill(distance,selected) or (distance<=180 and 'kick' or 'jump'),selected)end
end
return E
