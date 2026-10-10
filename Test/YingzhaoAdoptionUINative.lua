-- Public training/comparison/review route with real earned source archives.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-adoption-ui-result.json';local r={status='RUNNING',osInput=false,checks={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adoption%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-adoption-ui-'..os.time()..'.db';r.database=db;r.parentEvidence=parent;r.algorithm=prior.algorithm;save()
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local equal=require('Training.FlowerIdentity').equal;local initial=S.state('ninilite');assert(initial.current==0)
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id')},false,true)end
  local before=snapshot()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Review route timed out');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'ninilite');wait(controls)
  local ui=controls();local menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped')
  menu:getChildByTag(prior.algorithm=='yingzhao-qlearning'and'自主对照'or'部位对照'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-budget')end)
  D.Director.ui3D:getChildByTag('yingzhao-comparison-budget').saveButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end,420)
  local comparison=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(comparison.saved,comparison.saveError or comparison.error)
  assert(comparison.report.setup.candidate.id==prior.candidateId);r.comparisonId=comparison.saved;r.checks.publicComparison=true;save();comparison.backButton:emit('Tapped');wait(controls)
  ui=controls();menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and not v.state.busy end)
  local p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state
  assert(p.bundle and p.adopt.visible and not p.rollback.visible);assert(p.ids[p.index]==comparison.saved)
  p.adopt:emit('Tapped');assert(p.confirm.visible and p.cancel.visible and not p.back.visible);p.cancel:emit('Tapped');assert(equal(initial,S.state('ninilite')));r.checks.cancelPreservesSelection=true
  assert(D.DB:exec("CREATE TRIGGER lsd.ui_adopt_failure BEFORE INSERT ON Game0YingzhaoAdoptions BEGIN SELECT RAISE(ABORT,'UI failure'); END")>=0)
  p.adopt:emit('Tapped');p.confirm:emit('Tapped');assert(p.busy);p.confirm:emit('Tapped');p.back:emit('Tapped')
  wait(function()return not p.busy end);assert(equal(initial,S.state('ninilite'))and p.view.label.text:find('保存失败',1,true));assert(not ui.visible)
  assert(D.DB:exec('DROP TRIGGER lsd.ui_adopt_failure')>=0);r.checks.failureRetryable=true
  p.adopt:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  local current=S.state('ninilite');assert(current.current>0 and p.current.id==current.current and not p.adopt.visible and p.rollback.visible)
  r.active=current.current;r.already=p.already==true;save()
  assert(p.already,'Successfully adopted current record is incorrectly treated as stale')
  p.refresh:emit('Tapped');wait(function()return not p.busy end)
  assert(p.already and p.view.label.text:find('已经采用',1,true)and not p.view.label.text:find('专项成果已变化',1,true))
  r.checks.adoptedRecordRecognized=true
  local checkpoint=D.Content.writablePath..'/yingzhao-ui-adopted-checkpoint-'..os.time()..'.db'
  assert(D.DB:exec("VACUUM lsd INTO '"..checkpoint.."'")>=0);r.adoptedCheckpoint=checkpoint;save()
  local originalSize=D.App.winSize;D.Director.entry:slot('Cleanup',function()D.App.winSize=originalSize end)
  r.screenshots={}
  for _,size in ipairs({D.Size(683,384),D.Size(960,540)})do
   D.App.winSize=size;D.sleep(.4);local path=root..'/Test/yingzhao-adoption-active-'..math.floor(size.width)..'.tga';D.App:saveScreenshot(path);D.sleep(.1);r.screenshots[#r.screenshots+1]=path
  end
  p.rollback:emit('Tapped');p.cancel:emit('Tapped');assert(equal(current,S.state('ninilite')))
  p.rollback:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end);assert(S.state('ninilite').current==0 and not p.rollback.visible and not p.adopt.visible)
  assert(p.view.label.text:find('已回滚',1,true));p.refresh:emit('Tapped');wait(function()return not p.busy end);assert(not p.bundle and not p.adopt.visible and p.view.label.text:find('专项成果已变化',1,true));r.checks.rollbackAndStaleReview=true
  p.back:emit('Tapped');assert(ui.visible and not ui.arena.closed);assert(S.state('wuyun').current==0 and snapshot()==before and E.wallet().available==balance and not E.active());r.checks.otherRoleWalletBasicModelsUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
