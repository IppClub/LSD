local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-q-multi-practice-result.json';local r={status='RUNNING',practice={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-q-generalization-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-q%-generalization%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-q-multi-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local S=require('Training.ResourceQStore');local P=require('Training.ResourcePracticeStore');local C=require('Training.ResourceSourceCoverage')
  local candidate=assert(S.loadLatestAsync());local old=candidate;assert(candidate.depth==2)
  local wallet=require('Economy.Store').wallet();local sourceCount=#D.DB:query('SELECT id FROM lsd.Game0ResourcePractices')
  local loadout={{actor='mentor',item='kinetic',quantity=60},{actor='ninilite',item='emp',quantity=30},{actor='wuyun',item='emp',quantity=6},{actor='wuyun',item='blade',quantity=60}}
  for i,profile in ipairs({'near','far'})do
   local run=require('Training.FlowerQSession').runAsync({mode='explore',seed=1800+i,epsilon=.65,models=candidate.bundle.baseModels,initial=candidate.models,profile=profile,virtualSupplies=loadout})
   assert(run.models,run.learningError);assert(P.saveRunAsync(run));candidate=assert(S.trainAsync());assert(candidate.depth==2+i)
   assert(require('Training.ResourceQ').equivalentModels(run.models,candidate.models))
   r.practice[#r.practice+1]={profile=profile,status=run.status,cost=run.episode.resources.spent,seconds=run.report.seconds,seed=1800+i};save()
  end
  assert(#D.DB:query('SELECT id FROM lsd.Game0ResourcePractices')==sourceCount+2)
  assert(require('Training.FlowerIdentity').equal(S.loadVersionAsync(old.id).models,old.models));assert(#require('Training.ResourceQTrials').loadAsync(old.id)==6)
  assert(#require('Training.ResourceQTrials').loadAsync(candidate.id)==0)
  local counts=C.build(candidate.records);assert(counts.exposed==2 and counts.near==1 and counts.far==1)
  assert(require('Economy.Store').wallet().available==wallet.available and require('Economy.Store').wallet().revision==wallet.revision)
  local panel=require('Training.FlowerQPanel').openAsync(function()end,candidate.bundle.baseModels)
  assert(panel.label.text:find('近距完整护甲×1',1,true)and panel.label.text:find('远距完整护甲×1',1,true))
  r.coverage=counts;r.candidate=candidate.id;r.depth=candidate.depth;r.oldPreserved=true;r.walletUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
