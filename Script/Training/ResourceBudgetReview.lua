-- Group only disjoint matched trials. Spending less on a loss is not improvement.
local M={};local equal=require('Training.FlowerIdentity').equal
local C=require('Training.ResourceC45Comparison')
local O=require('Factory.Outcome')
local function countFacts(counts,result)
 local o=result.outcome
 if not O.valid(o)then counts.unknown=counts.unknown+1;return end
 counts.known=counts.known+1
 if o.enemiesRemaining==0 and o.partyAlive then
  counts.cleared=counts.cleared+1
  if not O.storyComplete(o)then counts.storyMissing=counts.storyMissing+1 end
 end
end
local function facts()return {known=0,unknown=0,cleared=0,storyMissing=0}end
function M.build(policy,models,records)
 local groups,used={},{}
 for _,candidate in ipairs(records or {})do
  local id=candidate.episode and candidate.episode.episode
  if id and not used[id]and candidate.controller=='candidate'and equal(candidate.policy,policy)and candidate.setup and equal(candidate.setup.models,models)then
   for _,basic in ipairs(records)do
    local bid=basic.episode and basic.episode.episode
    if bid and not used[bid]and basic.controller=='basic'then
     local pair=C.build(basic,candidate)
     if pair then
      used[id]=true;used[bid]=true
      local group
      for _,g in ipairs(groups)do
       if equal(g.versions,candidate.episode.versions)and equal(g.quote,candidate.episode.resources.quote)and equal(g.setup,candidate.setup)and equal(g.initialHP,candidate.initialHP)and equal(g.source,candidate.resourceSource)then group=g;break end
      end
      if not group then group={versions=candidate.episode.versions,basicFacts=facts(),candidateFacts=facts(),quote=candidate.episode.resources.quote,setup=candidate.setup,initialHP=candidate.initialHP,source=candidate.resourceSource,pairs={},basicWins=0,candidateWins=0,jointWins=0,basicWinningCost=0,candidateWinningCost=0};groups[#groups+1]=group end
      group.pairs[#group.pairs+1]={basicEpisode=bid,candidateEpisode=id,comparison=pair}
      countFacts(group.basicFacts,pair.basic);countFacts(group.candidateFacts,pair.candidate)
      if pair.basic.status=='won'then group.basicWins=group.basicWins+1 end
      if pair.candidate.status=='won'then group.candidateWins=group.candidateWins+1 end
      if pair.basic.status=='won'and pair.candidate.status=='won'then group.jointWins=group.jointWins+1;group.basicWinningCost=group.basicWinningCost+pair.basic.cost;group.candidateWinningCost=group.candidateWinningCost+pair.candidate.cost end
      break
     end
    end
   end
  end
 end
 return {groups=groups,adoptionEligible=false}
end
function M.text(review)
 if not review or #review.groups==0 then return '完成同一配装的基础与候选试战后显示分组对照。'end
 local lines={'同配装资源对照（基础 / 候选）：'}
 for i,g in ipairs(review.groups)do
  if i>3 then lines[#lines+1]='另有'..(#review.groups-3)..'组配装记录。';break end
  local n=#g.pairs
  local row=(g.setup.profile and g.setup.profile.name or '标准战况')..' · '..string.format('预算%d：任务完成%d/%d / %d/%d',g.quote.total,g.basicWins,n,g.candidateWins,n)
  if g.jointWins>0 then row=row..string.format('；同胜%d组平均成本%.1f / %.1f',g.jointWins,g.basicWinningCost/g.jointWins,g.candidateWinningCost/g.jointWins)else row=row..'；没有双方获胜的成本对照'end
  row=row..(g.setup.trainingGoal=='resource-clear-v1' and '〔存活清场目标〕' or '〔含剧情条件〕')
  lines[#lines+1]=row
  local b,c=g.basicFacts,g.candidateFacts
  if b.known+c.known>0 then
   lines[#lines+1]=string.format('存活清场%d/%d / %d/%d；清场但剧情未完成%d / %d',b.cleared,b.known,c.cleared,c.known,b.storyMissing,c.storyMissing)
  end
  if b.unknown+c.unknown>0 then lines[#lines+1]=string.format('缺少分项记录%d / %d轮，不计入清场率。',b.unknown,c.unknown)end
 end
 lines[#lines+1]='失败不按低成本判优；仅限已保存配装，尚不足以采用。'
 return table.concat(lines,'\n')
end
return M
