local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local out=root..'/Test/target-adoption-native-result.json';local r={status='RUNNING'}
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
  local database=D.Content.writablePath..'/target-adoption.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(database))
  assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local Store=require('Training.TargetStore');local store=assert(Store.open('ninilite'))
  assert(not store:saveAsync(candidate));local empty,status=store:load();assert(not empty and status=='NEW_PROFILE')
  local old=D.json.decode(D.json.encode(candidate),32)
  old.traceId=nil
  old.tree.rules={{conditions={},action='front_leg'}}
  assert(store:saveAsync(old));practice.store=store;practice.adopted=old
  assert(not practice:adoptAsync(),'Adopted without comparison')
  local evaluation,problem=practice:evaluateAsync();assert(evaluation,problem)
  assert(#evaluation.groups.baseline==3 and #evaluation.groups.candidate==3 and #evaluation.groups.adopted==3)
  for _,rounds in pairs(evaluation.groups)do for _,round in ipairs(rounds)do assert(round.emitted+round.unavailable<=6 and round.emitted>0,'Missing real shots')end end
  assert(#practice.demonstrations==before,'Comparison self-labelled')
  r.comparison=evaluation.groups
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_target BEFORE INSERT ON Game0TargetTraining WHEN NEW.slot='main' BEGIN SELECT RAISE(ABORT,'QA failure'); END")>=0)
  local revision=store.revision
  local failed,failReason=practice:adoptAsync();assert(not failed and failReason=='WRITE_FAILED',failReason)
  assert(practice.adopted==old and practice.candidate==candidate and store.revision==revision,'Failure replaced original')
  assert(#D.DB:query("SELECT payload FROM lsd.Game0TargetTraining WHERE slot='backup'")==0,'Backup escaped rollback')
  assert(#D.DB:query('SELECT * FROM lsd.Game0TargetRuns')==0,'Trace escaped failed adoption')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_target')>=0)
  local adopted,adoptReason=practice:adoptAsync();assert(adopted,adoptReason);assert(practice.adopted==candidate and practice.previous==old)
  assert(practice:rollbackAsync() and practice.adopted==old)
  assert(practice:rollbackAsync() and practice.adopted==candidate)
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
  assert(D.DB:exec("ATTACH DATABASE '"..database.."' AS lsd")>=0)
  local reloaded=assert(Store.open('ninilite'));local saved=assert(reloaded:load())
  local trace=assert(reloaded:loadTrace(saved.adopted));assert(#trace.demonstrations==8 and #trace.groups.candidate==3)
  local bad=D.json.decode(D.json.encode(trace),64);bad.groups.candidate[1].armor=999;assert(not require('Training.TargetTrace').validate(bad,saved.adopted))
  assert(#D.DB:query('SELECT * FROM lsd.Game0TargetRuns')==1,'Rollback duplicated trace')
  r.traceReadback=true;r.traceAtomic=true;r.traceTamperRejected=true
  assert(saved.revision==4 and saved.adopted.tree.sampleCount==8 and saved.previous.tree.rules[1].action=='front_leg')
  local other=assert(Store.open('wuyun'));assert(not other:load());assert(not other:saveAsync(candidate),'Cross-character policy accepted')
  -- Recreate the production binding without the practice-only exclusion.
  practice.partCombat:close('QA_REBIND');practice.managesPartCleanup=false
  practice.partCombat=require('Ground.PartCombat').new(practice)
  assert(practice.partCombat.policy,'Adopted policy not loaded for deployment')
  wait(function()return a:available('laser')end)
  assert(a:request('laser','model'))
  wait(function()return not a:isAttacking() and #practice.partCombat.shots==0 end)
  local deployed=practice.partCombat.journal.steps[#practice.partCombat.journal.steps]
  assert(deployed.action.controller=='model' and deployed.action.intendedPart~='unknown' and deployed.action.emitted==1)
  r.deployed={intent=deployed.action.intendedPart,hits=deployed.hits}
  assert(#practice.demonstrations==before)
  local future=D.json.decode(D.json.encode(saved),32);future.adopted.partSetVersion=99
  local raw=D.json.encode(future)
  assert(D.DB:exec("UPDATE lsd.Game0TargetTraining SET payload=? WHERE slot='main'",{{raw}})>=0)
  local protected=assert(Store.open('ninilite'));local recovered,reason=protected:load()
  assert(recovered and reason=='RECOVERED_BACKUP' and protected.writeBlocked)
  assert(not protected:saveAsync(candidate) and D.DB:query("SELECT payload FROM lsd.Game0TargetTraining WHERE slot='main'")[1][1]==raw)
  r.atomicFailure=true;r.rollback=true;r.reconnect=true;r.futureProtected=true;r.characterIsolation=true
  practice:close()
  assert(D.DB:exec('DETACH DATABASE lsd')>=0)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
