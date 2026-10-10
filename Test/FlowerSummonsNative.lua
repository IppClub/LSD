local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING'};local out=root..'/Test/flower-summons-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local a=require('Training.Arena').createAsync({scene='Factory',enemyAsset='dahuayao',manualUpdate=true})
  a:beginDemo(350);a.enemyTargets=function()return {}end
  local c=a.enemyCombat;local registry={};local retired=0
  c.onSpawn=function(child)registry[child]=true end
  c.onDespawn=function(child)assert(registry[child]);registry[child]=nil;retired=retired+1 end
  local tick=D.Node();tick:addTo(a.world);tick:schedule(function()a.nextEnemy=math.huge;c:update(D.App.runningTime);return false end)
  local function wait(f)local deadline=D.App.runningTime+15;while not f()do assert(D.App.runningTime<deadline,'Summon timeout');D.sleep(.01)end end
  local function seed()assert(c:start('seed'));local strike=a.enemyStrike;wait(function()return strike.completedAt end);return strike end
  local first=seed();assert(first.spawned==3 and c:activeSummons()==3)
  local second=seed();assert(second.spawned==0 and second.summonBlocked and #c.children==3);r.capped=true
  -- Real bud damage window and blossom must finish before a summoned flower dies.
  local victim=c.children[1];victim.enemyHP=victim.enemyHP-120
  wait(function()return not victim.enemyCombat.budding and not victim.enemyCombat.opening end)
  victim.enemyHP=0;local deathAt=D.App.runningTime
  wait(function()return victim.enemyCombat.dead end)
  local deathDuration=victim.enemyCombat.deathDuration
  D.sleep(.1);assert(victim.enemy.parent,'Death removed early')
  wait(function()return not registry[victim]end)
  assert(D.App.runningTime-deathAt>=deathDuration-.03 and not victim.enemy.parent and #c.children==2)
  r.fullDeath=true;r.deathSeconds=D.App.runningTime-deathAt
  local replacement=seed();assert(replacement.spawned==1 and c:activeSummons()==3 and #c.children==3);r.refillOne=true
  local remaining={};for _,child in ipairs(c.children)do remaining[#remaining+1]=child end
  c:close();assert(#c.children==0 and not next(registry));for _,child in ipairs(remaining)do assert(not child.enemy.parent and child.closed)end
  assert(not c:start('seed'));D.sleep(.2);assert(#c.children==0);r.closed=true;r.retired=retired
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
