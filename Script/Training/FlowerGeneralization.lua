-- Coverage review of evaluation-only profiles, kept separate from repeated
-- standard-encounter review. No profile result alone authorizes adoption.
local G={};local equal=require('Training.FlowerIdentity').equal
function G.latest(actor,policy,models,records)
 if not policy then return nil,'NO_CANDIDATE'end
 local rows,why=records;if not rows then rows,why=require('Training.FlowerTrialStore').history(actor)end;if not rows then return nil,why end
 local result={schemaVersion=1,scope='held-out-profile-observations',pairs={},missing={},completed=0,required=3,basicWins=0,candidateWins=0,adoptionEligible=false}
 for _,id in ipairs(require('Training.FlowerScenarios').ids)do
  local candidate,basic
  for _,r in ipairs(rows)do
   if r.status~='aborted' and r.setup.scenario=='flower-practice-v3' and r.setup.profile.id==id and equal(r.setup.models,models)then
    if r.controller=='candidate' and not candidate and equal(r.policy,policy)then candidate=r
    elseif r.controller=='basic' and not basic then basic=r end
   end
  end
  if candidate and basic then
   local comparison,why=require('Training.FlowerComparison').build(basic,candidate);if not comparison then return nil,why end
   result.pairs[id]=comparison;result.completed=result.completed+1
   result.basicWins=result.basicWins+(comparison.basic.won and 1 or 0);result.candidateWins=result.candidateWins+(comparison.candidate.won and 1 or 0)
  else result.missing[#result.missing+1]=id end
 end
 return result
end
function G.text(r)
 if not r then return ''end
 return string.format('专项评价：%d/%d配置 · 基础胜%d / 候选胜%d（记录覆盖不等于通过）',r.completed,r.required,r.basicWins,r.candidateWins)
end
return G
