-- Controlled geometry lessons through the real demonstration executor.
-- Reinforcement AI is paused only while collecting these QA lessons. Frozen
-- trial enables it; no Boss/learner speed, HP or attack timing is changed.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-dual-threat-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local Small=require('Enemy.SmallYingzhao')
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Dual-threat timeout');D.sleep(.02)end end
  local function addChild(b)
   local child={enemy=Small.create(b.world,2100),enemyHP=70};child.guard=Small.new(b,child);child.guard.nextAttack=math.huge;b.enemies[#b.enemies+1]=child;return child
  end
  local function setup(b,child,direction,same)
   local a=b.arena;local boss=b.enemies[1];local x=direction==1 and 2200 or 2600
   require('Combat.Displacement').clear(a.student);a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(x+direction*700,b.world.offset+155)
   boss.enemy:stop();boss.enemy.velocity=D.Vec2.zero;boss.enemy.position=D.Vec2(x,b.world.offset+255);boss.guard.nextAttack=math.huge
   child.guard.sequence:cancel('FIXTURE_REPOSITION');child.guard.nextAttack=math.huge;child.enemy.velocity=D.Vec2.zero;child.enemy.position=D.Vec2(a.student.x+direction*(same and -180 or 180),b.world.offset+105)
   b.mentor.x=x-direction*700;b.wuyun.student.x=x-direction*800;b.wuyun.mode='review'
   D.sleep(.35);wait(function()return a.student.onSurface and boss.enemy.onSurface and child.enemy.onSurface end)
   return a,boss
  end
  local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor='ninilite',item='emp',quantity=1}},'ninilite')
  assert(b:start());b.enemies[1].guard.nextAttack=math.huge;local child=addChild(b)
  for _,case in ipairs({{1,true},{1,false},{-1,true},{-1,false},{1,true},{-1,false}})do
   local direction,same=case[1],case[2];local a,boss=setup(b,child,direction,same)
   assert(boss.guard:attack('massive',a.student));D.sleep(.1)
   assert(b:command(direction==1 and'right'or'left'))
   wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge;a.student:stop()
   assert(a.studentHP==100,'Teaching failed to avoid Boss')
  end
  b:finish('aborted','Controlled dual-threat lesson');wait(function()return b.phase=='aborted'end)
  local resources=b.supplies:evidence();b.bossTrace.resources=resources
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='ninilite',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
  local review=assert(require('Training.YingzhaoReview').rebuild(e));r.reviewText=require('Training.YingzhaoReview').text(review)
  assert(r.reviewText:find('同侧 3 段 / 夹击 3 段',1,true))
  local P=require('Training.YingzhaoPolicy');local data=assert(P.inspect({e},'ninilite'));r.actions=data.actions
  assert(data.actions.fmove==3 and data.actions.bmove==3)
  local m=assert(P.buildAsync({e},'ninilite'));r.model=m;r.source=e;save()
  assert(m.featureSchemaVersion==4 and m.trainingAccuracy==1 and m.sampleCount==6)
  local legacy=assert(P.buildAsync({e},'ninilite',1));r.legacyAccuracy=legacy.trainingAccuracy
  assert(legacy.trainingAccuracy<1,'Legacy aliased data unexpectedly distinguishes sides')
  local snapshot=D.json.decode(D.json.encode(m),32)
  local virtual=assert(require('Economy.CombatSession').virtual('dual-threat-trial',{{actor='ninilite',item='emp',quantity=1}}))
  local trial=require('Enemy.BigYingzhaoBattle').createAsync(models,virtual,{virtual=true});require('Training.YingzhaoTrial').attach(trial,m)
  assert(trial:start());trial.enemies[1].guard.nextAttack=math.huge;local reinforcement=addChild(trial)
  for _,case in ipairs({{1,true},{1,false},{-1,true},{-1,false}})do
   local direction,same=case[1],case[2];local a,boss=setup(trial,reinforcement,direction,same)
   local hp=a.studentHP;local x=a.student.x;local first=#trial.yingzhaoCandidateDecisions
   reinforcement.guard.nextAttack=0
   assert(boss.guard:attack('massive',a.student));local strike=boss.guard.strike
   wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge
   local row={direction=direction,same=same,damage=hp-a.studentHP,travel=(a.student.x-x)*direction,actions={}}
   for i=first+1,#trial.yingzhaoCandidateDecisions do local d=trial.yingzhaoCandidateDecisions[i];if d.accepted then row.actions[d.action]=(row.actions[d.action]or 0)+1 end end
   local bossHits=0;for _,impact in ipairs(strike.impacts)do for _,target in ipairs(impact.targets or {})do if target.actor==a.student.entity.name then bossHits=bossHits+1 end end end
   row.bossHits=bossHits;row.alive=a.studentHP>0;r.trials[#r.trials+1]=row;save()
   assert(row.alive and row.travel>100 and bossHits==0,'Frozen dual-threat evasion failed')
   wait(function()return not require('Combat.Displacement').blocked(a.student)end)
  end
  assert(require('Training.FlowerIdentity').equal(snapshot,trial.yingzhaoCandidate));assert(#trial.arena.recorder.samples==0)
  trial:finish('aborted','Dual-threat frozen fixture');wait(function()return trial.phase=='aborted'end)
  D.Cache:loadAsync({'ar.clip','button.clip','gearBox.clip'})
  local view=require('UI.Settlement')({missionMode=true,economy=assert(b.supplies:closeVirtual('aborted')),economyMode='virtual',resultStatus='Failed',missionTitle='双威胁示范 · 测试复盘',resultTitle='示范已结束',reportText=r.reviewText,storyText='脚本驱动的隔离QA示范；未采用候选。'})
  view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.3)
  assert(view.reportArea.viewSize.height>view.reportArea.height,'Long tactical report did not scroll')
  view.reportArea:scrollToPosY(-10000,0);D.sleep(.2)
  r.screenshot=root..'/Docs/evidence/2026-10-05/yingzhao-dual-threat-review.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
  r.notHumanDemonstration=true;r.notNaturalVictory=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
