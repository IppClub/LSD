-- Public second learner training from the earned cooperation profile.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-wuyun-training-result.txt"); D.Content:save(out,"LSD_FRESH_WUYUN_TRAINING_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","fresh-cooperation-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-fresh%-cooperation%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-fresh-wuyun-training-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  require("Data.Config"):loadAsync(); local Progress=require("Training.Progress"); assert(Progress.load())
  local niPayload=D.json.encode(D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),false,true)
  local niModel=Progress.adopted; assert(niModel.sampleCount==6)
  local function wait(f,t)
   local deadline=D.App.runningTime+(t or 15)
   while not f() do assert(D.App.runningTime<deadline,"Wuyun training wait timed out"); D.sleep(0.05) end
  end
  require('Start')
  local function world()return D.Platformer.Data.store.world end
  local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end)end
  local function move(x)
   local e=assert(player());local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local side=e.unit.x<x and 'Right' or 'Left';hud.move:emit(side,true)
   local deadline=D.App.runningTime+45
   while math.abs(e.unit.x-x)>35 do
    if D.App.runningTime>=deadline then hud.move:emit(side,false);error('Factory physical walk stalled x='..e.unit.x..' target='..x)end
    D.sleep(.02)
   end
   hud.move:emit(side,false);D.sleep(.5)
  end
  local function door(route,target)
   local old=world(); move(route=="left" and 120 or route=="right" and old.sceneWidth-120 or old.center.x)
   local e=player(); local index; assert(e.moveTargets,"Missing story route sensor")
   for i=1,e.moveTargets.count do if e.moveTargets:get(i)==target then index=i; break end end
   assert(index and e.interaction.menu.enabled,"Story destination missing: "..target); e.interaction:emit("Tapped",index)
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3)
  end
  wait(function()return world() and world().tag=='PreparationRoom' and player() and not player().busy end,30)
  door('right','PassageB');door('right','TrainingRoom');move(900)
  world():getChildByTag('trainingTerminal'):emit('Tapped',1)
  wait(function() return D.Director.ui3D:getChildByTag("training-controls") end)
  local ui=D.Director.ui3D:getChildByTag("training-controls")
  assert(ui.arena.character.id=="ninilite" and ui.arena.adopted.sampleCount==6)
  ui:getChildByTag("training-switch"):emit("Tapped")
  wait(function() local u=D.Director.ui3D:getChildByTag("training-controls"); return u and u~=ui and u.arena.character.id=="wuyun" end)
  ui=D.Director.ui3D:getChildByTag("training-controls"); local a=ui.arena; assert(not a.adopted and a.recorder.characterId=="wuyun")
  assert(not a:beginTrial(420,niModel),"Ni model deployed as Wuyun")
  local menu=ui:getChildByTag("training-menu"); local hud=D.Director.ui3D:getChildByTag("trainingHUD"); local blade=hud.skillArea:getChildByTag("training-melee")
  local timelines={}; D.sleep(0.8)
  for i=1,6 do
   menu:getChildByTag("近处对练"):emit("Tapped"); D.sleep(0.3)
   local start=D.App.runningTime; blade:emit("TapBegan"); D.sleep(0.12)
   assert(a.enemyHP==100 and not a:request("laser","demo"),"Melee windup damaged or interrupted")
   D.sleep(1.1); blade:emit("TapEnded")
   assert(a.metrics.hits==1 and a.enemyHP==80 and a.student.data.combatCompletedName=="melee" and a.student.playable.current=="prepare","Melee incomplete or did not recover")
   timelines[#timelines+1]={impact=a.meleeEventAt-start,completed=a.student.data.combatCompletedAt-start}
   if i==1 then ui:getChildByTag("training-switch"):emit("Tapped"); D.sleep(0.1); assert(D.Director.ui3D:getChildByTag("training-controls")==ui,"Unsaved samples discarded") end
   menu:getChildByTag("中距对练"):emit("Tapped"); D.sleep(0.3)
   hud.weapon:emit("TapBegan"); D.sleep(0.05); hud.weapon:emit("TapEnded"); D.sleep(1.5); assert(a.metrics.hits==1)
   menu:getChildByTag("远处对练"):emit("Tapped"); D.sleep(0.3)
   hud.move:emit("Right",true); D.sleep(0.12); hud.move:emit("Right",false)
  end
  assert(#a.recorder.samples==18 and a.recorder.counts.melee==6 and a.recorder.counts.laser==6 and a.recorder.counts.fmove==6)
  menu:getChildByTag("结束示范"):emit("Tapped"); wait(function() return a.mode=="review" and a.candidate end)
  local model=a.candidate; local Model=require("Training.Model")
  local function state(d) return {distance=d,facing="yes",enemyAction="idle",attackReady="yes"} end
  assert(Model.predict(model,state(220))=="melee" and Model.predict(model,state(420))=="laser" and Model.predict(model,state(680))=="fmove")
  menu:getChildByTag("三场试战"):emit("Tapped"); wait(function() return a.evaluation and not a.evaluating end,160)
  local e=a.evaluation; assert(e.summary.candidate.wins==3 and e.summary.baseline.wins==3 and e.summary.candidate.fallback==0)
  assert(e.summary.candidate.actions.melee and e.summary.candidate.actions.laser and e.summary.candidate.actions.fmove)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_wuyun_adopt BEFORE INSERT ON Game0Training_wuyun WHEN NEW.slot='main' BEGIN SELECT RAISE(ABORT,'QA Wuyun public save'); END")>=0)
  menu:getChildByTag("采用"):emit("Tapped"); wait(function() return a.mode=="review" end); assert(a.candidate==model and not a.adopted and not Progress.forCharacter("wuyun").adopted)
  D.DB:exec("DROP TRIGGER lsd.fail_wuyun_adopt"); menu:getChildByTag("采用"):emit("Tapped"); wait(function() return a.mode=="review" and a.adopted==model end)
  assert(Progress.forCharacter("wuyun").load() and Progress.forCharacter("wuyun").adopted.characterId=="wuyun")
  ui:getChildByTag("training-switch"):emit("Tapped"); wait(function() local u=D.Director.ui3D:getChildByTag("training-controls"); return u and u~=ui and u.arena.character.id=="ninilite" end)
  ui=D.Director.ui3D:getChildByTag("training-controls"); assert(ui.arena.adopted.sampleCount==6)
  ui:getChildByTag("training-switch"):emit("Tapped"); wait(function() local u=D.Director.ui3D:getChildByTag("training-controls"); return u and u~=ui and u.arena.character.id=="wuyun" end)
  ui=D.Director.ui3D:getChildByTag("training-controls"); assert(ui.arena.adopted.sampleCount==18)
  assert(D.json.encode(D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),false,true)==niPayload,"Ni rows changed during Wuyun training")
  ui:getChildByTag("training-menu"):getChildByTag("返回训练室"):emit("Tapped")
  wait(function() return D.Platformer.Data.store.world.tag=="TrainingRoom" end)
  D.Content:save(D.Path(root,"Test","fresh-wuyun-training-resume-fixture.txt"),db)
  return "PASS earnedCooperationCopy=true physicalTrainingTerminal=true earnedLearnerAccess=true publicSwitch=true unsavedSamplesPreserved=true realMeleeEvent=true fullMeleeRecovery=true publicHudSamples=18 nativeC45=true heldOutActions=melee/shoot/approach equalTrials=3 candidate="..D.json.encode(e.summary.candidate).." baseline="..D.json.encode(e.summary.baseline).." saveRollback=true retry=true independentModels=true NiBytesUntouched=true switchReload=true publicReturn=true meleeTimelines="..D.json.encode(timelines)
 end,debug.traceback)
 local report="LSD_FRESH_WUYUN_TRAINING_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
