local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',cases={},scope='Controlled native original pursuit skills and full recovery; high-HP observer; not formal mission or natural victory',osInput=false,formalMissionAccepted=false};local out=root..'/Test/big-shan-combo-current-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  b.mentorHP=10000;wait(function()return b.mentor.onSurface end)
  local e=b.enemies[1]
  for _,case in ipairs({{skill=2,name='slum-front',hits=3},{skill=3,name='punch-front',hits=3},{skill=2,name='slum-cross-behind',cross=true,hits=3},{skill=3,name='punch-cross-behind',cross=true,hits=1},{skill=2,name='slum-escape',escape=true,hits=1},{skill=3,name='punch-stunned',stun=true,hits=1}})do
   e.nextAttack=math.huge;e.stunUntil=0;e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7980,b.world.offset+155);D.sleep(.2)
   local spec=B.attackSpecs.dashanxiao[case.skill];local hp=b.mentorHP
   assert(b:enemyStrike(e,spec));local strike=e.strikes[#e.strikes]
   D.sleep(spec.at[1]-.1);assert(b.mentorHP==hp,'Windup caused damage')
   wait(function()return #strike.impacts>=1 end)
   if case.cross then b.mentor.position=D.Vec2(7620,b.world.offset+155)end
   if case.escape then b.mentor.position=D.Vec2(8400,b.world.offset+155)end
   if case.stun then e.stunUntil=D.App.runningTime+4 end
   wait(function()return not e.busy end);e.nextAttack=math.huge
   assert(#strike.impacts==3 and strike.hits==case.hits,case.name..' hits '..strike.hits)
   assert(hp-b.mentorHP==case.hits*8)
   assert(strike.completed-strike.started>=strike.duration-.02 and e.unit.playable.current==e.unit.data.combatRest)
   r.cases[#r.cases+1]={name=case.name,hits=strike.hits,impacts=strike.impacts,duration=strike.duration,elapsed=strike.completed-strike.started};save()
  end
  e.stunUntil=0;e.nextAttack=math.huge;e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7980,b.world.offset+155);D.sleep(.2)
  assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[2]));local strike=e.strikes[#e.strikes];wait(function()return #strike.impacts==1 end)
  local hp=b.mentorHP;b:finish('aborted','QA');wait(function()return not e.busy end);D.sleep(2)
  assert(#strike.impacts==1 and b.mentorHP==hp and strike.cancelled=='BATTLE_ENDED');r.cancelled=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
