-- Opt-in online decision boundaries for dynamic encounters. Never reconstruct
-- successor states by joining the interleaved action journal after the battle.
local D=require('Dora');local F=require('Training.FlowerFeatures');local P=require('Training.FlowerPolicy')
local T={};local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
function T.options(battle,a)
 local labels={'idle','fmove','bmove','shoot'};if a.character.id=='wuyun'then labels[#labels+1]='melee'end
 for _,part in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do labels[#labels+1]='shoot@'..part end
 local legal,aims={},{}
 for _,label in ipairs(labels)do
  local name,part=P.decodeAction(label)
  if a:available(name=='shoot' and 'laser' or name) and (not a.student:isDoing(a.physical[name=='shoot' and 'laser' or name]) or a.continuousDecisions and (name=='idle' or name=='fmove' or name=='bmove')) then
   local aim=part and battle.partCombat:aim(a.student,part,true,battle.roots[3].enemy.x>=a.student.x) or nil
   if not part or aim then legal[#legal+1]=label;if part then aims[part]=aim end end
  end
 end
 return legal,aims
end
-- Fallback and Q selection must share the recorded legal set. Wall-clock
-- cooldowns may open while expensive synchronous geometry is being evaluated.
function T.baseActions(decision)
 local mask={};for _,label in ipairs(decision.actions)do mask[label]=true end
 local result={}
 for _,name in ipairs({'idle','fmove','bmove','laser','melee'})do
  result[name]=mask[name=='laser' and 'shoot' or name]==true
 end
 return result
end
-- One synchronous decision owns these results; never reuse across frames or actors.
function T.decision(battle,a)
 local actions,aims=T.options(battle,a)
 if #actions==0 then return nil,'NO_AVAILABLE_ACTIONS'end
 return {owner=a,battle=battle,at=D.App.totalTime,actions=actions,aims=aims,state=F.capture(battle,a.student,battle.partCombat.known)}
end
local function counters(battle,a)
 local state=battle.partCombat.vitals.actors[a.character.id]
 return {events=state and #state.events or 0,supportEvents=#battle.flowerDecisionTrace.resources,damage=state and state.damage or 0,healing=state and state.healing or 0,supportSpent=battle.support.spent or 0}
end
local function boundary(battle,a)
 return {state=F.capture(battle,a.student,battle.partCombat.known),actions=T.options(battle,a),at=D.App.totalTime,counters=counters(battle,a)}
end
function T.attach(battle)
 assert(battle.phase=='ready' and not battle.flowerDecisionTrace,'Trace must begin before combat')
 local self={schemaVersion=2,resources={},clock='simulation',boundaryPolicy='next-accepted-actor-decision-v1',rewardPolicy='flower-contribution-v1',actors={},closed=false,trainable=false}
 battle.flowerDecisionTrace=self
 self.initialSupportSpent=battle.support.spent or 0
 local update=battle.support.update
 battle.support.update=function(s,...)
  local before={gold=s.gold,machineHP=s.machineHP,spent=s.spent};local dt=select(1,...)
  local result=update(s,...)
  if not self.closed then self.resources[#self.resources+1]={at=D.App.totalTime,dt=dt,span=s.span,gold=before.gold,machineHP=before.machineHP,used=s.spent-before.spent}end
  return result
 end
 local function finishInterval(actor,nextBoundary,done)
  local row=actor.steps[#actor.steps];if not row then return end
  row.after=copy(nextBoundary.counters)
  row.nextState=copy(nextBoundary.state);row.nextActions=done and {} or copy(nextBoundary.actions)
  row.finished=nextBoundary.at;row.duration=row.finished-row.started;row.done=done
  row.components.damageTaken=nextBoundary.counters.damage-row.before.damage
  row.components.healing=nextBoundary.counters.healing-row.before.healing
  row.components.supportSpent=nextBoundary.counters.supportSpent-row.before.supportSpent
 end
 for _,a in ipairs(battle.learners)do
  local actor={steps={},energyCost=a.studentEnergy~=nil and a.shotEnergyCost or 0};self.actors[a.character.id]=actor
  local request=a.request
  a.request=function(arena,action,source,decision)
   if self.closed or battle.phase~='playing'then return request(arena,action,source)end
   -- Failed requests never create a decision boundary. Delegate to the real
   -- executor so its rejection reason, demo recorder and facing effects remain
   -- authoritative, without solving all five body-part rays first.
   if (arena.mode~='demo' and arena.mode~='trial') or not arena:available(action)
    or (arena.physical[action] and arena.student:isDoing(arena.physical[action]) and not(arena.continuousDecisions and (action=='idle' or action=='fmove' or action=='bmove'))) then
    return request(arena,action,source)
   end
   local before
   if decision and decision.owner==arena and decision.battle==battle and decision.at==D.App.totalTime and not decision.used then
    decision.used=true
    before={state=decision.state,actions=decision.actions,at=decision.at,counters=counters(battle,arena)}
   else before=boundary(battle,arena)end
   local count=#battle.partCombat.journal.steps
   local label=action=='laser' and (arena.flowerTargetPart and 'shoot@'..arena.flowerTargetPart or 'shoot') or action
   local ok,why=request(arena,action,source);if not ok then return ok,why end
   local found
   for i=count+1,#battle.partCombat.journal.steps do local step=battle.partCombat.journal.steps[i];if step.action.actor==arena.character.id then assert(not found,'Multiple actions per decision');found=step.id end end
   assert(found,'Accepted action lacks combat evidence')
   local legal=false;for _,v in ipairs(before.actions)do if v==label then legal=true end end;assert(legal,'Accepted action absent from legal set')
   battle.partCombat.vitals:checkpoint(arena.character.id)
   finishInterval(actor,before,false)
   actor.steps[#actor.steps+1]={state=copy(before.state),actions=copy(before.actions),action=label,origin=source,started=before.at,before=before.counters,combatStep=found,
    components={health=0,armor=0,breaks=0,assistedHealth=0,friendlyDamage=0,shots=0,energy=0,budDamage=0,terminal=0}}
   return ok,why
  end
 end
 local start=battle.start
 battle.start=function(b,...)
  local began=D.App.totalTime;local ok=start(b,...)
  if ok then self.timing={schemaVersion=1,clock='simulation',started=began}end
  return ok
 end
 local finish=battle.finish
 battle.finish=function(b,status,reason)
  if self.closed or (b.phase~='playing' and b.phase~='ready')then return finish(b,status,reason)end
  local last={};for _,a in ipairs(b.learners)do last[a.character.id]=boundary(b,a)end
  if self.timing then self.timing.finished=D.App.totalTime end
  local result=finish(b,status,reason)
  self.closed=true;self.status=status;self.episode=b.combatEpisode.episode
  self.trainable=status=='won' or status=='failed'
  local byStep,byAttack={},{}
  for _,a in ipairs(b.learners)do
   local actor=self.actors[a.character.id];finishInterval(actor,last[a.character.id],true)
   for _,row in ipairs(actor.steps)do
    local step=b.combatEpisode.steps[row.combatStep];assert(step.action.actor==a.character.id)
    byStep[row.combatStep]=row
    row.components.shots=step.action.emitted or 0;row.components.energy=step.action.energySpent or 0
    row.actionInterrupted=step.truncated==true
    for _,hit in ipairs(step.hits)do byAttack[hit.attackId]=row end
   end
   if #actor.steps>0 then actor.steps[#actor.steps].components.terminal=status=='won' and 1 or status=='failed' and -1 or 0 end
  end
  self.unassignedAssists=0
  for _,step in ipairs(b.combatEpisode.steps)do
   local row=byStep[step.id]
   for _,hit in ipairs(step.hits)do
    if row then
     local c=row.components
     if hit.relation=='friendly'then c.friendlyDamage=c.friendlyDamage+hit.healthDamage
     else
      c.health=c.health+hit.credit.health;c.armor=c.armor+hit.credit.armor;c.breaks=c.breaks+hit.credit.breaks
      if hit.targetStage=='bud'then c.budDamage=c.budDamage+hit.healthDamage end
     end
    end
    local assist=hit.credit and hit.credit.assist
    if assist and self.actors[assist.actor]then
     local opener=byAttack[assist.attackId]
     if opener then opener.components.assistedHealth=opener.components.assistedHealth+assist.health else self.unassignedAssists=self.unassignedAssists+assist.health end
    end
   end
  end
  for _,actor in pairs(self.actors)do
   if #actor.steps==0 then self.trainable=false end
   for _,row in ipairs(actor.steps)do if row.duration<=0 then self.trainable=false end end
  end
  for _,actor in pairs(self.actors)do
   for _,row in ipairs(actor.steps)do
    local c=row.components
    -- Healing and temporary bud HP are facts, never farmable positive rewards.
    -- Support consumption is shared team cost; direct damage is actor-specific.
    row.reward=c.health*.005+c.armor*.002+c.breaks*.1+c.assistedHealth*.002-c.damageTaken*.01-c.friendlyDamage*.02-row.duration*.01-c.shots*.02-c.energy*.001-c.supportSpent*.001+c.terminal
    row.sealed=self.trainable and row.duration>0;row.outcomeCutoff='encounter-end';row.delayedOutcomes=true
   end
  end
  return result
 end
 return self
end
return T
