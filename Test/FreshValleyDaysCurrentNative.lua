local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','fresh-valley-days-current-result.json');local evidence={status='RUNNING',osInput=false};local function save() D.Content:save(out,D.json.encode(evidence,false,true)) end;save()
D.thread(function()
 local ok,res=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-earned-valley-activities-20261007/result.json')),32)
  assert(prior.status=='PASS' and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-valley%-activities%-current%-%d+%.db$'))
  local source=prior.database;local db=D.Path(D.Content.writablePath,'fresh-valley-days-current-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));evidence.database=db;evidence.source=source;save();assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function models() return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true) end
  local unchanged=models()
  local function wait(f,t) local endTime=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<endTime,'Valley days stalled');D.sleep(.03) end end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.valleyDays and w.valleyEncounter.phase=='ready' end,30)
  local w=D.Platformer.Data.store.world;local c=w.valleyDays;local service=assert(require('Story.Service').open())
  local p=assert(D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==w end))
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  local function move(x)
   local side=p.unit.x<x and 'Right' or 'Left';hud.move:emit(side,true)
   local deadline=D.App.runningTime+45
   while math.abs(p.unit.x-x)>30 do assert(D.App.runningTime<deadline,'Valley physical walk stalled');D.sleep(.02)end
   hud.move:emit(side,false);D.sleep(.3)
  end
  assert(not service:canRead('valley-friends','OuterHeaven'),'Days gate bypassed')
  move(1800);wait(function() return c.rest.menu.menu.enabled end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_valley_days BEFORE INSERT ON Game0StoryUnlocks WHEN NEW.id='valley-days-passed' BEGIN SELECT RAISE(ABORT,'QA valley days fault'); END")>=0)
  c.rest.menu:emit('Tapped',1);wait(function() return w.storyFlow and w.storyFlow.id=='valley-days' and w.storyFlow.view.visible end)
  local f=w.storyFlow
  local function complete(flow,seconds)
   local deadline=D.App.runningTime+(seconds or 30)
   while flow.phase=='dialogue' or flow.phase=='saving' do assert(D.App.runningTime<deadline,'Valley dialogue stalled');if not flow.view._advancing then flow.view.confirm:emit('Tapped') end;D.sleep(.08) end
  end
  complete(f);assert(f.phase=='save-error' and c.restCompleted and #c.logs==2 and #f.view._reviews==1)
  assert(not service:summary().completed['valley-days'] and p.busy)
  D.DB:exec('DROP TRIGGER lsd.fail_valley_days');f.retryButton:emit('Tapped');wait(function() return f.phase=='complete' and not p.busy end)
  assert(#c.logs==2 and service:summary().completed['valley-days'])
  local v=w.valleyEncounter.actor;move(v.unit.x);wait(function() return c.friends.menu.menu.enabled end)
  c.friends.menu:emit('Tapped',1);wait(function() return w.storyFlow~=f and w.storyFlow.view.visible end);f=w.storyFlow
  complete(f);assert(f.phase=='complete' and #f.view._reviews==24,'Original later dialogue missing')
  assert(f.view._reviews[6].name=='怪物' and f.view._reviews[14].name=='大狐狸' and f.view._reviews[15].name=='万薇莉','Original speaker names missing')
  assert(c.fox and c.foxArrival and c.foxArrival.completed and math.abs(c.foxArrival.from-c.foxArrival.to)>450,'Fox did not actually arrive')
  assert(c.fox.motionVariant=='spine-corrected' and c.fox.speed==1 and math.abs(c.fox.recovery-.2)<.001)
  assert(service:summary().completed['valley-friends'] and service:summary().unlocks['fox-route-offered'])
  local arrival=c.foxArrival.completed;local logs=D.json.encode(c.logs,false,true)
  local journal=assert(require('Story.Journal').openAsync(w,11));journal.view.researchButton:emit('Tapped')
  wait(function() return w.storyFlow~=f and w.storyFlow.view.visible end);f=w.storyFlow;complete(f)
  assert(f.phase=='complete' and #f.view._reviews==24 and c.foxArrival.completed==arrival and D.json.encode(c.logs,false,true)==logs,'Replay repeated arrival/rest')
  wait(function() return D.Director.ui3D:getChildByTag('story-journal') end);D.Director.ui3D:getChildByTag('story-journal').controller.view.closeButton:emit('Tapped')
  assert(#D.DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='fox-route-offered'")==1)
  for _,log in ipairs(c.logs) do assert(log.completed-log.started>=log.duration-.05) end
  local E=require('Economy.Store');assert(E.open() and not E.active() and E.wallet().available==prior.balance and models()==unchanged,'Valley days changed wallet/model')
  evidence.balance=E.wallet().available;evidence.sameJourney=true;evidence.stage='valley-friends';save()
  return 'PASS earnedFiveActivityCopy=true realStart=true languageAndDaysGates=true physicalHammock=true fullSleepWake=true originalDaysDisplay=true saveRollbackRetry=true originalLaterRows24=true originalFoxActuallyArrives=true originalSpeakerNames=true publicJournalReplay=true noRepeatArrivalRest=true rewardOnce=true'
 end,debug.traceback)
 evidence.status=ok and 'PASS' or 'FAIL';evidence.detail=ok and res or nil;evidence.error=not ok and tostring(res) or nil;save();print('LSD_FRESH_VALLEY_DAYS_CURRENT_'..evidence.status)
end)
