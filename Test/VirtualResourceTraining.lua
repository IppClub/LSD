local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/virtual-resource-training-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/virtual-resource-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync())
  local Store=require('Economy.Store');assert(Store.open());local before=Store.wallet()
  local function snapshot()return D.json.encode(D.DB:query('SELECT id,status,payload FROM lsd.Game0SupplyAttempts ORDER BY id'),false,true)end
  local attempts=snapshot()
  for _,name in ipairs({'beginAsync','consumeNow','consumeAsync','settleAsync'})do Store[name]=function()error('Virtual training touched durable economy: '..name)end end
  local loadout={{actor='mentor',item='kinetic',quantity=2},{actor='ninilite',item='emp',quantity=2},{actor='wuyun',item='emp',quantity=2},{actor='wuyun',item='blade',quantity=2}}
  local Session=require('Economy.CombatSession');local probe=assert(Session.virtual('virtual:probe',loadout))
  local evidence=probe:evidence();assert(probe:emit('mentor','kinetic',1,'mentor'));assert(evidence.spent==9 and probe.ledger.spent==11)
  local second=assert(Session.virtual('virtual:second',loadout));assert(second.ledger.stock['mentor:kinetic'].remaining==2)
  local calls=0
  local result=require('Training.FlowerQSession').runAsync({mode='basic',profile='field',models=saved.source.baseModels,virtualSupplies=loadout,
   onStart=function(b)assert(b.supplies.isVirtual==true and b.supplies:statusText():find('不扣物资',1,true));calls=calls+1 end})
  assert(result.report.virtualEconomy and result.report.virtualEconomy.cost==result.episode.resources.spent and result.report.economy==nil)
  assert(calls==1 and result.status=='failed','Low-budget run should end through real battle failure')
  assert(result.episode.versions.resourceSimulation==1 and result.episode.resources.mode=='virtual')
  assert(require('Training.CombatStore').validate(result.episode))
  local rebuilt,why=require('Training.ResourceTraceReview').rebuild(result.trace,result.episode,result.status);assert(rebuilt,why)
  local empty,low=0,0
  for _,actor in pairs(result.trace.actors)do for _,step in ipairs(actor.steps)do
   for _,state in ipairs({step.state,step.nextState})do for _,name in ipairs({'empAmmo','bladeAmmo'})do
    if state.resourceFeatures[name]=='empty'then empty=empty+1 elseif state.resourceFeatures[name]=='low'then low=low+1 end
   end end
  end end
  assert(empty>0 and low>0,'Boundary samples missing')
  local models,why=require('Training.ResourceQ').learn(result.trace,result.episode,result.status);assert(models,why)
  for actor,model in pairs(models)do assert(require('Training.ResourceQ').restore(model,actor))end
  assert(Store.wallet().available==before.available and Store.wallet().revision==before.revision and snapshot()==attempts)
  local accepted,why=require('Mission.Service').finishAsync({},nil,nil,nil,result.episode);assert(not accepted and why=='VIRTUAL_RESOURCES_NOT_MISSION')
  assert(not pcall(require('Factory.Battle').createAsync,{}, {mission='c0-m05',models=saved.source.baseModels},nil,{virtualSupplies=loadout}))
  r.statusOfBattle=result.status;r.cost=result.episode.resources.spent;r.lowObservations=low;r.emptyObservations=empty;r.seconds=result.report.seconds;r.walletUnchanged=true;r.models=models
  r.source=root..'/Test/virtual-resource-source.json';assert(D.Content:save(r.source,D.json.encode({trace=result.trace,episode=result.episode},false,true)))
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
