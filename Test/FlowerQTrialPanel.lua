local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-trial-panel-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-trials-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-trials%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-trial-panel-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());local Panel=require('Training.FlowerQPanel');local returned=false
  local function wait(fn,seconds)local limit=D.App.totalTime+(seconds or 30);while not fn()do assert(D.App.totalTime<limit,'UI timeout');D.sleep(.05)end end
  local panel=Panel.openAsync(function()returned=true end,saved.source.baseModels);assert(#panel.trials==2 and panel.evaluate.visible);r.coldRecords=#panel.trials
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_trial_ui BEFORE INSERT ON Game0FlowerQTrials BEGIN SELECT RAISE(ABORT,'QA trial UI'); END")>=0)
  panel.evaluate:emit('Tapped');wait(function()return not panel.busy end,155)
  assert(panel.pendingKind=='trial' and panel.pending and panel.saveError=='WRITE_FAILED',panel.diagnostic or panel.message)
  assert(panel.retry.visible and not panel.back.visible);assert(Store.loadAsync().id==saved.id);r.failedSaveRetained=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_trial_ui')>=0);panel.retry:emit('Tapped');wait(function()return not panel.busy end)
  assert(not panel.pending and not panel.loadError and #panel.trials==3,panel.message)
  assert(require('Training.FlowerIdentity').equal(panel.saved.models,saved.models));r.candidateUnchanged=true;r.naturalStatus=panel.last.status
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-trial-panel.tga');D.sleep(.2)
  panel.back:emit('Tapped');wait(function()return returned end)
  panel=Panel.openAsync(function()end,saved.source.baseModels);assert(#panel.trials==3 and panel.saved.id==saved.id);r.reopened=true;r.records=3
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
