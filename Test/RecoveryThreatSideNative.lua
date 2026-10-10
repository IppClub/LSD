-- Actual native recovery, controlled injury/visible Boss relocation; no victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/recovery-threat-side-result.json'
local r={status='RUNNING',controlledFixture=true,osInput=false,naturalVictory=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local function wait(f,t)local endAt=D.App.runningTime+t;while not f()do assert(D.App.runningTime<endAt,'Threat-side recovery stalled');D.sleep(.01)end end
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local original=D.json.encode(models)
  local supply=assert(require('Economy.CombatSession').virtual('recovery-threat-side',{{actor='ninilite',item='emp',quantity=1},{actor='wuyun',item='blade',quantity=1}}))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supply,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.wuyun.student.onSurface end,8)
  b.mentor.x=1320;b.arena.student.x=1120;b.wuyun.student.x=1220
  assert(b:start());local boss=b.enemies[1];boss.guard.nextAttack=math.huge
  b.arena.studentHP=30;assert(b:command('recover-gather'))
  local record=b.bossTrace.gathers[1];local initial=b.gatherPlan;local deadline=b.gatherUntil
  wait(function()return b.arena.regroupComplete and b.wuyun.regroupComplete end,3)
  r.before={anchor=b.mentor.x,bossX=boss.enemy.x,ninilite=initial.ninilite,wuyun=initial.wuyun,deadline=deadline,machineX=b.support.x}
  -- A Boss can change sides while the mentor remains still (e.g. aerial return).
  boss.enemy.x=800;boss.enemy.velocityX=0
  assert(not require('Combat.Formation').stationaryRecovery(b.arena,b,D.App.runningTime),'Stale threat side retained stationary policy ownership')
  r.staleThreatRevoked=true;D.sleep(.2)
  r.after={anchor=b.mentor.x,bossX=boss.enemy.x,ninilite=b.gatherPlan.ninilite,wuyun=b.gatherPlan.wuyun,deadline=b.gatherUntil,replans=record.replans};save()
  assert(b.gatherPlan~=initial and b.gatherPlan.ninilite>b.mentor.x and b.gatherPlan.wuyun>b.mentor.x,'Recovery targets stayed on the Boss side after visible side change')
  assert(b.gatherUntil==deadline and record.initialPlan.ninilite==r.before.ninilite,'Side change extended deadline or mutated initial plan')
  wait(function()return b.arena.regroupComplete and b.wuyun.regroupComplete end,5)
  r.firstSwitchArrivals=D.json.decode(D.json.encode(record.arrivals),32)
  for _,v in pairs(r.firstSwitchArrivals)do assert(v.target>b.mentor.x and math.abs(v.x-v.target)<=18)end
  local switched=b.gatherPlan
  -- Equality / tiny center oscillation must not repeatedly reverse formation.
  boss.enemy.x=b.mentor.x;D.sleep(.1);boss.enemy.x=b.mentor.x+5;D.sleep(.1)
  assert(b.gatherPlan==switched,'Formation flipped inside center tolerance')
  -- Preserve the left-side formation after a clear second change.
  boss.enemy.x=1920;D.sleep(.2)
  assert(b.gatherPlan.ninilite<b.mentor.x and b.gatherPlan.wuyun<b.mentor.x)
  r.switches=record.replans;r.deadlinePreserved=b.gatherUntil==deadline
  assert(r.switches==2 and r.deadlinePreserved)
  wait(function()return b.arena.regroupComplete and b.wuyun.regroupComplete end,5)
  r.arrivals=record.arrivals;r.machineX=b.support.x
  for _,v in pairs(record.arrivals)do assert(math.abs(v.x-v.target)<=18)end
  assert(b:command('gather'));assert(record.reason=='PLAYER_CANCELLED')
  assert(b:finish('aborted','Controlled threat-side regression'))
  assert(original==D.json.encode(models));r.modelsUnchanged=true;r.gathers=b.bossTrace.gathers
  r.scope='Controlled Boss relocation and injury; actual recovery locomotion/replan/arrival, no formal save or victory'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
