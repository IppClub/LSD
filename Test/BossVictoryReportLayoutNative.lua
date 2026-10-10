-- Re-render an actual earned victory report; no battle or database mutation.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/boss-victory-report-layout-result.json'
local r={status='RUNNING',scope='Actual saved Boss victory data in original Settlement; layout/scroll only, not another combat victory',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-report-snapshot-continuous-os-boss-20261009/result.json'),32)
  assert(prior.status=='PASS'and prior.outcome=='won'and prior.returnedToTrain)
  local code,compileError=D.xml.tolua(D.Content:load(root..'/UI/Settlement.xml'));assert(code,compileError)
  assert(D.Content:save(D.Path(D.Content.writablePath,'Settlement.generated.lua'),'-- [xml]: UI/Settlement.xml\n'..code))
  D.Cache:loadAsync({'ar.clip','button.clip'})
  local report=require('Training.YingzhaoContributions').text(prior.trace)..'\n\n'..string.format('导师命中 %d · 火羽命中 %d · 旋风命中 %d\n净收益以实际消耗和任务收入计算。',prior.battle.mentorHits,prior.battle.fireHits,prior.battle.windHits)
  local support=require('Factory.Support').resultText(prior.battle);if support then report=report..'\n'..support end
  local v=require('UI.Settlement')({missionMode=true,missionCategory='Side',missionTitle='地面调查 · 大英招讨伐',resultTitle='大英招已击退',resultStatus='Complete',reportText=report,storyText=prior.battle.reason,economy=prior.battle.economy,againText='继续调查',baseText='返回列车'})
  v:addTo(D.Director.ui3D)
  for _,size in ipairs({D.Size(1280,768),D.Size(960,540),D.Size(683,384)})do
   D.App.winSize=size;D.sleep(.3);v:alignLayout();D.sleep(.15)
   local a,l=v.reportArea,v.reportLabel
   local row={resolution={D.App.bufferSize.width,D.App.bufferSize.height},areaWidth=a.area.width,areaHeight=a.area.height,viewWidth=a.viewSize.width,viewHeight=a.viewSize.height,labelWidth=l.width,labelHeight=l.height,labelX=l.x,labelY=l.y,textWidth=l.textWidth,offsetTop={a.offset.x,a.offset.y}}
   r.cases[#r.cases+1]=row;save()
   a:scrollToPosY(10000,0);D.sleep(.15)
   D.App:saveScreenshot(D.Path(D.Content.writablePath,'boss-victory-report-'..size.width..'-top.tga'));D.sleep(.1)
   a:scrollToPosY(-10000,0);D.sleep(.15)
   row.offsetBottom={a.offset.x,a.offset.y};row.visibleBottom=l.y-l.height;row.visibleTop=l.y-a.offset.y
   local bottom=l:convertToWorldSpace(D.Vec2(0,0));local upper=l:convertToWorldSpace(D.Vec2(l.width,l.height))
   row.bottomWorld={bottom.x,bottom.y};row.upperWorld={upper.x,upper.y};save()
   D.App:saveScreenshot(D.Path(D.Content.writablePath,'boss-victory-report-'..size.width..'-bottom.tga'));D.sleep(.1)
   assert(l.width<=a.area.width-20,'Report label wider than viewport')
   assert(a.viewSize.height>=l.height,'Report scroll height truncates text')
   assert(math.abs(a.offset.y)>0,'Long report cannot scroll')
   assert(l.y-l.height>=19.9 and l.y-l.height<=20.1,'Final report line is not inside the bottom viewport')
   assert(math.abs(l.y-a.offset.y-823)<.1,'Report top moved outside viewport after resize')
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
