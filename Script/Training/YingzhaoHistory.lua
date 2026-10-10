local D=require('Dora');local M={}
function M.open(closed)
 local store=require('Training.YingzhaoComparisonStore');local ids,why=store.list();ids=ids or {};local index=1
 local view=require('UI.DisarmComparison')({title='大英招 · 对照历史',closed=closed})
 view.tag='yingzhao-history'
 local function refresh()
  local id=ids[index];local r,error;if id then r,error=store.load(id)end;view.record=r;view.recordId=id
  if r then
   local actor=require('Training.Characters')[r.candidate.characterId].name
   view:setText(string.format('最近20组 · %d / %d · 记录 #%d · %s\n\n',index,#ids,id,actor)..require('Training.YingzhaoComparison').text(r))
  else view:setText(why and '历史暂时读取失败，请返回后重试。'or id and '这条记录未通过核对，无法展示；可切换其他记录。'or'尚无完整对照记录。完成部位对照后可在这里查看。')end
 end
 view.previous=view.makeButton('上一记录',-500,function()if #ids>0 then index=(index-2)%#ids+1;refresh()end end)
 view.next=view.makeButton('下一记录',-100,function()if #ids>0 then index=index%#ids+1;refresh()end end)
 view.previous.visible=#ids>1;view.next.visible=#ids>1
 refresh();view:addTo(D.Director.ui3D);view:alignLayout();return view
end
return M
