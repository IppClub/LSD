local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/male-current-roof-aftermath-exit-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-roof-aftermath-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-roof%-aftermath%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-male-current-roof-aftermath-exit-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.roof and w.roof.phase=='ready'end,30)
  local c=D.Platformer.Data.store.world.roof;assert(c.aftermathComplete and c.vortex.active and not c.wuyun.visible and not c.world.storyFlow);report.noReplay=true
  D.sleep(.1);assert(c.label.text:find('返回控制舱，离开工厂。',1,true),'Stale roof objective');report.exitHint=c.label.text
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-roof-exit-hint.tga'))
  c.back:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.controlPod and w.controlPod.phase=='ready'end,30)
  local pod=D.Platformer.Data.store.world.controlPod;assert(pod.aftermathComplete);D.sleep(.2)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-roof-aftermath-control-pod.tga'))
  pod.leave:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,30)
  local w=D.Platformer.Data.store.world;assert(w.infiltration.wuyunGone)
  assert(not D.Group({'name','unit'}):find(function(e)return e.name=='wuyun'and e.unit.world==w end),'Wuyun reappeared')
  report.wuyunAbsent=true;w.infiltration.menu:emit('Tapped',2)
  wait(function()local n=D.Platformer.Data.store.world;return n and n~=w and n.tag=='OperationRoom' end,30)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-roof-exit-operation.tga'))
  report.returnedToOperation=true
  for name,value in pairs(snapshot)do if name~='Game0Roof'and name~='Game0ControlPod'and name~='Game0Infiltration'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Exit changed '..name)end end
  D.Content:save(D.Path(root,'Test/male-current-roof-exit-resume-fixture.txt'),db)
  report.priorTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
