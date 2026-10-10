-- Candidate trials retain their exact controllers and full outcome ledger.
-- A saved trial is evidence, never an adoption or a claim of improvement.
return function(resourceMode)
local D=require('Dora');local S={maxBytes=resourceMode and 41943040 or 4194304}
local policy=require(resourceMode and 'Training.ResourcePolicy' or 'Training.FlowerPolicy')
local tableName=resourceMode and 'Game0ResourceC45Trials' or 'Game0FlowerTrials'
local function finite(n)return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function canonical(t)return D.json.encode(t,false,true)end
local function same(a,b)
 if type(a)~=type(b)then return false end
 if type(a)=='number'then return finite(a) and finite(b) and math.abs(a-b)<=1e-8 end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function validate(record,team)
 if type(record)~='table' or record.schemaVersion~=1 or not ({candidate=true,basic=true})[record.controller] or not ({won=true,failed=true,aborted=true})[record.status]then return false,'INVALID_TRIAL'end
 local actor=record.learner
 if not (record.controller=='candidate' and policy.validate(record.policy,actor) or record.controller=='basic' and require('Training.Model').validate(record.policy,actor)) or (actor~='ninilite' and actor~='wuyun')then return false,'INVALID_POLICY'end
 local setup=record.setup
 if type(setup)~='table' or (setup.scenario~='flower-practice-v1' and setup.scenario~='flower-practice-v2' and setup.scenario~='flower-practice-v3') or setup.decisionSeconds~=.25 or setup.supportVariant~='defence'  or type(setup.models)~='table' then return false,'INVALID_SETUP'end
 if team then
  if record.learner~='ninilite' or setup.teamVersion~=1 or setup.teamFormation~='ni-left-wu120-v1' or type(setup.teamPolicies)~='table' or type(record.episode)~='table' or record.episode.context~='flower-team-practice' then return false,'INVALID_TEAM_SETUP'end
  for id in pairs(setup.teamPolicies)do if id~='ninilite' and id~='wuyun'then return false,'INVALID_TEAM_POLICY'end end
  for _,id in ipairs({'ninilite','wuyun'})do if not require('Training.FlowerPolicy').validate(setup.teamPolicies[id],id)then return false,'INVALID_TEAM_POLICY'end end
  if record.controller=='candidate' and not require('Training.FlowerIdentity').equal(record.policy,setup.teamPolicies.ninilite)then return false,'TEAM_POLICY_MISMATCH'end
 elseif setup.teamPolicies~=nil or setup.teamVersion~=nil then return false,'TEAM_TRIAL_REQUIRES_SEPARATE_STORE'end
 local profile=setup.scenario=='flower-practice-v3' and setup.profile
 local expectedGold=type(profile)=='table' and profile.id=='field' and 45 or 90
 if setup.supportGold~=expectedGold then return false,'INVALID_SUPPORT_GOLD'end
 if (setup.scenario=='flower-practice-v2' or setup.scenario=='flower-practice-v3') and (setup.initialDecisionSeconds~=.2 or setup.mentor~='auto-nearest-kinetic-v1' or setup.chant~='on-confusion-v1')then return false,'INVALID_SUPPORT_CONTROLLER'end
 if record.controller=='basic' and not require('Training.FlowerIdentity').equal(record.policy,setup.models[actor])then return false,'BASELINE_MISMATCH'end
 for _,id in ipairs({'ninilite','wuyun'})do if not require('Training.Model').validate(setup.models[id],id)then return false,'INVALID_PARTNER_MODEL'end end
 if not finite(record.seconds) or record.seconds>180 or type(record.initialHP)~='table' or type(record.finalHP)~='table' then return false,'INVALID_OUTCOME'end
 local episode=record.episode
 if not require('Factory.Rules').validReaction(setup,episode)then return false,'INVALID_HIT_REACTION_RULE'end
 if type(episode)~='table' or episode.context~=(resourceMode and 'flower-resource-c45-trial' or team and 'flower-team-practice' or 'flower-practice') or type(episode.versions)~='table' or episode.versions.observation~=6 or episode.versions.action~=4 or episode.versions.clock~='simulation'then return false,'INVALID_EPISODE'end
 if not team and (record.teamSources~=nil or episode.context~=(resourceMode and 'flower-resource-c45-trial' or 'flower-practice'))then return false,'TEAM_TRIAL_REQUIRES_SEPARATE_STORE'end
 if setup.scenario=='flower-practice-v3' and (not require('Training.FlowerScenarios').validate(setup.profile) or episode.practiceProfile~=setup.profile.id)then return false,'INVALID_EVALUATION_PROFILE'end
 if resourceMode then
  if not episode.resources or episode.resources.mode~='virtual' or episode.versions.resourceFeatures~=1 then return false,'RESOURCE_TRIAL_REQUIRED'end
  local ok,why=require('Training.ResourcePolicyEvidence').validate(record.resourceSource,actor);if not ok then return false,why end
  if record.controller=='candidate' and not require('Training.FlowerIdentity').equal(record.policy,record.resourceSource.policy)then return false,'RESOURCE_CANDIDATE_MISMATCH'end
 elseif episode.resources then return false,'RESOURCE_TRIAL_REQUIRES_SEPARATE_STORE'end
 if episode.versions.outcome~=nil or episode.outcome~=nil then
  if episode.versions.outcome~=1 or not require('Factory.Outcome').valid(episode.outcome)then return false,'INVALID_OUTCOME_FACTS'end
 if not require('Factory.Outcome').validGoal(setup,episode,resourceMode)then return false,'INVALID_TRAINING_GOAL'end
  if record.status=='won' and not require('Factory.Outcome').satisfied(episode.outcome,setup.trainingGoal)then return false,'OUTCOME_STATUS_MISMATCH'end
 end
 if not require('Factory.Outcome').validGoal(setup,episode,resourceMode)then return false,'INVALID_TRAINING_GOAL'end
 local evaluation,why=require('Training.FlowerEvaluation').build(episode);if not evaluation then return false,why end
 for _,step in ipairs(episode.steps)do
  local action=step.action
  if action.origin=='demo' or action.origin=='player' then return false,'HUMAN_ACTION_IN_TRIAL'end
  if (action.actor==actor or (team and action.actor=='wuyun')) and action.origin~='model' and not(action.origin=='baseline' and (action.name=='idle' or record.controller=='basic' and action.name=='shoot'))then return false,'INVALID_TRIAL_CONTROLLER'end
 end
 for _,id in ipairs({'mentor','ninilite','wuyun'})do
  local first,last=record.initialHP[id],record.finalHP[id]
  if first~=100 or not finite(last) or last>100 then return false,'INVALID_HP'end
  local v=episode.vitals.actors[id]
  if v then if math.abs(v.initialHP-first)>1e-5 or math.abs(v.finalHP-last)>1e-5 then return false,'HP_LEDGER_MISMATCH'end
  elseif first~=last then return false,'MISSING_HP_LEDGER'end
 end
 if not record.evaluation or not same(record.evaluation,evaluation)then return false,'EVALUATION_MISMATCH'end
 return true
