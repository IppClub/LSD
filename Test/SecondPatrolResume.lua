-- Read-only resume of earned second-wave victory, with a reversible version probe in a QA copy.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false,sameProcessOnly=true};local out=D.Path(root,'Test/second-patrol-resume-result.json')
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/second-patrol-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-second%-patrol%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-second-patrol-resume-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local service=assert(require('Story.Service').open());local facts=service:summary();local mod=require('Story.SecondPatrolStore')
  assert(D.DB:exec('UPDATE lsd.Game0SecondPatrol SET schemaVersion=99')>=0)
  local store,why=mod.open();assert(not store and why=='INCOMPATIBLE_SECOND_PATROL_SAVE')
  local options;options,why=require('Story.InfiltrationStore').resumeOptions(facts);assert(not options and why=='INCOMPATIBLE_SECOND_PATROL_SAVE')
  assert(D.DB:exec('UPDATE lsd.Game0SecondPatrol SET schemaVersion=1')>=0)
  require('Start');local deadline=D.App.runningTime+40
  while not (D.Platformer.Data.store.world and D.Platformer.Data.store.world.infiltration and D.Platformer.Data.store.world.infiltration.phase=='ready')do assert(D.App.runningTime<deadline,'Resume stalled');D.sleep(.03)end
  local world=D.Platformer.Data.store.world;local route=world.infiltration
  assert(route.second.completed and route.interrogated and not route.battleLevel and not world.interrogation)
  assert(service:summary().objective:find('守卫已制服'))
  local wu=D.Group({'name','unit'}):find(function(e)return e.name=='wuyun' and e.unit.world==world end);assert(wu and math.abs(wu.unit.x-4680)<5)
  assert(route.researcher.current=='unconscious' or route.researcher.lastCompleted=='unconscious')
  assert(require('Story.ControlPodStore').open(),'Control pod unavailable on resume')
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.status='PASS';report.allTablesPreserved=true;report.futureVersionRefused=true;report.noRepeatedBattle=true;report.guardRestored=true;report.database=db
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
