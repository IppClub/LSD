-- Public source selection from a real correction session, never adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-recent-learning-result.json'
local r={status='RUNNING',osInput=false,naturalVictory=false};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),64)
  assert(prior.status=='PASS');local cold=os.getenv('LSD_QA_RECENT_COLD')=='1'
  local original=cold and prior.recentCandidateCheckpoint or prior.database
  assert(original:match('^/private/tmp/lsd%-combat%-qa%-.+/save/'))
  local db=D.Content.writablePath..'/yingzhao-recent-learning-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(original,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  require('Data.Config'):loadAsync();local E=require('Economy.Store');assert(E.open())
  local I=require('Training.FlowerIdentity');local S=require('Training.YingzhaoPolicyStore');local A=require('Training.YingzhaoAdoptionStore')
  local function protected()return {basic=D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),other=D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot'),missions=D.DB:query('SELECT * FROM lsd.Game0MissionAttempts ORDER BY id'),wallet=E.wallet().available,ninilite=A.state('ninilite'),wuyun=A.state('wuyun'),observations=D.DB:query('SELECT * FROM lsd.Game0YingzhaoObservations ORDER BY id')}end
  local before=protected();local oldRows=D.DB:query('SELECT * FROM lsd.Game0YingzhaoCandidates ORDER BY id')
  if cold then
   local loaded=assert(S.loadLatestAsync('ninilite'));assert(loaded.id==prior.recentCandidate and I.equal(loaded.model,prior.recentModel))
   assert(#loaded.model.sourceEpisodes==1 and loaded.model.sourceEpisodes[1]==prior.sourceEpisode)
   assert(E.wallet().available==prior.balance);r.coldRead=true;r.recentCandidate=loaded.id;r.samples=loaded.model.sampleCount
  else
   local archive=require('Training.YingzhaoStore');local ids=assert(archive.listAsync('ninilite'));assert(ids[1]==prior.sourceId)
   local source=assert(archive.loadAsync(ids[1]));local data=assert(require('Training.YingzhaoSamples').extract({source},'ninilite'))
   local old=assert(S.loadLatestAsync('ninilite'));assert(old.model.sampleCount>#data.samples)
   local invalid,why=S.learnAsync('ninilite','invalid');assert(not invalid and why=='INVALID_SOURCE_SELECTION');r.invalidSelectionRejected=true
   local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
   local function wait(fn)local deadline=D.App.runningTime+60;while not fn()do assert(D.App.runningTime<deadline,'Recent learning UI timeout');D.sleep(.02)end end
   require('Training.Level')(nil,'ninilite');wait(controls)
   local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped')
   local recent=menu:getChildByTag('学习最近示范');assert(recent.visible and menu.enabled)
   assert(D.DB:exec("CREATE TRIGGER lsd.reject_recent_candidate BEFORE INSERT ON Game0YingzhaoCandidates BEGIN SELECT RAISE(ABORT,'recent write QA'); END")>=0)
   recent:emit('Tapped');wait(function()return controls().arena.mode~='building'end)
   assert(controls().arena.message:find('保存失败',1,true),controls().arena.message)
   assert(I.equal(oldRows,D.DB:query('SELECT * FROM lsd.Game0YingzhaoCandidates ORDER BY id')))
   assert(D.DB:exec('DROP TRIGGER lsd.reject_recent_candidate')>=0);r.writeFailurePreserved=true
   recent:emit('Tapped');wait(function()return controls().arena.mode~='building'end)
   assert(controls().arena.message:find('仅使用最近完整示范',1,true),controls().arena.message)
   local candidate=assert(S.loadLatestAsync('ninilite'));assert(candidate.model.sampleCount==#data.samples and #candidate.model.sourceEpisodes==1 and candidate.model.sourceEpisodes[1]==source.episode)
   r.recentCandidate=candidate.id;r.recentModel=candidate.model;r.sourceEpisode=source.episode;r.sourceId=ids[1];r.recentSamples=candidate.model.sampleCount;r.previousSamples=old.model.sampleCount;r.message=controls().arena.message;r.balance=E.wallet().available
   r.recentCandidateCheckpoint=D.Content.writablePath..'/recent-candidate-checkpoint-'..os.time()..'.db';assert(D.Content:copyAsync(db,r.recentCandidateCheckpoint))
   D.App:saveScreenshot(root..'/Test/yingzhao-recent-learning.tga');D.sleep(.2)
   menu:getChildByTag('学习部位'):emit('Tapped');wait(function()return controls().arena.mode~='building'end)
   local all=assert(S.loadLatestAsync('ninilite'));assert(all.id~=candidate.id and all.model.sampleCount==old.model.sampleCount and #all.model.sourceEpisodes>1)
   r.allCandidate=all.id;r.allSamples=all.model.sampleCount;r.legacyAllSourcesPreserved=true
   local remaining=D.DB:query('SELECT * FROM lsd.Game0YingzhaoCandidates WHERE id<=? ORDER BY id',{old.id});assert(I.equal(oldRows,remaining),'Old candidate history changed')
  end
  assert(I.equal(before,protected()),'Source learning changed observations, adoption, wallet or missions');r.protectedStateUnchanged=true
  if not cold and os.getenv('LSD_QA_RECENT_EMPTY')=='1'then
   local priorCandidate=assert(S.loadLatestAsync('ninilite'))
   local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
   local function wait(fn)local deadline=D.App.runningTime+60;while not fn()do assert(D.App.runningTime<deadline,'Empty recent demonstration timeout');D.sleep(.02)end end
   controls():getChildByTag('training-menu'):getChildByTag('大英招示范'):emit('Tapped')
   wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
   D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
   wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
   local c=D.Platformer.Data.store.world.patrolLevel;c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
   r.emptySource=c.battle.demonstrationSourceId;assert(r.emptySource>r.sourceId)
   c.result.baseButton:emit('Tapped');wait(controls)
   local menu=controls():getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('学习最近示范'):emit('Tapped')
   wait(function()return controls().arena.mode~='building'end)
   assert(controls().arena.message:find('未合并旧记录',1,true)and controls().arena.message:find('不足6条',1,true),controls().arena.message)
   assert(assert(S.loadLatestAsync('ninilite')).id==priorCandidate.id,'Empty recent session fell back to historical learning')
   local after=protected();after.observations=nil;before.observations=nil;assert(I.equal(before,after),'Empty demonstration changed adoption, wallet or missions')
   r.emptyRecentRejected=true;r.emptyMessage=controls().arena.message
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
