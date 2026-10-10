-- Skill evidence supplements existing resource/damage replay. Old archives have no skill version.
local S={}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function S.step(row,index)
 local s=row.skill
 if type(s)~='table'or s.schemaVersion~=1 or s.step~=index or s.skill~=row.action or s.actor~=row.actor or s.source~=row.origin then return false end
 if row.actor~=(row.action=='wind'and'wuyun'or'ninilite')or(s.direction~=1 and s.direction~=-1)then return false end
 if not finite(s.requestedAt)or not finite(s.startedAt)or not finite(s.endedAt)or not finite(s.cooldownUntil)or s.requestedAt>s.startedAt or s.endedAt<s.startedAt or s.cooldownUntil<s.startedAt then return false end
 if row.started~=s.startedAt or row.ended~=s.endedAt or not row.after then return false end
 local before=row.before
 if type(before)=='table'and type(before.featureSchemaVersion)=='number'and before.featureSchemaVersion>=6 then
  if type(before.skillControl)~='table'or before.skillControl.skill~=row.action or before.skillState~='ready'or before.skillCooldown~='ready'or not finite(before.at)or before.at>row.started or row.started-before.at>.1 then return false end
 end
 if row.action=='fire'and not finite(s.aim)then return false end
 if s.status=='completed'then if s.completedAt~=s.endedAt or s.cancelledAt~=nil then return false end
 elseif s.status=='cancelled'then if s.cancelledAt~=s.endedAt or s.completedAt~=nil or type(s.reason)~='string'then return false end
 else return false end
 if s.releaseAt~=nil then
  if not finite(s.releaseAt)or s.releaseAt<s.startedAt or s.releaseAt>s.endedAt or row.emitted~=1 then return false end
 elseif row.emitted~=nil then return false end
 return true
end
function S.hit(hit,steps,seen)
 local row=hit.step and steps[hit.step];local action=hit.weapon=='wind'and'wind'or'fire'
 if not row or row.action~=action or row.actor~=hit.source or not row.skill or not row.skill.releaseAt or not finite(hit.at)or hit.at<row.skill.releaseAt then return false end
 local key=tostring(hit.step)
 if action=='wind'then key=key..':'..tostring(hit.target);if seen[key]then return false end;seen[key]=true
 else seen[key]=(seen[key]or 0)+1;if seen[key]>3 then return false end end
 return true
end
return S
