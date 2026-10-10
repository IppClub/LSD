local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/roof-route-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/control-pod-dialogue-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-control%-pod%-dialogue%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-route-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync();local world,err=require('Factory.Roof').openAsync();assert(world,err);local c=world.roof;report.character=c.player.name
  local function wait(f,seconds)local deadline=D.App.runningTime+seconds;while not f()do assert(D.App.runningTime<deadline,'Roof route timeout: '..c.phase..' '..tostring(c.error));D.sleep(.02)end end
  D.sleep(.05);assert(c.stage==0 and c:landingCollision(c.player));assert(not c.store:writeAsync('climb',{}));assert(not c.store:writeAsync('stairs',{}))
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-route-entry.tga'))
  assert(D.DB:exec("CREATE TRIGGER lsd.roof_test_save_failure BEFORE UPDATE ON Game0Roof WHEN NEW.stage=1 BEGIN SELECT RAISE(FAIL,'roof test save failure'); END")>=0)
  c.hud.move:emit('Right',true);wait(function()return c.player.model.x>=340 end,2);c.hud.move:emit('Right',false);assert(c:act());assert(not c:act())
  wait(function()return c.phase=='save-error' or c.phase=='action-error'end,25);assert(c.phase=='save-error',c.error);assert(c.stage==0 and c.store:load().stage==0 and c.player.model.y==620)
  assert(D.DB:exec('DROP TRIGGER lsd.roof_test_save_failure')>=0);assert(c:saveAsync(table.unpack(c.pending)));assert(c.stage==1);report.saveRetry=true;D.sleep(1);assert(c.nini.model.x>=920 and c.player.model.x-c.nini.model.x>=125);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-route-stair-landing.tga'))
  local bad,reason=c:act();assert(not bad and reason=='OUT_OF_RANGE')
  c.hud.move:emit('Left',true);wait(function()return c.player.model.x<=902 end,2);c.hud.move:emit('Left',false);D.sleep(1);assert(c.nini.model.x>=1040 and c:landingCollision(c.nini),'Follower left safe platform');report.platformTurn=true
  c.hud.move:emit('Right',true);wait(function()return c.player.model.x>=1235 end,3);c.hud.move:emit('Right',false);assert(c:act())
  wait(function()return c.phase=='ready'or c.phase=='action-error'or c.phase=='save-error'end,45);assert(c.phase=='ready',c.error);assert(c.stage==2 and c:landingCollision(c.player) and c:landingCollision(c.nini))
  local state=assert(c.store:load());assert(state.stage==2 and #state.report.climb.actors==2)
  local options=assert(require('Story.InfiltrationStore').resumeOptions(require('Story.Service').open():summary()));assert(options.scene=='FactoryRoof')
  D.sleep(1);assert(c.player.model.x-c.nini.model.x>=125);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-route-landed.tga'))
  for name,value in pairs(snapshot)do if name~='Game0ControlPod' then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  report.status='PASS';report.stage=state.stage;report.climb=state.report.climb;report.stairs=state.report.stairs;report.priorTablesPreserved=true;report.resumeScene=options.scene
  D.Content:save(D.Path(root,'Test/roof-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
