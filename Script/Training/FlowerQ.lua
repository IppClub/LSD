-- Flower-domain Q tables. Only verified online traces may enter batch learning.
local Core=require('Training.QModel');local F=require('Training.FlowerFeatures');local Names=require('Training.FlowerPolicy').names
local Q={};Q.__index=Q
Q.rewardPolicy='flower-contribution-v1'
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
local function encode(state,version)
 if not F.validate(state) or state.featureSchemaVersion~=6 then return nil,'INVALID_FLOWER_STATE'end
 local names=version==7 and require('Training.FlowerPolicy').names7 or Names
 if version==7 then
  for name,words in pairs(require('Training.FlowerTacticsFeatures').categories)do
   local valid=false;for word in words:gmatch('%S+')do if state[name]==word then valid=true;break end end
   if not valid then return nil,'INVALID_TACTICAL_STATE'end
  end
 end
 local values={};for _,name in ipairs(names)do values[#values+1]=tostring(state[name])end;return table.concat(values,'|')
end
function Q.key(state,version)
 version=version or 6
 if version~=6 and version~=7 then return nil,'INCOMPATIBLE_FEATURE_VERSION'end
 if version==7 then local why;state,why=require('Training.FlowerTacticsFeatures').project(state);if not state then return nil,why end end
 return encode(state,version)
end
function Q.new(actor,version)
 version=version or 7;assert(version==6 or version==7,'INCOMPATIBLE_FLOWER_Q')
 assert(actor=='ninilite' or actor=='wuyun','Invalid flower learner')
 local actions={'idle','fmove','bmove','shoot'};if actor=='wuyun'then actions[#actions+1]='melee'end
 for _,part in ipairs({'flower-head','flower-core','petal-left','petal-right','roots'})do actions[#actions+1]='shoot@'..part end
 local legal={};for _,action in ipairs(actions)do legal[action]=true end
 return setmetatable({characterId=actor,actions=actions,legal=legal,featureSchemaVersion=version,stateKey=function(state)return Q.key(state,version)end,alpha=.2,gamma=.95,values={},states=0,updates=0,maxStates=4096},Q)
end
Q.choose=Core.choose
function Q:snapshot()
 local values={};for key,row in pairs(self.values)do values[key]={};for action,value in pairs(row)do values[key][action]=value end end
 return {algorithm='flower-qlearning',schemaVersion=1,featureSchemaVersion=self.featureSchemaVersion,actionSetVersion=5,partSetVersion=2,traceSchemaVersion=2,enemyAsset='dahuayao',rewardPolicy=Q.rewardPolicy,discountTimeUnit='seconds',characterId=self.characterId,alpha=self.alpha,gamma=self.gamma,updates=self.updates,values=values}
end
function Q.restore(model,actor)
 local function restore()
  assert(type(model)=='table' and model.algorithm=='flower-qlearning' and model.schemaVersion==1 and (model.featureSchemaVersion==6 or model.featureSchemaVersion==7) and model.actionSetVersion==5 and model.partSetVersion==2 and model.traceSchemaVersion==2 and model.enemyAsset=='dahuayao' and model.rewardPolicy==Q.rewardPolicy and model.discountTimeUnit=='seconds','INCOMPATIBLE_FLOWER_Q')
  local names=model.featureSchemaVersion==7 and require('Training.FlowerPolicy').names7 or Names
  local q=Q.new(model.characterId,model.featureSchemaVersion);assert(not actor or actor==model.characterId,'WRONG_ACTOR')
  assert(finite(model.alpha) and model.alpha>0 and model.alpha<=1 and finite(model.gamma) and model.gamma>=0 and model.gamma<=1 and finite(model.updates) and model.updates>=1 and model.updates%1==0 and model.updates<=1000000000 and type(model.values)=='table','INVALID_Q_PARAMETERS')
  q.alpha=model.alpha;q.gamma=model.gamma;q.updates=model.updates;local entries=0
  for key,row in pairs(model.values)do
   assert(type(key)=='string' and #key<=512 and type(row)=='table','INVALID_Q_ROW')
   local parts={};for word in (key..'|'):gmatch('(.-)|')do parts[#parts+1]=word end;assert(#parts==#names,'INVALID_Q_KEY')
   local state={featureSchemaVersion=6,partSetVersion=2,enemyAsset='dahuayao'}
   for i,name in ipairs(names)do local word=parts[i];if name=='phasePending' or name=='confused' or name=='poisoned' or name=='virus'then assert(word=='true' or word=='false');state[name]=word=='true' else state[name]=word end end
   assert(encode(state,model.featureSchemaVersion)==key,'INVALID_Q_STATE');local count=0;q.values[key]={}
   for action,value in pairs(row)do assert(q.legal[action] and finite(value),'INVALID_Q_VALUE');q.values[key][action]=value;count=count+1 end
   assert(count>0,'EMPTY_Q_ROW');entries=entries+count;q.states=q.states+1;assert(q.states<=q.maxStates,'STATE_LIMIT')
  end
  assert(q.states>0 and entries<=q.updates,'INVALID_Q_SUMMARY');return q
 end
 local ok,result=pcall(restore);if not ok then return nil,tostring(result)end;return result
end
function Q.learn(trace,episode,status,initial,version)
 if type(episode)=='table' and episode.versions and episode.versions.resources then return nil,'RESOURCE_REWARD_POLICY_REQUIRED'end
 version=version or (type(initial)=='table' and type(initial.ninilite)=='table' and initial.ninilite.featureSchemaVersion) or 6
 if version~=6 and version~=7 then return nil,'INCOMPATIBLE_FEATURE_VERSION'end
 -- Learning and later reconstruction use identical persisted numeric values,
 -- including duration-dependent discounting, not pre-serialization doubles.
 local D=require('Dora')
 local ok,frozen=pcall(function()return D.json.decode(D.json.encode({trace=trace,episode=episode,initial=initial},false,true),32)end)
 if not ok or type(frozen)~='table'then return nil,'INVALID_Q_EVIDENCE'end
 trace=frozen.trace;episode=frozen.episode;initial=frozen.initial
 if initial~=nil then
  if type(initial)~='table' or not initial.ninilite or not initial.wuyun then return nil,'INCOMPLETE_INITIAL_MODELS'end
  if initial.ninilite.featureSchemaVersion~=initial.wuyun.featureSchemaVersion then return nil,'MIXED_FEATURE_VERSIONS'end
  for id in pairs(initial)do if id~='ninilite' and id~='wuyun'then return nil,'INVALID_INITIAL_ACTOR'end end
 end
 local rebuilt,why=require('Training.FlowerTraceReview').rebuild(trace,episode,status);if not rebuilt then return nil,why end
 local result={}
 for _,actor in ipairs({'ninilite','wuyun'})do
  local q,why
  if initial and initial[actor]then
   q,why=Q.restore(initial[actor],actor);if not q then return nil,why end
   if q.featureSchemaVersion~=version then
    if q.featureSchemaVersion~=6 or version~=7 then return nil,'FEATURE_DOWNGRADE_REJECTED'end
    q=Q.new(actor,7) -- A new state space; old values stay in the immutable parent.
   end
  else q=Q.new(actor,version)end
  for i,row in ipairs(trace.actors[actor].steps)do
   local ok,why=Core.update(q,{state=row.state,action=row.action,nextState=row.nextState,nextActions=row.nextActions,duration=row.duration,reward=rebuilt.actors[actor][i].reward,done=row.done,sealed=true})
   if not ok then return nil,why end
  end
  result[actor]=q:snapshot()
 end
 return D.json.decode(D.json.encode(result,false,true),32)
end
return Q
