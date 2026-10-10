-- Isolated manual direction check using the game's existing movement UI.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
 local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2.zero,D.Vec2(ui.width,0),D.Vec2(ui.width,ui.height),D.Vec2(0,ui.height)},D.Color(0xff293341));bg:addTo(ui)
 local function label(t,x,y)local l=D.Label('SourceHanSansCN-Regular',25);l.text=t;l.position=D.Vec2(x,y);l:addTo(ui);return l end
 label('狐狸方向检查 · A / D 或原有移动摇杆',ui.width/2,ui.height-110)
 local status=label('待机',ui.width/2,ui.height-165)
 local ground=D.DrawNode();ground:drawSegment(D.Vec2(50,332),D.Vec2(ui.width-50,332),2,D.Color(0xff91a4ba))
 for x=50,ui.width-50,50 do ground:drawSegment(D.Vec2(x,332),D.Vec2(x,318),1,D.Color(0xff91a4ba))end;ground:addTo(ui)
 local asset=D.Path(root,'Docs/artwork/fox-export/fox-chibi-spine.skel')..'|'..D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas')
 D.Cache:unload('spine:'..asset);D.Cache:unload(D.Path(root,'Spine/FoxPrototype/fox-chibi-spine.atlas'))
 local fox=assert(D.Spine(asset));fox.scaleX=.55;fox.scaleY=.55;fox.position=D.Vec2(ui.width/2,320);fox.recovery=.15;fox:addTo(ui);fox:play('idle',true)
 local ContactLock=require('Story.FoxSpineContactLock');local stopping
 local keys={};local hud=require('UI.HUDMove'){x=230,y=160,visible=true};hud.scaleX=.7;hud.scaleY=.7;hud.onMove=function(key,down)keys[key]=down;keys.callbacks=(keys.callbacks or 0)+1;if down then keys.presses=(keys.presses or 0)+1 end end;hud:addTo(ui)
 local evidence={runId=os.time(),leftDistance=0,rightDistance=0,turns=0,source='native HUD callbacks; no injected controls',visualAcceptancePending=true}
 ui.keyboardEnabled=true;ui:slot('KeyDown',function(key)evidence.lastRawKey=key;evidence.rawKeyDowns=(evidence.rawKeyDowns or 0)+1 end)
 local output=D.Path(root,'Test/fox-spine-directions-result.json');local previous=0;local elapsed=0;local captured=false
 local post=D.Node();post.scheduler=D.Director.postScheduler;post:addTo(ui)
 post:schedule(function(dt)
  if stopping then
   local done=ContactLock.update(stopping,fox,dt)
   evidence.stopAnchorError=stopping.maxError;evidence.stopSettleDistance=stopping.settleDistance;evidence.stopAnchorFrames=stopping.frames;evidence.stopAnchorSettled=stopping.settled;evidence.stopAnchorTimedOut=stopping.timedOut
   if done then stopping=nil end
  end
  return false
 end)
 ui:schedule(function(dt)
  local direction=(keys.keyRight and 1 or 0)-(keys.keyLeft and 1 or 0)
  if direction~=previous then
   elapsed=0;captured=false
   if direction~=0 then
    stopping=nil;evidence.turns=evidence.turns+1;fox.fliped=direction>0;fox.speed=180/(192*.55);fox.recovery=.15*fox.speed;fox:play('fmove',true)
   else stopping=ContactLock.begin(fox,.2);fox.speed=1;fox.recovery=.15;fox:play('idle',true)end
   previous=direction
  end
  if direction~=0 then
   elapsed=elapsed+dt;local before=fox.x;fox.x=math.max(100,math.min(ui.width-100,fox.x+direction*180*dt))
   local field=direction<0 and 'leftDistance'or'rightDistance';evidence[field]=evidence[field]+math.abs(fox.x-before)
   evidence.lastDirection=direction;evidence.fliped=fox.fliped;evidence.x=fox.x
   status.text=direction>0 and '向右移动 →'or'← 向左移动'
   if elapsed>.4 and not captured then captured=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/fox-spine-input-'..(direction>0 and 'right'or'left')..'.tga'))end
  else status.text=stopping and '收脚 · 支撑脚固定' or '待机'end
  evidence.hudCallbacks=keys.callbacks or 0;evidence.hudPresses=keys.presses or 0
  D.Content:save(output,D.json.encode(evidence))
  return false
 end)
end)
