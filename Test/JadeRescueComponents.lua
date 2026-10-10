local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local out=D.Path(root,'Test/jade-rescue-components-result.json');local report={status='RUNNING',runId=tostring(os.time()),osInput=false};D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local Actors=require('Rescue.Actor');local Ward=require('Rescue.Ward');Actors.loadAsync()
  D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren()
  local stage=D.Node();stage.size=D.App.bufferSize;stage:addTo(D.Director.ui3D)
  local actors={Actors.new('yu',stage,450,360),Actors.new('vika',stage,830,360),Actors.new('vivi',stage,1150,360)}
  local ward=Ward.new(stage,450,470,230,50);ward:open()
  local tick=D.Node();tick:addTo(stage);local velocity=90;tick:schedule(function(dt)ward:update(dt);for _,actor in ipairs(actors)do actor:update(velocity,dt)end;return false end)
  local damage,blocked=ward:protect(20,450,470);assert(damage==20 and blocked==0,'Ward active before deployment')
  D.sleep(3.3);for _,actor in ipairs(actors)do assert((actor.completed.fmove or 0)>=2 and not actor.model.fliped,'Missing full walk loops')end
  velocity=-90;D.sleep(1.4);for _,actor in ipairs(actors)do assert(actor.model.fliped,'Wrong reverse facing')end
  velocity=0;D.sleep(5.5);for _,actor in ipairs(actors)do assert(actor.state=='idle'and (actor.completed.idle or 0)>=2 and math.abs(actor.model.recovery-.2)<.001,'Missing native idle/recovery')end
  damage,blocked=ward:protect(20,681,470);assert(damage==20 and blocked==0,'Outside field protected')
  damage,blocked=ward:protect(20,450,701);assert(damage==20 and blocked==0,'Vertical range ignored')
  damage,blocked=ward:protect(20,450,470);assert(damage==0 and blocked==20)
  damage,blocked=ward:protect(40,450,470);assert(damage==10 and blocked==30 and ward.remaining==0)
  assert(actors[2]:damage(damage)==10 and actors[2].hp==90,'Exhausted shield discarded overflow')
  damage,blocked=ward:protect(15,450,470);assert(damage==15 and blocked==0)
  ward:close();assert(ward:protect(15,450,470)==15)
  report.protection={outside=true,verticalRange=true,warmup=true,finiteCapacity=true,overflowHP=actors[2].hp,absorbed=ward.absorbed,hits=ward.hits}
  report.actors={};for _,a in ipairs(actors)do report.actors[#report.actors+1]={asset=a.asset,loops=a.completed,distance=a.distance,state=a.state}end
  tick:removeFromParent();report.status='PASS';D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/jade-rescue-actors.tga'));D.sleep(.2)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
