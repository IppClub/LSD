local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/part-features-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local strip=require('Tutorial.LightStrip');local original=strip.LightStrip;local strips=0
  strip.LightStrip=function(origin,bullet,color)assert(bullet.parent and color==3431841523);strips=strips+1;original(origin,bullet,color);if strips==1 then D.thread(function()D.sleep(.05);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/tutorial-strip-reuse.tga')end)end end
  local practice=require('Training.PartPractice').createAsync('ninilite');local a=practice.arena
  local function wait(f)local limit=D.App.runningTime+6;while not f()do assert(D.App.runningTime<limit,'Target lesson wait');D.sleep(.02)end end
  wait(function()return a.student.onSurface and a.enemy.onSurface end)
  local T=require('Training.TargetPolicy')
  local unknown=a.targetSnapshot();assert(unknown.part_head=='unknown' and unknown.part_front_leg=='unknown')
  r.initialParts=unknown

  assert(not practice:learnAsync(),'Empty lesson accepted')
  for i=1,8 do
   wait(function()return a:available('laser')end)
   a.student.faceRight=true
   local part=i%2==1 and 'head' or 'front-leg'
   assert(a.selectPart(part));assert(a:request('laser','demo'))
   wait(function()local s=practice.demonstrations[i];return s and s.step.sealed end)
   assert(practice.demonstrations[i].step.action.aimAngle and not practice.demonstrations[i].step.action.shotRejected)
  end
  wait(function()return not a:isAttacking() and #practice.partCombat.shots==0 end)
  local observed=a.targetSnapshot();assert(observed.part_head=='exposed' and observed.part_front_leg=='exposed')
  local actual=practice.partCombat.target.damage.parts.head;local ap=actual.ap;actual.ap=80
  assert(a.targetSnapshot().part_head=='exposed','Read unobserved armor regeneration');actual.ap=ap
  local candidate,why=practice:learnAsync();assert(candidate,why);assert(candidate.tree.featureSchemaVersion==4)
  assert(T.validate(candidate,'ninilite','dataotie') and candidate.tree.sampleCount==8)
  assert(not require('Training.Model').validate(candidate),'Part tree was accepted as combat-action model')
  assert(not T.validate(candidate,'wuyun','dataotie') and not T.validate(candidate,'ninilite','xiaotaotie'))
  local part=T.predict(candidate,practice.demonstrations[1].state,function()return true end,'ninilite','dataotie');assert(part)
  assert(not T.predict(candidate,practice.demonstrations[1].state,function()return false end,'ninilite','dataotie'))
  local before=#practice.demonstrations;wait(function()return a:available('laser')end)
  local accepted,reason=practice:tryCandidate();assert(accepted,reason)
  wait(function()return not a:isAttacking() and #practice.partCombat.shots==0 end)
  assert(#practice.demonstrations==before and practice.candidate==candidate,'Candidate labelled its own demonstrations')
  local shot=practice.partCombat.journal.steps[#practice.partCombat.journal.steps]
  assert(shot.action.intendedPart~='unknown' and shot.action.aimAngle)
  local copy=D.json.decode(D.json.encode(candidate),32);copy.partSetVersion=99;assert(not T.validate(copy))
  copy=D.json.decode(D.json.encode(candidate),32);copy.tree.rules[1].action='laser';assert(not T.validate(copy))
  r.samples=candidate.tree.sampleCount;r.trainingAccuracy=candidate.tree.trainingAccuracy;r.rules=candidate.tree.rules
  r.predicted=part;r.actualTrialIntent=shot.action.intendedPart;r.actualTrialHits=shot.hits;r.noSelfLabels=true;r.legalMask=true
  local Recorder=require('Training.Recorder');local Model=require('Training.Model')
  local rec=Recorder.new({characterId='ninilite',actions={'head','front_leg'},featureSchemaVersion=4})
  for i=1,12 do for _,reverse in ipairs({false,true})do
   local state={distance=500,facing='yes',enemyAction='idle',attackReady='yes',part_head=reverse and 'exposed' or 'armored',part_front_leg=reverse and 'armored' or 'exposed'}
   assert(rec:record(state,reverse and 'front_leg' or 'head',true))
  end end
  local swapped=assert(Model.buildAsync(rec));assert(swapped.featureSchemaVersion==4)
  local state={distance=500,facing='yes',enemyAction='idle',attackReady='yes',part_head='armored',part_front_leg='exposed'}
  assert(Model.predict(swapped,state)=='head');state.part_head='exposed';state.part_front_leg='armored';assert(Model.predict(swapped,state)=='front_leg')
  swapped.featureSchemaVersion=3;assert(not Model.validate(swapped));swapped.featureSchemaVersion=4
  local old=D.json.decode(D.json.encode(candidate),64);old.tree.featureSchemaVersion=3;old.tree.rules={{conditions={},action='head'}};assert(T.validate(old))
  assert(Model.predict(old.tree,state)=='head')
  practice:reset();assert(a.targetSnapshot().part_head=='unknown','Knowledge leaked across episodes')
  assert(strips==9);r.tutorialStrips=strips;strip.LightStrip=original
  r.swapRules=swapped.rules;r.swapAccuracy=swapped.trainingAccuracy;r.noHiddenArmor=true;r.resetKnowledge=true;r.legacyTarget=true
  practice:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
