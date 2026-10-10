local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-practice-ui-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-ui-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  D.Cache:loadAsync('button.clip')
  local saved=assert(require('Training.FlowerQStore').loadAsync())
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet()
  local Loadout=require('Economy.Loadout');local values=assert(Loadout.load());assert(Loadout.saveAsync(values));local encode=function(x)return D.json.encode(x,false,true)end
  local before=encode(Loadout.load())
  local panel=require('Training.FlowerQPanel').openAsync(function()end,saved.source.baseModels)
  assert(panel.resourceButton.visible);panel.resourceButton:emit('Tapped');local config=assert(panel.resourceConfig)
  assert(not config.recoveryButton.visible);config.buttons[1][-1]:emit('Tapped');config.closeButton:emit('Tapped')
  assert(not panel.busy and panel.node.visible and encode(Loadout.load())==before)
  panel.resourceValues={['mentor:kinetic']=2,['ninilite:emp']=2,['wuyun:emp']=2,['wuyun:blade']=2}
  panel.profile='field';panel.resourceButton:emit('Tapped');config=assert(panel.resourceConfig)
  D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/resource-practice-budget.tga');D.sleep(.15)
  config.saveButton:emit('Tapped');D.sleep(.1)
  local deadline=D.App.totalTime+160
  while panel.busy do assert(D.App.totalTime<deadline,'Resource practice did not finish');D.sleep(.1)end
  assert(not panel.pending,panel.saveError);assert(panel.resourceSaved and panel.last.status=='failed')
  assert(panel.label.text:find('模拟成本',1,true));assert(E.wallet().available==balance.available and E.wallet().revision==balance.revision and encode(Loadout.load())==before)
  local id=panel.resourceSaved.id
  local Store=require('Training.ResourcePracticeStore');local record=assert(Store.loadLatestAsync());assert(record.id==id and record.review.resourceMode=='virtual')
  local ok,why,same=Store.saveRunAsync(panel.last);assert(ok and why=='ALREADY_SAVED'and same==id)
  local changed=D.json.decode(encode(panel.last),32);changed.episode.resources.spent=999;assert(not Store.saveRunAsync(changed))
  assert(require('Training.FlowerQStore').loadAsync().id==saved.id,'Legacy Q draft changed')
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/resource-practice-result.tga');D.sleep(.2)
  r.id=id;r.seconds=panel.last.report.seconds;r.cost=panel.last.episode.resources.spent;r.checks={'virtual UI config','cancel preserves mission loadout','full natural failure','saved source rebuild','wallet unchanged','mission config unchanged','legacy Q draft unchanged','idempotent save','tampered evidence rejected'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
