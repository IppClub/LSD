local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-adoption-recovery-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-adoption-store-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-adoption%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-adoption-recovery-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local S=require('Training.FlowerQAdoptionStore');local adopted=assert(S.inspectAsync());local source=D.DB:query('SELECT payload FROM lsd.Game0FlowerQSources WHERE id=2')[1][1]
  assert(D.DB:exec("UPDATE lsd.Game0FlowerQSources SET payload='{}' WHERE id=2")>=0)
  local q=require('Training.FlowerQPanel').openAsync(function()end,adopted.bundle.models);assert(q.loadError and q.adoptionButton.visible and not q.explore.visible)
  local function wait(fn)local untilAt=D.App.totalTime+90;while not fn()do assert(D.App.totalTime<untilAt);D.sleep(.05)end end
  q.adoptionButton:emit('Tapped');wait(function()return q.adoptionView and not q.adoptionView.busy end);local panel=q.adoptionView
  assert(not panel.bundle and panel.currentError and panel.rollback.visible and not panel.adopt.visible);r.recoveryReachable=true
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_recovery BEFORE UPDATE ON Game0FlowerQAdoptionState BEGIN SELECT RAISE(ABORT,'QA recovery'); END")>=0)
  panel.rollback:emit('Tapped');panel.confirmRollback:emit('Tapped');wait(function()return not panel.busy end);assert(panel.error=='WRITE_FAILED' and S.currentId()==adopted.id);r.failedRollbackRetained=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_recovery')>=0);panel.rollback:emit('Tapped');panel.confirmRollback:emit('Tapped');wait(function()return not panel.busy end)
  assert(S.currentId()==0 and panel.message:find('来源读取异常',1,true));assert(#D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==2);r.corruptArchiveDeactivated=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQSources SET payload=? WHERE id=2',{source})>=0);panel.refresh:emit('Tapped');wait(function()return not panel.busy end);assert(panel.bundle and not panel.currentError)
  panel.back:emit('Tapped');wait(function()return not q.busy and q.node.visible end);assert(not q.loadError and q.saved and q.explore.visible);r.parentRecovered=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
