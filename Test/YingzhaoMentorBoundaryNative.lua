-- Full wave telegraph and paid mentor counter at either arena boundary.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mentor-boundary-result.json';local r={status='RUNNING',cases={},notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local M=require('Training.YingzhaoMentor')
  for _,side in ipairs({-1,1})do for _,distance in ipairs({700,1000})do
   local supplies=assert(require('Economy.CombatSession').virtual('mentor-boundary:'..D.App.runningTime,{{actor='mentor',item='kinetic',quantity=10}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
   local boss=b.enemies[1];local g=boss.guard;local update=g.update;g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review'
   local edge=side==-1 and b.minX or b.maxX;local bx=edge-side*distance
   b.mentor.position=D.Vec2(edge,b.world.offset+155);boss.enemy.position=D.Vec2(bx,b.world.offset+255);b.arena.student.x=bx-side*400;b.wuyun.student.x=bx-side*500
   b.magic.ready.fire=D.App.runningTime+3600;b.magic.ready.wind=D.App.runningTime+3600
   D.sleep(.5);assert(g:attack('wave',b.mentor));local strike=g.strike;local state=M.new();local row={side=side,distance=distance,commands={}};r.cases[#r.cases+1]=row
   local command=b.command;b.command=function(self,name,...)row.commands[#row.commands+1]=name;return command(self,name,...)end
   local deadline=D.App.runningTime+10
   repeat assert(D.App.runningTime<deadline);M.step(b,state);D.sleep(.1)until not g.busy and not b.bossCombat:pendingActor('mentor')
   row.hp=b.mentorHP;row.emissions=supplies.emissions;row.cancelled=strike.cancelled;row.hits=#b.bossTrace.hits
   assert(row.emissions>0 and row.hits>0,'Boundary did not fire an actual paid shot');assert(strike.cancelled=='HIT'and b.mentorHP==100,'Boundary shot did not counter wave')
   for _,name in ipairs(row.commands)do assert(name~=(side==-1 and'left'or'right'),'Impossible retreat repeated')end
   assert(b:finish('aborted','Controlled boundary counter'));while b.phase=='settling'do D.sleep(.02)end;save()
  end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
