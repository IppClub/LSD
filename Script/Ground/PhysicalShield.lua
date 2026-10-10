-- Finite shared physical protection. Life-field healing/environment rules stay
-- in LifeSupport; only actual enemy attacks spend this shield and its energy.
local M={version=1,rules={defence={capacity=80},cargo={capacity=50},mobility={capacity=50},radius=240,height=260,recharge=6,delay=4,energyPerDamage=.04}}
local Shield={};Shield.__index=Shield
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function close(a,b)return finite(a)and finite(b)and math.abs(a-b)<1e-6 end
local function snapshot(s)return {capacity=s.capacity,charge=s.charge,gold=s.support.gold,machineHP=s.support.machineHP,delayUntil=s.state.delayUntil}end
function M.new(s,now)
 assert(finite(now)and finite(s.gold)and finite(s.machineHP),'Invalid shield host')
 local capacity=assert(M.rules[s.variant or 'defence'],'Unknown auxiliary variant').capacity
 local state=s.physicalShield
 if not state then state={version=1,capacity=capacity,charge=capacity,delayUntil=now,chargeAt=now};s.physicalShield=state end
 assert(state.version==1 and state.capacity==capacity and finite(state.charge)and state.charge>=0 and state.charge<=capacity,'Invalid carried shield')
 local self=setmetatable({support=s,state=state,capacity=capacity,charge=state.charge,events={}},Shield)
 self.initial=snapshot(self);return self
end
function Shield:append(e)
 if #self.events>=1500 then self.truncated=true else self.events[#self.events+1]=e;e.index=#self.events end
 self.state.charge=self.charge
end
function Shield:update(now)
 if self.closed then return end
 local state=self.state
 if self.support.gold<=0 or self.support.machineHP<=0 or self.charge>=self.capacity then state.chargeAt=now;return end
 local dt=now-math.max(state.chargeAt,state.delayUntil)
 if dt<.5 then return end
 dt=math.min(.5,dt);state.chargeAt=now
 local before=self.charge;self.charge=math.min(self.capacity,before+M.rules.recharge*dt)
 self:append({kind='recharge',at=now,dt=dt,chargeBefore=before,chargeAfter=self.charge,goldBefore=self.support.gold,goldAfter=self.support.gold,machineHP=self.support.machineHP})
end
function Shield:resolve(amount,x,y,now,context)
 assert(finite(amount)and amount>=0 and finite(x)and finite(y)and finite(now),'Invalid shield impact')
 local kind=context and context.kind
 if self.closed or (kind~='enemy-melee'and kind~='enemy-wave')then return amount end
 local s=self.support;local before=self.charge;local energy=s.gold
 local eligible=s.machineHP>0 and energy>0 and math.abs(x-s.x)<=M.rules.radius and math.abs(y)<=M.rules.height
 local absorbed=eligible and math.min(amount,before,energy/M.rules.energyPerDamage)or 0
 self.charge=before-absorbed;s.gold=math.max(0,energy-absorbed*M.rules.energyPerDamage)
 s.spent=s.spent+energy-s.gold;s.active=s.gold>0 and s.machineHP>0
 if absorbed>0 then self.state.delayUntil=now+M.rules.delay;self.state.chargeAt=self.state.delayUntil;s.shieldImpactSerial=(s.shieldImpactSerial or 0)+1 end
 local e={kind='impact',attackKind=kind,skill=context.skill or 'unknown',actor=context.actor or 'unknown',at=now,incoming=amount,absorbed=absorbed,remaining=amount-absorbed,chargeBefore=before,chargeAfter=self.charge,goldBefore=energy,goldAfter=s.gold,machineHP=s.machineHP,x=x,y=y,machineX=s.x,eligible=eligible}
 -- Preserve actual incoming-contact identity for simultaneous Boss/summon hits.
 -- Optional fields retain compatibility with already saved shield reports.
 if context.attackerId then e.attackerId=context.attackerId;e.strikeStarted=context.strikeStarted;e.hitIndex=context.hitIndex end
 self:append(e);return e.remaining,e
end
function Shield:finish(now)
 if not self.closed then self.closed=true;self.finished=now;self.final=snapshot(self)end
 return {schemaVersion=1,closed=true,variant=self.support.variant or 'defence',initial=self.initial,final=self.final,events=self.events,finished=self.finished,truncated=self.truncated}
end
function Shield:status()
 if self.support.machineHP<=0 or self.support.gold<=0 then return '停机'end
 return self.charge<=0 and '耗尽'or self.charge<self.capacity and '恢复中'or '就绪'
