-- Summarize already validated trials; every stored repetition contributes once.
local R={};local ids={'near','far','reproduction','field'}
local metrics={'health','armor','assistedHealth','teamDamage','friendlyDamage'}
local function bucket()local b={count=0,won=0,failed=0,episodes={},mean={},timed=0,winSeconds=0,lossSeconds=0,timedWins=0,timedLosses=0,sourceGames=0,q=0,fallback=0};for _,k in ipairs(metrics)do b.mean[k]=0 end;return b end
function R.build(candidate,records,hitReaction,qFeatureVersion)
 local excluded
 if hitReaction then
  local selected={};excluded=0
  for _,row in ipairs(records)do if row.setup.hitReaction==hitReaction and (not qFeatureVersion or row.setup.qFeatureVersion==qFeatureVersion)then selected[#selected+1]=row else excluded=excluded+1 end end
  records=selected
 end
 local result={candidate=candidate,completed=0,total=#records,profiles={},adoptionEligible=false};local seen={}
 if hitReaction then result.hitReaction=hitReaction;result.qFeatureVersion=qFeatureVersion;result.excluded=excluded end
 for _,id in ipairs(ids)do result.profiles[id]={basic=bucket(),evaluate=bucket()}end
 for _,row in ipairs(records)do
  assert(row.candidate==candidate,'MIXED_Q_VERSIONS');assert(not seen[row.episode.episode],'DUPLICATE_EPISODE');seen[row.episode.episode]=true
  local profile=assert(result.profiles[row.profile],'UNKNOWN_PROFILE')
  if profile.setup then assert(require('Training.FlowerIdentity').equal(profile.setup,row.setup),'MIXED_Q_SETUPS')else profile.setup=row.setup end
  local b=assert(profile[row.mode],'EXPLORING_TRIAL');assert(row.status=='won' or row.status=='failed','INCOMPLETE_TRIAL')
  local telemetry=row.telemetry or {}
  if telemetry.seconds then b.timed=b.timed+1;if row.status=='won'then b.timedWins=b.timedWins+1;b.winSeconds=b.winSeconds+telemetry.seconds else b.timedLosses=b.timedLosses+1;b.lossSeconds=b.lossSeconds+telemetry.seconds end end
  if telemetry.actors then b.sourceGames=b.sourceGames+1;for _,id in ipairs({'ninilite','wuyun'})do b.q=b.q+telemetry.actors[id].q;b.fallback=b.fallback+telemetry.actors[id].fallback end end
  b.count=b.count+1;b[row.status]=b[row.status]+1;b.episodes[#b.episodes+1]=row.episode.episode
  for _,id in ipairs({'mentor','ninilite','wuyun'})do
   local a=assert(row.facts.actors[id]);b.mean.teamDamage=b.mean.teamDamage+a.damageTaken;b.mean.friendlyDamage=b.mean.friendlyDamage+a.friendlyDamage
   if id~='mentor'then for _,key in ipairs({'health','armor','assistedHealth'})do b.mean[key]=b.mean[key]+a[key]end end
  end
 end
 for _,id in ipairs(ids)do local p=result.profiles[id]
  for _,mode in ipairs({'basic','evaluate'})do local b=p[mode];if b.count>0 then for _,k in ipairs(metrics)do b.mean[k]=b.mean[k]/b.count end end end
  if p.basic.count>0 and p.evaluate.count>0 then result.completed=result.completed+1;p.delta={};for _,k in ipairs(metrics)do p.delta[k]=p.evaluate.mean[k]-p.basic.mean[k]end end
 end
 return result
end
function R.text(review,profile)
 local p=assert(review.profiles[profile]);local lines={string.format('候选 #%d · 已保存%d场 · 对照覆盖%d/4',review.candidate,review.total,review.completed),
  '本页汇总同一候选、同场景的全部已保存试战，包含失败。'}
 if review.excluded then lines[#lines+1]=string.format('当前规则评价；另有%d场旧规则记录保留，未混入本次统计。',review.excluded)end
 for _,mode in ipairs({'basic','evaluate'})do local b=p[mode];local name=mode=='basic' and '基础策略' or '候选策略'
  lines[#lines+1]=string.format('%s：%d场 · %d胜 / %d负',name,b.count,b.won,b.failed)
  if b.count>0 then lines[#lines+1]=string.format('场均：学员输出%.1f · 削甲%.1f · 破甲协作%.1f',b.mean.health,b.mean.armor,b.mean.assistedHealth)
   lines[#lines+1]=string.format('场均：队伍承伤%.1f · 队伍误伤%.1f',b.mean.teamDamage,b.mean.friendlyDamage)
  else lines[#lines+1]='尚无记录；缺失不按零伤害处理。'end
  lines[#lines+1]=string.format('用时采集%d/%d场 · 胜局均值%s · 败局均值%s',b.timed,b.count,b.timedWins>0 and string.format('%.1f秒',b.winSeconds/b.timedWins) or '未采集',b.timedLosses>0 and string.format('%.1f秒',b.lossSeconds/b.timedLosses) or '未采集')
  if mode=='evaluate'then lines[#lines+1]=b.sourceGames>0 and string.format('决策来源采集%d/%d场 · 已执行Q选择%d / 基础回退%d',b.sourceGames,b.count,b.q,b.fallback) or string.format('决策来源采集0/%d场 · Q选择与基础回退次数未采集',b.count)end
 end
 if p.delta then lines[#lines+1]=string.format('候选减基础：削甲%+.1f · 承伤%+.1f · 误伤%+.1f',p.delta.armor,p.delta.teamDamage,p.delta.friendlyDamage)
 else lines[#lines+1]='本场景尚缺基础或候选试战，暂不计算差值。'end
 lines[#lines+1]='输出、削甲和协作统计两名学员；承伤与误伤统计全队。'
 lines[#lines+1]='失败与胜利共同计入均值；短局可能输出更少，不能据此判断优劣。'
 lines[#lines+1]='场次数可能不同；这是观察对照，未证明稳定收益，也未证明属于未见训练场景。'
 lines[#lines+1]='旧记录未采集的字段不补零；决策统计仅含已执行动作，不含拒绝或等待。'
 lines[#lines+1]='是否采用由玩家决定，评价不会自动替换正式策略。'
 return table.concat(lines,'\n')
end
return R
