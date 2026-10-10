local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING'};local out=root..'/Test/pursuit-stamina-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local c=require('Ruins.PursuitLevel').openAsync({finishAsync=function()return true end},{mission='c0-m06'});local b=c.battle
  local function wait(f)local deadline=D.App.runningTime+10;while not f()do assert(D.App.runningTime<deadline);D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  wait(function()return b.mentor.onSurface end);b.mentorHP=10000
  local e=b.enemies[1];e.unit.position=D.Vec2(7800,b.world.offset+155);b.mentor.position=D.Vec2(7980,b.world.offset+155);D.sleep(.2)
  assert(b:enemyStrike(e,require('Ruins.Pursuit').attackSpecs.dashanxiao[2]))
  wait(function()return b.stamina.down end);local record=b.stamina.records[1]
  assert(b.stamina.value==0 and b.stamina.knockdowns==1)
  for _,command in ipairs({'left','right','shoot','smoke','flare'})do local ok,why=b:command(command);assert(not ok and why=='KNOCKED_DOWN')end
  b.stamina:hit(100);assert(b.stamina.knockdowns==1)
  D.App.winSize=D.Size(683,384);D.sleep(.1);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/pursuit-stamina-down.tga')
  wait(function()return not e.busy end);e.nextAttack=math.huge
  wait(function()return not b.stamina.down end)
  assert(record.completed and #record.stages==2 and record.stages[1].name=='fall' and record.stages[2].name=='standUp')
  local total=record.stages[1].duration+record.stages[2].duration
  assert(record.completed-record.started>=total-.03 and b.stamina.value>=40)
  local hud=D.Director.ui3D:getChildByTag('pursuit-hud');hud.move:emit('Right',true);D.sleep(.1);assert(b.mentor.velocityX>0);hud.move:emit('Right',false)
  local recovered=b.stamina.value;D.sleep(3);assert(b.stamina.value>recovered)
  r.record=record;r.recoveredControl=true;r.regenerated=true
  b.stamina:hit(100);assert(b.stamina.down);b:finish('aborted','QA');D.sleep(.2)
  assert(not b.stamina.down and b.stamina.records[2].cancelled and not b.stamina.records[2].completed);r.cancelled=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
