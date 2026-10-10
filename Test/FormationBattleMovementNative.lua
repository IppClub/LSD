local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/formation-battle-movement-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local F=require('Combat.Formation');local A=require('Training.Arena');local K=require('Combat.Displacement')
  local plan=F.plan(1000,1600,{'wuyun','ninilite'},350,2000)
  assert(plan.wuyun==820 and plan.ninilite==640)
  local edge=F.plan(400,1600,{'wuyun','ninilite'},350,2000)
  assert(edge.wuyun==580 and edge.ninilite==760)
  local narrow=F.plan(400,1600,{'wuyun','ninilite'},350,500);assert(not narrow.wuyun and not narrow.ninilite)
  local ni=A.createAsync({scene='VRTraining',manualUpdate=true,minX=350,maxX=2000,actionPrefix='formationNi_'})
  local wu=A.createAsync({world=ni.world,manualUpdate=true,minX=350,maxX=2000,characterId='wuyun',actionPrefix='formationWu_'})
  ni.student.x=1050;wu.student.x=1060;D.sleep(.3)
  local deadline=D.App.totalTime+4
  while true do
   local n=F.step(ni,plan.ninilite);local w=F.step(wu,plan.wuyun)
   if n and w then break end
   assert(D.App.totalTime<deadline,'Regroup did not reach distinct slots');D.sleep(.02)
  end
  r.gap=math.abs(ni.student.x-wu.student.x);assert(r.gap>=F.spacing-2*F.tolerance)
  assert(ni.student.velocityX==0 and wu.student.velocityX==0)
  local x=ni.student.x;D.sleep(.3);assert(math.abs(ni.student.x-x)<2)
  assert(K.apply({unit=ni.student},480,1080,{}));local vx,vy=ni.student.velocityX,ni.student.velocityY
  assert(not F.step(ni,plan.ninilite));assert(ni.student.velocityX==vx and ni.student.velocityY==vy)
  r.displacementPreserved=true
  local landing=D.App.totalTime+9
  while K.blocked(ni.student) or not ni.student.onSurface do assert(D.App.totalTime<landing,'Launch never recovered');D.sleep(.02)end
  deadline=D.App.totalTime+5
  while not F.step(ni,plan.ninilite)do assert(D.App.totalTime<deadline,'Post-launch regroup stalled');D.sleep(.02)end
  r.regroupAfterLanding=true;F.stop(ni);F.stop(wu)
  -- Controlled real-UnitAction cases; not a formal mission or natural win.
  r.controlledBattleMovement=true;r.movementCases={}
  local battle={phase='playing',enemies={{enemy=ni.enemy,enemyHP=100}}}
  local function exercise(label,enemyX,delta,clip,face,velocity,hp)
   F.stop(ni);ni.student:stop();ni.student.x=1050;ni.student.velocityX=0
   ni.enemy.x=enemyX;ni.enemy.visible=true;ni.enemy.opacity=1;battle.enemies[1].enemyHP=hp or 100
   D.sleep(.15);assert(ni.student.onSurface)
   local destination=ni.student.x+delta;local started=D.App.totalTime
   while D.App.totalTime-started<.22 do F.step(ni,destination,battle);D.sleep(.02)end
   assert(ni.student:isDoing(ni.physical[clip]),label..' wrong movement action')
   assert(ni.student.faceRight==face,label..' wrong facing')
   assert(math.abs(ni.student.velocityX-velocity)<1,label..' wrong velocity '..ni.student.velocityX)
   r.movementCases[#r.movementCases+1]={label=label,clip=ni.student.playable.current,faceRight=ni.student.faceRight,velocityX=ni.student.velocityX}
   F.stop(ni);local stopped=ni.student.x;D.sleep(.2)
   assert(ni.student.velocityX==0 and math.abs(ni.student.x-stopped)<2,label..' did not stop')
  end
  exercise('near-right-retreat',1400,-180,'bmove',true,-120)
  exercise('near-right-advance',1400,180,'fmove',true,240)
  exercise('near-left-retreat',700,180,'bmove',false,120)
  exercise('outside-range',1950,-180,'fmove',false,-240)
  exercise('defeated-target',1400,-180,'fmove',false,-240,0)
  ni.student:stop();ni.student.x=1050;ni.enemy.x=1400;battle.enemies[1].enemyHP=100;D.sleep(.15)
  F.step(ni,ni.student.x-180,battle);D.sleep(.08)
  assert(ni.student:isDoing(ni.physical.bmove))
  F.step(ni,ni.student.x,battle);D.sleep(.15)
  assert(ni.student.velocityX==0 and not ni.student:isDoing(ni.physical.bmove),'Arrival left retreat running')
  r.backstepArrivalStopped=true
  r.edgeSlots=edge;r.positions={ninilite=ni.student.x,wuyun=wu.student.x}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
