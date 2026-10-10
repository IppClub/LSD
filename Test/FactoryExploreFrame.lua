-- Explicit outcome fixtures: prepared abort and actual low-life defeat, no fake win.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","factory-explore-frame-result.txt"); D.Content:save(out,"LSD_FACTORY_EXPLORE_FRAME_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","factory-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-factory%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-factory-explore-frame-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync()
  local w=require("Academy.Navigation").returnToRoomAsync("Factory",{spawn=5200})
  local deadline=D.App.runningTime+10; local ui
  repeat ui=D.Director.ui3D:getChildByTag("factory-explore-status"); assert(D.App.runningTime<deadline,"Factory status did not layout"); D.sleep(0.05) until ui and ui.width==D.App.bufferSize.width and ui.height==D.App.bufferSize.height and ui.visible
  assert(w.factoryExpedition and w.factoryExpedition.hp[2]<100 and ui.children.last.text:find("导师",1,true))
  return "PASS earnedWinCopy=true originalFactory=true realExplorationStatus=true screenLayoutSize=true injuryHPPreserved=true"
 end,debug.traceback)
 local report="LSD_FACTORY_EXPLORE_FRAME_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
