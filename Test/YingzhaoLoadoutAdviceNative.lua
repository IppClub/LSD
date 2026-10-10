local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-loadout-advice-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local L=require('Economy.Loadout');local A=require('Economy.LoadoutAdvice');local I=require('Training.FlowerIdentity')
  D.Cache:loadAsync('button.clip')
  for _,virtual in ipairs({false,true})do
   local values=L.defaults();local baseline=D.json.decode(D.json.encode(values),32)
   local view=require('UI.SupplyLoadout')({mission='c0-yingzhao',virtual=virtual,virtualMode='yingzhao-compare',values=values,formation={mentor=true,learner='ninilite',wuyun=true},balance=500})
   view:addTo(D.Director.ui3D);view:alignLayout();D.sleep(.2)
   local total=view.quote.total;assert(view.adviceButton)
   D.App:saveScreenshot(root..'/Test/yingzhao-loadout-advice-budget.tga');D.sleep(.1)
   view.adviceButton:emit('Tapped');assert(view.advicePanel and not view.visible)
   local popup=view.advicePanel;assert(popup.label.text:find('不造成生命伤害',1,true)and popup.label.text:find('导师实弹 40',1,true))
   assert(popup.label.text:find('上限 900',1,true)and popup.label.text:find('仅靠这些实弹无法击败Boss',1,true));assert(popup.area.viewSize.height>popup.area.height);D.sleep(.2)
   D.App:saveScreenshot(root..'/Test/yingzhao-loadout-advice-top.tga');D.sleep(.1);popup.area:scrollTo(D.Vec2(0,popup.area.viewSize.height-460));D.sleep(.2)
   D.App:saveScreenshot(root..'/Test/yingzhao-loadout-advice-bottom.tga');D.sleep(.1)
   popup.backButton:emit('Tapped');assert(view.visible and not view.advicePanel and view.quote.total==total and I.equal(values,baseline))
   for i=1,5 do view.buttons[1][1]:emit('Tapped')end
   view.adviceButton:emit('Tapped');assert(view.advicePanel.label.text:find('上限 1012.5',1,true)and not view.advicePanel.label.text:find('仅靠这些实弹无法击败Boss',1,true));view.advicePanel.backButton:emit('Tapped')
   for i=1,5 do view.buttons[1][-1]:emit('Tapped')end
   for i=1,40 do view.buttons[1][-1]:emit('Tapped')end
   view.adviceButton:emit('Tapped');assert(view.advicePanel.label.text:find('未携带导师实弹',1,true));view.advicePanel.backButton:emit('Tapped')
   view.adviceButton:emit('Tapped');local opened=view.advicePanel;view:removeFromParent();D.sleep(.1);assert(not opened.parent,'Advice leaked after loadout cleanup')
  end
  local text=A.bossDetails(L.defaults(),{mentor=true})
  assert(text:find('学员EMP 0',1,true)and text:find('乌云近战能量 0',1,true),'Excluded member supplies counted')
  local empty=L.defaults();empty['mentor:kinetic']=0;empty['wuyun:blade']=0;empty['ninilite:emp']=0;empty['wuyun:emp']=0
  text=A.bossDetails(empty,{mentor=true,learner=true,wuyun=true});assert(text:find('生命伤害需依靠技能',1,true)and text:find('主要破甲手段',1,true))
  r.checks={'formal and virtual entry','live quantities','active formation only','no write or automatic budget change','scroll return cleanup'}
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
