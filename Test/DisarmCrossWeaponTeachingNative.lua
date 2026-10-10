local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-cross-weapon-result.json';local r={status='RUNNING',lessons={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-melee-teaching-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-melee%-teaching%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-cross-weapon-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local untilAt=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<untilAt,'Cross-weapon timeout');D.sleep(.02)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local models=assert(require('Training.FlowerPractice').models())
  for _,lesson in ipairs({'low','empty'})do
   r.lesson=lesson;save()
   local b=require('Training.DisarmPractice').createAsync(models,{{actor='wuyun',item='emp',quantity=lesson=='low'and 3 or 1},{actor='wuyun',item='blade',quantity=24}},'wuyun');local a=b.demonstrator
   D.sleep(.4);assert(b:start());wait(function()return a.student.onSurface end)
   local timeout=D.App.runningTime+100
   while b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<timeout,'Battle did not settle')
    if b.phase=='playing'and not a:isAttacking()then
     local dx=b.enemies[1].enemy.x-a.student.x;local distance=math.abs(dx)
     local resources=b.supplies:observation('wuyun')
     if a.student.data.weaponDisarmed then b:command(dx>0 and 'left'or'right');D.sleep(.3);b:command('stop')
     elseif lesson=='empty'and resources.ammo.emp>0 and distance<=450 then b:command('shoot')
     elseif distance>300 then b:command(dx>0 and 'right'or'left');D.sleep(.2);b:command('stop')
     else b:command('melee')end
    end
    D.sleep(.1)
   end
   wait(function()return b.disarmTrace.sourceSaveState=='saved'end)
   local archived=assert(require('Training.DisarmStore').loadLatestAsync());local data=assert(require('Training.DisarmPolicy').inspect({archived},'wuyun'))
   local count=0;for _,sample in ipairs(data.samples)do if sample.action=='melee'and sample.state.empAmmo==lesson then count=count+1 end end
   r.lessons[#r.lessons+1]={lesson=lesson,melee=count,outcome=b.phase,cost=b.disarmTrace.virtualResult.cost,samples=#data.samples};save()
   assert(count>=5,'Missing complete cross-weapon melee samples');assert(a.metrics.modelActions==0 and snapshot()==before)
  end
  local Store=require('Training.DisarmPolicyStore');local candidate,why=Store.learnAsync('wuyun');assert(candidate,why);assert(Store.loadLatestAsync('wuyun'))
  r.candidate=candidate.id;r.samples=candidate.model.sampleCount;r.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
