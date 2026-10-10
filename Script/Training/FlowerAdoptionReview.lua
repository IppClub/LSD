-- Freeze source demonstrations and the three latest matched evaluation pairs.
-- This is a review artifact, never permission to deploy or proof of team benefit.
local D=require('Dora')
local R={maxBytes=60*1024*1024};local equal=require('Training.FlowerIdentity').equal
local Evidence=require('Training.FlowerEvidence')
local Trials=require('Training.FlowerTrialStore')
local ids=require('Training.FlowerScenarios').ids
local function dense(t,n)
 if type(t)~='table' or #t~=n then return false end
 local count=0;for k in pairs(t)do if type(k)~='number' or k%1~=0 or k<1 or k>n then return false end;count=count+1 end
 return count==n
end
-- Only recomputed outcome totals allow sub-nanounit floating/JSON roundoff.
-- Schema, identity, action counts, readiness and topology remain exact.
function R.sameAssessment(a,b,key)
 if type(a)~=type(b)then return false end
 if type(a)=='number' then
  if a==b then return true end
  local metric=({seconds=true,health=true,armor=true,assistedHealth=true,teamDamage=true,teamHealing=true,friendlyDamage=true,teamFinalHP=true,delta=true})[key]
  return metric==true and a==a and b==b and math.abs(a)<math.huge and math.abs(b)<math.huge and math.abs(a-b)<=1e-8
 end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not R.sameAssessment(v,b[k],k)then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
function R.assess(bundle)
 if type(bundle)~='table' or bundle.schemaVersion~=1 or bundle.scope~='flower-c45-adoption-review' or not dense(bundle.trials,6)then return nil,'INVALID_ADOPTION_REVIEW'end
 local ok,why=Evidence.validate(bundle.source,bundle.learner);if not ok then return nil,why end
 if bundle.learner~=bundle.source.policy.characterId then return nil,'WRONG_LEARNER'end
 local seen={};for _,e in ipairs(bundle.source.episodes)do seen[e.episode]=true end
 local validationTrials={table.unpack(bundle.trials)}
 if bundle.fieldTrials then
  if not dense(bundle.fieldTrials,2)then return nil,'INVALID_FIELD_PAIR'end
  for _,trial in ipairs(bundle.fieldTrials)do validationTrials[#validationTrials+1]=trial end
 end
 for _,trial in ipairs(validationTrials)do
  local ok,why=Trials.validate(trial);if not ok then return nil,why end
  if trial.learner~=bundle.learner or not equal(trial.setup.models,bundle.models)then return nil,'REVIEW_SETUP_MISMATCH'end
  if seen[trial.episode.episode]then return nil,'REUSED_EPISODE'end;seen[trial.episode.episode]=true
  if trial.setup.scenario~='flower-practice-v3' or trial.status=='aborted' then return nil,'INVALID_REVIEW_TRIAL'end
  if trial.controller=='candidate' and not equal(trial.policy,bundle.source.policy)then return nil,'REVIEW_POLICY_MISMATCH'end
 end
 local coverage,why=require('Training.FlowerGeneralization').latest(bundle.learner,bundle.source.policy,bundle.models,bundle.trials)
 if not coverage then return nil,why end
 if coverage.completed~=3 then return nil,'MISSING_PROFILE_PAIR'end
 local review={schemaVersion=1,learner=bundle.learner,pairs=coverage.pairs,blockers={},tradeoffs={},improvements={},candidateWins=coverage.candidateWins,adoptionEligible=false}
 local reviewedIds={table.unpack(ids)}
 if bundle.fieldTrials then
  local comparison,why=require('Training.FlowerComparison').build(bundle.fieldTrials[1],bundle.fieldTrials[2])
  if not comparison then return nil,why end
  if comparison.profile~='field'then return nil,'INVALID_FIELD_PAIR'end
  review.fieldComparison=comparison;review.required=4
  review.candidateWins=review.candidateWins+(comparison.candidate.won and 1 or 0)
  coverage.pairs.field=comparison;reviewedIds[#reviewedIds+1]='field'
 end
 for _,id in ipairs(reviewedIds)do
  local p=coverage.pairs[id]
  if not p.candidate.won then review.blockers[#review.blockers+1]={profile=id,reason='CANDIDATE_NOT_WON'}end
  -- Report every observed adverse direction; the player must see these before
  -- any later explicit choice. Do not compensate friendly fire with damage.
  local metrics={{'teamDamage',1},{'friendlyDamage',1},{'seconds',1},{'armor',-1},{'health',-1},{'assistedHealth',-1},{'teamFinalHP',-1}}
  for _,m in ipairs(metrics)do
   if m[1]~='seconds' or (p.basic.won and p.candidate.won)then
    local delta=p.delta[m[1]];local entry={profile=id,metric=m[1],delta=delta}
    if delta*m[2]>1e-6 then review.tradeoffs[#review.tradeoffs+1]=entry
    elseif delta*m[2]<-1e-6 then review.improvements[#review.improvements+1]=entry end
   end
  end
 end
 review.readyForDecision=#review.blockers==0
 -- Match the stored numeric representation when acknowledging/reloading review.
 return D.json.decode(D.json.encode(review,false,true),32)
end
function R.make(source,models,records)
 local ok,why=Evidence.validate(source);if not ok then return nil,why end
 if type(records)~='table'then return nil,'MISSING_TRIAL_HISTORY'end
 local seen={}
 for _,trial in ipairs(records)do
  local ok,why=Trials.validate(trial);if not ok then return nil,why end
  if seen[trial.episode.episode]then return nil,'REUSED_EPISODE'end;seen[trial.episode.episode]=trial
 end
 -- history must be newest first, as returned by FlowerTrialStore.history.
 local coverage,why=require('Training.FlowerGeneralization').latest(source.policy.characterId,source.policy,models,records)
 if not coverage then return nil,why end;if coverage.completed~=3 then return nil,'MISSING_PROFILE_PAIR'end
 local selected={}
 for _,id in ipairs(ids)do local pair=coverage.pairs[id];selected[#selected+1]=seen[pair.basicEpisode];selected[#selected+1]=seen[pair.candidateEpisode]end
 local bundle={schemaVersion=1,scope='flower-c45-adoption-review',learner=source.policy.characterId,source=source,models=models,trials=selected}
 local fieldBasic,fieldCandidate
 for _,trial in ipairs(records)do
  if trial.learner==source.policy.characterId and trial.status~='aborted' and trial.setup.scenario=='flower-practice-v3' and trial.setup.profile.id=='field' and equal(trial.setup.models,models)then
   if trial.controller=='basic' and not fieldBasic then fieldBasic=trial
   elseif trial.controller=='candidate' and not fieldCandidate and equal(trial.policy,source.policy)then fieldCandidate=trial end
  end
 end
 if fieldBasic and fieldCandidate then bundle.fieldTrials={fieldBasic,fieldCandidate}end
 local review,why=R.assess(bundle);if not review then return nil,why end
 local payload=D.json.encode(bundle,false,true);if not payload or #payload>R.maxBytes then return nil,'ADOPTION_EVIDENCE_TOO_LARGE'end
 local frozen=D.json.decode(payload,32);local review,why=R.assess(frozen);if not review then return nil,why end
 return frozen,review
end
function R.verifyAsync(bundle)
 local review,why=R.assess(bundle);if not review then return nil,why end
 local ok,why=Evidence.verifyAsync(bundle.source,bundle.learner);if not ok then return nil,why end
 return review
end
return R
