-- Continue only the unseeded opening/training/mission journey earned by the public UI.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-investigation-result.json';local r={status='RUNNING',osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(root..'/Test/fresh-opening-academy-result.json'),32)
  assert(previous.status=='PASS'and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/lsd%-fresh%-opening%-academy%-qa%-%d+/lsd%-journey%-%d+%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-investigation-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  r.database=db;r.source=previous.database;save();require('Start')
  local function wait(test,seconds)
   local deadline=D.App.runningTime+(seconds or 7)
   while not test() do assert(D.App.runningTime<deadline,"Story UI timeout"); D.sleep(0.05) end
  end
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world() end) end
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
   wait(function() return world()~=old and world().tag==target and player() end); D.sleep(0.3);r.stage=target;save()
  end
  local function complete(flow)
   wait(function() return flow.view.visible end)
   local deadline=D.App.runningTime+15
   while flow.phase=="dialogue" do
    assert(D.App.runningTime<deadline,"Yarn did not finish")
    if not flow.view._advancing then flow.view.confirm:emit("Tapped") end
    D.sleep(0.1)
   end
   wait(function() return flow.phase=="complete" or flow.phase=="save-error" end)
   D.sleep(0.1);r.stage=flow.id;r.dialogues=r.dialogues or {};r.dialogues[#r.dialogues+1]=flow.id;save()
  end
  wait(function() return world() and world().tag=="PreparationRoom" and player() and not player().busy end,20)
  assert(require("Data.Config").charName=="旅程QA","Same profile identity lost")
  local mission=assert(require("Mission.Service").open())
  assert(mission:summary().unlocks["library-lead"],"Actual prior battle reward absent")
  assert(require("Training.Progress").load() and require("Training.Progress").adopted,"Publicly learned model not restored")
  door("left","PassageA"); door("center","PassageC"); door("center","PassageD"); door("right","RDRoom")
  move(world().sceneWidth/2); world():getChildByTag("storyTerminal"):emit("Tapped",1)
  wait(function() return world().storyFlow end); complete(world().storyFlow)
  assert(world().storyFlow.phase=="complete" and not player().busy,"Research completion froze input")
  local journal=assert(require("Story.Journal").openAsync(world()))
  assert(journal.view.detail.text:find("资料室",1,true))
  journal.view.mailButton:emit("Tapped"); wait(function() return world().storyFlow.id=="mail-one" end)
  complete(world().storyFlow); wait(function() return D.Director.ui3D:getChildByTag("story-journal") end)
  local j=D.Director.ui3D:getChildByTag("story-journal").controller; j.view.closeButton:emit("Tapped")
  door("left","PassageD"); door("left","LibraryRoom"); move(2690)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_archive_ui BEFORE INSERT ON Game0StoryUnlocks BEGIN SELECT RAISE(ABORT,'QA archive save fault'); END")>=0)
  world():getChildByTag("storyTerminal"):emit("Tapped",1); wait(function() return world().storyFlow end)
  local archive=world().storyFlow; complete(archive)
  assert(archive.phase=="save-error" and archive.retryButton and player().busy,"Story save failure not recoverable")
  assert(not archive.service:summary().completed["archive-discovery"])
  D.DB:exec("DROP TRIGGER lsd.fail_archive_ui"); archive.retryButton:emit("Tapped"); wait(function() return archive.phase=="complete" end)
  assert(not player().busy and archive.service:summary().unlocks["archive-discovered"])
  local nodes=#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")
  local final=assert(require("Story.Journal").openAsync(world())); final.view.archiveButton:emit("Tapped")
  wait(function() return world().storyFlow~=archive end); complete(world().storyFlow)
  wait(function() return D.Director.ui3D:getChildByTag("story-journal") end)
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryNodes")==nodes,"Replay duplicated story record")
  local saved=D.Director.ui3D:getChildByTag("story-journal").controller
  assert(saved.view.detail.text:find("三月十五日",1,true) and saved.view.detail.text:find("地面站台",1,true))
  saved.view.closeButton:emit("Tapped")
  door("right","PassageD"); door("center","PassageC"); door("left","Station")
  move(world().sceneWidth-650)
  assert(D.Group({"name","unit"}):find(function(e) return e.storyCompanion and e.unit.world==world() end),"Station companion absent")
  world():getChildByTag("storyTerminal"):emit("Tapped",1)
  wait(function() return world().storyFlow and world().storyFlow.id=="station-brief" end)
  complete(world().storyFlow)
  assert(world().storyFlow.phase=="complete" and not player().busy,"Station completion froze input")
  assert(world().storyFlow.service:summary().unlocks["station-briefed"],"Station preparation not persisted")
  door("right","PassageC")
  local E=require('Economy.Store');assert(E.open()and not E.active()and E.wallet().available==previous.balance)
  r.balance=E.wallet().available;r.sameJourney=true;r.stage='station-brief-complete'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_INVESTIGATION_'..r.status)
end)
