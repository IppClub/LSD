local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-spatial-policy-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-reaction-migration-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-reaction%-migration%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-spatial-policy-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Policy=require('Training.FlowerPolicy');local Evidence=require('Training.FlowerEvidence')
  local legacy=assert(require('Training.FlowerPolicyStore').evidence('ninilite'))
  assert(legacy.policy.featureSchemaVersion==6 and Evidence.verifyAsync(legacy));r.legacyRebuilt=true
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite');D.sleep(.3);c.startButton:emit('Tapped');assert(c.battle.phase=='playing')
  local count=0;local deadline=D.App.totalTime+30
  while count<12 do
   assert(c.battle.phase=='playing' and D.App.totalTime<deadline,'Demonstration did not finish')
   local action=({'fmove','idle','bmove','idle'})[count%4+1]
   if c:request(action)then count=count+1;D.sleep(.35)else D.sleep(.05)end
  end
  c:stopMove();D.sleep(.4);c:finish();deadline=D.App.totalTime+15
  while c.battle.phase=='saving'do assert(D.App.totalTime<deadline);D.sleep(.05)end
  assert(c.result and c.result.saved,'Demonstration not saved')
  local yes,why=c:learnAsync('latest');assert(yes,why);assert(c.candidate.featureSchemaVersion==7)
  local evidence=assert(require('Training.FlowerPolicyStore').evidence('ninilite'));assert(evidence.builder=='flower-c45-v2'and Evidence.verifyAsync(evidence))
  local samples=assert(Policy.collect(evidence.episodes,'ninilite',7));assert(#samples.samples>=6)
  for _,sample in ipairs(samples.samples)do for _,name in ipairs(require('Training.FlowerTacticsFeatures').names)do assert(sample.state[name]~=nil,'New field omitted')end end
  r.samples=#samples.samples;r.schema=7;r.savedAndRebuilt=true
  -- Prediction contract: same observed scene, only measured ally spacing differs.
  local state=evidence.episodes[1].steps[1].observation
  local model=D.json.decode(D.json.encode(c.candidate),32)
  local nodes={}
  local accuracy=assert(D.ML.BuildDecisionTreeAsync('allySpacing,action\nC,C\ncrowded,bmove\nisolated,fmove\ncrowded,bmove\nisolated,fmove\ncrowded,bmove\nisolated,fmove',5,function(depth,name,op,value)nodes[#nodes+1]={depth=depth,name=name,op=op,value=value}end))
  model.rules=assert(Policy.compile(nodes,'ninilite',7));r.syntheticSpacingAccuracy=accuracy
  r.learnedConditions={};for _,rule in ipairs(c.candidate.rules)do for _,condition in ipairs(rule.conditions)do r.learnedConditions[condition.name]=true end end
  local crowded=D.json.decode(D.json.encode(state),32);crowded.spatial.ally={actor='mentor',dx=80,dy=0,distance=80}
  local isolated=D.json.decode(D.json.encode(state),32);isolated.spatial.ally={actor='mentor',dx=500,dy=0,distance=500}
  assert(Policy.predict(model,crowded)=='bmove'and Policy.predict(model,isolated)=='fmove');r.spacingAffectsPrediction=true
  model.featureSchemaVersion=6;assert(not Policy.validate(model),'Legacy model accepted new feature name')
  local missing=D.json.decode(D.json.encode(state),32);missing.spatial=nil;assert(not Policy.predict(c.candidate,missing));r.missingEvidenceRejected=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
