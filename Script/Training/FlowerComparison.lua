-- Compare actual completed trials with identical encounter/support/partner setup.
-- One pair is descriptive evidence, not an adoption gate or a success grade.
local C={}
local equal=require('Training.FlowerIdentity').equal
function C.build(basic,candidate)
 if type(basic)~='table' or type(candidate)~='table'then return nil,'MISSING_TRIAL'end
 local store=require('Training.FlowerTrialStore')
 for _,r in ipairs({basic,candidate})do local ok,why=store.validate(r);if not ok then return nil,why end end
 if basic.controller~='basic' or candidate.controller~='candidate' or basic.learner~=candidate.learner then return nil,'WRONG_CONTROLLERS'end
 if basic.episode.episode==candidate.episode.episode then return nil,'SAME_EPISODE'end
 if basic.status=='aborted' or candidate.status=='aborted'then return nil,'ABORTED_TRIAL'end
 if (basic.setup.scenario~='flower-practice-v2' and basic.setup.scenario~='flower-practice-v3') or not equal(basic.setup,candidate.setup) or not equal(basic.initialHP,candidate.initialHP) or not equal(basic.episode.versions,candidate.episode.versions)then return nil,'SETUP_MISMATCH'end
 local function stats(r)
  local a=r.evaluation.actors[r.learner]
  local result={won=r.status=='won',seconds=r.seconds,health=a.health,armor=a.armor,breaks=a.breaks,assistedHealth=a.assistedHealth,actions=a.actions,shots=a.shots,teamDamage=0,teamHealing=0,friendlyDamage=0,teamFinalHP=0,incompleteActions=r.evaluation.incompleteActions}
  for _,id in ipairs({'mentor','ninilite','wuyun'})do local v=r.evaluation.actors[id];result.teamDamage=result.teamDamage+v.damageTaken;result.teamHealing=result.teamHealing+v.healing;result.friendlyDamage=result.friendlyDamage+v.friendlyDamage;result.teamFinalHP=result.teamFinalHP+r.finalHP[id]end
  local aim=r.evaluation.aim and r.evaluation.aim.actors[r.learner]
  if aim then result.aimedShots=aim.aimed;result.correctPartShots=aim.correct;result.wrongPartShots=aim.wrongPart;result.unknownIntentShots=aim.unknownIntent end
  return result
 end
 local b,c=stats(basic),stats(candidate)
 -- Zero actions/shots remain visible outcomes; do not silently drop failures.
 local delta={};for name,n in pairs(c)do if type(n)=='number'then delta[name]=n-b[name]end end
 return {schemaVersion=1,scope='single-pair-observation',profile=basic.setup.profile and basic.setup.profile.id or 'standard',learner=basic.learner,basicEpisode=basic.episode.episode,candidateEpisode=candidate.episode.episode,basic=b,candidate=c,delta=delta,adoptionEligible=false}
end
function C.latest(actor,policy,models,records)
 if not policy then return nil,'NO_CANDIDATE'end
 local rows,why=records;if not rows then rows,why=require('Training.FlowerTrialStore').history(actor)end;if not rows then return nil,why end
 for _,candidate in ipairs(rows)do
  if candidate.controller=='candidate' and candidate.status~='aborted' and equal(candidate.policy,policy) and equal(candidate.setup.models,models)then
   for _,basic in ipairs(rows)do
    if basic.controller=='basic' and basic.status~='aborted'then local result=C.build(basic,candidate);if result then return result end end
   end
  end
 end
 return nil,'NO_MATCHING_PAIR'
end
function C.text(r)
 if not r then return '完成相同配置的基础与候选试战后显示对照。'end
 local function displayDelta(n)return math.abs(n)<.5 and 0 or n end
 local profile=r.profile~='standard' and require('Training.FlowerScenarios').get(r.profile)
 local text=string.format('%s对照：基础%s / 候选%s · 候选削甲%+.0f · 队伍承伤%+.0f · 误伤%+.0f\n仅本组实战差异；尚不足以判定稳定提升或采用。',profile and profile.name..' · ' or '',r.basic.won and '胜利' or '失败',r.candidate.won and '胜利' or '失败',displayDelta(r.delta.armor),displayDelta(r.delta.teamDamage),displayDelta(r.delta.friendlyDamage))
 if r.basic.aimedShots~=nil and r.candidate.aimedShots~=nil then
  text=text..string.format('\n正确部位 基础%d/%d / 候选%d/%d；分母只计完成且明确瞄准部位的弹丸，0/0表示无此类射击。',r.basic.correctPartShots,r.basic.aimedShots,r.candidate.correctPartShots,r.candidate.aimedShots)
 end
 return text
end
return C
