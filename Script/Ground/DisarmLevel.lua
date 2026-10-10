local D=require('Dora');local M={}
function M.openAsync(service,attempt,support)
 local battle;local saved=false
 return require('Factory.PatrolLevel').openAsync(attempt.models,function(status,_,action)
  if not saved then return false,'SAVE_REQUIRED'end
  -- Continuing returns to the optional terminal; another attempt needs a new budget.
  if support then support.hp={battle.mentorHP,battle.arena.studentHP,battle.wuyun.studentHP}end
  require('Academy.Navigation').returnToRoomAsync(status=='won'and action=='again'and 'AbandonedCity'or'TrainA',status=='won'and action=='again'and {energySquad=true,spawn=4650,support=support}or nil);return true
 end,{requireSavedExit=true,
  battleFactory=function(models)
   local E=require('Enemy.MediumYingzhao');D.Cache:loadAsync('spine:'..E.asset)
   battle=require('Factory.PatrolBattle').createAsync(models,{id='yingzhao-route',scene='AbandonedCity',enemyAsset=E.asset,enemyFactory=E.create,controller=E,singleEnemy=true,enemyHP=360,timeLimit=90,victory=function()return true,'中英招已击退，道路恢复通行。'end,timeoutReason='清障超时，重新调整配装与接敌距离。'})
   if support and support.hp then battle.mentorHP=support.hp[1];battle.arena.studentHP=support.hp[2];battle.wuyun.studentHP=support.hp[3]or 100 end
   require('Ground.BattleSupport').attach(battle,support)
   battle.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt))
   for _,a in ipairs(battle.learners)do a.supplies=battle.supplies end
   require('Training.DisarmTrace').attach(battle,true)
   require('Training.DisarmDeployment').attachAsync(battle,models)
   return battle
  end,
  onSettledAsync=function(status,report)
   local t=battle.disarmTrace;local deadline=D.App.runningTime+10
   while not t.sourceSaveState do if D.App.runningTime>deadline then return false,'TRACE_NOT_READY'end;D.sleep(.02)end
   if t.sourceSaveState~='mission-ready'then return false,t.executionReviewError or t.resourceReviewError end
   local episode={schemaVersion=1,closed=true,trainable=false,episode=attempt.supplyAttempt,versions={resources=1,disarm=1},resources=t.resources,disarm=t}
   report.disarmTrace=nil
   local yes,why=service:finishAsync(attempt,status,report,episode)
   saved=yes;return yes,why
  end,
  music='Music/战斗1.mp3',presentation={category='Side',singleExitOnFailure=true,title='地面调查 · 中英招清障',start='开始清障',won='道路已清理',failed='清障未完成',withdrawButton='撤回调查点',withdraw='已撤离中英招清障。',baseText='返回列车',continueText='继续调查',unsavedBaseText='返回调查点',
   statusText=function(b)
    local text=string.format('地面调查 · 中英招清障　敌人生命 %.0f / 360\n导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f',b.enemies[1].enemyHP,b.mentorHP,b.arena.studentHP,b.wuyun.studentHP)
    -- Teach the controls before starting; the original labelled HUD remains
    -- visible in combat. Keep weapon theft, adopted policy and costs live.
    if b.phase=='ready'then text=text..'\n摇杆/A、D移动 · J射击 · F火焰 · R旋风'end
    return text..'\n'..require('Combat.DisarmStatus').hint(b)..'\n'..(b.adoptionStatus or '')
   end,
   fitHeader=true,playerMarker=true,
   frameCamera=function(b,c)require('Ground.DisarmCamera').attach(b,c)end,
   headerHeight=function(b)return b.phase=='ready'and 255 or 155 end,
   supportText=function(b)
    if not b.support then return nil end
    local text=string.format('辅助机 %.0f / 100 · 金粉 %.1f · 维生场%s',b.support.machineHP,b.support.gold,b.support.active and '运行'or'停机')
    if b.physicalShield then text=text..string.format(' · 护盾 %.0f / %.0f · %s',b.physicalShield.charge,b.physicalShield.capacity,b.physicalShield:status())end
    return text
   end,
   ready='正式任务将消耗携带物资。中英招抢枪后使用原持有者的弹药；命中它可取回武器。',playing='保持机动避开抢枪前摇，夺枪期间配合学员攻击。',
   reportText=function(b)return (b.adoptionStatus or '')..string.format('\n导师命中 %d · 火焰 %d · 旋风 %d\n实际消耗包含被夺武器的射击；明细以本次账单为准。',b.mentorHits,b.magic.fireHits,b.magic.windHits)end,
  }})
end
return M
