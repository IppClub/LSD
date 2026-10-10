-- Passive battle and action-boundary counters. No rates are interpolated.
local M={version=1,maxSamples=6002};local Book={};Book.__index=Book
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function close(a,b)return finite(a)and finite(b)and math.abs(a-b)<1e-6 end
local function valid(s)
 return type(s)=='table'and finite(s.at)and finite(s.gold)and s.gold>=0 and s.gold<=90 and finite(s.spent)and s.spent>=0 and finite(s.machineHP)and s.machineHP>=0 and s.machineHP<=100 and finite(s.collectionSerial)and s.collectionSerial>=0 and s.collectionSerial%1==0 and finite(s.shieldEvent)and s.shieldEvent>=0 and s.shieldEvent%1==0 and finite(s.shieldGold)and s.shieldGold>=0
end
function M.open(s,shield,at)
 assert(s and shield and shield.support==s and s.ruleVersion==require('Ground.LifeSupport').version)
 local self=setmetatable({support=s,shield=shield,record={schemaVersion=1,lifeRuleVersion=s.ruleVersion,closed=false,samples={}}},Book)
 self:sample(at);return self
end
function Book:sample(at)
 local r=self.record;if r.closed then return #r.samples end
 local s=self.support;local last=r.samples[#r.samples];local gold=last and last.shieldGold or 0
 for i=(last and last.shieldEvent or #self.shield.events)+1,#self.shield.events do
  local event=self.shield.events[i];if event.kind=='impact'then gold=gold+event.goldBefore-event.goldAfter end
 end
 local row={at=at,gold=s.gold,spent=s.spent,machineHP=s.machineHP,collectionSerial=s.collectionSerial,shieldEvent=#self.shield.events,shieldGold=gold};assert(valid(row),'Invalid support boundary')
 if last and close(last.at,at)and close(last.gold,row.gold)and close(last.spent,row.spent)and close(last.machineHP,row.machineHP)and last.collectionSerial==row.collectionSerial and last.shieldEvent==row.shieldEvent then return #r.samples end
 if #r.samples>=M.maxSamples then r.truncated=true;return #r.samples end
 r.samples[#r.samples+1]=row;return #r.samples
end
function M.interval(r,first,last)
 if not finite(first)or not finite(last)or first%1~=0 or last%1~=0 or first<1 or last<1 then return nil,'INVALID_SUPPORT_INTERVAL'end
 local a=r and r.samples and r.samples[first];local b=r and r.samples and r.samples[last]
 if not valid(a)or not valid(b)or first>last or a.at>b.at or a.collectionSerial~=b.collectionSerial then return nil,'INVALID_SUPPORT_INTERVAL'end
 local total=b.spent-a.spent;local shield=b.shieldGold-a.shieldGold;local hp=a.machineHP-b.machineHP
 if total< -1e-6 or shield< -1e-6 or total-shield< -1e-6 or hp< -1e-6 then return nil,'INVALID_SUPPORT_INTERVAL'end
 return {goldSpent=math.max(0,total),shieldGold=math.max(0,shield),upkeepGold=math.max(0,total-shield),machineDamage=math.max(0,hp)}
end
function M.validate(r,trace)
 if type(r)~='table'or r.schemaVersion~=1 or not r.closed or r.truncated or r.lifeRuleVersion~=require('Ground.LifeSupport').version or type(r.samples)~='table'or #r.samples<1 or #r.samples>M.maxSamples then return false,'INVALID_SUPPORT_ACCOUNT'end
 local count=0;for k in pairs(r.samples)do if type(k)~='number'or k%1~=0 or k<1 or k>#r.samples then return false,'INVALID_SUPPORT_BOUNDARIES'end;count=count+1 end
 if count~=#r.samples or not require('Ground.PhysicalShield').validate(trace)then return false,'INVALID_SUPPORT_BOUNDARIES'end
 local first=r.samples[1];if not valid(first)or first.shieldEvent>#trace.events or first.shieldGold~=0 then return false,'INVALID_SUPPORT_BASELINE'end
 for i=1,first.shieldEvent do if trace.events[i].at>first.at then return false,'INVALID_SUPPORT_BASELINE'end end
 local gold,hp=0,first.machineHP;local prior=first
 for i,row in ipairs(r.samples)do
  if not valid(row)or row.at<prior.at or row.shieldEvent<prior.shieldEvent or row.shieldEvent>#trace.events or row.collectionSerial~=first.collectionSerial then return false,'INVALID_SUPPORT_BOUNDARIES'end
  for j=prior.shieldEvent+1,row.shieldEvent do
   local event=trace.events[j];if event.at<prior.at or event.at>row.at then return false,'SUPPORT_EVENT_INTERVAL_MISMATCH'end
   if event.kind=='impact'then
    gold=gold+event.goldBefore-event.goldAfter
    if event.actor=='machine'then
     if not close(event.hpBefore,hp)or not finite(event.hpAfter)then return false,'MACHINE_DAMAGE_CHAIN_MISMATCH'end
     hp=event.hpAfter
    end
   end
  end
  if not close(row.shieldGold,gold)or not close(row.machineHP,hp)or not close(row.spent-prior.spent,prior.gold-row.gold)or not M.interval(r,i>1 and i-1 or 1,i)then return false,'SUPPORT_COUNTER_MISMATCH'end
  prior=row
 end
 if not close(r.finished,trace.finished)or not close(prior.at,r.finished)or prior.shieldEvent~=#trace.events or not close(prior.gold,trace.final.gold)or not close(prior.machineHP,trace.final.machineHP)then return false,'SUPPORT_SHIELD_MISMATCH'end
 local total=assert(M.interval(r,1,#r.samples));for k,v in pairs(total)do if not close(r[k],v)then return false,'SUPPORT_COMPONENT_MISMATCH'end end
 return true
end
function Book:finish(trace,at)
 if self.result then return self.result end
 if not self.record.closed then self:sample(at)end;local r=self.record;r.closed=true;r.finished=at
 local total,why=M.interval(r,1,#r.samples);if not total then return nil,why end
 for k,v in pairs(total)do r[k]=v end
 local ok,why=M.validate(r,trace);if not ok then return nil,why end
 self.result=r;return r
end
return M
