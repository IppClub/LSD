local D=require('Dora');local M={}
function M.openAsync(onReturn,characterId,models,candidate,values)
 local policy=candidate and candidate.model.algorithm=='yingzhao-qlearning'and 'Training.YingzhaoQ'or 'Training.YingzhaoPolicy'
 assert(candidate and require(policy).validate(candidate.model,characterId),'Candidate mismatch')
 D.Director.ui3D:removeAllChildren()
 local panel=require('UI.SupplyLoadout')({virtual=true,virtualMode='yingzhao-trial',values=values or require('Economy.Loadout').defaults(),formation={mentor=true,learner=true,wuyun=true},closed=function(confirmed,selection)
  D.thread(function()
   if not confirmed then require('Training.Level')(onReturn,characterId);return end
   require('Factory.PatrolLevel').openAsync(models,function(_,_,action)
    if action=='again'then M.openAsync(onReturn,characterId,models,candidate,selection.values)else require('Training.Level')(onReturn,characterId)end
    return true
   end,{battleFactory=function(m)
    local supplies=assert(require('Economy.CombatSession').virtual('yingzhao-trial:'..candidate.id..':'..tostring(D.App.runningTime),selection.loadout))
    local b=require('Enemy.BigYingzhaoBattle').createAsync(m,supplies,{virtual=true,physicalSupport=true});require('Training.YingzhaoTrial').attach(b,candidate.model);b.yingzhaoCandidateId=candidate.id;return b
   end,music='Music/训练场.mp3',presentation={title='虚拟训练场 · 大英招候选试战',start='开始试战',withdrawButton='结束试战',withdraw='已结束候选试战。',won='试战完成',failed='试战中止',baseText='返回训练',
    statusText=function(b)return string.format('大英招候选 #%d · %s\n你控制导师；候选控制学员，另一学员沿用基础策略。\nBoss生命 %.0f / 1000 · J瞄准射击 · F/R施法 · G集合\n虚拟补给；本轮只试战，不学习或采用。',candidate.id,require('Training.Characters')[characterId].name,b.enemies[1].enemyHP)end,
    reportText=function(b)
     local issued=0;for _,decision in ipairs(b.yingzhaoCandidateDecisions)do if decision.accepted then issued=issued+1 end end
     return string.format('候选 #%d：%d次决策，%d次动作执行。\nBoss剩余生命 %.0f，虚拟消耗 %d。\n本轮未保存为示范，未自动训练或采用。',candidate.id,#b.yingzhaoCandidateDecisions,issued,b.enemies[1].enemyHP,b.supplies.ledger.spent)
    end,
   }})
  end)
 end})
 panel.tag='yingzhao-trial-budget';panel:addTo(D.Director.ui3D);panel:alignLayout();return panel
end
return M
