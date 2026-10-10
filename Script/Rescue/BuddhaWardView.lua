-- Optional presentation binding. Protection remains exclusively owned by Ward.
local D=require('Dora');local View={};View.__index=View
function View.new(parent,ward,x,y)
 local root=D.Node();root.position=D.Vec2(x,y);root.order=-2;root:addTo(parent)
 local model=require('Rescue.BuddhaPrototype').create();model:addTo(root)
 root.opacity=0;root.visible=false
 return setmetatable({root=root,model=model,ward=ward,phase='hidden',elapsed=0,shown=false,hits=ward.hits,pulses=0},View)
end
function View:update(dt)
 local w=self.ward;local shown=w.active and w.remaining>0
 if shown~=self.shown then
  self.shown=shown;self.elapsed=0;self.startOpacity=self.root.opacity;self.phase=shown and 'summoning'or'retracting';self.root.visible=true
  self.model:emit('Guard',shown)
 end
 self.elapsed=self.elapsed+dt
 if self.phase=='summoning'or self.phase=='retracting'then
  local duration=self.shown and .6 or .4;local t=math.min(1,self.elapsed/duration);local eased=t*t*(3-2*t)
  self.root.opacity=self.startOpacity+((self.shown and 1 or 0)-self.startOpacity)*eased
  if t==1 then self.phase=self.shown and 'guard'or'hidden';self.root.visible=self.shown end
 end
 if w.hits>self.hits then
  self.pulses=self.pulses+w.hits-self.hits;self.model:emit('Pulse')
 end
 self.hits=w.hits
end
function View:dispose()self.root:removeFromParent()end
return View
