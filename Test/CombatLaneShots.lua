local _,capture=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-lane-shots-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-hud-performance-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync())
  local support=require('Ground.LifeSupport').new(45,'defence');support.hp={100,100,100}
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models=saved.source.baseModels},support);local b=c.battle
  local function wait(f)
   local deadline=D.App.totalTime+6
   while not f()do assert(D.App.totalTime<deadline,'Lane shot timeout');D.sleep(.01)end
  end
  assert(b:start());for _,a in ipairs(b.learners)do a.mode='review';a.student:stop()end
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  -- Isolate the original-size boss from ordinary flower body blockers.
  for i=1,2 do b.roots[i].enemyHP=0;b.roots[i].enemy.group=D.Platformer.Data.groupHide end
  local observe=b.arena.observeProjectile;local emitted
  b.arena.observeProjectile=function(bullet,source,step)
   if source=='mentor'then
    local gun=b.mentor.playable:getSlot('pistol')
    local p=b.arena.world:convertToNodeSpace(gun:convertToWorldSpace(D.Vec2(300,0)))
    assert(math.abs(bullet.x-p.x)<.01 and math.abs(bullet.y-p.y)<.01,'Bullet detached from visible muzzle')
    emitted={x=bullet.x,y=bullet.y,muzzleX=p.x,muzzleY=p.y}
   end
   return observe(bullet,source,step)
  end
  for _,case in ipairs({{-1,true},{0,true},{1,true},{-1,false},{0,false},{1,false}})do
   local lane,right=case[1],case[2]
   local u=b.mentor;u.order=lane;b.arena.world:moveChild(u,lane)
   u.x=b.roots[3].enemy.x+(right and -850 or 750);u.faceRight=right;u.velocityX=0;D.sleep(.1)
   wait(function()return u.onSurface and b.mentorAim.canStart() and not b.mentorAim.shot end)
   local solution
   for _,part in ipairs({'flower-core','petal-left','petal-right','roots','flower-head'})do solution=b.partCombat:aim(u,part,false);if solution then break end end
   if not solution then r.debug={muzzle=b.partCombat:muzzle(u),unit={x=u.x,y=u.y},boss={x=b.roots[3].enemy.x,y=b.roots[3].enemy.y},regions=b.partCombat.target.regions}end
   assert(solution,'No visible boss part available')
   local hits=b.mentorHits;emitted=nil
   b.mentorAim.angle=solution.angle;b.mentorAim.shot=true
   assert(b:command('shoot'))
   wait(function()return emitted~=nil end)
   wait(function()return b.mentorHits>hits end)
   local event=b.partCombat.events[#b.partCombat.events]
   assert(event and event.source=='mentor','No authoritative part hit')
   assert(u.order==lane,'Shooting changed lane')
   emitted.lane=lane;emitted.right=right;emitted.part=event.part;emitted.damage=event.healthDamage
   r.cases[#r.cases+1]=emitted
  end
  r.bossScale=b.roots[3].enemy.playable.scaleX;assert(r.bossScale==1)
  b:finish('aborted','Lane shot regression complete')

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
