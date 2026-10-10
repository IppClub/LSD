-- Resource-aware candidates are deliberately distinct from deployed legacy Q.
local D=require('Dora');local Core=require('Training.QModel');local Base=require('Training.FlowerQ')
local Features=require('Training.ResourceFeatures');local Q={};Q.__index=Q
function Q.key(state)
 local base,why=Base.key(state,7);if not base then return nil,why end
 local resources,why=Features.key(state);if not resources then return nil,why end
 return base..'~'..resources
end
function Q.new(actor,goal)
 assert(goal==nil or goal=="resource-clear-v1","INVALID_TRAINING_GOAL")
 local q=Base.new(actor,7);q.trainingGoal=goal;q.stateKey=Q.key;return setmetatable(q,Q)
end
Q.update=Core.update
function Q:choose(state,available,training,epsilon,random)
 if not training or self.explorationPolicy~='coverage-v1' then return Core.choose(self,state,available,training,epsilon,random)end
 epsilon=epsilon or 0;assert(type(epsilon)=='number'and epsilon==epsilon and epsilon>=0 and epsilon<=1)
 local key,why=Q.key(state);if not key then return nil,why end
 local eligible={};for _,a in ipairs(self.actions)do if available(a)then eligible[#eligible+1]=a end end
 if #eligible==0 then return nil,'ACTION_UNAVAILABLE'end
 if epsilon>0 then
  assert(random,'Explicit RNG required for exploration');local roll=random();assert(type(roll)=='number'and roll>=0 and roll<1)
  if roll<epsilon then
   self.explorationVisits=self.explorationVisits or {}
   local visits=self.explorationVisits[key]or {};self.explorationVisits[key]=visits
   local values=self.values[key]or {};local candidates,best={},nil
   for _,a in ipairs(eligible)do
    -- Try all available alternatives before repeating; among equal visits,
    -- prioritize actions without a learned value. Never fabricate that value.
    local score=(visits[a]or 0)*2+(values[a]~=nil and 1 or 0)
    if best==nil or score<best then best=score;candidates={a}elseif score==best then candidates[#candidates+1]=a end
   end
   local pick=random();assert(type(pick)=='number'and pick>=0 and pick<1)
   local action=candidates[math.floor(pick*#candidates)+1];visits[action]=(visits[action]or 0)+1
   return action,'EXPLORE'
  end
 end
 return Core.choose(self,state,available,true,0)
end
function Q:snapshot()
 local values=D.json.decode(D.json.encode(self.values,false,true),32)
 return {trainingGoal=self.trainingGoal,algorithm='flower-resource-qlearning',schemaVersion=1,featureSchemaVersion=8,resourceFeatureVersion=1,actionSetVersion=5,
  partSetVersion=2,rewardPolicy='mission-resources-v1',discountTimeUnit='seconds',characterId=self.characterId,alpha=self.alpha,gamma=self.gamma,values=values,updates=self.updates}
end
function Q.restore(model,actor)
 local function restore()
  assert(type(model)=='table' and model.algorithm=='flower-resource-qlearning' and model.schemaVersion==1 and model.featureSchemaVersion==8 and model.resourceFeatureVersion==1 and model.actionSetVersion==5 and model.partSetVersion==2 and model.rewardPolicy=='mission-resources-v1' and model.discountTimeUnit=='seconds','INCOMPATIBLE_RESOURCE_Q')
  assert(model.alpha==.2 and model.gamma==.95 and type(model.updates)=='number' and model.updates%1==0 and model.updates>0 and model.updates<=1000000,'INVALID_Q_PARAMETERS')
  local q=Q.new(model.characterId,model.trainingGoal);assert(not actor or actor==q.characterId,'WRONG_ACTOR');assert(type(model.values)=='table','INVALID_VALUES')
  local entries=0
  for key,row in pairs(model.values)do
   assert(type(key)=='string' and #key<=640 and type(row)=='table','INVALID_RESOURCE_KEY')
   local base,resource=key:match('^([^~]+)~([^~]+)$');assert(base and resource,'INVALID_RESOURCE_KEY')
   local tokens={};for word in (resource..'|'):gmatch('(.-)|')do tokens[#tokens+1]=word end;assert(#tokens==#Features.names,'INVALID_RESOURCE_KEY')
   for i,name in ipairs(Features.names)do local allowed=false;for word in Features.categories[name]:gmatch('%S+')do if tokens[i]==word then allowed=true end end;assert(allowed,'INVALID_RESOURCE_CATEGORY')end
   local count=0
   for action,value in pairs(row)do
    assert(q.legal[action] and type(value)=='number' and value==value and math.abs(value)<math.huge,'INVALID_Q_VALUE')
    local probe=Base.new(q.characterId,7):snapshot();probe.values={[base]={[action]=value}};probe.updates=1
    assert(Base.restore(probe,q.characterId),'INVALID_TACTICAL_KEY');count=count+1
   end
   assert(count>0,'EMPTY_Q_ROW');entries=entries+count;q.states=q.states+1;assert(q.states<=q.maxStates,'STATE_LIMIT');q.values[key]=D.json.decode(D.json.encode(row,false,true),32)
  end
  assert(entries>0 and entries<=model.updates,'INVALID_UPDATE_COUNT');q.updates=model.updates;return q
 end
 local ok,value=pcall(restore);if not ok then return nil,tostring(value)end;return value
end
-- Legacy v1 rewards summed a hash table in unspecified order. Only stored
-- value roundoff may differ on replay; metadata, states and actions stay exact.
function Q.equivalentModels(expected,stored)
 local equal=require('Training.FlowerIdentity').equal
 if type(stored)~='table'then return false end
 for actor,model in pairs(expected)do
  local other=stored[actor];if type(other)~='table'then return false end
  for key,value in pairs(model)do if key~='values' and not equal(value,other[key])then return false end end
  for key in pairs(other)do if model[key]==nil then return false end end
  if type(other.values)~='table'then return false end
  for state,row in pairs(model.values)do
   local actual=other.values[state];if type(actual)~='table'then return false end
   for action,value in pairs(row)do
    local n=actual[action]
    if type(n)~='number' or n~=n or math.abs(n)==math.huge or math.abs(value-n)>1e-12*math.max(1,math.abs(value))then return false end
   end
   for action in pairs(actual)do if row[action]==nil then return false end end
  end
  for state in pairs(other.values)do if not model.values[state]then return false end end
 end
 for actor in pairs(stored)do if not expected[actor]then return false end end
 return true
end
function Q.learn(trace,episode,status,initial)
 if initial~=nil and type(initial)~='table'then return nil,'INVALID_INITIAL_MODELS'end
 local goal=episode and episode.versions and episode.versions.trainingGoal
 if initial then for _,actor in ipairs({'ninilite','wuyun'})do
  if type(initial[actor])~='table' or initial[actor].trainingGoal~=goal then return nil,'TRAINING_GOAL_MISMATCH'end
 end end
 -- Freeze exactly the persisted precision before reward reconstruction/update.
 local ok,source=pcall(function()return D.json.decode(D.json.encode({trace=trace,episode=episode},false,true),32)end)
 if not ok then return nil,'INVALID_SOURCE'end
 local rebuilt,why=require('Training.ResourceTraceReview').rebuild(source.trace,source.episode,status);if not rebuilt then return nil,why end
 if not rebuilt.trainable then return nil,'RESOURCE_TRACE_NOT_TRAINABLE'end
 local models={}
 for _,actor in ipairs({'ninilite','wuyun'})do
  local q,why
  if initial then q,why=Q.restore(initial[actor],actor);if not q then return nil,why end else q=Q.new(actor,goal)end
  for i,row in ipairs(rebuilt.actors[actor].transitions)do
   local original=source.trace.actors[actor].steps[i]
   local ok,why=q:update({state=original.state,nextState=original.nextState,nextActions=original.nextActions,action=row.action,reward=row.reward,duration=original.duration,done=row.done,sealed=true})
   if not ok then return nil,why end
  end
  models[actor]=q:snapshot()
 end
 return D.json.decode(D.json.encode(models,false,true),32)
end
return Q
