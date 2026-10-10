local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/reconnection-mouse-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-aftermath-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-aftermath%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-reconnection-mouse-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Data.Config'):loadAsync()
  local service=assert(require('Story.Service').open());local nav=require('Academy.Navigation')
  local w=nav.returnToOperationAsync();assert(w.reconnection and not w.commandAssembly)
  wait(function()return w.storyFlow and w.storyFlow.view.visible end,900)
  local f=w.storyFlow;assert(f.id=='return-online');wait(function()return f.phase=='complete'end,900)
  assert(#f.view._reviews==16 and service:summary().completed['return-online']);report.rows=16;report.actualInputOnly=true
  assert(not D.Group({'name','unit'}):find(function(e)return e.name=='wuyun'and e.unit.world==w end))
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/reconnection-os-complete.tga'))
  report.status='PASS';D.Content:save(D.Path(root,'Test/reconnection-mouse-fixture.txt'),db)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
