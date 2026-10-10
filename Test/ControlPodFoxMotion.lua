-- Loads the last earned control-pod checkpoint in a QA copy without replaying travel or audio.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/control-pod-fox-motion-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/control-pod-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and (D.Path:getFilename(source):match('^lsd%-control%-pod%-route%-qa%-%d+%.db$')or D.Path:getFilename(source):match('^lsd%-control%-pod%-mouse%-qa%-%d+%.db$')))
  local db=D.Path(D.Content.writablePath,'lsd-control-pod-fox-motion-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local store=assert(require('Story.ControlPodStore').open());local before=assert(store:load());assert(before.active)
  require('Start');local deadline=D.App.runningTime+40
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.controlPod and D.Platformer.Data.store.world.controlPod.phase=='ready')do assert(D.App.runningTime<deadline,'Control pod resume stalled');D.sleep(.03)end
  local c=D.Platformer.Data.store.world.controlPod
  assert(c.floor==before.floor and c.state.doorOpen==before.doorOpen and not c.sound and not c.lastTraversal and not c.lastDoor)
  if before.doorOpen then assert(not c.barrier and math.abs(c.art.door.angleY+105)<.1)else assert(c.barrier)end
  local m=c.fox.model;assert(m.motionVariant=='spine-corrected');assert(require('Story.FoxCompanion').walkSpeed==240)
  local movementStartX=m.x;local movementStartTime=D.App.runningTime
  local loops={idle=0,fmove=0};local ends={idle={},fmove={}};m:slot('AnimationEnd',function(name)if loops[name]then loops[name]=loops[name]+1;table.insert(ends[name],D.App.runningTime)end end)
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Fox motion timed out');D.sleep(.02)end end
  c.hud.move:emit('Right',true);D.sleep(3)
  assert(c.fox.animation=='fmove' and m.fliped==true,'Right travel missing');report.right=true
  assert(#ends.fmove>=2,'Walking never completed two native loops')
  report.walkLoopSeconds=ends.fmove[2]-ends.fmove[1]
  report.animationSpeed=m.speed;assert(math.abs(m.speed-.85)<.001,'Animation pace override missing')
  report.movedDistance=m.x-movementStartX;assert(report.movedDistance>350,'Follow movement still slowed')
  assert(math.abs(report.walkLoopSeconds-1/m.speed)<.06,'Walking loop cut short')
  c.hud.move:emit('Right',false)
  wait(function()return c.fox.animation=='idle'end,10);assert(m.speed==1 and math.abs(m.recovery-.2)<.001)
  c.hud.move:emit('Left',true);D.sleep(2)
  c.hud.move:emit('Left',false)
  wait(function()return c.fox.animation=='idle'end,10)
  -- After reversing, followers move right to their new trailing position.
  -- Walk left long enough that the whole party subsequently travels left.
  c.hud.move:emit('Left',true);wait(function()return c.fox.animation=='fmove' and m.fliped==false end,2)
  assert(c.fox.animation=='fmove' and m.fliped==false,'Left travel missing');report.left=true
  c.hud.move:emit('Left',false);wait(function()return c.fox.animation=='idle'end,10)
  assert(m.fliped==false and m.speed==1 and math.abs(m.recovery-.2)<.001,'Idle facing or recovery changed')
  local stopped=m.x;local idleBefore=loops.idle
  wait(function()return loops.idle>=idleBefore+2 end,12)
  report.stoppedX=stopped;report.finalX=m.x;report.finalState=c.fox.animation;report.idleLoopSeconds=ends.idle[#ends.idle]-ends.idle[#ends.idle-1]
  assert(math.abs(m.x-stopped)<.01 and loops.fmove>0,'Idle drift or no complete walk loop')
  report.idleLoopSeconds=ends.idle[#ends.idle]-ends.idle[#ends.idle-1];assert(math.abs(report.idleLoopSeconds-2)<.08,'Idle loop cut short')
  report.nativeLoops=loops;report.idleRecovery=.2;report.noIdleDrift=true;report.followersFinishAfterRelease=true
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.status='PASS';report.floor=c.floor;report.doorOpen=c.state.doorOpen;report.noReplay=true;report.allTablesPreserved=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
