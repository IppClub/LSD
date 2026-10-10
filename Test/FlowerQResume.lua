local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-resume-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-q-store-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-store%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-resume-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local S=require('Training.FlowerQStore');local Q=require('Training.FlowerQ');local equal=require('Training.FlowerIdentity').equal
  local loaded,why=S.loadAsync();assert(loaded,why);assert(loaded.id==prior.second and loaded.depth==2);r.coldRead=true
  local first=loaded.chain[#loaded.chain];local learn=Q.learn;local changed=false
  Q.learn=function(...)
   local value,why=learn(...)
   if not changed then changed=true;D.thread(function()assert(D.DB:exec('UPDATE lsd.Game0FlowerQSources SET payload=? WHERE id=?',{first.payload..' ',first.id})>=0)end)end
   return value,why
  end
  local stale,why=S.loadAsync();Q.learn=learn;assert(not stale and why=='Q_DRAFT_CHANGED',why)
  assert(D.DB:exec('UPDATE lsd.Game0FlowerQSources SET payload=? WHERE id=?',{first.payload,first.id})>=0);r.readRaceRejected=true
  loaded=assert(S.loadAsync());r.parent=loaded.id;r.initialUpdates={ninilite=loaded.models.ninilite.updates,wuyun=loaded.models.wuyun.updates};save()
  local result=require('Training.FlowerQSession').runAsync({mode='explore',models=loaded.source.baseModels,initial=loaded.models,seed=90210,profile='near',onProgress=function(b)r.elapsed=D.App.runningTime-b.started;save()end})
  assert(result.models,result.learningError);assert(equal(result.initial,loaded.models));r.battleStatus=result.status
  local ok,why,id=S.saveRunAsync(result,loaded.id);assert(ok,why);local latest,why=S.loadAsync();assert(latest,why)
  assert(latest.id==id and latest.parent==loaded.id and latest.depth==3 and equal(latest.models,result.models));r.id=id;r.depth=latest.depth;r.updates={}
  for _,actor in ipairs({'ninilite','wuyun'})do assert(latest.models[actor].updates>r.initialUpdates[actor]);r.updates[actor]=latest.models[actor].updates end
  assert(#D.DB:query('SELECT * FROM lsd.Game0FlowerQSources')==3);r.resumedAndSaved=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
