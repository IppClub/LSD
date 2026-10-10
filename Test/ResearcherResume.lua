local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/researcher-resume-result.txt');D.Content:save(out,'RUNNING '..id)
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/researcher-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-researcher%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-researcher-resume-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 25);while not fn()do assert(D.App.runningTime<deadline,'Researcher resume stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local r=w.infiltration
  assert(r.capture.caught and r.pathCompleted and not r.path and not r.battleLevel)
  assert(r.researcher.current=='restrained' and math.abs(r.fox.x-r.researcher.x)>=250)
  local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end);assert(math.abs(p.unit.x-4100)<50)
  local j=assert(require('Story.Journal').openAsync(w,14));assert(j.recordIds[1]=='researcher-contact');j.view.mailButton:emit('Tapped')
  wait(function()return w.storyFlow and w.storyFlow.id=='researcher-contact' and w.storyFlow.view.visible end)
  local f=w.storyFlow;while f.phase~='complete'do if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end;assert(#f.view._reviews==2)
  wait(function()return w.storyJournal.phase=='journal'end);w.storyJournal.view.closeButton:emit('Tapped')
  assert(not r.battleLevel,'Journal replay launched capture')
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume/replay changed '..name)end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/researcher-resumed.tga'))
  return 'PASS actualStart=true earnedCaptureCopy=true factory4100=true noRepeatedPatrolPathCapture=true restrainedActor=true separatedFox=true originalContactJournalRows2=true replayNoBattle=true allTablesUnchanged=true sameProcessOnly=true'
 end,debug.traceback)
 local text='LSD_RESEARCHER_RESUME_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;D.Content:save(out,text);print(text)
end)
