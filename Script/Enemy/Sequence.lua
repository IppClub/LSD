-- One authored skill, possibly split across multiple finite Spine clips.
-- The host forwards AnimationEnd; elapsed time alone never advances a clip.
local Sequence={};Sequence.__index=Sequence
function Sequence.new(host)
 assert(host and host.play and host.now,'Sequence requires play and monotonic clock')
 return setmetatable({host=host,status='idle',serial=0},Sequence)
end
function Sequence:start(stages)
 if self.status=='playing' then return false,'BUSY' end
 assert(type(stages)=='table' and #stages>0,'Empty skill sequence')
 local copy={}
 for i,s in ipairs(stages)do
  assert(type(s.name)=='string' and s.name~='','Missing clip name')
  local impacts={};local previous=-1
  for j,t in ipairs(s.impacts or {})do
   assert(type(t)=='number' and t==t and t>=0 and t<math.huge and t>=previous,'Invalid impact time')
   impacts[j]=t;previous=t
  end
  copy[i]={name=s.name,impacts=impacts}
 end
 self.serial=self.serial+1;self.stages=copy;self.index=0;self.status='playing';self.error=nil
 self:_next();return self.status=='playing',self.error
end
function Sequence:_fail(reason)
 self.status='failed';self.error=reason
 if self.host.stop then self.host.stop(reason)end
end
function Sequence:_next()
 self.index=self.index+1
 if self.index>#self.stages then
  self.status='complete';if self.host.complete then self.host.complete()end;return
 end
 local stage=self.stages[self.index]
 self.started=self.host.now();self.completed=false;self.nextImpact=1
 self.duration=self.host.play(stage.name,self.serial,self.index)
 if type(self.duration)~='number' or self.duration~=self.duration or self.duration<=0 then self:_fail('MISSING_CLIP:'..stage.name);return end
 for _,time in ipairs(stage.impacts)do
  if time>self.duration then self:_fail('IMPACT_AFTER_CLIP:'..stage.name);return end
 end
end
function Sequence:ended(name,serial,index)
 if self.status~='playing' or serial~=self.serial or index~=self.index or name~=self.stages[self.index].name then return false end
 -- Reject an interrupted same-name track's old completion callback.
 -- The native animation update can precede the scheduled controller by one
 -- frame. Latch that end event, but never advance until the full duration.
 if self.host.now()-self.started<self.duration-1/30 then return false end
 self.completed=true;return true
end
function Sequence:update()
 if self.status~='playing' then return end
 local serial=self.serial
 local stage=self.stages[self.index];local elapsed=self.host.now()-self.started
 while self.nextImpact<=#stage.impacts and elapsed>=stage.impacts[self.nextImpact]do
  local strike=self.nextImpact;self.nextImpact=strike+1
  if self.host.impact then self.host.impact(stage.name,self.index,strike)end
  if self.status~='playing' or self.serial~=serial then return end
 end
 if self.completed and elapsed>=self.duration-.001 then self:_next()
 elseif elapsed>self.duration+2 then self:_fail('END_EVENT_TIMEOUT:'..stage.name)end
end
function Sequence:cancel(reason)
 if self.status~='playing' then return false end
 self.status='cancelled';self.serial=self.serial+1
 if self.host.stop then self.host.stop(reason or 'CANCELLED')end
 return true
end
return Sequence
