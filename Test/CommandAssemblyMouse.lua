-- The preparation thread stops before any report click; CUA supplies actual mouse input.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','command-assembly-mouse-result.txt');D.Content:save(out,'LSD_COMMAND_MOUSE_PREPARING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','fox-trail-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fox%-trail%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-command-mouse-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20);while not f() do assert(D.App.runningTime<deadline,'Mouse setup stalled');D.sleep(.03) end end
  local before={}
  for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")) do
   if row[1]~='Game0StoryNodes' and row[1]~='Game0StoryUnlocks' and row[1]~='Game0StoryAssignments' then before[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.commandAssembly and w.commandAssembly.phase=='ready' end,40)
  local w=D.Platformer.Data.store.world;local c=w.commandAssembly;local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
  wait(function()p.keyLeft=p.unit.x>c.center+20;p.keyRight=p.unit.x<c.center-20;return math.abs(p.unit.x-c.center)<25 end);p.keyLeft=false;p.keyRight=false;p.unit:stop();p.unit.velocityX=0
  c.mouseQA={before=before,runId=id,database=db}
  wait(function()return c.menu.menu.enabled end);assert(not c.service:summary().completed['command-assembly'])
  return 'READY earnedFoxTrailCopy=true actualStart=true physicalCenter=true unrecordedReport=true mouseInputRequired=true'
 end,debug.traceback)
 local report='LSD_COMMAND_MOUSE_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
