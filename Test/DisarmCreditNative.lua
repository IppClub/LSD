local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-credit-result.json';local r={status='RUNNING',cases={}}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local Credit=require('Training.DisarmCredit')
  local function copy(x)return D.json.decode(D.json.encode(x,false,true),32)end
  local traces={}
  for _,file in ipairs({'disarm-empty-resource-result.json','disarm-performance-result.json'})do
   local source=D.json.decode(D.Content:load(root..'/Test/'..file),32);assert(source.status=='PASS');local t=source.trace or source.report.disarmTrace
   local c,why=Credit.rebuild(t);assert(c,why);assert(not c.trainable and c.cost+c.unassignedCost+c.stolenCost+c.deployment==t.virtualResult.cost)
   assert(c.damageTaken+c.unassignedDamageTaken==t.vitals.damage);traces[#traces+1]=t;r.cases[#r.cases+1]={source=file,credit=c}
  end
  assert(r.cases[1].credit.stolenCost==2 and r.cases[1].credit.cost==0 and r.cases[1].credit.unassignedDamageTaken==25)
  assert(r.cases[2].credit.cost>0 and r.cases[2].credit.damageDealt>0 and r.cases[2].credit.unassignedCost>0)
  local original=traces[2]
  -- Controlled time-boundary fixtures based on the recorded action schedule.
  local boundary=copy(original);local action=boundary.executions[1]
  boundary.vitals={initial={mentor=100,ninilite=100,wuyun=100},final={mentor=100,ninilite=100,wuyun=100},events={{actor=action.actor,before=100,after=90,damage=10,healing=0,at=action.startedAt,kind='enemy-melee'}}};boundary.vitals.final[action.actor]=90
  local atStart=assert(Credit.rebuild(boundary));assert(atStart.steps[1].damageTaken==10 and atStart.unassignedDamageTaken==0)
  boundary.vitals.events[1].at=action.startedAt-.01
  local beforeStart=assert(Credit.rebuild(boundary));assert(beforeStart.damageTaken==0 and beforeStart.unassignedDamageTaken==10)
  r.boundaryFixtures=true
  local function rejects(name,fn)local t=copy(original);fn(t);local c,why=Credit.rebuild(t);assert(not c,name);r.cases[#r.cases+1]={mutation=name,rejected=why}end
  rejects('duplicate-execution',function(t)t.executions[2].id=t.executions[1].id end)
  rejects('negative-duration',function(t)t.executions[1].duration=-1 end)
  rejects('unclosed-action',function(t)t.executions[1].outcome='running'end)
  rejects('orphan-impact',function(t)t.impacts[1].step=99999 end)
  rejects('negative-impact',function(t)t.impacts[1].damage=-1 end)
  rejects('late-impact-outside-session',function(t)t.impacts[1].at=t.resourcesFinalizedAt+1 end)
  rejects('missing-consumption-step',function(t)for _,c in ipairs(t.consumption)do if c.step then c.step=nil;break end end end)
  rejects('incomplete-health',function(t)t.vitals.final.mentor=0 end)
  rejects('old-source',function(t)t.executionVersion=nil end)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
