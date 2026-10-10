local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local result={status='RUNNING',runId=tostring(os.time()),osInput=false};local out=D.Path(root,'Test/last-promise-resume-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/last-promise-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-last%-promise%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-last-promise-resume-qa-'..result.runId..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Start');local deadline=D.App.runningTime+40
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.finalGate)do assert(D.App.runningTime<deadline);D.sleep(.03)end
  D.sleep(1);local w=D.Platformer.Data.store.world;local c=w.jadeArrival
  assert(w.tag=='RDRoom'and c.recorded and not c.barrier and not c.ward.active and not w.storyFlow and not w.finalBattle and not w.patrolLevel)
  assert(c.twins[1].model.x==5400 and c.twins[2].model.x==5560)
  result.roster=assert(require('Story.AcademyLossRecords').current());for _,r in ipairs(result.roster)do if r.role=='vika'or r.role=='vivi'then assert(r.status=='rescued')end end
  local facts=assert(require('Story.Service').open()):summary();assert(facts.mission.unlocks['last-promise-complete']and facts.objective:find('已抵达',1,true))
  local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end));local hud
  D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  hud.move:emit('Right',true);while p.unit.x<w.finalGate.marker.x-100 do assert(D.App.runningTime<deadline);D.sleep(.02)end;hud.move:emit('Right',false);D.sleep(.2)
  local record=assert(w.finalGate:request());assert(w.finalGate.phase=='record');record.againButton:emit('Tapped');assert(w.finalGate.phase=='ready')
  D.sleep(3)
  assert((c.twins[1].completed.idle or 0)>1 and (c.twins[2].completed.idle or 0)>1)
  assert(#D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE status='active'")==0)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/last-promise-cold-resume.tga'));D.sleep(.2)
  result.savedRecord=true;result.originalIdleLoops=true
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  result.allTablesPreserved=true;result.noReplay=true;result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
