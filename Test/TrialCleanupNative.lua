local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/trial-cleanup-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local weak=setmetatable({},{__mode='v'})
  local function wait(f)local limit=D.App.runningTime+15;while not f()do assert(D.App.runningTime<limit,'Trial lifecycle timeout');D.sleep(.02)end end
  for cycle=1,3 do
   for _,mission in ipairs({'c0-m04','c0-m04-duel'})do
    local b=require('Trial.Battle').createAsync({finishAsync=function()return true end},{mission=mission});weak[mission]=b
    assert(b:begin());b.nextNpc=D.App.runningTime+100
    wait(function()return b.heroAim.canStart()end);assert(b.heroAim:begin());D.sleep(.05);assert(b.heroAim:release())
    wait(function()return b.heroHits>0 and not b:heroBusy()end)
    assert(b:command('guard'));wait(function()return not b:heroBusy()end)
    assert(#b.casts>=2 and b.casts[#b.casts].completedAt)
    local startX=b.hero.x;assert(b:command('right'));D.sleep(.35);assert(b:command('stop'));assert(b.hero.x>startX+20,'Trial move failed')
    b.nextNpc=D.App.runningTime;wait(function()return b.npcHits>0 and not b:npcBusy()end)
    r.cases[#r.cases+1]={cycle=cycle,mission=mission,hits=b.heroHits,npcHits=b.npcHits,casts=#b.casts,moved=b.hero.x-startX}
    b:finish('aborted','Cleanup QA');wait(function()return b.phase=='aborted'end)
    D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();wait(function()return b.closed end)
   end
   D.sleep(.2);collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
   r.retained=0;for _ in pairs(weak)do r.retained=r.retained+1 end;save();assert(r.retained==0,'Global trial actions retained the closed battle')
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
