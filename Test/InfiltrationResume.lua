-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','infiltration-resume-result.txt');D.Content:save(out,'LSD_INFILTRATION_RESUME_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','infiltration-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-infiltration%-mid%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-infiltration-resume-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local store=assert(require('Story.InfiltrationStore').open());assert(store:load().active and store:load().firstPatrol)
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Infiltration resume stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local c=world.infiltration
  assert(world.tag=='Factory' and world.infiltrationRoute and c.state.firstPatrol and c.fox.companionForm=='nine-tail-chibi')
  assert(not world.patrolBattle and not world.foxTrail,'Safe checkpoint resumed combat or repeated old route')
  local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end);assert(math.abs(p.unit.x-2200)<80)
  assert(c.phase=='ready' and not world.storyFlow,'Completed patrol repeated');assert(require('Story.Service').open():canRead('infiltration-fox-guide','Factory'),'Next authored fox route locked')
  local journal=assert(require('Story.Journal').openAsync(world,13));journal.view.researchButton:emit('Tapped');wait(function()return world.storyFlow and world.storyFlow.id=='patrol-cleared' and world.storyFlow.view.visible end)
  local f=world.storyFlow;local deadline=D.App.runningTime+20;while f.phase~='complete'do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end
  assert(#f.view._reviews==1);wait(function()return world.storyJournal.phase=='journal'end);world.storyJournal.view.closeButton:emit('Tapped')
  D.App:saveScreenshot(D.Path(root,'Docs','evidence','2026-10-03','infiltration-resumed-first-patrol.tga'))
  for name,value in pairs(snapshot) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Prototype battle mutated '..name) end
  return 'PASS actualStart=true earnedPatrolCopy=true safeFactory2200=true noRepeatedCombatOrOldFoxRoute=true originalQFox=true publicJournalReplay=true allTablesUnchanged=true'
 end,debug.traceback)
 local report='LSD_INFILTRATION_RESUME_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
