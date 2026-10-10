-- Stateful original-art auxiliary machine. Every one-shot finishes before recovery.
local D=require('Dora')
local Actor={}
Actor.variants={{id='defence',name='护盾机'},{id='cargo',name='装备机'},{id='mobility',name='悬浮机'}}
function Actor.create(variant)
 variant=variant or 'defence'
 local root=D.Node(); local model=require('Ground.AuxiliaryModel').create(variant); model:addTo(root)
 local scale=variant=='cargo' and .65 or variant=='defence' and 1.15 or .9
 model.scaleX=scale; model.scaleY=scale; model.y=variant=='mobility' and 90 or variant=='cargo' and 12 or 0
 local fx=D.DrawNode(); fx.order=2; fx:addTo(root)
 local a={node=root,model=model,variant=variant,state='deploy',desired='idle',queue={},history={},completed={},eventCounts={},revealUntil=D.App.runningTime+2,active=true,energy=45,hp=100,time=0,scale=scale}
 local function start(name,loop)
  a.state=name; a.history[#a.history+1]=name; a.started=D.App.runningTime
  model.speed=1; a.duration=model:play(name,loop or false); a.loop=not not loop
 end
 local function nextState()
  local name=table.remove(a.queue,1) or a.desired
  start(name,name=='idle' or name=='move')
 end
 model:slot('ModelEvent',function(_,name) a.eventCounts[name]=(a.eventCounts[name] or 0)+1 end)
 model:slot('AnimationEnd',function(name)
  a.completed[name]=(a.completed[name] or 0)+1
  if (name=='depleted' or name=='lose') and not a.active then model.speed=0
  elseif not a.loop or #a.queue>0 or a.desired~=a.state then nextState() end
 end)
 function a:enqueue(name)
  for _,n in ipairs(self.queue) do if n==name then return end end
  self.queue[#self.queue+1]=name
 end
 function a:reveal(seconds) self.revealUntil=D.App.runningTime+(seconds or 4) end
 function a:update(support,x)
  local now=D.App.runningTime; self.time=now; local oldHP=self.hp; local oldActive=self.active
  self.energy=support.gold; self.hp=support.machineHP; self.active=support.active~=false and self.energy>0 and self.hp>0
  local moved=self.lastX and math.abs(x-self.lastX)>.15
  if moved and self.active then root.scaleX=x>self.lastX and -1 or 1 end
  self.lastX=x
  self.desired=self.hp<=0 and 'lose' or not self.active and 'depleted' or moved and 'move' or 'idle'
  -- Final exhausted/destroyed poses stay held. Reactivation finishes deployment first.
  if not self.active and oldActive then self.queue={}; self:reveal(10)
  elseif self.active and not oldActive then self:enqueue('deploy'); self:enqueue('shield'); self:reveal(2) end
  if self.hp<oldHP and self.hp>0 then self:enqueue('hit'); self:reveal(2); self.hitAt=now end
  local serial=support.collectionSerial or 0
  if self.collectionSerial and serial>self.collectionSerial then self:enqueue('collect'); self:reveal(2); self.collectAt=now; self.collection=support.lastCollection end
  self.collectionSerial=serial
  local shieldSerial=support.shieldImpactSerial or 0
  if self.shieldImpactSerial and shieldSerial>self.shieldImpactSerial and self.active then self:enqueue('shield');self:reveal(1);self.shieldAt=now end
  self.shieldImpactSerial=shieldSerial
  if (self.state=='depleted' or self.state=='lose') and self.completed[self.state] and self.active then nextState() end
 end
 -- Exhaustion and destruction are one-shot held poses, not replaying loops.
 local bodyNodes={}
 for _,part in ipairs(model.auxiliaryParts)do
  if part.name~='sensor' then local n=model:getNodeByName(part.name);if n then bodyNodes[#bodyNodes+1]=n end end
 end
 local sensor=model:getNodeByName('sensor')
 local tick=D.Node(); tick:addTo(root)
 tick:schedule(function()
  if a.active and model.speed==0 then model.speed=1 end
  local camouflage=a.active and D.App.runningTime>a.revealUntil
  -- Animation tracks can write opacity each frame; reapply camouflage after them.
  for _,n in ipairs(bodyNodes)do n.opacity=camouflage and .18 or 1 end
  if sensor then sensor.opacity=1 end
  fx:clear()
  local t=D.App.runningTime; local core=variant=='cargo' and D.Vec2(-41,365)*scale or variant=='defence' and D.Vec2(-98,114)*scale or D.Vec2(-140,218)*scale
  core=core+D.Vec2(0,model.y)
  local colour=a.active and D.Color(0xcc68ffee) or D.Color(0xccf58c67)
  local pulse=a.active and (6+2*math.sin(t*3)) or 3
  fx:drawDot(core,pulse,colour)
  local barY=(variant=='cargo' and 365 or variant=='defence' and 310 or 330)+model.y
  fx:drawSegment(D.Vec2(-38,barY),D.Vec2(38,barY),4,D.Color(0x66516573))
  fx:drawSegment(D.Vec2(-38,barY),D.Vec2(-38+76*math.max(0,math.min(1,a.energy/90)),barY),3,colour)
  if variant=='mobility' and a.active then
   for i=1,2 do local p=D.Vec2(235,174+(i-1)*56+model.y); local length=16+7*math.sin(t*18+i)
    fx:drawPolygon({p+D.Vec2(0,7),p+D.Vec2(length,0),p-D.Vec2(0,7)},D.Color(0x9962dfff))
   end
  end
  if a.collectAt and t-a.collectAt<1.6 then
   local elapsed=t-a.collectAt
   local origin=D.Vec2(a.collection and (a.collection.x-root.x)/root.scaleX or -80,30)
   for i=1,9 do local u=(elapsed/1.6+i/9)%1; local p=origin*(1-u)+core*u+D.Vec2(0,math.sin(u*math.pi)*45)
    fx:drawDot(p,3+(1-u)*2,D.Color(0xcce9d27d))
   end
  end
  if a.hitAt and t-a.hitAt<.5 then
   for i=1,8 do local angle=i*math.pi/4; local p=core+D.Vec2(math.cos(angle),math.sin(angle))*((t-a.hitAt)*120+15)
    fx:drawSegment(p,p+D.Vec2(math.cos(angle),math.sin(angle))*9,2,D.Color(0xccffd393))
   end
  end
  return false
 end)
 local touch=D.Node(); touch.touchEnabled=true; touch.size=D.Size(460,370); touch.position=D.Vec2(0,185); touch:addTo(root)
 touch:slot('Tapped',function() a:reveal(4); if a.active then a:enqueue('carry') end end); a.touch=touch
 a.queue={'shield'}; start('deploy',false)
 return a
end
return Actor
