local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-restraint-trials-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-restraint-demo-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-restraint%-demo%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-restraint-trials-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local CS=require('Training.ResourcePolicyStore');local frozen=assert(CS.loadAsync('ninilite'))
  local DS=require('Training.ResourceDemoStore');local before=#assert(DS.history('ninilite'))
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local loadout={{actor='ninilite',item='emp',quantity=16},{actor='mentor',item='kinetic',quantity=30},{actor='wuyun',item='blade',quantity=30}}
  for _,mode in ipairs({'basic',true})do
   local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',{rounds={}},models,mode,nil,nil,loadout)
   local deadline=D.App.totalTime+140
   while c.battle.phase=='playing'or c.battle.phase=='saving'do assert(D.App.totalTime<deadline,'Trial stalled');D.sleep(.2)end
   assert(c.result and c.result.trialSaved,c.battle.saveError)
   assert(c.result.status=='won'or c.result.status=='failed')
   assert(require('Training.FlowerIdentity').equal(CS.loadAsync('ninilite'),frozen))
   assert(#assert(DS.history('ninilite'))==before)
   assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
   r.trials[#r.trials+1]={controller=c.mode,status=c.result.status,cost=c.result.episode.resources.spent,seconds=c.result.report.seconds};save()
  end
  local history=assert(require('Training.ResourceC45Trials').history('ninilite'));assert(#history==2)
  local basic,candidate;for _,record in ipairs(history)do if record.controller=='basic'then basic=record else candidate=record end end
  r.comparison=assert(require('Training.ResourceC45Comparison').build(basic,candidate))
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
