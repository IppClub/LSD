local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-four-source-evaluation-result.json';local r={status='RUNNING',trials={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-multi-practice-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-multi%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-q-four-source-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.ResourceQStore');local Trials=require('Training.ResourceQTrials');local equal=require('Training.FlowerIdentity').equal
  local candidate=assert(Store.loadLatestAsync());assert(candidate.depth==4 and candidate.bundle.trainingGoal=='resource-clear-v1')
  local sourceCount=#D.DB:query('SELECT id FROM lsd.Game0ResourcePractices')
  local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local loadout={{actor='mentor',item='kinetic',quantity=60},{actor='ninilite',item='emp',quantity=30},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=60}}
  for _,profile in ipairs({'near','far','reproduction'})do
   for _,mode in ipairs({'basic','evaluate'})do
    local result=require('Training.FlowerQSession').runAsync({mode=mode,models=candidate.bundle.baseModels,initial=mode=='evaluate'and candidate.models or nil,virtualSupplies=loadout,profile=profile})
    local yes,why,diagnostic=Trials.saveAsync(result,candidate.id);assert(yes,tostring(why)..':'..tostring(diagnostic))
    assert(equal(Store.loadLatestAsync().models,candidate.models))
    assert(#D.DB:query('SELECT id FROM lsd.Game0ResourcePractices')==sourceCount)
    assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
    r.trials[#r.trials+1]={profile=profile,mode=mode,status=result.status,cost=result.episode.resources.spent,seconds=result.report.seconds,outcome=result.episode.outcome,decisions=result.decisions};save()
   end
  end
  local records=assert(Trials.loadAsync(candidate.id));assert(#records==6)
  local groups=require('Training.ResourceQReview').build(records);assert(#groups==3)
  r.candidate=candidate.id;r.depth=candidate.depth;r.reviews={};for _,g in ipairs(groups)do assert(g.basic.count==1 and g.evaluate.count==1);r.reviews[g.key.profile]=require('Training.ResourceQReview').text(g)end
  r.sourceUnchanged=true;r.candidateUnchanged=true;r.walletUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
