local D=require('Dora');local Review=require('Training.ResourceQReview')
return function(args)
 local view=require('UI.Control.Basic.AlignNode')({isRoot=true,inUI=true});view.order=110;view.index=1;view.groups=Review.build(args.records)
 view.assessment=require('Training.ResourceAssessment').build(view.groups)
 local panel=D.Node();panel:addTo(view)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-640,-360),D.Vec2(640,-360),D.Vec2(640,360),D.Vec2(-640,360)},D.Color(0xff111c29));bg:addTo(panel)
 local title=assert(D.Label('SourceHanSansCN-Regular',30));title.position=D.Vec2(-585,320);title.anchor=D.Vec2(0,1);title.text='资源试战 · 同配装对照';title:addTo(panel)
 local header=assert(D.Label('SourceHanSansCN-Regular',22));header.position=D.Vec2(-585,270);header.anchor=D.Vec2(0,1);header:addTo(panel)
 local area=require('UI.Control.Basic.ScrollArea')({width=1170,height=470,x=0,y=-15,scrollBar=true});area:addTo(panel);view.area=area
 local label=assert(D.Label('SourceHanSansCN-Regular',24));label.anchor=D.Vec2(0,1);label.alignment='Left';label.textWidth=1110;label.position=D.Vec2(20,450);label:addTo(area.view);view.label=label
 local function refresh()
  local group=view.groups[view.index]
  header.text=group and string.format('%d / %d · 候选 #%d · %s',view.index,#view.groups,group.key.candidate,require('Training.FlowerScenarios').get(group.key.profile).name)or '尚无可对照记录'
  if view.showAssessment then header.text='当前候选 · 采用前检查'end
  label.text=view.showAssessment and require('Training.ResourceAssessment').text(view.assessment)or Review.text(group);area.viewSize=D.Size(1170,math.max(470,label.height+40));area:scrollTo(D.Vec2.zero)
 end
 local function button(text,x,fn)
  local holder=D.Node();holder.position=D.Vec2(x,-330);holder.scaleX=.5;holder.scaleY=.5;holder:addTo(panel)
  local b=require('UI.PropButton')({text=text});b:addTo(holder);b:slot('Tapped',fn);return b
 end
 view.previous=button('上一配置',-510,function()view.showAssessment=false;if #view.groups>0 then view.index=(view.index-2)%#view.groups+1;refresh()end end)
 view.next=button('下一配置',-220,function()view.showAssessment=false;if #view.groups>0 then view.index=view.index%#view.groups+1;refresh()end end)
 view.previous.visible=#view.groups>1;view.next.visible=#view.groups>1
 view.summaryButton=button('整体评价',70,function()view.showAssessment=true;refresh()end)
 view.back=button('返回训练',400,function()view:removeFromParent();args.closed()end)
 view:slot('AlignLayout',function(w,h)local k=math.min(w/1280,h/720);panel.scaleX=k;panel.scaleY=k;panel.position=D.Vec2(w/2,h/2)end)
 refresh();return view
end
