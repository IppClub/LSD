local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-scenario-trials-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-restraint-demo-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-restraint%-demo%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-scenario-trials-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local CS=require('Training.ResourcePolicyStore');local frozen=assert(CS.loadAsync('ninilite'))
  local DS=require('Training.ResourceDemoStore');local before=#assert(DS.history('ninilite'))
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  r.pairs={}
  for _,config in ipairs({{name='near',ammo={16,30,30}},{name='exposed',ammo={16,30,30}}})do
  local loadout={{actor='ninilite',item='emp',quantity=config.ammo[1]},{actor='mentor',item='kinetic',quantity=config.ammo[2]},{actor='wuyun',item='blade',quantity=config.ammo[3]}}
  local episodeIds={}
  for _,mode in ipairs({'basic',true})do
   local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',{rounds={}},models,mode,config.name,nil,loadout)
   local deadline=D.App.totalTime+140
   while c.battle.phase=='playing'or c.battle.phase=='saving'do assert(D.App.totalTime<deadline,'Trial stalled');D.sleep(.2)end
   assert(c.result and c.result.trialSaved,c.battle.saveError)
   assert(c.result.status=='won'or c.result.status=='failed')
   assert(require('Training.FlowerIdentity').equal(CS.loadAsync('ninilite'),frozen))
   assert(#assert(DS.history('ninilite'))==before)
   assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
   episodeIds[c.mode]=c.result.episode.episode
   r.trials[#r.trials+1]={configuration=config.name,reserved=c.result.episode.resources.quote.total,controller=c.mode,status=c.result.status,cost=c.result.episode.resources.spent,seconds=c.result.report.seconds,reason=c.result.report.reason};save()
  end
  local history=assert(require('Training.ResourceC45Trials').history('ninilite'))
  local basic,candidate
  for _,record in ipairs(history)do
   if record.episode.episode==episodeIds.basic then basic=record elseif record.episode.episode==episodeIds.candidate then candidate=record end
  end
  local pair=assert(require('Training.ResourceC45Comparison').build(basic,candidate));pair.configuration=config.name
  r.pairs[#r.pairs+1]=pair;save()
  end
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,models,nil,nil,nil,{{actor='ninilite',item='emp',quantity=16},{actor='mentor',item='kinetic',quantity=30},{actor='wuyun',item='blade',quantity=30}})
  D.sleep(.2)
  for _,name in ipairs({'near','far','reproduction','field','exposed','standard'})do
   assert(c.scenarioButton.visible);local old=c;c.scenarioButton:emit('Tapped');local endAt=D.App.totalTime+20
   repeat D.sleep(.05);local ui=D.Director.ui3D:getChildByTag('flower-practice-controls');c=ui and ui.practice or old;assert(D.App.totalTime<endAt)until c~=old
   D.sleep(.1);assert((c.scenario or 'standard')==name and c.battle.supplies.isVirtual and c.battle.supplies.ledger.quote.total==160)
   if name~='standard'then local yes,why=c:start();assert(not yes and why=='EVALUATION_ONLY'and not c.startButton.visible)end
  end
  r.scenarioCycle=true
  assert(#r.trials==4 and #r.pairs==2)

 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
