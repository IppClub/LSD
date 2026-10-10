local D=require('Dora')
return function(args)
 local view=require('UI.Control.Basic.AlignNode')({isRoot=true,inUI=true});view.order=110
 local panel=D.Node();panel:addTo(view);local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-640,-360),D.Vec2(640,-360),D.Vec2(640,360),D.Vec2(-640,360)},D.Color(0xff111c29));bg:addTo(panel)
 local title=assert(D.Label('SourceHanSansCN-Regular',32));title.anchor=D.Vec2(0,1);title.position=D.Vec2(-580,315);title.text=args.title or '缴械对照 · 相同补给与导师规则';title:addTo(panel)
 local area=require('UI.Control.Basic.ScrollArea')({width=1170,height=460,x=0,y=-5,scrollBar=true});area:addTo(panel);view.area=area
 local label=assert(D.Label('SourceHanSansCN-Regular',25));label.alignment='Left';label.anchor=D.Vec2(0,1);label.textWidth=1110;label.position=D.Vec2(20,440);label:addTo(area.view);view.label=label
 function view:setText(text)label.text=text;area.viewSize=D.Size(1170,math.max(460,label.height+40));area:scrollTo(D.Vec2.zero)end
 local function button(text,x,callback)local n=D.Node();n.position=D.Vec2(x,-325);n.scaleX=.5;n.scaleY=.5;n:addTo(panel);local b=require('UI.PropButton')({text=text});b:addTo(n);b:slot('Tapped',callback);return b end
 view.makeButton=button
 view.retryButton=button('重试保存',-350,function()if args.retry then args.retry(view)end end);view.retryButton.visible=args.saveFailed==true
 view.backButton=button(args.backText or '返回训练',300,function()if args.closed then args.closed()end end)
 view.discardButton=button('放弃并返回',300,function()if args.closed then args.closed()end end);view.discardButton.visible=args.saveFailed==true;view.backButton.visible=not args.saveFailed
 function view:setSaveState(saving,saved,error)
  view.retryButton.visible=not saving and not saved;view.discardButton.visible=not saving and not saved;view.backButton.visible=not saving and saved~=nil
  view:setText(require('Training.DisarmCompare').text(args.record)..(saving and '\n正在保存，请稍候…'or saved and ('\n对照记录 #'..saved..' 已保存。')or '\n本轮完整对照尚未保存。可重试保存，或放弃本轮对照并返回；原成果保留。'))
 end
 local summary=args.summary or args.record and require('Training.DisarmCompare').text(args.record)or '没有可展示的对照记录。'
 if args.error then summary=summary..'\n\n'..(args.error=='CANCELLED'and '本轮已停止；完整对照尚未完成。'or '本轮对照或保存未完成；原训练成果保留。')end
 if args.saveFailed then summary=summary..'\n这份完整对照尚未保存，请重试保存后返回。'end
 if args.saved then summary=summary..'\n对照记录 #'..args.saved..' 已保存。'end
 if args.history then
  local Store=require('Training.DisarmComparisonStore');view.ids,view.readError=Store.list();view.ids=view.ids or {};view.index=1
  local function refresh()
   local id=view.ids[view.index];local saved,why;if id then saved,why=Store.load(id)end;view.record=saved
   local heading=id and string.format('最近20组 · %d / %d · 记录 #%d\n\n',view.index,#view.ids,id)or ''
   view:setText(heading..(saved and require('Training.DisarmCompare').text(saved.record)or view.readError and '记录暂时读取失败，请返回后重试。'or id and '这条对照未通过完整核对，无法展示。可切换其他记录。'or '尚无完整对照记录。完成六场缴械对照后可在此查看。'))
  end
  view.previous=button('上一记录',-500,function()if #view.ids>0 then view.index=(view.index-2)%#view.ids+1;refresh()end end)
  view.next=button('下一记录',-100,function()if #view.ids>0 then view.index=view.index%#view.ids+1;refresh()end end)
  view.previous.visible=#view.ids>1;view.next.visible=#view.ids>1;refresh()
 else view:setText(summary)end
 view:slot('AlignLayout',function(w,h)local k=math.min(w/1280,h/720);panel.scaleX=k;panel.scaleY=k;panel.position=D.Vec2(w/2,h/2)end)
 return view
end
