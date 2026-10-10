-- Large-Yingzhao authored skills; formal encounter/armor is integrated separately.
local D=require('Dora');local A=require('CombatAnimation');local Base=require('Enemy.SmallYingzhao');local K=require('Combat.Displacement')
local Rules=require('Enemy.BigYingzhaoRules')
local E=setmetatable({asset='dayingzhao'},{__index=Base});E.__index=E
function E.loadAsync()D.Cache:loadAsync({'spine:dayingzhao-hitboxes.skel|dayingzhao.atlas','spine:xiaoyingzhao'})end
function E.create(world,x)
 local def=D.Dictionary();def.playable='spine:dayingzhao-hitboxes.skel|dayingzhao.atlas';def.bodyType='Dynamic';def.size=D.Size(300,500);def.density=1;def.friction=1;def.linearAcceleration=D.Vec2(0,-15);def.defaultFaceRight=false;def.scale=1;def.actions=D.Array({})
 local marker=D.Node();D.Entity({yingzhao=true,name='dayingzhao',spawnMarker=marker})
 local entity=assert(D.Group({'yingzhao','spawnMarker'}):find(function(e)return e.spawnMarker==marker end))
 local u=assert(D.Platformer.Unit(def,world,entity,D.Vec2(x,world.offset+255)));entity.unit=u;u.group=2;u.playable.y=-250;u:addTo(world);world:addShadowTo(u);A.configure(u,E.asset);A.rest(u);return u
end
function E.new(battle,record)
 local self=setmetatable(Base.new(battle,record),E);self.timeline=require('Enemy.BigYingzhaoTimeline');self.reactionCooldown=3.8;self.maxHP=record.enemyHP;self.nextHero=D.App.runningTime+8;self.nextWave=0;self.waves={};self.hunt=require('Enemy.YingzhaoHunt').new(self);self.unit:slot('Cleanup',function()if self.hero then self.hero:close('CLEANUP')end;self.hunt:clear('CLEANUP');for _,w in ipairs(self.waves)do w:stop('CLEANUP')end end);return self
end
function E:onClip(name)if self.hero and not self.hero.closed then self.hero:clip(name)end end
-- Completed heavy attacks leave a visible opening for whole-party movement.
-- Authored clip tails and impact frames are still played at their original speed.
function E:recoveryDuration(skill)return Rules.recovery[skill]or .9 end
function E:chooseSkill(distance,target)
 if self.record.enemyHP<=self.maxHP*.5 and D.App.runningTime>=self.nextHero and require('Enemy.YingzhaoHero').destination(self,target)then return 'hero'end
 if #self.hunt.children==0 and D.App.runningTime>=(self.nextHunt or 0)then return 'hunt'end
 return distance>650 and D.App.runningTime>=self.nextWave and 'wave'or distance>260 and 'massive'or'punch'end
function E:approachRange()
 -- Close for the advancing melee combo while the ranged attack recovers.
 return D.App.runningTime>=self.nextWave and 1000 or 650
end
function E:attack(skill,target)
 if skill~='punch'and skill~='massive'and skill~='wave'and skill~='hunt'and skill~='hero'then return false,'SKILL_NOT_IMPLEMENTED'end
 if skill=='hunt'and #self.hunt.children>=2 then return false,'SUMMON_LIMIT'end
 if skill=='wave'and D.App.runningTime<self.nextWave then return false,'COOLDOWN'end
 local destination
 if skill=='hero'then destination=require('Enemy.YingzhaoHero').destination(self,target);if not destination then return false,'NO_SAFE_REENTRY'end end
 local ok,why=Base.attack(self,skill,target)
 if ok then self.strike.source='dayingzhao';
  -- Reserve on accepted windup; taking a hit must not reset the skill clock.
  if skill=='wave'then self.nextWave=self.strike.started+Rules.waveCooldown end;if skill=='hero'then self.hero=require('Enemy.YingzhaoHero').new(self,destination);self.nextHero=D.App.runningTime+18 end;if skill=='hunt'then self.nextHunt=D.App.runningTime+14 end end
 return ok,why
end
function E:impact(name)
 local b,u=self.battle,self.unit;local strike=self.strike
 if b.phase~='playing'or self.record.enemyHP<=0 then return end
 if name=='hunt'then
  strike.impacts[#strike.impacts+1]={clip=name,at=D.App.runningTime,x=u.x,y=u.y};self.hunt:spawn(strike);return
 end
 if name=='wave'then
  strike.impacts[#strike.impacts+1]={clip=name,at=D.App.runningTime,x=u.x,y=u.y}
  self.waves[#self.waves+1]=require('Enemy.GroundWave').new(self,strike);return
 end
 local impact={clip=name,at=D.App.runningTime,x=u.x,y=u.y,targets={}}
 strike.impacts[#strike.impacts+1]=impact
 -- An area strike hits every living front target once, even if a host returns duplicates.
 local seen={}
 for _,t in ipairs(b:targets())do
  local dx=(t.unit.x-u.x)*self.direction
  if not seen[t.unit]and t.hp()>0 and dx>=0 and dx<=self.timeline.meleeReach and math.abs(t.unit.y-u.y)<=self.timeline.meleeVerticalReach then
   seen[t.unit]=true;local blocked=false
   b.world:raycast(u.position,t.unit.position,false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
   if not blocked then
    local damage=(name=='hero2'or name=='hero3')and 8 or name=='massive'and 10 or 18
    t.damage(damage,{kind='enemy-melee',attacker=u,skill=strike.skill,strikeStarted=strike.started,attackerId=strike.source,hitIndex=#strike.impacts})
    strike.hits=strike.hits+1;impact.targets[#impact.targets+1]={actor=t.unit.entity.name,damage=damage}
    if name=='massive'or name=='hero3'then K.apply({unit=t.unit,immovable=t.immovable,displacementScale=t.displacementScale,alive=function()return t.hp()>0 end,onForcedMovement=t.onForcedMovement},self.direction*1000,650,strike)end
   end
  end
 end
end
function E:update(now)
 Base.update(self,now)
 if self.hero and not self.hero.closed then self.hero:update(now)end
 self.hunt:update(now)
 for i=#self.waves,1,-1 do local w=self.waves[i];w:update(now);if not w.active then table.remove(self.waves,i)end end
 if self.busy and self.strike.skill=='massive'then
  local elapsed=now-self.strike.started;local u=self.unit
  local motion=self.timeline.massiveMotion
  if elapsed>=motion.start and elapsed<=motion.finish then
   local blocked=false;local ground=false;local x=u.x+self.direction*180
   self.battle.world:raycast(u.position,D.Vec2(x,u.y),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
   self.battle.world:raycast(D.Vec2(x,u.y-220),D.Vec2(x,u.y-390),false,function(body)if body.group==D.Platformer.Data.groupTerrain then ground=true end;return false end)
   u.velocityX=not blocked and ground and self.direction*motion.speed or 0
  else u.velocityX=0 end
 end
end
return E
