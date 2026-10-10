local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-coverage-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-demonstration-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-demo%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-coverage-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn,seconds)local untilAt=D.App.runningTime+(seconds or 15);while not fn()do assert(D.App.runningTime<untilAt,'Coverage timeout: '..tostring(r.stage));D.sleep(.02)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local models=assert(require('Training.FlowerPractice').models())
  for _,actor in ipairs({'ninilite','wuyun'})do
   r.actor=actor;r.stage='approach';save()
   local loadout={{actor=actor,item='emp',quantity=2}}
   local b=require('Training.DisarmPractice').createAsync(models,loadout,actor);local a=b.demonstrator
   D.sleep(.4);assert(b:start());wait(function()return a.student.onSurface end)
   assert(b:command('right'));wait(function()return math.abs(a.student.x-b.enemies[1].enemy.x)<180 end,15);b:command('stop')
   r.stage='theft';save();wait(function()return a.student.data.weaponDisarmed end,18)
   local blocked,why=b:command('shoot');assert(not blocked,'Disarmed shot accepted')
   r.stage='disarmed-movement';save()
   for i=1,2 do assert(b:command('left'));D.sleep(.35);b:command('stop');D.sleep(.25)end
   wait(function()return not a.student.data.weaponDisarmed end,10)
   r.stage='ammo';save();local timeout=D.App.runningTime+18
   while (b.supplies.ledger.quote.lines[1] and b.supplies:observation(actor).ammo.emp or 0)>0 do
    assert(D.App.runningTime<timeout and b.phase=='playing','Could not exhaust remaining ammo');b:command('shoot');D.sleep(.85)
   end
   r.stage='empty-movement';save()
   for i=1,2 do b:command('left');D.sleep(.3);b:command('stop');D.sleep(.25)end
   assert(a.metrics.modelActions==0)
   b:finish('aborted','覆盖验证结束');wait(function()return b.phase~='settling'and b.disarmTrace.sourceSaveState=='saved'end)
   local archived=assert(require('Training.DisarmStore').loadLatestAsync());assert(archived.source.trace.demonstrator==actor)
   local report=assert(require('Training.DisarmCoaching').review({archived},actor));assert(report.disarmed>0,'No accepted disarmed demonstration');assert((report.ammo.empty or 0)>0,'No accepted empty-ammo demonstration')
   local candidate,why=require('Training.DisarmPolicyStore').learnAsync(actor);assert(candidate,why);assert(require('Training.DisarmPolicyStore').loadLatestAsync(actor))
   r.actors[actor]={coverage=report,candidate=candidate.id,samples=candidate.model.sampleCount};assert(snapshot()==before);save()
  end
  r.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
