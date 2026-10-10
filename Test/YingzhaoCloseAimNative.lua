-- Controlled live summon poses diagnose muzzle overlap; no training/imports.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-close-aim-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')})
  local boss=b.enemies[1];local g=boss.guard;local update=g.update;g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
  assert(b:start());b.arena.mode='review';b.wuyun.mode='review';D.sleep(.5)
  assert(g:attack('hunt',b.mentor));local deadline=D.App.runningTime+8
  while #g.hunt.children<2 do assert(D.App.runningTime<deadline);D.sleep(.02)end
  local children=g.hunt.children
  for _,child in ipairs(children)do child.pendingPounce=nil;child.guard.update=function()end;child.enemy:stop();child.enemy.velocity=D.Vec2.zero end
  for _,side in ipairs({-1,1})do for _,distance in ipairs({41,60,100,140,200,300})do
   local x=side==-1 and 3623 or 217;b.mentor.position=D.Vec2(x,b.world.offset+155);b.mentor:stop();b.mentor.velocity=D.Vec2.zero
   boss.enemy.x=x+side*1200
   children[1].enemy.position=D.Vec2(x+side*distance,b.world.offset+105)
   children[2].enemy.position=D.Vec2(x+side*(distance+85),b.world.offset+105)
   D.sleep(.1)
   local row={side=side,distance=distance,x=b.mentor.x,nearest=children[1].enemy.x,plans={},canStart=b.mentorAim.canStart()}
   for _,part in ipairs({'summon','head','arms','forelegs','torso','flank','hindlegs'})do
    local aim,why=require('Training.YingzhaoActions').plan(b,{student=b.mentor},part);row.plans[part]=aim and 'reachable'or why
   end
   r.cases[#r.cases+1]=row;save()
  end end
  b:finish('aborted','Close muzzle diagnosis');while b.phase=='settling'do D.sleep(.02)end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
