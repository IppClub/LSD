-- Independent full-clip encounters. Controlled placements, no HP resets or training imports.
local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(...));local output='yingzhao-melee-spacing-result.json';local skills={'punch','massive'};local distances={350,650}
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
      for _,response in ipairs({'stationary','fmove','bmove'})do
       local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=5}},actor)
       local a=b.demonstrator;local other=actor=='ninilite'and b.wuyun or b.arena
       local boss=b.enemies[1];local g=boss.guard;local update=g.update
       g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
       other.mode='review';assert(b:start())
       local bx=(b.minX+b.maxX)/2;local edge=bx+side*distance
       boss.enemy.position=D.Vec2(bx,b.world.offset+255);boss.enemy.faceRight=side>0
       a.student.position=D.Vec2(edge,b.world.offset+155)
       other.student.x=bx-side*700;b.mentor.x=bx-side*500;b.mentor.faceRight=side<0
       D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
       local row={actor=actor,skill=skill,distance=distance,side=side,response=response,reaction=.1,hpBefore=a.studentHP,xBefore=a.student.x,bossBefore=boss.enemy.x,commands={},rejections={}}
       r.cases[#r.cases+1]=row;save();assert(g:attack(skill,a.student));local strike=g.strike
       local direction=-side;local cast=false;D.sleep(.1)
       local deadline=D.App.runningTime+10
       while g.busy or #g.waves>0 or a:isAttacking()do
        assert(D.App.runningTime<deadline,'Clip did not complete')
        if not cast and response~='stationary' then
         local accepted,why
         accepted,why=require('Training.YingzhaoActions').request(b,a,response,'demo',2)
         if not accepted then row.rejections[why or 'UNKNOWN']=(row.rejections[why or 'UNKNOWN']or 0)+1 end
         row.commands[#row.commands+1]={at=D.App.runningTime-strike.started,accepted=accepted,x=a.student.x}
        end
        D.sleep(.1)
       end
       row.hpAfter=a.studentHP;row.damage=row.hpBefore-row.hpAfter;row.travel=(a.student.x-row.xBefore)*side;row.bossTravel=(boss.enemy.x-row.bossBefore)*side
       row.strike=strike;row.magic=b.magic.logs;row.windHits=b.magic.windHits;row.bossHP=boss.enemyHP
       if strike.cancelled then assert(strike.cancelled=='HIT'and row.windHits>0 and boss.enemyHP<1000,'Cancellation without actual damage')
       else row.duration=assert(strike.completed)-strike.started;for _,clip in ipairs(strike.clips)do assert(clip.ended and clip.ended-clip.started>=clip.duration-.06,'Truncated Boss clip')end end
       b:command('stop');b:finish('aborted','Independent spacing fixture');wait(function()return b.phase=='aborted'end)
       local resources=b.supplies:evidence();b.bossTrace.resources=resources
       row.source=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace},false,true),32)
       assert(require('Enemy.BigYingzhaoEvidence').validateVirtual(row.source))
       local samples=response~='stationary'and assert(require('Training.YingzhaoPolicy').inspect({row.source},actor,8,2))or{samples={},actions={}}
       row.samples=#samples.samples;row.actions=samples.actions
       if response~='stationary'then assert(#row.commands>0 and row.commands[1].accepted,'Movement was never started')end
       row.lessonEligible=row.damage==0 and response~='stationary';save()
      end
     end
    end
   end
  end
  assert(#r.cases==#skills*#distances*2*3)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
