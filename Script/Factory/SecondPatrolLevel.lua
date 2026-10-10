local Level={}
function Level.openAsync(models,onResult,options)
 local config={};for k,v in pairs(options or {})do config[k]=v end
 config.battleFactory=function(m)
  local b=require('Factory.SecondPatrolBattle').createAsync(m)
  if config.supplyAttempt then
   b.supplies=assert(require('Economy.CombatSession').open(config.supplyAttempt))
   for _,a in ipairs(b.learners)do a.supplies=b.supplies end
  end
  return b
 end
 config.presentation={title='工厂潜入 · 控制舱前守卫',start='迎击守卫',won='道路已打通',withdraw='已撤回，控制舱前的守卫仍在巡逻。',ready='乌云留下看守。导师与妮妮莉特继续前往控制舱。',playing='靠近守卫，射击并配合妮妮莉特的火焰。'}
 return require('Factory.PatrolLevel').openAsync(models,onResult,config)
end
return Level
