-- Replayable training evidence stored separately from small policy envelopes.
local Q=require('Training.QModel');local Recorder=require('Training.Recorder')
local T={maxBytes=2097152}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function array(t,max)
 if type(t)~='table' or #t>max then return false end
 local n=0;for k in pairs(t)do if type(k)~='number' or k%1~=0 or k<1 or k>#t then return false end;n=n+1 end
 return n==#t
end
function T.validId(id)return type(id)=='string' and #id<=128 and id:match('^q%-[%w%-]+$')~=nil end
function T.validate(e,model)
 if type(e)~='table' or e.schemaVersion~=1 or not T.validId(e.id) or type(model)~='table' or e.id~=model.trainingRunId then return false,'INVALID_TRACE'end
 if not Q.validate(model,e.characterId) or e.rewardPolicy~=model.rewardPolicy or e.featureSchemaVersion~=3 or e.actionSetVersion~=1 then return false,'INCOMPATIBLE_TRACE'end
 if not finite(e.seed) or e.seed%1~=0 or e.seed<1 or e.seed>=2147483647 or not finite(e.epsilon) or e.epsilon<0 or e.epsilon>1 or type(e.enemyAsset)~='string' or not finite(e.roundLimit) or e.roundLimit<=0 then return false,'INVALID_CONFIGURATION'end
 if not array(e.rounds,3) or #e.rounds~=3 then return false,'INCOMPLETE_ROUNDS'end
 local replay,err
 if e.initialModel then replay,err=Q.restore(e.initialModel,e.characterId)
 else replay=Q.new({characterId=e.characterId,actions=model.actions,alpha=model.alpha,gamma=model.gamma});replay.rewardPolicy=model.rewardPolicy end
 if not replay then return false,err end
 if replay.alpha~=model.alpha or replay.gamma~=model.gamma or replay.rewardPolicy~=model.rewardPolicy then return false,'INCOMPATIBLE_INITIAL_POLICY'end
 if #replay.actions~=#model.actions then return false,'INCOMPATIBLE_INITIAL_POLICY'end
 for i,a in ipairs(replay.actions)do if model.actions[i]~=a then return false,'INCOMPATIBLE_INITIAL_POLICY'end end
 local initial=replay.updates;local count=0
 for index,round in ipairs(e.rounds)do
  if type(round)~='table' or round.distance~=({180,460,800})[index] or not array(round.steps,1500) or #round.steps==0 or not ({VICTORY=true,DEFEAT=true,TIMEOUT=true})[round.reason]then return false,'INVALID_ROUND'end
  local lastFinish
  for i,s in ipairs(round.steps)do
   count=count+1;if count>1500 then return false,'TRACE_LIMIT'end
   if type(s)~='table' or not finite(s.started) or not finite(s.finished) or not finite(s.duration) or s.duration<=0 or math.abs(s.finished-s.started-s.duration)>1e-7 or (lastFinish and s.started<lastFinish-1e-7) or s.rewardPolicy~=e.rewardPolicy or not Recorder.validateFeatures(s.nextState) then return false,'INVALID_INTERVAL'end
   lastFinish=s.finished
   if s.done~=(i==#round.steps) or s.reason~=(s.done and round.reason or 'DECISION')then return false,'INVALID_TERMINAL'end
   local c=s.components
   if type(c)~='table'then return false,'INVALID_REWARD'end
   for _,name in ipairs({'healthDamage','damageTaken','energySpent','seconds','victory','defeat'})do if not finite(c[name]) or c[name]<0 then return false,'INVALID_REWARD'end end
   if math.abs(c.seconds-s.duration)>1e-7 or c.victory~=(s.done and round.reason=='VICTORY' and 1 or 0) or c.defeat~=(s.done and round.reason=='DEFEAT' and 1 or 0)then return false,'INVALID_REWARD'end
   local reward=c.healthDamage/100-c.damageTaken/100-c.energySpent/1000-c.seconds*.01+c.victory-c.defeat
   if not finite(s.reward) or math.abs(s.reward-reward)>1e-8 then return false,'REWARD_MISMATCH'end
   local accepted,why=replay:update(s);if not accepted then return false,why end
  end
 end
 if e.newUpdates~=count or replay.updates-initial~=count or replay.updates~=model.updates then return false,'UPDATE_MISMATCH'end
 local states=0;for key,row in pairs(model.values)do
  states=states+1;local actual=replay.values[key];if not actual then return false,'POLICY_MISMATCH'end
  for action,value in pairs(row)do if actual[action]==nil or math.abs(actual[action]-value)>1e-8 then return false,'POLICY_MISMATCH'end end
  for action in pairs(actual)do if row[action]==nil then return false,'POLICY_MISMATCH'end end
 end
 if states~=replay.states then return false,'POLICY_MISMATCH'end
 return true
end
return T
