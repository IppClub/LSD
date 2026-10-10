-- Sparse, duration-aware Q learning. Does not use the engine's legacy
-- same-state update API. Exploration is explicitly restricted to training.
local Recorder=require('Training.Recorder');local Features=require('Training.CombatFeatures')
local Q={};Q.__index=Q
local function finite(x)return type(x)=='number' and x==x and math.abs(x)<math.huge end
function Q.key(state)
 local ok,why=Recorder.validateFeatures(state);if not ok then return nil,why end
 local values={Recorder.distanceBand(state.distance),state.facing,state.enemyAction,state.attackReady}
 for _,name in ipairs(Features.names)do values[#values+1]=Features.value(state,name)end
 return table.concat(values,'|')
end
function Q.new(options)
 local o=options or {};local character=require('Training.Characters')[o.characterId]
 assert(character,'Unknown training character')
 local actions={};local legal={}
 for _,name in ipairs(o.actions or character.actions)do assert(character.legal[name] and not legal[name],'Invalid Q action');actions[#actions+1]=name;legal[name]=true end
 assert(#actions>0)
 local alpha,gamma=o.alpha or .2,o.gamma or .95
 assert(finite(alpha) and alpha>0 and alpha<=1 and finite(gamma) and gamma>=0 and gamma<=1)
 return setmetatable({characterId=character.id,actions=actions,legal=legal,alpha=alpha,gamma=gamma,values={},states=0,updates=0,maxStates=4096},Q)
end
function Q:choose(state,available,training,epsilon,random)
 local key,why=(self.stateKey or Q.key)(state);if not key then return nil,why end
 epsilon=epsilon or 0;assert(finite(epsilon) and epsilon>=0 and epsilon<=1)
 if not training and epsilon~=0 then return nil,'EXPLORATION_REQUIRES_TRAINING' end
 local eligible={};for _,a in ipairs(self.actions)do if available(a)then eligible[#eligible+1]=a end end
 if #eligible==0 then return nil,'ACTION_UNAVAILABLE' end
 if training and epsilon>0 then
  assert(random,'Explicit RNG required for exploration')
  local roll=random();assert(finite(roll) and roll>=0 and roll<1)
  if roll<epsilon then local pick=random();assert(finite(pick) and pick>=0 and pick<1);return eligible[math.floor(pick*#eligible)+1],'EXPLORE'end
 end
 local row=self.values[key];if not row and not training then return nil,'UNSEEN_STATE'end
 local best,value
 for _,a in ipairs(eligible)do
  local v=row and row[a]
  if v==nil and training then v=0 end
  if v~=nil and (value==nil or v>value)then best,value=a,v end
 end
 return best,best and 'Q_POLICY' or 'UNSEEN_ACTIONS'
end
function Q:update(transition)
 local t=transition
 if type(t)~='table'then return false,'INVALID_TRANSITION'end
 if t.truncated then return false,'TRUNCATED_TRANSITION'end
 if t.sealed~=true or type(t.done)~='boolean' or not finite(t.reward) or not finite(t.duration) or t.duration<=0 or not self.legal[t.action]then return false,'INVALID_TRANSITION'end
 local key,why=(self.stateKey or Q.key)(t.state);if not key then return false,why end
 local future=0
 if not t.done then
  local nextKey,err=(self.stateKey or Q.key)(t.nextState);if not nextKey then return false,err end
  if type(t.nextActions)~='table'then return false,'MISSING_LEGAL_ACTIONS'end
  -- A nonterminal decision must have a legal successor action (including idle).
  -- Empty or sparse masks must not silently turn a live state into a terminal.
  local count=0;for k in pairs(t.nextActions)do
   if type(k)~='number' or k%1~=0 or k<1 or k>#t.nextActions then return false,'INVALID_NEXT_ACTIONS'end
   count=count+1
  end
  if count==0 or count~=#t.nextActions or count>#self.actions then return false,'INVALID_NEXT_ACTIONS'end
  local row=self.values[nextKey] or {};local best;local seen={}
  for _,a in ipairs(t.nextActions)do
   if not self.legal[a] or seen[a]then return false,'INVALID_NEXT_ACTION'end
   seen[a]=true
   local v=row[a] or 0;if best==nil or v>best then best=v end
  end
  future=best or 0
 end
 local row=self.values[key]
 if not row then if self.states>=self.maxStates then return false,'STATE_LIMIT'end;row={} end
 local old=row[t.action] or 0
 local value=old+self.alpha*(t.reward+(t.done and 0 or self.gamma^t.duration*future)-old)
 if not finite(value)then return false,'VALUE_OVERFLOW'end
 if not self.values[key]then self.values[key]=row;self.states=self.states+1 end
 row[t.action]=value;self.updates=self.updates+1;return true,value
end
function Q:snapshot()
 local values={};for state,row in pairs(self.values)do local copy={};for a,v in pairs(row)do copy[a]=v end;values[state]=copy end
 local actions={};for i,a in ipairs(self.actions)do actions[i]=a end
 return {algorithm='qlearning',schemaVersion=1,featureSchemaVersion=3,actionSetVersion=1,rewardPolicy=self.rewardPolicy,discountTimeUnit='seconds',characterId=self.characterId,alpha=self.alpha,gamma=self.gamma,actions=actions,values=values,updates=self.updates}
end
-- Serialized Q tables are data, never executable policies. Validate all keys
-- and action values before allowing inference or restoring a training session.
local function array(t,limit)
 if type(t)~='table' or #t<1 or #t>limit then return false end
 local count=0;for k in pairs(t)do
  if type(k)~='number' or k%1~=0 or k<1 or k>#t then return false end
  count=count+1
 end
 return count==#t
end
function Q.compatible(m)
 return type(m)=='table' and m.algorithm=='qlearning' and m.schemaVersion==1 and m.featureSchemaVersion==3
  and m.actionSetVersion==1 and m.rewardPolicy=='unarmored-v1' and m.discountTimeUnit=='seconds'
end
function Q.validate(m,characterId,legalActions)
 if not Q.compatible(m)then return false,'INCOMPATIBLE_MODEL'end
 if m.trainingRunId~=nil and (type(m.trainingRunId)~='string' or #m.trainingRunId>128 or not m.trainingRunId:match('^q%-[%w%-]+$'))then return false,'INVALID_TRACE_ID'end
 local character=require('Training.Characters')[m.characterId]
 if not character or (characterId and m.characterId~=characterId)then return false,'INCOMPATIBLE_CHARACTER'end
 if not finite(m.alpha) or m.alpha<=0 or m.alpha>1 or not finite(m.gamma) or m.gamma<0 or m.gamma>1 then return false,'INVALID_PARAMETERS'end
 if not finite(m.updates) or m.updates%1~=0 or m.updates<1 or m.updates>1000000000 then return false,'INVALID_SUMMARY'end
 if not array(m.actions,#character.actions) or type(m.values)~='table'then return false,'INVALID_Q_TABLE'end
 local legal={};for _,a in ipairs(m.actions)do
  if not character.legal[a] or legal[a] or (legalActions and not legalActions[a])then return false,'UNKNOWN_ACTION'end
  legal[a]=true
 end
 local states=0;local entries=0
 for key,row in pairs(m.values)do
  if type(key)~='string' or #key>256 or type(row)~='table'then return false,'INVALID_Q_STATE'end
  local parts={};for v in (key..'|'):gmatch('(.-)|')do parts[#parts+1]=v end
  if #parts~=9 then return false,'INVALID_Q_STATE'end
  local distance=({near=0,mid=400,far=700})[parts[1]]
  local state={distance=distance,facing=parts[2],enemyAction=parts[3],attackReady=parts[4]}
  for i,name in ipairs(Features.names)do state[name]=parts[4+i]end
  if Q.key(state)~=key then return false,'INVALID_Q_STATE'end
  local size=0
  for a,v in pairs(row)do
   if not legal[a] or not finite(v)then return false,'INVALID_Q_VALUE'end
   size=size+1
  end
  if size==0 then return false,'EMPTY_Q_STATE'end
  entries=entries+size;states=states+1
  if states>4096 then return false,'STATE_LIMIT'end
 end
 if states==0 or entries>m.updates then return false,'INVALID_SUMMARY'end
 return true
end
function Q.restore(snapshot,characterId)
 local ok,why=Q.validate(snapshot,characterId);if not ok then return nil,why end
 local q=Q.new(snapshot);q.rewardPolicy=snapshot.rewardPolicy;q.updates=snapshot.updates
 for key,row in pairs(snapshot.values)do
  local copy={};for a,v in pairs(row)do copy[a]=v end
  q.values[key]=copy;q.states=q.states+1
 end
 return q
end
function Q.predict(snapshot,state,available)
 local ok,why=Q.validate(snapshot);if not ok then return nil,why end
 -- Read-only view: no copies of the full Q table on each decision, and no
 -- update/exploration call. choose only reads actions and values in this mode.
 local view=setmetatable({actions=snapshot.actions,values=snapshot.values},Q)
 return view:choose(state,available or function()return true end,false,0)
end
return Q
