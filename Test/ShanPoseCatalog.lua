-- Native frozen authored poses for attacks without embedded attack events.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","shan-pose-catalog-result.txt")
D.Content:save(out,"LSD_SHAN_POSES_RUNNING\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  D.Cache:loadAsync("spine:dashanxiao"); D.Cache:loadAsync("spine:xiaoshanxiao")
  local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
  local rows={{"dashanxiao","throw",{0.7,1,1.3,1.6}},{"dashanxiao","punch",{1,1.4,1.8,2.2}},{"dashanxiao","slum",{0.7,1.1,1.5,2}},{"xiaoshanxiao","throw",{0.4,0.7,0.9,1.1}},{"xiaoshanxiao","scratch",{0.3,0.6,0.8,1}},{"xiaoshanxiao","rush",{0.6,1,1.4,1.8}}}
  local pending=0; local durations={}
  for r,row in ipairs(rows) do for col,t in ipairs(row[3]) do
   local m=assert(D.Spine(row[1])); m.scaleX=row[1]=="dashanxiao" and 0.23 or 0.35; m.scaleY=m.scaleX; m.position=D.Vec2((col-0.5)*ui.width/4,ui.height-r*ui.height/6+50); m:addTo(ui); m.recovery=0
   durations[row[1].."/"..row[2]]=m:play(row[2],false)
   local label=D.Label("SourceHanSansCN-Regular",16); label.text=string.format("%s/%s %.2fs",row[1],row[2],t); label.position=m.position+D.Vec2(0,-24); label:addTo(ui)
   pending=pending+1; D.thread(function() D.sleep(t); m.speed=0; pending=pending-1 end)
  end end
  while pending>0 do D.sleep(0.02) end
  return "PASS actualFrozenFrames=24 durations="..D.json.encode(durations,false,true)
 end,debug.traceback)
 local report="LSD_SHAN_POSES_"..(ok and result or "FAIL "..tostring(result)); print(report); D.Content:save(out,report.."\n")
end)
