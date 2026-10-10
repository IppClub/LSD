local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/failure-result-layout-result.json';local r={status='RUNNING',osInput=false,sizes={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  D.Cache:loadAsync({'ar.clip','button.clip'})
  local source='/private/tmp/lsd-single-package-materials-earned-retry-preserved-story-20261007/result.json'
  local failed=D.json.decode(assert(D.Content:load(source)),256)
  local b=assert(failed.failureBattle);assert(b.economy.status=='failed')
  for _,size in ipairs({D.Size(683,384),D.Size(960,540)})do
   D.App.winSize=size;D.sleep(.4)
   local report=require('Training.FlowerEvaluation').text(b.evaluation)
   local args={missionMode=true,economy=b.economy,missionTitle='废弃工厂 · 沼泽花妖',resultTitle='调查中止',resultStatus='Failed',reportText=report,storyText='行动超时，返回训练与补给。\n采用模型保留；返回列车检查队伍，再来调查。'}
   local v=require('UI.Settlement')(args);v:addTo(D.Director.ui3D);v:alignLayout();D.sleep(.3)
   assert(v.resultLayout=='MissionFail' and v.reportButton)
   local width=math.floor(D.App.bufferSize.width);local top=root..'/Test/failure-result-'..width..'-top.tga'
   D.App:saveScreenshot(top);D.sleep(.15)
   v.reportButton:emit('Tapped');local popup=assert(v.reportPanel);assert(not v.visible and popup.label.text:find(report,1,true))
   assert(popup.label.text:find('消耗明细',1,true));D.sleep(.2)
   D.App:saveScreenshot(root..'/Test/failure-result-'..width..'-report.tga');D.sleep(.15)
   popup.area:scrollTo(D.Vec2(0,popup.area.viewSize.height-popup.area.contentSize.height));D.sleep(.2)
   assert(popup.label.visible,'Report culled at legal scroll limit')
   local bottom=root..'/Test/failure-result-'..width..'-bottom.tga';D.App:saveScreenshot(bottom);D.sleep(.15)
   popup.backButton:emit('Tapped');assert(v.visible and not v.reportPanel and popup.parent==v and not popup.visible)
   v:setReportText('配装读取失败，请重试。\n'..popup.label.text);v.reportButton:emit('Tapped');assert(v.reportPanel==popup and popup.label.text:find('配装读取失败',1,true));popup.backButton:emit('Tapped')
   local again,base=0,0;v.againButton:slot('Tapped',function()again=again+1 end);v.baseButton:slot('Tapped',function()base=base+1 end)
   v.againButton:emit('Tapped');v.baseButton:emit('Tapped');assert(again==1 and base==1)
   r.sizes[#r.sizes+1]={width=width,top=top,bottom=bottom,reportHeight=popup.label.height,scrollHeight=popup.area.viewSize.height,labelVisible=popup.label.visible,labelPosition={x=popup.label.x,y=popup.label.y},labelAnchor={x=popup.label.anchor.x,y=popup.label.anchor.y},labelSize={width=popup.label.width,height=popup.label.height},menuSize={width=popup.area.view.width,height=popup.area.view.height},offset={x=popup.area.offset.x,y=popup.area.offset.y}}
   v.reportButton:emit('Tapped');local orphan=assert(v.reportPanel);v:removeFromParent();D.sleep(.1);assert(not orphan.parent and not v.reportPanel)
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
