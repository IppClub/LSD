local D=require('Dora');local M={}
-- Present visible geometry only: no hidden destinations or future targets.
function M.supportWarningText(b)
 if not b.support then return '',false end
 local text,danger=b.support:warningText()
 if b.support.machineHP<=0 or b.support.gold<=0 then return text,danger end
 local outside=false
 if b.physicalShield and b.mentor and (b.mentorHP or 0)>0 then
  local shield=require('Ground.PhysicalShield')
  local own=shield.project(shield.observe(b.physicalShield,b.mentor.x,b.mentor.y-b.world.offset))
  outside=own and own.shieldState=='outside'
 end
 local function warning(message,urgent)
  -- Critical HP/energy must not hide the visible attack that must be avoided.
  -- Keep the original two-line area and finite geometry/visibility checks.
  local cues={}
  if outside then cues[#cues+1]='导师在护盾外'end
  if b.support.machineHP<=30 then cues[#cues+1]='机体危急'
  elseif b.support.machineHP<=70 then cues[#cues+1]='机体受损'end
  if b.support:energyObservation().seconds<=20 then cues[#cues+1]='金粉将尽'
  elseif b.support.physicalShield and b.support.physicalShield.charge<=0 then cues[#cues+1]='护盾耗尽'end
  if #cues>0 then message=table.concat(cues,' · ')..' · '..message end
  return message,danger or urgent
 end
 local boss=b.bossCombat and b.bossCombat.boss
 local u=boss and boss.enemy;local machine=b.machine
 if not u or not machine or boss.enemyHP<=0 or not b.bossCombat.armor:available()then return text,danger end
 local guard=boss.guard
 if guard and require('Enemy.GroundWave').escapeDirection(guard,machine,true)then
  return warning('机体处于波技能路径\n移动并G集合 · 避开波前',true)
 end
 local timeline=require('Enemy.BigYingzhaoTimeline')
 local reach=timeline.meleeReach+(timeline.massiveMotion.finish-timeline.massiveMotion.start)*timeline.massiveMotion.speed
 local function inFront(unit,range)
  local front=(unit.x-u.x)*(u.faceRight and 1 or -1)
  return front>=0 and front<=range and math.abs(unit.y-u.y)<=timeline.meleeVerticalReach
 end
 local machineRisk=inFront(machine,reach)
 local frontRisk=machineRisk
 local closeRisk=inFront(machine,timeline.meleeReach)
 if b.targets then
  for _,target in ipairs(b:targets())do
   local actor=target.unit
   if target.hp()>0 and actor.visible~=false and (not actor.opacity or actor.opacity>.1)then
    if guard and require('Enemy.GroundWave').escapeDirection(guard,actor,true)then
     return warning('队员处于波技能路径\n整队避开波前 · 勿急于换侧',true)
    end
    frontRisk=frontRisk or inFront(actor,reach)
    closeRisk=closeRisk or inFront(actor,timeline.meleeReach)
   end
  end
 end
 local completed=guard and guard.strike
 if b.phase=='playing'and completed and completed.completed and not guard.busy and not guard.reacting and (completed.recoveryDuration or 0)>.9 and D.App.runningTime<guard.nextAttack then
  -- Show the already-visible completed opening, never a future skill.
  local seconds=math.ceil(math.max(0,guard.nextAttack-D.App.runningTime)*10)/10
  local move='整队换位 · 瞄准已破甲部位'
  local margin=require('Combat.Formation').spacing*2
  if type(b.minX)=='number'and type(b.maxX)=='number'then
   if machine.x>u.x and b.maxX-machine.x<=margin then move='右侧退路窄 · 向左整队换位'
   elseif machine.x<u.x and machine.x-b.minX<=margin then move='左侧退路窄 · 向右整队换位'end
  end
  return warning(string.format('Boss收招停顿 · %.1fs\n%s',seconds,move),false)
 end
 if frontRisk and guard and guard.sequence then
  local timing=require('Training.YingzhaoTiming')
  local raw,window=timing.capture(guard,true,D.App.runningTime)
  if window=='recovery'then
   local tail,kind=timing.recoveryTail(raw,D.App.runningTime)
   if kind=='follow-up'then return warning('Boss连招尚未结束\n保持整队避让 · 留意后续攻击',true) end
   if tail then return warning('Boss收招，整队仍在正面\n核对退路和队员位置 · G集合',false) end
  elseif raw and raw.skill=='massive'then
   return warning('Boss连斩正在推进\n避免贴边后退 · 留意整队位置',true)
  elseif raw and raw.skill=='punch'and closeRisk then
   return warning('Boss拳击前摇\n整队移出正面 · 留意机体位置',true)
  end
 end
 if frontRisk and not machineRisk then
  return warning('队员处于Boss正面\nG集合转移 · 留意机体位置',false)
 end
 if machineRisk then
  return warning('机体处于Boss正面\nG集合转移 · 避开冲进',false)
 end
 if outside then return warning('靠近机体或避开攻击\nG集合 · 长按恢复',true)end
 return text,danger
end
function M.openAsync(service,attempt,support)
 local battle;local saved=false
 local c=require('Factory.PatrolLevel').openAsync(attempt.models,function(status,_,action)
  if not saved then return false,'SAVE_REQUIRED'end
  if support then support.hp={battle.mentorHP,battle.arena.studentHP,battle.wuyun.studentHP}end
  require('Academy.Navigation').returnToRoomAsync(status=='won'and action=='again'and'AbandonedCity'or'TrainA',status=='won'and action=='again'and {energySquad=true,spawn=4650,support=support}or nil);return true
 end,{requireSavedExit=true,battleFactory=function(models)
  battle=require('Enemy.BigYingzhaoBattle').createAsync(models,assert(require('Economy.CombatSession').open(attempt.supplyAttempt)))
  if support and support.hp then battle.mentorHP=support.hp[1];battle.arena.studentHP=support.hp[2];battle.wuyun.studentHP=support.hp[3]or 100 end
   require('Ground.BattleSupport').attach(battle,support)
   require('Training.YingzhaoDeployment').attachAsync(battle,models)
   battle.yingzhaoDeploymentText=require('Training.YingzhaoDeployment').text(battle)
  return battle
 end,onSettledAsync=function(status,report)
  local verified,why=require('Training.YingzhaoDeployment').verifyAsync(battle);if not verified then return false,why end
  local trace=battle.bossTrace
  -- PatrolLevel calls after finite character actions have fully settled.
  trace.resources=battle.supplies:evidence()
  local episode={schemaVersion=1,closed=true,trainable=false,episode=attempt.supplyAttempt,versions={resources=1,bigYingzhao=1},resources=trace.resources,boss=trace}
  report.bossTrace=nil
  local ok,why=service:finishAsync(attempt,status,report,episode);saved=ok;return ok,why
 end,presentation={playerMarker=true,category='Side',singleExitOnFailure=true,title='地面调查 · 大英招讨伐',start='开始讨伐',won='大英招已击退',failed='讨伐未完成',withdrawButton='撤回调查点',withdraw='已撤离大英招讨伐。',baseText='返回列车',continueText='继续调查',unsavedBaseText='返回调查点',
  headerHeight=function(b)
   local height=b.phase=='ready'and(275+((b.yingzhaoDeploymentText or '')~=''and 60 or 0))or 235
   -- Warning starts 255px below the top; PatrolLevel adds the 80px shield
   -- area. Include wrapped warnings so the camera still clears their bottom.
   if b.supportWarning and b.supportWarning.visible then height=math.max(height,191+b.supportWarning.height)end
   return height
  end,
  supplyText=function(text)return text:gsub(' · 已用成本 ','\n已用成本 ')end,
  layoutControls=function(c,ui,startHolder,withdrawHolder)
   c.status.textWidth=ui.width-580
   startHolder.position=D.Vec2(ui.width-270,ui.height-285)
   withdrawHolder.position=D.Vec2(ui.width-270,ui.height-225)
   battle.bossCombat.view.node.position=D.Vec2(ui.width-270,ui.height-130)
   if not c.supportWarning then
    local label=D.Label('SourceHanSansCN-Regular',22)
    label.anchor=D.Vec2(0,1);label.alignment='Left';label.textWidth=480
    label:addTo(ui);c.supportWarning=label;battle.supportWarning=label
   end
   c.supportWarning.position=D.Vec2(ui.width-510,ui.height-255)
  end,
  statusText=function(b)
   if b.supportWarning then
    local text,danger='',false
    text,danger=M.supportWarningText(b)
    if b.supportWarning.text~=text then
     b.supportWarning.text=text;b.supportWarning.color3=D.Color3(danger and 0xff756d or 0xffcf72)
     b.supportWarningWrites=(b.supportWarningWrites or 0)+1
    end
    b.supportWarning.visible=text~=''and b.phase~='ready'
   end
   if b.phase~='ready'then
    local gathering=b:gatherActive()
    local note=gathering and (b.gatherMode=='recover'and'恢复集合中，G取消'or'集合中，G取消恢复自主行动')or 'J瞄准 / G集合，长按恢复'
    if gathering and b.gatherPlan._compressed then note='退路窄，调整站位 / G取消'end
    if b.support then
     local energy=b.support:energyObservation()
     if not energy.powered then note='维生场停机，及时撤离'
     elseif energy.seconds<=20 then note=gathering and '金粉将耗尽，集合中 / 及时撤离'or '金粉将耗尽，G集合/撤离'
     elseif energy.span>require('Ground.PhysicalShield').rules.radius*2 then note=gathering and '队伍分散，集合中 / G取消'or '队伍分散，G集合节省金粉'end
    end
    return string.format('导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f · %s',b.mentorHP,b.arena.studentHP,b.wuyun.studentHP,note)..((b.yingzhaoDeploymentText or '')~=''and('\n'..b.yingzhaoDeploymentText)or'')
   end
   return string.format('大英招讨伐　生命 %.0f / 1000\n导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f\n长按射击瞄准部位 · EMP破甲后集中实弹输出\nG集合/取消 · 长按恢复 · 避开预警并清理援军。',b.enemies[1].enemyHP,b.mentorHP,b.arena.studentHP,b.wuyun.studentHP)..((b.yingzhaoDeploymentText or '')~=''and('\n'..b.yingzhaoDeploymentText)or'')end,
  reportText=function(b)return require('Training.YingzhaoContributions').text(b.bossTrace)..'\n\n'..string.format('导师命中 %d · 火羽命中 %d · 旋风命中 %d\n净收益以实际消耗和任务收入计算。',b.mentorHits,b.magic.fireHits,b.magic.windHits)..((b.yingzhaoDeploymentText or '')~=''and('\n'..b.yingzhaoDeploymentText)or'')end}})
 local view=battle.bossCombat.view
 view.node.anchor=D.Vec2.zero
 -- Adoption validation can yield: the engine then manages an unattached root.
 -- Move ownership without Cleanup, which would close HP/AP feedback.
 view.node:moveToParent(c.controls)
 require('Enemy.BigYingzhaoCamera').attach(battle,c)
 return c
end
return M
