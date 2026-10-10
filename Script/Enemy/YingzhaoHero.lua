-- Locked, warned rear assault. No damage during retreat or invisible relocation.
local D=require('Dora');local H={};H.__index=H
function H.destination(c,target)
 if not target then return end
 local direction=target.x>=c.unit.x and 1 or -1;local x=target.x+direction*430
 if c.battle.minX and (x<c.battle.minX or x>c.battle.maxX)then return end
 local world=c.battle.world;local feet=c.unit.y-c.unit.unitDef.size.height/2
 if world.sceneWidth and (x<180 or x>world.sceneWidth-180)then return end
 local blocked=false
 world:raycast(D.Vec2(target.x,feet+250),D.Vec2(x,feet+250),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
 for _,height in ipairs({35,250,480})do
  world:raycast(D.Vec2(x-155,feet+height),D.Vec2(x+155,feet+height),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
 end
 local ground
 for _,dx in ipairs({-135,0,135})do
  local floor
  world:raycast(D.Vec2(x+dx,feet+50),D.Vec2(x+dx,feet-70),false,function(body,p)if body.group==D.Platformer.Data.groupTerrain and (not floor or p.y>floor)then floor=p.y end;return false end)
  if not floor then return end
  ground=math.max(ground or floor,floor)
 end
 if blocked then return end
 return {x=x,y=ground+c.unit.unitDef.size.height/2+5,direction=-direction,originalDirection=direction,targetX=target.x}
end
function H.new(c,destination)
 local self=setmetatable({owner=c,destination=destination,stage='hero',started=c.strike.started},H)
 self.record={targetX=destination.targetX,entryX=destination.x,direction=destination.direction,started=self.started,stages={}}
 c.strike.hero=self.record
 self.warning=D.DrawNode();self.warning.order=c.unit.order+1;self.warning:addTo(c.battle.world)
 local y=destination.y-c.unit.unitDef.size.height/2
 self.warning:drawSegment(D.Vec2(destination.x,y+4),D.Vec2(destination.x+destination.direction*1000,y+4),6,D.Color(0x99ef5399))
 for i=0,4 do local x=destination.x+destination.direction*i*220;self.warning:drawSegment(D.Vec2(x,y+25),D.Vec2(x+destination.direction*40,y+4),4,D.Color(0xffffaacd))end
 self:clip('hero');return self
end
function H:clip(name)
 self.stage=name;self.stageStarted=D.App.runningTime;self.record.stages[#self.record.stages+1]={name=name,started=self.stageStarted}
 local c,u=self.owner,self.owner.unit
 if name=='hero2'and not self.entered then
  -- Check the locked location again, without following a target that dodged.
  local destination=H.destination(c,{x=self.destination.targetX})
  if not destination or math.abs(destination.x-self.destination.x)>1 then self.unsafe=true;return end
  self.entered=true;u.position=D.Vec2(self.destination.x,self.destination.y);u.velocity=D.Vec2.zero;c.direction=self.destination.direction
  self.record.reappeared=D.App.runningTime
 end
 -- hero/hero2 are authored facing opposite to idle; hero3 faces idle direction.
 if name=='hero2'then u.faceRight=self.destination.direction<0
 elseif name=='hero3'then u.faceRight=self.destination.direction>0;u.opacity=1;u.velocityX=0 end
end
function H:close(reason)
 if self.closed then return end;self.closed=true
 local u=self.owner.unit;u.opacity=1;u.faceRight=(self.entered and self.destination.direction or self.destination.originalDirection)>0;u.velocityX=0
 self.warning:removeFromParent();self.record.ended=D.App.runningTime;self.record.reason=reason
end
function H:update(now)
 local c,u=self.owner,self.owner.unit
 if not c.busy or c.strike.skill~='hero'then self:close(c.strike.cancelled or 'COMPLETE');return end
 if self.unsafe then c.sequence:cancel('UNSAFE_REENTRY');self:close('UNSAFE_REENTRY');require('CombatAnimation').rest(u);return end
 local elapsed=now-self.stageStarted;local direction,speed
 if self.stage=='hero'then
  u.opacity=math.max(0,1-math.max(0,elapsed-.4)/.9);direction=-self.destination.originalDirection;speed=elapsed>.35 and 220 or 0
 elseif self.stage=='hero2'then
  u.opacity=math.min(1,.45+(now-self.record.reappeared)*3);direction=self.destination.direction;speed=420
 else u.opacity=1;u.velocityX=0;return end
 local x=u.x+direction*190;local feet=u.y-u.unitDef.size.height/2;local blocked=false;local ground=false
 c.battle.world:raycast(u.position,D.Vec2(x,u.y),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
 c.battle.world:raycast(D.Vec2(x,feet+35),D.Vec2(x,feet-65),false,function(body)if body.group==D.Platformer.Data.groupTerrain then ground=true end;return false end)
 u.velocityX=not blocked and ground and direction*speed or 0
 self.warning.opacity=.65+.25*math.sin((now-self.started)*9)
end
return H
