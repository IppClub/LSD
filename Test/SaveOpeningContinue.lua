-- Resume a copy of the newly played opening without altering its earned checkpoint.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local out=D.Path(root,'Test/save-opening-continue-result.json')
local report={status='RUNNING',runId=run,osInput=false,coldProcess=false}
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/save-opening-resume-fixture.txt')))
  local directory=D.Path:getPath(source);assert(directory:match('lsd%-title%-opening%-qa%-%d+$')and D.Path:getFilename(source):match('^lsd%-journey%-%d+%-%d+%.db$'))
  local store=require('Save.Slots').new(directory);assert(store:current()==D.Path:getFilename(source))
  assert(store:attach(store:current()))
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Config ORDER BY name'),false,true)
  D.DB:exec('DETACH DATABASE lsd')
  local title=require('Save.Title').open({store=store});title.continue:emit('Tapped')
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
  report.status='PASS';report.source=source;report.database=source;report.academyResumed=true;report.identityPreserved=true;report.configUnchanged=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
