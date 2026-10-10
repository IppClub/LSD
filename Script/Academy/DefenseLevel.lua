local Level={}
function Level.openAsync(models,onResult,options)
 options=options or {};options.battleFactory=require('Academy.DefenseBattle').createAsync
 options.presentation={title='学院防卫',start='守住入口',withdrawButton='撤回准备点',withdraw='已撤回；防卫尚未完成。',won='撤离通道已打开',failed='防卫中止',baseText=options.baseText or '返回指挥室',continueText='返回防线',
  statusText=function(b)return string.format('学院防卫 · %s\n导师 %.0f · 妮妮莉特 %.0f · 供电 %.0f · 信标 %.0f\n摇杆 / A、D 移动 · J 射击 · F 火焰 · H 治疗水（%d）\n%s\n%s',b.stageName,b.mentorHP,b.arena.studentHP,b.powerHP,b.beaconHP,b.medicineRemaining,b.stage==3 and (b.escortHint or '靠近信标，清除附近威胁，再共同前往右侧出口。')or b.stage==2 and '敌人正在攻击供电节点，优先拦截！'or '与妮妮一起清除入口的敌人。',b.message or '')end,
  reportText=function(b)return string.format('完成阶段 %d / 3\n导师命中 %d · 学员命中 %d · 火焰命中 %d\n供电剩余 %.0f · 信标剩余 %.0f',#b.completedStages,b.mentorHits,b.arena.metrics.hits,b.magic.fireHits,b.powerHP,b.beaconHP)end}
 local leave=onResult or function(_,_,action)
  if action=='again'then Level.openAsync(models,nil,options)else require('Academy.Navigation').returnToOperationAsync()end
  return true
 end
 local c=require('Factory.PatrolLevel').openAsync(models,leave,options)
 local D=require('Dora');local medicine=require('UI.Skill')({visible=true,text='药品 H'})
 medicine.position=c.hud.weapon.position-D.Vec2(592,0);medicine:addTo(c.hud.skillArea);c.medicine=medicine
 medicine:slot('TapBegan',function()c.commandInput('medicine')end)
 c.hud.keyboardEnabled=true;c.hud:slot('KeyDown',function(key)if key=='H'then c.commandInput('medicine')end end)
 return c
end
return Level
