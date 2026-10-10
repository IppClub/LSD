-- Internal candidate archive. Replays combat and source-linked Q rewards.
-- Public adoption remains unavailable until evaluation and ancestry are complete.
local D=require('Dora');local Q=require('Training.YingzhaoQ');local I=require('Training.FlowerIdentity')
local S={maxBytes=8*1024*1024};local busy=false
local function open()return D.DB:existDB('lsd')and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoQCandidates(id INTEGER PRIMARY KEY AUTOINCREMENT,actor TEXT NOT NULL,episode TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0 end
function S.validate(e)
 if type(e)~='table'or e.schemaVersion~=2 or e.kind~='yingzhao-q-candidate'or type(e.episode)~='string'or #e.episode<1 or #e.episode>128 or not e.episode:match('^[%w%-_:%.]+$')then return false,'INVALID_SOURCE'end
 local valid,why=Q.validate(e.model);if not valid then return false,why end
 if type(e.transitions)~='table'or #e.transitions<1 or #e.transitions>1500 then return false,'INVALID_TRANSITIONS'end
 local count=0;for k in pairs(e.transitions)do if type(k)~='number'or k%1~=0 or k<1 or k>#e.transitions then return false,'INVALID_TRANSITIONS'end;count=count+1 end
 if count~=#e.transitions then return false,'INVALID_TRANSITIONS'end
 local combatOK,combatWhy=require('Enemy.BigYingzhaoEvidence').validateEvaluation(e.combat)
 if not combatOK then return false,combatWhy end
 if not require('Training.YingzhaoVitals').validate(e.combat.boss.vitals)then return false,'INVALID_BOSS_VITALS'end
 if e.combat.rewardPolicy~=nil and e.combat.rewardPolicy~=e.model.rewardPolicy or e.model.rewardPolicy==require('Training.YingzhaoRewards').supportPolicy and e.combat.rewardPolicy~=e.model.rewardPolicy then return false,'REWARD_POLICY_SOURCE_MISMATCH'end
 local actor=e.model.characterId;local trace=e.combat.boss;local w=require('Training.YingzhaoRewards').weights
 local firstStep;for i,step in ipairs(trace.steps)do if step.actor==actor and step.origin=='q-learning'then firstStep=i;break end end
 local deployment=0;for _,line in ipairs(e.combat.resources.quote.lines)do if line.actor==actor then deployment=deployment+line.deploy end end
 local previousEnd=-math.huge;local seen={}
 local function finite(x)return type(x)=='number'and x==x and math.abs(x)<math.huge end
 local q
 if e.base then q,why=Q.restore(e.base,e.model.characterId);if not q then return false,why end else q=Q.new(e.model.characterId,e.model.featureSchemaVersion,e.model.actionSetVersion,e.model.rewardPolicy)end
 for i,t in ipairs(e.transitions)do
  if type(t)~='table'or (t.done and i~=#e.transitions)then return false,'INVALID_TRANSITION_ORDER'end
  local step=trace.steps[t.sourceStep or false]
  if not step or seen[t.sourceStep]or step.actor~=actor or step.origin~='q-learning'then return false,'Q_ACTION_SOURCE_MISMATCH'end
  seen[t.sourceStep]=true
  local physical,part,face=require('Training.YingzhaoActions').decode(t.action,e.model.actionSetVersion)
  local expected=physical=='laser'and 'shoot'or physical
  if step.action~=expected or (part and (not step.aim or step.aim.intent~=part))then return false,'Q_ACTION_SOURCE_MISMATCH'end
  if not finite(t.started)or not finite(t.ended)or t.started<previousEnd or t.ended<=t.started or math.abs(t.duration-math.max(.001,t.ended-t.started))>1e-6 or math.abs(step.started-t.started)>.1 then return false,'Q_INTERVAL_MISMATCH'end
  if physical=='fire'or physical=='wind'then
   if not step.skill or step.skill.direction~=(face and 1 or -1)then return false,'Q_SKILL_DIRECTION_MISMATCH'end
   if t.ended<step.ended then return false,'Q_SKILL_INCOMPLETE'end
   local F=require('Training.YingzhaoFeatures')
   if not F.validate(t.state)or t.state.featureSchemaVersion<6 or t.state.skillState~='ready'or F.key(t.state,e.model.featureSchemaVersion)~=F.key(step.before,e.model.featureSchemaVersion)then return false,'Q_SKILL_OBSERVATION_MISMATCH'end
  end
  if e.model.actionSetVersion==2 and type(t.nextActions)=='table'then
   for _,label in ipairs(t.nextActions)do
    local action=require('Training.YingzhaoActions').decode(label,2)
    if (action=='fire'or action=='wind')and(type(t.nextState)~='table'or t.nextState.skillState~='ready')then return false,'Q_SKILL_AVAILABILITY_MISMATCH'end
   end
  end
  previousEnd=t.ended
  if not t.state or math.abs((t.state.at or -1)-t.started)>.01 then return false,'Q_INTERVAL_MISMATCH'end
  if not t.done and (not t.nextState or math.abs((t.nextState.at or -1)-t.ended)>.01)then return false,'Q_INTERVAL_MISMATCH'end
  if t.supportBoundaryVersion~=nil or t.supportStart~=nil or t.supportEnd~=nil then
   local account=trace.supportAccounting;local A=require('Training.YingzhaoSupportAccounting')
   local interval=account and A.interval(account,t.supportStart,t.supportEnd)
   if t.supportBoundaryVersion~=1 or not interval then return false,'Q_SUPPORT_BOUNDARY_MISMATCH'end
   local first,last=account.samples[t.supportStart],account.samples[t.supportEnd]
   if math.abs(first.at-t.started)>.01 or last.at>t.ended+.01 or (not t.done and math.abs(last.at-t.ended)>.01)or (t.done and t.supportEnd~=#account.samples)then return false,'Q_SUPPORT_BOUNDARY_MISMATCH'end
  end
  local reward=0
  for _,hit in ipairs(trace.hits)do
   local inInterval=trace.hitTimeVersion==1 and hit.at>t.started and hit.at<=t.ended
   if hit.source==actor and (trace.hitTimeVersion==1 and inInterval or trace.hitTimeVersion==nil and hit.step==t.sourceStep)then reward=reward+hit.armorDamage*w.armor+hit.healthDamage*w.health end
  end
  for _,event in pairs(e.combat.resources.events)do if event.step==t.sourceStep and event.owner==actor then reward=reward-event.cost*w.cost end end
  for _,event in ipairs(trace.vitals.events)do if event.at>t.started and event.at<=t.ended then reward=reward-event.damage*(event.actor==actor and w.ownDamage or w.allyDamage)end end
  local Rewards=require('Training.YingzhaoRewards')
  if e.model.rewardPolicy==Rewards.supportPolicy then
   if trace.physicalShield and t.supportBoundaryVersion~=1 then return false,'MISSING_Q_SUPPORT_BOUNDARIES'end
   local cost,why=Rewards.supportCost(trace,t.supportStart,t.supportEnd);if not cost then return false,why end
   reward=reward-cost.goldSpent*w.cost-cost.machineDamage*w.machineDamage
  elseif e.model.rewardPolicy==Rewards.policy then reward=reward-Rewards.shieldCost(trace,t.started,t.ended)
  elseif trace.physicalShield then return false,'INCOMPATIBLE_PROTECTION_REWARD'end
  local deploy=t.sourceStep==firstStep and deployment or 0
  if t.deployment~=deploy then return false,'Q_DEPLOYMENT_MISMATCH'end
  reward=reward-deploy
  if t.done then
   if trace.status~='won'and trace.status~='failed'then return false,'Q_TERMINAL_MISMATCH'end
   reward=reward+(trace.status=='won'and w.won or w.failed)
  end
  if not finite(t.reward)or math.abs(t.reward-reward)>1e-6 then return false,'Q_REWARD_SOURCE_MISMATCH'end
  local ok,reason=q:update(t);if not ok then return false,reason end
 end
 if not I.equal(q:snapshot(),e.model)then return false,'SOURCE_MODEL_MISMATCH'end
 return true
end
local function decode(payload)
 if type(payload)~='string'or #payload>S.maxBytes then return nil,'SOURCE_TOO_LARGE'end
 local ok,e,valid,why=pcall(function()local e=D.json.decode(payload,32);local valid,why=S.validate(e);return e,valid,why end)
 if not ok then return nil,'INVALID_SOURCE'end;if not valid then return nil,why end;return e
end
-- Follow immutable prior rows in decreasing id order. Validate every ancestor
-- on read; a valid leaf must not hide corrupted earlier training evidence.
local function ancestry(source,childId)
 local depth=0
 while source.base do
  depth=depth+1;if depth>1024 then return false,'ANCESTRY_LIMIT'end
  local id=source.parentId
  if type(id)~='number'or id%1~=0 or id<1 or id>=childId then return false,'INVALID_PARENT'end
  local rows=D.DB:query('SELECT actor,payload FROM lsd.Game0YingzhaoQCandidates WHERE id=?',{id})
  if not rows then return false,'READ_FAILED'end;if not rows[1]then return false,'MISSING_PARENT'end
  local parent,why=decode(rows[1][2]);if not parent then return false,why end
  if rows[1][1]~=parent.model.characterId or parent.model.characterId~=source.model.characterId or parent.episode==source.episode or not I.equal(parent.model,source.base)then return false,'PARENT_MODEL_MISMATCH'end
  source=parent;childId=id
 end
 if source.parentId~=nil then return false,'UNEXPECTED_PARENT'end
 return true
end
function S.loadAsync(id)
 if type(id)~='number'or id%1~=0 or id<1 then return nil,'INVALID_SOURCE_ID'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT actor,payload FROM lsd.Game0YingzhaoQCandidates WHERE id=?',{id})
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NO_CANDIDATE'end
 local source,why=decode(rows[1][2]);if not source then return nil,why end
 if rows[1][1]~=source.model.characterId then return nil,'INCOMPATIBLE_CHARACTER'end
 local ok,why=ancestry(source,id);if not ok then return nil,why end
 return {id=id,model=source.model,source=source}
end
function S.saveAsync(e)
 if busy then return false,'BUSY'end;busy=true
 local ok,accepted,why,id=pcall(function()
  local payload=D.json.encode(e,false,true);local source,why=decode(payload);if not source then return false,why end
  if not open()then return false,'WRITE_FAILED'end
  local lineage,why=ancestry(source,math.huge);if not lineage then return false,why end
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoQCandidates WHERE episode=?',{source.episode})
  if not rows then return false,'READ_FAILED'end
  if rows[1]then local old=decode(rows[1][2]);if not old or not I.equal(old,source)then return false,'SOURCE_CONFLICT'end;return true,'ALREADY_RECORDED',rows[1][1]end
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0YingzhaoQCandidates(actor,episode,payload) VALUES(?,?,?)',{{source.model.characterId,source.episode,payload}}}})then return false,'WRITE_FAILED'end
  rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoQCandidates WHERE episode=?',{source.episode})
  if not rows or not rows[1]then return false,'READ_FAILED'end;return true,nil,rows[1][1]
 end)
 busy=false;if not ok then return false,'INVALID_SOURCE'end;return accepted,why,id
end
function S.loadLatestAsync(actor)
 if actor~='ninilite'and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoQCandidates WHERE actor=? ORDER BY id DESC LIMIT 1',{actor})
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NO_CANDIDATE'end
 return S.loadAsync(rows[1][1])
end
return S
