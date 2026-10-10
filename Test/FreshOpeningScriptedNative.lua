-- Full fresh profile through original UI events; title/name and controls are scripted, not OS input.
-- Engine event replay supplements native input QA; no HP, completion or model fixture.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-opening-scripted-result.json")
local directory=D.Path(D.Content.writablePath,'lsd-fresh-opening-academy-qa-'..id)
assert(not D.Content:exist(directory)and D.Content:mkdir(directory)and not D.DB:existDB('lsd'))
local store=require('Save.Slots').new(directory);local db
-- No seeded Config fields: Start creates defaults and the original Yarn sets identity.
local result={status='RUNNING',osInput=false,openingTitleAndNameOS=false,scriptedTitleAndName=true,stages={}}
local function report(s)
 result.stage=s;result.status=s:match('^PASS')and'PASS'or s:match('^FAIL')and'FAIL'or'RUNNING'
 if result.status=='FAIL'then result.error=s end
 result.database=db;result.stages[#result.stages+1]={stage=s,time=D.App.runningTime}
 D.Content:save(out,D.json.encode(result,false,true));print('LSD_FRESH_OPENING_SCRIPTED_'..result.status)
end
report("RUNNING phase=start")
local title=require('Save.Title').open({store=store})
D.thread(function()
 local ok,result=xpcall(function()
  title.new:emit('Tapped')
  local startDeadline=D.App.runningTime+120
  while not title.selected do assert(D.App.runningTime<startDeadline,'Actual new journey click required');D.sleep(.05)end
  db=D.Path(directory,title.selected)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(test,seconds,message)
   local deadline=D.App.runningTime+(seconds or 30)
   while not test() do assert(D.App.runningTime<deadline,message or "Fresh journey timed out"); D.sleep(0.05) end
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
    if not input._qaInputSent then input._qaInputSent=true;input.box:emit('TextInput','旅程QA');input.box:emit('KeyPressed','Return')end
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
  assert(nameSeen and config.charName=="旅程QA" and config.char=="charF","Native name/gender not preserved")
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
  local function academyMove(x)
   local e=assert(player());local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local side=e.unit.x<x and'Right'or'Left';hud.move:emit(side,true)
   wait(function()return math.abs(e.unit.x-x)<30 end,45,'Academy walk stalled');hud.move:emit(side,false);D.sleep(.4)
  end
  local function door(side,target)
   local old=world();academyMove(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=assert(player());local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled,'Missing door '..target);p.interaction:emit('Tapped',index)
   wait(function()return world()~=old and world().tag==target and player()end,30,'Door transition stalled');D.sleep(.3)
  end
  door("right","PassageB"); door("right","TrainingRoom"); academyMove(900)
  world():getChildByTag("trainingTerminal"):emit("Tapped",1)
  wait(function() return world().tag=="VRTraining" and D.Director.ui3D:getChildByTag("training-controls") end,12)
  report("RUNNING phase=demonstrate")
  local hud=assert(D.Director.ui3D:getChildByTag("trainingHUD")); local ui=D.Director.ui3D:getChildByTag("training-controls")
  local menu=ui:getChildByTag("training-menu"); local status=ui:getChildByTag("training-status")
  D.sleep(0.8)
  local idle=assert(hud.skillArea:getChildByTag("training-wait")); idle:emit("TapBegan"); idle:emit("TapEnded"); D.sleep(0.15)
  -- Natural stationary shooting demonstration plus explicit waiting, using public HUD.
  for i=1,5 do hud.weapon:emit("TapBegan"); D.sleep(0.05); hud.weapon:emit("TapEnded"); D.sleep(1.5) end
  assert(status.text:find("射击 5",1,true) and status.text:find("等待 1",1,true),"HUD demonstrations missing: "..status.text)
  menu:getChildByTag("结束示范"):emit("Tapped")
  wait(function() return status.text:find("候选模型",1,true) end,12,"Public demonstration did not build model")
  report("RUNNING phase=evaluate")
  menu:getChildByTag("三场试战"):emit("Tapped")
  wait(function() return status.text:find("三场",1,true) and status.text:find("查看结果",1,true) end,120,"Public trial matrix did not finish: "..status.text)
  assert(status.text:find("候选三场胜利 3/3",1,true),"Natural demonstrations did not win all trials: "..status.text)
  menu:getChildByTag("采用"):emit("Tapped")
  wait(function() return require("Training.Progress").adopted~=nil and status.text:find("训练成果已保存",1,true) end,10,"Public adoption did not persist")
  local model=assert(require("Training.Progress").adopted)
  assert(model.sampleCount>=6,"Model lacks natural public demonstrations")
  local saved=D.json.decode(D.DB:query("SELECT payload FROM lsd.Game0Training WHERE slot='main'")[1][1],32)
  assert(saved.adopted.sampleCount==model.sampleCount,"Persisted model mismatch")
  menu:getChildByTag("返回训练室"):emit("Tapped")
  wait(function() return world().tag=="TrainingRoom" and player() end,12); D.sleep(0.5)
  door("left","PassageB"); door("left","PreparationRoom"); door("left","PassageA"); door("center","PassageC"); door("right","OperationRoom")
  academyMove(world().sceneWidth/2); local room=world(); room:getChildByTag("missionTerminal"):emit("Tapped",1)
  wait(function() return room.missionBriefing end)
  local briefing=room.missionBriefing; briefing.view.startButton:emit("Tapped")
  wait(function()return briefing.supplyPanel end,20,'Formal budget did not open')
  local panel=briefing.supplyPanel;result.budget=panel.quote;panel.saveButton:emit('Tapped')
  wait(function()return briefing.level end,30,'Mission did not load')
  local level=briefing.level;local battle=level.battle;D.sleep(.8)
  if level.start then level.start:emit('Tapped')end
  local deadline=D.App.runningTime+100
  while level.phase~='result'do
   assert(D.App.runningTime<deadline,'First mission stalled')
   local h=assert(D.Director.ui3D:getChildByTag('mission-hud'))
   D.emit('Skill.Began');D.emit('Skill.Ended');D.sleep(.9)
  end
  result.battle=battle.report;assert(battle.phase=='won',battle.reason)
  assert(briefing.service:summary().unlocks['library-lead'])
  local E=require('Economy.Store');assert(E.open()and not E.active());result.balance=E.wallet().available
  level.result.baseButton:emit('Tapped');wait(function()return world().tag=='OperationRoom'and player()end,30,'Return to academy failed')
  result.identity={name=config.charName,character=config.char};result.model=require('Training.Summary').record(model)
  return 'PASS unseeded=true tutorialAndAcademy=true publicTrainingAndAdoption=true formalMission=true scriptedMovement=true'

 end,debug.traceback)
 report(ok and result or "FAIL "..tostring(result))
end)
