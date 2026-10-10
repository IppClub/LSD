-- Real physics and real HUD/door events, isolated QA DB; not native long-touch proof.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local output=D.Path(root,"Test","academy-training-route-result.txt")
local runId=tostring(os.time())
D.Content:save(output,"LSD_ACADEMY_ROUTE_RUNNING runId="..runId.."\n")
local database=D.Path(D.Content.writablePath,"lsd-academy-route-qa-"..runId..".db")
assert(not D.Content:exist(database) and not D.DB:existDB("lsd"))
assert(D.DB:exec("ATTACH DATABASE '"..database:gsub("'","''").."' AS lsd")>=0)
D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
D.thread(function()
 local ok,result=xpcall(function()
  local config=require("Data.Config"); config:loadAsync(); config.char="charM"; config.charName="RouteQA"; config.tutorialCompleted=1
  require("Academy.Level.Arrive")()
  local function world() return D.Platformer.Data.store.world end
  local function waitFor(test,seconds)
   local deadline=D.App.runningTime+(seconds or 5)
   while not test() and D.App.runningTime<deadline do D.sleep(0.05) end
   assert(test(),"Timed out waiting for route state")
  end
  local function player()
   return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end)
  end
  waitFor(function() local e=player(); return e and not e.busy and world().data.navigationAttached end,15)
  local tags={"PreparationRoom"}
  local function moveTo(x)
   local e=assert(player()); local before=e.unit.x
   local started=D.App.runningTime
   while math.abs(e.unit.x-x)>45 and D.App.runningTime-started<16 do
    e.keyRight=e.unit.x<x; e.keyLeft=e.unit.x>x; D.sleep(0.05)
   end
   e.keyLeft=false; e.keyRight=false; D.sleep(0.3)
   assert(math.abs(e.unit.x-x)<100,"Physical movement failed")
   return before,e.unit.x
  end
  local function door(route,target)
   local w=world(); moveTo(route=="right" and w.sceneWidth-120 or 120)
   local e=assert(player()); assert(e.moveTargets and e.moveTargets:get(1)==target,"Wrong door route")
   assert(e.interaction and e.interaction.menu.enabled,"Door interaction unavailable")
   e.interaction:emit("Tapped",1)
   waitFor(function() return world()~=w and world().tag==target end)
   D.sleep(0.3); tags[#tags+1]=target
  end
  door("right","PassageB"); door("right","TrainingRoom")
  local room=world(); assert(not room:getChildByTag("trainingTerminal").menu.enabled,"Terminal available before approach")
  moveTo(900)
  local terminal=assert(room:getChildByTag("trainingTerminal")); assert(terminal.menu.enabled,"Physical terminal unavailable")
  terminal:emit("Tapped",1)
  waitFor(function() return world().tag=="VRTraining" end)
  tags[#tags+1]="VRTraining"; D.sleep(1)
  local hud=assert(D.Director.ui3D:getChildByTag("trainingHUD"))
  hud.move:emit("Left",true); D.sleep(0.2); hud.move:emit("Left",false); D.sleep(0.3)
  hud.move:emit("Right",true); D.sleep(0.2); hud.move:emit("Right",false); D.sleep(0.3)
  hud.weapon:emit("TapBegan"); hud.weapon:emit("TapEnded"); D.sleep(1.2)
  local wait=assert(hud.skillArea:getChildByTag("training-wait")); wait:emit("TapBegan"); wait:emit("TapEnded"); D.sleep(0.2)
  local ui=assert(D.Director.ui3D:getChildByTag("training-controls"))
  local text=ui:getChildByTag("training-status").text
  assert(text:find("射击 1 / 接近 1 / 后退 1 / 等待 1",1,true),"Unified HUD did not record each action")
  assert(text:find("对手 80",1,true),"Skill projectile did not hit")
  local menu=ui:getChildByTag("training-menu"); assert(menu:getChildByTag("返回训练室")):emit("Tapped")
  waitFor(function() return world().tag=="TrainingRoom" end)
  tags[#tags+1]="TrainingRoom"; D.sleep(1)
  door("left","PassageB"); door("left","PreparationRoom")
  assert(D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end),"No player after return")
  return "PASS path="..table.concat(tags,">").." hudActions=4 skillHit=true"
 end,debug.traceback)
 local report="LSD_ACADEMY_ROUTE_"..(ok and result or "FAIL "..tostring(result)).." runId="..runId
 print(report); D.Content:save(output,report.."\n")
end)
