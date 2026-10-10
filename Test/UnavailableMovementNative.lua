-- Native rejected-decision lifetime; controlled actors/models, not formal play.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/unavailable-movement-result.json'
local r={status='RUNNING',osInput=false,controlledCombatFixture=true,formalCombat=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local path=D.Content.writablePath..'/unavailable-movement-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and not D.Content:exist(path))
  assert(D.DB:exec("ATTACH DATABASE '"..path.."' AS lsd")>=0);r.database=path
  local E=require('Economy.Store');assert(E.open());local L=require('Economy.Loadout')
  local values=L.defaults();for key in pairs(values)do values[key]=0 end;values['wuyun:blade']=1
  local quote=assert(L.quote(values,{mentor=true,learner='ninilite',wuyun=true}))
  assert(E.beginAsync('movement-window',quote.lines,0));local session=assert(require('Economy.CombatSession').open('movement-window'))
  local oldPath='/private/tmp/lsd-unavailable-movement-20261009/Arena-before.lua'
  local before=assert(load(assert(D.Content:load(oldPath)),'@'..oldPath))()
  local after=require('Training.Arena')
  local function wait(fn)local limit=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<limit,'Native movement fixture timed out');D.sleep(.02)end end
  for _,spec in ipairs({{'before',before},{'after',after}})do
   for _,actor in ipairs({'ninilite','wuyun'})do
    for _,movement in ipairs({'fmove','bmove'})do
     local a=spec[2].createAsync({characterId=actor,enemySpeed=0,enemyMaxHP=1000,manualUpdate=true,actionPrefix=spec[1]..actor..movement})
     a.externalCombat=true;a.supplies=session;a.mode='demo';a.enemy.x=a.student.x+600
     wait(function()return a.student.onSurface end)
     assert(a:request(movement,'model'));D.sleep(.2);assert(a.student:isDoing(a.physical[movement]))
     local model={schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=actor,sampleCount=1,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}
     assert(require('Training.Model').validate(model));assert(not a:available('laser'))
     a.mode='trial';a.trialModel=model;a.nextDecision=0;local x=a.student.x;a:update();D.sleep(.4)
     local continuing=a.student:isDoing(a.physical[movement]);local travel=math.abs(a.student.x-x)
     if spec[1]=='before'then assert(continuing and travel>10,'Old unavailable decision did not reproduce stale walking')
     else assert(not continuing and travel<3,'Rejected decision kept old walking')end
     assert(a.lastDecision=='ACTION_UNAVAILABLE'and a.metrics.unavailable>0 and session.emissions==0)
     r.cases[#r.cases+1]={variant=spec[1],actor=actor,movement=movement,reason=a.lastDecision,continued=continuing,travel=travel,emissions=session.emissions};save()
     -- An unavailable new shot must never truncate a currently playing shot.
     if spec[1]=='after'then
      a.mode='demo';a.supplies=nil;a.nextShot=0;a.studentEnergy=100
      wait(function()return a:available('laser')end);assert(a:request('laser','model'));D.sleep(.05)
      assert(a:isAttacking());a.mode='trial';a.nextDecision=0;a:update();assert(a:isAttacking(),'Rejected decision interrupted attack')
      wait(function()return not a:isAttacking()end);assert(a.lastDecision=='ACTION_UNAVAILABLE')
      r.cases[#r.cases].attackCompleted=true;save()
     end
     a.closed=true;a.world:removeFromParent()
    end
   end
  end
  -- Exercise the real Boss gather wrapper with no learner EMP; the manual
  -- order must own travel until arrival even when the model would reject fire.
  local function model(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'laser'},rules={{conditions={},action='laser'}}}end
  local models={ninilite=model('ninilite'),wuyun=model('wuyun')};local modelBefore=D.json.encode(models,false,true)
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,session,{virtual=true})
  require('Ground.BattleSupport').attach(b,require('Ground.LifeSupport').new(90,'defence'))
  wait(function()return b.arena.student.onSurface and b.wuyun.student.onSurface and b.mentor.onSurface end)
  b.mentor.x=2320;assert(b:start());b.enemies[1].guard.nextAttack=math.huge
  assert(b:command('gather'));local plan=b.gatherPlan;D.sleep(1)
  r.manualGather={plan={ninilite=plan.ninilite,wuyun=plan.wuyun},travel={}}
  for _,a in ipairs(b.learners)do
   assert(require('Combat.Formation').owns(a,b,D.App.runningTime),'Manual gather lost ownership')
   assert(a.student:isDoing(a.physical.fmove)or a.student:isDoing(a.physical.bmove),'Unavailable model stopped manual travel')
   r.manualGather.travel[a.character.id]=true
  end
  local deadline=D.App.runningTime+15
  while not(b.arena.regroupComplete and b.wuyun.regroupComplete)do assert(D.App.runningTime<deadline,'Gather did not arrive');D.sleep(.02)end
  D.sleep(.3)
  for _,a in ipairs(b.learners)do
   assert(math.abs(a.student.x-plan[a.character.id])<=require('Combat.Formation').tolerance)
   assert(not a.student:isDoing(a.physical.fmove)and not a.student:isDoing(a.physical.bmove))
  end
  assert(D.json.encode(models,false,true)==modelBefore);r.manualGather.arrived=true;r.manualGather.modelsUnchanged=true
  b.closed=true;b.arena.closed=true;b.wuyun.closed=true;b.world:removeFromParent()
  assert(session.emissions==0);assert(E.settleAsync('movement-window','aborted'));assert(not E.active())
  r.scope='Both real learner rigs, both native walk actions and actual unprovisioned EMP budget; controlled previous walking/new model decision. Full attacks preserved. No Boss win or learned-policy improvement claim.'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
