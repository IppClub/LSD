-- Public mission gate and real charged session from an earned adopted archive.
-- Short deployment/withdrawal regression, not a natural Boss victory or full journey.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-deployment-result.json';local r={status='RUNNING',osInput=false,naturalVictory=false,checks={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local parent=assert(os.getenv('LSD_QA_PARENT_RESULT'));local prior=D.json.decode(D.Content:load(parent),32)
  assert(prior.status=='PASS'and prior.adoptedCheckpoint:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-checkpoint%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-deployment-'..os.time()..'.db';r.database=db;r.parentEvidence=parent
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.adoptedCheckpoint,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local service=assert(require('Mission.Service').open());assert(service:summary().unlocks['yingzhao-route-cleared'])
  local function models()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local original=models();local adoption=require('Training.YingzhaoAdoptionStore');local state=adoption.state('ninilite');assert(state.current==prior.active)
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Deployment UI timed out');D.sleep(.02)end end
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true})
  local world=D.Platformer.Data.store.world;local gate=assert(world.disarmGate);wait(function()return gate.menu.visible and gate.menu.menu.enabled end)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end);assert(gate.supplyPanel.quote.total<=initial)
  gate.supplyPanel.saveButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end)
  local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle
  assert(b.bossCombat.view.node.parent==level.controls and not b.bossCombat.view.closed,'Boss status view ownership/feedback is invalid after adoption loading')
  r.checks.statusViewOwnership=true
  local deployed=b.yingzhaoDeployments.ninilite;assert(deployed.status=='adopted'and deployed.id==prior.active and deployed.candidateId==prior.candidateId and deployed.algorithm==prior.algorithm)
  assert(b.yingzhaoDeployments.wuyun.status=='NOT_ADOPTED'and not b.supplies.isVirtual)
  assert(b.yingzhaoCandidates.ninilite.algorithm==prior.algorithm and b.yingzhaoDeploymentText:find('专项',1,true))
  r.readyDeployment=deployed;r.supportPresent=b.support~=nil;r.checks.publicGateAndFormalLoad=true
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end);D.sleep(5)
  local decisions=b.yingzhaoDecisionsByActor.ninilite;assert(#decisions>0)
  for _,d in ipairs(decisions)do assert(d.origin=='adopted')end
  r.decisions=#decisions;r.accepted=0;for _,d in ipairs(decisions)do if d.accepted then r.accepted=r.accepted+1 end end
  level.withdraw:emit('Tapped');wait(function()return level.phase=='result'or level.phase=='save-error'end,45)
  assert(level.phase=='result',level.error);assert(level.result.resultLayout=='MissionFail'and b.report.economy.income==0)
  assert(b.report.learners.ninilite.training.domain=='big-yingzhao'and b.report.learners.ninilite.training.adoptionId==prior.active and b.report.learners.ninilite.training.algorithm==prior.algorithm)
  assert(b.report.learners.ninilite.basicTraining and b.report.learners.ninilite.policyDecisions)
  assert(E.wallet().available==initial-b.report.economy.cost and not E.active());assert(models()==original)
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));assert(episode.boss.status=='aborted'and episode.boss.deployments.ninilite.id==prior.active)
  assert(require('Training.FlowerIdentity').equal(adoption.state('ninilite'),state));r.cost=b.report.economy.cost;r.balanceBefore=initial;r.balanceAfter=E.wallet().available;r.checks.realLedgerReportAndEpisode=true
  level.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end);r.checks.normalReturn=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
