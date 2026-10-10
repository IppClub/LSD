-- Reuse the existing battle HUD, skills and settlement, with roof-specific checkpoints.
local Level={}
function Level.openAsync(c)
 local store,why=require('Story.RoofDuelStore').open();if not store then return nil,why end
 if assert(store:load()).completed then return nil,'ALREADY_WON'end
 local p=require('Training.Progress');if not p.load()or not p.adopted then return nil,'ADOPTED_LEARNER_REQUIRED'end
 local initialUI=c.ui.visible;local initialHUD=c.hud.visible
 c.phase='supply';c.held={};c.ui.visible=false;c.hud.visible=false
 local function cancel()c.supplyPanel=nil;c.phase='ready';c.ui.visible=initialUI;c.hud.visible=initialHUD end
 local panel,why=require('Economy.Preparation').openAsync('c0-roof',p.adopted,cancel,function(service,attempt)
  c.supplyPanel=nil;c.phase='ready'
  local options={requireSavedExit=true,battleFactory=function()
   local b=require('Factory.RoofBattle').createAsync(c,attempt.model)
   b.supplies=assert(require('Economy.CombatSession').open(attempt.supplyAttempt));b.arena.supplies=b.supplies
   return b
  end,
  presentation={title='发射炮前 · 乌云',start='迎战乌云',won='攻势已止',failed='战斗中止',withdraw='已退回屋顶，调整后可以再次迎战。',withdrawButton='退回屋顶',baseText='返回屋顶',continueText='继续剧情',
   statusText=function(b)return string.format('发射炮前 · 乌云\n导师 %.0f · 妮妮莉特 %.0f · 乌云 %.0f\n摇杆/A、D 移动 · J 射击 · F 鸿鹄焰火\n%s',b.mentorHP,b.arena.studentHP,b.enemy.enemyHP,b.phase=='ready'and '与妮妮莉特并肩阻止乌云。'or '留意刀光与寒风，拉开距离。')end,
   reportText=function(b)return string.format('导师生命 %.0f · 妮妮莉特生命 %.0f',b.mentorHP,b.arena.studentHP)end},
  onSettledAsync=function(status,proof)return service:finishAsync(attempt,status,proof)end}
 c.battleLevel=require('Factory.PatrolLevel').openAsync({ninilite=attempt.model},function(status,proof,action)
  local world,why=require('Factory.Roof').openAsync();if not world then return false,why end
  if action=='again'and status~='won'then local controller,why=Level.openAsync(world.roof);return controller~=nil,why end
  return true
 end,options)
 end)
 c.supplyPanel=panel;if not panel then cancel();return nil,why end
 return panel
end
return Level
