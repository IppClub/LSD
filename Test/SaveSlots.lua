local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local out=D.Path(root,'Test/save-slots-result.json');local report={status='RUNNING',runId=run};D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  assert(not D.DB:existDB('lsd'))
  local directory=D.Path(D.Content.writablePath,'lsd-slots-qa-'..run);assert(not D.Content:exist(directory));assert(D.Content:mkdir(directory));report.directory=directory
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-ending-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-ending%-flow%-qa%-%d+%.db$'))
  local legacy=D.Path(directory,'lsd.db');assert(D.Content:copyAsync(source,legacy));local original=D.Content:load(legacy)
  local store=require('Save.Slots').new(directory);assert(store:current()=='lsd.db')
  assert(not store:attach('../lsd.db'));assert(not store:attach('lsd-journey-1-1.db'))
  assert(store:attach('lsd.db'));assert(D.DB:query("SELECT id FROM lsd.Game0StoryNodes WHERE id='final-betrayal'")[1]);assert(not store:create());D.DB:exec('DETACH DATABASE lsd')
  local first=assert(store:create());assert(first~='lsd.db');assert(#D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table'")==0);D.DB:exec('DETACH DATABASE lsd')
  local second=assert(store:create());assert(first~=second);D.DB:exec('DETACH DATABASE lsd');assert(store:current()==second)
  local bad='lsd-journey-1-1.db';assert(D.Content:save(D.Path(directory,bad),'not a database'));assert(not store:attach(bad));assert(not D.DB:existDB('lsd')and store:current()==second)
  assert(store:attach('lsd.db'));D.DB:exec('DETACH DATABASE lsd');assert(D.Content:load(legacy)==original)
  report.legacyPreserved=true;report.uniqueNewSaves=true;report.corruptRejected=true;report.pointerPreservedOnFailure=true
  local c=require('Save.Title').open({store=store,onOpen=function(name)report.mouseSelected=name end})
  report.awaitingMouse=true;D.Content:save(out,D.json.encode(report))
  local deadline=D.App.runningTime+120;while not report.mouseSelected do assert(D.App.runningTime<deadline,'Mouse new journey required');D.sleep(.05)end
  assert(report.mouseSelected~='lsd.db'and report.mouseSelected~=first and report.mouseSelected~=second)
  assert(#D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table'")==0);D.DB:exec('DETACH DATABASE lsd');assert(D.Content:load(legacy)==original)
  report.osNewJourney=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
