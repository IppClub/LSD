local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Font'),D.Path(root,'Image')})do D.Content:insertSearchPath(1,p)end
local result={status='RUNNING',runId=tostring(os.time()),osInput=false};local out=D.Path(root,'Test/fresh-jade-arrival-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-academy-loss-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-academy%-loss%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-jade-arrival-qa-'..result.runId..'.db');result.source=source;result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Jade arrival timeout');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='PassageA'and w.academyLoss end,40);local service=assert(require('Story.Service').open());local nav=require('Academy.Navigation')
  local lossRow=assert(D.DB:query("SELECT completedAt FROM lsd.Game0StoryNodes WHERE id='academy-loss'")[1])
  assert(D.DB:exec("DELETE FROM lsd.Game0StoryNodes WHERE id='academy-loss'")>=0);local allowed,why=service:canRead('jade-arrival','RDRoom');assert(not allowed and why=='STORY_LOCKED');assert(D.DB:exec("INSERT INTO lsd.Game0StoryNodes VALUES ('academy-loss',?)",{lossRow[1]})>=0);result.prerequisiteRejected=true
  assert(not service:canRead('jade-arrival','PassageA'));assert(not service:completeAsync('jade-arrival','RDRoom',false,{}))
  local function world()return D.Platformer.Data.store.world end
  local function player()return assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end))end
  local function move(x)
   local p=player();local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
   if math.abs(p.unit.x-x)>25 then
    local side=p.unit.x<x and 'Right'or'Left';hud.move:emit(side,true)
    wait(function()return math.abs(p.unit.x-x)<25 end,45);hud.move:emit(side,false)
   end;D.sleep(.3)
  end
  local function door(side,target)
   local old=world();move(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=player();local index;assert(p.moveTargets)
   for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled);p.interaction:emit('Tapped',index)
   wait(function()return world()~=old and world().tag==target end,15);D.sleep(.3)
  end
  door('center','PassageC');door('center','PassageD');door('right','RDRoom');result.physicalRoute={'PassageA','PassageC','PassageD','RDRoom'}
  local w=world();local c=assert(w.jadeArrival);wait(function()return c.phase=='ready'end,20)
  assert(not c:request());local p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end));local hud
  D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  hud.move:emit('Right',true);wait(function()return p.unit.x>4400 end,30);D.sleep(1);hud.move:emit('Right',false);D.sleep(.2)
  assert(p.unit.x>4300 and p.unit.x<4520,'Solid barrier did not stop actual movement');result.blockedX=p.unit.x
  hud.move:emit('Left',true);wait(function()return p.unit.x<c.marker.x+30 end,10);hud.move:emit('Left',false);D.sleep(.3)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_jade BEFORE INSERT ON Game0StoryPerformances WHEN NEW.node='jade-arrival' BEGIN SELECT RAISE(FAIL,'QA jade'); END")>=0)
  c.menu:emit('Tapped',1);wait(function()return w.storyFlow~=nil end,20);local flow=w.storyFlow
  local function advance(f)
   wait(function()return f.view.visible end,20);local deadline=D.App.runningTime+60
   while f.phase=='dialogue'or f.phase=='saving'do assert(D.App.runningTime<deadline);if f.view.visible and not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end
  end
  advance(flow);assert(flow.phase=='save-error'and #flow.view._reviews==12);assert(not service:summary().completed['jade-arrival']and not service:summary().unlocks['jade-met'])
  assert(not c.barrier and c.report.twinsProtected);assert(D.DB:exec('DROP TRIGGER lsd.fail_jade')>=0);flow.retryButton:emit('Tapped');wait(function()return flow.phase=='complete'end,20);result.saveRetry=true
  result.proof=c.report;assert(require('Rescue.ArrivalProof').validate(c.report));assert(not service:summary().mission.unlocks['twins-rescued'])
  hud.move:emit('Right',true);wait(function()return p.unit.x>4670 end,10);hud.move:emit('Right',false);result.crossedX=p.unit.x
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true)
  local replay=assert(require('Story.Flow').openAsync('jade-arrival',w,nil,true));advance(replay);assert(replay.phase=='complete'and #replay.view._reviews==12 and before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true));result.replayUnchanged=true
  local roster=assert(require('Story.AcademyLossRecords').saved());for _,r in ipairs(roster)do if r.role=='vika'or r.role=='vivi'then assert(r.status=='awaiting-rescue')end end
  package.loaded['Start']=nil;require('Start');wait(function()local n=D.Platformer.Data.store.world;return n~=w and n.jadeArrival and n.jadeArrival.phase=='ready'end,30)
  w=D.Platformer.Data.store.world;c=w.jadeArrival;assert(w.tag=='RDRoom'and c.recorded and not c.barrier and not w.storyFlow)
  assert(c.yu.model.parent and c.twins[1].model.parent and c.twins[2].model.parent);D.sleep(3)
  assert(c.carrier.phase=='riding' and c.carrier.robot.state=='guard' and c.carrier.robot.opacity>.99 and c.carrier.robot.parent)
  result.buddhaGuardVisible=true
  assert((c.yu.completed.ride or 0)>0 and (c.twins[1].completed.idle or 0)>0 and (c.twins[2].completed.idle or 0)>0)
  p=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end));D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
  hud.move:emit('Right',true);wait(function()return p.unit.x>3900 end,10);hud.move:emit('Right',false);D.sleep(1)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-jade-arrival-restored.tga'));D.sleep(.2)
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.priorTablesPreserved=true;result.restored=true;result.status='PASS';D.Content:save(D.Path(root,'Test/fresh-jade-arrival-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
