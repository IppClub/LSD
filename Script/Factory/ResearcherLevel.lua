-- Original joystick, weapon, learner skills and result controls for 2-15 capture.
local Level={}
function Level.openAsync(models,onResult,options)
 local config={};for key,value in pairs(options or {})do config[key]=value end
 config.battleFactory=function(m)
  local b=require('Factory.ResearcherBattle').createAsync(m)
  if config.supplyAttempt then
   b.supplies=assert(require('Economy.CombatSession').open(config.supplyAttempt))
   for _,a in ipairs(b.learners)do a.supplies=b.supplies end
  end
  return b
 end
 config.presentation={title='工厂潜入 · 控制研发人员',start='开始行动',won='战斗成功',withdraw='已撤离，研发人员尚未被控制。',ready='研发人员就在前方。准备好后展开行动。',playing='研发人员正在离开。跟上目标，配合学员将其控制。'}
 return require('Factory.PatrolLevel').openAsync(models,onResult,config)
end
return Level
