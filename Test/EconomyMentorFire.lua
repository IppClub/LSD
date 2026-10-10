local _,capture=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/economy-mentor-fire-result.json';local r={status='RUNNING',cases={}}
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
  local S=require('Economy.Store');assert(S.open())
  assert(S.beginAsync('fire-qa',{{actor='mentor',item='kinetic',quantity=2}},0))
  b.supplies=assert(require('Economy.CombatSession').open('fire-qa'))
  local emitted=0;local observe=b.arena.observeProjectile
  b.arena.observeProjectile=function(bullet,source,step)
   if source=='mentor'then emitted=emitted+1;assert(S.load('fire-qa').stock['mentor:kinetic'].used==emitted)end
   return observe(bullet,source,step)
  end
  local u=b.mentor;u.x=b.roots[3].enemy.x-850;u.faceRight=true;u.velocityX=0;D.sleep(.1)
  local function shoot()
   wait(function()return u.onSurface and b.mentorAim.canStart() and not b.mentorAim.shot end)
   local solution
   for _,part in ipairs({'flower-core','petal-left','petal-right','roots','flower-head'})do solution=b.partCombat:aim(u,part,false);if solution then break end end
   assert(solution);b.mentorAim.angle=solution.angle;b.mentorAim.shot=true;b.supplyFailure=nil
   assert(b:command('shoot'));D.sleep(.1)
   wait(function()return not u:isDoing('groundMentorShot')end)
  end
  assert(D.DB:exec("CREATE TRIGGER lsd.FailShot BEFORE UPDATE ON Game0SupplyAttempts BEGIN SELECT RAISE(ABORT,'shot fault'); END")>=0)
  shoot();assert(emitted==0 and b.supplyFailure=='WRITE_FAILED' and S.load('fire-qa').spent==2)
  assert(D.DB:exec('DROP TRIGGER lsd.FailShot')>=0)
  shoot();assert(emitted==1 and S.load('fire-qa').spent==4)
  shoot();assert(emitted==2 and S.load('fire-qa').spent==6)
  local fired,why=b:command('shoot');assert(not fired and why=='OUT_OF_SUPPLIES' and not b.mentorAim.canStart());assert(emitted==2 and S.load('fire-qa').spent==6)
  r.emitted=emitted;r.cost=6;r.maxCommitMs=b.supplies.maxCommitSeconds*1000
  r.checks={'real attack event','durable before projectile publication','SQL failure prevents fire','empty ammo prevents fire'}
  b:finish('aborted','Resource shot QA complete');assert(S.settleAsync('fire-qa','aborted'))
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
