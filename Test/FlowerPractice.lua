local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/flower-practice-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-medical-visit-qa-1791007987.db';local dest=D.Content.writablePath..'/lsd-flower-practice-qa-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=saved()
  local function wait(fn,seconds)local deadline=D.App.totalTime+(seconds or 8);while not fn()do assert(D.App.totalTime<deadline,'Flower practice timeout');D.sleep(.02)end end
  require('Training.Level')(nil,'ninilite')
  wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local basic=D.Director.ui3D:getChildByTag('training-controls')
  basic:getChildByTag('training-menu'):getChildByTag('花妖实战'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('flower-practice-controls')end)
  local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');local c=ui.practice;local b=c.battle
  assert(c.arena.world.tag=='VRTraining' and b.minX==800 and b.maxX==3100)
  D.sleep(.5);assert(b.phase=='ready' and #b.partCombat.journal.steps==0)
  c.startButton:emit('Tapped');assert(c.arena.mode=='demo')
  c.hud.move:emit('Right',true);D.sleep(.3);c.hud.move:emit('Right',false)
  wait(function()return c.arena.student.onSurface and not c.arena:isAttacking()end)
  c.hud.weapon:emit('TapBegan');c.hud.weapon:emit('TapEnded')
  wait(function()for _,s in ipairs(b.partCombat.journal.steps)do if s.action.actor=='ninilite' and s.action.origin=='demo' and s.action.name=='shoot' and (s.action.emitted or 0)>0 then return true end end end)
  D.sleep(1.2)
  D.App.winSize=D.Size(683,384);D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-practice-active.tga');D.sleep(.2)
  local store=require('Training.FlowerPracticeStore');store.latest('ninilite')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_flower_demo BEFORE INSERT ON Game0FlowerPractice BEGIN SELECT RAISE(ABORT,'QA flower practice save'); END")>=0)
  c.finishButton:emit('Tapped');wait(function()return b.phase=='save-error'end)
  assert(not c.result and #D.DB:query('SELECT serial FROM lsd.Game0FlowerPractice')==0)
  c.backButton:emit('Tapped');D.sleep(.1);assert(D.Director.ui3D:getChildByTag('flower-practice-controls')==ui,'Failed save abandoned demonstration')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_flower_demo')>=0)
  c.retryButton:emit('Tapped');wait(function()return c.result end)
  local repeated,repeatError=store.saveAsync('ninilite','aborted',c.result.episode);assert(repeated and repeatError==nil);assert(#D.DB:query('SELECT serial FROM lsd.Game0FlowerPractice')==1,'Retry duplicated episode')
  assert(not store.saveAsync('wuyun','aborted',c.result.episode),'Wrong learner accepted')
  local persisted=assert(require('Training.FlowerPracticeStore').latest('ninilite'));assert(persisted.episode.episode==c.result.episode.episode and #persisted.episode.steps==#c.result.episode.steps)
  assert(c.result.episode.context=='flower-practice' and require('Training.CombatStore').validate(c.result.episode))
  local demo,helper,moving=0,0,0
  for _,s in ipairs(c.result.episode.steps)do
   if s.action.actor=='ninilite' and s.action.origin=='demo' then demo=demo+1;if s.action.name=='fmove'then moving=moving+1 end end
   if s.action.actor=='mentor'then assert(s.action.origin=='scripted');helper=helper+1 end
  end
  assert(demo>=2 and helper>0 and moving>0)
  assert(saved()==before,'Practice mutated mission or adopted models')
  D.App.winSize=D.Size(683,384);D.sleep(.3);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-practice-result.tga');D.sleep(.2)
  c.restartButton:emit('Tapped');wait(function()local node=D.Director.ui3D:getChildByTag('flower-practice-controls');return node and node~=ui end)
  local again=D.Director.ui3D:getChildByTag('flower-practice-controls').practice
  assert(#again.context.rounds==1 and again.battle.phase=='ready')
  again.backButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  assert(saved()==before,'Leaving practice mutated progression')
  assert(require('Training.FlowerPracticeStore').latest('ninilite').episode.episode==persisted.episode.episode,'Empty exit replaced the demonstration')
  local niBasic=D.Director.ui3D:getChildByTag('training-controls')
  niBasic:getChildByTag('training-switch'):emit('Tapped')
  wait(function()local node=D.Director.ui3D:getChildByTag('training-controls');return node and node~=niBasic and node.arena.character.id=='wuyun'end)
  D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('花妖实战'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('flower-practice-controls')end)
  local wu=D.Director.ui3D:getChildByTag('flower-practice-controls').practice
  assert(wu.characterId=='wuyun' and wu.melee)
  wu.startButton:emit('Tapped');wait(function()return wu.arena.student.onSurface end)
  wu.melee:emit('TapBegan')
  wait(function()for _,step in ipairs(wu.battle.partCombat.journal.steps)do if step.action.actor=='wuyun' and step.action.name=='melee' and step.action.origin=='demo' and step.sealed then return true end end end)
  wu.finishButton:emit('Tapped');wait(function()return wu.result end)
  local wuSaved=assert(require('Training.FlowerPracticeStore').latest('wuyun'));assert(wuSaved.episode.episode==wu.result.episode.episode)
  assert(require('Training.FlowerPracticeStore').latest('ninilite').episode.episode==persisted.episode.episode)
  assert(saved()==before,'Wuyun practice changed progression');r.bothLearners=true
  r.demoActions=demo;r.scriptedMentor=helper;r.publicEntry=true;r.virtualScene=true;r.restart=true;r.returned=true;r.progressUnchanged=true;r.saveRetry=true;r.idempotent=true
 end,debug.traceback)
 r.status=ok and 'PASS'or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
