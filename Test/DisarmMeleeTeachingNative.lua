local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-melee-teaching-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-attack-teaching-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-attack%-teaching%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-melee-teaching-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local untilAt=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<untilAt,'Attack teaching timeout');D.sleep(.02)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local models=assert(require('Training.FlowerPractice').models())
  for _,actor in ipairs({'wuyun'})do
   r.actor=actor;save();local loadout={{actor=actor,item='emp',quantity=24}}
   if actor=='wuyun'then loadout[#loadout+1]={actor=actor,item='blade',quantity=16}end
   local b=require('Training.DisarmPractice').createAsync(models,loadout,actor);local a=b.demonstrator
   D.sleep(.4);assert(b:start());wait(function()return a.student.onSurface end)
   local timeout=D.App.runningTime+100
   while b.phase=='playing' or b.phase=='settling'do
    assert(D.App.runningTime<timeout,'Battle did not settle')
    if b.phase=='playing'and not a:isAttacking()then
     local enemy=b.enemies[1];local dx=enemy.enemy.x-a.student.x;local distance=math.abs(dx)
     local snapshot=b.disarmSnapshot(a.student)
     if a.student.data.weaponDisarmed or distance<170 and snapshot.enemySkill=='rob'then
      b:command(dx>0 and 'left'or'right');D.sleep(.3);b:command('stop')
     elseif distance>450 then
      b:command(dx>0 and 'right'or'left');D.sleep(.25);b:command('stop')
     elseif actor=='wuyun'and distance<=300 and b.supplies:observation(actor).ammo.blade>0 then b:command('melee')
     else b:command('shoot')end
    end
    D.sleep(.1)
   end
   wait(function()return b.disarmTrace.sourceSaveState=='saved'end)
   local archived=assert(require('Training.DisarmStore').loadLatestAsync());assert(archived.source.trace.demonstrator==actor)
   local report=assert(require('Training.DisarmCoaching').review({archived},actor));r.actors[actor]={coverage=report,outcome=b.phase,cost=b.disarmTrace.virtualResult.cost};save()
   assert((report.actions.melee or 0)>=5,'Too few completed melee attacks')
   assert(a.metrics.modelActions==0)
   local candidate,why=require('Training.DisarmPolicyStore').learnAsync(actor);assert(candidate,why);assert(require('Training.DisarmPolicyStore').loadLatestAsync(actor))
   local attackRules=0;for _,rule in ipairs(candidate.model.rules)do if rule.action=='melee'then attackRules=attackRules+1 end end
   r.actors[actor].candidate=candidate.id;r.actors[actor].attackRules=attackRules;r.actors[actor].samples=candidate.model.sampleCount
   assert(candidate.model.featureSchemaVersion==2 and attackRules>0,'Candidate lacks learned melee');assert(snapshot()==before);save()
  end
  r.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