end
function M.validate(t,vitals)
 if type(t)~='table'or t.schemaVersion~=1 or not t.closed or t.truncated or not M.rules[t.variant]or type(t.initial)~='table'or type(t.final)~='table'or type(t.events)~='table'or #t.events>1500 or not finite(t.finished)then return false end
 local capacity=M.rules[t.variant].capacity;local charge=t.initial.charge;local last=-math.huge;local lastRecharge=-math.huge;local delay=t.initial.delayUntil
 if not finite(delay)or t.initial.capacity~=capacity or not finite(charge)or charge<0 or charge>capacity then return false end
 for i,e in ipairs(t.events)do
  if type(e)~='table'or e.index~=i or not finite(e.at)or e.at<last or e.at>t.finished or not close(e.chargeBefore,charge)or not finite(e.goldBefore)or e.goldBefore<0 or not finite(e.machineHP)or e.machineHP<0 or e.machineHP>100 then return false end
  if e.kind=='impact'then
   if e.attackerId~=nil or e.strikeStarted~=nil or e.hitIndex~=nil then
    if type(e.attackerId)~='string'or e.attackerId==''or #e.attackerId>128 or not finite(e.strikeStarted)or e.strikeStarted>e.at or not finite(e.hitIndex)or e.hitIndex<1 or e.hitIndex%1~=0 then return false end
   end
   if not finite(e.incoming)or e.incoming<0 or not finite(e.x)or not finite(e.y)or not finite(e.machineX)or (e.attackKind~='enemy-melee'and e.attackKind~='enemy-wave')then return false end
   local eligible=e.machineHP>0 and e.goldBefore>0 and math.abs(e.x-e.machineX)<=M.rules.radius and math.abs(e.y)<=M.rules.height
   local absorbed=eligible and math.min(e.incoming,charge,e.goldBefore/M.rules.energyPerDamage)or 0
   if e.eligible~=eligible or not close(e.absorbed,absorbed)or not close(e.remaining,e.incoming-absorbed)or not close(e.goldAfter,e.goldBefore-absorbed*M.rules.energyPerDamage)or not close(e.chargeAfter,charge-absorbed)then return false end
   if e.hpBefore~=nil then
    if not finite(e.hpBefore)or e.hpBefore<0 or e.hpBefore>100 or not close(e.hpAfter,math.max(0,e.hpBefore-e.remaining))then return false end
   end
   if vitals and e.actor~='machine'then
    if e.hpBefore==nil then return false end
    if e.hpAfter<e.hpBefore then
     local found=false
     for _,v in ipairs(vitals.events or {})do
      if v.physicalShieldEvent==e.index and v.actor==e.actor and close(v.at,e.at)and close(v.before,e.hpBefore)and close(v.after,e.hpAfter)and v.kind==e.attackKind and v.skill==e.skill and (not e.attackerId or v.attackerId==e.attackerId and v.strikeStarted==e.strikeStarted and v.hitIndex==e.hitIndex)then found=true;break end
     end
     if not found then return false end
    end
   end
   if absorbed>0 then delay=e.at+M.rules.delay end
  elseif e.kind=='recharge'then
   if not finite(e.dt)or e.dt<=0 or e.dt>.5 or e.at-e.dt<delay-1e-6 or e.at-lastRecharge<e.dt-1e-6 or e.machineHP<=0 or e.goldBefore<=0 or not close(e.goldAfter,e.goldBefore)or not close(e.chargeAfter,math.min(capacity,charge+M.rules.recharge*e.dt))then return false end
   lastRecharge=e.at
  else return false end
  charge=e.chargeAfter;last=e.at
 end
 return t.final.capacity==capacity and close(t.final.charge,charge)and finite(t.final.gold)and t.final.gold>=0 and finite(t.final.machineHP)and t.final.machineHP>=0 and t.final.machineHP<=100
end
-- Raw decision-time facts accompany the categorical learning projection.
function M.observe(shield,x,y)
 if not shield then return {schemaVersion=1,present=false}end
 return {schemaVersion=1,present=true,variant=shield.support.variant or 'defence',charge=shield.charge,capacity=shield.capacity,gold=shield.support.gold,machineHP=shield.support.machineHP,machineX=shield.support.x,ownX=x,ownY=y}
end
function M.project(o)
 if type(o)~='table'or o.schemaVersion~=1 or type(o.present)~='boolean'then return end
 if not o.present then return {shieldState='absent',shieldCharge='unknown'}end
 for _,k in ipairs({'charge','capacity','gold','machineHP','machineX','ownX','ownY'})do if not finite(o[k])then return end end
 if not M.rules[o.variant]or o.capacity~=M.rules[o.variant].capacity or o.charge<0 or o.charge>o.capacity or o.gold<0 or o.machineHP<0 or o.machineHP>100 then return end
 local state=o.machineHP<=0 or o.gold<=0
 local status=state and 'stopped'or math.abs(o.ownX-o.machineX)>M.rules.radius or math.abs(o.ownY)>M.rules.height
 return {shieldState=state and 'stopped'or status and 'outside'or o.charge<=0 and 'empty'or 'covered',shieldCharge=o.charge<=0 and 'empty'or o.charge<=o.capacity*.25 and 'low'or 'ready'}
end
return M
