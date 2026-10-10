local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING',cases={}};local out=root..'/Test/part-terrain-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local p=require('Training.PartPractice').createAsync('ninilite');local a=p.arena
  for _,case in ipairs({{name='wall-before',wall='before',hit=false},{name='wall-behind',wall='behind',hit=true},{name='no-wall',hit=true},{name='reverse-wall-before',wall='before',reverse=true,hit=false},{name='reverse-wall-behind',wall='behind',reverse=true,hit=true}})do
   a:beginDemo(620);D.sleep(.2);a.enemy.playable.speed=0
   local c=p.partCombat;c.target:sample()
   local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
   for _,part in ipairs(c.target.regions)do for _,v in ipairs(part.vertices)do minX=math.min(minX,v.x);maxX=math.max(maxX,v.x);minY=math.min(minY,v.y);maxY=math.max(maxY,v.y)end end
   local fromX=case.reverse and maxX+100 or minX-100;local toX=case.reverse and minX-100 or maxX+100
   local y
   for height=maxY-20,minY+20,-10 do if c.target:probe({x=fromX,y=height},{x=toX,y=height})then y=height;break end end
   assert(y)
   local wall
   if case.wall then
    local x=case.wall=='before' and (case.reverse and maxX+30 or minX-30) or (case.reverse and minX-30 or maxX+30)
    local def=D.BodyDef();def.type='Static';def:attachPolygon(10,100,1,0,0)
    wall=D.Body(def,a.world,D.Vec2(x,y));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(a.world);D.sleep(.05)
   end
   local def=D.Platformer.BulletDef();def.lifeTime=1;def.highSpeedFix=true;def.gravity=D.Vec2.zero;def:setAsCircle(1);def:setVelocity(0,100000)
   a.student.faceRight=not case.reverse
   local bullet=D.Platformer.Bullet(def,a.student);bullet.position=D.Vec2(fromX,y);bullet:addTo(a.world)
   c:projectile(bullet,'learner')
   local deadline=D.App.runningTime+2
   while bullet.parent do assert(D.App.runningTime<deadline);D.sleep(.01)end
   assert((#c.events>0)==case.hit,case.name..' wrong hit ordering')
   r.cases[#r.cases+1]={name=case.name,hits=#c.events};save()
   if wall then wall:removeFromParent()end
  end
  p:close()
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
