-- Original medium-Yingzhao body envelope sampled at 30 Hz over all 14 clips.
-- Camera framing changes no unit scale, collision geometry or firing distance.
local D=require('Dora');local C={}
local envelope={minX=-524,maxX=334,minY=-57,maxY=659}
function C.attach(b,controls)
 assert(not b.cameraFrame,'Clearance camera already attached')
 local state={};b.cameraFrame=state
 local camera=b.world.camera
 -- A smaller viewport needs more original sky, not stretched architecture.
 local sky=b.world:getLayer(-110)
 if sky.children then sky.children:each(function(n)
  if n.look=='bk'then n.scaleY=2.5;n.y=589*(1-2.5);state.extendedSky=true end
 end)end
 local function update()
  if b.arena.closed or (b.phase~='ready'and b.phase~='playing')then return end
  local enemy=b.enemies[1].enemy
  local buffer,view=D.App.bufferSize,D.View.size
  local pixelX,pixelY=view.width/buffer.width,view.height/buffer.height
  local top=((controls.headerHeight or 335)+16)*pixelY
  local bottom=160*buffer.height/1080*pixelY
  local left,right=enemy.x+envelope.minX-30,enemy.x+envelope.maxX+200
  local low=math.min(b.world.offset-40,enemy.y+enemy.playable.y+envelope.minY-20)
  local high=enemy.y+enemy.playable.y+envelope.maxY+20
  for _,t in ipairs(b:targets())do
   left=math.min(left,t.unit.x-180);right=math.max(right,t.unit.x+180)
   low=math.min(low,t.unit.y-200);high=math.max(high,t.unit.y+200)
  end
  local zoom=math.min(.9,math.max(80*pixelY,view.height-top-bottom)/(high-low),(view.width-80*pixelX)/(right-left))
  local x=(left+right)/2;local y=(low+high)/2+(top-bottom)/(2*zoom)
  -- Reapply ownership after exploration resize callbacks, including preparation.
  if camera.followTarget then camera.followTarget=nil end
  if camera.boundary.width~=0 then camera.boundary=D.Rect.zero end
  if math.abs(camera.zoom-zoom)>.0001 then camera.zoom=zoom end
  local position=camera.position
  if math.abs(position.x-x)>.0001 or math.abs(position.y-y)>.0001 then camera.position=D.Vec2(x,y)end
  state.zoom=zoom;state.x=x;state.y=y;state.top=top;state.bottom=bottom
  state.envelope={left=left,right=right,low=low,high=high};state.view={width=view.width,height=view.height}
 end
 local prior=b.update
 b.update=function(self,...)
  local done=prior(self,...);update();return done
 end
 update()
end
return C
