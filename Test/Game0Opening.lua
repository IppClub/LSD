-- Full fresh profile: authored film, native name input, gender choice, tutorial and academy.
-- Engine event replay supplements native input QA; no HP, completion or model fixture.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","game0-opening-result.txt")
local db=D.Path(D.Content.writablePath,"lsd-game0-journey-qa-"..id..".db")
assert(not D.Content:exist(db) and not D.DB:existDB("lsd"))
assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
-- No seeded Config fields: Start creates defaults and the original Yarn sets identity.
local function report(s) D.Content:save(out,"LSD_GAME0_OPENING_"..s.." runId="..id.."\n"); print("LSD_GAME0_OPENING_"..s) end
report("RUNNING phase=start")
require("Start")
D.thread(function()
 local ok,result=xpcall(function()
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,seconds,message)
   local deadline=D.App.runningTime+seconds
   while not test() do assert(D.App.runningTime<deadline,message); D.sleep(0.05) end
  end
  local function move(left,right)
   local hud
   D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
   assert(hud,'Tutorial HUD missing')
   hud.move:emit('Left',left);hud.move:emit('Right',right)
  end
  local nameSeen=false
  local function advance()
   local story
   if D.Director.ui3D.children then D.Director.ui3D.children:each(function(n) if n._runner and n.visible then story=n end end) end
   local input
   if D.Director.ui3D.children then D.Director.ui3D.children:each(function(n) if n.box and n.label and n.visible then input=n end end) end
   if input then
    if not nameSeen then nameSeen=true; report("RUNNING phase=native-name-input") end
    return true
   end
   if story and not story._advancing then
    if story._options and story.answerList.children and story.answerList.children.count>0 then
     local index=1
     for i,option in ipairs(story._options) do if option.text:find("女",1,true) then index=i end end
     local answer=story.answerList.children:get(index)
     if answer and answer.touchEnabled then answer:emit("Tapped") end
    elseif not story._options then story.confirm:emit("Tapped") end
   end
   return story~=nil
  end
  local openingDeadline=D.App.runningTime+300
  while not player() do
   assert(D.App.runningTime<openingDeadline,"Full opening did not reach tutorial; check native name input")
   advance(); D.sleep(0.15)
  end
  local config=require("Data.Config")
  assert(nameSeen and config.charName=="JourneyQA" and config.char=="charF","Native name/gender not preserved")
  assert(config.skipOP==1,"Opening did not finish and persist skipOP")
  assert(not world().data.navigationAttached,"Fresh opening incorrectly skipped tutorial")
  report("RUNNING phase=first-meeting")
  local deadline=D.App.runningTime+90; local enemy
  while not enemy do
   assert(D.App.runningTime<deadline,"First meeting did not reach battle")
   advance(); enemy=D.Group({"monster","unit"}):find(function(e) return e.unit.world==world() end); D.sleep(0.25)
  end
  report("RUNNING phase=tutorial-combat")
  -- Walk left to trigger the authored evade/weapon introduction.
  local e=player(); move(true,false); D.sleep(0.25); move(false,false)
  local fired=0; local nextShot=0; deadline=D.App.runningTime+180
  while enemy.hp>0 do
   assert(D.App.runningTime<deadline,"Tutorial combat timed out: HP="..enemy.hp.." AP="..enemy.ap)
   local talking=advance(); e=assert(player())
   if not talking then
    local distance=enemy.unit.x-e.unit.x
    move(distance<220,distance>380)
    if D.App.runningTime>=nextShot then
     D.emit("Skill.Began"); D.sleep(0.05); D.emit("Skill.Ended"); fired=fired+1; nextShot=D.App.runningTime+1.1
    end
   else move(false,false) end
   D.sleep(0.1)
  end
  move(false,false)
  assert(enemy.firstHit and fired>0,"Tutorial was not completed through real hits")
  report("RUNNING phase=tutorial-exit shots="..fired)
  deadline=D.App.runningTime+100
  while not (e.interaction and e.exitAvailable and e.enterExit and e.interaction.menu.enabled) do
   assert(D.App.runningTime<deadline,"Physical tutorial exit unavailable x="..e.unit.x)
   advance(); e=assert(player()); move(e.unit.x>6270,e.unit.x<6210)
   D.sleep(0.05)
  end
  move(false,false); e.interaction:emit("Tapped",1)
  wait(function() return world().tag=="PreparationRoom" and player() and not player().busy and world().data.navigationAttached end,25,"Academy arrival did not complete")
  local c=require("Data.Config")
  assert(c.tutorialCompleted==true or c.tutorialCompleted==1,"Completion was not saved by tutorial exit")
  D.sleep(0.3)
  local completion=D.DB:query("SELECT coalesce(value_bool,value_num) FROM lsd.Config WHERE name='tutorialCompleted'")
  assert(completion[1][1]==1,"Completion not persisted")
  D.Content:save(D.Path(root,"Test","journey-resume-fixture.txt"),db)
  return "PASS unseededProfile=true authoredFilmCompleted=true nativeNameInput=true selectedFemale=true firstMeet=true realTutorialCombat=true shots="..fired.." physicalExit=true academyArrival=true completionSaved=true openingFilmSkipped=false"
 end,debug.traceback)
 report(ok and result or "FAIL "..tostring(result))
end)
