-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','infiltration-mouse-result.txt');D.Content:save(out,'LSD_INFILTRATION_MOUSE_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-infiltration-mouse-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Mouse preparation stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.commandAssembly and w.commandAssembly.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local c=w.commandAssembly;local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
  p.keyLeft=true;wait(function()return math.abs(p.unit.x-c.center)<100 end);p.keyLeft=false;D.sleep(.4)
  D.Director.entry.infiltrationMouseQA={before=snapshot,database=db,runId=id}
  return 'READY actualAssemblyCenter=true actualMouseEntryAndLensAndBattleRequired=true noAutomaticPass=true'

 end,debug.traceback)
 local report='LSD_INFILTRATION_MOUSE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
