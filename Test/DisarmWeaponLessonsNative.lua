local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-weapon-lessons-result.json';local r={status='RUNNING',lessons={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-cross-weapon-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-cross%-weapon%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-weapon-lessons-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local untilAt=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<untilAt,'Cross-weapon timeout');D.sleep(.02)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();local models=assert(require('Training.FlowerPractice').models())
  for _,lesson in ipairs({'low-blade','no-blade','no-emp'})do
   r.lesson=lesson;save()
   local loadout={}
   if lesson~='no-emp'then loadout[#loadout+1]={actor='wuyun',item='emp',quantity=24}end
   if lesson~='no-blade'then loadout[#loadout+1]={actor='wuyun',item='blade',quantity=lesson=='low-blade'and 3 or 24}end
   local b=require('Training.DisarmPractice').createAsync(models,loadout,'wuyun');local a=b.demonstrator
   D.sleep(.4);assert(b:start());wait(function()return a.student.onSurface end)
   local timeout=D.App.runningTime+100
   while b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<timeout,'Battle did not settle')
    if b.phase=='playing'and not a:isAttacking()then
     local dx=b.enemies[1].enemy.x-a.student.x;local distance=math.abs(dx)
     local resources=b.supplies:observation('wuyun')
     if a.student.data.weaponDisarmed then b:command(dx>0 and 'left'or'right');D.sleep(.3);b:command('stop')
     elseif (resources.ammo.blade or 0)>0 and distance<=300 then b:command('melee')
     elseif (resources.ammo.emp or 0)>0 and distance<=450 then b:command('shoot')
     elseif distance>300 then b:command(dx>0 and 'right'or'left');D.sleep(.2);b:command('stop')
     else b:command('stop')end
    end
    D.sleep(.1)
   end
   wait(function()return b.disarmTrace.sourceSaveState=='saved'end)
   local archived=assert(require('Training.DisarmStore').loadLatestAsync());local data=assert(require('Training.DisarmPolicy').inspect({archived},'wuyun'))
   local count,lowBlade=0,0
   for _,sample in ipairs(data.samples)do
    local state=sample.state
    if sample.action=='melee'and state.bladeAmmo=='low'then lowBlade=lowBlade+1 end
    if lesson=='low-blade'and sample.action=='laser'and state.bladeAmmo=='empty'
     or lesson=='no-blade'and sample.action=='laser'and state.bladeAmmo=='unequipped'
     or lesson=='no-emp'and sample.action=='melee'and state.empAmmo=='unequipped'then count=count+1 end
   end
   r.lessons[#r.lessons+1]={lesson=lesson,targetActions=count,lowBlade=lowBlade,outcome=b.phase,cost=b.disarmTrace.virtualResult.cost,samples=#data.samples};save()
   if lesson=='low-blade'then assert(lowBlade>0,'No completed low-blade melee')end
   assert(count>=5,'Missing complete weapon boundary samples');assert(a.metrics.modelActions==0 and snapshot()==before)
  end
  local Store=require('Training.DisarmPolicyStore');local candidate,why=Store.learnAsync('wuyun');assert(candidate,why);assert(Store.loadLatestAsync('wuyun'))
  r.candidate=candidate.id;r.samples=candidate.model.sampleCount;r.originalProgressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
