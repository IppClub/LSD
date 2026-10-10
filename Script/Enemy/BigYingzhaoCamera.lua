-- Frame the authored body through the camera; never resize units or hit regions.
local D=require('Dora');local C={}
function C.attach(b,controls)
 assert(not b.cameraFrame,'Boss camera already attached')
 local state={nextSample=0};b.cameraFrame=state
 local camera=b.world.camera
 -- Extend only the original far sky. Architecture, clouds and road retain
 -- their authored transforms when the wider camera reveals more vertical space.
 local skyLayer=b.world:getLayer(-110)
 if skyLayer.children then
  skyLayer.children:each(function(node)
   if node.look=='bk'then
    -- Native exported bk vertices span y=589..1081. Anchor the lower edge
    -- while extending the sky upward; scaling around zero leaves a gap.
    node.scaleY=2.5;node.y=589*(1-2.5);state.extendedSky=true
   end
  end)
 end
 local function update()
  if b.arena.closed or (b.phase~='ready'and b.phase~='playing')then return end
  local boss=b.bossCombat.boss.enemy;local now=D.App.runningTime
  if now>=state.nextSample then
   state.nextSample=now+.1;b.bossCombat:sample()
   for _,part in ipairs(b.bossCombat.armor.target.regions)do
    for _,v in ipairs(part.vertices)do
     local y=v.y-boss.y
     -- Keep a conservative envelope, so normal animation never pumps the zoom.
     state.low=math.min(state.low or y,y-20)
     state.high=math.max(state.high or y,y+110) -- hair and silhouette beyond armor
    end
   end
  end
  if not state.low then return end
  local width,height=D.App.bufferSize.width,D.App.bufferSize.height
  local top=(controls.headerHeight or 225)+16
  local bottom=160*height/1080
  local available=math.max(80,height-top-bottom)
  local mentor=b.controlledUnit or b.mentor;local left=math.min(mentor.x-100,boss.x-400);local right=math.max(mentor.x+100,boss.x+400)
  local zoom=math.min(.9,available/(state.high-state.low),(width-80)/(right-left))
  local y=boss.y+(state.low+state.high)/2+(top-bottom)/(2*zoom)
  local x=(mentor.x+boss.x)/2
  local resized=state.width~=width or state.height~=height
  local dt=math.min(.1,math.max(0,now-(state.last or now)))
  if resized or not state.zoom then state.zoom=zoom;state.y=y
  else
   local mix=1-math.exp(-dt*14)
   state.zoom=state.zoom+(zoom-state.zoom)*mix;state.y=state.y+(y-state.y)*mix
  end
  -- Scene resize callbacks restore their exploration camera. Reapply ownership
  -- every update, including preparation, while preserving horizontal arena limits.
  if camera.followTarget then camera.followTarget=nil end
  if camera.boundary.width~=0 then camera.boundary=D.Rect.zero end
  if math.abs(camera.zoom-state.zoom)>.0001 then camera.zoom=state.zoom end
  x=math.max(b.cameraMinX,math.min(b.cameraMaxX,x))
  local position=camera.position
  if math.abs(position.x-x)>.0001 or math.abs(position.y-state.y)>.0001 then camera.position=D.Vec2(x,state.y)end
  state.width=width;state.height=height;state.phase=b.phase;state.last=now
  state.top=top;state.bottom=bottom;state.targetZoom=zoom;state.targetY=y
 end
 local prior=b.update
 b.update=function(self,...)
  local done=prior(self,...);update();return done
 end
 update()
end
return C
