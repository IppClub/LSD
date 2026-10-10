local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/roof-resume-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-resume-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.roof and w.roof.phase=='ready'end,30)
  local c=D.Platformer.Data.store.world.roof;D.sleep(1);assert(c.stage==2 and not c.lastClimb and not c.lastStairs and c:landingCollision(c.player));report.noReplay=true
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-resume-landed.tga'))
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume changed '..name)end;report.allTablesPreserved=true
  c.world:removeFromParent();D.Platformer.Data.store:clear();assert(D.DB:exec('UPDATE lsd.Game0Roof SET schemaVersion=99 WHERE id=1')>=0)
  local future=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Roof ORDER BY 1'),false,true)
  package.loaded.Start=nil;require('Start');wait(function()return D.Director.ui3D:getChildByTag('resume-problem')~=nil end,20)
  assert(not D.Platformer.Data.store.world,'Future save silently fell back to another scene');assert(future==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0Roof ORDER BY 1'),false,true));report.futureVersionBlocked=true
  D.Director.ui3D:removeAllChildren();assert(D.DB:exec('UPDATE lsd.Game0Roof SET schemaVersion=1 WHERE id=1')>=0);package.loaded.Start=nil;require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.roof and w.roof.phase=='ready'end,30)
  report.status='PASS';report.stage=2
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
