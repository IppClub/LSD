-- Earned two-fight copy; original Start/doors, explicit mail forwarding and physical story-fragment unlock.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Spine"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","male-current-aftertrial-result.txt"); D.Content:save(out,"LSD_MALE_CURRENT_AFTERTRIAL_RUNNING runId="..id.."\n")
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,"Test","male-current-liyena-resume-fixture.txt")))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match("^lsd%-male%-current%-liyena%-route%-qa%-%d+%.db$"))
  local db=D.Path(D.Content.writablePath,"lsd-male-current-aftertrial-qa-"..id..".db")
  assert(not D.DB:existDB("lsd") and not D.Content:exist(db) and D.Content:copyAsync(source,db)); assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
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
  door("right","PassageB"); door("right","TrainingRoom")
  wait(function() return world().afterTrial and world().afterTrial.actor end)
  local c=world().afterTrial; assert(c.stage==5 and c.tray.visible)
  assert(not D.Group({"name","unit"}):find(function(e) return e.unit.world==world() and (e.name=="sunborn" or e.name=="liyena") end),"Leaders did not depart")
  move(2050); wait(function() return c.view.menu.enabled end)
  c.view:emit("Tapped",1); D.sleep(0.3); assert(not world().storyFlow and not story:summary().completed["ayan-refreshment"],"Food bypassed mail forwarding")
  c.view:emit("Tapped",2); wait(function() return world().companionPanel and world().companionPanel.phase=="information" end)
  local info=world().companionPanel; info.view.researchButton:emit("Tapped"); assert(info.phase=="information" and info.view.detail.text:find("尚未记录",1,true)); info.view.closeButton:emit("Tapped")
  local j=assert(require("Story.Journal").openAsync(world(),5)); assert(j.recordIds[3]=="mail-three" and j.recordIds[4]=="mail-three-forward")
  j.view.stationButton:emit("Tapped"); assert(j.phase=="journal" and not world().storyFlow,"Forwarded unread mail")
  local function dialogue(node,count,expected)
   wait(function() return world().storyFlow and world().storyFlow.id==node and world().storyFlow.view.visible end,15,node)
   local f=world().storyFlow; local deadline=D.App.runningTime+35
   while f.phase=="dialogue" or f.phase=="saving" do assert(D.App.runningTime<deadline,"Yarn stalled "..node); if not f.view._advancing then f.view.confirm:emit("Tapped") end; D.sleep(0.08) end
   assert(f.phase==(expected or "complete") and #f.view._reviews==count,"Incomplete dialogue "..node.." "..f.phase.." "..#f.view._reviews)
   return f
  end
  j.view.archiveButton:emit("Tapped"); local mail=dialogue("mail-three",4)
  assert(mail.view._reviews[1].text:find("眼动编辑邮件",1,true) and mail.view._reviews[3].text:find("清醒和思考",1,true),"Original mail facts missing")
  wait(function() return world().storyJournal.phase=="journal" end)
  world().storyJournal.view.stationButton:emit("Tapped"); local f=dialogue("mail-three-forward",3)
  wait(function() return f.phase=="complete" and world().storyJournal.phase=="journal" end)
  world().storyJournal.view.closeButton:emit("Tapped"); wait(function() return c.view.menu.enabled end)
  c.view:emit("Tapped",1); dialogue("ayan-refreshment",7); wait(function() return c.stage==6 end)
  assert(not c.tray.visible and story:summary().unlocks["academy-refreshment-received"])
  local mid=D.Path(D.Content.writablePath,"lsd-male-current-aftertrial-food-qa-"..id..".db"); assert(D.Content:copyAsync(db,mid)); D.Content:save(D.Path(root,"Test","male-current-aftertrial-mid-fixture.txt"),mid)
  move(935); local remote,why=require("Story.Flow").openAsync("ayan-fragment",world()); assert(not remote and why=="DISCOVERY_LOCATION_REQUIRED")
  j=assert(require("Story.Journal").openAsync(world(),6)); assert(j.recordIds[2]=="ayan-fragment"); j.view.researchButton:emit("Tapped"); assert(j.phase=="journal" and not story:summary().completed["ayan-fragment"]); j.view.closeButton:emit("Tapped")
  move(2050); wait(function() return c.view.menu.enabled end)
  c.view:emit("Tapped",1); f=dialogue("ayan-fragment",7)
  for _,r in ipairs(f.view._reviews) do assert(not r.text:find("删除",1,true) and not r.text:find("模拟的游戏角色",1,true),"Hidden author truth disclosed") end
  wait(function() return f.phase=="complete" and c.stage==7 end)
  c.view:emit("Tapped",1); dialogue("ayan-sharing",8); wait(function() return c.stage==8 end)
  c.view:emit("Tapped",2); wait(function() return world().companionPanel.phase=="information" end)
  info=world().companionPanel; info.view.researchButton:emit("Tapped"); dialogue("ayan-fragment",7); wait(function() return world().companionPanel.phase=="information" and world().companionPanel~=info end)
  world().companionPanel.view.closeButton:emit("Tapped")
  for _,reward in ipairs({"mail-three-read","ninilite-third-mail-received","academy-refreshment-received","ayan-memory-fragment","medical-pair-invited"}) do assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id=?",{reward})==1,"Duplicated reward "..reward) end
  assert(models()==unchanged and story:summary().mission.rewards["energy-site-secured"]==1)
  -- Follow the actual academy route mentioned by Ayan; no phone teleport.
  door("left","PassageB"); door("left","PreparationRoom"); door("left","PassageA"); door("left","RestRoom")
  assert(story:summary().completed["ayan-sharing"] and story:summary().unlocks["medical-pair-invited"])
  D.Content:save(D.Path(root,"Test","male-current-aftertrial-resume-fixture.txt"),db)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-aftertrial.tga'));D.sleep(.2)
  return "PASS actualStart=true earnedTwoFightCopy=true physicalAcademyDoors=true leadersDeparted=true foodAfterForward=true explicitMailReadAndForward=true saveFaultInjected=false physicalFoodHandover=true initialFragmentRequiresActor=true storyFragmentClick=true publicCharacterStoryReplay=true hiddenTruthNotDisclosed=true unlocksOnce=true modelRowsUnchanged=true earnedSingleEnergyPreserved=true physicalRestRoomArrival=true"
 end,debug.traceback)
 local report="LSD_MALE_CURRENT_AFTERTRIAL_"..(ok and result or "FAIL "..tostring(result)).." runId="..id; print(report); D.Content:save(out,report.."\n")
end)
