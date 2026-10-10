local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-decision-trace-edges-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-decision-trace-edges-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local sources=assert(P.teamSources());local equal=require('Training.FlowerIdentity').equal
  for _,status in ipairs({'won','failed','aborted'})do
   local c=P.openAsync(nil,'ninilite',nil,nil,nil,'field',sources);D.sleep(.1)
   -- Synthetic zero-decision terminal, never stored as a combat achievement.
   c.battle.service={finishAsync=function()return true end}
   local trace=require('Training.FlowerDecisionTrace').attach(c.battle)
   c.battle:finish(status,'QA empty boundary')
   assert(trace.closed and not trace.trainable)
   assert(#trace.actors.ninilite.steps==0 and #trace.actors.wuyun.steps==0)
   D.sleep(.1)
  end
  r.emptyTerminalsExcluded=true

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
