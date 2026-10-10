-- A finite ground-following wave. Small terrain steps prevent crossing gaps/walls.
local D=require('Dora');local K=require('Combat.Displacement');local Contact=require('Enemy.RushContact')
local W={range=1100,bodyPadding=35};W.__index=W
-- Visible telegraph/front only; no hidden destination or future target lookup.
function W.escapeDirection(controller,unit,bossVisible)
 local margin=unit.unitDef.size.width/2+W.bodyPadding+30 -- one controller tick
 for _,wave in ipairs(controller.waves or {})do
  if wave.active and wave.visual.parent and wave.visual.visible then
   local ahead=(unit.x-wave.x)*wave.direction
   if ahead>=-margin and ahead<=math.max(0,W.range-wave.travel)+margin then return wave.direction end
  end
 end
 if bossVisible and controller.unit.playable.current=='wave'then
  local direction=controller.direction or 1
  local ahead=(unit.x-controller.unit.x)*direction
  if ahead>=0 and ahead<=W.range+margin then return direction end
 end
end
local function floorAt(world,x,y)
 local top
 world:raycast(D.Vec2(x,y+45),D.Vec2(x,y-65),false,function(body,p)
  if body.group==D.Platformer.Data.groupTerrain and (not top or p.y>top)then top=p.y end;return false
 end)
 return top
end
function W.new(controller,strike)
 local u=controller.unit;local world=controller.battle.world;local ground=u.y-u.unitDef.size.height/2
 local self=setmetatable({controller=controller,strike=strike,world=world,x=u.x,y=ground,direction=controller.direction,travel=0,last=D.App.runningTime,seen={},previous={},active=true},W)
 self.record={started=self.last,source='dayingzhao',skill='wave',hits={},travel=0};strike.wave=self.record
 self.visual=D.DrawNode();self.visual:addTo(world);self.visual.order=u.order+1
 -- A curved energy crest with a low trailing wake, tinted like the authored axes.
 local crest={};local edge={}
 for i=0,16 do local t=i/16;local x=48*math.sin(math.pi*t)-18*t;local y=155*t;edge[#edge+1]=D.Vec2(x,y);crest[#crest+1]=D.Vec2(x,y)end
 for i=16,0,-1 do local t=i/16;crest[#crest+1]=D.Vec2(48*math.sin(math.pi*t)-18*t-28*math.sin(math.pi*t),155*t)end
 self.visual:drawPolygon(crest,D.Color(0xccf63292))
 for i=2,#edge do self.visual:drawSegment(edge[i-1],edge[i],3,D.Color(0xffffb5ec))end
 self.visual:drawPolygon({D.Vec2(-130,0),D.Vec2(-25,22),D.Vec2(20,14),D.Vec2(45,0)},D.Color(0x66ef3c93))
 for i=1,5 do self.visual:drawSegment(D.Vec2(-i*22,4+i%2*6),D.Vec2(-i*22+14,9+i%2*6),2,D.Color(0xfffa90cd))end
 self.visual.scaleX=self.direction;self.visual.position=D.Vec2(self.x,self.y)
 for _,t in ipairs(controller.battle:targets())do self.previous[t.unit]={x=t.unit.x,y=t.unit.y}end
 return self
end
function W:stop(reason)
 if not self.active then return end
 self.active=false;self.record.ended=D.App.runningTime;self.record.reason=reason;self.record.travel=self.travel
 self.visual:removeFromParent()
end
function W:update(now)
 if not self.active then return end
 local c=self.controller
 if c.battle.phase~='playing'or c.record.enemyHP<=0 then self:stop(c.record.enemyHP<=0 and 'DEFEATED'or'BATTLE_ENDED');return end
 local amount=math.min(math.max(0,now-self.last)*780,W.range-self.travel);self.last=now
 local steps=math.max(1,math.ceil(amount/30));local targets=c.battle:targets()
 for step=1,steps do
  local oldX,oldY=self.x,self.y;local x=oldX+self.direction*amount/steps
  local blocked=false
  self.world:raycast(D.Vec2(oldX,oldY+35),D.Vec2(x,oldY+35),false,function(body)if body.group==D.Platformer.Data.groupTerrain then blocked=true end;return false end)
  if blocked then self:stop('WALL');return end
  local ground=floorAt(self.world,x,oldY)
  if not ground then self:stop('GAP');return end
  self.x,self.y=x,ground;self.travel=self.travel+amount/steps
  for _,t in ipairs(targets)do
   local u=t.unit
   if not self.seen[u]and t.hp()>0 then
    local old=self.previous[u]or{x=u.x,y=u.y};local f0=(step-1)/steps;local f1=step/steps
    local px=old.x+(u.x-old.x)*f0;local py=old.y+(u.y-old.y)*f0
    local nx=old.x+(u.x-old.x)*f1;local ny=old.y+(u.y-old.y)*f1
    local size=u.unitDef.size
    local hit=Contact.hit({x=px-oldX,y=py-(oldY+65)},{x=nx-x,y=ny-(ground+65)},size.width/2+W.bodyPadding,size.height/2+65,self.direction>0)
    if hit then
     -- Terrain between the travelling front and a target wins over its body radius.
     local wall=false;self.world:raycast(D.Vec2(x,ground+35),D.Vec2(u.x,ground+35),false,function(body)if body.group==D.Platformer.Data.groupTerrain then wall=true end;return false end)
     if not wall then
      self.seen[u]=true;t.damage(16,{kind='enemy-wave',attacker=c.unit,skill='wave',strikeStarted=self.strike.started,attackerId=self.strike.source,hitIndex=1})
      self.strike.hits=self.strike.hits+1;self.record.hits[#self.record.hits+1]={actor=u.entity.name,at=now,x=u.x,y=u.y,damage=16}
      K.apply({unit=u,immovable=t.immovable,displacementScale=t.displacementScale,alive=function()return t.hp()>0 end,onForcedMovement=t.onForcedMovement},self.direction*1100,720,self.strike)
     end
    end
   end
  end
 end
 for _,t in ipairs(targets)do self.previous[t.unit]={x=t.unit.x,y=t.unit.y}end
 self.visual.position=D.Vec2(self.x,self.y);self.visual.scaleY=.95+.05*math.sin(self.travel/35);self.record.travel=self.travel
 if self.travel>=W.range-.001 then self:stop('RANGE')end
end
return W
