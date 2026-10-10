local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-exploration-panel-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-exploration-panel-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local source=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-exploration-exposed/source.json'),32)
  local P=require('Training.ResourcePracticeStore');assert(P.saveRunAsync(source))
  local again,why=P.saveRunAsync(source);assert(again and why=='ALREADY_SAVED')
  local seed=source.seed;source.seed=nil;local accepted,why=P.saveRunAsync(source);assert(not accepted and why=='INVALID_RESOURCE_EXPLORATION');source.seed=seed
  source.initial={};local accepted,why=P.saveRunAsync(source);assert(not accepted and why=='INVALID_INITIAL_MODELS');source.initial=nil
  local candidate=assert(require('Training.ResourceQStore').trainAsync())
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  D.Cache:loadAsync('button.clip');local panel=require('Training.FlowerQPanel').openAsync(function()end,source.baseModels)
  assert(panel.resourceExplore.visible and panel.resourceScenario.visible and panel.resourceProfile=='field')
  for i=1,4 do panel.resourceScenario:emit('Tapped')end
  assert(panel.resourceProfile=='exposed' and panel.profile=='near')
  panel.resourceExplore:emit('Tapped');local config=assert(panel.resourceConfig);D.sleep(.2)
  config.saveButton:emit('Tapped')
  local deadline=D.App.totalTime+15;while not panel.running do assert(D.App.totalTime<deadline,panel.diagnostic);D.sleep(.02)end
  assert(panel.battle.supplies.isVirtual==true)
  for part,state in pairs(panel.battle.partCombat.target.damage.parts)do assert(state.ap==0 and panel.battle.partCombat.known[part].ap==0)end
  panel.stop:emit('Tapped');while panel.busy do assert(D.App.totalTime<deadline,panel.diagnostic);D.sleep(.02)end
  assert(panel.last.mode=='explore' and panel.last.status=='aborted' and not panel.pending)
  assert(P.loadLatestAsync().source.episode.episode==source.episode.episode,'Aborted exploration was recorded')
  assert(require('Training.FlowerIdentity').equal(require('Training.ResourceQStore').loadLatestAsync().models,candidate.models))
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  r.checks={'exploration source idempotence','missing seed rejected','invalid initial rejected','independent resource scenario selector','revealed virtual armor','player exploration start and stop','aborted source not saved','candidate and wallet unchanged'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
