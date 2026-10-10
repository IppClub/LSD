-- Real controls and original dialogue on an independently earned patrol checkpoint.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/infiltration-path-result.txt');D.Content:save(out,'LSD_INFILTRATION_PATH_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/infiltration-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-infiltration%-mid%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-infiltration-path-qa-'..id..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local function wait(fn,t,msg)local deadline=D.App.runningTime+(t or 20);while not fn()do assert(D.App.runningTime<deadline,msg or 'Path stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local r=w.infiltration;local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end)
  assert(not assert(require('Story.Service').open()):canRead('infiltration-researcher-scout','Factory'),'Researcher bypassed physical path')
  r.menu:emit('Tapped',1);wait(function()return w.storyFlow and w.storyFlow.id=='infiltration-fox-guide'and w.storyFlow.view.visible end)
  local flow=w.storyFlow;while flow.phase~='complete'do if not flow.view._advancing then flow.view.confirm:emit('Tapped')end;D.sleep(.08)end
  wait(function()return r.path and r.path.phase=='walking'end,20);local c=r.path;assert(#flow.view._reviews==1 and #c.guards==3 and #c.covers==3)
  local mid=D.Path(D.Content.writablePath,'lsd-infiltration-path-mid-qa-'..id..'.db');assert(D.Content:copyAsync(db,mid));D.Content:save(D.Path(root,'Test/infiltration-path-mid-fixture.txt'),mid)
  assert(not c.store:writeAsync('complete',{x=4100}),'Completion accepted without physical path')
  local function move(x)
   p.keyLeft=p.unit.x>x;p.keyRight=p.unit.x<x
   wait(function()return math.abs(p.unit.x-x)<18 end,8,'Physical movement stalled at '..p.unit.x)
   p.keyLeft=false;p.keyRight=false;p.unit:stop();p.unit.velocityX=0;D.sleep(.06)
  end
  -- Prove actual patrol detection, not just a success-only path.
  local g=c.guards[1];wait(function()return g.sign==-1 and g.unit.x>2600 and g.unit.x<2750 end,15)
  local alerts=c.alerts;p.keyRight=true;wait(function()return c.alerts>alerts end,8,'Patrol did not detect exposed mentor');p.keyRight=false;assert(math.abs(p.unit.x-2200)<80 and not c.store:load().completed)
  for i,v in ipairs(c.covers)do
   if i==1 then wait(function()return c.guards[1].sign==1 and c.guards[1].unit.x>2700 end,15)
   else wait(function()return c.guards[i-1].sign==-1 and c.guards[i-1].unit.x<c.covers[i-1].x-35 and c.guards[i].sign==1 and c.guards[i].unit.x>v.x+35 end,15)end
   local before=c.alerts;move(v.x);assert(c.alerts==before,'Patrol detected safe crossing '..i)
   local center;c.action:convertToWindowSpace(D.Vec2(c.action.width*.5,c.action.height*.5),function(point)center=point end);wait(function()return center end,2)
   assert(center.x>0 and center.x<D.App.bufferSize.width and center.y>0 and center.y<D.App.bufferSize.height,'Action button is outside viewport')
   c.action:emit('TapBegan');assert(c.hidden and p.busy,'Original action did not hide');D.sleep(.55)
   D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-03/infiltration-cover-'..i..'.tga'))
   if i<3 then wait(function()return c.guards[i].sign==-1 and c.guards[i].unit.x<v.x-35 and c.guards[i+1].sign==1 and c.guards[i+1].unit.x>c.covers[i+1].x+35 end,15)
   else wait(function()return c.guards[i].sign==-1 and c.guards[i].unit.x<v.x-35 end,15)end
   c.action:emit('TapBegan');assert(not c.hidden and not p.busy)
  end
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_fox_path BEFORE UPDATE OF completed ON Game0InfiltrationPath WHEN NEW.completed=1 BEGIN SELECT RAISE(ABORT,'QA path');END")>=0)
  move(4100);wait(function()return c.error=='SAVE_FAILED'end,10);assert(not c.store:load().completed)
  D.DB:exec('DROP TRIGGER lsd.fail_fox_path');wait(function()return c.phase=='complete'and r.pathCompleted end,10);assert(not r.error and not c.error,'Saved path still shows failure')
  local saved=c.store:load();assert(saved.report.travelled>=1500 and #saved.report.covers==3 and saved.report.alerts>=1)
  local before=D.json.encode(saved.report,false,true);assert(c.store:writeAsync('complete',saved.report));assert(before==D.json.encode(c.store:load().report,false,true))
  r.menu:emit('Tapped',1);wait(function()return w.storyFlow and w.storyFlow.id=='infiltration-researcher-scout'and w.storyFlow.view.visible end)
  flow=w.storyFlow;while flow.phase~='complete'do if not flow.view._advancing then flow.view.confirm:emit('Tapped')end;D.sleep(.08)end;assert(#flow.view._reviews==2)
  D.Content:save(D.Path(root,'Test/infiltration-path-resume-fixture.txt'),db)
  return 'PASS actualStart=true originalRows3=true physicalPatrolDetection=true realMovement=true threeActionCovers=true actualFoxGait=true saveFailureRetry=true noRepeatCompletion=true safePathCheckpoint=true researcherStillNotCaught=true'
 end,debug.traceback)
 local report='LSD_INFILTRATION_PATH_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
