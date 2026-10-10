-- 2-15 capture encounter. No story progress is saved by this combat module.
local R=require('Factory.Researcher')
local Battle={}
function Battle.createAsync(models)
 return require('Factory.PatrolBattle').createAsync(models,{
  id='researcher-capture',singleEnemy=true,enemyFactory=R.create,controller=R,enemyHP=180,enemyX=2450,timeLimit=45,
  failed=function(b)return b.enemies[1].guard.escaped end,
  failureReason='研发人员逃离了这一段通道，重新寻找机会。',timeoutReason='没有及时控制住研发人员，潜入行动中止。',
  victory=function(b)
   local r=b.enemies[1].guard
   if not r.capturedAt or not r.damageTaken or r.damageTaken<=0 then return false,'尚未控制住研发人员。'end
   return true,'研发人员已被控制，可以询问指挥中心的位置。'
  end,
 })
end
return Battle
