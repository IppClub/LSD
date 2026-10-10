local D=require('Dora');local Store=require('Training.DisarmStore')
return function(args)
 local view=require('UI.Control.Basic.AlignNode')({isRoot=true,inUI=true});view.order=110;view.index=1;view.ids,view.readError=Store.listAsync();view.ids=view.ids or{}
 local panel=D.Node();panel:addTo(view)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-640,-360),D.Vec2(640,-360),D.Vec2(640,360),D.Vec2(-640,360)},D.Color(0xff111c29));bg:addTo(panel)
 local function label(text,size,x,y,width)
  local node=assert(D.Label('SourceHanSansCN-Regular',size));node.text=text;node.alignment='Left';node.anchor=D.Vec2(0,1);node.position=D.Vec2(x,y);node.textWidth=width or 1150;node:addTo(panel);return node
 end
 label('缴械演练 · 资源复盘',30,-585,320)
 local header=label('',22,-585,270)
 local area=require('UI.Control.Basic.ScrollArea')({width=1170,height=460,x=0,y=-20,scrollBar=true});area:addTo(panel);view.area=area
 local body=assert(D.Label('SourceHanSansCN-Regular',24));body.alignment='Left';body.anchor=D.Vec2(0,1);body.textWidth=1110;body.position=D.Vec2(20,440);body:addTo(area.view);view.label=body
 local names={mentor='导师',ninilite='妮妮莉特',wuyun='乌云'}
 local function refresh()
  local id=view.ids[view.index];local record,why
  if id then record,why=Store.loadAsync(id)end
  view.record=record
  header.text=id and string.format('最近20场 · %d / %d · 记录 #%d',view.index,#view.ids,id)or '尚无已保存的缴械演练'
  if record then
   local trace,review=record.source.trace,record.review
   local lines={string.format('结果：%s　模拟总成本 %d',({won='胜利',failed='失败',aborted='已结束'})[trace.status],review.total),string.format('整备 %d　自用消耗 %d　被夺武器消耗 %d',review.deployment,review.ownCost,review.stolenCost),'不扣真实物资；失败或主动结束的低消耗不代表战术更好。',''}
   if trace.candidate then
    local candidate=trace.candidate
    if type(candidate)=='table'and type(candidate.id)=='number'and require('Training.DisarmPolicy').validate(candidate.model)then lines[#lines+1]='候选试战：'..names[candidate.model.characterId]..' #'..candidate.id
    else lines[#lines+1]='候选信息不完整，暂不作效果比较。'end
    lines[#lines+1]=''
   end
   if trace.demonstrator then lines[#lines+1]='本场亲自示范：'..(names[trace.demonstrator]or trace.demonstrator);lines[#lines+1]=''end
   for _,actor in ipairs({'mentor','ninilite','wuyun'})do local owner=review.byOwner[actor];if owner then lines[#lines+1]=string.format('%s：自用%d，被夺后消耗%d',names[actor],owner.ownCost,owner.stolenCost)end end
   if trace.vitalsVersion==1 then
    local v=require('Training.DisarmVitals').review(trace.vitals)
    if v then lines[#lines+1]=string.format('队伍累计承伤 %d（拳脚 %d，被夺武器 %d，其他 %d）',v.damage,v.byKind['enemy-melee']or 0,v.byKind['stolen-firearm']or 0,v.byKind.unknown or 0)
    else lines[#lines+1]='承伤记录不完整，暂不作效果比较。'end
   end
   lines[#lines+1]='';lines[#lines+1]=require('UI.ResultDetails').breakdown(trace.virtualResult,'virtual')
   lines[#lines+1]='\n此记录用于复盘，尚未用于训练或改变已采用模型。'
   body.text=table.concat(lines,'\n')
  else body.text=view.readError and '记录暂时读取失败，请返回后重试。'or id and '这条记录未通过读取核对，暂不能展示。请选择其他记录。'or '完成一次缴械演练后，可在这里查看已保存的资源消耗。'end
  area.viewSize=D.Size(1170,math.max(460,body.height+40));area:scrollTo(D.Vec2.zero)
 end
 local function button(text,x,fn)
  local holder=D.Node();holder.position=D.Vec2(x,-330);holder.scaleX=.5;holder.scaleY=.5;holder:addTo(panel)
  local b=require('UI.PropButton')({text=text});b:addTo(holder);b:slot('Tapped',fn);return b
 end
 view.previous=button('上一记录',-500,function()if #view.ids>0 then view.index=(view.index-2)%#view.ids+1;refresh()end end)
 view.next=button('下一记录',-100,function()if #view.ids>0 then view.index=view.index%#view.ids+1;refresh()end end)
 view.closeButton=button('返回训练',300,function()view:removeFromParent();if args.closed then args.closed()end end)
 view.previous.visible=#view.ids>1;view.next.visible=#view.ids>1
 view:slot('AlignLayout',function(w,h)local k=math.min(w/1280,h/720);panel.scaleX=k;panel.scaleY=k;panel.position=D.Vec2(w/2,h/2)end)
 refresh();return view
end
