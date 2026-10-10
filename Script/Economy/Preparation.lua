-- Shared formal budget confirmation; mission creation and reservation are atomic.
local D=require('Dora');local M={}
function M.openAsync(mission,models,cancelled,started)
 local service,why=require('Mission.Service').open();if not service then return nil,why end
 local formation,why=service:formation();if not formation then return nil,why end
 local Store=require('Economy.Store');local ok,why=Store.open();if not ok then return nil,why end
 local Loadout=require('Economy.Loadout');local values,why=Loadout.load();if not values then return nil,why end
 local wallet,why=Store.wallet();if not wallet then return nil,why end
 local shownFormation=mission=='c0-m06' and {mentor=true} or (mission=='c0-roof' or mission=='c0-patrol-second' or mission=='c0-m01' or mission=='c0-m02' or mission=='c0-m07' or mission=='c0-m08' or mission=='c0-m09') and {mentor=true,learner=formation.learner} or formation
 local panel=require('UI.SupplyLoadout')({mission=mission,values=values,formation=shownFormation,balance=wallet.available,
  confirmAsync=function()
   local supplies,why=Loadout.forMission(mission,formation);if not supplies then return nil,'补给配置读取失败，请重试。'end
   local attempt,why=service:beginAsync(mission,models,shownFormation,supplies)
   if not attempt then
    if why=='INSUFFICIENT_SUPPLIES'then return nil,'物资不足：减少携带量，或先完成整理回收。'end
    if why=='TRAINING_REQUIRED'then return nil,'请先完成示范、试战并采用训练成果。'end
    if why=='INVALID_FORMATION'then return nil,'请先将任务需要的学员编入队伍。'end
    if why=='STORY_LOCKED'then return nil,'请先完成任务前的调查与对话。'end
    return nil,'出战未保存，请检查编队和训练成果：'..tostring(why)
   end
   return attempt
  end,
  closed=function(saved,attempt)
   if not saved then if cancelled then cancelled()end;return end
   if started then started(service,attempt)end
  end})
 panel:addTo(D.Director.ui3D);panel:alignLayout();return panel
end
return M
