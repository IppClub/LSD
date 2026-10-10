-- Visible attack reaction matrix, real full animations and continuous damage.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-dodge-window-result.json';local r={status='RUNNING',cases={},notNaturalVictory=true,notHumanDemonstration=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Dodge window timeout');D.sleep(.02)end end
  for _,skill in ipairs({'kick','jump'})do for _,side in ipairs({-1,1})do for _,timing in ipairs({'early','late'})do for _,response in ipairs({'toward','away'})do
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')})
   local boss=b.enemies[1];local g=boss.guard;local update=g.update;g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review';D.sleep(.4);assert(g:attack('hunt',b.mentor));wait(function()return #g.hunt.children==2 end)
   local child=g.hunt.children[1];local other=g.hunt.children[2]
   for _,e in ipairs(g.hunt.children)do
    e.pendingPounce=nil;local step=e.guard.update;e.guard.update=function(self,now)self.nextAttack=math.huge;step(self,now);self.nextAttack=math.huge end
    e.enemy:stop();e.enemy.velocity=D.Vec2.zero
   end
   boss.enemy.x=3300;other.enemy.x=3200;b.arena.student.x=3400;b.wuyun.student.x=3500
   child.enemy.position=D.Vec2(1920,b.world.offset+105)
   b.mentor.position=D.Vec2(1920+side*(skill=='kick'and 140 or 280),b.world.offset+155)
   D.sleep(.4);wait(function()return child.enemy.onSurface and b.mentor.onSurface end)
   local hp=b.mentorHP;assert(child.guard:attack(skill,b.mentor));local strike=child.guard.strike
   local delay=timing=='early'and .1 or .55;D.sleep(delay)
   local direction=side*(response=='away'and 1 or -1)
   local row={skill=skill,side=side,timing=timing,delay=delay,response=response,clip=child.enemy.playable.current,hpBefore=hp,startX=b.mentor.x}
   r.cases[#r.cases+1]=row
   local deadline=D.App.runningTime+10
   repeat assert(D.App.runningTime<deadline);b:command(direction==1 and'right'or'left');D.sleep(.05)until not child.guard.busy
   b:command('stop');assert(strike.completed and not strike.cancelled,'Attack clip interrupted')
   row.damage=hp-b.mentorHP;row.finishX=b.mentor.x;row.strike=strike;save()
   b:finish('aborted','Visible attack timing matrix');while b.phase=='settling'do D.sleep(.02)end
  end end end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
