local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/male-current-jade-distance-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-twins-evacuation-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-twins%-evacuation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-male-current-jade-distance-qa-'..run..'.db');result.source=source;result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Jade distance timeout');D.sleep(.02)end end
  require('Data.Config'):loadAsync();local service=assert(require('Story.Service').open())
  assert(not service:canRead('jade-distance','PassageA'));assert(not service:completeAsync('jade-distance','RDRoom',false,{}));result.invalidEntryRejected=true
  require('Start');wait(function()local n=D.Platformer.Data.store.world;return n and n.tag=='RDRoom'and n.jadeArrival end,40);local w=D.Platformer.Data.store.world;wait(function()return w.jadeArrival and w.jadeArrival.phase=='ready'end,20);local c=w.jadeArrival
  assert(c.marker.tag=='jade-distance-ready'and c.marker.x==4650 and not c:request())
  local function approach(world)
   local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end));local hud
   D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   hud.move:emit('Right',true);wait(function()return p.unit.x>4530 end,10);hud.move:emit('Right',false);D.sleep(.2)
  end
  local function advance(f)
   wait(function()return f.view.visible end,20);local deadline=D.App.runningTime+50
   while f.phase=='dialogue'or f.phase=='saving'do
    assert(D.App.runningTime<deadline)
    if f.view.visible and not f.view._advancing then
     local id=f.view._dialog.character;result.portraits=result.portraits or {}
     if id and id~=''then
      local portrait=assert(f.view.figure.children.first,'Missing portrait for '..id);local kind=id=='yu'and 'illustration'or 'spine';assert(portrait.tag=='story-portrait:'..kind..':'..id,'Stale speaker portrait')
      if not result.portraits[id]then
       result.portraits[id]=kind;D.sleep(.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-jade-dialogue-'..id..'.tga'));D.sleep(.2)
      end
     else assert(f.view.figure.children.count==0,'Previous speaker portrait remained on a call')end
     f.view.confirm:emit('Tapped')
    end
    D.sleep(.08)
   end
  end
  approach(w)
  c.menu:emit('Tapped',1);wait(function()return w.storyFlow and w.storyFlow.id=='jade-distance'end,15);local f=w.storyFlow;advance(f)
  assert(f.phase=='complete'and #f.view._reviews==8);assert(service:summary().completed['jade-distance'])
  result.proof=w.jadeDistance.report;assert(require('Rescue.DistanceProof').validate(result.proof));assert(service:summary().unlocks['evacuation-window']);result.saveFaultInjected=false
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true)
  local replay=assert(c:request(1));advance(replay);assert(replay.phase=='complete'and #replay.view._reviews==8)
  local initial=assert(c:request(2));advance(initial);assert(initial.phase=='complete'and #initial.view._reviews==12 and not c.barrier and not c.ward.active)
  assert(c.label.text:find('有限的撤离窗口',1,true),'Old replay overwrote current story hint')
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true));result.bothReplaysUnchanged=true
  package.loaded['Start']=nil;require('Start');wait(function()local world=D.Platformer.Data.store.world;return world~=w and world.jadeArrival and world.jadeArrival.phase=='ready'end,30)
  w=D.Platformer.Data.store.world;assert(w.tag=='RDRoom'and not w.storyFlow and w.jadeArrival.marker.x==4650);approach(w)
  assert(service:summary().objective:find('有限的撤离窗口',1,true));result.restored=true
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-jade-distance-restored.tga'));D.sleep(.2)
  for name,value in pairs(snapshots)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  for _,id in ipairs({'yu',require('Data.Config').char,'ninilite','vika','vivi'})do assert(result.portraits[id],'Speaker not covered: '..id)end
  result.priorTablesPreserved=true;result.status='PASS';D.Content:save(D.Path(root,'Test/male-current-jade-distance-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
