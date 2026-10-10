-- Descriptive allocation, not a reward policy or human-demonstration approval.
local M={}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<1e12 end
local function array(t)
 if type(t)~='table'or #t>2000 then return false end
 local n=0;for k in pairs(t)do if type(k)~='number'or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end;return n==#t
end
function M.rebuild(t)
 if type(t)~='table'or t.executionVersion~=1 or t.impactVersion~=1 or t.vitalsVersion~=1 or not array(t.executions)or not array(t.impacts)or not finite(t.resourcesFinalizedAt)then return nil,'INCOMPLETE_EXECUTION_EVIDENCE'end
 local economy,why=require('Training.DisarmResourceReview').rebuild(t);if not economy then return nil,why end
 local vitals;vitals,why=require('Training.DisarmVitals').review(t.vitals);if not vitals then return nil,why end
 local r={schemaVersion=1,trainable=false,scope='execution-accounting-only',steps={},byActor={},deployment=economy.deployment,stolenCost=economy.stolenCost,unassignedCost=0,unassignedDamageTaken=0,unassignedHealing=0,damageDealt=0,cost=0,damageTaken=0,healing=0}
 local ids,previous,windows={},{},{};local last=-math.huge
 for _,s in ipairs(t.executions)do
  if type(s)~='table'or not finite(s.id)or s.id%1~=0 or s.id<1 or ids[s.id]or not ({ninilite=true,wuyun=true})[s.actor]or not ({laser=true,melee=true,fmove=true,bmove=true,idle=true})[s.action]or type(s.source)~='string'or not finite(s.startedAt)or not finite(s.endedAt)or not finite(s.duration)or s.endedAt<s.startedAt or s.startedAt<last or s.endedAt>t.resourcesFinalizedAt or math.abs(s.duration-(s.endedAt-s.startedAt))>.00001 or not ({completed=true,interrupted=true,stopped=true,settled=true,closed=true})[s.outcome]then return nil,'INVALID_EXECUTION'end
  if previous[s.actor]and previous[s.actor].endedAt>s.startedAt then return nil,'OVERLAPPING_EXECUTIONS'end
  previous[s.actor]=s;last=s.startedAt
  local row={id=s.id,actor=s.actor,action=s.action,source=s.source,outcome=s.outcome,seconds=s.duration,cost=0,damageDealt=0,damageTaken=0,healing=0}
  ids[s.id]={source=s,row=row};r.steps[#r.steps+1]=row;windows[s.actor]=windows[s.actor]or{};windows[s.actor][#windows[s.actor]+1]=ids[s.id]
  r.byActor[s.actor]=r.byActor[s.actor]or{cost=0,damageDealt=0,damageTaken=0,healing=0}
 end
 for _,c in ipairs(t.consumption)do
  local e=t.resources.events[c.event]
  if e.step~=c.step then return nil,'CONSUMPTION_STEP_MISMATCH'end
  if c.owner==c.performer and c.owner~='mentor'then
   local step=ids[c.step];local s=step and step.source
   if not s or s.actor~=c.owner or ({laser='emp',melee='blade'})[s.action]~=c.item or c.at<s.startedAt or c.at>s.endedAt then return nil,'CONSUMPTION_EXECUTION_MISMATCH'end
   step.row.cost=step.row.cost+e.cost;r.cost=r.cost+e.cost
  elseif c.owner==c.performer then r.unassignedCost=r.unassignedCost+e.cost end
 end
 for _,hit in ipairs(t.impacts)do
  local step=type(hit)=='table'and ids[hit.step];local s=step and step.source
  if not s or s.actor~=hit.actor or (s.action~='laser'and s.action~='melee')or not finite(hit.at)or hit.at<s.startedAt or hit.at>t.resourcesFinalizedAt or not finite(hit.requested)or not finite(hit.damage)or hit.damage<0 or hit.damage>hit.requested then return nil,'INVALID_IMPACT'end
  step.row.damageDealt=step.row.damageDealt+hit.damage;r.damageDealt=r.damageDealt+hit.damage
 end
 -- Half-open intervals assign boundary events at most once. Events after a
 -- completed action remain unassigned; time coincidence is not causation.
 local cursor={}
 for _,hit in ipairs(t.vitals.events)do
  if hit.at>t.resourcesFinalizedAt then return nil,'VITALS_OUTSIDE_SESSION'end
  local assigned;local list=windows[hit.actor]or{};local index=cursor[hit.actor]or 1
  while list[index]and hit.at>=list[index].source.endedAt do index=index+1 end;cursor[hit.actor]=index
  if list[index]and hit.at>=list[index].source.startedAt then assigned=list[index].row end
  if assigned then assigned.damageTaken=assigned.damageTaken+hit.damage;assigned.healing=assigned.healing+hit.healing;r.damageTaken=r.damageTaken+hit.damage;r.healing=r.healing+hit.healing
  else r.unassignedDamageTaken=r.unassignedDamageTaken+hit.damage;r.unassignedHealing=r.unassignedHealing+hit.healing end
 end
 for _,step in ipairs(r.steps)do for _,key in ipairs({'cost','damageDealt','damageTaken','healing'})do r.byActor[step.actor][key]=r.byActor[step.actor][key]+step[key]end end
 if r.deployment+r.stolenCost+r.unassignedCost+r.cost~=economy.total or r.damageTaken+r.unassignedDamageTaken~=vitals.damage or r.healing+r.unassignedHealing~=vitals.healing then return nil,'ACCOUNTING_MISMATCH'end
 return r
end
return M
