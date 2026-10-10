-- The commander owns summon updates; the battle owns their damage/target registration.
local D=require('Dora');local Small=require('Enemy.SmallYingzhao');local H={};H.__index=H
function H.new(owner)return setmetatable({owner=owner,children={},history={},serial=0},H)end
function H:retire(index,reason)
 local child=table.remove(self.children,index);if not child then return end
 child.guard.sequence:cancel(reason);child.log.ended=D.App.runningTime;child.log.reason=reason;child.log.strikes=child.guard.strikes
 local enemies=self.owner.battle.enemies
 if enemies then for i=#enemies,1,-1 do if enemies[i]==child then table.remove(enemies,i);break end end end
 local entity=child.enemy.entity;child.enemy:removeFromParent();if entity then entity:destroy()end
end
function H:clear(reason)for i=#self.children,1,-1 do self:retire(i,reason)end end
function H:spawn(strike)
 local c=self.owner;local b,u=c.battle,c.unit
 local info={at=D.App.runningTime,limit=2,spawned=0,blocked=#self.children>=2,children={}};strike.summons=info
 if info.blocked then return end
 local target,distance
 for _,t in ipairs(b:targets())do local d=math.abs(t.unit.x-u.x);if t.hp()>0 and (not distance or d<distance)then target=t.unit;distance=d end end
 if not target then info.reason='NO_TARGET';return end
 for _,offset in ipairs({160,350})do
  if #self.children>=2 then break end
  local x=u.x+c.direction*offset;local floor;local blocked=false
  b.world:raycast(u.position,D.Vec2(x,u.y),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
  local feet=u.y-u.unitDef.size.height/2
  b.world:raycast(D.Vec2(x,feet+70),D.Vec2(x,feet-90),false,function(body,p)if body.group==D.Platformer.Data.groupTerrain and (not floor or p.y>floor)then floor=p.y end;return false end)
  -- Keep reinforcements out of walls, gaps and existing living summons.
  for _,child in ipairs(self.children)do if math.abs(child.enemy.x-x)<170 then blocked=true end end
  if floor and not blocked then
   self.serial=self.serial+1
   local child={enemy=Small.create(b.world,x),enemyHP=70,summonOwner=c,combatSource='yingzhao-summon-'..self.serial}
   child.enemy.y=floor+105;child.enemy.faceRight=c.direction>0
   child.guard=Small.new(b,child);child.guard.nextAttack=math.huge;child.pendingPounce=target
   local summonId=self.serial;local attack=child.guard.attack
   child.guard.attack=function(guard,skill,selected)
    local ok,why=attack(guard,skill,selected)
    if ok then guard.strike.summonId=summonId;guard.strike.commander='dayingzhao';guard.strike.summonedAt=info.at end
    return ok,why
   end
   child.log={id=self.serial,started=D.App.runningTime,x=x,hp=70,strikes=child.guard.strikes};self.history[#self.history+1]=child.log
   self.children[#self.children+1]=child;info.children[#info.children+1]=self.serial;info.spawned=info.spawned+1
   if b.enemies then b.enemies[#b.enemies+1]=child end
  end
 end
 if info.spawned==0 then info.reason='NO_SAFE_SPAWN'end
end
function H:update(now)
 local c=self.owner
 if c.battle.phase~='playing'or c.record.enemyHP<=0 then self:clear(c.record.enemyHP<=0 and 'COMMANDER_DEFEATED'or'BATTLE_ENDED');return end
 for i=#self.children,1,-1 do
  local child=self.children[i];local guard=child.guard
  if child.pendingPounce and child.enemyHP>0 and child.enemy.onSurface then
   local target=child.pendingPounce;child.pendingPounce=nil
   if target.parent and guard:attack('jump',target)then child.log.commandedAt=now end
  end
  guard:update(now)
  if guard.dead then child.log.loseStarted=guard.loseStarted;child.log.loseEnded=guard.loseEnded;self:retire(i,'DEFEATED')end
 end
end
return H
