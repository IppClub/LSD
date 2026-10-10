-- Immutable review of an entire controller combination, never a deployment.
local D=require('Dora');local T=require('Training.FlowerTeamTrials')
local equal=require('Training.FlowerIdentity').equal
local R={maxBytes=140*1024*1024};local ids={'near','far','reproduction','field'}
local function dense(t,n)
 if type(t)~='table' or #t~=n then return false end
 local count=0;for k in pairs(t)do if type(k)~='number' or k%1~=0 or k<1 or k>n then return false end;count=count+1 end
 return count==n
end
function R.assess(bundle,historical)
 if type(bundle)~='table' or bundle.schemaVersion~=1 or bundle.scope~='flower-team-adoption-review' or not dense(bundle.trials,8) or type(bundle.sources)~='table'then return nil,'INVALID_TEAM_REVIEW'end
 local seen={}
 for id in pairs(bundle.sources)do if id~='ninilite' and id~='wuyun'then return nil,'INVALID_TEAM_SOURCES'end end
 for _,id in ipairs({'ninilite','wuyun'})do
  local ok,why=require('Training.FlowerEvidence').validate(bundle.sources[id],id);if not ok then return nil,why end
  for _,episode in ipairs(bundle.sources[id].episodes)do seen[episode.episode]=true end
 end
 local review={schemaVersion=1,scope='joint-combination-review',pairs={},blockers={},tradeoffs={},improvements={},candidateWins=0,required=4,adoptionEligible=false}
 local versions,geometry
 for i,id in ipairs(ids)do
  local basic,candidate=bundle.trials[i*2-1],bundle.trials[i*2]
  for _,trial in ipairs({basic,candidate})do
   local ok,why=T.validate(trial);if not ok then return nil,why end
   if not equal(trial.teamSources,bundle.sources) or not equal(trial.setup.models,bundle.models) or trial.setup.profile.id~=id then return nil,'TEAM_REVIEW_MISMATCH'end
   if seen[trial.episode.episode]then return nil,'REUSED_EPISODE'end;seen[trial.episode.episode]=true
   if versions and not equal(versions,trial.episode.versions)then return nil,'TEAM_VERSION_MISMATCH'end;versions=trial.episode.versions
   local g={scale=trial.setup.bossScale,aim=trial.setup.aimPolicy,hitReaction=trial.setup.hitReaction}
   if geometry and not equal(geometry,g)then return nil,'TEAM_VERSION_MISMATCH'end;geometry=g
  end
  local pair,why=T.compare(basic,candidate);if not pair then return nil,why end;review.pairs[id]=pair
  if pair.candidate.won then review.candidateWins=review.candidateWins+1 else review.blockers[#review.blockers+1]={profile=id,reason='CANDIDATE_NOT_WON'}end
  if not historical and (not require('Factory.Rules').current(basic.setup)) then review.blockers[#review.blockers+1]={profile=id,reason='ENCOUNTER_CHANGED'}end
  for _,metric in ipairs({{'teamDamage',1},{'friendlyDamage',1},{'seconds',1},{'armor',-1},{'health',-1},{'assistedHealth',-1},{'teamFinalHP',-1}})do
   if metric[1]~='seconds' or pair.basic.won and pair.candidate.won then
    local delta=pair.delta[metric[1]];local entry={profile=id,metric=metric[1],delta=delta}
    if delta*metric[2]>1e-6 then review.tradeoffs[#review.tradeoffs+1]=entry elseif delta*metric[2]<-1e-6 then review.improvements[#review.improvements+1]=entry end
   end
  end
 end
 review.readyForDecision=#review.blockers==0
 return D.json.decode(D.json.encode(review,false,true),32)
end
function R.make(sources,models,records)
 if type(records)~='table'then return nil,'MISSING_TRIAL_HISTORY'end
 local byId={}
 for _,record in ipairs(records)do
  local ok,why=T.validate(record);if not ok then return nil,why end
  local id=record.episode.episode;if byId[id]then return nil,'REUSED_EPISODE'end;byId[id]=record
 end
 local coverage,why=T.review(sources,models,records);if not coverage then return nil,why end
 if coverage.completed~=4 then return nil,'MISSING_PROFILE_PAIR'end
 local trials={};for _,id in ipairs(ids)do local pair=coverage.pairs[id];trials[#trials+1]=byId[pair.basicEpisode];trials[#trials+1]=byId[pair.candidateEpisode]end
 local bundle={schemaVersion=1,scope='flower-team-adoption-review',sources=sources,models=models,trials=trials}
 local assessment,why=R.assess(bundle);if not assessment then return nil,why end
 local payload=D.json.encode(bundle,false,true);if #payload>R.maxBytes then return nil,'ADOPTION_EVIDENCE_TOO_LARGE'end
 local frozen=D.json.decode(payload,32);local review,why=R.assess(frozen);if not review then return nil,why end
 return frozen,review
end
function R.verifyAsync(bundle)
 local review,why=R.assess(bundle);if not review then return nil,why end
 for _,id in ipairs({'ninilite','wuyun'})do local ok,why=require('Training.FlowerEvidence').verifyAsync(bundle.sources[id],id);if not ok then return nil,why end end
 return review
end
return R
