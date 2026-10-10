-- Regression for another actor evicting a learner's older demonstrations.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-actor-sources-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-yingzhao-schema5-actor-sources-natural-20261006/result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-mixed%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-actor-sources-'..os.time()..'.db';r.database=db;assert(not D.DB:existDB('lsd'))
  assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  local S=require('Training.YingzhaoStore');local history=assert(S.listAsync());assert(#history==20)
  local recent={};for _,id in ipairs(history)do recent[id]=true end
  local count=D.DB:query('SELECT COUNT(*) FROM lsd.Game0YingzhaoObservations')[1][1];assert(count==21)
  local total,outside=0,0;r.actors={}
  for _,actor in ipairs({'ninilite','wuyun'})do
   local ids=assert(S.listAsync(actor));local expected=actor=='ninilite'and prior.model or prior.companion
   assert(#ids==#expected.sourceEpisodes and #ids<=20)
   local episodes={};for _,episode in ipairs(expected.sourceEpisodes)do episodes[episode]=true end
   for _,id in ipairs(ids)do
    local e=assert(S.loadAsync(id));assert(e.demonstrator==actor and episodes[e.episode]);episodes[e.episode]=nil
    if not recent[id]then outside=outside+1 end
   end
   assert(next(episodes)==nil);total=total+#ids
   local loaded=assert(require('Training.YingzhaoPolicyStore').loadLatestAsync(actor))
   assert(require('Training.FlowerIdentity').equal(loaded.model,expected))
   r.actors[actor]={sources=#ids,samples=loaded.model.sampleCount}
  end
  assert(total==21 and outside==1)
  local bad,why=S.listAsync('fox');assert(not bad and why=='INVALID_CHARACTER')
  r.globalHistoryCount=#history;r.recoveredOutsideGlobalPage=outside;r.noAdoption=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
