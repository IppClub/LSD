-- Per-unit flower status: physical drag, poison, confusion, disabled equipment.
local D=require("Dora")
local Effects={}; Effects.__index=Effects
function Effects.new(targets)
 return setmetatable({targets=targets,states={},logs={},poisonDamage=0,confusions=0,virusHits=0,songReleases=0},Effects)
end
function Effects:state(target)
 local unit=target.unit
 local s=self.states[unit]
 if not s then s={unit=unit,target=target,stamina=100,originalGroup=unit.group}; self.states[unit]=s end
 s.target=target; return s
end
function Effects:alive(target)
 return target.unit.parent and (not target.alive or target.alive())
end
function Effects:apply(target,kind,seconds,strike)
 if not self:alive(target) then return false end
 local now=D.App.runningTime; local s=self:state(target)
 if kind=="confuse" and now<(s.protectedUntil or 0) then return false end
 if kind=="confuse" then s.confusedUntil=math.max(s.confusedUntil or 0,now+seconds); target.unit.group=2; self.confusions=self.confusions+1
 elseif kind=="poison" then s.poisonSource=strike and strike.source or "unknown";s.poisonAttackId=strike and strike.attackId;s.poisonUntil=math.max(s.poisonUntil or 0,now+seconds); s.nextPoison=s.nextPoison or now+1
 elseif kind=="virus" then s.virusUntil=math.max(s.virusUntil or 0,now+seconds); self.virusHits=self.virusHits+1
 else return false end
 if (kind=="virus" or kind=="confuse") and not require('Combat.Displacement').blocked(target.unit) and (not target.isAttacking or not target.isAttacking()) then target.unit:stop(); target.unit.velocityX=0 end
 self.logs[#self.logs+1]={kind=kind,at=now,untilTime=now+seconds,unit=target.unit.entity.name,skill=strike and strike.kind}
 return true
end
function Effects:pull(target,sourceX,strike)
 if not self:alive(target) or target.immovable then return false end
 local s=self:state(target); local u=target.unit; local now=D.App.runningTime
 s.stamina=math.max(0,s.stamina-25)
 s.dragTo=sourceX+(u.x>=sourceX and 110 or -110); s.dragUntil=now+0.8
 if s.stamina==0 then s.exhaustedUntil=now+1.5 end
 if not require('Combat.Displacement').blocked(u) and (not target.isAttacking or not target.isAttacking()) then u:stop() end
 if target.onForcedMovement then target.onForcedMovement({origin='forced',kind='pull',source=strike and strike.source or 'unknown',skill=strike and strike.kind or 'pull',at=D.App.totalTime,x=u.x,y=u.y,velocityX=u.velocityX,velocityY=u.velocityY})end
 self.logs[#self.logs+1]={kind="pull",at=now,unit=u.entity.name,stamina=s.stamina,skill=strike and strike.kind}
 return true
end
function Effects:blocked(unit,action)
 local s=self.states[unit]; if not s then return false end
 local now=D.App.runningTime
 if now<(s.confusedUntil or 0) or now<(s.exhaustedUntil or 0) or now<(s.dragUntil or 0) then return true end
 return now<(s.virusUntil or 0) and (action=="fmove" or action=="bmove" or action=="gather")
end
function Effects:redirect(unit)
 local s=self.states[unit]; if not s or D.App.runningTime>=(s.virusUntil or 0) then return end
 local selected; local distance=math.huge
 for _,target in ipairs(self.targets()) do
  if target.unit~=unit and not target.immovable and self:alive(target) then
   local dx=math.abs(target.unit.x-unit.x); if dx<distance then selected=target; distance=dx end
  end
 end
 return selected
end
function Effects:song(sourceX,radius)
 local now=D.App.runningTime; local count=0
 for _,target in ipairs(self.targets()) do
  if self:alive(target) and not target.immovable and math.abs(target.unit.x-sourceX)<=radius then
   local s=self:state(target)
   if now<(s.confusedUntil or 0) then count=count+1 end
   s.confusedUntil=0; s.protectedUntil=now+6; target.unit.group=s.originalGroup
  end
 end
 self.songReleases=self.songReleases+1
 self.logs[#self.logs+1]={kind="song",at=now,cleared=count,radius=radius,x=sourceX}
 return count
end
function Effects:update(now)
 now=now or D.App.runningTime
 for unit,s in pairs(self.states) do
  if not self:alive(s.target) then
   if unit.parent then unit.group=s.originalGroup end; self.states[unit]=nil
  else
   if now>=(s.confusedUntil or 0) and unit.group~=s.originalGroup then unit.group=s.originalGroup end
   if now<(s.poisonUntil or 0) and now>=(s.nextPoison or math.huge) then
    local dealt=s.target.damage(2,{kind="poison",source=s.poisonSource or "unknown",attackId=s.poisonAttackId,startedAt=now}); self.poisonDamage=self.poisonDamage+(dealt==nil and 2 or dealt); s.nextPoison=now+1
   elseif now>=(s.poisonUntil or 0) then s.nextPoison=nil end
   if now<(s.dragUntil or 0) then
    local dx=s.dragTo-unit.x
    if math.abs(dx)<=25 then s.dragUntil=0; unit.velocityX=0
    else unit.velocityX=dx>=0 and 650 or -650 end
   elseif s.dragUntil then unit.velocityX=0; s.dragUntil=nil end
   if s.exhaustedUntil and now>=s.exhaustedUntil then s.exhaustedUntil=nil; s.stamina=35 end
  end
 end
end
function Effects:clear()
 for unit,s in pairs(self.states) do if unit.parent then unit.group=s.originalGroup; unit.velocityX=0 end end
 self.states={}
end
return Effects
