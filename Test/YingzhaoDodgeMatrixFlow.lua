-- Independent full-clip encounters. Controlled placements, no HP resets or training imports.
local D=require('Dora')
return function(root,output,skills,distances)
local out=root..'/Test/'..output
local r={status='RUNNING',cases={},notNaturalVictory=true,notHumanDemonstration=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Dodge matrix timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do
   for _,skill in ipairs(skills)do
    for _,distance in ipairs(distances)do
     for _,side in ipairs({-1,1})do
      for _,response in ipairs({'stationary','away','toward'})do
       local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=5}},actor)
       local a=b.demonstrator;local other=actor=='ninilite'and b.wuyun or b.arena
       local boss=b.enemies[1];local g=boss.guard;local update=g.update
       g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
       other.mode='review';assert(b:start())
       boss.enemy.position=D.Vec2(1920,b.world.offset+255);boss.enemy.faceRight=side>0
       a.student.position=D.Vec2(1920+side*distance,b.world.offset+155)
       other.student.x=1920-side*1400;b.mentor.x=1920-side*1200
       D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
       local row={actor=actor,skill=skill,distance=distance,side=side,response=response,reaction=.1,hpBefore=a.studentHP,xBefore=a.student.x,bossBefore=boss.enemy.x,commands={},rejections={}}
       r.cases[#r.cases+1]=row;save();assert(g:attack(skill,a.student));local strike=g.strike
       local direction=side*(response=='away'and 1 or -1);D.sleep(.1)
       local deadline=D.App.runningTime+10
       while g.busy do
        assert(D.App.runningTime<deadline,'Clip did not complete')
        if response~='stationary'then
         local accepted,why=b:command(direction>0 and 'right'or'left')
         if not accepted then row.rejections[why or 'UNKNOWN']=(row.rejections[why or 'UNKNOWN']or 0)+1 end
         row.commands[#row.commands+1]={at=D.App.runningTime-strike.started,accepted=accepted,x=a.student.x}
        end
        D.sleep(.1)
       end
       row.hpAfter=a.studentHP;row.damage=row.hpBefore-row.hpAfter;row.travel=(a.student.x-row.xBefore)*side;row.bossTravel=(boss.enemy.x-row.bossBefore)*side
       row.strike=strike;row.duration=assert(strike.completed)-strike.started
       assert(not strike.cancelled and #strike.impacts==(skill=='punch'and 1 or 3),'Missing actual impact')
       assert(row.duration>=(skill=='punch'and 2 or 2.85),'Authored recovery truncated')
       b:command('stop');b:finish('aborted','Independent dodge direction fixture');wait(function()return b.phase=='aborted'end);save()
      end
     end
    end
   end
  end
  assert(#r.cases==2*#skills*#distances*2*3)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)

end
