local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','fox-trail-route-result.txt');D.Content:save(out,'LSD_FOX_TRAIL_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','valley-days-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-valley%-days%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fox-trail-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t,message) local deadline=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<deadline,message or 'Fox trail stalled');D.sleep(.03) end end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.valleyDays and w.valleyDays.fox and w.valleyEncounter.phase=='ready' end,30)
  local w=D.Platformer.Data.store.world;local p=D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==w end)
  local function move(x)
   local deadline=D.App.runningTime+30;while math.abs(p.unit.x-x)>25 do assert(D.App.runningTime<deadline,'Travel stalled x='..p.unit.x..' target='..x);p.keyLeft=p.unit.x>x;p.keyRight=p.unit.x<x;D.sleep(.03) end
   p.keyLeft=false;p.keyRight=false;p.unit:stop();p.unit.velocityX=0;D.sleep(.15)
  end
  local story=assert(require('Story.Service').open());local store=assert(require('Story.FoxTrailStore').open())
  assert(not story:canRead('valley-departure','Factory'),'Departure bypassed')
  local originalFood=assert(store:foodCount());local supplies=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StorySupplies ORDER BY 1,2,3'),false,true)
  move(w.valleyDays.fox.x);wait(function() return w.valleyDays.departure.menu.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_fox_depart BEFORE UPDATE OF departed ON Game0FoxTrail BEGIN SELECT RAISE(ABORT,'QA departure'); END")>=0)
  w.valleyDays.departure.menu:emit('Tapped',1);wait(function() return w.valleyDays.error end);assert(not store:load().departed and D.Platformer.Data.store.world==w)
  D.DB:exec('DROP TRIGGER lsd.fail_fox_depart');w.valleyDays.departure.menu:emit('Tapped',1)
  wait(function() local n=D.Platformer.Data.store.world;return n~=w and n.foxTrail and n.foxTrail.villy end,30);w=D.Platformer.Data.store.world;local c=w.foxTrail;p=c.player;store=c.store
  assert(w.tag=='Factory' and not c.villy.unit.visible and not w.factoryExpedition)
  assert(not D.Group({'name','unit'}):find(function(e) return (e.name=='ninilite' or e.name=='wuyun') and e.unit.world==w end),'Old expedition companions spawned')
  local function open(id)
   c.action:emit('TapBegan');wait(function() return w.storyFlow and w.storyFlow.id==id and w.storyFlow.view.visible end,20);return w.storyFlow
  end
  local function advance(flow,untilFn,t)
   local deadline=D.App.runningTime+(t or 30)
   while not untilFn() do assert(D.App.runningTime<deadline,'Dialogue stalled '..flow.id..' command='..tostring(c.command)..' phase='..flow.phase);if flow.phase=='dialogue' and not flow.view._advancing then flow.view.confirm:emit('Tapped') end;D.sleep(.08) end
  end
  local f=open('valley-departure');advance(f,function() return f.phase=='complete' end);assert(#f.view._reviews==1)
  local stopped=c.fox.x;D.sleep(2.5);assert(c.phase=='walk1' and c.fox.x<=p.unit.x+500,'Fox failed to wait for player')
  move(2600);wait(function() return c.phase=='checkpoint' end,15)
  f=open('fox-trail-rest');advance(f,function() return c.command=='food' end)
  assert(not f.view.visible,'Food operation blocked by dialogue layer')
  assert(not story:completeAsync('fox-trail-rest','Factory'),'Food completion bypassed')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_fox_food BEFORE UPDATE OF foodUsed ON Game0FoxTrail BEGIN SELECT RAISE(ABORT,'QA food'); END")>=0)
  c.action:emit('TapBegan');wait(function() return c.foodError end,15);assert(store:load().foodUsed==0 and store:foodCount()==originalFood)
  local foodLog=c.logs[#c.logs];assert(foodLog.phase=='food' and foodLog.completed-foodLog.started>=foodLog.duration-.05)
  D.DB:exec('DROP TRIGGER lsd.fail_fox_food');c.action:emit('TapBegan');advance(f,function() return f.phase=='complete' end,35)
  assert(#f.view._reviews==13 and store:load().foodUsed==1 and store:foodCount()==originalFood-1)
  local foods,arrival=0
  for _,log in ipairs(c.logs) do if log.phase=='food' then foods=foods+1 elseif log.phase=='villy-arrival' then arrival=log end end
  assert(foods==1 and arrival and arrival.completed and arrival.to-arrival.from>200 and c.villy.unit.visible,'Food repeated or Villy teleported')
  local mid=D.Path(D.Content.writablePath,'lsd-fox-trail-mid-qa-'..id..'.db');assert(D.Content:copyAsync(db,mid));D.Content:save(D.Path(root,'Test','fox-trail-mid-resume-fixture.txt'),mid)
  move(4100);wait(function() return c.phase=='checkpoint' end,15)
  local second=c.logs[#c.logs];assert(second.phase=='walk2' and second.movingSeconds>=5 and second.movingSeconds<=10,'Original follow duration violated '..second.movingSeconds)
  f=open('fox-trail-scout');advance(f,function() return c.command=='scan' end)
  assert(not f.view.visible,'Lens operation blocked by dialogue layer')
  assert(not story:completeAsync('fox-trail-scout','Factory'),'Survey bypassed')
  c.action:emit('TapBegan');wait(function() return w.nightLens and w.nightLens.phase=='map' end);local lens=w.nightLens
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_fox_scan BEFORE UPDATE OF scanned ON Game0FoxTrail BEGIN SELECT RAISE(ABORT,'QA survey'); END")>=0)
  lens.view.archiveButton:emit('Tapped');wait(function() return c.scanError end,10);assert(not store:load().scanned and not story:summary().completed['fox-trail-scout'])
  D.DB:exec('DROP TRIGGER lsd.fail_fox_scan');lens.view.archiveButton:emit('Tapped');wait(function() return c.scanDone end,10)
  assert(c.scanLog.completed-c.scanLog.started>=2.9 and lens.view.detail.text:find('收集完毕',1,true))
  lens.view.closeButton:emit('Tapped');advance(f,function() return f.phase=='complete' end)
  assert(#f.view._reviews==1 and store:load().scanned)
  f=open('fox-trail-return');advance(f,function() return c.command=='walk-open' end);move(4500);advance(f,function() return f.phase=='complete' end,30)
  assert(#f.view._reviews==7 and c.walkFinished and c.phase=='done')
  assert(supplies==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StorySupplies ORDER BY 1,2,3'),false,true),'Food changed medical supplies')
  c.action:emit('TapBegan');wait(function() return D.Platformer.Data.store.world~=w and D.Platformer.Data.store.world.foxParty end,30)
  w=D.Platformer.Data.store.world;assert(w.tag=='OperationRoom');assert(D.Group({'name','unit'}):find(function(e) return e.name=='villywan' and e.unit.world==w end))
  for _,record in ipairs({{11,3,'valley-departure',1},{11,4,'fox-trail-rest',13},{12,1,'fox-trail-scout',1},{12,2,'fox-trail-return',7}}) do
   local j=assert(require('Story.Journal').openAsync(w,record[1]));({j.view.mailButton,j.view.researchButton,j.view.archiveButton,j.view.stationButton})[record[2]]:emit('Tapped')
   wait(function() return w.storyFlow and w.storyFlow.id==record[3] and w.storyFlow.view.visible end);local replay=w.storyFlow
   advance(replay,function() return replay.phase=='complete' end);assert(#replay.view._reviews==record[4])
   wait(function() return w.storyJournal.phase=='journal' end);w.storyJournal.view.closeButton:emit('Tapped')
  end
  assert(store:load().foodUsed==1 and store:foodCount()==originalFood-1 and store:load().scanned,'Replay changed consumables')
  D.Content:save(D.Path(root,'Test','fox-trail-resume-fixture.txt'),db)
  return 'PASS earnedValleyCopy=true physicalDeparture=true departureRollbackRetry=true originalRows22=true actualFollowAndWait=true secondFollow5to10seconds=true actualFoodFullNativeEnd=true foodRollbackRetryNoRepeat=true realVillyArrival=true originalNightLens=true realThreeSecondSurvey=true scanRollbackRetry=true collectedDisplay=true threePartyOpenSpace=true originalOperationRoom=true crossRoomJournalReplay=true consumablesAndMedicinePreserved=true'
 end,debug.traceback)
 local report='LSD_FOX_TRAIL_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
