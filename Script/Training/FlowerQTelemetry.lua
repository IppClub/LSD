-- Verified summaries from optional live witnesses. Missing legacy data stays missing.
local T={}
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
function T.build(record)
 local trace=record.trace;local result={}
 if trace.timing then
  local t=trace.timing
  assert(t.schemaVersion==1 and t.clock=='simulation' and finite(t.started) and finite(t.finished) and t.started>=0 and t.finished>t.started,'INVALID_SESSION_TIME')
  for _,actor in pairs(trace.actors)do
   assert(actor.steps[1].started>=t.started and math.abs(actor.steps[#actor.steps].finished-t.finished)<1e-7,'SESSION_TIME_MISMATCH')
  end
  for _,event in ipairs(trace.resources)do assert(event.at>=t.started-1e-7 and event.at<=t.finished+1e-7,'RESOURCE_OUTSIDE_SESSION')end
  for _,step in ipairs(record.episode.steps)do assert(step.started>=t.started-1e-7 and step.started<=t.finished+1e-7,'ACTION_OUTSIDE_SESSION')end
  result.seconds=t.finished-t.started
 end
 if trace.decisionSourcesVersion~=nil then
  assert(trace.decisionSourcesVersion==1 and record.mode=='evaluate','INVALID_DECISION_SOURCES')
  result.actors={}
  for _,id in ipairs({'ninilite','wuyun'})do
   local learner=record.initial[id].algorithm=='flower-resource-qlearning' and require('Training.ResourceQ')or require('Training.FlowerQ')
   local policy=assert(learner.restore(record.initial[id],id));local counts={q=0,fallback=0,total=0,reasons={}}
   if record.episode.resources then counts.empCost=0;counts.fallbackEmpCost=0;counts.zeroProgressEmpCost=0 end
   for _,row in ipairs(trace.actors[id].steps)do
    local mask={};for _,action in ipairs(row.actions)do mask[action]=true end
    local selected,why=policy:choose(row.state,function(action)return mask[action]==true end,false,0)
    local witness=assert(row.decisionSource,'MISSING_DECISION_SOURCE');assert(witness.reason==why,'DECISION_REASON_MISMATCH')
    if selected then assert(selected==row.action and witness.state==nil and witness.available==nil,'Q_CHOICE_MISMATCH');counts.q=counts.q+1
    else
     assert(why=='UNSEEN_STATE' or why=='UNSEEN_ACTIONS','INVALID_FALLBACK_REASON')
     assert(require('Training.Recorder').validateFeatures(witness.state,record.baseModels[id].featureSchemaVersion),'INVALID_BASE_STATE')
     local available=assert(witness.available)
     -- Resource trials require the current shared mask; historical legacy trials
     -- retain their original witness contract and are not relabelled as resources.
     if record.initial[id].algorithm=='flower-resource-qlearning'then assert(require('Training.FlowerIdentity').equal(available,require('Training.FlowerDecisionTrace').baseActions({actions=row.actions})),'BASE_MASK_MISMATCH')end
     local allowed={idle=true,fmove=true,bmove=true,laser=true,melee=true}
     for name,value in pairs(available)do assert(allowed[name] and type(value)=='boolean','INVALID_BASE_MASK')end
     for name in pairs(allowed)do assert(type(available[name])=='boolean','INCOMPLETE_BASE_MASK')end
     local action
     if record.setup and (record.setup.resourceFallback==1 or record.setup.resourceFallback==2 or record.setup.resourceFallback==3) then action=require('Training.ResourceFallback').predict(record.baseModels[id],witness.state,available,row.state,record.setup.resourceFallback)
     else action=require('Training.Model').predict(record.baseModels[id],witness.state,function(a)return available[a]end);if not action and available.idle then action='idle'end end
     assert(action and (action=='laser' and 'shoot' or action)==row.action,'BASE_CHOICE_MISMATCH')
     counts.fallback=counts.fallback+1;counts.reasons[why]=(counts.reasons[why] or 0)+1
    end
    if counts.empCost~=nil then
     local step=record.episode.steps[row.combatStep]
     if step and step.action.weapon=='emp' then
      local entry=record.episode.resourceCosts.byStep[tostring(row.combatStep)]
      local cost=entry and entry.cost or 0
      counts.empCost=counts.empCost+cost
      if not selected then counts.fallbackEmpCost=counts.fallbackEmpCost+cost end
      local c=row.components
      if c.health==0 and c.armor==0 and c.breaks==0 and c.assistedHealth==0 then counts.zeroProgressEmpCost=counts.zeroProgressEmpCost+cost end
     end
    end
    counts.total=counts.total+1
   end
   result.actors[id]=counts
  end
 end
 return result
end
return T
