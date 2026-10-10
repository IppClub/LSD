local D=require('Dora');local R=require('Economy.Recovery')
return function(args)
 local view=require('UI.Control.Basic.AlignNode')({isRoot=true,inUI=true});view.order=110
 local panel=D.Node();panel:addTo(view)
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-640,-360),D.Vec2(640,-360),D.Vec2(640,360),D.Vec2(-640,360)},D.Color(0xff111c29));bg:addTo(panel)
 local function label(value,size,y)local l=assert(D.Label('SourceHanSansCN-Regular',size));l.text=value;l.position=D.Vec2(0,y);l:addTo(panel);return l end
 label('整理回收 · 不消耗弹药',32,295)
 local task=label('',25,225);local status=label('',23,-195)
 label(string.format('三件物资归箱后获得最多%d；仅补足至%d行动物资。',R.reward,R.ceiling),21,-240)
 local sprite;view.state=args.state;view.buttons={}
 local function refresh(message)
  local state=view.state
  task.text=state.eligible and ('第'..(state.stage+1)..'/3件：'..R.tasks[state.stage+1].text)or '补给已足够，再检查携带预算后出发。'
  status.text=message or ('当前行动物资 '..state.balance)
  if sprite then sprite:removeFromParent()end
  sprite=assert(D.Sprite('Image/Equipment/'..R.tasks[state.stage+1].art..'.png'));local k=math.min(370/sprite.width,120/sprite.height);sprite.scaleX=k;sprite.scaleY=k;sprite.position=D.Vec2(0,120);sprite:addTo(panel)
 end
 for i,item in ipairs({'kinetic','emp','laser'})do
  local node=D.Node();node.position=D.Vec2((i-2)*330,-60);node:addTo(panel)
  local box=assert(D.Sprite('Image/Equipment/crate-'..item..'-small.png'));local k=math.min(150/box.width,130/box.height);box.scaleX=k;box.scaleY=k;box:addTo(node)
  local holder=D.Node();holder.scaleX=.5;holder.scaleY=.5;holder.position=D.Vec2(-74,-105);holder:addTo(node)
  local button=require('UI.PropButton')({text=({'实弹箱','EMP箱','激光箱'})[i]});button:addTo(holder);view.buttons[item]=button
  button:slot('Tapped',function()
   if view.busy or not view.state.eligible then return end
   view.busy=true;local state=view.state
   D.thread(function()
    local nextState,why=R.sortAsync(state.round,state.stage,item);view.busy=false
    if nextState then view.state=nextState;refresh(nextState.reward>0 and ('整理完成，回收 +'..nextState.reward..' · 余额 '..nextState.balance)or nil)
    else refresh(why=='WRONG_CRATE' and '箱子类型不匹配，再看看武器上的颜色。' or '暂不能保存回收进度，请返回后重试。')end
   end)
  end)
 end
 local holder=D.Node();holder.scaleX=.55;holder.scaleY=.55;holder.position=D.Vec2(-82,-330);holder:addTo(panel)
 view.backButton=require('UI.PropButton')({text='返回补给'});view.backButton:addTo(holder);view.backButton:slot('Tapped',function()if not view.busy then view:removeFromParent();args.closed()end end)
 view:slot('AlignLayout',function(w,h)local k=math.min(w/1280,h/720);panel.scaleX=k;panel.scaleY=k;panel.position=D.Vec2(w/2,h/2)end)
 refresh();return view
end
