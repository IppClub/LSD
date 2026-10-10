-- Isolated online virtual training. Reuse duration-aware Q updates; do not
-- mutate deployed models or treat cancelled transitions as terminal losses.
local D=require('Dora');local Core=require('Training.QModel');local F=require('Training.YingzhaoFeatures');local A=require('Training.YingzhaoActions')
local Q={};Q.__index=Q
function Q.new(actor,version,actionVersion,rewardPolicy)
 version=version or F.version;assert(F.fields(version))
 local Rewards=require('Training.YingzhaoRewards')
 rewardPolicy=rewardPolicy or(version>=10 and Rewards.supportPolicy or Rewards.policy);assert(Rewards.supports(rewardPolicy)and(rewardPolicy~=Rewards.supportPolicy or version>=10))
 actionVersion=actionVersion or(version>=6 and 2 or 1);assert((actionVersion==1 or actionVersion==2)and(actionVersion~=2 or version>=6))
 assert(actor=='ninilite'or actor=='wuyun')
 local actions={'shoot@head','shoot@torso','shoot@flank','shoot@arms','shoot@forelegs','shoot@hindlegs','shoot@summon','fmove','bmove','idle'}
 if actor=='wuyun'then actions[#actions+1]='melee'end
 if actionVersion==2 then local skill=actor=='wuyun'and'wind'or'fire';actions[#actions+1]=skill..'@left';actions[#actions+1]=skill..'@right'end
 local legal={};for _,a in ipairs(actions)do legal[a]=true end
 return setmetatable({characterId=actor,rewardPolicy=rewardPolicy,featureVersion=version,actionVersion=actionVersion,actions=actions,legal=legal,alpha=.2,gamma=.95,values={},states=0,updates=0,maxStates=4096,stateKey=function(s)return F.key(s,version)end},Q)
end
Q.choose=Core.choose;Q.update=Core.update
function Q:snapshot()
 return D.json.decode(D.json.encode({algorithm='yingzhao-qlearning',schemaVersion=1,featureSchemaVersion=self.featureVersion,actionSetVersion=self.actionVersion,rewardPolicy=self.rewardPolicy,discountTimeUnit='seconds',characterId=self.characterId,alpha=self.alpha,gamma=self.gamma,values=self.values,updates=self.updates}),32)
end
local function finite(x)return type(x)=='number'and x==x and math.abs(x)<math.huge end
function Q.validate(m,actor)
 if type(m)~='table'or m.algorithm~='yingzhao-qlearning'or m.schemaVersion~=1 or not F.fields(m.featureSchemaVersion) or (m.actionSetVersion~=1 and m.actionSetVersion~=2)or(m.actionSetVersion==2 and m.featureSchemaVersion<6)or not require('Training.YingzhaoRewards').supports(m.rewardPolicy) or m.discountTimeUnit~='seconds'then return false,'INCOMPATIBLE_MODEL'end
 if m.rewardPolicy==require('Training.YingzhaoRewards').supportPolicy and m.featureSchemaVersion<10 then return false,'INCOMPATIBLE_SUPPORT_REWARD'end
 if (m.characterId~='ninilite'and m.characterId~='wuyun')or (actor and actor~=m.characterId)then return false,'INCOMPATIBLE_CHARACTER'end
 if not finite(m.alpha)or m.alpha<=0 or m.alpha>1 or not finite(m.gamma)or m.gamma<0 or m.gamma>1 or not finite(m.updates)or m.updates<1 or m.updates%1~=0 or m.updates>1000000000 then return false,'INVALID_PARAMETERS'end
 if type(m.values)~='table'then return false,'INVALID_Q_TABLE'end
 local legal=Q.new(m.characterId,m.featureSchemaVersion,m.actionSetVersion).legal;local states,entries=0,0
 for key,row in pairs(m.values)do
  if type(key)~='string'or #key>512 or type(row)~='table'then return false,'INVALID_Q_STATE'end
  local parts={};for v in (key..'|'):gmatch('(.-)|')do parts[#parts+1]=v end
  if #parts~=#F.fields(m.featureSchemaVersion) then return false,'INVALID_Q_STATE'end
  for i,name in ipairs(F.fields(m.featureSchemaVersion))do
   local v=parts[i]
   if v==''or v:find('%s')or not (' '..F.categories[name]..' '):find(' '..v..' ',1,true)then return false,'INVALID_Q_STATE'end
  end
  local count=0
  for action,value in pairs(row)do
   if not legal[action]or not finite(value)then return false,'INVALID_Q_VALUE'end
   count=count+1
  end
  if count==0 then return false,'EMPTY_Q_STATE'end
  states=states+1;entries=entries+count
  if states>4096 then return false,'STATE_LIMIT'end
 end
 if states==0 or entries>m.updates then return false,'INVALID_SUMMARY'end
 return true
end
function Q.restore(m,actor)
 local ok,why=Q.validate(m,actor);if not ok then return nil,why end
 local q=Q.new(m.characterId,m.featureSchemaVersion,m.actionSetVersion,m.rewardPolicy);q.alpha=m.alpha;q.gamma=m.gamma;q.updates=m.updates
 for key,row in pairs(m.values)do local copy={};for a,v in pairs(row)do copy[a]=v end;q.values[key]=copy;q.states=q.states+1 end
 return q
end
function Q.predict(m,state,available)
 local ok,why=Q.validate(m);if not ok then return nil,why end
 local q=Q.new(m.characterId,m.featureSchemaVersion,m.actionSetVersion);q.values=m.values
 return q:choose(state,available or function()return true end,false,0)
end
local function measure(b,actor,policy)
 -- Seal the current actual HP changes before valuing a decision boundary.
 -- Otherwise a later batch flush can put damage inside an already sealed interval.
 require('Training.YingzhaoVitals').flush(b.bossTrace.vitals)
 local w=require('Training.YingzhaoRewards').weights;local value=0
 for _,hit in ipairs(b.bossTrace.hits)do if hit.source==actor then value=value+hit.armorDamage*w.armor+hit.healthDamage*w.health end end
 for _,event in pairs(b.supplies.ledger.events)do if event.owner==actor then value=value-event.cost*w.cost end end
 for _,event in ipairs(b.bossTrace.vitals.events)do value=value-event.damage*(event.actor==actor and w.ownDamage or w.allyDamage)end
 if policy==require('Training.YingzhaoRewards').policy then value=value-require('Training.YingzhaoRewards').shieldCost({physicalShield=b.physicalShield})end
 local boundary=b.supportAccountBook and b.supportAccountBook:sample(D.App.runningTime)
 if policy==require('Training.YingzhaoRewards').supportPolicy and b.physicalShield then
  assert(b.supportAccountBook and boundary,'New support reward requires actual battle accounting')
  local cost=assert(require('Training.YingzhaoSupportAccounting').interval(b.supportAccountBook.record,1,boundary))
  value=value-cost.goldSpent*w.cost-cost.machineDamage*w.machineDamage
 end
 return value,boundary
end
function Q.attach(b,actor,options)
 options=options or {};assert(b.phase=='ready'and b.supplies and b.supplies.isVirtual and not b.demonstrator and not (b.yingzhaoCandidates and b.yingzhaoCandidates[actor])and not b.yingzhaoQTraining)
 local a;for _,arena in ipairs(b.learners)do if arena.character.id==actor then a=arena end end;assert(a)
 local q=options.model and assert(Q.restore(options.model,actor))or Q.new(actor)
 assert(not b.physicalShield or q.rewardPolicy==require('Training.YingzhaoRewards').policy or q.rewardPolicy==require('Training.YingzhaoRewards').supportPolicy,'Legacy reward requires an unshielded environment; start a new shield training candidate')
 local session={actor=actor,q=q,base=options.model and q:snapshot()or nil,transitions={},discarded=0};b.yingzhaoQTraining=session
 a.continuousDecisions=true
 local pending;local first=true;local update=a.update;local nextDecision=0
 local function legal()
  local list={};for _,label in ipairs(session.q.actions)do
   if A.available(b,a,label,session.q.actionVersion)then list[#list+1]=label end
  end;return list
 end
 local function seal(done,nextState,nextActions)
  local w=require('Training.YingzhaoRewards').weights
  local value,supportEnd=measure(b,actor,session.q.rewardPolicy)
  local reward=value-pending.value-pending.deployment+(done and (b.phase=='won'and w.won or w.failed)or 0)
  local ended=D.App.runningTime
  local t={sourceStep=pending.step,started=pending.started,ended=ended,deployment=pending.deployment,state=pending.state,action=pending.action,reward=reward,duration=math.max(.001,ended-pending.started),nextState=nextState,nextActions=nextActions,done=done,sealed=true}
  if pending.supportStart then t.supportBoundaryVersion=1;t.supportStart=pending.supportStart;t.supportEnd=supportEnd end
  -- New action sets learn from the exact persisted transition representation.
  -- Fractional armor-reduced skill damage must replay identically after JSON.
  if session.q.actionVersion==2 then t=D.json.decode(D.json.encode(t,false,true),32)end
  local ok,why=session.q:update(t);assert(ok,why);session.transitions[#session.transitions+1]=t;pending=nil
 end
 a.update=function(self,...)
  self.mode='demo';self.recorder.active=false
  if require('Combat.Formation').owns(self,b,D.App.runningTime)then if pending then session.discarded=session.discarded+1;pending=nil end;return update(self,...)end
  local now=D.App.runningTime
  if b.phase=='playing'and now>=nextDecision and not self:isAttacking()and not b.bossCombat:pendingActor(actor)then
   local choices=legal();local state=b.observeYingzhao(self.student)
   if #choices>0 then
    if pending and now-pending.started>=.3 then seal(false,state,choices)end
    if not pending then
     local allowed={};for _,label in ipairs(choices)do allowed[label]=true end
     state=b.observeYingzhao(self.student)
     local action=session.q:choose(state,function(label)return allowed[label]end,true,options.epsilon or .2,options.random or math.random)
     local value,supportStart=measure(b,actor,session.q.rewardPolicy);local started=D.App.runningTime;local stepCount=#b.bossTrace.steps
     local ok=A.request(b,self,action,'q-learning',session.q.actionVersion)
     if ok and #b.bossTrace.steps>stepCount then
      local deploy=0;if first then for _,line in ipairs(b.supplies.ledger.quote.lines)do if line.actor==actor then deploy=deploy+line.deploy end end;first=false end
      pending={step=stepCount+1,state=state,action=action,value=value,started=started,deployment=deploy,supportStart=supportStart}
     end
    end
   end
   nextDecision=now+.3
  end
  return update(self,...)
 end
 local node=D.Node();node:addTo(b.world);node:schedule(function()
  if session.closed then return true end
  if b.phase=='won'or b.phase=='failed'or b.phase=='aborted'then
   if pending then if b.phase~='aborted'then seal(true,nil,nil)else session.discarded=session.discarded+1;pending=nil end end
   session.closed=true;session.model=session.q:snapshot()
   b.bossTrace.resources=b.supplies:evidence()
   session.combat=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',rewardPolicy=session.q.rewardPolicy,episode=b.bossTrace.resources.attempt,versions={resources=1,bigYingzhao=1},resources=b.bossTrace.resources,boss=b.bossTrace}),32)
   return true
  end
  return false
 end)
 return session
end
return Q
