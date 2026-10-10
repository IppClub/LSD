-- One isolated profile: actual Start, tutorial combat and physical academy arrival.
-- Engine event replay supplements native input QA; no HP, completion or model fixture.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","game0-journey-result.txt")
local db=D.Path(D.Content.writablePath,"lsd-game0-journey-qa-"..id..".db")
assert(not D.Content:exist(db) and not D.DB:existDB("lsd"))
assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
require("Data.Config")
-- Explicitly exercise numeric zero. Opening film/name entry is a separate QA gate.
assert(D.DB:exec("INSERT INTO lsd.Config(name,value_num,value_str) VALUES ('skipOP',1,NULL),('tutorialCompleted',0,NULL),('char',NULL,'charF'),('charName',NULL,'JourneyQA')")>=0)
local function report(s) D.Content:save(out,"LSD_GAME0_JOURNEY_"..s.." runId="..id.."\n"); print("LSD_GAME0_JOURNEY_"..s) end
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
  local function advance()
   local story
   if D.Director.ui3D.children then D.Director.ui3D.children:each(function(n) if n._runner and n.visible then story=n end end) end
   if story and not story._advancing then
    if story._options and story.answerList.children and story.answerList.children.count>0 then story.answerList.children.first:emit("Tapped")
    elseif not story._options then story.confirm:emit("Tapped") end
   end
   return story~=nil
  end
  wait(function() return player() end,20,"Start did not create tutorial player")
  assert(not world().data.navigationAttached,"Numeric zero incorrectly skipped tutorial")
  local deadline=D.App.runningTime+90; local enemy
  while not enemy do
   assert(D.App.runningTime<deadline,"First meeting did not reach battle")
   advance(); enemy=D.Group({"monster","unit"}):find(function(e) return e.unit.world==world() end); D.sleep(0.25)
  end
  report("RUNNING phase=tutorial-combat")
  -- Walk left to trigger the authored evade/weapon introduction.
  local e=player(); e.keyLeft=true; D.sleep(0.25); e.keyLeft=false
  local fired=0; local nextShot=0; deadline=D.App.runningTime+180
  while enemy.hp>0 do
   assert(D.App.runningTime<deadline,"Tutorial combat timed out: HP="..enemy.hp.." AP="..enemy.ap)
   local talking=advance(); e=assert(player())
   if not talking then
    local distance=enemy.unit.x-e.unit.x
    e.keyRight=distance>380; e.keyLeft=distance<220
    if D.App.runningTime>=nextShot then
     D.emit("Skill.Began"); D.sleep(0.05); D.emit("Skill.Ended"); fired=fired+1; nextShot=D.App.runningTime+1.1
    end
   else e.keyLeft=false; e.keyRight=false end
   D.sleep(0.1)
  end
  e.keyLeft=false; e.keyRight=false
  assert(enemy.firstHit and fired>0,"Tutorial was not completed through real hits")
  report("RUNNING phase=tutorial-exit shots="..fired)
  deadline=D.App.runningTime+100
  while not (e.interaction and e.exitAvailable and e.enterExit and e.interaction.menu.enabled) do
   assert(D.App.runningTime<deadline,"Physical tutorial exit unavailable x="..e.unit.x)
   advance(); e=assert(player()); e.keyRight=e.unit.x<6210; e.keyLeft=e.unit.x>6270
   D.sleep(0.05)
  end
  e.keyRight=false; e.keyLeft=false; e.interaction:emit("Tapped",1)
  wait(function() return world().tag=="PreparationRoom" and player() and not player().busy and world().data.navigationAttached end,25,"Academy arrival did not complete")
  local c=require("Data.Config")
  assert(c.tutorialCompleted==true or c.tutorialCompleted==1,"Completion was not saved by tutorial exit")
  D.sleep(0.3)
  local completion=D.DB:query("SELECT coalesce(value_bool,value_num) FROM lsd.Config WHERE name='tutorialCompleted'")
  assert(completion[1][1]==1,"Completion not persisted")
  D.Content:save(D.Path(root,"Test","journey-resume-fixture.txt"),db)
  return "PASS numericZeroRoutesTutorial=true firstMeet=true realTutorialCombat=true shots="..fired.." physicalExit=true academyArrival=true completionSaved=true openingFilmSkipped=true"
 end,debug.traceback)
 report(ok and result or "FAIL "..tostring(result))
end)
