local D=require('Dora');local Level={}
function Level.openAsync(models,variant,onResult,options)
 options=options or {};options.battleFactory=function(m,attempt)return require('Final.Battle').createAsync(m,variant,attempt)end
 options.presentation={title='最后的约定',start='开始撤离',withdrawButton='撤回准备点',withdraw='已撤回，回收记录尚未送出。',won='抵达撤离终端',failed='撤离中止',baseText='返回研发室',continueText='继续',
  statusText=function(b)return string.format('最后的约定 · %s\n导师 %.0f · 妮妮莉特 %.0f · 辅助机 %.0f · 金粉 %.1f\nA/D 摇杆 · J 射击 · F 火焰 · H 治疗水 %d（任务补给 %d）\n%s\n离开青色维生范围持续受伤；贴近机体恢复。',b.stageName,b.mentorHP,b.arena.studentHP,b.support.machineHP,b.support.gold,b.medicineRemaining,b.emergencyRemaining,b.message or b.escortHint or '三段通道；保护妮妮莉特与记录载体抵达出口。')end,
  reportText=function(b)return string.format('撤离区段 %d / 3 · 辅助机 %.0f\n导师命中 %d · 学员命中 %d · 火焰命中 %d\n维生消耗 %.1f · 场外伤害 %.1f · 掩护 %d 次',#b.completedStages,b.support.machineHP,b.mentorHits,b.arena.metrics.hits,b.magic.fireHits,b.support.spent,b.support.hazardDamage,b.coverBlocks)end}
 local c=require('Factory.PatrolLevel').openAsync(models,onResult or function(_,_,action)
  if action=='again'then Level.openAsync(models,variant,nil,options)else require('Academy.Navigation').returnToRoomAsync('RDRoom')end;return true
 end,options)
 local medicine=require('UI.Skill')({visible=true,text='药品 H'});medicine.position=c.hud.weapon.position-D.Vec2(592,0);medicine:addTo(c.hud.skillArea);c.medicine=medicine
 medicine:slot('TapBegan',function()c.commandInput('medicine')end);c.hud.keyboardEnabled=true;c.hud:slot('KeyDown',function(key)if key=='H'then c.commandInput('medicine')end end)
 return c
end
return Level
