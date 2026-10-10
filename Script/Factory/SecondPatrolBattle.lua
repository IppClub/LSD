-- Authored 2-15 separation: Wuyun stays with the captured researcher.
local Battle={}
function Battle.createAsync(models)
 return require('Factory.PatrolBattle').createAsync(models,{
  id='second-patrol',leaveWuyun=true,engageRange=550,
  victory=function(b)
   if b.mentorHits<=0 or b.magic.fireHits<=0 then return false,'配合妮妮莉特的火焰制服守卫。'end
   return true,'通往控制舱的巡逻队已制服。乌云仍在看守研发人员。'
  end,
 })
end
return Battle
