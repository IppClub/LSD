local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',cases={},scope='Controlled native original Pursuit skill effects; high-HP observer and manually arranged targets; not formal mission victory; backstep dodge remains unaccepted',osInput=false,formalMissionAccepted=false};local out=root..'/Test/ambush-current-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+6;while not f()do assert(D.App.runningTime<deadline,'Timeout');D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  local e=b.enemies[1];assert(e.unit.playable.scaleX==1 and e.unit.playable.scaleY==1,'Boss not authored scale');r.authoredScale=true;local spec=B.attackSpecs.dashanxiao[4]
  for _,kind in ipairs({'left','right','dodge','group','smoke','stun','cancel','exit'})do
   wait(function()return not b.stamina.down and b.mentor.onSurface end)
   b:command('idle');e.unit.position=D.Vec2(7520,b.world.offset+155);e.stunUntil=0;e.unit.velocityX=0
   b.mentor.position=D.Vec2(kind=='right' and 7940 or 7100,b.world.offset+155);b.mentor.velocityX=0;b.mentorHP=10000;b.stamina.value=100
   D.sleep(.2);if kind=='left'then e.sequence=3;e.nextAttack=D.App.runningTime;wait(function()return e.busy end);r.automaticSelection=true else assert(b:enemyStrike(e,spec))end;local strike=e.strikes[#e.strikes];local targetX=strike.targetX
   if kind=='dodge'then assert(b:command('left'),'Movement unavailable')end
   if kind=='stun'then D.sleep(.2);e.stunUntil=D.App.runningTime+2
   elseif kind=='cancel'then D.sleep(.8);assert(e.untargetable);e.attackSequence:cancel('QA_CANCEL')
   else
    wait(function()return #strike.stages==2 end)
    assert(strike.stages[2].started-strike.started>=.99,'First clip truncated')
    if kind=='group'then b.escorts[1].unit.position=D.Vec2(targetX+20,b.world.offset+155)
    elseif kind=='smoke'then b.smoke[#b.smoke+1]={x=targetX,radius=300,started=D.App.runningTime,ends=D.App.runningTime+2}
    elseif kind=='exit'then b:finish('aborted','QA')end
   end
   wait(function()return not e.busy end);e.nextAttack=math.huge
   assert(strike.portal.closed and not strike.warning.parent and e.unit.group==2 and not e.untargetable,'Cleanup failed')
   if kind=='left' or kind=='right' or kind=='group' or kind=='dodge'then
    assert(#strike.impacts==1 and strike.hits==(kind=='group' and 2 or 1),'Hit count '..strike.hits)
    assert(b.mentorHP==9982 and b.stamina.value<100)
    assert(math.abs(strike.impactX-targetX)<50,'Warning mismatch '..(strike.impactX-targetX))
    assert(strike.completed-strike.started>=1.99,'Animation truncated')
    if kind=='group'then assert(b.escorts[1].hp==82)end
   else r.current={kind=kind,hits=strike.hits,mentorHP=b.mentorHP,mentorX=b.mentor.x,targetX=targetX,staminaDown=b.stamina.down};save();assert(strike.hits==0 and b.mentorHP==10000,'Unexpected hit')end
   if kind=='dodge'then r.movementDodge=false;r.backstepGap={hit=true,distanceAtAnimationEnd=math.abs(b.mentor.x-targetX),requiredRange=spec.range};save()end
   r.cases[#r.cases+1]={kind=kind,hits=strike.hits,impact=strike.impacts[1],offset=strike.impactX and strike.impactX-targetX,completed=strike.completed and strike.completed-strike.started,cancelled=strike.cancelled}
  end
  D.sleep(.5);assert(b.mentorHP==10000);r.noDelayedHits=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
