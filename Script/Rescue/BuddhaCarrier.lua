-- Visual carrier lifecycle; callers retain ownership of travel and combat state.
local D=require('Dora');local Carrier={};Carrier.__index=Carrier
function Carrier.new(parent,x,y,riderAsset,style)
 local self=setmetatable({node=D.Node(),phase='ground',weight=0,alive=true,events={},completed={}},Carrier)
 self.node.position=D.Vec2(x,y);self.node:addTo(parent)
 self.robot=require('Rescue.BuddhaPrototype').create(style);self.robot.y=320;self.robot.opacity=0;self.robot:addTo(self.node)
 self.rider=assert(D.Spine(riderAsset));self.rider.order=1;self.rider.recovery=.2;self.rider:play('idle',true);self.rider:addTo(self.node)
 self.handPoint=style and style.handPoint or D.Vec2(310,250)
 self.ready=false
 self.hands={};for _,arm in ipairs(self.robot.arms)do if arm.index==3 then self.hands[#self.hands+1]=arm.hand end end
 self.node:slot('Cleanup',function()self.alive=false end)
 self.rider:slot('AnimationEnd',function(name)
  self.completed[name]=(self.completed[name]or 0)+1
  local active=self.active
  if active and active.started and active.name==name then active.completedEventAt=D.App.runningTime end
 end)
 local tick=D.Node();tick:addTo(self.node);tick:schedule(function()
  if not self.alive then return true end
  self.ready=true
  local a=self.node:convertToNodeSpace(self.hands[1]:convertToWorldSpace(self.handPoint))
  local b=self.node:convertToNodeSpace(self.hands[2]:convertToWorldSpace(self.handPoint))
  self.seat=(a+b)*.5-D.Vec2(5,75)
  self.rider.position=self.seat*self.weight
  self.robot.opacity=self.weight
  return false
 end)
 return self
end
function Carrier:transitionAsync(mount)
 if not self.alive then return nil,'CLOSED' end
 if self.active then return nil,'BUSY' end
 local source=mount and 'ground' or 'riding'
 if self.phase~=source then return nil,'WRONG_PHASE' end
 local name=mount and 'sit' or 'stand';self.phase=mount and 'mounting' or 'landing'
 -- These authored clips have identical endpoints. Recovery is used when
 -- returning to the original idle, not to add a setup-pose bridge mid-transfer.
 local active={name=name};self.active=active
 -- A freshly created scene may still be processing its first large frame delta.
 -- Wait for the carrier scheduler to enter before starting a finite clip.
 while self.alive and not self.ready do D.sleep() end
 if not self.alive then self.active=nil;return nil,'CLOSED' end
 self.rider.recovery=0;local duration=self.rider:play(name,false);assert(duration>0,'Missing carrier animation: '..name)
 active.started=D.App.runningTime;active.duration=duration
 local from,to=mount and 0 or 1,mount and 1 or 0
 while self.alive and (not active.completedEventAt or D.App.runningTime-active.started<duration) do
  local elapsed=D.App.runningTime-active.started
  assert(elapsed<duration+1,'Carrier animation did not complete: '..name)
  local t=math.min(1,elapsed/duration);self.weight=from+(to-from)*t*t*(3-2*t)
  D.sleep()
 end
 if not self.alive then self.active=nil;return nil,'CLOSED' end
 active.ended=D.App.runningTime
 self.weight=to;self.phase=mount and 'riding' or 'ground';self.events[#self.events+1]=active;self.active=nil
 self.rider.recovery=mount and 0 or .2;self.rider:play(mount and 'ride' or 'idle',true)
 return true
end
function Carrier:mountAsync()return self:transitionAsync(true)end
function Carrier:landAsync()return self:transitionAsync(false)end
function Carrier:guard(value)self.robot:emit('Guard',value)end
function Carrier:dispose()self.node:removeFromParent()end
return Carrier
