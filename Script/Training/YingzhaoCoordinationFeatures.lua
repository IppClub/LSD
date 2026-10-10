-- Visible teammate geometry, independent of enemy targeting and skill alignment.
local C={names={'mentorSide','mentorDistance'},categories={mentorSide='unknown left overlap right',mentorDistance='unknown close near far'}}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function C.project(raw)
 if type(raw)~='table'or raw.schemaVersion~=1 or type(raw.present)~='boolean'or not finite(raw.ownX)then return nil end
 if not raw.present then if raw.mentorX~=nil then return nil end;return {mentorSide='unknown',mentorDistance='unknown'}end
 if not finite(raw.mentorX)then return nil end
 local dx=raw.mentorX-raw.ownX;local gap=math.abs(dx)
 return {mentorSide=gap<=.01 and'overlap'or dx<0 and'left'or'right',mentorDistance=gap<=require('Ground.LifeSupport').healingRange and'close'or gap<=700 and'near'or'far'}
end
function C.capture(b,owner)
 local raw={schemaVersion=1,present=b.mentorHP>0,ownX=owner.x}
 if raw.present then raw.mentorX=b.mentor.x end
 return raw,assert(C.project(raw))
end
function C.validate(s)
 local values=C.project(s.coordination)
 if not values or s.coordination.ownX~=s.ownX then return false end
 if s.coordination.present and s.skillControl and s.coordination.mentorX~=s.skillControl.mentorX then return false end
 for _,name in ipairs(C.names)do if values[name]~=s[name]then return false end end
 return true
end
return C
