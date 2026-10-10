local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/auxiliary-selection-resume-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/auxiliary-selection-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-auxiliary%-selection%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-auxiliary-selection-resume-qa-'..run..'.db');result.source=source;result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Selection resume timeout');D.sleep(.03)end end
  require('Start');wait(function()return D.Platformer.Data.store.world~=nil end,30)
  assert(require('Ground.AuxiliarySelection').open():load().variant=='mobility')
  local w=require('Academy.Navigation').returnToRoomAsync('TrainA')
  local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end));local hud
  D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  hud.move:emit('Right',true);wait(function()return p.unit.x>w.sceneWidth-200 end,15);hud.move:emit('Right',false);D.sleep(.3)
  w:getChildByTag('groundDeploymentTerminal'):emit('Tapped',1);wait(function()return w.groundDeployment end,15)
  local c=w.groundDeployment;assert(c.auxiliaryVariant=='mobility'and c.auxiliaryRecorded and c.phase=='briefing')
  for name,value in pairs(snapshots)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  result.status='PASS';result.allTablesPreserved=true;result.variant=c.auxiliaryVariant;result.publicTrainGate=true
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/auxiliary-selection-cold.tga'));D.sleep(.2)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
