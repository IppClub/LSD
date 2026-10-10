-- Deterministic timing contracts; native animation validation is separate.
local Sequence=dofile('/Users/Jin/Workspace/Dora/LSD/Script/Enemy/Sequence.lua')
local now=0;local plays,impacts,stops,completes={},{},{},0
local duration={windup=1,strike=2,recover=.6}
local s=Sequence.new({now=function()return now end,play=function(name,serial,index)plays[#plays+1]={name,serial,index};return duration[name]end,
 impact=function(name,index,n)impacts[#impacts+1]={name,index,n}end,stop=function(r)stops[#stops+1]=r end,complete=function()completes=completes+1 end})
assert(s:start({{name='windup'},{name='strike',impacts={.5,1.5}},{name='recover'}}))
assert(not s:start({{name='strike'}}))
now=.2;assert(not s:ended('windup',1,1));s:update();assert(#plays==1)
now=1.1;s:update();assert(#plays==1,'Timer must not replace AnimationEnd')
assert(s:ended('windup',1,1));s:update();assert(#plays==2)
now=2.8;s:update();assert(#impacts==2,'Late frame must deliver both strikes exactly once');s:update();assert(#impacts==2)
assert(not s:ended('windup',1,1));now=3.2;assert(s:ended('strike',1,2));s:update();assert(#plays==3 and completes==0)
now=3.9;assert(s:ended('recover',1,3));s:update();assert(completes==1)
assert(s:start({{name='strike',impacts={1}}}));local token=s.serial;assert(s:cancel('DEAD'));now=10;s:update();assert(#impacts==2);assert(not s:ended('strike',token,1))
assert(s:start({{name='windup'}}));now=14;s:update();assert(s.status=='failed' and s.error=='END_EVENT_TIMEOUT:windup')
local ok=s:start({{name='strike',impacts={3}}});assert(not ok and s.error=='IMPACT_AFTER_CLIP:strike')
print('PASS sequence: full ending, delayed frames, multihit once, cancellation, stale event, timeout, invalid impact')

-- A hit may finish a battle and start another skill synchronously. The old
-- update must not dispatch remaining strikes into that new generation.
local restart;local hitCount=0
restart=Sequence.new({now=function()return now end,play=function()return 2 end,impact=function()
 hitCount=hitCount+1;restart:cancel('REPLACED');restart:start({{name='recover'}})
end})
assert(restart:start({{name='strike',impacts={.5,1}}}));now=now+1.5;restart:update()
assert(hitCount==1 and restart.stages[1].name=='recover' and restart.status=='playing')
print('PASS reentrant skill replacement')

local clock=0;local count=0
local early=Sequence.new({now=function()return clock end,play=function()count=count+1;return 1 end})
assert(early:start({{name='windup'},{name='strike'}}))
clock=.98;assert(early:ended('windup',early.serial,1));early:update();assert(count==1)
clock=1;early:update();assert(count==2,'Latched native end must advance at full duration')
print('PASS one-frame early native end latched without truncating duration')
