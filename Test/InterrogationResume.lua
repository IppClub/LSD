-- Reload an earned complete interrogation, then reread all original rows.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false,sameProcessOnly=true};local out=D.Path(root,'Test/interrogation-resume-result.json')
local function save()D.Content:save(out,D.json.encode(report))end
save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/interrogation-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-interrogation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-interrogation-resume-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Interrogation resume stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local route=world.infiltration
  assert(not world.interrogation and not route.battleLevel and not route.path)
  assert((route.researcher.current=='unconscious' or route.researcher.lastCompleted=='unconscious'));assert(math.abs(route.fox.x-route.researcher.x)>350,'Fox overlaps fallen researcher')
  local wu=D.Group({'name','unit'}):find(function(e)return e.name=='wuyun' and e.unit.world==world end);assert(wu and math.abs(wu.unit.x-4680)<5)
  local j=assert(require('Story.Journal').openAsync(world,14));assert(j.recordIds[2]=='researcher-interrogation')
  j.view.researchButton:emit('Tapped');wait(function()return world.storyFlow and world.storyFlow.id=='researcher-interrogation'end)
  local flow=world.storyFlow
  while flow.phase~='complete'do if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit('Tapped')end;D.sleep(.08)end
  assert(#flow.view._reviews==12);wait(function()return world.storyJournal.phase=='journal'end);world.storyJournal.view.closeButton:emit('Tapped')
  assert(not world.interrogation and not route.battleLevel,'Replay created physical actors or battle')
  assert(route.secondStore and not route.second.completed,'Second patrol checkpoint missing')
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.rows=12;report.allExistingTablesUnchanged=true;report.noRepeatedActors=true;report.guardRestored=true;report.foxSeparated=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end
 save();print(D.json.encode(report))
end)
