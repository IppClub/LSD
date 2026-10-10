-- Own HUD/position facts only. Never expose the Boss's private reaction timer.
local S={}
S.categories={skillState='unknown ready casting cooldown busy airborne displaced inactive absent',skillCooldown='unknown ready soon cooling',skillTargetSide='unknown left right overlap',skillDefaultFacing='unknown toward away',fireAimLeft='unknown left aligned right',fireAimRight='unknown left aligned right'}
S.names={'skillState','skillCooldown','skillTargetSide','skillDefaultFacing','fireAimLeft','fireAimRight'}
local states={ALREADY_CASTING='casting',COOLDOWN='cooldown',ACTION_BUSY='busy',AIRBORNE='airborne',DISPLACED='displaced',NOT_PLAYING='inactive',ROLE_ABSENT='absent'}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function offset(dx)return dx< -120 and'left'or dx>120 and'right'or'aligned'end
function S.values(raw,at,ownX,targetX)
 if type(raw)~='table'or(raw.skill~='wind'and raw.skill~='fire')or not finite(at)or not finite(ownX)or not finite(raw.readyAt)or type(raw.available)~='boolean'or type(raw.mentorFaceRight)~='boolean'or not finite(raw.mentorX)or(targetX~=nil and not finite(targetX))then return nil end
 if raw.available then if raw.reason~=nil or raw.readyAt>at then return nil end
 elseif not states[raw.reason]then return nil end
 if raw.reason=='COOLDOWN'and raw.readyAt<=at then return nil end
 local left=raw.readyAt-at
 local v={skillState=raw.available and'ready'or states[raw.reason],skillCooldown=left<=0 and'ready'or left<=1 and'soon'or'cooling',skillTargetSide='unknown',skillDefaultFacing='unknown',fireAimLeft='unknown',fireAimRight='unknown'}
 if targetX then
  local dx=targetX-ownX;v.skillTargetSide=math.abs(dx)<=.01 and'overlap'or dx<0 and'left'or'right'
  v.skillDefaultFacing=(dx>=0)==raw.mentorFaceRight and'toward'or'away'
  if raw.skill=='fire'then v.fireAimLeft=offset(targetX-(raw.mentorX-240));v.fireAimRight=offset(targetX-(raw.mentorX+240))end
 end
 return v
end
function S.capture(b,owner,targetX,at)
 local name=owner==b.arena.student and'fire'or b.wuyun and owner==b.wuyun.student and'wind'
 if not name or not b.magic then return end
 -- Cooldown must use the observation timestamp, even when aim tracing crosses its expiry.
 local available,reason=b.magic:available(name,at)
 local raw={skill=name,readyAt=b.magic.ready[name],available=available,reason=reason,mentorX=b.mentor.x,mentorFaceRight=b.mentor.faceRight}
 return raw,assert(S.values(raw,at,owner.x,targetX))
end
function S.validate(s)
 if not s.skillControl then for _,name in ipairs(S.names)do if s[name]~='unknown'then return false end end;return true end
 local v=S.values(s.skillControl,s.at,s.ownX,s.targetX);if not v then return false end
 for _,name in ipairs(S.names)do if s[name]~=v[name]then return false end end
 return true
end
return S
