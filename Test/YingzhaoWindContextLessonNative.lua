-- Two real casts per episode, opposite starting facings, continuous HP/AP/ammo.
-- Positions and Boss wave selection are controlled; not human input or natural victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-wind-context-lesson-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Wind context timeout');D.sleep(.02)end end
  local A=require('Training.YingzhaoActions');local P=require('Training.YingzhaoPolicy')
  for _,distance in ipairs({700,1000})do for _,direction in ipairs({1,-1})do
   local b=require('Training.BigYingzhaoPractice').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},{{actor='wuyun',item='emp',quantity=5}},'wuyun')
   local a=b.wuyun;local boss=b.enemies[1];local g=boss.guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';local row={distance=distance,direction=direction,casts={}};r.cases[#r.cases+1]=row
   for _,toward in ipairs({true,false})do
    wait(function()return b.magic:available('wind')and not g.reacting and not g.busy end)
    local edge=direction==1 and b.minX or b.maxX;local bx=edge+direction*distance
    a.student:stop();a.student.velocity=D.Vec2.zero;a.student.position=D.Vec2(edge,b.world.offset+155);boss.enemy.position=D.Vec2(bx,b.world.offset+255)
    b.mentor.x=bx+direction*500;b.mentor.faceRight=direction==1;b.arena.student.x=bx+direction*650
    D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
    assert(g:attack('wave',a.student));local strike=g.strike;D.sleep(.1)
    if distance==1000 then
     local deadline=D.App.runningTime+6
     while math.abs(a.student.x-boss.enemy.x)>650 do assert(D.App.runningTime<deadline);assert(b:command(direction==1 and'right'or'left'));D.sleep(.05)end
     assert(b:command('stop'))
    end
    a.student.faceRight=toward and direction==1 or not toward and direction==-1
    local before=b.observeYingzhao(a.student);assert(before.facing==(toward and'toward'or'away')and before.skillState=='ready')
    assert(b:command('wind'));local log=b.magic.logs[#b.magic.logs]
    wait(function()return not b.magic:busy('wind')and not g.busy and #g.waves==0 end)
    assert(strike.cancelled=='HIT'and not strike.wave and a.studentHP==100 and log.direction==direction and log.status=='completed'and log.hits==1)
    -- A ready firearm remains useful during skill cooldown. Pay for a real EMP shot.
    wait(function()return a:available('laser')and not g.reacting end)
    local observed=b.observeYingzhao(a.student);local part
    for _,id in ipairs({'head','forelegs','arms','torso','hindlegs','flank'})do if observed['part_'..id]~='exposed'and A.plan(b,a,id)then part=id;break end end
    assert(part,'No reachable armored part after counter');assert(observed.skillState=='cooldown','Cooldown lesson started too late')
    local startHits=#b.bossTrace.hits;assert(b:command('aim-part',part));assert(b:command('shoot'))
    wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('wuyun')end)
    local armor=0;for i=startHits+1,#b.bossTrace.hits do armor=armor+b.bossTrace.hits[i].armorDamage end;assert(armor>0,'Cooldown shot failed to break armor')
    row.casts[#row.casts+1]={toward=toward,before=before,log=log,strike=strike,shotBefore=observed,shotPart=part,armor=armor};save()
    a:request('idle','scripted')
   end
   assert(b.supplies.emissions==2 and b.supplies:observation('wuyun').ammo.emp==3)
   assert(b:finish('aborted','Wind facing/cooldown lesson'));wait(function()return b.phase=='aborted'end)
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   row.source=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='wuyun',episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace},false,true),32)
   local samples=assert(P.inspect({row.source},'wuyun'));assert(samples.actions['wind@'..(direction==1 and'right'or'left')]==2)
   local cooling=0;for _,s in ipairs(samples.samples)do assert(s.state.skillState~='unknown');if s.action:match('^shoot@')then assert(s.state.skillState=='cooldown');cooling=cooling+1 end end
   assert(cooling==2);row.samples=#samples.samples;row.actions=samples.actions;save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
