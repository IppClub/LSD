-- Combine archived native QA lessons, then evaluate without altering Boss AI,
-- health, positions, speed or timeline. No automatic adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mixed-natural-result.json';local r={status='RUNNING',rounds={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-mixed-natural-'..os.time()..'.db';r.database=db;assert(not D.DB:existDB('lsd'))
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerPractice').models())
  local function adopted()return D.json.decode(D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')}),32)end
  local equal=require('Training.FlowerIdentity').equal;local before=adopted()
  local economy=require('Economy.Store');assert(economy.open());local balance=economy.wallet().available
  for _,file in ipairs({'yingzhao-alternating-result.json','yingzhao-dual-threat-result.json','yingzhao-wuyun-alternating-result.json'})do
   local source=D.json.decode(D.Content:load(root..'/Test/'..file),32);assert(source.status=='PASS'and source.source)
   for _,step in ipairs(source.source.boss.steps)do assert(step.before.featureSchemaVersion==2,'Mixed lesson missing new direction observation')end
   assert(require('Training.YingzhaoStore').saveAsync(source.source))
  end
  local punch=D.json.decode(D.Content:load(root..'/Test/yingzhao-punch-lesson-result.json'),32);assert(punch.status=='PASS')
  for _,actor in ipairs({'ninilite','wuyun'})do assert(require('Training.YingzhaoStore').saveAsync(punch.actors[actor].source))end
  local finiteWave=D.json.decode(D.Content:load(root..'/Test/yingzhao-wave-reach-result.json'),32);assert(finiteWave.status=='PASS')
  for _,actor in ipairs({'ninilite','wuyun'})do
   local source=finiteWave.actors[actor].source;local review=require('Training.YingzhaoReview')
   assert(review.text(assert(review.rebuild(source))):find('可达 3 段 / 范围外 3 段 / 未知 0 段',1,true))
   assert(require('Training.YingzhaoStore').saveAsync(source))
  end
  local edges=D.json.decode(D.Content:load(root..'/Test/yingzhao-edge-lesson-result.json'),32);assert(edges.status=='PASS')
  for _,actor in ipairs({'ninilite','wuyun'})do
   local source=edges.actors[actor].source;local review=require('Training.YingzhaoReview')
   assert(review.text(assert(review.rebuild(source))):find('移动起点：左边界 ',1,true))
   assert(require('Training.YingzhaoStore').saveAsync(source))
  end
  local melee=D.json.decode(D.Content:load(root..'/Test/yingzhao-summon-melee-result.json'),32);assert(melee.status=='PASS')
  local meleeSamples=0
  for _,case in ipairs(melee.cases)do assert(require('Training.YingzhaoStore').saveAsync(case.source));meleeSamples=meleeSamples+case.samples end
  local hunt=D.json.decode(D.Content:load(root..'/Test/yingzhao-hunt-lesson-result.json'),32);assert(hunt.status=='PASS')
  local huntSamples={ninilite=0,wuyun=0}
  for _,case in ipairs(hunt.cases)do assert(require('Training.YingzhaoStore').saveAsync(case.source));huntSamples[case.actor]=huntSamples[case.actor]+case.samples end
  local hit=D.json.decode(D.Content:load(root..'/Test/yingzhao-hit-lesson-result.json'),32);assert(hit.status=='PASS')
  local hitSamples={ninilite=0,wuyun=0}
  for _,case in ipairs(hit.cases)do assert(require('Training.YingzhaoStore').saveAsync(case.source));hitSamples[case.actor]=hitSamples[case.actor]+case.samples end
  local conservation=D.json.decode(D.Content:load(root..'/Test/yingzhao-conserve-lesson-result.json'),32);assert(conservation.status=='PASS')
  local conserveSamples=0
  for _,case in ipairs(conservation.cases)do assert(require('Training.YingzhaoStore').saveAsync(case.source));conserveSamples=conserveSamples+case.samples end
  local spacing=D.json.decode(D.Content:load(root..'/Test/yingzhao-spacing-lesson-result.json'),32);assert(spacing.status=='PASS')
  local spacingSamples={ninilite=0,wuyun=0}
  for _,case in ipairs(spacing.cases)do assert(case.damage==0 and case.armorDamage==35);assert(require('Training.YingzhaoStore').saveAsync(case.source));spacingSamples[case.actor]=spacingSamples[case.actor]+case.samples end
  local summonEscape=D.json.decode(D.Content:load(root..'/Test/yingzhao-summon-escape-result.json'),32);assert(summonEscape.status=='PASS')
  local escapeSamples=0
  for _,case in ipairs(summonEscape.cases)do if case.escape then assert(case.damage==0 and case.childHP==0);assert(require('Training.YingzhaoStore').saveAsync(case.source));escapeSamples=escapeSamples+case.samples end end
  local companion=assert(require('Training.YingzhaoPolicyStore').learnAsync('wuyun'));assert(companion.model.sampleCount==19+edges.actors.wuyun.samples+meleeSamples+huntSamples.wuyun+hitSamples.wuyun+spacingSamples.wuyun);r.companion=companion.model
  local candidate=assert(require('Training.YingzhaoPolicyStore').learnAsync('ninilite'));r.model=candidate.model
  assert(candidate.model.sampleCount==25+edges.actors.ninilite.samples+huntSamples.ninilite+hitSamples.ninilite+conserveSamples+spacingSamples.ninilite+escapeSamples,'Mixed lessons unexpectedly include other sources')
  assert(equal(assert(require('Training.YingzhaoPolicyStore').loadLatestAsync('ninilite')).model,candidate.model))
  r.conservationContrast={}
  for _,group in ipairs({{name='clear',cases=conservation.cases},{name='near-summon',cases=summonEscape.cases}})do
   for _,case in ipairs(group.cases)do
    if group.name=='clear'or case.escape then
     local action,why=require('Training.YingzhaoPolicy').predict(candidate.model,case.before)
     r.conservationContrast[#r.conservationContrast+1]={kind=group.name,side=case.side,action=action,reason=why,expected=group.name=='clear'and'idle'or'bmove'}
    end
   end
  end
  r.coverage={}
  for _,entry in ipairs({candidate,companion})do
   local m=entry.model;local payload=D.json.decode(D.DB:query('SELECT payload FROM lsd.Game0YingzhaoCandidates WHERE id=?',{entry.id})[1][1],32)
   local data=assert(require('Training.YingzhaoPolicy').inspect(payload.records,m.characterId,m.featureSchemaVersion))
   local row={known={correct=0,total=0},legacy={correct=0,total=0},actions={},reachabilityConditions=0}
   for _,rule in ipairs(m.rules)do for _,c in ipairs(rule.conditions)do if c.name:match('^aim_')then row.reachabilityConditions=row.reachabilityConditions+1 end end end
   for _,sample in ipairs(data.samples)do
    local predicted
    for _,rule in ipairs(m.rules)do
     local match=true;for _,c in ipairs(rule.conditions)do if sample.state[c.name]~=c.value then match=false;break end end
     if match then predicted=rule.action;break end
    end
    local group=sample.state.aim_head=='unknown'and row.legacy or row.known
    group.total=group.total+1;if predicted==sample.action then group.correct=group.correct+1 end
    local action=row.actions[sample.action]or{correct=0,total=0};row.actions[sample.action]=action
    action.total=action.total+1;if predicted==sample.action then action.correct=action.correct+1 end
   end
   r.coverage[m.characterId]=row
  end
  save()
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true});assert(loadout)
  local currentBattle
  local report=require('Training.YingzhaoComparison').runAsync(models,candidate.model,loadout,function(round)
   for _,step in ipairs(round.trace.steps)do assert(step.origin~='command-gather','Automatic assistance interrupted learner movement')end
   local actions,failures,missing,blockers={},{},{},{};local knownBlocked=0
   local summonDamage,summonKills=0,0
   for _,hit in ipairs(round.trace.hits)do if hit.summoned and hit.source=='mentor'then summonDamage=summonDamage+(hit.healthDamage or 0);if hit.hpAfter==0 then summonKills=summonKills+1 end end end
   for _,d in ipairs(round.decisions or {})do
    assert(require('Training.YingzhaoFeatures').validate(d.observation),'Missing valid decision-time observation')
    if d.reason=='NO_MATCH'then local s=d.observation;local key=s.target..'/'..s.targetDistance..'/'..s.bossAction;missing[key]=(missing[key]or 0)+1 end
    for label,cause in pairs(d.blockedActions or {})do
     blockers[cause]=(blockers[cause]or 0)+1
     if cause=='PART_UNREACHABLE'then
      local part=label:match('^shoot@(.+)$');assert(part and d.observation['aim_'..part]=='blocked','Decision geometry disagrees with real solver');knownBlocked=knownBlocked+1
     end
    end
    local list=d.accepted and actions or failures;local key=d.accepted and d.action or d.reason or'unknown';list[key]=(list[key]or 0)+1 end
   local companionActions,companionFailures,companionMissing={},{},{}
   for _,d in ipairs(currentBattle.yingzhaoDecisionsByActor.wuyun)do
    local list=d.accepted and companionActions or companionFailures;local key=d.accepted and d.action or d.reason or'unknown';list[key]=(list[key]or 0)+1
    if d.reason=='NO_MATCH'then local s=d.observation;local key=s.target..'/'..s.targetDistance..'/'..s.bossAction;companionMissing[key]=(companionMissing[key]or 0)+1 end
   end
   r.rounds[#r.rounds+1]={knownBlockedPartSelections=knownBlocked,companionActions=companionActions,companionFailures=companionFailures,companionMissing=companionMissing,mode=round.mode,status=round.status,seconds=round.seconds,cost=round.cost,hp=round.hp,bossHP=round.bossHP,armor=round.armorDamage,damage=round.healthDamage,actions=actions,failures=failures,uncovered=missing,blockedActions=blockers,mentorSummonDamage=summonDamage,mentorSummonKills=summonKills};save()
  end,{companion=companion.model,onBattle=function(b)currentBattle=b end})
  r.report=report;r.reportText=require('Training.YingzhaoComparison').text(report)
  local noMatch=r.rounds[2].failures.NO_MATCH or 0
  if noMatch>0 then assert(r.reportText:find('未学过的状态/动作 '..noMatch..' 次',1,true),'C4.5 coverage gap counted as unavailable action')end
  r.saved=assert(require('Training.YingzhaoComparisonStore').saveAsync(report))
  local store=require('Training.YingzhaoComparisonStore')
  assert(equal(assert(store.load(r.saved)),D.json.decode(D.json.encode(report,false,true),32)),'Companion decisions did not round-trip')
  for _,round in ipairs(report.rounds)do assert(round.companionDecisions and #round.companionDecisions>0)end
  assert(r.reportText:find('中的队友乌云：',1,true),'Companion review absent')
  local copy=D.json.decode(D.json.encode(report),32);copy.rounds[1].companionDecisions[1].observation.health='invalid'
  assert(not store.validate(copy),'Malformed companion observation accepted')
  copy=D.json.decode(D.json.encode(report),32);for _,round in ipairs(copy.rounds)do round.companionDecisions=nil end
  assert(store.validate(copy),'Legacy report rejected')
  r.companionReadback=true;r.legacyReportCompatible=true

  assert(equal(assert(require('Training.YingzhaoPolicyStore').loadLatestAsync('ninilite')).model,candidate.model))
  assert(equal(before,adopted())and economy.wallet().available==balance)
  r.adoptionUnchanged=true;r.walletUnchanged=true;r.sourceKind='scripted-native-QA-lessons'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
