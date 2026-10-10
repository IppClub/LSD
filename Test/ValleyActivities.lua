local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','valley-activities-result.txt');D.Content:save(out,'LSD_VALLEY_ACTIVITIES_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','valley-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-valley%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-valley-activities-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t) local untilTime=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<untilTime,'Valley activities stalled');D.sleep(.03) end end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.valleyActivities and w.valleyEncounter.phase=='ready' end,30)
  local w=D.Platformer.Data.store.world;local c=w.valleyActivities;local R=require('Story.ValleyRules')
  local p=assert(D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==w end))
  local v=w.valleyEncounter.actor;assert(w.valleyEncounter.friendly.visible,'Completed visit lost friendly monster on resume')
  for _,name in ipairs({'fmove','idle','turn'}) do local a=p.unit:getAction(name);if a then a.reaction=.05 end end
  local function stop() p.keyLeft=false;p.keyRight=false;p.unit:stop();p.unit.velocityX=0 end
  local function move(x)
   local deadline=D.App.runningTime+30
   while math.abs(p.unit.x-x)>25 do assert(D.App.runningTime<deadline,'Activity walking stalled');p.keyLeft=p.unit.x>x;p.keyRight=p.unit.x<x;D.sleep(.03) end
   stop();D.sleep(.1)
  end
  local function choose(activity)
   move(R.specs[activity].x);wait(function() return c.terminals[activity].menu.menu.enabled end)
   c.terminals[activity].menu:emit('Tapped',1);assert(c.active==activity)
  end
  local function action() c.actionButton:emit('TapBegan');wait(function() return c.phase=='idle' or c.phase=='save-error' end,8) end
  -- No remote pickup; no activity reward before the actual location/task.
  c.active='fish';assert(not c:request());assert(#D.DB:query('SELECT id FROM lsd.Game0ValleyRewards')==0)
  choose('fish')
  for i=1,3 do
   local deadline=D.App.runningTime+18
   while not c.states.fish.marks[i] do
    assert(D.App.runningTime<deadline,'Fishing timed action stalled')
    local target=c.art.fishes[i].x-200;p.keyLeft=p.unit.x>target+15;p.keyRight=p.unit.x<target-15
    if math.abs(p.unit.x-target)<75 and c.fishCycles[i]<.55 then stop();c.actionButton:emit('TapBegan');wait(function() return c.phase=='idle' end,8) end
    D.sleep(.03)
   end
   stop()
  end
  choose('farm')
  for stage=0,2 do for i=1,3 do
   move(R.specs.farm.x+(i-2)*150)
   if stage==2 then wait(function() return os.time()-c.states.farm.watered[i]>=R.growthSeconds end,8) end
   action();assert(c.states.farm.plots[i]==stage+1,'Plot did not advance')
  end end
  choose('peach')
  for i=1,3 do move(R.specs.peach.x+(i-2)*200);wait(function() return c.observing[i]>=2.5 end,8);action();assert(c.states.peach.marks[i]) end
  choose('chicken')
  for i=1,2 do
   local deadline=D.App.runningTime+20
   while not c.states.chicken.marks[i] do
    assert(D.App.runningTime<deadline,'Chicken chase stalled')
    local target=c.art.chickens[i].x-200;p.keyLeft=p.unit.x>target;p.keyRight=p.unit.x<target
    if math.abs(p.unit.x-target)<90 then stop();c.actionButton:emit('TapBegan');wait(function() return c.phase=='idle' end,8) end
    D.sleep(.03)
   end
   stop()
  end
  choose('language');assert(not c:request(),'Language skipped calm requirement')
  wait(function() return c.calm>=3 end,8);c.actionButton:emit('TapBegan');assert(c.phase=='quiz')
  c.answerButtons[2]:emit('Tapped');assert(c.phase=='idle' and c.states.language.correct==0 and c.calm==0,'Wrong answer rewarded')
  for i=1,3 do
   wait(function() return c.calm>=3 end,8);c.actionButton:emit('TapBegan');assert(c.phase=='quiz')
   if i==3 then assert(D.DB:exec("CREATE TRIGGER lsd.fail_valley_reward BEFORE INSERT ON Game0ValleyRewards WHEN NEW.id='language' BEGIN SELECT RAISE(ABORT,'QA valley reward fault'); END")>=0) end
   c.answerButtons[R.lessons[i].correct]:emit('Tapped');wait(function() return c.phase=='idle' or c.phase=='save-error' end,8)
   if i==3 then
    assert(c.phase=='save-error' and c.states.language.correct==2 and c.service:load('language').correct==2,'Activity reward was not atomic')
    D.DB:exec('DROP TRIGGER lsd.fail_valley_reward');c.retryButton:emit('Tapped');wait(function() return c.phase=='idle' end)
   end
   assert(c.states.language.correct==i)
  end
  local facts=assert(c.service:summary());for _,activity in ipairs(R.ids) do assert(facts.complete[activity] and facts.rewards[activity]) end
  local rewards=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0ValleyRewards ORDER BY id'),false,true)
  assert(not c:request() and rewards==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0ValleyRewards ORDER BY id'),false,true),'Repeat duplicated reward')
  for _,log in ipairs(c.logs) do assert(log.completed and log.completed-log.started>=log.duration-.05,'Activity action truncated') end
  assert(v.unit.x>8000,'Villywan did not actually follow exploration')
  local before=D.json.encode(facts.states,false,true);local restarted=require('Academy.Navigation').returnToRoomAsync('OuterHeaven',{spawn=9300,valleyVisit=true})
  wait(function() return restarted.valleyActivities and restarted.valleyEncounter.phase=='ready' end,30)
  assert(D.json.encode(restarted.valleyActivities.service:summary().states,false,true)==before)
  assert(rewards==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0ValleyRewards ORDER BY id'),false,true))
  D.Content:save(D.Path(root,'Test','valley-activities-resume-fixture.txt'),db)
  return 'PASS actualStartResume=true fivePhysicalTerminals=true realTimedFishing=true actualCropStagesGrowth=true realPeachObservation=true realChickenChase=true calmLanguage=true wrongNoReward=true fullActions=true rewardRollbackRetry=true fiveRewardsOnce=true actualVillyFollow=true completedResume=true'
 end,debug.traceback)
 local report='LSD_VALLEY_ACTIVITIES_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
