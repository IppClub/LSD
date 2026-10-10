local script=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script));local out=root..'/Test/flower-wuyun-deployment-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-wuyun-current-result.json'),32));assert(prior.status=='PASS' and prior.ready);local source=prior.database
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-wuyun%-current%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-wuyun-deployment-'..os.time()..'.db';assert(not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local R=require('Training.FlowerAdoptionReview');local S=require('Training.FlowerAdoptionStore')
  local archive=assert(require('Training.FlowerPolicyStore').evidence('wuyun'));local rows=assert(require('Training.FlowerTrialStore').history('wuyun'))
  local bundle,review=R.make(archive,rows[1].setup.models,rows);assert(bundle,review)
  local p=require('Training.FlowerPractice').openAsync(nil,'wuyun');D.sleep(.3);p.adoptionButton:emit('Tapped');local panel=assert(p.adoptionView)
  assert(panel.ready);for i=1,4 do panel.next:emit('Tapped')end;panel.adopt:emit('Tapped')
  local deadline=D.App.totalTime+20;while panel.busy do assert(D.App.totalTime<deadline);D.sleep(.02)end;assert(panel.saved,panel.error)
  local selected=assert(S.load('wuyun'));r.adoptionId=selected.id
  assert(require('Training.FlowerPolicy').actionText('melee')=='刀击')
  assert(panel.label.text:find('刀击',1,true) or require('Training.FlowerPolicy').learnedActionsText(selected.bundle.source.policy):find('刀击',1,true))
  while panel.page>0 do panel.previous:emit('Tapped')end
  assert(panel.label.text:find('刀击',1,true))
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-wuyun-review.tga');D.sleep(.2)
  panel.back:emit('Tapped')
  local ni=require('Training.FlowerPractice').openAsync(nil,'ninilite');D.sleep(.2);ni.adoptionButton:emit('Tapped')
  local other=assert(ni.adoptionView);assert(not other.ready and other.partner.id==selected.id)
  for i=1,4 do other.next:emit('Tapped')end;other.adopt:emit('Tapped')
  assert(not S.inspect('ninilite') and S.inspect('wuyun').id==selected.id)
  other.back:emit('Tapped');r.untestedJointDeploymentBlocked=true

  -- Compose two existing QA fixtures: trained evidence plus an actually earned
  -- factory-entry story fact. This test does not revalidate the story journey.
  local journey=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db'
  assert(D.DB:exec("ATTACH DATABASE '"..journey.."' AS journey")>=0)
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes SELECT * FROM journey.Game0StoryNodes WHERE id='factory-encounter'")>=0)
  assert(D.DB:exec('DETACH DATABASE journey')>=0)
  local service=assert(require('Mission.Service').open());local attempt=assert(service:beginAsync('c0-m05',bundle.models,assert(service:formation())))
  local loads=0;local load=S.load;S.load=function(...)loads=loads+1;return load(...)end
  local controller=require('Training.FlowerController');local step=controller.step;local decisions=0
  controller.step=function(...)decisions=decisions+1;return step(...)end
  local c=require('Factory.Level').openAsync(service,attempt);local b=c.battle
  assert(loads==2 and b.wuyun.flowerDeployment.id==selected.id and not b.arena.flowerDeployment)
  assert(b.flowerDeployments.wuyun.status=='adopted')
  assert(controller.text(b):find('花妖专项'))
  D.sleep(.1);c.start:emit('Tapped');assert(b.arena.mode=='trial' and b.wuyun.mode=='demo')
  local began=D.App.totalTime
  while b.phase=='playing' and D.App.totalTime-began<3 do
   assert(D.App.totalTime-began<135,'Deployed battle stalled')
   b:command('shoot');if b.effects.confusions>0 then b:command('song')end;D.sleep(.1)
  end
  if b.phase=='playing'then c.withdraw:emit('Tapped')end
  local deadline=D.App.totalTime+10;while b.phase=='saving' or not c.result do assert(D.App.totalTime<deadline and b.phase~='save-error','Deployment save failed');D.sleep(.05)end
  assert(loads==2 and decisions>0,'Specialist was not executed or was reloaded')
  local report=b.report.learners.wuyun
  assert(report.adoptionId==selected.id and report.controller=='flower-c45')
  local savedReport=D.json.decode(D.DB:query('SELECT report FROM lsd.Game0MissionAttempts WHERE id=?',{attempt.id})[1][1],32)
  assert(savedReport.learners.wuyun.adoptionId==selected.id and savedReport.learners.wuyun.training.count==35)
  r.currentDeploymentExecuted=true;r.savedIdentity=true;r.loadsPerEncounter=loads;r.decisions=decisions
  b.arena.world:removeFromParent();c.result:removeFromParent()
  local training=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models=bundle.models},nil,{training=true})
  assert(not training.arena.flowerDeployment and not training.flowerDeployments and loads==2)
  training:finish('aborted','QA training isolation');D.sleep(.1);training.arena.world:removeFromParent();r.trainingIsolated=true
  assert(S.rollbackAsync('wuyun'))
  local baseline=require('Factory.Battle').createAsync({finishAsync=function()return true end},{mission='c0-m05',models=bundle.models})
  assert(not baseline.arena.flowerDeployment and not baseline.wuyun.flowerDeployment);assert(baseline:start() and baseline.arena.mode=='trial' and baseline.wuyun.mode=='trial')
  baseline:finish('aborted','QA rollback deployment');D.sleep(.1);baseline.arena.world:removeFromParent();r.rollbackUsesBasic=true
  controller.step=step;S.load=load
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
