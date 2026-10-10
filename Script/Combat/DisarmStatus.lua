-- Ownership and usable ammunition are separate: returning a gun cannot refill it.
local D=require('Dora');local M={}
local function owner(b,u)
 if u==b.mentor then return 'mentor','导师','kinetic'end
 for _,a in ipairs(b.learners)do if a.student==u then return a.character.id,a.character.name,'emp'end end
end
function M.hint(b)
 local lease=b.enemies[1].guard.lease
 if lease then
  local actor,name,item=owner(b,lease.owner)
  if name then
   local ready,why=true,nil;if b.supplies then ready,why=b.supplies:canSpend(actor,item)end
   if lease.active then
    return string.format('%s武器被夺（最多%d秒）：命中中英招可取回。%s',name,math.max(0,math.ceil(lease.expires-D.App.runningTime)),ready and '敌人开火将消耗该角色的弹药。'or '该武器无可用弹药，仍须躲避拳击。')
   elseif lease.returnedAt and D.App.runningTime-lease.returnedAt<2 then
    return name..'的武器已归还；'..(ready and '可以再次射击。'or why=='NOT_EQUIPPED'and '未携带射击补给，仍不能开火。'or '弹药已耗尽，仍不能开火。')
   end
  end
 end
 local a=b.demonstrator;local actor,name,item=owner(b,a and a.student or b.mentor)
 if b.supplies then
  local ready,why=b.supplies:canSpend(actor,item)
  if not ready then return name..(why=='NOT_EQUIPPED'and '未携带射击补给。'or '射击补给已耗尽。')..'保持移动，配合学员施法；退出后可重新配装。'end
 end
 return '中英招会冲近抢枪；避开前摇，命中持枪的中英招可夺回武器。'
end
return M
