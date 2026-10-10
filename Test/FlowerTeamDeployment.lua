-- Real public joint adoption and production battle, restricted to a named QA copy.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-team-deployment-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-team-deployment-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local S=require('Training.FlowerTeamAdoptionStore');local single=require('Training.FlowerAdoptionStore')
  local models=assert(P.models());local sources=assert(P.teamSources())
  local function wait(fn,seconds)local endAt=D.App.totalTime+(seconds or 20);while not fn()do assert(D.App.totalTime<endAt,'Timeout');D.sleep(.02)end end
  local singles=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState'),false,true)
  local c=P.openAsync(nil,'ninilite',nil,models,nil,'field',sources);D.sleep(.3);c.teamReviewButton:emit('Tapped');local panel=assert(c.adoptionView)
  assert(not panel.adopt.visible);for i=1,4 do panel.next:emit('Tapped')end;assert(panel.adopt.visible)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_team_adopt BEFORE UPDATE ON Game0FlowerTeamState BEGIN SELECT RAISE(ABORT,'QA team adoption'); END")>=0)
  panel.adopt:emit('Tapped');wait(function()return not panel.busy end);assert(not panel.saved and panel.error=='WRITE_FAILED' and S.currentId()==0)
  assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerTeamAdoptions')==0)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_team_adopt')>=0);panel.adopt:emit('Tapped');wait(function()return not panel.busy end);assert(panel.saved,panel.error)
  local adopted=assert(S.load(models));r.adoptionId=adopted.id;r.failedSaveRetried=true
  assert(S.adoptAsync(panel.bundle,{accepted=true,review=panel.review}));assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerTeamAdoptions')==1)
  for _,id in ipairs({'ninilite','wuyun'})do local v,why=single.load(id,models);assert(not v and why=='TEAM_ADOPTION_ACTIVE');local ok,why=single.rollbackAsync(id);assert(not ok and why=='TEAM_ADOPTION_ACTIVE')end
  local bad,why=S.rollbackAsync(adopted.id+1);assert(not bad and why=='ADOPTION_STATE_CHANGED');r.singleOperationsBlocked=true
  panel.back:emit('Tapped')
  local journey=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db';assert(D.DB:exec("ATTACH DATABASE '"..journey.."' AS journey")>=0)
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes SELECT * FROM journey.Game0StoryNodes WHERE id='factory-encounter'")>=0);assert(D.DB:exec('DETACH DATABASE journey')>=0)
  local service=assert(require('Mission.Service').open());local attempt=assert(service:beginAsync('c0-m05',models,assert(service:formation())))
  local Controller=require('Training.FlowerController');local step=Controller.step;local decisions={ninilite=0,wuyun=0}
  Controller.step=function(b,a,p)decisions[a.character.id]=decisions[a.character.id]+1;return step(b,a,p)end
  local loads=0;local load=S.load;S.load=function(...)loads=loads+1;return load(...)end
  local level=require('Factory.Level').openAsync(service,attempt);local b=level.battle
  assert(loads==1 and b.arena.flowerDeployment.teamAdoptionId==adopted.id and b.wuyun.flowerDeployment.teamAdoptionId==adopted.id)
  level.start:emit('Tapped');assert(b.arena.mode=='demo' and b.wuyun.mode=='demo')
  local began=D.App.totalTime
  while b.phase=='playing' and D.App.totalTime-began<150 do b:command('shoot');if b.effects.confusions>0 then b:command('song')end;D.sleep(.1)end
  r.naturalTerminal=b.phase~='playing';if b.phase=='playing'then level.withdraw:emit('Tapped')end
  wait(function()return level.result~=nil or b.phase=='save-error'end);assert(b.phase~='save-error')
  assert(loads==1 and decisions.ninilite>0 and decisions.wuyun>0);r.decisions=decisions;r.loads=loads
  local result=D.DB:query('SELECT status,report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt.id})[1];r.battleStatus=result[1]
  local report=assert(D.json.decode(result[2],32));for _,id in ipairs({'ninilite','wuyun'})do assert(report.learners[id].teamAdoptionId==adopted.id and report.learners[id].training.teamAdoptionId==adopted.id)end;r.savedCombinationIdentity=true
  S.load=load;Controller.step=step
  -- Public rollback after returning to training; immutable adoption remains.
  c=P.openAsync(nil,'ninilite',nil,models,nil,'field',sources);D.sleep(.3);c.teamReviewButton:emit('Tapped');panel=assert(c.adoptionView);assert(panel.current.id==adopted.id)
  panel.rollback:emit('Tapped');panel.confirmRollback:emit('Tapped');wait(function()return not panel.busy end);assert(S.currentId()==0 and not panel.current)
  assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerTeamAdoptions')==1)
  assert(singles==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState'),false,true));r.publicRollback=true
  panel.back:emit('Tapped')
  local baseline=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models=models});assert(not baseline.arena.flowerDeployment and not baseline.wuyun.flowerDeployment)
  baseline:finish('aborted','QA rollback');r.basicRestored=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
