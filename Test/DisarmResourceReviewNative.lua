local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-resource-review-result.json';local r={status='RUNNING',cases={}}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local Review=require('Training.DisarmResourceReview')
  local function copy(x)return D.json.decode(D.json.encode(x,false,true),32)end
  local traces={}
  for _,file in ipairs({'disarm-empty-resource-result.json','disarm-performance-result.json'})do
   local source=D.json.decode(D.Content:load(root..'/Test/'..file),32);assert(source.status=='PASS');local trace=source.trace or source.report.disarmTrace
   local reviewed,why=Review.rebuild(trace);assert(reviewed,why);assert(reviewed.total==reviewed.ownCost+reviewed.stolenCost+reviewed.deployment and not reviewed.trainable)
   traces[#traces+1]=trace;r.cases[#r.cases+1]={source=file,review=reviewed}
  end
  local original=traces[1]
  local function rejects(name,mutate,reason)
   local trace=copy(original);mutate(trace);local value,why=Review.rebuild(trace);assert(not value and why==reason,name..': '..tostring(why));r.cases[#r.cases+1]={mutation=name,rejected=why}
  end
  rejects('duplicate',function(t)t.consumption[#t.consumption+1]=copy(t.consumption[1])end,'DUPLICATE_OR_INVALID_EVENT')
  rejects('omitted',function(t)table.remove(t.consumption)end,'INCOMPLETE_RESOURCE_HISTORY')
  rejects('owner',function(t)t.consumption[1].owner='wuyun'end,'RESOURCE_EVENT_MISMATCH')
  rejects('before',function(t)t.consumption[1].before.spent=100 end,'RESOURCE_BEFORE_MISMATCH')
  rejects('after',function(t)t.consumption[1].after.ammo.kinetic=5 end,'RESOURCE_AFTER_MISMATCH')
  rejects('settlement',function(t)t.virtualResult.cost=0 end,'SETTLEMENT_MISMATCH')
  rejects('time',function(t)t.consumption[1].at=t.resourcesFinalizedAt+1 end,'RESOURCE_TIME_MISMATCH')
  rejects('truncated',function(t)t.truncated=true end,'INCOMPLETE_DISARM_TRACE')
  rejects('old',function(t)t.schemaVersion=1 end,'INCOMPLETE_DISARM_TRACE')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
