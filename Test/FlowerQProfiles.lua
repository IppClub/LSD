local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-profiles-result.json';local r={status='RUNNING',matches={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-q-trial-panel-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-trial%-panel%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-profiles-'..os.time()..'.db';assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local Trials=require('Training.FlowerQTrials');local saved=assert(Store.loadAsync());local Session=require('Training.FlowerQSession')
  for _,profile in ipairs({'far','reproduction','field'})do for _,mode in ipairs({'basic','evaluate'})do
   r.current={profile=profile,mode=mode};save()
   local run=Session.runAsync({mode=mode,profile=profile,models=saved.source.baseModels,initial=mode=='evaluate' and saved.models or nil,onProgress=function(b)r.current.seconds=D.App.runningTime-b.started;save()end})
   assert(run.status=='won' or run.status=='failed');local yes,why,detail=Trials.saveAsync(run,saved.id);assert(yes,tostring(why)..':'..tostring(detail))
   r.matches[#r.matches+1]={profile=profile,mode=mode,status=run.status,seconds=run.report.seconds,decisions=run.decisions,evaluation=run.report.evaluation};save();D.sleep(.2)
  end end
  local rows=assert(Trials.loadAsync(saved.id));r.review=require('Training.FlowerQReview').build(saved.id,rows);assert(r.review.completed==4 and #rows==9)
  assert(require('Training.FlowerIdentity').equal(Store.loadAsync().models,saved.models));r.candidateUnchanged=true
  local panel=require('Training.FlowerQPanel').openAsync(function()end,saved.source.baseModels);panel.reviewButton:emit('Tapped');assert(panel.review.completed==4)
  panel.profile='field';panel:render();D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-q-review-four-profiles.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
