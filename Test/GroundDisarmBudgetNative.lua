-- Same adopted team and HUD command policy; loadout is the only changed input.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-disarm-budget-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/ground-disarm-budget-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local S=assert(require('Mission.Service').open());local models=assert(require('Training.FlowerPractice').models());local L=require('Economy.Loadout')
  local function loadout(a,b,c,d)return {{actor='mentor',item='kinetic',quantity=a},{actor='ninilite',item='emp',quantity=b},{actor='wuyun',item='emp',quantity=c},{actor='wuyun',item='blade',quantity=d}}end
  local _,defaults=L.quote(L.defaults(),{mentor=true,learner=true,wuyun=true})
  local configs={{name='default',items=defaults},{name='lean',items=loadout(12,12,3,16)},{name='one-each',items=loadout(1,1,1,1)}}
  local original=D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmAdoptionState')},false,true)
  local function wait(fn)local untilAt=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<untilAt,'Budget comparison timeout');D.sleep(.02)end end
  for repetition=1,2 do for _,config in ipairs(configs)do
   r.current=config.name;r.repetition=repetition;save();local balance=E.wallet().available
   local attempt,why=S:beginAsync('c0-disarm',models,{mentor=true,learner='ninilite',wuyun=true},{loadout=config.items,reward=100});assert(attempt,why)
   local c=require('Ground.DisarmLevel').openAsync(S,attempt);local b=c.battle;assert(b.disarmTrace.adoptions.wuyun)
   c.start:emit('Tapped');wait(function()return b.phase=='playing'end);local deadline=D.App.runningTime+110
   while b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<deadline,'Budget encounter timeout')
    if b.phase=='playing'then local enemy=b:target(b.mentor)
     if enemy then local dx=enemy.enemy.x-b.mentor.x
      if math.abs(dx)>420 then c.hud.move:emit(dx>0 and 'Right'or'Left',true)
      else c.hud.move:emit('Right',false);c.hud.move:emit('Left',false);c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')end
      c.fire:emit('TapBegan');c.wind:emit('TapBegan')
     end
    end;D.sleep(.1)
   end
   wait(function()return c.phase=='result'or c.phase=='save-error'end);assert(c.phase=='result',c.error)
   local e=assert(require('Training.CombatStore').load(attempt.id));local bill=b.report.economy;assert(E.wallet().available==balance+bill.net and bill.cost<=bill.reserved)
   local vitals=assert(require('Training.DisarmVitals').review(e.disarm.vitals))
   r.cases[#r.cases+1]={name=config.name,repetition=repetition,status=b.phase,reserved=bill.reserved,cost=bill.cost,net=bill.net,refund=bill.refund,seconds=b.report.seconds,damage=vitals.damage,attempt=attempt.id};save()
  end end
  assert(original==D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmAdoptionState')},false,true));r.trainingUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
