-- Native authored emission-pose sampling only; controlled arena, no policy learning.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=D.Path(root,'Test/learner-muzzle-calibration-result.json');local r={status='RUNNING',controlledFixture=true,osInput=false,samples={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  for _,id in ipairs({'ninilite','wuyun'})do
   local angle=0
   local a=require('Training.Arena').createAsync({characterId=id,manualUpdate=true,enemyMaxHP=1000})
   local aim=D.Node();aim:addTo(a.world);aim:schedule(function()a.student.playable:setBoneRotation('aim',-angle);return a.closed end)
   local function wait(fn)local stop=D.App.runningTime+8;while not fn()do assert(D.App.runningTime<stop,'Authored emission sample timed out');D.sleep(.02)end end
   a.observeProjectile=function(bullet)
    local p=a.student:convertToNodeSpace(a.world:convertToWorldSpace(bullet.position))
    r.samples[#r.samples+1]={actor=id,angle=angle,faceRight=a.student.faceRight,x=p.x*(a.student.faceRight and 1 or -1),y=p.y,worldX=bullet.x,worldY=bullet.y,animation=a.student.playable.current};save()
   end
   for _,face in ipairs({true,false})do for _,degrees in ipairs({-45,-30,-15,0,15,30,45})do for i=1,2 do
    angle=degrees
    wait(function()return a:available('laser')and not a:isAttacking()end)
    a.enemy.x=a.student.x+(face and 400 or -400);D.sleep(.25)
    local count=#r.samples;local yes,why=a:request('laser','qa-calibration');assert(yes,why)
    wait(function()return #r.samples==count+1 and not a:isAttacking()end);D.sleep(.3)
   end end end
   a.world:removeFromParent();D.sleep(.1)
  end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
