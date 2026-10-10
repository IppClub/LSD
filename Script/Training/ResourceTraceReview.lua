-- Rebuild economic rewards from verified ONLINE actor intervals, never joined
-- attack rows. The legacy contribution trace remains raw supporting evidence.
local R={}
function R.rebuild(trace,episode,status)
 local O=require('Factory.Outcome')
 if type(episode)~='table' or type(episode.versions)~='table' then return nil,'INVALID_EPISODE'end
 local goal=episode.versions.trainingGoal
 if not O.validGoal({trainingGoal=goal},episode,true)then return nil,'INVALID_TRAINING_GOAL'end
 if episode.versions.outcome~=nil or episode.outcome~=nil then
  if episode.versions.outcome~=1 or not O.valid(episode.outcome)then return nil,'INVALID_OUTCOME_FACTS'end
  if status=='won' and not O.satisfied(episode.outcome,goal)then return nil,'OUTCOME_STATUS_MISMATCH'end
 end
 local base,why=require('Training.FlowerTraceReview').rebuild(trace,episode,status)
 if not base then return nil,why end
 if not episode.versions.resources or not episode.resourceCosts then return nil,'RESOURCE_EVIDENCE_REQUIRED'end
 local equal=require('Training.FlowerIdentity').equal
 local costs,why=require('Training.ResourceEvidence').attribute(episode.resources,episode.steps)
 if not costs or not equal(costs,episode.resourceCosts)then return nil,why or 'RESOURCE_COST_MISMATCH'end
 local result={trainingGoal=goal,schemaVersion=1,resourceMode=episode.resources.mode or 'mission',featureVersion=1,rewardPolicy=require('Training.ResourceReward').policy,episode=episode.episode,status=status,actors={},trainable=true,deploymentReady=false}
 for actor,rebuilt in pairs(base.actors)do
  local inputs,transitions={},{}
  for i,row in ipairs(rebuilt)do
   local original=trace.actors[actor].steps[i];local c=row.components
   local features,why=require('Training.ResourceFeatures').project(original.state);if not features then return nil,why end
   local nextFeatures,why=require('Training.ResourceFeatures').project(original.nextState);if not nextFeatures then return nil,why end
   local entry=costs.byStep[tostring(original.combatStep)]
   inputs[i]={progress=c.health*.005+c.armor*.002+c.breaks*.1+c.assistedHealth*.002,
    harm=c.damageTaken*.01+c.friendlyDamage*.02,duration=original.duration,cost=entry and entry.cost or 0}
   transitions[i]={combatStep=original.combatStep,features=features,nextFeatures=nextFeatures,action=original.action,origin=original.origin,started=original.started,finished=original.finished,done=original.done}
  end
  local reward,why=require('Training.ResourceReward').calculate(inputs,status,episode.resources.quote.total)
  if not reward then return nil,why end
  for i,row in ipairs(transitions)do row.reward=reward.rows[i].value;row.rewardComponents=reward.rows[i].components;row.cost=inputs[i].cost end
  result.actors[actor]={transitions=transitions,total=reward.total,normalization=reward.normalization}
 end
 return result
end
return R
