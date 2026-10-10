local Level={}
function Level.openAsync(models,onResult,options)
 options=options or {};options.battleFactory=require('Rescue.Battle').createAsync
 options.presentation={title='研究区 · 双子救援',start='开始护送',withdrawButton='撤回准备点',withdraw='已撤回；双子尚未脱离危险。',won='双子抵达出口',failed='救援中止',baseText='返回研发室',continueText='继续',
  statusText=function(b)return string.format('双子救援 · %s\n导师 %.0f · 妮妮莉特 %.0f · 烛参 %.0f · 烛商 %.0f\n摇杆 / A、D 移动 · J 射击 · F 火焰 · H 治疗水（%d）\n%s\n保护场只在金色边界内生效，吸收量有限。',b.stageName,b.mentorHP,b.arena.studentHP,b.twins[1].actor.hp,b.twins[2].actor.hp,b.medicineRemaining,b.message or b.escortHint or '靠近双子，清除前路的敌人。')end,
  reportText=function(b)return string.format('完成危险区 %d / 2\n烛参 %.0f · 烛商 %.0f · 保护场吸收 %.0f\n导师命中 %d · 学员命中 %d · 火焰命中 %d',#b.completedStages,b.twins[1].actor.hp,b.twins[2].actor.hp,b.ward.absorbed,b.mentorHits,b.arena.metrics.hits,b.magic.fireHits)end}
 local c=require('Factory.PatrolLevel').openAsync(models,onResult or function(_,_,action)
  if action=='again'then Level.openAsync(models,nil,options)else require('Academy.Navigation').returnToRoomAsync('RDRoom')end;return true
 end,options)
 local D=require('Dora');local medicine=require('UI.Skill')({visible=true,text='药品 H'});medicine.position=c.hud.weapon.position-D.Vec2(592,0);medicine:addTo(c.hud.skillArea);c.medicine=medicine
 medicine:slot('TapBegan',function()c.commandInput('medicine')end);c.hud.keyboardEnabled=true;c.hud:slot('KeyDown',function(key)if key=='H'then c.commandInput('medicine')end end)
 return c
end
return Level
