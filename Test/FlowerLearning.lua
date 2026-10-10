-- Real C4.5 learning and candidate execution; isolated save, no adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/flower-learning-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local src=D.Content.writablePath..'/lsd-medical-visit-qa-1791007987.db';local dest=D.Content.writablePath..'/flower-learning-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(src,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=saved();local P=require('Training.FlowerPractice');local Policy=require('Training.FlowerPolicy');local Store=require('Training.FlowerPolicyStore')
  local function wait(fn,n)local deadline=D.App.totalTime+(n or 10);while not fn()do assert(D.App.totalTime<deadline,'Learning timeout');D.sleep(.02)end end
  local c=P.openAsync(nil,'ninilite');local b=c.battle;D.sleep(.1)
  local accepted,why=c:learnAsync();assert(not accepted and why=='TOO_FEW_SAMPLES')
  c.startButton:emit('Tapped');wait(function()return c.arena.student.onSurface end)
  -- Hold enemy skills only in this plumbing fixture, not a combat-benefit claim.
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for i=1,3 do assert(c:request('fmove'));D.sleep(.15);assert(c:request('bmove'));D.sleep(.15);assert(c:request('idle'));D.sleep(.15)end
  -- The final idle remains ongoing until withdrawal; it must stay incomplete,
  -- rather than become a spurious one-frame completed sample on neutral input.
  c:stopMove();D.sleep(.05);c.finishButton:emit('Tapped');wait(function()return c.result end)
  local history=assert(require('Training.FlowerPracticeStore').history('ninilite'));local data=assert(Policy.collect(history,'ninilite'));assert(#data.samples==8 and data.coverage.excludedIncomplete==1,'Non-demo or incomplete action entered learning')
  c.learnButton:emit('Tapped');wait(function()return c.candidate or c.learningError end);assert(c.candidate,c.learningError)
  assert(c.candidate.sampleCount==8 and Policy.validate(c.candidate,'ninilite'));assert(not Policy.validate(c.candidate,'wuyun'))
  local original=D.json.encode(assert(Store.load('ninilite')),false,true)
  local storedBefore=D.DB:query('SELECT payload FROM lsd.Game0FlowerCandidates WHERE learner=?',{'ninilite'})[1][1]
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_candidate BEFORE INSERT ON Game0FlowerCandidates BEGIN SELECT RAISE(ABORT,'QA candidate'); END")>=0)
  local learned,why=c:learnAsync();assert(not learned and why=='WRITE_FAILED');assert(require('Training.FlowerIdentity').equal(Store.load('ninilite'),D.json.decode(original,32)),'Failed save replaced candidate')
  assert(D.DB:query('SELECT payload FROM lsd.Game0FlowerCandidates WHERE learner=?',{'ninilite'})[1][1]==storedBefore,'Failed save changed stored bytes')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_candidate')>=0)
  local corrupt=D.json.decode(original,32);corrupt.rules[0]=corrupt.rules[1];assert(not Policy.validate(corrupt),'Sparse rule topology accepted')
  corrupt=D.json.decode(original,32);corrupt.rules[1].action='melee';assert(not Policy.validate(corrupt),'Ni learned illegal melee')
  assert(saved()==before)
  local oldUI=c.ui;c.trialButton:emit('Tapped');wait(function()local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');return ui and ui~=oldUI end)
  local trial=D.Director.ui3D:getChildByTag('flower-practice-controls').practice
  assert(trial.mode=='candidate' and trial.candidate.sampleCount==8,'Candidate did not reload')
  local blocked,why=trial:request('laser');assert(not blocked and why=='CANDIDATE_RUNNING')
  wait(function()return trial.arena.metrics.modelActions>0 end)
  D.sleep(.5);D.App.winSize=D.Size(683,384);D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-learning-candidate.tga');D.sleep(.2)
  local TrialStore=require('Training.FlowerTrialStore')
  assert(not trial:start(true),'Trial restarted in place')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_trial BEFORE INSERT ON Game0FlowerTrials BEGIN SELECT RAISE(ABORT,'QA trial'); END")>=0)
  trial.finishButton:emit('Tapped');wait(function()return trial.battle.phase=='save-error'end)
  assert(not trial.result and not TrialStore.latest('ninilite'))
  trial.backButton:emit('Tapped');D.sleep(.1);assert(D.Director.ui3D:getChildByTag('flower-practice-controls')==trial.ui,'Lost unsaved trial')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_trial')>=0)
  trial.retryButton:emit('Tapped');wait(function()return trial.result end)
  assert(trial.result.trialSaved)
  local persisted=assert(TrialStore.latest('ninilite'));assert(TrialStore.validate(persisted))
  assert(require('Training.FlowerIdentity').equal(persisted.policy,D.json.decode(original,32)),'Trial recorded another policy')
  local again,why=TrialStore.saveAsync(trial.trialRecord);assert(again and why==nil)
  assert(#D.DB:query('SELECT serial FROM lsd.Game0FlowerTrials')==1,'Retry duplicated trial')
  local altered=D.json.decode(D.json.encode(persisted),32);altered.evaluation.actors.ninilite.armor=123456
  assert(not TrialStore.validate(altered),'Fabricated evaluation accepted')
  altered=D.json.decode(D.json.encode(persisted),32);altered.finalHP.ninilite=17
  assert(not TrialStore.validate(altered),'HP changed outside ledger')
  altered=D.json.decode(D.json.encode(persisted),32);altered.policy.trainingAccuracy=.123
  local accepted,why=TrialStore.saveAsync(altered);assert(not accepted and why=='EPISODE_CONFLICT','Trial snapshot overwritten')
  r.trialSaved=true;r.trialSaveRetry=true;r.trialIdempotent=true;r.evaluationRecomputed=true
  local models,demos=0,0
  for _,s in ipairs(trial.result.episode.steps)do if s.action.actor=='ninilite'then if s.action.origin=='model'then models=models+1 elseif s.action.origin=='demo'then demos=demos+1 end end end
  assert(models>0 and demos==0 and not trial.result.saved,'Candidate contaminated demonstrations')
  assert(#require('Training.FlowerPracticeStore').history('ninilite')==1 and saved()==before)
  assert(not Store.load('wuyun'),'Candidate crossed learners')
  -- A second learner builds independently from complete melee/movement demos.
  local niAgain=P.openAsync(nil,'ninilite');assert(niAgain.lastTrial and niAgain.lastTrial.episode.episode==persisted.episode.episode)
  assert(niAgain.lastTrial.status=='aborted','Aborted trial promoted to success')
  D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-trial-reloaded.tga');D.sleep(.2)
  r.trialReload=true
  local wu=P.openAsync(nil,'wuyun');assert(not wu.lastTrial,'Trial crossed learners');D.sleep(.1);wu.startButton:emit('Tapped')
  for _,e in ipairs(wu.battle.roots)do e.enemyCombat:close()end
  wait(function()return wu.arena.student.onSurface end)
  for i=1,2 do assert(wu:request('fmove'));D.sleep(.15);assert(wu:request('bmove'));D.sleep(.15);assert(wu:request('idle'));D.sleep(.15)end
  assert(wu:request('melee'));wait(function()return not wu.arena:isAttacking()end);D.sleep(.1)
  wu.finishButton:emit('Tapped');wait(function()return wu.result end)
  assert(wu:learnAsync());assert(Policy.validate(wu.candidate,'wuyun') and wu.candidate.sampleCount==7)
  assert(require('Training.FlowerIdentity').equal(Store.load('ninilite'),D.json.decode(original,32)) and saved()==before)
  r.bothLearners=true;r.wuSamples=wu.candidate.sampleCount
  r.samples=#data.samples;r.modelActions=models;r.nativeC45=true;r.reload=true;r.failedSavePreserved=true;r.progressUnchanged=true;r.noSyntheticDemonstrations=true;r.trainingAccuracy=c.candidate.trainingAccuracy
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
