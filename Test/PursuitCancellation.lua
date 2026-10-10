-- Native production combat; no database or progression writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/pursuit-cancellation-result.json'
 local report={status='RUNNING',scope='Production attack completion and cancellation; no save or balance acceptance'}
 local function save()D.Content:save(out,D.json.encode(report))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit')
  local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f,n)local deadline=D.App.runningTime+(n or 8);while not f()do assert(D.App.runningTime<deadline,'Wait timed out');D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  wait(function()return b.mentor.onSurface end)
  b.mentorHP=10000
  local e=b.enemies[1];local spec=B.attackSpecs.dashanxiao[2]
  e.unit.position=D.Vec2(7500,b.world.offset+155);b.mentor.position=D.Vec2(7400,b.world.offset+155)
  assert(b:enemyStrike(e,spec));local first=e.strikes[#e.strikes]
  wait(function()return not e.busy end)
  assert(first.completed and first.completed-first.started>=first.duration-.02)
  assert(#first.impacts==#spec.at and first.hits>0)
  assert(e.unit.playable.current==e.unit.data.combatRest)
  report.fullAttack={duration=first.duration,elapsed=first.completed-first.started,hits=first.hits}
  e.nextAttack=math.huge
  assert(b:enemyStrike(e,spec));local dead=e.strikes[#e.strikes]
  D.sleep(.15);b.damageMentorTarget(e.unit,1000)
  local hp=b.mentorHP;wait(function()return not e.busy end);D.sleep(1.6)
  assert(dead.cancelled=='DEAD' and #dead.impacts==0 and b.mentorHP==hp)
  report.deathCancelled=true
  local other=b.enemies[2];other.nextAttack=math.huge
  assert(b:enemyStrike(other,B.attackSpecs.xiaoshanxiao[1]));local stopped=other.strikes[#other.strikes]
  local count=#b.hostileProjectiles;b:finish('aborted','QA cancellation')
  wait(function()return not other.busy end);D.sleep(1)
  assert(stopped.cancelled=='BATTLE_ENDED' and #stopped.impacts==0 and #b.hostileProjectiles==count)
  report.exitCancelled=true
 end,debug.traceback)
 report.status=ok and 'PASS' or 'FAIL';report.error=not ok and err or nil;save()
end)
