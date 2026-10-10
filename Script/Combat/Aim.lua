-- Same sweep/tap convention as Tutorial.System: hold sweeps +/-45 degrees,
-- then slow precision sweeps; release fires, taps <=150ms fire straight.
-- Separate child avoids replacing
-- Unit schedules used by movement, status effects or animation recovery.
local D=require('Dora')
local Aim={};Aim.__index=Aim
function Aim.createLine(owner)
 local line=D.DrawNode();line:drawSegment(D.Vec2(100,0),D.Vec2(150,0),2,D.Color(0xaaffffff));line.tag='aim';line.visible=false;line:addTo(owner);return line
end
function Aim.new(owner,canStart,fire,actionName)
 local self=setmetatable({owner=owner,canStart=canStart,fire=fire,angle=0,held=false,shot=false,closed=false},Aim)
 local line=Aim.createLine(owner);self.line=line
 line:schedule(function()
  if self.closed then return true end
  if self.held then
   if not self.canStart()then self:cancel();return false end
   self.angle,self.precision=require('Tutorial.AimSweep').angle(D.App.runningTime-self.started)
   local facing=owner.faceRight and 1 or -1;line.scaleX=facing;line.angle=self.angle*facing
   line.position=require('Combat.Muzzle').manualLocal(owner,self.angle,owner.faceRight) or D.Vec2.zero
  elseif self.shot and owner:isDoing(actionName or 'groundMentorShot')then
   owner.playable:setBoneRotation('aim',-self.angle)
  elseif self.shot then
   self.shot=false;self.angle=0;owner.playable:setBoneRotation('aim',0)
  end
  return false
 end)
 line:slot('Cleanup',function()self.closed=true;self.held=false;self.shot=false end)
 return self
end
function Aim:begin()
 if self.closed or self.held or self.shot or not self.canStart()then return false end
 self.started=D.App.runningTime;self.held=true;self.precision=false;self.angle=45;self.line.position=require('Combat.Muzzle').manualLocal(self.owner,45,self.owner.faceRight) or D.Vec2.zero;self.line.visible=true;return true
end
function Aim:release()
 if self.closed or not self.held then return false end
 self.held=false;self.line.visible=false
 if not self.canStart()then self.angle=0;return false end
 if D.App.runningTime-self.started<=.15 then self.angle=0 end
 self.shot=true
 local ok=self.fire()
 if not ok then self.shot=false;self.angle=0 end
 return ok
end
-- Automated collaborators commit the same bounded aim used by manual release.
-- This freezes direction/angle; projectile travel still decides the actual hit.
function Aim:fireAt(angle,faceRight)
 if type(angle)~='number'or angle~=angle or math.abs(angle)>45 or type(faceRight)~='boolean'then return false,'INVALID_AIM'end
 if self.closed or self.held or self.shot or not self.canStart()then return false,'AIM_UNAVAILABLE'end
 self.owner.faceRight=faceRight;self.angle=angle;self.shot=true;self.line.visible=false
 self.owner.playable:setBoneRotation('aim',-angle)
 local ok,why=self.fire()
 if not ok then self.shot=false;self.angle=0;self.owner.playable:setBoneRotation('aim',0)end
 return ok,why
end
function Aim:cancel()
 self.held=false;self.line.visible=false
 if not self.shot then self.angle=0 end
end
return Aim
