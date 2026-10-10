local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-continuous-decision-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/resource-exploration-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/resource%-exploration%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-continuous-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local source=D.json.decode(D.Content:load(root..'/Test/resource-exploration-source.json'),32)
  local cancelled=false
  local result=require('Training.FlowerQSession').runAsync({mode='explore',seed=1703,epsilon=1,models=source.baseModels,profile='far',virtualSupplies=source.virtualSupplies,cancelled=function()return cancelled end,
   onStart=function(b)
    local deadline=D.App.totalTime+3
    while not(b.arena.student.onSurface and b.wuyun.student.onSurface)do assert(D.App.totalTime<deadline);D.sleep(.02)end
    for _,action in ipairs({'idle','fmove'})do
     for _,a in ipairs(b.learners)do assert(a:request(action,'model'))end
     D.sleep(.28)
     for _,a in ipairs(b.learners)do
      assert(a.student:isDoing(a.physical[action]))
      local step=a.movementStep;local node=a.student.playable;local x=a.student.x
      local options=require('Training.FlowerDecisionTrace').options(b,a);local legal=false;for _,v in ipairs(options)do if v==action then legal=true end end;assert(legal,'Continuation absent from mask')
      local yes,why=a:request(action,'model');assert(yes and why=='CONTINUED',why)
      assert(a.movementStep~=step and a.student.playable==node and a.student:isDoing(a.physical[action])and a.student.x==x)
     end
     D.sleep(.28)
    end
    -- Explicit test endpoint, not a natural battle outcome or training source.
    b:finish('failed','决策区间边界测试结束');cancelled=true
   end})
  assert(result.status=='failed'and result.setup.continuousMovement==1 and result.episode.versions.continuousMovement==1)
  local rebuilt,why=require('Training.ResourceTraceReview').rebuild(result.trace,result.episode,result.status);assert(rebuilt,why)
  for _,actor in ipairs({'ninilite','wuyun'})do
   local rows=result.trace.actors[actor].steps;assert(#rows==4)
   for i,row in ipairs(rows)do assert(row.duration>0 and row.action==(i<=2 and 'idle'or'fmove'))end
  end
  assert(result.episode.resources.spent==result.episode.resources.quote.deployment)
  r.checks={'idle and move remain selectable','continued action keeps active animation node and position','distinct positive-duration decision intervals','resource reward reconstruction','no ammo charged for continuing movement'}
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
