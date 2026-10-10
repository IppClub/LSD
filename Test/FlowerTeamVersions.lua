-- Native version replacement and transaction boundary checks in disposable QA.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-team-versions-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-team-versions-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local R=require('Training.FlowerTeamReview');local S=require('Training.FlowerTeamAdoptionStore');local T=require('Training.FlowerTeamTrials')
  local sources=assert(P.teamSources());local models=assert(P.models());local bundle,review=R.make(sources,models,assert(T.history()));assert(bundle,review)
  local function adopt(b,v)return S.adoptAsync(b,{accepted=true,review=v})end
  assert(S.currentId()==0)
  -- Mutate a dependency after preflight, inside the actual INSERT transaction.
  -- The pointer guard must abort the whole transaction, including this mutation.
  for _,tableName in ipairs({'Game0FlowerCandidates','Game0FlowerCandidateEvidence','Game0Training','Game0Training_wuyun','Game0FlowerTeamTrials'})do
   local original=D.DB:query('SELECT payload FROM lsd.'..tableName)[1][1]
   assert(D.DB:exec("CREATE TRIGGER lsd.change_team_dependency BEFORE INSERT ON Game0FlowerTeamAdoptions BEGIN UPDATE "..tableName.." SET payload=payload || ' '; END")>=0)
   local ok,why=adopt(bundle,review);assert(not ok and why=='WRITE_FAILED',tableName..':'..tostring(why));assert(S.currentId()==0)
   assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerTeamAdoptions')==0)
   assert(D.DB:query('SELECT payload FROM lsd.'..tableName)[1][1]==original)
   assert(D.DB:exec('DROP TRIGGER lsd.change_team_dependency')>=0)
  end;r.transactionDependenciesGuarded=true;save()
  local verify=R.verifyAsync;local nested
  R.verifyAsync=function(b)
   local ok,why=adopt(bundle,review);assert(not ok and why=='BUSY');nested=true
   return verify(b)
  end
  local ok,why,id=adopt(bundle,review);R.verifyAsync=verify;assert(ok,why);assert(nested and id>0);r.first=id
  -- Concurrent pointer change while native source reconstruction yields.
  R.verifyAsync=function(b)local result,why=verify(b);assert(D.DB:exec('UPDATE lsd.Game0FlowerTeamState SET current=0 WHERE singleton=1')>=0);return result,why end
  local ok,why=adopt(bundle,review);R.verifyAsync=verify;assert(not ok and why=='ADOPTION_STATE_CHANGED');assert(S.currentId()==0)
  assert(D.DB:exec('UPDATE lsd.Game0FlowerTeamState SET current=? WHERE singleton=1',{id})>=0);r.pointerRaceRejected=true
  -- Missing current source after reconstruction cannot be hidden by the frozen source.
  local evidence=D.DB:query("SELECT payload FROM lsd.Game0FlowerCandidateEvidence WHERE learner='wuyun'")[1][1]
  R.verifyAsync=function(b)local result,why=verify(b);assert(D.DB:exec("DELETE FROM lsd.Game0FlowerCandidateEvidence WHERE learner='wuyun'")>=0);return result,why end
  local ok,why=adopt(bundle,review);R.verifyAsync=verify;assert(not ok and why=='EVIDENCE_NOT_RECORDED');assert(S.currentId()==id)
  assert(D.DB:exec("INSERT INTO lsd.Game0FlowerCandidateEvidence VALUES('wuyun',?)",{evidence})>=0);r.sourceRaceRejected=true
  local function wait(fn)local untilAt=D.App.totalTime+20;while not fn()do assert(D.App.totalTime<untilAt,'Save timeout');D.sleep(.02)end end
  -- New independent natural rounds become the new version's default-field pair.
  for _,mode in ipairs({'basic','candidate'})do
   r.phase=mode;save();local c=P.openAsync(nil,'ninilite',nil,models,nil,'field',sources);D.sleep(.3)
   if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
   local start=D.App.totalTime
   while c.battle.phase=='playing' and D.App.totalTime-start<150 do D.sleep(.1)end
   assert(c.battle.phase~='playing','Natural round exceeded deadline')
   wait(function()return c.result or c.battle.phase=='save-error'end);assert(c.result and c.result.trialSaved)
   r[mode]={status=c.trialRecord.status,seconds=c.trialRecord.seconds};save()
  end
  local nextBundle,nextReview=R.make(sources,models,assert(T.history()));assert(nextBundle,nextReview)
  local ok,why=adopt(bundle,review);assert(not ok and why=='REVIEW_STALE');assert(S.currentId()==id);r.staleReviewRejected=true
  assert(nextReview.readyForDecision,'New natural candidate did not win; retain failure for review')
  local ok,why,nextId=adopt(nextBundle,nextReview);assert(ok,why);local current=assert(S.load(models));assert(current.id==nextId and nextId>id and current.parent==id)
  assert(adopt(nextBundle,nextReview));assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerTeamAdoptions')==2);r.second=nextId
  assert(S.rollbackAsync(nextId));assert(S.load(models).id==id);r.parentRestored=true
  assert(S.rollbackAsync(id));assert(S.currentId()==0 and #D.DB:query('SELECT * FROM lsd.Game0FlowerTeamAdoptions')==2);r.historyPreserved=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
