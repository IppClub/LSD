local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-magic-lifecycle-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Magic lifecycle timeout');D.sleep(.02)end end
  for _,skill in ipairs({'fire','wind'})do for _,mode in ipairs({'right','left','interrupted','queued'})do
   local supplies=assert(require('Economy.CombatSession').virtual('magic-lifecycle:'..D.App.runningTime,{{actor='wuyun',item='emp',quantity=4},{actor='ninilite',item='emp',quantity=4}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true});local g=b.enemies[1].guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());b.arena.mode='review';b.wuyun.mode='review'
   local a=skill=='wind'and b.wuyun or b.arena;local other=skill=='wind'and b.arena or b.wuyun
   a.student.position=D.Vec2(1200,b.world.offset+155);other.student.x=3200;b.mentor.x=2800;b.mentor.faceRight=false;D.sleep(.4)
   local row={skill=skill,mode=mode,started=0,released=0,stopped=0};r.cases[#r.cases+1]=row
   local onStarted,onReleased,onStopped=b.magic.onStarted,b.magic.onReleased,b.magic.onStopped
   b.magic.onStarted=function(name,log,before)if onStarted then onStarted(name,log,before)end;assert(name==skill);assert(before and before.skillState=='ready'and before.skillCooldown=='ready'and before.at<=log.startedAt);row.before=before;row.started=row.started+1;row.log=log end
   b.magic.onReleased=function(name,log)if onReleased then onReleased(name,log)end;assert(name==skill and log==row.log);row.released=row.released+1 end
   b.magic.onStopped=function(name,log)if onStopped then onStopped(name,log)end;assert(name==skill and log==row.log);row.stopped=row.stopped+1 end
   if mode=='interrupted'then
    local Small=require('Enemy.SmallYingzhao');local child={enemy=Small.create(b.world,1350),enemyHP=70};child.guard=Small.new(b,child);b.enemies[#b.enemies+1]=child
    local childUpdate=child.guard.update;child.guard.update=function(self,now)self.nextAttack=math.huge;childUpdate(self,now);self.nextAttack=math.huge end
    D.sleep(.3);wait(function()return child.enemy.onSurface end);assert(child.guard:attack('kick',a.student));D.sleep(.5)
   end
   local face=mode~='left'
   if mode=='queued'then
    a.mode='demo'
    assert(a:request('laser','qa-queue-setup'))
    local accepted,why=b.magic:request(skill,{faceRight=face,source='qa-lifecycle',noQueue=true});assert(not accepted and why=='ACTION_BUSY'and row.started==0)
    accepted,why=b.magic:request(skill,{faceRight=face,source='qa-lifecycle'});assert(accepted and why=='QUEUED_AFTER_ATTACK'and row.started==0)
   else assert(b.magic:request(skill,{faceRight=face,source='qa-lifecycle',noQueue=true}))end
   D.sleep(.05);b.mentor.faceRight=not face;b.mentor.x=3000
   wait(function()return row.stopped==1 and not b.magic:busy(skill)end)
   assert(row.started==1 and row.log.actor==a.character.id and row.log.source=='qa-lifecycle'and row.log.direction==(face and 1 or -1))
   if mode=='interrupted'then
    assert(row.log.status=='cancelled'and row.log.cancelledAt and not row.log.completedAt and not row.log.releaseAt and row.released==0 and a.studentHP<100,'Interrupted skill released or completed')
   else
    assert(row.log.status=='completed'and row.log.completedAt and not row.log.cancelledAt and row.released==1)
    assert(row.log.startedAt<=row.log.releaseAt and row.log.releaseAt<=row.log.endedAt)
    if mode=='queued'then assert(row.log.requestedAt<row.log.startedAt and not b.magic.pending[skill])end
    if skill=='fire'then assert(row.log.aim==(mode=='queued'and 3000 or 2800)+(face and 240 or -240),'Cast aim changed after start')end
    local available,why=b.magic:available(skill);assert(not available and why=='COOLDOWN')
    local accepted,reason=b.magic:request(skill,{source='qa-lifecycle',noQueue=true});assert(not accepted and reason=='COOLDOWN')
   end
   local released=row.released;a.student.playable:emit('attack');D.sleep(.05);assert(row.released==released,'Late attack callback released stale cast')
   row.hp=a.studentHP;assert(b:finish('aborted','Magic lifecycle fixture'));wait(function()return b.phase=='aborted'end);save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
