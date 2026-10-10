local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',cases={},scope='Actual native budget labels and complete scrollable advice at two resolutions; no formal money changes',osInput=false}
 local function save()D.Content:save(root..'/Test/supply-budget-advice-layout-result.json',D.json.encode(r,false,true))end;save()
 local ok,err=xpcall(function()
  local L=require('Economy.Loadout');local special='完整训练说明测试：候选只在试战使用，不能自动替换已采用模型。'
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.1)
   for _,mission in ipairs({'c0-m06','c0-yingzhao','c0-m03','c0-disarm'})do
    local p=require('UI.SupplyLoadout')({mission=mission,values=L.defaults(),formation={mentor=true,learner='ninilite',wuyun=true},balance=487,confirmAsync=function()error('Unexpected confirmation')end,trainingNote=special});p:addTo(D.Director.ui3D);p:alignLayout();D.sleep(.05)
    assert(p.noteLabel.y-p.noteLabel.height>-305,'Budget note overlaps footer buttons')
    assert(p.summaryLabel.y-p.summaryLabel.height>p.noteLabel.y,'Budget summary overlaps note')
    local values=D.json.encode(p.values,false,true);local quote=p.quote.total
    assert(p.adviceButton);p.adviceButton:emit('Tapped');D.sleep(.05);assert(p.advicePanel and not p.visible)
    local detail=p.advicePanel;assert(detail.label.text:find(special,1,true),'Training instructions dropped')
    if p.loadoutAdvice then assert(detail.label.text:find(p.loadoutAdvice,1,true),'Mission advice dropped')end
    assert(detail.area.viewSize.height>=detail.label.height+40)
    detail.backButton:emit('Tapped');assert(p.visible and not p.advicePanel and values==D.json.encode(p.values,false,true)and quote==p.quote.total)
    r.cases[#r.cases+1]={mission=mission,resolution={D.App.bufferSize.width,D.App.bufferSize.height},noteHeight=p.noteLabel.height,noteBottom=p.noteLabel.y-p.noteLabel.height,detailHeight=detail.label.height,quote=quote};save();p:removeFromParent()
   end
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and tostring(err)or nil;save()
end)
