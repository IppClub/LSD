local D=require('Dora');local S={};local busy=false;local equal=require('Training.FlowerIdentity').equal
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function S.validate(r)
 if type(r)~='table'or r.schemaVersion~=1 or r.trainable~=false or r.cancelled or not ({['mentor-range-fire-wind-gather-v1']=true,['mentor-range-fire-wind-gather-v2']=true,['mentor-range-fire-wind-gather-v3']=true,['mentor-range-fire-wind-gather-v4']=true,['mentor-range-fire-wind-gather-v5']=true,['mentor-range-fire-wind-gather-v6']=true,['mentor-range-fire-wind-v7']=true,['mentor-range-fire-wind-v8']=true,['mentor-range-fire-wind-v9']=true,['mentor-range-fire-wind-v10']=true,['mentor-range-fire-wind-v11']=true,['mentor-range-fire-wind-v12']=true,['mentor-range-fire-wind-v13']=true,['mentor-range-fire-wind-v14']=true})[r.controller]or not require(r.candidate and r.candidate.algorithm=='yingzhao-qlearning'and 'Training.YingzhaoQ'or 'Training.YingzhaoPolicy').validate(r.candidate)or type(r.rounds)~='table'or #r.rounds~=2 then return false,'INVALID_COMPARISON'end
 if r.supportAccountingVersion~=nil and r.supportAccountingVersion~=1 then return false,'INVALID_SUPPORT_SUMMARY_VERSION'end
 if r.locomotion~=nil and(type(r.locomotion)~='table'or r.locomotion.version~=1 or r.locomotion.enemyRange~=800 or r.locomotion.retreatRatio~=.5)then return false,'INVALID_LOCOMOTION'end
 if r.skillControl~=nil then
  local c=r.skillControl
  if type(c)~='table'then return false,'INVALID_SKILL_CONTROL'end
  if c.version==1 then
   if c.independentActor~=r.candidate.characterId or r.candidate.actionSetVersion~=2 then return false,'INVALID_SKILL_CONTROL'end
  elseif c.version==2 then
   local actors=c.independentActors;if type(actors)~='table'or #actors<1 or #actors>2 then return false,'INVALID_SKILL_CONTROL'end
   local count=0;for k in pairs(actors)do if type(k)~='number'or k%1~=0 or k<1 or k>#actors then return false,'INVALID_SKILL_CONTROL'end;count=count+1 end
   if count~=#actors then return false,'INVALID_SKILL_CONTROL'end
   local expected={};for _,m in ipairs({r.candidate,r.baseline or false,r.companion or false})do if m and m.actionSetVersion==2 then expected[m.characterId]=true end end
   for _,actor in ipairs(actors)do if not expected[actor]then return false,'INVALID_SKILL_CONTROL'end;expected[actor]=nil end
   if next(expected)then return false,'INVALID_SKILL_CONTROL'end
  else return false,'INVALID_SKILL_CONTROL'end
 end
 if r.setup~=nil then
  local setup=r.setup
  if type(setup)~='table'or setup.schemaVersion~=1 or type(setup.candidate)~='table'or not finite(setup.candidate.id)or setup.candidate.id<1 or setup.candidate.id%1~=0 or setup.candidate.algorithm~=r.candidate.algorithm or type(setup.combatRules)~='string'or type(setup.models)~='table'or type(setup.states)~='table'then return false,'INVALID_DEPLOYMENT_CONTEXT'end
  for _,actor in ipairs({'ninilite','wuyun'})do
   local state=setup.states[actor]
   if type(state)~='table'or not finite(state.current)or state.current<0 or state.current%1~=0 or not finite(state.revision)or state.revision<0 or state.revision%1~=0 or not require('Training.Model').validate(setup.models[actor],actor,require('Training.Characters')[actor].legal)then return false,'INVALID_DEPLOYMENT_CONTEXT'end
  end
 end
 if r.baseline then
  local p=r.baseline.algorithm=='yingzhao-qlearning'and'Training.YingzhaoQ'or'Training.YingzhaoPolicy'
  if r.baseline.characterId~=r.candidate.characterId or not require(p).validate(r.baseline)then return false,'INVALID_BASELINE'end
 end
 if r.companion then
  local p=r.companion.algorithm=='yingzhao-qlearning'and 'Training.YingzhaoQ'or 'Training.YingzhaoPolicy'
  if r.companion.characterId==r.candidate.characterId or not require(p).validate(r.companion)then return false,'INVALID_COMPANION'end
 end
 local quote,episodes
 for i,round in ipairs(r.rounds)do
  if type(round)~='table'or round.mode~=(i==1 and'baseline'or'candidate')or (round.status~='won'and round.status~='failed')or not finite(round.seconds)or round.seconds<=0 or round.seconds>200 then return false,'INVALID_ROUND'end
  if not equal(round.companion,r.companion)then return false,'COMPANION_MISMATCH'end
  if round.companionDecisions~=nil then
   local decisions=round.companionDecisions
   if not r.companion or type(decisions)~='table'or #decisions>1500 then return false,'INVALID_COMPANION_DECISIONS'end
   local previous=-math.huge
   for key in pairs(decisions)do if type(key)~='number'or key%1~=0 or key<1 or key>#decisions then return false,'INVALID_COMPANION_DECISIONS'end end
   for _,d in ipairs(decisions)do
    if type(d)~='table'or not finite(d.at)or d.at<previous or type(d.accepted)~='boolean'or not require('Training.YingzhaoFeatures').validate(d.observation)or d.observation.at>d.at or (d.action~=nil and not require('Training.YingzhaoActions').legal(r.companion.characterId,d.action,r.companion.actionSetVersion))or (d.accepted and not d.action)or (d.reason~=nil and type(d.reason)~='string')then return false,'INVALID_COMPANION_DECISION'end
    previous=d.at
   end
  end
  if r.baseline then
   local model=i==1 and r.baseline or r.candidate
   if not equal(round.primaryModel,model)then return false,'PRIMARY_MODEL_MISMATCH'end
   local decisions=round.decisions
   if type(decisions)~='table'or #decisions>1500 then return false,'INVALID_PRIMARY_DECISIONS'end
   local previous=-math.huge
   for key in pairs(decisions)do if type(key)~='number'or key%1~=0 or key<1 or key>#decisions then return false,'INVALID_PRIMARY_DECISIONS'end end
   for _,d in ipairs(decisions)do
    if type(d)~='table'or not finite(d.at)or d.at<previous or type(d.accepted)~='boolean'or not require('Training.YingzhaoFeatures').validate(d.observation)or d.observation.at>d.at or (d.action~=nil and not require('Training.YingzhaoActions').legal(model.characterId,d.action,model.actionSetVersion))or(d.accepted and not d.action)or(d.reason~=nil and type(d.reason)~='string')then return false,'INVALID_PRIMARY_DECISION'end
    previous=d.at
   end
  elseif round.primaryModel~=nil then return false,'UNDECLARED_PRIMARY_MODEL'end
  local t=round.trace;local resource=t and t.resources
  if r.skillControl and t then
   local actors={[r.skillControl.independentActor or '']=true};for _,actor in ipairs(r.skillControl.independentActors or {})do actors[actor]=true end
   for _,step in ipairs(t.steps or {})do if actors[step.actor]and(step.action=='wind'or step.action=='fire')and step.origin=='mentor-command'then return false,'MENTOR_SKILL_INTERFERENCE'end end
  end
  local e={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-evaluation',episode=resource and resource.attempt,versions={resources=1,bigYingzhao=1},resources=resource,boss=t}
  local ok,why=require('Enemy.BigYingzhaoEvidence').validateEvaluation(e);if not ok then return false,why end
  if quote and not equal(quote,resource.quote)then return false,'LOADOUT_MISMATCH'end;quote=resource.quote
  local loadout={};for _,line in ipairs(quote.lines)do loadout[#loadout+1]={actor=line.actor,item=line.item,quantity=line.quantity}end
  if not equal(loadout,r.loadout)then return false,'LOADOUT_MISMATCH'end
  if t.physicalShield then
   local cost=require('Training.YingzhaoRewards').shieldCost(t)
   if not finite(round.shieldEnergy)or math.abs(round.shieldEnergy-cost)>1e-6 then return false,'SHIELD_COST_MISMATCH'end
  elseif round.shieldEnergy~=nil and round.shieldEnergy~=0 then return false,'SHIELD_COST_MISMATCH'end
  if r.supportAccountingVersion==1 then
   local summary=round.supportSummary;local account=t.supportAccounting
   if t.supportAccountingVersion~=1 or type(summary)~='table'or summary.version~=1 or not account then return false,'MISSING_SUPPORT_SUMMARY'end
   for _,field in ipairs({'goldSpent','shieldGold','upkeepGold','machineDamage'})do
    if not finite(summary[field])or math.abs(summary[field]-account[field])>1e-6 then return false,'SUPPORT_SUMMARY_MISMATCH'end
   end
   local first,last=account.samples[1],account.samples[#account.samples]
   if not finite(summary.initialMachineHP)or not finite(summary.finalMachineHP)or math.abs(summary.initialMachineHP-first.machineHP)>1e-6 or math.abs(summary.finalMachineHP-last.machineHP)>1e-6 then return false,'SUPPORT_SUMMARY_MISMATCH'end
  elseif round.supportSummary~=nil then return false,'UNVERSIONED_SUPPORT_SUMMARY'end
  if round.status~=t.status or round.cost~=resource.spent or round.bossHP~=t.encounter.hp or not equal(round.hp,t.partyHP)then return false,'SUMMARY_MISMATCH'end
  for _,actor in ipairs({'mentor','ninilite','wuyun'})do local hp=round.hp and round.hp[actor];if not finite(hp)or hp<0 or hp>100 then return false,'INVALID_HP'end end
  local armor,health=0,0;for _,hit in ipairs(t.hits)do if hit.target=='big-yingzhao'then armor=armor+hit.armorDamage;health=health+hit.healthDamage end end
  if not finite(round.armorDamage)or not finite(round.healthDamage)or math.abs(armor-round.armorDamage)>1e-6 or math.abs(health-round.healthDamage)>1e-6 then return false,'SUMMARY_MISMATCH'end
  if episodes==resource.attempt then return false,'DUPLICATE_ROUND'end;episodes=resource.attempt
 end
 return true
end
local function open()return D.DB:existDB('lsd')and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoComparisons(id INTEGER PRIMARY KEY AUTOINCREMENT,identity TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0 end
local function decode(payload)
 if type(payload)~='string'or #payload>16*1024*1024 then return nil,'SOURCE_TOO_LARGE'end
 local ok,r,valid,why=pcall(function()local r=D.json.decode(payload,32);local valid,why=S.validate(r);return r,valid,why end)
 if not ok then return nil,'INVALID_SOURCE'end;if not valid then return nil,why end;return r
end
function S.saveAsync(r)
 if busy then return nil,'BUSY'end;busy=true
 local ok,id,why=pcall(function()
  local payload=D.json.encode(r,false,true);local source,why=decode(payload);if not source then return nil,why end
  if not open()then return nil,'WRITE_FAILED'end
  local identity=source.rounds[1].trace.resources.attempt..'|'..source.rounds[2].trace.resources.attempt
  local rows=D.DB:query('SELECT id,payload FROM lsd.Game0YingzhaoComparisons WHERE identity=?',{identity});if not rows then return nil,'READ_FAILED'end
  if rows[1]then local old=decode(rows[1][2]);if not old or not equal(old,source)then return nil,'SOURCE_CONFLICT'end;return rows[1][1]end
  if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0YingzhaoComparisons(identity,payload) VALUES(?,?)',{{identity,payload}}}})then return nil,'WRITE_FAILED'end
  rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoComparisons WHERE identity=?',{identity});return rows and rows[1]and rows[1][1]or nil,'READ_FAILED'
 end)
 busy=false;if not ok then return nil,'INVALID_SOURCE'end;return id,id and nil or why
end
function S.list()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id FROM lsd.Game0YingzhaoComparisons ORDER BY id DESC LIMIT 20');if not rows then return nil,'READ_FAILED'end
 local ids={};for _,row in ipairs(rows)do ids[#ids+1]=row[1]end;return ids
end
function S.load(id)
 if type(id)~='number'or id%1~=0 or id<1 or not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0YingzhaoComparisons WHERE id=?',{id});if not rows or not rows[1]then return nil,'NOT_RECORDED'end
 return decode(rows[1][1])
end
return S
