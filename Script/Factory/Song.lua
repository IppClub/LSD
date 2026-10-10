-- Wuyun's emergency chant uses the original comm gesture to completion, no fake attack event.
local D=require("Dora")
local Animation=require("CombatAnimation")
local Song={}; Song.__index=Song
function Song:request()
 local a=self.arena; local now=D.App.runningTime
 if a.closed or (a.mode~="demo" and a.mode~="trial") or a.studentHP<=0 then return false,"NOT_PLAYING" end
 if require('Combat.Displacement').blocked(a.student)then return false,'DISPLACED'end
 if a.student:isDoing(self.action) then return false,"ALREADY_CASTING" end
 if now<self.ready then return false,"COOLDOWN" end
 local state=self.effects.states[a.student]
 if state and now<(state.virusUntil or 0) then return false,"EQUIPMENT_DISABLED" end
 if a:isAttacking() then self.pending=now+2; return true,"QUEUED_AFTER_ATTACK" end
 return a.student:start(self.action),"STARTED"
end
function Song:update()
 if self.pending then
  if D.App.runningTime>self.pending or self.arena.studentHP<=0 then self.pending=nil
  elseif not self.arena:isAttacking() then self.pending=nil; self:request() end
 end
end
function Song.new(arena,effects)
 assert(arena.character.id=="wuyun","Only Wuyun knows this chant")
 local self=setmetatable({arena=arena,effects=effects,action=arena.physical.laser.."_Chant",ready=0,logs={}},Song)
 local inherited=arena.isAttacking
 arena.isAttacking=function(a) return inherited(a) or a.student:isDoing(self.action) end
 -- The registry outlives scenes; only active actions may own the song.
 local songRef=setmetatable({self},{__mode="v"})
 D.Platformer.UnitAction:add(self.action,{priority=4,reaction=0,recovery=0.2,
  available=function(u) local self=songRef[1]; local arena=self and self.arena; return arena~=nil and not arena.closed and not require('Combat.Displacement').blocked(u) and u.onSurface and arena.studentHP>0 and D.App.runningTime>=self.ready end,
  create=function(u)
   local self=songRef[1]; if not self or self.arena.closed then return function()return true end end
   local arena=self.arena
   self.ready=D.App.runningTime+8; u.velocityX=0
   local log={startedAt=D.App.runningTime,animation="comm",noAttackEvent=true}; self.logs[#self.logs+1]=log
   u.playable:slot("attack"):set(function() log.unexpectedAttackEvent=true end)
   return D.once(function()
    local completed
    log.duration,completed=Animation.playOnceAsync(u,"comm")
    if not completed then
     log.interruptedAt=D.App.runningTime;log.interruptedReason=u.data.combatAnimationFailure
     if not arena.closed and arena.studentHP>0 then Animation.rest(u)end
     return true
    end
    log.completedAt=D.App.runningTime
    if not arena.closed and arena.studentHP>0 and (arena.mode=="demo" or arena.mode=="trial") then
     log.releaseAt=D.App.runningTime; log.cleared=self.effects:song(u.x,950); Animation.rest(u)
    end
    return true
   end)
  end,
  stop=function(u)
   local self=songRef[1]; if not self then return end
   local arena=self.arena
   local log=self.logs[#self.logs]
   if log and not log.completedAt and not log.interruptedAt then log.interruptedAt=D.App.runningTime; log.interruptedReason=arena.studentHP<=0 and "defeated" or "withdrawn" end
   if not arena.closed and arena.studentHP>0 then Animation.rest(u) end
  end})
 arena.student:attachAction(self.action); return self
end
return Song
