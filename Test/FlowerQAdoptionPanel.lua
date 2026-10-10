local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-adoption-panel-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-repeated-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-repeated%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-adoption-panel-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local function wait(fn,seconds)local untilAt=D.App.totalTime+(seconds or 90);while not fn()do assert(D.App.totalTime<untilAt,'UI timeout');D.sleep(.05)end end
  local P=require('Training.FlowerPractice');local S=require('Training.FlowerQAdoptionStore')
  local c=P.openAsync(nil,'wuyun');D.sleep(.2);c.qButton:emit('Tapped')
  wait(function()local n=D.Director.ui3D:getChildByTag('flower-q-controls');return n and not n.panel.busy end)
  local q=D.Director.ui3D:getChildByTag('flower-q-controls').panel
  D.sleep(.3);assert(not c.hud.visible and not c.arena.demoInputAvailable(),'Practice controls leaked into Q screen');r.practiceInputHidden=true
  q.adoptionButton:emit('Tapped')
  wait(function()return q.adoptionView and not q.adoptionView.busy end);local panel=q.adoptionView;assert(panel.bundle and panel.bundle.assessment.readyForDecision);r.publicEntry=true
  assert(not panel.adopt.visible);for i=1,3 do panel.next:emit('Tapped')end;assert(panel.adopt.visible)
  panel.adopt:emit('Tapped');assert(panel.confirmAdopt.visible and S.currentId()==0);panel.cancel:emit('Tapped');assert(panel.adopt.visible and S.currentId()==0);r.explicitConfirmation=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=1 WHERE singleton=1')>=0)
  panel.adopt:emit('Tapped');panel.confirmAdopt:emit('Tapped');wait(function()return not panel.busy end)
  assert(panel.error=='REVIEW_STALE' and not panel.adopt.visible and S.currentId()==0);r.staleBlocked=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQDraft SET current=2 WHERE singleton=1')>=0)
  panel.refresh:emit('Tapped');wait(function()return not panel.busy end);assert(not panel.adopt.visible);for i=1,3 do panel.next:emit('Tapped')end;assert(panel.adopt.visible)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_q_panel_adopt BEFORE UPDATE ON Game0FlowerQAdoptionState BEGIN SELECT RAISE(ABORT,'QA UI adopt'); END")>=0)
  panel.adopt:emit('Tapped');panel.confirmAdopt:emit('Tapped');wait(function()return not panel.busy end)
  assert(panel.error=='WRITE_FAILED' and S.currentId()==0 and #D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==0);r.failedSaveRetained=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_q_panel_adopt')>=0)
  panel.adopt:emit('Tapped');panel.confirmAdopt:emit('Tapped');wait(function()return not panel.busy end)
  assert(panel.current and panel.alreadyAdopted and not panel.adopt.visible and panel.rollback.visible and panel.label.text:find('已查看4/4',1,true),panel.message);local id=panel.current.id;r.adopted=id
  assert(require('Training.FlowerQAdoptionStore').loadAsync(q.models).id==id);r.runtimeLoadable=true
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-public-adopted.tga');D.sleep(.2)
  panel.rollback:emit('Tapped');panel.cancel:emit('Tapped');assert(S.currentId()==id)
  panel.rollback:emit('Tapped');panel.confirmRollback:emit('Tapped');wait(function()return not panel.busy end)
  assert(S.currentId()==0 and not panel.current and #D.DB:query('SELECT id FROM lsd.Game0FlowerQAdoptions')==1);r.publicRollback=true
  panel.back:emit('Tapped');wait(function()return not q.busy and q.node.visible end);assert(q.saved and q.adoptionView==nil)
  q.back:emit('Tapped');wait(function()local n=D.Director.ui3D:getChildByTag('flower-practice-controls');return n and n.practice~=c end)
  local returned=D.Director.ui3D:getChildByTag('flower-practice-controls').practice
  assert(returned.characterId=='wuyun');D.sleep(.3);assert(returned.hud.visible and returned.arena.demoInputAvailable(),'Practice input did not recover');r.returnedToWuyun=true;r.practiceInputRestored=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
