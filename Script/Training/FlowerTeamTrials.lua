-- Joint trials have independent storage and preserve both controllers' sources.
-- They cannot authorize either single-learner adoption, or joint deployment yet.
local D=require('Dora');local T={maxBytes=16*1024*1024}
local equal=require('Training.FlowerIdentity').equal
function T.validate(record)
 local ok,why=require('Training.FlowerTrialStore').validateTeam(record);if not ok then return false,why end
 if record.setup.scenario~='flower-practice-v3' or type(record.teamSources)~='table'then return false,'INVALID_TEAM_SOURCES'end
 for id in pairs(record.teamSources)do if id~='ninilite' and id~='wuyun'then return false,'INVALID_TEAM_SOURCES'end end
 for _,id in ipairs({'ninilite','wuyun'})do
  local source=record.teamSources[id];local ok,why=require('Training.FlowerEvidence').validate(source,id);if not ok then return false,why end
  if not equal(source.policy,record.setup.teamPolicies[id])then return false,'TEAM_SOURCE_MISMATCH'end
  for _,episode in ipairs(source.episodes)do if episode.episode==record.episode.episode then return false,'REUSED_EPISODE'end end
 end
 return true
end
local function open()
 return D.DB:existDB('lsd') and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0FlowerTeamTrials(serial INTEGER PRIMARY KEY AUTOINCREMENT,episode TEXT NOT NULL UNIQUE,payload TEXT NOT NULL)')>=0
end
function T.saveAsync(record)
 local ok,why=T.validate(record);if not ok then return false,why end
 local payload=D.json.encode(record,false,true);if #payload>T.maxBytes then return false,'TRIAL_TOO_LARGE'end
 if not open()then return false,'WRITE_FAILED'end
 local existing=D.DB:query('SELECT payload FROM lsd.Game0FlowerTeamTrials WHERE episode=?',{record.episode.episode})
 if not existing then return false,'READ_FAILED'end
 if existing[1]then if existing[1][1]==payload or equal(D.json.decode(existing[1][1],32),record)then return true end;return false,'EPISODE_CONFLICT'end
 local frozen=D.json.decode(payload,32)
 for _,id in ipairs({'ninilite','wuyun'})do local ok,why=require('Training.FlowerEvidence').verifyAsync(frozen.teamSources[id],id);if not ok then return false,why end end
 local saved=D.DB:transactionAsync({
  {'INSERT INTO lsd.Game0FlowerTeamTrials(episode,payload) VALUES(?,?)',{{frozen.episode.episode,payload}}},
  {'DELETE FROM lsd.Game0FlowerTeamTrials WHERE serial NOT IN (SELECT serial FROM lsd.Game0FlowerTeamTrials ORDER BY serial DESC LIMIT 24)',{}}
 })
 if not saved then return false,'WRITE_FAILED'end;return true
end
function T.history()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerTeamTrials ORDER BY serial DESC LIMIT 24');if not rows then return nil,'READ_FAILED'end
 local records={};for _,row in ipairs(rows)do
  if type(row[1])~='string' or #row[1]>T.maxBytes then return nil,'INVALID_PAYLOAD'end
  local record=D.json.decode(row[1],32);local ok,why=T.validate(record);if not ok then return nil,why end;records[#records+1]=record
 end
 return records
end
function T.compare(basic,candidate)
 if type(basic)~='table' or type(candidate)~='table'then return nil,'MISSING_PAIR'end
 for _,record in ipairs({basic,candidate})do local ok,why=T.validate(record);if not ok then return nil,why end end
 if basic.controller~='basic' or candidate.controller~='candidate' or basic.status=='aborted' or candidate.status=='aborted' then return nil,'INVALID_PAIR'end
 if basic.episode.episode==candidate.episode.episode or not equal(basic.setup,candidate.setup) or not equal(basic.teamSources,candidate.teamSources) or not equal(basic.episode.versions,candidate.episode.versions)then return nil,'TEAM_SETUP_MISMATCH'end
 local function stats(r)
  local s={won=r.status=='won',seconds=r.seconds,armor=0,health=0,assistedHealth=0,teamDamage=0,friendlyDamage=0,teamHealing=0,teamFinalHP=0,actors=r.evaluation.actors}
  for _,id in ipairs({'mentor','ninilite','wuyun'})do
   local a=r.evaluation.actors[id];s.teamDamage=s.teamDamage+a.damageTaken;s.friendlyDamage=s.friendlyDamage+a.friendlyDamage;s.teamHealing=s.teamHealing+a.healing;s.teamFinalHP=s.teamFinalHP+r.finalHP[id]
   if id~='mentor'then s.armor=s.armor+a.armor;s.health=s.health+a.health;s.assistedHealth=s.assistedHealth+a.assistedHealth end
  end
  return s
 end
 local b,c=stats(basic),stats(candidate);local delta={};for k,v in pairs(c)do if type(v)=='number'then delta[k]=v-b[k]end end
 return {profile=basic.setup.profile.id,scope='joint-pair-observation',basicEpisode=basic.episode.episode,candidateEpisode=candidate.episode.episode,basic=b,candidate=c,delta=delta,adoptionEligible=false}
end
function T.review(sources,models,records)
 local result={pairs={},missing={},completed=0,required=4}
 for _,profile in ipairs(require('Training.FlowerScenarios').menuIds)do
  local b,c
  for _,record in ipairs(records)do
   if record.status~='aborted' and record.setup.profile.id==profile and equal(record.teamSources,sources) and equal(record.setup.models,models)then
    if record.controller=='basic' and not b then b=record elseif record.controller=='candidate' and not c then c=record end
   end
  end
  if b and c then local pair,why=T.compare(b,c);if not pair then return nil,why end;result.pairs[profile]=pair;result.completed=result.completed+1 else result.missing[#result.missing+1]=profile end
 end
 return result
end
function T.text(review,profile)
 local text=string.format('联合评价覆盖：%d/4；请在联合成果审查中查看取舍并选择采用。',review.completed)
 local pair=review.pairs[profile];if not pair then return text..' 本配置尚缺同组合基础/候选对照。'end
 return text..string.format('\n双基础%s / 双候选%s；两学员削甲%+.0f · 队伍承伤%+.0f · 误伤%+.0f。',pair.basic.won and '胜利' or '失败',pair.candidate.won and '胜利' or '失败',pair.delta.armor,pair.delta.teamDamage,pair.delta.friendlyDamage)
end
return T
