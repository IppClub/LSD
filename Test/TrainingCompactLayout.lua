-- Visual replay of the actual OS-triggered comparison, not a new battle result.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),visualReplay=true};local out=D.Path(root,'Test/training-compact-layout-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local data=assert(D.json.decode(D.Content:load(D.Path(root,'Docs/evidence/2026-10-04/training-comparison-os.json')),128))
  local C=require('Training.ComparisonText');local c,b=data.evaluation.summary.candidate,data.evaluation.summary.baseline
  assert(C.verdict(c,b):find('基础 AI 表现更好',1,true))
  assert(C.verdict(b,c):find('候选整体优于',1,true));assert(C.verdict(c,c):find('结果接近',1,true))
  assert(C.verdict({wins=3,health=50,seconds=5},{wins=2,health=90,seconds=10}):find('各有取舍',1,true))
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-cooperation-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-cooperation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-comparison-layout-qa-'..report.runId..'.db');assert(not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();require('Training.Level')(nil,'wuyun')
  local deadline=D.App.runningTime+30;while not D.Director.ui3D:getChildByTag('training-controls')do assert(D.App.runningTime<deadline);D.sleep(.03)end
  local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena
  a.recorder.samples=data.samples;a.recorder.counts={};for _,sample in ipairs(data.samples)do a.recorder.counts[sample.action]=(a.recorder.counts[sample.action]or 0)+1 end
  a.mode='review';a.candidate=data.candidate;a.evaluation=data.evaluation;a.message=C.verdict(c,b)
  D.sleep(.2);local label=ui:getChildByTag('training-comparison');assert(label.visible and label.text:find('基础 AI 表现更好',1,true))
  local originalSize=D.App.winSize
  D.Director.entry:slot('Cleanup',function()D.App.winSize=originalSize end)
  report.sizes={};report.verdict=C.verdict(c,b)
  for _,size in ipairs({D.Size(640,360),D.Size(480,320)})do
   D.App.winSize=size;D.sleep(.7)
   local buffer=D.App.bufferSize;local menu=ui:getChildByTag('training-menu');local count=0
   for i=1,menu.children.count do
    local button=menu.children:get(i)
    local p=button:convertToWorldSpace(D.Vec2.zero)+D.Vec2(buffer.width/2,buffer.height/2)
    assert(p.x>=0 and p.y>=0 and p.x+button.width*button.scaleX*ui.scaleX<=buffer.width and p.y+button.height*button.scaleY*ui.scaleY<=buffer.height,'Menu outside viewport: '..button.tag)
    count=count+1
   end
   assert(count==15, "Expected 15 training buttons, got "..count)
   local id=tostring(size.width)..'x'..tostring(size.height)
   report.sizes[#report.sizes+1]={windowWidth=size.width,windowHeight=size.height,bufferWidth=buffer.width,bufferHeight=buffer.height,menuCount=count}
   D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/training-compact-'..id..'.tga'));D.sleep(.1)
  end
  report.status='PASS';report.boundsScope='Menu button bounds only; visual replay, not a new battle result'

 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
