-- QA drives the ordinary demonstration buttons. No fabricated labels or damage.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script))
local out=root..'/Test/flower-combat-learning-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={status='RUNNING',trials={}};local function save()D.Content:save(out,D.json.encode(r))end
 local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-heldout%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-combat-learning-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local P=require('Training.FlowerPractice');local Policy=require('Training.FlowerPolicy');local Store=require('Training.FlowerTrialStore')
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=progress();local c=P.openAsync(nil,'ninilite');local b=c.battle
  assert(c.coverage and c.coverage.actions.shoot==0 and c.coverage.actions.melee==0,'Wrong demonstration fixture')
  local oldCandidate=D.json.decode(D.json.encode(c.candidate),32)
  local function wait(fn,n)local endAt=D.App.totalTime+(n or 10);while not fn()do assert(D.App.totalTime<endAt,'Combat learning timeout');D.sleep(.02)end end
  D.sleep(.3);c.startButton:emit('Tapped');wait(function()return c.arena.student.onSurface end)
  c.hud.move:emit('Right',true);D.sleep(.2);c.hud.move:emit('Right',false);c.wait:emit('TapBegan');D.sleep(.25)
  local start=D.App.totalTime
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.totalTime-start<135,'Demonstration did not naturally finish')
   if b.phase=='playing'then
    if c.arena:available('laser')then c.hud.weapon:emit('TapBegan');c.hud.weapon:emit('TapEnded')end
    for _,state in pairs(b.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then c.song:emit('TapBegan');break end end
   end
   r.phase='demonstrating';r.elapsed=D.App.totalTime-start;save();D.sleep(.1)
  end
  assert(c.result and c.result.saved,'Demonstration save failed '..tostring(b.saveError))
  assert(c.coverage and c.coverage.actions.shoot>=6 and c.coverage.actions.fmove>=1 and c.coverage.armor>0,'Missing actual attack/armor demonstrations')
  r.demonstrationStatus=b.phase;r.coverage=c.coverage
  local history=assert(require('Training.FlowerPracticeStore').history('ninilite'));local data=assert(Policy.collect(history,'ninilite'));assert(#data.samples==c.coverage.total)
  c.learnButton:emit('Tapped');wait(function()return c.candidate and not require('Training.FlowerIdentity').equal(c.candidate,oldCandidate) or c.learningError end,20)
  assert(c.candidate and not c.learningError);assert(c.candidate.sampleCount==c.coverage.total)
  assert(c.generalization.completed==0,'Old candidate trials credited to new model')
  r.samples=c.candidate.sampleCount;r.accuracy=c.candidate.trainingAccuracy;r.rules=c.candidate.rules;r.sourceEpisodes=c.candidate.sourceEpisodes
  assert(progress()==before,'Learning adopted or modified mission progression')
  for _,id in ipairs(require('Training.FlowerScenarios').ids)do
   c=P.openAsync(nil,'ninilite',nil,nil,nil,id);D.sleep(.3);c.trialButton:emit('Tapped');assert(c.mode=='candidate')
   local started=D.App.totalTime
   while c.battle.phase=='playing' or c.battle.phase=='saving'do
    assert(D.App.totalTime-started<135,'Learned trial did not naturally finish')
    r.phase='candidate';r.profile=id;r.elapsed=D.App.totalTime-started;save();D.sleep(.5)
   end
   assert(c.result and c.result.trialSaved,'Learned trial save failed '..tostring(c.battle.saveError))
   local record=assert(Store.latest('ninilite'));assert(record.status~='aborted')
   local a=record.evaluation.actors.ninilite
   r.trials[#r.trials+1]={profile=id,status=record.status,seconds=record.seconds,shots=a.shots,armor=a.armor,damageTaken=a.damageTaken};save()
   assert(progress()==before,'Trial changed progression')
  end
  local again=P.openAsync(nil,'ninilite');assert(again.generalization.completed==3 and not again.generalization.adoptionEligible)
  r.generalization=again.generalization;r.publicDemonstrations=true;r.nativeLearning=true;r.naturalTrials=true;r.progressUnchanged=true
  D.App.winSize=D.Size(683,384);D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-combat-learning.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
