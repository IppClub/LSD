-- Manual learner control uses the same legal action executor as adopted models.
local M={}
function M.attach(b,id)
 local selected
 for _,a in ipairs(b.learners)do if a.character.id==id then selected=a end end
 assert(selected,'Unknown disarm demonstrator');b.demonstrator=selected;b.controlledUnit=selected.student
 local start=b.start
 b.start=function(self,...)
  local ok=start(self,...);if ok then selected.mode='demo';selected.recorder.active=false end;return ok
 end
 local command=b.command
 b.command=function(self,name,...)
  if name~='left'and name~='right'and name~='stop'and name~='shoot'and name~='melee'then return command(self,name,...)end
  if self.closed or selected.closed or not selected.student.parent or not selected.world.parent then return false,'CLOSED'end
  if self.phase~='playing'then return false,'NOT_PLAYING'end
  if require('Combat.Displacement').blocked(selected.student)then return false,'DISPLACED'end
  if name=='shoot'or name=='melee'then return selected:request(name=='shoot'and 'laser'or'melee','demo')end
  if name=='stop'then
   if selected:isAttacking()then return false,'ACTION_BUSY'end
   if selected.student:isDoing(selected.physical.idle)then return true,'CONTINUED'end
   selected.student:stop();selected.student.velocityX=0;return selected:request('idle','demo')
  end
  local target=self:target(selected.student);if not target then return false,'NO_TARGET'end
  local face=target.enemy.x>=selected.student.x
  local toward=(name=='right')==face;local action=toward and 'fmove'or'bmove'
  if selected.student:isDoing(selected.physical[action])then
   if selected.student.faceRight==face then return true,'CONTINUED'end
   -- End the old directional interval before starting the opposite one, so
   -- the movement trace never attributes both directions to one decision.
   selected.student:stop()
  end
  return selected:request(action,'demo',face)
 end
end
return M
