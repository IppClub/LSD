-- All evaluation profiles run to natural termination using isolated saved models.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script))
local out=root..'/Test/flower-heldout-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={status='RUNNING',rounds={}};local function save()D.Content:save(out,D.json.encode(r))end
 local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-learning%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-heldout-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local P=require('Training.FlowerPractice');local S=require('Training.FlowerScenarios');local Store=require('Training.FlowerTrialStore')
  local function wait(fn,n)local endAt=D.App.totalTime+(n or 10);while not fn()do assert(D.App.totalTime<endAt,'Heldout UI timeout');D.sleep(.02)end end
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks'),D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerPractice')},false,true)end
  local before=progress()
  local c=P.openAsync(nil,'ninilite')
  for _,id in ipairs({'near','far','reproduction','field','standard'})do
   local previous=c.ui;c.scenarioButton:emit('Tapped');wait(function()local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');return ui and ui~=previous end)
   c=D.Director.ui3D:getChildByTag('flower-practice-controls').practice
   assert((c.scenario or 'standard')==id)
   if id~='standard'then local accepted,why=c:start();assert(not accepted and why=='EVALUATION_ONLY')end
  end
  local demo=assert(require('Training.FlowerPracticeStore').latest('ninilite')).episode
  local tagged=D.json.decode(D.json.encode(demo),32);tagged.practiceProfile='near'
  assert(not require('Training.FlowerPracticeStore').saveAsync('ninilite','aborted',tagged),'Heldout tagged as demo')
  local no,why=require('Training.FlowerPolicy').collect({tagged},'ninilite');assert(not no and why=='TOO_FEW_SAMPLES','Heldout entered C4.5')
  -- Validate the second learner receives the same distance setting, without
  -- claiming this setup check is Wuyun's six natural trial outcomes.
  local wu=P.openAsync(nil,'wuyun',nil,nil,nil,'far');assert(math.abs(wu.battle.roots[3].enemy.x-wu.arena.student.x-850)<.01)
  for _,id in ipairs(S.ids)do
   for _,mode in ipairs({'basic','candidate'})do
    c=P.openAsync(nil,'ninilite',nil,nil,nil,id);local profile=S.get(id);local b=c.battle
    assert(c.profile and b.roots[3].enemyHP==profile.bossHP and b.partCombat.target.damage.hp==profile.bossHP and b.roots[3].enemyCombat.bossPhase==profile.phase)
    assert(math.abs(b.roots[3].enemy.x-c.arena.student.x-profile.distance)<.01)
    for part,ap in pairs(profile.armor)do assert(b.partCombat.target.damage.parts[part].ap==ap)end
    assert(#b.partCombat.events==0 and next(b.partCombat.credits.targets)==nil,'Initial exposure minted damage credit')
    D.sleep(.3);if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
    assert(c.mode==mode and b.phase=='playing')
    local started=D.App.totalTime
    while b.phase=='playing' or b.phase=='saving'do
     assert(D.App.totalTime-started<135,'Heldout natural termination timeout')
     r.profile=id;r.mode=mode;r.elapsed=D.App.totalTime-started;r.phase=b.phase;save();D.sleep(.5)
    end
    assert(c.result and c.result.trialSaved,'Heldout save failed '..tostring(b.saveError))
    local record=assert(Store.latest('ninilite'));assert(record.status~='aborted' and record.setup.scenario=='flower-practice-v3' and record.setup.profile.id==id and record.episode.practiceProfile==id)
    local changed=D.json.decode(D.json.encode(record),32);changed.setup.profile.distance=9999;assert(not Store.validate(changed),'Unregistered profile accepted')
    r.rounds[#r.rounds+1]={profile=id,controller=mode,status=record.status,seconds=record.seconds,evaluation=record.evaluation};save()
    assert(progress()==before,'Evaluation changed demonstrations or progression')
   end
  end
  local final=P.openAsync(nil,'ninilite')
  assert(final.generalization and final.generalization.completed==3 and not final.generalization.adoptionEligible)
  r.generalization=final.generalization;r.publicProfiles=true;r.noTrainingLeakage=true;r.wuyunSetup=true;r.naturalRounds=#r.rounds
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-heldout-summary.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
