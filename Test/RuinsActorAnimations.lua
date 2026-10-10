-- Probe actual authored flower-monster timelines before binding their attacks.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","ruins-actor-animations-result.txt")
local runId=tostring(os.time()); D.Content:save(out,"LSD_RUINS_ACTOR_ANIMATIONS_RUNNING runId="..runId.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  local records={}
  for _,asset in ipairs({"vika","vivi","ayan","ninilite"}) do
   D.Cache:loadAsync("spine:"..asset)
   local spine=assert(D.Spine(asset)); spine.position=D.Vec2(600,400); spine:addTo(D.Director.entry); spine.recovery=0.2
   local record={asset=asset,animations=D.Spine:getAnimations(asset),measured={}}; records[#records+1]=record
   local wanted=asset=="ayan" and {"lose"} or asset=="ninilite" and {"throw","comm"} or {"melee","lose"}
   local exists={}; for _,a in ipairs(record.animations) do exists[a]=true end
   for _,name in ipairs(wanted) do if exists[name] and name~="idle" and name~="idle1" and name~="move" and name~="fmove" and name~="bmove" then
    local r={name=name,events={}}; record.measured[#record.measured+1]=r
    local started=D.App.runningTime; local ended=false
    spine:slot("attack"):set(function() r.events[#r.events+1]=D.App.runningTime-started end)
    spine:slot("AnimationEnd"):set(function(a) if a==name then ended=true; r.completed=D.App.runningTime-started end end)
    r.duration=spine:play(name,false); assert(r.duration>0)
    while not ended do assert(D.App.runningTime-started<r.duration+2,"Missing end "..name); D.sleep(0.01) end
    spine:play("idle",true); D.sleep(0.25)
   end end
   spine:removeFromParent()
  end
  return "PASS "..D.json.encode(records,false,true)
 end,debug.traceback)
 local report="LSD_RUINS_ACTOR_ANIMATIONS_"..(ok and result or "FAIL "..result).." runId="..runId; print(report); D.Content:save(out,report.."\n")
end)
