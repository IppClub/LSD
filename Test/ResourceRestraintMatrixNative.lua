local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-restraint-matrix-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-restraint-demo-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-restraint%-demo%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-restraint-matrix-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local CS=require('Training.ResourcePolicyStore');local frozen=assert(CS.loadAsync('ninilite'))
  local DS=require('Training.ResourceDemoStore');local before=#assert(DS.history('ninilite'))
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  r.pairs={}
  for _,config in ipairs({{name='repeat-a',ammo={16,30,30}},{name='repeat-b',ammo={16,30,30}},{name='reduced',ammo={8,20,20}},{name='scarce',ammo={2,12,12}}})do
  local loadout={{actor='ninilite',item='emp',quantity=config.ammo[1]},{actor='mentor',item='kinetic',quantity=config.ammo[2]},{actor='wuyun',item='blade',quantity=config.ammo[3]}}
  local episodeIds={}
  for _,mode in ipairs({'basic',true})do
   local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',{rounds={}},models,mode,nil,nil,loadout)
   local deadline=D.App.totalTime+140
   while c.battle.phase=='playing'or c.battle.phase=='saving'do assert(D.App.totalTime<deadline,'Trial stalled');D.sleep(.2)end
   assert(c.result and c.result.trialSaved,c.battle.saveError)
   assert(c.result.status=='won'or c.result.status=='failed')
   assert(require('Training.FlowerIdentity').equal(CS.loadAsync('ninilite'),frozen))
   assert(#assert(DS.history('ninilite'))==before)
   assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
   episodeIds[c.mode]=c.result.episode.episode
   r.trials[#r.trials+1]={configuration=config.name,reserved=c.result.episode.resources.quote.total,controller=c.mode,status=c.result.status,cost=c.result.episode.resources.spent,seconds=c.result.report.seconds};save()
  end
  local history=assert(require('Training.ResourceC45Trials').history('ninilite'))
  local basic,candidate
  for _,record in ipairs(history)do
   if record.episode.episode==episodeIds.basic then basic=record elseif record.episode.episode==episodeIds.candidate then candidate=record end
  end
  local pair=assert(require('Training.ResourceC45Comparison').build(basic,candidate));pair.configuration=config.name
  r.pairs[#r.pairs+1]=pair;save()
  end
  assert(#r.trials==8 and #r.pairs==4)

 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
