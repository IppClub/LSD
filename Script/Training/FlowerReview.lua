-- Multi-round review of saved evidence. Repeating the same encounter is not
-- held-out distance/phase/armor coverage and cannot authorize adoption.
local R={requiredPairs=3}
local equal=require('Training.FlowerIdentity').equal
function R.build(history,actor,policy,models)
 local ok,why=require('Training.FlowerPolicy').validate(policy,actor);if not ok then return nil,why end
 local seen={};local candidates,basics={},{};local excluded={aborted=0,otherPolicy=0,otherSetup=0}
 for _,record in ipairs(history)do
  local valid,why=require('Training.FlowerTrialStore').validate(record);if not valid then return nil,why end
  local id=record.episode.episode
  if seen[id]then return nil,'DUPLICATE_EPISODE'end;seen[id]=true
  if record.learner~=actor or record.setup.scenario~='flower-practice-v2' or not equal(record.setup.models,models)then excluded.otherSetup=excluded.otherSetup+1
  elseif record.status=='aborted'then excluded.aborted=excluded.aborted+1
  elseif record.controller=='basic'then basics[#basics+1]=record
  elseif equal(record.policy,policy)then candidates[#candidates+1]=record
  else excluded.otherPolicy=excluded.otherPolicy+1 end
 end
 local result={schemaVersion=1,scope='repeated-encounter-review',learner=actor,requiredPairs=R.requiredPairs,pairs={},excluded=excluded,missingBaseline=0,candidateRounds=#candidates,adoptionEligible=false,coverage='single-configuration',nextRequirement='held-out-distance-phase-armor',basicWins=0,candidateWins=0,regressions=0,safetyRegressions=0,delta={armor=0,health=0,assistedHealth=0,teamDamage=0,friendlyDamage=0},durationPairs=0,winningDurationDelta=0}
 local used={}
 -- History is newest first. Only the latest three completed current-candidate
 -- rounds count; a bad recent round cannot be replaced with an older good one.
 for i=1,math.min(R.requiredPairs,#candidates)do
  local candidate=candidates[i];local comparison
  for j,basic in ipairs(basics)do
   if not used[j] and equal(basic.setup,candidate.setup)then
    local value,why=require('Training.FlowerComparison').build(basic,candidate)
    if value then comparison=value;used[j]=true;break
    elseif why~='NO_LEARNER_ACTIONS'then return nil,why end
   end
  end
  if comparison then
   result.pairs[#result.pairs+1]=comparison
   local b,c=comparison.basic,comparison.candidate
   result.basicWins=result.basicWins+(b.won and 1 or 0);result.candidateWins=result.candidateWins+(c.won and 1 or 0)
   if b.won and not c.won then result.regressions=result.regressions+1 end
   if c.friendlyDamage>b.friendlyDamage+1e-8 or (b.won and c.won and c.teamDamage>b.teamDamage+1e-8)then result.safetyRegressions=result.safetyRegressions+1 end
   for name in pairs(result.delta)do result.delta[name]=result.delta[name]+comparison.delta[name]end
   if b.won and c.won then result.durationPairs=result.durationPairs+1;result.winningDurationDelta=result.winningDurationDelta+comparison.delta.seconds end
  else result.missingBaseline=result.missingBaseline+1 end
 end
 local n=#result.pairs
 if n<R.requiredPairs then result.verdict='collect-more'
 elseif result.regressions>0 or result.candidateWins<result.basicWins then result.verdict='candidate-regressed'
 elseif result.safetyRegressions>0 then result.verdict='safety-regressed'
 elseif result.candidateWins==0 then result.verdict='no-success'
 else result.verdict='needs-held-out-evaluation'end
 return result
end
function R.latest(actor,policy,models,records)
 if not policy then return nil,'NO_CANDIDATE'end
 local history,why=records;if not history then history,why=require('Training.FlowerTrialStore').history(actor)end;if not history then return nil,why end
 return R.build(history,actor,policy,models)
end
function R.text(r)
 if not r then return ''end
 local descriptions={['collect-more']='继续完成基础/候选对照', ['candidate-regressed']='候选出现战斗退步，需补练', ['safety-regressed']='候选承伤或误伤增加，需复查', ['no-success']='尚无成功回合，需补练', ['needs-held-out-evaluation']='需补未参训距离、阶段与护甲配置评价'}
 return string.format('普通场景复盘：%d/%d组 · 基础胜%d / 候选胜%d · %s',#r.pairs,r.requiredPairs,r.basicWins,r.candidateWins,descriptions[r.verdict])
end
return R
