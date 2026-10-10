-- Recompute Q reward facts from online boundaries plus authoritative combat data.
local F=require('Training.FlowerFeatures');local equal=require('Training.FlowerIdentity').equal
local R={}
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
local function near(a,b)return finite(a) and finite(b) and math.abs(a-b)<1e-7 end
local function array(t,min,max)
 assert(type(t)=='table' and #t>=min and #t<=max,'INVALID_ARRAY');local n=0
 for k in pairs(t)do assert(type(k)=='number' and k%1==0 and k>=1 and k<=#t,'INVALID_ARRAY');n=n+1 end;assert(n==#t,'INVALID_ARRAY')
end
local function actions(list,id,empty)
 array(list,empty and 0 or 1,10);local seen={}
 for _,label in ipairs(list)do local name,part=require('Training.FlowerPolicy').decodeAction(label)
  assert(not seen[label] and (({idle=true,fmove=true,bmove=true,shoot=true})[name] or name=='melee' and id=='wuyun'),'INVALID_ACTION_MASK');seen[label]=true
 end
 return seen
end
function R.reward(c,seconds)
 return c.health*.005+c.armor*.002+c.breaks*.1+c.assistedHealth*.002-c.damageTaken*.01-c.friendlyDamage*.02-seconds*.01-c.shots*.02-c.energy*.001-c.supportSpent*.001+c.terminal
end
local function rebuild(trace,episode,status)
 assert(type(trace)=='table' and trace.schemaVersion==2 and trace.closed==true and trace.trainable==true and trace.clock=='simulation' and trace.boundaryPolicy=='next-accepted-actor-decision-v1' and trace.rewardPolicy=='flower-contribution-v1','INCOMPATIBLE_TRACE')
 assert((status=='won' or status=='failed') and trace.status==status,'NONTERMINAL_TRACE')
 assert(require('Training.CombatStore').validate(episode));assert(trace.episode==episode.episode,'WRONG_EPISODE')
 array(trace.resources,0,40000);assert(finite(trace.initialSupportSpent) and trace.initialSupportSpent>=0)
 local resource={[0]=trace.initialSupportSpent};local lastTime=0
 for i,event in ipairs(trace.resources)do
  assert(finite(event.dt) and event.dt>=0 and event.dt<=1 and finite(event.span) and event.span>=0 and finite(event.gold) and event.gold>=0 and finite(event.machineHP) and finite(event.at) and event.at>=lastTime,'INVALID_RESOURCE_EVENT')
  local used=event.gold>0 and event.machineHP>0 and math.min(event.gold,event.dt*(.35+event.span/1000)) or 0
  assert(near(used,event.used),'RESOURCE_COST_MISMATCH');resource[i]=resource[i-1]+used;lastTime=event.at
 end
 local byStep,byAttack={},{};local result={actors={}}
 for id in pairs(trace.actors)do assert(id=='ninilite' or id=='wuyun','INVALID_ACTOR')end
 for _,id in ipairs({'ninilite','wuyun'})do
  local actor=assert(trace.actors[id]);array(actor.steps,1,1500);result.actors[id]={}
  local damage,healing={[0]=0},{[0]=0};local vitals=episode.vitals.actors[id]
  for i,event in ipairs(vitals and vitals.events or {})do
   damage[i]=damage[i-1]+math.max(0,event.hpBefore-event.hpAfter);healing[i]=healing[i-1]+math.max(0,event.hpAfter-event.hpBefore)
  end
  local function boundary(c,at)
   assert(type(c)=='table' and damage[c.events]~=nil and resource[c.supportEvents]~=nil,'INVALID_BOUNDARY_COUNTER')
   assert(near(c.damage,damage[c.events]) and near(c.healing,healing[c.events]) and near(c.supportSpent,resource[c.supportEvents]),'BOUNDARY_COUNTER_MISMATCH')
   if c.events>0 then assert(vitals.events[c.events].finished<=at+1e-7,'FUTURE_VITAL_EVENT')end
   if vitals and c.events<#vitals.events then assert(vitals.events[c.events+1].started>=at-1e-7,'OMITTED_VITAL_EVENT')end
   if c.supportEvents>0 then assert(trace.resources[c.supportEvents].at<=at+1e-7,'FUTURE_RESOURCE_EVENT')end
   if c.supportEvents<#trace.resources then assert(trace.resources[c.supportEvents+1].at>=at-1e-7,'OMITTED_RESOURCE_EVENT')end
  end
  for i,row in ipairs(actor.steps)do
   assert(F.validate(row.state) and F.validate(row.nextState) and row.state.featureSchemaVersion==6 and row.nextState.featureSchemaVersion==6,'INVALID_STATE')
   assert(finite(row.started) and finite(row.finished) and row.finished>row.started and near(row.duration,row.finished-row.started),'INVALID_DURATION')
   assert(row.done==(i==#actor.steps) and row.sealed==true and row.delayedOutcomes==true and row.outcomeCutoff=='encounter-end','INVALID_BOUNDARY')
   local legal=actions(row.actions,id,false);assert(legal[row.action],'ILLEGAL_ACTION');actions(row.nextActions,id,row.done)
   if row.done then assert(#row.nextActions==0,'TERMINAL_ACTIONS')end
   boundary(row.before,row.started);boundary(row.after,row.finished)
   if row.done then assert(row.after.events==(vitals and #vitals.events or 0) and row.after.supportEvents==#trace.resources,'INCOMPLETE_TERMINAL_LEDGER')end
   if i>1 then local previous=actor.steps[i-1];assert(near(previous.finished,row.started) and equal(previous.nextState,row.state) and equal(previous.nextActions,row.actions) and equal(previous.after,row.before),'DISCONTINUOUS_TRACE')end
   local step=assert(episode.steps[row.combatStep]);assert(not byStep[row.combatStep] and step.action.actor==id and step.action.origin==row.origin and near(step.started,row.started),'ACTION_IDENTITY_MISMATCH')
   local name,part=require('Training.FlowerPolicy').decodeAction(row.action);assert(name==step.action.name and (not part or step.action.aimSource=='part-policy-v1' and step.action.intendedPart==part),'ACTION_LABEL_MISMATCH')
   local c={health=0,armor=0,breaks=0,assistedHealth=0,friendlyDamage=0,shots=step.action.emitted or 0,energy=step.action.energySpent or 0,budDamage=0,terminal=row.done and (status=='won' and 1 or -1) or 0,
    damageTaken=row.after.damage-row.before.damage,healing=row.after.healing-row.before.healing,supportSpent=row.after.supportSpent-row.before.supportSpent}
   for _,v in pairs(c)do assert(finite(v),'INVALID_COMPONENT')end
   assert(c.damageTaken>=-1e-7 and c.healing>=-1e-7 and c.supportSpent>=-1e-7,'REVERSED_COUNTER')
   local rebuilt={components=c};result.actors[id][i]=rebuilt;byStep[row.combatStep]=rebuilt
   for _,hit in ipairs(step.hits)do assert(not byAttack[hit.attackId] or byAttack[hit.attackId]==rebuilt,'DUPLICATE_ATTACK');byAttack[hit.attackId]=rebuilt end
  end
 end
 for _,step in ipairs(episode.steps)do
  if trace.actors[step.action.actor]then assert(byStep[step.id],'OMITTED_ACTION')end
  for _,hit in ipairs(step.hits)do
   local row=byStep[step.id]
   if row then local c=row.components
    if hit.relation=='friendly'then c.friendlyDamage=c.friendlyDamage+hit.healthDamage
    else c.health=c.health+hit.credit.health;c.armor=c.armor+hit.credit.armor;c.breaks=c.breaks+hit.credit.breaks;if hit.targetStage=='bud'then c.budDamage=c.budDamage+hit.healthDamage end end
   end
   local assist=hit.credit and hit.credit.assist
   if assist and trace.actors[assist.actor]then local opener=assert(byAttack[assist.attackId],'UNASSIGNED_ASSIST');opener.components.assistedHealth=opener.components.assistedHealth+assist.health end
  end
 end
 for id,rows in pairs(result.actors)do for i,rebuilt in ipairs(rows)do
  local row=trace.actors[id].steps[i];rebuilt.reward=R.reward(rebuilt.components,row.duration)
  assert(type(row.components)=='table','MISSING_COMPONENTS')
  for key,value in pairs(rebuilt.components)do assert(near(value,row.components[key]),'REWARD_COMPONENT_MISMATCH:'..key)end
  for key in pairs(row.components)do assert(rebuilt.components[key]~=nil,'UNKNOWN_COMPONENT')end
  assert(near(rebuilt.reward,row.reward),'REWARD_MISMATCH')
 end end
 return result
end
function R.rebuild(trace,episode,status)
 local ok,result=pcall(rebuild,trace,episode,status);if not ok then return nil,tostring(result)end;return result
end
return R
