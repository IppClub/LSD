local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local report={status='RUNNING',osInput=false,databaseAccess=false,visualAcceptance=false}
 local ok,err=xpcall(function()
  local file=D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.json')..'|'..D.Path(root,'Docs/artwork/final-portraits/prototype/ninilite-emotion.atlas')
  D.Cache:loadAsync('spine:'..file)
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  local m=assert(D.Spine(file));m.scaleX=.3;m.scaleY=.3;m.position=D.Vec2(ui.width/2-100,80);m.recovery=.2;m:addTo(ui)
  local ends={};m:slot('AnimationEnd',function(name)if name=='listenCandidate'then ends[#ends+1]=D.App.runningTime end end)
  local duration=m:play('listenCandidate',true);assert(duration>5.3 and duration<5.4);report.duration=duration
  local start=D.App.runningTime
  for _,sample in ipairs({{1,'open'},{2.2,'blink'},{2.5,'reopen'},{5.4,'loop'}})do
   while D.App.runningTime-start<sample[1]do D.sleep(.005)end
   D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-portrait-listen-'..sample[2]..'.tga'))
  end
  while #ends<2 do assert(D.App.runningTime-start<12,'Incomplete loop');D.sleep(.02)end
  report.loopSeconds=ends[2]-ends[1];assert(math.abs(report.loopSeconds-duration)<.06)
  report.completedLoops=#ends;report.recovery=m.recovery
  m:play('idle',true);D.sleep(.5)
  m:play('listenCandidate',true)
  for i,delay in ipairs({.05,.05,.15})do
   D.sleep(delay);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-portrait-recovery-'..i..'.tga'));D.sleep(.02)
  end
  report.recoverySamples=true;report.status='PASS_TIMING_ONLY'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 D.Content:save(D.Path(root,'Test/final-portrait-motion-result.json'),D.json.encode(report));print(D.json.encode(report))
end)
