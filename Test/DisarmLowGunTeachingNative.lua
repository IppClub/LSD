local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-low-gun-result.json';local r={status='RUNNING',lessons={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-weapon-lessons-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-weapon%-lessons%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-low-gun-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local untilAt=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<untilAt,'Low-gun timeout');D.sleep(.02)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local models=assert(require('Training.FlowerPractice').models());local total=0
  for lesson=1,2 do
   r.lesson=lesson;save()
   local b=require('Training.DisarmPractice').createAsync(models,{{actor='wuyun',item='emp',quantity=3}},'wuyun');local a=b.demonstrator
   D.sleep(.4);assert(b:start());wait(function()return a.student.onSurface end)
   local limit=D.App.runningTime+40
   while b.supplies:observation('wuyun').ammo.emp>0 or a:isAttacking()do
    assert(D.App.runningTime<limit and b.phase=='playing','Cannot complete low-gun demonstration')
    if not a:isAttacking()then
     local dx=b.enemies[1].enemy.x-a.student.x
     if a.student.data.weaponDisarmed then b:command(dx>0 and 'left'or'right');D.sleep(.3);b:command('stop')
     elseif math.abs(dx)>300 then b:command(dx>0 and 'right'or'left');D.sleep(.2);b:command('stop')
     else b:command('shoot')end
    end
    D.sleep(.1)
   end
   local spent=b.supplies.ledger.spent;assert(not b:command('shoot'));D.sleep(.2);assert(b.supplies.ledger.spent==spent,'Empty shot consumed resources')
   b:command('left');D.sleep(.3);b:command('stop');D.sleep(.25)
   b:finish('aborted','少量弹药示范结束');wait(function()return b.disarmTrace.sourceSaveState=='saved'end)
   local source=assert(require('Training.DisarmStore').loadLatestAsync());local data=assert(require('Training.DisarmPolicy').inspect({source},'wuyun'));local count=0
   for _,sample in ipairs(data.samples)do if sample.action=='laser'and sample.state.empAmmo=='low'and sample.state.bladeAmmo=='unequipped'then count=count+1 end end
   assert(count>0);total=total+count;r.lessons[#r.lessons+1]={lowGunShots=count,samples=#data.samples,cost=b.disarmTrace.virtualResult.cost};assert(a.metrics.modelActions==0 and snapshot()==before);save()
  end
  assert(total>=3)
  local Store=require('Training.DisarmPolicyStore');local candidate,why=Store.learnAsync('wuyun');assert(candidate,why);assert(Store.loadLatestAsync('wuyun'))
  r.candidate=candidate.id;r.samples=candidate.model.sampleCount;r.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
