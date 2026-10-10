-- Earned energy copy, actual Start and academy doors, physical NPC escort and Yarn.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","ayan-aftertrial-frame-result.txt"); D.Content:save(out,"LSD_AYAN_AFTERTRIAL_FRAME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","liyena-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-liyena%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-ayan-aftertrial-frame-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local w=require("Academy.Navigation").returnToTrainingAsync()
  local deadline=D.App.runningTime+10
  while not (w.academyVisit and w.academyVisit.actor and w.academyVisit.hint.text~="") do assert(D.App.runningTime<deadline,"Guide frame timed out"); D.sleep(0.05) end
  local c=w.academyVisit; assert(c.stage>=4 and c.hint.parent.width==D.App.bufferSize.width and c.hint.parent.visible)
  local player=assert(D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==w end))
  local function move(x)
   local untilTime=D.App.runningTime+12
   while math.abs(player.unit.x-x)>25 do assert(D.App.runningTime<untilTime,"Guide visual framing walk stalled"); player.keyLeft=player.unit.x>x; player.keyRight=player.unit.x<x; D.sleep(0.03) end
   player.keyLeft=false; player.keyRight=false; D.sleep(0.3)
  end
  move(1900); deadline=D.App.runningTime+8
  assert(w.afterTrial and c.stage==5 and c.tray.visible and c.view.menu.enabled)
  local others=D.Group({"name","unit"}):find(function(e) return e.unit.world==w and (e.name=="lin" or e.name=="liyena") end)
  assert(not others,"Departed companions still in room")
  assert(math.abs(player.unit.x-c.actor.unit.x)>100,"Actor/player overlap")
  c.view.menu.children:each(function(button) assert(button.children.last.width+35<=button.width,"After-trial option spills"); return false end)
  return "PASS physicalFoodMeeting=true optionTextFits=true separateActors=true earnedTwoFightCopy=true foodTrayPrototype=true originalRoom=true nativeGuideViewport=true visibleGuidance=true"
 end,debug.traceback)
 local report="LSD_AYAN_AFTERTRIAL_FRAME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
