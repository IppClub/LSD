-- Explicitly adopted policies apply to medium-Yingzhao practice and explicitly confirmed missions.
-- Demonstrations and controlled comparisons retain their own controllers.
local D=require('Dora');local P=require('Training.DisarmPolicy');local M={}
function M.attachAsync(b,models)
 assert(not b.demonstrator and not b.trialCandidate)
 b.disarmTrace.adoptions={};b.disarmTrace.adoptionDecisions={};local descriptions={}
 for _,a in ipairs(b.learners)do
  local actor=a.character.id;local saved,why=require('Training.DisarmAdoptionStore').loadAsync(actor,models,b.disarmTrace.kind=='disarm-mission'and'mission'or nil)
  if saved then
   local candidate=D.json.decode(D.json.encode(saved.proof.candidate,false,true),32)
   b.disarmTrace.adoptions[actor]={id=saved.id,candidate=candidate,comparisonId=saved.bundle.comparison.id,rules=require('Training.DisarmRules').version}
   descriptions[#descriptions+1]=a.character.name..'采用#'..saved.id
   local request=a.request
   a.request=function(self,action,source,...)return request(self,action,source=='model'and'adopted-disarm'or source,...)end
   a.resourceTrialPredict=function(_,available)
    local before=b.disarmSnapshot(a.student);local action,reason=P.predict(candidate.model,before,available)
    local log=b.disarmTrace.adoptionDecisions
    if #log<b.disarmTrace.limit then log[#log+1]={at=D.App.runningTime,actor=actor,adoption=saved.id,before=before,action=action,reason=reason}else b.disarmTrace.truncated=true end
    return action,reason
   end
  elseif why~='NOT_ADOPTED'then
   descriptions[#descriptions+1]=a.character.name..(why=='MISSION_NOT_CONFIRMED'and '成果尚未确认用于正式清障，使用基础策略'or (why=='BASE_MODELS_CHANGED'or why=='ENCOUNTER_CHANGED')and '规则或基础成果已变，使用基础策略'or '采用档案读取异常，使用基础策略')
  end
 end
 b.adoptionStatus=#descriptions>0 and table.concat(descriptions,'；')or '两名学员使用基础策略'
end
return M
