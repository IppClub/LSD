local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','fox-trail-complete-resume-result.txt');D.Content:save(out,'LSD_FOX_COMPLETE_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','fox-trail-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fox%-trail%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fox-complete-resume-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20);while not f() do assert(D.App.runningTime<deadline,'Complete resume stalled');D.sleep(.03) end end
  local before={};for _,name in ipairs({'Game0FoxTrail','Game0ValleyRewards','Game0StorySupplies','Game0StoryUnlocks'}) do before[name]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true) end
  require('Start');wait(function() local w=D.Platformer.Data.store.world;return w and w.tag=='OperationRoom' and w.foxParty and w.data.navigationAttached end,30)
  local w=D.Platformer.Data.store.world;assert(not w.foxTrail and D.Group({'name','unit'}):find(function(e) return e.name=='villywan' and e.unit.world==w end))
  local j=assert(require('Story.Journal').openAsync(w,12));j.view.mailButton:emit('Tapped');wait(function() return w.storyFlow and w.storyFlow.id=='fox-trail-scout' and w.storyFlow.view.visible end)
  local f=w.storyFlow;local deadline=D.App.runningTime+20;while f.phase=='dialogue' or f.phase=='saving' do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==1 and not w.nightLens)
  wait(function() return w.storyJournal.phase=='journal' end);w.storyJournal.view.closeButton:emit('Tapped')
  for name,value in pairs(before) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume changed '..name) end
  return 'PASS actualStart=true earnedCompletedCopy=true operationRoomRestored=true originalFoxAndVillyPresent=true publicJournalSurveyReplay=true noRepeatSurvey=true foodRewardsAndSuppliesUnchanged=true'
 end,debug.traceback)
 local report='LSD_FOX_COMPLETE_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
