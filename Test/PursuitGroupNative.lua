local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING',actors={}};local out=root..'/Test/pursuit-group-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit');local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
  local function wait(f)local deadline=D.App.runningTime+8;while not f()do assert(D.App.runningTime<deadline,'Timeout');D.sleep(.01)end end
  for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
  local e=b.enemies[1];b.mentor.position=D.Vec2(9000,b.world.offset+155);e.unit.position=D.Vec2(7520,b.world.offset+155)
  local hold=D.Node();hold:addTo(b.world);hold:schedule(function()for i,escort in ipairs(b.escorts)do escort.unit.position=D.Vec2(7520+(i-2.5)*75,b.world.offset+155)end;return false end)
  D.sleep(.25);assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[2]));local strike=e.strikes[#e.strikes]
  wait(function()return #strike.impacts==3 end)
  assert(strike.hits==12 and b.mentorHP==100,'Area damage not per target')
  for _,escort in ipairs(b.escorts)do
   assert(escort.hp==76)
   if escort.stamina then assert(escort.stamina.down and escort.stamina.value==0)end
  end
  hold:removeFromParent();wait(function()return not e.busy end);e.nextAttack=math.huge
  for _,escort in ipairs(b.escorts)do
   if escort.stamina then
    wait(function()return not escort.stamina.down end)
    local record=escort.stamina.records[1];assert(record.completed and #record.stages==2)
    local x=escort.unit.x;D.sleep(.2);assert(escort.unit.x<x,'Escort did not resume evacuation')
    r.actors[escort.name]={hp=escort.hp,knockdowns=escort.stamina.knockdowns,seconds=record.completed-record.started}
   else r.actors[escort.name]={hp=escort.hp,missingKnockdownAnimation=true}end
  end
  local victim=b.escorts[3];victim.hp=5
  local hold2=D.Node();hold2:addTo(b.world);hold2:schedule(function()victim.unit.position=D.Vec2(e.unit.x-150,b.world.offset+155);return false end)
  D.sleep(.1);assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[2]));local lethal=e.strikes[#e.strikes]
  wait(function()return b.phase=='failed'end);hold2:removeFromParent()
  assert(victim.hp==0 and b.report.escortHP[victim.name]==0 and b.mentorHP==100,'Escort loss not recorded')
  local hits=lethal.hits;D.sleep(1);assert(lethal.hits==hits and lethal.cancelled,'Damage after failure')
  r.groupHits=strike.hits;r.escortFailure=true;r.noDelayedDamage=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
