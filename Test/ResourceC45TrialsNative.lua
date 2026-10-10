local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-c45-trials-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-demo-player-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local saved=assert(require('Training.FlowerQStore').loadAsync());local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local legacy=assert(require('Training.FlowerPracticeStore').history('ninilite'))
  local view=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,saved.source.baseModels);D.sleep(.2)
  view.resourceButton:emit('Tapped');assert(view.resourceConfig);view.resourceConfig.saveButton:emit('Tapped')
  local deadline=D.App.totalTime+30;while not view.resourcePractice do assert(D.App.totalTime<deadline);D.sleep(.02)end
  local c=view.resourcePractice;D.sleep(.2);assert(c.resourceLoadout and c.battle.supplies.isVirtual)
  c.startButton:emit('Tapped');assert(c.battle.phase=='playing')
  for i=1,12 do
   local action=({'fmove','idle','bmove','idle'})[(i-1)%4+1]
   while not c:request(action)do assert(D.App.totalTime<deadline);D.sleep(.05)end
   D.sleep(.35)
  end
  D.sleep(.4);c.finishButton:emit('Tapped');while c.battle.phase=='saving'do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(c.result and c.result.saved,c.battle.saveError)
  local S=require('Training.ResourceDemoStore');local episodes=assert(S.history('ninilite'));assert(#episodes==1)
  local yes,why=S.saveAsync('ninilite',c.result.status,c.result.episode);assert(yes and why=='ALREADY_SAVED')
  local model,why=require('Training.ResourcePolicy').buildAsync(episodes,'ninilite');assert(model,why)
  assert(#assert(require('Training.FlowerPracticeStore').history('ninilite'))==#legacy)
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectResourceDemo BEFORE INSERT ON Game0ResourceDemos BEGIN SELECT RAISE(ABORT,'demo fault'); END")>=0)
  local copy=D.json.decode(D.json.encode(episodes[1]),32);copy.episode=copy.episode..'-write-failure'
  local yes,why=S.saveAsync('ninilite','aborted',copy);assert(D.DB:exec('DROP TRIGGER lsd.RejectResourceDemo')>=0);assert(not yes and why=='WRITE_FAILED',tostring(yes)..':'..tostring(why));assert(#assert(S.history('ninilite'))==1)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-demo-player.tga');D.sleep(.2)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  assert(#assert(S.history('ninilite'))==1,'Source lost after reopening')
  local yes,why=S.saveAsync('ninilite','aborted',copy);assert(yes,why)
  copy.context='flower-resource-practice';local yes,why=S.saveAsync('ninilite','aborted',copy);assert(not yes and why=='INVALID_RESOURCE_DEMO')
  assert(c:learnAsync());local CS=require('Training.ResourcePolicyStore');local frozen=assert(CS.loadAsync('ninilite'))
  local trials={}
  for _,mode in ipairs({'basic',true})do
   local t=require('Training.FlowerPractice').openAsync(nil,'ninilite',{rounds={}},saved.source.baseModels,mode,nil,nil,c.resourceLoadout)
   local limit=D.App.totalTime+140
   while t.battle.phase=='playing' or t.battle.phase=='saving'do assert(D.App.totalTime<limit,'Resource C4.5 trial stalled');D.sleep(.2)end
   assert(t.result and t.result.trialSaved,t.battle.saveError)
   assert(t.result.status=='won' or t.result.status=='failed')
   assert(require('Training.FlowerIdentity').equal(CS.loadAsync('ninilite'),frozen))
   assert(#assert(S.history('ninilite'))==2,'Autonomous trial entered demos')
   trials[#trials+1]={controller=t.mode,status=t.result.status,cost=t.result.episode.resources.spent,seconds=t.result.report.seconds}
   r.trials=trials;D.Content:save(out,D.json.encode(r,false,true))
  end
  local TS=require('Training.ResourceC45Trials');local history=assert(TS.history('ninilite'));assert(#history==2)
  assert(TS.saveAsync(history[1]));assert(#assert(TS.history('ninilite'))==2)
  local corrupt=D.json.decode(D.json.encode(history[1]),32);corrupt.policy.rules={{conditions={},action='idle'}}
  assert(not TS.saveAsync(corrupt),'Altered controller accepted')
  assert(not require('Training.FlowerTrialStore').saveAsync(history[1]),'Resource trial entered legacy store')
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  r.trialChecks={'natural basic and frozen C4.5 trials','independent results and cost','no demonstration pollution','models and formal wallet unchanged','duplicate idempotence','modified controller rejected','legacy trial isolation'}
  r.samples=model.sampleCount;r.checks={'player budget to manual practice','real complete demonstration source','independent history','duplicate idempotence','source trains resource C4.5','write fault preserves history and retry','file reopen retains source','automatic context rejected','formal wallet and legacy history unchanged'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
