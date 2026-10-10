local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING',cases={}};local out=root..'/Test/shan-rush-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  b.mentorHP=10000;wait(function()return b.mentor.onSurface end)
  local e=b.enemies[2];local spec=B.attackSpecs.xiaoshanxiao[3];assert(spec.name=='rush')
  for _,case in ipairs({{name='early',distance=155,hit=true},{name='late',distance=335,hit=true},{name='reverse',distance=-335,hit=true},{name='miss',distance=600,hit=false},{name='smoke',distance=155,hit=false,blocked=true},{name='stunned',distance=155,hit=false,stunned=true}})do
   e.nextAttack=math.huge;e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7800+case.distance,b.world.offset+155);D.sleep(.2)
   b.smoke=case.blocked and {{x=b.mentor.x,radius=200,started=D.App.runningTime,ends=D.App.runningTime+5}} or {}
   e.stunUntil=case.stunned and D.App.runningTime+5 or 0
   local hp=b.mentorHP;assert(b:enemyStrike(e,spec));local strike=e.strikes[#e.strikes]
   wait(function()return not e.busy end);e.nextAttack=math.huge
   assert(strike.completed-strike.started>=strike.duration-.02)
   assert(strike.hits==(case.hit and 1 or 0),case.name..' hit count '..strike.hits)
   assert(hp-b.mentorHP==(case.hit and 12 or 0))
   assert(#strike.impacts==((case.hit or case.blocked) and 1 or 0) and e.unit.velocityX==0)
   if case.hit then assert(strike.rushStopped>.6 and strike.rushStopped<1.5)end
   r.cases[#r.cases+1]={name=case.name,impact=strike.rushStopped,hits=strike.hits,elapsed=strike.completed-strike.started,duration=strike.duration};save()
  end
  assert(r.cases[1].impact<1 and r.cases[2].impact>1)
  e.stunUntil=0;b.smoke={};e.nextAttack=math.huge
  e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(8100,b.world.offset+155);D.sleep(.2)
  assert(b:enemyStrike(e,spec));local cancelled=e.strikes[#e.strikes];D.sleep(.2)
  local hp=b.mentorHP;b:finish('aborted','QA');wait(function()return not e.busy end);D.sleep(1.5)
  assert(cancelled.cancelled=='BATTLE_ENDED' and #cancelled.impacts==0 and b.mentorHP==hp);r.cancelled=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
