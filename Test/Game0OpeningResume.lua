-- Resume a copy of the newly played opening without altering its earned checkpoint.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local out=D.Path(root,'Test/game0-opening-resume-result.json')
local report={status='RUNNING',runId=run,osInput=false,coldProcess=false}
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/journey-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-game0%-journey%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-opening-resume-qa-'..run..'.db')
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Config ORDER BY name'),false,true)
  require('Start')
  local deadline=D.App.runningTime+30
  while true do
   local w=D.Platformer.Data.store.world
   if w and w.tag=='PreparationRoom' and w.data.navigationAttached then
    local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
    if p and not p.busy then break end
   end
   assert(D.App.runningTime<deadline,'Completed opening replayed or failed to resume');D.sleep(.05)
  end
  local c=require('Data.Config')
  assert(c.charName=='JourneyQA' and c.char=='charF' and c.skipOP==1 and (c.tutorialCompleted==true or c.tutorialCompleted==1))
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Config ORDER BY name'),false,true),'Resume changed identity/config')
  report.status='PASS';report.source=source;report.database=db;report.academyResumed=true;report.identityPreserved=true;report.configUnchanged=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
