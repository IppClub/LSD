-- Original twin rigs; defer reaction transitions until the native update completes.
local D=require('Dora');local Actor={};Actor.__index=Actor
function Actor.loadAsync()for _,asset in ipairs({'yu','vika','vivi'})do D.Cache:loadAsync('spine:'..asset)end end
function Actor.new(asset,parent,x,y)
 assert(asset=='yu'or asset=='vika'or asset=='vivi')
 local model=assert(D.Spine(asset));model.position=D.Vec2(x,y);model.recovery=.2;model.speed=1;model:addTo(parent)
 local self=setmetatable({asset=asset,model=model,state='idle',hp=100,completed={},distance=0,events={}},Actor)
 model:slot('AnimationEnd',function(name)
  self.completed[name]=(self.completed[name]or 0)+1
  local r=self.reaction
  -- Never start a new track inside the Spine completion callback. Ignore a
  -- same-name old mixing track's early end; require the actual clip duration.
  if r and r.clip==name and not r.ended and D.App.totalTime-r.started>=r.duration-.025 then
   r.ended=D.App.totalTime
  end
 end)
 model:play('idle',true);return self
end
function Actor:log(kind,clip,extra)
 local row={kind=kind,clip=clip,at=D.App.totalTime,hp=self.hp}
 if extra then for k,v in pairs(extra)do row[k]=v end end
 self.events[#self.events+1]=row;if #self.events>64 then table.remove(self.events,1)end
end
function Actor:playReaction(clip)
 assert(not self.reaction,'Reaction interrupted')
 self.model.recovery=.2;self.model.speed=1;self.state=clip
 local duration=self.model:play(clip,false);assert(duration>0,'Missing twin reaction '..clip)
 self.reaction={clip=clip,started=D.App.totalTime,duration=duration}
 self:log('start',clip,{duration=duration});self.down=false
end
function Actor:isReacting()return self.reaction~=nil or self.downWait~=nil end
function Actor:blocksMovement()return self.hp<=0 or self:isReacting()end
function Actor:update(velocity,dt)
 assert(type(dt)=='number' and dt>=0)
 local dx=velocity*dt;self.model.x=self.model.x+dx;self.distance=self.distance+math.abs(dx)
 local r=self.reaction
 if r and r.ended and D.App.totalTime-r.started>=r.duration then
  self:log('complete',r.clip,{duration=r.duration,elapsed=D.App.totalTime-r.started,nativeElapsed=r.ended-r.started})
  self.reaction=nil
  if r.clip=='fall'then
   self.state='down';self.down=true;self.model:play('down',true)
   if self.hp>0 then self.downWait=.3 end
  elseif self.hp<=0 then self.pending=nil;self:playReaction('fall')
  elseif r.clip=='standUp'then self.down=false
  end
 end
 if self.downWait then
  if self.hp<=0 then self.downWait=nil;self.pending=nil
  else
   self.downWait=self.downWait-dt
   if self.downWait<=0 then self.downWait=nil;self:playReaction('standUp')end
  end
 end
 if not self.reaction and not self.downWait and not self.down and self.pending then
  local clip=self.pending;self.pending=nil;self:playReaction(clip)
 end
 if self.reaction or self.down then return end
 local state=math.abs(velocity)>.001 and'fmove'or'idle'
 if velocity~=0 then self.model.fliped=velocity<0 end
 if self.state~=state then self.state=state;self.model.recovery=.2;self.model.speed=1;self.model:play(state,true)end
end
function Actor:damage(amount)
 assert(type(amount)=='number'and amount>=0 and amount<math.huge)
 local dealt=math.min(self.hp,amount);self.hp=self.hp-dealt
 if dealt<=0 or self.asset=='yu'then return dealt end
 local wanted=(self.hp<=0 or dealt>=18)and'fall'or'hurt'
 self:log('damage',wanted,{dealt=dealt})
 if self.hp<=0 then
  -- Fatal damage during a fall/down cannot restart it or resurrect the actor.
  if self.down then self.downWait=nil;self.pending=nil
  elseif self.reaction and self.reaction.clip=='fall'then self.pending=nil
  elseif not self.reaction then self:playReaction('fall')
  else self.pending='fall'end
 elseif not self.reaction and not self.down then self:playReaction(wanted)
 elseif self.pending~='fall'then self.pending=wanted end
 return dealt
end
return Actor
