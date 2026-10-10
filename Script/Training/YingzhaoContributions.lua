-- Display-only accounting from validated battle traces. No rewards or policy updates.
local M={};local order={'mentor','ninilite','wuyun'}
local names={mentor='导师',ninilite='妮妮莉特',wuyun='乌云'}
function M.summarize(trace)
 local result={actors={},deployment=trace.resources.quote.deployment,totalCost=trace.resources.spent,actionCost=0}
 for _,actor in ipairs(order)do result.actors[actor]={bossDamage=0,summonDamage=0,armor=0,kills=0,cost=0,noDamageCost=0,empNoEffectBossHits=0,empKnownExposedHits=0,empNoEffectCost=0,damageTaken=trace.vitals and 0 or nil}end
 local effects,dead,empSteps={},{},{}
 for _,hit in ipairs(trace.hits)do
  local actor=result.actors[hit.source]
  if actor then
   actor.armor=actor.armor+(hit.armorDamage or 0)
   if hit.summoned then
    actor.summonDamage=actor.summonDamage+hit.healthDamage
    if hit.killed and not dead[hit.target]then actor.kills=actor.kills+1;dead[hit.target]=true end
   elseif hit.target=='big-yingzhao'then actor.bossDamage=actor.bossDamage+hit.healthDamage end
  end
  if hit.step and ((hit.healthDamage or 0)>0 or (hit.armorDamage or 0)>0)then effects[hit.step]=true end
  if actor and hit.weapon=='emp'and hit.target=='big-yingzhao'and (hit.armorDamage or 0)==0 and (hit.healthDamage or 0)==0 then
   actor.empNoEffectBossHits=actor.empNoEffectBossHits+1
   if hit.step then
    empSteps[hit.step]=true
    local step=trace.steps and trace.steps[hit.step]
    if step and step.aim and step.aim.intent==hit.part and step.before['part_'..hit.part]=='exposed'then
     actor.empKnownExposedHits=actor.empKnownExposedHits+1
    end
   end
  end
 end
 if trace.flightVersion==1 then
  assert(require('Enemy.BigYingzhaoFlightEvidence').validate(trace),'Invalid projectile outcomes')
  for _,actor in pairs(result.actors)do actor.flights={contact=0,terrain=0,removed=0,cancelled=0,rejected=0,firearm=0,fire=0}end
  for _,flight in ipairs(trace.flights)do
   local count=result.actors[flight.actor].flights
   local key=flight.reason=='battle-ended'and'cancelled'or flight.reason=='contact-rejected'and'rejected'or flight.reason
   count[key]=count[key]+1;local kind=flight.kind or 'firearm';count[kind]=count[kind]+1
  end
 end
 for _,event in pairs(trace.resources.events)do
  local actor=result.actors[event.performer];assert(actor,'Unknown resource performer')
  actor.cost=actor.cost+event.cost;result.actionCost=result.actionCost+event.cost
  if not effects[event.step]then
   actor.noDamageCost=actor.noDamageCost+event.cost
   if event.item=='emp'and empSteps[event.step]then actor.empNoEffectCost=actor.empNoEffectCost+event.cost end
  end
 end
 if trace.vitals then for _,event in ipairs(trace.vitals.events)do local actor=result.actors[event.actor];if actor then actor.damageTaken=actor.damageTaken+event.damage end end end
 assert(result.actionCost+result.deployment==result.totalCost,'Contribution costs must reconcile')
 return result
end
function M.text(trace)
 local r=M.summarize(trace);local rows={string.format('队伍贡献（耗材 %d，整备另计 %d）',r.actionCost,r.deployment)}
 for _,id in ipairs(order)do local a=r.actors[id]
  rows[#rows+1]=string.format('%s：Boss伤害 %.1f · 援军伤害 %.1f · 破甲 %.0f · 击倒援军 %d\n耗材 %d（未造成伤害或破甲 %d） · %s',names[id],a.bossDamage,a.summonDamage,a.armor,a.kills,a.cost,a.noDamageCost,a.damageTaken and string.format('承伤 %.0f',a.damageTaken)or'承伤未记录')
  if a.flights then local f=a.flights
   rows[#rows+1]=string.format('射弹记录（实弹/EMP %d，火羽 %d）：接触 %d · 地形遮挡 %d · 消失前无接触记录 %d · 战斗结束取消 %d · 接触未结算 %d',f.firearm,f.fire,f.contact,f.terrain,f.removed,f.cancelled,f.rejected)
  end
 end
 for _,id in ipairs(order)do local a=r.actors[id]
  if a.empNoEffectBossHits>0 then
   rows[#rows+1]=string.format('%s：EMP命中Boss但未改变护甲或生命 %d 次，对应耗材 %d；其中瞄准时已知该部位破甲 %d 次。',names[id],a.empNoEffectBossHits,a.empNoEffectCost,a.empKnownExposedHits)
  end
 end
 local empNoEffect=0;for _,a in pairs(r.actors)do empNoEffect=empNoEffect+a.empNoEffectBossHits end
 if empNoEffect>0 then rows[#rows+1]='补练建议：EMP只削减护甲。目标部位已破甲时，示范转向仍有护甲的部位，或移动、等待、使用角色技能；实弹负责生命伤害。'end
 rows[#rows+1]=require('Training.YingzhaoSurvivalFeedback').text(trace.vitals)
 rows[#rows+1]='未造成伤害或破甲包含落空、遮挡和无效命中；不代表没有控制或掩护作用。'
 return table.concat(rows,'\n')
end
return M
