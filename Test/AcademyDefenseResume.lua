-- Native battle integration against an earned model; no story victory is inserted.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/academy-defense-resume-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/academy-defense-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-academy%-defense%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-defense-resume-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true)end
  require('Start')
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Defense resume stalled');D.sleep(.02)end end
  wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='PassageA'and w.defenseGate end,35)
  local world=D.Platformer.Data.store.world;assert(not world.defenseBattle and not world.patrolLevel)
  local facts=assert(require('Story.Service').open()):summary();assert(facts.mission.unlocks['academy-defense-complete'])
  assert(facts.objective:find('已守住',1,true))
  local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end))
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  hud.move:emit('Left',true);wait(function()return p.unit.x<1260 end,5);hud.move:emit('Left',false);D.sleep(.1)
  local record=assert(world.defenseGate:request());assert(world.defenseGate.phase=='record');record.againButton:emit('Tapped')
  local briefing=assert(require('Mission.Briefing').openAsync());assert(briefing.mission=='c0-m07'and not briefing.view.startButton.visible)
  briefing.view.startButton:emit('Tapped');D.sleep(.1);assert(briefing.phase=='briefing'and #D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  briefing.view.backButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world.tag=='OperationRoom'end,15)
  require('Academy.Navigation').returnToRoomAsync('PassageA');result.briefingRoutesToPhysicalGate=true
  for name,snapshot in pairs(snapshots)do assert(snapshot==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-defense-resume.tga'))
  result.status='PASS';result.noReplay=true;result.savedRecord=true;result.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
