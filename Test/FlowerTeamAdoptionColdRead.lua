local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-team-adoption-cold-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-deployment-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-deployment%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-team-adoption-cold-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  -- Restore the already earned QA archive pointer solely to test cold deployment.
  assert(D.DB:exec('UPDATE lsd.Game0FlowerTeamState SET current=? WHERE singleton=1',{prior.adoptionId})>=0)
  local S=require('Training.FlowerTeamAdoptionStore');local saved=assert(S.load());assert(saved.id==prior.adoptionId);r.coldLoaded=true
  local P=require('Training.FlowerPractice');local c=P.openAsync(nil,'wuyun');D.sleep(.3);c.adoptionButton:emit('Tapped');assert(not c.adoptionView.ready and c.adoptionView.deploymentError=='TEAM_ADOPTION_ACTIVE');c.adoptionView.back:emit('Tapped');r.singleUIBlocked=true
  local trial=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models=saved.bundle.models},nil,{training=true})
  assert(not trial.arena.flowerDeployment and not trial.wuyun.flowerDeployment);trial:finish('aborted','QA training isolation');r.trainingIsolated=true
  local part=require('Factory.PartCombat');local aim=part.aimPolicy;part.aimPolicy='QA-future-aim'
  local invalid,why=S.load();assert(not invalid and why=='ENCOUNTER_CHANGED');assert(S.inspect().id==saved.id)
  assert(S.rollbackAsync(saved.id));assert(S.currentId()==0);part.aimPolicy=aim;r.oldArchiveRollback=true
  assert(D.DB:exec('UPDATE lsd.Game0FlowerTeamState SET current=? WHERE singleton=1',{saved.id})>=0)
  local load=assert(S.load());local c=P.openAsync(nil,'ninilite',nil,saved.bundle.models,nil,'field',saved.bundle.sources);D.sleep(.3);c.teamReviewButton:emit('Tapped')
  local panel=assert(c.adoptionView);assert(panel.current.id==saved.id)
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-team-adopted.tga');D.sleep(.2)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_team_rollback BEFORE UPDATE ON Game0FlowerTeamState BEGIN SELECT RAISE(ABORT,'QA team rollback'); END")>=0)
  local ok,why=S.rollbackAsync(saved.id);assert(not ok and why=='WRITE_FAILED' and S.currentId()==saved.id)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_team_rollback')>=0);assert(S.rollbackAsync(saved.id));r.rollbackFailureAtomic=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
