-- One order per physical press, with a distinct deliberate hold for recovery.
-- Clock and callbacks belong to the host; this module has no engine state.
local G={holdSeconds=.65};G.__index=G
function G.new(canIssue,command,isRecovering)
 return setmetatable({canIssue=canIssue,command=command,isRecovering=isRecovering,held={}},G)
end
function G:clear()
 self.held={};self.started=nil;self.longIssued=false;self.deferredGather=false
end
function G:press(source,now)
 if not self.canIssue()or self.held[source]then return false end
 local first=next(self.held)==nil
 self.held[source]=true
 if first then
  self.started=now;self.longIssued=false
  -- A deliberate hold must not revoke the recovery it is continuing. Defer
  -- only this short cancellation until release distinguishes it from a hold.
  self.deferredGather=self.isRecovering and self.isRecovering()or false
  if not self.deferredGather then self.command('gather')end
 end
 return true
end
function G:release(source)
 if not self.held[source]then return false end
 self.held[source]=nil
 if not next(self.held)then
  local cancel=self.deferredGather and not self.longIssued and self.canIssue()
  self.started=nil;self.longIssued=false;self.deferredGather=false
  if cancel then return self.command('gather')end
 end
 return true
end
function G:update(now)
 if not self.canIssue()then self:clear();return false end
 if self.started and not self.longIssued and now-self.started>=G.holdSeconds then
  self.longIssued=true
  return self.command('recover-gather')
 end
 return false
end
return G
