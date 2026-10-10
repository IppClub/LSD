-- Frozen candidate inference in the existing encounter, never online learning.
local D=require('Dora');local Policy=require('Training.DisarmPolicy');local T={}
function T.attach(b,candidate)
 assert(not b.demonstrator,'A candidate cannot control a manual demonstrator')
 assert(type(candidate)=='table'and type(candidate.id)=='number'and Policy.validate(candidate.model))
 local frozen=D.json.decode(D.json.encode(candidate,false,true),32)
 local a;for _,learner in ipairs(b.learners)do if learner.character.id==frozen.model.characterId then a=learner end end;assert(a)
 b.trialCandidate=frozen;b.candidateArena=a
 b.disarmTrace.candidate=frozen;b.disarmTrace.candidateDecisions={}
 local request=a.request
 a.request=function(self,action,source,...)return request(self,action,source=='model'and'candidate'or source,...)end
 a.resourceTrialPredict=function(_,available)
  local observed=b.disarmSnapshot(a.student)
  local action,why=Policy.predict(frozen.model,observed,available)
  local log=b.disarmTrace.candidateDecisions
  if #log<b.disarmTrace.limit then log[#log+1]={at=D.App.runningTime,actor=a.character.id,before=observed,action=action,reason=why}
  else b.disarmTrace.truncated=true end
  return action,why
 end
end
return T
