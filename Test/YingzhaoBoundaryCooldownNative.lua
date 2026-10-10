-- Independent full-clip encounters. Controlled placements, no HP resets or training imports.
local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(...));local output='yingzhao-boundary-cooldown-result.json';local skills={'wave'};local distances={1000}
local out=root..'/Test/'..output
local r={status='RUNNING',cases={},notNaturalVictory=true,notHumanDemonstration=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Dodge matrix timeout');D.sleep(.02)end end
  for _,actor in ipairs({'wuyun'})do
   for _,skill in ipairs(skills)do
    for _,distance in ipairs(distances)do
     for _,side in ipairs({-1,1})do
      for _,response in ipairs({'advance-wind'})do
       local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=5}},actor)
       local a=b.demonstrator;local other=actor=='ninilite'and b.wuyun or b.arena
       local boss=b.enemies[1];local g=boss.guard;local update=g.update
       g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
       other.mode='review';assert(b:start())
       local edge=side<0 and b.minX or b.maxX;local bx=edge-side*distance
       boss.enemy.position=D.Vec2(bx,b.world.offset+255);boss.enemy.faceRight=side>0
       a.student.position=D.Vec2(edge,b.world.offset+155)
       other.student.x=bx-side*700;b.mentor.x=bx-side*500;b.mentor.faceRight=side<0
       D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
       local row={actor=actor,skill=skill,distance=distance,side=side,response=response,reaction=.1,hpBefore=a.studentHP,xBefore=a.student.x,bossBefore=boss.enemy.x,commands={},rejections={}}
       r.cases[#r.cases+1]=row;save();assert(b:command('wind'));wait(function()return not a:isAttacking()end);assert(b.magic.windHits==0,'Cooldown setup unexpectedly hit Boss');assert(g:attack(skill,a.student));local strike=g.strike
       local direction=-side;local cast=false;D.sleep(.1)
       local deadline=D.App.runningTime+10
       while g.busy or #g.waves>0 or a:isAttacking()do
        assert(D.App.runningTime<deadline,'Clip did not complete')
        if not cast then
         local accepted,why
         if response=='wind'or math.abs(a.student.x-boss.enemy.x)<=650 then
          accepted,why=b:command('wind');if accepted then cast=true;row.castAt=D.App.runningTime-strike.started end
         else accepted,why=b:command(direction>0 and 'right'or'left')end
         if not accepted then row.rejections[why or 'UNKNOWN']=(row.rejections[why or 'UNKNOWN']or 0)+1 end
         row.commands[#row.commands+1]={at=D.App.runningTime-strike.started,accepted=accepted,x=a.student.x}
        end
        D.sleep(.1)
       end
       row.hpAfter=a.studentHP;row.damage=row.hpBefore-row.hpAfter;row.travel=(a.student.x-row.xBefore)*side;row.bossTravel=(boss.enemy.x-row.bossBefore)*side
       row.strike=strike;row.magic=b.magic.logs;row.windHits=b.magic.windHits;row.bossHP=boss.enemyHP
       if strike.cancelled then assert(strike.cancelled=='HIT'and row.windHits>0 and boss.enemyHP<1000,'Cancellation without actual damage')
       else row.duration=assert(strike.completed)-strike.started;assert(row.duration>=3.95 and strike.wave and strike.wave.ended)end
       b:command('stop');b:finish('aborted','Independent dodge direction fixture');wait(function()return b.phase=='aborted'end);save()
      end
     end
    end
   end
  end
  assert(#r.cases==#skills*#distances*2);for _,row in ipairs(r.cases)do assert(row.damage==16 and row.rejections.COOLDOWN and not row.castAt and not row.strike.cancelled,'Cooldown did not prevent counter')end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
