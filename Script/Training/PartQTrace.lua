-- Recompute recorded part rewards and every update before adopting a Q policy.
local Q=require('Training.PartQ');local F=require('Training.PartFeatures')
local T={}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function close(a,b)return finite(a) and finite(b) and math.abs(a-b)<=1e-8*math.max(1,math.abs(a),math.abs(b))end
local function validate(report,model)
 if type(report)~='table' or report.schemaVersion~=1 or report.status~='COMPLETE' or report.rewardPolicy~=Q.rewardPolicy or report.epsilon~=.35 or not finite(report.seed) or report.seed%1~=0 or report.seed<1 or report.seed>=2147483647 or not Q.validate(model) or not Q.validate(report.model,model.characterId) or #report.rounds~=3 then return false,'INVALID_Q_REPORT'end
 local q=report.initialModel and Q.restore(report.initialModel,model.characterId) or Q.new(model.characterId)
 if not q then return false,'INVALID_INITIAL_Q'end
 local initialUpdates=q.updates;local previousFinish
 for index,round in ipairs(report.rounds)do
  if round.distance~=({420,620,780})[index] or round.pending or #round.steps<1 or #round.steps>12 then return false,'INVALID_Q_ROUND'end
  local credit=require('Training.PartCredit').new({target='ground-taotie',maxHP=480,parts={head=80,['head-gem']=0,['back-front']=120,['back-rear']=100,['front-leg']=60,['rear-leg']=60,tail=40}})
  for i,t in ipairs(round.steps)do
   local step=t.combatStep;local c=t.components
   if not t.sealed or t.truncated or not finite(t.started) or not finite(t.finished) or t.finished<=t.started or previousFinish and t.started<previousFinish or not close(t.duration,t.finished-t.started) then return false,'INVALID_Q_TIME'end
   previousFinish=t.finished
   if not step.sealed or step.truncated or step.action.controller~='part-qlearning' or step.action.intendedPart~=F.parts[t.action] or t.state['part_'..t.action]=='blocked' then return false,'INVALID_Q_ACTION'end
   local armor,breaks=0,0
   for _,hit in ipairs(step.hits)do
    if hit.source~='learner' or not hit.credit or hit.credit.actor~=model.characterId then return false,'INVALID_Q_ACTOR'end
    local expected=credit:hit(hit,model.characterId,hit.credit.at);if not expected or expected.armor~=hit.credit.armor or expected.breaks~=hit.credit.breaks then return false,'INVALID_Q_CREDIT'end
    armor=armor+expected.armor;breaks=breaks+expected.breaks
   end
   local before=type(step.observation.energy)=='number' and step.observation.energy or 0
   local after=type(step.nextObservation.energy)=='number' and step.nextObservation.energy or 0
   if c.armor~=armor or c.breaks~=breaks or c.energy~=math.max(0,before-after) or not close(c.seconds,t.duration) then return false,'INVALID_Q_COMPONENTS'end
   if not close(t.reward,armor/100+breaks*.1-c.energy/1000-t.duration*.01)then return false,'INVALID_Q_REWARD'end
   local terminal=i==#round.steps
   if t.done~=terminal or (terminal and (t.reason~=round.reason or (t.reason~='SHOT_BUDGET' and t.reason~='NO_REACHABLE_PART'))) or (t.reason=='SHOT_BUDGET' and i~=12)then return false,'INVALID_Q_TERMINAL'end
   local expected={};for _,label in ipairs(q.actions)do if t.nextState['part_'..label]~='blocked'then expected[#expected+1]=label end end
   if #expected~=#t.nextActions then return false,'INVALID_Q_MASK'end
   for n,label in ipairs(expected)do if t.nextActions[n]~=label then return false,'INVALID_Q_MASK'end end
   if t.reason=='NO_REACHABLE_PART' and #expected~=0 then return false,'INVALID_Q_TERMINAL'end
   if not terminal and Q.key(t.nextState)~=Q.key(round.steps[i+1].state)then return false,'DISCONTINUOUS_Q_STATE'end
   local ok,why=q:update(t);if not ok then return false,why end
  end
 end
 if q.updates~=model.updates or report.updates~=q.updates-initialUpdates or model.alpha~=q.alpha or model.gamma~=q.gamma then return false,'Q_UPDATE_MISMATCH'end
 for _,snapshot in ipairs({model,report.model})do
  if snapshot.updates~=q.updates then return false,'Q_UPDATE_MISMATCH'end
  for key,row in pairs(q.values)do for a,v in pairs(row)do if not snapshot.values[key] or not close(v,snapshot.values[key][a])then return false,'Q_VALUE_MISMATCH'end end end
  for key,row in pairs(snapshot.values)do for a,v in pairs(row)do if not q.values[key] or not close(v,q.values[key][a])then return false,'Q_VALUE_MISMATCH'end end end
 end
 return true
end
function T.validate(report,model)
 local ok,result,why=pcall(validate,report,model);if not ok then return false,'MALFORMED_Q_REPORT'end;return result,why
end
return T
