local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/infiltration-path-resume-result.txt');D.Content:save(out,'LSD_INFILTRATION_PATH_RESUME_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/infiltration-path-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-infiltration%-path%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-infiltration-path-resume-qa-'..id..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 20);while not fn()do assert(D.App.runningTime<deadline,'Path resume stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local r=w.infiltration;local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
  assert(math.abs(p.unit.x-4100)<40 and r.pathCompleted and not r.path,'Resume repeated stealth route')
  assert(r.fox.motionVariant=='articulated-q-v5' and math.abs(r.fox.x-4400)<1)
  for _,name in ipairs({'ninilite','wuyun'})do local e=assert(D.Group({'name','unit'}):find(function(e)return e.name==name and e.unit.world==w end));assert(math.abs(e.unit.x-4100)<700,'Ally left at previous checkpoint')end
  for _,record in ipairs({{3,'infiltration-fox-guide',1},{4,'infiltration-researcher-scout',2}})do
   local j=assert(require('Story.Journal').openAsync(w,13));({j.view.mailButton,j.view.researchButton,j.view.archiveButton,j.view.stationButton})[record[1]]:emit('Tapped')
   wait(function()return w.storyFlow and w.storyFlow.id==record[2]and w.storyFlow.view.visible end);local f=w.storyFlow
   while f.phase~='complete'do if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end;assert(#f.view._reviews==record[3]);wait(function()return w.storyJournal.phase=='journal'end);w.storyJournal.view.closeButton:emit('Tapped')
  end
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume/replay changed '..name)end
  D.DB:exec('UPDATE lsd.Game0InfiltrationPath SET schemaVersion=99 WHERE id=1')
  local s,why=require('Story.InfiltrationPathStore').open();assert(not s and why=='INCOMPATIBLE_INFILTRATION_PATH')
  local options,err=require('Story.InfiltrationStore').resumeOptions(assert(require('Story.Service').open()):summary());assert(not options and err=='INCOMPATIBLE_INFILTRATION_PATH')
  D.DB:exec('UPDATE lsd.Game0InfiltrationPath SET schemaVersion=1 WHERE id=1')
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/infiltration-path-resumed.tga'))
  return 'PASS actualStart=true physicalPathEarnedCopy=true safeFactory4100=true articulatedQFox=true twoAlliesAtCheckpoint=true noRepeatedPatrolOrPath=true originalJournalRows3=true allTablesUnchanged=true futurePathVersionRefused=true sameProcessOnly=true'
 end,debug.traceback)
 local report='LSD_INFILTRATION_PATH_RESUME_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
