-- Versioned outcome accounting, not a Q transition or a deployment score.
-- A hit contributes once; HP damage and armor damage are distinct benefits.
local M={version=3,supportPolicy='yingzhao-economy-survival-support-v3',policy='yingzhao-economy-survival-shield-v2',legacyPolicy='yingzhao-economy-survival-v1'}
function M.supports(policy)return policy==M.supportPolicy or policy==M.policy or policy==M.legacyPolicy end
function M.shieldCost(trace,from,to)
 local cost=0
 for _,event in ipairs(trace.physicalShield and trace.physicalShield.events or {})do
  if event.kind=='impact'and(not from or event.at>from)and(not to or event.at<=to)then cost=cost+event.goldBefore-event.goldAfter end
 end
 return cost
end
-- Caller validates the full episode once; this reads its exact counter range.
function M.supportCost(trace,first,last)
 if not trace.physicalShield and not trace.supportAccounting then return {goldSpent=0,shieldGold=0,upkeepGold=0,machineDamage=0}end
 local r=trace.supportAccounting
 if trace.supportAccountingVersion~=1 or type(r)~='table'or not r.closed then return nil,'MISSING_SUPPORT_ACCOUNT'end
 if first==nil and last==nil then first=1;last=#r.samples end
 return require('Training.YingzhaoSupportAccounting').interval(r,first,last)
end
M.weights={armor=.25,health=1,cost=1,ownDamage=2,allyDamage=.5,machineDamage=1,won=100,failed=-100}
function M.rebuild(e,actor,policy)
 if actor~='ninilite'and actor~='wuyun'and actor~='mentor'then return nil,'INVALID_CHARACTER'end
 local E=require('Enemy.BigYingzhaoEvidence');local ok,why
 if e and e.kind=='big-yingzhao-demonstration'then ok,why=E.validateVirtual(e)
 elseif e and e.resources and e.resources.mode=='mission'then ok,why=E.validate(e)
 else ok,why=E.validateEvaluation(e)end
 if not ok then return nil,why end
 policy=policy or e.rewardPolicy or (e.boss.physicalShield and M.policy or M.legacyPolicy)
 if not M.supports(policy)or policy==M.legacyPolicy and e.boss.physicalShield then return nil,'INCOMPATIBLE_PROTECTION_REWARD'end
 local v=e.boss.vitals;if not require('Training.YingzhaoVitals').validate(v)then return nil,'MISSING_VALID_VITALS'end
 local r={schemaVersion=1,policy=policy,trainable=false,actor=actor,armor=0,health=0,consumption=0,deployment=0,ownDamage=0,allyDamage=0,hits=0,damageEvents=0,status=e.boss.status}
 for _,h in ipairs(e.boss.hits)do if h.source==actor then r.armor=r.armor+(h.armorDamage or 0);r.health=r.health+(h.healthDamage or 0);r.hits=r.hits+1 end end
 for _,event in pairs(e.resources.events)do if event.owner==actor then r.consumption=r.consumption+event.cost end end
 for _,line in ipairs(e.resources.quote.lines)do if line.actor==actor then r.deployment=r.deployment+line.deploy end end
 for _,event in ipairs(v.events)do if event.actor==actor then r.ownDamage=r.ownDamage+event.damage else r.allyDamage=r.allyDamage+event.damage end;if event.damage>0 then r.damageEvents=r.damageEvents+1 end end
 if policy==M.policy then r.shieldEnergy=M.shieldCost(e.boss)end
 if policy==M.supportPolicy then
  local cost,why=M.supportCost(e.boss);if not cost then return nil,why end
  r.shieldEnergy=cost.shieldGold;r.upkeepEnergy=cost.upkeepGold;r.machineDamage=cost.machineDamage
 end
 local w=M.weights
 r.components={armor=r.armor*w.armor,health=r.health*w.health,cost=-(r.consumption+r.deployment)*w.cost,ownDamage=-r.ownDamage*w.ownDamage,allyDamage=-r.allyDamage*w.allyDamage,outcome=r.status=='won'and w.won or r.status=='failed'and w.failed or 0}
 if policy==M.policy or policy==M.supportPolicy then r.components.shieldEnergy=-r.shieldEnergy*w.cost end
 if policy==M.supportPolicy then r.components.upkeepEnergy=-r.upkeepEnergy*w.cost;r.components.machineDamage=-r.machineDamage*w.machineDamage end
 r.total=(r.components.upkeepEnergy or 0)+(r.components.machineDamage or 0)+(r.components.shieldEnergy or 0)+r.components.armor+r.components.health+r.components.cost+r.components.ownDamage+r.components.allyDamage+r.components.outcome
 r.terminal=r.status=='won'or r.status=='failed'
 return r
end
return M
