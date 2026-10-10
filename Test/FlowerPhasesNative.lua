local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local r={status='RUNNING'};local out=root..'/Test/flower-phases-result.json'
 local function save()D.Content:save(out,D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local a=require('Training.Arena').createAsync({scene='Factory',enemyAsset='dahuayao',manualUpdate=true})
  a:beginDemo(350);local c=a.enemyCombat;c.phaseEnabled=true;c:reset();a.enemyTargets=function()return {}end
  local auto=false;local tick=D.Node();tick:addTo(a.world);tick:schedule(function()if not auto then a.nextEnemy=math.huge end;c:update(D.App.runningTime);return false end)
  local function wait(f)local deadline=D.App.runningTime+12;while not f()do assert(D.App.runningTime<deadline,'Phase timeout '..tostring(c.stage)..' elapsed='..tostring(D.App.runningTime-c.partStarted)..' done='..tostring(c.stageDone)..' duration='..tostring(c.stageDuration)..' mode='..tostring(a.mode));D.sleep(.01)end end
  assert(c.bossPhase==1 and #c.skills==3)
  assert(c:start('transv'));local strike=a.enemyStrike
  a.enemyHP=a.enemyMaxHP*.5;D.sleep(.1);assert(c.phasePending and c.bossPhase==1)
  wait(function()return strike.completedAt end);assert(#strike.segments==3)
  for _,segment in ipairs(strike.segments)do assert(segment.completedAt-segment.startedAt>=segment.duration-.04)end
  wait(function()return c.bossPhase==2 end);assert(#c.phaseEvents==1 and c.phaseEvents[1].at>=strike.completedAt)
  auto=true;wait(function()return a.enemyStrike~=strike end);local seed=a.enemyStrike;assert(seed.kind=='seed')
  wait(function()return seed.completedAt end);assert(seed.spawned==3)
  wait(function()return a.enemyStrike~=seed end);assert(a.enemyStrike.kind=='twine');r.phaseCombo=true
  auto=false;wait(function()return a.enemyStrike.completedAt end)
  a.enemyHP=a.enemyMaxHP;c:update(D.App.runningTime);assert(c.bossPhase==2 and #c.phaseEvents==1);r.noReverse=true
  -- Phase-owned effects cannot keep their old hit schedule after reset.
  a.enemyPhase='idle';assert(c:start('twine'));local vines=a.enemyStrike
  wait(function()return vines.attackAt and next(c.waves)end)
  local old={};for wave in pairs(c.waves)do old[#old+1]=wave end
  c:reset();assert(not next(c.waves) and c.bossPhase==1 and #c.children==0)
  for _,wave in ipairs(old)do assert(not wave.parent)end
  c:close();D.sleep(.3);assert(not next(c.waves));r.effectsCleaned=true;r.transitions=1
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
