local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-projectiles-result.json';local r={status='RUNNING',shots={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});b.phase='ready'
  local E=require('Enemy.BigYingzhao');E.loadAsync();local boss={enemy=E.create(b.world,7800),enemyHP=1000}
  local events={};local host={world=b.world,phase='playing',enemies={boss},bossTrace={limit=1500,steps={},hits=events}}
  local p=require('Enemy.BigYingzhaoProjectiles').new(host,boss,function(e)e.at=D.App.runningTime;events[#events+1]=e end)
  p.view.node.position=D.Vec2(0,250);p.view.node:addTo(D.Director.ui3D)
  D.sleep(.4);boss.enemy.playable.speed=0;p:sample()
  local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
  for _,part in ipairs(p.armor.target.regions)do for _,v in ipairs(part.vertices)do minX=math.min(minX,v.x);maxX=math.max(maxX,v.x);minY=math.min(minY,v.y);maxY=math.max(maxY,v.y)end end
  local fromX=minX-300;local direction=1;local y
  for height=maxY,minY,-2 do local hit=p:contact({x=fromX,y=height},{x=maxX+20,y=height});if hit and hit.part=='head'then y=height;break end end
  assert(y,'No reachable head ray')
  local function fire(name,weapon,height,after)
   local def=D.Platformer.BulletDef();def.lifeTime=.7;def.gravity=D.Vec2.zero;def.highSpeedFix=true;def:setAsCircle(1);def:setVelocity(0,5000)
   def.face=D.Platformer.Face(function()local n=D.DrawNode();n:drawDot(D.Vec2.zero,3,D.Color(0xffffffff));return n end)
   b.mentor.faceRight=direction>0;local bullet=D.Platformer.Bullet(def,b.mentor);bullet.position=D.Vec2(fromX,height or y);bullet:addTo(b.world)
   local step=#host.bossTrace.steps+1;host.bossTrace.steps[step]={actor='mentor',action='shoot',started=D.App.runningTime,emitted=1}
   local before=#events;local legacy=0;bullet:slot('HitTarget',function()legacy=legacy+1 end);assert(p:projectile(bullet,'mentor',weapon,nil,step))
   if after then after(bullet)end
   local untilAt=D.App.runningTime+2;while bullet.parent do assert(D.App.runningTime<untilAt,'Bullet did not finish');D.sleep(.01)end
   assert(legacy==0 and #events<=before+1,'Duplicate legacy damage')
   local e=events[before+1];r.shots[#r.shots+1]={name=name,event=e,flight=host.bossTrace.flights[#host.bossTrace.flights]};save();return e
  end
  local e=assert(fire('armored','mentor'));assert(e.part=='head'and math.abs(e.healthDamage-2.25)<.001)
  e=assert(fire('emp','laser'));assert(e.part=='head'and e.armorBroken and e.armorDamage==35 and e.healthDamage==0)
  e=assert(fire('exposed','mentor'));assert(e.part=='head'and e.healthDamage==22.5)
  assert(not fire('miss','mentor',maxY+100))
  local def=D.BodyDef();def.type='Static';def:attachPolygon(20,200);local wall=D.Body(def,b.world,D.Vec2(fromX+100,y));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(b.world);D.sleep(.05)
  assert(not fire('terrain','mentor'));wall:removeFromParent()
  boss.enemy.opacity=0;assert(not fire('hidden','mentor'));boss.enemy.opacity=1
  local Small=require('Enemy.SmallYingzhao');local child={enemy=Small.create(b.world,fromX+150),enemyHP=70};host.enemies[2]=child;D.sleep(.2)
  local bodyY=child.enemy.y
  local hit=p:contact({x=fromX,y=bodyY},{x=maxX+20,y=bodyY});assert(hit and hit.enemy==child)
  e=assert(fire('summon-shields','mentor',bodyY));assert(e.summoned and e.healthDamage==15 and child.enemyHP==55)
  local summonId=e.target;host.enemies={child,boss}
  e=assert(fire('emp-on-summon','laser',bodyY));assert(e.target==summonId and e.summoned and e.healthDamage==0 and child.enemyHP==55);host.enemies={boss,child}
  host.enemies[2]=nil;child.enemy:removeFromParent()
  assert(not fire('target-dodges','mentor',y,function()boss.enemy.x=boss.enemy.x+3000 end));boss.enemy.x=7800
  assert(not fire('phase-exit','mentor',y,function()host.phase='ended'end));host.phase='playing'
  boss.enemy.faceRight=not boss.enemy.faceRight;D.sleep(.05);p:sample()
  local lo,hi=math.huge,-math.huge
  for _,part in ipairs(p.armor.target.regions)do for _,v in ipairs(part.vertices)do lo=math.min(lo,v.x);hi=math.max(hi,v.x)end end
  fromX=hi+300;direction=-1;y=nil
  for height=maxY,minY,-2 do local h=p:contact({x=fromX,y=height},{x=lo-20,y=height});if h and h.part=='head'then y=height;break end end
  assert(y,'No reverse head ray');e=assert(fire('reverse-exposed','mentor'));assert(e.part=='head'and e.healthDamage==22.5)
  assert(require('Enemy.BigYingzhaoFlightEvidence').validate(host.bossTrace),'Actual flight journal invalid')
  local expected={armored='contact',emp='contact',exposed='contact',miss='removed',terrain='terrain',hidden='removed',['summon-shields']='contact',['emp-on-summon']='contact',['target-dodges']='removed',['phase-exit']='battle-ended',['reverse-exposed']='contact'}
  for _,shot in ipairs(r.shots)do assert(shot.flight.reason==expected[shot.name],'Wrong physical flight outcome: '..shot.name)end
  r.flightJournalValidated=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-projectile-hud.tga')
  D.sleep(.8);assert(#p.view.effects==0 and next(p.shots)==nil,'Effects or watchers leaked')
  assert(p.view.armor.text:find('已破甲') and math.abs(p.view.hpBar.scaleX-boss.enemyHP/1000)<.00001)
  p:close();assert(p.closed and p.view.closed and p.armor.closed);r.cleanup=true;r.hp=boss.enemyHP
  boss.enemy:removeFromParent();b:finish('aborted','QA complete')
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
