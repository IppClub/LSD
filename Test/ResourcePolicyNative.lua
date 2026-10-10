-- Engine-driven demonstration input; not evidence of a human teaching session.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-policy-result.json';local r={status='RUNNING'}
D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-policy-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local saved=assert(require('Training.FlowerQStore').loadAsync());local episode
  local support=require('Ground.LifeSupport').new(90,'defence');support.hp={100,100,100}
  local b=require('Factory.Battle').createAsync({finishAsync=function(_,attempt,status,report,e) e.context='flower-resource-demo';episode=e;return true end},{mission='c0-m05',id='resource-demo-test',models=saved.source.baseModels},support,{training=true,virtualSupplies={{actor='ninilite',item='emp',quantity=2},{actor='wuyun',item='blade',quantity=8}}})
  assert(b:start());for _,a in ipairs(b.learners)do a.mode='demo'end
  local count=0;local deadline=D.App.totalTime+30
  while count<12 do
   assert(b.phase=='playing' and D.App.totalTime<deadline,'Demonstrations timed out')
   if b.arena:request(({'fmove','idle','bmove','idle'})[count%4+1],'demo')then count=count+1;D.sleep(.35)else D.sleep(.05)end
  end
  D.sleep(.4);b:finish('aborted','Resource classifier contract QA')
  while b.phase=='saving'do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(episode,b.saveError)
  local P=require('Training.ResourcePolicy');local old=require('Training.FlowerPolicy')
  local data=assert(P.collect({episode},'ninilite'));assert(data.featureSchemaVersion==8)
  for _,row in ipairs(data.samples)do assert(row.state.empAmmo=='low' and row.state.kineticAmmo=='unequipped' and row.state.missionBudget=='ready')end
  local model,why=P.buildAsync({episode},'ninilite');assert(model,why);assert(not old.validate(model))
  assert(old.inspect({episode},'ninilite').coverage.total==0)
  local auto=D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/resource-exploration-exposed/source.json'),32)
  assert(P.inspect({auto.episode},'ninilite').coverage.total==0,'Q exploration became demonstrations')
  -- Synthetic classifier isolates the ammo decision boundary, not quality of play.
  local nodes={};assert(D.ML.BuildDecisionTreeAsync('empAmmo,action\nC,C\nempty,bmove\nready,fmove\nempty,bmove\nready,fmove\nempty,bmove\nready,fmove',5,function(depth,name,op,value)nodes[#nodes+1]={depth=depth,name=name,op=op,value=value}end))
  model.rules=assert(P.compile(nodes,'ninilite',8))
  local state=D.json.decode(D.json.encode(episode.steps[1].observation),32)
  state.resources.ammo.emp=0;assert(P.predict(model,state)=='bmove')
  state.resources.ammo.emp=4;assert(P.predict(model,state)=='fmove')
  assert(not P.predict(model,state,function()return false end))
  state.resources=nil;assert(not P.predict(model,state),'Missing resources accepted')
  model.rules[1].conditions[1].name='futureIncome';assert(not P.validate(model),'Outcome feature accepted')
  r.samples=#data.samples;r.checks={'real decision-time resource observations','native C4.5 build','legacy adoption rejection','automatic trace exclusion','ammo boundary prediction','availability gate','missing resource and future feature rejection'}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
