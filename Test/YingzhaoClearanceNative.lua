-- Real repositioning and paid hits against controlled living summons.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-clearance-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  for _,side in ipairs({-1,1})do for _,edge in ipairs({true,false})do
   local supply=assert(require('Economy.CombatSession').virtual('clearance:'..D.App.runningTime,{{actor='mentor',item='kinetic',quantity=10}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supply,{virtual=true})
   local boss=b.enemies[1];local g=boss.guard;local update=g.update;g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review';D.sleep(.5)
   assert(g:attack('hunt',b.mentor));local deadline=D.App.runningTime+10
   while #g.hunt.children<2 do assert(D.App.runningTime<deadline);D.sleep(.02)end
   for _,c in ipairs(g.hunt.children)do c.pendingPounce=nil;c.guard.update=function()end;c.enemy:stop();c.enemy.velocity=D.Vec2.zero end
   local x=edge and(side==-1 and 3623 or 217)or 1920
   b.mentor.position=D.Vec2(x,b.world.offset+155);boss.enemy.x=x+side*1100
   local first=g.hunt.children[1];first.enemy.position=D.Vec2(x+side*41,b.world.offset+105)
   g.hunt.children[2].enemy.position=D.Vec2(x+side*126,b.world.offset+105)
   b.magic.ready.fire=D.App.runningTime+3600;b.magic.ready.wind=D.App.runningTime+3600
   D.sleep(.2);assert(b.mentorAim.canStart());assert(not require('Training.YingzhaoActions').plan(b,{student=b.mentor},'summon'))
   local row={side=side,edge=edge,start=b.mentor.x};r.cases[#r.cases+1]=row
   local M=require('Test.YingzhaoMentorClearanceV14');local state=M.new();deadline=D.App.runningTime+12
   repeat assert(D.App.runningTime<deadline,'Clearance failed to produce a real hit');M.step(b,state);D.sleep(.1)until #b.bossTrace.hits>0
   local hit=b.bossTrace.hits[1];assert(hit.summoned and hit.healthDamage>0 and supply.emissions>0)
   row.finish=b.mentor.x;row.hit=hit;row.emissions=supply.emissions;row.hp=b.mentorHP
   assert((row.finish-row.start)*side*(edge and 1 or -1)>150,'Wrong clearance direction')
   b:finish('aborted','Controlled clearance proof');while b.phase=='settling'do D.sleep(.02)end;save()
  end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
