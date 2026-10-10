local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','fresh-fox-trail-current-result.json');local evidence={status='RUNNING',osInput=false};local function save() D.Content:save(out,D.json.encode(evidence,false,true)) end;save()
D.thread(function()
 local ok,res=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-earned-valley-days-20261007/result.json')),32)
  assert(prior.status=='PASS' and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-valley%-days%-current%-%d+%.db$'))
  local source=prior.database;local db=D.Path(D.Content.writablePath,'fresh-fox-trail-current-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));evidence.database=db;evidence.source=source;save();assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function models() return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true) end
  local unchanged=models()
  local function wait(f,t,message) local deadline=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<deadline,message or 'Fox trail stalled');D.sleep(.03) end end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.valleyDays and w.valleyDays.fox and w.valleyEncounter.phase=='ready' end,30)
  local w=D.Platformer.Data.store.world;local p=D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==w end)
  evidence.visualSamples={}
  local walkSamples,nextWalkSample=0,0
  local function captureFox(kind)
   local trail=w.foxTrail
   if not trail then return end
   local fox=trail.fox
   local index=#evidence.visualSamples+1
   local path=D.Path(D.Content.writablePath,'fox-trail-pose-'..index..'.tga')
   local sample={kind=kind,path=path,requestedAt=D.App.runningTime}
   evidence.visualSamples[index]=sample
   -- Projection runs during rendering with the actual PlatformerCamera.
   -- Window points are logical pixels; screenshots use the render buffer.
   fox:convertToWindowSpace(D.Vec2.zero,function(point)
    local buffer,window=D.App.bufferSize,D.App.winSize
    sample.at=D.App.runningTime
    sample.x=fox.x;sample.y=fox.y;sample.clip=fox.current
    sample.movementState=fox.movementState;sample.speed=fox.speed
    sample.fliped=fox.fliped;sample.travelVelocity=fox.travelVelocity
    sample.playerX=p.unit.x
    sample.windowX=point.x;sample.windowY=point.y
    sample.screenX=point.x*buffer.width/window.width
    sample.screenY=point.y*buffer.height/window.height
    sample.bufferWidth=buffer.width;sample.bufferHeight=buffer.height
    sample.windowWidth=window.width;sample.windowHeight=window.height
    sample.projection='convertToWindowSpace-render-camera'
    D.App:saveScreenshot(path)
   end)
  end
  local function move(x)
   local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local side=p.unit.x<x and 'Right' or 'Left';hud.move:emit(side,true)
   local deadline=D.App.runningTime+45
   while math.abs(p.unit.x-x)>30 do
    assert(D.App.runningTime<deadline,'Travel stalled x='..p.unit.x..' target='..x)
    if w.foxTrail and w.foxTrail.fox.movementState=='fmove' and walkSamples<8 and D.App.runningTime>=nextWalkSample then
     captureFox('walk');walkSamples=walkSamples+1;nextWalkSample=D.App.runningTime+.2
    end
    D.sleep(.02)
   end
   hud.move:emit(side,false);D.sleep(.3)
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
  assert(require('Story.FoxCompanion').walkSpeed==240 and c.fox.motionVariant=='spine-corrected')
  assert(math.abs(c.fox.walkAnimationSpeed-.85)<.001 and math.abs(c.fox.recovery-.2)<.001)
  local foxWalkEnds={}
  c.fox:slot('AnimationEnd',function(name)if name=='fmove' then foxWalkEnds[#foxWalkEnds+1]=D.App.runningTime end end)

  assert(not D.Group({'name','unit'}):find(function(e) return (e.name=='ninilite' or e.name=='wuyun') and e.unit.world==w end),'Old expedition companions spawned')
  local function open(id)
   c.action:emit('TapBegan');wait(function() return w.storyFlow and w.storyFlow.id==id and w.storyFlow.view.visible end,20);return w.storyFlow
  end
  local function advance(flow,untilFn,t)
   local deadline=D.App.runningTime+(t or 30)
   while not untilFn() do assert(D.App.runningTime<deadline,'Dialogue stalled '..flow.id..' command='..tostring(c.command)..' phase='..flow.phase);if flow.phase=='dialogue' and not flow.view._advancing then flow.view.confirm:emit('Tapped') end;D.sleep(.08) end
  end
  local f=open('valley-departure');advance(f,function() return f.phase=='complete' end);assert(#f.view._reviews==1)
  local stopped=c.fox.x
  for i=1,8 do captureFox('waiting');D.sleep(.3125)end
  assert(c.phase=='walk1' and c.fox.x<=p.unit.x+500,'Fox failed to wait for player')
  move(2600);wait(function() return c.phase=='checkpoint' end,15)
  assert(#foxWalkEnds>=2,'Fox never completed full walk loops')
  local fullLoop=false
  for i=2,#foxWalkEnds do if math.abs(foxWalkEnds[i]-foxWalkEnds[i-1]-1/.85)<.07 then fullLoop=true end end
  assert(fullLoop,'Fox walk clock is still accelerated or truncated')

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
  local mid=D.Path(D.Content.writablePath,'lsd-fresh-fox-trail-mid-qa-'..id..'.db');assert(D.Content:copyAsync(db,mid));evidence.midDatabase=mid;save()
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
  local E=require('Economy.Store');assert(E.open() and not E.active() and E.wallet().available==prior.balance and models()==unchanged,'Fox trail changed combat wallet/model')
  assert(#evidence.visualSamples==16,'Missing authored-route visual samples')
  for _,sample in ipairs(evidence.visualSamples)do
   assert(sample.at and sample.projection=='convertToWindowSpace-render-camera' and D.Content:exist(sample.path),'Projection or screenshot callback missing')
   assert(sample.screenX>=0 and sample.screenX<=sample.bufferWidth and sample.screenY>=0 and sample.screenY<=sample.bufferHeight,'Fox projected outside visible buffer')
  end
  evidence.balance=E.wallet().available;evidence.sameJourney=true;evidence.stage='fox-trail-return';save()
  return 'PASS earnedValleyCopy=true physicalDeparture=true departureRollbackRetry=true originalRows22=true actualFollowAndWait=true secondFollow5to10seconds=true actualFoodFullNativeEnd=true foodRollbackRetryNoRepeat=true realVillyArrival=true originalNightLens=true realThreeSecondSurvey=true scanRollbackRetry=true collectedDisplay=true threePartyOpenSpace=true originalOperationRoom=true crossRoomJournalReplay=true consumablesAndMedicinePreserved=true'
 end,debug.traceback)
 evidence.status=ok and 'PASS' or 'FAIL';evidence.detail=ok and res or nil;evidence.error=not ok and tostring(res) or nil;save();print('LSD_FRESH_FOX_TRAIL_CURRENT_'..evidence.status)
end)