end
function S.validate(record)return validate(record,false)end
function S.validateTeam(record)return validate(record,true)end
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.'..tableName..' (serial INTEGER PRIMARY KEY AUTOINCREMENT, episode TEXT NOT NULL UNIQUE, learner TEXT NOT NULL, payload TEXT NOT NULL)')>=0
end
function S.saveAsync(record)
 if resourceMode then
  local frozen=canonical(record);if #frozen>S.maxBytes then return false,'TRIAL_TOO_LARGE'end
  record=D.json.decode(frozen,32)
 end
 local valid,why=S.validate(record);if not valid then return false,why end
 if resourceMode then local ok,why=require('Training.ResourcePolicyEvidence').verifyAsync(record.resourceSource,record.learner);if not ok then return false,why end end
 local payload=canonical(record);if #payload>S.maxBytes then return false,'TRIAL_TOO_LARGE'end
 if not open()then return false,'WRITE_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.'..tableName..' WHERE episode=?',{record.episode.episode});if not rows then return false,'READ_FAILED'end
 if rows[1]then if rows[1][1]==payload or require('Training.FlowerIdentity').equal(D.json.decode(rows[1][1],32),record) then return true end;return false,'EPISODE_CONFLICT'end
 local ok=D.DB:transactionAsync({
  {'INSERT INTO lsd.'..tableName..'(episode,learner,payload) VALUES(?,?,?)',{{record.episode.episode,record.learner,payload}}},
  {'DELETE FROM lsd.'..tableName..' WHERE learner=? AND serial NOT IN (SELECT serial FROM lsd.'..tableName..' WHERE learner=? ORDER BY serial DESC LIMIT 20)',{{record.learner,record.learner}}}
 })
 if not ok then return false,'WRITE_FAILED'end;return true
end
function S.history(actor)
 if actor~='ninilite' and actor~='wuyun'then return nil,'INVALID_CHARACTER'end
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.'..tableName..' WHERE learner=? ORDER BY serial DESC LIMIT 20',{actor});if not rows then return nil,'READ_FAILED'end
 local result={}
 for _,row in ipairs(rows)do
 local payload=row[1];if type(payload)~='string' or #payload>S.maxBytes then return nil,'INVALID_PAYLOAD'end
 local record=D.json.decode(payload,32);local valid,why=S.validate(record);if not valid then return nil,why end
 if record.learner~=actor then return nil,'WRONG_LEARNER'end
 if resourceMode then local ok,why=require('Training.ResourcePolicyEvidence').verifyAsync(record.resourceSource,actor);if not ok then return nil,why end end
 result[#result+1]=record
 end
 return result
end
function S.latest(actor)
 local records,why=S.history(actor);if not records then return nil,why end
 if not records[1]then return nil,'NOT_RECORDED'end
 return records[1]
end
return S
end
