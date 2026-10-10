local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-trace-reload-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-trace-review-result.json'),32));assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-trace%-review%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-trace-reload-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);r.database=dest
  local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerTeamTrials ORDER BY serial DESC LIMIT 1');local record=assert(D.json.decode(rows[1][1],32));local episode=record.episode
  local events={};for _,step in ipairs(episode.steps)do for _,hit in ipairs(step.hits)do if hit.credit then events[#events+1]=hit end end end
  table.sort(events,function(a,b)return a.credit.sequence<b.credit.sequence end)
  local replay=require('Training.FlowerCredit').new();r.diffs={}
  local function diff(a,b,path)
   if type(a)=='table' and type(b)=='table'then for k,v in pairs(a)do diff(v,b[k],path..'.'..k)end
   elseif a~=b then r.diffs[#r.diffs+1]={path=path,recomputed=a,saved=b,delta=type(a)=='number' and type(b)=='number' and a-b or nil}end
  end
  for _,hit in ipairs(events)do diff(replay:hit(hit,episode.creditTargets[hit.target],hit.credit.at),hit.credit,tostring(hit.credit.sequence))end
  r.valid,r.validationError=require('Training.CombatStore').validate(episode);assert(r.valid,r.validationError)
  local trace=assert(D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/flower-trace-review-trace.json'),32))
  local Review=require('Training.FlowerTraceReview');local rebuilt,why=Review.rebuild(trace,episode,record.status);assert(rebuilt,why);r.rewardRebuilt=true
  local function copy(x)return D.json.decode(D.json.encode(x,false,true),32)end
  local bad=copy(trace);bad.actors.ninilite.steps[1].reward=bad.actors.ninilite.steps[1].reward+.01;assert(not Review.rebuild(bad,episode,record.status))
  bad=copy(trace);bad.actors.ninilite.steps[2].state.health='fallen';assert(not Review.rebuild(bad,episode,record.status))
  bad=copy(trace);bad.resources[1].used=bad.resources[1].used+.1;assert(not Review.rebuild(bad,episode,record.status))
  bad=copy(trace);bad.actors.ninilite.steps[1].after.events=999999;assert(not Review.rebuild(bad,episode,record.status))
  local mutated=copy(episode);local h;for _,step in ipairs(mutated.steps)do for _,hit in ipairs(step.hits)do if hit.credit then h=hit;break end end;if h then break end end
  h.credit.health=h.credit.health+.01;assert(not require('Training.CombatStore').validate(mutated))
  mutated=copy(episode);for _,step in ipairs(mutated.steps)do for _,hit in ipairs(step.hits)do if hit.credit then hit.credit.sequence=hit.credit.sequence+1e-10;h=hit;break end end;if h and h.credit.sequence%1~=0 then break end end
  assert(not require('Training.CombatStore').validate(mutated));r.tamperingRejected=true
  local Q=require('Training.FlowerQ');local models,why=Q.learn(trace,episode,record.status);assert(models,why);r.updates={}
  for _,id in ipairs({'ninilite','wuyun'})do
   local model=models[id];assert(model.updates==#trace.actors[id].steps);local restored=assert(Q.restore(copy(model),id));r.updates[id]=restored.updates
   local row=trace.actors[id].steps[1];local action=assert(restored:choose(row.state,function(a)for _,v in ipairs(row.actions)do if a==v then return true end end;return false end,false,0));assert(restored.legal[action])
   assert(not restored:choose(row.state,function()return true end,false,.3))
   assert(not Q.restore(model,id=='ninilite' and 'wuyun' or 'ninilite'))
  end
  local repeated=assert(Q.learn(copy(trace),copy(episode),record.status));assert(require('Training.FlowerIdentity').equal(models,repeated));r.deterministicLearning=true
  assert(not Q.learn(trace,episode,record.status,{ninilite=models.ninilite}));assert(not Q.learn(trace,episode,record.status,'invalid'))
  assert(not Q.learn(trace,episode,'aborted'));assert(not Q.learn(bad,episode,record.status))
  D.Content:save(root..'/Docs/evidence/2026-10-05/flower-q-first-models.json',D.json.encode(models,false,true))

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
