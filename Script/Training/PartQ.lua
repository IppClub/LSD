-- Target-selection Q stage. Shares the duration-aware updater, not combat actions.
local Core=require('Training.QModel');local F=require('Training.PartFeatures');local R=require('Training.Recorder')
local Q={};Q.__index=Q
Q.rewardPolicy='part-emp-v1'
function Q.key(s)
 local ok,why=R.validateFeatures(s,4);if not ok then return nil,why end
 local values={R.distanceBand(s.distance),s.facing}
 for _,name in ipairs(F.names)do values[#values+1]=F.value(s,name)end
 return table.concat(values,'|')
end
function Q.new(characterId)
 assert(require('Training.Characters')[characterId],'Unknown character')
 local actions={};local legal={}
 for _,name in ipairs(F.names)do local a=name:sub(6);actions[#actions+1]=a;legal[a]=true end
 return setmetatable({characterId=characterId,actions=actions,legal=legal,stateKey=Q.key,alpha=.2,gamma=.95,values={},states=0,updates=0,maxStates=4096},Q)
end
Q.choose=Core.choose;Q.update=Core.update
function Q:snapshot()
 local values={};for k,row in pairs(self.values)do values[k]={};for a,v in pairs(row)do values[k][a]=v end end
 return {algorithm='part-qlearning',schemaVersion=1,featureSchemaVersion=4,partSetVersion=1,weapon='emp',enemyAsset='dataotie',rewardPolicy=Q.rewardPolicy,discountTimeUnit='seconds',characterId=self.characterId,alpha=self.alpha,gamma=self.gamma,updates=self.updates,values=values}
end
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
function Q.compatible(m)
 return type(m)=='table' and m.algorithm=='part-qlearning' and m.schemaVersion==1 and m.featureSchemaVersion==4 and m.partSetVersion==1 and m.weapon=='emp' and m.enemyAsset=='dataotie' and m.rewardPolicy==Q.rewardPolicy and m.discountTimeUnit=='seconds'
end
local function validate(m,characterId)
 if not Q.compatible(m)then return false,'INCOMPATIBLE_PART_Q'end
 if not require('Training.Characters')[m.characterId] or characterId and m.characterId~=characterId then return false,'INCOMPATIBLE_CHARACTER'end
 if not finite(m.alpha) or m.alpha<=0 or m.alpha>1 or not finite(m.gamma) or m.gamma<0 or m.gamma>1 or not finite(m.updates) or m.updates<1 or m.updates%1~=0 or m.updates>1000000000 or type(m.values)~='table'then return false,'INVALID_PART_Q'end
 local states,entries=0,0
 for key,row in pairs(m.values)do
  if type(key)~='string' or #key>256 or type(row)~='table'then return false,'INVALID_STATE'end
  local fields={};for word in (key..'|'):gmatch('(.-)|')do fields[#fields+1]=word end
  if #fields~=9 then return false,'INVALID_STATE'end
  local state={distance=({near=0,mid=500,far=800})[fields[1]],facing=fields[2],enemyAction='idle',attackReady='yes'}
  for i,name in ipairs(F.names)do state[name]=fields[i+2]end
  if Q.key(state)~=key then return false,'INVALID_STATE'end
  local count=0;for action,value in pairs(row)do if not F.parts[action] or not finite(value)then return false,'INVALID_VALUE'end;count=count+1 end
  if count==0 then return false,'EMPTY_STATE'end
  states=states+1;entries=entries+count;if states>4096 then return false,'STATE_LIMIT'end
 end
 if states==0 or entries>m.updates then return false,'INVALID_SUMMARY'end
 return true
end
function Q.validate(m,characterId)
 local ok,result,why=pcall(validate,m,characterId);if not ok then return false,'MALFORMED_PART_Q'end;return result,why
end
function Q.restore(m,characterId)
 local ok,why=Q.validate(m,characterId);if not ok then return nil,why end
 local q=Q.new(m.characterId);q.alpha=m.alpha;q.gamma=m.gamma;q.updates=m.updates
 for key,row in pairs(m.values)do q.values[key]={};q.states=q.states+1;for a,v in pairs(row)do q.values[key][a]=v end end
 return q
end
function Q.predict(m,state,available)
 local ok,why=Q.validate(m);if not ok then return nil,why end
 local view=Q.new(m.characterId);view.values=m.values
 return view:choose(state,available,false,0)
end
return Q
