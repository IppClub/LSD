-- Earned two-fight copy; original Start/doors, explicit mail forwarding and physical story-fragment unlock.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","fresh-medical-current-result.json"); local evidence={status='RUNNING',osInput=false};local function save()D.Content:save(out,D.json.encode(evidence,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-aftertrial-current-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-aftertrial%-current%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'fresh-medical-current-'..id..'.db')
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(prior.database,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);evidence.database=db;evidence.source=prior.database;save()
  D.Director.entry:slot("Cleanup",function() if D.DB:existDB("lsd") then D.DB:exec("DETACH DATABASE lsd") end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t,label) local deadline=D.App.runningTime+(t or 20); while not f() do assert(D.App.runningTime<deadline,"After trial timeout "..(label or "")); D.sleep(0.02) end end
  require("Start"); wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end)
  local function models() return D.json.encode({D.DB:query("SELECT slot,payload FROM lsd.Game0Training ORDER BY slot"),D.DB:query("SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot")},false,true) end
  local unchanged=models(); local story=assert(require("Story.Service").open()); assert(story:summary().completed["liyena-recognition"])
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
  local function door(side,target)
   local old=world(); move(side=="right" and old.sceneWidth-110 or 110); assert(player().interaction and player().moveTargets:get(1)==target)
   player().interaction:emit("Tapped",1); wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.4)
  end
  assert(story:summary().completed["ayan-sharing"])
  assert(not world().medicalVisit,"Preparation started before material request")
  local can,why=story:canRead("translator-preparation","PreparationRoom"); assert(not can and why=="STORY_LOCKED")
  local j=assert(require("Story.Journal").openAsync(world(),6)); assert(j.recordIds[4]=="medical-meeting")
  j.view.stationButton:emit("Tapped"); assert(j.phase=="journal" and not story:summary().completed["medical-meeting"]); j.view.closeButton:emit("Tapped")
  door("left","PassageA"); door("left","RestRoom")
  wait(function() return world().medicalVisit and world().medicalVisit.phase=="ready" end)
  local c=world().medicalVisit; assert(#c.actors==2 and c.actors[1].name=="moyu" and c.actors[2].name=="moling")
  local remote,reason=require("Story.Flow").openAsync("medical-meeting",world()); assert(not remote and reason=="DISCOVERY_LOCATION_REQUIRED")
  move(world().sceneWidth/2+850); wait(function() return c.view.menu.enabled end)
  local function dialogue(node,count,expected)
   wait(function() return world().storyFlow and world().storyFlow.id==node and world().storyFlow.view.visible end,20,node)
   local f=world().storyFlow; local deadline=D.App.runningTime+65
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Medical Yarn stalled "..node); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase==(expected or "complete") and #f.view._reviews==count,"Incomplete medical Yarn "..node.." "..f.phase.." rows="..#f.view._reviews)
   return f
  end
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_medical BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='medical-pair-met' BEGIN SELECT RAISE(ABORT,'QA medical fault'); END")>=0)
  c.view:emit("Tapped",1); local f=dialogue("medical-meeting",35,"save-error")
  assert(not story:summary().completed["medical-meeting"] and not story:summary().unlocks["medical-pair-met"] and player().busy)
  local prose=""; for _,row in ipairs(f.view._reviews) do prose=prose..row.text end
  assert(prose:find("主攻西医",1,true) and prose:find("三顾茅庐",1,true) and prose:find(require("Data.Config").charName,1,true),"Medical source facts/name missing")
  D.DB:exec("DROP TRIGGER lsd.fail_medical"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and not player().busy end)
  local mid=D.Path(D.Content.writablePath,"lsd-fresh-medical-met-qa-"..id..".db"); assert(D.Content:copyAsync(db,mid)); evidence.midDatabase=mid;save()
  j=assert(require("Story.Journal").openAsync(world(),7)); assert(j.recordIds[1]=="translator-request" and j.recordIds[2]=="translator-preparation")
  j.view.researchButton:emit("Tapped"); assert(j.phase=="journal" and not story:summary().completed["translator-preparation"])
  j.view.mailButton:emit("Tapped"); f=dialogue("translator-request",3); assert(f.view._reviews[1].text:find("砗磲贝",1,true))
  wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  door("right","PassageA"); door("right","PreparationRoom")
  wait(function() return world().medicalVisit and world().medicalVisit.phase=="ready" end)
  c=world().medicalVisit; assert(c.actors[1].name=="ninilite" and c.actors[2].name=="wuyun")
  local counts={}; D.Group({"name","unit"}):each(function(e) if e.unit.world==world() then counts[e.name]=(counts[e.name] or 0)+1 end end)
  assert(counts.ninilite==1 and counts.wuyun==1,"Duplicated preparation companions")
  remote,reason=require("Story.Flow").openAsync("translator-preparation",world()); assert(not remote and reason=="DISCOVERY_LOCATION_REQUIRED")
  move(world().sceneWidth/2); wait(function() return c.view.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_preparation BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='factory-expedition-briefed' BEGIN SELECT RAISE(ABORT,'QA preparation fault'); END")>=0)
  c.view:emit("Tapped",1); f=dialogue("translator-preparation",15,"save-error")
  assert(not story:summary().completed["translator-preparation"] and player().busy)
  prose=""; for _,row in ipairs(f.view._reviews) do prose=prose..row.text end
  assert(prose:find("沼泽",1,true) and prose:find("废弃工厂",1,true) and prose:find("牵挂",1,true),"Preparation source facts missing")
  D.DB:exec("DROP TRIGGER lsd.fail_preparation"); f.retryButton:emit("Tapped"); wait(function() return f.phase=="complete" and not player().busy end)
  j=assert(require("Story.Journal").openAsync(world(),6)); j.view.stationButton:emit("Tapped"); dialogue("medical-meeting",35); wait(function() return world().storyJournal.phase=="journal" end); world().storyJournal.view.closeButton:emit("Tapped")
  for _,reward in ipairs({"medical-pair-met","translator-material-requested","factory-expedition-briefed"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1,"Duplicate unlock "..reward) end
  assert(models()==unchanged and story:summary().mission.rewards["energy-site-secured"]==1)
  local E=require('Economy.Store');assert(E.open()and not E.active()and E.wallet().available==prior.balance);evidence.balance=E.wallet().available;evidence.sameJourney=true;evidence.stage='factory-expedition-briefed';save()
  return "PASS actualStart=true earnedAyanCopy=true physicalAcademyDoors=true medicalPairOriginalActors=true medicalFull35Lines=true genderNeutralGreeting=true dynamicPlayerName=true medicalRollbackRetry=true initialRemoteRejected=true explicitLinMessage=true preparationBothOriginalActors=true noDuplicateCompanions=true preparationFull15Lines=true preparationRollbackRetry=true recordedMedicalReplayAnywhere=true allUnlocksOnce=true modelRowsUnchanged=true earnedSingleEnergyPreserved=true"
 end,debug.traceback)
 evidence.status=ok and 'PASS'or'FAIL';evidence.detail=ok and result or nil;evidence.error=not ok and tostring(result)or nil
 save();print('LSD_FRESH_MEDICAL_CURRENT_'..evidence.status)
end)
