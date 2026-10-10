local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local out=root..'/Test/big-shan-hand-current-result.json';local r={status='RUNNING',cases={},scope='Controlled native original Pursuit skill effects; high-HP observer and manually arranged targets; not formal mission victory',osInput=false,formalMissionAccepted=false}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline,'Timeout');D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  local originalThrow=b.props.throw
  b.props.throw=function(self,item,position,aim,onHit)
   return originalThrow(self,item,position,aim,function(target,direction)
    onHit(target,direction)
    if target==b.mentor then r.lastHit={direction=direction,velocityX=target.velocityX,velocityY=target.velocityY,x=target.x,at=D.App.runningTime};save() end
   end)
  end
  b.mentorHP=10000;local e=b.enemies[1];local original=D.Spine('dashanxiao');local copy=D.Spine('dashanxiao-release')
  local source=D.Spine:getAnimations('dashanxiao')
  local count=0;for _,name in ipairs(source)do local duration=original:play(name,false);assert(duration>0 and duration==copy:play(name,false),'Duration changed: '..name);count=count+1 end;r.animationCount=count
  for i,right in ipairs({false,true})do
   e.unit.position=D.Vec2(i==1 and 7520 or 8500,b.world.offset+155);b.mentor.position=D.Vec2(e.unit.x+(right and 420 or -420),b.world.offset+155)
   e.unit.velocityX=0;b.mentor.velocityX=0;D.sleep(.25)
   assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[1]));local strike=e.strikes[#e.strikes];local item=strike.prop;local hp=b.mentorHP;local minY,maxY=math.huge,-math.huge
   while not strike.propReleased do
    if item.state=='carried'then minY=math.min(minY,item.node.y);maxY=math.max(maxY,item.node.y)end
    assert(D.App.runningTime-strike.started<1.5);D.sleep(.01)
   end
   assert(maxY-minY>150,'Object did not follow lifting arm')
   assert(strike.propReleased-strike.started>=1.33333,'Early release')
   assert(strike.release.faceRight==right)
   -- Turn the thrower after release: knockback must follow projectile travel.
   e.unit.faceRight=not right
   wait(function()return strike.hits==1 end);assert(hp-b.mentorHP==14)
   r.velocityAtObservation=b.mentor.velocityX;save();assert(r.lastHit and (r.lastHit.velocityX>0)==right and (r.lastHit.direction>0)==right,'Collision knockback follows changed facing')
   wait(function()return not e.busy end);e.nextAttack=math.huge
   assert(D.App.runningTime-strike.started>=strike.duration-.02,'Truncated animation')
   r.cases[#r.cases+1]={right=right,lift=maxY-minY,release=strike.propReleased-strike.started,duration=strike.duration,hits=strike.hits,collision=r.lastHit,observedVelocity=r.velocityAtObservation}
  end
  b:finish('aborted','QA');r.originalDurations=true;r.directionAfterRelease=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
