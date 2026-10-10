local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-fallback-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-full-coverage-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-full%-coverage%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-fallback-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.ResourceQStore');local Trials=require('Training.ResourceQTrials');local equal=require('Training.FlowerIdentity').equal
  local candidate=assert(Store.loadLatestAsync());assert(candidate.depth==4 and candidate.bundle.trainingGoal=='resource-clear-v1')
  local oldRecords=assert(Trials.loadAsync(candidate.id));assert(#oldRecords==10)
  local F=require('Training.ResourceFallback');local sample,base
  for _,entry in ipairs(oldRecords)do if entry.record.mode=='evaluate'then
   for _,id in ipairs({'ninilite','wuyun'})do for _,row in ipairs(entry.record.trace.actors[id].steps)do
    if row.action=='shoot'and row.decisionSource.state then sample=row;base=candidate.bundle.baseModels[id];break end
   end end
  end end
  assert(sample);local copy=function(x)return D.json.decode(D.json.encode(x,false,true),32)end
  local state=copy(sample.state);state.target='boss';state.resources.ammo.emp=10
  for name in pairs(require('Training.FlowerFeatures').parts)do state['part_'..name]='exposed'end
  local available={idle=true,fmove=true,bmove=true,laser=true,melee=false}
  assert(require('Training.Model').predict(base,sample.decisionSource.state,function(a)return available[a]end)=='laser')
  assert(F.predict(base,sample.decisionSource.state,available,state)=='idle')
  state.part_roots='unknown';assert(F.predict(base,sample.decisionSource.state,available,state)=='laser')
  state.part_roots='armored';assert(F.predict(base,sample.decisionSource.state,available,state)=='laser')
  state.part_roots='exposed'
  for _,target in ipairs({'bud','flower','none'})do state.target=target;assert(F.predict(base,sample.decisionSource.state,available,state)=='laser')end
  state.target='boss';available.idle=false;assert(F.predict(base,sample.decisionSource.state,available,state)==nil);available.idle=true
  state.target='flower';state.resources.ammo.emp=0;assert(F.predict(base,sample.decisionSource.state,available,state)=='idle')
  assert(F.valid({}, {versions={}}))
  assert(not F.valid({resourceFallback=1},{versions={},resources={mode='virtual'}}))
  assert(not F.valid({resourceFallback=99},{versions={resourceFallback=99},resources={mode='virtual'}}))
  assert(not F.valid({resourceFallback=1},{versions={resourceFallback=1},resources={mode='mission'}}))
  r.contracts=true;r.oldRecordsRebuilt=#oldRecords
  local sourceCount=#D.DB:query('SELECT id FROM lsd.Game0ResourcePractices')
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local loadout={{actor='mentor',item='kinetic',quantity=60},{actor='ninilite',item='emp',quantity=30},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=60}}
  for _,profile in ipairs({'exposed','near'})do
   for _,mode in ipairs({'basic','evaluate'})do
    local result=require('Training.FlowerQSession').runAsync({mode=mode,models=candidate.bundle.baseModels,initial=mode=='evaluate'and candidate.models or nil,virtualSupplies=loadout,profile=profile})
    assert(result.setup.resourceFallback==2 and result.episode.versions.resourceFallback==2)
    local tampered=copy(result);tampered.setup.resourceFallback=99;local accepted=Trials.saveAsync(tampered,candidate.id);assert(not accepted)
    local yes,why,diagnostic=Trials.saveAsync(result,candidate.id);assert(yes,tostring(why)..':'..tostring(diagnostic))
    assert(equal(Store.loadLatestAsync().models,candidate.models))
    assert(#D.DB:query('SELECT id FROM lsd.Game0ResourcePractices')==sourceCount)
    assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
    r.trials[#r.trials+1]={profile=profile,mode=mode,status=result.status,cost=result.episode.resources.spent,seconds=result.report.seconds,outcome=result.episode.outcome,decisions=result.decisions};save()
   end
  end
  local records=assert(Trials.loadAsync(candidate.id));assert(#records==14)
  local groups=require('Training.ResourceQReview').build(records);assert(#groups==7)
  r.candidate=candidate.id;r.depth=candidate.depth;r.reviews={};for _,g in ipairs(groups)do assert(g.basic.count==1 and g.evaluate.count==1);r.reviews[g.key.profile]=require('Training.ResourceQReview').text(g)end
  local assessment=require('Training.ResourceAssessment').build(groups);assert(#assessment.missing==3 and #assessment.sparse==2 and assessment.outdated==5 and not assessment.adoptionEligible);r.assessment=assessment;r.diagnostics={};for _,entry in ipairs(records)do if entry.record.setup.resourceFallback==2 and entry.record.mode=='evaluate'then r.diagnostics[entry.record.profile]=entry.facts.telemetry.actors end end;r.sourceUnchanged=true;r.candidateUnchanged=true;r.walletUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
