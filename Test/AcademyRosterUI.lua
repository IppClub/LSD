local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local result={status='RUNNING',runId=tostring(os.time()),osInput=false};local out=D.Path(root,'Test/academy-roster-ui-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-twins-evacuation-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-twins%-evacuation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-roster-ui-qa-'..result.runId..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Data.Config'):loadAsync()
  require('Academy.Navigation').returnToRoomAsync('PassageA')
  local function world()return D.Platformer.Data.store.world end
  local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end)end
  local function wait(f)local untilTime=D.App.runningTime+30;while not f()do assert(D.App.runningTime<untilTime,'Roster UI wait timed out');D.sleep(.03)end end
  local function move(x)
   wait(function()return player()and not player().busy end)
   local p=player();local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   local side=p.unit.x>x and 'Left'or'Right';hud.move:emit(side,true)
   wait(function()return math.abs(p.unit.x-x)<40 end);hud.move:emit(side,false);D.sleep(.3)
  end
  local w=world();move(w.academyLoss.marker.x)
  assert(w.academyLoss.menu.visible);w.academyLoss.menu:emit('Tapped',1)
  wait(function()return w.academyLoss.record end)
  local function page(n)
   local v=w.academyLoss.record;assert(v.detail.text:find('双子已获救',1,true))
   D.sleep(.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-roster-rescued-page-'..n..'.tga'));D.sleep(.15)
  end
  page(1);w.academyLoss.record.nextButton:emit('Tapped');page(2)
  w.academyLoss.record.archiveButton:emit('Tapped');assert(w.academyLoss.record.detail.text:find('烛参',1,true));page('twin')
  w.academyLoss.record.nextButton:emit('Tapped');page(3)
  w.academyLoss.record.closeButton:emit('Tapped');assert(not w.data.journalOpen)
  move(120);local p=player();local index
  assert(p.moveTargets);for i=1,p.moveTargets.count do if p.moveTargets:get(i)=='RestRoom'then index=i end end
  assert(index and p.interaction.menu.enabled);p.interaction:emit('Tapped',index)
  wait(function()return world()~=w and world().tag=='RestRoom'end)
  D.sleep(.8);local rest=world();assert(rest.academyLoss.recorded and rest.academyLoss.damageNode.children.count==12)
  assert(not require('System.Music').inspect().playing,'Normal academy theme played after catastrophe')
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-roster-rest-route.tga'))
  result.rescuedFooter=true;result.physicalDoor=true;result.damagePersists=true;result.noNormalMusic=true
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  result.allTablesPreserved=true;result.noReplay=true;result.status='PASS'
  world().academyLoss:showRecord()
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
