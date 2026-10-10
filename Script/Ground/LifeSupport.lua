-- Ground-life rules shared by exploration and future battles, independent of rendering.
local Support={version=2,healingRange=120,healingRate=3}; Support.__index=Support
function Support.new(gold,variant)
 return setmetatable({ruleVersion=Support.version,gold=gold or 45,variant=variant or "defence",collectionSerial=0,hp={100,100},machineHP=100,collected={},spent=0,healed=0,hazardDamage=0},Support)
end
-- Upkeep excludes attack-dependent shield spending: this is an upper bound,
-- not a promise that the machine will remain powered for this long.
function Support:energyRate() return 0.35+(self.span or 0)/1000 end
function Support:energyObservation()
 local rate=self:energyRate()
 return {rate=rate,seconds=self.machineHP>0 and self.gold/rate or 0,span=self.span or 0,powered=self.machineHP>0 and self.gold>0}
end
-- Read-only combat cues. Upkeep time excludes future shield impacts.
function Support:warningText()
 if self.machineHP<=0 then return '辅助机被摧毁\n调查行动中止',true end
 if self.gold<=0 then return '金粉耗尽 · 维生场停机\n及时撤离',true end
 local lines={};local danger=self.machineHP<=30
 if danger then lines[#lines+1]='机体危急 · 保护辅助机'
 elseif self.machineHP<=70 then lines[#lines+1]='机体受损 · 保护辅助机'end
 if self:energyObservation().seconds<=20 then
  lines[#lines+1]='金粉将耗尽 · G集合/撤离'
 elseif self.physicalShield and self.physicalShield.charge<=0 then
  lines[#lines+1]='护盾耗尽 · 避开攻击'end
 return table.concat(lines,'\n'),danger
end
function Support:update(dt,left,right,anchor)
 local positions=type(left)=="table" and left or {left,right}
 -- Preserve role indices for healing/hazard accounting, but a defeated
 -- body cannot drag the machine or inflate the active squad's energy cost.
 local low,high
 for i,x in ipairs(positions) do
  if (self.hp[i] or 0)>0 then
   low=low and math.min(low,x) or x;high=high and math.max(high,x) or x
  end
 end
 if not low then low=self.x or positions[1];high=low end
 assert(dt>=0 and dt<=1,"Life support step must be bounded")
 if anchor then
  self.x=anchor.x; self.radius=anchor.radius
 else
  if not self.x or (self.gold>0 and self.machineHP>0) then self.x=(low+high)/2 end
  self.radius=math.max(180,(high-low)/2+90)
 end
 self.span=high-low
 self.active=self.gold>0 and self.machineHP>0
 if self.active then
  local used=math.min(self.gold,dt*self:energyRate()); self.gold=self.gold-used; self.spent=self.spent+used
 end
 self.active=self.gold>0 and self.machineHP>0
 for i,x in ipairs(positions) do
  if not self.active or math.abs(x-self.x)>self.radius then
   local n=math.min(self.hp[i],dt*2); self.hp[i]=self.hp[i]-n; self.hazardDamage=self.hazardDamage+n
  elseif self.hp[i]>0 and math.abs(x-self.x)<=Support.healingRange then
   local ceiling=self.maxHP and self.maxHP[i] or 100
   local n=math.max(0,math.min(ceiling-self.hp[i],dt*Support.healingRate)); self.hp[i]=self.hp[i]+n; self.healed=self.healed+n
  end
 end
 return self.active
end
function Support:collect(id,amount,x,left,right)
 if self.collected[id] or self.machineHP<=0 then return false end
 if math.min(math.abs(x-left),math.abs(x-right),math.abs(x-(left+right)/2))>70 then return false end
 self.collected[id]=true; self.collectionSerial=self.collectionSerial+1; self.lastCollection={id=id,x=x,amount=amount}; self.gold=math.min(90,self.gold+amount); return true
end
function Support:damageMachine(amount) self.machineHP=math.max(0,self.machineHP-amount) end
return Support
