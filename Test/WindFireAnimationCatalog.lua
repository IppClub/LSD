-- Probe actual authored boss and rescuer timelines before binding their attacks.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","wind-fire-animation-catalog-result.txt")
D.Content:save(out,"LSD_WIND_FIRE_ANIMATIONS_RUNNING\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  local records={}
  for _,asset in ipairs({"ninilite","wuyun"}) do
   D.Cache:loadAsync("spine:"..asset)
   local spine=assert(D.Spine(asset)); spine.position=D.Vec2(600,400); spine:addTo(D.Director.entry); spine.recovery=0.2
   local record={asset=asset,animations=D.Spine:getAnimations(asset),measured={}}; records[#records+1]=record
   local wanted=asset=="ninilite" and {"throw","comp","comm","gun1","gun2","gun3","bow"} or {"melee","throw","comp","comm"}
   local exists={}; for _,a in ipairs(record.animations) do exists[a]=true end
   for _,name in ipairs(wanted) do if exists[name] then
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
 local report="LSD_WIND_FIRE_ANIMATIONS_"..(ok and result or "FAIL "..result); print(report); D.Content:save(out,report.."\n")
end)
