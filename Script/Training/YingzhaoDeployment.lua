-- Only explicitly adopted, source-checked models enter formal encounters.
local D=require('Dora');local M={}
function M.attachAsync(b,models)
 assert(b.phase=='ready'and b.supplies and not b.supplies.isVirtual,'Formal ready battle required')
 local store=require('Training.YingzhaoAdoptionStore');b.yingzhaoDeployments={}
 for _,actor in ipairs({'ninilite','wuyun'})do
  local saved,why=store.loadAsync(actor,models,'mission')
  if saved then
   require('Training.YingzhaoTrial').attach(b,saved.proof.candidate.model,{origin='adopted',formalBasicFallback=true})
   local model=saved.proof.candidate.model
   b.yingzhaoDeployments[actor]={status='adopted',basicFallbackVersion=1,id=saved.id,candidateId=saved.bundle.candidate.id,algorithm=model.algorithm,count=model.algorithm=='yingzhao-qlearning'and model.updates or model.sampleCount,featureSchemaVersion=model.featureSchemaVersion,actionSetVersion=model.actionSetVersion,comparisonId=saved.bundle.comparison.id,virtualEvaluation=true,formalSupportPresent=b.support~=nil,formalLoadoutMatchesEvaluation=require('Training.FlowerIdentity').equal(b.supplies.ledger.loadout,saved.proof.record.loadout)}
  else b.yingzhaoDeployments[actor]={status=why or 'READ_FAILED'}end
 end
 b.bossTrace.deployments=D.json.decode(D.json.encode(b.yingzhaoDeployments),32)
 local finish=b.finish
 b.finish=function(self,...)
  local ok=finish(self,...)
  if ok and self.report then
   self.report.yingzhaoDeployments=D.json.decode(D.json.encode(self.yingzhaoDeployments),32)
   for actor,deployed in pairs(self.yingzhaoDeployments)do if deployed.status=='adopted'then
    local learner=self.report.learners[actor]
    learner.basicTraining=learner.training
    learner.training={domain='big-yingzhao',characterId=actor,algorithm=deployed.algorithm,count=deployed.count,adoptionId=deployed.id,candidateId=deployed.candidateId,featureSchemaVersion=deployed.featureSchemaVersion,actionSetVersion=deployed.actionSetVersion}
    learner.samples=deployed.algorithm=='yingzhao-c45'and deployed.count or nil
    local counters={accepted=0,unseen=0,unavailable=0,basicFallback=0,basicFallbackAccepted=0}
    for _,d in ipairs(self.yingzhaoDecisionsByActor[actor])do
     if d.fallback then counters.basicFallback=counters.basicFallback+1;if d.fallback.accepted then counters.basicFallbackAccepted=counters.basicFallbackAccepted+1 end end
     if d.accepted then counters.accepted=counters.accepted+1
     elseif d.reason=='UNSEEN_STATE'or d.reason=='UNSEEN_ACTIONS'or d.reason=='NO_MATCH'then counters.unseen=counters.unseen+1
     else counters.unavailable=counters.unavailable+1 end
    end
    learner.policyDecisions=counters
   end end
  end
  return ok
 end
 return b.yingzhaoDeployments
end
function M.verifyAsync(b)
 local models,why=require('Training.FlowerPractice').models();if not models then return false,why end
 local store=require('Training.YingzhaoAdoptionStore')
 for actor,expected in pairs(b.yingzhaoDeployments or {})do if expected.status=='adopted'then
  local current,why=store.loadAsync(actor,models,'mission');if not current then return false,why end
  if current.id~=expected.id or current.bundle.candidate.id~=expected.candidateId or current.proof.candidate.model.algorithm~=expected.algorithm or not require('Training.FlowerIdentity').equal(current.proof.candidate.model,b.yingzhaoCandidates[actor])then return false,'DEPLOYMENT_CHANGED'end
 end end
 return true
end
function M.text(b)
 local lines={}
 for _,entry in ipairs({{'ninilite','妮妮莉特'},{'wuyun','乌云'}})do
  local s=b.yingzhaoDeployments and b.yingzhaoDeployments[entry[1]]
  if s and s.status=='adopted'then
   lines[#lines+1]=string.format('%s：%s专项 #%d%s',entry[2],s.algorithm=='yingzhao-qlearning'and'Q学习'or'示范学习',s.id,(s.formalSupportPresent or not s.formalLoadoutMatchesEvaluation)and'（本场配置与虚拟评价有差异）'or'')..'；未覆盖时使用原基础模型'
  elseif s and s.status=='NOT_ADOPTED'then lines[#lines+1]=entry[2]..'：基础模型，未采用部位专项'
  elseif s then lines[#lines+1]=entry[2]..'：专项档案不可用，沿用基础成果，请返回训练室检查。'end
 end
 return table.concat(lines,' · ')
end
return M
