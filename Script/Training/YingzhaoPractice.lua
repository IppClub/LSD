-- Virtual enemy encounter. Existing adopted policies stay frozen; no new
-- demonstration/Q samples or story rewards are written by this practice.
local D=require('Dora');local P={}
function P.createAsync(models)
 D.Cache:loadAsync('spine:xiaoyingzhao')
 local Enemy=require('Enemy.SmallYingzhao')
 return require('Factory.PatrolBattle').createAsync(models,{
  id='small-yingzhao-practice',scene='VRTraining',enemyAsset='xiaoyingzhao',enemyFactory=Enemy.create,controller=Enemy,enemyHP=100,timeLimit=90,
  timeoutReason='演练超时。尝试先避开扑击，再集中火力。',
  victory=function()return true,'小英招小队已击败。演练结束，已采用的训练成果保留。'end,
 })
end
function P.openAsync(onReturn,characterId,models)
 return require('Factory.PatrolLevel').openAsync(models,function(_,_,action)
  if action=='again' then P.openAsync(onReturn,characterId,models)
  else require('Training.Level')(onReturn,characterId)end
  return true
 end,{battleFactory=P.createAsync,music='Music/训练场.mp3',presentation={
  title='虚拟训练场 · 小英招小队',start='开始演练',withdrawButton='结束演练',withdraw='已结束英招演练。',
  ready='三只小英招会接近并飞扑；近身翻踢能击退角色。留出闪避距离，再开火。',
  playing='按住武器瞄准、松开发射。避开扑击，与学员配合攻击。',
  won='演练完成',failed='演练中止',baseText='返回基础训练',
 }})
end
return P
