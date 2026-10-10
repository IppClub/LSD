-- Manual commands share the learner executor. These observations are still
-- separate from the legacy C4.5 recorder until the Boss training schema lands.
local D=require('Dora');local M={}
local parts={head=true,torso=true,flank=true,arms=true,forelegs=true,hindlegs=true,summon=true}
function M.attach(b,id)
 require('Training.DisarmDemonstration').attach(b,id)
 b.demonstrator.continuousDecisions=true
 b.yingzhaoDemonstration=true;b.demonstrationTarget='head'
 local command=b.command
 b.command=function(self,name,value)
  if name=='aim-part'then
   if self.phase~='playing'and self.phase~='ready'then return false,'NOT_PLAYING'end
   if not parts[value]then return false,'UNKNOWN_PART'end
   self.demonstrationTarget=value;return true
  end
  if name=='left'or name=='right'then
   if self.phase~='playing'then return false,'NOT_PLAYING'end
   local a=self.demonstrator
   if require('Combat.Displacement').blocked(a.student)then return false,'DISPLACED'end
   local moving=a.student:isDoing(a.physical.fmove)or a.student:isDoing(a.physical.bmove)
   -- The HUD repeats held input every frame. Keep the same world direction
   -- until the next observation interval; a changed input turns immediately.
   if moving and a.yingzhaoHeldDirection==name and D.App.runningTime<(a.yingzhaoNextMovementSample or 0)then return true,'CONTINUED'end
   local target=self:target(a.student);local face=target and require('Training.YingzhaoActions').movementFaceRight(a.student,target.enemy)
   if not target then face=name=='right'end
   local action=not target and'fmove'or((name=='right')==face and'fmove'or'bmove')
   if a.student:isDoing(a.physical[action])and a.student.faceRight~=face then a.student:stop()end
   local ok,why=a:request(action,'demo',face)
   if ok then a.yingzhaoHeldDirection=name;a.yingzhaoNextMovementSample=D.App.runningTime+.25 end
   return ok,why
  end
  if name=='shoot'then
   if self.phase~='playing'then return false,'NOT_PLAYING'end
   local ok,why=require('Training.YingzhaoActions').request(self,self.demonstrator,'shoot@'..self.demonstrationTarget,'demo');if ok then self.demonstrationFeedback=nil else self.demonstrationFeedback=why end;return ok,why
  end
  if name=='fire'or name=='wind'then
   local a=self.magic.roles[name]
   return self.magic:request(name,{source=a==self.demonstrator and'demo'or'mentor-command'})
  end
  return command(self,name,value)
 end
 return b.demonstrator
end
return M
