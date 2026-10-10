local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','valley-complete-resume-result.txt');D.Content:save(out,'LSD_VALLEY_COMPLETE_RESUME_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','valley-days-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-valley%-days%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-valley-complete-resume-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t) local deadline=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<deadline,'Valley complete resume stalled');D.sleep(.04) end end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.tag=='OuterHeaven' and w.valleyDays and w.valleyDays.fox and w.valleyEncounter.phase=='ready' end,30)
  local w=D.Platformer.Data.store.world;local days=w.valleyDays;local story=assert(require('Story.Service').open())
  assert(story:summary().completed['valley-days'] and story:summary().completed['valley-friends'])
  assert(#days.logs==0 and not days.foxArrival and not w.valleyEncounter.logs.fallen,'Resume repeated initial performances')
  assert(w.valleyEncounter.friendly.visible,'Friendly monster missing on resume')
  local before={};for _,name in ipairs({'Game0ValleyActivities','Game0ValleyRewards','Game0StorySupplies','Game0MissionUnlocks'}) do before[name]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true) end
  for _,node in ipairs({1,2}) do
   local j=assert(require('Story.Journal').openAsync(w,11));(node==1 and j.view.mailButton or j.view.researchButton):emit('Tapped')
   wait(function() return w.storyFlow and w.storyFlow.id==(node==1 and 'valley-days' or 'valley-friends') and w.storyFlow.view.visible end)
   local f=w.storyFlow;local deadline=D.App.runningTime+30
   while f.phase=='dialogue' or f.phase=='saving' do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
   assert(f.phase=='complete' and #f.view._reviews==(node==1 and 1 or 24))
   wait(function() return D.Director.ui3D:getChildByTag('story-journal') end);D.Director.ui3D:getChildByTag('story-journal').controller.view.closeButton:emit('Tapped')
  end
  assert(#days.logs==0 and not days.foxArrival)
  for name,value in pairs(before) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume/replay changed '..name) end
  local facts=assert(w.valleyActivities.service:summary());for _,activity in ipairs(require('Story.ValleyRules').ids) do assert(facts.complete[activity] and facts.rewards[activity]) end
  return 'PASS actualStart=true originalValley=true completeFiveActivitiesRetained=true originalFriendlyAndFoxRestored=true publicPage11Replay=true noRepeatSleepWakeOrArrival=true rewardsAndSuppliesUnchanged=true'
 end,debug.traceback)
 local report='LSD_VALLEY_COMPLETE_RESUME_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
