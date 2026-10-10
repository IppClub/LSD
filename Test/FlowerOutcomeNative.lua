local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-outcome-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local O=require('Factory.Outcome')
  for mask=0,15 do
   local o={version=1,enemiesRemaining=0,partyAlive=true,niniliteHit=mask&1~=0,wuyunHit=mask&2~=0,confusionCleared=mask&4~=0,injury=mask&8~=0}
   assert(O.valid(o));assert(O.satisfied(o,'resource-clear-v1'));assert(O.satisfied(o,nil)==(mask==15));assert(O.storyComplete(o)==(mask==15));assert((#O.missing(o)==0)==(mask==15))
  end
  assert(not O.valid({version=1,enemiesRemaining=0/0}));assert(O.text(nil):find('旧记录',1,true))
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-restraint-demo-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-restraint%-demo%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-outcome-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,models,true,'near',nil,{{actor='ninilite',item='emp',quantity=16},{actor='mentor',item='kinetic',quantity=30},{actor='wuyun',item='blade',quantity=30}})
  local untilAt=D.App.totalTime+140
  while c.battle.phase=='playing'or c.battle.phase=='saving'do assert(D.App.totalTime<untilAt);D.sleep(.2)end
  assert(c.result and c.result.trialSaved,c.battle.saveError);D.sleep(.2)
  assert(c.result.episode.versions.trainingGoal=='resource-clear-v1' and c.runSetup.trainingGoal=='resource-clear-v1');local facts=c.result.episode.outcome;assert(O.valid(facts));assert(c.label.text:find(O.text(facts),1,true))
  local S=require('Training.ResourceC45Trials');local rows=assert(S.history('ninilite'));assert(#rows==1)
  assert(require('Training.FlowerIdentity').equal(rows[1].episode.outcome,facts))
  local bad=D.json.decode(D.json.encode(rows[1],false,true),32);bad.episode.outcome.partyAlive='yes'
  local yes,why=S.validate(bad);assert(not yes and why=='INVALID_OUTCOME_FACTS')
  bad.episode.outcome.partyAlive=false;bad.status='won';yes,why=S.validate(bad);assert(not yes and why=='OUTCOME_STATUS_MISMATCH')
  local legacy=D.json.decode(D.json.encode(rows[1],false,true),32);legacy.episode.outcome=nil;legacy.episode.versions.outcome=nil;legacy.episode.versions.trainingGoal=nil;legacy.setup.trainingGoal=nil;assert(S.validate(legacy))
  assert(D.DB:exec('DETACH DATABASE lsd')>=0);assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  assert(require('Training.FlowerIdentity').equal(S.history('ninilite')[1].episode.outcome,facts))
  r.database=dest;r.outcome=facts;r.result=c.result.status;r.reason=c.result.report.reason;r.checks={'16 story combinations','live battle facts and UI','saved facts reload','invalid facts rejected','inconsistent win rejected','legacy remains readable'}
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/flower-outcome.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
