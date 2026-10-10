local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/character-hit-recovery-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={actors={}};local ok,err=xpcall(function()
  local a=require('Training.Arena').createAsync({scene='VRTraining',manualUpdate=true,minX=-1000,maxX=5000})
  local K=require('Combat.Displacement')
  for _,id in ipairs({'ninilite','wuyun','charM','charF'})do
   D.Cache:loadAsync('spine:'..id)
   local u=a.spawnUnit(id,1,700,{});D.sleep(.25)
   assert(u.data.combatHasHit and u.data.combatHasFall and u.data.combatHasStandUp,'Missing authored reactions '..id)
   local strike={source='test-boss',kind='pounce'};local order=u.order;local events={}
   assert(K.apply({unit=u,onForcedMovement=function(e)events[#events+1]=e end},900,850,strike))
   local deadline=D.App.totalTime+9;local protectedStandUp=false
   while K.blocked(u)do
    assert(D.App.totalTime<deadline,'Recovery stuck '..id)
    local phases=strike.displacements[1].reactions
    if phases[#phases].name=='standUp'then
     protectedStandUp=true;assert(u.onSurface,'Standing up in air')
     local accepted=K.apply({unit=u},-1200,1080,{})
     assert(not accepted,'Repeated hit reset get-up')
    end
    D.sleep(.02)
   end
   D.sleep(.05);local phases=strike.displacements[1].reactions
   assert(#phases==3 and phases[1].name=='hit' and phases[2].name=='fall' and phases[3].name=='standUp' and protectedStandUp)
   for _,phase in ipairs(phases)do assert(phase.completed and phase.completed-phase.started>=phase.duration-.04,'Truncated '..id..' '..phase.name)end
   assert(u.onSurface and u.order==order and u.playable.current==u.data.combatRest)
   assert(#events==3 and events[1].kind=='hit'and events[2].kind=='fall'and events[3].kind=='standUp')
   for i,e in ipairs(events)do assert(e.origin=='forced'and e.source=='test-boss'and e.skill=='pounce');if i>1 then assert(e.at>events[i-1].at)end end
   assert(K.snapshot(u).phase=='free'and not K.snapshot(u).blocked)
   r.actors[id]={movement=events,phases=phases,rest=u.playable.current,landed=true,getUpProtected=protectedStandUp}
   K.clear(u);local light={};assert(K.apply({unit=u},0,nil,light))
   deadline=D.App.totalTime+4
   while K.blocked(u)do assert(D.App.totalTime<deadline);D.sleep(.02)end
   assert(#light.displacements[1].reactions==1 and light.displacements[1].reactions[1].name=='hit')
   K.clear(u);u:removeFromParent()
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
