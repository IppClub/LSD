local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-panel-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-q-resume-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-resume%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-panel-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local Store=require('Training.FlowerQStore')
  local function wait(fn,seconds)local limit=D.App.totalTime+(seconds or 30);while not fn()do assert(D.App.totalTime<limit,'UI timeout');D.sleep(.02)end end
  local c=P.openAsync(nil,'wuyun');D.sleep(.3);assert(c.qButton.visible);c.qButton:emit('Tapped')
  wait(function()local n=D.Director.ui3D:getChildByTag('flower-q-controls');return n and not n.panel.busy end)
  local panel=D.Director.ui3D:getChildByTag('flower-q-controls').panel;assert(panel.saved.id==prior.id and panel.explore.visible and panel.evaluate.visible);r.publicEntry=true
  local parent=panel.saved.id;local depth=panel.saved.depth
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_ui BEFORE UPDATE ON Game0FlowerQDraft BEGIN SELECT RAISE(ABORT,'QA public Q save'); END")>=0)
  panel.explore:emit('Tapped');wait(function()return panel.running or not panel.busy end);assert(panel.running,panel.diagnostic)
  local began=D.App.totalTime;r.phase='exploring';save()
  while panel.busy do assert(D.App.totalTime-began<155,'Training UI stalled');r.elapsed=D.App.totalTime-began;save();D.sleep(1)end
  assert(panel.pending and panel.saveError=='WRITE_FAILED',panel.diagnostic or panel.saveError);assert(panel.retry.visible and not panel.back.visible)
  panel.back:emit('Tapped');assert(not panel.closed and panel.pending)
  assert(Store.loadAsync().id==parent and #D.DB:query('SELECT * FROM lsd.Game0FlowerQSources')==depth)
  r.naturalStatus=panel.last.status;r.failedSaveRetained=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_ui')>=0);panel.retry:emit('Tapped');wait(function()return not panel.busy end)
  assert(not panel.pending and panel.saved.id>parent and panel.saved.depth==depth+1,panel.message);r.saved=panel.saved.id
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-panel-saved.tga');D.sleep(.2)
  for _,profile in ipairs({'far','reproduction','field','near'})do panel.scenario:emit('Tapped');assert(panel.profile==profile)end;r.profileCycle=true
  local id=panel.saved.id;panel.explore:emit('Tapped');wait(function()return panel.running or not panel.busy end);assert(panel.running);panel.stop:emit('Tapped');wait(function()return not panel.busy end)
  assert(panel.last.status=='aborted' and not panel.pending and Store.loadAsync().id==id);r.publicCancel=true
  panel.back:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('flower-practice-controls')~=nil end)
  c=D.Director.ui3D:getChildByTag('flower-practice-controls').practice;assert(c.characterId=='wuyun');r.returnedToWuyun=true
  D.sleep(.2);c.qButton:emit('Tapped');wait(function()local n=D.Director.ui3D:getChildByTag('flower-q-controls');return n and not n.panel.busy end)
  panel=D.Director.ui3D:getChildByTag('flower-q-controls').panel;assert(panel.saved.id==id and panel.saved.depth==depth+1);r.reopened=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
