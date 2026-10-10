local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/target-policy-native-result.json';local r={status='RUNNING'}
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local practice=require('Training.PartPractice').createAsync('ninilite');local a=practice.arena
  local function wait(f)local limit=D.App.runningTime+6;while not f()do assert(D.App.runningTime<limit,'Target lesson wait');D.sleep(.02)end end
  wait(function()return a.student.onSurface and a.enemy.onSurface end)
  local T=require('Training.TargetPolicy')
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
  local candidate,why=practice:learnAsync();assert(candidate,why)
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
  practice:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
