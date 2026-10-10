-- Freeze actual Spine poses at measured progress, for native frame calibration.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","boss-pose-catalog-result.txt"); D.Content:save(out,"LSD_BOSS_POSES_RUNNING\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren(); D.Cache:loadAsync("spine:dataotie")
  local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
  local names={"trample","swing","pounce","shot","rush1"}; local times={{0.3,0.4,0.5,0.6},{0.7,0.9,1.1,1.3},{1.1,1.3,1.5,1.7},{0.4,0.65,1.0,1.4},{0.1,0.5,0.9,1.2}}; local durations={}; local pending=0
  for row,name in ipairs(names) do
   for col,ratio in ipairs(times[row]) do
    local m=D.Spine("dataotie"); m.scaleX=0.30; m.scaleY=0.30; m.position=D.Vec2((col-0.5)*ui.width/4,ui.height-row*ui.height/5+35); m:addTo(ui)
    m.recovery=0; local duration=m:play(name,false); assert(duration>0,name.." absent"); durations[name]=duration
    local label=D.Label("SourceHanSansCN-Regular",18); label.text=string.format("%s · %.2fs",name,ratio); label.position=m.position+D.Vec2(0,-23); label:addTo(ui)
    pending=pending+1
    D.thread(function() D.sleep(ratio); m.speed=0; pending=pending-1 end)
   end
  end
  while pending>0 do D.sleep(0.05) end
  return "PASS frozenFrames=20 recoveryZeroForInspectionOnly=true durations="..D.json.encode(durations)
 end,debug.traceback)
 local report="LSD_BOSS_POSES_"..(ok and result or "FAIL "..result); print(report); D.Content:save(out,report.."\n")
end)
