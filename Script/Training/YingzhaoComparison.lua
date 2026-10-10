-- Paired natural encounters with identical loadouts and mentor assistance.
-- A single pair is descriptive evidence, not a win-rate or adoption decision.
local D=require('Dora');local Mentor=require('Training.YingzhaoMentor');local M={version=1}
function M.runAsync(models,candidate,loadout,onRound,options)
 options=options or {}
 local policy=candidate and candidate.algorithm=='yingzhao-qlearning'and 'Training.YingzhaoQ'or 'Training.YingzhaoPolicy'
 assert(require(policy).validate(candidate),'Invalid candidate')
 local report={schemaVersion=1,trainable=false,locomotion={version=1,enemyRange=800,retreatRatio=.5},supportAccountingVersion=1,controller=Mentor.version,candidate=D.json.decode(D.json.encode(candidate),32),loadout=D.json.decode(D.json.encode(loadout),32),rounds={}}
 if options.candidateId then
  assert(type(options.candidateId)=='number'and options.candidateId%1==0 and options.candidateId>0,'Invalid candidate id')
  report.setup={schemaVersion=1,candidate={id=options.candidateId,algorithm=candidate.algorithm},models=D.json.decode(D.json.encode(models),32),combatRules=require('Training.YingzhaoRules').version,states=options.adoptionStates}
 end
 -- Both rounds reserve the tested actor's skill for its own policy.
 if candidate.actionSetVersion==2 then report.skillControl={version=1,independentActor=candidate.characterId}end
 if options.baseline then
  local baseline=options.baseline;local p=baseline.algorithm=='yingzhao-qlearning'and'Training.YingzhaoQ'or'Training.YingzhaoPolicy'
  assert(baseline.characterId==candidate.characterId and require(p).validate(baseline),'Invalid frozen baseline')
  report.baseline=D.json.decode(D.json.encode(baseline),32)
 end
 if options.companion then
  local companion=options.companion;local p=companion.algorithm=='yingzhao-qlearning'and 'Training.YingzhaoQ'or 'Training.YingzhaoPolicy'
  assert(companion.characterId~=candidate.characterId and require(p).validate(companion),'Invalid companion')
  report.companion=D.json.decode(D.json.encode(companion),32)
 end
 local independent={}
 for _,model in ipairs({candidate,report.baseline or false,report.companion or false})do
  if model and model.actionSetVersion==2 then independent[model.characterId]=true end
 end
 local actors={};for _,actor in ipairs({'ninilite','wuyun'})do if independent[actor]then actors[#actors+1]=actor end end
 if #actors>0 then report.skillControl={version=2,independentActors=actors}end
 for _,mode in ipairs({'baseline','candidate'})do
  local supplies=assert(require('Economy.CombatSession').virtual('yingzhao-compare:'..mode..':'..tostring(D.App.runningTime),loadout))
  local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true,physicalSupport=true})
  if report.companion then require('Training.YingzhaoTrial').attach(b,report.companion)end
  if mode=='candidate'then require('Training.YingzhaoTrial').attach(b,candidate)elseif report.baseline then require('Training.YingzhaoTrial').attach(b,report.baseline)end
  if options.onBattle then options.onBattle(b,mode,#report.rounds+1)end
  assert(b:start());local started=D.App.runningTime;local assistance=Mentor.new(report.skillControl)
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime-started<200,'Comparison exceeded encounter deadline')
   if options.cancelled and options.cancelled()and b.phase=='playing'then b:finish('aborted','对照已停止。')end
   if options.update then options.update(b,mode)end
   Mentor.step(b,assistance)
   D.sleep(.1)
  end
  b.bossTrace.resources=supplies:evidence()
  local armor,health=0,0;for _,hit in ipairs(b.bossTrace.hits)do if hit.target=='big-yingzhao'then armor=armor+hit.armorDamage;health=health+hit.healthDamage end end
  local round={mode=mode,status=b.phase,seconds=D.App.runningTime-started,hp={mentor=b.mentorHP,ninilite=b.arena.studentHP,wuyun=b.wuyun.studentHP},bossHP=b.enemies[1].enemyHP,armorDamage=armor,healthDamage=health,cost=supplies.ledger.spent,shieldEnergy=require('Training.YingzhaoRewards').shieldCost(b.bossTrace),trace=b.bossTrace,decisions=(mode=='candidate'or report.baseline)and b.yingzhaoDecisionsByActor[candidate.characterId]or nil,companion=report.companion and b.yingzhaoCandidates[report.companion.characterId]or nil}
  local account=assert(b.bossTrace.supportAccounting,'Missing actual comparison support account')
  local first,last=account.samples[1],account.samples[#account.samples]
  round.supportSummary={version=1,goldSpent=account.goldSpent,shieldGold=account.shieldGold,upkeepGold=account.upkeepGold,machineDamage=account.machineDamage,initialMachineHP=first.machineHP,finalMachineHP=last.machineHP}
  if report.baseline then round.primaryModel=b.yingzhaoCandidates[candidate.characterId]end
  if report.companion then round.companionDecisions=b.yingzhaoDecisionsByActor[report.companion.characterId] end
  b.bossTrace.partyHP=D.json.decode(D.json.encode(round.hp),32)
  report.rounds[#report.rounds+1]=round;if onRound then onRound(round)end
  if round.status=='aborted'then report.cancelled=true;return report end
 end
 return report
end
function M.text(report)
 local lines={(report.candidate.algorithm=='yingzhao-qlearning'and '自主训练候选' or '示范学习候选')..'：同一虚拟补给与导师协作，仅替换指定学员的策略。'}
 if report.setup and require('Training.YingzhaoRules').current(report.setup)then lines[#lines+1]='两场均使用同样的护盾机、45金粉和有限防护；金粉消耗单独计入评价。'end
 for _,round in ipairs(report.rounds)do
  local label=round.mode=='baseline'and'原策略'or'候选'
  if report.supportAccountingVersion==1 and round.supportSummary then
   local support=round.supportSummary
   lines[#lines+1]=string.format('%s辅助机：金粉消耗 %.2f（护盾 %.2f / 维生 %.2f）\n机体生命 %.0f → %.0f · 承伤 %.0f',label,support.goldSpent,support.shieldGold,support.upkeepGold,support.initialMachineHP,support.finalMachineHP,support.machineDamage)
  elseif round.shieldEnergy~=nil then lines[#lines+1]=string.format('%s实体护盾金粉消耗 %.2f；历史报告未单列维生与机体指标。',label,round.shieldEnergy)end
 end
 lines[#lines+1]='武器耗材与辅助机金粉分别记录；低消耗需结合输出、存活和实际动作判断。'
 if report.locomotion then lines[#lines+1]='移动规则：近敌保持朝向，后退为前进的一半速度。'else lines[#lines+1]='历史记录未保存移动规则，不能直接与当前结果比较。'end
 if report.skillControl then lines[#lines+1]='两场专项策略负责的学员法术均由自身策略决定，导师不代为施放。'end
 if report.baseline then lines[#lines+1]='原策略场次使用此前保存的作战方案，两场的实际动作均可复盘。'end
 if report.companion then lines[#lines+1]='两场均使用同一队友训练方案：'..require('Training.Characters')[report.companion.characterId].name end
 for _,r in ipairs(report.rounds)do lines[#lines+1]=string.format('%s：%s · %.1f秒\n破甲 %.0f · Boss伤害 %.1f · 消耗 %d\n导师 %.0f / 妮妮莉特 %.0f / 乌云 %.0f',r.mode=='baseline'and'原策略'or'候选',({won='获胜',failed='失败',aborted='已停止'})[r.status],r.seconds,r.armorDamage,r.healthDamage,r.cost,r.hp.mentor,r.hp.ninilite,r.hp.wuyun)end
 for _,round in ipairs(report.rounds)do if round.trace and round.trace.resources then lines[#lines+1]=(round.mode=='baseline'and'原策略'or'候选')..' · '..require('Training.YingzhaoContributions').text(round.trace)end end
 for _,round in ipairs(report.rounds)do if round.mode=='candidate'or report.baseline then
  local accepted,unseen,unavailable=0,0,0;local blockers={}
  for _,decision in ipairs(round.decisions or {})do
   if not decision.accepted and decision.reason=='ACTION_UNAVAILABLE'then
    local counted={};for _,cause in pairs(decision.blockedActions or {})do if not counted[cause]then blockers[cause]=(blockers[cause]or 0)+1;counted[cause]=true end end
   end
   if decision.accepted then accepted=accepted+1 elseif decision.reason=='UNSEEN_STATE'or decision.reason=='UNSEEN_ACTIONS'or decision.reason=='NO_MATCH'then unseen=unseen+1 else unavailable=unavailable+1 end
  end
  lines[#lines+1]=string.format('%s动作执行 %d 次 · 未学过的状态/动作 %d 次 · 其他不可执行 %d 次。',round.mode=='baseline'and'原策略'or'候选',accepted,unseen,unavailable)
  local labels={ARENA_BOUNDARY='场景边界',DISPLACED='受击恢复',AIRBORNE='腾空',COOLDOWN='冷却',ENERGY_SHORTAGE='能量不足',PART_UNREACHABLE='角度或遮挡限制',BOSS_HIDDEN='Boss不可见',NO_VISIBLE_SUMMON='无可见援军',NOT_EQUIPPED='未携带武器',OUT_OF_SUPPLIES='弹药耗尽',WEAPON_DISARMED='武器被夺',ACTION_UNAVAILABLE='其他动作限制'}
  local reasons={};for cause,count in pairs(blockers)do reasons[#reasons+1]=(labels[cause]or '其他动作限制')..' '..count..' 次'end;table.sort(reasons)
  if #reasons>0 then lines[#lines+1]='动作限制：'..table.concat(reasons,'、')..'。一次决策可能受多种限制。'end
  local blockedParts={}
  for _,decision in ipairs(round.decisions or {})do
   for action,cause in pairs(decision.blockedActions or {})do
    local part=action:match('^shoot@([%w]+)$')
    if cause=='PART_UNREACHABLE'and part then blockedParts[part]=(blockedParts[part]or 0)+1 end
   end
  end
  local partNames={head='头部',torso='躯干',flank='侧腹',arms='手臂',forelegs='前腿',hindlegs='后腿',summon='援军'}
  local rankedParts={};for part,count in pairs(blockedParts)do rankedParts[#rankedParts+1]={part=part,count=count}end
  table.sort(rankedParts,function(a,b)if a.count~=b.count then return a.count>b.count end;return a.part<b.part end)
  if #rankedParts>0 then
   local descriptions={};for _,entry in ipairs(rankedParts)do descriptions[#descriptions+1]=(partNames[entry.part]or entry.part)..' '..entry.count..' 次'end
   lines[#lines+1]='瞄准受阻部位：'..table.concat(descriptions,'、')..'。'
   lines[#lines+1]='补练建议：示范目标被挡住时的移动、等待或更换部位。'
  end
  if unseen>0 then
   local gaps={}
   local actions={hidden='不可见',idle='待机',punch='拳击',massive='连斩',hunt='召援',wave='冲击波',hero='连续技',hit='受击',lose='倒下'}
   local targets={none='无目标',boss='Boss',summon='援军'}
   local distances={unknown='距离未知',near='近距离',mid='中距离',far='远距离'}
   for _,decision in ipairs(round.decisions or {})do
    local s=decision.observation
    if not decision.accepted and (decision.reason=='NO_MATCH'or decision.reason=='UNSEEN_STATE'or decision.reason=='UNSEEN_ACTIONS')and s then
     local label=(actions[s.bossAction]or '未知动作')..' / '..(targets[s.target]or '未知目标')..' / '..(distances[s.targetDistance]or '距离未知')
     gaps[label]=(gaps[label]or 0)+1
    end
   end
   local ranked={};for label,count in pairs(gaps)do ranked[#ranked+1]={label=label,count=count}end
   table.sort(ranked,function(a,b)if a.count~=b.count then return a.count>b.count end;return a.label<b.label end)
   if #ranked>0 then
    lines[#lines+1]='优先补练的实际场景：'
    for i=1,math.min(5,#ranked)do local gap=ranked[i];lines[#lines+1]=string.format('%s：%d 次',gap.label,gap.count)end
    if #ranked>5 then lines[#lines+1]=string.format('另有 %d 类场景保留在记录中。',#ranked-5)end
   end
   lines[#lines+1]='请补充未覆盖状态的示范或训练；这些次数不表示角色被动作锁定。'
  end
  if accepted==0 then table.insert(lines,2,(round.mode=='baseline'and'本轮原策略'or'本轮候选')..'未执行动作；较低消耗不能视为战术改善，请补充训练。')end
 end end
 for _,round in ipairs(report.rounds)do lines[#lines+1]=(round.mode=='baseline'and'原策略'or'候选')..' · '..require('Training.YingzhaoThreatReview').text(round.trace)end
 if report.companion then
  for _,round in ipairs(report.rounds)do if round.companionDecisions then
   local accepted,unseen,unavailable=0,0,0
   for _,d in ipairs(round.companionDecisions)do
    if d.accepted then accepted=accepted+1
    elseif d.reason=='NO_MATCH'or d.reason=='UNSEEN_STATE'or d.reason=='UNSEEN_ACTIONS'then unseen=unseen+1
    else unavailable=unavailable+1 end
   end
   lines[#lines+1]=string.format('%s中的队友%s：动作执行 %d 次 · 未学过的状态/动作 %d 次 · 其他不可执行 %d 次。',round.mode=='baseline'and'原策略场次'or'候选场次',require('Training.Characters')[report.companion.characterId].name,accepted,unseen,unavailable)
  end end
 end
 lines[#lines+1]=report.cancelled and '本组未完成，不能比较效果。'or'这是一组固定顺序观察，不能据此判断稳定胜率；未自动采用。'

 return table.concat(lines,'\n\n')
end
return M
