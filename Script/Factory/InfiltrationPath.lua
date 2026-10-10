-- Real world patrol positions and facing; hiding uses the existing action UI.
local D=require('Dora');local Path={}
function Path.attach(world,route)
 local c={phase='ready',covers={},guards={},visited={},alerts=0,travelled=0,route=route};local player=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end);c.player=assert(player)
 local store=assert(require('Story.InfiltrationPathStore').open());c.store=store
 D.Cache:loadAsync('Image/Factory/patrol-guard.model')
 local allies={};for _,name in ipairs({'ninilite','wuyun'})do local e=D.Group({'name','unit'}):find(function(e)return e.name==name and e.unit.world==world end);if e then allies[#allies+1]=e end end;c.allies=allies
 for i,x in ipairs({2650,3150,3650})do
  local cover={x=x,index=i};local sprite=assert(D.Sprite('Image/box2.png'));sprite.anchor=D.Vec2(.5,0);sprite.position=D.Vec2(x,world.offset);sprite.scaleX=360/sprite.width;sprite.scaleY=200/sprite.height;sprite:addTo(world,2);cover.sprite=sprite;c.covers[i]=cover
  local sign=i%2==1 and -1 or 1
  local guard=require('Factory.PatrolGuard').create(world,x-sign*165);guard.group=3;guard.playable:play('fmove',true)
  local cone=D.DrawNode();cone:addTo(world,-1);c.guards[i]={unit=guard,origin=x,sign=sign,cone=cone}
 end
 local screen=D.Node();screen.size=D.App.bufferSize;screen:addTo(D.Director.ui3D);c.ui=screen
 local action=require('UI.Skill')({visible=false,text='隐蔽 E'});action.position=D.Vec2(screen.width-150,110);action.scaleX=.5;action.scaleY=.5;action:addTo(screen);c.action=action
 local leave=require('UI.Skill')({visible=false,text='撤回基地'});leave.position=D.Vec2(screen.width-150,230);leave.scaleX=.5;leave.scaleY=.5;leave:addTo(screen);c.leave=leave
 leave:slot('TapBegan',function()
  if c.phase~='walking'or world.data.storyBusy or world.data.journalOpen then return end
  c.phase='leaving';D.thread(function()
   local ok,why=assert(require('Story.InfiltrationStore').open()):writeAsync('withdraw')
   if ok then require('Academy.Navigation').returnToOperationAsync()else c.phase='walking';route.error=why end
  end)
 end)
 local input=D.Node();input.keyboardEnabled=true;input:addTo(world)
 local function coverAt(x)for _,v in ipairs(c.covers)do if math.abs(x-v.x)<115 then return v end end end
 local function setHidden(value)
  c.hidden=value;c.player.busy=value;c.player.unit.velocityX=0;c.player.keyLeft=false;c.player.keyRight=false
  if value then c.player.unit:stop();c.player.unit:start('idle');c.player.unit.opacity=.35
  else c.player.unit.opacity=1;if c.coverLog then c.coverLog.left=D.App.runningTime;c.coverLog=nil end end
 end
 function c:request()
  if self.phase~='walking' or world.data.storyBusy or world.data.journalOpen then return false,'BUSY'end
  if self.hidden then setHidden(false);return true end
  local v=coverAt(player.unit.x)
  if not v then self.seekCover=not self.seekCover;self.message=self.seekCover and '已准备隐蔽，实际走到箱后即可进入掩体。再次点击可取消。'or nil;return true end
  self.seekCover=false
  setHidden(true);self.coverLog={index=v.index,x=v.x,entered=D.App.runningTime}
  local old=self.visited[v.index];if not old or not old.left or old.left-old.entered<.4 then self.visited[v.index]=self.coverLog end
  self.message=nil;return true
 end
 local function request()
  local ok,why=c:request();c.lastAction={time=D.App.runningTime,x=player.unit.x,ok=ok,reason=why}
  if not ok and why=='COVER_REQUIRED'then c.message='先走到箱体后方，再进行隐蔽。'end
 end
 action:slot('TapBegan',request);input:slot('KeyDown',function(key)if key=='E'then request()end end)
 function c:beginAsync()
  local ok,why=store:writeAsync('start');if not ok then self.error=why;return false,why end
  self.phase='walking';self.started=D.App.runningTime;self.lastX=player.unit.x;route.phase='stealth';return true
 end
 local function reset()
  c.alerts=c.alerts+1;setHidden(false);player.unit:stop();player.unit.x=2200;player.unit.velocityX=0;route.fox.x=2500
  for i,e in ipairs(allies)do e.unit:stop();e.unit.velocityX=0;e.unit.x=2200-i*90;e.busy=false;e.keyLeft=false;e.keyRight=false;e.unit.opacity=1 end
  c.visited={};c.travelled=0;c.lastX=2200;c.started=D.App.runningTime;c.message='被巡逻队发现，已撤回安全点。等守卫背向后再前进，在箱后按隐蔽。'
 end
 local tick=D.Node();tick:addTo(world);c.tick=tick
 tick:schedule(function(dt)
  if not world.parent or not player.unit then return true end
  local paused=world.data.storyBusy or world.data.journalOpen or c.phase~='walking'
  action.visible=c.phase=='walking' and not world.data.storyBusy and not world.data.journalOpen;action.children.last.text=c.hidden and '离开掩体 E'or c.seekCover and '取消隐蔽 E'or'隐蔽 E'
  leave.visible=action.visible
  if paused then
   for _,g in ipairs(c.guards)do g.unit.velocityX=0;g.cone.visible=false;if g.unit.playable.current~='prepare'then g.unit.playable:play('prepare',true)end end
   for _,e in ipairs(allies)do e.keyLeft=false;e.keyRight=false;e.unit.velocityX=0;if e.unit:isDoing('fmove')or e.unit:isDoing('bmove')then e.unit:stop();e.unit:start('idle')end end
   return false
  end
  local p=player.unit;local now=D.App.runningTime
  if c.seekCover and coverAt(p.x)then c:request()end
  if c.hidden then player.busy=true;player.keyLeft=false;player.keyRight=false;p.velocityX=0 end
  for _,g in ipairs(c.guards)do
   if g.sign<0 and g.unit.x<=g.origin-170 then g.sign=1;g.pauseUntil=now+.8 elseif g.sign>0 and g.unit.x>=g.origin+170 then g.sign=-1;g.pauseUntil=now+.8 end
   local scanning=now<(g.pauseUntil or 0);local animation=scanning and 'prepare'or'fmove'
   g.unit.faceRight=g.sign>0;g.unit.velocityX=scanning and 0 or g.sign*80;if g.unit.playable.current~=animation then g.unit.playable:play(animation,true)end;g.cone.visible=true;g.cone:clear()
   g.cone:drawPolygon({D.Vec2(g.unit.x,world.offset+245),D.Vec2(g.unit.x+g.sign*260,world.offset),D.Vec2(g.unit.x+g.sign*260,world.offset+330)},D.Color(0x33f4b963))
   local dx=p.x-g.unit.x
   if not c.hidden and dx*g.sign>0 and math.abs(dx)<250 then reset();return false end
  end
  if c.hidden and not coverAt(p.x)then setHidden(false)end
  for i,e in ipairs(allies)do
   e.busy=c.hidden;e.keyRight=not c.hidden and e.unit.x<p.x-i*90-20;e.keyLeft=not c.hidden and e.unit.x>p.x-i*90+20
   e.unit.opacity=c.hidden and .35 or 1;if c.hidden then e.unit:stop();e.unit.velocityX=0;if not e.unit:isDoing('idle')then e.unit:start('idle')end end
  end
  local delta=math.abs(p.x-c.lastX);c.travelled=c.travelled+delta;c.lastX=p.x
  local fox=route.fox;local target=math.min(4400,p.x+350);local moving=not c.hidden and fox.x<target-2
  require('Story.FoxMovement').step(fox,moving and 200 or 0,dt);if moving then fox.x=math.min(target,fox.x)end
  local count=0;local proofCovers={};for _,v in ipairs(c.covers)do local log=c.visited[v.index];if log and log.left and log.left-log.entered>=.4 then count=count+1;proofCovers[#proofCovers+1]=log end end
  route.message=c.message or ('跟随狐狸，避开巡逻视线。箱后按行动隐蔽，再按一次离开。\n已通过掩体 '..count..'/3 · 被发现 '..c.alerts..' 次')
  if p.x>=4050 and count==3 and not c.hidden then
   c.phase='saving';require('Story.FoxMovement').setVelocity(fox,0)
   D.thread(function()
    local proof={x=p.x,travelled=c.travelled,seconds=now-c.started,covers=proofCovers,alerts=c.alerts};local ok,why=store:writeAsync('complete',proof)
    if ok then c.phase='complete';c.error=nil;route.error=nil;route.phase='ready';route.pathCompleted=true;route.message='已绕过巡逻队，前方有研发人员。走近狐狸继续行动。';if c.onComplete then c.onComplete()end
    else c.phase='walking';c.error=why;route.error=why end
   end)
  end
  return false
 end)
 world:slot('Cleanup',function()
  screen:removeFromParent();player.busy=false;if player.unit then player.unit.opacity=1 end
  for _,e in ipairs(allies)do if e.unit then e.unit.opacity=1 end;e.busy=false;e.keyLeft=false;e.keyRight=false end
 end)
 return c
end
return Path
