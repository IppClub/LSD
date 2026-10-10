-- A descriptive pre-adoption checklist, not permission to deploy a model.
local M={minimumRuns=3}
function M.build(groups)
 local result={missing={},sparse={},regressions={},failures={},compared=0,outdated=0,resourceFallback=0,adoptionEligible=false}
 for _,g in ipairs(groups or {})do result.resourceFallback=math.max(result.resourceFallback,g.key.setup and g.key.setup.resourceFallback or 0)end
 local covered={};local candidate
 for _,g in ipairs(groups or {})do
  assert(not candidate or candidate==g.key.candidate,'MIXED_CANDIDATES');candidate=g.key.candidate
  if (g.key.setup and g.key.setup.resourceFallback or 0)<result.resourceFallback then result.outdated=result.outdated+1 else
  local a,b=g.basic,g.evaluate
  local label=require('Training.FlowerScenarios').get(g.key.profile).name..' · 预算'..g.key.quote.total
  if a.count>0 and b.count>0 then
   result.compared=result.compared+1;covered[g.key.profile]=true
   if b.wins/b.count<a.wins/a.count then result.regressions[#result.regressions+1]=label..'：候选任务完成比例更低。'end
   if a.wins>0 and b.wins>0 and b.winCost/b.wins>a.winCost/a.wins then result.regressions[#result.regressions+1]=string.format('%s：候选平均成功成本高 %.1f。',label,b.winCost/b.wins-a.winCost/a.wins)end
  end
  if a.count<M.minimumRuns or b.count<M.minimumRuns then result.sparse[#result.sparse+1]=string.format('%s：基础%d / 候选%d场。',label,a.count,b.count)end
  if a.wins<a.count or b.wins<b.count then result.failures[#result.failures+1]=label..'：存在未完成回合，先检查失败原因。'end
  end
 end
 for _,profile in ipairs(require('Training.FlowerScenarios').resourceIds)do
  if not covered[profile]then result.missing[#result.missing+1]=require('Training.FlowerScenarios').get(profile).name end
 end
 result.candidate=candidate
 return result
end
function M.text(a)
 local lines={'采用前检查（各场景、配装分别比较）'}
 if a.outdated>0 then lines[#lines+1]=string.format('另有%d组旧回退规则记录，保留在分组中，不计入当前规则评价。',a.outdated)end
 if #a.regressions>0 then lines[#lines+1]='当前存在退步，不建议采用：';for _,s in ipairs(a.regressions)do lines[#lines+1]=s end end
 for _,s in ipairs(a.failures)do lines[#lines+1]=s end
 if #a.missing>0 then lines[#lines+1]='缺少完整基础/候选对照：'..table.concat(a.missing,'、')..'。'end
 if #a.sparse>0 then
  lines[#lines+1]='重复样本不足（每种配置双方至少3场，只是观察起点）：'
  for _,s in ipairs(a.sparse)do lines[#lines+1]=s end
 end
 if #a.regressions==0 and #a.failures==0 and #a.missing==0 and #a.sparse==0 then lines[#lines+1]='当前检查未发现上述缺项；仍需更多预算与实际任务验证。'end
 lines[#lines+1]='训练来源轮数不等于效果；不同预算、场景和候选的成本不合并。'
 lines[#lines+1]='资源候选仍处于试验阶段，尚未用于正式任务。'
 return table.concat(lines,'\n')
end
return M
