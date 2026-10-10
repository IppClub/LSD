local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/academy-move-response-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-aftermath-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-aftermath%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-move-response-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Data.Config'):loadAsync()
  local service=assert(require('Story.Service').open());local nav=require('Academy.Navigation')
  local w=nav.returnToOperationAsync();assert(w.reconnection and not w.commandAssembly)
  local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end))
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  local originalSpeed=p.unit.unitDef.move;assert(originalSpeed==300)
  local function pulse(key)hud.move:emit(key,true);D.sleep();hud.move:emit(key,false);D.sleep(.12)end
  local start=p.unit.x;for i=1,20 do pulse('Left')end;report.shortLeft=start-p.unit.x;assert(report.shortLeft>30 and report.shortLeft<150)
  start=p.unit.x;for i=1,20 do pulse('Right')end;report.shortRight=p.unit.x-start;assert(report.shortRight>30 and report.shortRight<150)
  D.sleep(.3);start=p.unit.x;D.sleep(.5);report.idleDrift=math.abs(p.unit.x-start);assert(report.idleDrift<.05)
  local startTime=D.App.runningTime;start=p.unit.x;hud.move:emit('Left',true);D.sleep(1);hud.move:emit('Left',false);D.sleep(.04)
  report.heldDistance=start-p.unit.x;report.heldSeconds=D.App.runningTime-startTime;assert(report.heldDistance>260 and report.heldDistance<330)
  D.sleep(.3);start=p.unit.x;D.sleep(.5);assert(math.abs(p.unit.x-start)<.05)
  assert(p.unit.unitDef.move==originalSpeed);report.moveSpeed=originalSpeed
  local fox=require('Story.FoxCompanion');assert(fox.walkSpeed==240);local m=fox.createAnimated();assert(m.walkAnimationSpeed==1.2);m:cleanup();report.foxUnchanged=true
  report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
