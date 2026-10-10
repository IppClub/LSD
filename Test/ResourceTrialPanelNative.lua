local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-trial-panel-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-trial-panel-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local source=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-practice-ui/source.json'),32);assert(require('Training.ResourcePracticeStore').saveRunAsync(source));local candidate=assert(require('Training.ResourceQStore').trainAsync())
  D.Cache:loadAsync('button.clip');local panel=require('Training.FlowerQPanel').openAsync(function()end,source.baseModels)
  assert(panel.resourceEvaluate.visible and panel.resourceCompare.visible)
  panel.resourceEvaluate:emit('Tapped');local config=assert(panel.resourceConfig);D.sleep(.2)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/resource-trial-config.tga');D.sleep(.1)
  config.saveButton:emit('Tapped')
  local deadline=D.App.totalTime+15;while not panel.running do assert(D.App.totalTime<deadline,panel.diagnostic);D.sleep(.02)end
  assert(panel.battle.supplies.isVirtual==true);panel.stop:emit('Tapped');while panel.busy do assert(D.App.totalTime<deadline,panel.diagnostic);D.sleep(.02)end
  assert(panel.last.mode=='evaluate' and panel.last.status=='aborted' and not panel.pending)
  assert(require('Training.FlowerIdentity').equal(panel.last.models,candidate.models))
  assert(#assert(require('Training.ResourceQTrials').loadAsync(candidate.id))==0,'Aborted trial was saved as evaluation')
  r.checks={'candidate budget UI','starts resource evaluator','virtual session','stop preserves frozen candidate','aborted evaluation not recorded'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
