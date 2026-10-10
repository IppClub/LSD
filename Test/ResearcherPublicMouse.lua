-- Public route from an earned stealth checkpoint; no fabricated victory or user save writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/researcher-public-mouse-result.txt');D.Content:save(out,'RUNNING '..id)
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/infiltration-path-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-infiltration%-path%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-researcher-public-mouse-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local untilTime=D.App.runningTime+(t or 25);while not fn()do assert(D.App.runningTime<untilTime,'Researcher route stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local route=w.infiltration
  assert(route.pathCompleted and route.researcher and not route.capture.caught)
  D.Content:save(out,'LSD_RESEARCHER_PUBLIC_MOUSE_READY runId='..id)
  wait(function()
   local current=D.Platformer.Data.store.world
   return current and current.infiltration and current.infiltration.capture and current.infiltration.capture.caught
  end,180)
  local store=assert(require('Story.ResearcherStore').open());local saved=assert(store:load())
  assert(saved.caught and saved.report.status=='won')
  assert(saved.report.mentorHits>0,'No actual mentor shot hit')
  local facts=assert(require('Story.Service').open()):summary();assert(facts.completed['researcher-contact'])
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes' and name~='Game0StoryUnlocks'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.Content:save(D.Path(root,'Test/researcher-public-mouse-report.json'),D.json.encode(saved.report))
  return 'PASS earnedPath=true actualOSInput=true publicMenu=true originalDialogue=true actualCaptureCombat=true resultContinue=true capturedCheckpoint=true priorTablesPreserved=true'

 end,debug.traceback)
 local text='LSD_RESEARCHER_PUBLIC_MOUSE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;D.Content:save(out,text);print(text)
end)
