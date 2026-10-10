local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local output=root..'/Test/failure-reason-result.json'
local r={status='RUNNING',osInput=false,historicalBattle=true,uiOnly=true,layoutCases={}}
local function save()D.Content:save(output,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(os.getenv('LSD_QA_FAILURE_RECORD'))
  assert(source:match('^/private/tmp/lsd%-pursuit%-result%-os%-boss%-resource%-loadout%-20261009/result%.json$'))
  local raw=assert(D.Content:load(source));local record=assert(D.json.decode(raw,32))
  assert(record.status=='PASS'and record.outcome=='failed'and record.returnedToTrain)
  local report=record.battle;assert(report.reason=='辅助机被摧毁，调查行动中止。')
  for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.15)
   local view=require('UI.Settlement')({missionMode=true,resultStatus='Failed',resultTitle='讨伐未完成',missionTitle='地面调查 · 大英招讨伐',economy=report.economy,storyText=report.reason,reportText='真实失败战报',baseText='返回列车'})
   view:addTo(D.Director.ui3D);D.sleep(.2);view:alignLayout();D.sleep(.1)
   local image=D.Path(D.Content.writablePath,'failure-reason-'..size.width..'.tga');D.App:saveScreenshot(image);D.sleep(.1)
   r.layoutCases[#r.layoutCases+1]={path=image,width=D.App.bufferSize.width,height=D.App.bufferSize.height};save()
   assert(view.resultLayout=='MissionFail'and view.failureReasonLabel,'Dedicated failure page hides the recorded failure cause')
   local reason=view.failureReasonLabel
   assert(reason.text==report.reason and reason.visible and reason.height<90)
   local low=reason:convertToWorldSpace(D.Vec2.zero)+D.Vec2(D.App.bufferSize.width/2,D.App.bufferSize.height/2)
   local high=reason:convertToWorldSpace(D.Vec2(reason.width,reason.height))+D.Vec2(D.App.bufferSize.width/2,D.App.bufferSize.height/2)
   assert(low.x>=0 and low.y>=0 and high.x<=D.App.bufferSize.width and high.y<=D.App.bufferSize.height,'Failure reason outside the viewport')
   r.layoutCases[#r.layoutCases].reasonBounds={low.x,low.y,high.x,high.y};save()
   assert(view.economyLabel.text:find('消耗 %-55')and view.economyLabel.text:find('结余 434',1,true))
   view.reportButton:emit('Tapped');D.sleep(.1);assert(view.reportPanel and not view.visible)
   assert(view.reportLabel.text:find(report.reason,1,true))
   view.reportPanel.backButton:emit('Tapped');D.sleep(.1);assert(view.visible and not view.reportPanel and reason.visible)
   view:removeFromParent()
  end
  assert(D.Content:load(source)==raw);r.sourceUnchanged=true;r.reason=report.reason
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
