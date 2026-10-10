-- Earned factory victory copy; original Start/doors, full treatment and next-day messages.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ruins-frame-result.txt"); D.Content:save(out,"LSD_RUINS_FRAME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ruins-mid-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ruins%-twins%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ruins-frame-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local w=require("Academy.Navigation").returnToRoomAsync("AbandonedCity",{energySquad=true,ruinsSearch=true,spawn=8500})
  local c=w.ruinsExpedition; local deadline=D.App.runningTime+20
  while not (c.phase=="exploring" and c.stage==2 and c.found.menu.enabled) do assert(D.App.runningTime<deadline,"Ruins body formation did not arrive"); D.sleep(0.04) end
  assert(c.body and c.body.visible and c.bodyPose.completedAt and c.body.speed==0 and c.diary.visible)
  assert(c.bodyPose.completedAt-c.bodyPose.startedAt>=c.bodyPose.duration-0.06)
  assert(c.bodyHeldPose and c.bodyHeldPose.originalDeathCompleted and c.bodyHeldPose.sampleSeconds>=0.59 and c.bodyHeldPose.sampleSeconds<0.8,"Persistent body must use the inspected opaque pose after full death completion")
  assert(c.hint.parent.width==D.App.bufferSize.width and c.hint.parent.visible)
  local nodes={}; local points={}; local pending=0
  D.Group({"name","unit"}):each(function(e) if e.unit.world==w then nodes[#nodes+1]=e.unit end; return false end)
  assert(#nodes==5,"Ruins must have five living actors")
  nodes[#nodes+1]=c.body
  for _,node in ipairs(nodes) do for _,x in ipairs({-100,100}) do
   pending=pending+1; node:convertToWindowSpace(D.Vec2(x,0),function(p) points[#points+1]=p; pending=pending-1 end)
  end end
  local projectedBy=D.App.runningTime+1
  while pending>0 do assert(D.App.runningTime<projectedBy,"Ruins projection callback missing"); D.sleep(0.02) end
  assert(#points==12,"Ruins must project all actors and body")
  for _,p in ipairs(points) do assert(p.x>0 and p.x<D.App.visualSize.width,"Ruins camera clips actual projected actor or body") end
  local overflow=false; c.found.menu.children:each(function(b) overflow=overflow or b.children.last.width+35>b.width; return false end); assert(not overflow,"Ruins found button overflow")
  return "PASS earnedTwinsCheckpoint=true originalCity=true fiveLivingActorsFramed=true actualOriginalAyanLoseCompleted=true heldBodyPoseVisible=true diaryVisible=true realFormationArrived=true screenStatusVisible=true menuFits=true"
 end,debug.traceback)
 local report="LSD_RUINS_FRAME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
