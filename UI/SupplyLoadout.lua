local D=require('Dora');local Loadout=require('Economy.Loadout');local Price=require('Economy.Ledger').items
return function(args)
 local view=require('UI.Control.Basic.AlignNode')({isRoot=true,inUI=true});view.order=100
 local panel=D.Node();panel:addTo(view);view.buttons={};view.values=args.virtual and D.json.decode(D.json.encode(args.values,false,true),32)or args.values
 local bg=D.DrawNode();bg:drawPolygon({D.Vec2(-640,-360),D.Vec2(640,-360),D.Vec2(640,360),D.Vec2(-640,360)},D.Color(0xff111c29));bg:addTo(panel)
 panel.touchEnabled=true;panel.size=D.Size(1280,720);panel.anchor=D.Vec2.zero
 local function text(value,size,x,y,width)
  local l=assert(D.Label('SourceHanSansCN-Regular',size));l.text=value;l.alignment='Left';l.anchor=D.Vec2(0,1);l.position=D.Vec2(x,y);l.textWidth=width or 1100;l:addTo(panel);return l
 end
 local function button(value,x,y,callback)
  local holder=D.Node();holder.scaleX=.45;holder.scaleY=.45;holder.position=D.Vec2(x,y);holder:addTo(panel)
  local b=require('UI.PropButton')({text=value});b:addTo(holder);b:slot('Tapped',callback);return b
 end
 text(args.virtual and '虚拟训练 · 补给预算'or '武器补给 · 携带预算',34,-570,325)
 text(args.virtual and '使用模拟弹药与同一成本规则；不扣正式物资，不更改出战配置。'or '按编队计算整备与携带上限；未使用补给将在任务结束时退回。',20,-570,270)
 text('数量降为0即不携带，不收取该项整备费。',17,-570,238)
 local slots=Loadout.displaySlots(args.mission)
 local labels={};local summary=text('',21,-570,-175);view.summaryLabel=summary
 local note=text(args.virtual and (args.virtualMode=='yingzhao-q' and '你控制导师，学员自主训练；只用虚拟补给，结束后保存候选，可续训，不自动采用。'or args.virtualMode=='yingzhao-compare' and '自动运行原策略与候选各一场，相同补给与导师协作；可停止，不自动采用。'or args.virtualMode=='yingzhao-trial' and '你控制导师，候选控制指定学员；仅消耗虚拟补给，本轮不学习或自动采用。'or args.virtualMode=='big-yingzhao-demo' and '亲自控制学员选择部位、破甲和清理援军；仅消耗虚拟补给，结束后独立保存观察，不自动训练或采用。'or args.virtualMode=='disarm-compare' and '确认后自动运行近、中、远三组旧模型/候选对照，共6场；导师按固定规则协作，不接受手动战斗输入。'or args.virtualMode=='disarm-trial' and '使用当前缴械候选控制指定学员，另一学员沿用旧模型；你控制导师协作，不学习或自动采用。'or args.virtualMode=='disarm-demo' and '确认后亲自控制当前学员示范缴械应对；另一学员沿用旧模型。只保存观察，不自动采用。'or args.virtualMode=='disarm' and '中英招抢枪开火会消耗原持有者的弹药；本次仅作演练，不自动学习或采用。'or args.virtualMode=='demo' and '确认后亲自示范资源战术；模拟弹药有限，完整示范独立保存，正式物资不变。'or args.virtualMode=='evaluate' and '确认后运行冻结资源候选；本轮只评价，不学习或采用。'or args.virtualMode=='explore' and '确认后探索不同合法动作；模拟弹药有限，完成后保存资源练习记录。'or args.virtualMode=='compare' and '确认后运行基础策略对照；请与资源候选使用相同预算。'or '确认后开始基础策略练习；记录模拟消耗与弹药耗尽后的决策。')or args.confirmAsync and '确认后预留预算；成功报酬100，失败无报酬，按实际消耗结算。' or '正式战斗任务使用此配置；训练不扣物资，遗迹掩护的投掷物在出发前另选。',17,-570,-260)
 if args.mission=='c0-m06'then note.text=note.text..'\n烟雾/火光按投掷生效计费；药品使用已有库存，不额外收费。'end
 local standardNote=note.text;view.noteLabel=note
 local function refresh()
  local q,why=Loadout.quote(view.values,args.formation,args.mission);view.quote=q;view.loadoutError=not q and why or nil
  for i,slot in ipairs(slots)do local n=view.values[slot.actor..':'..slot.item];labels[i].text=n==0 and '不携带' or tostring(n)end
  note.text=standardNote
  view.loadoutAdvice=not args.virtual and require('Economy.LoadoutAdvice').text(args.mission,view.values,args.formation) or nil
  if not q then summary.text='本次出战未携带补给。\n请为出战成员至少配置一种补给；数量为0的项目不收整备费。';return end
  if args.virtual then summary.text=string.format('模拟预算 %d　其中整备 %d\n可自由调整数量；训练结束后显示模拟消耗。',q.total,q.deployment);return end
  summary.text=string.format('预算上限 %d　其中整备 %d　可用物资 %d\n%s',q.total,q.deployment,args.balance,q.total>args.balance and '预算超出可用物资，请减少携带数量。' or '预算充足；配置不合适仍可能导致任务亏损。')
  summary.text=summary.text..string.format('\n成功时净收益：%+d 至 %+d（仅成本估算）',100-q.total,100-q.deployment)
 end
 for i,slot in ipairs(slots)do
  local y=190-(i-1)*90
  local sprite=assert(D.Sprite('Image/Equipment/'..slot.art..'.png'));local scale=math.min(155/sprite.width,65/sprite.height);sprite.scaleX=scale;sprite.scaleY=scale;sprite.position=D.Vec2(-490,y-20);sprite:addTo(panel)
  if slot.crate then local crate=assert(D.Sprite('Image/Equipment/'..slot.crate..'.png'));local k=math.min(65/crate.width,65/crate.height);crate.scaleX=k;crate.scaleY=k;crate.position=D.Vec2(-590,y-20);crate:addTo(panel)end
  local active=slot.actor=='mentor' or slot.actor=='ninilite' and args.formation.learner or slot.actor=='wuyun' and args.formation.wuyun
  text(slot.name..(active and '' or '（未编入）'),22,-380,y,410)
  text('每单位 '..Price[slot.item].unit..' · 整备 '..Price[slot.item].deploy,17,-380,y-34,410)
  labels[i]=text('',25,160,y,100)
  view.buttons[i]={}
  local deltas=(args.virtual or slot.optional) and {-1,1} or {-5,-1,1,5}
  for j,delta in ipairs(deltas)do
   local x=#deltas==2 and (delta>0 and 330 or -20) or (-30+(j-1)*160)
   local b=button(delta>0 and '+'..delta or '−'..(-delta),x,y-47,function()
    if view.saving then return end
    local key=slot.actor..':'..slot.item;view.values[key]=math.max(0,math.min(200,view.values[key]+delta));refresh()
   end);view.buttons[i][delta]=b
  end
 end
 do
  view.adviceButton=button('作战说明',110,280,function()
   if view.saving or view.advicePanel then return end
   local popup
   local details=standardNote
   if args.trainingNote then details=details..'\n\n'..args.trainingNote end
   if view.loadoutAdvice then details=details..'\n\n'..view.loadoutAdvice end
   if args.mission=='c0-yingzhao' then details=details..'\n\n'..require('Economy.LoadoutAdvice').bossDetails(view.values,args.formation) end
   popup=require('UI.DisarmComparison')({title=args.mission=='c0-yingzhao' and '大英招 · 配装与武器分工' or '作战说明 · 补给与任务规则',backText='返回配装',summary=details,closed=function()popup:removeFromParent();view.advicePanel=nil;view.visible=true end})
   view.visible=false;view.advicePanel=popup;popup:addTo(D.Director.ui3D);popup:alignLayout()
  end)
 end
 view.defaultsButton=button('恢复默认',370,280,function()
  if view.saving then return end
  view.values=Loadout.defaults();refresh()
 end)
 view.closeButton=button('取消',-560,-325,function()if not view.saving then view:removeFromParent();if args.closed then args.closed(false)end end end)
 view.recoveryButton=button('整理回收',-90,-325,function()
  if args.virtual then return end
  if view.saving then return end
  local state=require('Economy.Recovery').load()
  if not state then note.text='回收任务读取失败，请重试。';return end
  view.visible=false
  local recovery=require('UI.SupplyRecovery')({state=state,closed=function()
   view.visible=true;local wallet=require('Economy.Store').wallet();if wallet then args.balance=wallet.available end;refresh()
  end});view.recoveryPanel=recovery;recovery:addTo(D.Director.ui3D);recovery:alignLayout()
 end)
 view.recoveryButton.visible=not args.virtual
 view.saveButton=button(args.virtual and (args.virtualMode=='evaluate' and '开始试战'or args.virtualMode=='compare' and '开始对照'or '开始练习')or args.confirmAsync and '确认出战' or '保存配置',370,-325,function()
  if view.saving then return end
  if not view.quote then note.text='请先为本次出战配置至少一种补给，再确认。';return end
  view.saving=true
  D.thread(function()
   if args.virtual then
    local _,lines=Loadout.quote(view.values,args.formation,args.mission)
    view.saving=false;view:removeFromParent();if args.closed then args.closed(true,{values=view.values,loadout=lines})end;return
   end
   local ok=Loadout.saveAsync(view.values)
   if not ok then view.saving=false;note.text='配置尚未保存，请重试。';return end
   local attempt,why
   if args.confirmAsync then
    attempt,why=args.confirmAsync()
    if not attempt then view.saving=false;note.text=why or '出战未保存，请重试。';return end
   end
   view.saving=false;view:removeFromParent();if args.closed then args.closed(true,attempt)end
  end)
 end)
 view:slot('Cleanup',function()if view.advicePanel then view.advicePanel:removeFromParent();view.advicePanel=nil end end)
 view:slot('AlignLayout',function(w,h)local k=math.min(w/1280,h/720);panel.scaleX=k;panel.scaleY=k;panel.position=D.Vec2(w/2,h/2)end)
 refresh();return view
end
