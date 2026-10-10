local D=require('Dora');local E={}
function E.openAsync(onReturn,characterId,models,candidate,values)
 D.Director.ui3D:removeAllChildren()
 local budget=require('UI.SupplyLoadout')({virtual=true,virtualMode='disarm-compare',values=values or require('Economy.Loadout').defaults(),formation={mentor=true,learner=true,wuyun=true},closed=function(confirmed,selection)
  if not confirmed then require('Training.Level')(onReturn,characterId);return end
  D.thread(function()
   local state={cancelled=false,running=true};local label;local updated=0
   local record,why=require('Training.DisarmCompare').runAsync(candidate,models,selection.loadout,{
    cancelled=function()return state.cancelled end,
    onBattle=function(b,index,total,profile,controller)
     state.battle=b;state.index=index;state.profile=profile;state.controller=controller
     local ui=D.Node();ui.tag='disarm-comparison-progress';ui.state=state;state.progress=ui;ui:addTo(D.Director.ui3D)
     local bg=D.DrawNode();bg:drawPolygon({D.Vec2(0,0),D.Vec2(D.App.bufferSize.width,0),D.Vec2(D.App.bufferSize.width,175),D.Vec2(0,175)},D.Color(0xee111c29));bg.position=D.Vec2(0,D.App.bufferSize.height-175);bg:addTo(ui)
     label=assert(D.Label('SourceHanSansCN-Regular',26));label.anchor=D.Vec2(0,1);label.alignment='Left';label.textWidth=D.App.bufferSize.width-360;label.position=D.Vec2(30,D.App.bufferSize.height-25);label:addTo(ui)
     local holder=D.Node();holder.position=D.Vec2(D.App.bufferSize.width-175,D.App.bufferSize.height-90);holder.scaleX=.5;holder.scaleY=.5;holder:addTo(ui)
     local cancel=require('UI.PropButton')({text='停止对照'});cancel:addTo(holder);cancel:slot('Tapped',function()state.cancelled=true end);ui.cancelButton=cancel;updated=0
    end,
    update=function(b)
     if not label or D.App.runningTime<updated then return end;updated=D.App.runningTime+.2
     label.text=string.format('缴械自动对照 %d / 6 · %s · %s\n同一补给、导师协作规则与基础队伍；本轮不接受手动战斗输入。\n敌人生命 %.0f / 360 · 模拟消耗 %d\n%s',state.index,({near='近距',middle='中距',far='远距'})[state.profile],state.controller=='baseline'and '基础模型'or'候选',b.enemies[1].enemyHP,b.supplies.ledger.spent,state.cancelled and '正在停止并保存单场观察…'or'可停止对照；完整六场结束后查看结果。')
    end,
   })
   state.running=false;state.progress=nil;state.record=record;state.error=why
   local saved,saveWhy
   if not why then saved,saveWhy=require('Training.DisarmComparisonStore').saveAsync(record)end
   state.error=why or saveWhy
   D.Director.ui3D:removeAllChildren()
   local view
   view=require('UI.DisarmComparison')({record=record,error=why or saveWhy,saved=saved,saveFailed=not why and not saved,closed=function()if not state.saving then require('Training.Level')(onReturn,characterId)end end,
    retry=function(panel)
     if state.saving or state.saved then return end;state.saving=true;panel:setSaveState(true)
     D.thread(function()
      local id,err=require('Training.DisarmComparisonStore').saveAsync(record);state.saving=false;state.saved=id;state.error=err
      panel:setSaveState(false,id,err)
     end)
    end})
   state.saved=saved;view.state=state;view.tag='disarm-comparison-result';view:addTo(D.Director.ui3D);view:alignLayout()
  end)
 end})
 budget.tag='disarm-comparison-budget';budget:addTo(D.Director.ui3D);budget:alignLayout();return budget
end
return E
