local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-reconnection-resume-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-reconnection-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-reconnection%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-reconnection-resume-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='RDRoom' and w.reconnection end,40)
  local w=D.Platformer.Data.store.world;assert(not w.storyFlow and not w.commandAssembly)
  local facts=assert(require('Story.Service').open()):summary();assert(facts.completed['return-online'] and facts.completed['network-warning'])
  assert(not D.Group({'name','unit'}):find(function(e)return e.name=='wuyun' and e.unit.world==w end))
  report.scene=w.tag;report.noReplay=true;report.wuyunAbsent=true;report.sameProcessOnly=true
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Departure changed '..name)end
  report.allTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
