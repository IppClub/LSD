-- Measure authored combat timelines; no save database.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine")}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,"Test","enemy-animation-catalog-result.txt")
D.Content:save(out,"LSD_ENEMY_CATALOG_RUNNING\n")
D.thread(function()
 local ok,result=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  D.Cache:loadAsync("spine:xiaotaotie")
  local model=assert(D.Spine("xiaotaotie")); model.position=D.Vec2(D.App.visualSize.width/2,250); model:addTo(D.Director.entry)
  model.recovery=0.2
  local entries={}
  for _,name in ipairs({"blow","swing","butt","bomb","rollStart","rollEnd"}) do
   local e={name=name,events={}}; entries[#entries+1]=e
   local started=D.App.runningTime; local ended=false
   model:slot("attack"):set(function() e.events[#e.events+1]=D.App.runningTime-started end)
   model:slot("AnimationEnd"):set(function(animation) if animation==name then ended=true; e.completed=D.App.runningTime-started end end)
   e.duration=model:play(name,false); assert(e.duration>0,"Missing "..name)
   local deadline=started+e.duration+2
   while not ended do assert(D.App.runningTime<deadline,"No completion "..name); D.sleep(0.01) end
   model:play("idle",true); D.sleep(0.25)
  end
  return "PASS "..D.json.encode(entries,false,true)
 end,debug.traceback)
 local report="LSD_ENEMY_CATALOG_"..(ok and result or "FAIL "..result)
 print(report); D.Content:save(out,report.."\n")
end)
