-- Descriptive comparison of validated, frozen trials; never an adoption decision.
local C={};local equal=require('Training.FlowerIdentity').equal
function C.build(basic,candidate)
 for _,record in ipairs({basic,candidate})do
  local ok,why=require('Training.ResourceC45Trials').validate(record);if not ok then return nil,why end
 end
 if not basic or not candidate then return nil,'MISSING_TRIAL'end
 if basic.controller~='basic' or candidate.controller~='candidate' or basic.learner~=candidate.learner or basic.episode.episode==candidate.episode.episode then return nil,'WRONG_CONTROLLERS'end
 if basic.status=='aborted' or candidate.status=='aborted'then return nil,'ABORTED_TRIAL'end
 if not equal(basic.resourceSource,candidate.resourceSource) or not equal(basic.setup,candidate.setup) or not equal(basic.initialHP,candidate.initialHP) or not equal(basic.episode.versions,candidate.episode.versions) or not equal(basic.episode.resources.quote,candidate.episode.resources.quote)then return nil,'SETUP_MISMATCH'end
 return {basic={status=basic.status,cost=basic.episode.resources.spent,seconds=basic.seconds,outcome=basic.episode.outcome},candidate={status=candidate.status,cost=candidate.episode.resources.spent,seconds=candidate.seconds,outcome=candidate.episode.outcome},adoptionEligible=false}
end
function C.latest(policy,models,records)
 for _,candidate in ipairs(records or {})do
  if candidate.controller=='candidate' and equal(candidate.policy,policy) and equal(candidate.setup.models,models)then
   for _,basic in ipairs(records)do
    if basic.controller=='basic'then local pair=C.build(basic,candidate);if pair then return pair end end
   end
  end
 end
end
function C.text(pair)
 if not pair then return '完成同一候选、配装和场景的基础与候选试战后显示资源对照。'end
 local function text(r)return string.format('%s，成本%d，用时%.1f秒',r.status=='won' and '胜利' or '失败',r.cost,r.seconds)end
 return '同配装资源对照：基础'..text(pair.basic)..'；候选'..text(pair.candidate)..'。\n仅一组观察；失败不能因花费少判定为改善，尚不足以采用。'
end
return C
