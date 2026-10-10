-- Actual decision-time life-support facts, consumed by observation schema 10.
local M={version=1,names={'lifePower','machineHealth','squadSpan'}}
M.categories={lifePower='unknown absent stopped critical low ready',machineHealth='unknown fallen danger wounded healthy',squadSpan='unknown compact spread wide'}
local function finite(x)return type(x)=='number'and x==x and math.abs(x)<math.huge end
local function close(a,b)return math.abs(a-b)<=1e-6*(1+math.abs(a)+math.abs(b))end
function M.observe(support)
 if not support then return {schemaVersion=1,present=false}end
 local energy=support:energyObservation()
 return {schemaVersion=1,lifeRuleVersion=support.ruleVersion,present=true,gold=support.gold,machineHP=support.machineHP,span=energy.span,rate=energy.rate,seconds=energy.seconds,powered=energy.powered}
end
function M.project(o)
 if type(o)~='table'or o.schemaVersion~=1 or type(o.present)~='boolean'then return end
 if not o.present then return {lifePower='absent',machineHealth='unknown',squadSpan='unknown'}end
 for _,name in ipairs({'gold','machineHP','span','rate','seconds'})do if not finite(o[name])then return end end
 if o.gold<0 or o.gold>90 or o.machineHP<0 or o.machineHP>100 or o.span<0 or o.rate<=0 or o.seconds<0 or type(o.powered)~='boolean'then return end
 -- The public warning uses the actual upkeep lifetime, excluding future hits.
 local Support=require('Ground.LifeSupport')
 if o.lifeRuleVersion~=Support.version then return end
 local rate=Support.energyRate({span=o.span})
 local seconds=o.machineHP>0 and o.gold/rate or 0
 local powered=o.machineHP>0 and o.gold>0
 if not close(o.rate,rate)or not close(o.seconds,seconds)or o.powered~=powered then return end
 local life=not powered and 'stopped'or seconds<=10 and 'critical'or seconds<=20 and 'low'or 'ready'
 local hp=o.machineHP<=0 and 'fallen'or o.machineHP<=30 and 'danger'or o.machineHP<=70 and 'wounded'or 'healthy'
 local Shield=require('Ground.PhysicalShield')
 local span=o.span<=Support.healingRange*2 and 'compact'or o.span<=Shield.rules.radius*2 and 'spread'or 'wide'
 return {lifePower=life,machineHealth=hp,squadSpan=span}
end
return M
