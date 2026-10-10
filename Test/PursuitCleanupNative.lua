local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/pursuit-cleanup-result.json';local r={status='RUNNING',cycles={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local weak=setmetatable({},{__mode='v'})
  local function wait(f)local limit=D.App.runningTime+15;while not f()do assert(D.App.runningTime<limit,'Pursuit lifecycle timeout');D.sleep(.02)end end
  for cycle=1,3 do
   do
    local b=require('Ruins.Pursuit').createAsync({finishAsync=function()return true end},{mission='c0-m06'});weak[cycle]=b
    for _,e in ipairs(b.enemies)do e.nextAttack=math.huge end
    wait(function()return b.mentor.onSurface end)
    assert(b:command('smoke'));wait(function()return b.toolAnimations.smoke==1 end);assert(b.toolUses.smoke==1)
    local actors={b.stamina};for _,e in ipairs(b.escorts)do if e.stamina then actors[#actors+1]=e.stamina end end
    for _,s in ipairs(actors)do s:hit(100);assert(s.down)end
    wait(function()for _,s in ipairs(actors)do if s.down then return false end end;return true end)
    for _,s in ipairs(actors)do assert(s.records[1].completed and #s.records[1].stages==2)end
    b.stamina:hit(100);assert(b.stamina.down);b:finish('aborted','Cleanup QA');wait(function()return b.phase=='aborted'end)
    assert(not b.stamina.down and b.stamina.records[2].cancelled)
    r.cycles[#r.cycles+1]={cycle=cycle,actors=#actors,smoke=b.toolUses.smoke,cancelled=true}
    D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear()
   end
   D.sleep(.3);collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
   r.retained=0;for _ in pairs(weak)do r.retained=r.retained+1 end;save();assert(r.retained==0,'Pursuit action registry retained old battle')
  end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
