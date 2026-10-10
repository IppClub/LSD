-- Adopt the second learner against the actually adopted companion, then deploy both.
-- Short formal withdrawal regression; no claim of a Boss victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-dual-deployment-result.json';local r={status='RUNNING',osInput=false,naturalVictory=false,checks={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.algorithm=='yingzhao-c45'and prior.adoptedCheckpoint:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-ui%-adopted%-checkpoint%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-dual-deployment-'..os.time()..'.db';r.database=db;r.parentEvidence=parent;save()
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.adoptedCheckpoint,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.YingzhaoAdoptionStore');local equal=require('Training.FlowerIdentity').equal
  local models=assert(require('Training.FlowerPractice').models());local first=assert(S.loadAsync('ninilite',models,'mission'));local firstState=S.state('ninilite');assert(first.id==prior.active and S.state('wuyun').current==0)
  local function basic()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local before=basic();local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Dual route timed out');D.sleep(.02)end end
  local function controls()return D.Director.ui3D:getChildByTag('training-controls')end
  require('Training.Level')(nil,'wuyun');wait(controls)
  local ui=controls();local menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位对照'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-budget')end);D.Director.ui3D:getChildByTag('yingzhao-comparison-budget').saveButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end,420)
  local v=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(v.saved,v.saveError or v.error)
  assert(v.report.candidate.characterId=='wuyun'and equal(v.report.companion,first.proof.candidate.model))
  for _,round in ipairs(v.report.rounds)do assert(equal(round.companion,first.proof.candidate.model)and #round.companionDecisions>0)end
  assert(equal(v.report.setup.states.ninilite,firstState));r.comparisonId=v.saved;r.checks.actualCompanionCompared=true;save();v.backButton:emit('Tapped');wait(controls)
  ui=controls();menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and not v.state.busy end)
  local p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state;assert(p.bundle and p.adopt.visible);p.adopt:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  local second=assert(S.loadAsync('wuyun',models,'mission'));assert(p.already and equal(firstState,S.state('ninilite'))and S.loadAsync('ninilite',models,'mission').id==first.id);r.adoptions={ninilite=first.id,wuyun=second.id};r.checks.roleIsolatedAdoption=true;save();p.back:emit('Tapped')
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true});local world=D.Platformer.Data.store.world;local gate=assert(world.disarmGate)
  wait(function()return gate.menu.visible and gate.menu.menu.enabled end);gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end);assert(gate.supplyPanel.quote.total<=E.wallet().available);gate.supplyPanel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end);local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle
  assert(b.bossCombat.view.node.parent==level.controls and not b.bossCombat.view.closed,'Boss status view ownership/feedback is invalid after adoption loading')
  r.checks.statusViewOwnership=true
  for actor,id in pairs(r.adoptions)do assert(b.yingzhaoDeployments[actor].status=='adopted'and b.yingzhaoDeployments[actor].id==id and b.yingzhaoCandidates[actor].characterId==actor)end
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end);D.sleep(5)
  r.decisions={};for actor in pairs(r.adoptions)do local rows=b.yingzhaoDecisionsByActor[actor];assert(#rows>0);local accepted=0;for _,d in ipairs(rows)do assert(d.origin=='adopted');if d.accepted then accepted=accepted+1 end end;r.decisions[actor]={count=#rows,accepted=accepted}end
  level.withdraw:emit('Tapped');wait(function()return level.phase=='result'or level.phase=='save-error'end,45);assert(level.phase=='result',level.error);assert(level.result.resultLayout=='MissionFail')
  for actor,id in pairs(r.adoptions)do assert(b.report.learners[actor].training.adoptionId==id and b.report.learners[actor].training.domain=='big-yingzhao')end
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));for actor,id in pairs(r.adoptions)do assert(episode.boss.deployments[actor].id==id)end
  assert(E.wallet().available==initial-b.report.economy.cost and not E.active()and basic()==before);r.cost=b.report.economy.cost;r.balanceAfter=E.wallet().available;r.checks.dualFormalReportAndLedger=true;save()
  level.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end)
  require('Training.Level')(nil,'wuyun');wait(controls);ui=controls();menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('部位成果'):emit('Tapped')
  wait(function()local v=D.Director.ui3D:getChildByTag('yingzhao-adoption');return v and not v.state.busy end);p=D.Director.ui3D:getChildByTag('yingzhao-adoption').state;assert(p.current.id==second.id and p.rollback.visible);p.rollback:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  assert(S.state('wuyun').current==0 and equal(S.state('ninilite'),firstState)and S.loadAsync('ninilite',models,'mission').id==first.id and basic()==before);r.checks.secondRollbackPreservesFirst=true;p.back:emit('Tapped')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
