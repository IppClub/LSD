-- Root movement follows the planted hand evaluated by native Spine.
-- This controller does not implement entering or vaulting out of the wall.
local D=require('Dora');local Climb={duration=2.4,rise=60}
local cache
function Climb.definition(name)
 if not cache then cache=assert(D.json.decode(D.Content:load('Spine/Roof/climb-authoring.json')))end
 for _,row in ipairs(cache)do if row.name==name then return row end end
 error('Unknown climbing rig: '..tostring(name))
end
function Climb.attach(model,name)
 local def=Climb.definition(name)
 local c={model=model,definition=def,originX=model.x,originY=model.y,cycle=0,support='HandL',paused=true,started=false,closed=false,samples=0,maxSupportError=0}
 local function changeRight()if c.started and not c.closed then c.support='HandR' end end
 local function changeLeft()if c.started and not c.closed then c.cycle=c.cycle+1;c.support='HandL' end end
 model:slot('roofGripRight',changeRight);model:slot('roofGripLeft',changeLeft)
 function c:point(key)
  local p=self.model:getKey('climb'..key..'/climb'..key)
  return D.Vec2(self.model.x+p.x*self.model.scaleX,self.model.y+p.y*self.model.scaleY)
 end
 function c:hold(key,row)
  local h=self.definition[key]
  return D.Vec2(self.originX+h.x*self.model.scaleX,self.originY+(h.highY-Climb.rise*h.phase+Climb.rise*row)*self.model.scaleY)
 end
 function c:start()
  if self.closed then return false end
  if not self.started then
   self.started=true;self.model.speed=1;self.model.recovery=0;self.model:play('climb',true)
  end
  self.paused=false;self.model.speed=1;return true
 end
 function c:pause()self.paused=true;self.model.speed=0 end
 function c:update()
  if self.closed or not self.started or self.paused then return end
  local row=self.cycle+(self.support=='HandR' and 1 or 0)
  local target=self:hold(self.support,row);local p=self:point(self.support)
  self.model.y=self.model.y+target.y-p.y
  self.samples=self.samples+1;local actual=self:point(self.support)
  self.maxSupportError=math.max(self.maxSupportError,math.abs(actual.y-target.y),math.abs(actual.x-target.x))
 end
 function c:dispose()self.closed=true;self:pause();model:slot('roofGripRight'):remove(changeRight);model:slot('roofGripLeft'):remove(changeLeft)end
 return c
end
return Climb
