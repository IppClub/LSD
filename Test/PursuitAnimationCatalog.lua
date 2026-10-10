-- Authored enemy/mentor/valley tracks: measure actual events and full ends.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","pursuit-animation-catalog-result.txt"); local id=tostring(os.time())
D.Content:save(out,"LSD_PURSUIT_ANIMATIONS_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  local ui=D.Node(); ui.size=D.App.bufferSize; ui:addTo(D.Director.ui3D)
  local rows={}
  local requests={dashanxiao={"throw","slum","punch","ambush"},xiaoshanxiao={"throw","scratch","litter","rush","evade"},charM={"throw","pistol"},charF={"throw","pistol"},villywan={"idle"},dahuli={"idle"}}
  for _,asset in ipairs({"dashanxiao","xiaoshanxiao","charM","charF","villywan","dahuli"}) do
   D.Cache:loadAsync("spine:"..asset)
   local animations=D.Spine:getAnimations(asset); local available={}; for _,name in ipairs(animations) do available[name]=true end
   rows[asset]={animations=animations,tracks={}}
   local model=assert(D.Spine(asset)); model.position=D.Vec2(ui.width/2,ui.height/2); model.scaleX=0.65; model.scaleY=0.65; model.recovery=0.2; model:addTo(ui)
   for _,name in ipairs(requests[asset]) do
    if available[name] then
     local row={name=name,events={}}; rows[asset].tracks[#rows[asset].tracks+1]=row
     local started=D.App.runningTime; local ended=false
     model:slot("attack"):set(function() row.events[#row.events+1]=D.App.runningTime-started end)
     model:slot("AnimationEnd"):set(function(n) if n==name then ended=true; row.elapsed=D.App.runningTime-started end end)
     row.duration=model:play(name,false); local deadline=started+row.duration+2
     while not ended do assert(D.App.runningTime<deadline,"Missing AnimationEnd "..asset.."/"..name); D.sleep(0.01) end
    end
   end
   model:removeFromParent()
  end
  return "PASS actualFullEnds=true data="..D.json.encode(rows,false,true)
 end,debug.traceback)
 local report="LSD_PURSUIT_ANIMATIONS_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
