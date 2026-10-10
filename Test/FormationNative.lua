local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/formation-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
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
  r.edgeSlots=edge;r.positions={ninilite=ni.student.x,wuyun=wu.student.x}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
