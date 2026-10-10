-- Actual learner execution intervals, independent of command acceptance.
-- Completion is not proof of a human demonstration or an attributed reward.
local D=require('Dora');local M={}
function M.attach(b,trace,snapshot)
 trace.executionVersion=1;trace.executions={};trace.impactVersion=1;trace.impacts={};trace.projectiles={}
 local active={};local sequence=0;local closed=false
 local function append(list,row)if #list>=trace.limit then trace.truncated=true;return false end;list[#list+1]=row;return true end
 local function targetId(unit)for i,e in ipairs(b.enemies)do if e.enemy==unit then return "enemy:"..i end end;return "other"end
 local function finish(a,state)
  local row=active[a];if not row then return end
  row.after=snapshot(a.student);row.endedAt=D.App.runningTime;row.duration=row.endedAt-row.startedAt;row.outcome=state;active[a]=nil
 end
 local function begin(a,action,source)
  if closed then return end
  finish(a,'interrupted')
  if #trace.executions>=trace.limit then trace.truncated=true;return end
  sequence=sequence+1
  local row={id=sequence,actor=a.character.id,action=action,source=source or a.currentActionSource or 'unknown',before=snapshot(a.student),startedAt=D.App.runningTime,outcome='running'}
  trace.executions[#trace.executions+1]=row;active[a]=row;return row.id
 end
 local function complete(a,id,state)
  if active[a]and active[a].id==id then finish(a,state)end
 end
 for _,a in ipairs(b.learners)do
  assert(not a.beginCombatAction and not a.beginMeleeAction and not a.beginMovementAction,'Disarm execution cannot replace another recorder')
  assert(not a.observeProjectile,'Disarm cannot replace another projectile observer')
  local damage=a.damageOpponent
  a.damageOpponent=function(unit,n,step)
   local dealt=damage(unit,n,step)
   if not closed and step then append(trace.impacts,{step=step,actor=a.character.id,target=targetId(unit),requested=n,damage=dealt,at=D.App.runningTime,phase=b.phase})end
   return dealt
  end
  a.observeProjectile=function(bullet,source,step)
   if closed or source~='learner' or not step then return end
   local row={step=step,actor=a.character.id,spawnedAt=D.App.runningTime,outcome='flying'}
   if not append(trace.projectiles,row)then return end
   bullet:slot('HitTarget',function(_,target)
    if closed or row.outcome~='flying'then return end
    row.outcome='contact';row.target=targetId(target);row.endedAt=D.App.runningTime
   end)
   bullet:slot('Cleanup',function()
    if closed or row.outcome~='flying'then return end
    row.endedAt=D.App.runningTime
    -- Cleanup has no native removal reason; do not manufacture a miss label.
    row.outcome='removed';row.flightSeconds=row.endedAt-row.spawnedAt
   end)
  end
  a.beginCombatAction=function(owner)if owner==a.student then return begin(a,'laser')end end
  a.finishCombatAction=function(id,owner,source,status)complete(a,id,status or 'completed')end
  a.beginMeleeAction=function(owner)if owner==a.student then return begin(a,'melee')end end
  a.finishMeleeAction=function(id,owner,status)complete(a,id,status or 'completed')end
  a.beginMovementAction=function(_,action,source)return begin(a,action,source)end
  a.finishMovementAction=function(id)complete(a,id,'stopped')end
 end
 local update=b.update
 b.update=function(self,...)
  local result=update(self,...)
  for a,row in pairs(active)do if not a.student:isDoing(a.physical[row.action])then finish(a,'interrupted')end end
  return result
 end
 local function close(reason)
  if closed then return end;closed=true
  for a in pairs(active)do finish(a,reason)end
  for _,row in ipairs(trace.projectiles)do if row.outcome=='flying'then row.outcome=reason;row.endedAt=D.App.runningTime end end
 end
 b.world:slot('Cleanup',function()close('closed')end)
 return {finish=function()close('settled')end}
end
return M
