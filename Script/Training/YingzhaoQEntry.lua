local D=require('Dora');local M={}
function M.openAsync(onReturn,actor,models,parent,values)
 local Store=require('Training.YingzhaoQStore')
 if parent then local saved=assert(Store.loadAsync(parent.id));assert(saved.model.characterId==actor);parent=saved end
 D.Director.ui3D:removeAllChildren()
 local Rewards=require('Training.YingzhaoRewards')
 local legacyProtection=parent and parent.model.rewardPolicy==Rewards.legacyPolicy
 local trainingNote=legacyProtection and '继续历史成果会保留无实体护盾的训练环境与旧收益规则；学习护盾与金粉成本请选择新建自主训练，历史成果保留。'or parent and parent.model.featureSchemaVersion<require('Training.YingzhaoFeatures').version and '继续旧成果会沿用原有观察范围；要学习最新攻击时机，可返回选择“新建自主训练”。'or parent and parent.model.rewardPolicy~=Rewards.supportPolicy and '继续旧成果保留原来的学习目标；新建自主训练还会考虑辅助机耗能与承伤，旧成果保留。'or not parent and '从零学习敌人方位、部位战术与攻击时机，也考虑辅助机耗能与承伤；已有候选保留。'or nil
 local panel=require('UI.SupplyLoadout')({trainingNote=trainingNote,virtual=true,virtualMode='yingzhao-q',values=values or require('Economy.Loadout').defaults(),formation={mentor=true,learner=true,wuyun=true},closed=function(confirmed,selection)
  D.thread(function()
   if not confirmed then require('Training.Level')(onReturn,actor);return end
   local battle,record
   require('Factory.PatrolLevel').openAsync(models,function(_,_,action)
    if action=='again'then
     local latest=parent
     if battle.qCandidateId then latest=assert(Store.loadAsync(battle.qCandidateId))end
     M.openAsync(onReturn,actor,models,latest,selection.values)
    else require('Training.Level')(onReturn,actor)end
    return true
   end,{battleFactory=function(m)
    local supplies=assert(require('Economy.CombatSession').virtual('yingzhao-q:'..os.time()..':'..tostring(D.App.runningTime),selection.loadout))
    battle=require('Enemy.BigYingzhaoBattle').createAsync(m,supplies,{virtual=true,physicalSupport=not legacyProtection})
    require('Training.YingzhaoQ').attach(battle,actor,{model=parent and parent.model});return battle
   end,onSettledAsync=function()
    local session=battle.yingzhaoQTraining
    local deadline=D.App.runningTime+3
    while not session.closed do assert(D.App.runningTime<deadline,'Q closure timeout');D.sleep(.01)end
    if #session.transitions==0 then battle.qNoUpdates=true;return true end
    record=record or {schemaVersion=2,kind='yingzhao-q-candidate',episode=session.combat.episode,model=session.model,base=session.base,parentId=parent and parent.id,transitions=session.transitions,combat=session.combat}
    local ok,why,id=Store.saveAsync(record);battle.qCandidateId=id;return ok,why
   end,music='Music/训练场.mp3',presentation={title='虚拟训练场 · 大英招自主训练',start='开始训练',withdrawButton='结束训练',withdraw='本轮训练已结束。未完成的动作不计作失败学习。',won='训练完成',failed='训练结束',baseText='返回训练',continueText='继续训练',saving='正在保存训练成果…',saveFailure='训练成果尚未保存，请重试；返回将放弃本轮更新。',unsavedBaseText='放弃并返回',
    statusText=function(b)
     local s=b.yingzhaoQTraining
     local goal=s.q.rewardPolicy==Rewards.supportPolicy and '学习目标包含辅助机耗能与承伤。'or'本轮沿用原成果的学习目标。'
     return string.format('%s · %s\n你控制导师，学员自主尝试部位攻击与走位。\n本轮学习 %d 次 · J瞄准射击 · F/R施法 · G集合\n只用虚拟补给；综合破甲、伤害、消耗与全队生存，不自动采用。\n%s',require('Training.Characters')[actor].name,parent and ('继续候选 #'..parent.id)or'从零训练',#s.transitions,goal)
    end,
    reportText=function(b)
     local s=b.yingzhaoQTraining;local reward=0;for _,t in ipairs(s.transitions)do reward=reward+t.reward end
     return string.format('本轮学习 %d 次 · 学习得分 %.2f\n未完成或集合打断的记录 %d 条未计入学习。\n%s\n虚拟消耗 %d；没有扣除正式物资，也未自动采用。',#s.transitions,reward,s.discarded,b.qNoUpdates and '本轮没有完整学习记录，未生成候选。'or b.qCandidateId and ('候选 #'..b.qCandidateId..' 已保存，可继续训练。')or'候选尚未保存。',b.supplies.ledger.spent)
    end,
   }})
  end)
 end})
 panel.tag='yingzhao-q-budget';panel:addTo(D.Director.ui3D);panel:alignLayout();return panel
end
return M
