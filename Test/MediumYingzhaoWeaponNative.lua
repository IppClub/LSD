local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/medium-yingzhao-weapon-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local asset='zhongyingzhao-weapon.skel|zhongyingzhao.atlas';D.Cache:loadAsync('spine:'..asset);D.Cache:loadAsync('spine:kineticgun')
  for _,flip in ipairs({false,true})do
   local m=assert(D.Spine(asset));m.look='default';m.fliped=flip;m.recovery=.2;m:addTo(D.Director.entry)
   local gun=assert(D.Spine('kineticgun'));gun.look='PT';gun.scaleX=.3;gun.scaleY=-.3;m:setSlot('pistol',gun)
   for _,name in ipairs({'gunidle','shoot'})do
    local row={name=name,flip=flip,started=D.App.runningTime};r.cases[#r.cases+1]=row
    m:slot('AnimationEnd'):set(function(n)if n==name then row.ended=D.App.runningTime end end);row.duration=m:play(name,false)
    D.sleep(.45)
    local origin=gun:convertToWorldSpace(D.Vec2.zero);local muzzle=gun:convertToWorldSpace(D.Vec2(300,0));local dx=muzzle.x-origin.x
    assert(flip and dx>50 or not flip and dx< -50,'Weapon facing mismatch');row.muzzle={x=muzzle.x,y=muzzle.y};row.direction=dx
    local deadline=D.App.runningTime+3;while not row.ended do assert(D.App.runningTime<deadline);D.sleep(.01)end
    assert(row.ended-row.started>=row.duration-.025,'Truncated original clip')
   end
   m:removeFromParent()
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
