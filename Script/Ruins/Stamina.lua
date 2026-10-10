local D=require('Dora');local A=require('CombatAnimation');local Sequence=require('Enemy.Sequence')
local S={};S.__index=S
function S.new(battle,options)
 options=options or {};local unit=options.unit or battle.mentor
 local health=options.health or function()return battle.mentorHP end
 local action=options.action or 'pursuitKnockdown'
 local self=setmetatable({value=100,max=100,knockdowns=0,lastHit=-math.huge,down=false,battle=battle,records={},unit=unit,health=health,action=action},S)
 local staminaRef=setmetatable({self},{__mode='v'})
 D.Platformer.UnitAction:add(action,{priority=10,reaction=0,recovery=.2,
  available=function()local self=staminaRef[1];return self~=nil and self.battle.phase=='playing' and self.health()>0 end,
  create=function(unit)
   local self=staminaRef[1];if not self then return function()return true end end
   local battle,health=self.battle,self.health
   self.down=true;self.knockdowns=self.knockdowns+1;unit.velocityX=0
   unit.playable:slot('attack'):clear()
   local record={started=D.App.runningTime,stages={}};self.records[#self.records+1]=record
   local sequence=Sequence.new({now=function()return D.App.runningTime end,
    play=function(name)
     unit.data.combatCompletedName='';unit.data.combatCompletedAt=-1
     local duration=A.play(unit,name,false);record.stages[#record.stages+1]={name=name,started=D.App.runningTime,duration=duration};return duration
    end,
    complete=function()record.completed=D.App.runningTime;self.value=40;self.lastHit=D.App.runningTime end,
    stop=function(reason)record.cancelled=reason end})
   self.sequence=sequence;sequence:start({{name='fall'},{name='standUp'}})
   return function()
    unit.velocityX=0
    if battle.phase~='playing' or health()<=0 then sequence:cancel('BATTLE_ENDED');return true end
    local stage=sequence.stages[sequence.index]
    if stage and unit.data.combatCompletedName==stage.name and (unit.data.combatCompletedAt or -1)>=sequence.started then sequence:ended(stage.name,sequence.serial,sequence.index)end
    sequence:update();return sequence.status~='playing'
   end
  end,
  stop=function(unit)
   local self=staminaRef[1];if not self then return end
   local sequence=self.sequence;local battle,health=self.battle,self.health
   if sequence and sequence.status=='playing' then sequence:cancel('INTERRUPTED')end
   self.sequence=nil
   self.down=false;unit.velocityX=0
   if battle.phase=='playing' and health()>0 then A.rest(unit)end
  end})
 unit:attachAction(action)
 return self
end
function S:hit(amount)
 if self.down or self.battle.phase~='playing' then return end
 self.lastHit=D.App.runningTime;self.value=math.max(0,self.value-amount)
 if self.value==0 and self.health()>0 then self.unit:start(self.action)end
end
function S:update(dt)
 if not self.down and D.App.runningTime-self.lastHit>2.5 then self.value=math.min(self.max,self.value+12*dt)end
end
return S
