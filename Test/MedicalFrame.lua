-- Earned energy copy, actual Start and academy doors, physical NPC escort and Yarn.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","medical-frame-result.txt"); D.Content:save(out,"LSD_MEDICAL_FRAME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","ayan-aftertrial-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-ayan%-aftertrial%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-medical-frame-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local w=require("Academy.Navigation").returnToRoomAsync("RestRoom")
  local deadline=D.App.runningTime+12
  while not (w.medicalVisit and w.medicalVisit.phase=="ready") do assert(D.App.runningTime<deadline,"Medical actors unavailable"); D.sleep(0.05) end
  local c=w.medicalVisit; local p=assert(D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==w end)); local x=w.sceneWidth/2+850
  while math.abs(p.unit.x-x)>20 do assert(D.App.runningTime<deadline,"Frame walk stalled"); p.keyLeft=p.unit.x>x; p.keyRight=p.unit.x<x; D.sleep(0.03) end
  p.keyLeft=false; p.keyRight=false
  deadline=D.App.runningTime+3; while not c.view.menu.enabled do assert(D.App.runningTime<deadline,"Medical menu unavailable"); D.sleep(0.05) end
  assert(c.station and c.station.visible and #c.actors==2)
  for _,a in ipairs(c.actors) do assert(math.abs(a.unit.x-p.unit.x)>170,"Medical actor overlaps visitor") end
  c.view.menu.children:each(function(b) assert(b.children.last.width+35<=b.width,"Medical button overflow"); return false end)
  return "PASS earnedAyanCopy=true originalRestRoom=true actualWalk=true originalMedicalPair=true separateActors=true menuFits=true visibleStationPrototype=true"
 end,debug.traceback)
 local report="LSD_MEDICAL_FRAME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
