local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',cases={},scope='Controlled native original Pursuit skill effects; high-HP observer and manually arranged targets; not formal mission victory',osInput=false,formalMissionAccepted=false};local out=root..'/Test/shan-claw-current-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  b.mentorHP=10000;wait(function()return b.mentor.onSurface end)
  local e=b.enemies[2];local spec=B.attackSpecs.xiaoshanxiao[2];assert(spec.name=='scratch')
  for _,case in ipairs({{name='both',distance=140,hits=2},{name='reverse',distance=-140,hits=2},{name='leave',distance=140,hits=1},{name='stun',distance=140,hits=1},{name='miss',distance=350,hits=0}})do
   e.nextAttack=math.huge;e.stunUntil=0;e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7800+case.distance,b.world.offset+155);D.sleep(.2)
   local hp=b.mentorHP;assert(b:enemyStrike(e,spec));local strike=e.strikes[#e.strikes]
   wait(function()return #strike.impacts>=1 end)
   if case.name=='leave' then b.mentor.position=D.Vec2(8400,b.world.offset+155)end
   if case.name=='stun' then e.stunUntil=D.App.runningTime+2 end
   wait(function()return not e.busy end);e.nextAttack=math.huge
   assert(strike.hits==case.hits and hp-b.mentorHP==case.hits*5,case.name)
   assert(#strike.impacts==2 and strike.impacts[1]>=.6 and strike.impacts[2]>=1.15)
   assert(strike.completed-strike.started>=strike.duration-.02 and e.unit.playable.current==e.unit.data.combatRest)
   r.cases[#r.cases+1]={name=case.name,hits=strike.hits,impacts=strike.impacts,elapsed=strike.completed-strike.started,duration=strike.duration};save()
  end
  e.stunUntil=0;e.nextAttack=math.huge
  local before=#b.hostileProjectiles;assert(b:enemyStrike(e,B.attackSpecs.xiaoshanxiao[1]));local strike=e.strikes[#e.strikes]
  D.sleep(1);assert(#b.hostileProjectiles==before,'Projectile emitted during windup')
  wait(function()return not e.busy end);e.nextAttack=math.huge
  assert(#b.hostileProjectiles==before+1 and strike.impacts[1]>=1.13333);r.throw={impact=strike.impacts[1],duration=strike.duration,elapsed=strike.completed-strike.started}
  e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7940,b.world.offset+155);D.sleep(.2)
  assert(b:enemyStrike(e,spec));strike=e.strikes[#e.strikes];wait(function()return #strike.impacts==1 end)
  local hp=b.mentorHP;b:finish('aborted','QA');wait(function()return not e.busy end);D.sleep(1)
  assert(#strike.impacts==1 and b.mentorHP==hp and strike.cancelled=='BATTLE_ENDED');r.cancelled=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
