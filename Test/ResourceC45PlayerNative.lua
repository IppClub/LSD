local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-c45-player-result.json';local r={status='RUNNING'}
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
  -- Exercise the player's learning action and the independently frozen candidate.
  D.sleep(.1);assert(c.learnButton.visible and not c.adoptionButton.visible)
  c.learnButton:emit('Tapped');D.sleep(.05)
  local untilDone=D.App.totalTime+20
  while c.learning or c.learningQueued do assert(D.App.totalTime<untilDone);D.sleep(.02)end
  assert(c.candidate and not c.learningError,c.learningError)
  local CS=require('Training.ResourcePolicyStore');local first=assert(CS.evidenceAsync('ninilite'))
  assert(first.model.algorithm=='flower-resource-c45' and not require('Training.FlowerPolicy').validate(first.model))
  assert(c:learnAsync());assert(CS.evidenceAsync('ninilite').id==first.id,'Repeated learning appended duplicate')
  local fresh=D.json.decode(D.json.encode(episodes[1]),32);fresh.episode=fresh.episode..'-new-candidate'
  local candidate=assert(require('Training.ResourcePolicy').buildAsync({fresh},'ninilite'))
  assert(D.DB:exec("CREATE TRIGGER lsd.RejectResourceC45 BEFORE INSERT ON Game0ResourceC45Candidates BEGIN SELECT RAISE(ABORT,'candidate fault'); END")>=0)
  local accepted,why=CS.saveAsync(candidate,{fresh});assert(not accepted and why=='WRITE_FAILED',why)
  assert(D.DB:exec('DROP TRIGGER lsd.RejectResourceC45')>=0);assert(CS.evidenceAsync('ninilite').id==first.id)
  assert(CS.saveAsync(candidate,{fresh}));local latest=assert(CS.evidenceAsync('ninilite'));assert(latest.id>first.id)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  assert(CS.evidenceAsync('ninilite').id==latest.id)
  local payload=D.DB:query('SELECT payload FROM lsd.Game0ResourceC45Candidates WHERE id=?',{latest.id})[1][1]
  local corrupt=D.json.decode(payload,32);corrupt.policy.rules={{conditions={},action='idle'}}
  assert(D.DB:exec('UPDATE lsd.Game0ResourceC45Candidates SET payload=? WHERE id=?',{D.json.encode(corrupt,false,true),latest.id})>=0)
  local read,why=CS.loadAsync('ninilite');assert(not read and why=='REBUILD_MISMATCH',why)
  assert(D.DB:exec('UPDATE lsd.Game0ResourceC45Candidates SET payload=? WHERE id=?',{payload,latest.id})>=0)
  assert(CS.loadAsync('ninilite'))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-c45-player.tga');D.sleep(.2)
  r.candidateChecks={'player learn button','source rebuilt on load','repeat idempotence','candidate insert failure preserves old version','retry and file reopen','modified rules rejected','legacy adoption rejects resource candidate'}
  r.samples=model.sampleCount;r.checks={'player budget to manual practice','real complete demonstration source','independent history','duplicate idempotence','source trains resource C4.5','write fault preserves history and retry','file reopen retains source','automatic context rejected','formal wallet and legacy history unchanged'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
