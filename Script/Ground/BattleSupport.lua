-- Carry the actual expedition machine into optional ground encounters.
local D=require('Dora');local M={};local serial=0
function M.attach(b,support)
 if not support then return end
 assert(not b.support,'Battle already owns a support machine')
 b.support=support;b.world.groundSupport=support;b.world.auxiliaryVariant=support.variant
 b.physicalShield=require('Ground.PhysicalShield').new(support,D.App.runningTime)
 if b.bossTrace then b.bossTrace.physicalShieldVersion=1 end
 support.hp={b.mentorHP,b.arena.studentHP,b.wuyun.studentHP}
 local function positions()return {b.mentor.x,b.arena.student.x,b.wuyun.student.x}end
 support:update(0,positions())
 -- Set orders before addTo creates the world layers, rather than while rendering.
 b.supportView=require('Ground.SupportView').create(b.world,support.variant,-2,-3)
 local def=D.Dictionary();def.playable='spine:kineticgun';def.bodyType='Dynamic';def.size=D.Size(140,160);def.density=1;def.actions=D.Array({});def.linearAcceleration=D.Vec2.zero
 serial=serial+1;D.Entity({optionalMachineId=serial,name='auxiliary-machine'})
 local entity=assert(D.Group({'optionalMachineId'}):find(function(e)return e.optionalMachineId==serial end))
 b.machine=assert(D.Platformer.Unit(def,b.world,entity,D.Vec2(support.x,b.world.offset+80)))
 b.machine.group=1;b.machine.playable.visible=false;b.machine:addTo(b.world)
 local targets=b.targets
 b.targets=function(self)
  local list=targets(self)
  list[#list+1]={unit=self.machine,immovable=true,hp=function()return support.machineHP end,damage=function(n)
   local before=support.machineHP;support:damageMachine(n);return before-support.machineHP
  end}
  for _,target in ipairs(list)do
   local damage=target.damage
   target.damage=function(n,context)
    local actor=target.unit==self.machine and 'machine'or target.unit==self.mentor and 'mentor'or target.unit==self.arena.student and 'ninilite'or 'wuyun'
    local meta={kind=context and context.kind,skill=context and context.skill,actor=actor,attackerId=context and context.attackerId,strikeStarted=context and context.strikeStarted,hitIndex=context and context.hitIndex}
    local remaining,event=self.physicalShield:resolve(n,target.unit.x,target.unit.y-self.world.offset,D.App.runningTime,meta)
    local tagged={}
    for k,v in pairs(context or {})do tagged[k]=v end
    tagged.physicalShieldEvent=event
    local before=target.hp();local result=damage(remaining,tagged)
    if event then event.hpBefore=before;event.hpAfter=target.hp()end
    target.displacementScale=n>0 and remaining/n or 1
    return result
   end
  end
  return list
 end
 local vitals=b.bossTrace and b.bossTrace.vitals
 if vitals then vitals.schemaVersion=2 end
 local last=D.App.runningTime;local update=b.update
 b.update=function(self,...)
  local now=D.App.runningTime;local dt=math.min(.1,math.max(0,now-last));last=now
  if self.phase=='playing' then
   self.physicalShield:update(now)
   local before={self.mentorHP,self.arena.studentHP,self.wuyun.studentHP};support.hp={table.unpack(before)}
   support:update(dt,positions())
   if vitals then for i,actor in ipairs({'mentor','ninilite','wuyun'})do
    require('Training.YingzhaoVitals').record(vitals,actor,before[i],support.hp[i],{kind=support.hp[i]>=before[i]and'support-heal'or'support-hazard',skill='life-support'})
   end end
   self.mentorHP,self.arena.studentHP,self.wuyun.studentHP=table.unpack(support.hp)
  end
  local p=positions();self.supportView:update(support,math.min(table.unpack(p)),math.max(table.unpack(p)))
  self.machine.position=D.Vec2(support.x,self.world.offset+80);self.machine.velocity=D.Vec2.zero
  return update(self,...)
 end
 local failed=b.scenario.failed;local reason=b.scenario.failureReason
 b.scenario.failed=function(self)
  if support.machineHP<=0 then self.scenario.failureReason='辅助机被摧毁，调查行动中止。';return true end
  self.scenario.failureReason=reason;return failed and failed(self)or false
 end
 local function beginAccount(self)
  if self.bossTrace and not self.supportAccountBook then
   self.supportAccountBook=require('Training.YingzhaoSupportAccounting').open(support,self.physicalShield,D.App.runningTime)
   self.bossTrace.supportAccountingVersion=1;self.bossTrace.supportAccounting=self.supportAccountBook.record
  end
 end
 local start=b.start
 b.start=function(self,...)
  local ok=start(self,...);if ok then beginAccount(self)end;return ok
 end
 local finish=b.finish
 b.finish=function(self,...)
  if self.phase=='ready'then beginAccount(self)end
  local ok=finish(self,...)
  if ok and self.report then
   local shield=self.physicalShield:finish(D.App.runningTime)
   self.report.auxiliary=require('Factory.Support').report(support)
   self.report.auxiliary.physicalShield=shield
   if self.bossTrace then
    self.bossTrace.physicalShield=shield
    if self.supportAccountBook then
     local record,why=self.supportAccountBook:finish(shield,shield.finished)
     self.bossTrace.supportAccounting=record or self.supportAccountBook.record
     self.bossTrace.supportAccountingError=why
    end
   end
  end
  return ok
 end
 b.supportView:update(support,math.min(table.unpack(positions())),math.max(table.unpack(positions())))
end
return M
