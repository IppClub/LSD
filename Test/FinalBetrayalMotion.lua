local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local r={status='RUNNING',runId=tostring(os.time()),osInput=false};local out=D.Path(root,'Test/final-betrayal-motion-result.json');D.Content:save(out,D.json.encode(r))
D.thread(function()
 local ok,why=xpcall(function()
  for _,asset in ipairs({'sunborn','charF','charM','coldweapon'})do D.Cache:loadAsync('spine:'..asset)end
  local ui=D.Node();ui.size=D.App.bufferSize;ui:addTo(D.Director.ui3D)
  r.actors={}
  for _,asset in ipairs({'charF','charM'})do
   ui:removeAllChildren()
   local lin=assert(D.Spine('sunborn'));lin.position=D.Vec2(450,300);lin:addTo(ui);lin:play('idle',true)
   local cinematic='Spine/Final/'..asset..'.json|Spine/'..asset..'.atlas';D.Cache:loadAsync('spine:'..cinematic)
   local mentor=assert(D.Spine(cinematic));mentor.position=D.Vec2(940,300);mentor:addTo(ui);mentor:play('idle',true)
   local blade=assert(D.Spine('coldweapon'));blade.look='sword';blade.scaleX=.2;blade.scaleY=.2;lin:setSlot('melee',blade)
   local c={lin=lin,mentor=mentor,mentorAsset=asset}
   local p=assert(require('Final.BetrayalAction').playAsync(c));r.actors[asset]=p
   assert(p.attackEnded-p.attackStarted>=p.attackDuration-.04 and p.impactAt>p.attackStarted and p.impactAt<p.attackEnded)
   assert(p.hitEnded-p.hitStarted>=p.hitDuration-.04 and p.fallStarted>=p.attackEnded and p.fallStarted>=p.hitEnded)
   assert(p.fallEnded-p.fallStarted>=p.fallDuration-.04 and p.held and mentor.speed==0)
   D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-betrayal-'..asset..'-fall.tga'));D.sleep(.3)
  end
  r.status='PASS'
 end,debug.traceback)
 if not ok then r.status='FAIL';r.error=why end;D.Content:save(out,D.json.encode(r));print(D.json.encode(r))
end)
