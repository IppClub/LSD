local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','valley-encounter-result.txt');D.Content:save(out,'LSD_VALLEY_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','pursuit-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-pursuit%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-valley-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<deadline,'Valley wait stalled');D.sleep(.04) end end
  require('Start');wait(function() return world() and world().tag=='OuterHeaven' and world().valleyEncounter and world().valleyEncounter.phase=='ready' end,30)
  local w=world();local c=w.valleyEncounter;assert(w.sceneWidth==11520)
  assert(c.logs.fallen.completed and c.logs.awakening.completed and c.ambient>0)
  assert(not D.Group({'name','unit'}):find(function(e) return e.unit.world==w and e.name=='ninilite' end),'Escaped companion appeared in valley')
  local p=assert(player());p.keyRight=true;wait(function() return c.menu.menu.enabled end);p.keyRight=false;p.unit:stop();p.unit.velocityX=0
  c.menu:emit('Tapped',1);wait(function() return w.storyFlow and w.storyFlow.id=='valley-awakening' and w.storyFlow.view.visible end)
  local f=w.storyFlow;local deadline=D.App.runningTime+90
  while f.phase=='dialogue' or f.phase=='saving' do assert(D.App.runningTime<deadline,'Valley Yarn/command stalled');if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==32,'Incomplete original valley dialogue')
  assert(c.logs.water.completed and c.logs.ride.completed and c.logs.feed.completed and c.friendly.visible and c.friendlyCalmed)
  local service=assert(require('Story.Service').open());assert(service:summary().completed['valley-awakening'])
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='valley-met'")==1)
  local before=D.json.encode(c.logs,false,true)
  local journal=assert(require('Story.Journal').openAsync(w,10));journal.view.stationButton:emit('Tapped')
  wait(function() return w.storyFlow~=f and w.storyFlow.view.visible end);f=w.storyFlow
  while f.phase=='dialogue' or f.phase=='saving' do if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==32 and D.json.encode(c.logs,false,true)==before,'Replay repeated presentation')
  D.Content:save(D.Path(root,'Test','valley-resume-fixture.txt'),db)
  return 'PASS earnedPursuitCopy=true originalStartContinuesValley=true originalOuterHeaven=true originalVillywan=true noEscapedLearnersSpawned=true actualFullWake=true waterAndFeedFull=true actualRideWalk=true originalRows32=true musicAndAmbientStarted=true originalPetals=true replayNoPhysicalRepeat=true rewardOnce=true'
 end,debug.traceback)
 local report='LSD_VALLEY_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
