local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local out=D.Path(root,'Test','auxiliary-support-result.txt'); D.Content:save(out,'LSD_AUXILIARY_SUPPORT_RUNNING\n')
D.thread(function()
 local ok,res=xpcall(function()
  D.Director.entry:removeAllChildren(); D.Director.ui3D:removeAllChildren()
  local world=D.Node(); world.size=D.App.bufferSize; world.offset=D.App.bufferSize.height*.3; world:addTo(D.Director.ui3D)
  local bg=D.DrawNode(); bg.order=-5; bg:drawPolygon({D.Vec2.zero,D.Vec2(D.App.bufferSize.width,0),D.Vec2(D.App.bufferSize.width,D.App.bufferSize.height),D.Vec2(0,D.App.bufferSize.height)},D.Color(0xff23313f)); bg:addTo(world)
  local views={}; local supports={}; local routes={}; local phases={}
  for i,v in ipairs(require('Ground.AuxiliaryActor').variants) do
   world.auxiliaryVariant=v.id; local s=require('Ground.LifeSupport').new(45,v.id); local view=require('Ground.SupportView').create(world)
   views[i]=view; supports[i]=s; routes[i]=D.App.bufferSize.width*(i-.5)/3
   local label=D.Label('SourceHanSansCN-Regular',24); label.position=D.Vec2(routes[i],D.App.bufferSize.height*.82); label.text=v.name; label:addTo(world)
   phases[i]=label
  end
  local moving=false; local startTime=D.App.runningTime; local last=startTime
  local tick=D.Node(); tick:addTo(world)
  tick:schedule(function()
   local now=D.App.runningTime; local dt=math.min(.1,now-last);last=now
   for i,s in ipairs(supports) do
    if moving then routes[i]=routes[i]+dt*30 end
    s:update(dt,routes[i]-30,routes[i]+30); views[i]:update(s,routes[i]-30,routes[i]+30)
    phases[i].text=require('Ground.AuxiliaryActor').variants[i].name..' · '..views[i].actor.state..string.format('\n金粉 %.1f / 机体 %d',s.gold,s.machineHP)
   end
   return false
  end)
  local function waitAll(f,timeout)
   local deadline=D.App.runningTime+(timeout or 10)
   while true do local all=true; for i,a in ipairs(views) do all=all and f(a.actor,supports[i],i) end
    if all then return end; assert(D.App.runningTime<deadline,'Actor transition stalled'); D.sleep(.03)
   end
  end
  waitAll(function(a) return a.completed.deploy and a.completed.shield and a.state=='idle' end)
  D.sleep(.4)
  for _,v in ipairs(views) do local body=v.actor.model:getNodeByName('body') or v.actor.model:getNodeByName('core'); assert(body.opacity<.3,'Camouflage missing'); for _,part in ipairs(v.actor.model.auxiliaryParts) do local n=v.actor.model:getNodeByName(part.name);if part.name~='sensor' then assert(n.opacity<.3,'New part not camouflaged: '..part.name) end end; assert(v.actor.model:getNodeByName('sensor').opacity>.9) end
  for _,v in ipairs(views) do v.actor.touch:emit('Tapped') end
  waitAll(function(a) return a.completed.carry==1 and a.state=='idle' end)
  moving=true; waitAll(function(a) return a.state=='move' end); D.sleep(1.6); for _,v in ipairs(views) do assert(v.machine.scaleX==-1,'Machine faces away from travel') end; moving=false
  waitAll(function(a) return a.state=='idle' end)
  for i,s in ipairs(supports) do assert(s:collect('real-pickup',12,s.x,s.x-30,s.x+30)); assert(not s:collect('real-pickup',12,s.x,s.x-30,s.x+30)) end
  waitAll(function(a) return a.completed.collect==1 and a.state=='idle' end)
  for _,v in ipairs(views) do assert(v.actor.eventCounts['energy-transfer']==1) end
  for _,s in ipairs(supports) do s:damageMachine(18) end
  waitAll(function(a) return a.completed.hit==1 and a.state=='idle' end)
  for _,s in ipairs(supports) do s.gold=0 end
  waitAll(function(a) return a.state=='depleted' and a.model.speed==0 end)
  for _,v in ipairs(views)do assert(not v.field.visible,'Depleted field remains visible')end
  local held={}; for i,v in ipairs(views) do held[i]=v.machine.x; routes[i]=routes[i]+90 end
  D.sleep(.4)
  for i,v in ipairs(views) do assert(v.machine.x==held[i],'Exhausted machine moved'); local body=v.actor.model:getNodeByName('body') or v.actor.model:getNodeByName('core'); assert(body.opacity>.9,'Exhausted machine still camouflaged') end
  for i,s in ipairs(supports) do assert(s:collect('recharge',12,s.x,s.x-30,s.x+30)) end
  waitAll(function(a) return a.completed.deploy==2 and a.state=='idle' end)
  for _,v in ipairs(views)do assert(v.field.visible,'Recharged field did not return')end
  for _,s in ipairs(supports) do s:damageMachine(100) end
  waitAll(function(a) return a.state=='lose' and a.model.speed==0 end)
  D.sleep(.5)
  for i,v in ipairs(views) do assert(v.actor.completed.lose==1,'Destroyed pose replayed'); assert(not supports[i]:collect('dead',12,supports[i].x,supports[i].x,supports[i].x)) end
  -- Rebuild healthy public presentation after checking all held terminal states.
  tick:removeFromParent()
  for i,v in ipairs(views) do v.machine:removeFromParent();v.field:removeFromParent();world.auxiliaryVariant=require('Ground.AuxiliaryActor').variants[i].id
   local new=require('Ground.SupportView').create(world);local s=require('Ground.LifeSupport').new();s:update(0,D.App.bufferSize.width*(i-.5)/3-30,D.App.bufferSize.width*(i-.5)/3+30);new:update(s,s.x-30,s.x+30);new.actor:reveal(100); phases[i].text=require('Ground.AuxiliaryActor').variants[i].name..' · 完整显形预览'
  end
  return 'PASS variants=3 realCollectionOnce=true fullDeployShieldMoveCollectHit=true camouflage=true travelFacing=true depletedHeld=true noMovementWithoutEnergy=true rechargeFullDeploy=true destroyedHeld=true noDestroyedCollection=true recovery=.2'
 end,debug.traceback)
 local report='LSD_AUXILIARY_SUPPORT_'..(ok and res or 'FAIL '..tostring(res));print(report);D.Content:save(out,report..'\n')
end)
