local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-exploration-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-exploration-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync());local E=require('Economy.Store');assert(E.open());local before=E.wallet()
  local result=require('Training.FlowerQSession').runAsync({mode='explore',seed=1701,epsilon=1,models=saved.source.baseModels,profile='exposed',virtualSupplies={{actor='mentor',item='kinetic',quantity=12},{actor='ninilite',item='emp',quantity=6},{actor='wuyun',item='emp',quantity=3},{actor='wuyun',item='blade',quantity=12}},onStart=function(b)
   for part,state in pairs(b.partCombat.target.damage.parts)do assert(state.ap==0 and b.partCombat.known[part].ap==0)end
  end})
  assert(result.setup.trainingGoal=='resource-clear-v1' and result.episode.versions.trainingGoal=='resource-clear-v1')
  assert(result.status=='won' or result.status=='failed');assert(result.models,result.learningError)
  local counts,empty,exposed=0,0,0
  for id,actor in pairs(result.trace.actors)do
   counts=counts+result.decisions[id].explored
   for _,row in ipairs(actor.steps)do
    if row.state.part_core=='exposed'then exposed=exposed+1 end
    if row.state.resourceFeatures.empAmmo=='empty'then empty=empty+1 end
   end
  end
  assert(counts>0 and exposed>0 and empty>0,'Required training states missing')
  local P=require('Training.ResourcePracticeStore');local yes,why=P.saveRunAsync(result);assert(yes,why)
  local candidate,why=require('Training.ResourceQStore').trainAsync();assert(candidate,why)
  assert(require('Training.ResourceQ').equivalentModels(result.models,candidate.models))
  assert(E.wallet().available==before.available and E.wallet().revision==before.revision)
  r.statusOfBattle=result.status;r.seconds=result.report.seconds;r.cost=result.episode.resources.spent;r.explored=counts;r.exposedStates=exposed;r.emptyStates=empty;r.decisions=result.decisions;r.candidate=candidate.id;r.trainingGoal=candidate.bundle.trainingGoal;r.models=candidate.models
  r.source=root..'/Test/resource-exploration-source.json';assert(D.Content:save(r.source,D.json.encode(P.loadLatestAsync().source,false,true)))
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
