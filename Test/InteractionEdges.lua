local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/interaction-edges-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-academy-loss-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-academy%-loss%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-interaction-edges-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Resume timeout');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='PassageA'and w.academyLoss end,40)
  local w=D.Platformer.Data.store.world
  local ni=assert(D.Group({'name','unit'}):find(function(e)return e.name=='ninilite'and e.unit.world==w end))
  wait(function()return ni.interaction and ni.interaction.menu.enabled end,10);D.sleep(1)
  local menu=ni.interaction
  local function check(node)
   local a,b;node:convertToWindowSpace(D.Vec2.zero,function(p)a=p end);node:convertToWindowSpace(D.Vec2(node.width,node.height),function(p)b=p end)
   wait(function()return a and b end,3)
   assert(math.min(a.x,b.x)>=14 and math.max(a.x,b.x)<=D.App.visualSize.width-14,'Clipped interaction bounds '..a.x..' '..b.x)
   return {left=a.x,right=b.x}
  end
  report.buttons=check(menu.menu);report.title=check(menu.screenBoundsTargets[2]);report.hint=check(w.academyLoss.hint)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/interaction-edge-fixed.tga'))
  report.awaitingMouse=true;D.Content:save(out,D.json.encode(report))
  wait(function()return w.data.storyBusy end,120)
  report.realMouseDialogue=true
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Departure changed '..name)end
  report.allTablesPreserved=true;report.status='PASS'
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
