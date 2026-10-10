-- Inspect original Ayan death poses, including the completed frame.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","ayan-pose-catalog-result.txt")
D.Content:save(out,"LSD_AYAN_POSES_RUNNING\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  D.Cache:loadAsync("spine:ayan")
  local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
  local pending=0; local completed=false; local duration
  for i,t in ipairs({0.01,0.3,0.6,0.9,1.15}) do
   local m=assert(D.Spine("ayan")); m.position=D.Vec2((i-0.5)*ui.width/5,ui.height/2); m:addTo(ui); m.recovery=0
   if i==5 then m:slot("AnimationEnd",function(name) if name=="lose" then completed=true end end) end
   duration=m:play("lose",false); assert(duration>0)
   local label=D.Label("SourceHanSansCN-Regular",22); label.text=string.format("lose %.2fs",t); label.position=m.position+D.Vec2(0,-180); label:addTo(ui)
   pending=pending+1; D.thread(function() D.sleep(t); m.speed=0; pending=pending-1 end)
  end
  while pending>0 do D.sleep(0.02) end
  assert(completed,"Full original lose must finish")
  return "PASS originalDeathCompleted=true frozenPoses=5 duration="..duration
 end,debug.traceback)
 local report="LSD_AYAN_POSES_"..(ok and result or "FAIL "..tostring(result)); print(report); D.Content:save(out,report.."\n")
end)
