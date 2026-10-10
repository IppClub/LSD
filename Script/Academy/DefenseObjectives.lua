-- Reuse the original operation-room device and Zhou Daxi's assembled hover machine.
-- Atlas pixels and auxiliary assembly/occlusion remain unchanged.
local D=require('Dora');local View={}
local function label()
 local n=D.Label('SourceHanSansCN-Regular',22,true);n.outlineWidth=.16;n.outlineColor=D.Color(0xff101b28);return n
end
function View.create(world)
 local self={world=world,lastPowerHP=150,lastBeaconHP=150}
 local power=D.Node();power.position=D.Vec2(1300,world.offset);power.order=-3;power:addTo(world);self.power=power
 local device=assert(D.Sprite('Spine/operationRoom.png'))
 -- Spine atlas rotated region: device, bounds 989,466,375,468, rotate 90.
 device.textureRect=D.Rect(989,466,468,375);device.size=D.Size(468,375);device.angle=90;device.scaleX=.68;device.scaleY=.68;device.position=D.Vec2(0,159);device:addTo(power);self.device=device
 local glow=D.DrawNode();glow.order=1;glow:addTo(power);self.glow=glow
 local powerLabel=label();powerLabel.y=350;powerLabel:addTo(power);self.powerLabel=powerLabel
 local route=D.DrawNode();route.order=-4;route:addTo(world);self.route=route
 function self:update(b,dt)
  local now=D.App.runningTime
  if b.powerHP<self.lastPowerHP then self.powerHitAt=now end
  self.lastPowerHP=b.powerHP
  local hit=self.powerHitAt and now-self.powerHitAt<.45
  device.x=hit and math.sin((now-self.powerHitAt)*55)*3 or 0
  local c=D.Color(b.powerHP<=0 and 0xffa65657 or hit and 0xffffa965 or b.stage<2 and 0xff898cae or 0xff67e1d1)
  glow:clear();glow:drawSegment(D.Vec2(-100,18),D.Vec2(100,18),3,c)
  glow:drawSegment(D.Vec2(-84,324),D.Vec2(84,324),6,D.Color(0xcc1d2b3e))
  glow:drawSegment(D.Vec2(-84,324),D.Vec2(-84+168*math.max(0,b.powerHP)/150,324),4,c)
  for i=1,3 do glow:drawDot(D.Vec2(-27+(i-1)*27,303),2.5+math.sin(now*3+i)*.5,c)end
  if hit then for i=1,7 do local angle=i*math.pi/3.5;local distance=20+(now-self.powerHitAt)*120;local p=D.Vec2(math.cos(angle)*distance,170+math.sin(angle)*distance);glow:drawSegment(p,p+D.Vec2(math.cos(angle)*8,math.sin(angle)*8),2,D.Color(0xffffc383))end end
  powerLabel.text=(b.stage<2 and '供电节点 · 待保护'or b.stage==2 and '保护供电'or'供电已稳定')..'  '..math.ceil(b.powerHP)..' / 150'
  if b.stage==3 and not self.beacon then
   self.beacon=require('Ground.AuxiliaryActor').create('mobility');self.beacon.queue={};self.beacon.touch.touchEnabled=false
   -- Keep the outer display scale independent from the actor's directional flip.
   local holder=D.Node();holder.scaleX=.52;holder.scaleY=.52;holder.order=-1;holder:addTo(world)
   self.beacon.node:addTo(holder);self.beaconHolder=holder
   local text=label();text:addTo(world);self.beaconLabel=text
  end
  route:clear()
  if self.beacon then
   self.beaconHolder.position=D.Vec2(b.objective.x,world.offset)
   self.beacon:reveal(.5);self.beacon:update({gold=90,machineHP=b.beaconHP,active=b.beaconHP>0},b.objective.x)
   self.beaconLabel.position=D.Vec2(b.objective.x,world.offset+420)
   self.beaconLabel.text='撤离信标 · 悬浮机  '..math.ceil(b.beaconHP)..' / 150'
   local color=D.Color(0x9967e1d1)
   for x=math.floor(b.objective.x/110)*110,b.exitX-35,110 do
    if x>b.objective.x+160 then local y=world.offset+7;route:drawSegment(D.Vec2(x-8,y+7),D.Vec2(x+4,y),2,color);route:drawSegment(D.Vec2(x+4,y),D.Vec2(x-8,y-7),2,color)end
   end
   route:drawSegment(D.Vec2(b.exitX,world.offset),D.Vec2(b.exitX,world.offset+260),3,color)
  end
 end
 return self
end
return View
