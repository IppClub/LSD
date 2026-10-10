-- Public joint entry and eight natural paired trials. All records stay in QA.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-team-native-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-wuyun-current-result.json'),32));assert(prior.status=='PASS' and prior.ready)
  assert(D.Path:getFilename(prior.database):match('^flower%-wuyun%-current%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-team-native-'..os.time()..'.db';assert(not D.DB:existDB('lsd') and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local T=require('Training.FlowerTeamTrials');local equal=require('Training.FlowerIdentity').equal
  local function singleState()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerPractice'),D.DB:query('SELECT * FROM lsd.Game0FlowerTrials'),D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0FlowerAdoptionState')},false,true)end
  local before=singleState();local function wait(fn,seconds)local untilAt=D.App.totalTime+(seconds or 10);while not fn()do assert(D.App.totalTime<untilAt,'Joint entry timeout');D.sleep(.02)end end
  local c=P.openAsync(nil,'ninilite');D.sleep(.3);assert(c.teamButton.visible);local old=c.ui;c.teamButton:emit('Tapped')
  wait(function()local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');return ui and ui~=old end)
  c=D.Director.ui3D:getChildByTag('flower-practice-controls').practice;assert(c.teamSources and c.profile.id=='field')
  assert(not c:start() and not c:learnAsync('latest'));D.sleep(.2);assert(not c.hud.visible and not c.adoptionButton.visible and not c.learnButton.visible)
  local sources=c.teamSources;assert(sources.ninilite.policy.sampleCount==39 and sources.wuyun.policy.sampleCount==35);r.publicEntry=true
  local records={};local injected=false
  for _,profile in ipairs({'near','far','reproduction','field'})do
   records[profile]={}
   for _,mode in ipairs({'basic','candidate'})do
    c=P.openAsync(nil,'ninilite',nil,nil,nil,profile,sources);D.sleep(.3)
    if profile~='field'then assert(math.abs(c.battle.wuyun.student.x-(c.arena.student.x-120))<1)end
    local fail=mode=='candidate' and not injected
    if fail then
     assert(T.history());assert(D.DB:exec("CREATE TRIGGER lsd.fail_joint_trial BEFORE INSERT ON Game0FlowerTeamTrials BEGIN SELECT RAISE(ABORT,'QA joint trial'); END")>=0)
    end
    if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
    assert(c.mode==mode);assert(c.battle.arena.mode==(mode=='basic' and 'trial' or 'demo') and c.battle.wuyun.mode==(mode=='basic' and 'trial' or 'demo'))
    local started=D.App.totalTime
    while c.battle.phase=='playing' or c.battle.phase=='saving'do
     assert(D.App.totalTime-started<150,'Joint battle stalled');r.phase=profile..'-'..mode;r.elapsed=D.App.totalTime-started;save();D.sleep(.5)
    end
    if fail then
     assert(c.battle.phase=='save-error' and not c.result);local beforeUI=c.ui;c.backButton:emit('Tapped');D.sleep(.1);assert(c.ui==beforeUI and not c.arena.closed)
     assert(D.DB:exec('DROP TRIGGER lsd.fail_joint_trial')>=0);c.retryButton:emit('Tapped');wait(function()return c.result end,30);injected=true;r.failedSaveRetried=true
    end
    assert(c.result and c.result.trialSaved,c.battle.saveError);local record=assert(T.history())[1];assert(T.validate(record));assert(record.status~='aborted' and record.controller==mode)
    assert(record.setup.teamPolicies.wuyun.sampleCount==35 and record.setup.teamPolicies.ninilite.sampleCount==39)
    assert(not require('Training.FlowerTrialStore').validate(record),'Joint record accepted by single-learner validator')
    assert(not require('Training.FlowerTrialStore').saveAsync(record),'Joint record saved into single trials')
    for _,actor in ipairs({'ninilite','wuyun'})do
     local samples=assert(require('Training.FlowerPolicy').inspect({record.episode},actor));assert(samples.coverage.total==0)
     local actions=0;for _,step in ipairs(record.episode.steps)do if step.action.actor==actor then assert(step.action.origin~='demo');actions=actions+1 end end
     assert(actions>0,'Joint learner never executed')
    end
    assert(T.saveAsync(c.trialRecord));assert(singleState()==before)
    records[profile][mode]=record;r[profile]=r[profile] or {};r[profile][mode]={status=record.status,seconds=record.seconds,evaluation=record.evaluation};save()
   end
  end
  local rows=assert(T.history());assert(#rows==8)
  local review=assert(T.review(sources,records.field.basic.setup.models,rows));assert(review.completed==4);r.review=review
  for _,profile in ipairs({'near','far','reproduction','field'})do assert(T.compare(records[profile].basic,records[profile].candidate))end
  local bad=D.json.decode(D.json.encode(records.field.candidate),32);bad.setup.teamPolicies.wuyun.trainingAccuracy=.01;assert(not T.validate(bad));r.changedPartnerRejected=true
  bad=D.json.decode(D.json.encode(records.field.candidate),32);bad.episode.steps[1].action.origin='demo';assert(not T.validate(bad));r.humanActionRejected=true
  assert(singleState()==before);r.singleStateUnchanged=true
  c=P.openAsync(nil,'ninilite',nil,nil,nil,'field',sources);D.sleep(.5);assert(c.teamReview.completed==4 and c.label.text:find('联合评价覆盖：4/4',1,true))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-team-review.tga');D.sleep(.2);r.reopened=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
