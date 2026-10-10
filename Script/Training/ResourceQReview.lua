-- Display aggregation only. Callers supply revalidated ResourceQTrials rows.
local equal=require('Training.FlowerIdentity').equal;local R={}
local actors={mentor='导师',ninilite='妮妮莉特',wuyun='乌云'}
local weapons={kinetic='实弹',emp='EMP',blade='近战',laser='激光'}
local function stats()return {count=0,wins=0,cost=0,seconds=0,winCost=0,winSeconds=0,empCost=0,fallbackEmpCost=0,zeroProgressEmpCost=0,qDecisions=0,fallbackDecisions=0,diagnosed=0}end
local function quoteKey(quote)
 local lines={};for _,line in ipairs(quote.lines)do lines[#lines+1]={actor=line.actor,item=line.item,quantity=line.quantity,unit=line.unit,deploy=line.deploy}end
 table.sort(lines,function(a,b)return a.actor..':'..a.item<b.actor..':'..b.item end)
 return {priceVersion=quote.priceVersion,total=quote.total,deployment=quote.deployment,lines=lines}
end
function R.build(records)
 local groups,seen={},{}
 for _,entry in ipairs(records)do
  local record,facts=entry.record,entry.facts;local episode=record.episode.episode
  assert(not seen[episode],'DUPLICATE_TRIAL');seen[episode]=true
  assert(record.mode=='basic' or record.mode=='evaluate','INVALID_TRIAL_MODE')
  assert(facts.status==record.status and (facts.status=='won' or facts.status=='failed'),'INVALID_TRIAL_STATUS')
  assert(type(facts.cost)=='number'and facts.cost>=0 and facts.cost<math.huge,'INVALID_TRIAL_COST')
  local seconds=facts.telemetry.seconds;assert(type(seconds)=='number'and seconds>0 and seconds<math.huge,'MISSING_TRIAL_TIME')
  local key={candidate=record.candidate,profile=record.profile,setup=record.setup,quote=quoteKey(record.episode.resources.quote)}
  local group;for _,item in ipairs(groups)do if equal(item.key,key)then group=item;break end end
  if not group then group={sourceProfiles=facts.sourceProfiles,key=key,basic=stats(),evaluate=stats()};groups[#groups+1]=group end
  local s=group[record.mode];s.count=s.count+1;s.cost=s.cost+facts.cost;s.seconds=s.seconds+seconds
  local actorFacts=facts.telemetry.actors
  if actorFacts and actorFacts.ninilite.empCost~=nil and actorFacts.wuyun.empCost~=nil then
   s.diagnosed=s.diagnosed+1
   for _,actor in ipairs({'ninilite','wuyun'})do local a=actorFacts[actor];s.qDecisions=s.qDecisions+a.q;s.fallbackDecisions=s.fallbackDecisions+a.fallback;s.empCost=s.empCost+a.empCost;s.fallbackEmpCost=s.fallbackEmpCost+a.fallbackEmpCost;s.zeroProgressEmpCost=s.zeroProgressEmpCost+a.zeroProgressEmpCost end
  end
  if facts.status=='won'then s.wins=s.wins+1;s.winCost=s.winCost+facts.cost;s.winSeconds=s.winSeconds+seconds end
 end
 return groups
end
function R.text(group)
 if not group then return '尚无完整资源试战记录。\n先使用相同配置完成“资源基础对照”和“资源候选试战”。'end
 local q=group.key.quote;local loadout={}
 for _,line in ipairs(q.lines)do loadout[#loadout+1]=(actors[line.actor]or line.actor)..' '..(weapons[line.item]or line.item)..' '..line.quantity end
 local lines={group.key.setup.trainingGoal=='resource-clear-v1' and '训练目标：全队存活并清场' or '训练目标：清场及剧情条件',string.format('预算上限 %d · 整备 %d',q.total,q.deployment),table.concat(loadout,' / '),'同一总预算但武器数量不同，也会分开比较。',''}
 table.insert(lines,2,require('Training.ResourceSourceCoverage').text(group.sourceProfiles,group.key.profile))
 if group.key.setup.resourceFallback==3 then table.insert(lines,2,'基础回退：对花苞、小花妖及已知全破甲Boss保留EMP；候选动作仍独立执行。')
 elseif group.key.setup.resourceFallback~=nil then table.insert(lines,2,'基础回退：已知目标为全破甲Boss时保留EMP；候选动作仍独立执行。')end
 if group.key.setup.continuousMovement==1 then table.insert(lines,2,'动作规则：支持继续等待或移动')end
 for _,mode in ipairs({'basic','evaluate'})do
  local s=group[mode];lines[#lines+1]=mode=='basic' and '基础策略' or '资源候选'
  if s.count==0 then lines[#lines+1]='尚无完整试战。'
  else
   lines[#lines+1]=string.format('胜利 %d / %d · 失败 %d',s.wins,s.count,s.count-s.wins)
   lines[#lines+1]=string.format('每次平均消耗 %.1f（含失败）· 平均用时 %.1f秒',s.cost/s.count,s.seconds/s.count)
   lines[#lines+1]=s.wins>0 and string.format('仅胜利场次：平均消耗 %.1f · 用时 %.1f秒',s.winCost/s.wins,s.winSeconds/s.wins)or '尚无胜利，不能计算成功完成任务的平均成本。'
  end
  if s.diagnosed>0 then
   lines[#lines+1]=string.format('可追溯回合中：候选决策%d次 · 基础回退%d次。',s.qDecisions,s.fallbackDecisions)
   if s.qDecisions==0 then lines[#lines+1]='这些回合没有执行候选决策，收益变化不能归因为学会了新策略。'end
   lines[#lines+1]=string.format('可追溯%d场：学员EMP成本%d，其中基础回退%d；无有效伤害/破甲贡献的EMP成本%d。',s.diagnosed,s.empCost,s.fallbackEmpCost,s.zeroProgressEmpCost)
   if s.fallbackEmpCost>0 then lines[#lines+1]='存在未覆盖状态的基础回退，请补充相同资源与站位条件下的训练。'end
  end
  lines[#lines+1]=''
 end
 local a,b=group.basic,group.evaluate
 if a.count==0 or b.count==0 then lines[#lines+1]='缺少同配置对照，暂不能判断变化。'
 elseif a.wins==0 and b.wins==0 then lines[#lines+1]='两组均未取得胜利；少花资源不能代替完成任务。'
 elseif b.wins/b.count<a.wins/a.count then lines[#lines+1]='候选胜利比例较低，不能只根据消耗判定改善。'
 else lines[#lines+1]='先看任务完成情况，再比较胜利场次成本；不会自动采用候选。'end
 if a.wins>0 and b.wins>0 then
  local delta=b.winCost/b.wins-a.winCost/a.wins
  if delta>0 then lines[#lines+1]=string.format('候选平均成功成本高于基础 %.1f；本组未显示节省资源。',delta)
  elseif delta<0 then lines[#lines+1]=string.format('候选平均成功成本低于基础 %.1f；仍需结合完成率和更多试战。',-delta)
  else lines[#lines+1]='双方平均成功成本相同。'end
 end
 if a.count<3 or b.count<3 then lines[#lines+1]='样本较少，目前只作观察，不代表稳定胜率。'end
 return table.concat(lines,'\n')
end
return R
