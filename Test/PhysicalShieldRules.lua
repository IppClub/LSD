package.path='Script/?.lua;'..package.path
local M=require('Ground.PhysicalShield')
local function support(gold,hp,variant)return {gold=gold or 45,machineHP=hp or 100,x=500,spent=0,variant=variant or 'defence'}end
local function impact(s,n,x,y,at)
 local remaining,e=s:resolve(n,x or 500,y or 0,at or 0,{kind='enemy-wave',actor='mentor',skill='wave'})
 if e then e.hpBefore=100;e.hpAfter=math.max(0,100-remaining)end
 return remaining,e
end
local cases=0
local host=support();local shield=M.new(host,0)
for i=1,4 do assert(impact(shield,18)==0)end
assert(impact(shield,18)==10 and shield.charge==0 and math.abs(host.gold-41.8)<1e-8);cases=cases+1
shield:update(4);assert(shield.charge==0);shield:update(4.5);assert(shield.charge==3);shield:update(5);assert(shield.charge==6);cases=cases+1
local trace=shield:finish(5);assert(M.validate(trace));trace.events[1].absorbed=0;assert(not M.validate(trace));trace.events[1].absorbed=18;trace.events[6].at=3;assert(not M.validate(trace));cases=cases+1
for _,host in ipairs({support(0),support(45,0)})do local s=M.new(host,0);assert(impact(s,18)==18);s:update(5);assert(s.charge==80);assert(M.validate(s:finish(5)));cases=cases+1 end
local s=M.new(support(),0);assert(impact(s,18,741)==18);assert(impact(s,18,500,261)==18);assert(s.charge==80);cases=cases+1
local s=M.new(support(.2),0);assert(math.abs(impact(s,18)-13)<1e-8 and s.support.gold==0 and s.charge==75);assert(M.validate(s:finish(0)));cases=cases+1
local host=support();local s=M.new(host,0);impact(s,20);s:finish(0);local carried=M.new(host,1);assert(carried.charge==60);cases=cases+1
for _,variant in ipairs({'defence','cargo','mobility'})do local s=M.new(support(45,100,variant),0);assert(s.capacity==(variant=='defence'and 80 or 50));assert(s:resolve(18,500,0,0,{kind='support-hazard'})==18);assert(s.charge==s.capacity);cases=cases+1 end
local s=M.new(support(),0);local o=M.observe(s,500,155);assert(M.project(o).shieldState=='covered');o.capacity=999;assert(not M.project(o));cases=cases+1
print('PhysicalShieldRules PASS '..cases..' behavioral cases')
