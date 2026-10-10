local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-panel-recovery-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-q-panel-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-panel%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-recovery-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync());local returned=false
  local panel=require('Training.FlowerQPanel').openAsync(function()returned=true end,saved.source.baseModels)
  local function wait(fn)local limit=D.App.totalTime+30;while not fn()do assert(D.App.totalTime<limit,'UI timeout');D.sleep(.02)end end
  local function corrupt()assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=999999 WHERE singleton=1')>=0)end
  local function restore()assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current='..saved.id..' WHERE singleton=1')>=0)end
  -- Inject only the pending UI state; actual failed-save retention is covered by FlowerQPanel.
  panel.pending={boundaryFixture=true};panel.saveError='WRITE_FAILED';panel:render();assert(panel.discard.visible and not panel.back.visible)
  corrupt();panel.discard:emit('Tapped');wait(function()return not panel.busy end)
  assert(not panel.pending and panel.loadError and panel.reload.visible and panel.back.visible and not panel.explore.visible)
  assert(panel.message:find('读取失败',1,true) or panel.message:find('不一致',1,true),panel.message);r.discardPreservesLoadError=true
  restore();panel.reload:emit('Tapped');wait(function()return not panel.busy end)
  assert(not panel.loadError and panel.saved.id==saved.id and panel.explore.visible);r.reloadRecovers=true
  panel.pending={boundaryFixture=true};panel.saveError='WRITE_FAILED';panel:render();panel.discard:emit('Tapped');wait(function()return not panel.busy end)
  assert(not panel.pending and not panel.saveError and panel.saved.id==saved.id and panel.back.visible);r.discardKeepsSaved=true
  assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQSources')==saved.depth)
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-panel-recovery.tga');D.sleep(.2)
  panel.back:emit('Tapped');wait(function()return returned end);r.returned=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
